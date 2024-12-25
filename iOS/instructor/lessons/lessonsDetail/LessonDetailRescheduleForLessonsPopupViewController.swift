//
//  LessonDetailRescheduleForLessonsPopupViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/4/6.
//  Copyright © 2022 spelist. All rights reserved.
//

import FirebaseFunctions
import SnapKit
import UIKit

class LessonDetailRescheduleForLessonsPopupViewController: TKBaseViewController {
    private var contentView: TKView = TKView.create().backgroundColor(color: .white).corner(size: 10).maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
    private var contentViewHeight: CGFloat = 410

    @Live var titleString: String = ""
    @Live var config: TKLessonScheduleConfigure {
        didSet {
            updateHeight()
        }
    }

    var oldConfig: TKLessonScheduleConfigure
    var selectedLessonScheduleId: String

    var rescheduleType: TKRescheduleType = .allLessons {
        didSet {
            if rescheduleType == .thisAndFollowingLessons {
                titleString = "For this and following lessons:"
            } else {
                titleString = "For all lessons:"
            }
        }
    }

    init(_ config: TKLessonScheduleConfigure, oldConfig: TKLessonScheduleConfigure, selectedLessonScheduleId: String) {
        self.config = config
        self.oldConfig = oldConfig
        self.selectedLessonScheduleId = selectedLessonScheduleId
        super.init(nibName: nil, bundle: nil)
        logger.debug("要修改的新config: \(config.toJSONString() ?? "") \n 旧config: \(oldConfig.toJSONString() ?? "")")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isShow: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let config = self.config
        if config.startDateTime < Date().timeIntervalSince1970 {
            config.startDateTime = TimeInterval(Date().timestamp)
            self.config = config
        }
        updateHeight()
        show()
    }

    private func updateHeight() {
        var defaultHeight: CGFloat = 410
        if config.repeatType != .none {
            // 40 是其中的一个的高度
            defaultHeight += (205 - 40)
        }
        if config.endType != .none {
            defaultHeight += 121
        }
        contentViewHeight = defaultHeight
        logger.debug("更新高度: \(contentViewHeight)")
        animate(timeInterval: 0.2) { [weak self] in
            guard let self = self else { return }
            self.contentView.snp.updateConstraints { make in
                make.height.equalTo(self.contentViewHeight)
            }
            self.view.layoutIfNeeded()
        }
    }
}

extension LessonDetailRescheduleForLessonsPopupViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.addTo(superView: view) { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(contentViewHeight)
        }
        // 20
        ViewBox(paddings: UIEdgeInsets(top: 20, left: 0, bottom: UiUtil.safeAreaBottom(), right: 0)) {
            VStack {
                // 20
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)) {
                    Label($titleString)
                        .textColor(ColorUtil.Font.primary)
                        .font(FontUtil.regular(size: 13))
                        .size(height: 20)
                }
                // 82
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)) {
                    ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                        HStack {
                            Label()
                                .textColor(ColorUtil.Font.third)
                                .font(FontUtil.bold(size: 18))
                                .size(height: 22)
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$config.addSubscriber { config in
                                        _ = label.text(Date(seconds: config.startDateTime).toLocalFormat("yyyy/MM/dd \(Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm")"))
                                    }
                                }
                            Label("Change to")
                                .textColor(ColorUtil.Font.primary)
                                .font(FontUtil.regular(size: 13))
                                .size(height: 22)
                            ImageView()
                                .image(UIImage(named: "arrowRight"))
                                .size(width: 22, height: 22)
                        }
                    }
                    .backgroundColor(.white)
                    .borderColor(ColorUtil.borderColor)
                    .borderWidth(1)
                    .cornerRadius(5)
                    .showShadow()
                    .onViewTapped { [weak self] _ in
                        self?.onStartOnTapped()
                    }
                }
                // 82
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)) {
                    ViewBox(paddings: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)) {
                        VStack {
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                                HStack {
                                    Label("Recurrence")
                                        .textColor(ColorUtil.Font.third)
                                        .font(FontUtil.bold(size: 18))
                                        .size(height: 22)
                                    View().apply { [weak self] view in
                                        guard let self = self else { return }
                                        let tkSwitch = TKSwitch()
                                            .addTo(superView: view) { make in
                                                make.center.equalToSuperview()
                                                make.size.equalToSuperview()
                                            }
                                        tkSwitch.onValueChanged { isOn in
                                            let config = self.config
                                            if isOn {
                                                config.repeatType = .weekly
                                            } else {
                                                config.repeatType = .none
                                            }
                                            self.config = config
                                        }
                                        self.$config.addSubscriber { config in
                                            if config.repeatType == .none {
                                                tkSwitch.isOn = false
                                            } else {
                                                tkSwitch.isOn = true
                                            }
                                        }
                                    }.size(width: 55, height: 22)
                                }
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)) {
                                VStack {
                                    HStack {
                                        Label("Weekly")
                                            .textColor(ColorUtil.Font.third)
                                            .font(FontUtil.bold(size: 18))
                                            .size(height: 22)
                                        View().apply { [weak self] view in
                                            guard let self = self else { return }
                                            self.$config.addSubscriber { config in
                                                view.layer.sublayers?.forEach({ $0.removeFromSuperlayer() })
                                                if config.repeatType == .weekly {
                                                    let checkLayer = view.getCheckLayer(containerSize: 22, color: ColorUtil.main, animated: false, duration: 0)
                                                    view.layer.addSublayer(checkLayer)
                                                }
                                            }
                                        }.size(width: 22, height: 22)
                                    }
                                    Spacer(spacing: 10)
                                    HStack(distribution: .fillEqually, spacing: 2) {
                                        for i in 0 ... 6 {
                                            View().apply { [weak self] view in
                                                guard let self = self else { return }
                                                let label = Label(TimeUtil.getWeekDayShotName(weekDay: i))
                                                    .font(FontUtil.bold(size: 13))
                                                    .textColor(.white)
                                                    .textAlignment(.center)
                                                    .addTo(superView: view) { make in
                                                        make.left.right.equalToSuperview()
                                                        make.centerY.equalToSuperview()
                                                    }
                                                self.$config.addSubscriber { config in
                                                    if config.repeatType == .weekly {
                                                        let diff = TimeUtil.getUTCWeekdayDiff(timestamp: Int(config.startDateTime * 1000))
                                                        let weeks: [Int] = config.repeatTypeWeekDay.compactMap {
                                                            var i = $0 + (-diff)
                                                            if i < 0 {
                                                                i = 6
                                                            } else if i > 6 {
                                                                i = 0
                                                            }
                                                            return i
                                                        }
                                                        if weeks.contains(i) {
                                                            _ = label.textColor(.white)
                                                            _ = view.backgroundColor(ColorUtil.main)
                                                                .borderWidth(0)
                                                        } else {
                                                            _ = label.textColor(ColorUtil.Font.second)
                                                            _ = view.backgroundColor(.white)
                                                                .borderWidth(1)
                                                        }
                                                    } else {
                                                        _ = label.textColor(ColorUtil.Font.second)
                                                        _ = view.backgroundColor(.white)
                                                            .borderWidth(1)
                                                    }
                                                }
                                            }
                                            .borderColor(ColorUtil.borderColor)
                                            .cornerRadius(5)
                                            .size(height: 40)
                                            .onViewTapped { [weak self] _ in
                                                guard let self = self else { return }
                                                let config = self.config
                                                if config.repeatType != .weekly {
                                                    config.repeatType = .weekly
                                                }
                                                let diff = TimeUtil.getUTCWeekdayDiff(timestamp: Int(config.startDateTime * 1000))
                                                var weeks: [Int] = config.repeatTypeWeekDay.compactMap {
                                                    var i = $0 + (-diff)
                                                    if i < 0 {
                                                        i = 6
                                                    } else if i > 6 {
                                                        i = 0
                                                    }
                                                    return i
                                                }

                                                if weeks.contains(i) {
                                                    weeks.removeElements({ $0 == i })
                                                } else {
                                                    weeks.append(i)
                                                }
                                                config.repeatTypeWeekDay = weeks.compactMap {
                                                    var i = $0 + diff
                                                    if i < 0 {
                                                        i = 6
                                                    } else if i > 6 {
                                                        i = 0
                                                    }
                                                    return i
                                                }.sorted(by: { $0 < $1 })
                                                self.config = config
                                            }
                                        }
                                    }
                                    .size(height: 40)
                                    .apply { [weak self] view in
                                        guard let self = self else { return }
                                        self.$config.addSubscriber { config in
                                            if config.repeatType == .weekly {
                                                view.isHidden = false
                                            } else {
                                                view.isHidden = true
                                            }
                                        }
                                    }
                                    Spacer(spacing: 10)
                                    Divider(weight: 1, color: ColorUtil.borderColor)
                                }
                            }
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                self.$config.addSubscriber { config in
                                    logger.debug("监听到config发生变化: \(config.repeatType.rawValue)")
                                    if config.repeatType == .none {
                                        _ = view.isHidden(true)
                                    } else {
                                        _ = view.isHidden(false)
                                    }
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                guard let self = self else { return }
                                let config = self.config
                                config.repeatType = .weekly
                                self.config = config
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 10, right: 20)) {
                                VStack {
                                    HStack {
                                        Label("Bi-Weekly")
                                            .textColor(ColorUtil.Font.third)
                                            .font(FontUtil.bold(size: 18))
                                            .size(height: 22)
                                        View().apply { [weak self] view in
                                            guard let self = self else { return }
                                            self.$config.addSubscriber { config in
                                                view.layer.sublayers?.forEach({ $0.removeFromSuperlayer() })
                                                if config.repeatType == .biWeekly {
                                                    let checkLayer = view.getCheckLayer(containerSize: 22, color: ColorUtil.main, animated: false, duration: 0)
                                                    view.layer.addSublayer(checkLayer)
                                                }
                                            }
                                        }.size(width: 22, height: 22)
                                    }
                                    Spacer(spacing: 10)
                                    HStack(distribution: .fillEqually, spacing: 2) {
                                        for i in 0 ... 6 {
                                            View().apply { [weak self] view in
                                                guard let self = self else { return }
                                                let label = Label(TimeUtil.getWeekDayShotName(weekDay: i))
                                                    .font(FontUtil.bold(size: 13))
                                                    .textColor(.white)
                                                    .textAlignment(.center)
                                                    .addTo(superView: view) { make in
                                                        make.left.right.equalToSuperview()
                                                        make.centerY.equalToSuperview()
                                                    }
                                                self.$config.addSubscriber { config in
                                                    if config.repeatType == .biWeekly {
                                                        let diff = TimeUtil.getUTCWeekdayDiff(timestamp: Int(config.startDateTime * 1000))
                                                        let weeks: [Int] = config.repeatTypeWeekDay.compactMap {
                                                            var i = $0 + (-diff)
                                                            if i < 0 {
                                                                i = 6
                                                            } else if i > 6 {
                                                                i = 0
                                                            }
                                                            return i
                                                        }
                                                        if weeks.contains(i) {
                                                            _ = label.textColor(.white)
                                                            _ = view.backgroundColor(ColorUtil.main)
                                                                .borderWidth(0)
                                                        } else {
                                                            _ = label.textColor(ColorUtil.Font.second)
                                                            _ = view.backgroundColor(.white)
                                                                .borderWidth(1)
                                                        }
                                                    } else {
                                                        _ = label.textColor(ColorUtil.Font.second)
                                                        _ = view.backgroundColor(.white)
                                                            .borderWidth(1)
                                                    }
                                                }
                                            }
                                            .borderColor(ColorUtil.borderColor)
                                            .cornerRadius(5)
                                            .size(height: 40)
                                            .onViewTapped { [weak self] _ in
                                                guard let self = self else { return }
                                                let config = self.config
                                                if config.repeatType != .biWeekly {
                                                    config.repeatType = .biWeekly
                                                }
                                                let diff = TimeUtil.getUTCWeekdayDiff(timestamp: Int(config.startDateTime * 1000))
                                                var weeks: [Int] = config.repeatTypeWeekDay.compactMap {
                                                    var i = $0 + (-diff)
                                                    if i < 0 {
                                                        i = 6
                                                    } else if i > 6 {
                                                        i = 0
                                                    }
                                                    return i
                                                }

                                                if weeks.contains(i) {
                                                    weeks.removeElements({ $0 == i })
                                                } else {
                                                    weeks.append(i)
                                                }
                                                config.repeatTypeWeekDay = weeks.compactMap {
                                                    var i = $0 + diff
                                                    if i < 0 {
                                                        i = 6
                                                    } else if i > 6 {
                                                        i = 0
                                                    }
                                                    return i
                                                }.sorted(by: { $0 < $1 })
                                                self.config = config
                                            }
                                        }
                                    }
                                    .size(height: 40)
                                    .apply { [weak self] view in
                                        guard let self = self else { return }
                                        self.$config.addSubscriber { config in
                                            if config.repeatType == .biWeekly {
                                                view.isHidden = false
                                            } else {
                                                view.isHidden = true
                                            }
                                        }
                                    }
                                    Spacer(spacing: 20)
                                        .apply { [weak self] view in
                                            guard let self = self else { return }
                                            self.$config.addSubscriber { config in
                                                if config.repeatType != .biWeekly {
                                                    view.isHidden = true
                                                } else {
                                                    view.isHidden = false
                                                }
                                            }
                                        }
                                }
                            }
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                self.$config.addSubscriber { config in
                                    if config.repeatType == .none {
                                        _ = view.isHidden(true)
                                    } else {
                                        _ = view.isHidden(false)
                                    }
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                guard let self = self else { return }
                                let config = self.config
                                config.repeatType = .biWeekly
                                self.config = config
                            }
                        }
                    }
                    .backgroundColor(.white)
                    .borderColor(ColorUtil.borderColor)
                    .borderWidth(1)
                    .cornerRadius(5)
                    .showShadow()
                }

                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)) {
                    ViewBox(paddings: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)) {
                        VStack {
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                                HStack {
                                    Label("Ends")
                                        .textColor(ColorUtil.Font.third)
                                        .font(FontUtil.bold(size: 18))
                                        .size(height: 22)
                                    View().apply { [weak self] view in
                                        guard let self = self else { return }
                                        let tkSwitch = TKSwitch()
                                            .addTo(superView: view) { make in
                                                make.center.equalToSuperview()
                                                make.size.equalToSuperview()
                                            }
                                        tkSwitch.onValueChanged { isOn in
                                            let config = self.config
                                            if isOn {
                                                config.endType = .endAtSomeday
                                                config.endDate = Date(seconds: config.startDateTime).add(component: .month, value: 1).timeIntervalSince1970
                                            } else {
                                                config.endType = .none
                                            }
                                            self.config = config
                                        }
                                        self.$config.addSubscriber { config in
                                            if config.endType == .none {
                                                tkSwitch.isOn = false
                                            } else {
                                                tkSwitch.isOn = true
                                            }
                                        }
                                    }.size(width: 55, height: 22)
                                }
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 5, left: 20, bottom: 5, right: 20)) {
                                HStack(alignment: .center) {
                                    ImageView()
                                        .borderColor(ColorUtil.borderColor)
                                        .borderWidth(1)
                                        .cornerRadius(11)
                                        .size(width: 22, height: 22)
                                        .apply { [weak self] imageView in
                                            guard let self = self else { return }
                                            self.$config.addSubscriber { config in
                                                if config.endType == .endAtSomeday {
                                                    imageView.image = UIImage(named: "radiobuttonOn")
                                                } else {
                                                    imageView.image = nil
                                                }
                                            }
                                        }
                                    Spacer(spacing: 8)
                                    Label("Ends on")
                                        .textColor(ColorUtil.Font.third)
                                        .font(FontUtil.bold(size: 18))
                                        .size(width: 70, height: 21)
                                        .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                    Spacer(spacing: 8)
                                    ViewBox(paddings: UIEdgeInsets(top: 11, left: 8, bottom: 11, right: 8)) {
                                        Label()
                                            .textColor(ColorUtil.Font.third)
                                            .font(FontUtil.bold(size: 18))
                                            .size(height: 21)
                                            .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                            .apply { [weak self] label in
                                                guard let self = self else { return }
                                                self.$config.addSubscriber { config in
                                                    _ = label.text(Date(seconds: config.endDate).toLocalFormat("MMM dd, yyyy"))
                                                }
                                            }
                                    }
                                    .cornerRadius(5)
                                    .backgroundColor(UIColor(hex: "E6E9EB"))
                                    .onViewTapped { [weak self] _ in
                                        guard let self = self else { return }
                                        TKDatePicker.show(startDate: Date(seconds: self.config.startDateTime)) { date in
                                            let config = self.config
                                            config.endDate = TimeInterval(date.toString().toDate("yyyy-MM-dd", region: .local)!.date.timestamp)
                                            config.endType = .endAtSomeday
                                            self.config = config
                                        }
                                    }
                                    Label("")
                                        .contentHuggingPriority(.defaultLow, for: .horizontal)
                                }
                            }.apply { [weak self] view in
                                guard let self = self else { return }
                                self.$config.addSubscriber { config in
                                    if config.endType == .none {
                                        view.isHidden = true
                                    } else {
                                        view.isHidden = false
                                    }
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                guard let self = self else { return }
                                let config = self.config
                                config.endType = .endAtSomeday
                                config.endDate = Date(seconds: config.startDateTime).add(component: .month, value: 1).timeIntervalSince1970
                                self.config = config
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 5, left: 20, bottom: 20, right: 20)) {
                                HStack(alignment: .center) {
                                    ImageView()
                                        .borderColor(ColorUtil.borderColor)
                                        .cornerRadius(11)
                                        .borderWidth(1)
                                        .size(width: 22, height: 22)
                                        .apply { [weak self] imageView in
                                            guard let self = self else { return }
                                            self.$config.addSubscriber { config in
                                                if config.endType == .endAfterSometimes {
                                                    imageView.image = UIImage(named: "radiobuttonOn")
                                                } else {
                                                    imageView.image = nil
                                                }
                                            }
                                        }
                                    Spacer(spacing: 8)
                                    Label("Ends after")
                                        .textColor(ColorUtil.Font.third)
                                        .font(FontUtil.bold(size: 18))
                                        .size(width: 91, height: 21)
                                        .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                    Spacer(spacing: 8)
                                    ViewBox(paddings: UIEdgeInsets(top: 11, left: 8, bottom: 11, right: 8)) {
                                        Label()
                                            .textColor(ColorUtil.Font.third)
                                            .font(FontUtil.bold(size: 18))
                                            .size(height: 21)
                                            .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                            .apply { [weak self] label in
                                                guard let self = self else { return }
                                                self.$config.addSubscriber { config in
                                                    if config.endType == .endAfterSometimes {
                                                        _ = label.text("\(config.endCount)")
                                                    } else {
                                                        _ = label.text("10")
                                                    }
                                                }
                                            }
                                    }
                                    .cornerRadius(5)
                                    .backgroundColor(UIColor(hex: "E6E9EB"))
                                    .onViewTapped { [weak self] _ in
                                        guard let self = self else { return }
                                        TKPopAction.showEditPop(target: self, placeholder: "currence", defaultValue: "\(self.config.endCount)", titleString: "Set currence", confirmAction: { data in
                                            let config = self.config
                                            config.endType = .endAfterSometimes
                                            let data: Int = Int(data) ?? 1
                                            config.endCount = data
                                            self.config = config
                                        }, onTyped: { textBox, value in
                                            if let v = Int(value) {
                                                if v >= 999 {
                                                    textBox.value("999")
                                                }
                                            }
                                        })
                                    }
                                    Spacer(spacing: 8)
                                    Label("currence")
                                        .textColor(ColorUtil.Font.third)
                                        .font(FontUtil.bold(size: 18))
                                        .size(height: 21)
                                        .contentHuggingPriority(.defaultLow, for: .horizontal)
                                }
                            }
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                self.$config.addSubscriber { config in
                                    if config.endType == .none {
                                        view.isHidden = true
                                    } else {
                                        view.isHidden = false
                                    }
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                guard let self = self else { return }
                                let config = self.config
                                config.endType = .endAfterSometimes
                                config.endCount = 10
                                self.config = config
                            }
                        }
                    }
                    .backgroundColor(.white)
                    .borderColor(ColorUtil.borderColor)
                    .borderWidth(1)
                    .cornerRadius(5)
                    .showShadow()
                }

                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)) {
                    HStack(distribution: .fillEqually, spacing: 10) {
                        BlockButton()
                            .set(title: "CANCEL", style: .cancel)
                            .size(height: 50)
                            .onTapped { [weak self] _ in
                                self?.hide()
                            }
                        BlockButton()
                            .set(title: "CONFIRM", style: .normal)
                            .size(height: 50)
                            .onTapped { [weak self] _ in
                                self?.onConfirmButtonTapped()
                            }
                    }
                }
            }
        }
        .addTo(superView: contentView) { make in
            make.top.left.right.equalToSuperview()
        }
        contentView.transform = CGAffineTransform(translationX: 0, y: contentViewHeight)
    }
}

