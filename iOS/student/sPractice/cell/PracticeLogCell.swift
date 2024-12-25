//
//  PracticeLogCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/26.
//  Copyright © 2019年 spelist. All rights reserved.
//

import RxSwift
import SnapKit
import UIKit

class PracticeLogCell: UITableViewCell {
    private var mainView: TKView!
    private var calendarImgView: UIImageView! = UIImageView()
    private var dateLabel: TKLabel! = TKLabel()
    private var timeLabel: TKLabel! = TKLabel()
    var df: DateFormatter!
    weak var delegate: PracticeLogCellDelegate!
    private var addLogButton: TKBlockButton!

    private var studyView = UIStackView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PracticeLogCell {
    func initView() {
        contentView.backgroundColor = UIColor.white
        mainView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.edges.equalToSuperview()
            })
//        mainView.addSubviews(calendarImgView, dateLabel, timeLabel)
        
        //这个注释就是为了增加行数确定报错的位置
        calendarImgView.addTo(superView: mainView) { make in
            make.top.equalTo(mainView).offset(20)
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }
        calendarImgView.image = UIImage(named: "icCalendar")
        calendarImgView.snp.makeConstraints { make in
            make.top.equalTo(mainView).offset(20)
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }
        timeLabel.addTo(superView: mainView) { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(22)
        }
        timeLabel
            .alignment(alignment: .center)
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.bold(size: 18))
            .text("0 hrs")
        timeLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
//        timeLabel.snp.makeConstraints { make in
//            make.top.equalTo(self.mainView).offset(20)
//            make.right.equalToSuperview().offset(-20)
//            make.height.equalTo(22)
//        }

        let addLogView = TKView.create()
            .addTo(superView: mainView) { make in
                make.right.equalTo(timeLabel.snp.left)
                make.centerY.equalTo(timeLabel)
                make.height.equalTo(28)
            }
        addLogView.layer.masksToBounds = true

        addLogButton = TKBlockButton(frame: .zero, title: "ADD LOG", style: .cancel)
        addLogButton.setFontSize(size: 15)
        addLogButton.layer.masksToBounds = true
        addLogView.addSubview(view: addLogButton) { make in
            make.height.equalTo(28)
            make.width.equalTo(80)
            make.center.equalToSuperview()
        }
        addLogButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.practiceLogCell(clickAddLog: self)
        }
        dateLabel.addTo(superView: mainView) { make in
            make.centerY.equalTo(calendarImgView)
            make.left.equalTo(calendarImgView.snp.right).offset(20)
            make.right.equalTo(addLogView.snp.left).priority(.medium)
        }
        dateLabel.textColor(color: ColorUtil.Font.primary).font(font: FontUtil.bold(size: 16)).text("")
        dateLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
