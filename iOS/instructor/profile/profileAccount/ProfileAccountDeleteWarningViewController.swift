//
//  ProfileAccountDeleteWarningViewController.swift
//  TuneKey
//
//  Created by zyf on 2020/7/22.
//  Copyright © 2020 spelist. All rights reserved.
//

import AuthenticationServices
import FirebaseAuth
import FirebaseFunctions
import NVActivityIndicatorView
import PromiseKit
import UIKit

protocol ProfileAccountDeleteWarningViewControllerDelegate: AnyObject {
    func profileAccountDeleteWarningViewController(deleteAccount isSuccess: Bool)
}

class ProfileAccountDeleteWarningViewController: UIViewController {
    weak var delegate: ProfileAccountDeleteWarningViewControllerDelegate?
    private let loadingView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: ColorUtil.main, padding: 0)

    private var isStep1: Bool = true

    private let contentView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 10)

    private let titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 20))
        .text(text: "Warning")
        .textColor(color: ColorUtil.red)
        .alignment(alignment: .center)

    private let msgLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.medium(size: 15))
        .setNumberOfLines(number: 0)

    private let textBox: TKTextBox = TKTextBox.create()
        .placeholder("DELETE")
        .isShowArrow(false)
        .isPassword(false)
        .keyboardType(.default)
        .inputType(.text)
    private let textBoxLine: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.dividingLine)
        .corner(size: 0.5)

    private let okButton: TKButton = TKButton.create()
        .titleColor(color: ColorUtil.red)
        .title(title: "DELETE")

    private let cancelButton: TKButton = TKButton.create()
        .titleColor(color: ColorUtil.main)
        .title(title: "CANCEL")

    private var currentUser: TKUser? = ListenerService.shared.user
    private var currentNonce: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        bindEvents()
    }

    private var isShowed: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
}

extension ProfileAccountDeleteWarningViewController {
    private func initView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.addTo(superView: view) { make in
            make.center.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(325)
        }
        contentView.clipsToBounds = true

        loadingView.addTo(superView: contentView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
        loadingView.isHidden = true

        titleLabel.addTo(superView: contentView) { make in
            make.top.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        msgLabel.addTo(superView: contentView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        msgLabel.attributedText = Tools.attributenStringColor(text: "If you delete your Tunekey account, there will be no way to retrieve it afterwards. Please enter \"DELETE\" in the input box to make sure you know the rick!", selectedText: "DELETE", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.red, font: FontUtil.medium(), fontSize: 15, selectedFontSize: 17, ignoreCase: false, charasetSpace: 1)

        textBox.addTo(superView: contentView) { make in
            make.top.equalTo(msgLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(64)
        }
        textBox.hideBorderAndShadowOnFocus(isHidden: true)
        textBoxLine.addTo(superView: contentView) { make in
            make.bottom.left.right.equalTo(textBox)
            make.height.equalTo(1)
        }

        okButton.addTo(superView: contentView) { make in
            make.bottom.left.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalTo(150)
        }

        cancelButton.addTo(superView: contentView) { make in
            make.bottom.right.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalTo(150)
        }
    }

    private func bindEvents() {
        cancelButton.onTapped { [weak self] _ in
            self?.hide {
            }
        }

        okButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            if self.isStep1 {
                // 第一步,判断输入框内容
                let text = self.textBox.getValue()
                if text.uppercased() == "DELETE" {
                    self.view.endEditing(true)
                    self.isStep1 = false
                    self.msgLabel.text = "Are you sure?"
                    _ = self.msgLabel.alignment(alignment: .center)
                    self.okButton.title(title: "YES")
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                        self.contentView.snp.updateConstraints { make in
                            make.height.equalTo(150)
                        }
                        self.textBox.transform = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
                        self.textBoxLine.transform = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
                        self.contentView.layoutIfNeeded()
                    }, completion: nil)
                } else {
                    self.textBoxLine.isHidden = true
                    self.textBox.showWrong {
                        self.textBox.hideBorderAndShadowOnFocus(isHidden: true)
                        self.textBoxLine.isHidden = false
                    }
                }
            } else {
                self.deleteAccount()
            }
        }
    }

    private func show() {
        guard !isShowed else { return }
        isShowed = true
        contentView.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.contentView.transform = .identity
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        }) { _ in
        }
    }

    private func hide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.contentView.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
        }) { _ in
            self.dismiss(animated: false, completion: {
                completion()
            })
        }
    }
}

