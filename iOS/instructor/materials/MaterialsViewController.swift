//
//  MaterialsViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/5.
//  Copyright © 2019年 spelist. All rights reserved.
//

import AVFoundation
import AVKit
import FirebaseFirestore
import Lottie
import MediaPlayer
import NVActivityIndicatorView
import PromiseKit
import StreamingKit
import UIKit

protocol MaterialsViewControllerListDelegate: NSObjectProtocol {
    func materialsViewController(selectData: [TKMaterial])
}

class MaterialsViewController: TKBaseViewController {
    enum Style {
        case noData
        case haveData
    }

    enum ShowType {
        case homepage
        case list
    }

    var showType: ShowType = .homepage
    weak var listDelegate: MaterialsViewControllerListDelegate?

    var mainView = UIView()
    private var navigationBar: TKNormalNavigationBar!

    var navigationBarView = UIView()
    var navigationTitle = TKLabel()
    var navigationItemView = UIView()
    var navigationEditButton = TKButton()
    var navigationAddButton = TKButton()
    var navigationSearchButton = TKButton()
    var navigationBackButton = TKButton()

    private var searchBar: TKSearchBar = TKSearchBar(frame: .zero)

    var emptyView: UIView!
    var emptyImageView = UIImageView()
    var emptyLabel = TKLabel()
    var emptyButton = TKBlockButton()

    var showProView = UIView()
    var showProLabel = TKLabel()
    var showProButton = TKButton()

    var uploadView: TKView = TKView.create().backgroundColor(color: ColorUtil.main)

    var collectionView: UICollectionView!
    // cell中ShowView的Size
    var youtubeCellSize: CGSize!
    var otherCellSize: CGSize!

    var collectionViewBackgroundView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.backgroundColor)

    var currentFolder: TKMaterial? {
        didSet {
            reloadNavigationBarTitle()
            if currentFolder == nil {
                collectionViewBackgroundView.backgroundColor = ColorUtil.backgroundColor
                collectionView?.backgroundColor = ColorUtil.backgroundColor
            } else {
                collectionViewBackgroundView.backgroundColor = ColorUtil.folderBackground
                collectionView?.backgroundColor = ColorUtil.folderBackground
            }
        }
    }

    var style: Style! = .noData
    var isEdit = false {
        didSet {
            reloadNavigationBarTitle()
        }
    }

    var homeOffset: CGPoint = .zero

//    var materialsData: [TKMaterial] = []
    var materialsDataList: [String] = []
    var searchData: [String] = []
    var dataSource: [String: TKMaterial] = [:]
    weak var delegate: MaterialsViewControllerDelegate?
    private var playingCell: MaterialsCell!
//    let picker = HSDrivePicker()
    var isTransferData: Bool = false
    var teacherMemberLevel: Int = 1 // 1是免费 2是收费用户
    var isShowConfirm = false
    var isShowEditTitle = false
    var defualtSelectId: [String] = []

    var viewAppeared: Bool = false

    var searchKey: String = "" {
        didSet {
            search()
        }
    }

    /// 初始化页面
    /// - Parameters:
    ///   - showType: 显示类型
    ///   - isEdit: 是否是Edit模式
    init(showType: ShowType, isEdit: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        self.showType = showType
        self.isEdit = isEdit
    }

    /// 初始化页面
    /// - Parameters:
    ///   - showType: 显示类型
    ///   - isEdit: 是否是Edit模式
    ///   -  data: 从上一页传递的Data
    init(showType: ShowType, isEdit: Bool = false, data: [TKMaterial]) {
        super.init(nibName: nil, bundle: nil)
        self.showType = showType
        isTransferData = true
        let folders = data.filter { $0.type == .folder }.compactMap { $0.id }
        materialsDataList = data.filter({ $0.folder == "" || ($0.folder != "" && !folders.contains($0.folder)) }).compactMap { $0.id }
        data.forEach { item in
            dataSource[item.id] = item
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewAppeared = true
    }

    func backToHome() {
        currentFolder = nil
        searchKey = ""
        searchData = []
        searchBar.isHidden = true
        collectionView?.reloadData()
    }
}

// MARK: - View

extension MaterialsViewController {
    override func initView() {
        mainView.backgroundColor = ColorUtil.backgroundColor
        view.addSubviews(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.addSubviews(navigationBarView)
        if showType == .homepage {
            initNavigationBarView()
        } else {
            initListNavagationBar()
        }
        initProView()
        initMaterialsView()
//        initEmptyView()
        initContentView(style: .haveData)
//        initUploadView()
    }

    private func initUploadView() {
//        guard showType == .homepage else {
//            return
//        }
//        guard let url = Bundle.main.url(forResource: "assets/animation/uploadAnimation", withExtension: "json") else { return }
//        guard let animation = Animation.filepath(url.path) else {
//            logger.error("动画未找到")
//            return
//        }
//        let uploadAnimationView = AnimationView(animation: animation)
//        uploadView.addTo(superView: mainView) { make in
//            make.size.equalTo(60)
//            make.right.equalToSuperview()
//            make.bottom.equalToSuperview().offset(-40)
//        }
//        uploadView.corner(size: 30)
//        uploadView.addSubview(view: uploadAnimationView) { make in
//            make.center.size.equalToSuperview()
//        }
//        uploadAnimationView.loopMode = .loop
//        uploadAnimationView.play()
    }

    // MARK: - 初始化内容View

    func initContentView(style: Style) {
        self.style = style
        switch style {
        case .noData:
            initEmptyView()
        case .haveData:
            initMaterialsView()
        }
    }

    // MARK: - 初始化NavigationBar

    private func initNavigationBarView() {
        navigationBarView.addSubviews(navigationTitle, navigationEditButton, navigationAddButton, navigationSearchButton)
        navigationBarView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }
        navigationTitle.font(font: FontUtil.bold(size: 18)).alignment(alignment: .center).textColor(color: ColorUtil.Font.fourth).text("Materials")
        _ = navigationEditButton.title(title: "")
        navigationEditButton.setImage(name: "edit_new", size: CGSize(width: 22, height: 22))

        _ = navigationAddButton.setImage(name: "icAddPrimary")
        _ = navigationSearchButton.setImage(name: "search_primary")
        _ = navigationBackButton.setImage(name: "back")
        navigationEditButton.titleFont(FontUtil.bold(size: 13))
        navigationEditButton.titleColor(ColorUtil.main)
        navigationEditButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(4)
            make.height.equalTo(32)
            make.width.equalTo(22)
            make.left.equalToSuperview().offset(20)
        }
        navigationBackButton.addTo(superView: navigationBarView) { make in
            make.centerY.equalToSuperview().offset(4)
            make.size.equalTo(22)
            make.left.equalToSuperview().offset(20)
        }
        navigationBackButton.isHidden = true

        navigationSearchButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview().offset(4)
            make.size.equalTo(22)
        }

        navigationAddButton.snp.makeConstraints { make in
            make.right.equalTo(navigationSearchButton.snp.left).offset(-20)
            make.centerY.equalToSuperview().offset(4)
            make.size.equalTo(22)
        }

        navigationTitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(4)
        }

        // 初始化searchBar
        searchBar.addTo(superView: navigationBarView) { make in
            make.right.equalTo(navigationSearchButton.snp.right)
            make.height.equalToSuperview().multipliedBy(0.9)
            make.left.equalTo(navigationEditButton.snp.right).offset(10)
            make.bottom.equalToSuperview()
        }
        searchBar.setClearButtonAlwaysShow()
        searchBar.background(UIColor(r: 239, g: 243, b: 242))
        searchBar.isHidden = true
        searchBar.delegate = self
        navigationBackButton.onTapped { [weak self] _ in
            self?.currentFolder = nil
            self?.searchKey = ""
            self?.searchData = []
            self?.searchBar.isHidden = true
            self?.reloadCollectionView()
        }
        navigationSearchButton.onTapped { [weak self] _ in
            self?.clickSearch()
        }
        navigationEditButton.onTapped { [weak self] _ in
            self?.clickEdit()
        }
        navigationAddButton.onTapped { [weak self] _ in
            self?.clickAddMaterials()
        }
    }

    private func initListNavagationBar() {
        if isShowConfirm {
            navigationBar = TKNormalNavigationBar(frame: .zero, title: "Materials", rightButton: "Confirm", target: self, onRightButtonTapped: { [weak self] in
                self?.clickConfirm()
            })
        } else {
            navigationBar = TKNormalNavigationBar(frame: .zero, title: "Materials", target: self)
        }
        navigationBar.delegate = self
        view.addSubview(navigationBar)
        navigationBar.updateLayout(target: self)
    }

    // MARK: - 初始化无内容

    private func initEmptyView() {
        navigationEditButton.isHidden = true
        navigationAddButton.isHidden = true
        navigationSearchButton.isHidden = true
        if collectionView != nil {
            collectionView.isHidden = true
        }
        if emptyView != nil {
            emptyView.isHidden = false
            return
        }
        emptyView = UIView()
        emptyView.layer.masksToBounds = true
        mainView.addSubview(view: emptyView) { make in
            if showType == .homepage {
                make.top.equalTo(navigationBarView.snp.bottom).offset(51)
            } else {
                make.top.equalTo(navigationBar.snp.bottom).offset(51)
            }
            make.left.equalToSuperview().offset(0)
            make.right.equalToSuperview().offset(0)
            make.bottom.equalToSuperview()
        }
        emptyView.addSubviews(emptyImageView, emptyLabel, emptyButton)
        emptyImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(240)
            make.height.equalTo(200)
        }
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyImageView.snp.bottom).offset(30)
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.centerX.equalToSuperview()
        }
        emptyButton.snp.makeConstraints { make in
            if UIScreen.main.bounds.height > 670 {
                make.top.equalTo(emptyLabel.snp.bottom).offset(120)
            } else {
                make.top.equalTo(emptyLabel.snp.bottom).offset(65)
            }
            make.height.equalTo(50)
            make.width.equalTo(200)
            make.centerX.equalToSuperview()
        }

        emptyImageView.image = UIImage(named: "imgNoMaterials")
        emptyLabel.textColor(color: ColorUtil.Font.primary).alignment(alignment: .center).font(font: FontUtil.bold(size: 16)).text("Add your materials in minutes.\nIt's easy, we promise!")
        emptyLabel.numberOfLines = 0
        emptyLabel.changeLabelRowSpace(lineSpace: 0.8, wordSpace: 0.89)
        emptyButton.setTitle(title: "ADD MATERIALS")
        emptyButton.onTapped { [weak self] _ in
            self?.clickAddMaterials()
        }
    }

    // 初始化无内容
    func initMaterialsView() {
        if emptyView != nil {
            emptyView.isHidden = true
        }
        navigationEditButton.isHidden = false
        navigationAddButton.isHidden = false
        navigationSearchButton.isHidden = false
        if collectionView != nil {
            collectionView.isHidden = false
            return
        }
        youtubeCellSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 150)
        otherCellSize = CGSize(width: (UIScreen.main.bounds.width - 50) / 3, height: (UIScreen.main.bounds.width - 50) / 3)

        collectionViewBackgroundView.addTo(superView: mainView) { make in
            make.top.equalTo(self.showProView.snp.bottom).offset(20)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        let layout = CollectionViewAlignFlowLayout()
//        let layout = UICollectionViewFlowLayout()
        // 上下边距
        layout.minimumLineSpacing = 0
        // 左右边距
        layout.minimumInteritemSpacing = 5
        layout.scrollDirection = .vertical
        layout.sectionInsetReference = .fromLayoutMargins
        layout.estimatedItemSize = CGSize(width: 100, height: 100)
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        if #available(iOS 13.0, *) {
            collectionView?.automaticallyAdjustsScrollIndicatorInsets = false
        }
        collectionView?.backgroundColor = ColorUtil.backgroundColor
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        collectionView.dataSource = self
        collectionView.allowsSelection = false
        collectionView.showsVerticalScrollIndicator = false
        // 开启拖拽
