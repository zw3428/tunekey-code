//
//  MaterialsV3ViewController.swift
//  TuneKey
//
//  Created by 砚枫张 on 2024/3/25.
//  Copyright © 2024 spelist. All rights reserved.
//

import Alamofire
import AttributedString
import AVFoundation
import AVKit
import DZNEmptyDataSet
import FirebaseFirestore
import FirebaseFunctions
import PromiseKit
import SnapKit
import SwiftDate
import UIKit

extension MaterialsV3ViewController {
    enum Style {
        case main
        case list
        case share
    }

    actor FileMetadata {
        var data: [String: StorageMetadata?] = [:]

        func append(id: String, metadata: StorageMetadata?) {
            data[id] = metadata
        }

        func getData() -> [String: StorageMetadata?] {
            return data
        }
    }

    struct GroupedFiles {
        var title: NSAttributedString

        /// 用来控制排名
        var weight: Double
        var files: [TKMaterial]
    }
}

class MaterialsV3ViewController: TKBaseViewController {
    private lazy var navigationBar: TKNormalNavigationBar = .init(frame: .zero, title: "Materials")

    private lazy var backButton: Button = Button().image(UIImage(named: "back"), for: .normal)
    private lazy var selectButton: Button = Button().image(UIImage(named: "multiple_select"), for: .normal)
    private lazy var addButton: Button = Button().image(UIImage(named: "icAddPrimary"), for: .normal)
    private lazy var filterButton: Button = Button().image(UIImage(named: "filter"), for: .normal)
    private var collectionViewContainerView: View = View().backgroundColor(ColorUtil.backgroundColor)

    private lazy var searchBar: TKSearchBar = {
        let searchBar = TKSearchBar()
        searchBar.delegate = self
        return searchBar
    }()

    @Live private var collectionViews: [MaterialsCollectionView] = []

    @Live private var isShowAddressMoreLineButton: Bool = false
    @Live private var isAddressOneLine: Bool = true
    @Live private var addressesLabelAlignment: UIStackView.Alignment = .center
    private lazy var addressView: ViewBox = makeAddressesView()

    private lazy var editableBottomButtonsView: ViewBox = makeEditableBottomButtonsView()

    private let searchCollectionViewTag: Int = 1
    private let materialCollectionViewTag: Int = 0

    private var firstTouchLocationInFolderCollectionView: CGPoint?

    private let gridIconSize: CGSize = .init(width: 44, height: 56)
    private let listIconSize: CGSize = .init(width: 25, height: 32)

    /// 元数据
    @Live var fileMetadata: FileMetadata = FileMetadata()

    /// 当前页面对应的Filter
    @Live var filters: [String: MaterialsFilter] = [:]
    /// 当前页面对应的数据,key=folderId | value=当前文件夹的所有文件
    @Live var data: [String: [GroupedFiles]] = [:]
    private var allData: [String: TKMaterial] = [:]

    @Live var isEditable: Bool = false
    @Live var selectedFiles: [String] = []

    @Live var isSearching: Bool = false
    private var searchKey: String = ""
    @Live private var searchResult: [TKMaterial] = []

    var onShareButtonTappedInShareStyle: ((_ silent: Bool, _ selectedFiles: [TKMaterial]) -> Void)?

    @Live var style: Style
    init(_ style: Style, files: [TKMaterial] = []) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
        if style == .share {
            isEditable = true
        }
        initListeners()
        if files.isNotEmpty {
            allData = files.reduce(into: [String: TKMaterial]()) { partialResult, item in
                partialResult[item.id] = item
            }

            let groupedFiles = Dictionary(grouping: files) { file in
                file.folder
            }
            for (folder, files) in groupedFiles {
                setupGroupedFiles(files, folderId: folder)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runOnce { [weak self] in
            guard let self = self else { return }
            self.loadData()
        }
        if let currentFolderId = getCurrentFolderId() {
            loadMaterials(folderId: currentFolderId)
        }
    }
}

extension MaterialsV3ViewController {
    private func loadData() {
        switch style {
        case .main, .share:
            initMainData()
        case .list:
            break
        }
    }

    /// 初始化main页面的时候所有第一层的数据
    private func initMainData() {
        guard let currentRole = ListenerService.shared.currentRole else { return }
        if currentRole == .teacher {
            initAllData(ListenerService.shared.studioManagerData.homeMaterials)
        } else if currentRole == .student || currentRole == .parent {
            if ParentService.shared.isCurrentRoleParent() {
                logger.debug("家长获取students的materials")
                ParentService.shared.fetchCurrentStudentMaterials()
                    .done { [weak self] materials in
                        guard let self = self else { return }
                        logger.debug("家长获取students的materials成功： \(materials.count)")
                        self.initAllData(materials)
                    }
                    .catch { [weak self] error in
                        guard let self = self else { return }
                        logger.error("家长获取students的materials失败： \(error)")
                        self.initAllData([])
                    }
            } else {
                initAllData(ListenerService.shared.studentData.materials)
            }
        }
        loadMaterials(folderId: "")
    }

    private func initAllData(_ allMaterials: [TKMaterial]) {
        logger.debug("所有的材料数量: \(allMaterials.count)")
        // 判断当前的Materials里，如果某个文件的文件夹，不存在在当前的所有文件夹中，那就证明这个文件是分享的子文件，是历史问题，要渲染出来，直接设置它的folderID为空
        let allFoldersIds = allMaterials.filter { $0.type == .folder }
            .compactMap { $0.id }
            .filterDuplicates { $0 }

        for material in allMaterials {
            if !allFoldersIds.contains(material.folder) {
                // 说明当前文件夹不存在于所有的文件夹内，把当前文件放在首页
                material.folder = ""
            }
            allData[material.id] = material
        }

        reloadData()
    }
}

extension MaterialsV3ViewController {
    override func initView() {
        super.initView()
        navigationBar.updateLayout(target: self)
        navigationBar.hiddenLeftButton()

        HStack(alignment: .center, spacing: 10) {
            backButton.size(width: 22, height: 22)
                .apply { [weak self] button in
                    guard let self = self else { return }
                    self.$collectionViews.addSubscriber { collectionViews in
                        if self.style == .main {
                            if self.isEditable {
                                button.isHidden = true
                            } else {
                                if collectionViews.count > 1 {
                                    button.isHidden = false
                                } else {
                                    button.isHidden = true
                                }
                            }
                        } else {
                            button.isHidden = false
                        }
                    }

                    self.$isEditable.addSubscriber { isEditable in
                        if self.style == .main {
                            if isEditable {
                                button.isHidden = true
                            } else {
                                if self.collectionViews.count > 1 {
                                    button.isHidden = false
                                } else {
                                    button.isHidden = true
                                }
                            }
                        } else {
                            button.isHidden = false
                        }
                    }
                }
                .onTapped { [weak self] _ in
                    guard let self = self else { return }
                    if self.style != .main {
                        if self.collectionViews.count > 1 {
                            self.popCollectionView()
                        } else {
                            self.dismiss(animated: true)
                        }
                    } else {
                        self.popCollectionView()
                    }
                }
            selectButton.size(width: 22, height: 22)
        }.addTo(superView: navigationBar) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(22)
        }

        filterButton.isHidden($isEditable)
            .addTo(superView: navigationBar) { make in
                make.bottom.equalToSuperview().offset(-10)
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(22)
            }

        addButton
            .apply { [weak self] button in
                guard let self = self else { return }
                self.$style.addSubscriber { style in
                    if style == .main {
                        if self.isEditable {
                            button.isHidden = true
                        } else {
                            button.isHidden = false
                        }
                    } else {
                        button.isHidden = true
                    }
                }

                self.$isEditable.addSubscriber { isEditable in
                    if self.style == .main {
                        if isEditable {
                            button.isHidden = true
                        } else {
                            button.isHidden = false
                        }
                    } else {
                        button.isHidden = true
                    }
                }
            }
            .addTo(superView: navigationBar) { make in
                make.bottom.equalToSuperview().offset(-10)
                make.right.equalTo(filterButton.snp.left).offset(-20)
                make.size.equalTo(22)
            }

        searchBar.addTo(superView: view) { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(36)
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
        }

        addressView.addTo(superView: view) { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        collectionViewContainerView.addTo(superView: view) { make in
            make.top.equalTo(searchBar.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }
        pushCollectionView(id: "")

        editableBottomButtonsView.addTo(superView: view) { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        editableBottomButtonsView.transform = CGAffineTransform(translationX: 0, y: 10 + 50 + UiUtil.safeAreaBottom())
        editableBottomButtonsView.layer.opacity = 0

        let searchCollectionView: MaterialsCollectionView = makeCollectionView(id: "")
        searchCollectionView.tag = searchCollectionViewTag
        searchCollectionView.addTo(superView: collectionViewContainerView) { make in
            make.edges.equalToSuperview()
        }

        $isSearching.addSubscriber { isSearching in
            if isSearching {
                searchCollectionView.isHidden = false
            } else {
                searchCollectionView.isHidden = true
            }
        }

        $searchResult.addSubscriber { _ in
            searchCollectionView.reloadData()
        }
    }

    private func pushCollectionView(id: String, animate: Bool = false, addGesture: Bool = false) {
        let collectionView: MaterialsCollectionView = makeCollectionView(id: id)
        collectionViews.append(collectionView)
        collectionView.addTo(superView: collectionViewContainerView) { make in
            make.center.size.equalToSuperview()
        }
        if animate {
            collectionView.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
            UIView.animate(withDuration: 0.2) {
                collectionView.transform = .identity
            }
        }
        collectionView.reloadData()
        reloadFilter(id)
        loadMaterials(folderId: id)
//        if addGesture {
//            let panGesture = UIPanGestureRecognizer()
//            panGesture.delegate = self
//            panGesture.maximumNumberOfTouches = 1
//            panGesture.minimumNumberOfTouches = 1
//            panGesture.addTarget(self, action: #selector(onCollectionViewPanGesture(_:)))
//            collectionView.addGestureRecognizer(panGesture)
//        }
        collectionView.reloadData()
        view.bringSubviewToFront(addressView)

        $isSearching.addSubscriber { isSearching in
            if isSearching {
                collectionView.isHidden = true
            } else {
                collectionView.isHidden = false
            }
        }
    }

    private func popCollectionView() {
        guard let collectionView = collectionViews.last, collectionView.materialsId.isNotEmpty else { return }
        UIView.animate(withDuration: 0.2) {
            collectionView.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.collectionViews.removeLast()
            collectionView.removeFromSuperview()
            if let topCollectionView = self.collectionViews.last {
                self.loadMaterials(folderId: topCollectionView.materialsId)
            }
        }
    }

    private func reloadFilter(_ id: String) {
        let filter = MaterialsFilter.get(id)
        filters[id] = filter
    }

    @objc private func onCollectionViewPanGesture(_ panGesture: UIPanGestureRecognizer) {
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
                popCollectionView()
            } else {
                UIView.animate(withDuration: 0.2) {
                    folderCollectionView.transform = .identity
                }
            }
        }
    }

