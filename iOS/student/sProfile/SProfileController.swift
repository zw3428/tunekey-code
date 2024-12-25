//
//  SProfileController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/18.
//  Copyright © 2019年 spelist. All rights reserved.
//

import AttributedString
import FirebaseFirestore
import PromiseKit
import SafariServices
import UIKit

class SProfileController: TKBaseViewController {
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    var tableView: UITableView!
    private var versionLabel: TKLabel = TKLabel.create()
        .text(text: "Tunekey iOS version: \(iosVersion)")
        .textColor(color: ColorUtil.Font.fourth)
        .font(font: FontUtil.medium(size: 13))
        .setNumberOfLines(number: 0)
    @Live var userInfoData: TKUser?
    var studentData: TKStudent!
    var unpaidInvoices: [TKInvoice] = [] {
        didSet {
            logger.debug("获取到的invoice: \(unpaidInvoices.count)")
        }
    }

    var notificationData: TKNotificationConfig?

    private var isStudioLoaded: Bool = false

    private var updateTimer: Timer?
    private var isLoadingStudio: Bool = true
    private var teacherId: String = ""
    private var studioData: (teacher: TKUser?, studio: TKStudio?)! = (teacher: nil, studio: nil)
    private var conversation: TKConversation?

    private var studios: [TKStudio] = []

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        studentData = StudentService.student
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SProfileUserInfoCell {
            cell.loadAvatar()
        }
//        loadConversation()
        loadUnpaidInvoices()
    }

    deinit {
        logger.debug("销毁 => \(tkScreenName)")
        EventBus.unregister(target: self)
    }
}

// MARK: - View

extension SProfileController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Profile", rightButton: "", onRightButtonTapped: { [weak self] in
            guard let self = self else { return }
            self.onNavigationBarRightButtonTapped()
        })
        navigationBar.hiddenLeftButton()
        navigationBar.rightButton.titleColor(ColorUtil.red)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initTableView()
        initListener()
    }

    func initTableView() {
        tableView = UITableView()
        mainView.addSubview(view: tableView) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        tableView.register(SProfileUserInfoCell.self, forCellReuseIdentifier: String(describing: SProfileUserInfoCell.self))
        tableView.register(SProfileNotificationsCell.self, forCellReuseIdentifier: String(describing: SProfileNotificationsCell.self))
        tableView.register(ProfileSettingsTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileSettingsTableViewCell.self))
        tableView.register(SStudioProfileCell.self, forCellReuseIdentifier: String(describing: SStudioProfileCell.self))
        tableView.register(ProfileShakeToReportTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileShakeToReportTableViewCell.self))
        tableView.register(SProfileStudioTableViewCell.self, forCellReuseIdentifier: SProfileStudioTableViewCell.id)
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 80))

        versionLabel.addTo(superView: footerView) { make in
            make.center.equalToSuperview()
        }
        versionLabel.textAlignment = .center

        tableView.tableFooterView = footerView
    }

    private func initListener() {
        EventBus.listen(key: .studentTeacherChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                logger.debug("刷新教师数据")
                self.studioData = (teacher: nil, studio: nil)
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SStudioProfileCell {
                    cell.initNilData()
                    cell.inviteTeacherButton.isHidden = true
                    cell.loadingIndicatorView.startAnimating()
                }
                self.initData()
            }
        }
    }
}

// MARK: - Data

extension SProfileController {
    override func initData() {
        weak var weakself = self
        if !UIApplication.shared.isRegisteredForRemoteNotifications {
            let count = SLCache.main.getInt(key: SLCache.SET_NOTIFICATION_PERMISSIONS_COUNT)
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                AppDelegate().setNotificationAuthority(count: count)
            }
        }

        EventBus.listen(key: .refreshUserInfo, target: weakself!) { [weak self] _ in
            self?.getUserInfo()
        }
        EventBus.listen(key: EventBus.Key.signOut, target: weakself!) { [weak self] _ in
//            self?.dismiss(animated: true, completion: nil)
            self?.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }

        EventBus.listen(key: .studentTeacherChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.loadConversationV2()
        }

        EventBus.listen(key: .conversationSyncSuccess, target: self) { [weak self] _ in
            self?.loadConversationV2()
        }
        EventBus.listen(key: .messagesSyncSuccess, target: self) { [weak self] _ in
            self?.loadConversationV2()
        }
        EventBus.listen(key: .dataVersionChanged, target: self) { [weak self] _ in
            self?.loadConversationV2()
        }
        EventBus.listen(key: .dataChangeHistorySyncStarted, target: self) { [weak self] _ in
            self?.loadConversationV2()
        }
        getUserInfo()

