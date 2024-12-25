//
//  MilestonesCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/25.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class MilestonesCell: UITableViewCell {
    private var mainView: TKView!
    private var calendarImgView: UIImageView! = UIImageView()
    private var dateLabel: TKLabel! = TKLabel()
    private var typeImgView: UIImageView! = UIImageView()
    private var contentLabel: TKLabel! = TKLabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MilestonesCell {
    func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        mainView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.bottom.equalToSuperview().offset(-10)
            })
        mainView.setShadows()
        mainView.addSubviews(calendarImgView, dateLabel, typeImgView, contentLabel)

        calendarImgView.image = UIImage(named: "icCalendar")
        calendarImgView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }

        typeImgView.image = UIImage(named: "icTechnique")
        typeImgView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }

        dateLabel.textColor(color: ColorUtil.Font.third).font(font: FontUtil.bold(size: 18)).text("July 17")
        dateLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalTo(calendarImgView.snp.right).offset(20)
            make.right.equalTo(typeImgView.snp.left).offset(-20)
            make.height.equalTo(22)
        }

        _ = contentLabel.textColor(color: ColorUtil.Font.primary).font(font: FontUtil.regular(size: 13))
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(10)
            make.left.equalTo(calendarImgView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
        }
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
    }
}

extension MilestonesCell {
    func initData(data: TKAchievement) {
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
            string = data.typeName
            typeImgView.image = UIImage(named: data.icon)
        }
        string = "\(string): \(data.name)\n\(data.desc)"
        contentLabel.attributedText = Tools.attributenStringColor(text: string, selectedText: "\(data.name)", allColor: ColorUtil.Font.primary, selectedColor: ColorUtil.Font.third, font: FontUtil.regular(size: 13), fontSize: 13, ignoreCase: true, charasetSpace: 0)
        let d = DateFormatter()
        d.dateFormat = "MMM dd"
        dateLabel.text = d.string(from: TimeUtil.changeTime(time: data.shouldDateTime))
    }
}
