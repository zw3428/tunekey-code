//
//  SMaterialsController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/18.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class SMaterialsController: TKBaseViewController {
    enum Style {
        case noData
        case haveData
    }

    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    var searchBar: TKSearchBar = TKSearchBar(frame: .zero)

    var emptyView: UIView?
    var emptyImageView = UIImageView()
    var emptyLabel = TKLabel()
    var style: Style! = .noData
    var collectionView: UICollectionView?
    var collectionViewBackgroundView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.backgroundColor)
    var dataSource: [String: TKMaterial] = [:]
    var materialsData: [String] = [] {
        didSet {
            checkUnreadData()
        }
    }

    var newMaterialsData: [String] = []

    var currentFolder: TKMaterial? {
        didSet {
            if let folder = currentFolder {
                navigationBar.title = folder.name
                navigationBar.showLeftButton()
                collectionViewBackgroundView.backgroundColor = ColorUtil.folderBackground
                collectionView?.backgroundColor = ColorUtil.folderBackground
            } else {
                collectionViewBackgroundView.backgroundColor = ColorUtil.backgroundColor
                collectionView?.backgroundColor = ColorUtil.backgroundColor
                navigationBar.hiddenLeftButton()
                navigationBar.title = "Materials"
            }
        }
    }

    var searchKey: String = "" {
        didSet {
            search()
        }
    }

    var searchData: [String] = []

    // cell中ShowView的Size
    var youtubeCellSize: CGSize!
    var otherCellSize: CGSize!
//    private var studentData: TKStudent!

    var homeOffset: CGPoint = .zero

    convenience init() {
        self.init(nibName: nil, bundle: nil)
        initViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        clearUnReadData()
    }
}

// MARK: - View

