//
//  Materials2ViewController.swift
//  TuneKey
//
//  Created by zyf on 2020/11/11.
//  Copyright © 2020 spelist. All rights reserved.
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
import UIKit

class Materials2ViewController: TKBaseViewController {
    // MARK: - UI Components

    private var navigationBarView: TKView = TKView.create()

    private var navigationTitleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 18))
        .alignment(alignment: .center)
        .textColor(color: ColorUtil.Font.fourth)
        .text(text: "Materials")

    private var backButton: TKButton = TKButton.create()
        .setImage(name: "back")
    private var editButton: TKButton = TKButton.create()
        .setImage(name: "edit_new")
    private var addButton: TKButton = TKButton.create()
        .setImage(name: "icAddPrimary")
    private var searchButton: TKButton = TKButton.create()
        .setImage(name: "search_primary")
    private var confirmButton: TKBlockButton = TKBlockButton(frame: .zero, title: "SHARE")

    private var shareSilentlyButton: Button = Button().title("Share Silently", for: .normal)
        .titleColor(.clickable, for: .normal)
        .font(.content)

    private var searchBar: TKSearchBar = TKSearchBar(frame: .zero)

    private var contentView: TKView = TKView.create()

    private var leftButtonsView: ViewBox?
    private var rightButtonsView: ViewBox?

    /// home页的collectionView
    private lazy var homeCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: {
            let layout = CollectionViewAlignFlowLayout()
            layout.layoutDelegate = self
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 5
            layout.scrollDirection = .vertical
            return layout
        }())
        return collectionView
    }()

    private var firstTouchLocationInFolderCollectionView: CGPoint?
//    private lazy var folderCollectionView: UICollectionView = {
//        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: {
//            let layout = CollectionViewAlignFlowLayout()
//            layout.layoutDelegate = self
//            layout.minimumLineSpacing = 0
//            layout.minimumInteritemSpacing = 5
//            layout.scrollDirection = .vertical
//            return layout
//        }())
//        return collectionView
//    }()

    @Live private var folderCollectionViews: [MaterialsCollectionView] = []
    @Live private var isShowAddressMoreLineButton: Bool = false
    @Live private var isAddressOneLine: Bool = true
    @Live private var addressesLabelAlignment: UIStackView.Alignment = .center
    private lazy var addressesView: ViewBox = makeAddressesView()

    private lazy var bottomButtonsView: TKView = {
        let view = TKView.create()
            .backgroundColor(color: .white)
        let width = UIScreen.main.bounds.width / 3
        view.addSubview(view: deleteButton) { make in
            make.width.equalTo(width)
            make.left.equalToSuperview()
            make.height.equalTo(49)
            make.top.equalToSuperview()
        }

        view.addSubview(view: shareButton) { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(width)
            make.height.equalTo(49)
            make.top.equalToSuperview()
        }

        view.addSubview(view: moveButton) { make in
            make.width.equalTo(width)
            make.right.equalToSuperview()
            make.height.equalTo(49)
            make.top.equalToSuperview()
        }
        return view
    }()

    private var deleteButton: TKButton = TKButton.create()
        .title(title: "Delete")
        .titleColor(color: ColorUtil.Font.fourth)
        .titleFont(font: FontUtil.bold(size: 18))

    private var shareButton: TKButton = TKButton.create()
        .title(title: "Share")
        .titleColor(color: ColorUtil.Font.fourth)
        .titleFont(font: FontUtil.bold(size: 18))

    private var moveButton: TKButton = TKButton.create()
        .title(title: "Move")
        .titleColor(color: ColorUtil.Font.fourth)
        .titleFont(font: FontUtil.bold(size: 18))

    private lazy var upgradeProView: TKView = {
        let view = TKView.create()
        upgradeProButton.addTo(superView: view) { make in
            make.right.equalToSuperview()
            make.height.equalTo(0)
            make.width.equalTo(0)
            make.centerY.equalToSuperview()
        }
        upgradeProButton.backgroundColor = ColorUtil.blush
        upgradeProButton.layer.cornerRadius = 4

        upgradeProLabel.addTo(superView: view) { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(upgradeProButton.snp.left)
        }
        return view
    }()

    private var upgradeProLabel: TKLabel = TKLabel.create()
        .textColor(color: ColorUtil.Font.primary)
        .font(font: FontUtil.regular(size: 10))
        .text(text: "You should upgrade Insights to pro.\nTry PRO to unlock the full power of TuneKey.")
        .setNumberOfLines(number: 2)
    private var upgradeProButton: TKButton = TKButton.create()
        .title(title: "PRO")
        .titleFont(font: FontUtil.regular(size: 10))

    private lazy var inviteTeacherLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 10))
        .textColor(color: ColorUtil.Font.primary)
        .text(text: "Reschedule? Interact with your instructors?\nInvite your instructor to unlock more cool features.")
        .alignment(alignment: .left)
        .setNumberOfLines(number: 0)

    private lazy var inviteTeacherButton: TKButton = TKButton.create()
        .titleFont(font: FontUtil.medium(size: 9))
        .title(title: "INVITE")
        .backgroundColor(color: ColorUtil.red)

    private lazy var inviteTeacherView: TKView = {
        let view = TKView.create()
        view.clipsToBounds = true
        inviteTeacherButton.cornerRadius = 3
        inviteTeacherButton.onTapped { [weak self] _ in
            self?.toInviteTeacher()
        }
        inviteTeacherButton.addTo(superView: view) { make in
            make.width.equalTo(42)
            make.height.equalTo(24)
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        inviteTeacherLabel.addTo(superView: view) { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(inviteTeacherButton.snp.left).offset(-20)
        }

        return view
    }()

    private lazy var emptyView: TKView = {
        let view = TKView.create()
        view.layer.masksToBounds = true
        let emptyImageView = TKImageView.create()
            .setImage(name: "imgNoMaterials")
            .addTo(superView: view) { make in
                make.top.equalToSuperview()
                make.centerX.equalToSuperview()
                make.width.equalTo(240)
                make.height.equalTo(200)
            }

        let emptyLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.primary)
            .alignment(alignment: .center)
            .font(font: FontUtil.bold(size: 16))
            .text(text: "Add your materials in minutes.\nIt's easy, we promise!")
            .setNumberOfLines(number: 0)
            .addTo(superView: view) { make in
                make.top.equalTo(emptyImageView.snp.bottom).offset(30)
                make.left.equalTo(30)
                make.right.equalTo(-30)
                make.centerX.equalToSuperview()
            }
        emptyLabel.changeLabelRowSpace(lineSpace: 0.8, wordSpace: 0.89)
        let emptyButton = TKBlockButton(frame: .zero, title: "ADD MATERIALS")
        emptyButton.onTapped { [weak self] _ in
            self?.onAddButtonTapped()
        }
        emptyButton.addTo(superView: view) { make in
            if UIScreen.main.bounds.height > 670 {
                make.top.equalTo(emptyLabel.snp.bottom).offset(120)
            } else {
                make.top.equalTo(emptyLabel.snp.bottom).offset(65)
            }
            make.height.equalTo(50)
            make.width.equalTo(200)
            make.centerX.equalToSuperview()
        }
        return view
    }()

    // MARK: - Data Model

    enum `Type`: Equatable {
        case homepage
        case list
        case share([String])
        case student
    }

    private var searchKey: String = "" {
        didSet {
            search()
        }
    }

    private var type: Type = .list {
        didSet {
            logger.debug("当前材料页的类型: \(type)")
        }
    }

    private var isEdit: Bool = false

    private var searchData: [String] = []

    private var searchFolderData: [String] = []

    private var data: [String] = [] {
        didSet {
            logger.debug("当前的首页文件: \(data)")
            initContentView()
        }
    }

    private var dataSource: [String: TKMaterial] = [:] {
        didSet {
            logger.debug("当前数据的数量: \(Array(dataSource.values).count)")
            switch type {
            case let .share(ids):
                dataSource.forEach { _, item in
                    if ids.contains(item.id) {
                        item._isSelected = true
                    } else {
                        item._isSelected = false
                    }
                }
                break
            default:
                break
            }
            homeCollectionView.reloadData()
            folderCollectionViews.forEach { $0.reloadData() }
        }
    }

    private var currentFolder: TKMaterial? {
        if let id = folderCollectionViews.first?.materialsId {
            return dataSource[id]
        } else {
            return nil
        }
    }

//    private var currentFolder: TKMaterial? {
//        didSet {
//            if currentFolder == nil {
//                addButton.isHidden = false
//                switch type {
//                case .student:
//                    var hasOwn: Bool = false
//                    for id in data {
//                        if let item = dataSource[id] {
//                            if item.isOwnMaterials {
//                                hasOwn = true
//                                break
//                            }
//                        }
//                    }
//                    if hasOwn {
//                        editButton.isHidden = false
//                    } else {
//                        editButton.isHidden = true
//                    }
//                default:
//                    break
//                }
//
//                navigationTitleLabel.snp.remakeConstraints { make in
//                    make.centerX.equalToSuperview()
//                    make.centerY.equalToSuperview().offset(4)
//                    if let leftButtonsView = leftButtonsView {
//                        make.left.equalTo(leftButtonsView.snp.right).offset(4)
//                    }
//                    make.right.equalTo(addButton.snp.left).offset(-4)
//                }
//            } else {
//                switch type {
//                case .share:
//                    break
//                default:
//                    if currentFolder!.isOwnMaterials {
//                        addButton.isHidden = false
//                        editButton.isHidden = false
//                    } else {
//                        addButton.isHidden = true
//                        editButton.isHidden = true
//                    }
//                    navigationTitleLabel.snp.remakeConstraints { make in
//                        make.centerY.equalToSuperview().offset(4)
//                        if let leftButtonsView = leftButtonsView {
//                            make.left.equalTo(leftButtonsView.snp.right).offset(4)
//                        }
//                        make.right.equalTo(addButton.snp.left).offset(-4)
//                    }
//                }
//            }
//        }
//    }

    /// 如果当前页的数据是没有从上一页传递过来,则为true,用来判断是否要从数据库中获取数据
    private var willLoadData: Bool = false

    private let homeCollectionViewTag: Int = 1

    private let folderCollectionViewTag: Int = 2

    private var youtubeCellSize: CGSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 150)

    private var otherCellSize: CGSize = CGSize(width: (UIScreen.main.bounds.width - 50) / 3, height: (UIScreen.main.bounds.width - 50) / 3)

    private var backToScale: CGPoint = .zero

    private var backToCenter: CGPoint = .zero

    private var teacherMemberLevel: Int = 1

    private var defaultSelectedIds: [String] = []

    var onConfirmed: (([TKMaterial], Bool) -> Void)?

    var newMaterialsData: [String] = []

    // MARK: - Init

    convenience init(type: Type, isEdit: Bool = false, data: [TKMaterial]? = nil) {
        self.init(nibName: nil, bundle: nil)
        self.type = type
        self.isEdit = isEdit
        if let data = data {
            setData(data: data)
        } else {
            willLoadData = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initContentView()
        if ParentService.shared.isCurrentRoleParent() {
            reloadHomeData()
        }
        homeCollectionView.reloadData()
        UIApplication.shared.isIdleTimerDisabled = true
//        folderCollectionView.reloadData()
        folderCollectionViews.forEach({ $0.reloadData() })
        if searchKey != "" {
            search()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        leftButtonsView?.layoutIfNeeded()
        if backButton.isHidden && editButton.isHidden {
            searchBar.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalToSuperview().multipliedBy(0.8)
                make.bottom.equalToSuperview().offset(-4)
            }
        } else {
            searchBar.snp.remakeConstraints { make in
                make.left.equalTo(leftButtonsView!.snp.right).offset(10)
                make.right.equalToSuperview().offset(-20)
                make.height.equalToSuperview().multipliedBy(0.8)
                make.bottom.equalToSuperview().offset(-4)
            }
        }
        rightButtonsView?.layoutIfNeeded()
        let leftWidth = leftButtonsView?.bounds.width ?? 0
        let rightWidth = rightButtonsView?.bounds.width ?? 0

        let maxWidth = max(leftWidth, rightWidth)
        logger.debug("左边: \(leftWidth) | 右边: \(rightWidth) | 最大的: \(maxWidth)")
        // 左边20,右边20,一共40的间距,所以总的宽度应该是
        let width = UIScreen.main.bounds.width - 40 - (maxWidth * 2) - 20
        logger.debug("title的宽度: \(width)")
        navigationTitleLabel.snp.updateConstraints { make in
            make.width.equalTo(width)
        }
    }
}

