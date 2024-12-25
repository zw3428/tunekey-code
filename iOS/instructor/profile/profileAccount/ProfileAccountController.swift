//
//  ProfileAccountController.swift
//  TuneKey
//
//  Created by WHT on 2020/3/9.
//  Copyright © 2020 spelist. All rights reserved.
//
import AuthenticationServices
import CryptoKit
import FBSDKLoginKit
import FirebaseAuth
import SnapKit
import UIKit
import GoogleSignIn
import GTMAppAuth

class ProfileAccountController: TKBaseViewController {
    var mainView = UIView()

    var emailView: TKView! = TKView.create()
        .backgroundColor(color: UIColor.white)
        .corner(size: 5)
        .showShadow()
        .showBorder(color: ColorUtil.borderColor)
    var emailAccountLabel: TKLabel! = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .alignment(alignment: .right)
        .textColor(color: ColorUtil.Font.primary)
    var googleView: TKView! = TKView.create()
        .backgroundColor(color: UIColor.white)
        .showShadow()
        .corner(size: 5)
        .showBorder(color: ColorUtil.borderColor)
    var googleAccountLabel: TKLabel! = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .alignment(alignment: .right)
        .textColor(color: ColorUtil.Font.primary)
    var facebookView: TKView! = TKView.create()
        .backgroundColor(color: UIColor.white)
        .showShadow()
        .corner(size: 5)
        .showBorder(color: ColorUtil.borderColor)
    var facebookAccountLabel: TKLabel! = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .alignment(alignment: .right)
        .textColor(color: ColorUtil.Font.primary)
    var appleView: TKView! = TKView.create()
        .backgroundColor(color: UIColor.white)
        .showShadow()
        .corner(size: 5)
        .showBorder(color: ColorUtil.borderColor)
    var appleAccountLabel: TKLabel! = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .alignment(alignment: .right)
        .textColor(color: ColorUtil.Font.primary)
    var userData: TKUser!
    var currentNonce: String?

    var deleteAccountButton: TKButton = TKButton.create()
        .titleFont(font: FontUtil.regular(size: 15))
        .title(title: "Delete account?")
        .titleColor(color: ColorUtil.red)
    private var setPasswordString = ""

    var navigationBar: TKNormalNavigationBar!
    private var facebookLoginManager: LoginManager?

    private var reauthCompletion: (() -> Void)?
    private var isUnlinkApple: Bool = false
    private var userId: String = ""

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let user = ListenerService.shared.user {
            userId = user.userId
        }
    }
}

// MARK: - View

