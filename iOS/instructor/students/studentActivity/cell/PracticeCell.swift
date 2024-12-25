//
//  PracticeCell.swift
//  TuneKey
//
//  Created by Wht on 2019/8/26.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit
class PracticeCell: UICollectionViewCell {
    private var backView: TKView!
    private var calendarImgView: UIImageView! = UIImageView()
    private var dateLabel: TKLabel! = TKLabel()
    private var timeLabel: TKLabel! = TKLabel()
    weak var delegate: PracticeCellDelegate!

    private var studyView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PracticeCell {
    private func initView() {
        backView = TKView()
        contentView.addSubview(backView)
        _ = backView.showShadow()
        backView.setTKBorderAndRaius()
        backView.snp.makeConstraints { make in
            make.width.equalTo(self.contentView.frame.width - 40)
            make.centerX.equalToSuperview()
            make.top.bottom.equalTo(self.contentView)
        }
        backView.backgroundColor = UIColor.white
        backView.addSubviews(calendarImgView, dateLabel, timeLabel)
        calendarImgView.image = UIImage(named: "icCalendar")
        calendarImgView.snp.makeConstraints { make in
            make.top.equalTo(self.backView).offset(20)
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }
        timeLabel.alignment(alignment: .center).textColor(color: ColorUtil.main).font(font: FontUtil.bold(size: 15)).text("2.5 hrs")
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
            make.right.equalTo(timeLabel.snp.left).offset(-10)
        }
        initStudyView()
    }

    private func initStudyView() {
        backView.addSubviews(studyView)
        studyView.axis = .vertical
        studyView.distribution = .fill
//        studyView.spacing = 10

        studyView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(dateLabel.snp.bottom).offset(23)
            make.bottom.equalTo(self.backView).offset(-20)
        }
    }
}

extension PracticeCell {
    func initData(data: TKPracticeAssignment) {
        studyView.removeAllArrangedSubviews()
        dateLabel.text(data.time)
        var totalTime: CGFloat = 0
        for item in data.assignments.enumerated() {
            totalTime += item.element.timeLength
            creatInfoLabel(studyView, item.element, item.offset)
        }
        if totalTime > 0 {
            totalTime = totalTime / 60 / 60
            if totalTime <= 0.1 {
                timeLabel.text("0.1 hrs")
            } else {
                timeLabel.text("\(totalTime.roundTo(places: 1)) hrs")
            }

        } else {
            timeLabel.text("0 hrs")
        }
    }

    func creatInfoLabel(_ infoSupperView: UIStackView, _ assignment: TKAssignment, _ index: Int) {
        let infoView = UIView()
        let inifoImgView = UIImageView()
        let infoLabel = TKLabel()

        infoSupperView.addViews(infoView)
        if assignment.recordIds.count > 0 {
            let playImg = TKImageView.create()
                .setImage(name: "icPlayPrimary")
                .addTo(superView: infoView) { make in
                    make.size.equalTo(22)
                    make.right.equalTo(0)
                    make.top.equalToSuperview()
                }
            playImg.tag = index
            playImg.onViewTapped { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.practiceCell(clickPlay: index, cell: self)
            }
        }

        infoView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }

        infoView.addSubviews(inifoImgView, infoLabel)
        inifoImgView.image = UIImage(named: assignment.done ? "checkboxOnGray" : "checkboxOff")

        infoLabel.textColor(color: ColorUtil.Font.primary)
            .font(font: FontUtil.regular(size: 13))
            .text(assignment.assignment)

        inifoImgView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.size.equalTo(22)
        }
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(inifoImgView.snp.right).offset(20)
            make.top.equalToSuperview().offset(2)
            if assignment.recordIds.count > 0 {
                make.right.equalToSuperview().offset(-32)

            } else {
                make.right.equalToSuperview().offset(0)
            }
            make.bottom.equalTo(infoView).offset(-10).priority(.medium)
        }
        infoLabel.numberOfLines = 0
    }
}

protocol PracticeCellDelegate: NSObjectProtocol {
    func practiceCell(clickPlay index: Int, cell: PracticeCell)
}