// MARK: - layout

extension Materials2ViewController {
    private func makeAddressesView() -> ViewBox {
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            HStack {
                Label().numberOfLines(0)
                    .lineBreakMode(.byTruncatingHead)
                    .apply { [weak self] label in
                        guard let self = self else { return }
                        self.$folderCollectionViews.addSubscriber { collectionViews in
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
            self.$folderCollectionViews.addSubscriber { collectionViews in
                view.isHidden = collectionViews.isEmpty
            }
        }
    }
}

extension Materials2ViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
        ViewBox(paddings: .zero) {
            VStack(spacing: 30) {
                ImageView(image: UIImage(named: "empty_folder")).contentMode(.scaleAspectFit)
                    .size(height: 200)
                Label("No materials here.").textColor(ColorUtil.Font.primary)
                    .font(FontUtil.bold(size: 16))
                    .textAlignment(.center)
            }
        }
    }
}

extension Materials2ViewController {
    override func initView() {
        super.initView()

        view.backgroundColor = ColorUtil.backgroundColor

        // MARK: - navigationBar

        navigationBarView.addTo(superView: view) { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.height.equalTo(44)
        }

//        backButton.addTo(superView: navigationBarView) { make in
//            make.centerY.equalToSuperview().offset(4)
//            make.size.equalTo(22)
//            make.left.equalToSuperview().offset(20)
//        }
//        backButton.isHidden = true
//
//        editButton.addTo(superView: navigationBarView) { make in
//            make.centerY.equalToSuperview().offset(4)
//            make.size.equalTo(22)
//            make.left.equalToSuperview().offset(20)
//        }
        editButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        editButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        backButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        backButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let leftButtonsView = ViewBox(paddings: .zero) {
            HStack(spacing: 20) {
                backButton
                editButton
            }
        }
        .contentHuggingPriority(.defaultHigh, for: .horizontal)
        .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        editButton.snp.makeConstraints { make in
            make.width.equalTo(22)
            make.height.equalTo(22)
        }
        backButton.snp.makeConstraints { make in
            make.width.equalTo(22)
            make.height.equalTo(22)
        }
        leftButtonsView.addTo(superView: navigationBarView) { make in
            make.centerY.equalToSuperview().offset(4)
            make.height.equalTo(22)
            make.left.equalToSuperview().offset(20)
        }
        self.leftButtonsView = leftButtonsView

        let rightButtonsView = ViewBox(paddings: .zero) {
            HStack(spacing: 20) {
                addButton
                searchButton
            }
        }
        rightButtonsView.addTo(superView: navigationBarView) { make in
            make.centerY.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(22)
        }
        self.rightButtonsView = rightButtonsView
        addButton.snp.makeConstraints { make in
            make.width.equalTo(22)
            make.height.equalTo(22)
        }
        searchButton.snp.makeConstraints { make in
            make.width.equalTo(22)
            make.height.equalTo(22)
        }
//        searchButton.addTo(superView: navigationBarView) { make in
//            make.centerY.equalToSuperview().offset(4)
//            make.size.equalTo(22)
//            make.right.equalToSuperview().offset(-20)
//        }
//
//        addButton.addTo(superView: navigationBarView) { make in
//            make.centerY.equalToSuperview().offset(4)
//            make.size.equalTo(22)
//            make.right.equalTo(searchButton.snp.left).offset(-20)
//        }

        navigationTitleLabel.addTo(superView: navigationBarView) { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(4)
            make.width.equalTo(100)
//            make.left.equalTo(leftButtonsView.snp.right).offset(4)
//            make.right.equalTo(addButton.snp.left).offset(-4)
        }

        searchBar.addTo(superView: navigationBarView) { make in
            make.right.equalToSuperview().offset(-20)
            make.height.equalToSuperview().multipliedBy(0.8)
            make.left.equalTo(leftButtonsView.snp.right).offset(10)
            make.bottom.equalToSuperview().offset(-4)
        }

        searchBar.setClearButtonAlwaysShow()
        searchBar.background(UIColor(r: 239, g: 243, b: 242))
        searchBar.isHidden = true
        searchBar.delegate = self

        // MARK: - Upgrade Pro

        upgradeProView.addTo(superView: view) { make in
            make.top.equalTo(navigationBarView.snp.bottom)
            make.height.equalTo(0)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        // MARK: - Invite teacher view

        inviteTeacherView.addTo(superView: view) { make in
            make.top.equalTo(navigationBarView.snp.bottom)
            make.height.equalTo(0)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        // MARK: - contentView

        contentView.addTo(superView: view) { make in
            make.top.equalTo(navigationBarView.snp.bottom)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        // MARK: - collectionView

        homeCollectionView.addTo(superView: contentView) { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        homeCollectionView.tag = homeCollectionViewTag
        homeCollectionView.backgroundColor = ColorUtil.backgroundColor
        homeCollectionView.contentInset = .init(top: 20, left: 20, bottom: 20, right: -20)
        homeCollectionView.allowsSelection = false
        homeCollectionView.showsVerticalScrollIndicator = false
        homeCollectionView.delegate = self
        homeCollectionView.dataSource = self

        homeCollectionView.dragDelegate = self
        homeCollectionView.dropDelegate = self
        homeCollectionView.dragInteractionEnabled = true

//        folderCollectionView.addTo(superView: contentView) { make in
//            make.top.bottom.equalToSuperview()
//            make.left.equalToSuperview()
//            make.right.equalToSuperview()
//        }
//        folderCollectionView.tag = folderCollectionViewTag
//        folderCollectionView.backgroundColor = ColorUtil.folderBackground
//        folderCollectionView.contentInset = .init(top: 20, left: 20, bottom: 20, right: -20)
//        folderCollectionView.allowsSelection = false
//        folderCollectionView.showsVerticalScrollIndicator = false
//        folderCollectionView.delegate = self
//        folderCollectionView.dataSource = self

        if #available(iOS 13.0, *) {
            homeCollectionView.automaticallyAdjustsScrollIndicatorInsets = false
//            folderCollectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        homeCollectionView.isPrefetchingEnabled = true
//        folderCollectionView.isPrefetchingEnabled = true

        homeCollectionView.register(MaterialsCell.self, forCellWithReuseIdentifier: String(describing: MaterialsCell.self))
//        folderCollectionView.register(MaterialsCell.self, forCellWithReuseIdentifier: String(describing: MaterialsCell.self))
//        folderCollectionView.isHidden = true
        switch type {
        case .share:
            homeCollectionView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 80, right: -20)
//            folderCollectionView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 80, right: -20)
        default:
            break
        }
        refreshViewForType()
//        addGestureForFolderCollectionView()

        bottomButtonsView.addTo(superView: view) { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(48 + UiUtil.safeAreaBottom())
        }
        bottomButtonsView.transform = CGAffineTransform(translationX: 0, y: 48 + UiUtil.safeAreaBottom())
        bottomButtonsView.isHidden = true

        // MARK: - empty view

        emptyView.addTo(superView: view) { make in
            make.top.equalTo(navigationBarView.snp.bottom).offset(51)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        emptyView.isHidden = true

        shareSilentlyButton.addTo(superView: view) { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.centerX.equalToSuperview()
        }
        shareSilentlyButton.isHidden = true
        confirmButton.addTo(superView: view) { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalTo(180)
//            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.bottom.equalTo(shareSilentlyButton.snp.top).offset(-20)
        }
        confirmButton.isHidden = true

        refreshViewForType()
        addressesView.addTo(superView: view) { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(contentView.snp.bottom)
        }

        $folderCollectionViews.addSubscriber { [weak self] collectionViews in
            guard let self = self else { return }
            self.confirmButton.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.height.equalTo(50)
                make.width.equalTo(180)
                switch self.type {
                case .share:
                    make.bottom.equalTo(self.shareSilentlyButton.snp.top).offset(-20)
                default:
                    if collectionViews.isEmpty {
                        make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-20)
                    } else {
                        make.bottom.equalTo(self.addressesView.snp.top)
                    }
                }
            }
            switch self.type {
            case .share:
                self.shareSilentlyButton.snp.remakeConstraints { make in
                    make.centerX.equalToSuperview()
                    if collectionViews.isEmpty {
                        make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-20)
                    } else {
                        make.bottom.equalTo(self.addressesView.snp.top).offset(-20)
                    }
                }
            default: break
            }
        }
    }

    private func addFolderCollectionView(_ materials: TKMaterial) {
        let folderCollectionView = makeFolderCollectionView()
        folderCollectionView.emptyDataSetSource = self
        folderCollectionView.emptyDataSetDelegate = self
        folderCollectionView.materialsId = materials.id
        folderCollectionView.addTo(superView: contentView) { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        folderCollectionView.tag = folderCollectionViewTag
        folderCollectionView.backgroundColor = ColorUtil.backgroundColor
        folderCollectionView.contentInset = .init(top: 20, left: 20, bottom: 20, right: -20)
        folderCollectionView.allowsSelection = false
        folderCollectionView.showsVerticalScrollIndicator = false
        folderCollectionView.delegate = self
        folderCollectionView.dataSource = self

        folderCollectionView.dragDelegate = self
        folderCollectionView.dropDelegate = self
        folderCollectionView.dragInteractionEnabled = true

        if #available(iOS 13.0, *) {
            folderCollectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        folderCollectionView.isPrefetchingEnabled = true

        folderCollectionView.register(MaterialsCell.self, forCellWithReuseIdentifier: String(describing: MaterialsCell.self))
        folderCollectionView.isHidden = true
        switch type {
        case .share:
            folderCollectionView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 180, right: -20)
        default:
            break
        }
        folderCollectionViews.insert(folderCollectionView, at: 0)
        addGestureForFolderCollectionView(folderCollectionView)
        view.bringSubviewToFront(addressesView)
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
//                currentFolder = nil
                hideFolder()
            } else {
                UIView.animate(withDuration: 0.2) {
                    folderCollectionView.transform = .identity
                }
            }
        }
    }

    /// 刷新view
    private func refreshViewForType() {
        isEdit = false
        switch type {
        case .homepage:
            editButton.isHidden = false
            addButton.isHidden = false
            searchButton.isHidden = false
            backButton.isHidden = true
            shareSilentlyButton.isHidden = true
            if let role = ListenerService.shared.currentRole {
                switch role {
                case .teacher:
                    backButton.isHidden = true
                case .studioManager:
                    backButton.isHidden = true
                default: break
                }
            }
        case .list:
            editButton.isHidden = true
            addButton.isHidden = true
            backButton.isHidden = false
            shareSilentlyButton.isHidden = true
        case .share:
            editButton.isHidden = true
            addButton.isHidden = false
            confirmButton.isHidden = false
            shareSilentlyButton.isHidden = false
            backButton.isHidden = false
            searchButton.isHidden = false
            isEdit = true
        case .student:
            shareSilentlyButton.isHidden = true
            backButton.isHidden = true
            addButton.isHidden = false
            editButton.isHidden = false
            searchButton.isHidden = false
        }
    }

//    private func reloadCollectionView2() {
//        // 判断当前文件夹是要消失还是要返回出现
//        if currentFolder != nil {
    ////            folderCollectionView.reloadData()