extension ProfileAccountController {
    override func initView() {
        showFullScreenLoading()
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Sign-in Options", target: self)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        navigationBar.target = self
        initEmailView()
        initGoogleView()
        initFacebookView()
        if #available(iOS 13.0, *) {
            initAppleView()
        }
        deleteAccountButton.addTo(superView: mainView) { make in
//            if #available(iOS 13.0, *) {
//                make.top.equalTo(appleView.snp.bottom).offset(20)
//            } else {
//                make.top.equalTo(facebookView.snp.bottom).offset(20)
//            }
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-20)
        }
        deleteAccountButton.onTapped { [weak self] _ in
            self?.onDeleteAccountButtonTapped()
        }
    }

    func initEmailView() {
        emailView.addTo(superView: mainView) { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(navigationBar.snp.bottom).offset(20)
            make.height.equalTo(64)
        }
        emailView.onViewTapped { [weak self] _ in
            self?.clickEmailView()
        }
        let backView = TKView.create()
            .backgroundColor(color: UIColor(hex: "#3688FC")!)
            .corner(size: 16)
            .addTo(superView: emailView) { make in
                make.size.equalTo(32)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(20)
            }
        let imgView = TKImageView.create()
            .setImage(name: "account_email")
            .addTo(superView: backView) { make in
                make.center.equalToSuperview()
                make.size.equalTo(22)
            }
        let titleLabel = TKLabel.create()
            .text(text: "Email")
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.bold(size: 18))
            .addTo(superView: emailView) { make in
                make.centerY.equalToSuperview()
                make.width.equalTo(49)
                make.left.equalTo(imgView.snp.right).offset(20)
            }
        emailAccountLabel
            .addTo(superView: emailView) { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(20)
            }
    }

    func initGoogleView() {
        googleView.addTo(superView: mainView) { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(emailView.snp.bottom).offset(20)
            make.height.equalTo(64)
        }
        googleView.onViewTapped { [weak self] _ in
            self?.clickGoogleView()
        }
        let backView = TKView.create()
            .backgroundColor(color: UIColor(r: 220, g: 78, b: 65))
            .corner(size: 16)
            .addTo(superView: googleView) { make in
                make.size.equalTo(32)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(20)
            }
        let imgView = TKImageView.create()
            .setImage(name: "ic_google_plus_w")
            .addTo(superView: backView) { make in
                make.center.equalToSuperview()
                make.size.equalTo(22)
            }
        let titleLabel = TKLabel.create()
            .text(text: "Google")
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.bold(size: 18))
            .addTo(superView: googleView) { make in
                make.centerY.equalToSuperview()
                make.width.equalTo(65)
                make.left.equalTo(imgView.snp.right).offset(20)
            }
        googleAccountLabel
            .addTo(superView: googleView) { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(20)
            }
    }

    func initFacebookView() {
        facebookView
            .addTo(superView: mainView) { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.top.equalTo(googleView.snp.bottom).offset(20)
                make.height.equalTo(64)
            }
        facebookView.onViewTapped { [weak self] _ in
            self?.clickFacebook()
        }
        let backView = TKView.create()
            .backgroundColor(color: UIColor(r: 59, g: 89, b: 152))
            .corner(size: 16)
            .addTo(superView: facebookView) { make in
                make.size.equalTo(32)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(20)
            }
        let imgView = TKImageView.create()
            .setImage(name: "ic_fb_w")
            .addTo(superView: backView) { make in
                make.center.equalToSuperview()
                make.size.equalTo(22)
            }
        let titleLabel = TKLabel.create()
            .text(text: "Facebook")
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.bold(size: 18))
            .addTo(superView: facebookView) { make in
                make.centerY.equalToSuperview()
                make.width.equalTo(88)
                make.left.equalTo(imgView.snp.right).offset(20)
            }
        facebookAccountLabel
            .addTo(superView: facebookView) { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(20)
            }
    }

    func initAppleView() {
        appleView
            .addTo(superView: mainView) { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.top.equalTo(facebookView.snp.bottom).offset(20)
                make.height.equalTo(64)
            }
        appleView.onViewTapped { [weak self] _ in
            if #available(iOS 13.0, *) {
                self?.clickAppleView()
            } else {
                // Fallback on earlier versions
            }
        }
        let backView = TKView.create()
            .backgroundColor(color: UIColor(hex: "#211F20")!)
            .corner(size: 16)
            .addTo(superView: appleView) { make in
                make.size.equalTo(32)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(20)
            }
        let imgView = TKImageView.create()
            .setImage(name: "ic_ap_w")
            .addTo(superView: backView) { make in
                make.center.equalToSuperview()
                make.size.equalTo(22)
            }
        let titleLabel = TKLabel.create()
            .text(text: "Apple")
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.bold(size: 18))
            .addTo(superView: appleView) { make in
                make.centerY.equalToSuperview()
                make.width.equalTo(60)
                make.left.equalTo(imgView.snp.right).offset(20)
            }
        appleAccountLabel
            .addTo(superView: appleView) { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(20)
            }
    }
}