    private func jumpToFolder(_ folderId: String) {
        // 跳转到folderId的CollectionView，就把在这个CollectionView之上的所有view都push出去
        guard let index = collectionViews.firstIndex(where: { $0.materialsId == folderId }) else {
            logger.debug("[跳转到文件夹] => 无法获取到正确的文件夹的index")
            return
        }
        logger.debug("[跳转到文件夹] => 获取到的index: \(index)")
        logger.debug("[跳转到文件夹] => 开始获取id和index")
        for (i, folderCollectionView) in collectionViews.enumerated() where i > index {
            logger.debug("[跳转到文件夹] => 当前index[\(i)] -> 对应的文件夹id: [\(folderCollectionView.materialsId)]")
        }
        UIView.animate(withDuration: 0.2) {
            for (i, folderCollectionView) in self.collectionViews.enumerated() where i > index {
                folderCollectionView.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
                logger.debug("[跳转到文件夹] => pop文件夹[\(i)] -> id:[\(folderCollectionView.materialsId)]")
            }
        } completion: { [weak self] _ in
            guard let self = self else { return }
            var ids: [String] = []
            for (i, folderCollectionView) in self.collectionViews.enumerated() where i > index {
                folderCollectionView.removeFromSuperview()
                ids.append(folderCollectionView.materialsId)
            }
            self.collectionViews.removeElements({ ids.contains($0.materialsId) })
            self.collectionViews.first?.reloadData()
        }
    }
}

extension MaterialsV3ViewController {
    private func makeEditableBottomButtonsView() -> ViewBox {
        ViewBox(top: 10, left: 40, bottom: UiUtil.safeAreaBottom(), right: 40) {
            if style == .share {
                VStack(alignment: .center, spacing: 20) {
                    BlockButton(title: "SHARE", style: .normal)
                        .size(width: 180, height: 50)
                        .onTapped { [weak self] _ in
                            guard let self = self else { return }
                            self.onShareButtonTappedInShareStyle?(false, self.selectedFiles.compactMap({ self.allData[$0] }))
                        }

                    Button().title("Share Silently", for: .normal)
                        .titleColor(.clickable, for: .normal)
                        .font(.content)
                        .onTapped { [weak self] _ in
                            guard let self = self else { return }
                            self.onShareButtonTappedInShareStyle?(true, self.selectedFiles.compactMap({ self.allData[$0] }))
                        }
                }
            } else {
                HStack(distribution: .fillEqually, alignment: .center, spacing: 10) {
                    Button().title("Delete", for: .normal)
                        .title("Delete", for: .disabled)
                        .titleColor(.tertiary, for: .disabled)
                        .titleColor(ColorUtil.blush, for: .normal)
                        .font(.bold(18))
                        .height(50)
                        .apply { [weak self] button in
                            guard let self = self else { return }
                            self.$selectedFiles.addSubscriber { selectedFiles in
                                if selectedFiles.isEmpty {
                                    button.isEnabled = false
                                } else {
                                    button.isEnabled = true
                                }
                            }
                        }
                        .onTapped { [weak self] _ in
                            guard let self = self else { return }
                            self.onDeleteButtonTapped()
                        }

                    Button().title("Share", for: .normal)
                        .titleColor(.clickable, for: .normal)
                        .title("Share", for: .disabled)
                        .titleColor(.tertiary, for: .disabled)
                        .font(.bold(18))
                        .height(50)
                        .apply { [weak self] button in
                            guard let self = self else { return }
                            self.$selectedFiles.addSubscriber { selectedFiles in
                                if selectedFiles.isEmpty {
                                    button.isEnabled = false
                                } else {
                                    button.isEnabled = true
                                }
                            }
                        }
                        .onTapped { [weak self] _ in
                            guard let self = self else { return }
                            self.onShareButtonTapped()
                        }

                    Button().title("Move", for: .normal)
                        .titleColor(.clickable, for: .normal)
                        .title("Move", for: .disabled)
                        .titleColor(.tertiary, for: .disabled)
                        .font(.bold(18))
                        .height(50)
                        .apply { [weak self] button in
                            guard let self = self else { return }
                            self.$selectedFiles.addSubscriber { selectedFiles in
                                if selectedFiles.isEmpty {
                                    button.isEnabled = false
                                } else {
                                    button.isEnabled = true
                                }
                            }
                        }
                        .onTapped { [weak self] _ in
                            guard let self = self else { return }
                            self.onMoveButtonTapped()
                        }
                }
            }
        }
        .backgroundColor(.white)
    }
}

extension MaterialsV3ViewController {
    private func makeCollectionView(id: String) -> MaterialsCollectionView {
        let collectionView = MaterialsCollectionView(frame: .zero, collectionViewLayout: makeCollectionViewFlowLayout())
        collectionView.materialsId = id
        collectionView.z.register(cell: MaterialV3GridCollectionViewCell.self)
        collectionView.z.register(cell: MaterialV3ListCollectionViewCell.self)
        collectionView.register(MaterialsV3HeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.tag = materialCollectionViewTag
        collectionView.dropDelegate = self
        collectionView.dragDelegate = self
        collectionView.dragInteractionEnabled = true

        return collectionView
    }

    private func makeCollectionViewFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        return layout
    }

