//
//  ParentProfileEditViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/11/28.
//  Copyright © 2022 spelist. All rights reserved.
//

import FirebaseFirestore
import FirebaseStorage
import PromiseKit
import RSKImageCropper
import SDWebImage
import SnapKit
import UIKit

class ParentProfileEditViewController: TKBaseViewController {
    private lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "My Profile", rightButton: "Sign out") { [weak self] in
        guard let self = self else { return }
        signout(from: self)
    }

    @Live var newAvatarImage: UIImage?
    @Live var user: TKUser?

    @Live var isDataChanged: Bool = false

    private var isUserLoaded: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
}

extension ParentProfileEditViewController {
    override func initView() {
        super.initView()
        navigationBar.updateLayout(target: self)
        navigationBar.rightButton?.titleColor(ColorUtil.red)
        ViewBox {
            VScrollStack {
                ViewBox(top: 20, left: (UIScreen.main.bounds.width - 80) / 2, bottom: 8, right: (UIScreen.main.bounds.width - 80) / 2) {
                    AvatarView(size: 80)
                        .backgroundColor(ColorUtil.main)
                        .apply { [weak self] avatarView in
                            guard let self = self else { return }
                            self.$user.addSubscriber { user in
                                guard self.newAvatarImage == nil else { return }
                                if let user = user {
                                    avatarView.loadAvatar(withUserId: user.userId, name: user.name)
                                        .contentMode(.scaleAspectFill)
                                } else {
                                    avatarView.loadAvatar(withImage: UIImage(named: "content_segment_camera")!.imageWithTintColor(color: .white).resizeImage(CGSize(width: 30, height: 30)))
                                        .contentMode(.center)
                                }
                            }
                            self.$newAvatarImage.addSubscriber { image in
                                if let image = image {
                                    avatarView.loadAvatar(withImage: image)
                                        .contentMode(.scaleAspectFill)
                                } else {
                                    if let user = self.user {
                                        avatarView.loadAvatar(withUserId: user.userId, name: user.name)
                                            .contentMode(.scaleAspectFill)
                                    } else {
                                        avatarView.loadAvatar(withImage: UIImage(named: "content_segment_camera")!.imageWithTintColor(color: .white).resizeImage(CGSize(width: 30, height: 30)))
                                            .contentMode(.center)
                                    }
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
                            ViewBox(left: 20) {
                                Label("Contacts").textColor(ColorUtil.Font.primary).font(.regular(size: 13))
                            }
                            ViewBox(top: 10, right: 20) {
                                TextBox().placeholder("Full Name")
                                    .isShadowShow(false)
                                    .isBorderShow(false)
                                    .height(64)
                                    .apply { [weak self] _, textBox in
                                        guard let self = self else { return }
                                        self.$user.addSubscriber { user in
                                            guard let user = user else { return }
                                            textBox.value(user.name)
                                        }
                                    }
                                    .onTyped { [weak self] text in
                                        guard let self = self else { return }
                                        self.user?.name = text
                                        self.isDataChanged = true
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
                                            guard var user = user else { return }
                                            textBox.value(user.phoneNumber.phoneNumber.formatPhoneNumber())
                                                .prefix(user.phoneNumber.country)
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
                                TextBox().placeholder("Contact email(not for sign-in)")
                                    .isShadowShow(false)
                                    .isBorderShow(false)
                                    .height(64)
                                    .apply { [weak self] _, textBox in
                                        guard let self = self else { return }
                                        self.$user.addSubscriber { user in
                                            guard let user = user else { return }
                                            textBox.value(user.email)
                                        }
                                    }
                                    .onTyped { [weak self] text in
                                        guard let self = self else { return }
                                        self.user?.email = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                        self.isDataChanged = true
                                    }
                            }
                            ViewBox {
                                Divider(weight: 1, color: ColorUtil.dividingLine)
                            }.height(1)
                            ViewBox(top: 10, right: 20) {
                                TextBox().placeholder("Address")
                                    .isShadowShow(false)
                                    .isBorderShow(false)
                                    .height(64)
                                    .apply { [weak self] _, textBox in
                                        guard let self = self else { return }
                                        textBox.textField.isEnabled = false
                                        self.$user.addSubscriber { user in
                                            guard let user = user else { return }
                                            textBox.value(user.addressDetail.addressString)
                                        }
                                    }
                            }.apply { view in
                                View().addTo(superView: view) { make in
                                    make.edges.equalToSuperview()
                                }.onViewTapped { [weak self] _ in
                                    self?.onAddressTapped()
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
                                            guard let user = user else { return }
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

        BlockButton(title: "SAVE", style: .normal)
            .isShow($isDataChanged)
            .onTapped { [weak self] _ in
                self?.onSaveButtonTapped()
            }
            .addTo(superView: view) { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(180)
                make.height.equalTo(50)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            }
    }
}

extension ParentProfileEditViewController {
    private func loadData() {
        guard !isUserLoaded else { return }
        isUserLoaded = true
        user = ListenerService.shared.user
        isDataChanged = false
    }
}

extension ParentProfileEditViewController {
    override func bindEvent() {
        super.bindEvent()
    }

    private func onPhoneNumberTapped() {
        guard let user = user else { return }
        let controller = StudioBillingSettingUpdatePhoneNumberPopWindowViewController()
        controller.countryTextField.text = user.phoneNumber.country
        controller.phoneNumberTextBox.value(user.phoneNumber.phoneNumber)
        controller.onConfirmButtonTapped = { [weak self] phoneNumber in
            guard let self = self, let user = self.user else { return }
            if user.phoneNumber.country != user.phoneNumber.country || phoneNumber.phoneNumber != user.phoneNumber.phoneNumber {
                self.user?.phoneNumber = phoneNumber
                self.user?.phone = phoneNumber.string
                self.isDataChanged = true
            }
        }
        controller.modalPresentationStyle = .custom
        present(controller, animated: false)
    }

    private func onAddressTapped() {
        guard let user = user else { return }
        let controller = StudioBillingSettingUpdateAddressPopWindowViewController()
        controller.address = .init(addressLine: user.addressDetail.line1, city: user.addressDetail.city, country: user.addressDetail.country, state: user.addressDetail.state, zipCode: user.addressDetail.postal_code)
        controller.onConfirmButtonTapped = { [weak self] address in
            guard let self = self, let user = self.user else { return }
            if user.addressDetail.line1 != address.addressLine
                || user.addressDetail.city != address.city
                || user.addressDetail.country != address.country
                || user.addressDetail.state != address.state
                || user.addressDetail.postal_code != address.zipCode {
                let addressDetail = TKPaymentAddress(city: address.city, country: address.country, line1: address.addressLine, line2: "", postal_code: address.zipCode, state: address.state)
                self.user?.addressDetail = addressDetail
                self.user?.address = addressDetail.addressString
                self.isDataChanged = true
            }
        }
        controller.modalPresentationStyle = .custom
        present(controller, animated: false)
    }

    private func onTimeZoneTapped() {
        guard let user = user else { return }
        let controller = StudioTimeZoneSelectorViewController()
        controller.currentTimeZone = user.timeZone
        controller.enableHero()
        controller.onTimeZoneChanged = { [weak self] timeZone in
            guard let self = self else { return }
            self.user?.timeZone = timeZone
            self.user?.hourFromGMT = TimeZone(identifier: timeZone)?.hourFromGMT ?? 0
            self.isDataChanged = true
        }
        present(controller, animated: true)
    }
}

extension ParentProfileEditViewController {
    private func onSaveButtonTapped() {
        akasync { [weak self] in
            guard let self = self else { return }
            updateUI {
                self.showFullScreenLoadingNoAutoHide()
            }

            try akawait(self.uploadAvatarImage())
            try akawait(self.saveUserData())

            updateUI {
                self.hideFullScreenLoading()
                self.newAvatarImage = nil
                self.isDataChanged = false
                if let user = self.user {
                    let url = UserService.user.getAvatarPath(user.userId)
                    SDWebImageManager.shared.imageCache.removeImage!(forKey: url, cacheType: .all) {
                        logger.debug("删除缓存成功")
                    }
                }
            }
        }
    }

    private func uploadAvatarImage() -> Promise<Void> {
        Promise { resolver in
            guard let image = newAvatarImage, let imageData = image.jpegData(compressionQuality: 0.5), let user = user else { return resolver.fulfill(()) }
            let newMetadata = StorageMetadata()
            newMetadata.contentType = "image/jpeg"
            let folderPath = UserService.user.getAvatarFolderPath()
            StorageService.shared.uploadFile(with: imageData, to: "\(folderPath)/\(user.userId).jpg", metadata: newMetadata) { [weak self] progress, _ in
                guard let self = self else { return }
                logger.error("上传进度: \(progress)")
                self.updateFullScreenLoadingMsg(msg: "Uploading avatar, \(Int(progress * 100))%")
            } completion: { isSuccess in
                if isSuccess {
                    resolver.fulfill(())
                } else {
                    resolver.reject(TKError.error("Unknown error"))
                }
            }
        }
    }

    private func saveUserData() -> Promise<Void> {
        Promise { resolver in
            guard let user = user else { return }
            let now = Date().timestamp
            DatabaseService.collections.user()
                .document(user.userId)
                .updateData([
                    "email": user.email,
                    "name": user.name,
                    "phoneNumber": user.phoneNumber.toJSON() ?? [:],
                    "phone": user.phone,
                    "addressDetail": user.addressDetail.toJSON() ?? [:],
                    "address": user.address,
                    "timeZone": user.timeZone,
                    "hourFromGMT": user.hourFromGMT,
                    "updateTime": "\(now)"
                ]) { error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        resolver.fulfill(())
                    }
                }
        }
    }
}

extension ParentProfileEditViewController: GalleryControllerDelegate, RSKImageCropViewControllerDelegate {
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
        isDataChanged = true
    }
}