extension ProfileAccountController: ProfileAccountDeleteWarningViewControllerDelegate {
    private func onDeleteAccountButtonTapped() {
        let controller = ProfileAccountDeleteWarningViewController()
        controller.delegate = self
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

    func profileAccountDeleteWarningViewController(deleteAccount isSuccess: Bool) {
        logger.debug("删除账号结果: \(isSuccess)")
        if isSuccess {
            if SLCache.main.getString(key: SLCache.ACCOUNT_HISTORY) != "" {
                if var accountData = [TKAccountHistory].deserialize(from: SLCache.main.getString(key: SLCache.ACCOUNT_HISTORY)) as? [TKAccountHistory] {
                    if accountData.count > 0 {
                        accountData = accountData.filter({ data -> Bool in
                            data.account != self.emailAccountLabel.text ?? ""
                        })
                        SLCache.main.set(key: SLCache.ACCOUNT_HISTORY, value: accountData.toJSONString() ?? "")
                    }
                }
            }

            do {
                try Auth.auth().signOut()
                SL.Cache.shared.remove(key: "user:user_id")
                SL.Cache.shared.remove(key: "user:teacher")
                view.window?.rootViewController?.dismiss(animated: false, completion: nil)
            } catch {
                logger.error("sign out error: \(error)")
                TKToast.show(msg: "Failed to sign out, please try again later.", style: .error)
            }
        } else {
            TKToast.show(msg: "Failed to Delete account , please try again later.", style: .error)
        }
    }
}

// MARK: - Data

extension ProfileAccountController {
    override func initData() {
        addSubscribe(
            UserService.user.getInfo()
                .subscribe(onNext: { [weak self] user in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if let user = user[true] {
                        self.userData = user
                        self.initAccount()
                    }
                    if let user = user[false] {
                        self.userData = user
                        self.initAccount()
                    }
                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    logger.error("==获取User失败==\(err)")
                })
        )
    }

    func initAccount() {
        emailAccountLabel.text("Link")
        googleAccountLabel.text("Link")
        facebookAccountLabel.text("Link")
        appleAccountLabel.text("Link")

        for item in userData.loginMethod {
            switch item.method {
            case .phone:
                break
            case .email:
                emailAccountLabel.text(item.account)
                break
            case .google:
                googleAccountLabel.text(item.account)

                break
            case .facebook:
                facebookAccountLabel.text(item.account)
                break
            case .apple:
                appleAccountLabel.text(item.account)
                break
            }
        }
    }

    func unlink(loginMethod: TKLoginMethodType) {
        logger.debug("unlink账号开始")
        if userData.loginMethod.count <= 1 {
            TKToast.show(msg: TipMsg.mustBindAccount, style: .warning)
            return
        }
        for item in Auth.auth().currentUser!.providerData {
            logger.debug("当前用户登录的提供方式: \(item.providerID)")
        }
        var providerId = ""
        switch loginMethod {
        case .phone:
            break
        case .email:
            providerId = "password"
            break
        case .google:
            providerId = "google.com"
            break
        case .facebook:
            providerId = "facebook.com"
            break
        case .apple:
            providerId = "apple.com"
        }
        for item in Auth.auth().currentUser!.providerData {
            print("=====\(item.providerID)")
        }

        SL.Alert.show(target: self, title: "Unlnik", message: TipMsg.unlink, leftButttonString: "UNLINK", rightButtonString: "CANCEL", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main) { [weak self] in
            guard let self = self else { return }
            self.showFullScreenLoading()
            if providerId == "apple.com" {
                self.unlinkAppleAccount()
            } else {
                self.unlinkOther(providerId: providerId, loginMethod: loginMethod)
            }

        } rightButtonAction: {
        }
    }

