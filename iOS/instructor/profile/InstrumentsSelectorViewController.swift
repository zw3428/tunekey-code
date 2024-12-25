//
//  InstrumentsSelectorViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/6/1.
//  Copyright © 2021 spelist. All rights reserved.
//

import PromiseKit
import UIKit

protocol InstrumentsSelectorViewControllerDelegate: AnyObject {
    func instrumentsSelectorViewController(didSelectInstrument instrument: TKInstrument)
    func instrumentsSelectorViewController(didSelectInstruments instruments: [TKInstrument])
}

class InstrumentsSelectorViewController: TKBaseViewController {
    enum Style {
        case singleSelection
        case multipleSelection
    }

    weak var delegate: InstrumentsSelectorViewControllerDelegate?

    var style: Style = .singleSelection

    var data: [TKInstrument] = [] {
        didSet {
            logger.debug("获取到的所有乐器: \(data.count)")
        }
    }

    private lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "", rightButton: "") { [weak self] in
        self?.onNavigationBarRightButtonTapped()
    }

    private var searchBar: TKSearchBar = TKSearchBar()

    private lazy var collectionViewLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = ColorUtil.backgroundColor
        collectionView.register(ProfileEditDetailInstrumentItemCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ProfileEditDetailInstrumentItemCollectionViewCell.self))
        collectionView.register(InstrumentsSelectorSearchResultItemCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: InstrumentsSelectorSearchResultItemCollectionViewCell.self))
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private var fullMatch: Bool = false
    private var searchKey: String = ""
    private var searchResult: [TKInstrument] = [] {
        didSet {
            logger.debug("搜索结果: \(searchResult.toJSONString() ?? "")")
            updateLayout()
        }
    }

    private var isLoaded: Bool = false

    var selectedInstruments: [TKInstrument] = []

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isLoaded else { return }
        loadAllInstruments()
        updateLayout()
        switch style {
        case .singleSelection:
            navigationBar.hiddenRightButton()
        case .multipleSelection:
            navigationBar.rightButton.title(title: "Done")
            searchBar.snp.updateConstraints { make in
                make.right.equalToSuperview().offset(-40 - 20 - 20)
            }
        }
    }
}

extension InstrumentsSelectorViewController {
    private func onNavigationBarRightButtonTapped() {
        guard style == .multipleSelection else {
            return
        }

        delegate?.instrumentsSelectorViewController(didSelectInstruments: selectedInstruments)
        dismiss(animated: true, completion: nil)
    }

    private func updateLayout() {
//        collectionViewLayout.scrollDirection = .vertical
//        if searchKey != "" {
//            collectionViewLayout.itemSize = CGSize(width: collectionView.bounds.width, height: 60)
//            collectionViewLayout.minimumInteritemSpacing = 0
//            collectionViewLayout.minimumLineSpacing = 0
//        } else {
//            let width = (collectionView.bounds.width / 4) - 6
//            let height = width + 30
//            collectionViewLayout.itemSize = CGSize(width: width, height: height)
//            collectionViewLayout.minimumInteritemSpacing = 2
//            collectionViewLayout.minimumLineSpacing = 10
//        }
    }
}

extension InstrumentsSelectorViewController {
    override func initView() {
        super.initView()

        navigationBar.updateLayout(target: self)
        searchBar.delegate = self
        searchBar.addTo(superView: navigationBar) { make in
            make.height.equalTo(38)
            make.left.equalTo(navigationBar.backButton.snp.right).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview()
        }

        collectionView.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        view.bringSubviewToFront(navigationBar)
    }
}

extension InstrumentsSelectorViewController {
    private func loadAllInstruments() {
        showFullScreenLoading()
        InstrumentService.shared.loadAllInstruments()
            .done { [weak self] instruments in
                guard let self = self else { return }
                self.isLoaded = true
                self.hideFullScreenLoading()
                self.data = instruments
                self.collectionView.reloadData()
            }
            .catch { [weak self] _ in
                guard let self = self else { return }
                self.isLoaded = false
                self.hideFullScreenLoading()
                logger.error("Load instruments failed, please try again later.")
                self.data = []
                self.collectionView.reloadData()
            }
    }
}

extension InstrumentsSelectorViewController: TKSearchBarDelegate {
    func tkSearchBar(didClearButtonTapped searchBar: TKSearchBar, textBefore: String) {
        searchKey = ""
        search()
    }

    func tkSearchBar(didReturn searchBar: TKSearchBar) {
        search()
    }

    func tkSearchBar(textChanged searchBar: TKSearchBar, text: String) {
        logger.debug("搜索内容:\(text)")
        searchKey = text
        search()
    }

