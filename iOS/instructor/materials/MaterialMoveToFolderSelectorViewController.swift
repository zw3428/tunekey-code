//
//  MaterialMoveToFolderSelectorViewController.swift
//  TuneKey
//
//  Created by zyf on 2020/10/17.
//  Copyright © 2020 spelist. All rights reserved.
//

import FirebaseFirestore
import FirebaseStorage
import NVActivityIndicatorView
import PromiseKit
import UIKit

class MaterialMoveToFolderSelectorViewController: TKBaseViewController {
    private var selectedItems: [TKMaterial] = []
    private var excludeFolder: TKMaterial?

    private var uploadFromGoogleDrive: [GoogleDriveMaterialPredownloadModel] = []

    private var currentFolderIndex: Int?
    private var currentFolder: TKMaterial?
    private var folders: [TKMaterialFolderModel] = []

    private var contentView: TKView = TKView.create()
        .corner(size: 10)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        .backgroundColor(color: .white)

    private var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .text(text: "Choose folder")
        .textColor(color: ColorUtil.Font.primary)

    private var collectionViewLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    private var collectionView: UICollectionView!
    private var loadingView: NVActivityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: ColorUtil.main, padding: 0)

    private var newFolderTextBox: TKView = TKView.create()
        .backgroundColor(color: .white)
        .showBorder(color: ColorUtil.borderColor)
        .corner(size: 5)
        .showShadow()
    private var newFolderTextField: UITextField = UITextField()

    private var cancelButton: TKBlockButton = TKBlockButton(frame: .zero, title: "CANCEL", style: .cancel)
    private var nextButton: TKBlockButton = TKBlockButton(frame: .zero, title: "MOVE NOW")
    private var progressBar: UIProgressView = {
        let progressBar = UIProgressView(progressViewStyle: .bar)
        progressBar.progressTintColor = ColorUtil.main
        return progressBar
    }()

    private var isUpload: Bool = false

    private var uploadTasks: [String: StorageUploadTask] = [:]

    convenience init(selectedItems: [TKMaterial], excludeFolder: TKMaterial? = nil) {
        self.init(nibName: nil, bundle: nil)
        self.selectedItems = selectedItems
        self.excludeFolder = excludeFolder
    }

    convenience init(uploadItems: [TKMaterial]) {
        self.init(nibName: nil, bundle: nil)
        selectedItems = uploadItems
        isUpload = true
        nextButton.setTitle(title: "UPLOAD NOW")
    }

    convenience init(uploadFromGoogleDrive: [GoogleDriveMaterialPredownloadModel]) {
        self.init(nibName: nil, bundle: nil)
        // 选择文件夹,上传文件
        self.uploadFromGoogleDrive = uploadFromGoogleDrive
        isUpload = true
        nextButton.setTitle(title: "UPLOAD NOW")
    }

    override fileprivate init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }

    deinit {
        logger.debug("销毁 => MaterialMoveToFolderSelectorViewController")
    }
}

