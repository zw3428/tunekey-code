//
//  SPreparationCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/21.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class SPreparationCell: UITableViewCell {
    private var mainView: TKView!
    private var practiceInfoLabel: TKLabel!
    private var homeworkInfoLabel: TKLabel!
    var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 18))
        .textColor(color: ColorUtil.Font.third)
    weak var delegate: SPreparationCellDelegate?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SPreparationCell {
    func initView() {
        contentView.backgroundColor = UIColor.white
        mainView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.left.right.top.bottom.equalToSuperview()
                make.height.equalTo(83 + 22)
            })
        let iconView = UIImageView()
        iconView.image = UIImage(named: "icStudientActivityGray")
        mainView.addSubview(view: iconView) { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview()
            make.size.equalTo(22)
        }
        mainView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.preparationCell(cell: self)
        }
        titleLabel.addTo(superView: mainView) { make in
            make.left.equalTo(iconView.snp.right).offset(18)
            make.top.equalToSuperview()
        }

        let practiceLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 18))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Self study: ")
            .addTo(superView: mainView) { make in
                make.left.equalTo(titleLabel.snp.left)
                make.top.equalTo(titleLabel.snp.bottom).offset(18)
            }
        practiceInfoLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: mainView) { make in
                make.left.equalTo(practiceLabel.snp.right)
                make.top.equalTo(titleLabel.snp.bottom).offset(20)
            }

        let homeworkLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 18))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Assignment: ")
            .addTo(superView: mainView) { make in
                make.left.equalTo(titleLabel.snp.left)
                make.top.equalTo(practiceLabel.snp.bottom)
            }
        homeworkInfoLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 18))
            .textColor(color: ColorUtil.kermitGreen)
            .addTo(superView: mainView) { make in
                make.left.equalTo(homeworkLabel.snp.right)
                make.top.equalTo(practiceInfoLabel.snp.bottom)
            }

        // arrow
        let arrowView = UIImageView()
        arrowView.image = UIImage(named: "arrowRight")
        mainView.addSubview(view: arrowView) { make in
            make.size.equalTo(22)
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: mainView) { make in
                make.bottom.right.equalToSuperview()
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(20)
            }
    }
}

extension SPreparationCell {
    func initData(data: TKLessonSchedule) {
//        homeworkInfoLabel.text("Complete")
        logger.debug("加载练习数据: \(data.practiceData.toJSONString() ?? "")")
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
    }

    func initDataWithNoneData() {
        practiceInfoLabel.text("0 hrs")
        homeworkInfoLabel.text("No assignment")
    }
}

protocol SPreparationCellDelegate: NSObjectProtocol {
    func preparationCell(cell: SPreparationCell)
}
