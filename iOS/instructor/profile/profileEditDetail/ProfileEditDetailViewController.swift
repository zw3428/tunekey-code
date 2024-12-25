//
//  ProfileEditDetailViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/7.
//  Copyright © 2019 spelist. All rights reserved.
//

import FirebaseAuth
import PromiseKit
import RSKImageCropper
import SDWebImage
import UIKit

class ProfileEditDetailViewController: TKBaseViewController {
    private var navigationBar: TKNormalNavigationBar!
    private var tableView: UITableView!
    private var studioLogoView: TKAvatarView!

    private var cellHeights: [CGFloat] = [120, 0, 0, 0, 0, 0]

    private var allInstrumentsData: [TKInstrument] = []

    private var instrumentsData: [TKInstrument?] = []

    private var user: TKUser!

    private var studio: TKStudio!

    private var isInit: Bool = true

    var inviteLink: String = "" {
        didSet {
            if inviteLink != "" {
                self.tableView?.reloadRows(at: [IndexPath(row: 4, section: 0)], with: .none)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        if !isInit {
//            SL.Executor.runAsyncAfter(time: 0.2) { [weak self] in
//                self?.initData()
//            }
//        }
        loadData()
    }

    deinit {
        logger.debug("销毁ProfileEditDetailViewController")
    }
}

extension ProfileEditDetailViewController {
    private func loadData() {
        user = ListenerService.shared.user
        navigationBar.startLoading()
        if let userId = UserService.user.id() {
            getTeacherInviteLink(teacherId: userId)
        }
        when(fulfilled: loadStudioInfo(), loadUserInfo())
            .done { [weak self] _, _ in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.navigationBar.stopLoading()
                self.isInit = false
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                logger.error("获取数据失败: \(error)")
                self.dismiss(animated: true) {
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                }
            }
    }
    
    private func getTeacherInviteLink(teacherId: String) {
        CommonsService.shared.getTeacherInviteLink(teacherId: teacherId) { orginalUrl, shortUrl in
            if let url = shortUrl {
                self.inviteLink = url
            } else {
                self.inviteLink = orginalUrl
            }
        }
    }

    private func loadStudioInfo() -> Promise<Any?> {
        return Promise { resolver in
            var isReturn: Bool = false
            let timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                if !isReturn {
                    resolver.reject(TKError.timeout)
                }
            }
            UserService.studio.info { [weak self] isSuccess, fromCache, studio in
                guard let self = self else { return }
                if isSuccess {
                    self.studio = studio!
                    if !fromCache {
                        timer.invalidate()
                        isReturn = true
                        resolver.fulfill(nil)
                    }
                } else {
                    timer.invalidate()
                    isReturn = true
                    resolver.reject(TKError.nilDataResponse(nil))
                }
            }
        }
    }

    private func loadUserInfo() -> Promise<Any?> {
        return Promise { resolver in
            var isReturn: Bool = false
            let timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                if !isReturn {
                    resolver.reject(TKError.timeout)
                }
            }
            self.addSubscribe(
                UserService.user.getInfo()
                    .subscribe(onNext: { [weak self] data in
                        guard let self = self else { return }
                        if let data = data[true] {
                            self.user = data
                        }
                        if let data = data[false] {
                            self.user = data
                        }
                        isReturn = true
                        timer.invalidate()
                        resolver.fulfill(nil)
                    }, onError: { err in
                        logger.debug("======获取用户失败")
                        isReturn = true
                        timer.invalidate()
                        resolver.reject(err)
                    })
            )
        }
    }

    private func loadStudioInfo(completion: @escaping () -> Void = {}) {
        UserService.studio.info { [weak self] isSuccess, fromCache, studio in
            guard let self = self else { return }
            if isSuccess {
                self.studio = studio!
            }
            if !fromCache {
                completion()
            }
        }
    }

    private func loadUserInfo(completion: @escaping () -> Void = {}) {
        addSubscribe(
            UserService.user.getInfo()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        self.user = data
                    }
                    if let data = data[false] {
                        self.user = data
                    }
                    completion()
                }, onError: { _ in
                    logger.debug("======获取用户失败")
                })
        )
    }
}

extension ProfileEditDetailViewController {
    override func initView() {
        enablePanToDismiss()
        initNavigationBar()
        initTableView()
    }

