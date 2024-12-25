//
//  SLessonCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/18.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class SLessonCell: UITableViewCell {
    private var mainView: TKView!
    private var dayLabel: TKLabel!
    private var monthLabel: TKLabel!
    private var timeLabel: TKLabel!
    private var messageLabel: TKLabel!
    private var data: TKLessonSchedule!
    private var yearLabel: TKLabel!
    private var noteLabel: TKLabel!
    private var arrowView: TKImageView!
    private var practiceInfoLabel: TKLabel!
    private var homeworkInfoLabel: TKLabel!
    private var practiceLabel: TKLabel!
    private var homeworkLabel: TKLabel!
    private var achievementImgView: TKImageView!

    private var tipPointer: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.main)
        .corner(size: 3)

    weak var delegate: SLessonCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SLessonCell {
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

        mainView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.sLessonCellSchedule(clickCell: self)
        }
        yearLabel = TKLabel.create()
            .font(font: FontUtil.medium(size: 13))
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: mainView, withConstraints: { make in
//                make.left.equalToSuperview().offset(20)
//                make.top.equalToSuperview().offset(16)
                make.left.equalToSuperview().offset(0)
                make.top.equalToSuperview().offset(0)
            })
        yearLabel.isHidden = true

        dayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.Font.third)
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
        tipPointer.addTo(superView: mainView) { make in
            make.top.equalTo(dayLabel.snp.top).offset(3)
            make.left.equalTo(dayLabel.snp.right)
            make.size.equalTo(6)
        }
        tipPointer.isHidden = true

        monthLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: mainView, withConstraints: { make in
//                make.bottom.equalTo(dayLabel.snp.bottom).offset(-5)
//                make.left.equalTo(dayLabel.snp.right).offset(5)
                make.top.equalTo(dayLabel.snp.bottom).offset(-3)
                make.centerX.equalTo(dayLabel)
            })

        timeLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: mainView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.width.equalTo(UIScreen.main.bounds.width - 150)
//                make.left.equalToSuperview().offset(140)
                make.left.equalTo(dayLabel.snp.right).offset(25)

                //                make.right.equalToSuperview().offset(-20)
            })
        arrowView = TKImageView.create()
            .setImage(name: "arrowRight")
            .addTo(superView: mainView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.size.equalTo(22)
                make.right.equalToSuperview().offset(-20)
            })
        practiceLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Self study: ")
            .addTo(superView: mainView) { make in
                make.left.equalTo(dayLabel.snp.right).offset(20)
                make.top.equalTo(timeLabel.snp.bottom).offset(5)
            }
        practiceInfoLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "0 hrs")
            .addTo(superView: mainView) { make in
                make.left.equalTo(practiceLabel.snp.right)
                make.top.equalTo(timeLabel.snp.bottom).offset(5)
            }

        homeworkLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Assignment: ")
            .addTo(superView: mainView) { make in
                make.left.equalTo(dayLabel.snp.right).offset(20)
                make.top.equalTo(practiceLabel.snp.bottom)
            }
        homeworkInfoLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.kermitGreen)
            .text(text: "No assignment")
            .addTo(superView: mainView) { make in
                make.left.equalTo(homeworkLabel.snp.right)
                make.top.equalTo(practiceLabel.snp.bottom)
            }

        achievementImgView = TKImageView()
        achievementImgView.setImage(name: "icAchievement")
        achievementImgView.addTo(superView: mainView) { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(10)
            make.left.equalTo(dayLabel.snp.right).offset(20)
            make.size.equalTo(22)
        }
        achievementImgView.isHidden = true
        noteLabel = TKLabel.create()
            .setNumberOfLines(number: 2)
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.fourth)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(timeLabel.snp.bottom).offset(5)
//                make.left.equalToSuperview().offset(140)
//                make.width.equalTo(UIScreen.main.bounds.width - 238)
//                make.width.equalTo(UIScreen.main.bounds.width - 150)
                make.right.equalTo(arrowView.snp.left)
                make.left.equalTo(dayLabel.snp.right).offset(20)
            })
        noteLabel.lineBreakMode = .byCharWrapping
    }
    func initData(data: TKLessonSchedule, newMsg: Bool) {
        self.data = data
        let d = TimeUtil.changeTime(time: data.getShouldDateTime())
        let weekString = "\(TimeUtil.getWeekDayShotNameLowerCase(weekDay: d.getWeekday())), "

//        dayLabel.text("\(d.day)")
//        yearLabel.text("\(d.year)")
//        monthLabel.text("\(TimeUtil.getMonthShortName(month: d.month))")
        tkDF.dateFormat = "hh:mm a"
//        timeLabel.text("\(tkDF.string(from: d))")
        noteLabel.text = ""
        noteLabel.textColor(color: ColorUtil.Font.fourth)
        noteLabel.isHidden = true
        homeworkInfoLabel.isHidden = true
        homeworkLabel.isHidden = true
        practiceInfoLabel.isHidden = true
        practiceLabel.isHidden = true
        achievementImgView.isHidden = true
        noteLabel.setNumberOfLines(number: 2)
        noteLabel.snp.updateConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(5)
            make.left.equalTo(dayLabel.snp.right).offset(20)
        }