extension LessonDetailRescheduleForLessonsPopupViewController {
    private func show() {
        guard !isShow else { return }
        isShow = true
        animate(timeInterval: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        }
    }

    func hide(_ completion: (() -> Void)? = nil) {
        animate(timeInterval: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: self.contentViewHeight)
        } completion: { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: false) {
                completion?()
            }
        }
    }
}

extension LessonDetailRescheduleForLessonsPopupViewController {
    private func onStartOnTapped() {
        guard let lessonType = ListenerService.shared.teacherData.lessonTypes.first(where: { $0.id == config.lessonTypeId }) else { return }
        let controller = TKPopSelectScheduleStartTimeController()
        controller.modalPresentationStyle = .custom
        if config.startDateTime < Date().timeIntervalSince1970 {
            let config = self.config
            config.startDateTime = TimeInterval(Date().timestamp)
            self.config = config
        }
        controller.selectDate = Date(seconds: config.startDateTime)
        controller.timeLength = lessonType.timeLength
        present(controller, animated: false)
        controller.onDone { [weak self] date in
            guard let self = self else { return }
            let config = self.config
            config.startDateTime = TimeInterval(date.timestamp)
            config.endDate = Date(seconds: config.startDateTime).add(component: .month, value: 1).timeIntervalSince1970
            config.repeatType = .none
            config.endType = .none
            self.config = config
        }
    }

    private func onConfirmButtonTapped() {
        logger.debug("要上传的config: \(config.toJSONString() ?? "")")
        let now = Date().timestamp
        config.createTime = now.description
        config.updateTime = now.description
        showFullScreenLoadingNoAutoHide()
        Functions.functions().httpsCallable("lessonService-rescheduleLessonsWithType")
            .call([
                "rescheduleType": rescheduleType.rawValue,
                "scheduleConfigId": oldConfig.id,
                "selectedLessonScheduleId": selectedLessonScheduleId,
                "newScheduleConfig": config.toJSON() ?? [:],
            ]) { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("发生错误: \(error)")
                    TKToast.show(msg: "Reschedule failed, please try again later.", style: .error)
                } else {
                    self.hide {
                        Tools.getTopViewController()?.dismiss(animated: true) {
                            TKToast.show(msg: "Reschedule successfully.", style: .success)
                        }
                    }
                }
            }
    }
}