extension MaterialMoveToFolderSelectorViewController {
    override func initView() {
        super.initView()

        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.addTo(superView: view) { make in
            make.left.right.bottom.equalToSuperview()
        }

        titleLabel.addTo(superView: contentView) { make in
            make.top.left.equalTo(20)
            make.height.equalTo(20)
        }

        newFolderTextBox.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(50)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(20)
            make.height.equalTo(50)
        }
        newFolderTextField.tintColor = ColorUtil.Font.primary
        newFolderTextField.font = FontUtil.regular(size: 15)
        newFolderTextField.textColor = ColorUtil.Font.third
        newFolderTextField.addTarget(self, action: #selector(onNewFolderTextFieldChanged), for: .editingChanged)
        newFolderTextField.addTo(superView: newFolderTextBox) { make in
            make.left.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
            make.right.equalToSuperview().offset(-10)
        }
        newFolderTextBox.isHidden = true

        // 20 - 6 - 6 - 20
        var width: CGFloat = 0
        var padding: CGFloat = 0
        if deviceType == .pad {
            width = 110
            padding = (UIScreen.main.bounds.width - 330 - 40) / 3
        } else {
            width = (UIScreen.main.bounds.width - 52) / 3
            if width > 110 {
                width = 110
                padding = (UIScreen.main.bounds.width - 40 - 330) / 2
            }
        }
        collectionViewLayout.itemSize = CGSize(width: width, height: 143)
        collectionViewLayout.minimumInteritemSpacing = padding
        collectionViewLayout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .white
        collectionView.register(MaterialFolderCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: MaterialFolderCollectionViewCell.self))
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(50)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(200)
            make.bottom.equalToSuperview().offset(-80 - view.safeAreaInsets.bottom).priority(.medium)
        }

        loadingView.addTo(superView: collectionView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(60)
        }
        loadingView.startAnimating()

        var buttonWidth = (UIScreen.main.bounds.width - 50) / 2
        if buttonWidth > 200 {
            buttonWidth = 200
        }

        cancelButton.addTo(superView: contentView) { make in
            make.bottom.equalToSuperview().offset(-20 - view.safeAreaInsets.bottom)
            make.left.equalToSuperview().offset(20)
            make.width.equalTo(buttonWidth)
            make.height.equalTo(50)
        }

        nextButton.addTo(superView: contentView) { make in
            make.bottom.equalTo(cancelButton.snp.bottom)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(buttonWidth)
            make.height.equalTo(50)
        }
        nextButton.disable()

        progressBar.addTo(superView: contentView) { make in
            make.center.size.equalTo(nextButton)
        }
        progressBar.isHidden = true
        progressBar.layer.cornerRadius = 10
        progressBar.layer.borderColor = ColorUtil.borderColor.cgColor
        progressBar.layer.borderWidth = 1
        progressBar.clipsToBounds = true
        progressBar.progress = 0
        
        
        cancelButton.onTapped { [weak self] _ in
            self?.onCancelButtonTapped()
        }

        nextButton.onTapped { [weak self] _ in
            self?.onNextButtonTapped()
        }

        contentView.transform = CGAffineTransform(translationX: 0, y: TKScreen.height)
    }
}

extension MaterialMoveToFolderSelectorViewController {
    private func show() {
        contentView.layoutIfNeeded()
        let height = contentView.frame.height
        contentView.transform = CGAffineTransform(translationX: 0, y: height)
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        }
    }

    private func hide(completion: (() -> Void)? = nil) {
        contentView.layoutIfNeeded()
        let height = contentView.frame.height
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: height)
        } completion: { _ in
            self.dismiss(animated: false) {
                EventBus.send(key: .refreshMaterials)
                completion?()
            }
        }
    }
}

extension MaterialMoveToFolderSelectorViewController {
    override func initData() {
        super.initData()
        getMaterialFolders()
    }

    private func getMaterialFolders() {
        guard let userId = UserService.user.id() else { return }
        DatabaseService.collections.material()
            .whereField("creatorId", isEqualTo: userId)
            .whereField("type", isEqualTo: TKMaterialFileType.folder.rawValue)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    logger.error("获取文件夹失败: \(error)")
                    TKToast.show(msg: "Get folders failed, please try again later.", style: .error, duration: 2) { [weak self] in
                        self?.hide()
                    }
                } else {
                    var data: [TKMaterialFolderModel] = [.init(type: .home, data: nil), .init(type: .createNewFolder, data: nil)]
                    if let materials: [TKMaterial] = [TKMaterial].deserialize(from: snapshot?.documents.compactMap { $0.data() }) as? [TKMaterial] {
                        let selectedIds = self.selectedItems.compactMap { $0.id }
                        logger.debug("选中的内容: \(selectedIds) | 所有文件夹: \(materials.compactMap { $0.id })")
                        let _materials: [TKMaterial]
                        if let folder = self.excludeFolder {
                            _materials = materials.filter { !selectedIds.contains($0.id) && $0.id != folder.id }
                        } else {
                            _materials = materials.filter({ !selectedIds.contains($0.id) })
                        }

                        data += _materials.compactMap { TKMaterialFolderModel(type: .folder, data: $0, isSelected: false) }
                    }
                    self.folders = data
                    self.collectionView.reloadData()
                    self.collectionView.setNeedsLayout()
                    self.collectionView.layoutIfNeeded()

                    var height = self.collectionView.contentSize.height

                    if height >= self.view.frame.height * 0.8 {
                        height = self.view.frame.height * 0.8
                    }
                    self.loadingView.isHidden = true
                    UIView.animate(withDuration: 0.2) {
                        self.collectionView.snp.updateConstraints { make in
                            make.height.equalTo(height)
                        }
                        self.contentView.layoutIfNeeded()
                    } completion: { _ in
                        if self.isUpload {
                            guard self.folders.count > 0 else { return }
                            self.folders[0].isSelected = true
                            self.collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
                            self.nextButton.enable()
                            self.currentFolderIndex = 0
                        }
//                        if self.excludeFolder == nil {
//                            // 证明在home下,自动选中home
//                            guard self.folders.count > 0 else { return }
//                            self.folders[0].isSelected = true
//                            self.collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
//                        }
                    }
                }
            }
    }
}

