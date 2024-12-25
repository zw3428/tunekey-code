//
//  StudentDetailsBalanceUnpaidItemCollectionViewCell.swift
//  TuneKey
//
//  Created by zyf on 2022/3/3.
//  Copyright © 2022 spelist. All rights reserved.
//

import SnapKit
import UIKit

class StudentDetailsBalanceUnpaidItemCollectionViewCell: UICollectionViewCell, ZReusable {
    static let id: String = String(describing: StudentDetailsBalanceUnpaidItemCollectionViewCell.self)

    @Live var topTitleString: String = "Invoice unpaid"
    @Live var title: String = ""
    @Live var amountString: String = ""
    @Live var lessonTypeString: String = ""
    @Live var paidAmount: String = ""
    @Live var paidAmountColor: UIColor = ColorUtil.Font.primary
    @Live var invoiceInfoString: String = ""
    @Live var dueDateString = ""

    @Live var buttonString: String = ""
    @Live var isButtonEnabled: Bool = true
    @Live var buttonColor: UIColor = ColorUtil.main

    @Live var isStudentView: Bool = false

    var onButtonTapped: (() -> Void)?

    private var containerView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .showShadow()
        .showBorder(color: ColorUtil.borderColor)
        .corner(size: 8)

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentDetailsBalanceUnpaidItemCollectionViewCell {
    private func initView() {
        containerView.addTo(superView: contentView) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10)
        }
        VStack {
            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
                Label($topTitleString)
                    .font(FontUtil.regular(size: 13))
                    .textColor(ColorUtil.Font.primary)
            }.size(width: nil, height: 40)
            ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 0, right: 20)) {
                HStack {
                    Label($title)
                        .textColor(ColorUtil.Font.third)
                        .font(FontUtil.bold(size: 18))
                    Label($amountString)
                        .textColor(ColorUtil.Font.third)
                        .font(FontUtil.bold(size: 18))
                        .textAlignment(.right)
                }
            }.size(width: nil, height: 30)
            ViewBox(paddings: UIEdgeInsets(top: 4, left: 20, bottom: 0, right: 20)) {
                VStack {
                    HStack {
                        Label($lessonTypeString)
                            .textColor(ColorUtil.Font.primary)
                            .font(FontUtil.regular(size: 15))
                            .contentHuggingPriority(.defaultLow, for: .horizontal)
                            .contentCompressionResistancePriority(.defaultLow, for: .horizontal)
                        Spacer(spacing: 20)
                        Label($paidAmount)
                            .textColor($paidAmountColor)
                            .font(FontUtil.regular(size: 15))
                            .contentHuggingPriority(.defaultHigh, for: .horizontal)
                            .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                    }
                    HStack {
                        Label($invoiceInfoString)
                            .textColor(ColorUtil.Font.primary)
                            .font(FontUtil.regular(size: 15))
                        Label($dueDateString)
                            .textColor(ColorUtil.Font.primary)
                            .font(FontUtil.regular(size: 15))
                            .textAlignment(.right)
                    }
                }
            }.size(width: nil, height: 44)
            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
                View()
                    .backgroundColor(ColorUtil.dividingLine)
                    .size(width: nil, height: 1)
            }
            .size(width: nil, height: 21)
//            .isHidden($isStudentView)
            Button()
                .title($buttonString, for: .normal)
                .font(FontUtil.bold(size: 18))
                .titleColor(ColorUtil.main, for: .normal)
                .size(width: nil, height: 61)
//                .isHidden($isStudentView)
                .isEnabled($isButtonEnabled)
                .apply { [weak self] button in
                    guard let self = self else { return }
                    self.$buttonColor.addSubscriber { color in
                        _ = button.titleColor(color, for: .normal)
                    }
                }
                .onTapped { [weak self] _ in
                    self?.onButtonTapped?()
                }
        }
        .addTo(superView: containerView) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}