        AppService.shared.fetchAppVersionFromAppStore()
            .done { [weak self] appVersion in
                guard let self = self else { return }
                if let appVersion {
                    logger.debug("获取到的版本信息: \(appVersion)")
                    if appVersion != iosVersion {
                        let attributedTexts = ASAttributedString(string: "Your current version is \(iosVersion) for iOS.\nThe latest version is available for update. ", with: [.font(FontUtil.medium(size: 13)), .foreground(ColorUtil.Font.fourth)]) + ASAttributedString(string: "UPDATE NOW", with: [.font(FontUtil.medium(size: 13)), .foreground(ColorUtil.main), .action({
                            let url = URL(string: "https://apps.apple.com/app/id1479006791")!
                            UIApplication.shared.open(url)
                        })])
                        self.versionLabel.attributed.text = attributedTexts
                    } else {
                        let attributedTexts = ASAttributedString(string: "Your current version is \(iosVersion) for iOS.\nYour Tunekey has been updated to the latest version.", with: [.font(FontUtil.medium(size: 13)), .foreground(ColorUtil.Font.fourth)])
                        self.versionLabel.attributed.text = attributedTexts
                    }
                } else {
                    logger.error("获取到的版本信息是空的")
                }
            }
            .catch { error in
                logger.error("获取版本信息失败: \(error)")
            }
    }

    private func loadConversationV2() {
        logger.debug("开始加载会话数据")
        var teacherId: String = ""
        if let t = ListenerService.shared.studentData.teacherData {
            teacherId = t.userId
        }
        if teacherId == "" {
            if let t = studioData.0 {
                teacherId = t.userId
            }
        }
        guard teacherId != "" else {
            logger.error("无法获取教师id")
            return
        }
        ChatService.conversation.getPrivateFromLocal(userId: teacherId)
            .done { [weak self] conversation in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    logger.debug("加载会话数据成功: \(conversation?.toJSONString() ?? "")")
                    self.conversation = conversation
                    self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                }
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    logger.debug("加载会话数据出错: \(error)")
                    self.conversation = nil
                    self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                }
            }
    }

    /// 获取teacher 和 studio infor
    private func getTeacherStudioInfo() {
        UserService.student.getStudents()
            .done { [weak self] students in
                guard let self = self else { return }
                if let student = students.first {
                    print("当前学生信息: \(student.toJSONString() ?? "")")
                    self.studentData = student
                    self.loadUnpaidInvoices()
                    let teacherId = student.teacherId
                    let studioId = student.studioId
                    guard studioId != "" else {
                        self.isLoadingStudio = false
                        return
                    }
                    akasync {
                        do {
                            let studioInfo = try akawait(UserService.studio.getStudioInfo(student.studioId))
                            self.studioData.studio = studioInfo
                            if teacherId != "" {
                                let teacher = try akawait(UserService.user.getUser(id: teacherId))
                                if let teacher = teacher {
                                    self.studioData.teacher = teacher
                                }
                            }
                            logger.debug("获取studio完成")
                            DispatchQueue.main.async {
                                self.isLoadingStudio = false
                                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                            }
                        } catch {
                            self.isStudioLoaded = true
                            logger.error("获取数据失败: \(error)")
                            DispatchQueue.main.async {
                                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                            }
                        }
                    }
//
//                    when(fulfilled: UserService.studio.getStudioInfo(student.studioId), UserService.user.getUser(id: teacherId))
//                        .done { studio, teacher in
//                            self.isStudioLoaded = true
//                            self.studioData.studio = studio
//                            if let teacher = teacher {
//                                self.studioData.teacher = teacher
//                            }
//                            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
//                        }
//                        .catch { error in
//                            self.isStudioLoaded = true
//                            logger.error("获取数据失败: \(error)")
//                            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
//                        }
                } else {
                    logger.debug("当前学生未绑定任何教师")
                    self.isStudioLoaded = true
                    self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                }
            }
            .catch { error in
                logger.error("获取学生数据失败: \(error)")
                self.isStudioLoaded = true
                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            }
    }

    private func getStudioInfo2() {
        guard teacherId != "" else { return }
        addSubscribe(
            UserService.studio.studentGetStudioInfo(teacherId: teacherId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    self.studioData.studio = data
                    SLCache.main.set(key: SLCache.STUDIO_NAME, value: data.name)
                    self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()

                    logger.debug("======\(err)")
                })
        )
    }

    private func getTeacherInfo2() {
        var isLoad = false
        addSubscribe(
            UserService.user.getUserInfoById(userId: teacherId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self, !isLoad else { return }
                    if let data = TKUser.deserialize(from: data.data()) {
                        self.studioData.teacher = data
                        isLoad = true
                        self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                    }

                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    /// 获取UserInfo
    private func getUserInfo() {
        addSubscribe(
            UserService.user.getInfo()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        self.userInfoData = data
                        initUserInfo()
                    }
                    if let data = data[false] {
                        self.userInfoData = data
                        initUserInfo()
                    }

                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
        // 初始化数据 用来展示
        func initUserInfo() {
            tableView.reloadData()
            if SLCache.LoginHistory.listAll(exceptEmail: userInfoData?.email ?? "").isEmpty {
                // 没有其他的账号了,显示sign out
                navigationBar.rightButton.title(title: "Sign out")
                    .titleColor(color: ColorUtil.red)
            } else {
                navigationBar.rightButton.title(title: "Switch account")
                    .titleColor(color: ColorUtil.main)
            }
        }
    }

    /// 获取Notification数据
    func getNotificationData() {
        guard let userId = UserService.user.id(), userId != "" else { return }
        var isLoad = false
        addSubscribe(
            NotificationServer.instance.getNotificateionConfig()
                .subscribe(onNext: { [weak self] doc in
                    guard let self = self else { return }
                    guard !isLoad else { return }
                    if doc.exists {
                        if let doc = TKNotificationConfig.deserialize(from: doc.data()) {
                            logger.debug("获取到的通知数据: \(doc.toJSONString() ?? "")")
                            isLoad = true
                            self.notificationData = doc
                            self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
                        } else {
                            setUpNotification()
                        }
                    } else {
                        setUpNotification()
                    }

                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
        /**
         因为没有Notification 信息,所以要初始化下
         */
        func setUpNotification() {
            guard UserService.user.id() != nil else { return }
            addSubscribe(
                NotificationServer.instance.initNotificationConfig()
                    .subscribe(onNext: { _ in
                        logger.debug("======初始化Notification成功")

                    }, onError: { err in
                        logger.debug("初始化Notification失败:\(err)")
                    })
            )
        }
    }

    private func updateNotificationConfig(data: [String: Any]) {
        addSubscribe(
            NotificationServer.instance.updateNotificateionConfig(data: data)
                .subscribe(onNext: { _ in
                    logger.debug("======更新Notification成功")

                }, onError: { err in
                    logger.debug("更新Notification失败:\(err)")
                })
        )
    }

    func toReportListController() {
        logger.debug("跳转到bug report界面")
        let controller = ShowBugReportorListController()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    private func loadUnpaidInvoices() {
        guard let student = studentData else { return }
        DatabaseService.collections.invoice()
            .whereField("studentId", isEqualTo: student.studentId)
            .whereField("status", in: [TKInvoiceStatus.paying.rawValue, TKInvoiceStatus.created.rawValue, TKInvoiceStatus.sent.rawValue, TKInvoiceStatus.waived.rawValue])
            .limit(to: 3)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    logger.error("获取未支付的invoices失败: \(error)")
                    self.unpaidInvoices = []
                } else {
                    logger.debug("获取未支付的invoices成功")
                    if var data: [TKInvoice] = [TKInvoice].deserialize(from: snapshot?.documents.compactMap({ $0.data() })) as? [TKInvoice] {
                        // 还要计算是否expire
                        for item in data {
                            if item.status == .waived && item.waivedAmount + item.paidAmount == item.totalAmount {
                                data.removeElements({ $0.id == item.id })
                            }
                        }
                        self.unpaidInvoices = data.filter({ !$0.markAsPay })
                    } else {
                        self.unpaidInvoices = []
                    }
                }
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
    }

    private func loadStudiosInfo(studioIds: [String]) -> Promise<[TKStudio]> {
        Promise { resolver in
            func fetch(_ idList: [String]) -> Promise<[TKStudio]> {
                Promise { r in
                    DatabaseService.collections.studio()
                        .whereField("id", in: idList)
                        .getDocumentsData(TKStudio.self) { studios, error in
                            if let error = error {
                                r.reject(error)
                            } else {
                                r.fulfill(studios)
                            }
                        }
                }
            }

            let idsList = studioIds.group(count: 10)
            var actions: [Promise<[TKStudio]>] = []
            for idList in idsList {
                actions.append(fetch(idList))
            }

            when(fulfilled: actions)
                .done { studiosList in
                    var studios: [TKStudio] = []
                    for studioList in studiosList {
                        studios += studioList
                    }
                    resolver.fulfill(studios)
                }
                .catch { error in
                    resolver.reject(error)
                }
        }
    }

    private func loadStudioIds(fromStudents students: [TKStudent]) -> Promise<[String]> {
        Promise { resolver in
            var studioIds: [String] = []
            var teacherIds: [String] = []
            for student in students {
                if student.studioId != "" {
                    studioIds.append(student.studioId)
                } else {
                    teacherIds.append(student.teacherId)
                }
            }

            if !teacherIds.isEmpty {
                UserService.teacher.getTeachers(ids: teacherIds)
                    .done { teachers in
                        studioIds += teachers.compactMap({ $0.studioId })
                        resolver.fulfill(studioIds)
                    }
                    .catch { error in
                        resolver.reject(error)
                    }
            } else {
                resolver.fulfill(studioIds)
            }
        }
    }

    private func loadStudentsInfo(studentId: String) -> Promise<[TKStudent]> {
        Promise { resolver in
            DatabaseService.collections.teacherStudentList()
                .whereField("studentId", isEqualTo: studentId)
                .getDocumentsData(TKStudent.self) { students, error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        resolver.fulfill(students)
                    }
                }
        }
    }
}

extension SProfileController {
    override func bindEvent() {
        super.bindEvent()
        $userInfoData.addSubscriber { [weak self] user in
            guard let self = self else { return }
            guard user != nil else { return }
            // 获取studioinfo
            self.getNotificationData()
            self.loadData()
        }
    }

    private func loadData() {
        akasync { [weak self] in
            guard let self = self, let user = self.userInfoData else { return }
            let students = try akawait(self.loadStudentsInfo(studentId: user.userId))
            let studioIds = try akawait(self.loadStudioIds(fromStudents: students))
            self.studios = try akawait(self.loadStudiosInfo(studioIds: studioIds))
            updateUI {
                self.isLoadingStudio = false
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - TableView

extension SProfileController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SProfileUserInfoCell.self), for: indexPath) as! SProfileUserInfoCell
            cell.delegate = self
            cell.initData(data: userInfoData, unpaidInvoices: unpaidInvoices)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: SProfileStudioTableViewCell.id, for: indexPath) as! SProfileStudioTableViewCell
            cell.tableView = tableView
            cell.isLoading = isLoadingStudio
            cell.studios = studios
            cell.onAddButtonTapped = sStudioProfileCellInviteTeacherButtonTapped
            return cell
//            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SStudioProfileCell.self), for: indexPath) as! SStudioProfileCell
//            if isStudioLoaded {
//                if studioData.1 == nil {
//                    cell.initNilData()
//                } else {
//                    var isPending: Bool = false
//                    if let studentData = self.studentData {
//                        isPending = studentData.studentApplyStatus == .apply
//                    }
//                    cell.initData(data: [studioData], isPending: isPending)
//                    if !isPending {
//                        cell.loadConversation(conversation)
//                    } else {
//                        cell.chatIconButton.isHidden = true
//                    }
//                }
//            }
//            cell.delegate = self
//            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SProfileNotificationsCell.self), for: indexPath) as! SProfileNotificationsCell
            cell.tableView = tableView
            if let notificationData {
                cell.initData(data: notificationData)
                cell.delegate = self
                if notificationData.weekendPracticeReminder.count < 3 {
                    self.notificationData?.weekendPracticeReminder = [.init(time: 61200, enable: true), .init(time: -1, enable: false), .init(time: -1, enable: false)]
                }
                if notificationData.workdayPracticeReminder.count < 3 {
                    self.notificationData?.workdayPracticeReminder = [.init(time: -1, enable: false), .init(time: -1, enable: false), .init(time: -1, enable: false)]
                }
            }
            cell.practiceReminderWorkdayTime1.willSelect { [weak self] in
                guard let self = self, let notificationData = self.notificationData else { return false }
                guard notificationData.practiceReminderOpened else { return false }
                let reminder = notificationData.workdayPracticeReminder[0]
                var defaultHour: Int = 0
                var defaultMin: Int = 0
                if reminder.time > 0 {
                    defaultHour = reminder.time / 3600
                    defaultMin = (reminder.time % 3600) / 60
                }
                TKTimePicker.show(between: TKTimePicker.Time(hour: 0, minute: 0), and: TKTimePicker.Time(hour: 23, minute: 59), defaultTime: .init(hour: defaultHour, minute: defaultMin), target: self, enableInterval: false) { selectedTime in
                    let time: Int = (selectedTime.hour * 3600) + (selectedTime.minute * 60)
                    self.notificationData?.workdayPracticeReminder[0] = .init(time: time, enable: true)
                    if let notificationData = self.notificationData {
                        self.updateNotificationConfig(data: notificationData.toJSON() ?? [:])
                    }
                    cell.practiceReminderWorkdayTime1.setTitle(TimeUtil.secondsToHourMins(time: time, withAMPM: true))
                    cell.practiceReminderWorkdayTime1.isSelected(true)
                } didShow: { controller in
                    controller.showDeleteButton()
                    controller.deleteButton.onTapped { [weak self] _ in
                        guard let self = self else { return }
                        self.notificationData?.workdayPracticeReminder[0].enable = false
                        self.notificationData?.workdayPracticeReminder[0].time = -1
                        if let notificationData = self.notificationData {
                            self.updateNotificationConfig(data: notificationData.toJSON() ?? [:])
                        }
                        cell.practiceReminderWorkdayTime1.isSelected(false)
                        cell.practiceReminderWorkdayTime1.setImage(UIImage(named: "ic_add_gray_small")!)
                        controller.hide {
                        }
                    }
                }
                return false
            }

            cell.practiceReminderWorkdayTime2.willSelect { [weak self] in
                guard let self = self, let notificationData = self.notificationData else { return false }
                guard notificationData.practiceReminderOpened else { return false }
                let reminder = notificationData.workdayPracticeReminder[1]
                var defaultHour: Int = 0
                var defaultMin: Int = 0
                if reminder.time > 0 {
                    defaultHour = reminder.time / 3600
                    defaultMin = (reminder.time % 3600) / 60
                }
                TKTimePicker.show(between: TKTimePicker.Time(hour: 0, minute: 0), and: TKTimePicker.Time(hour: 23, minute: 59), defaultTime: .init(hour: defaultHour, minute: defaultMin), target: self, enableInterval: false) { selectedTime in
                    let time: Int = (selectedTime.hour * 3600) + (selectedTime.minute * 60)
                    self.notificationData?.workdayPracticeReminder[1] = .init(time: time, enable: true)
                    self.updateNotificationConfig(data: self.notificationData?.toJSON() ?? [:])
                    cell.practiceReminderWorkdayTime2.setTitle(TimeUtil.secondsToHourMins(time: time, withAMPM: true))
                    cell.practiceReminderWorkdayTime2.isSelected(true)
                } didShow: { controller in
                    controller.showDeleteButton()
                    controller.deleteButton.onTapped { [weak self] _ in
                        guard let self = self else { return }
                        self.notificationData?.workdayPracticeReminder[1].enable = false
                        self.notificationData?.workdayPracticeReminder[1].time = -1
                        self.updateNotificationConfig(data: self.notificationData?.toJSON() ?? [:])
                        cell.practiceReminderWorkdayTime2.isSelected(false)
                        cell.practiceReminderWorkdayTime2.setImage(UIImage(named: "ic_add_gray_small")!)
                        controller.hide {
                        }
                    }
                }
                return false
            }
            cell.practiceReminderWorkdayTime3.willSelect { [weak self] in
                guard let self = self, let notificationData = self.notificationData else { return false }
                guard notificationData.practiceReminderOpened else { return false }
                let reminder = notificationData.workdayPracticeReminder[2]
                var defaultHour: Int = 0
                var defaultMin: Int = 0
                if reminder.time > 0 {
                    defaultHour = reminder.time / 3600
                    defaultMin = (reminder.time % 3600) / 60
                }
                TKTimePicker.show(between: TKTimePicker.Time(hour: 0, minute: 0), and: TKTimePicker.Time(hour: 23, minute: 59), defaultTime: .init(hour: defaultHour, minute: defaultMin), target: self, enableInterval: false) { selectedTime in
                    let time: Int = (selectedTime.hour * 3600) + (selectedTime.minute * 60)
                    self.notificationData?.workdayPracticeReminder[2] = .init(time: time, enable: true)
                    self.updateNotificationConfig(data: self.notificationData?.toJSON() ?? [:])
                    cell.practiceReminderWorkdayTime3.setTitle(TimeUtil.secondsToHourMins(time: time, withAMPM: true))
                    cell.practiceReminderWorkdayTime3.isSelected(true)
                } didShow: { controller in
                    controller.showDeleteButton()
                    controller.deleteButton.onTapped { [weak self] _ in
                        guard let self = self else { return }
                        self.notificationData?.workdayPracticeReminder[2].enable = false
                        self.notificationData?.workdayPracticeReminder[2].time = -1
                        self.updateNotificationConfig(data: self.notificationData?.toJSON() ?? [:])
                        cell.practiceReminderWorkdayTime3.isSelected(false)
                        cell.practiceReminderWorkdayTime3.setImage(UIImage(named: "ic_add_gray_small")!)
                        controller.hide {
                        }
                    }
                }
                return false
            }
            cell.practiceReminderWeekendTime1.willSelect { [weak self] in
                guard let self = self, let notificationData = self.notificationData else { return false }
                guard notificationData.practiceReminderOpened else { return false }
                let reminder = notificationData.weekendPracticeReminder[0]
                var defaultHour: Int = 0
                var defaultMin: Int = 0
                if reminder.time > 0 {
                    defaultHour = reminder.time / 3600
                    defaultMin = (reminder.time % 3600) / 60
                }
                TKTimePicker.show(between: TKTimePicker.Time(hour: 0, minute: 0), and: TKTimePicker.Time(hour: 23, minute: 59), defaultTime: .init(hour: defaultHour, minute: defaultMin), target: self, enableInterval: false) { selectedTime in
                    let time: Int = (selectedTime.hour * 3600) + (selectedTime.minute * 60)
                    self.notificationData?.weekendPracticeReminder[0] = .init(time: time, enable: true)
                    self.updateNotificationConfig(data: self.notificationData?.toJSON() ?? [:])
                    cell.practiceReminderWeekendTime1.setTitle(TimeUtil.secondsToHourMins(time: time, withAMPM: true))
                    cell.practiceReminderWeekendTime1.isSelected(true)
                } didShow: { controller in
                    controller.showDeleteButton()
                    controller.deleteButton.onTapped { [weak self] _ in
                        guard let self = self else { return }
                        self.notificationData?.weekendPracticeReminder[0].enable = false
                        self.notificationData?.weekendPracticeReminder[0].time = -1
                        self.updateNotificationConfig(data: self.notificationData?.toJSON() ?? [:])
                        cell.practiceReminderWeekendTime1.isSelected(false)
                        cell.practiceReminderWeekendTime1.setImage(UIImage(named: "ic_add_gray_small")!)
                        controller.hide {
                        }
                    }
                }
                return false
            }
            cell.practiceReminderWeekendTime2.willSelect { [weak self] in
                guard let self = self, let notificationData = self.notificationData else { return false }
                guard notificationData.practiceReminderOpened else { return false }
                let reminder = notificationData.weekendPracticeReminder[1]
                var defaultHour: Int = 0
                var defaultMin: Int = 0
                if reminder.time > 0 {
                    defaultHour = reminder.time / 3600
                    defaultMin = (reminder.time % 3600) / 60
                }
                TKTimePicker.show(between: TKTimePicker.Time(hour: 0, minute: 0), and: TKTimePicker.Time(hour: 23, minute: 59), defaultTime: .init(hour: defaultHour, minute: defaultMin), target: self, enableInterval: false) { selectedTime in
                    let time: Int = (selectedTime.hour * 3600) + (selectedTime.minute * 60)
                    self.notificationData?.weekendPracticeReminder[1] = .init(time: time, enable: true)
                    self.updateNotificationConfig(data: self.notificationData?.toJSON() ?? [:])
                    cell.practiceReminderWeekendTime2.setTitle(TimeUtil.secondsToHourMins(time: time, withAMPM: true))
                    cell.practiceReminderWeekendTime2.isSelected(true)
                } didShow: { controller in
                    controller.showDeleteButton()
                    controller.deleteButton.onTapped { [weak self] _ in
                        guard let self = self else { return }
                        self.notificationData?.weekendPracticeReminder[1].enable = false
                        self.notificationData?.weekendPracticeReminder[1].time = -1
                        self.updateNotificationConfig(data: self.notificationData?.toJSON() ?? [:])
                        cell.practiceReminderWeekendTime2.isSelected(false)
                        cell.practiceReminderWeekendTime2.setImage(UIImage(named: "ic_add_gray_small")!)
                        controller.hide {
                        }
                    }
                }
                return false
            }
            cell.practiceReminderWeekendTime3.willSelect { [weak self] in
                guard let self = self, let notificationData = self.notificationData else { return false }
                guard notificationData.practiceReminderOpened else { return false }
                let reminder = notificationData.weekendPracticeReminder[2]
                var defaultHour: Int = 0
                var defaultMin: Int = 0
                if reminder.time > 0 {
                    defaultHour = reminder.time / 3600
                    defaultMin = (reminder.time % 3600) / 60
                }
                TKTimePicker.show(between: TKTimePicker.Time(hour: 0, minute: 0), and: TKTimePicker.Time(hour: 23, minute: 59), defaultTime: .init(hour: defaultHour, minute: defaultMin), target: self, enableInterval: false) { selectedTime in
                    let time: Int = (selectedTime.hour * 3600) + (selectedTime.minute * 60)
                    self.notificationData?.weekendPracticeReminder[2] = .init(time: time, enable: true)
                    self.updateNotificationConfig(data: self.notificationData?.toJSON() ?? [:])
                    cell.practiceReminderWeekendTime3.setTitle(TimeUtil.secondsToHourMins(time: time, withAMPM: true))
                    cell.practiceReminderWeekendTime3.isSelected(true)
                } didShow: { controller in
                    controller.showDeleteButton()
                    controller.deleteButton.onTapped { [weak self] _ in
                        guard let self = self else { return }
                        self.notificationData?.weekendPracticeReminder[2].enable = false
                        self.notificationData?.weekendPracticeReminder[2].time = -1
                        self.updateNotificationConfig(data: self.notificationData?.toJSON() ?? [:])
                        cell.practiceReminderWeekendTime3.isSelected(false)
                        cell.practiceReminderWeekendTime3.setImage(UIImage(named: "ic_add_gray_small")!)
                        controller.hide {
                        }
                    }
                }
                return false
            }

            cell.practiceReminderSwitch.onValueChanged { [weak self] isOn in
                self?.onPracticeReminderSwitchChanged(isOn, at: cell)
            }
            if let notificationData = notificationData {
                cell.practiceReminderSwitch.isOn = notificationData.practiceReminderOpened
                onPracticeReminderSwitchChanged(notificationData.practiceReminderOpened, at: cell)

                cell.practiceReminderWorkdayTime1.isSelected(notificationData.workdayPracticeReminder[0].enable)
                cell.practiceReminderWorkdayTime2.isSelected(notificationData.workdayPracticeReminder[1].enable)
                cell.practiceReminderWorkdayTime3.isSelected(notificationData.workdayPracticeReminder[2].enable)
                if notificationData.workdayPracticeReminder[0].enable {
                    cell.practiceReminderWorkdayTime1.setTitle(TimeUtil.secondsToHourMins(time: notificationData.workdayPracticeReminder[0].time, withAMPM: true))
                } else {
                    cell.practiceReminderWorkdayTime1.setImage(UIImage(named: "ic_add_gray_small")!)
                }
                if notificationData.workdayPracticeReminder[1].enable {
                    cell.practiceReminderWorkdayTime2.setTitle(TimeUtil.secondsToHourMins(time: notificationData.workdayPracticeReminder[1].time, withAMPM: true))
                } else {
                    cell.practiceReminderWorkdayTime2.setImage(UIImage(named: "ic_add_gray_small")!)
                }
                if notificationData.workdayPracticeReminder[2].enable {
                    cell.practiceReminderWorkdayTime3.setTitle(TimeUtil.secondsToHourMins(time: notificationData.workdayPracticeReminder[2].time, withAMPM: true))
                } else {
                    cell.practiceReminderWorkdayTime3.setImage(UIImage(named: "ic_add_gray_small")!)
                }

                cell.practiceReminderWeekendTime1.isSelected(notificationData.weekendPracticeReminder[0].enable)
                cell.practiceReminderWeekendTime2.isSelected(notificationData.weekendPracticeReminder[1].enable)
                cell.practiceReminderWeekendTime3.isSelected(notificationData.weekendPracticeReminder[2].enable)
                if notificationData.weekendPracticeReminder[0].enable {
                    cell.practiceReminderWeekendTime1.setTitle(TimeUtil.secondsToHourMins(time: notificationData.weekendPracticeReminder[0].time, withAMPM: true))
                } else {
                    cell.practiceReminderWeekendTime1.setImage(UIImage(named: "ic_add_gray_small")!)
                }
                if notificationData.weekendPracticeReminder[1].enable {
                    cell.practiceReminderWeekendTime2.setTitle(TimeUtil.secondsToHourMins(time: notificationData.weekendPracticeReminder[1].time, withAMPM: true))
                } else {
                    cell.practiceReminderWeekendTime2.setImage(UIImage(named: "ic_add_gray_small")!)
                }
                if notificationData.weekendPracticeReminder[2].enable {
                    cell.practiceReminderWeekendTime3.setTitle(TimeUtil.secondsToHourMins(time: notificationData.weekendPracticeReminder[2].time, withAMPM: true))
                } else {
                    cell.practiceReminderWeekendTime3.setImage(UIImage(named: "ic_add_gray_small")!)
                }
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileSettingsTableViewCell.self), for: indexPath) as! ProfileSettingsTableViewCell
            cell.delegate = self
            cell.loadData(data: userInfoData)
            cell.reportInfoLabel.onViewTapped { [weak self] _ in
                self?.toReportListController()
            }
            cell.shakeToReportView.onViewTapped { [weak self] _ in
                self?.toReportListController()
            }
            cell.paymentView.onViewTapped { [weak self] _ in
                self?.toPaymentViewController()
            }
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileShakeToReportTableViewCell.self), for: indexPath) as! ProfileShakeToReportTableViewCell
            cell.infoLabel.onViewTapped { [weak self] _ in
                self?.toReportListController()
            }
            cell.initData()
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SProfileUserInfoCell.self), for: indexPath) as! SProfileUserInfoCell
            cell.initData(data: userInfoData, unpaidInvoices: unpaidInvoices)
            return cell
        }
    }
}

