//
//  LessonsDetailLessonNotesTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/3.
//  Copyright © 2019年 spelist. All rights reserved.
//

import IQKeyboardManagerSwift
import UIKit

class LessonsDetailLessonNotesTableViewCell: UITableViewCell {
    struct Item {
        var backView: TKView
        var contentView: TKView
        var avatarView: TKAvatarView
        var textView: UITextView
        var index: Int
    }

    weak var delegate: LessonsDetailLessonNotesTableViewCellDelegate?

    var data: TKLessonSchedule!
    var cellHeight: CGFloat = 0
    private var cellHeights: [CGFloat] = []

    private var views: [Item] = []

    private var backView: TKView!
    private var iconImageView: TKImageView!
    private var titleLabel: TKLabel!
    var addButton: TKButton!
    private var stackView: UIStackView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonsDetailLessonNotesTableViewCell {
    private func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
            .addTo(superView: contentView, withConstraints: { make in
                make.top.left.right.bottom.equalToSuperview()
            })

        iconImageView = TKImageView.create()
            .setImage(name: "icLessonNotes")
            .setSize(22)
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalTo(backView).offset(30)
                make.left.equalTo(backView).offset(20)
                make.size.equalTo(22)
            })

        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Lesson notes")
            .alignment(alignment: .left)
            .addTo(superView: backView, withConstraints: { make in
                make.centerY.equalTo(iconImageView.snp.centerY)
//                make.left.equalTo(iconImageView.snp.right).offset(20)
                make.left.equalToSuperview().offset(60)
            })

        addButton = TKButton.create()
            .setImage(name: "icAddPrimary", size: CGSize(width: 22, height: 22))
        addButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            logger.debug("add lessons notes button tapped")
            OperationQueue.main.addOperation {
                self.addButton.isHidden = true
                self.delegate?.lessonsDetailLessonNotesTableViewCellAddLessonTapeed(addButton: self.addButton) {
                    self.showNotesAddController { text in
                        self.addNote(content: text)
                    }
                }
            }
        }
        backView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.top.equalTo(backView).offset(21)
            make.right.equalTo(backView).offset(-11)
            make.size.equalTo(40)
        }

        stackView = UIStackView()
        stackView.axis = .vertical
        backView.addSubview(view: stackView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }

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

    func loadData(data: TKLessonSchedule, studio: TKStudio?) {
        self.data = data
        var cellCount = 0
        if data.teacherNote != "" {
            cellCount += 1
        }
        if data.studentNote != "" {
            cellCount += 1
        }
        cellHeights = [CGFloat].init(repeating: 0, count: cellCount)
        views.removeAll()

        stackView.removeAllArrangedSubviews()
        if data.teacherNote != "" {
            let viewItem = viewItemForStackView(text: data.teacherNote, isMe: true, userId: data.teacherId, index: 0)
            views.append(viewItem)
            stackView.addArrangedSubview(viewItem.backView)
            viewItem.backView.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(self.cellHeights[0]).priority(.high)
            }
            if let studio = studio {
                viewItem.avatarView.loadImage(userId: data.teacherId, name: studio.name)
            }
        }
        if data.studentNote != "" {
            let viewItem = viewItemForStackView(text: data.studentNote, isMe: false, userId: data.studentId, index: data.teacherNote != "" ? 1 : 0)
            views.append(viewItem)
            stackView.addArrangedSubview(viewItem.backView)
            viewItem.backView.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(self.cellHeights[data.teacherNote != "" ? 1 : 0]).priority(.high)
            }
            if let student = data.studentData {
                viewItem.avatarView.loadImage(userId: data.studentId, name: student.name)
            } else {
                viewItem.avatarView.loadImage(userId: data.studentId, name: "")
            }
        }
        reloadIndexForViewItems()
        updateHeight()
        if data.teacherNote != "" {
            addButton.isHidden = true
        } else {
            addButton.isHidden = false
        }
    }

    private func addNote(content: String = "") {
        guard let userId = UserService.user.id() else { return }
        addButton.isHidden = true
        data.teacherNote = " "
        cellHeights.insert(62, at: 0)
        updateHeight()
        delegate?.lessonsDetailLessonNotesTableViewCell(heightChanged: cellHeight)
        let viewItem = viewItemForStackView(text: "", isMe: true, userId: userId, index: 0)
        views.insert(viewItem, at: 0)
        viewItem.backView.transform = CGAffineTransform(translationX: -TKScreen.width, y: 0)
        stackView.insertArrangedSubview(viewItem.backView, at: 0)
        logger.debug("获取到的Item的高度: \(cellHeights[0])")
        viewItem.backView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(self.cellHeights[0]).priority(.high)
        }
        viewItem.textView.text = content
        reloadIndexForViewItems()
        UIView.animate(withDuration: 0.2, delay: 0.5, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            viewItem.backView.transform = CGAffineTransform.identity
        }) { [weak self] _ in
            guard let self = self else { return }
            self.updateHeight()
            self.textViewDidEndEditing(viewItem.textView)
//            self.delegate?.lessonsDetailLessonNotesTableViewCell(textChanged: content, height: self.cellHeight, at: viewItem.textView.tag)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                viewItem.textView.isEditable = true
//                viewItem.textView.becomeFirstResponder()
//                self.showNotesEditController(viewItem.textView)
//            }
        }
    }

    private func removeNote(index: Int) {
        // MARK: - 删除的时候高度变化有问题

        guard views[index].textView.text == "" else {
            return
        }
        let view = views[index]
        views.remove(at: index)
        cellHeights.remove(at: index)
        data.teacherNote = ""
        stackView.removeArrangedSubview(view.backView)
        view.backView.removeFromSuperview()
        reloadIndexForViewItems()
        updateHeight()
        delegate?.lessonsDetailLessonNotesTableViewCell(removeAt: index, height: cellHeight)
    }

    private func reloadIndexForViewItems() {
        for viewItem in views.enumerated() {
            let index = viewItem.offset
            if views.isSafeIndex(index) {
                views[index].backView.tag = index
                views[index].contentView.tag = index
                views[index].textView.tag = index
                views[index].index = index
            }
        }
    }

    private func updateHeight() {
        for (i, viewItem) in views.enumerated() {
            viewItem.textView.layoutIfNeeded()
            cellHeights[i] = getTextViewHeight(viewItem.textView)
        }

        var height: CGFloat = 0
        for i in cellHeights {
            height += i
        }
        cellHeight = 80 + height
    }

    private func viewItemForStackView(text: String, isMe: Bool, userId: String, index: Int) -> Item {
        let view = TKView.create()
            .backgroundColor(color: UIColor.white)
        let avatarView = TKAvatarView()
        avatarView.loadImage(userId: userId, name: "")
        avatarView.cornerRadius = 16
        view.addSubview(view: avatarView) { make in
            make.size.equalTo(32)
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(16)
        }
        let contentView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .addTo(superView: view) { make in
                make.top.equalToSuperview()
                make.left.equalTo(avatarView.snp.right)
                make.right.equalToSuperview().offset(-20)
                make.bottom.equalToSuperview().offset(-10).priority(.medium)
            }
        let textView = UITextView()
        textView.tintColor = ColorUtil.main
        textView.tag = index
        textView.font = FontUtil.regular(size: 18)
        textView.textColor = isMe ? ColorUtil.Font.third : ColorUtil.Font.primary
//        textView.isEditable = isMe
        textView.text = text
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.sizeToFit()
        textView.delegate = self
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.isEditable = false
        contentView.addSubview(view: textView) { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10).priority(.medium)
        }
        if text == "" {
            cellHeights[index] = getTextViewHeight(textView)
        } else {
            if textView.text == "" {
                cellHeights[index] = getTextViewHeight(textView)
            } else {
                cellHeights[index] = getTextViewHeight(textView)
            }
        }
        textView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if isMe {
                self.showNotesEditController(textView)
            } else {
                self.showContentLarge(textView.text!)
            }
        }
        return Item(backView: view, contentView: contentView, avatarView: avatarView, textView: textView, index: index)
    }
}

