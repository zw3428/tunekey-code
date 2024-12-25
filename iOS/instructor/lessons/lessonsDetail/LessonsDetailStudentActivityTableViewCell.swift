//
//  LessonsDetailStudentActivityTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/10/23.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class LessonsDetailStudentActivityTableViewCell: UITableViewCell {
    var cellHeight: CGFloat = 0

    private var backView: TKView!
    private var iconImageView: TKImageView!
    private var titleLabel: TKLabel!
    private var stackView: UIStackView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonsDetailStudentActivityTableViewCell {
    private func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
            .addTo(superView: contentView, withConstraints: { make in
                make.top.left.right.bottom.equalToSuperview()
            })

        iconImageView = TKImageView.create()
            .setImage(name: "icStudientActivityGray")
            .setSize(22)
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalTo(backView).offset(30)
                make.left.equalTo(backView).offset(20)
                make.size.equalTo(22)
            })

        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Student Activity")
            .alignment(alignment: .left)
            .addTo(superView: backView, withConstraints: { make in
                make.centerY.equalTo(iconImageView.snp.centerY)
                make.left.equalTo(iconImageView.snp.right).offset(20)
            })
        _ = TKImageView.create()
            .setImage(name: "arrowRight")
            .addTo(superView: backView, withConstraints: { make in
                make.size.equalTo(22)
                make.centerY.equalTo(iconImageView.snp.centerY)
                make.right.equalToSuperview().offset(-20)
            })

        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        backView.addSubview(view: stackView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }

        drawBorder()
        _ = TKView.create()
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

    private func viewForStackView(text: String) -> TKView {
        let view = TKView.create()
            .backgroundColor(color: UIColor.white)
        let label = TKLabel.create()
            .font(font: FontUtil.bold(size: 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: text)
            .addTo(superView: view, withConstraints: { make in
                make.center.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            })
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return view
    }
}

extension LessonsDetailStudentActivityTableViewCell {
    func loadData(data: [String]) {
        var height: CGFloat = 0
        stackView.removeAllArrangedSubviews()
        for item in data {
            let view = viewForStackView(text: item)
            stackView.addArrangedSubview(view)
            height += item.heightWithFont(font: FontUtil.bold(size: 15), fixedWidth: TKScreen.width - 40) + 10
        }
        cellHeight = height + 80
    }
}
