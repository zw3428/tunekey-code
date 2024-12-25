//
//  RescheduleLessonCell.swift
//  TuneKey
//
//  Created by Wht on 2019/12/4.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class RescheduleLessonCell: UITableViewCell {
    private var mainView: TKView!
    private var dayLabel: TKLabel!
    private var monthLabel: TKLabel!
    private var timeLabel: TKLabel!
    private var practiceInfoLabel: TKLabel!
    private var homeworkInfoLabel: TKLabel!
    weak var delegate: RescheduleLessonCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RescheduleLessonCell {
    func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        mainView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow()
            .corner(size: 5)
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(90)
                make.bottom.equalTo(-10).priority(.medium)
            })
        mainView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.rescheduleLesson(clickCell: self)
        }
        dayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 38))
            .alignment(alignment: .center)
            .textColor(color: ColorUtil.main)
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalToSuperview().offset(20)
                make.top.equalToSuperview().offset(10)
                make.width.equalTo(52)
            })
        monthLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 18))
            .textColor(color: ColorUtil.main)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(dayLabel.snp.bottom).offset(-2)
                make.centerX.equalTo(dayLabel)
            })
        timeLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalToSuperview().offset(18)
                make.left.equalTo(dayLabel.snp.right).offset(20)
                make.right.equalToSuperview().offset(-20)
            })
        let practiceLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Practice: ")
            .addTo(superView: mainView) { make in
                make.left.equalTo(dayLabel.snp.right).offset(20)
                make.top.equalTo(timeLabel.snp.bottom).offset(6)
            }
        practiceInfoLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: mainView) { make in
                make.left.equalTo(practiceLabel.snp.right)
                make.top.equalTo(timeLabel.snp.bottom).offset(6)
            }
        let homeworkLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Homework: ")
            .addTo(superView: mainView) { make in
                make.left.equalTo(dayLabel.snp.right).offset(20)
                make.top.equalTo(practiceLabel.snp.bottom)
            }
        homeworkInfoLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: mainView) { make in
                make.left.equalTo(homeworkLabel.snp.right)
                make.top.equalTo(practiceInfoLabel.snp.bottom)
            }
    }

    func initData() {
        dayLabel.text("15")
        monthLabel.text("Jul")
        timeLabel.text("Next lesson, 3:00 pm")
    }
}

protocol RescheduleLessonCellDelegate: NSObjectProtocol {
    func rescheduleLesson(clickCell cell: RescheduleLessonCell)
}
