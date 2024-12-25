//
//  LessonsDetailMaterialsTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/3.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

protocol LessonsDetailMaterialsTableViewCellDelegate: NSObjectProtocol {
    func lessonsDetailMaterialsTableViewCell(selectedData: [TKMaterial])
    func lessonsDetailMaterialsTableViewCell(click: TKMaterial, materilaCell: MaterialsCell)
//    func lessonsDetailMaterialsTableViewCell(heightChanged height:CGFloat)
}

class LessonsDetailMaterialsTableViewCell: UITableViewCell {
    var data: [TKMaterial] = []
    weak var delegate: LessonsDetailMaterialsTableViewCellDelegate?

    private var backView: TKView!
    private var iconImageView: TKImageView!
    private var titleLabel: TKLabel!
    var addButton: TKButton!
    private var collectionView: UICollectionView!

    private var youtubeCellSize: CGSize!
    private var otherCellSize: CGSize!
    private var isLoad = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonsDetailMaterialsTableViewCell {
    private func initView() {
        if isLoad {
            return
        }
        isLoad = true
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
        contentView.addSubview(backView)
        backView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalTo(self.contentView)
        }

        iconImageView = TKImageView.create()
            .setImage(name: "icMaterials")
            .setSize(22)
        backView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(backView).offset(30)
            make.left.equalTo(backView).offset(20)
            make.size.equalTo(22)
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Materials")
        backView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView.snp.centerY)
            make.height.equalTo(22)
            make.left.equalTo(iconImageView.snp.right).offset(20)
        }

        addButton = TKButton.create()
            .setImage(name: "icAddPrimary", size: CGSize(width: 22, height: 22))
        addButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            logger.debug("add lessons materials button tapped")
            self.delegate?.lessonsDetailMaterialsTableViewCell(selectedData: self.data)
        }
        backView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView)
            make.right.equalTo(backView).offset(-11)
            make.size.equalTo(40)
        }

        youtubeCellSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 150)
        otherCellSize = CGSize(width: (UIScreen.main.bounds.width - 50) / 3, height: (UIScreen.main.bounds.width - 50) / 3)

        let collectionViewLayout = DGCollectionViewLeftAlignFlowLayout()
//        collectionViewLayout.scrollDirection = .vertical
//        collectionViewLayout.horizontalAlignment = .left
//        collectionViewLayout.verticalAlignment = .top
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 5
//        collectionViewLayout.sectionInsetReference = .fromLayoutMargins
//        collectionViewLayout.estimatedItemSize = CGSize(width: (UIScreen.main.bounds.width - 50) / 3, height: 100)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = UIColor.white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.register(MaterialsCell.self, forCellWithReuseIdentifier: String(describing: MaterialsCell.self))
        backView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalTo(backView).offset(20)
            make.right.equalTo(backView).offset(-20)
            make.bottom.equalTo(backView).offset(-10).priority(.medium)
//            make.height.equalTo(0).priority(.medium)
        }

        let bottomLine = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
        backView.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    func loadData(data: [TKMaterial], height: CGFloat) {
        let folders = data.filter { $0.type == .folder }.compactMap { $0.id }
        self.data = data.filter { $0.folder == "" || ($0.folder != "" && !folders.contains($0.folder)) || $0.type == .folder }
        collectionView.reloadData()
    }
}

extension LessonsDetailMaterialsTableViewCell: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    // 组内缩进
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 50) / 3

        if data[indexPath.row].type == .youtube {
            return CGSize(width: UIScreen.main.bounds.width - 40, height: 150 + 76)
        } else {
            return CGSize(width: width, height: width + 51)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let id = String(describing: MaterialsCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! MaterialsCell
        print("个数-1---\(indexPath.row)====\(indexPath.item)")

        cell.cellInitialSize = data[indexPath.row].type == .youtube ? youtubeCellSize : otherCellSize
        cell.edit(false)
        cell.delegate = self
        cell.initData(materialsData: data[indexPath.row], isShowStudentAvatarView: false)
        return cell
    }

    func getMaterialsHeight() -> CGFloat {
        let folders = data.filter { $0.type == .folder }.compactMap { $0.id }
        data = data.filter { $0.folder == "" || ($0.folder != "" && !folders.contains($0.folder)) || $0.type == .folder }
        var height: CGFloat = 0
        var num = 0
        let screenWidth = UIScreen.main.bounds.width
        let width = (screenWidth - 50) / 3
        for item in data {
            if item.type == .youtube {
                height = height + 210 + 20
                num = 0
            } else {
                if num < 3 {
                    num = num + 1
                    if num == 1 {
                        height = height + width + 35 + 20
                    }
                } else {
                    num = 1
                    height = height + width + 35 + 20
                }
            }
        }
        return height
    }
}

extension LessonsDetailMaterialsTableViewCell: MaterialsCellDelegate {
    func materialsCell(shareButtonTappedAt index: Int, cell: MaterialsCell) {
        
    }
    func materialsCell(checkBoxDidTappedAt index: Int, materialsData: TKMaterial, cell: MaterialsCell) {
        delegate?.lessonsDetailMaterialsTableViewCell(click: materialsData, materilaCell: cell)
    }

    func materialsCell(titleLabelDidSelectedAt index: Int, cell: MaterialsCell) {
    }

    func clickItem(materialsData: TKMaterial, cell: MaterialsCell) {
        delegate?.lessonsDetailMaterialsTableViewCell(click: materialsData, materilaCell: cell)
    }
}
