//
//  StudentDetailsBalanceItemTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2022/3/2.
//  Copyright © 2022 spelist. All rights reserved.
//

import SnapKit
import UIKit

class StudentDetailsBalanceItemTableViewCell: UITableViewCell {
    
    @Live var title: String = ""
    @Live var amount: String = ""
    
    
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentDetailsBalanceItemTableViewCell {
    private func initView() {
        
    }
}
