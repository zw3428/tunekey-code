//
//  StudentDetailsMemoTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2023/1/14.
//  Copyright © 2023 spelist. All rights reserved.
//

import SnapKit
import UIKit

class StudentDetailsMemoTableViewCell: UITableViewCell {
    static let id: String = String(describing: StudentDetailsMemoTableViewCell.self)
    @Live var memo: String = ""
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension StudentDetailsMemoTableViewCell {
    private func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                HStack(alignment: .top, spacing: 20) {
                    ImageView(image: UIImage(named: "icTerms")).size(width: 22, height: 22)
                    VStack(spacing: 10) {
                        HStack(alignment: .center, spacing: 10) {
                            Label("Memo").textColor(ColorUtil.Font.third)
                                .font(FontUtil.bold(size: 18))
                            Label($memo).textColor(ColorUtil.Font.primary)
                                .font(FontUtil.regular(size: 13))
                                .textAlignment(.right)
                                .numberOfLines(1)
                            ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                        }
                        Label("Add memo, address, or parents contact etc.").textColor(ColorUtil.Font.primary)
                            .font(FontUtil.regular(size: 13))
                            .numberOfLines(0)
                    }
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
