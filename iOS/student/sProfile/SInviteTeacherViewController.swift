//
//  SInviteTeacherViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/1/21.
//  Copyright © 2021 spelist. All rights reserved.
//

import FirebaseFirestore
import FirebaseFunctions
import PromiseKit
import UIKit

protocol SInviteTeacherViewControllerDelegate: AnyObject {
    func sInviteTeacherViewControllerDismissed()
}

class SInviteTeacherViewController: TKBaseViewController {
    enum Step {
        case searchByEmail
        case addTeacher
        case inviteTeacher
    }

    weak var delegate: SInviteTeacherViewControllerDelegate?

    private var currentStep: Step = .searchByEmail

    // 通过email搜索
    private let searchByEmailViewHeight: CGFloat = 190 + UiUtil.safeAreaBottom()

    private lazy var searchByEmailView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 10)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

    public lazy var searchByEmailTextBox: TKTextBox = TKTextBox.create()
        .placeholder("Email address")
        .inputType(.text)
        .keyboardType(.emailAddress)
        .onTyped { [weak self] email in
            guard let self = self else { return }
            self.searchByEmailTextBox.value(email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
            if SL.FormatChecker.shared.isEmail(email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) {
                self.searchByEmailNextButton.enable()
                self.searchByEmailTextBox.reset()
            } else {
                self.searchByEmailTextBox.showWrong(autoHide: false)
                self.searchByEmailNextButton.disable()
            }
        }

    private lazy var searchByEmailCancelButton: TKBlockButton = TKBlockButton(frame: .zero, title: "CANCEL", style: .cancel)
    private lazy var searchByEmailNextButton: TKBlockButton = TKBlockButton(frame: .zero, title: "NEXT")

    // 搜索到了教师
    private let addTeacherViewHeight: CGFloat = 370 + UiUtil.safeAreaBottom()

    private lazy var addTeacherView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 10)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
    private lazy var addTeacherContainerView: TKView = TKView.create()
        .corner(size: 10)
    private var addTeacherTitleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 20))
        .alignment(alignment: .left)
        .textColor(color: .white)
        .setNumberOfLines(number: 0)
    private var addTeacherAvatarView: TKAvatarView = TKAvatarView()
    private var addTeacherInfoCardView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .showShadow()
        .showBorder(color: ColorUtil.borderColor)
    private var addTeacherFullNameLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 18))
        .textColor(color: ColorUtil.Font.third)
        .changeLabelRowSpace(lineSpace: 0, wordSpace: 1.0)
    private var addTeacherEmailLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.Font.primary)
    private var addTeacherCancelButton: TKBlockButton = TKBlockButton(frame: .zero, title: "CANCEL", style: .cancel)
    private var addTeacherAddTeacherButton: TKBlockButton = TKBlockButton(frame: .zero, title: "ADD INSTRUCTOR")

    // 没有搜索到教师,进入添加邀请
    private let inviteTeacherViewHeight: CGFloat = 250 + UiUtil.safeAreaBottom()
    private lazy var inviteTeacherView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 10)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
    private lazy var inviteTeacherEmailLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 18))
        .textColor(color: ColorUtil.Font.second)
    private lazy var inviteTeacherFullNameTextBox: TKTextBox = TKTextBox.create()
        .placeholder("Full name")
        .inputType(.text)
        .keyboardType(.default)
        .numberOfWordsLimit(40)
    private lazy var inviteTeacherCancelButton: TKBlockButton = TKBlockButton(frame: .zero, title: "CANCEL", style: .cancel)
    private lazy var inviteTeacherInviteTeacherButton: TKBlockButton = TKBlockButton(frame: .zero, title: "INVITE INSTRUCTOR")

    // MARK: - Data

    private var user: TKUser?
    private var studio: TKStudio?
    private var teacher: TKTeacher?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchByEmailView.transform = CGAffineTransform(translationX: 0, y: searchByEmailViewHeight)
        addTeacherView.transform = CGAffineTransform(translationX: 0, y: addTeacherViewHeight)
        inviteTeacherView.transform = CGAffineTransform(translationX: 0, y: inviteTeacherViewHeight)
        showSearchByEmail()
    }

    deinit {
        logger.debug("销毁 => \(tkScreenName)")
    }
}

