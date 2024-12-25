//
// Created by Wht on 2019-08-15.
// Copyright (c) 2019 Spelist. All rights reserved.
//
import FirebaseFirestore
import Foundation
import IQKeyboardManagerSwift
import SnapKit
import SwiftyBeaver
import UIKit

protocol NewStudentViewControllerDelegate: NSObjectProtocol {
    func newStudentViewControllerAddNewStudentCompletion(isExampleStudent: Bool, email: String)
    func newStudentViewControllerAddNewStudentRefData(email: String, name: String, phone: String)
}

class NewStudentViewController: TKBaseViewController {
    weak var delegate: NewStudentViewControllerDelegate?

    private var data: TKStudent = TKStudent()

    private var backView: TKView!
    private var cancelButton: TKButton!
    private var saveButton: TKButton!
    private var nameTextBox: TKTextBox!
    private var emailTextBox: TKTextBox!
    private var phoneTextBox: TKTextBox!

    private var loadingView: TKLoading!
    private var successContainerView: TKView!

    private var emailTyped: Bool = false

    private var viewHeight: CGFloat = 0
    var isEdit: Bool = false
    var oldStudentData: TKStudent?
    var isExampleStudent: Bool = false
    var exampleEmail: String = ""

    override func onViewAppear() {
        IQKeyboardManager.shared.enable = false
        show()

        if !isExampleStudent {
            nameTextBox.focus()
        } else {
            nameTextBox.value("Example Student")
            emailTextBox.value("\(exampleEmail.replacingOccurrences(of: ".com", with: "")).test")
            checkValues()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        IQKeyboardManager.shared.enable = true
    }

    override func onKeyboardShow(_ keyboardHeight: CGFloat) {
        super.onKeyboardShow(keyboardHeight)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.backView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
        }, completion: nil)
    }

    override func onKeyboardHide(_ keyboardHeight: CGFloat) {
        super.onKeyboardHide(keyboardHeight)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.backView.transform = .identity
        }, completion: nil)
    }
}

extension NewStudentViewController {
    private func show() {
        SL.Animator.run(time: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.backView.snp.updateConstraints({ make in
                make.top.equalToSuperview().offset(UIScreen.main.bounds.height - self.viewHeight)
            })
            self.view.layoutIfNeeded()
            if let oldStudentData = self.oldStudentData, self.isEdit {
                self.nameTextBox.value(oldStudentData.name)
                self.emailTextBox.value(oldStudentData.email)
                self.phoneTextBox.value(oldStudentData.phone)
            }
        }
    }

    private func hide(completion: @escaping () -> Void = {}) {
        SL.Animator.run(time: 0.2, animation: { [weak self] in
            self?.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self?.backView.snp.updateConstraints({ make in
                make.top.equalToSuperview().offset(UIScreen.main.bounds.height)
            })
            self?.view.layoutIfNeeded()
        }) { [weak self] _ in
            completion()
            self?.dismiss(animated: false, completion: nil)
        }
    }
}