    private func makeAddressesView() -> ViewBox {
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            HStack {
                Label().numberOfLines(0)
                    .lineBreakMode(.byTruncatingHead)
                    .apply { [weak self] label in
                        guard let self = self else { return }
                        self.$collectionViews.addSubscriber { collectionViews in
                            guard !collectionViews.isEmpty else {
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
                            for (index, collectionView) in collectionViews.enumerated() {
                                logger.debug("地址View => 遍历文件夹: \(collectionView.materialsId)")
                                if let folder = self.allData[collectionView.materialsId] {
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
                            let rect = attributedString.value.boundingRect(with: CGSize(width: UIScreen.main.bounds.width - 40, height: CGFloat.infinity), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                            let height = ceil(rect.size.height)
                            logger.debug("计算出的路径高度: \(height)")
                            if height > 16 {
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
                                    let rect = attributedString.boundingRect(with: CGSize(width: UIScreen.main.bounds.width - 40, height: CGFloat.infinity), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                                    let height = ceil(rect.size.height)
                                    if height > 16 {
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
        .backgroundColor(ColorUtil.backgroundColor)
        .apply { [weak self] view in
            guard let self = self else { return }
            self.$collectionViews.addSubscriber { collectionViews in
                view.isHidden = collectionViews.filter({ $0.materialsId.isNotEmpty }).isEmpty
            }
        }
    }
}

extension MaterialsV3ViewController {
    private func getData(folderId: String, atSection section: Int) -> [TKMaterial] {
        guard let filter = filters[folderId] else {
            logger.error("无法获取到Filter[\(folderId)]")
            return []
        }
        let groupedFiles = (data[folderId] ?? []).sorted(by: { $0.weight < $1.weight })
        let files = groupedFiles[section]

        return files.files.sorted { file1, file2 in
            switch filter.sortBy {
            case .updateDate:
                let file1UpdateTime = TimeInterval(file1.updateTime) ?? 0
                let file2UpdateTime = TimeInterval(file2.updateTime) ?? 0
                switch filter.order {
                case .asc:
                    return file1UpdateTime < file2UpdateTime
                case .desc:
                    return file1UpdateTime > file2UpdateTime
                }
            case .fileName:
                switch filter.order {
                case .asc:
                    return file1.name < file2.name
                case .desc:
                    return file1.name > file2.name
                }
            }
        }
    }
}

extension MaterialsV3ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionView = collectionView as! MaterialsCollectionView
        var filter: MaterialsFilter?
        let file: TKMaterial
        if collectionView.tag == materialCollectionViewTag {
            filter = filters[collectionView.materialsId]
            let files: [TKMaterial] = getData(folderId: collectionView.materialsId, atSection: indexPath.section)
            file = files[indexPath.item]
        } else {
            // 搜索
            filter = filters[""]
            file = searchResult[indexPath.item]
        }
        let viewType: MaterialsFilter.ViewType = filter?.view ?? .grid
        var imageURL: String = ""
        var imageName: String = ""
        var imageSize: CGSize = .zero
        var isPlayButtonShow: Bool = false
        var playButtonSize: CGSize = .zero
        var makePlayButtonCenter: Bool = false
        switch file.type {
        case .folder:
            imageName = "folder_empty"
            switch viewType {
            case .grid:
                imageSize = .init(width: 48, height: 48)
            case .list:
                imageSize = .init(width: 32, height: 32)
            }
        case .none:
            break
        case .file:
            imageName = "otherFile"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .pdf:
            imageName = "imgPdf"
        case .image:
            if file.status == .failed {
                imageName = "imgJpg"
            } else {
                imageURL = file.url
            }
        case .txt:
            imageName = "imgTxt"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .word:
            imageName = "imgDoc"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .ppt:
            imageName = "imgPpt"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .mp3:
            imageName = "imgMp3"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
            isPlayButtonShow = true
            playButtonSize = .init(width: 20, height: 20)
            makePlayButtonCenter = false
        case .video:
            imageURL = file.minPictureUrl
            isPlayButtonShow = true
            playButtonSize = .init(width: 40, height: 40)
            makePlayButtonCenter = true
        case .youtube:
            imageURL = file.minPictureUrl
            isPlayButtonShow = true
            playButtonSize = .init(width: 40, height: 40)
            makePlayButtonCenter = true
        case .link:
            imageURL = file.minPictureUrl
        case .excel:
            imageName = "imgExecl"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .pages:
            imageName = "imgPages"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .numbers:
            imageName = "imgNumbers"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .keynote:
            imageName = "imgKeynotes"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .googleDoc:
            imageName = "imgDocs"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .googleSheet:
            imageName = "imgSheets"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .googleSlides:
            imageName = "imgSlides"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .googleForms:
            imageName = "imgForms"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        case .googleDrawings:
            imageName = "imgDrawing"
            switch viewType {
            case .grid:
                imageSize = .init(width: 44, height: 56)
            case .list:
                imageSize = .init(width: 25, height: 32)
            }
        }
        let onMoreButtonTapped: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.onCollectionViewItemMoreButtonTapped(file)
        }
        switch viewType {
        case .grid:
            let cell: MaterialV3GridCollectionViewCell = collectionView.z.dequeueReusableCell(for: indexPath)
            cell.id = file.id
            cell.iconImage = .init(name: imageName, url: imageURL, size: imageSize)
            cell.isPlayButtonShow = isPlayButtonShow
            cell.playButtonSize = playButtonSize
            cell.makePlayButtonCenter = makePlayButtonCenter
            cell.title = Tools.attributenStringColor(text: file.name, selectedText: searchKey, allColor: .primary, selectedColor: .clickable, font: .content, selectedFont: .content, fontSize: UIFont.content.pointSize, selectedFontSize: UIFont.content.pointSize, ignoreCase: true, charasetSpace: 0)
            cell.subtitle = TimeInterval(file.updateTime)?.toLocalFormat("yyyy-MM-dd HH:mm:ss") ?? ""
            if let currentRole = ListenerService.shared.currentRole, currentRole == .teacher || currentRole == .studioManager {
                cell.avatars = file.studentIds.compactMap({ studentId in
                    .init(id: studentId, name: ListenerService.shared.studioManagerData.studentsMap[studentId]?.name ?? "")
                })
            } else {
                cell.avatars = []
            }

            cell.isEditable = isEditable
            cell.isFileSelected = selectedFiles.contains(file.id)
            cell.onMoreButtonTapped = onMoreButtonTapped
            return cell
        case .list:
            let cell: MaterialV3ListCollectionViewCell = collectionView.z.dequeueReusableCell(for: indexPath)
            cell.id = file.id
            cell.iconImage = .init(name: imageName, url: imageURL, size: imageSize)
            cell.isPlayButtonShow = isPlayButtonShow
            cell.playButtonSize = playButtonSize
            cell.makePlayButtonCenter = makePlayButtonCenter
            cell.title = Tools.attributenStringColor(text: file.name, selectedText: searchKey, allColor: .primary, selectedColor: .clickable, font: .title, selectedFont: .title, fontSize: UIFont.title.pointSize, selectedFontSize: UIFont.title.pointSize, ignoreCase: true, charasetSpace: 0)
            cell.info = "\(ListenerService.shared.user?.name ?? ""), \(TimeInterval(file.updateTime)?.toLocalFormat("yyyy-MM-dd HH:mm:ss") ?? "")"
            if let currentRole = ListenerService.shared.currentRole, currentRole == .teacher || currentRole == .studioManager {
                cell.avatars = file.studentIds.compactMap({ studentId in
                    .init(id: studentId, name: ListenerService.shared.studioManagerData.studentsMap[studentId]?.name ?? "")
                })
            } else {
                cell.avatars = []
            }
            cell.isEditable = isEditable
            cell.isFileSelected = selectedFiles.contains(file.id)
            cell.onMoreButtonTapped = onMoreButtonTapped
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let collectionView = collectionView as! MaterialsCollectionView
        if collectionView.tag == searchCollectionViewTag {
            return searchResult.count
        } else {
            return getData(folderId: collectionView.materialsId, atSection: section).count
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let collectionView = collectionView as! MaterialsCollectionView
        if collectionView.tag == searchCollectionViewTag {
            return 1
        } else {
            let groupedFiles = data[collectionView.materialsId]
            return groupedFiles?.count ?? 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let collectionView = collectionView as! MaterialsCollectionView
        if kind == UICollectionView.elementKindSectionHeader && collectionView.tag == materialCollectionViewTag {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! MaterialsV3HeaderCollectionReusableView
            let groupedFiles = (data[collectionView.materialsId] ?? []).sorted(by: { $0.weight < $1.weight })
            let groupedFile = groupedFiles[indexPath.section]
            header.title = groupedFile.title
            let filter = filters[collectionView.materialsId]
            header.isPaddingShow = (filter?.view ?? .list) == .list
            return header
        }

        return UICollectionReusableView()
    }
}

extension MaterialsV3ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionView: MaterialsCollectionView = collectionView as! MaterialsCollectionView
        let file: TKMaterial
        let folderId: String
        if collectionView.tag == materialCollectionViewTag {
            folderId = collectionView.materialsId
            let files = getData(folderId: folderId, atSection: indexPath.section)
            file = files[indexPath.item]
        } else {
            file = searchResult[indexPath.item]
            folderId = ""
        }
        if let filter = filters[folderId] {
            let viewType = filter.view
            switch viewType {
            case .grid:
                let width: CGFloat = (UIScreen.main.bounds.width - 40 - 10) / 3
                if let collectionViewLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                    collectionViewLayout.minimumLineSpacing = 10
                    collectionViewLayout.minimumInteritemSpacing = 5
                }
                return CGSize(width: width, height: 180)
            case .list:
                let width: CGFloat = UIScreen.main.bounds.width
                if let collectionViewLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                    collectionViewLayout.minimumLineSpacing = 0
                    collectionViewLayout.minimumInteritemSpacing = 0
                }
                // 减去左右两边的间距，就是中间文本容器的宽度
                let fixedWidth = UIScreen.main.bounds.width - 90 - 70
                let titleHeight: CGFloat = file.name.heightWithFont(font: .title, fixedWidth: fixedWidth)
                let infoHeight: CGFloat = "\(ListenerService.shared.user?.name ?? ""), \(TimeInterval(file.updateTime)?.toLocalFormat("yyyy-MM-dd HH:mm:ss") ?? "")".heightWithFont(font: .content, fixedWidth: fixedWidth)

                var height: CGFloat = 20 + titleHeight + 6 + infoHeight + 20
                if height <= 100 {
                    height = 100
                }
                return CGSize(width: width, height: height)
            }
        }

        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let collectionView = collectionView as! MaterialsCollectionView
        if collectionView.tag == searchCollectionViewTag {
            return CGSize(width: collectionView.bounds.width, height: 0)
        } else {
            let groupedFiles = data[collectionView.materialsId] ?? []
            let groupedFile = groupedFiles[section]
            if groupedFile.title.string.isEmpty {
                return CGSize(width: collectionView.bounds.width, height: 0)
            } else {
                return CGSize(width: collectionView.bounds.width, height: 50)
            }
        }
    }
}

extension MaterialsV3ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item: TKMaterial
        if collectionView.tag == searchCollectionViewTag {
            item = searchResult[indexPath.item]
        } else {
            item = getMaterialItem(withCollectionView: collectionView, atIndexPath: indexPath)
        }
        if isEditable {
            let isSelected: Bool
            if selectedFiles.contains(item.id) {
                selectedFiles.removeElements({ $0 == item.id })
                isSelected = false
            } else {
                selectedFiles.append(item.id)
                isSelected = true
            }
            if let cell = collectionView.cellForItem(at: indexPath) as? MaterialV3GridCollectionViewCell {
                cell.isFileSelected = isSelected
            } else if let cell = collectionView.cellForItem(at: indexPath) as? MaterialV3ListCollectionViewCell {
                cell.isFileSelected = isSelected
            }
        } else {
            if item.type == .folder {
                logger.debug("当前是点击的folder： \(item.id)")
                pushCollectionView(id: item.id, animate: true, addGesture: true)
            } else {
                logger.debug("点击材料: \(item.id)")
                onMaterialFileTapped(item)
            }
        }
    }

    private func onMaterialFileTapped(_ file: TKMaterial) {
        MaterialsHelper.cellClick(materialsData: file, mController: self)
    }

    func onCollectionViewItemMoreButtonTapped(_ item: TKMaterial) {
        var items: [PopSheet.Item] = [
            .init(title: "Details", action: { [weak self] in
                guard let self = self else { return }
                self.onMaterialDetailTapped(item)
            }),
        ]
        if style == .main, let currentRole = ListenerService.shared.currentRole, currentRole == .teacher || currentRole == .studioManager {
            items += [
                .init(title: "Share In-App", action: { [weak self] in
                    guard let self = self else { return }
                    self.selectedFiles = [item.id]
                    self.onShareButtonTapped()
                }),
            ]
        }
        if style == .main && item.creatorId == UserService.user.id() ?? "" {
            items += [
                .init(title: "Delete", action: { [weak self] in
                    guard let self = self else { return }
                    self.deleteMaterialsV2([item])
                }, tintColor: ColorUtil.red),
            ]
        }
        PopSheet().items(items)
            .show()
    }

    private func onMaterialDetailTapped(_ item: TKMaterial) {
        let controller = MaterialsV3DetailViewController(item)
        controller.modalPresentationStyle = .custom
        Tools.getTopViewController()?.present(controller, animated: false)
    }
}

extension MaterialsV3ViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard collectionView.tag == materialCollectionViewTag else { return [] }
        guard style == .main else { return [] }
        guard !isEditable else { return [] }
        let file = getMaterialItem(withCollectionView: collectionView, atIndexPath: indexPath)
        let itemProvider = NSItemProvider(object: file.id as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = file.id
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: any UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        guard collectionView.tag == materialCollectionViewTag else { return [] }
        guard style == .main else { return [] }
        guard !isEditable else { return [] }
        let file = getMaterialItem(withCollectionView: collectionView, atIndexPath: indexPath)
        let itemProvider = NSItemProvider(object: file.id as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = file.id
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let previewParameters = UIDragPreviewParameters()
        let collectionView: MaterialsCollectionView = collectionView as! MaterialsCollectionView
        let file: TKMaterial
        let folderId: String
        if collectionView.tag == materialCollectionViewTag {
            folderId = collectionView.materialsId
            let files = getData(folderId: folderId, atSection: indexPath.section)
            file = files[indexPath.item]
        } else {
            file = searchResult[indexPath.item]
            folderId = ""
        }
        var size: CGSize = .zero
        if let filter = filters[folderId] {
            let viewType = filter.view
            switch viewType {
            case .grid:
                let width: CGFloat = (UIScreen.main.bounds.width - 40 - 10) / 3
                if let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    collectionViewLayout.minimumLineSpacing = 10
                    collectionViewLayout.minimumInteritemSpacing = 5
                }
                size = CGSize(width: width, height: 180)
            case .list:
                let width: CGFloat = UIScreen.main.bounds.width
                if let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    collectionViewLayout.minimumLineSpacing = 0
                    collectionViewLayout.minimumInteritemSpacing = 0
                }
                // 减去左右两边的间距，就是中间文本容器的宽度
                let fixedWidth = UIScreen.main.bounds.width - 90 - 70
                let titleHeight: CGFloat = file.name.heightWithFont(font: .title, fixedWidth: fixedWidth)
                let infoHeight: CGFloat = "\(ListenerService.shared.user?.name ?? ""), \(TimeInterval(file.updateTime)?.toLocalFormat("yyyy-MM-dd HH:mm:ss") ?? "")".heightWithFont(font: .content, fixedWidth: fixedWidth)

                var height: CGFloat = 20 + titleHeight + 6 + infoHeight + 20
                if height <= 100 {
                    height = 100
                }
                size = CGSize(width: width, height: height)
            }
        }

        previewParameters.visiblePath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        return previewParameters
    }
}

extension MaterialsV3ViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: any UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else {
            logger.debug("无法获取perform drop with 的 destinationIndexPath")
            return
        }

        guard let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath else {
            logger.debug("无法获取perform drop with 的 sourceIndexPath")
            return
        }

        // 移动到的目标位置的文件
        let destFile = getMaterialItem(withCollectionView: collectionView, atIndexPath: destinationIndexPath)

        // 移动的文件
        let sourceFile = getMaterialItem(withCollectionView: collectionView, atIndexPath: sourceIndexPath)

        switch coordinator.proposal.operation {
        case .copy:
            logger.debug("合并到新文件夹内： 源文件：\(sourceFile.name) -> 目标文件：\(destFile.name)")
            mergeAndCreateNewFolder(items: [destFile, sourceFile])
        case .move:
            logger.debug("移动到文件夹: 源文件：\(sourceFile.name) -> 目标文件：\(destFile.name)")
            guard destFile.type == .folder else { return }
            moveToFolder(items: [sourceFile], folder: destFile)
        default: break
        }
    }

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        logger.debug("完全释放拖拽")
        let collectionView = collectionView as! MaterialsCollectionView