    func search() {
        guard searchKey.count > 0 else {
            searchResult = []
            fullMatch = false
            collectionView.reloadData()
            collectionView.borderWidth = 0
            collectionView.cornerRadius = 0
            collectionView.snp.remakeConstraints { make in
                make.top.equalTo(navigationBar.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            }
            return
        }
        
        searchResult = data.filter { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().contains(searchKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) }.filterDuplicates({ $0.name })
        fullMatch = !searchResult.filter { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == searchKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filterDuplicates({ $0.name }).isEmpty
        logger.debug("搜索结果数量: \(searchResult.count) | 是否全匹配: \(fullMatch)")
        updateLayout()
        collectionView.reloadData()
        collectionView.setBorder()
        collectionView.cornerRadius = 5
        collectionView.layoutIfNeeded()
        collectionView.snp.remakeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(collectionViewLayout.collectionViewContentSize.height)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
}

extension InstrumentsSelectorViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewLayout = collectionViewLayout as? UICollectionViewFlowLayout
        collectionViewLayout?.scrollDirection = .vertical
        let size: CGSize
        if searchKey != "" {
            size = CGSize(width: collectionView.bounds.width, height: 60)
            collectionViewLayout?.minimumInteritemSpacing = 0
            collectionViewLayout?.minimumLineSpacing = 0
        } else {
            let width = (collectionView.bounds.width / 4) - 6
            let height = width + 30
            size = CGSize(width: width, height: height)
            collectionViewLayout?.minimumInteritemSpacing = 2
            collectionViewLayout?.minimumLineSpacing = 10
        }
        return size
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if searchKey == "" {
            let selectedItem = data[indexPath.item]
            if let cell = collectionView.cellForItem(at: indexPath) as? ProfileEditDetailInstrumentItemCollectionViewCell {
                switch style {
                case .singleSelection:
                    let size = (collectionView.bounds.width / 4) - 6
                    cell.selectedView.corner(size: size / 2)
                    cell.selectedContainerView.layer.removeAllSublayers()
                    cell.selectedView.isHidden = false
                    let successLayer = cell.selectedContainerView.getCheckLayer(containerSize: 40)
                    cell.selectedContainerView.layer.addSublayer(successLayer)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                        guard let self = self else { return }
                        self.selectInstrument(selectedItem)
                    }
                case .multipleSelection:
                    if selectedInstruments.contains(where: { $0.id == selectedItem.id }) {
                        // 已选择,取消选择
                        selectedInstruments.removeElements { $0.id == selectedItem.id }
                        cell.selectedView.isHidden = true
                        cell.selectedContainerView.layer.removeAllSublayers()
                    } else {
                        cell.selectedContainerView.layer.removeAllSublayers()
                        let size = (collectionView.bounds.width / 4) - 6
                        cell.selectedView.corner(size: size / 2)
                        cell.selectedView.isHidden = false
                        let layer = cell.selectedContainerView.getCheckLayer(containerSize: 40)
                        cell.selectedContainerView.layer.addSublayer(layer)
                        selectInstrument(selectedItem)
                    }
                }
            }
        } else {
            if fullMatch {
                let selectedItem = searchResult[indexPath.item]
                if let cell = collectionView.cellForItem(at: indexPath) as? InstrumentsSelectorSearchResultItemCollectionViewCell {
                    switch style {
                    case .singleSelection:
                        cell.selectedIconView.layer.removeAllSublayers()
                        cell.selectedIconView.isHidden = false
                        let successLayer = cell.selectedIconView.getCheckLayer(containerSize: 40)
                        cell.selectedIconView.layer.addSublayer(successLayer)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                            guard let self = self else { return }
                            self.selectInstrument(selectedItem)
                        }
                    case .multipleSelection:
                        // 判断是选择还是取消选择
                        if selectedInstruments.contains(where: { $0.id == selectedItem.id }) {
                            // 选择了,取消选择
                            selectedInstruments.removeElements { $0.id == selectedItem.id }
                            cell.selectedIconView.layer.removeAllSublayers()
                            cell.selectedIconView.isHidden = true
                        } else {
                            // 没选择,进行选择
                            cell.selectedIconView.layer.removeAllSublayers()
                            cell.selectedIconView.isHidden = false
                            let successLayer = cell.selectedIconView.getCheckLayer(containerSize: 40)
                            cell.selectedIconView.layer.addSublayer(successLayer)
                            selectInstrument(selectedItem)
                        }
                    }
                }
            } else {
                if indexPath.item == 0 {
                    SL.Alert.show(target: self, title: "Notice", message: "You are creating a new, unlisted category.\nTap \"Confirm\", and our team will verify it within 24 hours.", leftButttonString: "Go back", rightButtonString: "Confirm") {
                    } rightButtonAction: { [weak self] in
                        guard let self = self else { return }
                        self.createNewInstrument(self.searchKey)
                    }
                } else {
                    let selectedItem = searchResult[indexPath.item - 1]
                    if let cell = collectionView.cellForItem(at: indexPath) as? InstrumentsSelectorSearchResultItemCollectionViewCell {
                        switch style {
                        case .singleSelection:
                            let successLayer = cell.selectedIconView.getCheckLayer(containerSize: 40)
                            cell.selectedIconView.layer.addSublayer(successLayer)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                                guard let self = self else { return }
                                self.selectInstrument(selectedItem)
                            }
                        case .multipleSelection:
                            if selectedInstruments.contains(where: { $0.id == selectedItem.id }) {
                                cell.selectedIconView.layer.removeAllSublayers()
                                selectedInstruments.removeElements { $0.id == selectedItem.id }
                                cell.selectedIconView.isHidden = true
                            } else {
                                cell.selectedIconView.isHidden = false
                                let successLayer = cell.selectedIconView.getCheckLayer(containerSize: 40)
                                cell.selectedIconView.layer.addSublayer(successLayer)
                                selectInstrument(selectedItem)
                            }
                        }
                    }
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searchKey == "" {
            return data.count
        } else {
            return searchResult.count + (fullMatch ? 0 : 1)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if searchKey == "" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ProfileEditDetailInstrumentItemCollectionViewCell.self), for: indexPath) as! ProfileEditDetailInstrumentItemCollectionViewCell
            let item = data[indexPath.item]
            cell.loadData(data: item)
            if selectedInstruments.contains(where: { $0.id == item.id }) {
                let size = (collectionView.bounds.width / 4) - 6
                cell.selectedView.corner(size: size / 2)
                cell.selectedView.isHidden = false
                let successLayer = cell.selectedContainerView.getCheckLayer(containerSize: 40, animated: false)
                cell.selectedContainerView.layer.addSublayer(successLayer)
            } else {
                cell.selectedContainerView.layer.removeAllSublayers()
                cell.selectedView.isHidden = true
            }
            cell.contentView.backgroundColor = ColorUtil.backgroundColor
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: InstrumentsSelectorSearchResultItemCollectionViewCell.self), for: indexPath) as! InstrumentsSelectorSearchResultItemCollectionViewCell
            if fullMatch {
                let data = searchResult[indexPath.item]
                cell.nameLabel.attributedText = Tools.attributenStringColor(text: data.name.trimmingCharacters(in: .whitespacesAndNewlines), selectedText: searchKey.trimmingCharacters(in: .whitespacesAndNewlines), allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 18), fontSize: 18, selectedFontSize: 18, ignoreCase: true, charasetSpace: 0)
                cell.iconView.contentMode = .scaleAspectFit
                cell.iconView.sd_setImage(with: URL(string: data.minPictureUrl))
                if indexPath.item == searchResult.count - 1 {
                    cell.lineView.isHidden = true
                    cell.backView.showShadow()
                } else {
                    cell.lineView.isHidden = false
                    cell.backView.showShadow(color: .clear)
                }

                cell.selectedIconView.layer.removeAllSublayers()
                if selectedInstruments.contains(where: { $0.id == data.id }) {
                    cell.selectedIconView.isHidden = false
                    let layer = cell.selectedIconView.getCheckLayer(containerSize: 40, color: ColorUtil.main, animated: false, duration: 0)
                    cell.selectedIconView.layer.addSublayer(layer)
                } else {
                    cell.selectedIconView.isHidden = true
                }

            } else {
                // 有一个新加的
                if indexPath.item == 0 {
                    cell.nameLabel.text(searchKey)
                    if #available(iOS 13.0, *) {
                        cell.iconView.image = UIImage(named: "8|8_selected")?.resizeImage(CGSize(width: 35, height: 35)).withTintColor(ColorUtil.gray)
                    } else {
                        cell.iconView.image = UIImage(named: "8|8")?.resizeImage(CGSize(width: 35, height: 35))
                    }
                    cell.iconView.setBorder()
                    cell.iconView.contentMode = .center
                    cell.lineView.isHidden = false
                } else {
                    let data = searchResult[indexPath.item - 1]
                    cell.nameLabel.attributedText = Tools.attributenStringColor(text: data.name.trimmingCharacters(in: .whitespacesAndNewlines), selectedText: searchKey.trimmingCharacters(in: .whitespacesAndNewlines), allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 18), fontSize: 18, selectedFontSize: 18, ignoreCase: true, charasetSpace: 0)
                    if data.minPictureUrl != "" {
                        cell.iconView.contentMode = .scaleAspectFit
                        cell.iconView.sd_setImage(with: URL(string: data.minPictureUrl))
                    } else {
                        cell.iconView.contentMode = .center
                        if #available(iOS 13.0, *) {
                            cell.iconView.image = UIImage(named: "8|8_selected")?.resizeImage(CGSize(width: 35, height: 35)).withTintColor(ColorUtil.gray)
                        } else {
                            cell.iconView.image = UIImage(named: "8|8")?.resizeImage(CGSize(width: 35, height: 35))
                        }
                        cell.iconView.setBorder()
                    }
                    if indexPath.item == searchResult.count {
                        cell.lineView.isHidden = true
                        cell.backView.showShadow()
                    } else {
                        cell.backView.showShadow(color: .clear)
                        cell.lineView.isHidden = false
                    }
                    cell.selectedIconView.layer.removeAllSublayers()
                    if selectedInstruments.contains(where: { $0.id == data.id }) {
                        cell.selectedIconView.isHidden = false
                        let layer = cell.selectedIconView.getCheckLayer(containerSize: 40, color: ColorUtil.main, animated: false, duration: 0)
                        cell.selectedIconView.layer.addSublayer(layer)
                    } else {
                        cell.selectedIconView.isHidden = true
                    }
                }
            }
            return cell
        }
    }
}

