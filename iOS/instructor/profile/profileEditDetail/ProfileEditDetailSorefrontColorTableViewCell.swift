//
//  ProfileEditDetailSorefrontColorTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/17.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileEditDetailSorefrontColorTableViewCell: UITableViewCell {
    weak var delegate: ProfileEditDetailSorefrontColorTableViewCellDelegate?

    var cellHeight: CGFloat = 74

    private var backView: TKView!
    private var titleLabel: TKLabel!
    private var colorView: TKView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileEditDetailSorefrontColorTableViewCell: TKViewConfigurer {
    func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
        backView.onViewTapped { [weak self] _ in
            self?.delegate?.profileEditDetailSorefrontColorTableViewCellTapped()
        }
        contentView.addSubview(view: backView) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10)
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
            .text(text: "Background color")
        backView.addSubview(view: titleLabel) { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
        }

        colorView = TKView.create()
            .corner(size: 15)
            .backgroundColor(color: ColorUtil.main)
        backView.addSubview(view: colorView) { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
            make.right.equalToSuperview().offset(-20)
        }
    }

    func loadData(color: UIColor) {
        _ = colorView.backgroundColor(color: color)
    }
}

protocol ProfileEditDetailSorefrontColorTableViewCellDelegate: NSObjectProtocol {
    func profileEditDetailSorefrontColorTableViewCellTapped()
}