//            navigationTitleLabel.text = currentFolder?.name ?? ""
    ////            folderCollectionView.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
    ////            folderCollectionView.isHidden = false
//            backButton.isHidden = false
//            switch type {
//            case .list:
//                editButton.isHidden = true
//            default: break
//            }
//        } else {
//            switch type {
//            case .homepage, .student:
//                backButton.isHidden = true
//            case .list:
//                editButton.isHidden = true
//            default: break
//            }
    ////            folderCollectionView.reloadData()
//            navigationTitleLabel.text = "Materials"
//
//            UIView.animate(withDuration: 0.2) {
    ////                self.folderCollectionView.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
//
//            } completion: { [weak self] _ in
//                guard let self = self else { return }
    ////                self.folderCollectionView.isHidden = true
    ////                self.folderCollectionView.transform = .identity
//            }
//        }
//    }

//    private func reloadCollectionView(cell: MaterialsCell? = nil) {
//        if let folder = currentFolder {
//            navigationTitleLabel.text = folder.name
//            // 当前是在子文件夹之内,获取子文件夹的位置
    ////            var frame: CGRect = .zero
    ////            let size = (UIScreen.main.bounds.width - 50) / 3
    ////            var center: CGPoint = .zero
    ////            if let cell = cell {
    ////                let f = cell.typeImageView.convert(cell.typeImageView.frame, to: contentView)
    ////                frame = CGRect(origin: CGPoint(x: f.origin.x, y: f.origin.y), size: CGSize(width: size, height: size))
    ////                center = CGPoint(x: f.midX, y: f.midY)
    ////            } else {
    ////                frame = CGRect(origin: CGPoint(x: view.center.x - (size / 2), y: view.center.y - (size / 2)), size: CGSize(width: size, height: size))
    ////                center = view.center
    ////            }
//            if let folderCollectionView = folderCollectionViews.first {
//                logger.debug("开始渲染子文件夹: \(folderCollectionView.materialsId)")
    ////                let originalFrame = folderCollectionView.frame
    ////                let scaleX = frame.width / originalFrame.width
    ////                let scaleY = frame.height / originalFrame.height
    ////                backToScale = CGPoint(x: scaleX, y: scaleY)
    ////                backToCenter = center
    ////                folderCollectionView.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
    ////                folderCollectionView.center = center
//                folderCollectionView.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
    ////                folderCollectionView.layer.opacity = 0
    ////                folderCollectionView.layer.cornerRadius = 5
//                folderCollectionView.isHidden = false
//                folderCollectionView.reloadData()
//                backButton.isHidden = false
//                UIView.animate(withDuration: 0.2) {
    ////                    folderCollectionView.backgroundColor = ColorUtil.folderBackground
    ////                    folderCollectionView.layer.opacity = 1
    ////                    folderCollectionView.layer.cornerRadius = 0
//                    folderCollectionView.transform = .identity
//                    folderCollectionView.center = self.homeCollectionView.center
//                }
//            }
//
//        } else {
//            navigationTitleLabel.text = "Materials"
//            switch type {
//            case .homepage, .student:
//                backButton.isHidden = true
//            default:
//                break
//            }
//            if let folderCollectionView = folderCollectionViews.first {
//                UIView.animate(withDuration: 0.2) {
//                    folderCollectionView.transform = CGAffineTransform(scaleX: self.backToScale.x, y: self.backToScale.y)
//                    folderCollectionView.center = self.backToCenter
//                    folderCollectionView.layer.opacity = 0
//                    folderCollectionView.layer.cornerRadius = 5
//                } completion: { [weak self] _ in
//                    guard let self = self else { return }
    ////                    folderCollectionView.isHidden = true
    ////                    folderCollectionView.transform = .identity
    ////                    folderCollectionView.center = self.homeCollectionView.center