extension InstrumentsSelectorViewController {
    private func createNewInstrument(_ name: String) {
        guard let id64 = IDUtil.nextId(group: .user)?.description, let userId = UserService.user.id() else { return }
        showFullScreenLoading()
//        let id = Int(id64)
        let instrument = TKInstrument(id: id64, name: name.trimmingCharacters(in: .whitespacesAndNewlines), desc: "", category: 9999999, minPictureUrl: "", creatorId: userId, isSelected: true)
        DatabaseService.collections.instrumentV2()
            .document(id64)
            .setData(instrument.toJSON() ?? [:]) { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("创建instrument失败: \(error)")
                    TKToast.show(msg: "Create instrument failed, please try again later.", style: .error)
                } else {
                    self.selectInstrument(instrument)
                }
            }
    }

    private func selectInstrument(_ instrument: TKInstrument) {
        logger.debug("已选择: \(instrument.toJSONString() ?? "")")
        if instrument.minPictureUrl == "" {
            SL.Alert.show(target: self, title: "Notice", message: "There currently is no icon for this category. Tap \"Confirm\", and our team will create one within 24 hours.", leftButttonString: "Go back", rightButtonString: "Confirm") {
            } rightButtonAction: { [weak self] in
                guard let self = self else { return }
                let msg = "[instrumentId]: \(instrument.id) | [instrumentName]: \(instrument.name)"
                CommonsService.shared.sendEmailFromWebsite(topic: "Update instrument icon", msg: msg)
                self.delegate?.instrumentsSelectorViewController(didSelectInstrument: instrument)
                self.dismiss(animated: true)
            }
        } else {
            delegate?.instrumentsSelectorViewController(didSelectInstrument: instrument)
            dismiss(animated: true)
        }
    }
}

// MARK: - Search result item collection cell

class InstrumentsSelectorSearchResultItemCollectionViewCell: UICollectionViewCell {
    var backView = TKView.create()
        .backgroundColor(color: UIColor.white)

    var nameLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 18))
        .textColor(color: ColorUtil.Font.third)

    var iconView: TKImageView = TKImageView.create()
        .setSize(40)
        .asCircle()

    var selectedIconView: TKView = TKView.create()
        .backgroundColor(color: UIColor.black.withAlphaComponent(0.4))
        .corner(size: 20)

    var lineView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.dividingLine)

    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InstrumentsSelectorSearchResultItemCollectionViewCell {
    private func initViews() {
        backView.addTo(superView: contentView) { make in
            make.edges.equalToSuperview()
        }

        iconView.addTo(superView: backView) { make in
            make.size.equalTo(40)
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        selectedIconView.addTo(superView: backView) { make in
            make.size.equalTo(40)
            make.center.equalTo(iconView)
        }
        selectedIconView.isHidden = true

        nameLabel.addTo(superView: contentView) { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        lineView.addTo(superView: backView) { make in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(1)
        }
    }
}
