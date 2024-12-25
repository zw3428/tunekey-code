//
//  ParentEditKidProfileViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/11/29.
//  Copyright © 2022 spelist. All rights reserved.
//

import FirebaseFirestore
import FirebaseStorage
import PromiseKit
import RSKImageCropper
import SDWebImage
import SnapKit
import UIKit

class ParentEditKidProfileViewController: TKBaseViewController {
    private lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Edit Kid Profile")

    @Live var newAvatarImage: UIImage?
    @Live var user: TKUser

    init(_ kid: TKUser) {
        user = kid
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ParentEditKidProfileViewController {
    override func initView() {
        super.initView()
        navigationBar.updateLayout(target: self)
        ViewBox {
            VScrollStack {
                ViewBox(top: 20, left: (UIScreen.main.bounds.width - 80) / 2, bottom: 8, right: (UIScreen.main.bounds.width - 80) / 2) {
                    AvatarView(size: 80)
                        .backgroundColor(ColorUtil.main)
                        .apply { [weak self] avatarView in
                            guard let self = self else { return }
                            self.$user.addSubscriber { user in
                                guard self.newAvatarImage == nil else { return }
                                avatarView.loadAvatar(withUserId: user.userId, name: user.name).contentMode(.scaleAspectFill)
                            }
                            self.$newAvatarImage.addSubscriber { image in
                                if let image = image {
                                    avatarView.loadAvatar(withImage: image)
                                        .contentMode(.scaleAspectFill)
                                } else {
                                    avatarView.loadAvatar(withUserId: self.user.userId, name: self.user.name)
                                        .contentMode(.scaleAspectFill)
                                }
                            }
                        }
                        .onViewTapped { [weak self] _ in
                            self?.onChangeAvatarTapped()
                        }
                }
                HStack(alignment: .center) {
                    Button().title("Change avatar", for: .normal)
                        .titleColor(ColorUtil.main, for: .normal)
                        .font(.regular(size: 13))
                        .onTapped { [weak self] _ in
                            self?.onChangeAvatarTapped()
                        }
                }
                ViewBox(top: 20, left: 20, bottom: 10, right: 20) {
                    ViewBox(top: 20, left: 0, bottom: 0, right: 0) {
                        VStack {
                            ViewBox(left: 20, bottom: 10) {
                                Label("Information").textColor(ColorUtil.Font.primary).font(.regular(size: 13))
                            }
                            ViewBox(top: 10, right: 20) {
                                TextBox().placeholder("Full Name")
                                    .isShadowShow(false)
                                    .isBorderShow(false)
                                    .height(64)
                                    .apply { [weak self] _, textBox in
                                        guard let self = self else { return }
                                        self.$user.addSubscriber { user in
                                            textBox.value(user.name)
                                        }
                                    }
                            }.apply { view in
                                View().addTo(superView: view) { make in
                                    make.edges.equalToSuperview()
                                }.onViewTapped { [weak self] _ in
                                    self?.onNameTapped()
                                }
                            }
                            ViewBox {
                                Divider(weight: 1, color: ColorUtil.dividingLine)
                            }.height(1)
                            ViewBox(top: 10, right: 20) {
                                TextBox().placeholder("Phone")
                                    .isShadowShow(false)
                                    .isBorderShow(false)
                                    .height(64)
                                    .apply { [weak self] _, textBox in
                                        guard let self = self else { return }
                                        textBox.textField.isEnabled = false
                                        self.$user.addSubscriber { user in
                                            let phoneNumberString: String
                                            if let account = user.loginMethod.first(where: { $0.method == .phone }) {
                                                phoneNumberString = account.account
                                            } else {
                                                phoneNumberString = ""
                                            }
                                            logger.debug("用户phoneNumber设置: \(phoneNumberString)")
                                            var phoneNumber = phoneNumberString.getPhoneNumber()
                                            
                                            textBox.value(phoneNumber.phoneNumber.formatPhoneNumber())
                                                .prefix(phoneNumber.country)
                                        }
                                    }
                            }.apply { view in
                                View().addTo(superView: view) { make in
                                    make.edges.equalToSuperview()
                                }.onViewTapped { [weak self] _ in
                                    self?.onPhoneNumberTapped()
                                }
                            }
                            ViewBox {
                                Divider(weight: 1, color: ColorUtil.dividingLine)
                            }.height(1)
                            ViewBox(top: 10, right: 20) {
                                TextBox().placeholder("Sign-in email")
                                    .isShadowShow(false)
                                    .isBorderShow(false)
                                    .height(64)
                                    .apply { [weak self] _, textBox in
                                        guard let self = self else { return }
                                        self.$user.addSubscriber { user in
                                            var email: String
                                            if let account = user.loginMethod.first(where: { $0.method == .email }) {
                                                email = account.account
                                            } else {
                                                email = ""
                                            }
                                            if email.contains(GlobalFields.fakeEmailSuffix) {
                                                email = ""
                                            }
                                            textBox.value(email)
                                        }
                                    }
                            }.apply { view in
                                View().addTo(superView: view) { make in
                                    make.edges.equalToSuperview()
                                }.onViewTapped { [weak self] _ in
                                    self?.onEmailTapped()
                                }
                            }
                            ViewBox {
                                Divider(weight: 1, color: ColorUtil.dividingLine)
                            }.height(1)
                            ViewBox(top: 10, right: 20) {
                                TextBox().placeholder("TimeZone")
                                    .isShadowShow(false)
                                    .isBorderShow(false)
                                    .height(64)
                                    .apply { [weak self] _, textBox in
                                        guard let self = self else { return }
                                        textBox.textField.isEnabled = false
                                        self.$user.addSubscriber { user in
                                            textBox.value(user.timeZone)
                                        }
                                    }
                            }.apply { view in
                                View().addTo(superView: view) { make in
                                    make.edges.equalToSuperview()
                                }.onViewTapped { [weak self] _ in
                                    self?.onTimeZoneTapped()
                                }
                            }
                        }
                    }.cardStyle()
                }
            }
            .applyScrollView { view in
                view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UiUtil.safeAreaBottom() + 70, right: 0)
            }
        }
        .addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

extension ParentEditKidProfileViewController {
    private func onEmailTapped() {
        let controller = TextFieldPopupViewController()
        var email: String
        if let account = user.loginMethod.first(where: { $0.method == .email }) {
            email = account.account
        } else {
            email = ""
        }
        if email.contains(GlobalFields.fakeEmailSuffix) {
            email = ""
        }
        controller.text = email
        controller.titleString = "Sign-in email"
        controller.rightButtonString = "UPDATE"
        controller.placeholder = "Email"
        controller.keyboardType = .emailAddress
        controller.onTextChanged = { email, _, rightButton in
            if SL.FormatChecker.shared.isEmail(email) {
                rightButton.enable()
            } else {
                rightButton.disable()
            }
        }
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] email in
            guard let self = self else { return }
            guard SL.FormatChecker.shared.isEmail(email) else { return }
            controller.hide()
            self.updateSigninEmail(email)
        }

        controller.modalPresentationStyle = .custom
        present(controller, animated: false)
    }

    private func onPhoneNumberTapped() {
        let controller = StudioBillingSettingUpdatePhoneNumberPopWindowViewController()
        let phoneNumberString: String
        if let account = user.loginMethod.first(where: { $0.method == .phone }) {
            phoneNumberString = account.account
        } else {
            phoneNumberString = ""
        }
        var phoneNumber = phoneNumberString.getPhoneNumber()
        controller.countryTextField.text = phoneNumber.country
        controller.phoneNumberTextBox.value(phoneNumber.phoneNumber.formatPhoneNumber())
        controller.onConfirmButtonTapped = { [weak self] phoneNumber in
            guard let self = self else { return }
            self.updateSigninPhone(phoneNumber)
        }
        controller.modalPresentationStyle = .custom
        present(controller, animated: false)
    }

    private func onTimeZoneTapped() {
        let controller = StudioTimeZoneSelectorViewController()
        controller.currentTimeZone = user.timeZone
        controller.enableHero()
        controller.onTimeZoneChanged = { [weak self] timeZone in
            guard let self = self else { return }
            self.updateTimeZone(timeZone)
        }
        present(controller, animated: true)
    }
    
    private func onNameTapped() {
        let controller = TextFieldPopupViewController()
        controller.text = user.name
        controller.titleString = "Full name"
        controller.rightButtonString = "UPDATE"
        controller.placeholder = "name"
        controller.keyboardType = .default
        controller.onTextChanged = { name, _, rightButton in
            if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                rightButton.enable()
            } else {
                rightButton.disable()
            }
        }
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] name in
            guard let self = self else { return }
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            controller.hide()
            self.updateFullName(name)
        }

        controller.modalPresentationStyle = .custom
        present(controller, animated: false)
    }
}