extension ProfileAccountDeleteWarningViewController {
    private func deleteAccount() {
        // 动画将整个view变小成为一个园
        _ = contentView.subviews.compactMap { $0.isHidden = true }
        loadingView.layer.opacity = 0
        loadingView.isHidden = false
        loadingView.startAnimating()
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.contentView.snp.updateConstraints { make in
                make.width.equalTo(60)
                make.height.equalTo(60)
            }
            self.loadingView.layer.opacity = 1
            self.contentView.layoutIfNeeded()
        }) { [weak self] _ in
//            self?.deleteAccountOnDatabaseV2()
            self?.deleteAccountNext()
        }
    }

    private func deleteAccountNext() {
        guard let userId = UserService.user.id() else { return }
        UserService.user.getUser(id: userId)
            .done { [weak self] user in
                guard let self = self else { return }
                guard let user = user else { return }
                self.currentUser = user
                logger.debug("当前用户的所有登录方式: \(user.loginMethod.toJSONString() ?? "")")
                if user.loginMethod.contains(where: { $0.method == .apple }) {
                    // reauth apple signin
                    if #available(iOS 13, *) {
                        self.reauthApple()
                    } else {
                        self.deleteAccountOnDatabaseV2()
                    }
                } else {
                    self.deleteAccountOnDatabaseV2()
                }
            }
            .catch { _ in
                TKToast.show(msg: TipMsg.connectionFailed, style: .error)
            }
    }

    private func deleteAccountOnDatabase() {
        Functions.functions()
            .httpsCallable("deleteUserAccountAndAllData")
            .call(["uId": Auth.auth().currentUser?.uid ?? ""]) { [weak self] result, error in
                guard let self = self else { return }
                if let error = error {
                    logger.error("删除账号错误: \(error)")
//                    TKToast.show(msg: "Delete account failed, try again please", style: .error)
                    self.deleteAccountDone(isSuccess: false)
                } else {
                    if let funcResult = TKFuncResult.deserialize(from: result?.data as? [String: Any]) {
                        if funcResult.code == .success {
                            // 删除账号成功
                            self.deleteAccountDone(isSuccess: true)
                        }
                    } else {
                        logger.debug("解析返回结果失败: \(String(describing: result?.data))")
                        self.deleteAccountDone(isSuccess: false)
                    }
                }
            }
    }

    private func deleteAccountOnDatabaseV2() {
        let user = CacheUtil.UserInfo.getUser()
        Functions.functions()
            .httpsCallable("deleteTeacherAccount")
            .call { [weak self] result, error in
                guard let self = self else { return }
                if let error = error {
                    logger.error("删除账号错误: \(error)")
                    self.deleteAccountDone(isSuccess: false)
                } else {
                    if let funcResult = TKFuncResult.deserialize(from: result?.data as? [String: Any]) {
                        if funcResult.code == .success {
                            // 删除账号成功
                            LoggerUtil.shared.log(.deleteAccount, params: user?.toJSON() ?? [:])
                            self.deleteAccountDone(isSuccess: true)
                        }
                    } else {
                        logger.debug("解析返回结果失败: \(String(describing: result?.data))")
                        self.deleteAccountDone(isSuccess: false)
                    }
                }
            }
    }

    @available(iOS 13, *)
    private func reauthApple() {
        let nonce = Tools.randomNonceString()
        currentNonce = nonce
        let appleIDProvicer = ASAuthorizationAppleIDProvider()
        let request = appleIDProvicer.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Tools.sha256(nonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self

        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func deleteAccountDone(isSuccess: Bool) {
        hide {
            self.delegate?.profileAccountDeleteWarningViewController(deleteAccount: isSuccess)
        }
    }
}

extension ProfileAccountDeleteWarningViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window!
    }

    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        hide {
            TKToast.show(msg: TipMsg.connectionFailed, style: .error)
        }
    }

    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                TKToast.show(msg: TipMsg.unknowErrorForLogin, style: .error)
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                TKToast.show(msg: TipMsg.unknowErrorForLogin, style: .error)
                return
            }
            guard let authorizationCode = appleIDCredential.authorizationCode,
                  let codeString = String(data: authorizationCode, encoding: .utf8) else {
                return
            }
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: currentNonce)
            Auth.auth().signIn(with: credential) { [weak self] data, error in
                guard let self = self else { return }
                if let error = error {
                    logger.error("登录失败: \(error)")
                    TKToast.show(msg: "Re-auth failed, please try again later.", style: .error)
                } else {
                    if let userId = data?.user.uid {
                        logger.debug("登录的id: \(userId) | \(self.currentUser?.userId ?? "")")
                        if userId == self.currentUser?.userId ?? "" {
                            self.revokeAppleSignInToken(code: codeString)
                        } else {
                            TKToast.show(msg: "Wrong apple id", style: .error)
                        }
                    } else {
                        logger.error("登录失败,未获取到用户的UID")
                        TKToast.show(msg: "Sign-in failed, no such id can be found.", style: .error)
                    }
                }
            }
        }
    }

    private func revokeAppleSignInToken(code: String) {
        Functions.functions().httpsCallable("authService-revokeToken")
            .call(["code": code]) { [weak self] result, error in
                guard let self = self else { return }
                self.deleteAccountOnDatabaseV2()
                if let error = error {
                    logger.error("删除失败: \(error)")
                } else {
                    logger.debug("删除成功,返回结果: \(String(describing: result?.data))")
                }
            }
    }
}
