//
//  StudentManagerViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/5.
//  Copyright © 2019年 spelist. All rights reserved.
//


import FirebaseDynamicLinks
import MessageUI
import SnapKit
import SwiftyBeaver
import SWXMLHash
import UIKit

class StudentsViewController: TKBaseViewController {
    enum Style {
        case noData
        case haveData
    }

    private lazy var titles = ["Inactive", "Active", "Archived"]
    private lazy var titleMap = [String: StudentsContentViewController]()

    private var pageViewManager: PageViewManager!

    var mainView = UIView()
    var navigationBarView = UIView()
    var navigationTitle = TKLabel()
    var navigationItemView = UIView()
//    var navigationEditButton = TKButton()
    var groupMessageButton: Button = Button().image(UIImage(named: "group_message")!.resizeImage(CGSize(width: 22, height: 22)), for: .normal)
    var navigationAddButton = TKButton()
    var navigationSearchButton = TKButton()

    var emptyView: UIView!
    var emptyImageView = UIImageView()
    var emptyLabel = TKLabel()
    var emptyButton = TKBlockButton()
    var emptyExampleStudentButton = TKLabel()

    var style: Style! = .noData
    var isEdit = false
    var isEnterListener = false
    weak var delegate: StudentsViewControllerDelegate?
    var studentDatas: [TKStudent] = []
    var usersInfo: [String: TKUser] = [:]
    var teacherMemberLevel: Int = 1 // 1是免费 2是收费用户

    // 底部按钮容器
    private var bottomView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.backgroundColor)

    lazy var archiveButtonForInactive: TKButton = TKButton.create()
        .titleColor(color: ColorUtil.main)
        .title(title: "Archive")
        .titleFont(font: FontUtil.bold(size: 18))
        .addTo(superView: bottomView) { make in
            make.width.equalTo(100)
            make.centerY.equalToSuperview()
            make.left.equalTo((UIScreen.main.bounds.width - 240) / 2)
            make.height.equalToSuperview()
        }

    lazy var deleteButtonForInactive: TKButton = TKButton.create()
        .titleColor(color: ColorUtil.red)
        .title(title: "Delete")
        .titleFont(font: FontUtil.bold(size: 18))
        .addTo(superView: bottomView) { make in
            make.width.equalTo(100)
            make.centerY.equalToSuperview()
            make.right.equalTo(-(UIScreen.main.bounds.width - 240) / 2)
            make.height.equalToSuperview()
        }

    lazy var archiveButtonForActive: TKButton = TKButton.create()
        .titleColor(color: ColorUtil.red)
        .title(title: "Archive")
        .titleFont(font: FontUtil.bold(size: 18))
        .addTo(superView: bottomView) { make in
            make.center.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalToSuperview()
        }

    lazy var deleteButtonForArchived: TKButton = TKButton.create()
        .titleColor(color: ColorUtil.red)
        .title(title: "Delete")
        .titleFont(font: FontUtil.bold(size: 18))
        .addTo(superView: bottomView) { make in
            make.center.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalToSuperview()
        }

    private var isFirstAppear: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        initEventBus()
        getStudent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.debug("所有的学生列表: \(studentDatas.toJSONString() ?? "")")
        checkBottomButtons(at: pageViewManager.titleView.currentIndex)
        studentDatas = ListenerService.shared.teacherData.studentList
        initStudentData()
    }
}

// MARK: - View

extension StudentsViewController {
    override func initView() {
        mainView.backgroundColor = ColorUtil.backgroundColor
        view.addSubviews(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.addSubviews(navigationBarView)
        initNavigationBarView()
        initContentView(style: .haveData)

        view.addSubview(bottomView)
        let height = (tabBarController?.tabBar.frame ?? .zero).height
        bottomView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(height)
        }

        archiveButtonForInactive.isHidden = true
        deleteButtonForInactive.isHidden = true

        archiveButtonForActive.isHidden = true

        deleteButtonForArchived.isHidden = true

        archiveButtonForInactive.onTapped { [weak self] _ in
            self?.onArchiveButtonTapped()
        }
        deleteButtonForInactive.onTapped { [weak self] _ in
            self?.onDeleteButtonTapped()
        }
        archiveButtonForActive.onTapped { [weak self] _ in
            self?.onArchiveButtonTapped()
        }
        deleteButtonForArchived.onTapped { [weak self] _ in
            self?.onDeleteButtonTapped()
        }
//        pageViewManager.titleView.contentView(pageViewManager.contentView, scrollingWith: pageViewManager.titleView.currentIndex, targetIndex: 1, progress: 1)
//        pageViewManager.contentView.titleView(pageViewManager.titleView, didSelectAt: 1)
//        pageViewManager.titleView.currentIndex = 1
//        pageViewManager.contentView.currentIndex = 1
//        checkBottomButtons(at: 1)
    }

