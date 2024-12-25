//
//  StudentDetailsInfoCell.swift
//  TuneKey
//
//  Created by Wht on 2019/8/20.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class StudentDetailsInfoCell: UITableViewCell {
    var backView: TKView!
    var infoImgView: UIImageView!
    var titleLabel: TKLabel!
    var infoLeftOneLabel: TKLabel!
    var infoLeftTwoLabel: TKLabel!
    var infoRightOneLabel: TKLabel!
    var infoRightTwoLabel: TKLabel!
    var infoScheduleTopLabel: TKLabel!
    var infoScheduleBottomLabel: TKLabel!

    var arrowImgView: UIImageView!

    var notesLabel: TKLabel!
    var notesDayLabel: TKLabel!
    var notesMonthLabel: TKLabel!

    var style: StudentDetailsCellStyle!
    weak var delegate: StudentDetailsInfoCellDelegate!

    var homeworkData: [TKPractice] = []
    var achievementData: [TKAchievement] = []
    var scheduleData: [TKLessonSchedule] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentDetailsInfoCell {
    func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        backView = TKView()
        backView.enableShadowAnimationOnTapped = true
        contentView.addSubview(backView)
        _ = backView.showShadow()
        contentView.onViewTapped { _ in
        }
        onViewTapped { _ in
        }
        backView.setTKBorderAndRaius()
        backView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10).priority(.medium)
        }
        backView.layer.masksToBounds = true
        backView.backgroundColor = UIColor.white
        backView.onViewTapped { _ in
            self.delegate?.clickStudentInfoCell(style: self.style)
        }

        infoImgView = UIImageView()
        backView.addSubview(infoImgView)
        infoImgView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }

        arrowImgView = UIImageView()
        backView.addSubview(arrowImgView)
        arrowImgView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }
        arrowImgView.image = UIImage(named: "arrowRight")

        titleLabel = TKLabel()
        backView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(23)
            make.top.equalToSuperview().offset(20)
            make.left.equalTo(infoImgView.snp.right).offset(20)
            make.right.equalTo(arrowImgView.snp.left).offset(-20)
        }
        titleLabel.textColor(color: ColorUtil.Font.third).font(FontUtil.bold(size: 18))
        titleLabel.text("Title")

        infoLeftOneLabel = TKLabel()
        infoLeftTwoLabel = TKLabel()
        infoRightOneLabel = TKLabel()
        infoRightTwoLabel = TKLabel()
        backView.addSubviews(infoLeftOneLabel, infoLeftTwoLabel, infoRightOneLabel, infoRightTwoLabel)
        infoLeftOneLabel.textColor(color: ColorUtil.Font.primary).font(FontUtil.regular(size: 13))
        infoLeftTwoLabel.textColor(color: ColorUtil.Font.primary).font(FontUtil.regular(size: 13))
        infoLeftOneLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        infoLeftTwoLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(infoLeftOneLabel.snp.bottom).offset(3)
        }

        infoRightOneLabel.textColor(color: ColorUtil.Font.third).font(FontUtil.regular(size: 13))
        infoRightTwoLabel.textColor(color: ColorUtil.Font.third).font(FontUtil.regular(size: 13))
        infoRightOneLabel.snp.makeConstraints { make in
            make.right.lessThanOrEqualTo(arrowImgView.snp.left).offset(-45)
            make.left.equalTo(infoLeftOneLabel.snp.right)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        infoRightTwoLabel.snp.makeConstraints { make in
            make.right.lessThanOrEqualTo(arrowImgView.snp.left).offset(-15)
            make.left.equalTo(infoLeftTwoLabel.snp.right)
            make.top.equalTo(infoLeftOneLabel.snp.bottom).offset(4)
        }

        infoScheduleTopLabel = TKLabel()
        infoScheduleBottomLabel = TKLabel()
        backView.addSubviews(infoScheduleTopLabel, infoScheduleBottomLabel)

        infoScheduleTopLabel.textColor(color: ColorUtil.main).font(FontUtil.bold(size: 14))
        infoScheduleBottomLabel.textColor(color: ColorUtil.main).font(font: FontUtil.regular(size: 10)).text("TOP")
        infoScheduleTopLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.right.equalTo(arrowImgView.snp.right)
        }
        infoScheduleBottomLabel.snp.makeConstraints { make in
            make.top.equalTo(infoScheduleTopLabel.snp.bottom).offset(4)
            make.centerX.equalTo(infoScheduleTopLabel.snp.centerX)
        }