extension SProfileController {
    private func onPracticeReminderSwitchChanged(_ isOn: Bool, at cell: SProfileNotificationsCell) {
        notificationData?.practiceReminderOpened = isOn
        updateNotificationConfig(data: notificationData?.toJSON() ?? [:])
        tableView.beginUpdates()
        cell.practiceReminderView.snp.updateConstraints { make in
            if isOn {
                make.height.equalTo(155)
            } else {
                make.height.equalTo(60)
            }
        }

        tableView.endUpdates()

        cell.practiceReminderWorkdayTime1.isHidden = !isOn
        cell.practiceReminderWorkdayTime2.isHidden = !isOn
        cell.practiceReminderWorkdayTime3.isHidden = !isOn
        cell.practiceReminderWeekendTime1.isHidden = !isOn
        cell.practiceReminderWeekendTime2.isHidden = !isOn
        cell.practiceReminderWeekendTime3.isHidden = !isOn
    }

    private func onPracticeReminderWorkdayTime1Tapped(_ isSelected: Bool) {
    }

    private func onPracticeReminderWorkdayTime2Tapped(_ isSelected: Bool) {
    }

    private func onPracticeReminderWorkdayTime3Tapped(_ isSelected: Bool) {
    }

    private func onPracticeReminderWeekendTime1Tapped(_ isSelected: Bool) {
    }