    func initContentView(style: Style) {
        self.style = style
        switch style {
        case .noData:
            initEmptyView()
        case .haveData:
            initPageView()
        }
    }

    private func initNavigationBarView() {
        navigationBarView.addSubviews(navigationTitle, navigationAddButton, navigationSearchButton)
        navigationBarView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }
        navigationTitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(4)
        }
        navigationTitle.font(font: FontUtil.bold(size: 18)).alignment(alignment: .center).textColor(color: ColorUtil.Font.fourth).text("Students")
//        navigationEditButton.title(title: "")
//        navigationEditButton.setImage(name: "edit_new", size: CGSize(width: 22, height: 22))
        _ = navigationAddButton.setImage(name: "icAddPrimary")
        _ = navigationSearchButton.setImage(name: "search_primary")
//        navigationEditButton.titleFont(FontUtil.bold(size: 13))
//        navigationEditButton.titleColor(ColorUtil.main)
//        navigationEditButton.snp.makeConstraints { make in
//            make.centerY.equalToSuperview().offset(4)
//            make.height.equalTo(32)
//            make.left.equalToSuperview().offset(21)
//        }
        groupMessageButton.addTo(superView: navigationBarView) { make in
            make.centerY.equalToSuperview().offset(4)
            make.height.equalTo(32)
            make.left.equalToSuperview().offset(21)
        }
        navigationSearchButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview().offset(4)
            make.size.equalTo(22)
        }

        navigationAddButton.snp.makeConstraints { make in
            make.right.equalTo(navigationSearchButton.snp.left).offset(-20)
            make.centerY.equalToSuperview().offset(4)
            make.size.equalTo(22)
        }

//        navigationEditButton.onTapped { [weak self] _ in
//            guard let self = self else { return }
//            self.clickEditButton()
//        }
        navigationAddButton.onTapped { [weak self] _ in
            guard let self = self else { return }

            if self.teacherMemberLevel == 1 {
                if self.studentDatas.count < FreeResources.maxStudentsCount {
                    self.clickAddStudent()
                } else {
                    ProfileUpgradeDetailViewController.show(level: .normal, target: self)
                }
            } else {
                self.clickAddStudent()
            }
//            self.clickAddStudent()
        }
        navigationSearchButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.clickSearchButton()
        }
        groupMessageButton.onTapped { [weak self] _ in
            self?.onGroupMessageTapped()
        }
    }

    private func initEmptyView() {
        navigationAddButton.isHidden = true
        navigationSearchButton.isHidden = true
//        navigationEditButton.isHidden = true
        if emptyView != nil {
            emptyView.isHidden = false
        } else {
            emptyView = UIView()
            mainView.addSubview(emptyView)
            emptyView.addSubviews(emptyImageView, emptyLabel, emptyButton, emptyExampleStudentButton)
            emptyView.snp.makeConstraints { make in
                make.top.equalTo(navigationBarView.snp.bottom).offset(51)
                make.left.equalToSuperview().offset(0)
                make.right.equalToSuperview().offset(0)
                make.bottom.equalToSuperview()
            }
            emptyImageView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.centerX.equalToSuperview()
                make.width.equalTo(300)
                make.height.equalTo(200)
            }
            emptyLabel.snp.makeConstraints { make in
                make.top.equalTo(emptyImageView.snp.bottom).offset(30)
                make.left.equalTo(30)
                make.right.equalTo(-30)
                make.centerX.equalToSuperview()
            }
            emptyButton.snp.makeConstraints { make in
                if UIScreen.main.bounds.height > 670 {
                    make.top.equalTo(emptyLabel.snp.bottom).offset(120)
                } else {
                    make.top.equalTo(emptyLabel.snp.bottom).offset(65)
                }
                make.height.equalTo(50)
                make.width.equalTo(200)
                make.centerX.equalToSuperview()
            }
            emptyExampleStudentButton.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(emptyButton.snp.bottom).offset(20)
            }
            emptyExampleStudentButton.textColor(color: ColorUtil.main).alignment(alignment: .center).font(font: FontUtil.bold(size: 16)).text("Add \"test\" student")

            emptyImageView.image = UIImage(named: "imgNostudents")
            emptyLabel.textColor(color: ColorUtil.Font.primary).alignment(alignment: .center).font(font: FontUtil.bold(size: 16)).text("Add your students in minutes.\nIt's easy, we promise!")
            emptyLabel.numberOfLines = 0
            emptyLabel.changeLabelRowSpace(lineSpace: 0.8, wordSpace: 0.89)
            emptyButton.setTitle(title: "ADD STUDENT")
            emptyButton.onTapped { [weak self] _ in
                self?.clickAddStudent()
            }
            emptyExampleStudentButton.onViewTapped { [weak self] _ in
                self?.clickAddExampleStudent()
            }
        }
        if pageViewManager != nil {
            pageViewManager.contentView.isHidden = true
            pageViewManager.titleView.isHidden = true
        }
    }

    private func initPageView() {
        navigationAddButton.isHidden = false
        navigationSearchButton.isHidden = false
//        navigationEditButton.isHidden = false
        if pageViewManager == nil {
            // 创建DNSPageStyle，设置样式
            let style = PageStyle()
            style.isShowBottomLine = true
            style.isTitleViewScrollEnabled = false
            style.titleViewBackgroundColor = UIColor.clear
            style.titleColor = ColorUtil.Font.primary
            style.titleSelectedColor = ColorUtil.main
            style.bottomLineColor = ColorUtil.main
            style.bottomLineWidth = 17
            style.titleFont = FontUtil.bold(size: 15)

            for item in titles.enumerated() {
                let controller = StudentsContentViewController()
                controller.studentsControllerStatus = .normal
                controller.index = item.offset
                controller.delegate = self
                titleMap[item.element] = controller
                addChild(controller)
            }

            pageViewManager = PageViewManager(style: style, titles: titles, childViewControllers: children)
            let titleView = pageViewManager.titleView
            titleView.clickHandler = { [weak self] _, index in
                logger.debug("点击标题: \(index)")
                self?.checkBottomButtons(at: index)
            }
            mainView.addSubviews(titleView)
            titleView.snp.makeConstraints { make in
                make.top.equalTo(navigationBarView.snp.bottom).offset(10)
                make.width.equalTo(247)
                make.centerX.equalToSuperview()
                make.height.equalTo(24)
            }

            let contentView = pageViewManager.contentView
            contentView.scrollDelegate = self
            mainView.addSubview(pageViewManager.contentView)
            contentView.snp.makeConstraints { maker in
                maker.top.equalTo(titleView.snp.bottom).offset(10)
                maker.left.right.bottom.equalToSuperview()
            }
        } else {
            pageViewManager.contentView.isHidden = false
            pageViewManager.titleView.isHidden = false
        }
        if emptyView != nil {
            emptyView.isHidden = true
        }
    }
}