//                    self.folderCollectionViews.remove(at: 0)
//                }
//            }
//        }
//    }

    private func showFolder() {
        guard let folderCollectionView = folderCollectionViews.first else {
            logger.debug("无法获取最顶层的文件夹collectionView")
            return
        }
        let folderId = folderCollectionView.materialsId
        guard let folder = dataSource[folderId] else {
            logger.debug("无法获取文件夹: \(folderId)")
            return
        }
        navigationTitleLabel.text = folder.name
        logger.debug("开始渲染子文件夹: \(folderCollectionView.materialsId)")
        folderCollectionView.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
        folderCollectionView.isHidden = false
        folderCollectionView.reloadData()
        backButton.isHidden = false
        view.bringSubviewToFront(addressesView)
        UIView.animate(withDuration: 0.2) {
            folderCollectionView.transform = .identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            if self.type != .homepage {
                var studentId: String?
                if self.type == .student {
                    studentId = ListenerService.shared.user?.userId
                }
                MaterialService.shared.getData(byFolderId: folderId, withStudentId: studentId)
                    .done { [weak self] data in
                        guard let self = self else { return }
                        data.forEach {
                            self.dataSource[$0.id] = $0
                        }
                        folderCollectionView.reloadData()
                    }
                    .catch { error in
                        logger.error("加载子文件夹失败: \(error)")
                    }
            }
        }
    }

    private func hideFolder() {
        switch type {
        case .homepage:
            if folderCollectionViews.count - 1 == 0 {
                // 没有更多了
                backButton.isHidden = true
                if let role = ListenerService.shared.currentRole {
                    switch role {
                    case .teacher:
                        backButton.isHidden = true
                    case .studioManager:
                        backButton.isHidden = true
                    default: break
                    }
                }
            } else {
                backButton.isHidden = false
            }
            editButton.isHidden = false
        case .student:
            if folderCollectionViews.count - 1 == 0 {
                // 没有更多了
                backButton.isHidden = true
            } else {
                backButton.isHidden = false
            }
            editButton.isHidden = false
        case .list:
            editButton.isHidden = true
        default: break
        }
//            folderCollectionView.reloadData()

        guard let folderCollectionView = folderCollectionViews.first else {
            logger.debug("无法获取最顶层的文件夹collectionView")
            return
        }

        UIView.animate(withDuration: 0.2) {
            folderCollectionView.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            if !self.folderCollectionViews.isEmpty {
                self.folderCollectionViews.removeFirst()
                folderCollectionView.removeFromSuperview()
            }
            self.folderCollectionViews.first?.reloadData()
            if let folderCollectionView = self.folderCollectionViews.first, let folder = self.dataSource[folderCollectionView.materialsId] {
                logger.debug("切换navigationTitle: \(folder.name)")
                self.navigationTitleLabel.text = folder.name
            } else {
                logger.debug("切换navigationTitle: Materials")
                self.navigationTitleLabel.text = "Materials"
            }
//                self.folderCollectionView.isHidden = true
//                self.folderCollectionView.transform = .identity
        }
    }

    private func jumpToFolder(_ id: String) {
        if id == "" {
            // 跳转到根目录
            UIView.animate(withDuration: 0.2) {
                self.folderCollectionViews.forEach({ $0.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0) })
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.folderCollectionViews.forEach({ $0.removeFromSuperview() })
                self.folderCollectionViews.removeAll()
                self.navigationTitleLabel.text = "Materials"
                self.backButton.isHidden = true
                if let role = ListenerService.shared.currentRole {
                    switch role {
                    case .teacher:
                        self.backButton.isHidden = true
                    case .studioManager:
                        self.backButton.isHidden = true
                    default: break
                    }
                }
            }
        } else {
            // 调准到对应目录
            guard let index = folderCollectionViews.firstIndex(where: { $0.materialsId == id }) else { return }
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
                self.folderCollectionViews.first?.reloadData()
                if let folder = self.dataSource[id] {
                    self.navigationTitleLabel.text = folder.name
                } else {
                    self.navigationTitleLabel.text = "Materials"
                }
            }
        }
    }

    private func updateInviteTeacherView() {
        guard let userId = UserService.user.id() else {
            return
        }
        logger.debug("[教师邀请View] => 更新邀请教师view: \(userId)")
        var isShow: Bool = false
        switch type {
        case .student:
            // 获取当前学生数据,查看是否绑定了教师
            if let studentData = ListenerService.shared.studentData.studentData {
                let count = dataSource.values.filter { $0.creatorId == userId }.count
                if studentData.teacherId == "" {
                    logger.debug("[教师邀请View] => 没有绑定老师")
                    if count >= FreeResources.studentMaxMaterialsCountUnbindTeacher {
                        logger.debug("[教师邀请View] => 当前数量需要显示")
                        isShow = true
                        inviteTeacherLabel.text("You've reached your limit of \(FreeResources.studentMaxMaterialsCountUnbindTeacher) materials.\nInvite your instructor to unlock the full access.")
                        inviteTeacherButton.isHidden = false
                        inviteTeacherLabel.snp.remakeConstraints { make in
                            make.top.bottom.equalToSuperview()
                            make.left.equalToSuperview().offset(20)
                            make.right.equalTo(inviteTeacherButton.snp.left).offset(-20)
                        }
                    }
                } else {
                    // 绑定老师了,获取老师是不是pro
                    guard let teacher = ListenerService.shared.studentData.teacherData else {
                        isShow = false
                        return
                    }
                    if teacher.memberLevelId == 1 {
                        // 普通会员
                        if count >= FreeResources.studentMaxMaterialsCountBoundTeacher {
                            inviteTeacherLabel.text("You've reached your limit of \(FreeResources.studentMaxMaterialsCountBoundTeacher) materials. Once your instrcutor upgrate to PRO, you will be unlocked the unlimited access.")
                            inviteTeacherLabel.snp.remakeConstraints { make in
                                make.top.bottom.equalToSuperview()
                                make.left.equalToSuperview().offset(20)
                                make.right.equalToSuperview().offset(-20)
                            }
                            inviteTeacherButton.isHidden = true
                            isShow = true
                        }
                    } else {
                        isShow = false
                    }
                }
            }
        default:
            isShow = false
            inviteTeacherButton.isHidden = true
            inviteTeacherLabel.isHidden = true
        }

        logger.debug("当前是否选择显示: \(isShow)")
        if isShow {
            addButton.isHidden = true
        } else {
            addButton.isHidden = false
        }
        inviteTeacherView.isHidden = !isShow
        if inviteTeacherView.superview == nil {
            inviteTeacherView.addTo(superView: view) { make in
                make.height.equalTo(isShow ? 44 : 0)
                make.top.equalTo(navigationBarView.snp.bottom)
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
        } else {
            inviteTeacherView.snp.remakeConstraints { make in
                make.height.equalTo(isShow ? 44 : 0)
                make.top.equalTo(navigationBarView.snp.bottom)
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
        }
        contentView.snp.remakeConstraints { make in
            make.top.equalTo(isShow ? inviteTeacherView.snp.bottom : navigationBarView.snp.bottom)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func updateMemberView() {
        if teacherMemberLevel == 1 {
            let count: Int = dataSource.values.count
            changeProView(count >= FreeResources.maxMaterialsCount)
        } else {
            changeProView(false)
        }
    }

    private func changeProView(_ show: Bool) {
        switch type {
        case .homepage:
            upgradeProView.isHidden = !show
            upgradeProView.snp.updateConstraints { make in
                make.top.equalTo(navigationBarView.snp.bottom)
                make.height.equalTo(show ? 26 : 0)
            }
            upgradeProButton.snp.updateConstraints { make in
                make.height.equalTo(show ? 26 : 0)
                make.width.equalTo(show ? 42 : 0)
            }
            contentView.snp.remakeConstraints { make in
                make.top.equalTo(show ? upgradeProView.snp.bottom : navigationBarView.snp.bottom)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            }
        default:
            break
        }
    }

    private func initContentView() {
        switch type {
        case .homepage:
            if data.count > 0 {
                emptyView.isHidden = true
                contentView.isHidden = false
                inviteTeacherView.isHidden = true
                updateMemberView()
            } else {
                emptyView.isHidden = false
                contentView.isHidden = true
                upgradeProView.isHidden = true
                inviteTeacherView.isHidden = true
            }
        case .student:
            // 判断是否有我上传,如果没有就不显示
            var hasOwn: Bool = false
            for id in data {
                if let item = dataSource[id] {
                    if item.isOwnMaterials {
                        hasOwn = true
                        break
                    }
                }
            }
            if hasOwn {
                editButton.isHidden = false
            } else {
                editButton.isHidden = true
            }
            updateInviteTeacherView()
            if let currentFolder = currentFolder {
                if currentFolder.isOwnMaterials {
                    addButton.isHidden = false
                    editButton.isHidden = false
                } else {
                    addButton.isHidden = true
                    editButton.isHidden = true
                }
            }
            if data.count > 0 {
                emptyView.isHidden = true
                contentView.isHidden = false
                upgradeProView.isHidden = true
            } else {
                emptyView.isHidden = false
                contentView.isHidden = true
                upgradeProView.isHidden = true
            }
        default:
            break
        }
    }

    private func refreshViewAndChangeEdit() {
        if isEdit {
            if currentFolder != nil {
                backButton.isHidden = false
            } else {
                backButton.isHidden = true
            }
            isEdit = false
            editButton.title(title: "")
            editButton.setImage(name: "edit_new", size: CGSize(width: 22, height: 22))
            editButton.snp.updateConstraints { make in
                make.width.equalTo(22)
                make.height.equalTo(22)
            }
            deleteButton.isEnabled = true
            shareButton.isEnabled = true
            moveButton.isEnabled = true
            deleteButton.titleColor(ColorUtil.Font.fourth)
            shareButton.titleColor(ColorUtil.Font.fourth)
            moveButton.titleColor(ColorUtil.Font.fourth)
            UIView.animate(withDuration: 0.2) {
                self.bottomButtonsView.transform = CGAffineTransform(translationX: 0, y: 48 + UiUtil.safeAreaBottom())
                self.tabBarController?.tabBar.frame.origin.y -= (48 + UiUtil.safeAreaBottom())
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.bottomButtonsView.isHidden = true
            }
        } else {
            backButton.isHidden = true
            isEdit = true
            editButton.title(title: "Cancel")
            editButton.titleFont(FontUtil.bold(size: 13))
            editButton.titleColor(ColorUtil.main)
            editButton.setImageNil()
            editButton.snp.updateConstraints { make in
                make.width.equalTo(50)
                make.height.equalTo(22)
            }
            bottomButtonsView.isHidden = false

            deleteButton.isEnabled = false
            shareButton.isEnabled = false
            moveButton.isEnabled = false
            switch type {
            case .homepage:
                shareButton.isHidden = false
                let width = UIScreen.main.bounds.width / 3
                deleteButton.snp.remakeConstraints { make in
                    make.width.equalTo(width)
                    make.left.equalToSuperview()
                    make.height.equalTo(49)
                    make.top.equalToSuperview()
                }

                shareButton.snp.remakeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.width.equalTo(width)
                    make.height.equalTo(49)
                    make.top.equalToSuperview()
                }

                moveButton.snp.makeConstraints { make in
                    make.width.equalTo(width)
                    make.right.equalToSuperview()
                    make.height.equalTo(49)
                    make.top.equalToSuperview()
                }
            case .student:
                let width = UIScreen.main.bounds.width / 2
                shareButton.isHidden = true
                deleteButton.snp.remakeConstraints { make in
                    make.width.equalTo(width)
                    make.left.equalToSuperview()
                    make.height.equalTo(49)
                    make.top.equalToSuperview()
                }
                moveButton.snp.remakeConstraints { make in
                    make.width.equalTo(width)
                    make.right.equalToSuperview()
                    make.height.equalTo(49)
                    make.top.equalToSuperview()
                }
                break
            default:
                break
            }

            UIView.animate(withDuration: 0.2) {
                self.bottomButtonsView.transform = .identity
                self.tabBarController?.tabBar.frame.origin.y += (48 + UiUtil.safeAreaBottom())
            }
        }
    }
}

// MARK: - Events

extension Materials2ViewController {
    override func bindEvent() {
        super.bindEvent()

        backButton.onTapped { [weak self] _ in
            self?.onBackButtonTapped()
        }

        editButton.onTapped { [weak self] _ in
            self?.onEditButtonTapped()
        }

        searchButton.onTapped { [weak self] _ in
            self?.onSearchButtonTapped()
        }

        addButton.onTapped { [weak self] _ in
            self?.onAddButtonTapped()
        }

        deleteButton.onTapped { [weak self] _ in
            self?.onDeleteButtonTapped()
        }

        shareButton.onTapped { [weak self] _ in
            self?.onShareButtonTapped()
        }

        moveButton.onTapped { [weak self] _ in
            self?.onMoveButtonTapped()
        }

        confirmButton.onTapped { [weak self] _ in
            self?.onConfirmButtonTapped()
        }

        upgradeProView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            ProfileUpgradeDetailViewController.show(level: .normal, target: self)
        }

        shareSilentlyButton.onTapped { [weak self] _ in
            self?.onShareSilentlyButtonTapped()
        }
    }

    private func onConfirmButtonTapped() {
        switch type {
        case .share:
            let selectedData = dataSource.filter({ $0.value._isSelected }).compactMap { $0.value }
            logger.debug("已选择的数量: \(selectedData.count)")
            dismiss(animated: true) { [weak self] in
                self?.onConfirmed?(selectedData, true)
            }
            break
        default:
            break
        }
    }

    private func onShareSilentlyButtonTapped() {
        switch type {
        case .share:
            let selectedData = dataSource.filter({ $0.value._isSelected }).compactMap { $0.value }
            logger.debug("已选择的数量: \(selectedData.count)")
            dismiss(animated: true) { [weak self] in
                self?.onConfirmed?(selectedData, false)
            }
        default: break
        }
    }

    private func onBackButtonTapped() {
        switch type {
        case .homepage:
            if folderCollectionViews.count == 0 {
                if let role = ListenerService.shared.currentRole {
                    switch role {
                    case .teacher:
                        break
                    case .studioManager:
//                        dismiss(animated: true)
                        break
                    default: break
                    }
                }
            } else {
                hideFolder()
            }
        case .student:
            hideFolder()
        case .list, .share:
            if currentFolder != nil {
                hideFolder()
            } else {
                dismiss(animated: true, completion: nil)
            }
        }
    }

    private func onEditButtonTapped() {
        refreshViewAndChangeEdit()
        switch type {
        case .student:
            if isEdit {
                setData(data: ListenerService.shared.studentData.materials.filter { $0.isOwnMaterials })
            } else {
                setData(data: ListenerService.shared.studentData.materials)
            }
        case .homepage:
            guard let role = ListenerService.shared.currentRole else { return }
            switch role {
            case .teacher:
                setData(data: ListenerService.shared.studioManagerData.homeMaterials)
            case .studioManager:
                setData(data: ListenerService.shared.studioManagerData.homeMaterials)
            default: return
            }
        default:
            break
        }
        resetAllSelectedData()
        search()
        homeCollectionView.reloadData()
        folderCollectionViews.forEach({ $0.reloadData() })
    }

    private func onSearchButtonTapped() {
        searchBar.isHidden = false
        searchBar.focus()
    }

    private func onAddButtonTapped() {
        switch type {
        case .homepage, .share:
            if teacherMemberLevel == 1 {
                let count = dataSource.values.count
                if count >= FreeResources.maxMaterialsCount {
                    ProfileUpgradeDetailViewController.show(level: .normal, target: self)
                    return
                }
            }
            showAddPopup()
        case .student:
            // 获取是否绑定教师
            showFullScreenLoadingNoAutoHide()
            akasync { [weak self] in
                guard let self = self else { return }
                let count = self.dataSource.values.count
                var teacher: TKTeacher?
                if let teacherData = ListenerService.shared.studentData.teacherData {
                    teacher = teacherData
                } else {
                    if let teacherId = ListenerService.shared.studentData.studentData?.teacherId, teacherId != "" {
                        teacher = try akawait(UserService.teacher.getTeacher(teacherId))
                    }
                }
                self.hideFullScreenLoading()
                if let teacher = teacher {
                    if teacher.memberLevelId == 1 {
                        if count >= FreeResources.studentMaxMaterialsCountBoundTeacher {
                            // 提示让教师升级
                            SL.Alert.show(target: self, title: "", message: "You've reached your limit of \(FreeResources.studentMaxMaterialsCountBoundTeacher) materials. Once your instrcutor upgrate to PRO, you will be unlocked the unlimited access.", centerButttonString: "GO BACK") {
                            }
                            return
                        }
                    }
                } else {
                    if count >= FreeResources.studentMaxMaterialsCountUnbindTeacher {
                        // 提示绑定教师
                        SL.Alert.show(target: self, title: "", message: "You've reached your limit of \(FreeResources.studentMaxMaterialsCountUnbindTeacher) materials.\nInvite your instructor to unlock the full access.", leftButttonString: "GO BACK", rightButtonString: "INVITE INSTRUCTOR") {
                        } rightButtonAction: {
                            DispatchQueue.main.async {
                                self.toInviteTeacher()
                            }
                        }

                        return
                    }
                }
                self.showAddPopup()
            }
            break
        default: return
        }
    }

    private func showAddPopup() {
        TKPopAction.show(items:
            TKPopAction.Item(title: "New Folder", action: { [weak self] in
                self?.newFolder()
            }),
            TKPopAction.Item(title: "Gallery", action: { [weak self] in
                self?.showPhotoLibrary()
            }),
            TKPopAction.Item(title: "Camera", action: { [weak self] in
                self?.showCamera()
            }),
            TKPopAction.Item(title: "Audio recording", action: { [weak self] in
                self?.showAudioRecording()
            }),
            TKPopAction.Item(title: "Shared link", action: { [weak self] in
                guard let self = self else { return }
                TKPopAction.showAddMaterials(target: self, type: .link, folder: self.currentFolder, confirmAction: {
                    EventBus.send(key: .refreshMaterials)
                })
            }),
            TKPopAction.Item(title: "Upload from computer", action: { [weak self] in
                self?.onUploadFromComputerTapped()
            }),
            TKPopAction.Item(title: "Google Drive", action: { [weak self] in
                self?.onGoogleDriveTapped()
            }),
            TKPopAction.Item(title: "Google Photo", action: { [weak self] in
                self?.onGooglePhotoTapped()
            }),
            isCancelShow: true, target: self)
    }

    private func onGooglePhotoTapped() {
        var refIds: [String] = []
        data.forEach { id in
            if let itemData = self.dataSource[id] {
                if itemData.refId != "" {
                    refIds.append(itemData.refId)
                }
            }
        }
        let controller = MaterialsGooglePhotoViewController(excludeFiles: data + refIds)
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }

    private func onGoogleDriveTapped() {
        var refIds: [String] = []
        data.forEach { id in
            if let itemData = self.dataSource[id] {
                if itemData.refId != "" {
                    refIds.append(itemData.refId)
                }
            }
        }
        let controller = MaterialsGoogleDriveViewController(excludeFiles: data + refIds)
        controller.delegate = self
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

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

    private func onDeleteButtonTapped() {
        // 获取所有被选中的cell
        refreshViewAndChangeEdit()
        homeCollectionView.reloadData()
        folderCollectionViews.forEach({ $0.reloadData() })
//        var ids: [String] = []
//        var inFolders: [String: [String]] = [:]
//        for item in data.enumerated().reversed() {
//            if let data = dataSource[item.element] {
//                if data.type == .folder {
//                    let inFoldersIds: [String] = data.materials.filter({ $0._isSelected }).compactMap { $0.id }
//                    if inFoldersIds.count > 0 {
//                        inFolders[data.id] = inFoldersIds
//                    }
//                }
//                if data._isSelected {
//                    ids.append(item.element)
//                }
//            }
//        }
//        dataSource.forEach { _, item in
//            if item._isSelected {
//                item._isSelected = false
//            }
//        }
//        currentFolder?.materials.forEach({ item in
//            if item._isSelected {
//                item._isSelected = false
//            }
//        })
        var selectedItems: [TKMaterial] = []
        dataSource.forEach { _, item in
            if item._isSelected {
                selectedItems.append(item)
                item._isSelected = false
            }
        }
        let folders = selectedItems.filter({ $0.type == .folder }).compactMap({ $0.id })
        selectedItems.removeElements({ folders.contains($0.folder) })
        logger.debug("选择的项目: \(selectedItems.toJSONString() ?? "")")
        SL.Alert.show(target: self, title: "", message: TipMsg.deleteMaterialTip, leftButttonString: "DELETE", rightButtonString: "GO BACK", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
//            self?.deleteMaterials(ids: ids, inFolders: inFolders)
            self?.deleteMaterialsV2(selectedItems)
        }) {
        }
    }

    private func onShareButtonTapped() {
        refreshViewAndChangeEdit()
        var selectData: [TKMaterial] = []
        var defStudentIds: [String] = []
//        if let folder = currentFolder {
//            selectData += folder.materials.filter { $0._isSelected }
//            for item in selectData {
//                defStudentIds += item.studentIds
//            }
//            logger.debug("材料分享 => 当前是在文件夹里,分享的材料id有: \(selectData.compactMap { $0.id })")
//        } else {
//            for item in data {
//                if let itemData = dataSource[item] {
//                    if itemData._isSelected {
//                        defStudentIds += itemData.studentIds
//                        selectData.append(itemData)
//                    }
//                }
//            }
//        }
//        dataSource.forEach { _, item in
//            if item._isSelected {
//                item._isSelected = false
//            }
//        }
//        currentFolder?.materials.forEach({ item in
//            if item._isSelected {
//                item._isSelected = false
//            }
//        })

        selectData = dataSource.values.filter({ $0._isSelected })
        // 获取当前的目录下的所有顶层目录,获取里面的所有学生Id
        for folderCollectionView in folderCollectionViews {
            if let folder = dataSource[folderCollectionView.materialsId] {
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
        controller.delegate = self
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
        if currentFolder != nil {
            logger.debug("文件分享 => 当前在文件夹里了")
            let folderIds = folderCollectionViews.map { $0.materialsId }
            var allStudentsMap: [String: [String]] = [:]
            for folderId in folderIds {
                allStudentsMap[folderId] = dataSource[folderId]?.studentIds ?? []
            }
            let allStudentsIdsList = dataSource.values.compactMap({ $0.studentIds })
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
                        let folders = dataSource.values.filter({ folderIds.contains($0.id) })
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
            }
            .catch { error in
                TKToast.show(msg: TipMsg.shareFailed, style: .error)
                logger.debug("分享失败: \(error)")
            }
    }

    private func onMoveButtonTapped() {
        refreshViewAndChangeEdit()
        var selectedItems: [TKMaterial] = []
        dataSource.forEach { _, item in
            if item._isSelected {
                selectedItems.append(item)
                item._isSelected = false
            }
        }
        // 判断如果选择了folder,那folder下所有的文件都取消选择,需要测试
        logger.debug("一开始选择的项目: \(selectedItems.toJSONString() ?? "")")
        let folders = selectedItems.filter({ $0.type == .folder }).compactMap({ $0.id })
        selectedItems.removeElements({ folders.contains($0.folder) })
        logger.debug("选择的项目: \(selectedItems.toJSONString() ?? "")")
        showMoveToController(selectedItems: selectedItems)
        homeCollectionView.reloadData()
        folderCollectionViews.forEach({ $0.reloadData() })
    }

    private func resetAllSelectedData() {
        dataSource.forEach { _, item in
            item._isSelected = false
        }
    }
}

extension Materials2ViewController: MaterialsGooglePhotoViewControllerDelegate {
    func materialsGooglePhotoViewController(uploadFiles: [GooglePhotoMediaItem]) {
        guard uploadFiles.count > 0 else { return }
//        showFullScreenLoadingNoAutoHide()
        logger.debug("要上传的文件: \(uploadFiles.toJSONString() ?? "")")
        let uid = UserService.user.id() ?? ""
        let now = Date()
        var files: [TKMaterial] = []
        let folderId: String
        if let currentFolder = currentFolder {
            folderId = currentFolder.id
        } else {
            folderId = ""
        }
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
            }
            .catch { [weak self] _ in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                TKToast.show(msg: "Upload materials failed, please try again later.", style: .error)
            }
//        uploadFilesFromGoogle(files: files)
    }

    private func uploadFilesFromGoogle(files: [TKMaterial]) {
        // 唤起选择文件夹
        let controller = MaterialMoveToFolderSelectorViewController(uploadItems: files)
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }
}

extension Materials2ViewController: MaterialsGoogleDriveViewControllerDelegate {
    func materialsGoogleDriveViewController(predownloadFilesDone files: [GoogleDriveMaterialPredownloadModel]) {
        logger.debug("准备上传的所有文件: \(files.compactMap { $0.file }.toJSONString() ?? "")")
        let folderId: String
        if let currentFolder = currentFolder {
            folderId = currentFolder.id
        } else {
            folderId = ""
        }
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

// MARK: - Data

extension Materials2ViewController {
    override func initData() {
        super.initData()
        logger.debug("加载数据")
        switch type {
        case .homepage, .share:
            initTeacherInfo()
        default:
            break
        }
        initListener()
        reloadHomeData()
    }

    private func initTeacherInfo() {
        guard let teacherId = UserService.user.id() else { return }
        UserService.teacher.getTeacher(teacherId)
            .done { [weak self] teacher in
                guard let self = self else { return }
                if let teacher = teacher {
                    self.teacherMemberLevel = teacher.memberLevelId
                    self.updateMemberView()
                    logger.debug("获取到的教师信息: \(teacher.toJSONString() ?? "")")
                }
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                self.updateMemberView()
                logger.debug("获取失败:\(error)")
            }
    }

    private func initListener() {
        switch type {
        case .homepage, .share:
            EventBus.listen(key: .teacherHomeMaterialsChanged, target: self) { [weak self] _ in
                self?.reloadHomeData()
            }
        case .student:
            EventBus.listen(key: .studentMaterialChanged, target: self) { [weak self] _ in
                self?.reloadHomeData()
            }
            EventBus.listen(key: .studentInfoChanged, target: self) { [weak self] _ in
                self?.updateInviteTeacherView()
            }

            EventBus.listen(key: .studentTeacherInfoChanged, target: self) { [weak self] _ in
                self?.updateInviteTeacherView()
            }

            EventBus.listen(key: .studentTeacherStudioChanged, target: self) { [weak self] _ in
                self?.reloadHomeData()
            }
        default:
            break
        }
    }

    private func reloadHomeData() {
        switch type {
        case .homepage, .share:
            setData(data: ListenerService.shared.studioManagerData.homeMaterials)
        case .list:
            break
        case .student:
            if ParentService.shared.isCurrentRoleParent() {
                logger.debug("家长获取students的materials")
                ParentService.shared.fetchCurrentStudentMaterials()
                    .done { [weak self] materials in
                        guard let self = self else { return }
                        logger.debug("家长获取students的materials成功： \(materials.count)")
                        self.setData(data: materials)
                        self.updateInviteTeacherView()
                    }
                    .catch { [weak self] error in
                        guard let self = self else { return }
                        logger.error("家长获取students的materials失败： \(error)")
                        self.setData(data: [])
                        self.updateInviteTeacherView()
                    }
            } else {
                setData(data: ListenerService.shared.studentData.materials)
                updateInviteTeacherView()
            }
        }
    }

    private func setData(data: [TKMaterial]) {
        logger.debug("设置数据源: \(data.count)")
        self.data.removeAll()
//        dataSource.removeAll()
        searchData.removeAll()
        searchFolderData.removeAll()
        homeCollectionView.reloadData()
        folderCollectionViews.forEach({ $0.reloadData() })
        if data.isNotEmpty {
            for item in data {
                dataSource[item.id] = item
            }
            logger.debug("设置后的dataSource: \(dataSource.values.count)")
            // 获取到所有的文件夹
            let folders = data.filter({ $0.type == .folder }).compactMap({ $0.id })
            logger.debug("设置dataSource: \(data.count)")
            // Home 文件
            self.data = data
                .filter({ $0.folder == "" })
                .compactMap { $0.id }
            logger.debug("设置dataSource: 设置后的首页数据: \(self.data)")
            // 判断是否有文件夹内的文件,但是文件夹未被分享的
            self.data += data.filter({ $0.folder != "" })
                .filter({ !folders.contains($0.folder) })
                .compactMap({ $0.id })
            logger.debug("当前过滤出来的所有文件: \(self.data)")
            self.data = self.data.sorted(by: { f1, f2 -> Bool in
                self.dataSource[f1]?.name ?? "" < self.dataSource[f2]?.name ?? ""
            })
        }
        setSutdentData()

        switch type {
        case let .share(ids):
            dataSource.forEach { _, item in
                if ids.contains(item.id) {
                    item._isSelected = true
                } else {
                    item._isSelected = false
                }
            }
            break
        default:
            break
        }
        homeCollectionView.reloadData()
        folderCollectionViews.forEach({ $0.reloadData() })
    }

    private func setSutdentData() {
        let json: String = SLCache.main.get(key: SLCache.STUDENT_LIST)
        if let studentData = [TKStudent].deserialize(from: json) as? [TKStudent] {
            for item in data.enumerated() {
                dataSource[item.element]?.studentData = []
                if let data = dataSource[item.element] {
                    for id in data.studentIds {
                        data.studentData += studentData.filter { $0.studentId == id }
                    }
//                    var files: [TKMaterial] = []
//                    if data.type == .folder {
//                        for childData in data.materials {
//                            for id in childData.studentIds {
//                                childData.studentData += studentData.filter { $0.studentId == id }
//                            }
//                            files.append(childData)
//                            dataSource[childData.id] = childData
//                        }
//                        data.materials = files
//                    }
                    dataSource[data.id] = data
                }
            }
        }
    }

    private func checkUnreadData() {
        let data: [TKMaterial] = dataSource.compactMap {
            if self.data.contains($0) {
                return $1
            } else {
                return nil
            }
        }
        let result = MaterialService.shared.newMaterials(cloudData: data)
        newMaterialsData = result.compactMap { $0.id }
        tabBarItem?.badgeColor = ColorUtil.main
        tabBarItem?.badgeValue = newMaterialsData.count > 0 ? "" : nil
    }

    func clearUnReadData() {
        newMaterialsData = []
        let data: [TKMaterial] = dataSource.compactMap {
            if self.data.contains($0) {
                return $1
            } else {
                return nil
            }
        }
        MaterialService.shared.setLocalMaterials(data)
        checkUnreadData()
    }
}

// MARK: - SearchBar Delegate

extension Materials2ViewController: TKSearchBarDelegate {
    private func search() {
        searchData = []
        searchFolderData = []
        if let folder = currentFolder {
//            searchFolderData = folder.materials.filter { $0.name.lowercased().contains(searchKey.lowercased()) }.compactMap { $0.id }
            searchFolderData = dataSource.values.filter({ $0.folder == folder.id }).filter { $0.name.lowercased().contains(searchKey.lowercased()) }.compactMap { $0.id }
        }
        searchData = dataSource.values.filter { $0.name.lowercased().contains(searchKey.lowercased()) }.compactMap { $0.id }
        homeCollectionView.reloadData()
        folderCollectionViews.forEach({ $0.reloadData() })
    }

    func tkSearchBar(textChanged searchBar: TKSearchBar, text: String) {
        searchKey = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func tkSearchBar(didClearButtonTapped searchBar: TKSearchBar, textBefore: String) {
        if textBefore == "" {
            searchBar.blur()
            searchBar.isHidden = true
        }
        searchKey = ""
    }
}

// MARK: - UICollectionViewDelegate DataSource

extension Materials2ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, CollectionViewAlignFlowLayoutDelegate {
    func sizeOfItemAt(collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        var size: CGSize = .zero
//        var data: TKMaterial?
//        if collectionView.tag == homeCollectionViewTag {
//            if searchKey == "" {
//                data = dataSource[self.data[indexPath.item]]
//            } else {
//                data = dataSource[searchData[indexPath.item]]
//            }
//        } else if collectionView.tag == folderCollectionViewTag {
//            if searchKey == "" {
//                if let folderCollectionView = folderCollectionViews.first, let folder = dataSource[folderCollectionView.materialsId] {
//                    let materials = dataSource.values.filter({ $0.folder == folder.id }).sorted(by: { $0.name < $1.name })
//                    data = materials[indexPath.item]
//                }
//            } else {
//                data = dataSource[searchFolderData[indexPath.item]]
//            }
//        }
//
//        if let data = data {
        ////            if data.type == .youtube {
        ////                if data.url.contains("youtu.be") || data.url.contains("youtube.com/watch") || data.url.contains("youtube.com/shorts") {
        ////                    // 视频
        ////                    switch type {
        ////                    case .homepage:
        ////                        size = .init(width: UIScreen.main.bounds.width - 40, height: 150 + 90 + 20)
        ////                    default:
        ////                        size = .init(width: UIScreen.main.bounds.width - 40, height: 150 + 70 + 20)
        ////                    }
        ////                } else {
        ////                    // link
        ////                    let width = (UIScreen.main.bounds.width - 50) / 3
        ////                    switch type {
        ////                    case .homepage:
        ////                        size = .init(width: width, height: width + 75 + 20)
        ////                    default:
        ////                        size = .init(width: width, height: width + 55 + 20)
        ////                    }
        ////                }
        ////            } else {
        ////                let width = (UIScreen.main.bounds.width - 50) / 3
        ////                switch type {
        ////                case .homepage:
        ////                    size = .init(width: width, height: width + 75 + 20)
        ////                default:
        ////                    size = .init(width: width, height: width + 55 + 20)
        ////                }
        ////            }
//            let width = (UIScreen.main.bounds.width - 50) / 3
//            switch type {
//            case .homepage:
//                size = .init(width: width, height: width + 75 + 20)
//            default:
//                size = .init(width: width, height: width + 55 + 20)
//            }
//        }
        let width = (UIScreen.main.bounds.width - 50) / 3
        switch type {
        case .homepage:
            size = .init(width: width, height: width + 75 + 20)
        default:
            size = .init(width: width, height: width + 55 + 20)
        }
        return size
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count: Int = 0
        switch collectionView.tag {
        case homeCollectionViewTag:
            if searchKey == "" {
                logger.debug("没有搜索,home: \(data.count)")
                count = data.count
            } else {
                logger.debug("有搜索,home: \(searchData.count)")
                count = searchData.count
            }
        case folderCollectionViewTag:
            if searchKey == "" {
                guard let folderCollectionView = collectionView as? MaterialsCollectionView, let folder = dataSource[folderCollectionView.materialsId] else {
                    return 0
                }
                count = dataSource.values.filter({ $0.folder == folder.id }).count
            } else {
                count = searchFolderData.count
            }
        default:
            break
        }
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MaterialsCell.self), for: indexPath) as! MaterialsCell
        var data: TKMaterial?
        if collectionView.tag == homeCollectionViewTag {
            if searchKey == "" {
                logger.debug("当前首页的所有数据: \(self.data) | \(dataSource.values.count)")
                data = dataSource[self.data[indexPath.item]]
            } else {
                data = dataSource[searchData[indexPath.item]]
            }
        } else if collectionView.tag == folderCollectionViewTag {
            // 当前是子文件夹,获取子文件夹id
            if let folderCollectionView = collectionView as? MaterialsCollectionView {
                if searchKey == "" {
                    let folderId = folderCollectionView.materialsId
                    // 获取所有文件中,folderId = 当前folder的文件,并且按照字母排序
                    let materials = dataSource.values.filter({ $0.folder == folderId }).sorted(by: { $0.name < $1.name })
                    logger.debug("渲染materials => 子文件夹[\(folderId)]未搜索,\(materials[indexPath.item].id)")
                    data = materials[indexPath.item]
                } else {
                    logger.debug("渲染materials => 子文件夹,已搜索: \(searchFolderData[indexPath.item])")
                    data = dataSource[searchFolderData[indexPath.item]]
                }
            }
        }

        cell.tag = indexPath.row
        if let data = data {
            var showAvatar: Bool = false
            var onlyShare: Bool = false
            switch type {
            case .homepage:
                showAvatar = true
            case .student:
                onlyShare = false
            default:
                break
            }
            cell.cellInitialSize = otherCellSize
//            cell.cellInitialSize = data.type == .youtube ? youtubeCellSize : otherCellSize
            cell.edit(isEdit)
            logger.debug("当前渲染的文件数据: \(data.id) | \(data.name) | \(data.studentIds)")
            cell.initData(materialsData: data, isShowStudentAvatarView: showAvatar, isMainMaterial: showAvatar, searchKey: searchKey, onlyShare: onlyShare)
            if data.type == .folder {
                // 判断是否子文件
                if !dataSource.values.filter({ $0.folder == data.id }).isEmpty {
                    cell.typeImageView.image = UIImage(named: "folder")!.resizeImage(CGSize(width: 48, height: 48))
                }
            }
        } else {
            logger.debug("当前未获取到要渲染的数据")
        }
        cell.backView.backgroundColor = collectionView.backgroundColor
        cell.delegate = self
        cell.border(show: false)
        return cell
    }
}

// MARK: - Drop Drag

extension Materials2ViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard !isEdit else { return [] }
        if collectionView.tag == homeCollectionViewTag {
            switch type {
            case .homepage, .student:
                guard data.isSafeIndex(indexPath.row) else {
                    logger.debug("MaterialsViewController移动cell,index错误: indexPath: \(indexPath) | 所有数据: \(data)")
                    return []
                }
                let item = data[indexPath.row]
                let itemProvider = NSItemProvider(object: item as NSString)
                let dragItem = UIDragItem(itemProvider: itemProvider)
                dragItem.localObject = item
                return [dragItem]
            default:
                return []
            }
        } else {
            guard let folderCollectionView = collectionView as? MaterialsCollectionView else { return [] }
            let folderId = folderCollectionView.materialsId
            let data = dataSource.values.filter({ $0.folder == folderId }).sorted(by: { $0.name < $1.name })
            guard data.isSafeIndex(indexPath.row) else {
                logger.debug("MaterialsViewController移动cell,index错误: indexPath: \(indexPath) | 所有数据: \(data.compactMap({ $0.id }))")
                return []
            }
            let item = data[indexPath.row].id
            let itemProvider = NSItemProvider(object: item as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            return [dragItem]
        }
    }

    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        guard !isEdit else { return [] }
        if collectionView.tag == homeCollectionViewTag {
            switch type {
            case .homepage, .student:
                guard data.isSafeIndex(indexPath.row) else {
                    logger.debug("MaterialsViewController移动cell,index错误: indexPath: \(indexPath) | 所有数据: \(data)")
                    return []
                }
                let item = data[indexPath.row]
                let itemProvider = NSItemProvider(object: item as NSString)
                let dragItem = UIDragItem(itemProvider: itemProvider)
                dragItem.localObject = item
                return [dragItem]
            default:
                return []
            }
        } else {
            guard let folderCollectionView = collectionView as? MaterialsCollectionView else { return [] }
            let folderId = folderCollectionView.materialsId
            let data = dataSource.values.filter({ $0.folder == folderId }).sorted(by: { $0.name < $1.name })
            guard data.isSafeIndex(indexPath.row) else {
                logger.debug("MaterialsViewController移动cell,index错误: indexPath: \(indexPath) | 所有数据: \(data.compactMap({ $0.id }))")
                return []
            }
            let item = data[indexPath.row].id
            let itemProvider = NSItemProvider(object: item as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            return [dragItem]
        }
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let previewParameters = UIDragPreviewParameters()
        let width = (UIScreen.main.bounds.width - 50) / 3
        let size: CGSize = CGSize(width: width, height: width)
        previewParameters.visiblePath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return previewParameters
    }
}

extension Materials2ViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        logger.debug("完全释放")
        for item in data.enumerated() {
            if let cell = collectionView.cellForItem(at: IndexPath(item: item.offset, section: 0)) as? MaterialsCell {
                cell.border(show: false)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let indexPath = destinationIndexPath {
            // 判断当前的位置,如果当前的位置和自己是一个,那则返回
            if let item = session.items.first {
                if let value = item.localObject as? String {
                    // 判断当前文件是不是自己创建的
                    if let itemData = dataSource[value] {
                        if !itemData.isOwnMaterials {
                            return UICollectionViewDropProposal(operation: .forbidden)
                        }
                    }
                    var dataList: [String] = []
                    if collectionView.tag == homeCollectionViewTag {
                        dataList = data
                    } else {
                        guard let folderCollectionView = collectionView as? MaterialsCollectionView else { return UICollectionViewDropProposal(operation: .forbidden) }
                        let folderId = folderCollectionView.materialsId
                        dataList = dataSource.values.filter({ $0.folder == folderId }).sorted(by: { $0.name < $1.name }).compactMap({ $0.id })
                    }
                    if value != dataList[indexPath.item] {
                        // 当前覆盖的不是自己,判断是不是文件夹
                        if let destData = dataSource[dataList[indexPath.item]], let selfData = dataSource[value] {
                            // 目标是文件夹 -> 移动到文件夹内
                            // 自己是文件,目标是文件 -> 合并,并创建文件夹
                            for (i, _) in dataList.enumerated() {
                                if let cell = collectionView.cellForItem(at: IndexPath(item: i, section: 0)) as? MaterialsCell {
                                    if i != indexPath.item {
                                        cell.border(show: false)
                                    } else {
                                        cell.border(show: true)
                                    }
                                }
                            }
                            if destData.type == .folder {
                                guard destData.isOwnMaterials && selfData.isOwnMaterials else {
                                    return UICollectionViewDropProposal(operation: .forbidden)
                                }
                                return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
                            } else {
                                // 目标是文件
                                if selfData.type == .folder {
                                    return UICollectionViewDropProposal(operation: .cancel)
                                } else {
                                    // 自己是文件,合并并创建文件夹
                                    return UICollectionViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
                                }
                            }
                        }
                    }
                }
            }
        }
        return UICollectionViewDropProposal(operation: .cancel)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            // Get last index path of table view.
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        let dataList: [String]
        if collectionView.tag == homeCollectionViewTag {
            dataList = data
        } else {
            guard let folderCollectionView = collectionView as? MaterialsCollectionView else { return }
            let folderId = folderCollectionView.materialsId
            dataList = dataSource.values.filter({ $0.folder == folderId }).sorted(by: { $0.name < $1.name }).compactMap({ $0.id })
        }
        guard let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath else { return }
        guard let destData = dataSource[dataList[destinationIndexPath.item]], let sourceData = dataSource[dataList[sourceIndexPath.item]] else { return }
        switch coordinator.proposal.operation {
        case .move:
//            reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
            // 移动文件
            guard destData.type == .folder else { return }
            moveToFolder(items: [sourceData], folder: destData)
            break
        case .copy:
            // 合并到新文件夹内
//            copyItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
            mergeAndCreateNewFolder(items: [destData, sourceData])
            break
        default:
            return
        }
    }

    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        let items = coordinator.items
        if items.count == 1, let item = items.first, let sourceIndexPath = item.sourceIndexPath {
            var dIndexPath = destinationIndexPath
            if dIndexPath.row >= collectionView.numberOfItems(inSection: 0) {
                dIndexPath.row = collectionView.numberOfItems(inSection: 0) - 1
            }
            collectionView.performBatchUpdates({
                // MARK: - 要进行判断的地方

                self.data.remove(at: sourceIndexPath.row)
                self.data.insert(item.dragItem.localObject as! String, at: dIndexPath.row)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [dIndexPath])
            })
            coordinator.drop(items.first!.dragItem, toItemAt: dIndexPath)
        }
    }

    private func copyItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        collectionView.performBatchUpdates({
            guard let itemData = dataSource[data[destinationIndexPath.item]] else { return }
            // 判断目标是否是文件夹
            if itemData.type == .folder {
                var add: [TKMaterial] = []
                for item in coordinator.items {
                    if let id = item.dragItem.localObject as? String, let _itemData = dataSource[id] {
                        // 将当前的item添加的文件夹里去
                        add.append(_itemData)
                    }
                }
                // move
                moveToFolder(items: add, folder: itemData)
            } else {
                // 判断当前的是自己是文件还是文件夹
                if let item = coordinator.items.first {
                    if let id = item.dragItem.localObject as? String, let _itemData = dataSource[id] {
                        if _itemData.type != .folder {
                            // 当前和目标都是文件,进行文件夹创建,先创建文件夹,然后唤起改名的弹窗
                            mergeAndCreateNewFolder(items: [itemData, _itemData])
                        }
                    }
                }
            }
        })
    }
}

