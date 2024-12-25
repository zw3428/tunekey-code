//
//  SLessonNotes2Cell.swift
//  TuneKey
//
//  Created by zyf on 2020/8/26.
//  Copyright © 2020 spelist. All rights reserved.
//

import IQKeyboardManagerSwift
import UIKit

protocol SLessonNotes2CellDelegate: AnyObject {
    func sLessonNotes2Cell(heightChanged height: CGFloat)
    func sLessonNotes2Cell(studentNotesChanged notes: String, height: CGFloat)
    func sLessonNotes2Cell(noteUpdated note: String)
}

class SLessonNotes2Cell: UITableViewCell {
    weak var delegate: SLessonNotes2CellDelegate?

    var cellHeight: CGFloat = 74

    var data: TKLessonSchedule?
    var newMsg: Bool = false

    private var isAdd: Bool = false

    private var topView: TKView = TKView.create()
    private var iconImageView: TKImageView = TKImageView.create()
        .setImage(name: "icLessonNotes")
    private var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 18))
        .text(text: "Lesson Notes")
    private var addButton: TKButton = TKButton.create()
        .setImage(name: "icAddPrimary", size: CGSize(width: 22, height: 22))

    private var notesContainerView: TKView = TKView.create()

    private var teacherAvatarView: TKAvatarView = TKAvatarView(frame: .zero, userId: "", name: "")
    private var teacherNotesLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 18))
        .textColor(color: ColorUtil.Font.primary)
        .setNumberOfLines(number: 0)

    private var studentAvatarView: TKAvatarView = TKAvatarView(frame: .zero, userId: "", name: "")
    private var studentNotesContainerView: TKView = TKView.create()
    private var studentNotesTextView: UITextView = UITextView(frame: .zero)

    private var tipPointerView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.main)
        .corner(size: 3)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
        bindEvent()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SLessonNotes2Cell {
    private func initView() {
        topView.addTo(superView: contentView) { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(74)
        }

        iconImageView.addTo(superView: topView) { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(22)
            make.left.equalToSuperview().offset(20)
        }

        addButton.addTo(superView: topView) { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(22)
            make.height.equalTo(40)
        }

        titleLabel.addTo(superView: topView) { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconImageView.snp.right).offset(20)
            make.right.equalTo(addButton.snp.left).offset(-20)
        }

        notesContainerView.addTo(superView: contentView) { make in
            make.top.equalTo(topView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().priority(.medium)
            make.height.equalTo(0)
        }

        teacherAvatarView.cornerRadius = 16
        teacherAvatarView.addTo(superView: notesContainerView) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(15)
            make.size.equalTo(32)
        }

        tipPointerView.addTo(superView: notesContainerView) { make in
            make.top.equalTo(teacherAvatarView.snp.top).offset(-3)
            make.left.equalTo(teacherAvatarView.snp.right)
            make.size.equalTo(6)
        }

        teacherNotesLabel.addTo(superView: notesContainerView) { make in
            make.top.equalTo(teacherAvatarView.snp.top)
            make.left.equalToSuperview().offset(62)
            make.right.equalToSuperview().offset(-30)
        }
        studentAvatarView.cornerRadius = 16
        studentAvatarView.addTo(superView: notesContainerView) { make in
            make.top.equalTo(teacherNotesLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(15)
            make.size.equalTo(32)
        }

        studentNotesContainerView.cornerRadius = 5
        studentNotesContainerView.backgroundColor = .white
        studentNotesContainerView.addTo(superView: notesContainerView) { make in
            make.top.equalTo(studentAvatarView.snp.top).offset(-10)
            make.left.equalToSuperview().offset(48)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(0)
        }

        studentNotesTextView.backgroundColor = .clear
        studentNotesTextView.delegate = self
        studentNotesTextView.font = FontUtil.regular(size: 18)
        studentNotesTextView.textContainer.lineFragmentPadding = 0
        studentNotesTextView.textContainerInset = .zero
        studentNotesTextView.textColor = ColorUtil.Font.primary
        studentNotesTextView.isScrollEnabled = false
        studentNotesTextView.translatesAutoresizingMaskIntoConstraints = true
        studentNotesTextView.sizeToFit()
        studentNotesTextView.isEditable = false
        studentNotesTextView.addTo(superView: studentNotesContainerView) { make in
            make.top.left.equalToSuperview().offset(10)
            make.right.bottom.equalToSuperview().offset(-10)
        }

        TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)
            .addTo(superView: contentView) { make in
                make.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview()
                make.height.equalTo(1)
            }
    }

    func loadData(_ data: TKLessonSchedule, newMsg: Bool) {
        self.data = data
        self.newMsg = newMsg
        cellHeight = 74
        tipPointerView.isHidden = true
        var height: CGFloat = 0
        if data.teacherNote != "" {
            var h = data.teacherNote.heightWithFont(font: FontUtil.regular(size: 18), fixedWidth: UIScreen.main.bounds.width - 92)
            if h < 41 {
                h = 41
            }
            height += h
            height += 10
            if teacherAvatarView.isHidden {
                teacherAvatarView.isHidden = false
            }
            if teacherNotesLabel.isHidden {
                teacherNotesLabel.isHidden = false
            }
            teacherAvatarView.loadImage(userId: data.teacherId, name: "")
            teacherNotesLabel.text = data.teacherNote
            tipPointerView.isHidden = !newMsg
        } else {
            teacherAvatarView.isHidden = true
            teacherNotesLabel.isHidden = true
            teacherNotesLabel.text = ""
        }
        if data.studentNote != "" || isAdd {
            addButton.isHidden = true
            var h = data.studentNote.heightWithFont(font: FontUtil.regular(size: 18), fixedWidth: UIScreen.main.bounds.width - 92) + 20
            if h < 41 {
                h = 41
            }
            studentNotesContainerView.snp.updateConstraints { make in
                make.height.equalTo(h)
            }
            height += h
            height += 10
            if studentAvatarView.isHidden {
                studentAvatarView.isHidden = false
            }
            if studentNotesContainerView.isHidden {
                studentNotesContainerView.isHidden = false
            }
            studentAvatarView.loadImage(userId: data.studentId, name: "")
            studentNotesTextView.text = data.studentNote
            studentAvatarView.snp.updateConstraints { make in
                make.top.equalTo(teacherNotesLabel.snp.bottom).offset(data.teacherNote == "" ? 0 : 20)
            }
        } else {
            if let config = ListenerService.shared.studentData.scheduleConfigs.first(where: { $0.id == data.lessonScheduleConfigId }) {
                switch config.lessonCategory {
                case .single:
                    addButton.isHidden = false
                case .group:
                    addButton.isHidden = true
                }
            } else {
                addButton.isHidden = false
            }
            studentAvatarView.isHidden = true
            studentNotesContainerView.isHidden = true
        }

        notesContainerView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        cellHeight += height
        delegate?.sLessonNotes2Cell(heightChanged: cellHeight)
    }

    private func bindEvent() {
        addButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.onAddButtonTapped()
        }
        teacherNotesLabel.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            let text = self.teacherNotesLabel.text ?? ""
            guard text != "" else { return }
            LargeContentPreviewViewController.show(text)
        }

        studentNotesTextView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.onAddButtonTapped()
        }
    }

    private func onAddButtonTapped() {
        guard let data = data else { return }
        isAdd = true
        addButton.isHidden = true
        let controller = LessonDetailAddNewContentViewController()
        controller.font = FontUtil.bold(size: 20)
        controller.text = data.studentNote
        controller.titleString = "Notes"
        controller.titleAlignment = .left
        controller.rightButtonString = "SAVE"
        controller.onLeftButtonTapped = { [weak self] _ in
            guard let self = self else { return }
            controller.hide()
            if self.studentNotesTextView.text == "" {
                self.addButton.isHidden = false
                self.isAdd = true
            }
        }
        controller.onRightButtonTapped = { [weak self] text in
            guard let self = self else { return }
            controller.hide()
            if text == "" {
                self.isAdd = true
                self.addButton.isHidden = false
            }
            self.studentNotesTextView.text = text
            self.textViewDidEndEditing(self.studentNotesTextView)
        }
        controller.modalPresentationStyle = .custom
        Tools.getTopViewController()?.present(controller, animated: false)
//        let transform = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
//        studentAvatarView.transform = transform
//        studentNotesContainerView.transform = transform
//        studentAvatarView.isHidden = false
//        studentNotesContainerView.isHidden = false
//        studentAvatarView.loadImage(userId: data.studentId, name: "")
//        cellHeight += 52
//        delegate?.sLessonNotes2Cell(heightChanged: cellHeight)
//        studentAvatarView.snp.updateConstraints { make in
//            make.top.equalTo(teacherNotesLabel.snp.bottom).offset(data.teacherNote == "" ? 0 : 20)
//        }
//        studentNotesContainerView.snp.updateConstraints { make in
//            make.height.equalTo(41)
//        }
//        notesContainerView.snp.updateConstraints { make in
//            make.height.equalTo(52 )
//        }
//        UIView.animate(withDuration: 0.2, animations: { [weak self] in
//            guard let self = self else { return }
//            self.studentAvatarView.transform = .identity
//            self.studentNotesContainerView.transform = .identity
//        }) { [weak self] _ in
//            guard let self = self else { return }
//            self.studentNotesTextView.becomeFirstResponder()
//        }
    }
}