// MARK: - Data

extension StudentsViewController {
    func initEventBus() {
        getTeacherInfo()
        EventBus.listen(key: .refreshStudents, target: self) { [weak self] _ in
            self?.initData()
        }
        EventBus.listen(EventBus.CHANGE_MEMBER_LEVEL_ID, target: self) { [weak self] data in
            guard let self = self else { return }
            if let data: Bool = data!.object as? Bool {
                if data {
                    self.teacherMemberLevel = 2
                } else {
                    self.teacherMemberLevel = 1
                }
                if self.studentDatas.count != 0 {
                    self.titleMap["Active"]?.initMemberLevel(totalStudentCont: self.studentDatas.count)
                    self.titleMap["Inactive"]?.initMemberLevel(totalStudentCont: self.studentDatas.count)
                    self.titleMap["Archived"]?.initMemberLevel(totalStudentCont: self.studentDatas.count)
                }

                self.initUserInfo()
            }
        }
    }

    func getTeacherInfo() {
        guard let id = UserService.user.id() else { return }
        addSubscribe(
            UserService.teacher.studentGetTeacherInfo(teacherId: id)
                .subscribe(onNext: { data in
                    self.hideFullScreenLoading()
                    if let data = data[false] {
                        self.teacherMemberLevel = data.memberLevelId
                        self.initUserInfo()
                    }
                    if let data = data[true] {
                        self.teacherMemberLevel = data.memberLevelId
                        self.initUserInfo()
                    }
                }, onError: { err in
                    self.hideFullScreenLoading()
                    self.initUserInfo()
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func initUserInfo() {
        for item in titleMap {
            item.value.teacherMemberLevel = teacherMemberLevel
        }
    }

    override func initData() {
        logger.debug("--------开始获取学生列表--------")
//        getStudentData()
        initListener()
    }

    // 此处这个方法是为了防止老师第一次注册 登录时 没有走到监听而设置的一个方法
    func getStudent() {
        if !isEnterListener {
            addSubscribe(
                UserService.student.getStudentList()
                    .subscribe(onNext: { [weak self] data in
                        guard let self = self else { return }
                        if let cacheData = data[true] {
                            self.studentDatas = cacheData
                            SLCache.main.set(key: SLCache.STUDENT_LIST, value: cacheData.toJSONString() ?? "")
                        }

                        if let serverData = data[false] {
                            self.studentDatas = serverData
                            SLCache.main.set(key: SLCache.STUDENT_LIST, value: serverData.toJSONString() ?? "")
                        }
                        print("====getStudent\(self.studentDatas.count)")
                        if self.studentDatas.count > 0 {
                            self.initContentView(style: .haveData)
                            self.initStudentData()
                        } else {
                            self.initContentView(style: .noData)
                        }

                    }, onError: { [weak self] err in
                        guard let self = self else { return }
                        logger.debug("====err==\(err)")
                        if self.studentDatas.count > 0 {
                            self.initContentView(style: .haveData)
                            self.initStudentData()
                        } else {
                            self.initContentView(style: .noData)
                        }
                    })
            )
        }
    }

    private func initListener() {
        EventBus.listen(key: .teacherStudentListChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            logger.debug("监听到教师的学生列表发生更改,获取到的数据: \(ListenerService.shared.teacherData.studentList.toJSONString() ?? "")")
            self.isEnterListener = true
            self.studentDatas = ListenerService.shared.teacherData.studentList
            SLCache.main.set(key: SLCache.STUDENT_LIST, value: self.studentDatas.toJSONString() ?? "")
            if self.studentDatas.count > 0 {
                self.initContentView(style: .haveData)
                self.initStudentData()
            } else {
                self.initContentView(style: .noData)
            }
            self.getUsersInfomation()
        }
    }

    func getStudentData(isOnlyOnline: Bool = true) {
        addSubscribe(
            UserService.student.getStudentList()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if isOnlyOnline {
                        if let cacheData = data[true] {
                            self.studentDatas = cacheData
                            SLCache.main.set(key: SLCache.STUDENT_LIST, value: cacheData.toJSONString() ?? "")
                        }
                    }
                    if let serverData = data[false] {
                        self.studentDatas = serverData
                        SLCache.main.set(key: SLCache.STUDENT_LIST, value: serverData.toJSONString() ?? "")
                    }
                    logger.debug("获取到学生的信息: \(self.studentDatas.toJSONString() ?? "")")
                    self.getUsersInfomation()
                    if self.studentDatas.count > 0 {
                        self.initContentView(style: .haveData)
                        self.initStudentData()
                    } else {
                        self.initContentView(style: .noData)
                    }

                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    logger.debug("====err==\(err)")
                    if self.studentDatas.count > 0 {
                        self.initContentView(style: .haveData)
                        self.initStudentData()
                    } else {
                        self.initContentView(style: .noData)
                    }
                })
        )
    }

    private func getUsersInfomation() {
        logger.debug("开始获取学生的用户信息: \(studentDatas.toJSONString() ?? "")")
        guard !studentDatas.isEmpty else { return }
        logger.debug("要获取的学生信息: \(studentDatas.toJSONString() ?? "")")
        UserService.user.getUserList(userIds: studentDatas.compactMap({ $0.studentId }))
            .done { [weak self] usersMap in
                guard let self = self else { return }
                logger.debug("获取到的用户数据: \(usersMap.keys.count)")
                self.studentDatas.forEachItems { student, index in
                    if let user = usersMap[student.studentId] {
                        self.studentDatas[index].userInfo = user
                    }
                }
                self.usersInfo = usersMap
                logger.debug("获取用户数据之后的信息: \(self.studentDatas.compactMap({ $0.userInfo }).toJSONString() ?? "")")
                self.initStudentData()
            }
            .catch { error in
                logger.error("获取用户失败:\(error)")
            }
    }

    func initStudentData() {
        var activeStudentData: [TKStudent] = []
        var inactiveStudentData: [TKStudent] = []
        var archivedStudentData: [TKStudent] = []
        for item in studentDatas {
            switch item.invitedStatus {
            case .none:
                if item.lessonTypeId != "" {
                    activeStudentData.append(item)
                } else {
                    inactiveStudentData.append(item)
                }
            case .sentPendding, .confirmed, .rejected:
                activeStudentData.append(item)
            case .archived:
                archivedStudentData.append(item)
            }
        }
        for (i, student) in activeStudentData.enumerated() {
            if let user = usersInfo[student.studentId] {
                activeStudentData[i].userInfo = user
            }
        }
        for (i, student) in inactiveStudentData.enumerated() {
            if let user = usersInfo[student.studentId] {
                inactiveStudentData[i].userInfo = user
            }
        }
        for (i, student) in archivedStudentData.enumerated() {
            if let user = usersInfo[student.studentId] {
                archivedStudentData[i].userInfo = user
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.titleMap["Active"]?.initStudentData(studentDatas: activeStudentData, users: self.usersInfo)
            self.titleMap["Inactive"]?.initStudentData(studentDatas: inactiveStudentData, users: self.usersInfo)
            self.titleMap["Archived"]?.initStudentData(studentDatas: archivedStudentData, users: self.usersInfo)
            self.titleMap["Active"]?.initMemberLevel(totalStudentCont: self.studentDatas.count)
            self.titleMap["Inactive"]?.initMemberLevel(totalStudentCont: self.studentDatas.count)
            self.titleMap["Archived"]?.initMemberLevel(totalStudentCont: self.studentDatas.count)
        }
        guard studentDatas.count > 0 else { return }
        guard isFirstAppear else {
            return
        }
        isFirstAppear = false
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if activeStudentData.count > 0 {
                self.pageViewManager.titleView.contentView(self.pageViewManager.contentView, scrollingWith: self.pageViewManager.titleView.currentIndex, targetIndex: 1, progress: 1)
                self.pageViewManager.contentView.titleView(self.pageViewManager.titleView, didSelectAt: 1)
                self.pageViewManager.titleView.currentIndex = 1
                self.pageViewManager.contentView.currentIndex = 1
                self.checkBottomButtons(at: 1)
            } else if inactiveStudentData.count > 0 {
                self.pageViewManager.titleView.contentView(self.pageViewManager.contentView, scrollingWith: self.pageViewManager.titleView.currentIndex, targetIndex: 0, progress: 1)
                self.pageViewManager.contentView.titleView(self.pageViewManager.titleView, didSelectAt: 0)
                self.pageViewManager.titleView.currentIndex = 0
                self.pageViewManager.contentView.currentIndex = 0
                self.checkBottomButtons(at: 0)
            } else if archivedStudentData.count > 0 {
                self.pageViewManager.titleView.contentView(self.pageViewManager.contentView, scrollingWith: self.pageViewManager.titleView.currentIndex, targetIndex: 2, progress: 1)
                self.pageViewManager.contentView.titleView(self.pageViewManager.titleView, didSelectAt: 2)
                self.pageViewManager.titleView.currentIndex = 2
                self.pageViewManager.contentView.currentIndex = 2
                self.checkBottomButtons(at: 2)
            }
        }
    }
}

// MARK: - Action

extension StudentsViewController: NewStudentViewControllerDelegate {
    func newStudentViewControllerAddNewStudentRefData(email: String, name: String, phone: String) {
    }

    func newStudentViewControllerAddNewStudentCompletion(isExampleStudent: Bool, email: String) {
        pageViewManager.titleView.contentView(pageViewManager.contentView, scrollingWith: pageViewManager.titleView.currentIndex, targetIndex: 1, progress: 1)
        pageViewManager.contentView.titleView(pageViewManager.titleView, didSelectAt: 0)
        pageViewManager.titleView.currentIndex = 0
        pageViewManager.contentView.currentIndex = 0
        checkBottomButtons(at: 0)
        if isExampleStudent {
            titleMap["Inactive"]?.exampleStudentToAddLessonDetailController(email: email)
        }
    }

    func clickAddExampleStudent() {
        var isLoad = false
        showFullScreenLoadingNoAutoHide()
        addSubscribe(
            UserService.user.getInfo()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    logger.debug("======\(data)")
                    if let data = data[true] {
                        self.hideFullScreenLoading()
                        isLoad = true
                        let controller = NewStudentViewController()
                        controller.delegate = self
                        controller.isExampleStudent = true
                        controller.exampleEmail = data.email
                        controller.modalPresentationStyle = .custom
                        self.present(controller, animated: false, completion: nil)
                    }
                    if !isLoad {
                        if let data = data[false] {
                            self.hideFullScreenLoading()
                            let controller = NewStudentViewController()
                            controller.delegate = self
                            controller.isExampleStudent = true
                            controller.exampleEmail = data.email
                            controller.modalPresentationStyle = .custom
                            self.present(controller, animated: false, completion: nil)
                        }
                    }

                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }
}

extension StudentsViewController: PageContentViewScrollDelegate {
    func contentView(_ contentView: PageContentView, didSelectedAt index: Int) {
        checkBottomButtons(at: index)
    }

    private func checkBottomButtons(at index: Int) {
        archiveButtonForInactive.isHidden = true
        deleteButtonForInactive.isHidden = true

        archiveButtonForActive.isHidden = true

        deleteButtonForArchived.isHidden = true
        let title = titles[index]
        guard let controller = titleMap[title] else { return }
        let hasData = controller.studentDatas.count > 0 && controller.getSelectedData().count > 0
        switch index {
        case 0:
            archiveButtonForInactive.isHidden = false
            deleteButtonForInactive.isHidden = false
            archiveButtonForInactive.isEnabled = hasData
            deleteButtonForInactive.isEnabled = hasData
            archiveButtonForInactive.titleColor(hasData ? ColorUtil.main : ColorUtil.Font.fourth)
            deleteButtonForInactive.titleColor(hasData ? ColorUtil.red : ColorUtil.Font.fourth)
        case 1:
            archiveButtonForActive.isHidden = false
            archiveButtonForActive.isEnabled = hasData
            archiveButtonForActive.titleColor(hasData ? ColorUtil.red : ColorUtil.Font.fourth)
        default:
            deleteButtonForArchived.isHidden = false
            deleteButtonForArchived.isEnabled = hasData
            deleteButtonForArchived.titleColor(hasData ? ColorUtil.red : ColorUtil.Font.fourth)
        }
    }
}

extension StudentsViewController: StudentsContentViewControllerDelegate {
    func studentsContentViewController(selectedStudentChanged students: [TKStudent], atIndex index: Int) {
        checkBottomButtons(at: index)
    }
}

// MARK: - 底部按钮的点击

extension StudentsViewController {
    private func onArchiveButtonTapped() {
//        SL.Alert.show(target: self, title: "", message: "Are you sure to Archive this student?", leftButttonString: "GO BACK", rightButtonString: "ARCHIVE", leftButtonAction: {
//        }) { [weak self] in
//            self?.clickBottomButtonReturn(isDelete: false)
//        }
        SL.Alert.show(target: self, title: "", message: "Are you sure to Archive this student?", leftButttonString: "ARCHIVE", rightButtonString: "GO BACK", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
            self?.clickBottomButtonReturn(isDelete: false)

        }) {
        }
    }

    private func onDeleteButtonTapped() {
        logger.debug("======点击Delete")
//        SL.Alert.show(target: self, title: "", message: "Are you sure to delete this student? ", leftButttonString: "GO BACK", rightButtonString: "DELETE", leftButtonAction: {
//        }) { [weak self] in
//            self?.clickBottomButtonReturn(isDelete: true)
//        }
        SL.Alert.show(target: self, title: "", message: "Are you sure to delete this student?", leftButttonString: "DELETE", rightButtonString: "GO BACK", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
            self?.clickBottomButtonReturn(isDelete: true)

        }) {
        }
    }
}

extension StudentsViewController {
    func clickSearchButton() {
        StudentSearchController.present(target: self, students: studentDatas)
    }

