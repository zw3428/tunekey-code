//
//  LessonDetailPracticeCell.swift
//  TuneKey
//
//  Created by WHT on 2020/2/27.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class LessonDetailPracticeTableViewCell: UITableViewCell {
    var backView: TKView!
    var infoImgView: UIImageView!
    var titleLabel: TKLabel!
    var infoLeftOneLabel: TKLabel!
    var infoLeftTwoLabel: TKLabel!
    var infoRightOneLabel: TKLabel!
    var infoRightTwoLabel: TKLabel!
    var arrowImgView: UIImageView!
    var cellHeight: CGFloat = 140 // 140
    var lineView: TKView!
    
    weak var delegate: LessonDetailPracticeTableViewCellDelegate!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonDetailPracticeTableViewCell {
    func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
            .addTo(superView: contentView, withConstraints: { make in
                make.top.left.right.bottom.equalToSuperview()
            })
        backView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.lessonDetailPracticeTableViewCell(cell: self)
        }
        backView.layer.masksToBounds = true
        infoImgView = UIImageView()
        infoImgView.image = UIImage(named: "icStudientActivityGray")
        backView.addSubview(infoImgView)
        infoImgView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(30)
            make.size.equalTo(22)
        }

        arrowImgView = UIImageView()
        backView.addSubview(arrowImgView)
        arrowImgView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(30)
            make.size.equalTo(22)
        }
        arrowImgView.image = UIImage(named: "arrowRight")

        titleLabel = TKLabel()
        backView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(23)
            make.top.equalToSuperview().offset(30)
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

        infoLeftOneLabel.changeLabelRowSpace(lineSpace: 24, wordSpace: 0)
        infoLeftTwoLabel.changeLabelRowSpace(lineSpace: 24, wordSpace: 0)

        infoLeftOneLabel.textColor(color: ColorUtil.Font.primary).font(FontUtil.regular(size: 18))
        infoLeftTwoLabel.textColor(color: ColorUtil.Font.primary).font(FontUtil.regular(size: 18))
        infoLeftOneLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        infoLeftTwoLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(infoLeftOneLabel.snp.bottom).offset(3)
        }
        infoRightOneLabel.changeLabelRowSpace(lineSpace: 24, wordSpace: 0)
        infoRightTwoLabel.changeLabelRowSpace(lineSpace: 24, wordSpace: 0)
        infoRightOneLabel.textColor(color: ColorUtil.Font.third).font(FontUtil.regular(size: 18))
        infoRightTwoLabel.textColor(color: ColorUtil.Font.third).font(FontUtil.regular(size: 18))
        infoRightOneLabel.snp.makeConstraints { make in
            make.right.equalTo(arrowImgView.snp.left).offset(-20).priority(.low)
            make.left.equalTo(infoLeftOneLabel.snp.right)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        infoRightTwoLabel.snp.makeConstraints { make in
            make.right.equalTo(arrowImgView.snp.left).offset(-20).priority(.low)
            make.left.equalTo(infoLeftTwoLabel.snp.right)
            make.top.equalTo(infoLeftOneLabel.snp.bottom).offset(4)
        }

        titleLabel.text("Student practice")
        infoLeftOneLabel.text("Self study: ")
        infoLeftTwoLabel.text("Homework: ")
        infoRightOneLabel.text("0 hrs")
        infoRightTwoLabel.text("No assignment")
        drawBorder()
        lineView = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: backView) { make in
                make.left.equalToSuperview().offset(20)
                make.right.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
    }

    private func drawBorder() {
        let layer = CALayer()
        layer.frame = CGRect(x: 10, y: 0, width: UIScreen.main.bounds.width - 20, height: 1)
        layer.backgroundColor = ColorUtil.borderColor.cgColor
        backView.layer.addSublayer(layer)

        let path = UIBezierPath(arcCenter: CGPoint(x: 10, y: 10), radius: 10, startAngle: .pi, endAngle: .pi * (3 / 2), clockwise: true)
        path.lineWidth = 1
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
        path.addArc(withCenter: CGPoint(x: UIScreen.main.bounds.width - 10, y: 10), radius: 10, startAngle: .pi * (3 / 2), endAngle: .pi * 2, clockwise: true)
        path.stroke()
        let layer2 = CAShapeLayer()
        layer2.path = path.cgPath
        layer2.strokeColor = ColorUtil.borderColor.cgColor
        layer2.fillColor = UIColor.white.cgColor
        backView.layer.addSublayer(layer2)
    }
}

extension LessonDetailPracticeTableViewCell {
    func initData(data: [TKPractice]) {
        cellHeight = 140
//        lineView.snp.updateConstraints { make in
//            make.height.equalTo(1)
//        }
//        var a: CGFloat = 0
//        for item in data where item.done {
//            a += 1
//        }
//        if a != 0 {
//            a = a / CGFloat(data.count)
//            backView.layer.masksToBounds = false
//        }
//        infoRightTwoLabel.text("\(Int(a * 100))% completion")
        var homeworkCount: CGFloat = 0
        var homeworkDoneCount: CGFloat = 0
        var practiceTotalTime: CGFloat = 0
        logger.debug("开始计算作业的完成度: \(data.toJSONString() ?? "")")
        for item in data {
            if !item.assignment {
                practiceTotalTime += item.totalTimeLength
            } else {
                homeworkCount += 1
                if item.done {
                    homeworkDoneCount += 1
                }
//                if item.startTime == item.shouldDateTime {
//                    homeworkCount += 1
//                    if item.done {
//                        homeworkDoneCount += 1
//                    }
//                }
            }
        }
        if homeworkCount != 0 {
            logger.debug("计算出的练习作业结果: \(homeworkDoneCount) / \(homeworkCount)")
            homeworkDoneCount = homeworkDoneCount / homeworkCount
            infoRightTwoLabel.text("\(Int(homeworkDoneCount * 100))% completion")
        } else {
            infoRightTwoLabel.text("No assignment")
        }

        if practiceTotalTime > 0 {
            practiceTotalTime = practiceTotalTime / 60 / 60
            if practiceTotalTime <= 0.1 {
                infoRightOneLabel.text("0.1 hrs")
            } else {
                infoRightOneLabel.text("\(practiceTotalTime.roundTo(places: 1)) hrs")
            }
        } else {
            infoRightOneLabel.text("0 hrs")
        }
    }
}

protocol LessonDetailPracticeTableViewCellDelegate: NSObjectProtocol {
    func lessonDetailPracticeTableViewCell(cell: LessonDetailPracticeTableViewCell)
}
