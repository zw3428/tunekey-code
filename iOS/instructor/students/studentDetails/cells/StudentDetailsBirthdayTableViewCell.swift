//
//  StudentDetailsBirthdayTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2023/1/11.
//  Copyright © 2023 spelist. All rights reserved.
//

import SnapKit
import UIKit

class StudentDetailsBirthdayTableViewCell: UITableViewCell {
    static let id: String = String(describing: StudentDetailsBirthdayTableViewCell.self)

    @Live var birthday: TimeInterval = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentDetailsBirthdayTableViewCell {
    private func initViews() {
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                HStack(alignment: .top) {
                    ImageView(image: UIImage(named: "ic_birthday")).size(width: 22, height: 22)
                    ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)) {
                        VStack {
                            HStack {
                                Label("Birthday").textColor(ColorUtil.Font.third)
                                    .font(FontUtil.bold(size: 18))
                                    .size(height: 24)
                                    .contentHuggingPriority(.defaultLow, for: .horizontal)
                                    .contentCompressionResistancePriority(.defaultLow, for: .horizontal)
                                Label().textColor(ColorUtil.Font.primary)
                                    .font(FontUtil.regular(size: 13))
                                    .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                    .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$birthday.addSubscriber { birthday in
                                            if birthday == 0 {
                                                label.text = "Optional"
                                            } else {
                                                label.text = Date(seconds: birthday).toLocalFormat("M/d/yyyy")
                                            }
                                        }
                                    }
                            }
                            Spacer(spacing: 10)
                            Label("A pop-up reminder won't let you miss out on the celebration.")
                                .textColor(ColorUtil.Font.primary)
                                .font(FontUtil.regular(size: 13))
                                .numberOfLines(2)
                                .size(height: 40)
                        }
                    }
                    ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                }
            }
            .apply { view in
                _ = view.showShadow()
                    .borderWidth(1)
                    .borderColor(ColorUtil.borderColor)
                    .backgroundColor(.white)
                    .cornerRadius(5)
            }
        }
        .backgroundColor(ColorUtil.backgroundColor)
        .addTo(superView: contentView) { make in
            make.top.left.right.equalToSuperview()
        }
    }
}