    func link(credential: AuthCredential, loginMethod: TKLoginMethodType) {
        logger.debug("link账号开始")
        var providerId = ""
        switch loginMethod {
        case .phone:
            break
        case .email:
            providerId = "password"
            break
        case .google:
            providerId = "google.com"
            break
        case .facebook:
            providerId = "facebook.com"
            break
        case .apple:
            providerId = "apple.com"
            break
        }

        if let currentUser = Auth.auth().currentUser {
            showFullScreenLoading()
            currentUser.link(with: credential) { [weak self] data, err in
                guard let self = self else { return }
                if let err = err {
                    OperationQueue.main.addOperation {
                        self.hideFullScreenLoading()
                    }
                    logger.debug("======\(err)")
                    if err._code == AuthErrorCode.requiresRecentLogin.rawValue {
                        self.reauthCompletion = { [weak self] in
                            self?.link(credential: credential, loginMethod: loginMethod)
                        }
                        self.showReauthPopViewController()
                    } else if err._code == 17021 {
                        // 被迫强制退出登录了,直接重新登录
                        self.reauthCompletion = { [weak self] in
                            self?.link(credential: credential, loginMethod: loginMethod)
                        }
                        self.showReauthPopViewController(isLogin: true)
                    } else if err._code == 17025 {
                        // MARK: - 问题: #305-1 => 替换为弹窗

                        SL.Alert.show(target: self, title: "Duplicate linking account", message: "This sign-in option is associated with a different TuneKey account.\nTo re-link, please login once more with this sign-in option transfer its association.", leftButttonString: "CANCEL", rightButtonString: "RE-LOGIN", leftButtonColor: ColorUtil.main, rightButtonColor: ColorUtil.main, leftButtonAction: {
                        }) { [weak self] in
                            guard let self = self else { return }
                            do {
                                try Auth.auth().signOut()
                                SL.Cache.shared.remove(key: "user:user_id")
                                SL.Cache.shared.remove(key: "user:teacher")
                                //                                 EventBus.send(key: EventBus.Key.signOut)
                                self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)
                            } catch {
                                logger.error("sign out error: \(error)")
                                TKToast.show(msg: "Failed to sign out, please try again later.", style: .error)
                            }
                        }
                    } else {
                        OperationQueue.main.addOperation {
                            TKToast.show(msg: TipMsg.linkFailed, style: .warning)
                        }
                    }
                } else {
                    if let data = data {
                        var newMethod = self.userData.loginMethod
                        var email = ""
                        for item in data.user.providerData {
                            if item.providerID == providerId {
                                email = item.email ?? ""
                            }
                        }

                        if providerId == "password" {
                            self.updatePassword()
                        } else {
                            OperationQueue.main.addOperation {
                                self.hideFullScreenLoading()
                                TKToast.show(msg: TipMsg.linkSuccessful, style: .success)
                            }
                        }

                        newMethod.append(TKLoginMethod(method: loginMethod, account: email))
                        self.userData.loginMethod = newMethod
                        self.updateUser()
                        self.initAccount()

                    } else {
                        TKToast.show(msg: TipMsg.linkFailed, style: .warning)
                    }
                }
            }
        } else {
            logger.debug("未获取到当前用户")
        }
    }

    func updateUser() {
        addSubscribe(
            UserService.user.updateUser(data: ["loginMethod": userData.loginMethod.toJSON()])
                .subscribe(onNext: { _ in
                    logger.debug("===更新成功===")
                }, onError: { err in
                    logger.debug("===更新失败===\(err)")
                })
        )
    }

    func updatePassword() {
        if let userId = UserService.user.id() {
            addSubscribe(
                CommonsService.shared.changePassword(userId: userId, password: setPasswordString)
                    .subscribe(onNext: { [weak self] () in
                        guard let self = self else { return }
                        OperationQueue.main.addOperation {
                            self.hideFullScreenLoading()
                            TKToast.show(msg: TipMsg.linkSuccessful, style: .success)
                        }
                    }, onError: { [weak self] err in
                        guard let self = self else { return }
                        OperationQueue.main.addOperation {
                            self.hideFullScreenLoading()
                            TKToast.show(msg: TipMsg.linkSuccessful, style: .success)
                        }
                        logger.debug("获取失败:\(err)")
                    })
            )
        } else {
            OperationQueue.main.addOperation {
                self.hideFullScreenLoading()
                TKToast.show(msg: TipMsg.linkSuccessful, style: .success)
            }
        }
    }