    private func onPracticeReminderWeekendTime2Tapped(_ isSelected: Bool) {
    }

    private func onPracticeReminderWeekendTime3Tapped(_ isSelected: Bool) {
    }
}

// MARK: - Action

extension SProfileController: SInviteTeacherViewControllerDelegate {
    func sInviteTeacherViewControllerDismissed() {
        if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SStudioProfileCell {
            cell.inviteTeacherButton.isHidden = true
            cell.loadingIndicatorView.startAnimating()
        }
        initData()
    }
}

extension SProfileController: ProfileSettingsTableViewCellDelegate, SProfileUserInfoCellDelegate, SProfileNotificationsCellDelegate, SStudioProfileCellDelegate {
    func sStudioProfileCell(didTappedConversation conversation: TKConversation?) {
        if let conversation = conversation {
            toMessagesViewController(conversation)
        } else {
            // 从本地获取
            guard let teacher = studioData.teacher else { return }
            let teacherId = teacher.userId
            showFullScreenLoading()
            ChatService.conversation.getPrivate(userId: teacherId)
                .done { [weak self] conversation in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    self.conversation = conversation
                    self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                    self.toMessagesViewController(conversation)
                }
                .catch { [weak self] error in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    logger.error("获取失败: \(error)")
                }
        }
    }

