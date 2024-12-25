//
//  ProfileLinkEmailController.swift
//  TuneKey
//
//  Created by WHT on 2020/3/9.
//  Copyright © 2020 spelist. All rights reserved.
//
import FirebaseAuth
import UIKit

protocol ProfileLinkEmailControllerDelegate: NSObjectProtocol {
    func profileLinkEmailController(save email: String, password: String)
    func profileLinkEmailController(updateEmail email: String)
}

class ProfileLinkEmailController: TKBaseViewController {
    private var data: TKStudent = TKStudent()

    private var backView: TKView!
    private var cancelButton: TKButton!
    private var saveButton: TKButton!
    private var emailTextBox: TKTextBox!
    private var passwordTextBox: TKTextBox!
    private var repeatPasswordTextBox: TKTextBox!

    private var loadingView: TKLoading!
    private var successContainerView: TKView!

    private var viewHeight: CGFloat = 0
    weak var delegate: ProfileLinkEmailControllerDelegate?
    private var isShow = false

    var isUpdateEmail: Bool = false

    override func onViewAppear() {
        guard !isShow else { return }
        isShow = true
        show()
    }
}

extension ProfileLinkEmailController {
    private func show() {
        if isUpdateEmail {
            passwordTextBox.isHidden = true
            repeatPasswordTextBox.isHidden = true
            viewHeight = 140 + UiUtil.safeAreaBottom()
            emailTextBox.placeholder("Your new sign in email")
        }

        SL.Animator.run(time: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.backView.snp.updateConstraints({ make in
                make.top.equalToSuperview().offset(UIScreen.main.bounds.height - self.viewHeight)
            })
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.emailTextBox.focus()
        }
    }

    private func hide(completion: @escaping () -> Void = {}) {
        SL.Animator.run(time: 0.2, animation: { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.backView.snp.updateConstraints({ make in
                make.top.equalToSuperview().offset(UIScreen.main.bounds.height)
            })
            self.view.layoutIfNeeded()
        }) { [weak self] _ in
            self?.dismiss(animated: false, completion: completion)
        }
    }
}

extension ProfileLinkEmailController {
    override func initView() {
        viewHeight = 286 + UiUtil.safeAreaBottom()

        view.backgroundColor = UIColor.black.withAlphaComponent(0)

        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
            .addTo(superView: view, withConstraints: { make in
                make.top.equalToSuperview().offset(UIScreen.main.bounds.height)
                make.left.right.equalTo(self.view.safeAreaLayoutGuide)
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
            .title(title: "Save")
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

        emailTextBox = TKTextBox.create()
            .placeholder("Email")
            .inputType(.text)
            .keyboardType(.emailAddress)
            .onTyped({ value in
                self.emailTextBox.value(value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
            })
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalTo(cancelButton.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })

        passwordTextBox = TKTextBox.create()
            .placeholder("Password")
            .keyboardType(.default)
            .numberOfWordsLimit(GlobalFields.maxPasswordLength)
            .isPassword(true)
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalTo(emailTextBox.snp.bottom).offset(10)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })

        repeatPasswordTextBox = TKTextBox.create()
            .placeholder("Repeat the password")
            .keyboardType(.default)
            .numberOfWordsLimit(GlobalFields.maxPasswordLength)
            .isPassword(true)
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalTo(passwordTextBox.snp.bottom).offset(10)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })
    }

    override func bindEvent() {
        view.onViewTapped { [weak self] _ in
            self?.hide()
        }

        backView.onViewTapped { _ in
        }

        cancelButton.onTapped { [weak self] _ in
            self?.hide()
        }
        saveButton.onTapped { [weak self] _ in
            self?.onSaveButtonTapped()
        }
    }
}

extension ProfileLinkEmailController {
    private func onSaveButtonTapped() {
        logger.debug("save button tapped")
        view.endEditing(true)
        showFullScreenLoading()
        guard emailTextBox.getValue() != "" else {
            emailTextBox.showWrong()
            return
        }
        guard SL.FormatChecker.shared.isEmail(emailTextBox.getValue()) else {
            emailTextBox.showWrong()
            return
        }

        if !isUpdateEmail {
            guard passwordTextBox.getValue() != "" else {
                passwordTextBox.showWrong()
                return
            }
            guard repeatPasswordTextBox.getValue() != "" else {
                repeatPasswordTextBox.showWrong()
                return
            }

            if repeatPasswordTextBox.getValue() != passwordTextBox.getValue() {
                repeatPasswordTextBox.showWrong()
                return
            }
        }

        CommonsService.shared.emailValidVerify(email: emailTextBox.getValue())
            .done { [weak self] isValid in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if isValid {
                    self.hide { [weak self] in
                        guard let self = self else { return }
                        if self.isUpdateEmail {
                            self.delegate?.profileLinkEmailController(updateEmail: self.emailTextBox.getValue())
                        } else {
                            self.delegate?.profileLinkEmailController(save: self.emailTextBox.getValue(), password: self.passwordTextBox.getValue())
                        }
                    }
                } else {
                    WrongEmailAlert.show(withEmail: self.emailTextBox.getValue().lowercased()) { isContinue in
                        guard isContinue else {
                            self.emailTextBox.showWrong()
                            return
                        }
                        self.hide { [weak self] in
                            guard let self = self else { return }
                            if self.isUpdateEmail {
                                self.delegate?.profileLinkEmailController(updateEmail: self.emailTextBox.getValue())
                            } else {
                                self.delegate?.profileLinkEmailController(save: self.emailTextBox.getValue(), password: self.passwordTextBox.getValue())
                            }
                        }
                    }
                }
            }
            .catch { [weak self] _ in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                TKToast.show(msg: TipMsg.emailValidationFalse, style: .error)
                self.emailTextBox.showWrong()
            }
    }
}
