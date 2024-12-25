//
//  StudentsContentViewController.swift
//  TuneKey
//
//  Created by Wht on 2019/8/17.
//  Copyright © 2019 spelist. All rights reserved.
//

import FirebaseFirestore
import PromiseKit
import UIKit

protocol StudentsContentViewControllerDelegate: NSObjectProtocol {
    func studentsContentViewController(selectedStudentChanged students: [TKStudent], atIndex index: Int)
}

enum StudentsCellStyle: Int {
    case normal = 1
    case singleSelection = 2
    case multipleSelection = 3
}

enum StudentsControllerStatus {
    case normal
    case edit
    case search
}

class StudentsContentViewController: TKBaseViewController {
    weak var delegate: StudentsContentViewControllerDelegate?
    var mainView = UIView()
    var index: Int = 0
    var collectionViewLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    var showProView = UIView()
    var showProLabel = TKLabel()
    var showProButton = TKButton()
    var studentsControllerStatus: StudentsControllerStatus!
    var localContactData: LocalContact!
    var studentDatas: [TKStudent] = []
    var usersInfo: [String: TKUser] = [:]
    var unconfirmedLesson: [String: [TKLessonScheduleConfigure]] = [:]
    var conversations: [String: TKConversation] = [:] {
        didSet {
            logger.debug("[会话查询结果] => \(conversations.count)  --------- 开始")
            for (id, conversation) in conversations {
                logger.debug("[会话查询结果] => item输出: \(id) | \(conversation.toJSONString() ?? "")")
            }
            logger.debug("[会话查询结果] => \(conversations.count)  --------- 结束")
        }
    }

    // 1是免费 2是收费用户
    var teacherMemberLevel: Int = 1 {
        didSet {
            if oldValue != teacherMemberLevel {
//                initMemberLevel()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadConversations()
    }
}

extension StudentsContentViewController {
    private func loadConversations() {
        logger.debug("加载当前学生页的所有会话")
        guard studentDatas.count > 0 else {
            collectionView?.reloadData()
            return
        }
        let studentIds = studentDatas.compactMap { $0.studentId }
        ChatService.conversation.getPrivateConversationsFromLocal(userIds: studentIds)
            .done { result in
                self.conversations = result
                // 将学生分为两拨排序
                var hasConversations: [TKStudent] = []
                var noConversations: [TKStudent] = []
                self.studentDatas.forEach { student in
                    if let c = result[student.studentId], c.latestMessageTimestamp != 0 {
                        hasConversations.append(student)
                    } else {
                        noConversations.append(student)
                    }
                }

                hasConversations.sort { s1, s2 in
                    if let s1C = result[s1.studentId], let s2C = result[s2.studentId] {
                        return s1C.latestMessageTimestamp > s2C.latestMessageTimestamp
                    } else {
                        return s1.name < s2.name
                    }
                }

                noConversations.sort { s1, s2 in
                    s1.name < s2.name
                }

                self.studentDatas = hasConversations + noConversations

                self.collectionView?.reloadData()
            }
            .catch { error in
                logger.error("[加载Conversation] => 查询错误: \(error)")
                self.conversations = [:]
                self.collectionView?.reloadData()
            }
    }
}

// MARK: - View

extension StudentsContentViewController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        initShowProView()
        initCollectionView()
//        initMemberLevel()

        EventBus.listen(key: .clearUnconfirmedLessons, target: self) { [weak self] notification in
            guard let self = self, let id = notification?.object as? String, id != "" else { return }
            self.unconfirmedLesson.removeValue(forKey: id)
            self.collectionView.reloadData()
        }

        EventBus.listen(key: .conversationSyncSuccess, target: self) { [weak self] _ in
            DispatchQueue.main.async {
                self?.loadConversations()
            }
        }

        EventBus.listen(key: .messagesAdded, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.loadConversations()
        }
    }

    func initMemberLevel(totalStudentCont: Int) {
        changeProView(teacherMemberLevel == 1 && totalStudentCont >= FreeResources.maxStudentsCount ? true : false)
    }