        for cell in collectionView.visibleCells {
            if let cell = cell as? MaterialV3GridCollectionViewCell {
                cell.borderWidth = 0
            } else if let cell = cell as? MaterialV3ListCollectionViewCell {
                cell.borderWidth = 0
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: any UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let destinationIndexPath, let item = session.items.first {
            if let id = item.localObject as? String {
                guard let sourceFile = allData[id], sourceFile.isOwnMaterials else {
                    // 原文件不是自己的文件
                    return UICollectionViewDropProposal(operation: .cancel)
                }

                let destFile = getMaterialItem(withCollectionView: collectionView, atIndexPath: destinationIndexPath)
                for cell in collectionView.visibleCells {
                    if let cell = cell as? MaterialV3GridCollectionViewCell {
                        if cell.id != destFile.id {
                            cell.borderWidth = 0
                        } else {
                            cell.borderWidth = 1
                            cell.borderColor = .clickable
                        }
                    } else if let cell = cell as? MaterialV3ListCollectionViewCell {
                        if cell.id != destFile.id {
                            cell.borderWidth = 0
                        } else {
                            cell.borderWidth = 1
                            cell.borderColor = .clickable
                        }
                    }
                }

                if destFile.type == .folder {
                    // 目标是文件夹
                    guard destFile.isOwnMaterials else {
                        return UICollectionViewDropProposal(operation: .forbidden)
                    }

                    return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
                } else {
                    // 目标是文件
                    if sourceFile.type == .folder {
                        // 原文件是文件夹，返回cancel
                        return UICollectionViewDropProposal(operation: .cancel)
                    } else {
                        return UICollectionViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
                    }
                }
            }
        }

        return UICollectionViewDropProposal(operation: .cancel)
    }
}

extension MaterialsV3ViewController {
    private func getMaterialItem(withCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) -> TKMaterial {
        let collectionView = collectionView as! MaterialsCollectionView
        let folderId = collectionView.materialsId
        let files = getData(folderId: folderId, atSection: indexPath.section)
        let item = files[indexPath.item]
        logger.debug("获取Item: \(item.toJSONString() ?? "")")
        return item
    }
}

extension MaterialsV3ViewController {
    private func getCurrentColletionView() -> MaterialsCollectionView? {
        collectionViews.last
    }

    private func getCurrentFolderId() -> String? {
        collectionViews.last?.materialsId
    }
}

extension MaterialsV3ViewController {
    override func bindEvent() {
        super.bindEvent()
        filterButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            guard let folderId = self.getCurrentFolderId() else { return }
            let controller = MaterialsV3FilterViewController(folderId)
            controller.enableHero()
            Tools.getTopViewController()?.present(controller, animated: true)
        }

        addButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.onAddButtonTapped()
        }

        $isEditable.addSubscriber { [weak self] isEditable in
            guard let self = self else { return }
            for collectionView in self.collectionViews {
                let cells = collectionView.visibleCells
                for cell in cells {
                    if let cell = cell as? MaterialV3ListCollectionViewCell {
                        cell.isEditable = isEditable
                    } else if let cell = cell as? MaterialV3GridCollectionViewCell {
                        cell.isEditable = isEditable
                    }
                }
            }
            if isEditable {
                UIView.animate(withDuration: 0.2) {
                    self.editableBottomButtonsView.transform = .identity
                    self.editableBottomButtonsView.layer.opacity = 1
                    self.tabBarController?.tabBar.layer.opacity = 0
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.editableBottomButtonsView.transform = CGAffineTransform(translationX: 0, y: 10 + 50 + UiUtil.safeAreaBottom())
                    self.editableBottomButtonsView.layer.opacity = 0
                    self.tabBarController?.tabBar.layer.opacity = 1
                }
            }
        }

        selectButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.isEditable.toggle()
        }

        $selectedFiles.addSubscriber { [weak self] selectedFiles in
            guard let self = self else { return }
            guard self.isEditable else { return }
            if selectedFiles.isEmpty {
            } else {
            }
        }

