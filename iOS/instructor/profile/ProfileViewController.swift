//
//  ProfileViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/5.
//  Copyright © 2019年 spelist. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import Hero
import SafariServices
import SnapKit
import UIKit

class ProfileViewController: TKBaseViewController {
    private lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Profile", rightButton: UIImage(named: "message")!) { [weak self] in
        self?.toConversationListForSupportMessaging()
    }

    private var tableView: UITableView!
    private var user: TKUser?
    private var studio: TKStudio?
    private var lessonTypes: [TKLessonType] = []
    private var policiesData: TKPolicies?
    private var teacherInfoData: TKTeacher?
    private var isSetAccountHistroy = false
    private var showUnread: Bool = false
    private var isCouponUser: Bool = false
    private var couponName: String = ""
    var notificationData: TKNotificationConfig = TKNotificationConfig()
    private var instruments: [String: TKInstrument] = [:]

    private var studioEvents: [StudioEvent] = []

    private var updateTimer: Timer?

//    private var isInit: Bool = true

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadStudioInfo()
        checkBugReportUnreadData()
        getTeacherInfo()
        loadStudioEvents()
    }
}

extension ProfileViewController {
    override func bindEvent() {
        EventBus.listen(key: EventBus.Key.signOut, target: self) { [weak self] _ in
            self?.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }

        EventBus.listen(key: .teacherTeacherInfoChanged, target: self) { [weak self] _ in
            self?.teacherInfoData = ListenerService.shared.teacherData.teacherInfo
            self?.tableView.reloadData()
        }
        EventBus.listen(key: .systemEventsChanged, target: self) { [weak self] _ in
            self?.tableView?.reloadData()
        }
    }
}

extension ProfileViewController {
    private func toConversationListForSupportMessaging() {
        let controller = SupportConversationListViewController()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }
}

extension ProfileViewController {
    // MARK: - Data

    private func loadData() {
        guard Auth.auth().currentUser != nil else { return }
        if !UIApplication.shared.isRegisteredForRemoteNotifications {
            let count = SLCache.main.getInt(key: SLCache.SET_NOTIFICATION_PERMISSIONS_COUNT)
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                AppDelegate().setNotificationAuthority(count: count)
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.loadStudioInfo()
            self.loadLessonTypes()
            self.loadPolicies()
            self.getTeacherInfo()
            self.getNotificationData()
            self.getIsCouponUser()
            self.checkSupportMessagingPermission()
            self.loadStudioEvents()
        }
    }

    private func loadAllInstruments() {
        InstrumentService.shared.loadAllInstruments()
            .done { [weak self] instruments in
                guard let self = self else { return }
                instruments.forEach { instrument in
                    self.instruments[instrument.id.description] = instrument
                }
                self.tableView.reloadData()
            }
            .catch { error in
                logger.error("获取乐器失败: \(error)")
            }
    }