    private func initNavigationBar() {
        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Edit Profile", rightButton: "Sign out", target: self, onRightButtonTapped: { [weak self] in
            logger.debug("sign out tapped")
            self?.signout()
        })
        navigationBar.rightButton.titleColor(UIColor(named: "red")!)
        navigationBar.updateLayout(target: self)
    }

    private func initTableView() {
        tableView = UITableView()
        addSubview(view: tableView) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        tableView.tableHeaderView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 0
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.delaysContentTouches = false
        tableView.showsVerticalScrollIndicator = false
        tableView.register(ProfileEditDetailLogoTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileEditDetailLogoTableViewCell.self))
        tableView.register(ProfileEditDetailNameTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileEditDetailNameTableViewCell.self))
        tableView.register(ProfileEditDetailSorefrontColorTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileEditDetailSorefrontColorTableViewCell.self))
        tableView.register(ProfileEditDetailContactsTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileEditDetailContactsTableViewCell.self))
        tableView.register(WelcomeStudentsQRCodeTableViewCell.self, forCellReuseIdentifier: String(describing: WelcomeStudentsQRCodeTableViewCell.self))
        tableView.register(ProfileEditDetailTimeZoneTableViewCell.self, forCellReuseIdentifier: ProfileEditDetailTimeZoneTableViewCell.id)
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func bindEvent() {
    }

    private func signout() {
        do {
            guard let userId = UserService.user.id() else { return }
            try Auth.auth().signOut()
            SL.Cache.shared.remove(key: "user:user_id")
            SL.Cache.shared.remove(key: "user:teacher")
            ListenerService.shared.teacherData.clear()
            ListenerService.shared.studentData.clear()
            EventBus.send(key: .signOut)
            view.window?.rootViewController?.dismiss(animated: false, completion: nil)
            NotificationServer.instance.resetNotificationConfigToken(userId: userId) {
            }
        } catch {
            logger.error("sign out error: \(error)")
            TKToast.show(msg: "Failed to sign out, please try again later.", style: .error)
        }
    }
}

extension ProfileEditDetailViewController: ProfileEditDetailLogoTableViewCellDelegate, RSKImageCropViewControllerDelegate {
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        if studioLogoView != nil {
            studioLogoView.loadImage(image: croppedImage)
        }
        // TODO: - upload
        controller.dismiss(animated: true, completion: { [weak self] in
            self?.uploadLogoImage(image: croppedImage)
        })
    }

    func profileEditDetailLogoTableViewCellTapped() {
        TKPopAction.show(items: [
            TKPopAction.Item(title: "Photo", action: { [weak self] in
                self?.showGalery()
            }),
            TKPopAction.Item(title: "Camera", action: { [weak self] in
                self?.showCamera()
            }),
        ], target: self)
    }

    private func showGalery() {
        if Tools.AuthChecker.isAuthAlbum() {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                invokeSystemPhoto()
            }
        } else {
            TKAlert.show(target: self, title: "Permission denied", message: "Photo permission denied, tap 'OK' to set it.") {
                SL.Executor.toAppSetting()
            }
        }
    }

    private func showCamera() {
        let gallery = GalleryController()
        Config.tabsToShow = [.cameraTab]
        Config.Camera.imageLimit = 1
        gallery.delegate = self
        present(gallery, animated: true, completion: nil)
    }

    override func reloadViewWithImg(img: UIImage) {
        SL.Executor.runAsync { [weak self] in
            guard let self = self else { return }
            logger.debug("加载已经选择的图片")
            let imageCropVC: RSKImageCropViewController = RSKImageCropViewController(image: img)
            imageCropVC.cropMode = .circle
            imageCropVC.delegate = self
            imageCropVC.maskLayerStrokeColor = ColorUtil.main
            self.present(imageCropVC, animated: false, completion: nil)
        }
    }

    private func uploadLogoImage(image: UIImage) {
        guard studio != nil else {
            return
        }
        let size = image.scaleImage(imageLength: 200)
        let _image = image.resizeImage(size)
        let data = _image.compressImage(maxLength: GlobalFields.maxImageSize)
        guard studio != nil else { return }
        let path = "/images/studio_logos/\(studio.id).jpg"
        print("开始上传")
        let url = UserService.user.getAvatarPath(user.userId)
        SDWebImageManager.shared.imageCache.removeImage!(forKey: url, cacheType: .all) {
            print("删除缓存成功")
        }
        studioLogoView.loadImage(image: image)

        StorageService.shared.uploadFile(with: data!, to: path, onProgress: { [weak self] progress, _ in
            guard let self = self else { return }
            logger.debug("progress: \(progress)")
            if self.studioLogoView != nil && progress != 1 {
                self.studioLogoView.setProgress(progress: progress)
            }
            if progress == 1 {
                self.studioLogoView.setProgress(progress: 0.99)
            }
        }) { isSuccess in
            self.studioLogoView.setProgress(progress: 1)
            EventBus.send(key: .refreshUserInfo)
            if isSuccess {
                CommonsService.shared.checkSendEmailWhenUploadedLogoOrSecondEntrance()
            }
        }
    }
}

