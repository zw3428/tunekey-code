//
//  StudentDetailsMaterialsCell.swift
//  TuneKey
//
//  Created by Wht on 2019/8/21.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit
protocol StudentDetailsMaterialsCellDelegate: NSObjectProtocol {
    func clickMaterialsCell()
    func clickCell(materialsData: TKMaterial, cell: MaterialsCell)
    func studentDetailsMaterialsCell(heightChanged height: CGFloat)
}

class StudentDetailsMaterialsCell: UITableViewCell {
    var cellHeight: CGFloat = 82
    var backView: UIView!
    var infoImgView: UIImageView!
    var titleLabel: TKLabel!
    var arrowImgView: UIImageView!
    var collectionView: UICollectionView!
    var data: [TKMaterial] = [] {
        didSet {
            if collectionView != nil {
                collectionView.reloadData()
            }
        }
    }

    private var youtubeCellSize: CGSize!
    private var otherCellSize: CGSize!
    weak var delegate: StudentDetailsMaterialsCellDelegate!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        contentView.onViewTapped { _ in
        }
        backView = UIView()
        contentView.addSubview(backView)
        backView.setTKBorderAndRaius()
        backView.setShadows()
        backView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        backView.backgroundColor = UIColor.white

        backView.onViewTapped { _ in
            self.delegate?.clickMaterialsCell()
        }
//        backView.layer.masksToBounds = true
        youtubeCellSize = CGSize(width: UIScreen.main.bounds.width - 60, height: 150)
        otherCellSize = CGSize(width: (UIScreen.main.bounds.width - 90) / 3, height: (UIScreen.main.bounds.width - 90) / 3)
        infoImgView = UIImageView()
        backView.addSubview(infoImgView)
        infoImgView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }
        infoImgView.image = UIImage(named: "icMaterials")

        arrowImgView = UIImageView()
        backView.addSubview(arrowImgView)
        arrowImgView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }
        arrowImgView.image = UIImage(named: "arrowRight")
        titleLabel = TKLabel()
        backView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(23)
            make.top.equalToSuperview().offset(20)
            make.left.equalTo(infoImgView.snp.right).offset(20)
            make.right.equalTo(arrowImgView.snp.left).offset(-20)
        }
        titleLabel.textColor(color: ColorUtil.Font.third).font(FontUtil.bold(size: 18))
        titleLabel.text("Materials")
        initcollectionView()
    }

    func initcollectionView() {
        let layout = DGCollectionViewLeftAlignFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 5
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView?.backgroundColor = UIColor.white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.bounces = false
        collectionView.allowsSelection = false
        backView.addSubview(collectionView)
        collectionView.register(MaterialsCell.self, forCellWithReuseIdentifier: String(describing: MaterialsCell.self))
        collectionView.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(infoImgView.snp.bottom).offset(20)
        }
        collectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
}

// MARK: - CollectionView

extension StudentDetailsMaterialsCell: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, MaterialsCellDelegate {
    func materialsCell(shareButtonTappedAt index: Int, cell: MaterialsCell) {}
    func materialsCell(checkBoxDidTappedAt index: Int, materialsData: TKMaterial, cell: MaterialsCell) {
        delegate?.clickCell(materialsData: materialsData, cell: cell)
    }

    func materialsCell(titleLabelDidSelectedAt index: Int, cell: MaterialsCell) {
    }

    func clickItem(materialsData: TKMaterial, cell: MaterialsCell) {
        delegate?.clickCell(materialsData: materialsData, cell: cell)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 90) / 3
        return CGSize(width: width, height: width + 51)
//        if data[indexPath.row].type == .youtube {
//            return CGSize(width: UIScreen.main.bounds.width - 60, height: 150 + 66)
//        } else {
//            return CGSize(width: width, height: width + 51)
//        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if data.count < 6 {
        }
        return data.count < 6 ? data.count : 5
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let id = String(describing: MaterialsCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! MaterialsCell
        cell.cellInitialSize = otherCellSize
        cell.delegate = self
        cell.edit(false)
        cell.tag = indexPath.row

        cell.initData(materialsData: data[indexPath.row], isShowStudentAvatarView: false)
        return cell
    }
}

extension StudentDetailsMaterialsCell {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "contentSize" else { return }
        let height = collectionView.contentSize.height
        cellHeight = height + 82
        delegate?.studentDetailsMaterialsCell(heightChanged: cellHeight)
        collectionView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }
}
