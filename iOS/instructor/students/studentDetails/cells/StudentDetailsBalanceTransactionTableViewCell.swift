//
//  StudentDetailsBalanceTransactionTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2022/3/3.
//  Copyright © 2022 spelist. All rights reserved.
//

import SnapKit
import UIKit

class StudentDetailsBalanceTransactionTableViewCell: UITableViewCell {
    static let id: String = String(describing: StudentDetailsBalanceTransactionTableViewCell.self)
    
    @Live var titleString: String = ""
    @Live var amountString: String = ""
    @Live var amountIcon: UIImage? = nil
    @Live var transactionTypeString: String = ""
    @Live var invoiceInfoString: String = ""

    private var containerView: TKView = TKView.create()
        .backgroundColor(color: .white)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentDetailsBalanceTransactionTableViewCell {
    private func initView() {
        containerView.addTo(superView: contentView) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        ViewBox(paddings: UIEdgeInsets(top: 27, left: 20, bottom: 10, right: 20)) {
            VStack {
                HStack {
                    Label($titleString)
                        .textColor(ColorUtil.Font.third)
                        .font(FontUtil.bold(size: 18))
                        .size(width: nil, height: 22)
                    Spacer(spacing: 10)
                    Label($amountString)
                        .textColor(ColorUtil.Font.third)
                        .font(FontUtil.bold(size: 18))
                        .textAlignment(.right)
                        .size(width: nil, height: 22)
                    ImageView()
                        .image($amountIcon)
                        .size(width: 22, height: 22)
                }
                Label($transactionTypeString)
                    .textColor(ColorUtil.Font.fourth)
                    .font(FontUtil.regular(size: 15))
                    .size(width: nil, height: 20)
                Label($invoiceInfoString)
                    .textColor(ColorUtil.Font.fourth)
                    .font(FontUtil.regular(size: 15))
            }
        }
        .addTo(superView: containerView) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}