//        collectionView.dragDelegate = self
//        collectionView.dropDelegate = self
//        collectionView.dragInteractionEnabled = true

        mainView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.showProView.snp.bottom).offset(20)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        collectionView.register(MaterialsCell.self, forCellWithReuseIdentifier: String(describing: MaterialsCell.self))
        collectionViewBackgroundView.snp.remakeConstraints { make in
            make.top.equalTo(collectionView.snp.top)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }

    func initProView() {
        view.addSubview(showProView)
        showProView.snp.makeConstraints { make in
            if showType == .homepage {
                make.top.equalTo(navigationBarView.snp.bottom).offset(0)
            } else {
                make.top.equalTo(navigationBar.snp.bottom).offset(0)
            }
            make.height.equalTo(0)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        showProView.addSubviews(showProLabel, showProButton)
        showProLabel
            .textColor(color: ColorUtil.Font.primary)
            .font(font: FontUtil.regular(size: 10))
            .text(text: "You should upgrade Insights to pro.\nTry PRO to unlock the full power of TuneKey.")
        showProLabel.numberOfLines = 2
        showProButton.title(title: "PRO").titleFont(FontUtil.regular(size: 10))
        showProButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.height.equalTo(0)
            make.width.equalTo(0)
            make.centerY.equalToSuperview()
        }
        showProButton.backgroundColor = ColorUtil.blush
        showProButton.layer.cornerRadius = 4

        showProLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(showProButton.snp.left)
        }

        showProButton.onTapped { [weak self] _ in
            self?.showUpgrade()
        }
    }

    private func showUpgrade() {
        ProfileUpgradeDetailViewController.show(level: .normal, target: self)
    }

    // MARK: - 更新是否显示ProView

    func changeProView(_ isShow: Bool) {
        if showType == .homepage {
            showProView.snp.updateConstraints { make in
                make.top.equalTo(navigationBarView.snp.bottom).offset(isShow ? 20 : 0)
                make.height.equalTo(isShow ? 26 : 0)
            }
            showProButton.snp.updateConstraints { make in
                make.height.equalTo(isShow ? 26 : 0)
                make.width.equalTo(isShow ? 42 : 0)
            }
            collectionView?.snp.remakeConstraints { make in
                make.top.equalTo(self.showProView.snp.bottom)
                make.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            }
        }
    }
}

extension MaterialsViewController: TKNormalNavigationBarDelegate {
    func backButtonTapped() {
        if currentFolder != nil {
            currentFolder = nil
            reloadCollectionView()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    func autoDismiss() -> Bool {
        return false
    }
}

// MARK: - Collection

extension MaterialsViewController: AddressBookViewControllerDelegate {
    func addressBookViewController(_ controller: AddressBookViewController, selectedLocalContacts: [LocalContact], userInfo: [String: Any]) {
    }

    func addressBookViewController(_ controller: AddressBookViewController, backTappedWithId id: String) {
//        logger.debug("进入代理回调")
//        var data: TKMaterial?
//        for item in materialsData {
//            if item.id == id {
//                data = item
//                break
//            }
//        }
//        guard data != nil else { return }
//        DispatchQueue.main.async {
//            self.showUpdateTitleController(data!)
//        }
    }
}

extension MaterialsViewController: UpdateMaterialsTitleViewControllerDelegate {
    func updateMaterialsTitleViewController(nextButtonTappedWithTitle title: String, id: String) {
        showFullScreenLoadingNoAutoHide()
        addSubscribe(
            MaterialService.shared.update(id: id, data: ["name": title])
                .subscribe(onNext: {
                    logger.debug("修改成功")
                    EventBus.send(key: .refreshMaterials)
                    TKToast.show(msg: "Successfully!", style: .success)
                    self.hideFullScreenLoading()
                }, onError: { err in
                    TKToast.show(msg: TipMsg.failed, style: .error)
                    logger.error("修改失败: \(err)")
                    self.hideFullScreenLoading()
                })
        )
    }
}

extension MaterialsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MaterialsCellDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentFolder == nil {
            homeOffset = scrollView.contentOffset
        }
    }

    func materialsCell(checkBoxDidTappedAt index: Int, materialsData: TKMaterial, cell: MaterialsCell) {
    }

