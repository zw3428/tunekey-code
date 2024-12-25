//
//  NotesCell.swift
//  TuneKey
//
//  Created by Wht on 2019/8/23.
//  Copyright © 2019年 spelist. All rights reserved.
//

import SnapKit
import UIKit

class NotesCell: UICollectionViewCell {
    private var backView: TKView!
    private var calendarImgView: UIImageView! = UIImageView()
    private var dateLabel: TKLabel! = TKLabel()
    private var contentLayout: UIStackView = UIStackView()
    private var isLoad = false
    private var data: TKLessonSchedule!
    struct NoteData {
        // 1 是老师 2是学生
        var who: Int = 1
        var note: String = ""
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NotesCell {
    func initView() {
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
        backView.addSubviews(calendarImgView, dateLabel, contentLayout)
        calendarImgView.image = UIImage(named: "icCalendar")
        calendarImgView.snp.makeConstraints { make in
            make.top.equalTo(self.backView).offset(20)
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }
        dateLabel.textColor(color: ColorUtil.Font.third).font(FontUtil.bold(size: 18))
        dateLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(self.backView).offset(20)
            make.left.equalTo(calendarImgView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(22)
        }
        contentLayout.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(10)
            make.left.equalTo(calendarImgView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(self.backView).offset(-20).priority(.medium)
        }
        contentLayout.axis = .vertical
        contentLayout.spacing = 10
        contentLayout.alignment = .fill
    }

    func initItem(data: TKLessonSchedule) {
        self.data = data
//        let d = DateFormatter()
//        d.dateFormat = "MMM dd"
        dateLabel.text = Date(seconds: data.getShouldDateTime()).toLocalFormat("MMM dd")
        contentLayout.removeAllArrangedSubviews()
        var noteDatas: [NoteData] = []
        if data.studentNote != "" {
            noteDatas.append(NoteData(who: 2, note: data.studentNote))
        }
        if data.teacherNote != "" {
            noteDatas.append(NoteData(who: 1, note: data.teacherNote))
        }
        for item in noteDatas {
            let contentLabel: TKLabel = TKLabel()
            contentLayout.addArrangedSubview(contentLabel)
            contentLabel.textColor(color: ColorUtil.Font.primary).font(font: FontUtil.regular(size: 18)).text("")
            contentLabel.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
            contentLabel.numberOfLines = 0
            contentLabel.lineBreakMode = .byWordWrapping
            contentLabel.changeLabelRowSpace(lineSpace: 20, wordSpace: 0)
            var who = "Me: "
            if item.who == 2{
                who = "Student: "
            }
            
            let text = "\(who)\(item.note)"
            contentLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: who, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.Font.primary, font: FontUtil.regular(size: 18), fontSize: 18)
        }
//        isLoad = true
    }
}