    func initCollectionView() {
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        collectionView.allowsSelection = false
        collectionView.backgroundColor = UIColor.white
        mainView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.showProView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        updateCollectionViewLayout()
        enableScreenRotateListener {
            self.updateCollectionViewLayout()
        }

        collectionView.register(StudentsSelectorCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: StudentsSelectorCollectionViewCell.self))
    }

    func initShowProView() {
        view.addSubview(showProView)
        showProView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.height.equalTo(0)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        showProView.clipsToBounds = true
        showProView.addSubviews(showProLabel, showProButton)
        showProLabel.textColor(color: ColorUtil.Font.primary).font(font: FontUtil.regular(size: 10))
            .text("You've reached your limit of 5 students.\nTry PRO to unlock the full power of TuneKey.")
        showProLabel.numberOfLines = 2
        showProButton.title(title: "PRO").titleFont(FontUtil.regular(size: 10))
        showProButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.height.equalTo(0)
            make.width.equalTo(0)
            make.centerY.equalToSuperview()
        }
        showProButton.backgroundColor = ColorUtil.blush
        showProButton.layer.cornerRadius = 4

        showProLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(showProButton.snp.left)
        }

        showProView.onViewTapped { _ in
            guard let topController = Tools.getTopViewController() else { return }
            ProfileUpgradeDetailViewController.show(level: .normal, target: topController)
        }

        showProButton.onViewTapped { _ in
            guard let topController = Tools.getTopViewController() else { return }
            ProfileUpgradeDetailViewController.show(level: .normal, target: topController)
        }

        showProLabel.onViewTapped { _ in
            guard let topController = Tools.getTopViewController() else { return }
            ProfileUpgradeDetailViewController.show(level: .normal, target: topController)
        }
    }

    // MARK: - 更新是否显示ProView

    func changeProView(_ isShow: Bool) {
        if isShow {
            collectionView?.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        } else {
            collectionView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        showProView.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(isShow ? 20 : 0)
            make.height.equalTo(isShow ? 26 : 0)
        }
        showProButton.snp.updateConstraints { make in
            make.height.equalTo(isShow ? 26 : 0)
            make.width.equalTo(isShow ? 42 : 0)
        }
    }
}

// MARK: - CollectionView

extension StudentsContentViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, StudentsSelectorCollectionViewCellDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.row < studentDatas.count else { return .zero }
        let student = studentDatas[indexPath.row]
        let id = student.studentId
        let conversation = conversations[id]
        if conversation == nil {
            if isPad {
                // 大屏幕, 两列，中间留出 10 的间距
                return CGSize(width: self.collectionView.frame.width / 2, height: 94)
            } else {
                // 小屏幕
                return CGSize(width: self.collectionView.frame.width, height: 94)
            }
        } else {
            var height: CGFloat = 0
            if conversation!.latestMessageId == "" {
                height = 94
            } else {
                height = 121
            }
            if let user = usersInfo[student.studentId] {
                if !user.active {
                    height += 20
                }
            }
            if isPad {
                // 大屏幕, 两列，中间留出 10 的间距
                return CGSize(width: self.collectionView.frame.width / 2, height: height)
            } else {
                // 小屏幕
                return CGSize(width: self.collectionView.frame.width, height: height)
            }
        }
    }

    func studentsSelectorCollectionViewCellIsEdit() -> Bool {
        return studentsControllerStatus! == .edit
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return studentDatas.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: StudentsSelectorCollectionViewCell.self), for: indexPath) as! StudentsSelectorCollectionViewCell
        cell.tag = indexPath.row
        cell.delegate = self
        switch studentsControllerStatus! {
        case .normal, .search:
            cell.initItem(.normal)
        case .edit:
            cell.initItem(.multipleSelection)
        }
        var student = studentDatas[indexPath.row]
        if student.userInfo == nil, var user = usersInfo[student.studentId] {
            user.active = false
            student.userInfo = user
        }
        cell.initData(studentData: student, unconfirmdLessonConfigs: unconfirmedLesson[student.studentId] ?? [])
        cell.messageBarView.onViewTapped { [weak self] _ in
            self?.toMessageDetail(student: student)
        }
        cell.loadConversation(conversations[student.studentId])
        return cell
    }
}

