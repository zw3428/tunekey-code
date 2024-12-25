//
//  PracticeCellV2.swift
//  TuneKey
//
//  Created by wht on 2020/8/12.
//  Copyright © 2020 spelist. All rights reserved.
//
import SwiftDate
import UIKit

class PracticeCellV2: UITableViewCell {
    private var backView: TKView!
    private var calendarImgView: UIImageView! = UIImageView()
    private var dateLabel: TKLabel! = TKLabel()
    private var timeLabel: TKLabel! = TKLabel()
    private var homeworkView = UIStackView()
    private var homeworkLabel = TKLabel()
    private var homeworkImgView = UIImageView()
    private var arrowImageView: TKImageView = TKImageView.create()
        .setImage(name: "arrowRight")

    private var studyView = UIStackView()
    private var studyLable = TKLabel()
    private var studyImgView = UIImageView()
    private var incompleteLabel = TKLabel()
    weak var delegate: PracticeCellV2Delegate!

    private var data: TKPracticeAssignment?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PracticeCellV2 {
    func initView() {
        backView = TKView()
        contentView.addSubview(backView)
        _ = backView.showShadow()
        backView.setTKBorderAndRaius()
        backView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            // make.centerX.equalToSuperview()
            make.bottom.equalTo(self.contentView).offset(-10)

            make.top.equalTo(self.contentView)
        }
        backView.backgroundColor = UIColor.white
        backView.addSubviews(calendarImgView, dateLabel, timeLabel)
        calendarImgView.image = UIImage(named: "icCalendar")
        calendarImgView.snp.makeConstraints { make in
            make.top.equalTo(self.backView).offset(20)
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }

        arrowImageView.addTo(superView: backView) { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }

        timeLabel.alignment(alignment: .center).textColor(color: ColorUtil.main).font(font: FontUtil.bold(size: 15)).text("")
        timeLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(self.backView).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(22)
        }
        dateLabel.textColor(color: ColorUtil.Font.third).font(font: FontUtil.bold(size: 18)).text("")
        dateLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(self.backView).offset(20)
            make.left.equalTo(calendarImgView.snp.right).offset(20)
//            make.height.equalTo(22)
        }
        initHomworkView()
        initStudyView()

        backView.onViewTapped { [weak self] _ in
            guard let self = self, let data = self.data else { return }
            self.delegate?.practiceCellV2(cellDidTapped: self, data: data)
        }
    }

    private func initHomworkView() {
        backView.addSubviews(homeworkImgView, homeworkLabel, homeworkView, incompleteLabel)
        homeworkImgView.image = UIImage(named: "icHomework")
        homeworkLabel.textColor(color: ColorUtil.Font.primary).font(font: FontUtil.regular(size: 13))
            .text("Assignment")
        homeworkView.axis = .vertical
        homeworkView.distribution = .fill
        homeworkView.spacing = 10
        homeworkImgView.snp.makeConstraints { make in
            make.size.equalTo(0)
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(dateLabel.snp.bottom).offset(0)
        }
        homeworkLabel.snp.makeConstraints { make in
            make.left.equalTo(homeworkImgView.snp.right).offset(20)
            make.height.equalTo(0)
            make.centerY.equalTo(homeworkImgView)
        }
        incompleteLabel
            .textColor(color: ColorUtil.red)
            .font(font: FontUtil.bold(size: 15))
            .text("Incomplete")
        incompleteLabel.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.height.equalTo(0)
            make.bottom.equalTo(homeworkLabel.snp.bottom).offset(-2)
        }
        homeworkView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(homeworkImgView.snp.bottom).offset(0)
        }
    }

    private func initStudyView() {
        backView.addSubviews(studyImgView, studyLable, studyView)
        studyImgView.image = UIImage(named: "icSelfDirected")
        studyLable.textColor(color: ColorUtil.Font.primary).font(font: FontUtil.regular(size: 13))
            .text("Self Study")
        studyView.axis = .vertical
        studyView.distribution = .fill
        studyView.spacing = 10

        studyImgView.snp.makeConstraints { make in
            make.size.equalTo(0)
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(homeworkView.snp.bottom).offset(0)
        }
        studyLable.snp.makeConstraints { make in
            make.left.equalTo(studyImgView.snp.right).offset(20)
            make.height.equalTo(0)
            make.centerY.equalTo(studyImgView)
        }
        studyView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(studyImgView.snp.bottom).offset(0)
            make.bottom.equalTo(self.backView).offset(0).priority(.medium)
        }
    }
}

