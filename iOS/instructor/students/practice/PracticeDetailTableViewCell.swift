//
//  PracticeDetailTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2021/1/28.
//  Copyright © 2021 spelist. All rights reserved.
//

import UIKit

protocol PracticeDetailTableViewCellDelegate: AnyObject {
    func practiceDetailTableViewCell(playAudio data: TKPractice)
}

class PracticeDetailTableViewCell: UITableViewCell {
    struct Subview {
        var contentView: TKView
        var iconView: TKImageView
        var titleLabel: TKLabel
        var playIconView: TKImageView
        var timeLabel: TKLabel
    }

    weak var delegate: PracticeDetailTableViewCellDelegate?

    private var monthIconImageView: TKImageView = TKImageView.create()
        .setImage(name: "icCalendar")
    private var monthLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 16))
        .textColor(color: ColorUtil.Font.primary)
        .changeLabelRowSpace(lineSpace: 0, wordSpace: 0.89)
    private var totalTimeLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 18))
        .textColor(color: ColorUtil.Font.second)
        .changeLabelRowSpace(lineSpace: 0, wordSpace: 1)

    private var recordStackView: UIStackView = UIStackView()

    private var recordSubviews: [Subview] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PracticeDetailTableViewCell {
    private func initView() {
        contentView.backgroundColor = .white
        monthIconImageView.addTo(superView: contentView) { make in
            make.size.equalTo(22)
            make.top.left.equalToSuperview().offset(20)
        }

        monthLabel.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalTo(monthIconImageView.snp.right).offset(20)
            make.height.equalTo(18)
        }

        totalTimeLabel.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(18)
        }

        recordStackView.axis = .vertical
        recordStackView.alignment = .fill
        recordStackView.distribution = .fillEqually
        recordStackView.addTo(superView: contentView) { make in
            make.top.equalTo(monthIconImageView.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
            make.bottom.equalToSuperview().offset(-20).priority(.medium)
        }

        TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: contentView) { make in
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
    }

    private func viewForStackView(practice: TKPractice) -> TKView {
        let view = TKView.create()
        let iconImageView = TKImageView.create()
            .asCircle()
            .addTo(superView: view) { make in
                make.size.equalTo(22)
                make.left.equalToSuperview().offset(20)
                make.centerY.equalToSuperview()
            }
        if practice.done || practice.totalTimeLength > 0 {
            if practice.manualLog {
                iconImageView.setImage(name: "manualLog")
            } else {
                iconImageView.setImage(name: "checkboxOnGray")
            }
        } else {
            iconImageView.setImage(name: "checkboxOffRed")
        }
        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 16))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: practice.name)
            .addTo(superView: view) { make in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(iconImageView.snp.right).offset(20)
            }

        let time: String
        if practice.totalTimeLength > 0 {
            let t: CGFloat = CGFloat(practice.totalTimeLength / 60)
            if t < 0.1 {
                time = "0.1 min"
            } else {
                time = "\(t.roundTo(places: 1)) min"
            }
        } else {
            time = "0 min"
        }

        let timeLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.primary)
            .font(font: FontUtil.regular(size: 13))
            .text(text: time)
            .addTo(superView: view) { make in
                make.top.bottom.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
            }

        let playIconImageView = TKImageView.create()
            .asCircle()
            .addTo(superView: view) { make in
                make.size.equalTo(16)
                make.centerY.equalToSuperview()
                make.right.equalTo(timeLabel.snp.left).offset(-5)
            }
        var canPlay: Bool = false
        for item in practice.recordData {
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
            playIconImageView.setImage(name: practice.recordData.compactMap({ $0.format }).contains(".mp4") ? "ic_video_play_primary" : "icPlayPrimary")
        } else {
            playIconImageView.image = nil
        }
        if practice.recordData.count > 0 {
            playIconImageView.isHidden = false
        } else {
            playIconImageView.isHidden = true
        }
        playIconImageView.onViewTapped { [weak self] _ in
            self?.delegate?.practiceDetailTableViewCell(playAudio: practice)
        }
        timeLabel.onViewTapped { [weak self] _ in
            self?.delegate?.practiceDetailTableViewCell(playAudio: practice)
        }
        titleLabel.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(iconImageView.snp.right).offset(20)
            if practice.recordData.count > 0 {
                make.right.lessThanOrEqualTo(playIconImageView.snp.left).offset(-20)
            } else {
                make.right.lessThanOrEqualTo(timeLabel.snp.left).offset(-20)
            }
        }
        recordSubviews.append(.init(contentView: view, iconView: iconImageView, titleLabel: titleLabel, playIconView: playIconImageView, timeLabel: timeLabel))
        return view
    }
}

extension PracticeDetailTableViewCell {
    func loadData(_ data: [TKPractice]) {
        recordStackView.removeAllArrangedSubviews()
        recordSubviews.removeAll()

        if let startTime = data.first?.startTime {
            let month: String = Date(seconds: startTime).startOfDay.toLocalFormat("MMM dd, yyyy")
            monthLabel.text(month)
        }

        var totalTime: CGFloat = 0

        for item in data {
            totalTime += item.totalTimeLength
            let view = viewForStackView(practice: item)
            recordStackView.addArrangedSubview(view)
            view.snp.makeConstraints { make in
                make.height.equalTo(22)
                make.left.right.equalToSuperview()
            }
        }
        recordStackView.snp.updateConstraints { make in
            make.height.equalTo(data.count * 32)
        }

        let time: String
        if totalTime > 0 {
            let t: CGFloat = CGFloat(totalTime / 60)
            if t < 0.1 {
                time = "0.1 min"
            } else {
                time = "\(t.roundTo(places: 1)) min"
            }
        } else {
            time = "0 min"
        }
        totalTimeLabel.text(time)
    }
}
