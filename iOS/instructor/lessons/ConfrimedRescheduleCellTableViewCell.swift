//
//  ConfrimedRescheduleCellTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2020/8/29.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class ConfrimedRescheduleCellTableViewCell: UITableViewCell {
    
    private var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 15))
        .textColor(color: ColorUtil.Font.primary)
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