extension StudentsContentViewController {
    private func toMessageDetail(student: TKStudent) {
        let userId = student.studentId
        akasync {
            do {
                let conversationFromLocal = try akawait(DBService.conversation.get(userId: userId, type: ConversationType.private))
                if let conversation = conversationFromLocal {
                    self.toMessagesViewController(conversation)
                } else {
                    // 开始加载动画
                    self.showFullScreenLoading()
                    ChatService.conversation.getPrivateWithoutLocal(userId)
                        .done { [weak self] conversation in
                            guard let self = self else { return }
                            self.hideFullScreenLoading()
                            self.toMessagesViewController(conversation)
                        }
                        .catch { [weak self] error in
                            guard let self = self else { return }
                            self.hideFullScreenLoading()
                            logger.error("获取失败: \(error)")
                        }
                }
            } catch {
                logger.error("获取conversation失败: \(error)")
            }
        }
    }

    private func toMessagesViewController(_ conversation: TKConversation) {
        MessagesViewController.show(conversation)
    }
}

// MARK: - Data

extension StudentsContentViewController {
    func initStudentData(studentDatas: [TKStudent], users: [String: TKUser]) {
        if studentDatas.count > 0 {
            view.backgroundColor = UIColor.white
            collectionView.backgroundColor = UIColor.white
            view.setTopRadius()
        } else {
            view.clearTopRadius()
            view.backgroundColor = ColorUtil.backgroundColor
            collectionView.backgroundColor = ColorUtil.backgroundColor
        }
        self.studentDatas = studentDatas
        usersInfo = users
        getStudentUnconfirmedLessons(students: studentDatas.filter { $0.studentApplyStatus == .confirm })
        loadConversations()
    }

    private func getStudentUnconfirmedLessons(students: [TKStudent]) {
        let idList = students.compactMap { $0.studentId }.group(count: 9)
        for ids in idList {
            getStudentUnconfirmedLessons(by: ids)
        }
    }

    private func getStudentUnconfirmedLessons(by ids: [String]) {
        DatabaseService.collections.lessonScheduleConfigure()
            .whereField("studentId", in: ids)
            .whereField("teacherId", isEqualTo: "")
            .whereField("delete", isEqualTo: false)
            .getDocuments(source: .server) { snapshot, error in
                if let error = error {
                    logger.error("[获取学生未确认的课程] => 获取错误: \(error)")
                } else {
                    if let docs = snapshot?.documents {
                        let data = docs.compactMap({ $0.data() })
                        logger.debug("[获取学生未确认的课程] => 原始数据: \(data)")
                        if let lessonConfigs: [TKLessonScheduleConfigure] = [TKLessonScheduleConfigure].deserialize(from: data) as? [TKLessonScheduleConfigure] {
                            logger.debug("[获取学生未确认的课程] => 获取到的数据: \(lessonConfigs.toJSONString() ?? "")")
                            // 获取更新的Id
                            var indexs: [Int] = []
                            for config in lessonConfigs {
                                var i: Int = -1
                                for item in self.studentDatas.enumerated() {
                                    if item.element.studentId == config.studentId {
                                        i = item.offset
                                        break
                                    }
                                }
                                if i != -1 {
                                    if !indexs.contains(i) {
                                        indexs.append(i)
                                    }
                                }
                                var list = self.unconfirmedLesson[config.studentId]
                                if list == nil {
                                    list = []
                                }
                                if !list!.contains(where: { $0.id == config.id }) {
                                    list?.append(config)
                                }
                                self.unconfirmedLesson[config.studentId] = list
                            }
                            if indexs.count > 0 {
                                let indexPaths: [IndexPath] = indexs.compactMap { IndexPath(item: $0, section: 0) }
                                self.collectionView.reloadItems(at: indexPaths)
                            }
                        }
                    }
                }
            }
    }
}