    private func checkBugReportUnreadData() {
        guard let userId = UserService.user.id() else {
            return
        }
        logger.debug("开始查询未读数量")
        DatabaseService.collections.bugReports()
            .whereField("userId", isEqualTo: userId)
            .whereField("reporterRead", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    logger.error("获取未读的文档失败: \(error)")
                } else {
                    if let docs = snapshot?.documents, docs.count > 0 {
                        self.showUnread = true
                    } else {
                        self.showUnread = false
                    }
                    self.tableView.reloadData()
                }
            }
    }

    override func initData() {
        loadAllInstruments()
        loadData()
        EventBus.listen(key: .refreshUserInfo, target: self) { [weak self] _ in
            self?.loadStudioInfo()
        }
        EventBus.listen(key: .refreshLessonType, target: self) { [weak self] _ in
            self?.loadLessonTypes()
        }
        EventBus.listen(key: .refreshPolicy, target: self) { [weak self] _ in
            self?.loadPolicies()
        }
        EventBus.listen(EventBus.CHANGE_MEMBER_LEVEL_ID, target: self) { [weak self] data in
            guard let self = self else { return }
            if let data: Bool = data!.object as? Bool {
                if data {
                    self.teacherInfoData?.memberLevelId = 2
                } else {
                    self.teacherInfoData?.memberLevelId = 1
                }
                self.tableView.reloadData()
                self.getIsCouponUser()
            }
        }
        EventBus.listen(key: .teacherReferralUseRecordChanged, target: self) { [weak self] _ in
            self?.tableView.reloadData()
        }
    }

    private func checkSupportMessagingPermission() {
        guard let user = ListenerService.shared.user else {
            return
        }
        let email = user.email

        guard email != "" else { return }
        Functions.functions().httpsCallable("checkSupportMessagingPermission")
            .call(["email": email]) { [weak self] funcResult, error in
                guard let self = self else { return }
                if let data = funcResult?.data as? [String: Any], let result = FuncResult.deserialize(from: data) {
                    logger.debug("检测消息权限结果: \(result)")
                    if result.code == 0, let hasPermission = result.data as? Bool {
                        if hasPermission {
                            self.navigationBar.showRightButton()
                        } else {
                            self.navigationBar.hiddenRightButton()
                        }
                    } else {
                        logger.error("返回结果不对")
                        self.navigationBar.hiddenRightButton()
                    }
                } else {
                    logger.error("获取权限失败: \(String(describing: error))")
                    self.navigationBar.hiddenRightButton()
                }
            }
    }

    private func getIsCouponUser() {
        guard let userId = UserService.user.id() else { return }
        addSubscribe(
            UserService.user.getCouponData(userId: userId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKCouponHistory] = []
                    for item in docs.documents {
                        if let doc = TKCouponHistory.deserialize(from: item.data()) {
                            data.append(doc)
                        }
                    }
                    let nowTime = Date().timeIntervalSince1970 * 1000
                    data.forEach { item in
                        if item.endTime > nowTime {
                            self.isCouponUser = true
                            self.couponName = item.couponName
                        } else {
                            self.isCouponUser = true
                            self.couponName = ""
                        }
                    }
                    logger.debug("=获取CouponHistory成功=====\(data.toJSONString(prettyPrint: true) ?? "")")

                }, onError: { err in
                    logger.debug("=获取CouponHistory失败=====\(err)")
                })
        )
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
                            if doc.createTime == "" {
                                setUpNotification()
                            } else {
                                isLoad = true
                                self.notificationData = doc
                                self.tableView.reloadData()
                            }
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
            addSubscribe(
                NotificationServer.instance.initTeacherNotificationConfig()
                    .subscribe(onNext: { _ in
                        logger.debug("======初始化Notification成功")

                    }, onError: { err in
                        logger.debug("初始化Notification失败:\(err)")
                    })
            )
        }
    }

    private func getTeacherInfo() {
        guard let userId = UserService.user.id() else {
            return
        }
        print(userId)
        addSubscribe(
            UserService.teacher.studentGetTeacherInfo(teacherId: userId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        self.teacherInfoData = data
                    }
                    if let data = data[false] {
                        self.teacherInfoData = data
                    }
                    self.tableView.reloadData()

                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func setAccountHistory() {
        // 此处需要判断是不是email登录
        guard !isSetAccountHistroy else { return }
        if let studio = studio, let user = user {
            isSetAccountHistroy = true
            var email = ""
            for item in user.loginMethod where item.method == .email {
                email = item.account
            }
            guard email != "" else { return }
            if SLCache.main.getString(key: SLCache.ACCOUNT_HISTORY) != "" {
                if let accountData = [TKAccountHistory].deserialize(from: SLCache.main.getString(key: SLCache.ACCOUNT_HISTORY)) {
                    var data: [TKAccountHistory] = []
                    if accountData.count > 0 {
                        var isHave = false
                        for item in accountData {
                            data.append(item!)
                            if item!.account.lowercased() == email.lowercased() {
                                isHave = true
                            }
                        }
                        if !isHave {
                            data.append(TKAccountHistory(id: studio.id, name: user.name, isTeacher: true, account: email.lowercased()))
                        }
                    } else {
                        data.append(TKAccountHistory(id: studio.id, name: user.name, isTeacher: true, account: email.lowercased()))
                    }
                    SLCache.main.set(key: SLCache.ACCOUNT_HISTORY, value: data.toJSONString() ?? "")
                }
            } else {
                let accountData: [TKAccountHistory] = [TKAccountHistory(id: studio.id, name: user.name, isTeacher: true, account: user.email)]
                SLCache.main.set(key: SLCache.ACCOUNT_HISTORY, value: accountData.toJSONString() ?? "")
            }
        }
    }

    private func loadPolicies() {
        addSubscribe(
            UserService.teacher.getPolicies()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        self.policiesData = data
                    }
                    if let data = data[false] {
                        self.policiesData = data
                    }
                    self.tableView.reloadData()
                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func loadStudioInfo() {
        navigationBar.startLoading()
        UserService.studio.getStudioInfo()
            .done { [weak self] studio in
                guard let self = self else { return }
                self.studio = studio
                SLCache.main.set(key: SLCache.STUDIO_NAME, value: studio.name)
                self.setAccountHistory()
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileUserInfoTableViewCell {
                    cell.loadData(user: self.user, studio: self.studio)
                }
                self.navigationBar.stopLoading()
            }
            .catch { [weak self] error in
                logger.error("获取studioinfo失败: \(error)")
                self?.navigationBar.stopLoading()
            }

        guard let userId = UserService.user.id() else {
            return
        }
        UserService.user.getUserInfo(id: userId)
            .done { [weak self] user in
                guard let self = self else { return }
                self.user = user
                self.setAccountHistory()
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileUserInfoTableViewCell {
                    cell.loadData(user: self.user, studio: self.studio)
                }
                self.navigationBar.stopLoading()
            }
            .catch { [weak self] error in
                logger.error("获取用户信息失败: \(error)")
                self?.navigationBar.stopLoading()
            }
    }

    private func loadLessonTypes() {
        addSubscribe(
            LessonService.lessonType.list()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        self.lessonTypes.removeAll()
                        for item in data where !item.deleted {
                            self.lessonTypes.append(item)
                        }
                    }
                    if let data = data[false] {
                        self.lessonTypes.removeAll()
                        for item in data where !item.deleted {
                            self.lessonTypes.append(item)
                        }
                    }
                    self.tableView.reloadData()
                })
        )
    }

    private func loadStudioEvents() {
        guard let teacherInfo = ListenerService.shared.teacherData.teacherInfo else { return }
        DatabaseService.collections.studioEvents()
            .whereField("studioId", isEqualTo: teacherInfo.studioId)
            .order(by: "startTime", descending: false)
            .limit(to: 3)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    logger.error("获取events失败: \(error)")
                } else {
                    if let events: [StudioEvent] = [StudioEvent].deserialize(from: snapshot?.documents.compactMap({ $0.data() })) as? [StudioEvent] {
                        self.studioEvents = events
                    } else {
                        self.studioEvents = []
                    }
                    self.tableView.reloadData()
                }
            }
    }
}