//        logger.debug("加载Lesson cell, 是否有新消息: \(newMsg)")
        tipPointer.isHidden = !newMsg
        dayLabel.textColor(color: ColorUtil.Font.third)
        yearLabel.textColor(color: ColorUtil.Font.third)
        monthLabel.textColor(color: ColorUtil.Font.third)
        timeLabel.textColor(color: ColorUtil.Font.third)

        if data.cancelled || (data.rescheduled && data.rescheduleId != "") {
            noteLabel.isHidden = false
            timeLabel.snp.remakeConstraints { make in
//                make.left.equalToSuperview().offset(140)
//                make.width.equalTo(UIScreen.main.bounds.width - 238)
                make.width.equalTo(UIScreen.main.bounds.width - 150)
                make.left.equalTo(dayLabel.snp.right).offset(20)
                make.top.equalTo(20)
            }

            if data.cancelled {
                noteLabel.text = "Canceled"
                if let cancelData = data.cancelLessonData {
                    noteLabel.text = "Cancelled at \(TimeUtil.changeTime(time: Double(cancelData.createTime)!).toLocalFormat("hh:mm a, MMM dd"))"
                }
            }
            if data.rescheduled && data.rescheduleId != "" {
                noteLabel.text = "Rescheduled"
                if let rescheduleData = data.rescheduleLessonData {
                    // MARK: - TimeAfter 修改过的地方
                    rescheduleData.getTimeAfterInterval {[weak self] (time) in
                        guard let self = self else{return}
                        let date = Date(seconds: time)
                        self.noteLabel.text = "Rescheduled to \(time.toLocalFormat("hh:mm a, MMM dd")))"
                    }
                }
            }

            noteLabel.textColor(color: ColorUtil.red)
//            noteLabel.strikeThrough(true)
//            dayLabel.strikeThrough(true)
//            yearLabel.strikeThrough(true)
//            monthLabel.strikeThrough(true)
//            timeLabel.strikeThrough(true)
            let day = NSMutableAttributedString(string: "\(d.day)")
            let year = NSMutableAttributedString(string: "\(d.year)")
            let month = NSMutableAttributedString(string: "\(TimeUtil.getMonthShortName(month: d.month))")
            let time = NSMutableAttributedString(string: "\(weekString)\(tkDF.string(from: d))")
            day.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, day.length))
            year.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, year.length))
            month.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, month.length))
            time.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, time.length))
            dayLabel.textColor(color: ColorUtil.Font.fourth)
            yearLabel.textColor(color: ColorUtil.Font.fourth)
            monthLabel.textColor(color: ColorUtil.Font.fourth)
            timeLabel.textColor(color: ColorUtil.Font.fourth)
            dayLabel.attributedText = day
            yearLabel.attributedText = year
            monthLabel.attributedText = month
            timeLabel.attributedText = time
            arrowView.isHidden = true

        } else {
//            dayLabel.strikeThrough(false)
//            yearLabel.strikeThrough(false)
//            monthLabel.strikeThrough(false)
//            timeLabel.strikeThrough(false)
            dayLabel.attributedText = NSMutableAttributedString(string: "\(d.day)")
            yearLabel.attributedText = NSMutableAttributedString(string: "\(d.year)")
            monthLabel.attributedText = NSMutableAttributedString(string: "\(TimeUtil.getMonthShortName(month: d.month))")
            timeLabel.attributedText = NSMutableAttributedString(string: "\(weekString)\(tkDF.string(from: d))")
            arrowView.isHidden = false

            if data.teacherNote != "" || data.studentNote != "" || data.lessonTypeData != nil || data.achievement.count > 0 || data.practiceData.count > 0 {
                noteLabel.isHidden = false
                noteLabel.textColor(color: ColorUtil.Font.fourth)
                timeLabel.snp.remakeConstraints { make in
//                    make.left.equalToSuperview().offset(140)
//                    make.width.equalTo(UIScreen.main.bounds.width - 238)
                    make.width.equalTo(UIScreen.main.bounds.width - 150)
                    make.left.equalTo(dayLabel.snp.right).offset(20)
                    make.top.equalTo(20)
                }
                if data.achievement.count > 0 {
                    noteLabel.snp.updateConstraints { make in
                        make.top.equalTo(timeLabel.snp.bottom).offset(11)

                        make.left.equalTo(dayLabel.snp.right).offset(52)
                    }
                    noteLabel.setNumberOfLines(number: 1)

                    noteLabel.textColor(color: ColorUtil.kermitGreen)
                    noteLabel.text = "\(data.achievement[0].name)"
                    achievementImgView.isHidden = false
                } else if data.teacherNote != "" {
                    noteLabel.text = data.teacherNote
                } else if data.studentNote != "" {
                    noteLabel.text = data.studentNote
                } else if data.practiceData.count > 0 {
                    noteLabel.isHidden = true
                    homeworkInfoLabel.isHidden = false
                    homeworkLabel.isHidden = false
                    practiceInfoLabel.isHidden = false
                    practiceLabel.isHidden = false
                    var assignmentData: [TKPractice] = []
                    var studyData: [TKPractice] = []
                    for item in data.practiceData {
                        if !item.assignment {
                            studyData.append(item)
                        } else {
                            assignmentData.append(item)
                        }
                    }

                    var totalTime: CGFloat = 0
                    for item in studyData {
                        totalTime += item.totalTimeLength
                    }

                    if totalTime > 0 {
                        totalTime = totalTime / 60 / 60
                        if totalTime <= 0.1 {
                            practiceInfoLabel.text("0.1 hrs")
                        } else {
                            practiceInfoLabel.text("\(totalTime.roundTo(places: 1)) hrs")
                        }
                    } else {
                        practiceInfoLabel.text("0 hrs")
                    }

                    guard assignmentData.count > 0 else {
                        homeworkInfoLabel.text("No assignment")
                        homeworkInfoLabel.textColor = ColorUtil.red
                        return
                    }
                    var isComplete = true
                    for item in assignmentData where !item.done {
                        isComplete = false
                    }
                    homeworkInfoLabel.text("\(isComplete ? "Completed" : data.isFirstLesson ? "Incomplete" : "Uncompleted")")

                    homeworkInfoLabel.textColor = isComplete ? ColorUtil.kermitGreen : ColorUtil.red

                } else {
                    noteLabel.text = data.lessonTypeData!.name
                }
            } else {
                timeLabel.snp.remakeConstraints { make in
                    make.width.equalTo(UIScreen.main.bounds.width - 150)
                    make.left.equalTo(dayLabel.snp.right).offset(20)
                    make.centerY.equalToSuperview()
                }
            }
        }
    }
    func initData(data: TKLessonSchedule, df: DateFormatter, newMsg: Bool) {
        initData(data: data, newMsg: newMsg)
    }
}

protocol SLessonCellDelegate: NSObjectProtocol {
    func sLessonCellSchedule(clickCell cell: SLessonCell)
}