// MARK: - Materials Cell Delegate

extension Materials2ViewController: MaterialsCellDelegate {
    func clickItem(materialsData: TKMaterial, cell: MaterialsCell) {
        logger.debug("点击材料: \(materialsData.toJSONString() ?? "")")
        view.endEditing(true)
        if !isEdit {
            if materialsData.type != .folder {
                logger.debug("进入点击状态")
                MaterialsHelper.cellClick(materialsData: materialsData, cell: cell, mController: self)
            } else {
                addFolderCollectionView(materialsData)
//                currentFolder = materialsData
                searchKey = ""
                searchData = []
                searchBar.isHidden = true
//                reloadCollectionView(cell: cell)
//                showFolder(fromCell: cell)
                showFolder()
            }
        } else {
            switch type {
            case .homepage, .student:
                logger.debug("选择文件")
//                if let folder = currentFolder {
//                    // 当前在文件夹内
//                    for item in folder.materials.enumerated() {
//                        if item.element.id == materialsData.id {
//                            folder.materials[item.offset]._isSelected = materialsData._isSelected
//                            break
//                        }
//                    }
//                }
//                let folderId: String = materialsData.folder
//                logger.debug("选择的文件所属文件夹: \(folderId) | \(materialsData.toJSONString() ?? "")")
//                if folderId != "" {
//                    var indexPaths: [IndexPath] = []
//                    for item in data.enumerated() {
//                        if item.element == folderId {
//                            indexPaths.append(IndexPath(item: item.offset, section: 0))
//                        }
//                    }
//
//                    homeCollectionView.reloadItems(at: indexPaths)
//                }
                let countOfSelected = dataSource.filter { $0.value._isSelected }.count
                let isSelected = countOfSelected > 0
                deleteButton.titleColor(isSelected ? ColorUtil.blush : ColorUtil.Font.fourth)
                shareButton.titleColor(isSelected ? ColorUtil.main : ColorUtil.Font.fourth)
                moveButton.titleColor(isSelected ? ColorUtil.main : ColorUtil.Font.fourth)
                deleteButton.isEnabled = isSelected
                shareButton.isEnabled = isSelected
                moveButton.isEnabled = isSelected

//                cell.cellInitialSize = materialsData.type == .youtube ? youtubeCellSize : otherCellSize
                cell.cellInitialSize = otherCellSize
                cell.edit(isEdit)
                var showAvatar: Bool = false
                switch type {
                case .homepage:
                    showAvatar = true
                default:
                    break
                }
                if materialsData.type == .folder {
                    cell.backView.backgroundColor = homeCollectionView.backgroundColor
                } else {
                    if currentFolder != nil {
                        cell.backView.backgroundColor = homeCollectionView.backgroundColor
                    } else {
                        cell.backView.backgroundColor = homeCollectionView.backgroundColor
                    }
                }
                cell.initData(materialsData: materialsData, isShowStudentAvatarView: showAvatar, isMainMaterial: showAvatar, searchKey: searchKey)
            case .share:
                if materialsData.type == .folder {
                    materialsData._isSelected.toggle()
                    addFolderCollectionView(materialsData)
                    searchKey = ""
                    searchData = []
                    searchBar.isHidden = true
                    showFolder()
                } else {
                    if currentFolder != nil {
//                        folderCollectionView.reloadItems(at: [IndexPath(item: cell.tag, section: 0)])
                        if let cell = folderCollectionViews.first?.cellForItem(at: IndexPath(item: cell.tag, section: 0)) as? MaterialsCell {
                            cell.updateCheckBox()
                        }
                    }
                    if let cell = homeCollectionView.cellForItem(at: IndexPath(item: cell.tag, section: 0)) as? MaterialsCell {
                        cell.updateCheckBox()
                    }
//                    homeCollectionView.reloadItems(at: [IndexPath(item: cell.tag, section: 0)])
//                    let folderId: String = materialsData.folder
//                    if folderId != "" {
//                        var indexPaths: [IndexPath] = []
//                        for item in data.enumerated() {
//                            if item.element == folderId {
//                                indexPaths.append(IndexPath(item: item.offset, section: 0))
//                                if let folder = dataSource[item.element] {
//                                    if folder.materials.filter({ $0._isSelected }).count == folder.materials.count {
//                                        folder._isSelected = true
//                                    } else {
//                                        folder._isSelected = false
//                                    }
//                                }
//                            }
//                        }
//                        for indexPath in indexPaths {
//                            if let cell = homeCollectionView.cellForItem(at: indexPath) as? MaterialsCell {
//                                cell.updateCheckBox()
//                            }
//                        }
                    ////                        homeCollectionView.reloadItems(at: indexPaths)
//                    }
                }
            default:
                break
            }
        }
    }