    private func showReauthPopViewController(isLogin: Bool = false) {
        guard userId.count > 0 else { return }
        let controller = ReauthPopViewController(userId: userId)
        controller.delegate = self
        controller.modalPresentationStyle = .custom
        controller.isLogin = isLogin
        present(controller, animated: false, completion: nil)
    }

    private func unlinkOther(providerId: String, loginMethod: TKLoginMethodType, completion: VoidFunc? = nil) {
        Auth.auth().currentUser?.unlink(fromProvider: providerId, completion: { [weak self] data, err in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let err = err {
                logger.error("Unlink失败: \(err)")
                let nserr = err as NSError
                if nserr.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    // 重新登录凭据
                    self.reauthCompletion = { [weak self] in
                        self?.unlink(loginMethod: loginMethod)
                    }
                    self.showReauthPopViewController()
                } else if nserr.code == 17021 {
                    // 被迫强制退出登录了,直接重新登录
                    self.reauthCompletion = { [weak self] in
                        self?.unlink(loginMethod: loginMethod)
                    }
                    self.showReauthPopViewController(isLogin: true)
                } else {
                    TKToast.show(msg: TipMsg.unlinkFailed, style: .warning)
                }
            }
            if data != nil {
                TKToast.show(msg: TipMsg.unlinkSuccessful, style: .success)
                logger.debug("======成功")
                for item in self.userData.loginMethod.enumerated() where item.element.method == loginMethod {
                    self.userData.loginMethod.remove(at: item.offset)
                    break
                }
                self.updateUser()
                self.initAccount()
                completion?()
            }
        })
    }

    private func unlinkAppleAccount() {
        isUnlinkApple = true
        if #available(iOS 13, *) {
            startSignInWithAppleFlow()
        }
    }
}

extension ProfileAccountController: ReauthPopViewControllerDelegate {
    func reauthPopViewControllerDidFinished() {
        logger.debug("执行回调方法")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.showFullScreenLoading()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.reauthCompletion?()
            }
        }
    }
}

// MARK: - Action

extension ProfileAccountController: ProfileLinkEmailControllerDelegate {
    func clickEmailView() {
        guard let userData else { return }
        if userData.loginMethod.count == 1 {
            logger.debug("当前登录方法只有一个")
            if userData.loginMethod[0].method == .email {
                logger.debug("当前只有一个登录方法,而且是email,所以当前点击email是直接更换")
                reauthCompletion = { [weak self] in
                    guard let self = self else { return }
                    let controller = ProfileLinkEmailController()
                    controller.isUpdateEmail = true
                    controller.modalPresentationStyle = .custom
                    controller.delegate = self
                    self.present(controller, animated: false, completion: nil)
                }
                showReauthPopViewController()
            } else {
                logger.debug("当前只有一个登录方法,但是不是email,所以当前点击email是添加")
                let controller = ProfileLinkEmailController()
                controller.modalPresentationStyle = .custom
                controller.delegate = self
                present(controller, animated: false, completion: nil)
            }
        } else {
            for item in userData.loginMethod where item.method == .email {
                unlink(loginMethod: .email)
                return
            }
            let controller = ProfileLinkEmailController()
            controller.modalPresentationStyle = .custom
            controller.delegate = self
            present(controller, animated: false, completion: nil)
        }
    }

    func profileLinkEmailController(save email: String, password: String) {
        showFullScreenLoading()
        print("设置的账号:\(email) 密码:\(password)")
        setPasswordString = password
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        link(credential: credential, loginMethod: .email)
    }