extension ParentEditKidProfileViewController: GalleryControllerDelegate, RSKImageCropViewControllerDelegate {
    private func onChangeAvatarTapped() {
        TKPopAction.show(items: [
            TKPopAction.Item(title: "Photo", action: { [weak self] in
                self?.showPhoto()
            }),
            TKPopAction.Item(title: "Camera", action: { [weak self] in
                self?.showCamera()
            }),
        ], target: self)
    }

    private func showPhoto() {
        if Tools.AuthChecker.isAuthAlbum() {
            let gallery = GalleryController()
            Config.tabsToShow = [.imageTab]
            Config.Camera.imageLimit = 1
            gallery.delegate = self
            present(gallery, animated: true, completion: nil)
        } else {
            TKAlert.show(target: self, title: "Permission denied", message: "Photo permission denied, tap 'OK' to set it.") {
                SL.Executor.toAppSetting()
            }
        }
    }

    private func showCamera() {
        if Tools.AuthChecker.isAuthCamera() {
            let gallery = GalleryController()
            Config.tabsToShow = [.cameraTab]
            Config.Camera.imageLimit = 1
            gallery.delegate = self
            present(gallery, animated: true, completion: nil)
        } else {
            TKAlert.show(target: self, title: "Permission denied", message: "Camera permission denied, tap 'OK' to set it.") {
                SL.Executor.toAppSetting()
            }
        }
    }

