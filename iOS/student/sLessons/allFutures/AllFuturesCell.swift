//
//  AllFuturesCell.swift
//  TuneKey
//
//  Created by wht on 2020/4/20.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class AllFuturesCell: UITableViewCell {
    var mainView: TKView!
    private var dayLabel: TKLabel!
    private var monthLabel: TKLabel!
    private var timeLabel: TKLabel!
    private var data: TKLessonSchedule!
    private var yearLabel: TKLabel!
    private var noteLabel: TKLabel!
    weak var delegate: AllFuturesCellDelegate?
    var cancelButton: TKLabel!
    var rescheduleButton: TKLabel!
    var makeUpButton: TKLabel!
    var line: TKView!
    private let arrowView = TKImageView()
    private let leftView = TKView()
    private let rightView = TKView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AllFuturesCell {
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
                make.height.equalTo(96)
                make.bottom.equalTo(-10).priority(.medium)
            })

//        mainView.onViewTapped { [weak self] _ in
//            guard let self = self else { return }
//            self.delegate?.allFuturesCellSchedule(clickCell: self)
//        }
        yearLabel = TKLabel.create()
            .font(font: FontUtil.medium(size: 13))
            .textColor(color: ColorUtil.Font.fourth)
            .addTo(superView: mainView, withConstraints: { make in
                //                make.left.equalToSuperview().offset(20)
                //                make.top.equalToSuperview().offset(16)
                make.left.equalToSuperview().offset(0)
                make.top.equalToSuperview().offset(0)
            })
        yearLabel.isHidden = true

        dayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.Font.fourth)
            .adjustsFontSizeToFitWidth()
            .alignment(alignment: .center)

            .addTo(superView: mainView, withConstraints: { make in
                //                make.left.equalToSuperview().offset(20)
                //                make.top.equalTo(yearLabel.snp.bottom)
                make.top.equalToSuperview().offset(10)
                make.left.equalToSuperview().offset(20)
                make.height.equalTo(50)
                make.width.equalTo(50)
            })
        monthLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 18))
            .textColor(color: ColorUtil.Font.fourth)
            .addTo(superView: mainView, withConstraints: { make in
                //                make.bottom.equalTo(dayLabel.snp.bottom).offset(-5)
                //                make.left.equalTo(dayLabel.snp.right).offset(5)
                make.top.equalTo(dayLabel.snp.bottom).offset(-3)
                make.centerX.equalTo(dayLabel)
            })

        timeLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.fourth)
            .addTo(superView: mainView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.width.equalTo(UIScreen.main.bounds.width - 170)
                make.left.equalTo(dayLabel.snp.right).offset(20)
            })
        noteLabel = TKLabel.create()
            .setNumberOfLines(number: 0)
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.fourth)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(timeLabel.snp.bottom).offset(5)
                //                make.left.equalToSuperview().offset(140)
                //                make.width.equalTo(UIScreen.main.bounds.width - 238)
                make.width.equalTo(UIScreen.main.bounds.width - 170)
                make.left.equalTo(dayLabel.snp.right).offset(20)
                make.height.equalTo(17.5)
                //                make.left.equalToSuperview().offset(140)
            })
        noteLabel.lineBreakMode = .byCharWrapping
        // 分割线
        line = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: mainView) { make in
                make.top.equalTo(96)
                make.height.equalTo(1)
                make.right.equalToSuperview().offset(-20)
                make.left.equalToSuperview().offset(20)
            }

        cancelButton = TKLabel.create()
            .textColor(color: ColorUtil.red)
            .text(text: "CANCEL LESSON")
            .font(font: FontUtil.bold(size: 14))
            .alignment(alignment: .center)
            .addTo(superView: mainView, withConstraints: { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(50)
                make.left.equalToSuperview()
                make.width.equalTo((UIScreen.main.bounds.width - 40) / 2)
            })
        cancelButton.isHidden = true
        rescheduleButton = TKLabel.create()
            .textColor(color: ColorUtil.main)
            .text(text: "RESCHEDULE")
            .font(font: FontUtil.bold(size: 14))
            .alignment(alignment: .center)
            .addTo(superView: mainView, withConstraints: { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(50)
                make.right.equalToSuperview()
                make.width.equalTo((UIScreen.main.bounds.width - 40) / 2)
            })
        rescheduleButton.isHidden = true
        makeUpButton = TKLabel.create()
            .textColor(color: ColorUtil.main)
            .text(text: "MAKE UP")
            .font(font: FontUtil.bold(size: 14))
            .alignment(alignment: .center)
            .addTo(superView: mainView, withConstraints: { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(50)
                make.right.left.equalToSuperview()
            })
        makeUpButton.isHidden = true
        makeUpButton.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.allFuturesCellSchedule(clickButton: self, isLeftButton: false)
        }

        cancelButton.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.allFuturesCellSchedule(clickButton: self, isLeftButton: true)
        }
        rescheduleButton.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.allFuturesCellSchedule(clickButton: self, isLeftButton: false)
        }