        $style.addSubscriber { [weak self] style in
            guard let self = self else { return }
            guard let currentRole = ListenerService.shared.currentRole else { return }
            if (style == .main || style == .share) && (currentRole == .teacher || currentRole == .studioManager) {
                self.selectButton.isHidden = false
                self.addButton.isHidden = false
            } else {
                self.selectButton.isHidden = true
                self.addButton.isHidden = true
            }
        }
    }

    private func loadMaterials(folderId: String) {
        logger.debug("加载文件数据: \(folderId)")
        guard let currentRole = ListenerService.shared.currentRole else { return }
        if currentRole == .teacher || currentRole == .studioManager {
            if style == .main || style == .share {
                guard let userId = UserService.user.id(), let currentRole = ListenerService.shared.currentRole else {
                    logger.debug("当前用户未登录")
                    return
                }
                navigationBar.startLoading()
                if currentRole == .teacher || currentRole == .studioManager {
                    DatabaseService.collections.material()
                        .whereField("creatorId", isEqualTo: userId)
                        .whereField("folder", isEqualTo: folderId)
                        .getDocumentsData(TKMaterial.self, source: .server)
                        .done { [weak self] materials in
                            guard let self = self else { return }
                            logger.debug("当前文件夹[\(folderId.isEmpty ? "Home" : folderId)]的文件数量： \(materials.count)")
                            self.setupGroupedFiles(materials, folderId: folderId)
                            for material in materials {
                                self.allData[material.id] = material
                            }
                            self.navigationBar.stopLoading()
                            self.reloadFolderData(folderId: folderId)
                        }
                        .catch { error in
                            logger.error("加载Materials失败: \(error)")
                        }
                } else {
                    let studentId: String
                    if currentRole == .parent {
                        guard let _studentId = ParentService.shared.currentStudent?.studentId else { return }
                        studentId = _studentId
                    } else {
                        studentId = userId
                    }
                    when(fulfilled: [
                        DatabaseService.collections.material()
                            .whereField("creatorId", isEqualTo: studentId)
                            .whereField("folder", isEqualTo: folderId)
                            .getDocumentsData(TKMaterial.self, source: .server),
                        DatabaseService.collections.material()
                            .whereField("studentIds", arrayContains: studentId)
                            .whereField("folder", isEqualTo: folderId)
                            .getDocumentsData(TKMaterial.self, source: .server),
                    ])
                    .done { [weak self] result in
                        guard let self = self else { return }
                        var materials: [TKMaterial] = []
                        for list in result {
                            materials += list
                        }
                        logger.debug("当前文件夹[\(folderId.isEmpty ? "Home" : folderId)]的文件数量： \(materials.count)")
                        self.setupGroupedFiles(materials, folderId: folderId)
                        for material in materials {
                            self.allData[material.id] = material
                        }
                        self.navigationBar.stopLoading()
                        self.reloadFolderData(folderId: folderId)
                    }
                    .catch { error in
                        logger.error("加载Materials失败: \(error)")
                    }
                }
            } else {
                reloadFolderData(folderId: folderId)
            }
        } else if currentRole == .student || currentRole == .parent {
            logger.debug("加载学生或家长的静态文件数据： \(folderId)")
            let files = allData.values.filter({ $0.folder == folderId })
            setupGroupedFiles(files, folderId: folderId)
            reloadFolderData(folderId: folderId)
        }
    }

    private func setupGroupedFiles(_ materials: [TKMaterial], folderId: String) {
        reloadFilter(folderId)
        guard let filter = filters[folderId] else { return }
        if filter.isGroupingByEnabled {
            switch filter.groupingBy {
            case .day, .week, .month:
                var groupedFiles: [GroupedFiles] = []
                let groupedByDay = Dictionary(grouping: materials) { item in
                    let updateTime = TimeInterval(item.updateTime) ?? 0
                    var unit: Calendar.Component = .day
                    if filter.groupingBy == .week {
                        unit = .weekOfYear
                    }
                    if filter.groupingBy == .month {
                        unit = .month
                    }
                    return DateInRegion(seconds: updateTime, region: .localRegion).dateAtStartOf(unit)
                }
                for (date, materialsInDay) in groupedByDay.sorted(by: { $0.key.timeIntervalSince1970 < $1.key.timeIntervalSince1970 }) {
                    let filesCount = "\(materialsInDay.count) file\(materialsInDay.count > 1 ? "s" : "")"
                    let title = if filter.groupingBy == .day {
                        "\(date.toLocalFormat("MMM dd, yyyy")) \(filesCount)"
                    } else if filter.groupingBy == .week {
                        "\(date.toLocalFormat("MM/dd/yyyy"))-\(date.dateByAdding(7, .weekday).dateByAdding(-1, .second).toLocalFormat("MM/dd/yyyy")) \(filesCount)"
                    } else {
                        "\(date.toLocalFormat("MMM, yyyy")) \(filesCount)"
                    }
                    groupedFiles.append(
                        GroupedFiles(
                            title: Tools.attributenStringColor(text: title, selectedText: filesCount, allColor: .primary, selectedColor: .tertiary, font: .cardTitle, selectedFont: .tinyContent, fontSize: UIFont.cardTitle.pointSize, selectedFontSize: UIFont.tinyContent.pointSize, ignoreCase: true, charasetSpace: 0),
                            weight: date.timeIntervalSince1970,
                            files: materialsInDay
                        )
                    )
                }
                data[folderId] = groupedFiles
            case .fileType:
                var groupedFiles: [GroupedFiles] = []
                let groupedByFileType = Dictionary(grouping: materials) { item in
                    item.type
                }
                for (fileType, materialsInType) in groupedByFileType {
                    let filesCount = "\(materialsInType.count) file\(materialsInType.count > 1 ? "s" : "")"
                    let title: String = "\(fileType.title) \(filesCount)"
                    groupedFiles.append(
                        GroupedFiles(
                            title: Tools.attributenStringColor(text: title, selectedText: filesCount, allColor: .primary, selectedColor: .tertiary, font: .cardTitle, selectedFont: .tinyContent, fontSize: UIFont.cardTitle.pointSize, selectedFontSize: UIFont.tinyContent.pointSize, ignoreCase: true, charasetSpace: 0),
                            weight: Double(fileType.rawValue),
                            files: materialsInType
                        )
                    )
                }
                data[folderId] = groupedFiles
            }
        } else {
            data[folderId] = [GroupedFiles(title: .init(string: ""), weight: 0, files: materials)]
        }
    }

    private func loadMetadatas(files: [TKMaterial]) {
        Task { [weak self] in
            guard let self = self else { return }
            await withTaskGroup(of: Void.self) { _ in
                do {
                    for file in files {
                        let metadata = try await self.loadMetadata(file: file)
                        logger.debug("[元数据获取] => \(file.id) -> \(String(describing: metadata))")
                        await self.fileMetadata.append(id: file.id, metadata: metadata)
                    }
                } catch {
                    logger.error("加载元数据失败: \(error)")
                }
            }
        }
    }

    private func loadMetadata(file: TKMaterial) async throws -> StorageMetadata? {
        guard file.storagePatch.isNotEmpty else {
            return nil
        }
        let ref = Storage.storage().reference(withPath: file.storagePatch)
        do {
            let metadata = try await ref.getMetadata()
            return metadata
        } catch {
            throw error
        }
    }

    private func reloadData() {
        for collectionView in collectionViews {
            let folderId = collectionView.materialsId
            reloadFilter(folderId)
            reloadFolderData(folderId: folderId)
        }
    }

    private func reloadFolderData(folderId: String) {
        guard let collectionView = collectionViews.first(where: { $0.materialsId == folderId }) else { return }
        reloadFilter(folderId)
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let filter = filters[folderId]
            let viewType = filter?.view ?? .grid
            switch viewType {
            case .grid:
                let width: CGFloat = (UIScreen.main.bounds.width - 40 - 10) / 3
                layout.itemSize = CGSize(width: width, height: 180)
                layout.minimumLineSpacing = 10
                layout.minimumInteritemSpacing = 5
                collectionView.contentInset = .init(top: 0, left: 20, bottom: UiUtil.safeAreaBottom() + 80, right: 20)
            case .list:
                let width: CGFloat = UIScreen.main.bounds.width
                layout.itemSize = CGSize(width: width, height: 100)
                layout.minimumLineSpacing = 0
                layout.minimumInteritemSpacing = 0
                collectionView.contentInset = .init(top: 0, left: 0, bottom: UiUtil.safeAreaBottom() + 80, right: 0)
            }
        }
        collectionView.reloadData()
    }
}

extension MaterialsV3ViewController {
    private func initListeners() {
        $collectionViews.addSubscriber { [weak self] collectionViews in
            guard let self = self else { return }
            guard let currentCollectionView = collectionViews.last else { return }
            let folderId = currentCollectionView.materialsId
            var navigationBarTitle: String = "Materials"
            if folderId.isNotEmpty {
                // 当前是在某个子文件夹下，获取这个view的上一个view
                if let file = self.allData[folderId] {
                    navigationBarTitle = file.name
                }
            }
            self.navigationBar.title = navigationBarTitle
        }

        EventBus.listen(key: .materialsFilterChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            guard let currentFolderId = self.getCurrentFolderId() else { return }
            self.reloadFilter(currentFolderId)
            self.loadMaterials(folderId: currentFolderId)
        }
    }
}

extension MaterialsV3ViewController {
}

extension MaterialsV3ViewController {
    private func onAddButtonTapped() {
        guard checkIfCanAddMaterial() else { return }
        switch style {
        case .main:
            guard let role = ListenerService.shared.currentRole else { return }
            if role == .teacher || role == .studioManager {
                showAddPopSheetForTeacher()
            } else if role == .student {
            } else if role == .parent {
            }
        case .list:
            break
        case .share:
            break
        }
    }

    private func checkIfCanAddMaterial() -> Bool {
        true
    }

    private func showAddPopSheetForTeacher() {
        guard let teacherInfo = ListenerService.shared.studioManagerData.teacherInfo else { return }
        if teacherInfo.memberLevelId == 1, ListenerService.shared.studioManagerData.homeMaterials.count >= FreeResources.maxMaterialsCount {
            SL.Alert.show(target: self, title: "Upgrade pro", message: "You\'ve reached your limit of \(FreeResources.maxMaterialsCount) materials.\nTry PRO to unlock the full power of TuneKey.", leftButttonString: "Go back", rightButtonString: "Upgrade", leftButtonColor: .tertiary, rightButtonColor: .clickable) {
            } rightButtonAction: {
                ProfileUpgradeDetailViewController.show(level: .normal, target: self, isCouponUser: false, couponName: "")
            }

            return
        }
        PopSheet()
            .items([
                .init(title: "New Folder", action: { [weak self] in
                    guard let self = self else { return }
                    self.onNewFolderTapped()
                }),
            ])
            .items([
                .init(title: "Gallery", action: { [weak self] in
                    guard let self = self else { return }
                    self.showPhotoLibrary()
                }),
                .init(title: "Camera", action: { [weak self] in
                    guard let self = self else { return }
                    self.showCamera()
                }),
                .init(title: "Audio recording", action: { [weak self] in
                    guard let self = self else { return }
                    self.showAudioRecording()
                }),
            ])
            .items([
                .init(title: "Shared link", action: { [weak self] in
                    guard let self = self else { return }
                    self.onSharedLinkTapped()
                }),
                .init(title: "Upload from computer", action: { [weak self] in
                    guard let self = self else { return }
                    self.onUploadFromComputerTapped()
                }),
                .init(title: "Google Drive", action: { [weak self] in
                    guard let self = self else { return }
                    self.onGoogleDriveTapped()
                }),
                .init(title: "Google Photo", action: { [weak self] in
                    guard let self = self else { return }
                    self.onGooglePhotoTapped()
                }),
            ])
            .show()
    }

    private func onNewFolderTapped() {
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
            self.submitNewFolder(withName: name.trimmingCharacters(in: .whitespacesAndNewlines))
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

    private func submitNewFolder(withName name: String) {
        guard let userId = UserService.user.id() else { return }
        guard let parentId = getCurrentFolderId() else { return }
        let now = Date().timestamp
        let folder = TKMaterial()
        folder.id = IDUtil.nextId()?.description ?? "\(now)"
        folder.creatorId = userId
        folder.type = .folder
        folder.name = name
        folder.desc = ""
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
                    self.loadMaterials(folderId: parentId)
                }
            }
    }
}