extension ProfileEditDetailViewController: GalleryControllerDelegate {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        controller.dismiss(animated: true, completion: nil)
        guard let image = images.first else {
            return
        }
        image.resolve { image in
            if let image = image {
                self.reloadViewWithImg(img: image)
            }
        }
    }

    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        controller.dismiss(animated: true, completion: nil)
    }

    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        controller.dismiss(animated: true, completion: nil)
    }

    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension ProfileEditDetailViewController: ProfileEditDetailSorefrontColorTableViewCellDelegate {
    func profileEditDetailSorefrontColorTableViewCellTapped() {
        let controller = WelcomeStudensViewController()
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        controller.confirm = {
            controller.dismiss(animated: true, completion: nil)
        }
        present(controller, animated: true, completion: nil)
    }
}

extension ProfileEditDetailViewController: ProfileEditDetailNameTableViewCellDelegate {
    func profileEditDetailNameTableViewCell(textBox: TKTextBox, nameChanged name: String) {
        guard studio != nil else {
            return
        }
        if textBox.isLoading() {
            textBox.stopLoading()
        }
        textBox.startLoading()
        studio.name = name
        UserService.studio.updateStudioName(id: studio.id, name: name) { [weak self] isSuccess, _name in
            guard let self = self else { return }
            if isSuccess {
                if self.studio.name == _name {
                    textBox.stopLoading(isShowSuccess: true)
                } else {
                    textBox.stopLoading()
                }
            } else {
                textBox.showWrong()
            }
        }
    }
}

extension ProfileEditDetailViewController: ProfileEditDetailContactsTableViewCellDelegate {
    func profileEditDetailContactsTableViewCell(addressChanged address: TKPaymentAddress) {
        
    }
    
    func profileEditDetailContactsTableViewCell(textBox: TKTextBox, nameChanged name: String) {
        guard user != nil else {
            return
        }
        if textBox.isLoading() {
            textBox.stopLoading()
        }
        textBox.startLoading()
        user.name = name
        UserService.user.updateName(name: name) { [weak self] isSuccess, _name in
            guard let self = self else { return }
            if isSuccess {
                if self.user.name == _name {
                    textBox.stopLoading(isShowSuccess: true)
                    EventBus.send(key: .refreshUserInfo)
                }
            } else {
                textBox.stopLoading()
            }
        }
    }

    func profileEditDetailContactsTableViewCell(textBox: TKTextBox, emailChanged email: String) {
        guard user != nil else {
            return
        }
        guard SL.FormatChecker.shared.isEmail(email) else {
            return
        }
        if textBox.isLoading() {
            textBox.stopLoading()
        }
        textBox.startLoading()
        user.email = email
        CommonsService.shared.emailValidVerify(email: email)
            .done { [weak self] isValid in
                guard let self = self else { return }
                if !isValid {
                    WrongEmailAlert.show(withEmail: email) { isContinue in
                        guard isContinue else {
                            textBox.stopLoading()
                            textBox.selectAll()
                            textBox.focus()
                            return
                        }
                        UserService.user.updateEmail(email: email) { isSuccess, _email in
                            if isSuccess {
                                if self.user.email == _email {
                                    textBox.stopLoading(isShowSuccess: true)
                                    EventBus.send(key: .refreshUserInfo)
                                }
                            } else {
                                textBox.stopLoading()
                            }
                        }
                    }
                } else {
                    UserService.user.updateEmail(email: email) { isSuccess, _email in
                        if isSuccess {
                            if self.user.email == _email {
                                textBox.stopLoading(isShowSuccess: true)
                                EventBus.send(key: .refreshUserInfo)
                            }
                        } else {
                            textBox.stopLoading()
                        }
                    }
                }
            }
            .catch { _ in
                textBox.stopLoading()
                TKToast.show(msg: TipMsg.emailValidationFalse, style: .error)
            }
    }

