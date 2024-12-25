//
//  SProfileUserInfoController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/20.
//  Copyright © 2019年 spelist. All rights reserved.
//

import FirebaseAuth
import RSKImageCropper
import SDWebImage
import SnapKit
import UIKit

class SProfileUserInfoController: TKBaseViewController {
    private var mainView = UIView()
    lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Edit Profile", rightButton: "Sign out", target: self, onRightButtonTapped: { [weak self] in
        guard let self = self else { return }
        signout(from: self)
    })
    private var tableView: UITableView!
    private var cellHeights: [CGFloat] = [146, 389, 84]
    private var userAvatarView: TKAvatarView!
    var user: TKUser!
    private var isInit: Bool = true

    deinit {
        logger.debug("销毁 => \(tkScreenName)")
    }

    var isViewDidAppear: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewDidAppear = true
        if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? ProfileEditBirthdayTableViewCell {
            cell.isViewAppeared = true
        }
    }
}

// MARK: - View

extension SProfileUserInfoController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        navigationBar.rightButton.titleColor(UIColor(named: "red")!)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initTableView()
    }

    func initTableView() {
        tableView = UITableView()
        tableView.backgroundColor = ColorUtil.backgroundColor
        mainView.addSubview(view: tableView) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.register(ProfileEditDetailLogoTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileEditDetailLogoTableViewCell.self))
        tableView.register(ProfileEditDetailContactsTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileEditDetailContactsTableViewCell.self))
        tableView.register(ProfileEditBirthdayTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileEditBirthdayTableViewCell.self))
        let tableFooterView = TKView.create()
        tableFooterView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 80)
        let tipLabel = TKLabel.create()
            .setNumberOfLines(number: 0)
            .alignment(alignment: .center)
        let text = "Change sign-in email?\nGo to \"Settings > Sign in options\""
        tipLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: "Settings > Sign in options", allColor: ColorUtil.Font.fourth, selectedColor: ColorUtil.main, font: FontUtil.regular(size: 13), selectedFont: FontUtil.medium(size: 13), fontSize: 13, selectedFontSize: 13, ignoreCase: true, charasetSpace: 0)
        tipLabel.addTo(superView: tableFooterView) { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(40)
        }
        tipLabel.onViewTapped { [weak self] _ in
            self?.toSignInOptionController()
        }

//        ViewBox(paddings: UIEdgeInsets(top: 80, left: 0, bottom: 10, right: 0)) {
//            Label()
//                .attributedText(Tools.attributenStringColor(text: text, selectedText: "Settings > Sign in options", allColor: ColorUtil.Font.fourth, selectedColor: ColorUtil.main, font: FontUtil.regular(size: 13), selectedFont: FontUtil.medium(size: 13), fontSize: 13, selectedFontSize: 13, ignoreCase: true, charasetSpace: 0))
//                .textAlignment(.center)
//                .onViewTapped { [weak self] _ in
//                    self?.toSignInOptionController()
//                }
//        }
//        .addTo(superView: tableFooterView) { make in
//            make.top.left.right.bottom.equalToSuperview()
//        }

        tableView.tableFooterView = tableFooterView
    }
}

extension SProfileUserInfoController {
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

// MARK: - Data

extension SProfileUserInfoController {
    override func initData() {
    }
}

// MARK: - TableView

extension SProfileUserInfoController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileEditDetailLogoTableViewCell.self), for: indexPath) as! ProfileEditDetailLogoTableViewCell
            cell.changeTipLabel.text("Change avatar")
            userAvatarView = cell.avatarView
            if user != nil {
                cell.setLogoImage(id: user.userId)
            }
            cell.delegate = self
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileEditDetailContactsTableViewCell.self), for: indexPath) as! ProfileEditDetailContactsTableViewCell
            cell.delegate = self
            if user != nil {
                cell.loadData(user: user, role: .student)
                cell.address = user.addresses.first
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: ProfileEditBirthdayTableViewCell.id, for: indexPath) as! ProfileEditBirthdayTableViewCell
            if let user = user {
                cell.birthday = user.birthday
            } else {
                cell.birthday = 0
            }
            cell.isViewAppeared = isViewDidAppear
            cell.onBirthdayTapped = {
                let controller = DatePickerViewController()
                if let user = self.user {
                    let defaultDate = DateInRegion(seconds: user.birthday, region: .localRegion)
                    controller.selectedYear = defaultDate.year
                    controller.selectedMonth = defaultDate.month
                    controller.selectedDay = defaultDate.day
                }
                controller.modalPresentationStyle = .custom
                Tools.getTopViewController()?.present(controller, animated: false)
                controller.onDateSelected = { [weak self] date in
                    guard let self = self else { return }
                    guard let user = self.user else { return }
                    self.showFullScreenLoadingNoAutoHide()
                    UserService.user.updateUserBirthday(user.userId, birthday: date.timeIntervalSince1970)
                        .done { _ in
                            self.hideFullScreenLoading()
                            self.user?.birthday = date.timeIntervalSince1970
                            cell.birthday = date.timeIntervalSince1970
                        }
                        .catch { error in
                            self.hideFullScreenLoading()
                            TKToast.show(msg: "Update student birthday failed, please try it later.", style: .error)
                            logger.error("发生错误: \(error)")
                        }
                }
            }
            return cell
        }
    }
}