extension NewStudentViewController {
    override func initView() {
        viewHeight = 286 + UiUtil.safeAreaBottom()

        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
            .addTo(superView: view, withConstraints: { make in
                make.top.equalToSuperview().offset(UIScreen.main.bounds.height)
                make.left.right.equalToSuperview()
                make.height.equalTo(viewHeight)
            })

        cancelButton = TKButton.create()
            .titleColor(color: ColorUtil.Font.primary)
            .title(title: "Cancel")
            .titleFont(font: FontUtil.bold(size: 13))
            .addTo(superView: backView, withConstraints: { make in
                make.top.left.equalToSuperview().offset(20)
                make.height.equalTo(20)
            })

        saveButton = TKButton.create()
            .titleColor(color: ColorUtil.main)
            .title(title: isExampleStudent ? "Next" : "Save")
            .titleFont(font: FontUtil.bold(size: 13))
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(20)
            })

        loadingView = TKLoading()
        backView.addSubview(view: loadingView) { make in
            make.center.equalTo(saveButton)
            make.size.equalTo(22)
        }
        loadingView.isHidden = true

        successContainerView = TKView.create()
            .backgroundColor(color: .white)
            .addTo(superView: backView, withConstraints: { make in
                make.center.equalTo(saveButton)
                make.size.equalTo(22)
            })
        backView.sendSubviewToBack(successContainerView)

        nameTextBox = TKTextBox.create()
            .placeholder("Full name")
            .inputType(.text)
            .onTyped({ value in
                // self.nameTextBox.value(value.capitalized)
                self.nameTextBox.value(value)
                self.checkValues()
            })
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalTo(cancelButton.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })

        emailTextBox = TKTextBox.create()
            .placeholder("Email")
            .inputType(.text)
            .keyboardType(.emailAddress)
            .onTyped({ [weak self] value in
                guard let self = self else { return }
                self.emailTyped = true
                let email = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                self.emailTextBox.value(email)
                // 判断是否符合Email
                self.checkValues()
            })
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalTo(nameTextBox.snp.bottom).offset(10)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })
        if isExampleStudent {
            emailTextBox.setEnabled(enabled: false)
            nameTextBox.setEnabled(enabled: false)
        }
        phoneTextBox = TKTextBox.create()
            .placeholder("Phone (optional)")
            .inputType(.text)
            .numberOfWordsLimit(11)
            .keyboardType(.phonePad)
            .prefix("+1")
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalTo(emailTextBox.snp.bottom).offset(10)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })
        checkValues()
    }

    override func bindEvent() {
        view.onViewTapped { _ in
//            guard let self = self, self.loadingView.isHidden else { return }
//            self.hide()
        }

        backView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.view.endEditing(true)
        }

        cancelButton.onTapped { [weak self] _ in
            guard let self = self, self.loadingView.isHidden else { return }
            self.hide()
        }
        saveButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            if self.isEdit {
                self.editStudentData()
            } else {
                self.onSaveButtonTapped()
            }
        }

        nameTextBox.next(emailTextBox)
        emailTextBox.next(phoneTextBox)
        phoneTextBox.onReturn { textBox in
            textBox.blur()
        }
    }

    private func checkValues() {
        if SL.FormatChecker.shared.isEmail(emailTextBox.getValue()) && nameTextBox.getValue() != "" {
            saveButton.isEnabled = true
            saveButton.titleColor(color: ColorUtil.main)
            emailTextBox.reset()
        } else {
            if !emailTyped {
                emailTextBox.reset()
            } else {
                emailTextBox.showWrong(autoHide: false)
            }
            saveButton.isEnabled = false
            saveButton.titleColor(color: ColorUtil.Font.primary)
        }
    }
}