    func materialsCell(shareButtonTappedAt index: Int, cell: MaterialsCell) {
        guard showType == .homepage else { return }
        var data: TKMaterial?
        if let folder = currentFolder {
            if searchKey == "" {
                data = folder.materials[index]
            } else {
                data = dataSource[searchData[index]]
            }
        } else {
            if searchKey == "" {
                data = dataSource[materialsDataList[index]]
            } else {
                data = dataSource[searchData[index]]
            }
        }
        guard let itemData = data else { return }
        // 进入分享页
        let controller = AddressBookViewController()
        controller.delegate = self
        controller.showType = .appContact
        controller.hero.isEnabled = true
        controller.isShowSelectAll = true

        controller.materials = [itemData]
        controller.defaultIds = itemData.studentIds
        controller.from = .materials
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .pageIn(direction: .up), dismissing: .pageOut(direction: .down))
        present(controller, animated: true, completion: nil)
    }

    func materialsCell(titleLabelDidSelectedAt index: Int, cell: MaterialsCell) {
        guard isShowEditTitle else { return }
        var data: TKMaterial?
        if let folder = currentFolder {
            if searchKey == "" {
                guard folder.materials.isSafeIndex(index) else { return }
                data = folder.materials[index]
            } else {
                guard searchData.isSafeIndex(index) else { return }
                data = dataSource[searchData[index]]
            }
        } else {
            if searchKey == "" {
                guard materialsDataList.isSafeIndex(index) else { return }
                data = dataSource[materialsDataList[index]]
            } else {
                guard searchData.isSafeIndex(index) else { return }
                data = dataSource[searchData[index]]
            }
        }
        guard let item = data else { return }
        logger.debug("被点击的标题: \(item.name)")
        showUpdateTitleController(item)
    }

    private func showUpdateTitleController(_ data: TKMaterial) {
        let controller = UpdateMaterialsTitleViewController()
        controller.id = data.id
        controller.defaultTitle = data.name
        controller.delegate = self
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

    // 点击cell
    func clickItem(materialsData: TKMaterial, cell: MaterialsCell) {
        if !isEdit {
            if materialsData.type != .folder {
                MaterialsHelper.cellClick(materialsData: materialsData, cell: cell, mController: self)
            } else {
                currentFolder = materialsData
                searchKey = ""
                searchData = []
                searchBar.isHidden = true
                reloadCollectionView()
                if !isTransferData {
                    reloadMaterialsFromFolder()
                }
            }
        } else {
            if let folder = currentFolder {
                // 当前是在文件夹内
                if searchKey == "" {
                    folder.materials[cell.tag]._isSelected = materialsData._isSelected
                    dataSource[folder.materials[cell.tag].id]?._isSelected = materialsData._isSelected
                } else {
                    for item in folder.materials.filter({ $0.id == searchData[cell.tag] }).enumerated() {
                        folder.materials[item.offset]._isSelected = materialsData._isSelected
                    }
                    dataSource[searchData[cell.tag]]?._isSelected = materialsData._isSelected
                }
            } else {
                if searchKey == "" {
                    dataSource[materialsDataList[cell.tag]]?._isSelected = materialsData._isSelected
                } else {
                    dataSource[searchData[cell.tag]]?._isSelected = materialsData._isSelected
                }
            }

            var selected: Bool = false
            if let folder = currentFolder {
                selected = folder.materials.filter { $0._isSelected }.count > 0
            }
            for id in materialsDataList {
                if dataSource[id]?._isSelected ?? false {
                    selected = true
                    break
                }
            }
            delegate?.materialsViewControllerUpdateBottomButton(isActive: selected)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 50) / 3
        var data: TKMaterial?
        if let folder = currentFolder {
            if searchKey == "" {
                data = folder.materials[indexPath.item]
            } else {
                data = dataSource[searchData[indexPath.item]]
            }
        } else {
            if searchKey == "" {
                data = dataSource[materialsDataList[indexPath.item]]
            } else {
                data = dataSource[searchData[indexPath.item]]
            }
        }

        guard let _data = data else { return .zero }
        if _data.type == .youtube {
            if showType == .homepage {
                return CGSize(width: UIScreen.main.bounds.width - 40, height: 150 + 90)
            } else {
                return CGSize(width: UIScreen.main.bounds.width - 40, height: 150 + 70)
            }

        } else {
            if showType == .homepage {
                return CGSize(width: width, height: width + 75)
            } else {
                return CGSize(width: width, height: width + 55)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let folder = currentFolder {
            return searchKey == "" ? folder.materials.count : searchData.count
        } else {
            return searchKey == "" ? materialsDataList.count : searchData.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MaterialsCell.self), for: indexPath) as! MaterialsCell
        let data: TKMaterial?
        var inFolder: Bool = false
        if let folder = currentFolder {
            if searchKey == "" {
                data = folder.materials[indexPath.item]
            } else {
                data = dataSource[searchData[indexPath.item]]
            }
            inFolder = true
        } else {
            if searchKey == "" {
                data = dataSource[materialsDataList[indexPath.item]]
            } else {
                data = dataSource[searchData[indexPath.item]]
            }
        }
        if let data = data {
            cell.cellInitialSize = data.type == .youtube ? youtubeCellSize : otherCellSize
            cell.tag = indexPath.row
            cell.edit(isEdit)
            cell.initData(materialsData: data, isShowStudentAvatarView: !isTransferData, isMainMaterial: showType == .homepage, searchKey: searchKey)
            if inFolder {
                cell.backView.backgroundColor = ColorUtil.folderBackground
            } else {
                cell.backView.backgroundColor = ColorUtil.backgroundColor
            }
        }
        cell.delegate = self
        return cell
    }
}

// MARK: - 拖拽相关

extension MaterialsViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        print("开始拖拽,indexPath: \(indexPath)")

        // MARK: - 要进行判断的地方

        let item = materialsDataList[indexPath.row]
        let itemProvider = NSItemProvider(object: item as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        // MARK: - 要进行判断的地方

        let item = materialsDataList[indexPath.row]
        let itemProvider = NSItemProvider(object: item as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let previewParameters = UIDragPreviewParameters()
        let width = (UIScreen.main.bounds.width - 50) / 3
        var size: CGSize = .zero

        // MARK: - 要进行判断的地方

        if let data = dataSource[materialsDataList[indexPath.item]] {
            if data.type == .youtube {
                size = CGSize(width: UIScreen.main.bounds.width - 40, height: 150)
            } else {
                size = CGSize(width: width, height: width)
            }
        }

        previewParameters.visiblePath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return previewParameters
    }
}

extension MaterialsViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let indexPath = destinationIndexPath {
            // 判断当前的位置,如果当前的位置和自己是一个,那则返回
            if let item = session.items.first {
                if let value = item.localObject as? String {
                    if value != materialsDataList[indexPath.item] {
                        // 当前覆盖的不是自己,判断是不是文件夹

                        // MARK: - 要进行判断的地方

                        let itemData = dataSource[materialsDataList[indexPath.item]]!
                        if itemData.type == .folder {
                            // 当前的是文件夹,合并
//                            return UICollectionViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
                        }
                    }
                }
            }
            // 移动和插入
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
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
        switch coordinator.proposal.operation {
        case .move:
            reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
        case .copy:
            // 合并到新文件夹内
            copyItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
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

                self.materialsDataList.remove(at: sourceIndexPath.row)
                self.materialsDataList.insert(item.dragItem.localObject as! String, at: dIndexPath.row)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [dIndexPath])
            })
            coordinator.drop(items.first!.dragItem, toItemAt: dIndexPath)
        }
    }

    private func copyItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        collectionView.performBatchUpdates({
            var indexPaths = [IndexPath]()

            // MARK: - 要进行判断的地方

            if let folder = dataSource[materialsDataList[destinationIndexPath.item]] {
                for item in coordinator.items {
                    if let id = item.dragItem.localObject as? String, let itemData = dataSource[id] {
                        // 将当前的item添加的文件夹里去
                        folder.materials.append(itemData)
                        if let indexPath = item.sourceIndexPath {
                            indexPaths.append(indexPath)
                        }
                    }
                }

                // MARK: - 要进行判断的地方

                dataSource[materialsDataList[destinationIndexPath.item]] = folder
            }

            // MARK: - 要进行判断的地方

            for item in indexPaths.reversed() {
                materialsDataList.remove(at: item.item)
            }
            collectionView.reloadItems(at: [destinationIndexPath])
            collectionView.deleteItems(at: indexPaths)
        })
    }
}

// MARK: - Data