    func profileLinkEmailController(updateEmail email: String) {
        logger.debug("更新email")
        showFullScreenLoading()
        Auth.auth().currentUser?.updateEmail(to: email.lowercased(), completion: { [weak self] error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            self.userData.loginMethod.forEachItems { method, index in
                if method.method == .email {
                    self.userData.loginMethod[index].account = email.lowercased()
                }
            }
            if let error = error {
                logger.error("更新失败: \(error)")
                TKToast.show(msg: "Update email failed, reason: \(error.localizedDescription)", style: .error)
            } else {
                self.updateUser()
                self.initAccount()
                TKToast.show(msg: "Update email success", style: .success)
            }
        })
    }

    func clickGoogleView() {
        for item in userData.loginMethod where item.method == .google {
            unlink(loginMethod: .google)

            return
        }
//        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
//        GIDSignIn.sharedInstance().delegate = self
//        GIDSignIn.sharedInstance().presentingViewController = self
//        GIDSignIn.sharedInstance().signIn()
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            guard let self = self else { return }
            if let error {
                let _error = error as NSError
                let msg: String
                var style: TKToast.Style = .error
                switch _error.code {
                case GIDSignInError.unknown.rawValue, GIDSignInError.EMM.rawValue:
                    msg = "Oops! Something went wrong. Please try again."
                case GIDSignInError.canceled.rawValue:
                    msg = "Looks like you've canceled. Feel free to try again."
                    style = .info
                case GIDSignInError.keychain.rawValue, GIDSignInError.hasNoAuthInKeychain.rawValue:
                    msg = "Something went wrong in your keychain, please try again later."
                default: return
                }
                TKToast.show(msg: msg, style: style)
            } else {
                guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                logger.debug("token: \(idToken) | \(user.accessToken.tokenString)")
                DispatchQueue.main.async { [weak self] in
                    self?.showFullScreenLoading()
                }
                link(credential: credential, loginMethod: .google)
            }
        }
    }

//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//        if let error = error {
//            let _error = error as NSError
//            logger.error("登录失败: \(_error.code)")
//            let msg: String
//            var style: TKToast.Style = .error
//            switch _error.code {
//            case GIDSignInErrorCode.unknown.rawValue, GIDSignInErrorCode.EMM.rawValue:
//                msg = "Oops! Something went wrong. Please try again."
//            case GIDSignInErrorCode.canceled.rawValue:
//                msg = "Looks like you've canceled. Feel free to try again."
//                style = .info
//            case GIDSignInErrorCode.keychain.rawValue, GIDSignInErrorCode.hasNoAuthInKeychain.rawValue:
//                msg = "Something went wrong in your keychain, please try again later."
//            default: return
//            }
//            TKToast.show(msg: msg, style: style)
//            return
//        }
//        guard let authentication = user.authentication else { return }
//        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
//        logger.debug("token: \(String(describing: authentication.idToken)) | \(String(describing: authentication.accessToken))")
//        DispatchQueue.main.async { [weak self] in
//            self?.showFullScreenLoading()
//        }
//        link(credential: credential, loginMethod: .google)
//    }

    func clickFacebook() {
        for item in userData.loginMethod where item.method == .facebook {
            unlink(loginMethod: .facebook)
            return
        }
        showFullScreenLoading()
        if facebookLoginManager == nil {
            facebookLoginManager = LoginManager()
        }
        facebookLoginManager?.logOut()
        facebookLoginManager?.logIn(permissions: ["email"], from: self, handler: { [weak self] result, error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let err = error {
                logger.error("facebook 登录失败: \(err)")
                DispatchQueue.main.async { [weak self] in
                    self?.hideFullScreenLoading()
                    TKToast.show(msg: "Failed, try again later", style: .warning)
                }
            } else {
                guard let result = result else {
                    DispatchQueue.main.async { [weak self] in
                        self?.hideFullScreenLoading()
                        TKToast.show(msg: "Failed, try again later", style: .warning)
                    }
                    return
                }
                if result.isCancelled {
                    DispatchQueue.main.async { [weak self] in
                        self?.hideFullScreenLoading()
//                        TKToast.show(msg: "You canceled", style: .warning)
                    }
                } else {
                    let credential = FacebookAuthProvider.credential(withAccessToken: result.token!.tokenString)
                    DispatchQueue.main.async { [weak self] in
                        self?.showFullScreenLoading()
                    }
                    logger.debug("Facebook登录回调: \(result.token!.tokenString)")
                    self.link(credential: credential, loginMethod: .facebook)
                }
            }
        })
    }
}