extension ProfileViewController {
    // MARK: - View

    override func initView() {
        initNavigationBar()
        initTableView()
    }

    private func initNavigationBar() {
        addSubview(view: navigationBar) { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.height.equalTo(44)
        }
        navigationBar.hiddenLeftButton()
        navigationBar.hiddenRightButton()

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.fourth)
            .alignment(alignment: .center)
            .text(text: "Profile")
        navigationBar.addSubview(view: titleLabel) { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(4)
        }
    }

    private func initTableView() {
        tableView = UITableView()
        addSubview(view: tableView) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.tableHeaderView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.showsVerticalScrollIndicator = false
//        tableView.estimatedRowHeight = 40
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileUserInfoTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileUserInfoTableViewCell.self))
        tableView.register(ProfileLessonTypesTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileLessonTypesTableViewCell.self))
        tableView.register(ProfileUpgradeProTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileUpgradeProTableViewCell.self))
        tableView.register(ProfilePoliciesTableViewCell.self, forCellReuseIdentifier: String(describing: ProfilePoliciesTableViewCell.self))
        tableView.register(ProfileSettingsTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileSettingsTableViewCell.self))
        tableView.register(ProfileNotificationCell.self, forCellReuseIdentifier: String(describing: ProfileNotificationCell.self))
        tableView.register(ProfileShakeToReportTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileShakeToReportTableViewCell.self))
        tableView.register(ProfileReferralProgramTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileReferralProgramTableViewCell.self))
        tableView.register(ProfileStudioEventsTableViewCell.self, forCellReuseIdentifier: ProfileStudioEventsTableViewCell.id)

        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 80))
        // 获取app信息
        guard let infoDictionary: Dictionary = Bundle.main.infoDictionary else { return }
        // 版本号
        guard let majorVersion: String = infoDictionary["CFBundleShortVersionString"] as? String else { return }
        // build号
        guard let minorVersion: String = infoDictionary["CFBundleVersion"] as? String else { return }
        let versionString = "Tunekey iOS version: \(majorVersion).\(minorVersion)"
        TKLabel.create()
            .text(text: versionString)
            .textColor(color: ColorUtil.Font.fourth)
            .font(font: FontUtil.medium(size: 13))
            .addTo(superView: footerView) { make in
                make.center.equalToSuperview()
            }

        tableView.tableFooterView = footerView
    }
}

