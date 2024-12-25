//
//  ChangeAccountTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/30.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ChangeAccountTableViewCell: UITableViewCell {
    private var nextButton: TKBlockButton!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ChangeAccountTableViewCell {
    private func initView() {
        let imageView = TKImageView.create()
            .setImage(name: "imgChengeNumber")
            .addTo(superView: contentView) { make in
                make.top.equalToSuperview().offset(60)
                make.centerX.equalToSuperview()
                make.width.equalTo(200)
                make.height.equalTo(120)
            }

        let label1 = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Use Change Number to migrate your account info, groups and settings from your current phone number to a new phone number. You can’t undo this change.")
            .addTo(superView: contentView) { make in
                make.top.equalTo(imageView.snp.bottom).offset(30)
                make.left.equalToSuperview().offset(30)
                make.right.equalToSuperview().offset(-30)
            }
        label1.numberOfLines = 0
        label1.lineBreakMode = .byWordWrapping

        let label2 = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "To proceed, confirm that your new number can receive SMS or calls and tap Next to very that number.")
            .addTo(superView: contentView) { make in
                make.top.equalTo(label1.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(30)
                make.right.equalToSuperview().offset(-30)
            }
        label2.lineBreakMode = .byWordWrapping
        label2.numberOfLines = 0

        nextButton = TKBlockButton(frame: .zero, title: "NEXT")
        contentView.addSubview(view: nextButton) { make in
            make.top.equalTo(label2.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
            make.width.equalTo(180)
            make.height.equalTo(50)
        }

        nextButton.onTapped { _ in
        }
    }
}
