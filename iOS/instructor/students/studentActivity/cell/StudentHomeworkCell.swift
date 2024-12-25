//
//  StudentHomeworkCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/12.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class StudentHomeworkCell: UICollectionViewCell {
    private var backView: TKView!
    private var calendarImgView: UIImageView! = UIImageView()
    private var dateLabel: TKLabel! = TKLabel()
    private var timeLabel: TKLabel! = TKLabel()

    private var homeworkView = UIStackView()
    private var progressView: UIProgressView!
    weak var delegate: StudentHomeworkCellDelegate!

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentHomeworkCell {
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
        timeLabel.alignment(alignment: .center)
            .textColor(color: ColorUtil.main)
            .font(font: FontUtil.bold(size: 15))
            .text("0%")
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
        progressView = UIProgressView()
        progressView.progressTintColor = ColorUtil.main
        progressView.trackTintColor = ColorUtil.buttonUnClickable
        progressView.setRadius(3)
        progressView.setProgress(0, animated: false)
        backView.addSubview(view: progressView) { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(23).priority(.low)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(6)
        }

        initHomeworkView()
    }

    private func initHomeworkView() {
        backView.addSubviews(homeworkView)
        homeworkView.axis = .vertical
        homeworkView.distribution = .fill
        homeworkView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(progressView.snp.bottom).offset(20)
            make.bottom.equalTo(self.backView).offset(-20)
        }
    }
}

extension StudentHomeworkCell {
    func initData(practiceAssignment: TKPracticeAssignment) {
        dateLabel.text = practiceAssignment.time
        var percentage: CGFloat = 0
        homeworkView.removeAllArrangedSubviews()
        for item in practiceAssignment.assignments.enumerated() {
            creatInfoLabel(homeworkView, assignment: item.element, item.offset)
            if item.element.done {
                percentage += 1
            }
        }
        print("-------\(percentage)")
        if percentage != 0 {
            percentage = percentage / CGFloat(practiceAssignment.assignments.count)
            progressView.setProgress(Float(percentage), animated: false)
            timeLabel.text = "\(Int(percentage * 100))%"
        }
    }

    func creatInfoLabel(_ infoSupperView: UIStackView, assignment: TKAssignment, _ index: Int) {
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
                self.delegate?.studentHomeworkCellCell(clickPlay: index, cell: self)
            }
        }
        infoView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }

        infoView.addSubviews(inifoImgView, infoLabel)
        if assignment.done {
            inifoImgView.image = UIImage(named: "checkboxOnGray")
        } else {
            inifoImgView.image = UIImage(named: "checkboxOff")
        }

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
            if  assignment.recordIds.count > 0{
                make.right.equalToSuperview().offset(-32)

            }else{
                make.right.equalToSuperview().offset(0)

            }
            make.bottom.equalTo(infoView).offset(-10).priority(.medium)
        }
        infoLabel.numberOfLines = 0
    }
}

protocol StudentHomeworkCellDelegate: NSObjectProtocol {
    func studentHomeworkCellCell(clickPlay index: Int, cell: StudentHomeworkCell)
}