extension SInviteTeacherViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        var buttonWidth = (UIScreen.main.bounds.width - 60) / 2
        if buttonWidth > 160 {
            buttonWidth = 160
        }

        // MARK: - 搜索教师

        searchByEmailView.addTo(superView: view) { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(searchByEmailViewHeight)
        }

        searchByEmailTextBox.addTo(superView: searchByEmailView) { make in
            make.top.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(64)
        }

        searchByEmailCancelButton.addTo(superView: searchByEmailView) { make in
            make.width.equalTo(buttonWidth)
            make.centerX.equalToSuperview().offset(-(buttonWidth / 2) - 10)
            make.height.equalTo(50)
            make.top.equalTo(searchByEmailTextBox.snp.bottom).offset(30)
        }

        searchByEmailNextButton.addTo(superView: searchByEmailView) { make in
            make.width.equalTo(buttonWidth)
            make.centerX.equalToSuperview().offset((buttonWidth / 2) + 10)
            make.height.equalTo(50)
            make.top.equalTo(searchByEmailTextBox.snp.bottom).offset(30)
        }

        // MARK: - 添加教师

        addTeacherView.addTo(superView: view) { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(addTeacherViewHeight)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        addTeacherContainerView.addTo(superView: addTeacherView) { make in
            make.top.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(245)
        }
        addTeacherAvatarView.cornerRadius = 32
        addTeacherAvatarView.addTo(superView: addTeacherContainerView) { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(64)
        }

        addTeacherTitleLabel.addTo(superView: addTeacherContainerView) { make in
            make.top.left.equalToSuperview().offset(20)
            make.right.equalTo(addTeacherAvatarView.snp.left).offset(-40)
        }

        addTeacherInfoCardView.addTo(superView: addTeacherContainerView) { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-30)
            make.height.equalTo(85)
        }

        addTeacherFullNameLabel.addTo(superView: addTeacherInfoCardView) { make in
            make.top.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(21)
        }

        addTeacherEmailLabel.addTo(superView: addTeacherInfoCardView) { make in
            make.top.equalTo(addTeacherFullNameLabel.snp.bottom).offset(4.5)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(20)
        }

        addTeacherCancelButton.addTo(superView: addTeacherView) { make in
            make.width.equalTo((UIScreen.main.bounds.width - 60) / 3)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(50)
            make.top.equalTo(addTeacherContainerView.snp.bottom).offset(30)
        }

        addTeacherAddTeacherButton.addTo(superView: addTeacherView) { make in
            make.width.equalTo(((UIScreen.main.bounds.width - 60) / 3) * 2)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(50)
            make.top.equalTo(addTeacherCancelButton.snp.top)
        }

        // MARK: - invite teacher

        inviteTeacherView.addTo(superView: view) { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(inviteTeacherViewHeight)
        }
        inviteTeacherEmailLabel.addTo(superView: inviteTeacherView) { make in
            make.top.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(20)
        }
        inviteTeacherFullNameTextBox.addTo(superView: inviteTeacherView) { make in
            make.top.equalTo(inviteTeacherEmailLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(64)
        }
        inviteTeacherCancelButton.addTo(superView: inviteTeacherView) { make in
            make.width.equalTo((UIScreen.main.bounds.width - 60) / 3)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(50)
            make.top.equalTo(inviteTeacherFullNameTextBox.snp.bottom).offset(30)
        }
        inviteTeacherInviteTeacherButton.addTo(superView: inviteTeacherView) { make in
            make.width.equalTo(((UIScreen.main.bounds.width - 60) / 3) * 2)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(50)
            make.top.equalTo(inviteTeacherCancelButton.snp.top)
        }
        inviteTeacherInviteTeacherButton.disable()

        searchByEmailView.transform = CGAffineTransform(translationX: 0, y: searchByEmailViewHeight)
        addTeacherView.transform = CGAffineTransform(translationX: 0, y: addTeacherViewHeight)
        inviteTeacherView.transform = CGAffineTransform(translationX: 0, y: inviteTeacherViewHeight)
    }
}

