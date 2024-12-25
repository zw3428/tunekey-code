//
//  LessonSearchEventCell.swift
//  TuneKey
//
//  Created by wht on 2020/8/11.
//  Copyright © 2020 spelist. All rights reserved.
//

import Foundation
import UIKit

class LessonSearchEventCell: UICollectionViewCell {
    private var mainView: TKView!
    private var eventLabel: TKLabel!
    private var nameLabel: TKLabel!
    override init(frame: CGRect) {
        super.init(frame:frame)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonSearchEventCell {
    func initView() {
        contentView.backgroundColor = UIColor.white
        mainView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.left.top.bottom.right.equalToSuperview()
                make.height.equalTo(94)
            })
        eventLabel = TKLabel.create()
            .alignment(alignment: .center)
            .textColor(color: ColorUtil.Font.primary)
            .font(font: FontUtil.bold(size: 18))
            .addTo(superView: mainView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.size.equalTo(60)
            })
        eventLabel.text = "Event"
        eventLabel.backgroundColor = UIColor(r: 235, g: 237, b: 238, alpha: 0.32)
        eventLabel.layer.cornerRadius = 30
        eventLabel.layer.masksToBounds = true
        nameLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .alignment(alignment: .left)
            .text(text: "")
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalTo(eventLabel.snp.right).offset(20)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-60)
            })

        nameLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        _ = TKImageView.create()
            .setImage(name: "arrowRight")
            .setSize(22)
            .addTo(superView: mainView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.size.equalTo(22)
                make.right.equalToSuperview().offset(-20)
            })
        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: mainView) { make in
                make.bottom.right.equalToSuperview()
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(20)
            }
    }
    func initData(data:TKEventConfigure){
        nameLabel.heroID = "\(data.title)"
        nameLabel.text("\(data.title)")
    }
}