    private func cropImage(_ image: UIImage) {
        let controller = RSKImageCropViewController(image: image)
        controller.cropMode = .circle
        controller.delegate = self
        controller.maskLayerStrokeColor = ColorUtil.main
        present(controller, animated: true)
    }

    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        controller.dismiss(animated: true)
        guard let image = images.first else { return }
        showFullScreenLoadingNoAutoHide()
        image.resolve { [weak self] image in
            self?.hideFullScreenLoading()
            guard let self = self, let image = image else { return }
            self.cropImage(image)
        }
    }

    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        controller.dismiss(animated: true)
    }

    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        controller.dismiss(animated: true)
    }

    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true)
    }

    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        controller.dismiss(animated: true)
    }

    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        controller.dismiss(animated: true)
        newAvatarImage = croppedImage
    }
}

extension ParentEditKidProfileViewController {
    private func updateSigninEmail(_ email: String) {
        showFullScreenLoadingNoAutoHide()
        callFunction("authService-updateSigninEmailForKid", withData: [
            "kidId": user.userId,
            "email": email,
        ]) { [weak self] _, error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let error = error {
                TKToast.show(msg: "Update email failed, please try again later.", style: .error)
                logger.error("更新email失败: \(error)")
            } else {
                for (index, method) in self.user.loginMethod.enumerated() {
                    if method.method == .email {
                        self.user.loginMethod[index].account = email
                        break
                    }
                }
                TKToast.show(msg: "Update email successfully.", style: .success)
            }
        }
    }
    
    private func updateSigninPhone(_ phoneNumber: TKPhoneNumber) {
        showFullScreenLoadingNoAutoHide()
        callFunction("authService-updateSigninPhoneForKid", withData: [
            "kidId": user.userId,
            "phoneNumber": phoneNumber.toJSON() ?? [:],
        ]) { [weak self] _, error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let error = error {
                TKToast.show(msg: "Update phone failed, please try again later.", style: .error)
                logger.error("更新phoneNumber失败: \(error)")
            } else {
                for (index, method) in self.user.loginMethod.enumerated() {
                    if method.method == .phone {
                        self.user.loginMethod[index].account = "\(phoneNumber.country) \(phoneNumber.phoneNumber)"
                        break
                    }
                }
                for (index, kid) in ParentService.shared.kids.enumerated() where kid.userId == self.user.userId {
                    ParentService.shared.kids[index] = self.user
                }
                TKToast.show(msg: "Update phone successfully.", style: .success)
            }
        }
    }
    
    private func updateTimeZone(_ timeZone: String) {
        showFullScreenLoadingNoAutoHide()
        let hourFromGMT = TimeZone(identifier: timeZone)?.hourFromGMT ?? 0
        DatabaseService.collections.user()
            .document(user.userId)
            .updateData(["timeZone": timeZone, "hourFromGMT": hourFromGMT]) { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    TKToast.show(msg: "Update time zone failed, please try again later.", style: .error)
                    logger.error("更新timeZone失败: \(error)")
                } else {
                    self.user.timeZone = timeZone
                    self.user.hourFromGMT = hourFromGMT
                    for (index, kid) in ParentService.shared.kids.enumerated() where kid.userId == self.user.userId {
                        ParentService.shared.kids[index] = self.user
                    }
                    TKToast.show(msg: "Update phone successfully.", style: .success)
                }
            }
    }
    
    private func updateFullName(_ fullName: String) {
        showFullScreenLoadingNoAutoHide()
        DatabaseService.collections.user()
            .document(user.userId)
            .updateData(["name": fullName]) { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    TKToast.show(msg: "Update name failed, please try again later.", style: .error)
                    logger.error("更新timeZone失败: \(error)")
                } else {
                    self.user.name = fullName
                    for (index, kid) in ParentService.shared.kids.enumerated() where kid.userId == self.user.userId {
                        ParentService.shared.kids[index] = self.user
                    }
                    TKToast.show(msg: "Update name successfully.", style: .success)
                }
            }
    }
}