extension MaterialsViewController {
    func reloadCollectionView() {
        logger.debug("重新渲染collectionView")
        view.endEditing(true)
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        if currentFolder == nil {
            collectionView.setContentOffset(homeOffset, animated: false)
        }
        var transform: CGAffineTransform
        let width = UIScreen.main.bounds.width
        if currentFolder != nil {
            // 当前是在文件夹内,从右往左来
            transform = CGAffineTransform(translationX: width, y: 0)
        } else {
            transform = CGAffineTransform(translationX: -width, y: 0)
        }
        collectionView.transform = transform
        UIView.animate(withDuration: 0.4) { [weak self] in
            self?.collectionView.transform = .identity
        }
        if navigationBar == nil {
            UIView.animate(withDuration: 0.2) {
                self.navigationEditButton.snp.remakeConstraints { make in
                    make.centerY.equalToSuperview().offset(4)
                    make.height.equalTo(32)
                    make.width.equalTo(22)
                    if self.currentFolder == nil {
                        // 返回home
                        make.left.equalToSuperview().offset(20)
                    } else {
                        make.left.equalToSuperview().offset(62)
                    }
                }
                self.navigationBarView.layoutIfNeeded()
            }
        }
    }

    override func initData() {
        if !isTransferData {
            getData()
            getTeacherInfo()
            EventBus.listen(key: .refreshMaterials, target: self) { [weak self] _ in
                self?.getData()
            }
            EventBus.listen(key: .shareMaterials, target: self) { [weak self] _ in
                guard let self = self else { return }
                self.getData()
            }
            EventBus.listen(EventBus.CHANGE_MEMBER_LEVEL_ID, target: self) { [weak self] data in
                guard let self = self else { return }
                if let data: Bool = data!.object as? Bool {
                    if data {
                        self.teacherMemberLevel = 2
                    } else {
                        self.teacherMemberLevel = 1
                    }
                    self.initUserInfo()
                }
            }
        }
    }

    func getTeacherInfo() {
        addSubscribe(
            UserService.teacher.studentGetTeacherInfo(teacherId: UserService.user.id()!)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        self.teacherMemberLevel = data.memberLevelId
                        self.initUserInfo()
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    self.initUserInfo()
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func initUserInfo() {
        if teacherMemberLevel == 1 {
            var count: Int = materialsDataList.count
            for item in materialsDataList {
                if let data = dataSource[item] {
                    if data.type == .folder {
                        count += data.materials.count
                    }
                }
            }
            changeProView(count >= 20)
        } else {
            changeProView(false)
        }
    }

    func getData(isOnlyLoadService: Bool = false) {
        if isTransferData {
            if materialsDataList.count > 0 {
                initContentView(style: .haveData)
                organizeOpentStudents()
                collectionView.reloadData()
            } else {
                initContentView(style: .noData)
            }
            return
        }
        addSubscribe(
            MaterialService.shared.materialList()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if data.count > 0 {
                        if !isOnlyLoadService {
                            if let cacheData = data[true] {
                                cacheData.forEach { item in
                                    if item.type == .folder {
                                        for _item in item.materials {
                                            self.dataSource[_item.id] = _item
                                        }
                                        item.materials = item.materials.sorted { f1, f2 -> Bool in
                                            Int(f1.updateTime) ?? 0 > Int(f2.updateTime) ?? 0
                                        }
                                    }
                                    self.dataSource[item.id] = item
                                }
                                let folders = cacheData.filter { $0.type == .folder }.compactMap { $0.id }
                                self.materialsDataList = cacheData.filter({ $0.folder == "" || ($0.folder != "" && !folders.contains($0.folder)) }).compactMap { $0.id }
                                self.materialsDataList = self.materialsDataList.sorted(by: { f1, f2 -> Bool in
                                    Int(self.dataSource[f1]?.updateTime ?? "0") ?? 0 > Int(self.dataSource[f2]?.updateTime ?? "0") ?? 0
                                })
                                if let folder = self.currentFolder {
                                    if let _folder = self.dataSource[folder.id] {
                                        self.currentFolder = _folder
                                        self.reloadMaterialsFromFolder()
                                    } else {
                                        self.currentFolder = nil
                                    }
                                }
                                if self.materialsDataList.count > 0 {
                                    self.initContentView(style: .haveData)
                                    self.organizeOpentStudents()
                                    self.collectionView.reloadData()
                                } else {
                                    self.initContentView(style: .noData)
                                }
                                self.initUserInfo()
                            }
                        }
                        if let serverData = data[false] {
                            serverData.forEach { item in
                                if item.type == .folder {
                                    for _item in item.materials {
                                        self.dataSource[_item.id] = _item
                                    }
                                }
                                item.materials = item.materials.sorted { f1, f2 -> Bool in
                                    Int(f1.updateTime) ?? 0 > Int(f2.updateTime) ?? 0
                                }
                                self.dataSource[item.id] = item
                            }

                            let folders = serverData.filter { $0.type == .folder }.compactMap { $0.id }
                            self.materialsDataList = serverData.filter({ $0.folder == "" || ($0.folder != "" && !folders.contains($0.folder)) }).compactMap { $0.id }
                            self.materialsDataList = self.materialsDataList.sorted(by: { f1, f2 -> Bool in
                                Int(self.dataSource[f1]?.updateTime ?? "0") ?? 0 > Int(self.dataSource[f2]?.updateTime ?? "0") ?? 0
                            })
                            if let folder = self.currentFolder {
                                if let _folder = self.dataSource[folder.id] {
                                    self.currentFolder = _folder
                                    self.reloadMaterialsFromFolder()
                                } else {
                                    self.currentFolder = nil
                                }
                            }
                            if self.materialsDataList.count > 0 {
                                self.initContentView(style: .haveData)
                                self.organizeOpentStudents()
                                self.collectionView.reloadData()
                            } else {
                                self.initContentView(style: .noData)
                            }
                            self.initUserInfo()
                        }
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    logger.debug("======\(err)")
                    var haveData: Bool = false
                    if self.currentFolder != nil {
                        haveData = true
                    } else {
                        haveData = self.materialsDataList.count > 0
                    }
                    if haveData {
                        self.initContentView(style: .haveData)
                        self.collectionView.reloadData()
                    } else {
                        self.initContentView(style: .noData)
                    }
                })
        )
    }

    func organizeOpentStudents() {
        let json: String = SLCache.main.get(key: SLCache.STUDENT_LIST)
        if let studentData = [TKStudent].deserialize(from: json) as? [TKStudent] {
            for item in materialsDataList.enumerated() {
                dataSource[item.element]?.studentData = []
                if let data = dataSource[item.element] {
                    for id in data.studentIds {
                        data.studentData += studentData.filter { $0.studentId == id }
                    }
                    var files: [TKMaterial] = []
                    if data.type == .folder {
                        for childData in data.materials {
                            for id in childData.studentIds {
                                childData.studentData += studentData.filter { $0.studentId == id }
                            }
                            files.append(childData)
                            dataSource[childData.id] = childData
                        }
                        data.materials = files
                    }
                    dataSource[data.id] = data
                }
            }
        }
    }

    private func showDeleteConfirmAlert() {
        // deleteMaterials()
        var ids: [String] = []
        var inFolders: [String: [String]] = [:]
        for item in materialsDataList.enumerated().reversed() {
            if let data = dataSource[item.element] {
                if data.type == .folder {
                    let inFoldersIds: [String] = data.materials.filter({ $0._isSelected }).compactMap { $0.id }
                    if inFoldersIds.count > 0 {
                        inFolders[data.id] = inFoldersIds
                    }
                }
                if data._isSelected {
                    ids.append(item.element)
                }
            }
        }

        SL.Alert.show(target: self, title: "", message: TipMsg.deleteMaterialTip, leftButttonString: "DELETE", rightButtonString: "GO BACK", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
            self?.deleteMaterials(ids: ids, inFolders: inFolders)
        }) {
        }
    }