//        noteLabel.lineBreakMode = .byCharWrapping
        arrowView.setImage(name: "arrowRight")
        mainView.addSubview(view: arrowView) { make in
            make.size.equalTo(22)
            make.right.equalTo(-20)
            make.top.equalTo(37)
        }
        addSubview(view: leftView) { make in
            make.left.top.equalToSuperview()
            make.height.equalTo(96)
            make.width.equalTo(UIScreen.main.bounds.width * 0.7)
        }
        leftView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.allFuturesCellSchedule(clickCell: self, isLeft: true)
        }
        addSubview(view: rightView) { make in
            make.right.top.equalToSuperview()
            make.height.equalTo(96)
            make.width.equalTo(UIScreen.main.bounds.width * 0.3)
        }
        rightView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.allFuturesCellSchedule(clickCell: self, isLeft: false)
        }
    }

    func initData(data: TKLessonSchedule, df: DateFormatter, locationInfo: String = "") {
        self.data = data
        if data.teacherId == "" {
            if let studentData = ListenerService.shared.studentData.studentData {
                if studentData.teacherId == "" || studentData.studentApplyStatus == .apply {
                    if studentData.studentApplyStatus == .apply {
                        rescheduleButton.text("RE-INVITE")
                    } else {
                        rescheduleButton.text("ADD INSTRUCTOR")
                    }
                    cancelButton.text("DELETE LESSON")
                } else {
                    cancelButton.text("CANCEL LESSON")
                    rescheduleButton.text("RESCHEDULE")
                }
            } else {
                rescheduleButton.text("ADD INSTRUCTOR")
                cancelButton.text("DELETE LESSON")
            }

        } else {
            cancelButton.text("CANCEL LESSON")
            rescheduleButton.text("RESCHEDULE")
        }
        logger.debug("当前课程的时间: \(data.getShouldDateTime()) | \(data.getShouldDateTime().toFormat("yyyy-MM-dd HH:mm:ss"))")
        let d = TimeUtil.changeTime(time: data.getShouldDateTime())
        let weekString = "\(TimeUtil.getWeekDayShotNameLowerCase(weekDay: d.getWeekday())), "

//        dayLabel.text("\(d.day)")
//        yearLabel.text("\(d.year)")
//        monthLabel.text("\(TimeUtil.getMonthShortName(month: d.month))")
        tkDF.dateFormat = "hh:mm a"
//        timeLabel.text("\(tkDF.string(from: d))")
//        noteLabel.text = ""
        noteLabel.snp.updateConstraints { make in
            make.height.equalTo(17.5)
        }
        if data._isOpen {
            mainView.snp.updateConstraints { make in
                make.height.equalTo(146)
            }
            if data.cancelled {
                rescheduleButton.isHidden = true
                cancelButton.isHidden = true
                makeUpButton.isHidden = false
            } else {
                rescheduleButton.isHidden = false
                cancelButton.isHidden = false
                makeUpButton.isHidden = true
            }
            line.isHidden = false
        } else {
            mainView.snp.updateConstraints { make in
                make.height.equalTo(96)
            }
            rescheduleButton.isHidden = true
            makeUpButton.isHidden = true
            cancelButton.isHidden = true
            line.isHidden = true
        }
        arrowView.isHidden = false
        noteLabel.font(font: FontUtil.regular(size: 15))
        if data.cancelled || (data.rescheduled && data.rescheduleId != "") {
            arrowView.isHidden = true
            timeLabel.textColor(color: ColorUtil.Font.fourth)
            monthLabel.textColor(color: ColorUtil.Font.fourth)
            dayLabel.textColor(color: ColorUtil.Font.fourth)
//            timeLabel.strikeThrough(true)
//            monthLabel.strikeThrough(true)
//            dayLabel.strikeThrough(true)
//            yearLabel.strikeThrough(true)
            noteLabel.isHidden = false
            noteLabel.textColor(color: ColorUtil.red)
            let day = NSMutableAttributedString(string: "\(d.day)")
            let year = NSMutableAttributedString(string: "\(d.year)")
            let month = NSMutableAttributedString(string: "\(TimeUtil.getMonthShortName(month: d.month))")
            let time = NSMutableAttributedString(string: "\(weekString)\(tkDF.string(from: d))")
            day.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, day.length))
            year.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, year.length))
            month.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, month.length))
            time.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, time.length))

            dayLabel.attributedText = day
            yearLabel.attributedText = year
            monthLabel.attributedText = month
            timeLabel.attributedText = time

            timeLabel.snp.remakeConstraints { make in
                make.width.equalTo(UIScreen.main.bounds.width - 150)
                make.left.equalTo(dayLabel.snp.right).offset(20)

                make.top.equalTo(15)
            }
            if data.cancelled {
                noteLabel.text = "Canceled"
                noteLabel.snp.updateConstraints { make in
                    make.height.equalTo(17.5)
                }
                if let cancelData = data.cancelLessonData {
                    noteLabel.text = "Cancelled at \(df.string(from: TimeUtil.changeTime(time: Double(cancelData.createTime)!)))"
                    noteLabel.snp.updateConstraints { make in
                        make.height.equalTo(35)
                    }
                }
            } else if data.rescheduled && data.rescheduleId != "" {
                noteLabel.text = "Rescheduled"
                noteLabel.snp.updateConstraints { make in
                    make.height.equalTo(17.5)
                }
                if let rescheduleData = data.rescheduleLessonData {
                    if data.rescheduleId != "" {
                        // 此处说明Reschedule 已完成

                        // MARK: - TimeAfter 修改过的地方

                        rescheduleData.getTimeAfterInterval { [weak self] time in
                            guard let self = self else { return }
                            let date = Date(seconds: time)
                            self.noteLabel.text = "Rescheduled to \(df.string(from: date))"
                            self.noteLabel.snp.updateConstraints { make in
                                make.height.equalTo(35)
                            }
                        }
                    }
                }

            } else if data.rescheduled && data.rescheduleId == "" && data.cancelled {
                // 这种判断是属于cancelled后 又make up
                noteLabel.isHidden = false
                noteLabel.textColor(color: ColorUtil.red)
                noteLabel.text = "Pending"
                timeLabel.snp.remakeConstraints { make in
                    make.width.equalTo(UIScreen.main.bounds.width - 150)
                    make.left.equalTo(dayLabel.snp.right).offset(20)
                    make.top.equalTo(15)
                }
                noteLabel.snp.updateConstraints { make in
                    make.height.equalTo(17.5)
                }
                if let rescheduleData = data.rescheduleLessonData {
                    if rescheduleData.timeAfter != "" {
                        // MARK: - TimeAfter 修改过的地方

                        rescheduleData.getTimeAfterInterval { [weak self] time in
                            guard let self = self else { return }
                            let date = Date(seconds: time)
                            self.noteLabel.text = "(Pending) Rescheduled to \(df.string(from: date))"
                            self.noteLabel.snp.updateConstraints { make in
                                make.height.equalTo(35)
                            }
                        }
                    }
                }

                dayLabel.attributedText = NSMutableAttributedString(string: "\(d.day)")
                yearLabel.attributedText = NSMutableAttributedString(string: "\(d.year)")
                monthLabel.attributedText = NSMutableAttributedString(string: "\(TimeUtil.getMonthShortName(month: d.month))")
                timeLabel.attributedText = NSMutableAttributedString(string: "\(weekString)\(tkDF.string(from: d))")
                timeLabel.textColor(color: ColorUtil.Font.third)
                monthLabel.textColor(color: ColorUtil.main)
                dayLabel.textColor(color: ColorUtil.main)
            }
        } else if data.rescheduled && data.rescheduleId == "" {
            noteLabel.isHidden = false
            noteLabel.textColor(color: ColorUtil.red)
            noteLabel.text = "Pending"
            noteLabel.snp.updateConstraints { make in
                make.height.equalTo(17.5)
            }
            timeLabel.snp.remakeConstraints { make in
                make.width.equalTo(UIScreen.main.bounds.width - 150)
                make.left.equalTo(dayLabel.snp.right).offset(20)
                make.top.equalTo(25)
            }
            if let rescheduleData = data.rescheduleLessonData {
                if rescheduleData.timeAfter != "" {
                    timeLabel.snp.remakeConstraints { make in
                        make.width.equalTo(UIScreen.main.bounds.width - 150)
                        make.left.equalTo(dayLabel.snp.right).offset(20)
                        make.top.equalTo(15)
                    }

                    // MARK: - TimeAfter 修改过的地方

                    rescheduleData.getTimeAfterInterval { [weak self] time in
                        guard let self = self else { return }
                        let date = Date(seconds: time)
                        self.noteLabel.text = "(Pending) Rescheduled to \(df.string(from: date))"
                        self.noteLabel.snp.updateConstraints { make in
                            make.height.equalTo(35)
                        }
                    }
                }
            }

            dayLabel.attributedText = NSMutableAttributedString(string: "\(d.day)")
            yearLabel.attributedText = NSMutableAttributedString(string: "\(d.year)")
            monthLabel.attributedText = NSMutableAttributedString(string: "\(TimeUtil.getMonthShortName(month: d.month))")
            timeLabel.attributedText = NSMutableAttributedString(string: "\(weekString)\(tkDF.string(from: d))")
            timeLabel.textColor(color: ColorUtil.Font.third)
            monthLabel.textColor(color: ColorUtil.main)
            dayLabel.textColor(color: ColorUtil.main)
        } else {
            dayLabel.attributedText = NSMutableAttributedString(string: "\(d.day)")
            yearLabel.attributedText = NSMutableAttributedString(string: "\(d.year)")
            monthLabel.attributedText = NSMutableAttributedString(string: "\(TimeUtil.getMonthShortName(month: d.month))")
            timeLabel.attributedText = NSMutableAttributedString(string: "\(weekString)\(tkDF.string(from: d))")
            if locationInfo.isEmpty {
                timeLabel.snp.remakeConstraints { make in
                    make.width.equalTo(UIScreen.main.bounds.width - 150)
                    make.left.equalTo(dayLabel.snp.right).offset(20)
                    make.top.equalTo(35)
                }
                noteLabel.isHidden = true
            } else {
                noteLabel.font(font: FontUtil.regular(size: 13))
                noteLabel.isHidden = false
                noteLabel.text = locationInfo
                noteLabel.snp.updateConstraints { make in
                    make.height.equalTo(17.5)
                }
                timeLabel.snp.remakeConstraints { make in
                    make.width.equalTo(UIScreen.main.bounds.width - 150)
                    make.left.equalTo(dayLabel.snp.right).offset(20)
                    make.top.equalTo(25)
                }
            }
            noteLabel.textColor(color: ColorUtil.Font.fourth)
            timeLabel.textColor(color: ColorUtil.Font.third)
            monthLabel.textColor(color: ColorUtil.main)
            dayLabel.textColor(color: ColorUtil.main)
        }

//        timeLabel.text("\(tkDF.string(from: d)) - \(tkDF.string(from: TimeUtil.changeTime(time: data.shouldDateTime + Double(data.shouldTimeLength * 60))))")
    }
}

extension AllFuturesCell {
    func clickMainView() {
//        mainView.snp.updateConstraints { (make) in
//            make.height.equalTo(131)
//        }
    }
}

protocol AllFuturesCellDelegate: NSObjectProtocol {
    func allFuturesCellSchedule(clickCell cell: AllFuturesCell, isLeft: Bool)
    func allFuturesCellSchedule(clickButton cell: AllFuturesCell, isLeftButton: Bool)
}