    private func toMessagesViewController(_ conversation: TKConversation) {
        MessagesViewController.show(conversation)
    }

    func profileSettingsTableViewCellContactUsTapped() {
        let controller = ContactUsSelectorViewController()
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

    func profileSettingsTableViewCellFAQTapped() {
        CommonsWebViewViewController.show("https://www.tunekey.app/faq/mobile")
    }

    func sStudioProfileCellInviteTeacherButtonTapped() {
        guard let userId = UserService.user.id() else { return }
        showFullScreenLoading()
        UserService.user.getUser(id: userId)
            .done { [weak self] user in
                guard let self = self else { return }
                guard let user = user else {
                    self.updateFullScreenLoadingMsg(msg: "Init data failed, please try again later.")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                    }
                    return
                }
                CacheUtil.UserInfo.setUser(user: user)
                self.hideFullScreenLoading()
                DispatchQueue.main.async {
                    let controller = SInviteTeacherViewController()
                    controller.delegate = self
                    controller.modalPresentationStyle = .custom
                    self.present(controller, animated: false, completion: nil)
                }
            }
            .catch { _ in
                self.updateFullScreenLoadingMsg(msg: "Init data failed, please try again later.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                }
            }
    }

    func sStudioProfileCell(click index: Int) {
        let controller = WelcomeStudensViewController()
        controller.modalPresentationStyle = .fullScreen
        if ListenerService.shared.studentData.studentData != nil {
            controller.studentData = ListenerService.shared.studentData.studentData!
        } else {
            controller.studentData = studentData
        }
        if let studio = studioData.studio {
            controller.studioName = studio.name
            controller.studioData = studio
            controller.studentName = userInfoData?.name ?? ""
            controller.currentColor = ColorUtil.Storefront.getColor(color: studio.storefrontColor)
        }
        if let teacher = studioData.teacher {
            controller.teacherUser = teacher
            controller.teacherName = teacher.name
        }
        controller.isStudentProfileEnter = true
        controller.hero.isEnabled = true
        controller.isLook = true
        controller.role = .student
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func profileSettingsTableViewCellCalendarTapped() {
    }

    // MARK: - SProfileNotificationsCellDelegate

    func profileNotification(onReminderDataChangedWith times: [Int], isOn: Bool) {
        notificationData?.reminderOpened = isOn

        notificationData?.reminderTimes = times
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
            self.updateNotificationConfig(data: [
                "reminderTimes": times,
                "reminderOpened": isOn,
            ])
        })
    }