extension NewStudentViewController {
    private func editStudentData() {
        guard nameTextBox.getValue() != "" else {
            nameTextBox.showWrong()
            return
        }

        guard emailTextBox.getValue() != "" else {
            emailTextBox.showWrong()
            return
        }

        guard SL.FormatChecker.shared.isEmail(emailTextBox.getValue()) else {
            emailTextBox.showWrong()
            return
        }
        guard let oldStudentData = oldStudentData else {
            TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
            return
        }
        saveButton.isHidden = true
        loadingView.isHidden = false
        loadingView.show(size: 22)
        if oldStudentData.email != emailTextBox.getValue() {
            CommonsService.shared.emailValidVerify(email: emailTextBox.getValue())
                .done { [weak self] isValid in
                    guard let self = self else { return }
//                    guard isValid else {
//                        self.loadingView.isHidden = true
//                        self.saveButton.isHidden = false
//                        TKToast.show(msg: TipMsg.emailValidationFalse, style: .error)
//                        return
//                    }
                    if isValid {
                        self.editUserEmail(userId: oldStudentData.studentId, studentListId: "\(oldStudentData.teacherId):\(oldStudentData.studentId)", email: self.emailTextBox.getValue().lowercased(), phone: self.phoneTextBox.getValue(), name: self.nameTextBox.getValue())
                    } else {
                        WrongEmailAlert.show(withEmail: self.emailTextBox.getValue()) { isContinue in
                            guard isContinue else {
                                self.loadingView.isHidden = true
                                self.saveButton.isHidden = false
                                return
                            }
                            self.editUserEmail(userId: oldStudentData.studentId, studentListId: "\(oldStudentData.teacherId):\(oldStudentData.studentId)", email: self.emailTextBox.getValue().lowercased(), phone: self.phoneTextBox.getValue(), name: self.nameTextBox.getValue())
                        }
                    }
                }
                .catch { error in
                    logger.error("校验email失败: \(error)")
                    self.loadingView.isHidden = true
                    self.saveButton.isHidden = false
                    TKToast.show(msg: TipMsg.failed, style: .error)
                }
        } else {
            CommonsService.shared.emailValidVerify(email: emailTextBox.getValue().lowercased())
                .done { [weak self] isValid in
                    guard let self = self else { return }
//                    guard isValid else {
//                        self.loadingView.isHidden = true
//                        self.saveButton.isHidden = false
//                        TKToast.show(msg: TipMsg.emailValidationFalse, style: .error)
//                        return
//                    }
                    if isValid {
                        self.editUserInfo(userId: oldStudentData.studentId, studentListId: "\(oldStudentData.teacherId):\(oldStudentData.studentId)", email: self.emailTextBox.getValue().lowercased(), phone: self.phoneTextBox.getValue(), name: self.nameTextBox.getValue())
                    } else {
                        WrongEmailAlert.show(withEmail: self.emailTextBox.getValue().lowercased()) { isContinue in
                            guard isContinue else {
                                self.loadingView.isHidden = true
                                self.saveButton.isHidden = false
                                return
                            }

                            self.editUserInfo(userId: oldStudentData.studentId, studentListId: "\(oldStudentData.teacherId):\(oldStudentData.studentId)", email: self.emailTextBox.getValue().lowercased(), phone: self.phoneTextBox.getValue(), name: self.nameTextBox.getValue())
                        }
                    }
                }
                .catch { error in
                    logger.error("校验email失败: \(error)")
                    self.loadingView.isHidden = true
                    self.saveButton.isHidden = false
                    TKToast.show(msg: TipMsg.emailValidationFalse, style: .error)
                }
        }
    }

    /// 修改学生的个人信息
    /// - Parameters:

