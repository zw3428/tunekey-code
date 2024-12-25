//
//  LessonSearchSchedulCell.swift
//  TuneKey
//
//  Created by wht on 2020/4/2.
//  Copyright © 2020 spelist. All rights reserved.
//

import Foundation
import UIKit

class LessonSearchSchedulCell: UITableViewCell {
    private var mainView: TKView!
    private var dayLabel: TKLabel!
    private var monthLabel: TKLabel!
    private var timeLabel: TKLabel!
    private var data: TKLessonSchedule!
    private var yearLabel: TKLabel!

    weak var delegate: LessonSearchSchedulCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonSearchSchedulCell {
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
            self.delegate?.lessonSearchSchedul(clickCell: self)
        }
        yearLabel = TKLabel.create()
            .font(font: FontUtil.medium(size: 13))
            .textColor(color: ColorUtil.Font.fourth)
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalToSuperview().offset(20)
                make.top.equalToSuperview().offset(16)

            })

        dayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 38))
            .textColor(color: ColorUtil.main)
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalToSuperview().offset(20)
                make.top.equalTo(yearLabel.snp.bottom)
            })
        monthLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.main)
            .addTo(superView: mainView, withConstraints: { make in
                make.bottom.equalTo(dayLabel.snp.bottom).offset(-5)
                make.left.equalTo(dayLabel.snp.right).offset(5)
            })

        timeLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: mainView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(monthLabel.snp.right).offset(20)
//                make.right.equalToSuperview().offset(-20)
            })
    
    }

    func initData(data: TKLessonSchedule) {
        self.data = data
        let d = TimeUtil.changeTime(time: data.getShouldDateTime())
        dayLabel.text("\(d.day)")
        yearLabel.text("\(d.year)")
        monthLabel.text("\(TimeUtil.getMonthShortName(month: d.month))")
        tkDF.dateFormat = Locale.is12HoursFormat() ? "hh:mm a": "HH:mm"
        timeLabel.text("\(tkDF.string(from: d))")
//
//        timeLabel.text("\(tkDF.string(from: d)) - \(tkDF.string(from: TimeUtil.changeTime(time: data.shouldDateTime + Double(data.shouldTimeLength * 60))))")
    }
}

protocol LessonSearchSchedulCellDelegate: NSObjectProtocol {
    func lessonSearchSchedul(clickCell cell: LessonSearchSchedulCell)
}