    func clickAddStudent() {
        TKPopAction.show(
            items: TKPopAction.Item(title: "New student", action: { [weak self] in
                guard let self = self else { return }
                let controller = NewStudentViewController()
                controller.delegate = self
                controller.modalPresentationStyle = .custom
                self.present(controller, animated: false, completion: nil)
            }),
            TKPopAction.Item(title: "Google contacts", action: { [weak self] in
                guard let self = self else { return }
                let controller = AddressBookViewController()
                controller.showType = .googleContact
                controller.hero.isEnabled = true
                controller.modalPresentationStyle = .fullScreen
                controller.enablePanToDismiss()
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                self.present(controller, animated: true, completion: nil)
            }),
            TKPopAction.Item(title: "Device contacts", action: { [weak self] in
                guard let self = self else { return }
                let controller = AddressBookViewController()
                controller.showType = .addressBook
                controller.hero.isEnabled = true
                controller.modalPresentationStyle = .fullScreen
                controller.enablePanToDismiss()
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                self.present(controller, animated: true, completion: nil)
            }),
            TKPopAction.Item(title: "Get invite link", action: { [weak self] in
                guard let self = self else { return }
                self.showFullScreenLoading()
                CommonsService.shared.getTeacherInviteLink(teacherId: UserService.user.id() ?? "") { originalUrl, shortUrl in
                    self.hideFullScreenLoading()
                    if let url = shortUrl {
                        self.showInviteAlert(urlString: url)
                    } else {
                        self.showInviteAlert(urlString: originalUrl)
                    }
                }
            }),
            isCancelShow: true, target: self)
    }