    private func editUserInfo(userId: String, studentListId: String, email: String, phone: String, name: String) {
        addSubscribe(
            UserService.teacher.editStudentInfo(userId: userId, studentListId: studentListId, email: email, phone: phone, name: name)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    EventBus.send(key: .refreshStudents)
                    self.delegate?.newStudentViewControllerAddNewStudentRefData(email: email, name: name, phone: phone)
                    self.successContainerView.layer.removeAllSublayers()
                    let checkLayer = self.backView.getCheckLayer(containerSize: 22, color: ColorUtil.main, animated: true)
                    self.successContainerView.layer.addSublayer(checkLayer)
                    SL.Executor.runAsyncAfter(time: 0.8, action: {
                        self.successContainerView.layer.removeAllSublayers()
                        self.saveButton.isHidden = false
                        self.loadingView.isHidden = true

                        self.hide()
                    })

                }, onError: { err in
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    self.saveButton.isHidden = false
                    self.loadingView.isHidden = true
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    /// 修改学生的邮箱
    /// - Parameters:
    private func editUserEmail(userId: String, studentListId: String, email: String, phone: String, name: String) {
        addSubscribe(
            CommonsService.shared.changeUserAdminInfo(userId: userId, email: email)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.editUserInfo(userId: userId, studentListId: studentListId, email: email, phone: phone, name: name)
                }, onError: { err in
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    self.saveButton.isHidden = false
                    self.loadingView.isHidden = true
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func onSaveButtonTapped() {
        view.endEditing(true)
        logger.debug("save button tapped")
        guard nameTextBox.getValue() != "" else {
            nameTextBox.showWrong()
            return
        }

        guard emailTextBox.getValue() != "" else {
            emailTextBox.showWrong()
            return
        }
        guard SL.FormatChecker.shared.isEmail(emailTextBox.getValue()) else {
            emailTextBox.showWrong()
            return
        }

        saveButton.isHidden = true
        loadingView.isHidden = false
        loadingView.show(size: 22)

        let email = emailTextBox.getValue().lowercased()

        func exec() {
            let name = nameTextBox.getValue()
            let phone = phoneTextBox.getValue()
            logger.debug("email: [\(email)] | name: [\(name)] | phone: [\(phone)]")
            var studentData: [UserService.Student.TKAddNewStudent] = []
            var student: UserService.Student.TKAddNewStudent = UserService.Student.TKAddNewStudent()
            student.email = email
            student.name = name
            student.phone = phone
            studentData.append(student)

            addSubscribe(
                UserService.student.addNewStudents(students: studentData)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        self.successContainerView.layer.removeAllSublayers()
                        let checkLayer = self.backView.getCheckLayer(containerSize: 22, color: ColorUtil.main, animated: true)
                        self.successContainerView.layer.addSublayer(checkLayer)
                        SL.Executor.runAsyncAfter(time: 0.8, action: { [weak self] in
                            guard let self = self else { return }
                            self.successContainerView.layer.removeAllSublayers()
                            self.saveButton.isHidden = false
                            self.loadingView.isHidden = true
                            self.hide { [weak self] in
                                guard let self = self else { return }
                                self.delegate?.newStudentViewControllerAddNewStudentCompletion(isExampleStudent: self.isExampleStudent, email: email)
                            }
                        })
                    }, onError: { [weak self] err in
                        guard let self = self else { return }
                        self.saveButton.isHidden = false
                        self.loadingView.isHidden = true
                        TKToast.show(msg: "Please check your connection and try again.", style: .error)
                        logger.debug("======\(err)")
                    })
            )
        }

        logger.debug("获取用户的角色")
        UserService.user.getUserRole(by: email)
            .done { [weak self] role in
                guard let self = self else { return }
                logger.debug("获取用户角色结束: \(String(describing: role))")
                var r = role
                if r == nil {
                    r = .student
                }
                if r! == .student {
                    logger.debug("判断学生是否已经被添加")
                    UserService.student.checkStudentCanBind(email: email)
                        .done { [weak self] canBind in
                            guard let self = self else { return }
                            logger.debug("学生是否可以被绑定: \(canBind)")
                            if canBind {
                                CommonsService.shared.emailValidVerify(email: email)
                                    .done { [weak self] isValid in
                                        guard let self = self else { return }
                                        if isValid {
                                            exec()
                                        } else {
                                            WrongEmailAlert.show(withEmail: email) { isContinue in
                                                guard isContinue else {
                                                    self.loadingView.isHidden = true
                                                    self.saveButton.isHidden = false
                                                    return
                                                }

                                                exec()
                                            }
                                        }
                                    }
                                    .catch { [weak self] error in
                                        self?.loadingView.isHidden = true
                                        self?.saveButton.isHidden = false
                                        TKToast.show(msg: TipMsg.emailValidationFalse, style: .error)
                                        logger.error("校验email出错: \(error)")
                                    }
                            } else {
                                logger.debug("不能绑定,提示已经被绑定了")
                                self.loadingView.isHidden = true
                                self.saveButton.isHidden = false
                                SL.Alert.show(target: self, title: "Not your student", message: "This student has been connected to another instructor. Please confirm with your student.", centerButttonString: "Got it") {
                                    self.emailTextBox.focus()
                                    self.emailTextBox.showWrong(autoHide: true) {
                                    }
                                }

                                logger.error("当前学生已经被其他账号绑定")
                            }
                        }
                        .catch { [weak self] error in
                            self?.loadingView.isHidden = true
                            self?.saveButton.isHidden = false
                            TKToast.show(msg: TipMsg.failed, style: .error)
                            logger.error("校验学生出错: \(error)")
                        }
                } else {
                    self.loadingView.isHidden = true
                    self.saveButton.isHidden = false
                    SL.Alert.show(target: self, title: "Not a student", message: "This email has been associated with a instructor account. Please confirm the e-mail with your student.", centerButttonString: "Got it") {
                        self.emailTextBox.focus()
                        self.emailTextBox.showWrong(autoHide: true) {
                        }
                    }
                }
            }
            .catch { [weak self] error in
                self?.loadingView.isHidden = true
                self?.saveButton.isHidden = false
                TKToast.show(msg: TipMsg.failed, style: .error)
                logger.error("校验email出错: \(error)")
            }
    }
}
