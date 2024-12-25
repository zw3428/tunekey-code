//
//  ProfileLinkCalendarViewController.swift
//  TuneKey
//
//  Created by zyf on 2020/7/8.
//  Copyright © 2020 spelist. All rights reserved.
//

import FirebaseCore
import EventKit
import FirebaseAuth
import GoogleAPIClientForREST
import NVActivityIndicatorView
import PromiseKit
import UIKit
import GoogleSignIn
import GTMAppAuth

class ProfileLinkCalendarViewController: SLBaseScrollViewController {
    struct ItemView {
        var itemView: TKView
        var iconView: TKImageView
        var titleLabel: TKLabel
        var detailLabel: TKLabel
        var loadingView: NVActivityIndicatorView
    }

    private var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Link Calendar")

    private var googleCalendarItemView: ItemView?
    private var appleCalendarItemView: ItemView?

    private var eventStore = EKEventStore()

    private var googleCalendarLinkStatus: Bool = false {
        didSet {
            updateUI()
        }
    }

    private var googleLinkedEmail: String = "" {
        didSet {
            updateUI()
        }
    }
}

extension ProfileLinkCalendarViewController {
    override func initView() {
        super.initView()

        navigationBar.updateLayout(target: self)

        updateContentViewOffsetTop(44)

        googleCalendarItemView = itemView(icon: "imgCalendarGoogle", title: "", detail: "Unlink")

        contentView.addSubview(view: googleCalendarItemView!.itemView) { make in
            make.top.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(64)
        }

        googleCalendarItemView?.itemView.onViewTapped({ [weak self] _ in
            self?.onGoogleCalendarTapped()
        })

        appleCalendarItemView = itemView(icon: "imgCalendarIOS", title: "", detail: "Unlink")
        contentView.addSubview(view: appleCalendarItemView!.itemView) { make in
            make.top.equalTo(googleCalendarItemView!.itemView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(64)
            make.bottom.equalToSuperview().offset(-40)
        }
        appleCalendarItemView?.itemView.onViewTapped({ [weak self] _ in
            self?.onAppleCalendarTapped()
        })
    }
}

extension ProfileLinkCalendarViewController {
    private func itemView(icon: String, title: String, detail: String) -> ItemView {
        let view = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
        let iconView = TKImageView.create()
            .setImage(name: icon)
            .addTo(superView: view) { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.size.equalTo(32)
            }
        let titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: title)
            .addTo(superView: view) { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(iconView.snp.right).offset(20)
            }
        let detailLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: detail)
            .alignment(alignment: .right)
            .addTo(superView: view) { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
            }
        let loadingView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: ColorUtil.main, padding: 0)
        loadingView.addTo(superView: view) { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }
        loadingView.startAnimating()
        return ItemView(itemView: view, iconView: iconView, titleLabel: titleLabel, detailLabel: detailLabel, loadingView: loadingView)
    }

    override func initData() {
        super.initData()

        let status = EKEventStore.authorizationStatus(for: .event)
        let detail: String
        if status == .authorized && CacheUtil.AppleCalendar.isLinked() {
            detail = UIDevice.current.name
        } else {
            detail = "Link Apple Calendar"
        }

        appleCalendarItemView?.detailLabel.text = detail
        appleCalendarItemView?.loadingView.isHidden = true
        googleCalendarItemView?.loadingView.isHidden = false
        googleCalendarItemView?.loadingView.startAnimating()
        googleCalendarItemView?.detailLabel.isHidden = true
        loadData()
    }

    private func loadData() {
        guard let uid = UserService.user.id() else { return }

        when(fulfilled: [checkGoogleAccessToken(uid: uid), checkGoogleCalendarEventsWatch(uid: uid)])
            .done { results in
                logger.debug("获取到的所有check结果: \(results)")
                var flag: Bool = true
                results.forEach { b in
                    if !b {
                        flag = false
                    }
                }
                self.googleCalendarLinkStatus = flag
            }
            .catch { error in
                logger.error("发生错误: \(error)")
                self.googleCalendarLinkStatus = false
            }

        getGoogleEmail()
    }

    private func getGoogleEmail() {
        DatabaseService.collections.googleEmail()
            .document(UserService.user.id() ?? "")
            .getDocument { snapshot, error in
                if let data = snapshot?.data(), let email = data["email"] as? String {
                    self.googleLinkedEmail = email
                } else {
                    logger.error("获取email失败: \(String(describing: error))")
                }
            }
    }

    private func checkGoogleCalendarEventsWatch(uid: String) -> Promise<Bool> {
        return Promise { resolver in
            DatabaseService.collections.googleCalendarEventsWatch()
                .document(uid)
                .getDocument { snapshot, error in
                    if let error = error {
                        logger.error("获取GoogleCalendarEventsWatch表出错: \(error)")
                        resolver.reject(error)
                    } else {
                        if snapshot?.exists ?? false {
                            resolver.fulfill(true)
                        } else {
                            resolver.fulfill(false)
                        }
                    }
                }
        }
    }

    private func checkGoogleAccessToken(uid: String) -> Promise<Bool> {
        return Promise { resolver in
            DatabaseService.collections.googleAccessTokenCalendar()
                .document(uid)
                .getDocument { snapshot, error in
                    if let error = error {
                        logger.error("获取accessTokenGoogle出错: \(error)")
                        resolver.reject(error)
                    } else {
                        if let tokenData = GoogleAuthToken.deserialize(from: snapshot?.data()) {
                            logger.debug("获取到的AccessToken: \(tokenData.toJSONString() ?? "nil")")
                            logger.debug("是否link: \(tokenData.isValid)")
                            resolver.fulfill(tokenData.isValid)
                        } else {
                            logger.debug("无法解析获取到的token数据: \(snapshot?.data() ?? [:])")
                            resolver.fulfill(false)
                        }
                    }
                }
        }
    }

    private func updateUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            logger.debug("更新UI: \(self.googleCalendarLinkStatus)")
            self.googleCalendarItemView?.loadingView.isHidden = true
            self.googleCalendarItemView?.detailLabel.isHidden = false
            self.googleCalendarItemView?.detailLabel.text = self.googleCalendarLinkStatus ? self.googleLinkedEmail : "Link Google Calendar"
            let detailForAppleCalendar: String

            if EKEventStore.authorizationStatus(for: .event) == .authorized && CacheUtil.AppleCalendar.isLinked() {
                detailForAppleCalendar = UIDevice.current.name
            } else {
                detailForAppleCalendar = "Link Apple Calendar"
            }
            self.appleCalendarItemView?.detailLabel.text = detailForAppleCalendar
        }
    }
}