//        dateLabel.snp.makeConstraints { make in
////            make.top.equalTo(self.mainView).offset(20)
//            make.centerY.equalTo(calendarImgView)
//            make.left.equalTo(calendarImgView.snp.right).offset(20)
//            make.right.equalTo(addLogView.snp.left).priority(.medium)
//        }
        initStudyView()
        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: mainView) { make in
                make.bottom.right.equalToSuperview()
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(20)
            }
    }

    private func initStudyView() {
        mainView.addSubviews(studyView)
        studyView.axis = .vertical
        studyView.distribution = .fill
        studyView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(dateLabel.snp.bottom).offset(23)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    func initData(data: TKPracticeAssignment) {
        addLogButton.snp.updateConstraints { make in
            make.width.equalTo(0)
        }
        studyView.removeAllArrangedSubviews()
        if data.practice.count > 0 {
            studyView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(-10)
            }
        } else {
            studyView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(0)
            }
        }
        var totalTime: CGFloat = 0

        for item in data.practice.sorted(by: { (TimeInterval($0.updateTime) ?? 0) > TimeInterval($1.updateTime) ?? 0 }).enumerated() {
            creatInfoLabel(item.element, item.offset)
            totalTime += item.element.totalTimeLength
        }
        if totalTime > 0 {
            totalTime = totalTime / 60
            if totalTime <= 0.1 {
                timeLabel.text("0.1 min")
            } else {
                timeLabel.text("\(totalTime.roundTo(places: 1)) min")
            }
        } else {
            timeLabel.text("0 min")
        }

        dateLabel.text(text: Date(seconds: data.startTime).toLocalFormat("MMM dd, yyyy"))
    }

    private func creatInfoLabel(_ assigment: TKPractice, _ index: Int) {
        let infoView = UIView()
        let inifoImgView = UIImageView()
        let infoLabel = TKLabel()
        let timeLabel = TKLabel()
        var playImg: TKImageView!

        studyView.addViews(infoView)

        infoView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }

        infoView.addSubviews(inifoImgView, infoLabel)
        inifoImgView.image = UIImage(named: assigment.done ? "checkboxOnGray" : "checkboxOffRed")
        if assigment.manualLog {
            inifoImgView.image = UIImage(named: "manualLog")
        }
        infoLabel
            .textColor(color: ColorUtil.Font.primary)
            .font(font: FontUtil.regular(size: 16))
            .text("\((assigment.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines))")

        inifoImgView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.size.equalTo(22)
        }
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(inifoImgView.snp.right).offset(20)
            make.top.equalToSuperview().offset(2)
            make.bottom.equalTo(infoView).offset(-10).priority(.medium)
        }
        infoLabel.numberOfLines = 0
        logger.debug("判断当前的assignment: \(assigment.toJSONString() ?? "")")
        if assigment.recordData.count > 0 {
            playImg = TKImageView.create()
                .addTo(superView: infoView) { make in
                    make.size.equalTo(20)
                    make.left.equalTo(infoLabel.snp.right).offset(10)
                    if assigment.totalTimeLength == 0 {
                        make.right.equalTo(-10)
                    }
                    make.top.equalToSuperview()
                }
            playImg.tag = index
            playImg.onViewTapped { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.practiceLogCell(clickPlay: index, cell: self, practice: assigment)
            }
            // 判断当前数据是否可以播放
            var canPlay: Bool = false
            // 判断有没有上传过的
            for item in assigment.recordData {
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
                if assigment.recordData.compactMap({ $0.format }).contains(".mp4") {
                    playImg.setImage(name: "ic_video_play_primary")
                } else {
                    playImg.setImage(name: "icPlayPrimary")
                }
            } else {
                playImg.image = nil
            }
        }
        if assigment.totalTimeLength > 0 {
            var time = assigment.totalTimeLength / 60
            if time < 0.1 && time > 0 {
                time = 0.1
            }
            let timeString = "\(time.roundTo(places: 1)) min"
            timeLabel.textColor(color: ColorUtil.Font.second).font(font: FontUtil.regular(size: 13))
                .text(timeString)

            infoView.addSubview(view: timeLabel) { make in
                make.right.equalTo(0)
                make.width.equalTo(timeString.getStringWidthByFont(font: FontUtil.regular(size: 13), height: 15.5) + 1)
                if assigment.recordData.count > 0 {
                    make.left.equalTo(playImg.snp.right).offset(10)
                } else {
                    make.left.equalTo(infoLabel.snp.right).offset(10)
                }
                make.top.equalToSuperview().offset(5)
            }
        } else {
            infoView.addSubview(view: timeLabel) { make in
                make.right.equalTo(0)
                make.width.equalTo(0)
                if assigment.recordData.count > 0 {
                    make.left.equalTo(playImg.snp.right).offset(10)
                } else {
                    make.left.equalTo(infoLabel.snp.right).offset(10)
                }
                make.top.equalToSuperview().offset(5)
            }
        }
    }
}

protocol PracticeLogCellDelegate: NSObjectProtocol {
    func practiceLogCell(clickPlay index: Int, cell: PracticeLogCell, practice: TKPractice)
    func practiceLogCell(clickAddLog cell: PracticeLogCell)
}
