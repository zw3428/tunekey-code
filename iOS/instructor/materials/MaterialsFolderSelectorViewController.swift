//
//  MaterialsFolderSelectorViewController.swift
//  TuneKey
//
//  Created by zyf on 2023/1/9.
//  Copyright © 2023 spelist. All rights reserved.
//

import AttributedString
import DZNEmptyDataSet
import SnapKit
import UIKit

class MaterialsFolderSelectorViewController: TKBaseViewController {
    private let contentViewHeight: CGFloat = UIScreen.main.bounds.height * 0.8
    var contentView: ViewBox?
    var collectionViewContainerView: View?
    @Live var folderCollectionViews: [MaterialsCollectionView] = []
    @Live private var isShowAddressMoreLineButton: Bool = false
    @Live private var isAddressOneLine: Bool = true
    @Live private var addressesLabelAlignment: UIStackView.Alignment = .center

    @Live var confirmButtonTitle: String = "CONFIRM"
    @Live private var confirmButtonStyle: TKBlockButton.Style = .normal
    private var firstTouchLocationInFolderCollectionView: CGPoint?

    @Live var selectedFolder: String = ""
    var excepteFolder: [String] = []

    var onFolderSelected: ((TKMaterial?) -> Void)?

    var dataList: [String: [TKMaterialFolderModel]] = [:]
    var dataSource: [String: TKMaterial] = [:]
    init(_ data: [TKMaterial]) {
        for item in data {
            dataSource[item.id] = item
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        logger.debug("销毁 => MaterialsFolderSelectorViewController")
    }

    private var isShow: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
}

extension MaterialsFolderSelectorViewController {
    private func show() {
        guard !isShow else { return }
        isShow = true
        showFolder("")
        UIView.animate(withDuration: 0.2) {
            self.contentView?.transform = .identity
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        }
    }

    private func hide(_ completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2) {
            self.contentView?.transform = CGAffineTransform(translationX: 0, y: self.contentViewHeight)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: false, completion: completion)
        }
    }

    private func showFolder(_ id: String) {
        firstTouchLocationInFolderCollectionView = nil
        selectedFolder = id
        let folderCollectionView = makeFolderCollectionView(id)
        folderCollectionView.reloadData()
        folderCollectionView.isHidden = true
        folderCollectionViews.insert(folderCollectionView, at: 0)
        collectionViewContainerView?.addSubview(view: folderCollectionView) { make in
            make.edges.equalToSuperview()
        }
        if id == "" {
            // 首页
            folderCollectionView.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
        } else {
            folderCollectionView.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
        }
        folderCollectionView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            folderCollectionView.transform = .identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.reloadAllFolderList(force: true)
        }
    }

    private func hideFolder() {
        guard let folderCollectionView = folderCollectionViews.first else {
            logger.debug("当前folder为空")
            return
        }
        firstTouchLocationInFolderCollectionView = nil
        let id = folderCollectionView.materialsId
        UIView.animate(withDuration: 0.2) {
            folderCollectionView.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            folderCollectionView.removeFromSuperview()
            self.folderCollectionViews.removeElements({ $0.materialsId == folderCollectionView.materialsId })
            self.selectedFolder = id
            self.reloadAllFolderList(force: true)
        }
    }

    private func jumpToFolder(_ id: String) {
        // 调准到对应目录
        guard let index = folderCollectionViews.firstIndex(where: { $0.materialsId == id }) else { return }
        firstTouchLocationInFolderCollectionView = nil
        selectedFolder = id
        UIView.animate(withDuration: 0.2) {
            for (i, folderCollectionView) in self.folderCollectionViews.enumerated() where i < index {
                folderCollectionView.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
            }
        } completion: { [weak self] _ in
            guard let self = self else { return }
            var ids: [String] = []
            for (i, folderCollectionView) in self.folderCollectionViews.enumerated() where i < index {
                folderCollectionView.removeFromSuperview()
                ids.append(folderCollectionView.materialsId)
            }
            self.folderCollectionViews.removeElements({ ids.contains($0.materialsId) })
            self.reloadAllFolderList(force: true)
        }
    }
}