extension MaterialMoveToFolderSelectorViewController {
    @objc private func onNewFolderTextFieldChanged() {
        guard let index = currentFolderIndex else { return }
        let item = folders[index]
        guard item.type == .createNewFolder else { return }
        if newFolderTextField.text!.count > 0 {
            nextButton.enable()
        } else {
            nextButton.disable()
        }
    }

    private func onCancelButtonTapped() {
        view.endEditing(true)
        if newFolderTextBox.isHidden {
            hide()
        } else {
            UIView.animate(withDuration: 0.2) {
                self.nextButton.setTitle(title: "NEXT")
                self.collectionView.isHidden = false
                self.newFolderTextBox.isHidden = true
                self.newFolderTextBox.snp.remakeConstraints { make in
                    make.top.equalToSuperview().offset(50)
                    make.left.equalToSuperview().offset(20)
                    make.right.equalToSuperview().offset(-20)
                }
                var height = self.collectionView.contentSize.height

                if height >= self.view.frame.height * 0.8 {
                    height = self.view.frame.height * 0.8
                }
                self.collectionView.snp.remakeConstraints { make in
                    make.top.equalToSuperview().offset(50)
                    make.left.equalToSuperview().offset(20)
                    make.right.equalToSuperview().offset(-20)
                    make.height.equalTo(height)
                    make.bottom.equalToSuperview().offset(-80 - self.view.safeAreaInsets.bottom).priority(.medium)
                }
                self.contentView.layoutIfNeeded()
            }
        }
    }

    private func onNextButtonTapped() {
        // 判断当前选择的文件夹
        guard let index = currentFolderIndex else { return }
        let folder = folders[index]
        switch folder.type {
        case .createNewFolder:
            if newFolderTextBox.isHidden {
                nextButton.disable()
                nextButton.setTitle(title: isUpload ? "UPLOAD NOW" : "MOVE NOW")
                cancelButton.setTitle(title: "GO BACK")
                collectionView.isHidden = true
                newFolderTextBox.isHidden = false
                UIView.animate(withDuration: 0.2) { [weak self] in
                    guard let self = self else { return }
                    self.newFolderTextBox.snp.remakeConstraints { make in
                        make.top.equalToSuperview().offset(50)
                        make.left.equalToSuperview().offset(20)
                        make.right.equalToSuperview().offset(-20)
                        make.height.equalTo(60)
                        make.bottom.equalToSuperview().offset(-80 - self.view.safeAreaInsets.bottom).priority(.medium)
                    }
                    self.collectionView.snp.remakeConstraints { make in
                        make.top.equalToSuperview().offset(50)
                        make.left.equalToSuperview().offset(20)
                        make.right.equalToSuperview().offset(-20)
                    }
                    self.collectionView.isHidden = true
                    self.contentView.layoutIfNeeded()
                } completion: { _ in
                    self.newFolderTextField.becomeFirstResponder()
                }
            } else {
                nextButton.startLoading(at: view) {
                    self.createNewFolder()
                        .done { folder in
                            self.currentFolder = folder
                            self.moveToFolder()
                        }
                        .catch { error in
                            logger.error("创建文件夹失败: \(error)")
                        }
                }
            }
            break
        case .home:
            nextButton.startLoading(at: view) { [weak self] in
                self?.moveToFolder()
            }
        case .folder:
            guard let index = currentFolderIndex else { return }
            let folder = folders[index]
            guard let folderData = folder.data else { return }
            currentFolder = folderData
            nextButton.startLoading(at: view) { [weak self] in
                self?.moveToFolder()
            }
            break
        }
    }