    func showInviteAlert(urlString: String) {
        let controller = StudentsInviteLinkViewController(url: urlString)
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
//        let controller = InviteLinkAlert()
//        controller.modalPresentationStyle = .custom
//        controller.isClickBackgroundHiden = false
//
//        controller.titleString = "Invite link for students"
//        controller.infoString = "Here is your studio's unique invite link.\nSend it to your students for automatic in-app registration."
//        controller.rightButtonColor = ColorUtil.main
//        controller.leftButtonColor = ColorUtil.main
//        controller.rightButtonString = "COPY TO CLIPBOARD"
//        controller.leftButtonString = MFMessageComposeViewController.canSendText() ? "TEXT TO STUDENTS" : "GO BACK"
//        controller.centerButtonString = "EMAIL THIS LINK TO ME"
//
//        controller.leftButtonAction = { [weak self] in
//            if MFMessageComposeViewController.canSendText() {
//                self?.sendInviteLinkViaText(url: urlString)
//            }
//        }
//
//        controller.rightButtonAction = {
        ////                    guard let self = self else { return }
//            TKToast.show(msg: "Copy Successful!")
//
//            UIPasteboard.general.string = urlString
//        }
//        controller.centerButtonAction = {
//            [weak self] in
//            guard let self = self else { return }
//            self.showFullScreenLoading()
//
//            self.addSubscribe(
//                CommonsService.shared.sendEmailToUser(uId: UserService.user.id() ?? "tunekey", url: urlString)
//                    .subscribe(onNext: { [weak self] _ in
//                        self?.hideFullScreenLoading()
//                        TKToast.show(msg: "Email send Successful!")
//                        logger.debug("====发送成功==")
//
//                    }, onError: { err in
//                        logger.debug("==发送失败====\(err)")
//                    })
//            )
//        }
//        controller.messageString = urlString
//        controller.buttonTwoLine = true
//        present(controller, animated: false, completion: nil)
//        controller.messageLabel.onViewTapped { _ in
//            if let url = URL(string: urlString) {
//                // 根据iOS系统版本，分别处理
//                if #available(iOS 10, *) {
//                    UIApplication.shared.open(url, options: [:],
//                                              completionHandler: {
//                                                  _ in
//                                              })
//                } else {
//                    UIApplication.shared.openURL(url)
//                }
//            }
//        }
    }

//    func clickEditButton() {
//        isEdit.toggle()
//        let height = (tabBarController?.tabBar.frame ?? .zero).height
//        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
    ////            self.tabBarController?.tabBar.transform = self.isEdit ? CGAffineTransform(translationX: 0, y: height) : .identity
//            self.bottomView.transform = self.isEdit ? CGAffineTransform(translationX: 0, y: -height) : .identity
//            self.tabBarController?.tabBar.alpha = self.isEdit ? 0 : 1
//        }, completion: nil)
//
//        for item in titleMap {
//            item.value.clickEdit()
//        }
//        if isEdit {
//            navigationEditButton.title(title: "Cancel")
//            navigationEditButton.setImageNil()
//            navigationSearchButton.isHidden = true
//            navigationAddButton.isHidden = true
//        } else {
//            navigationEditButton.title(title: "")
//            navigationEditButton.setImage(name: "edit_new", size: CGSize(width: 22, height: 22))
//            navigationSearchButton.isHidden = false
//            navigationAddButton.isHidden = false
//        }
//    }