extension SProfileUserInfoController: ProfileEditDetailLogoTableViewCellDelegate, ProfileEditDetailContactsTableViewCellDelegate, RSKImageCropViewControllerDelegate {
    func profileEditDetailContactsTableViewCell(addressChanged address: TKPaymentAddress) {
        guard var user = user else { return }
        user.addresses = [address]
        showFullScreenLoadingNoAutoHide()
        DatabaseService.collections.user()
            .document(user.userId)
            .updateData(["addresses": user.addresses.toJSON()]) { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    logger.error("更新失败： \(error)")
                } else {
                    self.user = user
                    if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? ProfileEditDetailContactsTableViewCell {
                        cell.loadData(user: user, role: .student)
                        EventBus.send(key: .refreshUserInfo)
                    }
                }
            }
    }

    // MARK: - 点击了修改头像

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
        if Tools.AuthChecker.isAuthCamera() {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                invokingSystemAlbumOrCamera(type: UIImagePickerController.InfoKey.originalImage.rawValue,
                                            albumT: UIImagePickerController.SourceType.camera.rawValue)
            }
        } else {
            TKAlert.show(target: self, title: "Permission denied", message: "Camera permission denied, tap 'OK' to set it.") {
                SL.Executor.toAppSetting()
            }
        }
    }

    override func reloadViewWithImg(img: UIImage) {
        SL.Executor.runAsync { [weak self] in
            guard let self = self else { return }
            let imageCropVC: RSKImageCropViewController = RSKImageCropViewController(image: img)
            imageCropVC.cropMode = .circle
            imageCropVC.delegate = self
            imageCropVC.maskLayerStrokeColor = ColorUtil.main
            self.present(imageCropVC, animated: false, completion: nil)
        }
    }

    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        if userAvatarView != nil {
            userAvatarView.loadImage(image: croppedImage)
        }
        // TODO: - upload
        controller.dismiss(animated: true, completion: { [weak self] in
            self?.uploadLogoImage(image: croppedImage)
        })
    }

    // MARK: - 上传头像

    private func uploadLogoImage(image: UIImage) {
        let size = image.scaleImage(imageLength: 200)
        let _image = image.resizeImage(size)

        let data = _image.compressImage(maxLength: GlobalFields.maxImageSize)
        let folderPath = UserService.user.getAvatarFolderPath()
        let path = "\(folderPath)/\(user.userId).jpg"

        userAvatarView.loadImage(image: _image)
        let url = UserService.user.getAvatarPath(user.userId)
        SDWebImageManager.shared.imageCache.removeImage!(forKey: url, cacheType: .all) {
            print("删除缓存成功")
        }
        StorageService.shared.uploadFile(with: data!, to: path, onProgress: { [weak self] progress, _ in
            guard let self = self else { return }
            logger.debug("progress: \(progress)")
            if self.userAvatarView != nil && progress < 1 {
                self.userAvatarView.setProgress(progress: progress)
            }
            if progress == 1 {
                self.userAvatarView.setProgress(progress: 0.99)
            }
        }) { [weak self] _ in
            print("上传头像成功")
            self?.userAvatarView.setProgress(progress: 1)
            EventBus.send(key: .refreshUserInfo)
        }
    }

    // MARK: - 修改了名字..手机..email等

    func profileEditDetailContactsTableViewCell(textBox: TKTextBox, nameChanged name: String) {
        logger.debug("======修改name:\(name)")
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
                    if let user = ListenerService.shared.user, let email = user.loginMethod.first(where: { $0.method == .email })?.account {
                        if var item = SLCache.LoginHistory.fetch(withEmail: email) {
                            item.name = name
                            SLCache.LoginHistory.save(item)
                        }
                    }
                }
//                CommonsService.shared.changeStudentNameInStudentList(studentId: self.user.userId, name: name)
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
        UserService.user.updateEmail(email: email) { [weak self] isSuccess, _email in
            guard let self = self else { return }
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

    func profileEditDetailContactsTableViewCell(textBox: TKTextBox, phoneChanged phone: String) {
        guard user != nil else {
            return
        }

        guard phone.count == 0 || phone.count >= 10 else {
            return
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
        logger.debug("======修改website:\(website)")
    }
}