extension MaterialsFolderSelectorViewController {
    private var addressesView: ViewBox {
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            HStack {
                Label().numberOfLines(0)
                    .lineBreakMode(.byTruncatingHead)
                    .apply { [weak self] label in
                        guard let self = self else { return }
                        self.$folderCollectionViews.addSubscriber { collectionViews in
                            guard collectionViews.count > 1 else {
                                return
                            }
                            logger.debug("地址View => 监听到folder文件夹数量变化: \(collectionViews.count)")
                            // 获取所有的文件夹名
                            var attributedString: ASAttributedString = ASAttributedString("Home", .font(FontUtil.regular(size: 13)), .foreground(ColorUtil.Font.primary), .action {
                                logger.debug("跳转到根目录")
                                self.jumpToFolder("")
                            })
                            attributedString += ASAttributedString(string: " / ", with: [.font(FontUtil.regular(size: 13)), .foreground(ColorUtil.Font.primary)])
                            logger.debug("地址View => 开始遍历文件夹树")
                            for (index, collectionView) in collectionViews.reversed().enumerated() {
                                logger.debug("地址View => 遍历文件夹: \(collectionView.materialsId)")
                                if let folder = self.dataSource[collectionView.materialsId] {
                                    logger.debug("地址View => 获取到文件夹: \(folder.id)")
                                    var attributeds: [ASAttributedString.Attribute] = [.font(FontUtil.regular(size: 13)), .foreground(ColorUtil.Font.primary)]
                                    if index != collectionViews.count - 1 {
                                        attributeds.append(.action({
                                            logger.debug("跳转到目录: \(collectionView.materialsId)")
                                            self.jumpToFolder(collectionView.materialsId)
                                        }))
                                    }
                                    attributedString += ASAttributedString(string: folder.name, with: attributeds)
                                    if index != collectionViews.count - 1 {
                                        attributedString += ASAttributedString(string: " / ", with: [.font(FontUtil.regular(size: 13)), .foreground(ColorUtil.Font.primary)])
                                    }
                                }
                            }
                            label.attributed.text = attributedString
                            let rect = attributedString.value.boundingRect(with: CGSize(width: UIScreen.main.bounds.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                            if rect.size.height > 18 {
                                // 多行了
                                self.isShowAddressMoreLineButton = true
                                if self.isAddressOneLine {
                                    // 只显示了一行
                                    self.addressesLabelAlignment = .center
                                } else {
                                    self.addressesLabelAlignment = .top
                                }
                            } else {
                                self.isShowAddressMoreLineButton = false
                                self.addressesLabelAlignment = .center
                            }
                        }

                        self.$isAddressOneLine.addSubscriber { isOneLine in
                            if isOneLine {
                                _ = label.numberOfLines(1)
                                self.addressesLabelAlignment = .center
                            } else {
                                _ = label.numberOfLines(0)
                                // 获取attributeString
                                if let attributedString = label.attributedText {
                                    let rect = attributedString.boundingRect(with: CGSize(width: UIScreen.main.bounds.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
                                    if rect.size.height > 18 {
                                        if isOneLine {
                                            self.addressesLabelAlignment = .center
                                        } else {
                                            self.addressesLabelAlignment = .top
                                        }
                                    }
                                }
                            }
                        }
                    }
                Button().image(UIImage(named: "icArrowTop")!.resizeImage(CGSize(width: 22, height: 22)), for: .normal)
                    .size(width: 22, height: 22)
                    .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                    .contentHuggingPriority(.defaultHigh, for: .horizontal)
                    .apply { [weak self] button in
                        guard let self = self else { return }
                        self.$isShowAddressMoreLineButton.addSubscriber { isShow in
                            if isShow {
                                button.isHidden = false
                            } else {
                                button.isHidden = true
                            }
                        }
                    }
                    .onTapped { [weak self] button in
                        guard let self = self else { return }
                        self.isAddressOneLine.toggle()
                        UIView.animate(withDuration: 0.2) {
                            if self.isAddressOneLine {
                                // 一行
                                button.transform = .identity
                            } else {
                                // 多行
                                button.transform = CGAffineTransform(rotationAngle: .pi)
                            }
                        }
                    }
                View().backgroundColor(UIColor.black.withAlphaComponent(0))
                    .size(width: 1, height: 22)
                    .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                    .contentHuggingPriority(.defaultHigh, for: .horizontal)
            }
            .apply { [weak self] stackView in
                guard let self = self else { return }
                self.$addressesLabelAlignment.addSubscriber { alignment in
                    stackView.alignment = alignment
                }
            }
        }
        .backgroundColor(.white)
        .apply { [weak self] view in
            guard let self = self else { return }
            self.$folderCollectionViews.addSubscriber { collectionViews in
                view.isHidden = collectionViews.count == 1
            }
        }
    }
}

extension MaterialsFolderSelectorViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView = ViewBox(paddings: .zero) {
            VStack {
                ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                    Label("Choose folder").textColor(ColorUtil.Font.primary)
                        .font(FontUtil.regular(size: 13))
                        .size(height: 15)
                }
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)) {
                    View().contentHuggingPriority(.defaultLow, for: .vertical)
                        .contentCompressionResistancePriority(.defaultLow, for: .vertical)
                        .apply { [weak self] view in
                            guard let self = self else { return }
                            self.collectionViewContainerView = view
                        }
                }
                addressesView
                ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: UiUtil.safeAreaBottom(), right: 20)) {
                    HStack(distribution: .fillEqually, spacing: 10) {
                        BlockButton().set(title: "GO BACK", style: .cancel)
                            .size(height: 50)
                            .onTapped { [weak self] _ in
                                self?.hide()
                            }
                        BlockButton().set(title: $confirmButtonTitle, style: $confirmButtonStyle)
                            .size(height: 50)
                            .apply { [weak self] button in
                                guard let self = self else { return }
                                self.$selectedFolder.addSubscriber { selectedFolder in
                                    if self.excepteFolder.contains(selectedFolder) {
                                        button.disable()
                                    } else {
                                        button.enable()
                                    }
                                }
                            }
                            .onTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.hide {
                                    if !self.selectedFolder.isEmpty  {
                                        self.onFolderSelected?(self.dataSource[self.selectedFolder])
                                    } else {
                                        self.onFolderSelected?(nil)
                                    }
                                }
                            }
                            
                    }
                }
            }
        }
        .backgroundColor(.white)
        .cornerRadius(10)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        contentView?.addTo(superView: view) { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(contentViewHeight)
        }
        contentView?.transform = CGAffineTransform(translationX: 0, y: contentViewHeight)
    }
}

extension MaterialsFolderSelectorViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let collectionView = collectionView as? MaterialsCollectionView else { return }
        let folderList = getFolderList(collectionView.materialsId)
        let item = folderList[indexPath.item]
        switch item.type {
        case .home:
            logger.debug("选择home")
            selectedFolder = ""
        case .createNewFolder:
            logger.debug("选择new folder")
            newFolder()
        case .folder:
            guard let folder = item.data else { return }
            showFolder(folder.id)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let collectionView = collectionView as? MaterialsCollectionView else { return 0 }
        let folderId = collectionView.materialsId
        return getFolderList(folderId).count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MaterialFolderCollectionViewCell.self), for: indexPath) as! MaterialFolderCollectionViewCell
        if let collectionView = collectionView as? MaterialsCollectionView {
            let folderId = collectionView.materialsId
            let folderList: [TKMaterialFolderModel] = getFolderList(folderId)
            let itemData = folderList[indexPath.item]
            cell.loadData(data: itemData)
        }

        return cell
    }

    private func getFolderList(_ folderId: String, force: Bool = false) -> [TKMaterialFolderModel] {
        if force {
            let data = dataSource.values.filter({ $0.folder == folderId && $0.type == .folder }).sorted(by: { $0.name < $1.name })
            var folders: [TKMaterialFolderModel] = []
            if folderId == "" {
                folders.append(TKMaterialFolderModel(type: .home, data: nil, isSelected: selectedFolder == ""))
                folders.append(TKMaterialFolderModel(type: .createNewFolder, data: nil, isSelected: false))
            } else {
                folders.append(TKMaterialFolderModel(type: .createNewFolder, data: nil, isSelected: false))
            }
            folders += data.compactMap({ TKMaterialFolderModel(type: .folder, data: $0, isSelected: selectedFolder == $0.id) })
            dataList[folderId] = folders
            return folders
        } else {
            if let folders = dataList[folderId] {
                return folders
            } else {
                let data = dataSource.values.filter({ $0.folder == folderId && $0.type == .folder }).sorted(by: { $0.name < $1.name })
                var folders: [TKMaterialFolderModel] = []
                if folderId == "" {
                    folders.append(TKMaterialFolderModel(type: .home, data: nil, isSelected: selectedFolder == ""))
                    folders.append(TKMaterialFolderModel(type: .createNewFolder, data: nil, isSelected: false))
                } else {
                    folders.append(TKMaterialFolderModel(type: .createNewFolder, data: nil, isSelected: false))
                }
                folders += data.compactMap({ TKMaterialFolderModel(type: .folder, data: $0, isSelected: selectedFolder == $0.id) })
                dataList[folderId] = folders
                return folders
            }
        }
    }

    private func reloadFolderList(_ folderId: String, force: Bool = false) {
        _ = getFolderList(folderId, force: force)
    }

    private func reloadAllFolderList(force: Bool = false) {
        for folderCollectionView in folderCollectionViews {
            reloadFolderList(folderCollectionView.materialsId, force: force)
            folderCollectionView.reloadData()
        }
    }
}