    func clickBottomButtonReturn(isDelete: Bool) {
        // 确认弹窗
        isEdit = false
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
//            self.tabBarController?.tabBar.transform = .identity
            self.tabBarController?.tabBar.alpha = 1
            self.bottomView.transform = .identity
        }, completion: nil)
        for item in titleMap {
            item.value.clickEdit()
        }
        if isEdit {
//            navigationEditButton.title(title: "Cancel")
//            navigationEditButton.setImageNil()
            //            pageViewManager.contentView.collectionView.isScrollEnabled = false
            navigationSearchButton.isHidden = true
            navigationAddButton.isHidden = true
        } else {
//            navigationEditButton.title(title: "")
//            navigationEditButton.setImage(name: "edit_new", size: CGSize(width: 22, height: 22))

            //            pageViewManager.contentView.collectionView.isScrollEnabled = true
            navigationSearchButton.isHidden = false
            navigationAddButton.isHidden = false
        }

        var selectedData: [TKStudent] = []
        switch pageViewManager.titleView.currentIndex {
        case 1:
            selectedData = titleMap["Active"]?.getSelectedData() ?? []
        case 0:
            selectedData = titleMap["Inactive"]?.getSelectedData() ?? []
        default:
            selectedData = titleMap["Archived"]?.getSelectedData() ?? []
        }
        print("=====选中的页数\(pageViewManager.titleView.currentIndex)=\(selectedData.count)")
        if selectedData.count == 0 {
            return
        }
        var ids: [String] = []
        for item in selectedData {
            ids.append(item.studentId)
        }
        showFullScreenLoadingNoAutoHide()
        if isDelete {
            addSubscribe(
                UserService.student.delete(studentIds: ids)
//                    .timeout(RxTimeInterval.seconds(30), scheduler: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        logger.debug("======成功")
                        self.hideFullScreenLoading()
                        self.getStudentData(isOnlyOnline: true)
                        self.refreshStudent(isRightButton: isDelete, ids: ids)
                        EventBus.send(EventBus.CHANGE_SCHEDULE_ONLINE)
                    }, onError: { [weak self] err in
                        guard let self = self else { return }

                        self.hideFullScreenLoading()
                        TKToast.show(msg: "Failed to delete, please try again later.", style: .warning)
                        logger.debug("======失败\(err)")
                    })
            )
        } else {
            addSubscribe(
                UserService.student.archive(studentIds: ids)
//                    .timeout(RxTimeInterval.seconds(30), scheduler: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        logger.debug("======成功")
                        self.getStudentData(isOnlyOnline: true)
                        self.refreshStudent(isRightButton: isDelete, ids: ids)
                        self.hideFullScreenLoading()

                        EventBus.send(EventBus.CHANGE_SCHEDULE_ONLINE)
                    }, onError: { [weak self] err in
                        guard let self = self else { return }
                        TKToast.show(msg: "Failed to archive, please try again later.", style: .warning)
                        self.hideFullScreenLoading()
                        logger.debug("======失败\(err)")
                    })
            )
        }
    }

    func refreshStudent(isRightButton: Bool, ids: [String]) {
        for selectItem in ids {
            for studentItem in studentDatas.enumerated().reversed() {
                if selectItem == studentItem.element.studentId {
                    if isRightButton {
                        studentDatas.remove(at: studentItem.offset)
                    } else {
                        studentDatas[studentItem.offset].invitedStatus = .archived
                        logger.debug(studentDatas.toJSONString(prettyPrint: true) ?? "")
                    }
                }
            }
        }
        SLCache.main.set(key: SLCache.STUDENT_LIST, value: studentDatas.toJSONString() ?? "")

        logger.debug(studentDatas.toJSONString(prettyPrint: true) ?? "")
        if studentDatas.count > 0 {
            initContentView(style: .haveData)
            initStudentData()
        } else {
            initContentView(style: .noData)
        }
    }
}