    func profileNotification(clickHomeworkReminder cell: SProfileNotificationsCell) {
        guard let notificationData = notificationData else { return }
        let dateTime = Date().startOfDay
        let defaultDate = TimeUtil.changeTime(time: Double(dateTime.timestamp + (notificationData.homeworkReminderTime == -1 ? 0 : notificationData.homeworkReminderTime)))
        let homeworkReminderTime = TKTimePicker.Time(hour: defaultDate.hour, minute: defaultDate.minute)
        TKTimePicker.show(between: TKTimePicker.Time(hour: 0, minute: 0), and: TKTimePicker.Time(hour: 23, minute: 59), defaultTime: homeworkReminderTime, target: self) { [weak self] time in
            guard let self = self else { return }
            logger.debug("======选择了Homework remider 时间为:\(time)")
            let selectData = TimeUtil.getDate(year: dateTime.year, month: dateTime.month, day: dateTime.day, hour: time.hour, min: time.minute)
            self.notificationData?.homeworkReminderTime = selectData.timestamp - dateTime.timestamp
            self.updateNotificationConfig(data: ["homeworkReminderTime": self.notificationData?.homeworkReminderTime ?? -1])

            self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
        }
    }

    func profileNotification(select cell: SProfileNotificationsCell, isOn: Bool, type: SProfileNotificationsCell.ProfileNotificationType) {
        logger.debug("======\(type)是否开启\(isOn)")
        switch type {
        case .homeworkReminder:
            break
        case .lessonNotes:
            updateNotificationConfig(data: ["notesNotificationOpened": isOn])
            break
        case .newAchievement:
            updateNotificationConfig(data: ["newAchievementNotificationOpened": isOn])
            break
        case .fileShared:
            updateNotificationConfig(data: ["fileSharedNotificationOpened": isOn])
            break
        case .rescheduleConfirmed:
            updateNotificationConfig(data: ["rescheduleConfirmedNotificationOpened": isOn])
            break
        }
    }