extension ProfileLinkCalendarViewController {
    private func onGoogleCalendarTapped() {
        if googleCalendarLinkStatus {
            showCancelGoogleCalendarAlert()
        } else {
            // 获取原始token
            showFullScreenLoadingNoAutoHide()
            UserService.user.getGoogleAuthToken(type: .calendar)
                .done { [weak self] token in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if let token = token {
                        if !token.scope.contains(GlobalFields.GoogleAuthScope.calendar) {
                            var scopes: [String] = []
                            if token.scope.contains(GlobalFields.GoogleAuthScope.drive) {
                                scopes.append(GlobalFields.GoogleAuthScope.drive)
                            }
                            if token.scope.contains(GlobalFields.GoogleAuthScope.photo) {
                                scopes.append(GlobalFields.GoogleAuthScope.photo)
                            }
                            self.signInWithGoogle(originalScopes: scopes)
                            return
                        }
                    }
                    self.signInWithGoogle()
                }
                .catch { [weak self] error in
                    logger.error("获取授权失败,直接授权: \(error)")
                    self?.signInWithGoogle()
                }
        }
    }

    private func signInWithGoogle(originalScopes: [String] = []) {
//        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
//        GIDSignIn.sharedInstance()?.serverClientID = "276871124610-s00jpqv805isouub987hceercr7qsc0v.apps.googleusercontent.com"
////        var scopes = GIDSignIn.sharedInstance()?.scopes
////        scopes?.append(GlobalFields.GoogleAuthScope.calendar)
////        originalScopes.forEach { scope in
////            scopes?.append(scope)
////        }
//        GIDSignIn.sharedInstance().scopes = [GlobalFields.GoogleAuthScope.calendar]
//        GIDSignIn.sharedInstance().delegate = self
//        GIDSignIn.sharedInstance().presentingViewController = self
//        GIDSignIn.sharedInstance().signIn()
        
        GIDSignIn.sharedInstance.configuration = .init(clientID: FirebaseApp.app()?.options.clientID ?? "", serverClientID: "276871124610-s00jpqv805isouub987hceercr7qsc0v.apps.googleusercontent.com")
        GIDSignIn.sharedInstance.signIn(withPresenting: self, hint: nil, additionalScopes: [GlobalFields.GoogleAuthScope.calendar]) { [weak self] result, error in
            guard let self = self else { return }
            if let err = error {
                logger.error("登录失败: \(err)")
                TKToast.show(msg: "Link google calendar failed: \(err.localizedDescription)", style: .error)
                self.hideFullScreenLoading()
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.showFullScreenLoading()
                    if let user = result?.user, let serverAuthCode = result?.serverAuthCode {
                        if let email = user.profile?.email {
                            UserService.user.saveEmailForGoogleAuth(email)
                                .done { _ in
                                    logger.debug("保存用户Google Email成功")
                                    let token = user.accessToken.tokenString
                                    logger.debug("登录完成,token: \(String(describing: token))")
                                    logger.debug("登录完成,server auth code: \(serverAuthCode)")
                                    logger.debug("登录完成,scopes: \(String(describing: user.grantedScopes))")
                                    self.updateFullScreenLoadingMsg(msg: "Request google auth token")
                                    UserService.user.requestAuthForGoogle(code: serverAuthCode, type: .calendar)
                                        .then { _ -> Promise<Void> in
                                            logger.debug("准备注册监听")
                                            self.updateFullScreenLoadingMsg(msg: "Register notification")
                                            return CalendarService.google.registerNotification()
                                        }
                                        .then { _ -> Promise<Any?> in
                                            self.updateFullScreenLoadingMsg(msg: "Sync calendar data")
                                            return CalendarService.google.syncCalendar()
                                        }
                                        .done { [weak self] _ in
                                            guard let self = self else { return }
                                            self.loadData()
                                            self.hideFullScreenLoading()
                                            self.googleCalendarLinkStatus = true
                                            self.googleLinkedEmail = email
                                            self.updateUI()
                                        }
                                        .catch { [weak self] error in
                                            guard let self = self else { return }
                                            DispatchQueue.main.async {
                                                logger.error("同步失败: \(error)")
                                                self.updateFullScreenLoadingMsg(msg: "Link failed, reason: \(error)")
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                                                    self?.hideFullScreenLoading()
                                                }
                                            }
                                        }
                                }
                                .catch { _ in
                                    logger.error("保存用户Google Email失败: \(email)")
                                }
                        }
                    } else {
                        TKToast.show(msg: "You cancelled link google calendar", style: .warning)
                        self.hideFullScreenLoading()
                    }
                }
            }
        }
        
    }