    func deleteMaterials(ids: [String], inFolders: [String: [String]]) {
        logger.debug("准备删除材料")
        materialsDataList.removeElements { ids.contains($0) }
        logger.debug("需要删除的材料id: \(ids) | 要文件夹里要删除的: \(inFolders.compactMap { ($0, $1) })")
        var haveData: Bool = false
        if currentFolder != nil {
            haveData = true
        } else {
            haveData = materialsDataList.count > 0
        }
        if haveData {
            initContentView(style: .haveData)
            collectionView.reloadData()
        } else {
            initContentView(style: .noData)
        }
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

//            for (folderId, itemIds) in inFolders {
//                do {
//                    let folderDocRef = collRef.document(folderId)
//                    let folderData = try transaction.getDocument(folderDocRef)
//                    if let folder = TKMaterial.deserialize(from: folderData.data()) {
//                        // 删除文件夹内的当前文档
//                        itemIds.forEach { (id) in
//                            folder.materials.removeElements { id == $0.id }
//                        }
//                        transaction.updateData(folder.toJSON() ?? [:], forDocument: folderDocRef)
//                    }
//                    for id in itemIds {
//                        transaction.deleteDocument(collRef.document(id))
//                    }
//                } catch {
//                    pointer?.pointee = error as NSError
//                    return nil
//                }
//            }
//
//            for id in ids {
//                transaction.deleteDocument(collRef.document(id))
//            }
            return nil
        } completion: { [weak self] _, error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let error = error {
                logger.error("删除失败: \(error)")
                TKToast.show(msg: TipMsg.deleteFailed, style: .error)
            } else {
                TKToast.show(msg: "Delete materials successful", style: .success)
                for id in ids {
                    self.materialsDataList.removeElements { $0 == id }
                }

                for (folderId, itemIds) in inFolders {
                    if let folder = self.dataSource[folderId] {
                        for id in itemIds {
                            folder.materials.removeElements { $0.id == id }
                        }
                        if let currentFolder = self.currentFolder, currentFolder.id == folder.id {
                            self.currentFolder = folder
                        }
                    }
                }
                self.collectionView.reloadData()
                self.getData()
            }
        }

//        addSubscribe(
//            MaterialService.shared.deleted(materialIds: ids)
//                .subscribe(onNext: { [weak self] _ in
//                    logger.debug("======删除成功")
//                    self?.getData(isOnlyLoadService: true)
//                }, onError: { err in
//                    logger.debug("======删除失败\(err)")
//                })
//        )
    }

    /// 批量分享
    private func showShareController() {
//        var selectedId: [String] = []
        var selectData: [TKMaterial] = []
        var defStudentIds: [String] = []
        if let folder = currentFolder {
            selectData += folder.materials.filter { $0._isSelected }
            for item in selectData {
                defStudentIds += item.studentIds
            }
            logger.debug("材料分享 => 当前是在文件夹里,分享的材料id有: \(selectData.compactMap { $0.id })")
        } else {
            for item in materialsDataList {
                if let itemData = dataSource[item] {
                    if itemData._isSelected {
                        defStudentIds += itemData.studentIds
                        selectData.append(itemData)
                    }
                }
            }
        }

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
        controller.showType = .appContact
        controller.hero.isEnabled = true
        controller.defaultIds = defStudentIds
        controller.materials = selectData
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }
}

// MARK: - Action