extension PracticeCellV2 {
    func initItem() {
//        initHomworkItem()
//        initStudyItem()
    }

    func initData(data: TKPracticeAssignment, isShowIncomplete: Bool = false) {
        self.data = data
        logger.debug("设置的Practice数据: \(data.toJSONString() ?? "")")
        let showArrow: Bool = data.practice.count > 0
        arrowImageView.isHidden = !showArrow

        timeLabel.snp.updateConstraints { make in
            make.right.equalToSuperview().offset(showArrow ? -50 : -20)
        }

        let startDate = TimeUtil.changeTime(time: data.startTime)
        let start = "\(TimeUtil.getMonthShortName(month: startDate.month)) \(startDate.day)"
        var end = ""
        if data.endTime != -1 {
            let endDate = TimeUtil.changeTime(time: data.endTime)
            end = "\(TimeUtil.getMonthShortName(month: endDate.month)) \(endDate.day)"
//            if startDate.month != endDate.month {
//            } else {
//                end = "\(endDate.day)"
//            }
        } else {
            end = "Today"
        }
        initConstraints()
        studyView.removeAllArrangedSubviews()
        homeworkView.removeAllArrangedSubviews()
        dateLabel.text("\(start) to \(end)")
        var assignmentData: [TKPractice] = []
        var studyData: [TKPractice] = []
        var isComplete = true
        var totalTime: CGFloat = 0
        for item in data.practice {
            totalTime += item.totalTimeLength
            if item.assignment {
                if !item.done {
                    isComplete = false
                }
                assignmentData.append(item)
            } else {
                if item.done {
                    studyData.append(item)
                }
            }
        }
        logger.debug("所有的时间L:\(totalTime) -> \(TimeUtil.secondsToMinsSeconds(time: Float(totalTime)))")
        incompleteLabel.isHidden = isComplete
        if isShowIncomplete {
            incompleteLabel.text("Incomplete")
        } else {
            incompleteLabel.text("Uncompleted")
        }
        if totalTime > 0 {
//            totalTime = totalTime / 60 / 60
//            if totalTime <= 0.1 {
//                timeLabel.text("0.1 hrs")
//            } else {
//                timeLabel.text("\(totalTime.roundTo(places: 1)) hrs")
//            }

            var timeString: String = ""
            var hourString: String = ""
            var minString: String = ""
            var secondString: String = ""
            let hour = Int(totalTime) / 3600
            if hour > 0 {
                hourString = "\(Int(hour)) hr\(hour > 1 ? "s" : "")"
            }
            let min = Int(totalTime) % 3600 / 60
            if min > 0 {
                minString = "\(Int(min)) m"
            }
            let second = (Int(totalTime) - hour * 3600 - min * 60) % 3600
            if second > 0 {
                secondString = "\(Int(second)) s"
            }
            timeString += hourString
            timeString += minString
            if hour <= 0 || min <= 0 {
                timeString += secondString
            }
            timeLabel.text(timeString)
            timeLabel.textColor(color: ColorUtil.main)
        } else {
            timeLabel.textColor(color: ColorUtil.red)
            timeLabel.text("0 hrs")
        }

        if studyData.count > 0 {
            initStudyItem(studyData)
        }
        if assignmentData.count > 0 {
            initHomworkItem(assignmentData)
        }
        if studyData.count == 0 && assignmentData.count == 0 {
            homeworkImgView.snp.updateConstraints { make in
                make.size.equalTo(0)
                make.top.equalTo(dateLabel.snp.bottom).offset(20)
            }
        }
    }

    private func initConstraints() {
        homeworkImgView.snp.updateConstraints { make in
            make.size.equalTo(0)
            make.top.equalTo(dateLabel.snp.bottom).offset(0)
        }
        homeworkLabel.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        incompleteLabel.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        homeworkView.snp.updateConstraints { make in
            make.top.equalTo(homeworkImgView.snp.bottom).offset(0)
        }
        studyImgView.snp.updateConstraints { make in
            make.size.equalTo(0)
            make.top.equalTo(homeworkView.snp.bottom).offset(0)
        }
        studyLable.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        studyView.snp.updateConstraints { make in
            make.top.equalTo(studyImgView.snp.bottom).offset(0)
            make.bottom.equalTo(self.backView).offset(0).priority(.medium)
        }
    }