    // MARK: - SProfileUserInfoCellDelegate

    func profileUserInfoCell(clickCell cell: SProfileUserInfoCell) {
        guard var student = studentData else {
            logger.debug("学生数据为空")
            toProfileContactEditController()
            return
        }
        var hasActiveLessons: Bool = false
        for (index, config) in ListenerService.shared.studentData.scheduleConfigs.enumerated() {
            let data = LessonUtil.getLessonEndDateAndCount(data: config)
            ListenerService.shared.studentData.scheduleConfigs[index].lessonEndDateAndCount = data
            switch data.type {
            case .none:
                if data.count > 0 {
                    hasActiveLessons = true
                    break
                }
            case .noLoop:
                if data.daysRemaining > 0 {
                    hasActiveLessons = true
                }
            case .unlimited:
                hasActiveLessons = true
                break
            }
            if hasActiveLessons {
                break
            }
        }
        if !hasActiveLessons && unpaidInvoices.isEmpty {
            logger.debug("没有正在上的课,也没有未支付的订单,进入edit页面")
            toProfileContactEditController()
        } else {
            let controller = StudentDetailsV2ViewController(student)
            student.name = userInfoData?.name ?? ""
            controller.isStudentView = true
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.enablePanToDismiss()
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            present(controller, animated: true, completion: nil)
        }
    }

