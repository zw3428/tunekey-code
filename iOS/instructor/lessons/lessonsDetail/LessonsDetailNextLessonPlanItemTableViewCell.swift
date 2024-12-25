//
//  LessonsDetailNextLessonPlanItemTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/10/22.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class LessonsDetailNextLessonPlanItemTableViewCell: UITableViewCell {
    weak var delegate: LessonsDetailNextLessonPlanItemTableViewCellDelegate?

    private var prefixView: TKView!
    private var contentTextView: UITextView!
    private var removeButton: TKButton!

    var cellHeight: CGFloat = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonsDetailNextLessonPlanItemTableViewCell {
    private func initView() {
        contentTextView = UITextView()
        contentTextView.delegate = self
        contentTextView.font = FontUtil.medium(size: 15)
        contentTextView.textColor = ColorUtil.Font.primary
        contentTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        contentTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        contentTextView.isScrollEnabled = false
        contentView.addSubview(view: contentTextView) { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.left.equalToSuperview().offset(60)
            make.right.equalToSuperview().offset(-60)
        }

        prefixView = TKView.create()
            .backgroundColor(color: UIColor(red: 230, green: 233, blue: 235))
            .corner(size: 6)
            .addTo(superView: contentView, withConstraints: { make in
                make.size.equalTo(12)
                make.top.equalTo(contentTextView.snp.top).offset(3)
                make.left.equalToSuperview().offset(40)
            })

        removeButton = TKButton.create()
            .setImage(name: "icDeleteRed", size: CGSize(width: 22, height: 22))
            .addTo(superView: contentView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(40)
                make.size.equalTo(40)
            })
        removeButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            if self.contentTextView.resignFirstResponder() {
                self.delegate?.lessonsDetailNextLessonPlanItemTableViewCell(removeButtonTappedAt: self.tag)
            }
        }
    }

    private func updateHeight() {
        if contentTextView.text != "" {
            let height = contentTextView.heightForText(fixedWidth: TKScreen.width - 120)
            cellHeight = height + 12
        }
    }

    func loadData(text: String) -> CGFloat {
        contentTextView.text = text
        updateHeight()
        return cellHeight
    }
}

extension LessonsDetailNextLessonPlanItemTableViewCell: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.removeButton.snp.remakeConstraints({ make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-10)
                make.size.equalTo(40)
            })
        }
        contentView.layoutIfNeeded()
        updateHeight()
        if cellHeight <= 40 {
            cellHeight = 40
        }
        contentTextView.isScrollEnabled = true
        delegate?.lessonsDetailNextLessonPlanItemTableViewCell(textChanged: textView.text, height: cellHeight, at: tag)
        return true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.removeButton.snp.remakeConstraints({ make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(40)
                make.size.equalTo(40)
            })
        }
        contentView.layoutIfNeeded()
        contentTextView.isScrollEnabled = false
        updateHeight()
        delegate?.lessonsDetailNextLessonPlanItemTableViewCell(heightChanged: cellHeight, at: tag)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let _text = (textView.text! as NSString).replacingCharacters(in: range, with: text)
        delegate?.lessonsDetailNextLessonPlanItemTableViewCell(textChanged: _text, height: cellHeight, at: tag)
        return true
    }
}

protocol LessonsDetailNextLessonPlanItemTableViewCellDelegate: NSObjectProtocol {
    func lessonsDetailNextLessonPlanItemTableViewCell(textChanged text: String, height: CGFloat, at index: Int)
    func lessonsDetailNextLessonPlanItemTableViewCell(heightChanged height: CGFloat, at index: Int)
    func lessonsDetailNextLessonPlanItemTableViewCell(removeButtonTappedAt index: Int)
}