@available(iOS 13.0, *)
extension ProfileAccountController: ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    // MARK: - Apple

    func clickAppleView() {
        for item in userData.loginMethod where item.method == .apple {
            unlink(loginMethod: .apple)
            return
        }
        startSignInWithAppleFlow()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    @available(iOS 13, *)
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
//                TKToast.show(msg: TipMsg.unknowErrorForLogin, style: .error)
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                TKToast.show(msg: "Unable to fetch identity token", style: .error)
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                TKToast.show(msg: "Unable to serialize token string from data: \(appleIDToken.debugDescription)", style: .error)
                return
            }
            updateUI { [weak self] in
                self?.showFullScreenLoadingNoAutoHide()
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            if isUnlinkApple {
                guard let authorizationCode = appleIDCredential.authorizationCode,
                      let codeString = String(data: authorizationCode, encoding: .utf8) else {
                    return
                }
                Auth.auth().signIn(with: credential) { [weak self] data, error in
                    guard let self = self else { return }
                    self.isUnlinkApple = false
                    if let error = error {
                        logger.error("登录失败: \(error)")
                        TKToast.show(msg: "Re-auth failed, please try again later.", style: .error)
                    } else {
                        if let userId = data?.user.uid {
                            if userId == self.userId {
                                self.updateFullScreenLoadingMsg(msg: "Unlink Apple sign-in")
                                self.unlinkOther(providerId: "apple.com", loginMethod: .apple) {
                                    self.updateFullScreenLoadingMsg(msg: "Revoke Sign-in token from Apple Server")
                                    self.revokeAppleSignInToken(code: codeString)
                                }
                            } else {
                                TKToast.show(msg: "Wrong apple id", style: .error)
                            }
                        } else {
                            logger.error("登录失败,未获取到用户的UID")
                            TKToast.show(msg: "Sign-in failed, no such id can be found.", style: .error)
                        }
                    }
                }
            } else {
                link(credential: credential, loginMethod: .apple)
            }
        }
    }

    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        guard let err = error as? ASAuthorizationError else { return }
        let msg: String
        var style: TKToast.Style = .error
        switch err.code {
        case .unknown:
            msg = "Oops! Something went wrong. Please try again."
        case .canceled:
            msg = "Looks like you've canceled. Feel free to try again."
            style = .info
        case .invalidResponse:
            msg = "Hmm, we got an invalid response. Please try again later."
        case .notHandled:
            msg = "Sorry, we missed your request. Please try again."
        case .failed:
            msg = "Sorry, attempt failed. Please retry."
        case .notInteractive:
            msg = "Request needs your interaction. Please retry."
        }
        TKToast.show(msg: msg, style: style)
        logger.error("Sign in with Apple errored: \(error)")
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }

    private func revokeAppleSignInToken(code: String) {
        Functions.functions().httpsCallable("authService-revokeToken")
            .call(["code": code]) { [weak self] result, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("删除失败: \(error)")
                    SL.Alert.show(target: self, title: "Revoke token failed", message: "Revoke token failed, please disable apple id in your settings:\nSettings > Apple ID > Password & Security > Apps Using Apple ID > TuneKey > Stop Using Apple ID", leftButttonString: "Go back", rightButtonString: "Go to settings") {
                    } rightButtonAction: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        }
                    }
                } else {
                    TKToast.show(msg: "Unlink successfully", style: .success)
                    logger.debug("删除成功,返回结果: \(String(describing: result?.data))")
                }
            }
    }
}