    private func toProfileContactEditController() {
        guard let userData = userInfoData else {
            logger.debug("当前用户信息为空")
            return
        }
        let controller = SProfileUserInfoController()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.user = userData
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    // MARK: - ProfileSettingsTableViewCellDelegate

    func profileSettingsTableViewCell(enableScreenLockChanged isOn: Bool) {
    }

    func profileSettingsTableViewCellChangePasswordTapped() {
        let controller = ChangePasswordViewController()
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func profileSettingsTableViewCellMergeAccountTapped() {
//        let controller = ProfileMergeAccountViewController()
//        controller.enablePanToDismiss()
//        controller.hero.isEnabled = true
//        controller.modalPresentationStyle = .fullScreen
//        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//        present(controller, animated: true, completion: nil)

        let controller = ProfileAccountController()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func profileSettingsTableViewCellAboutUsTapped() {
        let controller = ProfileAboutUsViewController()
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }
}

extension SProfileController {
    func toPaymentViewController() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let student = self.studentData else { return }
            let controller = StudentDetailsBalanceViewController(student)
            controller.enableHero()
            self.present(controller, animated: true)
        }
    }

    private func onNavigationBarRightButtonTapped() {
        guard let user = userInfoData else { return }
        let otherLoginItems = SLCache.LoginHistory.listAll(exceptEmail: user.email)
        if otherLoginItems.isEmpty {
            signout(from: self)
        } else {
            let controller = SwitchAccountViewController(loginItems: otherLoginItems)
            controller.modalPresentationStyle = .custom
            present(controller, animated: false)
        }
    }
}
