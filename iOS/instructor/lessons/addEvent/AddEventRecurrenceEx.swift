//
//  AddEventRecurrenceEx.swift
//  TuneKey
//
//  Created by WHT on 2020/3/10.
//  Copyright © 2020 spelist. All rights reserved.
//

import Foundation
extension AddEventController {
    func recurrenceChangeData() {
        data.repeatType = recurrenceData.repeatType
        data.repeatTypeWeekDay = recurrenceData.repeatTypeWeekDay
        data.repeatTypeMonthDayType = recurrenceData.repeatTypeMonthDayType
        data.repeatTypeMonthDay = recurrenceData.repeatTypeMonthDay
    }

    func resetRecurrenceData() {
        recurrenceData.repeatType = .none
        recurrenceSwitch.isOn = false
        _ = monthlySameWeekDayButton.setImage(name: monthlySelectedButtonImage)
        _ = monthlySameMonthDayButton.setImage(name: monthlyUnselectedButtonImage)
        initEndViewData(isOpend: false)
        updateCell()
    }
}

extension AddEventController {
    func initrecurrenceView() {
        recurrenceView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
            .showShadow()

        contentView.addSubview(recurrenceView)
        recurrenceView.snp.makeConstraints { make in
            make.top.equalTo(endTimeView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        recurrenceContentView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
        recurrenceContentView.clipsToBounds = true
        recurrenceView.addSubview(recurrenceContentView)
        recurrenceContentView.snp.makeConstraints { make in
            make.height.equalTo(64)
            make.top.left.right.bottom.equalToSuperview()
        }

        recurrenceTitleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
            .text(text: "Recurrence")
        recurrenceContentView.addSubview(recurrenceTitleLabel)
        recurrenceTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(21)
            make.left.equalToSuperview().offset(20)
        }

        recurrenceSwitch = TKSwitch()
        recurrenceContentView.addSubview(recurrenceSwitch)
        recurrenceSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(self.recurrenceTitleLabel.snp.centerY)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(self.recurrenceSwitch.size)
        }
        recurrenceSwitch.isEnabled = true
        recurrenceSwitch.isOn = false
        recurrenceSwitch.onValueChanged { [weak self] isOn in
            guard let self = self else { return }
            if isOn {
                self.recurrenceData.repeatType = .weekly
                self.initEndViewData(isOpend: true)
            } else {
                self.recurrenceData.repeatType = .none
                self.initEndViewData(isOpend: false)
            }
            self.updateCell()
        }
        initWeeklyView()
        initBiWeeklyView()
        initMonthlyView()
    }