    private func moveToFolder() {
        if isUpload {
            if selectedItems.count > 0 {
                logger.debug("上传到文件夹: \(String(describing: currentFolder))")
                Firestore.firestore().runTransaction { (transaction, _) -> Any? in
                    self.selectedItems.forEach { file in
                        if let currentFolder = self.currentFolder {
                            file.folder = currentFolder.id
                            logger.debug("当前文件有文件夹: \(currentFolder.id)")
                        }
                        transaction.setData(file.toJSON() ?? [:], forDocument: DatabaseService.collections.material().document(file.id))
                    }
                    if let currentFolder = self.currentFolder {
                        transaction.updateData(["materials": FieldValue.arrayUnion(self.selectedItems.toJSON() as [Any])], forDocument: DatabaseService.collections.material().document(currentFolder.id))
                    }
                    return nil
                } completion: { [weak self] _, error in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if let error = error {
                        logger.error("上传失败, 错误: \(error)")
                        TKToast.show(msg: TipMsg.failed, style: .error)
                    } else {
                        logger.debug("上传完的所有材料数据: \(self.selectedItems.toJSONString() ?? "")")
                        self.hide {
                            TKToast.show(msg: "Successfully", style: .success)
                        }
                    }
                }
            } else if uploadFromGoogleDrive.count > 0 {
                uploadFilesFromGoogleDriver()
            }
        } else {
            guard selectedItems.count > 0 else {
                nextButton.stopLoading {
                    self.hide {
                        TKToast.show(msg: "Successfully", style: .success)
                    }
                }
                return
            }
            MaterialService.shared.moveToFolder(items: selectedItems, moveTo: currentFolder) { error in
                if let error = error {
                    logger.error("move to folder failed: \(error)")
                    self.nextButton.stopLoadingWithFailed {
                        TKToast.show(msg: "Failed, please try again later.", style: .error)
                    }
                } else {
                    EventBus.send(key: .refreshMaterials)
                    self.nextButton.stopLoading {
                        self.hide {
                            TKToast.show(msg: "Successfully", style: .success)
                        }
                    }
                }
            }
        }
    }

    private func uploadFilesFromGoogleDriver() {
        var progresses: [String: Double] = [:]
        // 一共有多少个任务,就分为多少分,
        let count = uploadFromGoogleDrive.count
        let avg: Double = 1.0 / Double(count)
        var actions: [Promise<TKMaterial>] = []
        uploadFromGoogleDrive.forEach { model in
            progresses[model.id] = 0.0
            actions.append(uploadFileFromGoogleDrive(file: model, downloadProgressChanged: { id, progress in
                progresses[id] = progress
                updateUploadProgresses()
            }))
        }
        
        when(fulfilled: actions)
            .done { materials in
                // 上传完毕,插入数据
                for (index, item) in materials.enumerated() {
                    materials[index].refId = item.id
                    materials[index].id = IDUtil.nextId(group: .material)?.description ?? ""
                }
                logger.debug("整理所有的Google Drive Files: \(materials.toJSONString() ?? "")")
                Firestore.firestore().runTransaction { (transaction, _) -> Any? in
                    materials.forEach { file in
                        if let currentFolder = self.currentFolder {
                            file.folder = currentFolder.id
                            logger.debug("当前文件有文件夹: \(currentFolder.id)")
                        }
                        transaction.setData(file.toJSON() ?? [:], forDocument: DatabaseService.collections.material().document(file.id))
                    }
                    if let currentFolder = self.currentFolder {
                        transaction.updateData(["materials": FieldValue.arrayUnion(materials.toJSON() as [Any])], forDocument: DatabaseService.collections.material().document(currentFolder.id))
                    }
                    return nil
                } completion: { [weak self] _, error in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if let error = error {
                        logger.error("上传失败, 错误: \(error)")
                        TKToast.show(msg: TipMsg.failed, style: .error)
                    } else {
                        logger.debug("上传完的所有材料数据: \(self.selectedItems.toJSONString() ?? "")")
                        self.hide {
                            TKToast.show(msg: "Successfully", style: .success)
                        }
                    }
                }
            }
            .catch { error in
                logger.error("上传失败: \(error)")
                TKToast.show(msg: "Failed, try again later", style: .error)
            }

        func updateUploadProgresses() {
            var total: Double = 0.0
            progresses.forEach { _, progress in
                total += (progress * avg)
            }
            self.progressBar.progress = Float(total)
            self.progressBar.isHidden = false
        }
    }

