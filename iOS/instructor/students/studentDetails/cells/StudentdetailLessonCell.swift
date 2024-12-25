//
//  StudentdetailLessonCell.swift
//  TuneKey
//
//  Created by wht on 2020/6/29.
//  Copyright © 2020 spelist. All rights reserved.
//

import SwiftDate
import UIKit

class StudentdetailLessonCell: UITableViewCell {
    var mainView: TKView!
    private var titleLabel: TKLabel!
    private var editLabel: TKLabel!
    private var lessonStackView: UIStackView!
    var addLessonView: TKView!
    private var rightViews: [TKImageView] = []
    private var isEdit: Bool = false
    weak var delegate: StudentdetailLessonCellDelegate!

    private var rescheduleViews: [TKView] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentdetailLessonCell {
    func initView() {
        backgroundColor = ColorUtil.backgroundColor
        mainView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalTo(10)
                make.left.equalTo(20)
                make.height.equalTo(40.5)
                make.right.equalTo(-20)
                make.bottom.equalTo(-10)
            })
        mainView.layer.masksToBounds = true

        titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .alignment(alignment: .left)
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Lesson")
        mainView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(20)
        }

        editLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 13))
            .alignment(alignment: .left)
            .textColor(color: ColorUtil.main)
            .text(text: "Add / Delete")
        mainView.addSubview(view: editLabel) { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        editLabel.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.isEdit = !self.isEdit
            self.editLabel.text("\(self.isEdit ? "Done" : "Add / Delete")")

            for item in self.rightViews {
                item.setImage(name: self.isEdit ? "icDeleteRed" : "arrowRight")
            }
            self.delegate?.studentdetailLessonCell(clickEdit: self.isEdit, cell: self)
        }
        if let role = ListenerService.shared.currentRole {
            editLabel.isHidden = role == .student
        }

        lessonStackView = UIStackView()
        lessonStackView.distribution = .fill
        lessonStackView.axis = .vertical
        lessonStackView.alignment = .fill
        lessonStackView.spacing = 0
        mainView.addSubview(view: lessonStackView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        addLessonView = TKView.create()
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(lessonStackView.snp.bottom)
                make.height.equalTo(0).priority(.high)
                make.left.right.equalToSuperview()
            })
        addLessonView.layer.masksToBounds = true
        addLessonView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.studentdetailLessonCell(clickAdd: self)
        }

        let buttonBackView: TKView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 30)
        addLessonView.addSubview(view: buttonBackView) { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(60)
        }

        let buttonImageView: TKImageView = TKImageView.create()
            .setImage(name: "icAddPrimary")
        buttonBackView.addSubview(view: buttonImageView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }

        TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.main)
            .text(text: "New Lesson")
            .addTo(superView: addLessonView) { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(buttonBackView.snp.right).offset(20)
            }
    }

    func initData(isEdit: Bool, data: [TKLessonScheduleConfigure], isStudentEnter: Bool = false, isLoadLesson: Bool = false, instruments: [String: TKInstrument], reschedules: [String: TKReschedule]) {
        self.isEdit = isEdit
        editLabel.text("\(self.isEdit ? "Done" : "Add / Delete")")
        if isLoadLesson {
            mainView.layer.masksToBounds = false
            if isStudentEnter && data.count == 0 {
                mainView.layer.masksToBounds = true
            }
        } else {
            mainView.layer.masksToBounds = true
        }
        var stackHeight: CGFloat = 0
        for item in data {
            if let reschedule = reschedules[item.id], let timeAfter = TimeInterval(reschedule.timeAfter), let timeBefore = TimeInterval(reschedule.timeBefore) {
                let dateBefore = Date(seconds: timeBefore)
                let dateAfter = Date(seconds: timeAfter)
                let compare = dateAfter.compare(toDate: dateBefore, granularity: .day)
                var sameDay: Bool = false
                switch compare {
                case .orderedSame:
                    sameDay = true
                default:
                    break
                }
                if item.repeatType == .none {
                    if sameDay {
                        stackHeight += 128
                    } else {
                        stackHeight += 138
                    }
                } else {
                    stackHeight += 150
                }
            } else {
                stackHeight += 115
            }
        }
        mainView.snp.updateConstraints { make in
            if isEdit || data.count == 0 {
                make.height.equalTo(40.5 + 82.0 + stackHeight)
            } else {
                make.height.equalTo(40.5 + stackHeight)
            }
        }

        addLessonView.snp.updateConstraints { make in
            if isStudentEnter {
                make.height.equalTo(0).priority(.high)
            } else {
                make.height.equalTo((isEdit || data.count == 0) ? 82 : 0).priority(.high)
            }
        }
        if isStudentEnter {
            editLabel.isHidden = true
        } else {
            editLabel.isHidden = (data.count == 0)
        }

        lessonStackView.removeAllArrangedSubviews()
        rightViews.removeAll()
        rescheduleViews.removeAll()
        for item in data.enumerated() {
            let mainView = TKView.create()
                .backgroundColor(color: UIColor.white)
            let view = TKView.create()
                .backgroundColor(color: UIColor.white)
                .addTo(superView: mainView) { make in
                    make.left.top.bottom.right.equalToSuperview()
                    if reschedules[item.element.id] != nil {
                        if item.element.repeatType == .none {
                            make.height.equalTo(138)
                        } else {
                            make.height.equalTo(150)
                        }
                    } else {
                        make.height.equalTo(115)
                    }
                }
            mainView.tag = item.offset
            view.tag = item.offset
            let pointView = TKImageView.create()
                .setSize(60)
                .asCircle()
            if let instrumentId = item.element.lessonType?.instrumentId {
                if let instrument = instruments[instrumentId] {
                    if instrument.minPictureUrl == "" {
                        if #available(iOS 13.0, *) {
                            pointView.image = UIImage(named: "8|8_selected")?.resizeImage(CGSize(width: 35, height: 35)).withTintColor(ColorUtil.gray)
                        } else {
                            pointView.image = UIImage(named: "8|8")?.resizeImage(CGSize(width: 35, height: 35))
                        }
                        pointView.setBorder()
                        pointView.contentMode = .center
                    } else {
                        pointView.contentMode = .scaleAspectFit
                        pointView.sd_setImage(with: URL(string: instrument.minPictureUrl), completed: nil)
                    }
                } else {
                    InstrumentService.shared.getInstrument(with: instrumentId) { instrument in
                        guard let instrument = instrument else { return }
                        if instrument.minPictureUrl == "" {
                            if #available(iOS 13.0, *) {
                                pointView.image = UIImage(named: "8|8_selected")?.resizeImage(CGSize(width: 35, height: 35)).withTintColor(ColorUtil.gray)
                            } else {
                                pointView.image = UIImage(named: "8|8")?.resizeImage(CGSize(width: 35, height: 35))
                            }
                            pointView.setBorder()
                            pointView.contentMode = .center
                        } else {
                            pointView.contentMode = .scaleAspectFit
                            pointView.sd_setImage(with: URL(string: instrument.minPictureUrl), completed: nil)
                        }
                    }
                }
            }

            view.addSubview(view: pointView) { make in
                make.left.equalToSuperview()
                make.size.equalTo(60)
//                make.centerY.equalToSuperview()
                make.top.equalToSuperview().offset(25.4)
            }
            view.onViewTapped { [weak self] _ in
                guard let self = self else { return }
                if self.isEdit {
                    self.delegate?.studentdetailLessonCell(clickDelete: view.tag)
                } else {
                    self.delegate?.studentdetailLessonCell(clickLesson: view.tag)
                }
            }

            let titleLabel = TKLabel.create()
                .font(font: FontUtil.bold(size: 18))
                .textColor(color: ColorUtil.Font.third)
                .text(text: "\(item.element.lessonType?.name ?? "")")
            titleLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
            view.addSubview(view: titleLabel) { make in
                make.top.equalToSuperview().offset(25.4)
                make.left.equalTo(pointView.snp.right).offset(10)
                make.right.equalToSuperview().offset(-52)
            }
            var detailString: String = ""
            // 获取当前课程的配置信息,写入
            var formatString = ""
            if item.element.repeatType == .none {
                formatString = Locale.is12HoursFormat() ? "hh:mm a, MM/dd/yyyy" : "HH:mm, MM/dd/yyyy"
            } else {
                formatString = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"
            }
            let startDateTime = "\(Date(seconds: item.element.startDateTime).toLocalFormat(formatString))"
            var repeatDays: String = ""
            var repeatType: String = ""
            let diff = TimeUtil.getUTCWeekdayDiff(timestamp: Int(item.element.startDateTime) * 1000)
            let repeatWeekDay: [Int] = item.element.repeatTypeWeekDay.compactMap {
                var i = $0 + (-diff)
                if i < 0 {
                    i = 6
                } else if i > 6 {
                    i = 0
                }
                
                return Int(i)
            }.sorted(by: { $0 < $1 })
            logger.debug("时间差: \(diff) | 原来的时间: \(item.element.repeatTypeWeekDay) | 新的时间: \(repeatWeekDay)")
            switch item.element.repeatType {
            case .none:
                break
            case .weekly:
                repeatType = "Weekly"
                logger.debug("周时间差: \(diff) | Weekly: \(repeatWeekDay)")
                for day in repeatWeekDay.enumerated() {
                    switch day.element {
                    case 0: repeatDays += "Sun"
                    case 1: repeatDays += "Mon"
                    case 2: repeatDays += "Tue"
                    case 3: repeatDays += "Wed"
                    case 4: repeatDays += "Thu"
                    case 5: repeatDays += "Fri"
                    case 6: repeatDays += "Sat"
                    default:
                        break
                    }
                    if day.offset != repeatWeekDay.count - 1 {
                        repeatDays += "/"
                    }
                }
            case .biWeekly:
                logger.debug("周时间差: \(diff) | Bi-weekly: \(repeatWeekDay)")
                repeatType = "Bi-weekly"
                for day in repeatWeekDay.enumerated() {
                    switch day.element {
                    case 0: repeatDays += "Sun"
                    case 1: repeatDays += "Mon"
                    case 2: repeatDays += "Tue"
                    case 3: repeatDays += "Wed"
                    case 4: repeatDays += "Thu"
                    case 5: repeatDays += "Fri"
                    case 6: repeatDays += "Sat"
                    default:
                        break
                    }
                    if day.offset != repeatWeekDay.count - 1 {
                        repeatDays += "/"
                    }
                }
            case .monthly:
                repeatType = "Monthly"
                switch item.element.repeatTypeMonthDayType {
                case .day:
                    if let day = Int(item.element.repeatTypeMonthDay) {
                        switch day {
                        case 1: repeatDays = "1st"
                        case 2: repeatDays = "2nd"
                        case 3: repeatDays = "3rd"
                        default: repeatDays = "\(day)th"
                        }
                    }
                    break
                case .dayOfWeek:
                    let list = item.element.repeatTypeMonthDay.components(separatedBy: ":")
                    if list.count == 2 {
                        if let dayString = list.last, let dayOfWeek = Int(dayString), let weekString = list.first, let week = Int(weekString) {
                            switch dayOfWeek - diff {
                            case 0: repeatDays = "Sun"
                            case 1: repeatDays = "Mon"
                            case 2: repeatDays = "Tue"
                            case 3: repeatDays = "Wed"
                            case 4: repeatDays = "Thu"
                            case 5: repeatDays = "Fri"
                            case 6: repeatDays = "Sat"
                            default:
                                break
                            }
                            repeatDays += " at "
                            switch week {
                            case 1: repeatDays += "1st"
                            case 2: repeatDays += "2nd"
                            case 3: repeatDays += "3rd"
                            default: repeatDays += "\(week)th"
                            }
                            repeatDays += " week"
                        }
                    }
                    break
                case .dayOfLastWeek:
                    if let dayOfWeek = Int(item.element.repeatTypeMonthDay) {
                        switch dayOfWeek - diff {
                        case 0: repeatDays = "Sun"
                        case 1: repeatDays = "Mon"
                        case 2: repeatDays = "Tue"
                        case 3: repeatDays = "Wed"
                        case 4: repeatDays = "Thu"
                        case 5: repeatDays = "Fri"
                        case 6: repeatDays = "Sat"
                        default:
                            break
                        }
                        repeatDays += " at last week"
                    }
                    break
                case .endOfMonth:
                    repeatDays += "Last day of month"
                    break
                }
                break
            }
            if repeatDays != "" {
                repeatType = ",\(repeatType)"
            }

