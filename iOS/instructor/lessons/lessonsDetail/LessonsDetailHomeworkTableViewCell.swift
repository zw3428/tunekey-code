//
//  LessonsDetailHomeworkTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/3.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class LessonsDetailHomeworkTableViewCell: UITableViewCell {
    struct Item {
        var backView: TKView
        var prefixImageView: TKImageView
        var contentView: TKView
        var textView: UITextView
        var removeButton: TKButton
        var loadingView: TKLoading
        var index: Int
    }

    var cellHeight: CGFloat = 80

    var data: [TKPractice] = []

    weak var delegate: LessonsDetailHomeworkTableViewCellDelegate?

    private var backView: TKView!
    private var iconImageView: TKImageView!
    private var titleLabel: TKLabel!
    var addButton: TKButton!
    var copyFromLastLessonButton: TKButton = TKButton.create().title(title: "Copy from last lesson").titleFont(font: FontUtil.bold(size: 13)).titleColor(color: ColorUtil.main)
//    private var lineView: TKView!
    private var stackView: UIStackView!
    var cellHeights: [CGFloat] = []
    private var views: [Item] = []
    // lesson_schedule id
    var sId: String = ""
    // schedule config id

    private var timer: Timer?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonsDetailHomeworkTableViewCell {
    private func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        contentView.addSubview(backView)
        backView.snp.makeConstraints { make in
            make.top.equalTo(self.contentView)
            make.left.equalTo(self.contentView)
            make.right.equalTo(self.contentView)
            make.height.equalTo(80)
            make.width.equalTo(UIScreen.main.bounds.width)
        }

        iconImageView = TKImageView.create()
            .setImage(name: "icHomework")
        backView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(backView).offset(30)
            make.left.equalTo(backView).offset(20)
            make.height.equalTo(22)
            make.width.equalTo(22)
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Homework")
            .alignment(alignment: .left)
        backView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(60)
            make.centerY.equalTo(iconImageView.snp.centerY)
            make.height.equalTo(21)
        }

        addButton = TKButton.create()
            .setImage(name: "icAddPrimary", size: CGSize(width: 22, height: 22))
        addButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.lessonsDetailHomeworkTableViewCellAddHomeworkTapped(withView: self.addButton) {
//                self.addTapped()
            }
        }
        backView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.top.equalTo(backView).offset(21)
            make.right.equalTo(backView).offset(-11)
            make.size.equalTo(40)
        }
        copyFromLastLessonButton.isHidden = true
        copyFromLastLessonButton.addTo(superView: backView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(titleLabel.snp.left)
            make.height.equalTo(15)
        }
        stackView = UIStackView()
        backView.addSubview(view: stackView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
        }
        stackView.axis = .vertical
        stackView.spacing = 0

        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: backView) { make in
                make.left.equalToSuperview().offset(20)
                make.right.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
    }

    private func updateHeight() {
        var height: CGFloat = 0
        for i in cellHeights {
            height += i
        }
        if height > 0 {
            cellHeight = height + 80 + 20
        } else {
            cellHeight = 80 + (copyFromLastLessonButton.isHidden ? 0 : 15)
        }
        if backView != nil {
            backView.snp.updateConstraints { make in
                make.height.equalTo(cellHeight)
            }
        }
    }

    private func addTapped(isFocus: Bool = true) {
//        if let assignment = data.last {
//            if assignment.name.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
//                if isFocus {
//                    SL.Executor.runAsyncAfter(time: 0.5, action: {
//                        self.views.last?.textView.isEditable = true
//                        self.views.last?.textView.isUserInteractionEnabled = true
//                        self.views.last?.textView.becomeFirstResponder()
//                    })
//                }
//                return
//            }
//        }
//        let assignment = initHomeworkData()
//        data.append(assignment)
//        cellHeights.append(0)
//        let view = viewForStackView(assignment: assignment, index: cellHeights.count - 1)
//        views.append(view)
//        view.contentView.transform = CGAffineTransform(translationX: -TKScreen.width, y: 0)
//        stackView.addArrangedSubview(view.backView)
//        reloadIndexForViews()
//        copyFromLastLessonButton.isHidden = true
//        UIView.animate(withDuration: 0.2, animations: {
//            view.contentView.transform = CGAffineTransform.identity
//        }) { [weak self] _ in
//            guard let self = self else { return }
//            self.delegate?.lessonsDetailHomeworkTableViewCellAddHomeworkTapped(assignment: assignment)
//            self.updateHeight()
//            self.delegate?.lessonsDetailHomeworkTableViewCell(heightChanged: self.cellHeight)
//            if isFocus {
//                SL.Executor.runAsyncAfter(time: 0.5, action: {
//                    view.textView.becomeFirstResponder()
//                })
//            }
//        }
    }

    private func viewForStackView(assignment: TKPractice, index: Int) -> Item {
        let view = TKView.create()
            .backgroundColor(color: UIColor.white)
        view.tag = index

        let contentView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: view) { make in
                make.top.left.right.bottom.equalToSuperview()
            }

        let textView = UITextView()
        textView.tintColor = ColorUtil.main
        textView.delegate = self
        textView.font = FontUtil.regular(size: 18)
        textView.textColor = ColorUtil.Font.primary
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.tag = index
        textView.isEditable = false
        textView.text = assignment.name
        contentView.addSubview(view: textView) { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.left.equalToSuperview().offset(60)
            make.right.equalToSuperview().offset(-60)
        }
        textView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.lessonsDetailHomeworkTableViewCell(editAt: index)
        }

        let prefixImageView = TKImageView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.size.equalTo(22)
                make.top.equalToSuperview().offset(6)
                make.left.equalToSuperview().offset(20)
            })
        prefixImageView.backgroundColor = UIColor(red: 230, green: 233, blue: 235)
        prefixImageView.cornerRadius = 11
        prefixImageView.tag = index
        let removeButton = TKButton.create()
            .setImage(name: "icDeleteRed", size: CGSize(width: 22, height: 22))
            .addTo(superView: contentView, withConstraints: { make in
                make.centerY.equalTo(prefixImageView.snp.centerY)
                make.right.equalToSuperview().offset(-10)
                make.size.equalTo(40)
            })
        removeButton.tag = index
        removeButton.isHidden = true

        let loadingView = TKLoading()
        contentView.addSubview(view: loadingView) { make in
            make.centerY.equalTo(prefixImageView.snp.centerY)
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(40)
        }

        removeButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            logger.debug("remove lesson plan at: \(index)")
            self.removeDataFromIndex(index: index)
        }
        onCheckIconTapped(iconImageView: prefixImageView, textView: textView, index: index, isDone: assignment.done, isManualLog: assignment.manualLog)

        view.frame = CGRect(x: 0, y: 0, width: TKScreen.width, height: cellHeights[index])
        return Item(backView: view, prefixImageView: prefixImageView, contentView: contentView, textView: textView, removeButton: removeButton, loadingView: loadingView, index: index)
    }

    private func onCheckIconTapped(iconImageView: TKImageView, textView: UITextView, index: Int, isDone: Bool, isManualLog: Bool) {
        data[index].done = isDone
        if isDone {
            textView.textColor = ColorUtil.Font.primary
        } else {
            textView.textColor = ColorUtil.Font.third
        }

        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: data[index].name)
        if isDone {
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, attributeString.length))
        }

        attributeString.addAttributes([
            NSAttributedString.Key.font: FontUtil.regular(size: 18),
            NSAttributedString.Key.foregroundColor: isDone ? ColorUtil.Font.primary : ColorUtil.Font.third,
            NSAttributedString.Key.strikethroughColor: isDone ? ColorUtil.Font.primary : ColorUtil.Font.third,
        ], range: NSMakeRange(0, attributeString.length))
        textView.attributedText = attributeString

        // 没选择 radiobuttonOn
        // 选择了 checkboxOn
        if isDone {
            iconImageView.setImage(name: "checkboxOn")
        } else {
            iconImageView.setImage(name: "checkboxOffRed")
        }
        iconImageView.cornerRadius = 11
        if isManualLog {
            iconImageView.setImage(name: "manualLog")
        }
        var heightForItem: CGFloat = 0
        if data[index].name == "" {
            heightForItem = 30
        } else {
            heightForItem = getTextViewTextHeight(text: data[index].name, fixedWidth: TKScreen.width - 120, attributes: attributeString.attributes(at: 0, effectiveRange: nil)) + 12
        }
        cellHeights[index] = heightForItem
    }

    func getTextViewTextHeight(text: String, fixedWidth: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let size = CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude)
        let _text = text as NSString
        let rect = _text.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        return rect.height + 2
    }

    private func reloadIndexForViews() {
        for viewItem in views.enumerated() {
            let index = viewItem.offset
            views[index].index = index
            views[index].backView.tag = index
            views[index].prefixImageView.tag = index
            views[index].contentView.tag = index
            views[index].loadingView.tag = index
            views[index].removeButton.tag = index
            views[index].textView.tag = index
        }
    }

    func initHomeworkData() -> TKPractice {
        let assignment = TKPractice()
        let time = Date().timestamp
        assignment.updateTime = "\(time)"
        assignment.createTime = "\(time)"
        assignment.lessonScheduleId = sId
        if let id = IDUtil.nextId() {
            assignment.id = "\(id)"
        } else {
            assignment.id = "\(time)"
        }
        return assignment
    }

    private func removeDataFromIndex(index: Int) {
        logger.debug("当前要删除的index: \(index), 数据总量: \(data.count)")
        let viewItem = views[index]
        var needReFocus: Bool = false
        if index == data.count - 1 {
            needReFocus = false
        } else {
            needReFocus = true
        }
        UIView.animate(withDuration: 0.2, animations: {
            viewItem.contentView.transform = CGAffineTransform(translationX: -TKScreen.width, y: 0)
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            logger.debug("complete")
            self.stackView.removeArrangedSubview(viewItem.backView)
            viewItem.backView.removeFromSuperview()
            self.views.remove(at: index)
            self.initTag()
            self.cellHeights.remove(at: index)
            self.data.remove(at: index)
            self.updateHeight()
            for item in self.views.enumerated() {
                self.views[item.offset].textView.tag = item.offset
                self.views[item.offset].index = item.offset
                self.views[item.offset].removeButton.onTapped { _ in
                    logger.debug("新的点击事件remove lesson plan at: \(item.offset)")
                    self.removeDataFromIndex(index: item.offset)
                }
            }
            if needReFocus {
                if let currentFirstViewItem = self.views.first {
                    logger.debug("当前view可否聚焦: \(currentFirstViewItem.textView.canBecomeFirstResponder) | \(currentFirstViewItem.textView.canBecomeFocused)")
                    currentFirstViewItem.textView.becomeFirstResponder()
                } else {
                    self.contentView.endEditing(true)
                }
            }
            self.delegate?.lessonsDetailHomeworkTableViewCell(deleted: index, height: self.cellHeight)
        })
    }

    func initTag() {
        for item in views.enumerated() {
            views[item.offset].textView.tag = item.offset
        }
    }

    func loadData(data: [TKPractice], sId: String, showCopyButton: Bool = false, isForce: Bool = true) {
        self.sId = sId
        self.data = data
        if isForce {
            if data.isEmpty {
                copyFromLastLessonButton.isHidden = !showCopyButton
                cellHeights = []
                views.removeAll()
                stackView.removeAllArrangedSubviews()
            } else {
                copyFromLastLessonButton.isHidden = true
                cellHeights = [CGFloat].init(repeating: 0, count: data.count)
                views.removeAll()
                stackView.removeAllArrangedSubviews()
                for text in self.data.enumerated() {
                    let viewItem = viewForStackView(assignment: text.element, index: text.offset)
                    views.append(viewItem)
                    stackView.addArrangedSubview(viewItem.backView)
                    viewItem.backView.snp.makeConstraints { make in
                        make.width.equalToSuperview()
                        make.height.equalTo(self.cellHeights[text.offset]).priority(.high)
                    }
                }
            }
            if showCopyButton {
                if stackView.arrangedSubviews.isEmpty {
                    copyFromLastLessonButton.isHidden = false
                } else {
                    copyFromLastLessonButton.isHidden = true
                }
            }
        } else {
            logger.debug("仅检查是否显示copy button")
            if showCopyButton {
                if stackView.arrangedSubviews.isEmpty {
                    copyFromLastLessonButton.isHidden = false
                } else {
                    copyFromLastLessonButton.isHidden = true
                }
            } else {
                copyFromLastLessonButton.isHidden = true
            }
        }
        updateHeight()
    }
}

extension LessonsDetailHomeworkTableViewCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        views[textView.tag].removeButton.isHidden = false
        checkIfWillAddNewAssignment(textView: textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let index = textView.tag
        views[index].removeButton.isHidden = true
        delegate?.lessonsDetailHomeworkTableViewCell(done: data[textView.tag])
        clearEmptyData()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let _text = (textView.text! as NSString).replacingCharacters(in: range, with: text)
        data[textView.tag].name = _text
        textViewContentChanged(textView: textView, _text)
        return true
    }

    private func textViewContentChanged(textView: UITextView, _ text: String) {
        if textView.text != "" {
            SL.Executor.runAsync { [weak self] in
                guard let self = self else { return }
                self.checkIfWillAddNewAssignment(textView: textView)
                self.cellHeights[textView.tag] = textView.heightForText(fixedWidth: TKScreen.width - 120) + 12
                self.views[textView.tag].backView.snp.updateConstraints { make in
                    make.height.equalTo(self.cellHeights[textView.tag]).priority(.high)
                }
                self.updateHeight()
                self.delegate?.lessonsDetailHomeworkTableViewCell(textChanged: text, height: self.cellHeight, at: textView.tag)
            }
        } else {
            clearEmptyData(now: true)
        }
    }

    private func checkIfWillAddNewAssignment(textView: UITextView) {
        if textView.text != "" {
            if data.last?.name != "" {
                addTapped(isFocus: false)
            }
        }
        timer?.invalidate()
    }

    private func clearEmptyData(now: Bool = false) {
        logger.debug("清空所有的数据")
        var indexs: [Int] = []
        for item in data.enumerated() {
            if item.element.name.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                indexs.append(item.offset)
            }
        }
        indexs = indexs.sorted(by: >)
        let action = {
            for index in indexs {
                guard self.views.count > index else { continue }
                let view = self.views[index]
                guard view.textView.text == "" else { continue }
                if !view.textView.isFirstResponder {
                    self.removeDataFromIndex(index: index)
                }
            }
        }

        if now {
            action()
        } else {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
                action()
            })
        }
    }
}

protocol LessonsDetailHomeworkTableViewCellDelegate: NSObjectProtocol {
    func lessonsDetailHomeworkTableViewCellAddHomeworkTapped(withView button: TKButton, completion: @escaping () -> Void)
    func lessonsDetailHomeworkTableViewCell(editAt index: Int)
    func lessonsDetailHomeworkTableViewCell(heightChanged height: CGFloat)

    func lessonsDetailHomeworkTableViewCellAddHomeworkTapped(assignment: TKPractice)
    func lessonsDetailHomeworkTableViewCell(deleted index: Int, height: CGFloat)
    func lessonsDetailHomeworkTableViewCell(textChanged text: String, height: CGFloat, at index: Int)
    func lessonsDetailHomeworkTableViewCell(done assignment: TKPractice)
}