extension SInviteTeacherViewController {
    override func bindEvent() {
        super.bindEvent()

        searchByEmailCancelButton.onTapped { [weak self] _ in
            self?.hide()
        }

        searchByEmailNextButton.onTapped { [weak self] button in
            guard let self = self else { return }
            let email = self.searchByEmailTextBox.getValue().lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard SL.FormatChecker.shared.isEmail(email) else {
                self.searchByEmailTextBox.showWrong(autoHide: false)
                return
            }
            button.startLoading(at: self.view) {
                self.getTeacher(byEmail: email)
                    .done { data in
                        if let data = data {
                            logger.debug("搜索到当前教师: \(data)")
                            self.user = data.0
                            self.studio = data.1
                            self.teacher = data.2
                            button.stopLoading {
                                self.showAddTeacherView()
                            }
                        } else {
                            logger.debug("当前教师信息为空")
                            // 校验用户的Email是否可用
                            let email = self.searchByEmailTextBox.getValue().lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                            CommonsService.shared.emailValidVerify(email: email)
                                .done { isValid in
                                    if isValid {
                                        button.stopLoading {
                                            self.showInviteTeacher()
                                        }
                                    } else {
                                        WrongEmailAlert.show(withEmail: email) { isContinue in
                                            if isContinue {
                                                button.stopLoading {
                                                    self.showInviteTeacher()
                                                }
                                            } else {
                                                button.stopLoadingWithFailed()
                                            }
                                        }
                                    }
                                }
                                .catch { error in
                                    logger.error("校验email失败: \(error)")
                                    button.stopLoadingWithFailed {
                                        TKToast.show(msg: "Verify email failed, please try again.", style: .error)
                                    }
                                }
                        }
                    }
                    .catch { error in
                        logger.debug("搜索教师失败: \(error)")
                        if (error as NSError).code == -1 {
                            button.stopLoadingWithFailed {
                                SL.Alert.show(target: self, title: "Not a instructor!", message: "This e-mail has been associated with a student account, please confirm the e-mail with your instructor.", centerButttonString: "Go back") {
                                    self.searchByEmailTextBox.showWrong()
                                }
                            }
                        } else {
                            button.stopLoadingWithFailed {
                                TKToast.show(msg: "Find data failed, please try again later.", style: .error)
                            }
                        }
                    }
            }
        }

        inviteTeacherFullNameTextBox.onTyped { [weak self] value in
            guard let self = self else { return }
            if value != "" {
                self.inviteTeacherInviteTeacherButton.enable()
            } else {
                self.inviteTeacherInviteTeacherButton.disable()
            }
        }

        addTeacherCancelButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.2) {
                self.addTeacherView.transform = CGAffineTransform(translationX: 0, y: self.addTeacherViewHeight)
            } completion: { _ in
                self.showSearchByEmail()
            }
        }

        inviteTeacherCancelButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.2) {
                self.inviteTeacherView.transform = CGAffineTransform(translationX: 0, y: self.inviteTeacherViewHeight)
            } completion: { _ in
                self.showSearchByEmail()
            }
        }

        addTeacherAddTeacherButton.onTapped { [weak self] _ in
            self?.addTeacher()
        }

        inviteTeacherInviteTeacherButton.onTapped { [weak self] _ in
            self?.inviteTeacher()
        }
    }
}