//            detailString += "\(repeatDays)\(repeatType)"
            detailString += "\((item.element.lessonType?.timeLength ?? 0).description) minutes"
            var orginalPriceString = ""
            if !isStudentEnter {
                if item.element.specialPrice >= 0 {
                    orginalPriceString = "$\(item.element.lessonType?.price ?? 0)"
                    detailString += ",\(orginalPriceString)\(orginalPriceString == "" ? "" : ",")$\(item.element.specialPrice.descWithCleanZero)"
                } else if (item.element.lessonType?.price ?? -1) != -1 {
                    detailString += ",$\((item.element.lessonType?.price ?? 0).description)"
                }
            }
            detailString += "\n\(startDateTime)"
            let line2 = "\(repeatDays)\(repeatType)"
            if line2 != "" {
                detailString += ",\(line2)"
            }
            detailString = detailString.replacingOccurrences(of: ",", with: ", ")
            let detailLabel = TKLabel.create()
                .font(font: FontUtil.regular(size: 13))
                .textColor(color: ColorUtil.Font.primary)
                .setNumberOfLines(number: 2)

            if orginalPriceString != "" {
                let ranges: [NSRange] = detailString.nsranges(of: orginalPriceString)
                let attributeText: NSMutableAttributedString = NSMutableAttributedString(string: detailString)
                attributeText.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorUtil.Font.primary, range: NSRange(location: 0, length: detailString.count))
                for range in ranges {
                    attributeText.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSNumber(value: 1), range: range)
                    attributeText.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorUtil.Font.primary.withAlphaComponent(0.5), range: range)
                }
                detailLabel.attributedText = attributeText
            } else {
                detailLabel.text(detailString)
            }

            view.addSubview(view: detailLabel) { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(5)
                make.left.equalTo(titleLabel.snp.left)
                make.right.equalToSuperview().offset(-42)
//                make.bottom.equalToSuperview().offset(-23).priority(.medium)
            }

            let lineView = TKView.create()
                .backgroundColor(color: ColorUtil.dividingLine)
            view.addSubview(view: lineView) { make in
                make.left.equalToSuperview().offset(20)
                make.bottom.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(1)
            }

            let rightImageView = TKImageView.create()
                .setImage(name: self.isEdit ? "icDeleteRed" : "arrowRight")
                .addTo(superView: view) { make in
                    make.size.equalTo(22)
                    make.centerY.equalToSuperview()
                    make.right.equalToSuperview()
                }
            if let role = ListenerService.shared.currentRole {
                rightImageView.isHidden = role == .student
            }
            rightViews.append(rightImageView)

            if let reschedule = reschedules[item.element.id], let timeAfter = TimeInterval(reschedule.timeAfter), let timeBefore = TimeInterval(reschedule.timeBefore) {
                var text: String = ""
                let dateBefore = Date(seconds: timeBefore)
                let dateAfter = Date(seconds: timeAfter)
                let compare = dateAfter.compare(toDate: dateBefore, granularity: .day)
                var sameDay: Bool = false
                switch compare {
                case .orderedSame:
                    sameDay = true
                default:
                    break
                }
                var height: CGFloat = 0
                if item.element.repeatType == .none {
                    // 单个课程
                    text = "Has been rescheduled to \(dateAfter.toLocalFormat("EEEE")) \(sameDay ? "" : "\(dateAfter.toLocalFormat("MM/dd/yyyy")) at ")\(dateAfter.toLocalFormat(Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"))"
                    height = 30
                } else {
                    height = 44
                    text = "The lesson on \(dateBefore.toLocalFormat("EEEE")) \(dateBefore.toLocalFormat("MM/dd/yyyy")) at \(dateBefore.toLocalFormat(Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm")) has been rescheduled to  \(sameDay ? "" : "\(dateAfter.toLocalFormat("EEEE")) \(dateAfter.toLocalFormat("MM/dd/yyyy")) at ")\(dateAfter.toLocalFormat(Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"))"
                }
                let rescheduleInfoView = TKView.create()
                    .corner(size: height / 2)
                    .backgroundColor(color: ColorUtil.red.withAlphaComponent(0.16))
                    .addTo(superView: view) { make in
                        make.left.equalTo(detailLabel.snp.left)
                        make.top.equalTo(detailLabel.snp.bottom).offset(5)
                        make.right.lessThanOrEqualToSuperview().offset(-20)
                        make.height.equalTo(height)
                    }
                rescheduleViews.append(rescheduleInfoView)
                TKLabel.create()
//                    .font(font: FontUtil.regular(size: 13))
                    .font(font: FontUtil.bold(size: 10))
//                    .textColor(color: ColorUtil.Font.primary)
                    .textColor(color: ColorUtil.red)
                    .setNumberOfLines(number: 0)
                    .text(text: text)
                    .addTo(superView: rescheduleInfoView) { make in
                        make.left.equalToSuperview().offset(15)
                        make.right.equalToSuperview().offset(-15)
                        make.centerY.equalToSuperview()
//                        make.top.equalToSuperview().offset(4)
//                        make.bottom.equalToSuperview().offset(-4)
                    }
            } else {
                let infoView = TKView.create()
                    .corner(size: 10)
                    .addTo(superView: view) { make in
                        make.left.equalTo(detailLabel.snp.left)
                        make.top.equalTo(detailLabel.snp.bottom).offset(5)
                        make.height.equalTo(20)
                    }
                let infoLabel = TKLabel.create()
                    .font(font: FontUtil.bold(size: 10))
                    .addTo(superView: infoView) { make in
                        make.left.equalTo(10).priority(.high)
                        make.right.equalTo(-10).priority(.high)
                        make.centerY.equalToSuperview()
                    }

                infoLabel.isHidden = true
                infoView.isHidden = true
                if let lessonEndDateAndCount = item.element.lessonEndDateAndCount {
                    switch lessonEndDateAndCount.type {
                    case .none:
                        infoLabel.isHidden = false
                        infoView.isHidden = false
                        titleLabel.snp.updateConstraints { make in
                            make.top.equalToSuperview().offset(13.5)
                        }
                        if lessonEndDateAndCount.count > 0 {
                            infoLabel.textColor(color: ColorUtil.main)
                            infoView.backgroundColor(color: ColorUtil.main.withAlphaComponent(0.16))
                            infoLabel.text("\(lessonEndDateAndCount.count) lesson\(lessonEndDateAndCount.count > 1 ? "s" : "") / \(lessonEndDateAndCount.daysRemaining) day\(lessonEndDateAndCount.daysRemaining > 1 ? "s" : "") remaining")
                        } else {
                            infoLabel.textColor(color: ColorUtil.red)
                            infoView.backgroundColor(color: ColorUtil.red.withAlphaComponent(0.16))
                            infoLabel.text("Ended")
                        }
                        break
                    case .unlimited:
                        break
                    case .noLoop:
                        infoLabel.isHidden = false
                        infoView.isHidden = false
                        titleLabel.snp.updateConstraints { make in
                            make.top.equalToSuperview().offset(13.5)
                        }
                        if lessonEndDateAndCount.daysRemaining > 0 {
                            infoLabel.textColor(color: ColorUtil.main)
                            infoView.backgroundColor(color: ColorUtil.main.withAlphaComponent(0.16))
                            infoLabel.text("\(lessonEndDateAndCount.count) lessons / \(lessonEndDateAndCount.daysRemaining) days remaining")
                        } else {
                            infoLabel.textColor(color: ColorUtil.red)
                            infoView.backgroundColor(color: ColorUtil.red.withAlphaComponent(0.16))
                            infoLabel.text("Ended")
                        }
                        break
                    }
                }
            }

            if isStudentEnter {
                rightImageView.isHidden = true
            }
            lessonStackView.addArrangedSubview(mainView)
        }
    }

    func refreshCorners() {
        guard rescheduleViews.count > 0 else { return }

        rescheduleViews.forEach { view in
            let height = view.bounds.height
            view.corner(size: height / 2)
        }
    }
}

protocol StudentdetailLessonCellDelegate: NSObjectProtocol {
    func studentdetailLessonCell(clickEdit isEdit: Bool, cell: StudentdetailLessonCell)
    func studentdetailLessonCell(clickAdd cell: StudentdetailLessonCell)
    func studentdetailLessonCell(clickDelete index: Int)
    func studentdetailLessonCell(clickLesson index: Int)
}