extension MaterialsFolderSelectorViewController {
    private func makeFolderCollectionView(_ folderId: String) -> MaterialsCollectionView {
        let layout = UICollectionViewFlowLayout()
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
        layout.itemSize = CGSize(width: width, height: 143)
        layout.minimumInteritemSpacing = padding
        layout.scrollDirection = .vertical
        let collectionView = MaterialsCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.materialsId = folderId
        collectionView.register(MaterialFolderCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: MaterialFolderCollectionViewCell.self))
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        if !folderId.isEmpty {
            addGestureForFolderCollectionView(collectionView)
        }
        return collectionView
    }

    private func addGestureForFolderCollectionView(_ folderCollectionView: MaterialsCollectionView) {
        let panGesture = UIPanGestureRecognizer()
        panGesture.delegate = self
        panGesture.maximumNumberOfTouches = 1
        panGesture.minimumNumberOfTouches = 1
        panGesture.addTarget(self, action: #selector(onPanGesture(_:)))
        folderCollectionView.addGestureRecognizer(panGesture)
    }

    @objc private func onPanGesture(_ panGesture: UIPanGestureRecognizer) {
        guard let folderCollectionView = panGesture.view else { return }
        let point = panGesture.translation(in: folderCollectionView)
        if firstTouchLocationInFolderCollectionView == nil {
            // 第一次触摸
            let location = panGesture.location(in: folderCollectionView)
            guard location.x <= UIScreen.main.bounds.width * 0.15 else {
                return
            }
            firstTouchLocationInFolderCollectionView = location
        }
        let v = panGesture.velocity(in: folderCollectionView)
        switch panGesture.state {
        case .began, .changed, .possible:
            if point.x >= 0 {
                folderCollectionView.transform = CGAffineTransform(translationX: point.x * 1, y: 0)
            }
        default:
            firstTouchLocationInFolderCollectionView = nil
            if (point.x + v.x) / UIScreen.main.bounds.width > 0.5 {
                hideFolder()
            } else {
                UIView.animate(withDuration: 0.2) {
                    folderCollectionView.transform = .identity
                }
            }
        }
    }
}

extension MaterialsFolderSelectorViewController {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MaterialsFolderSelectorViewController {
    private func newFolder() {
        let controller = TextFieldPopupViewController()
        controller.placeholder = "Folder Name"
        controller.leftButtonString = "CANCEL"
        controller.titleString = "New folder"
        controller.titleAlignment = .left
        controller.rightButtonString = "CONFIRM"
        controller.rightButton?.disable()
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] name in
            guard let self = self else { return }
            controller.hide()
            self.newFolder(withName: name.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        controller.onTextChanged = { name, _, rightButton in
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                rightButton.disable()
            } else {
                rightButton.enable()
            }
        }
        controller.modalPresentationStyle = .custom
        Tools.getTopViewController()?.present(controller, animated: false)
    }

    private func newFolder(withName name: String) {
        guard let userId = UserService.user.id() else { return }
        let now = Date().timestamp
        let folder = TKMaterial()
        folder.id = IDUtil.nextId()?.description ?? "\(now)"
        folder.creatorId = userId
        folder.type = .folder
        folder.name = name
        folder.desc = ""
        let parentId: String
        if let folderCollectionView = folderCollectionViews.first {
            parentId = folderCollectionView.materialsId
        } else {
            parentId = ""
        }
        folder.folder = parentId
        folder.createTime = now.description
        folder.updateTime = now.description
        logger.debug("准备创建的文件夹: \(folder.toJSONString() ?? "")")
        showFullScreenLoadingNoAutoHide()
        DatabaseService.collections.material()
            .document(folder.id)
            .setData(folder.toJSON() ?? [:], merge: true) { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.debug("error: \(error)")
                    TKToast.show(msg: "Create new folder failed, please try again later.", style: .error)
                } else {
                    self.dataSource[folder.id] = folder
                    self.reloadAllFolderList(force: true)
                }
            }
    }
}