extension MaterialsV3ViewController: GalleryControllerDelegate {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        controller.dismiss(animated: true, completion: nil)
        guard let currentFolderId = getCurrentFolderId() else { return }
        let currentFolder = allData[currentFolderId]
        logger.debug("选择了照片: \(images.count)")
        guard images.count > 0 else { return }
        let imageAsset = images[0].asset
        showFullScreenLoadingNoAutoHide()
        let timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.updateFullScreenLoadingMsg(msg: "Fetching image from iCloud")
        }
        images[0].resolve { [weak self] image in
            guard let self = self else { return }
            guard let image = image else { return }
            DispatchQueue.main.async {
                timer.invalidate()
                self.hideFullScreenLoading()
                imageAsset.getURL { url in
                    if let url = url {
                        TKPopAction.showAddMaterials(target: self, type: .image, image: image, imageUrl: url, folder: currentFolder) {
                            EventBus.send(key: .refreshMaterials)
                            self.loadMaterials(folderId: currentFolderId)
                        }
                    }
                }
            }
        } onProgress: { [weak self] progress in
            guard let self = self else { return }
            self.updateFullScreenLoadingMsg(msg: "Fetching image from iCloud, \(Int(progress * 100))%")
        }
    }

    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        controller.dismiss(animated: true, completion: nil)
        guard let currentFolderId = getCurrentFolderId() else { return }
        let currentFolder = allData[currentFolderId]
        showFullScreenLoadingNoAutoHide()
        video.asset.getURL { [weak self] url in
            guard let self = self, let url = url, let hashCode = FileUtil.shared.getHashCode(url: url) else { return }
            DispatchQueue.main.async {
                self.hideFullScreenLoading()
                DispatchQueue.main.async {
                    logger.debug("获取到的HashCode: \(hashCode)")
                    TKPopAction.showAddMaterials(target: self, type: .video, vidioUrl: url, folder: currentFolder) {
                        logger.debug("======上传成功")
                        EventBus.send(key: .refreshMaterials)
                        self.loadMaterials(folderId: currentFolderId)
                    }
                }
            }
        }
    }

    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        controller.dismiss(animated: true, completion: nil)
    }

    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func showPhotoLibrary() {
        let gallery = GalleryController()
        Config.tabsToShow = [.imageTab, .videoTab]
        Config.Camera.imageLimit = 1
        gallery.delegate = self
        present(gallery, animated: true, completion: nil)
    }
}

extension MaterialsV3ViewController {
    private func showCamera() {
        TKPopAction.show(items: [
            .init(title: "Photo", action: { [weak self] in
                guard let self = self else { return }
                let gallery = GalleryController()
                Config.tabsToShow = [.cameraTab]
                Config.Camera.imageLimit = 1
                gallery.delegate = self
                self.present(gallery, animated: true, completion: nil)
            }),
            .init(title: "Video", action: { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    guard let currentFolderId = self.getCurrentFolderId(), let currentFolder = self.allData[currentFolderId] else { return }
                    let controller = VideoRecorderViewController()
                    controller.onRecordCompletion = { data in
                        TKPopAction.showAddMaterials(target: self, type: .video, vidioUrl: data.compressedURL, fileId: data.id, folder: currentFolder) {
                            logger.debug("======上传成功")
                            EventBus.send(key: .refreshMaterials)
                            self.loadMaterials(folderId: currentFolderId)
                        }
                    }
                    self.present(controller, animated: true, completion: nil)
                }
            }),
        ], target: self)
    }

    private func showAudioRecording() {
        TeacherAudioControllerEx.toRecording(fatherController: self) { [weak self] title, path, _, id, _ in
            guard let self = self else { return }
            UIApplication.shared.isIdleTimerDisabled = false
            self.view.endEditing(true)
            var title = title
            if title == "" {
                title = "Audio"
            }
            self.uploadAudio(title: title, path: path, id: id)
        }
    }

    private func uploadAudio(title: String, path: String, id: String) {
        do {
            let fileData = try Data(contentsOf: URL(fileURLWithPath: path))
            let path = "/materials/\(UserService.user.id()!)/\(id)\(path.getFileExtension)"
            logger.debug("上传路径: \(path)")
            guard let hash = FileUtil.shared.getHashCode(data: fileData) else {
                TKToast.show(msg: "Failed, please try again.", style: .error)
                return
            }
            guard let currentFolderId = getCurrentFolderId() else { return }
            let currentFolder = allData[currentFolderId]
            showFullScreenLoadingNoAutoHide()
            MaterialService.shared.checkFileHash(hash: hash)
                .done { [weak self] hashData in
                    guard let self = self else { return }
                    var _hashData: TKMaterialHash
                    var upload: Bool = false
                    if hashData == nil {
                        _hashData = TKMaterialHash()
                        _hashData.hash = hash
                        upload = true
                    } else {
                        _hashData = hashData!
                    }

                    if upload {
                        StorageService.shared.uploadFileReturnDownloadUrl(with: fileData, to: path, onProgress: { [weak self] progress, _ in
                            guard let self = self else { return }
//                            self.updateUploadProgressV2(progress: progress)
                            self.updateFullScreenLoadingMsg(msg: "Uploading, \(Int(progress * 100))%")
                            print("上传音频: progress:\(progress)")
                        }) { [weak self] url in
                            guard let self = self else { return }
                            if url != nil {
                                let data = MaterialService.shared.TKMaterialBean(id: id, url: "\(url!.absoluteString)", storagePatch: path, suffixName: path.getFileExtension, fileName: title, type: .mp3, openType: .block)
                                CacheUtil.materials.addAudioCount()
                                _hashData.url = url!.absoluteString
                                _hashData.path = path
                                _hashData.type = .mp3
                                MaterialService.shared.addMaterials(materialData: data!, hashData: _hashData, currentFolder: currentFolder)
                                    .done { _ in
                                        self.hideFullScreenLoading()
                                        TKToast.show(msg: "Successfully.", style: .success)
                                        self.loadMaterials(folderId: currentFolderId)
                                    }
                                    .catch { error in
                                        self.hideFullScreenLoading()
                                        logger.error("失败: \(error)")
                                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                                    }
                            } else {
                                self.hideFullScreenLoading()
//                                self.endUploadV2(isSuccess: false, showFailedToast: false)
                                TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                            }
                        }
                    } else {
                        self.updateFullScreenLoadingMsg(msg: "Uploading, 90%")
                        let data = MaterialService.shared.TKMaterialBean(id: id, url: _hashData.url, storagePatch: _hashData.path, suffixName: path.getFileExtension, fileName: title, type: .mp3, openType: .block)
                        CacheUtil.materials.addAudioCount()
                        MaterialService.shared.addMaterials(materialData: data!, hashData: _hashData, currentFolder: currentFolder)
                            .done { _ in
                                self.hideFullScreenLoading()
                                TKToast.show(msg: "Successfully.", style: .success)
                                self.loadMaterials(folderId: currentFolderId)
                            }
                            .catch { error in
                                self.hideFullScreenLoading()
                                logger.error("失败: \(error)")
                                TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                            }
                    }
                }
                .catch { [weak self] _ in
                    self?.hideFullScreenLoading()
//                    self.endUploadV2(isSuccess: false, showFailedToast: false)
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                }
        } catch {
            print("走到了catch")
            hideFullScreenLoading()
            TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
        }
    }
}

extension MaterialsV3ViewController {
    private func onSharedLinkTapped() {
        guard let currentFolderId = getCurrentFolderId() else { return }
        let currentFolder = allData[currentFolderId]
        TKPopAction.showAddMaterials(target: self, type: .link, folder: currentFolder, confirmAction: { [weak self] in
            guard let self = self else { return }
            EventBus.send(key: .refreshMaterials)
            self.loadMaterials(folderId: currentFolderId)
        })
    }
}

extension MaterialsV3ViewController {
    private func onUploadFromComputerTapped() {
        showFullScreenLoading()
        guard let userId = UserService.user.id() else {
            hideFullScreenLoading()
            TKToast.show(msg: TipMsg.connectionFailed, style: .error)
            logger.error("创建短连接 => 获取用户id失败")
            return
        }
        CommonsService.shared.shotLink("https://tunekey.app/d/upload/\(userId)")
            .done { [weak self] url in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                let urlstring = url.absoluteString
                let controller = InviteLinkAlert()
                controller.modalPresentationStyle = .custom
                controller.isClickBackgroundHiden = false

                controller.titleString = "Upload from computer"
//                controller.infoString = "Send your files to \nupload@tunekey.app\n or \n upload your files via the link."
                controller.infoString = "Upload your files via the link"
                controller.messageString = urlstring
                controller.leftButtonString = "GO BACK"
                controller.centerButtonString = "EMAIL THIS LINK TO ME"
                controller.rightButtonString = "COPY TO CLIPBOARD"
                controller.centerButtonAction = {
                    CommonsService.shared.fetchEmailAttachment()
                }
                controller.leftButtonAction = {
                    CommonsService.shared.fetchEmailAttachment()
                }
                controller.centerButtonAction = {
                    CommonsService.shared.fetchEmailAttachment()
                    CommonsService.shared.sendUploadEmailToUser(url: urlstring)
                    TKToast.show(msg: "Email send Successful!")
                }
                controller.rightButtonAction = {
                    CommonsService.shared.fetchEmailAttachment()
                    TKToast.show(msg: "Copy Successful!")
                    UIPasteboard.general.string = urlstring
                }

//                let controller = MaterialsUploadFromComputerViewController(link: urlstring)
//                controller.modalPresentationStyle = .custom
                self.present(controller, animated: false, completion: {
                    controller.messageLabel?.onViewTapped { _ in
                        // 根据iOS系统版本，分别处理
                        if #available(iOS 10, *) {
                            UIApplication.shared.open(url, options: [:],
                                                      completionHandler: {
                                                          _ in
                                                      })
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }
                })
            }
            .catch { [weak self] _ in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                TKToast.show(msg: TipMsg.failed, style: .error)
            }
    }
}

extension MaterialsV3ViewController {
    private func onGooglePhotoTapped() {
        let refIds: [String] = allData.filter { ele in
            ele.value.refId.isNotEmpty
        }.compactMap({ $0.value.id })

        let controller = MaterialsGooglePhotoViewController(excludeFiles: refIds)
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }

    private func onGoogleDriveTapped() {
        let refIds: [String] = allData.filter { ele in
            ele.value.refId.isNotEmpty
        }.compactMap({ $0.value.id })
        let controller = MaterialsGoogleDriveViewController(excludeFiles: refIds)
        controller.delegate = self
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }
}

extension MaterialsV3ViewController: MaterialsGoogleDriveViewControllerDelegate {
    func materialsGoogleDriveViewController(predownloadFilesDone files: [GoogleDriveMaterialPredownloadModel]) {
        logger.debug("准备上传的所有文件: \(files.compactMap { $0.file }.toJSONString() ?? "")")
        guard let folderId: String = getCurrentFolderId() else { return }
        let materialDatas = files.compactMap({ $0.file })
        materialDatas.forEach({ $0.folder = folderId })
        showFullScreenLoadingNoAutoHide()
        MaterialService.shared.saveMaterials(materialDatas)
            .done { [weak self] _ in
                guard let self = self else { return }
                self.hideFullScreenLoading()
            }
            .catch { [weak self] _ in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                TKToast.show(msg: "Upload materials failed, please try again later.", style: .error)
            }
    }