//
        notesLabel = TKLabel()
        notesDayLabel = TKLabel()
        notesMonthLabel = TKLabel()
        backView.addSubviews(notesLabel, notesDayLabel, notesMonthLabel)
        notesLabel.textColor(color: ColorUtil.Font.primary).font(FontUtil.regular(size: 13))
        notesLabel.numberOfLines = 3
        notesDayLabel.textColor(color: ColorUtil.Font.primary).font(FontUtil.bold(size: 13))
        notesMonthLabel.textColor(color: ColorUtil.Font.fourth).font(FontUtil.regular(size: 10))
        notesLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.right.equalToSuperview().offset(-20)
        }
        notesMonthLabel.snp.makeConstraints { make in
            make.centerX.equalTo(infoImgView.snp.centerX)
            make.top.equalTo(notesDayLabel.snp.bottom).offset(1)
        }
        notesDayLabel.snp.makeConstraints { make in
            make.centerX.equalTo(notesMonthLabel.snp.centerX)
            make.top.equalTo(infoImgView.snp.bottom).offset(12)
        }
        hiddenView()
    }

    func hiddenView() {
        backView.layer.masksToBounds = true
        infoLeftOneLabel.isHidden = true
        infoLeftTwoLabel.isHidden = true
        infoRightOneLabel.isHidden = true
        infoRightTwoLabel.isHidden = true
        infoScheduleTopLabel.isHidden = true
        infoScheduleBottomLabel.isHidden = true
        notesLabel.isHidden = true
        notesDayLabel.isHidden = true
        notesMonthLabel.isHidden = true
    }

    func showNonalView() {
        infoLeftOneLabel.isHidden = false
        infoLeftTwoLabel.isHidden = false
        infoRightOneLabel.isHidden = false
        infoRightTwoLabel.isHidden = false
        infoScheduleTopLabel.isHidden = false
        infoScheduleBottomLabel.isHidden = true
    }

    func showNotesView() {
        notesLabel.isHidden = false
        notesDayLabel.isHidden = false
        notesMonthLabel.isHidden = false
    }
}

extension StudentDetailsInfoCell {
    // MARK: - initItem

    func initItem(style: StudentDetailsCellStyle, homeworkData: [TKPractice], achievementData: [TKAchievement], scheduleData: [TKLessonSchedule], achievementTop: CGFloat = -1) {
        self.style = style

        hiddenView()

        switch style {
        case .studentActivity:
            showNonalView()
            self.homeworkData = homeworkData
            inithHomework()
            break
        case .achievement:
            showNonalView()
            self.achievementData = achievementData
            initAchievement(achievementTop)
            break
        case .notes:
            showNotesView()
            self.scheduleData = scheduleData
            initNote()
            break
        case .lesson:
            break
        case .userInfo:
            break
        case .materials:
            break
        case .balance:
            break
        case .birthday, .attendance, .memo:
            break
        }
    }

    func inithHomework() {
        infoImgView.image = UIImage(named: "icStudientActivityGray")
        titleLabel.text("Student practice")
//        infoScheduleTopLabel.text("TOP 20%")
        infoLeftOneLabel.text("Practice hrs: ")
        infoLeftTwoLabel.text("Assignment: ")
        guard homeworkData.count > 0 else {
            return
        }
        var doneCount: CGFloat = 0
        var totalPractice: CGFloat = 0
        var assignmentCount = 0
        for item in homeworkData {
            if item.assignment {
                assignmentCount += 1
                if item.done {
                    doneCount += 1
                }
            }

            if !item.assignment {
                totalPractice += item.totalTimeLength
            }
        }
        if totalPractice > 0 {
            totalPractice = totalPractice / 60 / 60

            if totalPractice <= 0.1 {
                infoRightOneLabel.text("0.1 hrs")
            } else {
                infoRightOneLabel.text("\(totalPractice.roundTo(places: 1)) hrs")
            }

        } else {
            infoRightOneLabel.text("0 hrs")
        }

        if doneCount != 0 {
            doneCount = doneCount / CGFloat(homeworkData.count)
        }
        backView.layer.masksToBounds = false
        if assignmentCount > 0 {
            infoRightTwoLabel.text("\(Int(doneCount * 100))% completion")
        } else {
            infoRightTwoLabel.text("No assignment")
        }
    }

    func initAchievement(_ achievementTop: CGFloat) {
        infoImgView.image = UIImage(named: "icAchievement")
        titleLabel.text("Award")
//        infoScheduleTopLabel.text("TOP 20%")
        infoLeftOneLabel.text("Total: ")
        if achievementTop != -1 && achievementTop < 0.5 {
            infoScheduleTopLabel.text("TOP \(Int(achievementTop * 100))%")
        }
        if achievementData.count > 0 {
            var string = ""
            switch achievementData[0].type {
            case .all:
                break
            case .technique:
                string = "Technique: "
            case .notation:
                string = "Theory: "
            case .song:
                string = "Song: "
            case .improv:
                string = "Improvement: "
            case .groupPlay:
                string = "Group play: "
            case .dedication:
                string = "Dedication: "
            case .creativity:
                string = "Creativity: "
            case .hearing:
                string = "Listening: "
            case .musicSheet:
                string = "Sight reading: "
            case .memorization:
                string = "Memorization"
            }
            infoLeftTwoLabel.text(string)

            backView.layer.masksToBounds = false
            infoRightTwoLabel.text(achievementData[0].name)
        }
        infoRightOneLabel.text("\(achievementData.count) badges")
    }

    func initNote() {
        infoImgView.image = UIImage(named: "icLessonNotes")
        titleLabel.text("Notes")
        if let lessonSchedule = self.scheduleData.sorted(by: { $0.shouldDateTime > $1.shouldDateTime }).first {
            backView.layer.masksToBounds = false
            var note = ""
            if lessonSchedule.teacherNote != "" {
                note = lessonSchedule.teacherNote
            } else {
                note = lessonSchedule.studentNote
            }
            notesLabel.text(note)
            let d = DateFormatter()
            d.dateFormat = "dd"
            let time = TimeUtil.changeTime(time: lessonSchedule.getShouldDateTime())
            notesDayLabel.text(d.string(from: time))
            d.dateFormat = "MMM"
            notesMonthLabel.text(d.string(from: time))
        }
    }
}

protocol StudentDetailsInfoCellDelegate: NSObjectProtocol {
    func clickStudentInfoCell(style: StudentDetailsCellStyle)
}
