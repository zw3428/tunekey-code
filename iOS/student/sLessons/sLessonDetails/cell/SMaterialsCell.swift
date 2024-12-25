//
//  SMaterialsCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/21.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class SMaterialsCell: UITableViewCell {
    private var mainView: TKView!
    private var arrowView: UIImageView!
    var collectionView: UICollectionView!
    // cell中ShowView的Size
    private var youtubeCellSize: CGSize!
    private var otherCellSize: CGSize!
    var materialsData: [TKMaterial] = []
    
    var dataSouce: [TKMaterial] = []

    private var contentHeight: CGFloat = 0
    var cellHeight: CGFloat = 74
    var isShow = false
    weak var delegate: SMaterialsCellDelegate?

    private let tipPointView = TKView.create()
        .backgroundColor(color: ColorUtil.main)
        .corner(size: 3)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SMaterialsCell {
    func initView() {
        contentView.backgroundColor = UIColor.white
        mainView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.edges.equalToSuperview()
            })
        let titleView = TKView.create()
            .addTo(superView: mainView) { make in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(74)
            }
        let iconView = UIImageView()
        iconView.image = UIImage(named: "icMaterials")
        titleView.addSubview(view: iconView) { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(32)
            make.size.equalTo(22)
        }
        _ = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .text(text: "Materials")
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: titleView) { make in
                make.left.equalTo(iconView.snp.right).offset(20)
                make.top.equalTo(32)
            }

        tipPointView.addTo(superView: titleView) { make in
            make.top.equalTo(iconView.snp.top).offset(-3)
            make.left.equalTo(iconView.snp.right)
            make.size.equalTo(6)
        }
        tipPointView.isHidden = true
        arrowView = UIImageView()
        arrowView.image = UIImage(named: "icArrowDown")
        titleView.addSubview(view: arrowView) { make in
            make.size.equalTo(22)
            make.top.equalTo(32)
            make.right.equalTo(-20)
        }
        titleView.onViewTapped { [weak self] _ in
            self?.clickTitleView()
        }
        youtubeCellSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 150)
        otherCellSize = CGSize(width: (UIScreen.main.bounds.width - 50) / 3, height: (UIScreen.main.bounds.width - 50) / 3)
        let layout = CollectionViewAlignFlowLayout()
        layout.layoutDelegate = self
        
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 5
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = false
        collectionView?.backgroundColor = UIColor.white
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        collectionView.dataSource = self
        collectionView.allowsSelection = false
        collectionView.showsVerticalScrollIndicator = false
        mainView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(0)
            make.right.equalToSuperview().offset(-20)
        }
        collectionView.register(MaterialsCell.self, forCellWithReuseIdentifier: String(describing: MaterialsCell.self))

        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: mainView) { make in
                make.bottom.right.equalToSuperview()
                make.height.equalTo(0)
                make.left.equalToSuperview().offset(20)
            }
    }
}

extension SMaterialsCell {
    func newMsg(_ newMsg: Bool, isShow: Bool) {
        self.isShow = isShow
        tipPointView.isHidden = !newMsg
        if self.isShow {
            arrowView.transform = CGAffineTransform.identity
                .rotated(by: CGFloat(Double.pi))
        } else {
            arrowView.transform = CGAffineTransform.identity
        }
        collectionView.snp.updateConstraints({ make in
            if self.isShow {
                make.height.equalTo(self.contentHeight)
            } else {
                make.height.equalTo(0)
            }
        })
    }
}

extension SMaterialsCell: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, MaterialsCellDelegate, CollectionViewAlignFlowLayoutDelegate {
    func sizeOfItemAt(collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 50) / 3
        if dataSouce[indexPath.row].type == .youtube {
            return CGSize(width: UIScreen.main.bounds.width - 40, height: 150 + 76)
        } else {
            return CGSize(width: width, height: width + 61)
        }
    }
    
    func materialsCell(checkBoxDidTappedAt index: Int, materialsData: TKMaterial, cell: MaterialsCell) {
        delegate?.materialsCell(clickMaterial: self, material: materialsData, materialCell: cell)
    }
    func getMaterialsHeight() {
        arrowView.isHidden = materialsData.count == 0
        //判断当前的文件有没有folder,如果有,则判断folder是否也被分享,如果有,则隐藏当前的文件
        let folders: [String] = materialsData.filter { $0.type == .folder }.compactMap { $0.id }
        dataSouce = []
        for item in materialsData {
            if item.type != .folder && item.folder != "" {
                //当前文件有父文件夹
                if folders.contains(item.folder) {
                    continue
                }
            }
            dataSouce.append(item)
        }
        var height: CGFloat = 0
        var num = 0
        for item in dataSouce {
            if item.type == .youtube {
                height = height + 226 + 20
                num = 0
            } else {
                if num < 3 {
                    num = num + 1
                    if num == 1 {
                        height = height + 172.33 + 20
                    }
                } else {
                    num = 1
                    height = height + 172.33 + 20
                }
            }
        }
        if height != 0 {
            contentHeight = height - 20
        }
        collectionView.reloadData()
    }

    func materialsCell(titleLabelDidSelectedAt index: Int, cell: MaterialsCell) {
    }
    func materialsCell(shareButtonTappedAt index: Int, cell: MaterialsCell){
        
    }

    // 点击cell
    func clickItem(materialsData: TKMaterial, cell: MaterialsCell) {
//        MaterialsHelper.cellClick(materialsData: materialsData, cell: cell, mController: self)
        delegate?.materialsCell(clickMaterial: self, material: materialsData, materialCell: cell)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 50) / 3
        if dataSouce[indexPath.row].type == .youtube {
            return CGSize(width: UIScreen.main.bounds.width - 40, height: 150 + 76)
        } else {
            return CGSize(width: width, height: width + 61)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSouce.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let id = String(describing: MaterialsCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! MaterialsCell
        cell.cellInitialSize = dataSouce[indexPath.row].type == .youtube ? youtubeCellSize : otherCellSize
        cell.tag = indexPath.row
        cell.initData(materialsData: dataSouce[indexPath.row], isShowStudentAvatarView: false)
        cell.delegate = self
        return cell
    }

    // MARK: - clickTitleView

    func clickTitleView() {
        isShow = !isShow
        cellHeight = isShow ? (74 + contentHeight) : 74
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            if self.isShow {
                self.arrowView.transform = CGAffineTransform.identity
                    .rotated(by: CGFloat(Double.pi))
            } else {
                self.arrowView.transform = CGAffineTransform.identity
            }

            self.collectionView.snp.updateConstraints({ make in
                if self.isShow {
                    make.height.equalTo(self.contentHeight)
                } else {
                    make.height.equalTo(0)
                }
            })
            self.layoutIfNeeded()
        }
        delegate?.materialsCell(clickCell: self, cellHeight: cellHeight, isShow: isShow)
    }
}

protocol SMaterialsCellDelegate: NSObjectProtocol {
    func materialsCell(clickCell cell: SMaterialsCell, cellHeight: CGFloat, isShow: Bool)
    func materialsCell(clickMaterial cell: SMaterialsCell, material: TKMaterial, materialCell: MaterialsCell)
}
