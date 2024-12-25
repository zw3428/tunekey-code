//
//  ProfileEditDetailAddInstrumentTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/10.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileEditDetailAddInstrumentTableViewCell: UITableViewCell {
    var cellHeight: CGFloat = 78

    weak var delegate: ProfileEditDetailAddInstrumentTableViewCellDelegate?

    private var backView: TKView!
    private var coverView: TKView!
    private var buttonView: TKView!
    private var tipLabel: TKLabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileEditDetailAddInstrumentTableViewCell {
    private func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow()
            .corner(size: 5)

        contentView.addSubview(view: backView) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(68)
        }

        buttonView = TKView.create()
            .corner(size: 24)
            .showBorder(color: ColorUtil.borderColor)
        backView.addSubview(view: buttonView) { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
            make.left.equalToSuperview().offset(20)
        }

        let addImageView = TKImageView.create()
            .setImage(name: "icAddPrimary")
        buttonView.addSubview(view: addImageView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(17)
        }

        tipLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.main)
            .text(text: "Add instrument")
        backView.addSubview(view: tipLabel) { make in
            make.top.equalToSuperview().offset(24)
//            make.bottom.equalToSuperview().offset(-24)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(20)
        }

        coverView = TKView.create()
            .backgroundColor(color: UIColor.white.withAlphaComponent(0.7))
        backView.addSubview(view: coverView) { make in
            make.size.equalToSuperview()
            make.center.equalToSuperview()
        }

        backView.onViewTapped { [weak self] _ in
            self?.delegate?.profileEditDetailAddInstrumentTableViewCellTapped()
        }
    }

    func enable() {
        coverView.isHidden = true
    }
}

protocol ProfileEditDetailAddInstrumentTableViewCellDelegate: NSObjectProtocol {
    func profileEditDetailAddInstrumentTableViewCellTapped()
}