extension SMaterialsController {
    private func initViews() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "Materials", rightButton: UIImage(named: "search_primary")!, onRightButtonTapped: {
            self.clickSearch()
        })
        navigationBar.hiddenRightButton()
        navigationBar.hiddenLeftButton()
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        navigationBar.delegate = self

        searchBar.addTo(superView: navigationBar) { make in
            make.right.equalTo(navigationBar.rightButton.snp.right)
            make.height.equalToSuperview().multipliedBy(0.9)
            make.left.equalToSuperview().offset(10)
            make.bottom.equalToSuperview()
        }
        searchBar.setClearButtonAlwaysShow()
        searchBar.background(UIColor(r: 239, g: 243, b: 242))
        searchBar.isHidden = true
        searchBar.delegate = self

        initContentView()
        reloadData()
    }

    // MARK: - 初始化内容View

    func initContentView() {
        switch style! {
        case .noData:
            initEmptyView()
        case .haveData:
            initMaterialsView()
        }
    }

    private func initEmptyView() {
        navigationBar.hiddenRightButton()
        if collectionView != nil {
            collectionView?.isHidden = true
        }
        if emptyView != nil {
            emptyView?.isHidden = false
            return
        }
        emptyView = UIView()
        mainView.addSubview(view: emptyView!) { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(46)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(393)
        }

        emptyView?.addSubviews(emptyImageView, emptyLabel)
        emptyImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(240)
            make.height.equalTo(200)
        }
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyImageView.snp.bottom).offset(30)
            make.left.right.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        emptyImageView.image = UIImage(named: "imgNoMaterials")
        emptyLabel.textColor(color: ColorUtil.Font.primary).alignment(alignment: .center).font(font: FontUtil.bold(size: 16)).text("The instructor hasn't shared any\nmaterials yet.")
        emptyLabel.numberOfLines = 0
        emptyLabel.changeLabelRowSpace(lineSpace: 0.8, wordSpace: 0.89)
    }

    // 初始化无内容
    func initMaterialsView() {
        if emptyView != nil {
            emptyImageView.isHidden = true
        }
        navigationBar.showRightButton()
        if collectionView != nil {
            collectionView?.isHidden = false
            return
        }

        collectionViewBackgroundView.addTo(superView: mainView) { make in
            make.top.equalTo(self.navigationBar.snp.bottom).offset(0)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        youtubeCellSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 150)
        otherCellSize = CGSize(width: (UIScreen.main.bounds.width - 50) / 3, height: (UIScreen.main.bounds.width - 50) / 3)
        let layout = CollectionViewAlignFlowLayout()

        layout.minimumLineSpacing = 0
        // 左右边距
        layout.minimumInteritemSpacing = 5
        layout.scrollDirection = .vertical
//        layout.sectionInsetReference = .fromLayoutMargins
//        layout.estimatedItemSize = CGSize(width: 100, height: 100)
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView?.backgroundColor = ColorUtil.backgroundColor
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        collectionView?.allowsSelection = false
        collectionView?.showsVerticalScrollIndicator = false
        mainView.addSubview(collectionView!)
        collectionView?.snp.makeConstraints { make in
            make.top.equalTo(self.navigationBar.snp.bottom).offset(0)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        collectionView?.register(MaterialsCell.self, forCellWithReuseIdentifier: String(describing: MaterialsCell.self))
        collectionViewBackgroundView.snp.remakeConstraints { make in
            make.top.equalTo(collectionView!.snp.top)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }
}

extension SMaterialsController: TKSearchBarDelegate {
    func tkSearchBar(textChanged searchBar: TKSearchBar, text: String) {
        searchKey = text
        collectionView?.reloadData()
    }

    func tkSearchBar(didReturn searchBar: TKSearchBar) {
        // 点击了搜索
        collectionView?.reloadData()
    }

    func tkSearchBar(didClearButtonTapped searchBar: TKSearchBar, textBefore: String) {
        // 点击了clear button
        if textBefore == "" {
            searchBar.blur()
            searchBar.isHidden = true
        }
        searchKey = ""
        collectionView?.reloadData()
    }

    private func search() {
        searchData = []
        if let folder = currentFolder {
            searchData = folder.materials.filter { $0.name.lowercased().contains(searchKey.lowercased()) }.compactMap { $0.id }
        } else {
//            searchData = materialsData.filter { $0.name.lowercased().contains(searchKey.lowercased()) }
            materialsData.forEach { id in
                if let data = dataSource[id] {
                    if data.name.lowercased().contains(searchKey.lowercased()) {
                        searchData.append(id)
                    }
                }
            }
        }
        logger.debug("获取到的搜索结果条数: \(searchData.count)")
        collectionView?.reloadData()
    }
}

// MARK: - Data

extension SMaterialsController {
    override func initData() {
        EventBus.listen(key: .studentMaterialChanged, target: self) { [weak self] _ in
            self?.reloadData()
        }
    }

    private func reloadData() {
        //过滤掉在文件夹里的,判断当前文件夹是否存在,如果存在则不显示,如果不存在,则显示
        let data = ListenerService.shared.studentData.materials
        let folders: [String] = data.compactMap {
            if $0.type == .folder {
                return $0.id
            } else {
                return nil
            }
        }

        materialsData = data.compactMap {
            //判断当前文件是否有所属文件夹
            if $0.folder != "" {
                //当前文件有所属文件夹,判断当前文件夹是否分享给了此用户
                if !folders.contains($0.folder) {
                    return $0.id
                }
            } else {
                return $0.id
            }
            return nil
        }
        materialsData = materialsData.sorted { (f1, f2) -> Bool in
            Int(dataSource[f1]?.updateTime ?? "0") ?? 0 > Int(dataSource[f2]?.updateTime ?? "0") ?? 0
        }
//        materialsData = data.compactMap { $0.id }
        data.forEach { (item) in
            if item.type == .folder {
                item.materials.forEach { (file) in
                    dataSource[file.id] = file
                }
            }
            item.materials = item.materials.sorted { (f1, f2) -> Bool in
                Int(f1.updateTime) ?? 0 > Int(f2.updateTime) ?? 0
            }
            dataSource[item.id] = item
        }
        initMaterilasData()
    }

    func initMaterilasData() {
        if materialsData.count > 0 {
            style = .haveData
            initContentView()
            collectionView?.reloadData()
        } else {
            style = .noData
            initContentView()
        }
    }

    private func checkUnreadData() {
        let data: [TKMaterial] = dataSource.compactMap {
            if materialsData.contains($0) {
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
            if materialsData.contains($0) {
                return $1
            } else {
                return nil
            }
        }
        MaterialService.shared.setLocalMaterials(data)
        checkUnreadData()
    }
}

// MARK: - CollectionView

extension SMaterialsController: TKNormalNavigationBarDelegate {
    func backButtonTapped() {
        currentFolder = nil
        searchKey = ""
        searchData = []
        searchBar.isHidden = true
        reloadCollectionView()
    }

    func reloadCollectionView() {
        view.endEditing(true)
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()
        if currentFolder == nil {
            collectionView?.setContentOffset(homeOffset, animated: false)
        }
        var transform: CGAffineTransform
        let width = UIScreen.main.bounds.width
        if currentFolder != nil {
            // 当前是在文件夹内,从右往左来
            transform = CGAffineTransform(translationX: width, y: 0)
        } else {
            transform = CGAffineTransform(translationX: -width, y: 0)
        }
        collectionView?.transform = transform
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.collectionView?.transform = .identity
        }
    }
}

extension SMaterialsController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentFolder == nil {
            let offset = scrollView.contentOffset
            homeOffset = offset
        }
    }
}

