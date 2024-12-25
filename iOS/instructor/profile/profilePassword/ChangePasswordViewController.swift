//
//  ChangePasswordViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/27.
//  Copyright © 2019年 spelist. All rights reserved.
//


import UIKit
import FirebaseAuth

class ChangePasswordViewController: SLBaseScrollViewController {
    enum Style {
        case change
        case reset
    }

    var style: Style = .change {
        didSet {
            if inited {
                updateView()
            }
        }
    }

    private var navigationBar: TKNormalNavigationBar!

    private var isVerify: Bool = true
    
    private var sent: Bool = false

    private var oldPasswordTextBox: TKTextBox = TKTextBox.create()
        .placeholder("Your old password")
        .isPassword(true)
        .inputType(.text)
        .keyboardType(.default)

    private var newPasswordTextBox: TKTextBox = TKTextBox.create()
        .placeholder("Your new password")
        .isPassword(true)
        .inputType(.text)
        .keyboardType(.default)

    private var confirmNewPasswordTextBox: TKTextBox = TKTextBox.create()
        .placeholder("Confirm your new password")
        .isPassword(true)
        .inputType(.text)
        .keyboardType(.default)

    private var button: TKBlockButton = TKBlockButton(frame: .zero, title: "Verify", style: .normal)

    private var forgotPasswordButton: TKButton = TKButton()

    private var tipLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 15))
        .textColor(color: ColorUtil.Font.primary)
        .setNumberOfLines(number: 0)

    var email: String = ""

    private var verificationCodeKey: String = ""

    private var inited: Bool = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        oldPasswordTextBox.focus()
        if style == .reset {
            guard !sent else { return }
            sent = true
            logger.debug("发送验证码: \(sent)")
            onForgotPasswordButtonTapped()
        }
    }
}

extension ChangePasswordViewController {
    override func initView() {
        super.initView()
        enablePanToDismiss()
        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Change Password",target:self)
        navigationBar.updateLayout(target: self)
        updateContentViewOffsetTop(44)

        contentView.addSubview(view: oldPasswordTextBox) { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.height.equalTo(64)
        }

        forgotPasswordButton.titleFont(font: FontUtil.regular(size: 15))
            .titleColor(color: ColorUtil.main)
            .title(title: "Forgot password?")
            .addTo(superView: contentView) { make in
                make.top.equalTo(oldPasswordTextBox.snp.bottom).offset(10)
                make.right.equalTo(oldPasswordTextBox.snp.right)
                make.height.equalTo(20)
            }

        contentView.addSubview(view: newPasswordTextBox) { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.height.equalTo(64)
        }

        contentView.addSubview(view: confirmNewPasswordTextBox) { make in
            make.top.equalTo(newPasswordTextBox.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.height.equalTo(64)
        }

        contentView.addSubview(view: button) { make in
            make.top.equalToSuperview().offset(64 + 64 + 20 + 60)
            make.width.equalTo(180)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-80).priority(.medium)
        }

        contentView.addSubview(view: tipLabel) { make in
            make.top.equalTo(oldPasswordTextBox.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
        }

        newPasswordTextBox.isHidden = true
        confirmNewPasswordTextBox.isHidden = true
        button.disable()

        updateView()
        inited = true
    }

    private func updateView() {
        switch style {
        case .change:
            navigationBar.title = "Change Password"
            forgotPasswordButton.title(title: "Forgot password?")
            oldPasswordTextBox.placeholder("Your old password")
                .isPassword(true)
        case .reset:
            navigationBar.title = "Reset Password"
            forgotPasswordButton.title(title: "Resend")
            oldPasswordTextBox.placeholder("Verification code")
                .isPassword(false)
        }
    }
}

extension ChangePasswordViewController {
    override func bindEvent() {
        super.bindEvent()

        oldPasswordTextBox.onTyped { [weak self] oldPassword in
            guard let self = self else { return }
            switch self.style {
            case .change:
                if oldPassword.count >= 6 {
                    self.button.enable()
                } else {
                    self.button.disable()
                }
            case .reset:
                if oldPassword.count == 4 {
                    self.button.enable()
                } else {
                    self.button.disable()
                }
            }
        }

        newPasswordTextBox.onTyped { [weak self] newPassword in
            guard let self = self else { return }
            let confirmNewPassword = self.confirmNewPasswordTextBox.getValue()
            if newPassword == confirmNewPassword && newPassword.count >= 6 {
                self.button.enable()
            } else {
                self.button.disable()
            }
        }

        confirmNewPasswordTextBox.onTyped { [weak self] confirmNewPassword in
            guard let self = self else { return }
            let newPassword = self.newPasswordTextBox.getValue()
            if newPassword == confirmNewPassword && newPassword.count >= 6 {
                self.button.enable()
            } else {
                self.button.disable()
            }
        }

        button.onTapped { [weak self] _ in
            guard let self = self else { return }
            switch self.style {
            case .change:
                if self.isVerify {
                    self.verifyOldPassword()
                } else {
                    self.changePassword()
                }
            case .reset:
                if self.isVerify {
                    self.verifyVerificationCode()
                } else {
                    self.changePasswordWithoutLogin()
                }
            }
        }

        forgotPasswordButton.onTapped { [weak self] _ in
            self?.onForgotPasswordButtonTapped()
        }
    }