extension LessonsDetailLessonNotesTableViewCell {
    private func getTextViewHeight(_ textView: UITextView) -> CGFloat {
        let height = textView.getRealHeight(minHeight: 42) + 30
        let h = textView.text.heightWithFont(font: FontUtil.regular(size: 18), fixedWidth: TKScreen.width - 90) + 30
        if height >= h {
            return height
        } else {
            return h
        }
    }
}

extension LessonsDetailLessonNotesTableViewCell: UITextViewDelegate {
//    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
//        IQKeyboardManager.shared.reloadLayoutIfNeeded()
//        let index = textView.tag
//        UIView.animate(withDuration: 0.2) { [weak self] in
//            guard let self = self else { return }
//            self.views[index].contentView.isShadowShow = false
//            _ = self.views[index].contentView.showShadow()
//            _ = self.views[index].contentView.showBorder(color: ColorUtil.borderColor)
//        }
//        textViewContentChanged(textView: textView)
//        return true
//    }
//
//    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
//        IQKeyboardManager.shared.reloadLayoutIfNeeded()
//        let index = textView.tag
//        UIView.animate(withDuration: 0.2) { [weak self] in
//            guard let self = self else { return }
//            self.views[index].contentView.isShadowShow = false
//            _ = self.views[index].contentView.hideBorder()
//        }
//        textViewContentChanged(textView: textView)
//        return true
//    }
//
    func textViewDidEndEditing(_ textView: UITextView) {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        delegate?.lessonsDetailLessonNotesTableViewCell(done: text)
        if text == "" {
            addButton.isHidden = false
            removeNote(index: textView.tag)
        } else {
            if !addButton.isHidden {
                addButton.isHidden = true
            }
        }
        textView.text = text
        textViewContentChanged(textView: textView)
    }

//
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        let _text = (textView.text! as NSString).replacingCharacters(in: range, with: text)
//        data.teacherNote = _text
//        textViewContentChanged(textView: textView)
//        return true
//    }

