//
//  SLessonNotesCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/21.
//  Copyright © 2019年 spelist. All rights reserved.
//

import SnapKit
import UIKit
class SLessonNotesCell: UITableViewCell {
    weak var delegate: SLessonNotesCellDelegate!

    private var mainView: TKView!
    private var arrowView: UIImageView!
    private var contentLayout = UIStackView()
    private var contentHeight: CGFloat = 0
    var cellHeight: CGFloat = 0
    var isShow = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SLessonNotesCell {
    func initView() {
        contentView.backgroundColor = UIColor.white
        mainView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.edges.equalToSuperview()
            })
        mainView.layer.masksToBounds = true
        let titleView = TKView.create()
            .addTo(superView: mainView) { make in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(74)
            }
        titleView.onViewTapped { [weak self] _ in
            self?.clickTitleView()
        }
        let iconView = UIImageView()
        iconView.image = UIImage(named: "icLessonNotes")
        titleView.addSubview(view: iconView) { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(32)
            make.size.equalTo(22)
        }
        _ = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .text(text: "Lesson notes")
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: titleView) { make in
                make.left.equalTo(iconView.snp.right).offset(20)
                make.top.equalTo(32)
            }
        arrowView = UIImageView()
        arrowView.image = UIImage(named: "icArrowDown")
        titleView.addSubview(view: arrowView) { make in
            make.size.equalTo(22)
            make.top.equalTo(32)
            make.right.equalTo(-20)
        }

        contentLayout.axis = .vertical
        contentLayout.spacing = 10
        contentLayout.alignment = .fill
        mainView.addSubview(view: contentLayout) { make in
            make.right.equalToSuperview().offset(-20)
            make.left.equalTo(iconView.snp.right).offset(20)
            make.top.equalTo(titleView.snp.bottom)
            make.height.equalTo(0)
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

    func initContentLayout(note: String, who: String) {
        let contentLabel: TKLabel! = TKLabel()
        contentLayout.addArrangedSubview(contentLabel)
        contentLabel.textColor(color: ColorUtil.Font.primary).font(font: FontUtil.regular(size: 18)).text("")
        contentLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byCharWrapping
        contentLabel.changeLabelRowSpace(lineSpace: 20, wordSpace: 0)
        let text = "\(note)"
        let height = text.heightWithFont(font: FontUtil.regular(size: 18), fixedWidth: UIScreen.main.bounds.width - 82)
        contentHeight += height
        contentLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: "\(who)", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.Font.primary, font: FontUtil.regular(size: 18), fontSize: 18)
    }
}

extension SLessonNotesCell {
    func initData(data: TKLessonSchedule) {
        contentLayout.removeAllArrangedSubviews()
        contentHeight = 0
        var count = 0
        if data.teacherNote != "" {
            count += 1
            initContentLayout(note: "Instructor: \(data.teacherNote)", who: "Instructor:")
        }
        if data.studentNote != "" {
            count += 1
            initContentLayout(note: "Me: \(data.studentNote)", who: "Me:")
        }
        if count != 0 {
            contentHeight = contentHeight + CGFloat((count - 1) * 10)
        }
       
        
    }

    func clickTitleView() {
        isShow = !isShow
        cellHeight = 74
        if contentHeight != 0 {
            cellHeight = isShow ? (74 + contentHeight + 20) : 74
        }
        SL.Animator.run(time: 0.3) { [weak self] in
            guard let self = self else { return }
            if self.isShow {
                self.arrowView.transform = CGAffineTransform.identity
                    .rotated(by: CGFloat(Double.pi))
            } else {
                self.arrowView.transform = CGAffineTransform.identity
            }
            self.contentLayout.snp.updateConstraints({ make in
                if self.isShow {
                    make.height.equalTo(self.contentHeight)
                } else {
                    make.height.equalTo(0)
                }
            })
            self.layoutIfNeeded()
        }
        delegate?.LessonNotesCell(clickCell: self, cellHeight: cellHeight)
    }
}

protocol SLessonNotesCellDelegate: NSObjectProtocol {
    func LessonNotesCell(clickCell cell: SLessonNotesCell, cellHeight: CGFloat)
}