    private func onForgotPasswordButtonTapped() {
        logger.debug("准备调用发送验证码")
        sent = true
        if email == "" {
            guard let user = Auth.auth().currentUser, let email = user.email else {
                TKToast.show(msg: "Get user email failed", style: .error)
                return
            }
            self.email = email
        }
        logger.debug("发送验证码到邮箱: \(email)")
        view.endEditing(true)
        showFullScreenLoading()
        CommonsService.shared.sendVerificationCodeToEmail(email: email, completion: { [weak self] isSuccess, key in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            self.tipLabel.attributedText = Tools.attributenStringColor(text: "The verification code has been sent to \(self.email), please check it!", selectedText: self.email, allColor: ColorUtil.Font.primary, selectedColor: ColorUtil.main, font: FontUtil.regular(), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 1)
            self.tipLabel.onViewTapped { _ in
                Tools.openEmailClient()
            }
            if isSuccess {
                self.oldPasswordTextBox.focus()
                self.style = .reset
                self.verificationCodeKey = key!
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                        self.oldPasswordTextBox.snp.updateConstraints { make in
                            make.right.equalToSuperview().offset(-100)
                        }
                        self.forgotPasswordButton.snp.remakeConstraints { make in
                            make.centerY.equalTo(self.oldPasswordTextBox.snp.centerY)
                            make.left.equalTo(self.oldPasswordTextBox.snp.right).offset(4)
                        }
                    }, completion: nil)
                }
                self.forgotPasswordButton.timeDown(time: 60, onTimeDown: { [weak self] time in
                    guard let self = self else { return }
                    self.forgotPasswordButton.title(title: "\(time)s")
                    self.forgotPasswordButton.isEnabled = false
                }) { [weak self] in
                    guard let self = self else { return }
                    self.forgotPasswordButton.title(title: "Resend")
                    self.forgotPasswordButton.isEnabled = true
                }
            } else {
                TKToast.show(msg: "Send email failed, please try again later", style: .error)
            }
        })
    }

    private func verifyVerificationCode() {
        // 验证验证码
        if email == "" {
            guard let user = Auth.auth().currentUser, let email = user.email else {
                TKToast.show(msg: "Get user email failed", style: .error)
                return
            }
            self.email = email
        }
        let code = oldPasswordTextBox.getValue()
        guard code.count == 4 else {
            return
        }
        button.startLoading(at: view) { [weak self] in
            guard let self = self else { return }
            CommonsService.shared.checkVerificationCode(email: self.email, code: code, key: self.verificationCodeKey) { isSuccess, key in
                if isSuccess, let key = key {
                    self.isVerify = false
                    self.verificationCodeKey = key
                    self.button.stopLoading {
                        self.newPasswordTextBox.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
                        self.confirmNewPasswordTextBox.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
                        self.newPasswordTextBox.isHidden = false
                        self.confirmNewPasswordTextBox.isHidden = false
                        self.tipLabel.text = ""
                        self.forgotPasswordButton.isHidden = true
                        self.button.setTitle(title: "Change")
                        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                            self.newPasswordTextBox.transform = .identity
                            self.confirmNewPasswordTextBox.transform = .identity
                            self.oldPasswordTextBox.transform = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
                        }) { _ in
                            self.newPasswordTextBox.focus()
                            self.button.disable()
                        }
                    }
                } else {
                    self.isVerify = true
                    self.button.stopLoadingWithFailed {
                        TKToast.show(msg: TipMsg.invalidVerificationCode, style: .error)
                    }
                }
            }
        }
    }

    private func verifyOldPassword() {
        let oldPassword = oldPasswordTextBox.getValue()
        guard oldPassword.count >= 6 else {
            return
        }
        guard let user = Auth.auth().currentUser else {
            TKToast.show(msg: "Get user detail error", style: .error)
            return
        }
        logger.debug("校验旧密码是否正确: \(user.email!) | \(oldPasswordTextBox.getValue())")
        button.startLoading(at: view) { [weak self] in
            guard let self = self else { return }
            Auth.auth().signIn(withEmail: user.email!, password: self.oldPasswordTextBox.getValue().trimmingCharacters(in: .whitespacesAndNewlines)) { _, err in
                if let err = err {
                    self.isVerify = true
                    logger.error("password error: \(err)")
                    self.button.stopLoadingWithFailed()
                    TKToast.show(msg: TipMsg.oldPasswordError, style: .error)
                } else {
                    self.button.setTitle(title: "Change")
                    self.button.stopLoading {
                        self.isVerify = false
                        DispatchQueue.main.async {
                            self.newPasswordTextBox.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
                            self.confirmNewPasswordTextBox.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
                            self.newPasswordTextBox.isHidden = false
                            self.confirmNewPasswordTextBox.isHidden = false

                            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                                self.newPasswordTextBox.transform = .identity
                                self.confirmNewPasswordTextBox.transform = .identity
                                self.oldPasswordTextBox.transform = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
                                self.forgotPasswordButton.transform = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
                            }) { _ in
                                self.newPasswordTextBox.focus()
                                self.button.disable()
                            }
                        }
                    }
                }
            }
        }
    }

    private func changePassword() {
        let newPassword = newPasswordTextBox.getValue()
        let confirmNewPassword = confirmNewPasswordTextBox.getValue()

        guard newPassword == confirmNewPassword else {
            TKToast.show(msg: "New password and confirmation password are inconsistent", style: .error)
            return
        }

        button.startLoading(at: view) { [weak self] in
            guard let self = self else { return }
            Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { err in
                if let err = err {
                    logger.error("Update password error: \(err)")
                    TKToast.show(msg: "Changed password failed, try again later!", style: .warning)
                    self.button.stopLoadingWithFailed()
                } else {
                    if let user = ListenerService.shared.user, let email = user.loginMethod.first(where: { $0.method == .email })?.account {
                        if var item = SLCache.LoginHistory.fetch(withEmail: email) {
                            item.password = newPassword
                            SLCache.LoginHistory.save(item)
                        }
                    }
                    self.button.stopLoading { [weak self] in
                        self?.dismiss(animated: true, completion: nil)
                    }
                }
            })
        }
    }

    private func changePasswordWithoutLogin() {
        // checkVerificationKeyAndUpdatePassword
        let newPassword = newPasswordTextBox.getValue()
        let confirmNewPassword = confirmNewPasswordTextBox.getValue()

        guard newPassword == confirmNewPassword else {
            TKToast.show(msg: "New password and confirmation password are inconsistent", style: .error)
            return
        }

        if email == "" {
            guard let user = Auth.auth().currentUser, let email = user.email else {
                TKToast.show(msg: "Get user email failed", style: .error)
                return
            }
            self.email = email
        }

        button.startLoading(at: view) {
            CommonsService.shared.checkVerificationKeyAndUpdatePassword(key: self.verificationCodeKey, password: newPassword, email: self.email) { err in
                if let err = err {
                    logger.error("更改失败: \(err)")
                    self.button.stopLoadingWithFailed {
                        TKToast.show(msg: "Update password failed", style: .error)
                    }
                } else {
                    self.button.stopLoading {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
}

extension ChangePasswordViewController: ChangePasswordTableViewCellDelegate {
    func changePasswordTableViewCell(changeButtonTapped button: TKBlockButton, oldPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser else {
            return
        }
        button.startLoading {
            Auth.auth().signIn(withEmail: user.email!, password: oldPassword) { _, err in
                if let err = err {
                    logger.error("password error: \(err)")
                    button.stopLoadingWithFailed()
                    TKToast.show(msg: TipMsg.oldPasswordError, style: .error)
                } else {
                    Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { err in
                        if let err = err {
                            logger.error("Update password error: \(err)")
                            TKToast.show(msg: TipMsg.changePasswordFailed, style: .warning)
                            button.stopLoadingWithFailed()
                        } else {
                            button.stopLoading { [weak self] in
                                self?.dismiss(animated: true, completion: nil)
                            }
                        }
                    })
                }
            }
        }
    }

    func changePasswordTableViewCellShowPasswordError(msg: String) {
        TKToast.show(msg: msg, style: .error)
    }
}

// extension ChangePasswordViewController: UITableViewDelegate, UITableViewDataSource {
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UIScreen.main.bounds.height > UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ChangePasswordTableViewCell.self), for: indexPath) as! ChangePasswordTableViewCell
//        cell.delegate = self
//        return cell
//    }
// }
