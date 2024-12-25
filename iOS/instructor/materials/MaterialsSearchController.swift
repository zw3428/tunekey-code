//
//  MaterialsSearchController.swift
//  TuneKey
//
//  Created by WHT on 2020/3/6.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class MaterialsSearchController: TKSearchViewController {
    private var searchResultView: TKView!
    private var collectionView: UICollectionView!
    var youtubeCellSize: CGSize!
    var otherCellSize: CGSize!
    var materialsData: [TKMaterial] = []
    var showData: [TKMaterial] = []
    init(data: [TKMaterial]) {
        super.init(nibName: nil, bundle: nil)
        materialsData = data
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.focus()
    }
}

// MARK: - View

extension MaterialsSearchController {
    override func initView() {
        super.initView()
        searchResultView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: mainView, withConstraints: { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.top.equalTo(searchView.snp.bottom).offset(24)
            })
        searchBar.delegate = self
        initCollectionView()
    }

    func initCollectionView() {
        youtubeCellSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 150)
        otherCellSize = CGSize(width: (UIScreen.main.bounds.width - 50) / 3, height: (UIScreen.main.bounds.width - 50) / 3)

        let layout = CollectionViewAlignFlowLayout()
        // 上下边距
        layout.minimumLineSpacing = 20
        // 左右边距
        layout.minimumInteritemSpacing = 5
        layout.scrollDirection = .vertical
        layout.sectionInsetReference = .fromLayoutMargins
        layout.estimatedItemSize = CGSize(width: 100, height: 100)
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView?.backgroundColor = ColorUtil.backgroundColor
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        collectionView.dataSource = self
        collectionView.allowsSelection = false
        collectionView.showsVerticalScrollIndicator = false
        searchResultView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        collectionView.register(MaterialsCell.self, forCellWithReuseIdentifier: String(describing: MaterialsCell.self))
    }
}

// MARK: - Data

extension MaterialsSearchController {
    override func initData() {
    }
}

// MARK: - TableView

extension MaterialsSearchController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MaterialsCellDelegate {
    func materialsCell(shareButtonTappedAt index: Int, cell: MaterialsCell) {
    }

    func materialsCell(checkBoxDidTappedAt index: Int, materialsData: TKMaterial, cell: MaterialsCell) {
    }

    func materialsCell(titleLabelDidSelectedAt index: Int, cell: MaterialsCell) {
    }

    // 点击cell
    func clickItem(materialsData: TKMaterial, cell: MaterialsCell) {
        MaterialsHelper.cellClick(materialsData: materialsData, cell: cell, mController: self)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 50) / 3
        if showData[indexPath.row].type == .youtube {
            return CGSize(width: UIScreen.main.bounds.width - 40, height: 150 + 96)
        } else {
            return CGSize(width: width, height: width + 71)
        }
    }

    // 192.33 246
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let id = String(describing: MaterialsCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! MaterialsCell
        cell.cellInitialSize = showData[indexPath.row].type == .youtube ? youtubeCellSize : otherCellSize
        cell.tag = indexPath.row
        cell.edit(false)
        cell.initData(materialsData: showData[indexPath.row])
        cell.delegate = self
        return cell
    }
}

// MARK: - Action

extension MaterialsSearchController: TKSearchBarDelegate {
    func tkSearchBar(textChanged searchBar: TKSearchBar, text: String) {
        search(searchBar, text)
    }

    func search(_ searchBar: TKSearchBar, _ text: String) {
        if text.count == 0 {
            showData.removeAll()
            collectionView.reloadData()
        } else {
            logger.debug("======\(text)")
            showData = []
            let pre3 = NSPredicate(format: "SELF CONTAINS[cd] %@", text.lowercased())
            for item in materialsData {
                if pre3.evaluate(with: item.name.lowercased()) {
                    logger.debug("======232323")
                    showData.append(item)
                }
            }
            collectionView.reloadData()
            if materialsData.count > 0 {
                OperationQueue.main.addOperation {
                    self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
            }
        }
    }
}