//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//        if let err = error {
//            logger.error("登录失败: \(err)")
//            TKToast.show(msg: "Link google calendar failed: \(err.localizedDescription)", style: .error)
//            hideFullScreenLoading()
//        } else {
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                self.showFullScreenLoading()
//                if let user = user {
//                    if let email = user.profile.email {
//                        UserService.user.saveEmailForGoogleAuth(email)
//                            .done { _ in
//                                logger.debug("保存用户Google Email成功")
//                                let token = user.authentication.accessToken
//                                logger.debug("登录完成,token: \(String(describing: token))")
//                                logger.debug("登录完成,server auth code: \(String(describing: user.serverAuthCode))")
//                                logger.debug("登录完成,scopes: \(String(describing: user.grantedScopes))")
//                                self.updateFullScreenLoadingMsg(msg: "Request google auth token")
//                                UserService.user.requestAuthForGoogle(code: user.serverAuthCode, type: .calendar)
//                                    .then { _ -> Promise<Void> in
//                                        logger.debug("准备注册监听")
//                                        self.updateFullScreenLoadingMsg(msg: "Register notification")
//                                        return CalendarService.google.registerNotification()
//                                    }
//                                    .then { _ -> Promise<Any?> in
//                                        self.updateFullScreenLoadingMsg(msg: "Sync calendar data")
//                                        return CalendarService.google.syncCalendar()
//                                    }
//                                    .done { [weak self] _ in
//                                        guard let self = self else { return }
//                                        self.loadData()
//                                        self.hideFullScreenLoading()
//                                        self.googleCalendarLinkStatus = true
//                                        self.googleLinkedEmail = email
//                                        self.updateUI()
//                                    }
//                                    .catch { [weak self] error in
//                                        guard let self = self else { return }
//                                        DispatchQueue.main.async {
//                                            logger.error("同步失败: \(error)")
//                                            self.updateFullScreenLoadingMsg(msg: "Link failed, reason: \(error)")
//                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
//                                                self?.hideFullScreenLoading()
//                                            }
//                                        }
//                                    }
//                            }
//                            .catch { _ in
//                                logger.error("保存用户Google Email失败: \(email)")
//                            }
//                    }
//                } else {
//                    TKToast.show(msg: "You cancelled link google calendar", style: .warning)
//                    self.hideFullScreenLoading()
//                }
//            }
//        }
//    }

    private func showCancelGoogleCalendarAlert() {
        SL.Alert.show(target: self, title: "Unlink", message: "Are you sure you want to cancel the link? We won't be able to get your events from the Google calendar.", leftButttonString: "Cancel", rightButtonString: "Unlink") {
        } rightButtonAction: { [weak self] in
            DispatchQueue.main.async {
                self?.cancelGoogleCalendarLink()
            }
        }
    }

    private func cancelGoogleCalendarLink() {
        showFullScreenLoading()
        updateFullScreenLoadingMsg(msg: "Getting configration")
        getGoogleCalendarEventsWatchData()
            .then { (watchData) -> Promise<Void> in
                self.updateFullScreenLoadingMsg(msg: "Unregister linstener")
                return CalendarService.google.unregisterNotification(watchData: watchData)
            }
            .then { (_) -> Promise<Void> in
                self.updateFullScreenLoadingMsg(msg: "Removing configration")
                return CalendarService.google.removeAllEvents()
            }
            .then { (_) -> Promise<Void> in
                self.updateFullScreenLoadingMsg(msg: "Removing calendar events")
                return self.removeGoogleCalendarEventsWatch()
            }
            .then{ (_) -> Promise<Void> in
                self.updateFullScreenLoadingMsg(msg: "Removing token data")
                return self.removeGoogleCalendarEventsSyncToken()
            }
            .done { _ in
                logger.debug("解除成功")
                self.googleCalendarLinkStatus = false
                self.googleLinkedEmail = ""
                self.updateUI()
                self.hideFullScreenLoading()
                TKToast.show(msg: "Unlink google calendar successfully", style: .success)
                EventBus.send(key: .googleCalendarUnlink)
            }
            .catch { error in
                self.hideFullScreenLoading()
                TKToast.show(msg: "Unlink google calendar failed, reason: \(error)", style: .error)
                logger.error("发生错误: \(error)")
            }
    }

    private func getGoogleCalendarEventsWatchData() -> Promise<GoogleCalendarEventsWatch> {
        return Promise { resolver in
            guard let uid = UserService.user.id() else { return resolver.reject(TKError.userNotLogin) }
            DatabaseService.collections.googleCalendarEventsWatch()
                .document(uid)
                .getDocument { snapshot, error in
                    if let doc = snapshot, doc.exists, let watchData = GoogleCalendarEventsWatch.deserialize(from: doc.data()) {
                        resolver.fulfill(watchData)
                    } else {
                        resolver.reject(TKError.functionsError(error))
                    }
                }
        }
    }

    private func removeGoogleCalendarEventsWatch() -> Promise<Void> {
        return Promise { resolver in
            guard let uid = UserService.user.id() else { return resolver.reject(TKError.userNotLogin) }
            DatabaseService.collections.googleCalendarEventsWatch()
                .document(uid).delete { error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        resolver.fulfill(())
                    }
                }
        }
    }

    private func removeGoogleCalendarEventsSyncToken() -> Promise<Void> {
        return Promise { resolver in
            guard let uid = UserService.user.id() else { return resolver.reject(TKError.userNotLogin) }
            DatabaseService.collections.googleCalendarEventsSyncToken()
                .document(uid)
                .delete { error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        resolver.fulfill(())
                    }
                }
        }
    }
}