    private func initWeeklyView() {
        weeklyView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: recurrenceContentView, withConstraints: { make in
                make.top.equalToSuperview().offset(64)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            })
        weeklyView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.recurrenceData.repeatType = .weekly
            self.updateCell()
            for view in self.weeklyDaysStackView.arrangedSubviews {
                var isSelectedDay: Bool = false
                if self.recurrenceData.repeatTypeWeekDay.contains(view.tag) {
                    isSelectedDay = true
                }
                view.backgroundColor = isSelectedDay ? ColorUtil.main : UIColor.white
                view.borderColor = isSelectedDay ? ColorUtil.main : ColorUtil.borderColor
                if let label = view.subviews.first, label is TKLabel {
                    _ = (label as! TKLabel).textColor(color: isSelectedDay ? UIColor.white : ColorUtil.Font.primary)
                }
            }
        }

        weeklyView.clipsToBounds = true
        weeklyTitleLabel = getTitleLabel(title: "Weekly")
        weeklyView.addSubview(view: weeklyTitleLabel) { make in
            make.top.equalToSuperview().offset(22)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(20)
        }

        weeklyCheckImageView = getCheckImageView()
        weeklyView.addSubview(view: weeklyCheckImageView) { make in
            make.centerY.equalTo(weeklyTitleLabel.snp.centerY)
            make.size.equalTo(22)
            make.right.equalToSuperview().offset(-20)
        }
        weeklyCheckImageView.isHidden = true

        weeklyDaysStackView = getWeekDaysStackView { [weak self] isSelected, dayOfWeek in
            guard let self = self else { return }
            logger.debug("weekly days selected: \(dayOfWeek)")
            guard self.recurrenceData.repeatType == .weekly else {
                return
            }
            if isSelected {
                if !self.recurrenceData.repeatTypeWeekDay.contains(dayOfWeek) {
                    self.recurrenceData.repeatTypeWeekDay.append(dayOfWeek)
                }
            } else {
                if let index = self.recurrenceData.repeatTypeWeekDay.firstIndex(of: dayOfWeek) {
                    self.recurrenceData.repeatTypeWeekDay.remove(at: index)
                }
            }
            self.recurrenceChangeData()
        }

        weeklyView.addSubview(view: weeklyDaysStackView) { make in
            make.top.equalToSuperview().offset(64)
            make.height.equalTo(40)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        // 初始化数据让点击后自带一个星期1
        for view in weeklyDaysStackView.arrangedSubviews {
            var isSelectedDay: Bool = false
            if recurrenceData.repeatTypeWeekDay.contains(view.tag) {
                isSelectedDay = true
            }
            view.backgroundColor = isSelectedDay ? ColorUtil.main : UIColor.white
            view.borderColor = isSelectedDay ? ColorUtil.main : ColorUtil.borderColor
            if let label = view.subviews.first, label is TKLabel {
                _ = (label as! TKLabel).textColor(color: isSelectedDay ? UIColor.white : ColorUtil.Font.primary)
            }
        }
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: weeklyView, withConstraints: { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview()
            })
    }

    private func initBiWeeklyView() {
        biWeeklyView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: recurrenceContentView, withConstraints: { make in
                make.top.equalTo(weeklyView.snp.bottom)
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(64)
            })
        biWeeklyView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.recurrenceData.repeatType = .biWeekly
            self.updateCell()
            for view in self.biWeeklyDaysStackView.arrangedSubviews {
                var isSelectedDay: Bool = false
                if self.recurrenceData.repeatTypeWeekDay.contains(view.tag) {
                    isSelectedDay = true
                }
                view.backgroundColor = isSelectedDay ? ColorUtil.main : UIColor.white
                view.borderColor = isSelectedDay ? ColorUtil.main : ColorUtil.borderColor
                if let label = view.subviews.first, label is TKLabel {
                    _ = (label as! TKLabel).textColor(color: isSelectedDay ? UIColor.white : ColorUtil.Font.primary)
                }
            }
        }

        biWeeklyView.clipsToBounds = true
        biWeeklyTitleLabel = getTitleLabel(title: "Bi-weekly")
        biWeeklyView.addSubview(view: biWeeklyTitleLabel) { make in
            make.top.equalToSuperview().offset(22)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(20)
        }

        biWeeklyCheckImageView = getCheckImageView()
        biWeeklyView.addSubview(view: biWeeklyCheckImageView) { make in
            make.centerY.equalTo(biWeeklyTitleLabel.snp.centerY)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }
        biWeeklyCheckImageView.isHidden = true

        biWeeklyDaysStackView = getWeekDaysStackView { [weak self] isSelected, dayOfWeek in
            guard let self = self else { return }
            logger.debug("bi weekly days selected: \(dayOfWeek)")
            guard self.recurrenceData.repeatType == .biWeekly else {
                return
            }
            if isSelected {
                if !self.recurrenceData.repeatTypeWeekDay.contains(dayOfWeek) {
                    self.recurrenceData.repeatTypeWeekDay.append(dayOfWeek)
                }
            } else {
                // MARK: - index:of -> firstIndex:of

                if let index = self.recurrenceData.repeatTypeWeekDay.firstIndex(of: dayOfWeek) {
                    self.recurrenceData.repeatTypeWeekDay.remove(at: index)
                }
            }
            self.recurrenceChangeData()
        }

        biWeeklyView.addSubview(view: biWeeklyDaysStackView) { make in
            make.top.equalToSuperview().offset(64)
            make.height.equalTo(40)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: biWeeklyView, withConstraints: { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview()
            })
    }

    private func initMonthlyView() {
        monthlyView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: recurrenceContentView, withConstraints: { make in
                make.top.equalTo(biWeeklyView.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            })
        monthlyView.clipsToBounds = true
        monthlyView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.recurrenceData.repeatType = .monthly
            self.recurrenceData.repeatTypeMonthDay = self.getRepeatTypeMontyDay()
            self.updateCell()
        }

        monthlyTitleLabel = getTitleLabel(title: "Monthly")
        monthlyView.addSubview(view: monthlyTitleLabel) { make in
            make.top.equalToSuperview().offset(22)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(20)
        }

        monthlyCheckImageView = getCheckImageView()
        monthlyView.addSubview(view: monthlyCheckImageView) { make in
            make.centerY.equalTo(monthlyTitleLabel.snp.centerY)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }

        let monthlySameWeekDayView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: monthlyView) { make in
                make.top.equalToSuperview().offset(64)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            }

        monthlySameWeekDayButton = TKImageView.create()
            .setImage(name: monthlySelectedButtonImage)
            .addTo(superView: monthlySameWeekDayView) { make in
                make.centerY.equalToSuperview()
                make.size.equalTo(22)
                make.left.equalToSuperview().offset(40)
            }

        monthlySameWeekDayTitleLabel = getTitleLabel(title: "On 2nd Tuesday")
        monthlySameWeekDayView.addSubview(view: monthlySameWeekDayTitleLabel) { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(monthlySameWeekDayButton.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
        }

        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: monthlySameWeekDayView, withConstraints: { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(40)
                make.right.equalToSuperview()
            })

        let monthlySameMonthDayView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: monthlyView) { make in
                make.top.equalTo(monthlySameWeekDayView.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            }

        monthlySameMonthDayButton = TKImageView.create()
            .setImage(name: monthlyUnselectedButtonImage)
            .addTo(superView: monthlySameMonthDayView) { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(40)
                make.size.equalTo(22)
            }
        monthlySameMonthDayTitleLabel = getTitleLabel(title: "On the 12th")
        monthlySameMonthDayView.addSubview(view: monthlySameMonthDayTitleLabel) { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(monthlySameMonthDayButton.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
        }

        monthlySameWeekDayView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if let date = self.selectedDate {
                _ = self.monthlySameWeekDayButton.setImage(name: self.monthlySelectedButtonImage)
                _ = self.monthlySameMonthDayButton.setImage(name: self.monthlyUnselectedButtonImage)
                if date.getweeksInAMonth() == date.getWeekOfMonth() {
                    self.recurrenceData.repeatTypeMonthDayType = .dayOfLastWeek
                } else {
                    self.recurrenceData.repeatTypeMonthDayType = .dayOfWeek
                }
                self.recurrenceData.repeatTypeMonthDay = self.getRepeatTypeMontyDay()
                self.recurrenceChangeData()
            }
        }

        monthlySameMonthDayView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if let date = self.selectedDate {
                _ = self.monthlySameWeekDayButton.setImage(name: self.monthlyUnselectedButtonImage)
                _ = self.monthlySameMonthDayButton.setImage(name: self.monthlySelectedButtonImage)
                if date.getMonthDay() == date.day {
                    self.recurrenceData.repeatTypeMonthDayType = .endOfMonth
                } else {
                    self.recurrenceData.repeatTypeMonthDayType = .day
                }
                self.recurrenceData.repeatTypeMonthDay = self.getRepeatTypeMontyDay()
                self.recurrenceChangeData()
            }
        }
    }
}