extension MaterialsViewController {
    func reloadNavigationBarTitle() {
        guard viewAppeared else { return }
        // 判断是普通的navigationBar还是navigationView
        if navigationBar != nil {
            if let folder = currentFolder {
                navigationBar.title = folder.name
            } else {
                navigationBar.title = "Materials"
            }
        } else {
            if let folder = currentFolder {
                navigationTitle.text = "\(folder.name)"
                navigationBackButton.isHidden = false
                searchBar.blur()
                searchKey = ""
                searchBar.isHidden = true
                navigationTitle.snp.remakeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.centerY.equalToSuperview().offset(4)
                    make.left.equalToSuperview().offset(isEdit ? 114 : 94)
                    make.right.equalToSuperview().offset(-94)
                }
            } else {
                navigationBackButton.isHidden = true
                navigationTitle.text = "Materials"
                navigationTitle.snp.remakeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.centerY.equalToSuperview().offset(4)
                }
            }
        }
    }

    func reloadMaterialsFromFolder() {
        guard let folder = currentFolder else { return }
        // 获取最新的材料,然后更新它

        Firestore.firestore().runTransaction { transaction, pointer -> TKMaterial? in
            do {
                let folderDoc = try transaction.getDocument(DatabaseService.collections.material().document(folder.id))
                guard let folderData = TKMaterial.deserialize(from: folderDoc.data()) else {
                    pointer?.pointee = NSError(domain: "解析错误", code: -1, userInfo: nil)
                    return nil
                }
                var files: [TKMaterial] = []
                for childFile in folderData.materials {
                    let fileDoc = try transaction.getDocument(DatabaseService.collections.material().document(childFile.id))
                    if let fileData = TKMaterial.deserialize(from: fileDoc.data()) {
                        files.append(fileData)
                    }
                }
                folderData.materials = files
                transaction.updateData(folderData.toJSON() ?? [:], forDocument: DatabaseService.collections.material().document(folderData.id))
                return folderData
            } catch {
                pointer?.pointee = error as NSError
                return nil
            }
        } completion: { [weak self] folderData, error in
            guard let self = self else { return }
            if let error = error {
                logger.error("更新失败: \(error)")
            } else {
                logger.debug("更新成功")
            }
            if let _folder = self.currentFolder, let _folderData = folderData as? TKMaterial, _folder.id == _folderData.id {
                _folderData.materials = _folderData.materials.sorted { f1, f2 -> Bool in
                    Int(f1.updateTime) ?? 0 > Int(f2.updateTime) ?? 0
                }
                self.currentFolder = _folderData
                self.dataSource[_folderData.id] = _folderData
                self.organizeOpentStudents()
                self.collectionView.reloadData()
            }
        }
    }

    func clickSearch() {
//        var data: [TKMaterial] = []
//        materialsData.forEach { id in
//            if let item = dataSource[id] {
//                data.append(item)
//            }
//        }
//        let controller = MaterialsSearchController(data: data)
//        controller.modalPresentationStyle = .fullScreen
//        controller.hero.isEnabled = true
//        controller.enablePanToDismiss()
//        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//        present(controller, animated: true, completion: nil)
        logger.debug("点击搜索按钮")
        searchBar.isHidden = false
        searchBar.focus()
    }

    func clickConfirm() {
        var selectedData: [TKMaterial] = []
        for item in materialsDataList {
            if let itemData = dataSource[item], itemData._isSelected {
                selectedData.append(itemData)
            }
        }
        listDelegate?.materialsViewController(selectData: selectedData)
        dismiss(animated: true, completion: nil)
    }

    func clickEdit() {
        if isEdit {
            for item in materialsDataList.enumerated() {
                dataSource[item.element]?._isSelected = false
            }
            currentFolder?.materials.forEach({ item in
                item._isSelected = false
            })
            navigationEditButton.title(title: "")
            navigationEditButton.setImage(name: "edit_new", size: CGSize(width: 22, height: 22))

            navigationEditButton.snp.updateConstraints { make in
                make.width.equalTo(22)
            }
        } else {
            navigationEditButton.title(title: "Cancel")
            navigationEditButton.setImageNil()
            navigationEditButton.snp.updateConstraints { make in
                make.width.equalTo(50)
            }
        }
        isEdit = !isEdit

        delegate?.clickEdit(isEdit: isEdit, controllerSelected: .materialsController)
//        UIView.performWithoutAnimation({
//            //刷新界面
//            self.collectionView.reloadData()
//        })

        collectionView.reloadData()
//        navigationSearchButton.isHidden = isEdit
        navigationAddButton.isHidden = isEdit
    }

    func clickMoveButton() {
        logger.debug("点击movebutton")
        isEdit = false
        navigationEditButton.title(title: "")
        navigationEditButton.setImage(name: "edit_new", size: CGSize(width: 22, height: 22))
        navigationEditButton.snp.updateConstraints { make in
            make.width.equalTo(22)
        }
        navigationSearchButton.isHidden = isEdit
        navigationAddButton.isHidden = isEdit
        collectionView.reloadData()
        var selectedItems: [TKMaterial] = []
        dataSource.forEach { _, item in
            if item._isSelected {
                selectedItems.append(item)
                item._isSelected = false
            }
        }
        currentFolder?.materials.forEach({ item in
            if item._isSelected {
                item._isSelected = false
            }
        })
        showMoveToController(selectedItems: selectedItems)
    }

    private func showMoveToController(selectedItems: [TKMaterial]) {
        let controller = MaterialMoveToFolderSelectorViewController(selectedItems: selectedItems, excludeFolder: currentFolder)
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

    func clickBottomButtonReturn(isRightButton: Bool) {
        isEdit = false

//        navigationEditButton.title(title: "Edit")
        navigationEditButton.setImage(name: "edit_new", size: CGSize(width: 22, height: 22))
        navigationEditButton.snp.updateConstraints { make in
            make.width.equalTo(22)
        }
        navigationSearchButton.isHidden = isEdit
        navigationAddButton.isHidden = isEdit
        collectionView.reloadData()

        if isRightButton {
            showShareController()
        } else {
            showDeleteConfirmAlert()
        }
        for item in materialsDataList.enumerated() {
            dataSource[item.element]?._isSelected = false
        }

        currentFolder?.materials.forEachItems({ _, index in
            currentFolder?.materials[index]._isSelected = false
        })

        searchData.forEachItems { item, _ in
            dataSource[item]?._isSelected = false
        }
    }

    func clickAddMaterials() {
        if teacherMemberLevel == 1 {
            if materialsDataList.count >= FreeResources.maxMaterialsCount {
//                TKToast.show(msg: "Become a member to add more!", style: .warning)
                ProfileUpgradeDetailViewController.show(level: .normal, target: self)
                return
            }
        }

        TKPopAction.show(
            items:
            TKPopAction.Item(title: "Photo or video", action: { [weak self] in
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
            isCancelShow: true, target: self)
    }

    private func showAudioRecording() {
        //  //_ path: String, _ totalTime: CGFloat, _ id: String, _ recordController: TeacherAudioControlle
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
//        OperationQueue.main.addOperation {
//            self.showFullScreenLoadingNoAutoHide()
//        }

        do {
            let fileData = try Data(contentsOf: URL(fileURLWithPath: path))
            let path = "/materials/\(UserService.user.id()!)/\(id)\(path.getFileExtension)"
            logger.debug("上传路径: \(path)")

            // MARK: - 要修改的地方

            TKPopAction.showAddMaterials(target: self, type: .audio, image: UIImage(named: "imgMp3")!, vidioUrl: nil, fileData: fileData, filePath: path, fileTitle: title, fileId: id, folder: currentFolder) {
                EventBus.send(key: .refreshMaterials)
            }
        } catch {
            print("走到了catch")
            hideFullScreenLoading()
            TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
        }
    }

    private func showPhotoLibrary() {
        showImagePicker()
//        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
//            invokeSystemPhotoOrMovie()
//        } else {
//            let alert = UIAlertController(title: "Prompt", message: TipMsg.accessForPhoto, preferredStyle: .alert)
//            let cancel = UIAlertAction(title: "OK", style: .cancel, handler: nil)
//            alert.addAction(cancel)
//            show(alert, sender: nil)
//        }
    }

    private func showCamera() {
        let controller = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { _ in
                // 检查相机权限
                DispatchQueue.main.async {
                    let status: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
                    if status == AVAuthorizationStatus.authorized { // 有相机权限
                        // 跳转到相机或者相册
                        controller.delegate = self
                        controller.allowsEditing = false
                        controller.sourceType = UIImagePickerController.SourceType.camera

                        controller.mediaTypes = UIImagePickerController.availableMediaTypes(for: UIImagePickerController.SourceType.photoLibrary)! // 拍照和录像都可以
                        // 弹出相册页面或相机
                        self.present(controller, animated: true, completion: {
                        })
                    } else if (status == AVAuthorizationStatus.denied) || (status == AVAuthorizationStatus.restricted) {
                    } else if status == AVAuthorizationStatus.notDetermined { // 权限没有被允许
                        // 去请求权限
                        AVCaptureDevice.requestAccess(for: AVMediaType.video) { genter in
                            if genter {
                                print("去打开相机")
                            } else {
                                print(">>>访问受限")
                            }
                        }
                    }
                }
            })
        }
    }

    private func showAudio() {
        DispatchQueue.main.async {
            let controller = MPMediaPickerController(mediaTypes: .anyAudio)
            controller.showsCloudItems = true
            controller.delegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }

    override func reloadViewWithImg(img: UIImage) {
        logger.debug("======获取Image成功")
        if let data = img.pngData() {
            let st = Date().timeIntervalSince1970
            let hash = FileUtil.shared.getHashCode(data: data)
            let et = Date().timeIntervalSince1970
            logger.debug("计算耗时:\(et - st) 完成后的hashCode: \(hash ?? "nil")")
        }
        // 3653ece9595272537e9d93c235133b0072b7ae0c4b796e4890c83f29919f9990
        // 3653ece9595272537e9d93c235133b0072b7ae0c4b796e4890c83f29919f9990
//        TKPopAction.showAddMaterials(target: self, type: .image, image: img, folder: currentFolder) {
//            logger.debug("======上传成功")
//            EventBus.send(key: .refreshMaterials)
//        }
    }

    override func reloadViewWithMovie(url: URL) {
        logger.debug("======获取Moview成功: \(url.absoluteString)")
        let st = Date().timeIntervalSince1970
        let hash = FileUtil.shared.getHashCode(url: url)
        let et = Date().timeIntervalSince1970
        logger.debug("计算耗时:\(et - st) 完成后的hashCode: \(hash ?? "nil")")
//        TKPopAction.showAddMaterials(target: self, type: .video, vidioUrl: url, folder: currentFolder) {
//            logger.debug("======上传成功")
//            EventBus.send(key: .refreshMaterials)
//        }
    }
}

extension MaterialsViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        logger.debug("选择完毕: \(mediaItemCollection.items)")
    }
}