extension ProfileViewController: ProfileUserInfoTableViewCellDelegate {
    func profileUserInfoTableViewCellTapped() {
        let controller = ProfileEditDetailViewController()
        controller.enablePanToDismiss()
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }
}

extension ProfileViewController: ProfileUpgradeProTableViewCellDelegate {
    func profileUpgradeProTableViewCellButtonTapped() {
        guard let teacherInfoData = teacherInfoData else { return }
        if let level = TKTeacher.MemberLevel(rawValue: teacherInfoData.memberLevelId) {
            ProfileUpgradeDetailViewController.show(level: level, target: self, isCouponUser: isCouponUser, couponName: couponName)
        }
    }
}

extension ProfileViewController: ProfileSettingsTableViewCellDelegate, VerifyPasswordViewControllerDelegate {
    func profileSettingsTableViewCellContactUsTapped() {
        let controller = ContactUsSelectorViewController()
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

    func profileSettingsTableViewCellFAQTapped() {
        CommonsWebViewViewController.show("https://www.tunekey.app/faq/mobile")
    }

    func profileSettingsTableViewCellCalendarTapped() {
//        TKToast.show(msg: "This feature has not yet been enabled.", style: .info)

        let controller = ProfileLinkCalendarViewController()
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func profileSettingsTableViewCellMergeAccountTapped() {
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

    func profileSettingsTableViewCellChangePasswordTapped() {
        let controller = ChangePasswordViewController()
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func profileSettingsTableViewCell(enableScreenLockChanged isOn: Bool) {
        if isOn {
            let controller = VerifyPasswordViewController()
            controller.delegate = self
            controller.verifyType = .local
            controller.hero.isEnabled = true
            controller.modalPresentationStyle = .fullScreen
            controller.hero.modalAnimationType = .selectBy(presenting: .pageIn(direction: .up), dismissing: .pageOut(direction: .down))
            present(controller, animated: true, completion: nil)
        } else {
            CacheUtil.UserInfo.setLocalAuthOpen(isOpen: false)
        }
    }

    func verifyPasswordViewControllerVerifySuccess() {
        CacheUtil.UserInfo.setLocalAuthOpen(isOpen: true)
    }

    func verifyPasswordViewControllerVerifyFailed() {
        CacheUtil.UserInfo.setLocalAuthOpen(isOpen: false)
    }
}

extension ProfileViewController: ProfilePoliciesTableViewCellDelegate {
    func profilePoliciesTableViewCellMakeupPolicyTapped() {
        guard let policiesData = policiesData else { return }
        SetPoliciesController.present(target: self, type: .reschedule, isEdit: true, data: policiesData)
    }

    func profilePoliciesTableViewCellCancellationPolicyTapped() {
        guard let policiesData = policiesData else { return }

        SetPoliciesController.present(target: self, type: .cancellation, isEdit: true, data: policiesData)
    }

    func profilePoliciesTableViewCellAvailabilityPolicyTapped() {
        guard let policiesData = policiesData else { return }
        if policiesData.allowReschedule {
            SetPoliciesController.present(target: self, type: .availability, isEdit: true, data: policiesData)
        } else {
            TKToast.show(msg: "Please set makeup policy first!", style: .warning)
        }
    }

    func profilePoliciesTableViewCellDescriptionPolicyTapped() {
        guard let policiesData = policiesData else { return }
        let controller = SetPoliciesDescriptionController()
        controller.isEdit = true

        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.data = policiesData
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)

        // MARK: - 签名页面

//        let controller = SignatureController()
//        controller.modalPresentationStyle = .fullScreen
//        controller.hero.isEnabled = true
//        controller.enablePanToDismiss()
//        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//        self.present(controller, animated: true, completion: nil)
    }
}

extension ProfileViewController: ProfileLessonTypesTableViewCellDelegate, ProfileNotificationCellDelegate {
    func profileNotification(reminderDataChanged data: [ProfileNotificationsReminderView.ReminderTime], isOn: Bool) {
        notificationData.reminderOpened = isOn
        let times: [Int] = data.compactMap {
            if $0.isSelected {
                return $0.value
            }
            return nil
        }
        notificationData.reminderTimes = times
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
            self.updateNotificationConfig(data: [
                "reminderTimes": times,
                "reminderOpened": isOn,
            ])
        })
    }

    func profileNotification(clickHomeworkReminder cell: ProfileNotificationCell) {
    }

    func profileNotification(select cell: ProfileNotificationCell, isOn: Bool, type: ProfileNotificationCell.ProfileNotificationType) {
        switch type {
        case .cancelLesson:
            updateNotificationConfig(data: ["cancelLessonNotificationOpened": isOn])
            break
        case .rescheduleConfirmed:
            updateNotificationConfig(data: ["rescheduleConfirmedNotificationOpened": isOn])
            break
        }
    }

    func profileLessonTypesTableViewCellMoreTapped() {
        let controller = LessonTypesViewController(style: .fullScreen)
        controller.from = .profile
        controller.data = lessonTypes
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func toReportListController() {
        DispatchQueue.global(qos: .background).async {
            StorageService.shared.uploadLogFile()
            StorageService.shared.uploadLocalDB()
        }
        let controller = ShowBugReportorListController()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }
}

extension ProfileViewController: ProfileReferralProgramTableViewCellDelegate {
    func profileReferralProgramTableViewCell(didTapped cell: ProfileReferralProgramTableViewCell) {
        let controller = ProfileReferralUsersViewController()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: - tableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileUserInfoTableViewCell.self), for: indexPath) as! ProfileUserInfoTableViewCell
            cell.loadData(user: user, studio: studio)
            cell.delegate = self
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileLessonTypesTableViewCell.self), for: indexPath) as! ProfileLessonTypesTableViewCell
            cell.delegate = self
            cell.loadData(data: lessonTypes, instruments: instruments)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProfileStudioEventsTableViewCell.id, for: indexPath) as! ProfileStudioEventsTableViewCell
            cell.tableView = tableView
            cell.events = studioEvents
            cell.onAddEventTapped = { [weak self] in
                guard let self = self else { return }
                let controller = StudioEventsAddNewViewController()
                controller.modalPresentationStyle = .fullScreen
                controller.hero.isEnabled = true
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                Tools.getTopViewController()?.present(controller, animated: true)
                controller.onEventCreated = { event in
                    self.studioEvents.insert(event, at: 0)
                    cell.events = self.studioEvents
                }
            }
            cell.onTitleViewTapped = {
                let controller = StudioEventsViewController()
                controller.modalPresentationStyle = .fullScreen
                controller.hero.isEnabled = true
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                Tools.getTopViewController()?.present(controller, animated: true)
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileUpgradeProTableViewCell.self), for: indexPath) as! ProfileUpgradeProTableViewCell
            cell.delegate = self
            if let teacherInfo = teacherInfoData {
                cell.initData(teacher: teacherInfo, event: ListenerService.shared.systemEvents.first)
            }
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfilePoliciesTableViewCell.self), for: indexPath) as! ProfilePoliciesTableViewCell
            if let policiesData = policiesData {
                cell.initData(data: policiesData)
            }
            cell.delegate = self
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileNotificationCell.self), for: indexPath) as! ProfileNotificationCell
            cell.tableView = tableView
            cell.initData(data: notificationData)
            cell.delegate = self
            return cell
        case 6:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileSettingsTableViewCell.self), for: indexPath) as! ProfileSettingsTableViewCell
            cell.delegate = self
            cell.loadData(data: user)
            cell.reportInfoLabel.onViewTapped { [weak self] _ in
                self?.toReportListController()
            }
            cell.shakeToReportView.onViewTapped { [weak self] _ in
                self?.toReportListController()
            }
            cell.showUnreadView(show: showUnread)
            return cell
        case 7:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileReferralProgramTableViewCell.self), for: indexPath) as! ProfileReferralProgramTableViewCell
            cell.loadData(users: ListenerService.shared.teacherData.referralUseRecord)
            cell.delegate = self
            return cell
        default:
            fatalError("Wrong index")
        }
    }
}
