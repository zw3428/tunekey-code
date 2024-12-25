//
//  StudentDetailsBalanceTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2022/3/2.
//  Copyright © 2022 spelist. All rights reserved.
//

import SnapKit
import UIKit

class StudentDetailsBalanceTableViewCell: UITableViewCell {
    static let id: String = String(describing: StudentDetailsBalanceTableViewCell.self)

    @Live var lastPaymentAmount: String = ""
    
    lazy var addInvoiceButton: TKButton = TKButton.create()
        .title(title: "Add invoice")
        .titleColor(color: .white)
        .titleFont(font: FontUtil.bold(size: 10))
        .backgroundColor(color: ColorUtil.main)
        .corner(4)

    private var containerView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 5)
        .showShadow()
        .showBorder(color: ColorUtil.borderColor)

    private var infoView: TKView = TKView.create()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentDetailsBalanceTableViewCell {
    private func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        let leftView = HStack(distribution: .fillProportionally, alignment: .leading, spacing: 20) {
            ImageView().image(UIImage(named: "ic_billing_yellow")!).size(width: 22, height: 22)
            Label().text("Balance").font(FontUtil.bold(size: 18)).textColor(ColorUtil.Font.third)
        }
        let rightView = HStack(distribution: .fill, alignment: .trailing, spacing: 2) {
            VStack {
                Spacer(spacing: 4.5)
                Label().text($lastPaymentAmount).textColor(ColorUtil.Font.fourth).font(FontUtil.regular(size: 13))
                Spacer(spacing: 4.5)
            }
            ImageView().image(UIImage(named: "arrowRight")!).size(width: 22, height: 22)
        }
        containerView.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10)
        }

        rightView.addTo(superView: containerView) { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(24)
        }
        leftView.addTo(superView: containerView) { make in
            make.top.left.equalToSuperview().offset(20)
            make.height.equalTo(24)
        }
        if #available(iOS 15.0, *) {
            addInvoiceButton.configuration?.contentInsets = .init(top: 0, leading: 10, bottom: 0, trailing: 10)
        } else {
            addInvoiceButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        }
        addInvoiceButton.addTo(superView: containerView) { make in
            make.right.equalToSuperview().offset(-42)
            make.height.equalTo(26)
            make.centerY.equalTo(rightView.snp.centerY)
        }
        addInvoiceButton.isHidden = true
        infoView.addTo(superView: containerView) { make in
            make.top.equalTo(leftView.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(62)
            make.right.equalToSuperview().offset(-20)
        }
    }

    func loadData(lastPayment: NSAttributedString?, nextBill: NSAttributedString?) {
        infoView.subviews.forEachItems { view, _ in
            view.removeFromSuperview()
        }
        VStack {
            if let lastPayment = lastPayment {
                Label().attributedText(lastPayment).size(height: 15)
                Spacer(spacing: 2)
            }
            if let nextBill = nextBill {
                HStack(alignment: .firstBaseline) {
                    Label("Unpaid:")
                        .textColor(ColorUtil.Font.fourth)
                        .font(FontUtil.regular(size: 13))
                        .size(width: 52)
                    Label().attributedText(nextBill)
                        .numberOfLines(0)
                }
            }
        }.addTo(superView: infoView) { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}
