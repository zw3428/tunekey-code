//
//  InsightsLearningStudentsCollectionViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/4.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class InsightsLearningStudentsCollectionViewCell: UICollectionViewCell {
    private var headerView: TKView!
    private var containerView: TKView!
    private var avatarView: TKAvatarView!
    private var nameLabel: TKLabel!
    private var contentLabel: TKLabel!
    private var hoursLabel: TKLabel!
    private var hoursUnitLabel: TKLabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InsightsLearningStudentsCollectionViewCell {
    private func initView() {
        contentView.backgroundColor = UIColor.white
        headerView = TKView.create()
            .backgroundColor(color: UIColor.white)
        headerView.isHidden = true
        drawBorder()
        contentView.addSubview(view: headerView) { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Students")
        headerView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(20)
        }
        containerView = TKView.create()
            .backgroundColor(color: UIColor.white)
        contentView.addSubview(view: containerView) { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(94)
        }
        avatarView = TKAvatarView()
        avatarView.setSize(size: 60)

        containerView.addSubview(view: avatarView) { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(60)
        }

        nameLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
            .alignment(alignment: .left)
            .text(text: "")
        containerView.addSubview(view: nameLabel) { make in
            make.top.equalToSuperview().offset(28)
            make.left.equalTo(avatarView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-40)
        }

        contentLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "0 awards")
        containerView.addSubview(view: contentLabel) { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.left.equalTo(avatarView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-40)
        }

        hoursUnitLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 13))
            .textColor(color: ColorUtil.main)
            .text(text: "hrs")
        containerView.addSubview(view: hoursUnitLabel) { make in
            make.centerY.equalTo(contentLabel.snp.centerY)
            make.right.equalToSuperview().offset(-20)
        }

        hoursLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.main)
            .text(text: "0")
        containerView.addSubview(view: hoursLabel) { make in
            make.centerY.equalTo(nameLabel.snp.centerY)
            make.centerX.equalTo(hoursUnitLabel.snp.centerX)
        }
        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: containerView) { make in
                make.bottom.right.equalToSuperview()
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(20)
        }
    }

    private func drawBorder() {
        let layer = CALayer()
        layer.frame = CGRect(x: 10, y: 0, width: UIScreen.main.bounds.width - 20, height: 1)
        layer.backgroundColor = ColorUtil.borderColor.cgColor
        headerView.layer.addSublayer(layer)

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
        headerView.layer.addSublayer(layer2)
    }
//wayne@prodrocket.com
    func loadData(index: Int,data:TKLearningStudent) {
        if index == 0 {
            headerView.isHidden = false
            headerView.snp.updateConstraints { make in
                make.height.equalTo(50)
            }
        } else {
            headerView.isHidden = true
            headerView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }
        let timeLength = (data.practiceHour ).roundTo(places: 1)
        if timeLength > 0 {
            if timeLength < 0.1{
                hoursLabel.text("0.1")
            }
            hoursLabel.text("\(timeLength)")

        }else{
            hoursLabel.text("0")
        }
        nameLabel.text("\(data.name)")
        contentLabel.text("\(data.achievementCount!) awards")
        avatarView.loadImage(userId: data.studentId, name: data.name)
    }
}