    func materialsCell(checkBoxDidTappedAt index: Int, materialsData: TKMaterial, cell: MaterialsCell) {
        logger.debug("点击checkBox: \(materialsData._isSelected)")
        guard let item = dataSource[materialsData.id] else {
            return
        }
        logger.debug("选择文件")
        item._isSelected = materialsData._isSelected
        if let cell = homeCollectionView.cellForItem(at: IndexPath(item: cell.tag, section: 0)) as? MaterialsCell {
            cell.updateCheckBox()
        }
//        if item.type == .folder {
        ////            item.materials.forEach { $0._isSelected = materialsData._isSelected }
//            if let cell = homeCollectionView.cellForItem(at: IndexPath(item: cell.tag, section: 0)) as? MaterialsCell {
//                cell.updateCheckBox()
//            }
//        } else {
//            item._isSelected = materialsData._isSelected
//            if let cell = homeCollectionView.cellForItem(at: IndexPath(item: cell.tag, section: 0)) as? MaterialsCell {
//                cell.updateCheckBox()
//            }
        ////            if let folder = currentFolder {
        ////                // 当前在文件夹内
        ////                for item in folder.materials.enumerated() {
        ////                    if item.element.id == materialsData.id {
        ////                        folder.materials[item.offset]._isSelected = materialsData._isSelected
        ////                        break
        ////                    }
        ////                }
        ////            }
        ////            let folderId: String = materialsData.folder
        ////            logger.debug("点击的文件所属文件夹: \(folderId)")
        ////            if folderId != "" {
        ////                var indexPaths: [IndexPath] = []
        ////                for item in data.enumerated() {
        ////                    if item.element == folderId {
        ////                        indexPaths.append(IndexPath(item: item.offset, section: 0))
        ////                        if let folder = dataSource[item.element] {
        ////                            if folder.materials.filter({ $0._isSelected }).count == folder.materials.count {
        ////                                folder._isSelected = true
        ////                            } else {
        ////                                folder._isSelected = false
        ////                            }
        ////                        }
        ////                    }
        ////                }
        ////                logger.debug("重新加载folder: \(folderId) | \(indexPaths)")
        ////                for indexPath in indexPaths {
        ////                    if let cell = homeCollectionView.cellForItem(at: indexPath) as? MaterialsCell {
        ////                        cell.updateCheckBox()
        ////                    }
        ////                }
        ////            } else {
        ////                if let cell = homeCollectionView.cellForItem(at: IndexPath(item: cell.tag, section: 0)) as? MaterialsCell {
        ////                    cell.updateCheckBox()
        ////                }
        ////            }
//        }

        let isSelected = dataSource.filter { $0.value._isSelected }.count > 0
        deleteButton.titleColor(isSelected ? ColorUtil.blush : ColorUtil.Font.fourth)
        shareButton.titleColor(isSelected ? ColorUtil.main : ColorUtil.Font.fourth)
        moveButton.titleColor(isSelected ? ColorUtil.main : ColorUtil.Font.fourth)
        deleteButton.isEnabled = isSelected
        shareButton.isEnabled = isSelected
        moveButton.isEnabled = isSelected
        if currentFolder != nil {
//            folderCollectionView.reloadItems(at: [IndexPath(item: cell.tag, section: 0)])
            if let cell = folderCollectionViews.first?.cellForItem(at: IndexPath(item: cell.tag, section: 0)) as? MaterialsCell {
                cell.itemData = materialsData
                cell.updateCheckBox()
            }
        }
    }