extension ProfileLinkCalendarViewController {
    private func onAppleCalendarTapped() {
        if EKEventStore.authorizationStatus(for: .event) == .authorized && CacheUtil.AppleCalendar.isLinked() {
            // 取消授权
            showCancelAppleCalendarAlert()
        } else {
            showFullScreenLoading()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self else { return }
                self.eventStore.requestAccess(to: .event) { [weak self] granted, error in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.hideFullScreenLoading()
                    }
                    logger.debug("授权结果: \(granted)  |  \(String(describing: error))")

                    if granted {
                        // 授权成功
                        if CacheUtil.AppleCalendar.isLinked() {
                            DispatchQueue.main.async {
                                self.showCancelAppleCalendarAlert()
                            }
                        }
                    } else {
                        logger.debug("用户点击取消了授权")
                        DispatchQueue.main.async {
                            SL.Alert.show(target: self, title: "Tip", message: "If you want to link apple canlendar, enter the system setting to open it.", leftButttonString: "OK", rightButtonString: "TO SETTING") {
                            } rightButtonAction: {
                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:]) { isSuccess in
                                    logger.debug("是否打开成功: \(isSuccess)")
                                }
                            }
                        }
                    }
                    if granted {
                        DispatchQueue.main.async {
                            TKToast.show(msg: "Link apple calendar successfully", style: .success)
                        }
                    }
                    CacheUtil.AppleCalendar.setLinked(granted)
                    EventBus.send(key: .appleCalendarStatusChanged)
                    self.updateUI()
                }
            }
        }
    }

    private func showCancelAppleCalendarAlert() {
        SL.Alert.show(target: self, title: "Unlink", message: "Are you sure you want to cancel the link? We won't be able to get your events from the Apple calendar.", leftButttonString: "Cancel", rightButtonString: "Unlink") {
        } rightButtonAction: { [weak self] in
            self?.cancelAppleCalendar()
        }
    }

    private func cancelAppleCalendar() {
        showFullScreenLoading()
        CacheUtil.AppleCalendar.setLinked(false)
        EventBus.send(key: .appleCalendarStatusChanged)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            TKToast.show(msg: "Unlink apple calendar successfully", style: .success)
            self?.hideFullScreenLoading()
            self?.updateUI()
        }
    }
}