// 音频播放
extension MaterialsViewController {
    func clickMp3(_ cell: MaterialsCell, url: String) {
        if playingCell != nil && cell.tag != playingCell.tag {
            playingCell.playImageView!.setStatus(.stop)
        }
        playingCell = cell

        if cell.playImageView!.previosStatus == .stop {
            cell.playImageView!.play(url)
        } else if cell.playImageView!.previosStatus == .playing {
            cell.playImageView!.setStatus(.stop)
        } else {
            cell.playImageView!.setStatus(.stop)
        }
    }
}

extension MaterialsViewController: TKSearchBarDelegate {
    func tkSearchBar(textChanged searchBar: TKSearchBar, text: String) {
        searchKey = text
        collectionView.reloadData()
    }

    func tkSearchBar(didReturn searchBar: TKSearchBar) {
        // 点击了搜索
        collectionView.reloadData()
    }

    func tkSearchBar(didClearButtonTapped searchBar: TKSearchBar, textBefore: String) {
        // 点击了clear button
        if textBefore == "" {
            searchBar.blur()
            searchBar.isHidden = true
        }
        searchKey = ""
        collectionView.reloadData()
    }
}

extension MaterialsViewController {
    private func search() {
        searchData = []
        var sourceDataId: [String] = []
        var sourceData: [String: TKMaterial] = [:]
        if let folder = currentFolder {
            sourceDataId = folder.materials.compactMap { $0.id }
            for item in folder.materials {
                sourceData[item.id] = item
            }
        } else {
            sourceDataId = materialsDataList
            sourceData = dataSource
        }
        if searchKey != "" {
            for id in sourceDataId {
                if let item = sourceData[id] {
                    if item.name.lowercased().contains(searchKey.lowercased()) {
                        searchData.append(id)
                    } else if item.type == .folder {
                        if item.materials.contains(where: { $0.id == id }) {
                            searchData.append(id)
                        }
                    }
                }
            }
        }
        collectionView?.reloadData()
    }
}

extension MaterialsViewController: GalleryControllerDelegate {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        controller.dismiss(animated: true, completion: nil)
        guard images.count > 0 else { return }
        let imageAsset = images[0].asset
        images[0].resolve { image in
            guard let image = image else { return }
            imageAsset.getURL { url in
                if let url = url {
                    TKPopAction.showAddMaterials(target: self, type: .image, image: image, imageUrl: url, folder: self.currentFolder) {
                        EventBus.send(key: .refreshMaterials)
                    }
                }
            }
        }
    }

    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        controller.dismiss(animated: true, completion: nil)
        video.asset.getURL { [weak self] url in
            guard let self = self, let url = url, let hashCode = FileUtil.shared.getHashCode(url: url) else { return }
            DispatchQueue.main.async {
                logger.debug("获取到的HashCode: \(hashCode)")
                TKPopAction.showAddMaterials(target: self, type: .video, vidioUrl: url, folder: self.currentFolder) {
                    logger.debug("======上传成功")
                    EventBus.send(key: .refreshMaterials)
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

    func showImagePicker() {
        let gallery = GalleryController()
        Config.tabsToShow = [.imageTab, .videoTab]
        Config.Camera.imageLimit = 1
        gallery.delegate = self
        present(gallery, animated: true, completion: nil)
    }
}

protocol MaterialsViewControllerDelegate: NSObjectProtocol {
    func clickEdit(isEdit: Bool, controllerSelected: MainViewController.MainSelectedController)
    func materialsViewControllerUpdateBottomButton(isActive: Bool)
}