    func profileEditDetailContactsTableViewCell(textBox: TKTextBox, phoneChanged phone: String) {
        guard user != nil else {
            return
        }
        if phone != "" {
            guard SL.FormatChecker.shared.isMobilePhone(phone) else {
                return
            }
        }
        if textBox.isLoading() {
            textBox.stopLoading()
        }
        textBox.startLoading()
        user.phone = phone
        UserService.user.updatePhone(phone: phone) { [weak self] isSuccess, _phone in
            guard let self = self else { return }
            if isSuccess {
                if self.user.phone == _phone {
                    textBox.stopLoading(isShowSuccess: true)
                    EventBus.send(key: .refreshUserInfo)
                }
            } else {
                textBox.stopLoading()
            }
        }
    }

    func profileEditDetailContactsTableViewCell(textBox: TKTextBox, websiteChanged website: String) {
        guard user != nil else {
            return
        }
        if website != "" {
            var _website: String = ""
            if !website.contains("http://") && !website.contains("https://") {
                _website = "https://\(website)"
            } else {
                _website = website
            }

            guard SL.FormatChecker.shared.isURL(_website) else {
                return
            }
        }
        if textBox.isLoading() {
            textBox.stopLoading()
        }
        textBox.startLoading()
        user.website = website
        addSubscribe(
            UserService.user.updateUser(data: ["website": website])
                .subscribe(onNext: { _ in
                    textBox.stopLoading(isShowSuccess: true)
                    EventBus.send(key: .refreshUserInfo)
                }, onError: { err in
                    logger.debug("======\(err)")
                    textBox.stopLoading()

                })
        )
    }
}

extension ProfileEditDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let user = ListenerService.shared.user {
            if user.roleIds.contains(TKUserRole.teacher.rawValue.description) {
                //教师,5个cell
                return 6
            } else {
                return 4
            }
        } else {
            return 4
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileEditDetailLogoTableViewCell.self), for: indexPath) as! ProfileEditDetailLogoTableViewCell
            studioLogoView = cell.avatarView
            cellHeights[indexPath.row] = cell.cellHeight
            if user != nil {
                cell.setLogoImage(id: user.userId)
            }
            cell.delegate = self
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileEditDetailNameTableViewCell.self), for: indexPath) as! ProfileEditDetailNameTableViewCell
            cellHeights[indexPath.row] = 84
            cell.skipLabel.isHidden = true
            if studio != nil {
                cell.loadData(defaultName: studio.name)
            }
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileEditDetailSorefrontColorTableViewCell.self), for: indexPath) as! ProfileEditDetailSorefrontColorTableViewCell
            cellHeights[indexPath.row] = cell.cellHeight

            if studio != nil && studio.storefrontColor != "" {
                let color = UIColor(hex: studio.storefrontColor)
                cell.loadData(color: color)
            }
            cell.delegate = self
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileEditDetailContactsTableViewCell.self), for: indexPath) as! ProfileEditDetailContactsTableViewCell
            cellHeights[indexPath.row] = cell.cellHeight
            if user != nil {
                cell.loadData(user: user)
            }
            cell.delegate = self
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProfileEditDetailTimeZoneTableViewCell.id, for: indexPath) as! ProfileEditDetailTimeZoneTableViewCell
            cellHeights[indexPath.row] = 200
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WelcomeStudentsQRCodeTableViewCell.self), for: indexPath) as! WelcomeStudentsQRCodeTableViewCell
            cell.loadData(url: inviteLink, logoImage: nil)
            cell.titleLabel.text("By scanning the QR-code, your students will download the app and auto-link to your studio.\nPRINT & POST it.")
            cell.titleLabel.font = FontUtil.regular(size: 11)
            cell.titleLabel.snp.updateConstraints { make in
                make.height.equalTo(40)
            }
            cell.containerView.snp.updateConstraints { make in
                make.height.equalTo(353)
            }
            cell.contentView.backgroundColor = ColorUtil.backgroundColor
            cellHeights[indexPath.row] = 383
            return cell
        }
    }
}

extension ProfileEditDetailViewController {
    private func toSignInOptionController() {
        logger.debug("点击跳转到signin option")
        let controller = ProfileAccountController()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }
}