extension SInviteTeacherViewController {
    private func showSearchByEmail() {
        currentStep = .searchByEmail
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.searchByEmailView.transform = .identity
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self = self else { return }
                if !self.searchByEmailTextBox.isFocus() {
                    self.searchByEmailTextBox.focus()
                }
            }
        }
    }

    private func showAddTeacherView() {
        // 设置数据
        guard let user = self.user, let studio = self.studio, let selfUser = ListenerService.shared.user else { return }
        let title: String = "Hi \(selfUser.name.getShortLastName()),\nWelcome to \(studio.name)!"
        addTeacherTitleLabel.text(title)
        addTeacherContainerView.backgroundColor = UIColor(hex: studio.storefrontColor)
        addTeacherFullNameLabel.text(user.name)
        addTeacherEmailLabel.text(user.email)
        addTeacherAvatarView.loadImage(studioId: studio.id, name: studio.name)
        hideCurrentView { [weak self] in
            guard let self = self else { return }
            self.currentStep = .addTeacher
            UIView.animate(withDuration: 0.2) {
                self.addTeacherView.transform = .identity
            }
        }
    }

    private func showInviteTeacher() {
        logger.debug("显示邀请老师")
        hideCurrentView { [weak self] in
            guard let self = self else { return }
            self.inviteTeacherEmailLabel.text = self.searchByEmailTextBox.getValue().lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            self.currentStep = .inviteTeacher
            UIView.animate(withDuration: 0.2) {
                self.inviteTeacherView.transform = .identity
            }
        }
    }

    private func hideCurrentView(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2) {
            switch self.currentStep {
            case .searchByEmail:
                self.searchByEmailView.transform = CGAffineTransform(translationX: 0, y: self.searchByEmailViewHeight)
            case .addTeacher:
                self.addTeacherView.transform = CGAffineTransform(translationX: 0, y: self.addTeacherViewHeight)
            case .inviteTeacher:
                self.inviteTeacherView.transform = CGAffineTransform(translationX: 0, y: self.inviteTeacherViewHeight)
            }
        } completion: { _ in
            completion()
        }
    }

    private func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            switch self.currentStep {
            case .searchByEmail:
                self.searchByEmailView.transform = CGAffineTransform(translationX: 0, y: self.searchByEmailViewHeight)
            case .addTeacher:
                self.addTeacherView.transform = CGAffineTransform(translationX: 0, y: self.addTeacherViewHeight)
            case .inviteTeacher:
                self.inviteTeacherView.transform = CGAffineTransform(translationX: 0, y: self.inviteTeacherViewHeight)
            }
        } completion: { [weak self] _ in
            guard let self = self else { return }
            EventBus.send(key: .studentTeacherChanged)
            self.delegate?.sInviteTeacherViewControllerDismissed()
            self.dismiss(animated: false, completion: nil)
        }
    }
}

extension SInviteTeacherViewController {
    private func getTeacher(byEmail email: String) -> Promise<(TKUser, TKStudio, TKTeacher)?> {
        view.endEditing(true)
        return Promise { resoler in
            getUser(byContactEmail: email)
                .done { user in
                    if let user = user {
                        // 获取详细信息
                        let userId = user.userId
                        when(fulfilled: UserService.studio.getStudioInfo(teacherId: userId), UserService.teacher.getTeacher(userId))
                            .done { studio, teacher in
                                if let studio = studio, let teacher = teacher {
                                    resoler.fulfill((user, studio, teacher))
                                } else {
                                    resoler.fulfill(nil)
                                }
                            }
                            .catch { error in
                                resoler.reject(error)
                            }
                    } else {
                        resoler.fulfill(nil)
                    }
                }
                .catch { error in
                    resoler.reject(error)
                }
        }
    }

    private func getUser(byContactEmail email: String) -> Promise<TKUser?> {
        return Promise { resolver in
            logger.debug("通过Email: \(email) 搜索用户")
            DatabaseService.collections.user()
                .whereField("email", isEqualTo: email)
                .getDocuments(source: .server) { snapshot, error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        if let docs = snapshot?.documents, let users: [TKUser] = [TKUser].deserialize(from: docs.compactMap { $0.data() }) as? [TKUser] {
                            logger.debug("搜索到的用户信息: \(users.toJSONString() ?? "")")
                            if users.count > 0 {
                                // 搜索到了用户,判断用户是否是学生
                                if users[0].roleIds.contains("\(TKUserRole.student.rawValue)") {
                                    // 当前搜索的是学生,返回一个错误
                                    resolver.reject(NSError(domain: "ROLE_ERROR", code: -1, userInfo: nil))
                                } else {
                                    resolver.fulfill(users[0])
                                }
                            } else {
                                resolver.fulfill(nil)
                            }
                        } else {
                            resolver.fulfill(nil)
                        }
                    }
                }
        }
    }
}

