//
//  AchieVementCell.swift
//  TuneKey
//
//  Created by Wht on 2019/8/22.
//  Copyright © 2019年 spelist. All rights reserved.
//

import SnapKit
import UIKit

class AchieVementCell: UICollectionViewCell {
    private var backView: TKView!
    private var calendarImgView: UIImageView! = UIImageView()
    private var dateLabel: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isScrollEnabled = false
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInset = .zero
        textView.tintColor = .clickable
        textView.font = FontUtil.bold(size: 18)
        textView.textColor = ColorUtil.Font.third
        return textView
    }()

    private var typeImgView: UIImageView! = UIImageView()
    private var contentLabel: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isScrollEnabled = false
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInset = .zero
        textView.tintColor = .clickable
        textView.font = FontUtil.regular(size: 18)
        textView.textColor = ColorUtil.Font.primary
        return textView
    }()

    private var data: TKAchievement!
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AchieVementCell {
    func initView() {
        backView = TKView()
        contentView.addSubview(backView)
        _ = backView.showShadow()
        backView.setTKBorderAndRaius()
        backView.snp.makeConstraints { make in
            make.width.equalTo(self.contentView.frame.width - 40)
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        backView.backgroundColor = UIColor.white
        backView.addSubviews(calendarImgView, dateLabel, typeImgView, contentLabel)

        calendarImgView.image = UIImage(named: "icCalendar")
        calendarImgView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }

        typeImgView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }
        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalTo(calendarImgView.snp.right).offset(20)
            make.right.equalTo(typeImgView.snp.left).offset(-20)
            make.height.equalTo(22)
        }

        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(10)
            make.left.equalTo(calendarImgView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(backView.snp.bottom).offset(-20).priority(.medium)
        }
    }

    func initItem(data: TKAchievement) {
        self.data = data
        var string = ""
        switch data.type {
        case .all:
            break
        case .technique:
            string = "Technique"
            typeImgView.image = UIImage(named: "icTechnique")
        case .notation:
            string = "Theory"
            typeImgView.image = UIImage(named: "icNotation")
        case .song:
            string = "Song"
            typeImgView.image = UIImage(named: "icSong")
        case .improv:
            string = "Improvement"
            typeImgView.image = UIImage(named: "icDedication")
        case .groupPlay:
            string = "Group play"
            typeImgView.image = UIImage(named: "icGroupPlay")
        case .dedication:
            string = "Dedication"
            typeImgView.image = UIImage(named: "icImprov")
        case .creativity:
            string = "Creativity"
            typeImgView.image = UIImage(named: "icCreativity")
        case .hearing:
            string = "Listening"
            typeImgView.image = UIImage(named: "icHearing")
        case .musicSheet:
            string = "Sight reading"
            typeImgView.image = UIImage(named: "icMusicSheet")
        case .memorization:
            string = "Memorization"
            typeImgView.image = UIImage(named: "icon_memorization")
        }
        string = "\(string): \(data.name)\n\(data.desc)"

        contentLabel.attributedText = Tools.attributenStringColor(text: string, selectedText: "\(data.name)", allColor: ColorUtil.Font.primary, selectedColor: ColorUtil.Font.third, font: FontUtil.regular(size: 18), selectedFont: FontUtil.regular(size: 18), fontSize: 18, selectedFontSize: 18)
        let d = DateFormatter()
        d.dateFormat = "MMM dd"
        dateLabel.text = d.string(from: TimeUtil.changeTime(time: Double(data.date) ?? 0))
    }
}
