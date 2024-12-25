//
//  ProfileEditDetailInstrumentV2TableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2021/6/1.
//  Copyright © 2021 spelist. All rights reserved.
//

import UIKit

protocol ProfileEditDetailInstrumentV2TableViewCellDelegate: AnyObject {
    func profileEditDetailInstrumentV2TableViewCellDidTapped()
}

class ProfileEditDetailInstrumentV2TableViewCell: UITableViewCell {
    weak var delegate: ProfileEditDetailInstrumentV2TableViewCellDelegate?
    
    var instrument: TKInstrument?
    
    var cellHeight: CGFloat = 84
    
    var arrowRightIconView: TKImageView = TKImageView.create()
        .setImage(name: "arrowRight")
    var selectLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.main)
        .text(text: "Select")

    var iconImageView: TKImageView = TKImageView.create()
        .setImage(color: ColorUtil.main)
        .setSize(48)
        .asCircle()

    var nameLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 18))
        .textColor(color: ColorUtil.Font.primary)
    
    var backView = TKView.create()
        .backgroundColor(color: UIColor.white)
        .corner(size: 5)
        .showShadow()
        .showBorder(color: ColorUtil.borderColor)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileEditDetailInstrumentV2TableViewCell {
    func initViews() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        contentView.addSubview(view: backView) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10)
        }
        nameLabel.addTo(superView: backView) { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
        }
        iconImageView.addTo(superView: backView) { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
            make.left.equalToSuperview().offset(20)
        }
        iconImageView.isHidden = true
        
        nameLabel.text("Category")
        
        arrowRightIconView.addTo(superView: backView) { make in
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
            make.centerY.equalToSuperview()
        }
        
        selectLabel.addTo(superView: backView) { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(arrowRightIconView.snp.left).offset(-10)
        }
        
        backView.onViewTapped { [weak self] _ in
            self?.delegate?.profileEditDetailInstrumentV2TableViewCellDidTapped()
        }
    }
    
    func loadData(_ instrument: TKInstrument?) {
        if let instrument = instrument {
            logger.debug("加载已选择的乐器: \(instrument.name)")
            nameLabel.font(font: FontUtil.bold(size: 18))
                .textColor(color: ColorUtil.Font.second)
                .text(text: instrument.name)
            nameLabel.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(iconImageView.snp.right).offset(10)
                make.right.equalTo(arrowRightIconView.snp.left).offset(-10)
            }
            iconImageView.isHidden = false
            if instrument.minPictureUrl == "" {
                iconImageView.setSize(48)
                    .asCircle()
                if #available(iOS 13.0, *) {
                    iconImageView.image = UIImage(named: "8|8")?.withTintColor(ColorUtil.gray)
                } else {
                    iconImageView.image = UIImage(named: "8|8")
                    iconImageView.tintColor = ColorUtil.gray
                }
                iconImageView.setBorder()
            } else {
                iconImageView.borderWidth = 0
                iconImageView.sd_setImage(with: URL(string: instrument.minPictureUrl), completed: nil)
            }
            selectLabel.isHidden = true
        } else {
            iconImageView.isHidden = true
            selectLabel.isHidden = false
            nameLabel.text(text: "Category")
                .font(font: FontUtil.regular(size: 18))
                .textColor(color: ColorUtil.Font.primary)
            nameLabel.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(20)
                make.centerY.equalToSuperview()
            }
        }
    }
}
