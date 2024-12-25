//
//  StudentDetailsAttendanceTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2023/1/13.
//  Copyright © 2023 spelist. All rights reserved.
//

import UIKit

class StudentDetailsAttendanceTableViewCell: UITableViewCell {
    static let id: String = String(describing: StudentDetailsAttendanceTableViewCell.self)

    @Live var latestAttendance: String = ""
    var cellHeight: CGFloat = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentDetailsAttendanceTableViewCell {
    private func initView() {
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                HStack(alignment: .top) {
                    ImageView(image: UIImage(named: "icTerms")?.imageWithTintColor(color: ColorUtil.main)).size(width: 22, height: 22)
                    ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)) {
                        VStack(spacing: 10) {
                            HStack {
                                Label("Attendance").textColor(ColorUtil.Font.third)
                                    .font(FontUtil.bold(size: 18))
                                    .size(height: 24)
                                    .contentHuggingPriority(.defaultLow, for: .horizontal)
                                    .contentCompressionResistancePriority(.defaultLow, for: .horizontal)
                                Label().textColor(ColorUtil.Font.primary)
                                    .font(FontUtil.regular(size: 13))
                                    .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                    .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                            }
                            Label($latestAttendance)
                                .textColor(ColorUtil.Font.primary)
                                .font(FontUtil.regular(size: 13))
                                .numberOfLines(2)
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$latestAttendance.addSubscriber { attendance in
                                        label.isHidden = attendance.isEmpty
                                    }
                                }
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

extension StudentDetailsAttendanceTableViewCell {
    func getCellHeight() -> CGFloat {
        if latestAttendance.isEmpty {
            cellHeight = 84
        } else {
            let height = latestAttendance.heightWithFont(font: FontUtil.regular(size: 13), fixedWidth: UIScreen.main.bounds.width - 144)
            cellHeight = height + 94
        }
        return cellHeight
    }
}
