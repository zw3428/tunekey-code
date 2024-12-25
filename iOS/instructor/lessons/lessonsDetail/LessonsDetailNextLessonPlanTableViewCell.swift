//
//  LessonsDetailNextLessonPlanTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/3.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class LessonsDetailNextLessonPlanTableViewCell: UITableViewCell {
    struct Item {
        var backView: TKView
        var contentView: TKView
        var textView: UITextView
        var prefixImageView: TKImageView
        var loadingView: TKLoading
        var index: Int
    }

    weak var delegate: LessonsDetailNextLessonPlanTableViewCellDelegate?

    var cellHeight: CGFloat = 0 // 80

    var data: [TKLessonPlan] = []
    // lesson_schedule id
    var sId: String = ""

    private var backView: TKView!
    private var iconImageView: TKImageView!
    private var titleLabel: TKLabel!
    var addButton: TKButton!
    private var stackView: UIStackView!

    var cellHeights: [CGFloat] = []
    private var views: [Item] = []

    // 0是 lesson plan 1是 next Lesson plan
    private var style: Int = 0

    /// 是否是下一节课的计划,如果是,则前面的小点变小,并且不可点击
    var isNext: Bool = false

    var timer: Timer?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonsDetailNextLessonPlanTableViewCell {
    private func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        contentView.addSubview(backView)
        backView.layer.masksToBounds = true
        backView.snp.makeConstraints { make in
            make.top.equalTo(self.contentView)
            make.left.equalTo(self.contentView)
            make.right.equalTo(self.contentView)
            make.height.equalTo(0)
            make.width.equalTo(UIScreen.main.bounds.width)
        }

        iconImageView = TKImageView.create()
            .setImage(name: "icNextLessonPlan")
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
            .text(text: "Next lesson plan")
            .alignment(alignment: .left)
        backView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
//            make.left.equalTo(iconImageView.snp.right).offset(20)
            make.left.equalToSuperview().offset(60)
            make.centerY.equalTo(iconImageView.snp.centerY)
            make.height.equalTo(21)
        }

        addButton = TKButton.create()
            .setImage(name: "icAddPrimary", size: CGSize(width: 22, height: 22))
        addButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            logger.debug("add next lesson plan button tapped")
            self.delegate?.lessonsDetailNextLessonPlanTableViewCellAddTapped(withView: self.addButton, completion: {
//                self.addTapped()
            })
        }
        backView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.top.equalTo(backView).offset(21)
            make.right.equalTo(backView).offset(-11)
            make.size.equalTo(40)
        }

        stackView = UIStackView()
        backView.addSubview(view: stackView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
//            make.bottom.equalToSuperview().offset(-20)
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
        cellHeight = height + 80 + (height > 0 ? 20 : 0)
        if backView != nil {
            backView.snp.updateConstraints { make in
                make.height.equalTo(cellHeight)
            }
        }
    }

    private func addTapped(isFocus: Bool = true) {
        if let lastPlan = data.last {
            if lastPlan.plan.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                if isFocus {
                    SL.Executor.runAsyncAfter(time: 0.5, action: {
                        self.views.last?.textView.isEditable = false
                        self.views.last?.textView.isUserInteractionEnabled = true
                        self.views.last?.textView.becomeFirstResponder()
                    })
                }
                return
            }
        }
        let plan = initLessonPlanData()
        data.append(plan)
        cellHeights.append(0)
        let view = viewForStackView(plan: plan, index: cellHeights.count - 1)
        views.append(view)
        view.contentView.transform = CGAffineTransform(translationX: -TKScreen.width, y: 0)