    func materialsCell(shareButtonTappedAt index: Int, cell: MaterialsCell) {
        logger.debug("点击分享: \(index)")
        switch type {
        case .homepage:
//            var data: TKMaterial?
//            logger.debug("主页面,判断当前是处于folder里还是folder外")
//            if let folder = currentFolder {
//                logger.debug("folder里")
//                if searchKey == "" {
//                    logger.debug("搜索为空")
//                    guard folder.materials.isSafeIndex(index) else { return }
//                    data = folder.materials[index]
//                } else {
//                    logger.debug("搜索不为空: \(searchData.count)")
//                    guard searchFolderData.isSafeIndex(index) else { return }
//                    data = dataSource[searchFolderData[index]]
//                }
//            } else {
//                if searchKey == "" {
//                    guard self.data.isSafeIndex(index) else { return }
//                    data = dataSource[self.data[index]]
//                } else {
//                    guard searchData.isSafeIndex(index) else { return }
//                    data = dataSource[searchData[index]]
//                }
//            }

            guard let itemData = cell.itemData else { return }
            // 进入分享页
            let controller = AddressBookViewController()
            controller.delegate = self
            controller.showType = .appContact
            controller.hero.isEnabled = true
            controller.isShowSelectAll = true
            controller.isShowAllStudent = true
            controller.materials = [itemData]
            controller.defaultIds = itemData.studentIds
            controller.from = .materials
            controller.modalPresentationStyle = .fullScreen
            controller.enablePanToDismiss()
            controller.hero.modalAnimationType = .selectBy(presenting: .pageIn(direction: .up), dismissing: .pageOut(direction: .down))
            present(controller, animated: true, completion: nil)
            controller.onStudentSelected = { [weak self] selectedStudentIds in
                guard let self = self else { return }
                logger.debug("是否是静音的: \(controller.isShareSilently)")
                self.shareMaterials(materials: [itemData], selectedStudentIds: selectedStudentIds, defaultStudentIds: itemData.studentIds, sendEmail: !controller.isShareSilently)
            }
        case .student:
            logger.debug("点击分享到外面")
            break
        default:
            break
        }
    }