    private func uploadFileFromGoogleDrive(file: GoogleDriveMaterialPredownloadModel, downloadProgressChanged: @escaping (_ id: String, _ progress: Double) -> Void) -> Promise<TKMaterial> {
        return Promise { resolver in
            guard let url = file.fileURL, let uid = UserService.user.id() else {
                return resolver.fulfill(file.file)
            }
            let path: String = "/materials/\(uid)/\(file.file.id).\(file.file.suffixName)"
            let uploadTask = Storage.storage().reference(withPath: path)
                .putFile(from: url, metadata: nil) { _, _ in
                }
            self.uploadTasks[file.file.id] = uploadTask
            uploadTask.observe(.progress) { snapshot in
//                onProgress(snapshot.progress!.fractionCompleted, uploadTask)
                if let progress = snapshot.progress?.fractionCompleted {
                    downloadProgressChanged(file.file.id, progress)
                }
            }
            uploadTask.observe(.success) { snapshot in
                snapshot.reference.downloadURL { _url, error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        file.file.url = _url?.absoluteString ?? ""
                        resolver.fulfill(file.file)
                    }
                    uploadTask.removeAllObservers()
                    self.uploadTasks.removeValue(forKey: file.file.id)
                }
            }
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    resolver.reject(error)
                } else {
                    resolver.reject(TKError.functionsError(nil))
                }
                uploadTask.removeAllObservers()
                self.uploadTasks.removeValue(forKey: file.file.id)
            }
        }
    }

    private func createNewFolder() -> Promise<TKMaterial> {
        return Promise { resolver in
            guard let index = currentFolderIndex else { return resolver.reject(TKError.error("current index is nil")) }
            let item = folders[index]
            guard item.type == .createNewFolder else { return resolver.reject(TKError.error("Type error")) }

            let folderName = newFolderTextField.text!
            MaterialService.shared.createNewFolder(name: folderName)
                .done { folder in
                    resolver.fulfill(folder)
                }
                .catch { err in
                    resolver.reject(err)
                }
        }
    }
}

extension MaterialMoveToFolderSelectorViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        logger.debug("点击选择文件夹")
        let item = folders[indexPath.item]
        var indexPaths: [IndexPath] = []
        folders.forEachItems { item, index in
            if index == indexPath.item {
                folders[index].isSelected.toggle()
                if folders[index].isSelected {
                    currentFolderIndex = index
                } else {
                    currentFolderIndex = nil
                }
            } else {
                if item.isSelected {
                    indexPaths.append(IndexPath(item: index, section: 0))
                }
                folders[index].isSelected = false
            }
        }

        indexPaths.append(indexPath)
        collectionView.reloadItems(at: indexPaths)
        let isSelected = folders.filter { $0.isSelected }.count > 0
        if isSelected {
            if item.type == .createNewFolder {
                nextButton.setTitle(title: "NEXT")
            } else {
                nextButton.setTitle(title: isUpload ? "UPLOAD NOW" : "MOVE NOW")
            }
            nextButton.enable()
        } else {
            nextButton.disable()
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        folders.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MaterialFolderCollectionViewCell.self), for: indexPath) as! MaterialFolderCollectionViewCell
        cell.loadData(data: folders[indexPath.item])
        return cell
    }
}