extension SInviteTeacherViewController {
    private func addTeacher() {
        guard let user = user, let teacher = self.teacher, let selfUserId = UserService.user.id() else { return }
        addTeacherAddTeacherButton.startLoading(at: view) {
            // 绑定教师
            // 获取是否已经绑定过未处理的老师,如果有,就删除,重新绑定
            UserService.student.resetTeacher()
                .done { _ in
                    Firestore.firestore().runTransaction { (transaction, pointer) -> Any? in
                        // 获取自己的信息
                        let selfUserDocRef = DatabaseService.collections.user().document(selfUserId)
                        let selfUser: TKUser
                        do {
                            let selfUserDoc = try transaction.getDocument(selfUserDocRef)
                            if let data = selfUserDoc.data(), let _user = TKUser.deserialize(from: data) {
                                selfUser = _user
                            } else {
                                pointer?.pointee = NSError(domain: "Failed: deserialize [TKUser] failed.", code: -1, userInfo: selfUserDoc.data())
                                return nil
                            }
                        } catch {
                            logger.error("获取用户信息失败: \(error)")
                            pointer?.pointee = error as NSError
                            return nil
                        }
                        // 添加学生表信息
                        let now = "\(Date().timestamp)"
                        let student = TKStudent(id: "\(teacher.studioId):\(selfUser.userId)", studioId: teacher.studioId, teacherId: "", studentId: selfUser.userId, name: selfUser.name, phone: selfUser.phone, email: selfUser.email, invitedStatus: .none, lessonTypeId: "", isUploadedAvatar: false, statusHistory: [], studentApplyStatus: .apply, createTime: now, updateTime: now)
                        let docId = "\(teacher.studioId):\(selfUser.userId)"
                        transaction.setData(student.toJSON() ?? [:], forDocument: DatabaseService.collections.teacherStudentList().document(docId), merge: true)
                        logger.debug("准备给文档[\(docId)]添加数据: \(student.toJSONString() ?? "")")
                        return nil
                    } completion: { [weak self] _, error in
                        guard let self = self else { return }
                        if let error = error {
                            logger.error("添加老师失败: \(error)")
                            self.addTeacherAddTeacherButton.stopLoadingWithFailed {
                                TKToast.show(msg: "Add instructor failed, please try again.", style: .error)
                            }
                        } else {
                            LoggerUtil.shared.log(.inviteTeachers)
                            logger.debug("添加老师成功")
                            CommonsService.shared.studentInviteTeacherEmailTemplate(teacherId: user.userId)
                            EventBus.send(key: .studentTeacherChanged)
                            self.addTeacherAddTeacherButton.stopLoading {
                                self.hide()
                            }
                        }
                    }
                }
                .catch { [weak self] error in
                    guard let self = self else { return }
                    logger.error("添加老师失败: \(error)")
                    self.addTeacherAddTeacherButton.stopLoadingWithFailed {
                        TKToast.show(msg: "Add instructor failed, please try again.", style: .error)
                    }
                }
        }
    }
}

extension SInviteTeacherViewController {
    private func inviteTeacher() {
        guard let user = ListenerService.shared.user else { return }
        inviteTeacherInviteTeacherButton.startLoading(at: view) { [weak self] in
            guard let self = self else { return }
            UserService.student.resetTeacher()
                .done { _ in
                    let email = self.searchByEmailTextBox.getValue().lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let fullName = self.inviteTeacherFullNameTextBox.getValue()
                    let selfUser = [
                        "userId": user.userId,
                        "name": user.name,
                        "phone": user.phone,
                        "email": user.email,
                    ]

                    Functions.functions().httpsCallable("studentInviteTeacher")
                        .call([
                            "email": email,
                            "fullName": fullName,
                            "selfUser": selfUser,
                        ]) { result, error in
                            if let error = error {
                                logger.error("邀请教师失败: \(error)")
                                self.inviteTeacherInviteTeacherButton.stopLoadingWithFailed {
                                    TKToast.show(msg: "Invite instructor failed, please try again.", style: .error)
                                }
                            } else {
                                LoggerUtil.shared.log(.inviteTeachers)
                                if let data = result?.data as? [String: Any], let resultData = FuncResult.deserialize(from: data) {
                                    if resultData.code == 0 {
                                        self.inviteTeacherInviteTeacherButton.stopLoading {
                                            self.hide()
                                        }
                                        return
                                    }
                                }
                                self.inviteTeacherInviteTeacherButton.stopLoadingWithFailed {
                                    TKToast.show(msg: "Invite instructor failed, please try again.", style: .error)
                                }
                            }
                        }
                }
                .catch { error in
                    logger.error("邀请教师失败: \(error)")
                    self.inviteTeacherInviteTeacherButton.stopLoadingWithFailed {
                        TKToast.show(msg: "Invite instructor failed, please try again.", style: .error)
                    }
                }
        }
    }
}