    func materialsCell(titleLabelDidSelectedAt index: Int, cell: MaterialsCell) {
        logger.debug("点击标题: \(index)")
        var data: TKMaterial?
        if let folderCollectionView = folderCollectionViews.first {
            let folderId = folderCollectionView.materialsId
            if searchKey == "" {
//                guard folder.materials.isSafeIndex(index) else { return }
                let dataList = dataSource.values.filter({ $0.folder == folderId }).sorted(by: { $0.name < $1.name })
                guard dataList.isSafeIndex(index) else { return }
                data = dataList[index]
            } else {
                guard searchFolderData.isSafeIndex(index) else { return }
                data = dataSource[searchFolderData[index]]
            }
        } else {
            if searchKey == "" {
                guard self.data.isSafeIndex(index) else { return }
                data = dataSource[self.data[index]]
            } else {
                guard searchData.isSafeIndex(index) else { return }
                data = dataSource[searchData[index]]
            }
        }
        guard let itemData = data, itemData.isOwnMaterials else { return }
        let controller = UpdateMaterialsTitleViewController()
        controller.id = itemData.id
        controller.defaultTitle = itemData.name
        controller.delegate = self
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }
}

extension Materials2ViewController: AddressBookViewControllerDelegate {
    func addressBookViewController(_ controller: AddressBookViewController, backTappedWithId id: String) {
    }

    func addressBookViewController(_ controller: AddressBookViewController, selectedLocalContacts: [LocalContact], userInfo: [String: Any]) {
    }
}

extension Materials2ViewController: UpdateMaterialsTitleViewControllerDelegate {
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
                }
            }
    }
}

extension Materials2ViewController: GalleryControllerDelegate {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        controller.dismiss(animated: true, completion: nil)
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
                        TKPopAction.showAddMaterials(target: self, type: .image, image: image, imageUrl: url, folder: self.currentFolder) {
                            EventBus.send(key: .refreshMaterials)
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
        showFullScreenLoadingNoAutoHide()
        video.asset.getURL { [weak self] url in
            guard let self = self, let url = url, let hashCode = FileUtil.shared.getHashCode(url: url) else { return }
            DispatchQueue.main.async {
                self.hideFullScreenLoading()
                DispatchQueue.main.async {
                    logger.debug("获取到的HashCode: \(hashCode)")
                    TKPopAction.showAddMaterials(target: self, type: .video, vidioUrl: url, folder: self.currentFolder) {
                        logger.debug("======上传成功")
                        EventBus.send(key: .refreshMaterials)
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

extension Materials2ViewController {
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
                    let controller = VideoRecorderViewController()
                    controller.onRecordCompletion = { data in
                        TKPopAction.showAddMaterials(target: self, type: .video, vidioUrl: data.compressedURL, fileId: data.id, folder: self.currentFolder) {
                            logger.debug("======上传成功")
                            EventBus.send(key: .refreshMaterials)
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
                                MaterialService.shared.addMaterials(materialData: data!, hashData: _hashData, currentFolder: self.currentFolder)
                                    .done { _ in
                                        self.hideFullScreenLoading()
                                        TKToast.show(msg: "Successfully.", style: .success)
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
                        MaterialService.shared.addMaterials(materialData: data!, hashData: _hashData, currentFolder: self.currentFolder)
                            .done { _ in
                                self.hideFullScreenLoading()
                                TKToast.show(msg: "Successfully.", style: .success)
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
//            TKPopAction.showAddMaterials(target: self, type: .audio, image: UIImage(named: "imgMp3")!, vidioUrl: nil, fileData: fileData, filePath: path, fileTitle: title, fileId: id, folder: currentFolder) {
//                EventBus.send(key: .refreshMaterials)
//            }
        } catch {
            print("走到了catch")
            hideFullScreenLoading()
            TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
        }
    }
}

extension Materials2ViewController {
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
                }
            }
    }

    func deleteMaterials(ids: [String], inFolders: [String: [String]]) {
        logger.debug("需要删除的材料id: \(ids) | 要文件夹里要删除的: \(inFolders.compactMap { ($0, $1) })")
        showFullScreenLoadingNoAutoHide()
        Firestore.firestore().runTransaction { transaction, pointer -> Any? in
            // 当前是进入文件夹的状态
            let collRef = DatabaseService.collections.material()

            var updateFolder: [TKMaterial] = []
            var deleteFile: [String] = []

            for (folderId, itemIds) in inFolders {
                do {
                    let doc = try transaction.getDocument(collRef.document(folderId))
                    // 删除子文件的文件夹数据更新
                    if let folder = TKMaterial.deserialize(from: doc.data()) {
                        itemIds.forEach { id in
                            folder.materials.removeElements { id == $0.id }
                        }
                        updateFolder.append(folder)
                    }
                    // 直接删除的子文件
                    deleteFile += itemIds
                } catch {
                    pointer?.pointee = error as NSError
                    return nil
                }
            }
            // 判断当前的文件是否是文件夹,如果是,则需要删除子文件
            for id in ids {
                do {
                    let doc = try transaction.getDocument(collRef.document(id))
                    if let data = TKMaterial.deserialize(from: doc.data()) {
                        // 当前是文件夹,删除子文件
                        if data.type == .folder {
                            deleteFile += data.materials.compactMap { $0.id }
                        }
                        // 删除自己
                        deleteFile.append(id)
                    }
                } catch {
                    pointer?.pointee = error as NSError
                    return nil
                }
            }

            logger.debug("要更新的文件夹信息: \(updateFolder.toJSONString() ?? "") | 要删除的文件: \(deleteFile)")

            for folder in updateFolder {
                transaction.updateData(folder.toJSON() ?? [:], forDocument: collRef.document(folder.id))
            }

            for id in deleteFile {
                transaction.deleteDocument(collRef.document(id))
            }
            return nil
        } completion: { [weak self] _, error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let error = error {
                logger.error("删除失败: \(error)")
                TKToast.show(msg: TipMsg.deleteFailed, style: .error)
            } else {
                TKToast.show(msg: "Delete materials successful", style: .success)
            }
        }
    }

    private func showMoveToController(selectedItems: [TKMaterial]) {
//        let controller = MaterialMoveToFolderSelectorViewController(selectedItems: selectedItems, excludeFolder: currentFolder)
//        controller.modalPresentationStyle = .custom
//        present(controller, animated: false, completion: nil)
        // 文件夹选择
        guard let currentRole = ListenerService.shared.currentRole else { return }
        var data: [TKMaterial]
        switch currentRole {
        case .teacher:
            data = ListenerService.shared.teacherData.homeMaterials
        case .student:
            data = ListenerService.shared.studentData.materials
        default:
            return
        }
        var currentFolderId: String = ""
        if let currentFolder = currentFolder {
            currentFolderId = currentFolder.id
        }
        logger.debug("准备移动的项目: \(selectedItems.toJSONString() ?? "")")
        let controller = MaterialsFolderSelectorViewController(data)
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
        showFullScreenLoadingNoAutoHide()
        logger.debug("要移动的项目: \(items.toJSONString() ?? ""), 目标: \(folder?.id ?? "Home")")
        MaterialService.shared.moveToFolderV2(items: items, moveTo: folder) { [weak self] error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let error = error {
                logger.error("Move failed: \(error)")
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
        let folderId: String
        if let currentFolder = currentFolder {
            folderId = currentFolder.id
        } else {
            folderId = ""
        }
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
            }
        }
    }
}

// MARK: - 点击Material

extension Materials2ViewController {
    private func clickMaterial(_ data: TKMaterial, cell: MaterialsCell) {
    }
}

// MARK: - 点击Material -> Video

extension Materials2ViewController {
    private func clickVideo(data: TKMaterial) {
        let w: CGFloat = UIScreen.main.bounds.width
        let h: CGFloat = w * 9 / 16
        let y: CGFloat = UIScreen.main.bounds.height / 2 - (h / 2)

        let imageView = UIImageView(frame: CGRect(x: 0, y: y, width: w, height: h))
        imageView.setImageForUrl(imageUrl: data.minPictureUrl, placeholderImage: ImageUtil.getImage(color: ColorUtil.imagePlaceholderDark))
        imageView.heroID = data.minPictureUrl
        imageView.contentMode = .scaleAspectFill
        guard let videoURL = URL(string: data.url) else { return }
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.contentOverlayView?.addSubview(imageView)

        playerViewController.hero.isEnabled = true
        playerViewController.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(playerViewController, animated: true) {
            playerViewController.player?.play()
            let appdelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.isForceAllDerictions = true
            SL.Executor.runAsyncAfter(time: 1) {
                SL.Animator.run(time: 0.5, animation: {
                    imageView.alpha = 0
                }) { isDone in
                    print("=======\(isDone)")
                    //                        imageView.isHidden = true
                }
            }
        }
    }
}

// MARK: - 点击Material -> YouTube

extension Materials2ViewController {
    private func clickYoutube(_ data: TKMaterial) {
        if Tools.extractYouTubeId(from: data.url) != nil {
            clickYoutube(materialsData: data)
        } else {
            clickLink(link: data.url)
        }
    }

    private func clickYoutube(materialsData: TKMaterial) {
        let controller = YoutubePlayerViewController()
        controller.materialsData = materialsData
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true)
    }
}

// MARK: - 点击Material -> Image

extension Materials2ViewController {
    private func clickImage(img: String, title: String) {
        let controller = PreviewViewController(image: img)
        controller.hero.isEnabled = true
        controller.titleString = title
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .fade, dismissing: .fade)
        present(controller, animated: true)
    }
}

// MARK: - 点击Material -> Link

extension Materials2ViewController {
    private func clickLink(link: String) {
        var link = link
        if !link.contains("http") {
            link = "http://\(link)"
        }
        if let url = URL(string: link) {
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
    }
}

// MARK: - 点击Material -> PDF

extension Materials2ViewController {
    private func clickPDF(mController: UIViewController, link: String) {
        logger.debug("点击PDF：\(link)")
        let remotePDFDocumentURLPath = link
        if let remotePDFDocumentURL = URL(string: remotePDFDocumentURLPath), let doc = document(remotePDFDocumentURL) {
            let image = UIImage(named: "")
            let controller = PDFViewController.createNew(with: doc, title: "", actionButtonImage: image, actionStyle: .activitySheet)
            controller.hero.isEnabled = true
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            mController.present(controller, animated: true, completion: nil)
        } else {
            print("Document named \(remotePDFDocumentURLPath) not found")
        }
    }

    /// Initializes a document with the name of the pdf in the file system
    private func document(_ name: String) -> PDFDocument? {
        guard let documentURL = Bundle.main.url(forResource: name, withExtension: "pdf") else { return nil }
        return PDFDocument(url: documentURL)
    }

    /// Initializes a document with the data of the pdf
    private func document(_ data: Data) -> PDFDocument? {
        return PDFDocument(fileData: data, fileName: "Sample PDF")
    }

    /// Initializes a document with the remote url of the pdf
    private func document(_ remoteURL: URL) -> PDFDocument? {
        return PDFDocument(url: remoteURL)
    }
}

extension Materials2ViewController: SInviteTeacherViewControllerDelegate {
    func sInviteTeacherViewControllerDismissed() {
    }

    func toInviteTeacher() {
        let controller = SInviteTeacherViewController()
        controller.delegate = self
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }
}

extension Materials2ViewController {
    private func makeFolderCollectionView() -> MaterialsCollectionView {
        MaterialsCollectionView(frame: .zero, collectionViewLayout: {
            let layout = CollectionViewAlignFlowLayout()
            layout.layoutDelegate = self
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 5
            layout.scrollDirection = .vertical
            return layout
        }())
    }
}

class MaterialsCollectionView: UICollectionView {
    var materialsId: String = ""
}

extension Materials2ViewController {
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
                }
            }
    }
}