extension SMaterialsController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MaterialsCellDelegate {
    func materialsCell(shareButtonTappedAt index: Int, cell: MaterialsCell){
        
    }
    func materialsCell(checkBoxDidTappedAt index: Int, materialsData: TKMaterial, cell: MaterialsCell) {
        
    }
    func materialsCell(titleLabelDidSelectedAt index: Int, cell: MaterialsCell) {
    }

    func clickItem(materialsData: TKMaterial, cell: MaterialsCell) {
        if materialsData.type == .folder {
            // 当前打开的是文件夹
            currentFolder = materialsData
            searchKey = ""
            searchData = []
            searchBar.isHidden = true
            reloadCollectionView()
        } else {
            MaterialsHelper.cellClick(materialsData: materialsData, cell: cell, mController: self)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 50) / 3
        let data: TKMaterial?
        if let folder = currentFolder {
            if searchKey == "" {
                data = folder.materials[indexPath.item]
            } else {
                data = dataSource[searchData[indexPath.item]]
            }
        } else {
            if searchKey == "" {
                data = dataSource[materialsData[indexPath.item]]
            } else {
                data = dataSource[searchData[indexPath.item]]
            }
        }
        guard let _data = data else {
            return .zero
        }
        if _data.type == .youtube {
            return CGSize(width: UIScreen.main.bounds.width - 40, height: 150 + 76)
        } else {
            return CGSize(width: width, height: width + 61)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let folder = currentFolder {
            return searchKey == "" ? folder.materials.count : searchData.count
        } else {
            return searchKey == "" ? materialsData.count : searchData.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MaterialsCell.self), for: indexPath) as! MaterialsCell
        let data: TKMaterial?
        var inFolder: Bool = false
        if let folder = currentFolder {
            inFolder = true
            if searchKey == "" {
                data = folder.materials[indexPath.item]
            } else {
                data = dataSource[searchData[indexPath.item]]
            }
        } else {
            if searchKey == "" {
                data = dataSource[materialsData[indexPath.item]]
            } else {
                data = dataSource[searchData[indexPath.item]]
            }
        }
        guard let _data = data else { return cell }
        cell.cellInitialSize = _data.type == .youtube ? youtubeCellSize : otherCellSize
        cell.tag = indexPath.row
        cell.initData(materialsData: _data, isShowStudentAvatarView: false, searchKey: searchKey)
        cell.delegate = self
        if inFolder {
            cell.backView.backgroundColor = ColorUtil.folderBackground
        } else {
            cell.backView.backgroundColor = ColorUtil.backgroundColor
        }
        return cell
    }
}

// MARK: - Action

extension SMaterialsController {
    func clickSearch() {
        searchBar.isHidden = false
        searchBar.focus()
        searchBar.snp.remakeConstraints { make in
            make.right.equalTo(navigationBar.rightButton.snp.right)
            make.height.equalToSuperview().multipliedBy(0.9)
            if currentFolder == nil {
                make.left.equalToSuperview().offset(10)
            } else {
                make.left.equalTo(navigationBar.backButton.snp.right).offset(10)
            }
            make.bottom.equalToSuperview()
        }
//        let controller = MaterialsSearchController(data: materialsData)
//        controller.modalPresentationStyle = .fullScreen
//        controller.hero.isEnabled = true
//        controller.enablePanToDismiss()
//        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//        present(controller, animated: true, completion: nil)
    }
}