extension AddEventController {
    func getRepeatTypeMontyDay() -> String {
        if let date = self.selectedDate {
            switch recurrenceData.repeatTypeMonthDayType {
            case .dayOfWeek:
                return "\(date.getWeekOfMonth()):\(date.getWeekday())"
            case .dayOfLastWeek:
                return "\(date.getWeekday())"
            case .day:
                return "\(date.day)"
            case .endOfMonth:
                return "\(date.day)"
            }
        }

        return ""
    }

    func getTitleLabel(title: String) -> TKLabel {
        return TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
            .text(text: title)
    }

    func getCheckImageView() -> TKImageView {
        return TKImageView.create()
            .setImage(name: "checkPrimary")
            .setSize(22)
    }

    func getWeekDaysStackView(onDayTapped: @escaping (_ isSelected: Bool, Int) -> Void) -> UIStackView {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.spacing = 2
        for i in 0 ... 6 {
            let view = TKView.create()
                .backgroundColor(color: UIColor.white)
                .showBorder(color: ColorUtil.borderColor)
                .corner(size: 5)
            view.tag = i
            weeklyDaysViews.append(view)

            let titleLabel = TKLabel.create()
                .font(font: FontUtil.bold(size: 13))
                .textColor(color: ColorUtil.Font.primary)
                .text(text: TimeUtil.getWeekDayShotName(weekDay: i))
                .alignment(alignment: .center)
                .addTo(superView: view, withConstraints: { make in
                    make.center.equalToSuperview()
                    make.left.right.equalToSuperview()
                })
            titleLabel.tag = i
            weeklyDaysLabels.append(titleLabel)
            view.onViewTapped { [weak self] _ in
                guard let self = self else { return }
                var isSelected: Bool = false
                if view.backgroundColor == ColorUtil.main {
                    // 已选中
                    if self.recurrenceData.repeatTypeWeekDay.count > 1 {
                        view.backgroundColor = UIColor.white
                        view.borderColor = ColorUtil.borderColor
                        _ = titleLabel.textColor(color: ColorUtil.Font.primary)
                        onDayTapped(isSelected, i)
                    }
                } else {
                    // 未选中,马上选中
                    isSelected = true
                    view.backgroundColor = ColorUtil.main
                    view.borderColor = ColorUtil.main
                    _ = titleLabel.textColor(color: UIColor.white)
                    onDayTapped(isSelected, i)
                }
            }

            stackView.addArrangedSubview(view)
        }
        return stackView
    }