// MARK: - Action

extension StudentsContentViewController {
    func studentsSelectorCollectionViewCell(didTappedAtButton cell: StudentsSelectorCollectionViewCell) {
        if studentsControllerStatus == .edit {
            clickEditCell(cell: cell)
        } else {
            clickCell(cell: cell)
        }
    }

    func studentsSelectorCollectionViewCell(didTappedAtContentView cell: StudentsSelectorCollectionViewCell) {
        if studentsControllerStatus == .edit {
            clickEditCell(cell: cell)
        } else {
            if studentDatas[cell.tag].getStudentType() == .addLesson || studentDatas[cell.tag].getStudentType() == .resend {
                clickResendAndAddLessonCell(cell)
            } else {
                // 点击进入用户详情You should upgrade Insights to pro.\nTry PRO to unlock the full power of TuneKey.
                let controller = StudentDetailsViewController()
                controller.modalPresentationStyle = .fullScreen
                controller.hero.isEnabled = true
                controller.studentData = studentDatas[cell.tag]
                controller.enablePanToDismiss()
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                present(controller, animated: true, completion: nil)
            }
        }
    }

    func clickResendAndAddLessonCell(_ cell: StudentsSelectorCollectionViewCell) {
//        let controller = NewStudentDetailController()
//        controller.isEditStudentInfo = true
//        controller.studentData = studentDatas[cell.tag]
//        controller.modalPresentationStyle = .fullScreen
//        controller.hero.isEnabled = true
//        controller.enablePanToDismiss()
//        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//        present(controller, animated: true, completion: nil)
        let controller = StudentDetailsViewController()
        controller.isEditStudentInfo = true
        controller.studentData = studentDatas[cell.tag]
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func clickEdit() {
        if studentsControllerStatus == .edit {
            studentsControllerStatus = .normal
        } else {
            for item in studentDatas.enumerated() {
                studentDatas[item.offset]._isSelect = false
            }
            studentsControllerStatus = .edit
        }
        collectionView.reloadData()
    }

    func getSelectedData() -> [TKStudent] {
        var data: [TKStudent] = []
        for item in studentDatas.enumerated() {
            if item.element._isSelect {
                data.append(item.element)
            }
        }
        return data
    }

    func clickEditCell(cell: StudentsSelectorCollectionViewCell) {
        studentDatas[cell.tag]._isSelect = !studentDatas[cell.tag]._isSelect
        delegate?.studentsContentViewController(selectedStudentChanged: getSelectedData(), atIndex: index)
    }

    func clickCell(cell: StudentsSelectorCollectionViewCell) {
        guard cell.tag < studentDatas.count else { return }
        let studentData = studentDatas[cell.tag]
        switch studentData.studentApplyStatus {
        case .apply:
            // 确认是否同意当前的学生
            guard let topController = Tools.getTopViewController() else { return }
            SL.Alert.show(target: topController, title: "New student?", message: "Tap ACCEPT, you will accept to add a new student.\n(\(studentData.email))", leftButttonString: "Go back", centerButttonString: "Not my student", rightButtonString: "Accept") {
            } centerButtonAction: { [weak self] in
                self?.rejectStudent(studentData)
            } rightButtonAction: { [weak self] in
                self?.acceptStudent(studentData)
            }
            break
        default:
            switch studentData.getStudentType() {
            case .none:
                let controller = StudentDetailsViewController()
                controller.modalPresentationStyle = .fullScreen
                controller.hero.isEnabled = true
                controller.studentData = studentData
                controller.enablePanToDismiss()
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                present(controller, animated: true, completion: nil)
            case .addLesson, .rejected, .newLesson:
                toAddLessonDetailController(data: studentData)
            case .resend, .invite:
                let message = """
                An invite email with download link will send to your student.

                The next steps for your student:

                1. Install Tunekey app (Apple Store / Google Play / Download link in email)
                2. Sign in with\n    \(studentData.email)
                3. Create a password
                4. All set!
                """
                SL.Alert.show(target: self, title: "Invite", message: message, leftButttonString: "LATER", rightButtonString: "SEND INVITE") {
                } rightButtonAction: {
                    CommonsService.shared.sendEmailNotificatioinForInvitationFromTeacher(studentName: studentData.name, email: studentData.email, teacherId: studentData.teacherId)
                } onShow: { alert in
                    alert.messageLabel?.textAlignment = .left
                    alert.leftButton?.text = "LATER"
                    alert.rightButton?.text = "SEND INVITE"
//                    alert.leftButton?.snp.updateConstraints({ make in
//                        make.width.equalTo(110)
//                    })
//                    alert.rightButton?.snp.updateConstraints({ make in
//                        make.width.equalTo(160)
//                    })
                }

//                SL.Alert.show(
//                    target: self,
//                    title: "Invite",
//                    message: message,
//                    leftButtonString: "LATER",
//                    rightButtonString: "SEND INVITE") {

//                TKAlert.show(target: self, title: "Resend", message: "Do you want to resend the invitation", buttonString: "RESEND") {
//                    TKToast.show(msg: "Resent invite to \(studentData.email)", style: .success)
//                    CommonsService.shared.sendEmailNotificatioinForInvitationFromTeacher(studentName: studentData.name, email: studentData.email, teacherId: studentData.teacherId)
//                }
            }
        }
    }

    func exampleStudentToAddLessonDetailController(email: String) {
        var studentData: TKStudent?
        studentDatas.forEach { item in
            if item.email == email {
                studentData = item
            }
        }
        guard let data = studentData else {
            return
        }
        OperationQueue.main.addOperation {
            exampleStudentEmail = email
            SLCache.main.setExampleStudentEmailAccountHistory(email: email, userId: data.studentId)
            self.toAddLessonDetailController(data: data, isExampleStudent: true)
        }
    }

    func toAddLessonDetailController(data: TKStudent, isExampleStudent: Bool = false) {
        // 判断是否有待确认的课程,如果有,那点击之后,进入默认值

        let controller = AddLessonDetailController(studentData: data)
        if let configs = unconfirmedLesson[data.studentId] {
            controller.defaultLessonScheculeConfigs = configs
        }
        controller.hero.isEnabled = true
        controller.isExampleStudent = isExampleStudent
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }
}

extension StudentsContentViewController {
    private func updateCollectionViewLayout() {
        DispatchQueue.main.async {
            self.collectionView.setNeedsLayout()
            self.collectionView.layoutIfNeeded()
            if self.collectionView.frame.width > 650 {
                // 大屏幕, 两列，中间留出 10 的间距
                self.collectionViewLayout.itemSize = CGSize(width: self.collectionView.frame.width / 2 - 10, height: 94)
            } else {
                // 小屏幕
                self.collectionViewLayout.itemSize = CGSize(width: self.collectionView.frame.width, height: 94)
            }
        }
    }
}

extension StudentsContentViewController {
    private func acceptStudent(_ student: TKStudent) {
        showFullScreenLoadingNoAutoHide()
        Firestore.firestore().runTransaction { transaction, _ -> Any? in

            transaction.updateData(["studentApplyStatus": TKStudentApplyStatus.confirm.rawValue], forDocument: DatabaseService.collections.teacherStudentList().document(student.teacherId + ":" + student.studentId))
            return nil
        } completion: { _, error in
            self.hideFullScreenLoading()
            if let error = error {
                logger.error("更改失败: \(error)")
            } else {
                logger.debug("更改成功")
            }
        }
    }

    private func rejectStudent(_ student: TKStudent) {
        showFullScreenLoadingNoAutoHide()
        Firestore.firestore().runTransaction { transaction, _ -> Any? in
            transaction.deleteDocument(DatabaseService.collections.teacherStudentList().document(student.teacherId + ":" + student.studentId))
            return nil
        } completion: { _, error in
            self.hideFullScreenLoading()
            if let error = error {
                logger.error("更改失败: \(error)")
                TKToast.show(msg: "Reject failed, please try again later.", style: .error)
            }
        }
    }
}