//        stackView.insertArrangedSubview(view.backView, at: 0)
        stackView.addArrangedSubview(view.backView)
        reloadIndexForViews()
        UIView.animate(withDuration: 0.2, animations: {
            view.contentView.transform = CGAffineTransform.identity
        }) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.lessonsDetailNextLessonPlanTableViewCellAddTapped(plan: plan, cell: self)
            self.updateHeight()
            self.delegate?.lessonsDetailNextLessonPlanTableViewCell(heightChanged: self.cellHeight, cell: self)
            if isFocus {
                SL.Executor.runAsyncAfter(time: 0.5, action: {
                    view.textView.isEditable = false
                    view.textView.isUserInteractionEnabled = true
                    view.textView.becomeFirstResponder()
                })
            }
        }
    }

    private func reloadIndexForViews() {
        for viewItem in views.enumerated() {
            let index = viewItem.offset
            views[index].index = index
            views[index].backView.tag = index
            views[index].contentView.tag = index
            views[index].loadingView.tag = index
//            views[index].removeButton.tag = index
            views[index].textView.tag = index
            views[index].prefixImageView.tag = index
        }
    }

    // -1为还未上课 ,0 为正常 , 1为next lesson plan
    func loadData(data: [TKLessonPlan], style: Int = 1, sId: String) {
        self.style = style
        self.sId = sId
        cellHeight = 80
        backView.snp.updateConstraints { make in
            make.height.equalTo(80)
        }
        addButton.isHidden = style == 0
        if style == 0 || style == -1 {
            titleLabel.text = "Lesson plan"
        } else {
            titleLabel.text = "Next lesson plan"
        }
        self.data = data
        cellHeights = [CGFloat].init(repeating: 0, count: data.count)
        views.removeAll()
        stackView.removeAllArrangedSubviews()
        for text in self.data.enumerated() {
            let viewItem = viewForStackView(plan: text.element, index: text.offset)
            views.append(viewItem)
            stackView.addArrangedSubview(viewItem.backView)
            viewItem.backView.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(self.cellHeights[text.offset]).priority(.high)
            }
        }
        updateHeight()
    }

    func loadNoDataView() {
        cellHeight = 0
        backView.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        cellHeights.removeAll()

        views.removeAll()

        stackView.removeAllArrangedSubviews()
    }

    private func viewForStackView(plan: TKLessonPlan, index: Int) -> Item {
        let view = TKView.create()
            .backgroundColor(color: UIColor.white)

        view.tag = index

        let contentView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: view) { make in
                make.top.left.right.bottom.equalToSuperview()
            }

        let textView = UITextView()
        textView.font = FontUtil.regular(size: 18)
        textView.textColor = ColorUtil.Font.third
        textView.tintColor = ColorUtil.main
        textView.translatesAutoresizingMaskIntoConstraints = true
        textView.sizeToFit()
        textView.delegate = self
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.tag = index
        textView.text = plan.plan
        textView.onViewTapped { [weak self] _ in
            self?.delegate?.lessonsDetailNextLessonPlanTableViewCell(editAt: index)
        }
        contentView.addSubview(view: textView) { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.left.equalToSuperview().offset(60)
            make.right.equalToSuperview().offset(-60)
        }

        let prefixImageView = TKImageView.create()
            .addTo(superView: contentView) { make in
                if style == 0 {
                    make.size.equalTo(22)
                    make.top.equalToSuperview().offset(6)
                    make.left.equalToSuperview().offset(20)
                } else {
                    make.size.equalTo(10)
                    make.top.equalToSuperview().offset(14)
                    make.left.equalToSuperview().offset(26)
                }
            }
        if style == 0 {
            prefixImageView.backgroundColor = .white
            prefixImageView.layer.borderWidth = 1
            prefixImageView.layer.borderColor = UIColor(red: 230, green: 233, blue: 235).cgColor
            prefixImageView.layer.cornerRadius = 6
        }
        onCheckIconTapped(iconImageView: prefixImageView, textView: textView, index: index, isDone: plan.done)
        view.frame = CGRect(x: 0, y: 0, width: TKScreen.width, height: cellHeights[index])
        if style == 0 {
            prefixImageView.onViewTapped { [weak self] _ in
                guard let self = self else { return }
                self.data[index].done.toggle()
                self.delegate?.lessonsDetailNextLessonPlanTableViewCell(check: index, plan: self.data[index], cell: self)
                self.onCheckIconTapped(iconImageView: prefixImageView, textView: textView, index: index, isDone: self.data[index].done)
            }
        }