    func textViewDidChange(_ textView: UITextView) {
        textViewContentChanged(textView: textView)
    }

    private func textViewContentChanged(textView: UITextView) {
        let index = textView.tag
        if textView.text != "" {
            SL.Executor.runAsync { [weak self] in
                guard let self = self else { return }
                self.cellHeights[textView.tag] = self.getTextViewHeight(textView)
                self.views[textView.tag].backView.snp.updateConstraints { make in
                    make.height.equalTo(self.cellHeights[textView.tag]).priority(.high)
                }
                self.updateHeight()
                self.delegate?.lessonsDetailLessonNotesTableViewCell(textChanged: textView.text, height: self.cellHeight, at: textView.tag)
            }
        } else {
            SL.Executor.runAsync { [weak self] in
                guard let self = self else { return }
                if self.cellHeights.count > index {
                    self.cellHeights[index] = self.getTextViewHeight(textView)
                }
                print("=ddd=====\(self.cellHeights)===\(self.cellHeight)")
                self.updateHeight()
            }
            delegate?.lessonsDetailLessonNotesTableViewCell(textChanged: textView.text, height: cellHeight, at: textView.tag)
        }
    }
}

extension LessonsDetailLessonNotesTableViewCell {
    private func showContentLarge(_ text: String) {
        LargeContentPreviewViewController.show(text)
    }

    private func showNotesEditController(_ textView: UITextView) {
        let controller = LessonDetailAddNewContentViewController()
        controller.font = FontUtil.bold(size: 20)
        controller.text = textView.text
        controller.titleString = "Notes"
        controller.titleAlignment = .left
        controller.rightButtonString = "SAVE"
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] text in
            guard let self = self else { return }
            controller.hide()
            textView.text = text
            self.textViewDidEndEditing(textView)
        }
        controller.modalPresentationStyle = .custom
        Tools.getTopViewController()?.present(controller, animated: false)
    }

    private func showNotesAddController(_ completion: ((String) -> Void)? = nil) {
        let controller = LessonDetailAddNewContentViewController()
        controller.text = ""
        controller.titleString = "Notes"
        controller.titleAlignment = .left
        controller.rightButtonString = "SAVE"
        controller.onLeftButtonTapped = { [weak self] _ in
            guard let self = self else { return }
            controller.hide()
            self.addButton?.isHidden = false
        }
        controller.onRightButtonTapped = { text in
            controller.hide()
            completion?(text)
        }
        controller.modalPresentationStyle = .custom
        Tools.getTopViewController()?.present(controller, animated: false)
    }
}

protocol LessonsDetailLessonNotesTableViewCellDelegate: NSObjectProtocol {
    func lessonsDetailLessonNotesTableViewCellAddLessonTapeed(addButton: TKButton, completion: @escaping () -> Void)
    func lessonsDetailLessonNotesTableViewCell(heightChanged height: CGFloat)
    func lessonsDetailLessonNotesTableViewCell(textChanged text: String, height: CGFloat, at index: Int)
    func lessonsDetailLessonNotesTableViewCell(done text: String)
    func lessonsDetailLessonNotesTableViewCell(removeAt index: Int, height: CGFloat)
}