    func initHomworkItem(_ data: [TKPractice]) {
        homeworkImgView.snp.updateConstraints { make in
            make.size.equalTo(22)
            make.top.equalTo(dateLabel.snp.bottom).offset(23)
        }
        homeworkLabel.snp.updateConstraints { make in
            make.height.equalTo(22)
        }
        incompleteLabel.snp.updateConstraints { make in
            make.height.equalTo(17.5)
        }
        homeworkView.snp.updateConstraints { make in
            make.top.equalTo(homeworkImgView.snp.bottom).offset(10)
        }
        studyImgView.snp.updateConstraints { make in

            make.top.equalTo(homeworkView.snp.bottom).offset(22)
        }
        for item in data.enumerated() {
            creatInfoLabel(homeworkView, data: item.element, isHomework: true, pos: item.offset)
        }
    }

    func initStudyItem(_ data: [TKPractice]) {
        studyImgView.snp.updateConstraints { make in
            make.size.equalTo(22)

            make.top.equalTo(homeworkView.snp.bottom).offset(22)
        }
        studyLable.snp.updateConstraints { make in
            make.height.equalTo(22)
            make.centerY.equalTo(studyImgView)
        }
        studyView.snp.updateConstraints { make in
            make.top.equalTo(studyImgView.snp.bottom).offset(10)
            make.bottom.equalTo(self.backView).offset(-20).priority(.medium)
        }

        for item in data.enumerated() {
            creatInfoLabel(studyView, data: item.element, isHomework: false, pos: item.offset)
        }
    }

    func creatInfoLabel(_ infoSupperView: UIStackView, data: TKPractice, isHomework: Bool, pos: Int) {
        let infoView = UIView()
        let inifoImgView = UIImageView()
        let infoLabel = TKLabel()
        infoLabel.numberOfLines = 0
        infoView.tag = pos

        infoSupperView.addViews(infoView)
        if data.recordData.count > 0 {
            let playImg = TKImageView.create()

                .addTo(superView: infoView) { make in
                    make.size.equalTo(16)
                    make.right.equalTo(0)
                    make.centerY.equalToSuperview()
                }
            playImg.tag = pos
            playImg.onViewTapped { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.practiceCellV2(clickPlay: self, data: data)
            }

            // 判断当前数据是否可以播放
            var canPlay: Bool = false
            // 判断有没有上传过的
            for item in data.recordData {
                if item.upload {
                    canPlay = true
                } else {
                    // 判断是否在本地有文件
                    if item.format == ".mp4" {
                        let folderPath = StorageService.shared.getPracticeFileFolderPath()
                        let filePath = "\(folderPath)/\(item.id)\(item.format)"
                        if FileManager.default.fileExists(atPath: filePath) {
                            canPlay = true
                        }
                    } else {
                        let filePath = "\(RecorderTool.sharedManager.composeDir())log-\(item.id)\(item.format)"
                        if FileManager.default.fileExists(atPath: filePath) {
                            canPlay = true
                        }
                    }
                }
            }
            if canPlay {
                if data.recordData.compactMap({ $0.format }).contains(".mp4") {
                    playImg.setImage(name: "ic_video_play_primary")
                } else {
                    playImg.setImage(name: "icPlayPrimary")
                }
            } else {
                playImg.image = nil
            }
        }

        infoView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }

        infoView.addSubviews(inifoImgView, infoLabel)
        var offImg = "checkboxOff"
        if data.assignment {
            offImg = "checkboxOffRed"
        }
        let isDone: Bool = data.done || data.totalTimeLength > 0
        inifoImgView.image = UIImage(named: isDone ? "checkboxOnGray" : "\(offImg)")
        if data.manualLog {
            inifoImgView.image = UIImage(named: "manualLog")
        }

        infoLabel.textColor(color: ColorUtil.Font.primary).font(font: FontUtil.regular(size: 13))
            .text("\(data.name)")

        inifoImgView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.size.equalTo(22)
        }
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(inifoImgView.snp.right).offset(20)
            make.top.equalToSuperview().offset(2)
            if data.recordData.count > 0 {
                make.right.equalToSuperview().offset(-32)
            } else {
                make.right.equalToSuperview().offset(0)
            }
            make.bottom.equalTo(infoView)
        }
        infoLabel.numberOfLines = 0
    }
}

protocol PracticeCellV2Delegate: AnyObject {
    func practiceCellV2(clickPlay cell: PracticeCellV2, data: TKPractice)
    func practiceCellV2(cellDidTapped cell: PracticeCellV2, data: TKPracticeAssignment)
}