//        let removeButton = TKButton.create()
//            .setImage(name: "icDeleteRed", size: CGSize(width: 22, height: 22))
//            .addTo(superView: contentView, withConstraints: { make in
//                make.centerY.equalTo(prefixImageView.snp.centerY)
//                make.right.equalToSuperview().offset(-10)
//                make.size.equalTo(40)
//            })
//        removeButton.tag = index
//        removeButton.isHidden = true

        let loadingView = TKLoading()
        contentView.addSubview(view: loadingView) { make in
            make.centerY.equalTo(prefixImageView.snp.centerY)
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(40)
        }
//        view.onViewTapped { [weak self] _ in
//            guard let self = self else { return }
//            if self.style != 0 {
//                textView.becomeFirstResponder()
//            }
//        }
//        removeButton.onTapped { [weak self] _ in
//            guard let self = self else { return }
//            logger.debug("remove lesson plan at: \(index)")
//            self.removeDataFromIndex(index: index)
//        }

        return Item(backView: view, contentView: contentView, textView: textView, prefixImageView: prefixImageView, loadingView: loadingView, index: index)
    }

    private func removeDataFromIndex(index: Int) {
        let viewItem = views[index]
        if viewItem.textView.isFirstResponder {
            viewItem.textView.resignFirstResponder()
        }
        UIView.animate(withDuration: 0.2, animations: {
            viewItem.contentView.transform = CGAffineTransform(translationX: -TKScreen.width, y: 0)
        }, completion: { [weak self] _ in
            logger.debug("complete")
            guard let self = self else { return }
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
//                self.views[item.offset].removeButton.onTapped { _ in
//                    logger.debug("新的点击事件remove lesson plan at: \(item.offset)")
//                    self.removeDataFromIndex(index: item.offset)
//                }
            }
            self.clearEmptyData()
            self.delegate?.lessonsDetailNextLessonPlanTableViewCell(deleted: index, height: self.cellHeight, cell: self)
        })
    }

    func initTag() {
        for item in views.enumerated() {
            views[item.offset].textView.tag = item.offset
        }
    }

    private func onCheckIconTapped(iconImageView: TKImageView, textView: UITextView, index: Int, isDone: Bool) {
        data[index].done = isDone
        if isDone {
            textView.textColor = ColorUtil.Font.primary
        } else {
            textView.textColor = ColorUtil.Font.third
        }

        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: data[index].plan)
        if isDone {
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, attributeString.length))
        }

        attributeString.addAttributes([
            NSAttributedString.Key.font: FontUtil.regular(size: 18),
            NSAttributedString.Key.foregroundColor: isDone ? ColorUtil.Font.primary : ColorUtil.Font.third,
            NSAttributedString.Key.strikethroughColor: isDone ? ColorUtil.Font.primary : ColorUtil.Font.third,
        ], range: NSMakeRange(0, attributeString.length))
        textView.attributedText = attributeString

        var heightForItem: CGFloat = 0
        if data[index].plan == "" {
            heightForItem = 30
        } else {
            heightForItem = getTextViewTextHeight(text: data[index].plan, fixedWidth: UIScreen.main.bounds.width - 120, attributes: attributeString.attributes(at: 0, effectiveRange: nil)) + 12
        }
        cellHeights[index] = heightForItem
        if style == 0 {
            textView.isEditable = false
            if isDone {
                iconImageView.setImage(name: "checkWhite")
                iconImageView.backgroundColor = ColorUtil.main
                iconImageView.layer.borderWidth = 0
            } else {
                iconImageView.image = nil
                iconImageView.layer.borderWidth = 2
                iconImageView.backgroundColor = .white
            }
        } else {
            textView.isEditable = false
            iconImageView.setImage(name: "grayPoint")
            iconImageView.backgroundColor = UIColor.clear
            iconImageView.layer.borderWidth = 0
        }
    }

    func getTextViewTextHeight(text: String, fixedWidth: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let size = CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude)
        let _text = text as NSString
        let rect = _text.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        return rect.height + 2
    }
}