extension StudentsViewController: MFMessageComposeViewControllerDelegate, AddressBookViewControllerDelegate {
    func addressBookViewController(_ controller: AddressBookViewController, backTappedWithId id: String) {
    }

    func addressBookViewController(_ controller: AddressBookViewController, selectedLocalContacts: [LocalContact], userInfo: [String: Any]) {
        guard selectedLocalContacts.count > 0, let url = userInfo["url"] as? String else { return }
        showFullScreenLoading()
        UserService.studio.getStudioInfo()
            .done { [weak self] studio in
                guard let self = self else { return }
                print("获取到studio: \(studio.toJSONString() ?? "")")
                self.hideFullScreenLoading()
                let controller = MFMessageComposeViewController()
                controller.messageComposeDelegate = self
                controller.recipients = selectedLocalContacts.compactMap { $0.phone }
                var string = ""
                if studio.name != "" {
                    string = "[\(studio.name)] "
                }
                string += "Hey, check out TuneKey, great app to learn music. \(url)"
                controller.body = string
                self.present(controller, animated: true, completion: nil)
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                logger.error("获取studio数据出错: \(error)")
                let controller = MFMessageComposeViewController()
                controller.messageComposeDelegate = self
                controller.recipients = selectedLocalContacts.compactMap { $0.phone }
                controller.body = "Hey, check out TuneKey, great app to learn music. \(url)"
                self.present(controller, animated: true, completion: nil)
            }
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
        switch result {
        case .cancelled:
            TKToast.show(msg: "Cancelled", style: .info)
        case .sent:
            TKToast.show(msg: "Successfully", style: .success)
        case .failed:
            TKToast.show(msg: TipMsg.failed, style: .error)
        @unknown default:
            break
        }
    }