    func updateCell() {
        updateSelectView()
        recurrenceChangeData()
    }

    private func updateSelectView() {
        var heightForWeekly: CGFloat = 64
        var heightForBiweekly: CGFloat = 64
        var heightForMonthly: CGFloat = 64
        weeklyCheckImageView.isHidden = true
        biWeeklyCheckImageView.isHidden = true
        monthlyCheckImageView.isHidden = true

        switch recurrenceData.repeatType {
        case .none:
            heightForWeekly = 0
            heightForBiweekly = 0
            heightForMonthly = 0
        case .weekly:
            heightForWeekly = 124
            weeklyCheckImageView.isHidden = false
        case .biWeekly:
            heightForBiweekly = 124
            biWeeklyCheckImageView.isHidden = false
        case .monthly:
            heightForMonthly = 192  - 64
            monthlyCheckImageView.isHidden = false
            if let date = self.selectedDate {
                var sameMonthDayString = "On the "
                switch date.day {
                case 1: sameMonthDayString += "1st"
                case 2: sameMonthDayString += "2nd"
                case 3: sameMonthDayString += "3rd"
                default: sameMonthDayString += "\(date.day)th"
                }
                if date.getMonthDay() == date.day {
                    sameMonthDayString = "On last day of the month"
                }
                monthlySameMonthDayTitleLabel.text(sameMonthDayString)
                let weekOfMonth = date.getWeekOfMonth()
                var sameWeekDayString = "On the "
                if date.getweeksInAMonth() == weekOfMonth {
                    sameWeekDayString += "every last "
                    if !isEdit {
                        recurrenceData.repeatTypeMonthDayType = .dayOfLastWeek
                    }
                } else {
                    if !isEdit {
                        recurrenceData.repeatTypeMonthDayType = .dayOfWeek
                    }
                    switch weekOfMonth {
                    case 1: sameWeekDayString += "1st "
                    case 2: sameWeekDayString += "2nd "
                    case 3: sameWeekDayString += "3rd "
                    default: sameWeekDayString += "\(weekOfMonth)th "
                    }
                }
                recurrenceData.repeatTypeMonthDay = getRepeatTypeMontyDay()

                sameWeekDayString += date.toFormat("EEEE")

                monthlySameWeekDayTitleLabel.text(sameWeekDayString)
            }
        }
        if recurrenceData.repeatType != .none {
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                self.weeklyView.snp.updateConstraints { make in
                    make.height.equalTo(heightForWeekly)
                }
                self.biWeeklyView.snp.updateConstraints { make in
                    make.height.equalTo(heightForBiweekly)
                }
                self.monthlyView.snp.updateConstraints { make in
                    make.height.equalTo(heightForMonthly)
                }
                self.recurrenceContentView.layoutIfNeeded()
            }
        }

        recurrenceCellHeight = 64 + heightForWeekly + heightForBiweekly + heightForMonthly
        recurrenceContentView.snp.updateConstraints { make in
            make.height.equalTo(recurrenceCellHeight)
        }
        //        delegate?.addLessonScheduleDetailRecurrenceTableViewCell(heightChanged: cellHeight)
    }
}