    func materialsGoogleDriveViewController(uploadFiles: [GoogleDriveFile]) {
        guard uploadFiles.count > 0 else { return }
//        showFullScreenLoadingNoAutoHide()
        logger.debug("要上传的文件: \(uploadFiles.toJSONString() ?? "")")
        // 先将文件整理成TKMaterial
        let uid = UserService.user.id() ?? ""
        let now = Date()
        var files: [TKMaterial] = []
        uploadFiles.forEach { file in
            let material = TKMaterial()
            material.id = file.id
            material.name = file.name
            material.folder = ""
            material.creatorId = uid
            material.createTime = "\(now.timestamp)"
            material.updateTime = "\(now.timestamp)"
            material.suffixName = file.fullFileExtension
            material.type = file.getTKMaterialFileType()
            var url: String = ""
            if file.webContentLink == "" {
                if file.webViewLink != "" {
                    url = file.webViewLink
                } else {
                    if file.hasThumbnail {
                        url = file.thumbnailLink
                    }
                }
            } else {
                url = file.webContentLink
            }
            material.url = url
            material.minPictureUrl = file.hasThumbnail ? file.thumbnailLink : file.iconLink
            material.fromType = .drive
            if material.type == .image || material.type == .video {
                material.status = .processing
            }
            files.append(material)
        }

        logger.debug("最终的文件: \(files.toJSONString() ?? "")")
        logger.debug("[Google Drive] => 开始尝试下载文件")
        downloadFilesFromGoogleDrive(files: files)
//        uploadFilesFromGoogle(files: files)
    }

    private func downloadFilesFromGoogleDrive(files: [TKMaterial]) {
        // 1. 下载到temp文件夹
        // 2. 下载成功之后,上传
        // 3. 删除temp文件夹内的文件

        let path: String = "\(NSHomeDirectory())/Documents/temp/googledrive"
        logger.debug("[Google Drive] => 开始准备文件夹,地址: \(path)")
        let fileManager = FileManager.default
        if !fileManager.directoryExists(atPath: path) {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                logger.debug("[Google Drive] => 当前文件夹不存在,创建成功")
            } catch {
                TKToast.show(msg: "Create temp file failed, please try again.", style: .error)
                return
            }
        }

        logger.debug("[Google Drive] => 开始准备下载文件")
        showFullScreenLoadingNoAutoHide()
        let totalTasksCount: Int = files.count
        let progressCallback: (Int, Double) -> Void = { [weak self] index, progress in
            guard let self = self else { return }
            self.updateFullScreenLoadingMsg(msg: "\(Int(progress * 100))%, \(index + 1)/\(totalTasksCount)")
        }
        var downloadTasks: [Promise<URL?>] = []
        for item in files.enumerated() {
            downloadTasks.append(downloadFileFromGoogleDrive(file: item.element, index: item.offset, downloadProgress: progressCallback))
        }

        when(fulfilled: downloadTasks)
            .done { [weak self] urls in
                guard let self = self else { return }
                logger.debug("[Google Drive] => 下载完成,最后的结果: \(urls.compactMap { $0 })")
                self.hideFullScreenLoading()
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                logger.error("[Google Drive] => 下载失败: \(error)")
                self.hideFullScreenLoading()
            }
    }

    private func downloadFileFromGoogleDrive(file: TKMaterial, index: Int, downloadProgress: @escaping (Int, Double) -> Void) -> Promise<URL?> {
        return Promise { resolver in
            let destination: DownloadRequest.Destination = { _, _ in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsURL.appendingPathComponent("temp").appendingPathComponent("googledrive").appendingPathComponent("\(file.id).jpg")
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
            AF.download(file.url, to: destination)
                .downloadProgress { progress in
                    logger.debug("[Google Drive] => 下载进度: \(progress.completedUnitCount) / \(progress.totalUnitCount) | \(progress.fractionCompleted)")
                    downloadProgress(index, progress.fractionCompleted)
                }
                .responseData { response in
                    logger.debug("[Google Drive] => 下载完成")
                    if let error = response.error {
                        resolver.reject(error)
                    } else {
                        logger.debug("[Google Drvie] => 下载之后的文件链接: \(response.fileURL?.absoluteString ?? "")")
                        resolver.fulfill(response.fileURL)
                    }
                }
        }
    }
}

extension MaterialsV3ViewController: MaterialsGooglePhotoViewControllerDelegate {
    func materialsGooglePhotoViewController(uploadFiles: [GooglePhotoMediaItem]) {
        guard uploadFiles.count > 0 else { return }
        //        showFullScreenLoadingNoAutoHide()
        logger.debug("要上传的文件: \(uploadFiles.toJSONString() ?? "")")
        let uid = UserService.user.id() ?? ""
        let now = Date()
        var files: [TKMaterial] = []
        guard let folderId: String = getCurrentFolderId() else { return }
        uploadFiles.forEach { file in
            let material = TKMaterial()
            material.id = IDUtil.nextId(group: .material)?.description ?? ""
            material.refId = file.id
            material.name = file.filename
            material.folder = folderId
            material.creatorId = uid
            material.createTime = "\(now.timestamp)"
            material.updateTime = "\(now.timestamp)"
            material.type = file.getMaterialType()
            material.url = file.baseUrl
            material.minPictureUrl = file.baseUrl
            material.status = .processing
            material.fromType = .photos
            files.append(material)
        }
        showFullScreenLoadingNoAutoHide()
        MaterialService.shared.saveMaterials(files)
            .done { [weak self] _ in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                self.loadMaterials(folderId: folderId)
            }
            .catch { [weak self] _ in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                TKToast.show(msg: "Upload materials failed, please try again later.", style: .error)
            }
    }
}

extension MaterialsV3ViewController {
    private func uploadFilesFromGoogle(files: [TKMaterial]) {
        // 唤起选择文件夹
        let controller = MaterialMoveToFolderSelectorViewController(uploadItems: files)
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }
}

extension MaterialsV3ViewController {
    private func resetEditableAndSelectedFiles() {
        isEditable = false
        selectedFiles.removeAll()
    }
}

extension MaterialsV3ViewController {
    private func onMoveButtonTapped() {
        let selectedFileIds = self.selectedFiles
        resetEditableAndSelectedFiles()
        var selectedFiles: [TKMaterial] = allData.filter { ele in
            selectedFileIds.contains(ele.key)
        }.compactMap({ $0.value })

        let selectedFolders = selectedFiles.filter({ $0.type == .folder }).compactMap({ $0.id })
        selectedFiles.removeElements { file in
            selectedFolders.contains(file.folder)
        }

        showMoveToController(selectedFiles)
    }

    private func showMoveToController(_ selectedItems: [TKMaterial]) {
        // 文件夹选择
        guard let currentFolderId: String = getCurrentFolderId() else { return }
        logger.debug("准备移动的项目: \(selectedItems.toJSONString() ?? "")")
        let controller = MaterialsFolderSelectorViewController(Array(allData.values))
        // 排除当前文件夹以及选择的项目里面的所有文件夹
        controller.excepteFolder = [currentFolderId] + selectedItems.filter({ $0.type == .folder }).compactMap({ $0.id })
        controller.modalPresentationStyle = .custom
        Tools.getTopViewController()?.present(controller, animated: false)
        controller.confirmButtonTitle = "Move to here"
        controller.onFolderSelected = { [weak self] folder in
            guard let self = self else { return }
            logger.debug("即将开始移动项目: \(selectedItems.toJSONString() ?? "")")
            self.moveToFolder(items: selectedItems, folder: folder)
        }
    }

    private func moveToFolder(items: [TKMaterial], folder: TKMaterial?) {
        let folderId = folder?.id ?? ""
        let originalFolders: [String] = items.compactMap({ $0.folder }).filterDuplicates({ $0 })
        logger.debug("当前准备移动文件到文件夹: \(folderId) | 源文件数据： \(items.compactMap({ "\($0.id) | \($0.folder)" }))")
        showFullScreenLoadingNoAutoHide()
        MaterialService.shared.moveToFolderV2(items: items, moveTo: folder) { [weak self] error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let error = error {
                logger.error("Move failed: \(error)")
            } else {
                self.loadMaterials(folderId: folderId)
                for originalFolder in originalFolders {
                    self.loadMaterials(folderId: originalFolder)
                }
            }
        }
    }

    private func mergeAndCreateNewFolder(items: [TKMaterial]) {
        guard let userId = UserService.user.id() else { return }
        guard let id = IDUtil.nextId(group: .material) else { return }
        showFullScreenLoadingNoAutoHide()
        let originalFolderId = items.first?.folder ?? ""
        // 获取当前的Untitled Folder
        let name: String = "Untitled Folder"
        guard let folderId: String = getCurrentFolderId() else { return }

        Firestore.firestore().runTransaction { transaction, _ -> TKMaterial in
            let data = TKMaterial()
            data.id = "\(id)"
            data.creatorId = userId
            data.type = .folder
            data.name = name
            data.folder = folderId
            let time = "\(Date().timestamp)"
            data.createTime = time
            data.updateTime = time

            transaction.setData(data.toJSON() ?? [:], forDocument: DatabaseService.collections.material().document(data.id))

            items.forEach { item in
                item.folder = data.id
                transaction.updateData(["folder": data.id], forDocument: DatabaseService.collections.material().document(item.id))
            }

            return data
        } completion: { [weak self] folder, error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let error = error {
                logger.error("Merge and create new folder failed: \(error)")
                TKToast.show(msg: TipMsg.failed, style: .error)
            } else {
                // 更改文件夹名称
                if let folder = folder as? TKMaterial {
                    self.loadMaterials(folderId: folderId)
                    DispatchQueue.main.async {
                        let controller = UpdateMaterialsTitleViewController()
                        controller.id = folder.id
                        controller.defaultTitle = folder.name
                        controller.delegate = self
                        controller.modalPresentationStyle = .custom
                        self.present(controller, animated: false, completion: nil)
                        controller.onCancelTapped = {
                            // 删除文件夹，并且移动文件到某个文件夹
                            self.removeFolder(id: folder.id, moveItems: items, toNewFolder: originalFolderId)
                        }
                    }
                }
            }
        }
    }