    func sendInviteLinkViaText(url: String) {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        let addressBookController = AddressBookViewController()
        addressBookController.showType = .addressBook
        addressBookController.justSelection = true
        addressBookController.userInfo["url"] = url
        addressBookController.delegate = self
        present(addressBookController, animated: true, completion: nil)

//        let controller = MFMessageComposeViewController()
//        controller.messageComposeDelegate = self
//        controller.recipients = []
//        controller.body = "Hey, check out TuneKey, Great app for learning music. \(url)"
//        present(controller, animated: true, completion: nil)
    }
}

extension StudentsViewController {
    private func onGroupMessageTapped() {
        // 获取groupMessage
        guard let studioId = ListenerService.shared.teacherData.teacherInfo?.studioId, let user = ListenerService.shared.user else { return }
        showFullScreenLoadingNoAutoHide()
        akasync { [weak self] in
            guard let self = self else { return }
            do {
                let conversation = try akawait(ChatService.conversation.get(studioId))
                if let conversation = conversation {
                    self.showMessageViewController(conversation)
                } else {
                    // 没有获取到会话,直接创建
                    // 获取所有的学生
                    var userMap: [String: Bool] = [user.userId: true]
                    var users: [TKConversationUser] = [TKConversationUser(conversationId: studioId, userId: user.userId, nickname: user.name, unreadMessageCount: 0)]
                    for student in ListenerService.shared.teacherData.studentList {
                        userMap[student.studentId] = true
                        users.append(TKConversationUser(conversationId: studioId, userId: student.studentId, nickname: student.name, unreadMessageCount: 0))
                    }
                    let now = Date().timeIntervalSince1970
                    let conversation = TKConversation(id: studioId, title: "Community", type: ConversationType.group, creatorId: user.userId, userMap: userMap, users: users, isFull: false, latestMessageId: "", latestMessageTimestamp: 0, latestMessage: nil, isPinTop: false, isRemoved: false, createTime: now, updateTime: now, speechMode: .onlyCreator)
                    try akawait(ChatService.conversation.saveToCloud(conversation))
                    self.showMessageViewController(conversation)
                }
            } catch {
                logger.error("获取conversation失败: \(error)")
                TKToast.show(msg: "Fetch conversation failed, please try again later.", style: .error)
            }
        }
    }

    private func showMessageViewController(_ conversation: TKConversation) {
        MessagesViewController.show(conversation)
    }
}

protocol StudentsViewControllerDelegate: NSObjectProtocol {
    func clickEdit(isEdit: Bool, controllerSelected: MainViewController.MainSelectedController)
}