extension SLessonNotes2Cell: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.studentNotesContainerView.isShadowShow = false
            self.studentNotesContainerView.showShadow()
            self.studentNotesContainerView.showBorder(color: ColorUtil.borderColor)
            self.studentNotesContainerView.clipsToBounds = false
        }
        return true
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.studentNotesContainerView.isShadowShow = false
            self.studentNotesContainerView.hideBorder()
            self.studentNotesContainerView.clipsToBounds = false
            guard let text = textView.text else { return }
            if text == "" {
                self.studentNotesContainerView.snp.updateConstraints { make in
                    make.height.equalTo(0)
                }
                self.notesContainerView.snp.updateConstraints { make in
                    make.height.equalTo(0)
                }
                self.cellHeight = self.cellHeight - 52
                if self.cellHeight <= 0 {
                    self.cellHeight = 74
                }
                self.delegate?.sLessonNotes2Cell(heightChanged: self.cellHeight)
                self.studentAvatarView.snp.updateConstraints { make in
                    make.top.equalTo(self.teacherNotesLabel.snp.bottom).offset(0)
                }
                self.studentAvatarView.isHidden = true
                self.studentNotesContainerView.isHidden = true
                self.addButton.isHidden = false
            }
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text, let data = data else { return }
        data.studentNote = text
        loadData(data, newMsg: newMsg)
        delegate?.sLessonNotes2Cell(studentNotesChanged: text, height: cellHeight)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.sLessonNotes2Cell(noteUpdated: textView.text)
    }

//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        guard let data = self.data else { return false }
//        let string = (textView.text as NSString).replacingCharacters(in: range, with: text)
//        logger.debug("string: \(string)")
//        data.studentNote = string
//        loadData(data)
//        delegate?.sLessonNotes2Cell(studentNotesChanged: string, height: cellHeight)
//        return true
//    }
}