extension LessonsDetailNextLessonPlanTableViewCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.lessonsDetailNextLessonPlanTableViewCellOnTextViewFocus()
//        views[textView.tag].removeButton.isHidden = false
        // 判断当前的文本框是否是空的,如果不是空的,判断最后一个是不是空的,如果不是,则添加一个新的
        checkIfWillAddNewPlan(textView: textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let index = textView.tag
//        views[index].removeButton.isHidden = true
        delegate?.lessonsDetailNextLessonPlanTableViewCell(done: data[textView.tag], cell: self)
        clearEmptyData()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let _text = (textView.text! as NSString).replacingCharacters(in: range, with: text)
        data[textView.tag].plan = _text
        textViewContentChanged(textView: textView)
        checkIfWillAddNewPlan(textView: textView)
        return true
    }

    private func textViewContentChanged(textView: UITextView) {
        if textView.text != "" {
            SL.Executor.runAsync { [weak self] in
                guard let self = self else { return }
                self.cellHeights[textView.tag] = textView.heightForText(fixedWidth: TKScreen.width - 120) + 12
                self.views[textView.tag].backView.snp.updateConstraints { make in
                    make.height.equalTo(self.cellHeights[textView.tag]).priority(.high)
                }
                self.updateHeight()
                self.delegate?.lessonsDetailNextLessonPlanTableViewCell(textChanged: textView.text, height: self.cellHeight, at: textView.tag, cell: self)
            }
        }
    }

    func initLessonPlanData() -> TKLessonPlan {
        var plan = TKLessonPlan()
        let time = Date().timestamp
        plan.updateTime = "\(time)"
        plan.createTime = "\(time)"
        plan.lessonScheduleId = sId
        if let id = IDUtil.nextId() {
            plan.id = "\(id)"
        } else {
            plan.id = "\(time)"
        }
        return plan
    }

    private func checkIfWillAddNewPlan(textView: UITextView) {
//        if textView.text != "" {
//            if data.last?.plan != "" {
//                addTapped(isFocus: false)
//            }
//        }
//        timer?.invalidate()
    }

    private func clearEmptyData(now: Bool = false) {
        logger.debug("清空所有的数据")
        var indexs: [Int] = []
        for item in data.enumerated() {
            if item.element.plan.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                indexs.append(item.offset)
            }
        }
        indexs = indexs.sorted(by: >)

        let action = {
            for index in indexs {
                guard self.views.count > index else { return }
                let view = self.views[index]
                guard view.textView.text == "" else { return }
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

protocol LessonsDetailNextLessonPlanTableViewCellDelegate: NSObjectProtocol {
    func lessonsDetailNextLessonPlanTableViewCellAddTapped(withView addButton: TKButton, completion: @escaping () -> Void)
    func lessonsDetailNextLessonPlanTableViewCellAddTapped(plan: TKLessonPlan, cell: LessonsDetailNextLessonPlanTableViewCell)
    func lessonsDetailNextLessonPlanTableViewCell(heightChanged height: CGFloat, cell: LessonsDetailNextLessonPlanTableViewCell)
    func lessonsDetailNextLessonPlanTableViewCell(deleted index: Int, height: CGFloat, cell: LessonsDetailNextLessonPlanTableViewCell)

    func lessonsDetailNextLessonPlanTableViewCell(textChanged text: String, height: CGFloat, at index: Int, cell: LessonsDetailNextLessonPlanTableViewCell)
    func lessonsDetailNextLessonPlanTableViewCell(done plan: TKLessonPlan, cell: LessonsDetailNextLessonPlanTableViewCell)
    func lessonsDetailNextLessonPlanTableViewCell(check index: Int, plan: TKLessonPlan, cell: LessonsDetailNextLessonPlanTableViewCell)
    func lessonsDetailNextLessonPlanTableViewCellOnTextViewFocus()
    func lessonsDetailNextLessonPlanTableViewCell(editAt index: Int)
}