    /// 删除文件夹并且将选中的文件移动到目标文件夹
    /// - Parameters:
    ///   - id: 要删除的文件夹 id
    ///   - items: 选中的文件
    ///   - folderId: 目标文件夹 id
    private func removeFolder(id: String, moveItems items: [TKMaterial], toNewFolder folderId: String) {
        showFullScreenLoadingNoAutoHide()
        Firestore.firestore().runTransaction { transaction, _ in
            for item in items {
                transaction.updateData(["folder": folderId], forDocument: DatabaseService.collections.material().document(item.id))
            }
            transaction.deleteDocument(DatabaseService.collections.material().document(id))
            return nil
        } completion: { [weak self] _, error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let error {
                logger.error("删除文件夹失败：\(error)")
                TKToast.show(msg: "Update failed, please try again later.", style: .error)
                guard let currentFolderId = self.getCurrentFolderId() else { return }
                self.loadMaterials(folderId: currentFolderId)
            }
        }
    }
}

extension MaterialsV3ViewController {
    private func onShareButtonTapped() {
        let selectedFileIds = selectedFiles
        resetEditableAndSelectedFiles()
        var selectData: [TKMaterial] = allData.filter { ele in
            selectedFileIds.contains(ele.key)
        }.compactMap({ $0.value })
        var defStudentIds: [String] = []

        // 获取当前的目录下的所有顶层目录,获取里面的所有学生Id
        for folderCollectionView in collectionViews {
            if let folder = allData[folderCollectionView.materialsId] {
                defStudentIds += folder.studentIds
            }
        }
        for item in selectData {
            defStudentIds += item.studentIds
        }
        defStudentIds = defStudentIds.filterDuplicates({ $0 })
        let folders = selectData.filter({ $0.type == .folder }).compactMap({ $0.id })
        selectData.removeElements({ folders.contains($0.folder) })
        logger.debug("已选择要分享的文件: \(selectData.toJSONString() ?? "")")
        logger.debug("已经分享给了的学生: \(defStudentIds)")
        guard selectData.count > 0 else {
            return
        }
        let controller = AddressBookViewController()
        controller.isShowSelectAll = true
        if selectData.count > 1 {
            controller.from = .materialsMultiple
            logger.debug("材料分享 => 当前是多个文件分享")
        } else {
            logger.debug("材料分享 => 当前是单个文件分享")
            controller.from = .materials
        }
        logger.debug("材料分享 => 分享到的学生id: [\(defStudentIds)] | 分享的材料:\(selectData.compactMap { $0.id })]")
        controller.showType = .appContact
        controller.hero.isEnabled = true
        controller.defaultIds = defStudentIds
        controller.materials = selectData
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
        controller.onStudentSelected = { [weak self] selectedStudentIds in
            guard let self = self else { return }
            logger.debug("是否是静音的: \(controller.isShareSilently)")
            self.shareMaterials(materials: selectData, selectedStudentIds: selectedStudentIds, defaultStudentIds: defStudentIds, sendEmail: !controller.isShareSilently)
        }
    }

    private func shareMaterials(materials: [TKMaterial], selectedStudentIds: [String], defaultStudentIds: [String], sendEmail: Bool) {
        logger.debug("文件分享 => 进入回调")
        guard let currentFolderId = getCurrentFolderId() else { return }
        let currentFolder = allData[currentFolderId]
        if currentFolder != nil {
            logger.debug("文件分享 => 当前在文件夹里了")
            let folderIds = collectionViews.map { $0.materialsId }
            var allStudentsMap: [String: [String]] = [:]
            for folderId in folderIds {
                allStudentsMap[folderId] = allData[folderId]?.studentIds ?? []
            }
            let allStudentsIdsList = allData.values.compactMap({ $0.studentIds })
            var allStudentsIds: [String] = []
            for ids in allStudentsIdsList {
                allStudentsIds += ids
            }
            allStudentsIds = allStudentsIds.filterDuplicates({ $0 })
            logger.debug("文件分享 => 原来的所有学生: \(allStudentsIds)")
            // 被取消的学生
            let removedStudentIds: [String] = defaultStudentIds.filter({ !selectedStudentIds.contains($0) })
            // studentId: [Materials]
            var removedExistsStudentMap: [String: [String]] = [:]
            for removedStudentId in removedStudentIds {
                // 当前被移除的学生有上层目录的权限
                for (folderId, studentIds) in allStudentsMap where studentIds.contains(removedStudentId) {
                    var folderIds = removedExistsStudentMap[removedStudentId]
                    if folderIds == nil {
                        folderIds = []
                    }
                    folderIds!.append(folderId)
                    removedExistsStudentMap[removedStudentId] = folderIds
                }
            }
            if !removedExistsStudentMap.isEmpty {
                // 获取所有顶层已经存在的被分享的学生
//                let removedStudents: [TKStudent] = ListenerService.shared.teacherData.studentList.filter { student in
//                    removedExistsStudentMap.keys.contains(student.studentId)
//                }
                var strings: [String] = []
                for (studentId, folderIds) in removedExistsStudentMap {
                    if let student = ListenerService.shared.teacherData.studentList.first(where: { $0.studentId == studentId }) {
                        let folders = allData.values.filter({ folderIds.contains($0.id) })
                        strings.append("\(student.name): (/Home/\(folders.compactMap({ $0.name }).joined(separator: "/")))")
                    }
                }

                SL.Alert.show(target: self, title: "Continue?", message: "The below students from which you are attempting to revoke access to the files, have access to the folder/subfolder in which the files are located.\n\n\(strings.joined(separator: "\n"))\n\nThis action will have no effect on these individuals' access to the files. Do you wish to continue?", leftButttonString: "Cancel", rightButtonString: "Continue") {
                } rightButtonAction: { [weak self] in
                    guard let self = self else { return }
                    self.commitShareMaterials(materials: materials, studentIds: selectedStudentIds, sendEmail: sendEmail)
                }
            } else {
                commitShareMaterials(materials: materials, studentIds: selectedStudentIds, sendEmail: sendEmail)
            }
        } else {
            commitShareMaterials(materials: materials, studentIds: selectedStudentIds, sendEmail: sendEmail)
        }
    }

    private func commitShareMaterials(materials: [TKMaterial], studentIds: [String], sendEmail: Bool) {
        logger.debug("是否发送email: \(sendEmail)")
        showFullScreenLoadingNoAutoHide()
        MaterialService.shared.shareMaterial(materialIds: materials.compactMap({ $0.id }), studentIds: studentIds, sendEmail: sendEmail)
            .done { [weak self] _ in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                TKToast.show(msg: "Successfully.", style: .success)
                let folders = materials.compactMap({ $0.folder }).filterDuplicates({ $0 })
                for folder in folders {
                    self.loadMaterials(folderId: folder)
                }
            }
            .catch { error in
                TKToast.show(msg: TipMsg.shareFailed, style: .error)
                logger.debug("分享失败: \(error)")
            }
    }
}

extension MaterialsV3ViewController {
    private func onDeleteButtonTapped() {
        // 获取所有被选中的cell
        let selectedFileIds = selectedFiles
        resetEditableAndSelectedFiles()
        var selectedItems: [TKMaterial] = allData.filter { ele in
            selectedFileIds.contains(ele.key)
        }.compactMap({ $0.value })

        let folders = selectedItems.filter({ $0.type == .folder }).compactMap({ $0.id })
        selectedItems.removeElements({ folders.contains($0.folder) })
        logger.debug("选择的项目: \(selectedItems.toJSONString() ?? "")")
        SL.Alert.show(target: self, title: "", message: TipMsg.deleteMaterialTip, leftButttonString: "DELETE", rightButtonString: "GO BACK", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
//            self?.deleteMaterials(ids: ids, inFolders: inFolders)
            self?.deleteMaterialsV2(selectedItems)
        }) {
        }
    }

    func deleteMaterialsV2(_ materials: [TKMaterial]) {
        logger.debug("要删除的材料： \(materials.compactMap({ $0.id }))")
        guard !materials.isEmpty else { return }
        showFullScreenLoadingNoAutoHide()
        Functions.functions().httpsCallable("materialService-deleteMaterial")
            .call(["ids": materials.compactMap({ $0.id })]) { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.debug("删除失败: \(error)")
                    TKToast.show(msg: TipMsg.deleteFailed, style: .error)
                } else {
                    let folders = materials.compactMap({ $0.folder }).filterDuplicates({ $0 })
                    for folder in folders {
                        self.loadMaterials(folderId: folder)
                    }
                }
            }
    }
}

extension MaterialsV3ViewController: TKSearchBarDelegate {
    func tkSearchBar(textChanged searchBar: TKSearchBar, text: String) {
        searchKey = text
        guard let currentFolderId = getCurrentFolderId() else { return }
        let groupedFiles = (data[currentFolderId] ?? []).sorted(by: { $0.weight < $1.weight })
        let files = groupedFiles.compactMap({ $0.files }).flatMap({ $0 })
        searchResult = files.filter({ file in
            if file.name.lowercased().contains(text.lowercased()) {
                return true
            }
            return false
        })
    }

    func tkSearchBar(didFocus searchBar: TKSearchBar) {
        isSearching = true
        logger.debug("聚焦搜索")
    }

    func tkSearchBar(didBlur searchBar: TKSearchBar) {
        isSearching = false
        logger.debug("搜索离焦")
    }
}

extension MaterialsV3ViewController: UpdateMaterialsTitleViewControllerDelegate {
    func updateMaterialsTitleViewController(nextButtonTappedWithTitle title: String, id: String) {
        showFullScreenLoadingNoAutoHide()
        DatabaseService.collections.material()
            .document(id)
            .updateData(["name": title]) { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("更改名称失败: \(error)")
                    TKToast.show(msg: "Update name failed, please try again later.", style: .error)
                } else {
                    TKToast.show(msg: "Successfully.", style: .success)
                    guard let currentFolderId = self.getCurrentFolderId() else { return }
                    self.loadMaterials(folderId: currentFolderId)
                }
            }
    }
}
