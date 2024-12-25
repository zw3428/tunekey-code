//
//  PraticeHistoryCell.swift
//  TuneKey
//
//  Created by wht on 2020/8/14.
//  Copyright © 2020 spelist. All rights reserved.
//

import Foundation
import UIKit
class PraticeHistoryCell: UITableViewCell {
    private var mainView: TKView!
    var titleLabel: TKLabel!
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PraticeHistoryCell {
    func initView() {
        contentView.backgroundColor = UIColor.white
        mainView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-10)
                make.left.right.equalToSuperview()

            })
        titleLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.second)
            .text(text: "")
            .font(font: FontUtil.regular(size: 17))
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(10)
                make.right.equalToSuperview().offset(-10)
            })
        titleLabel.numberOfLines = 0
    }
}
