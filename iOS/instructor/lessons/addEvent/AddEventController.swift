//
//  AddEventController.swift
//  TuneKey
//
//  Created by WHT on 2020/3/10.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class AddEventController: SLBaseScrollViewController {
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    var headerView: TKView!
    var titleView: TKTextBox!
    var startTimeView: TKView!
    var startTimeLabel: TKLabel!
    var endTimeView: TKView!
    var endTimeLabel: TKLabel!

    var selectedDate: Date? = Date()
    var recurrenceData: RepeatDays = RepeatDays()
    var recurrenceCellHeight: CGFloat = 84
    var recurrenceView: TKView!
    var recurrenceContentView: TKView!
    var recurrenceTitleLabel: TKLabel!
    var recurrenceSwitch: TKSwitch!
    var weeklyView: TKView!
    var weeklyTitleLabel: TKLabel!
    var weeklyCheckImageView: TKImageView!
    var weeklyDaysStackView: UIStackView!
    var biWeeklyView: TKView!
    var biWeeklyTitleLabel: TKLabel!
    var biWeeklyCheckImageView: TKImageView!
    var biWeeklyDaysStackView: UIStackView!
    var weeklyDaysLabels: [TKLabel] = []
    var weeklyDaysViews: [TKView] = []

    var monthlyView: TKView!
    var monthlyTitleLabel: TKLabel!
    var monthlyCheckImageView: TKImageView!
    var monthlySameWeekDayTitleLabel: TKLabel!
    var monthlySameMonthDayTitleLabel: TKLabel!
    var monthlySelectedButtonImage: String = "radiobuttonOn"
    var monthlyUnselectedButtonImage: String = "checkboxOff"

    var endCellHeight: CGFloat = 74
    struct EndsType: HandyJSON {
        var endType: TKEndType = .none
        var endDate: TimeInterval = 0
        var endCount: Int = 10
    }

    var endsType: EndsType!
    var endBoxView: TKView!
    var endContainerView: TKView!
    var topContainerView: TKView!
    var titleLabel: TKLabel!
    var doesNotEndSwitch: TKSwitch!
    var endOnSomedayView: TKView!
    var endOnSomedayCheckBox: TKImageView!
    var endOnSomedayDateView: TKView!
    var endOnSomedayDateLabel: TKLabel!
    var endAfterSomeTimesView: TKView!
    var endAfterSomeTimesCheckBox: TKImageView!
    var endAfterSomeTimesCountView: TKView!
    var endAfterSomeTimesCountLabel: TKLabel!

    var data: TKEventConfigure = TKEventConfigure()
    var dataFormatter = DateFormatter()
    var monthlySameMonthDayButton: TKImageView!
    var monthlySameWeekDayButton: TKImageView!

    var nextButton: TKBlockButton!
    var isEdit = false

    private let startTimeFormat = Locale.is12HoursFormat() ? "hh:mm a, MM/dd/yyyy" : "HH:mm, MM/dd/yyyy"
    private let endTimeFormat = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"

    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isEdit {
            titleView.value(data.title)
        } else {
            titleView.focus()
        }
    }
}

// MARK: - View

extension AddEventController {
    override func initView() {
        super.initView()
        if isEdit {
            navigationBar = TKNormalNavigationBar(frame: .zero, title: "Edit Event", rightButton: "Delete", rightButtonColor: ColorUtil.red, target: self, onRightButtonTapped: { [weak self] in
                self?.deleteEvent()
            })
        } else {
            navigationBar = TKNormalNavigationBar(frame: .zero, title: "Add Event", target: self)
        }

        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.height.equalTo(44)
        }
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
        scrollView.snp.remakeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
//        initHeaderView()
        initTitleView()
        initStartTimeView()
        initEndTimeView()
        initrecurrenceView()
        initEndsView()
        nextButton = TKBlockButton(frame: CGRect.zero, title: !isEdit ? "CREATE" : "SAVE")
        if !isEdit {
            nextButton.disable()
        }
        view.addSubview(view: nextButton) { make in
            make.height.equalTo(50)
            make.width.equalTo(180)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        nextButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            if self.isEdit {
                self.editEvent()
            } else {
                self.clickCreate()
            }
        }
    }

    private func initHeaderView() {
        headerView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalToSuperview().offset(10)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(94.3)
            })
        let titleImg = TKImageView.create()
            .setImage(name: "imgClaendar")
            .addTo(superView: headerView) { make in
                make.left.equalToSuperview().offset(20)
                make.centerY.equalToSuperview()
                make.size.equalTo(30)
            }
        _ = TKLabel.create()
            .text(text: "Event")
            .textColor(color: ColorUtil.Font.third)
            .font(font: FontUtil.bold(size: 18))
            .setLabelRowSpace(lineSpace: 0, wordSpace: 1)
            .addTo(superView: headerView) { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(titleImg.snp.right).offset(20)
            }
    }

    private func initTitleView() {
        titleView = TKTextBox.create()
            .placeholder("Title")
            .addTo(superView: contentView, withConstraints: { make in
//                make.top.equalTo(headerView.snp.bottom).offset(20)
                make.top.equalToSuperview().offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })
        titleView.onTyped { [weak self] text in
            guard let self = self else { return }
            self.data.title = text
            if text.count > 0 {
                self.nextButton.enable()
            } else {
                self.nextButton.disable()
            }
        }
    }

    private func initStartTimeView() {
        startTimeView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalTo(titleView.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })
        startTimeView.onViewTapped { [weak self] _ in
            self?.selectDate()
        }
        let arrowView = TKImageView.create()
            .setImage(name: "arrowRight")
            .addTo(superView: startTimeView) { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(22)
            }
        let infoLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.primary)
            .font(font: FontUtil.regular(size: 13))
            .text(text: "Start")
            .alignment(alignment: .right)
            .addTo(superView: startTimeView) { make in
                make.right.equalTo(arrowView.snp.left)
                make.centerY.equalToSuperview()
                make.width.equalTo(35)
            }
        startTimeLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.bold(size: 18))
            .addTo(superView: startTimeView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualTo(infoLabel.snp.left).offset(-20)
                make.left.equalToSuperview().offset(20)
            })
    }

    private func initEndTimeView() {
        endTimeView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalTo(startTimeView.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })
        endTimeView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            let startDate = TimeUtil.changeTime(time: self.data.startDateTime)
            let endDate = TimeUtil.changeTime(time: self.data.endDateTime)

            self.selectTime(type: 2, between: TKTimePicker.Time(hour: startDate.hour, minute: startDate.minute), defaultTime: TKTimePicker.Time(hour: endDate.hour, minute: endDate.minute))
        }
        let arrowView = TKImageView.create()
            .setImage(name: "arrowRight")
            .addTo(superView: endTimeView) { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(22)
            }
        let infoLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.primary)
            .font(font: FontUtil.regular(size: 13))
            .text(text: "End")
            .alignment(alignment: .right)
            .addTo(superView: endTimeView) { make in
                make.right.equalTo(arrowView.snp.left)
                make.centerY.equalToSuperview()
                make.width.equalTo("End".widthWithFont(font: FontUtil.regular(size: 13)) + 20)
            }
        endTimeLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.bold(size: 18))
            .addTo(superView: endTimeView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualTo(infoLabel.snp.left).offset(-20)
                make.left.equalToSuperview().offset(20)
            })
    }
}

extension AddEventController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}

// MARK: - Data

extension AddEventController {
    override func initData() {
        if isEdit {
            initEditData()
        } else {
            var currentDate = Date()
            endsType = EndsType()
            endsType.endType = .none
            endsType.endCount = 10
            endsType.endDate = currentDate.add(component: .month, value: 1).timeIntervalSince1970
            data.startDateTime = TimeInterval(currentDate.timestamp)
            data.endDateTime = currentDate.add(component: .hour, value: 1).timeIntervalSince1970
            data.endDate = endsType.endDate
            data.endCount = endsType.endCount
            if currentDate.hour > 23 {
                currentDate = currentDate.add(component: .hour, value: 2)
            }
            selectedDate = currentDate
            dataFormatter.dateFormat = startTimeFormat
            startTimeLabel.text = dataFormatter.string(from: currentDate)
            dataFormatter.dateFormat = endTimeFormat
            endTimeLabel.text = dataFormatter.string(from: currentDate.add(component: .hour, value: 1))
            recurrenceData.repeatTypeWeekDay = [currentDate.getWeekday()]
            data.repeatTypeWeekDay = [currentDate.getWeekday()]
            updateCell()
            for item in weeklyDaysViews.enumerated() {
                weeklyDaysViews[item.offset].backgroundColor = UIColor.white
                weeklyDaysViews[item.offset].borderColor = ColorUtil.borderColor
                weeklyDaysLabels[item.offset].textColor(color: ColorUtil.Font.primary)
            }
            for item in data.repeatTypeWeekDay {
                for view in weeklyDaysViews where view.tag == item {
                    view.backgroundColor = ColorUtil.main
                    view.borderColor = ColorUtil.main
                }
                for label in weeklyDaysLabels where label.tag == item {
                    label.textColor(color: UIColor.white)
                }
            }
        }
    }

    func initEditData() {
        endsType = EndsType()
        if data.endCount == 0 {
            data.endCount = 10
        }
        if data.endDate == 0 {
            data.endDate = TimeUtil.changeTime(time: data.startDateTime).add(component: .month, value: 1).timeIntervalSince1970
        }
        endsType.endType = data.endType
        endsType.endCount = data.endCount
        endsType.endDate = data.endDate
        recurrenceData.repeatType = data.repeatType
        recurrenceData.repeatTypeWeekDay = data.repeatTypeWeekDay
        recurrenceData.repeatTypeMonthDayType = data.repeatTypeMonthDayType
        recurrenceData.repeatTypeMonthDay = data.repeatTypeMonthDay
        dataFormatter.dateFormat = endTimeFormat
        endTimeLabel.text = dataFormatter.string(from: TimeUtil.changeTime(time: data.endDateTime))
        dataFormatter.dateFormat = startTimeFormat
        startTimeLabel.text = dataFormatter.string(from: TimeUtil.changeTime(time: data.startDateTime))
        selectedDate = TimeUtil.changeTime(time: data.startDateTime)
        switch data.repeatType {
        case .none:
            break
        case .weekly, .biWeekly, .monthly:
            recurrenceSwitch.isOn = true
            initEndViewData(isOpend: true)
            updateCell()
            break
        }
        switch data.repeatTypeMonthDayType {
        case .dayOfWeek, .dayOfLastWeek:
            _ = monthlySameWeekDayButton.setImage(name: monthlySelectedButtonImage)
            _ = monthlySameMonthDayButton.setImage(name: monthlyUnselectedButtonImage)
            break
        case .day, .endOfMonth:
            _ = monthlySameWeekDayButton.setImage(name: monthlyUnselectedButtonImage)
            _ = monthlySameMonthDayButton.setImage(name: monthlySelectedButtonImage)
            break
        }
        for item in weeklyDaysViews.enumerated() {
            weeklyDaysViews[item.offset].backgroundColor = UIColor.white
            weeklyDaysViews[item.offset].borderColor = ColorUtil.borderColor
            weeklyDaysLabels[item.offset].textColor(color: ColorUtil.Font.primary)
        }
        for item in data.repeatTypeWeekDay {
            for view in weeklyDaysViews where view.tag == item {
                view.backgroundColor = ColorUtil.main
                view.borderColor = ColorUtil.main
            }
            for label in weeklyDaysLabels where label.tag == item {
                label.textColor(color: UIColor.white)
            }
        }
        if data.endType != .none {
            doesNotEndSwitch.isOn = true
        }
    }

    func deleteEvent() {
        showFullScreenLoading()
        addSubscribe(
            LessonService.event.delete(id: data.id)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    EventBus.send(EventBus.CHANGE_SCHEDULE)
                    self.hideFullScreenLoading()
                    logger.debug("===成功===")
                    self.dismiss(animated: true) {
                        TKToast.show(msg: TipMsg.deleteSuccessful, style: .success)
                    }
                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    logger.debug("====失败==\(err)")
                    TKToast.show(msg: TipMsg.deleteFailed, style: .warning)
                })
        )
    }
}

// MARK: - TableView

extension AddEventController {
}

// MARK: - Action

extension AddEventController {
    func editEvent() {
        print(data.toJSONString(prettyPrint: true) ?? "")
        showFullScreenLoading()
        addSubscribe(
            LessonService.event.update(id: data.id, data: data.toJSON() ?? [:])
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    EventBus.send(EventBus.CHANGE_SCHEDULE)

                    self.hideFullScreenLoading()
                    logger.debug("===成功===")
                    self.dismiss(animated: true) {
                        TKToast.show(msg: "Save successfully!", style: .success)
                    }
                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    logger.debug("====失败==\(err)")
                    TKToast.show(msg: "Save failed Please try again!", style: .warning)
                })
        )
    }

    /// 创建Event
    func clickCreate() {
        let time = "\(Date().timestamp)"
        data.id = time
        if let id = IDUtil.nextId(group: .lesson) {
            data.id = "\(id)"
        }
        data.teacherId = UserService.user.id()!
        data.createTime = time
        data.updateTime = time

        print("\(data.toJSONString(prettyPrint: true) ?? "")")
        showFullScreenLoading()
        addSubscribe(
            LessonService.event.add(data: data)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    logger.debug("===成功===")
                    self.dismiss(animated: true) {
                        TKToast.show(msg: TipMsg.createSuccessful, style: .success)
                    }
                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    logger.debug("====失败==\(err)")
                    TKToast.show(msg: TipMsg.faildCreate, style: .warning)
                })
        )
    }

    /// 选择时间
    func selectDate() {
        var d = Date()
        if selectedDate != nil && selectedDate!.timestamp >= d.timestamp {
            d = selectedDate!
        }
        TKDatePicker.show(oldDate: d) { [weak self] date in
            guard let self = self else { return }
            let dateString = "\(date.toString()) \(d.hour):\(d.minute)"
            let date = dateString.toDate("YYYY-MM-dd hh:mm", region: .local)!.date
            self.selectedDate = date
            self.data.startDateTime = TimeInterval(date.timestamp)
            self.data.endDateTime = date.add(component: .hour, value: 1).timeIntervalSince1970
            self.dataFormatter.dateFormat = self.startTimeFormat
            self.startTimeLabel.text = self.dataFormatter.string(from: date)
            self.dataFormatter.dateFormat = self.endTimeFormat
            self.endTimeLabel.text = self.dataFormatter.string(from: date.add(component: .hour, value: 1))
            self.resetRecurrenceData()
            self.endsType.endDate = TimeInterval(date.date.add(component: .month, value: 1).timestamp)
            self.endsType.endCount = 10
            self.data.endDate = self.endsType.endDate
            self.data.endCount = self.endsType.endCount
            let dfmatter = DateFormatter()
            dfmatter.dateFormat = "MMM dd, YYYY"
            let endOnSomeDayDateString = dfmatter.string(from: date)

            self.endOnSomedayDateLabel.text(endOnSomeDayDateString)
            self.endAfterSomeTimesCountLabel.text("\(self.endsType.endCount)")

            self.recurrenceData.repeatTypeWeekDay = [date.getWeekday()]
            self.data.repeatTypeWeekDay = [date.getWeekday()]
            self.updateCell()
            for item in self.weeklyDaysViews.enumerated() {
                self.weeklyDaysViews[item.offset].backgroundColor = UIColor.white
                self.weeklyDaysViews[item.offset].borderColor = ColorUtil.borderColor
                self.weeklyDaysLabels[item.offset].textColor(color: ColorUtil.Font.primary)
            }
            for item in self.data.repeatTypeWeekDay {
                for view in self.weeklyDaysViews where view.tag == item {
                    view.backgroundColor = ColorUtil.main
                    view.borderColor = ColorUtil.main
                }
                for label in self.weeklyDaysLabels where label.tag == item {
                    label.textColor(color: UIColor.white)
                }
            }

            self.selectTime(type: 1, between: TKTimePicker.Time(hour: 0, minute: 0), defaultTime: TKTimePicker.Time(hour: d.hour, minute: d.minute))
        }
    }

    /// 选择时间
    /// - Parameters:
    ///   - type: 1是起始时间 2是结束时间
    ///   - between: 时间选择器的开始时间
    ///   - defaultTime: 时间选择器的默认时间
    func selectTime(type: Int, between: TKTimePicker.Time, defaultTime: TKTimePicker.Time) {
        TKTimePicker.show(between: between, and: TKTimePicker.Time(hour: 23, minute: 59), defaultTime: defaultTime, target: self) { [weak self] selectTime in
            guard let self = self else { return }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            var date = TimeUtil.changeTime(time: self.data.startDateTime)
            if type == 2 {
                date = TimeUtil.changeTime(time: self.data.endDateTime)
            }
            let dateString = "\(df.string(from: date)) \(selectTime.hour!):\(selectTime.minute!)"
            df.dateFormat = "yyyy-MM-dd HH:mm"
            if type == 1 {
                self.selectedDate = df.date(from: dateString)!
                self.data.startDateTime = TimeInterval(df.date(from: dateString)!.timestamp)
                self.dataFormatter.dateFormat = self.startTimeFormat
                self.startTimeLabel.text = self.dataFormatter.string(from: TimeUtil.changeTime(time: self.data.startDateTime))
                self.data.endDateTime = df.date(from: dateString)!.add(component: .hour, value: 1).timeIntervalSince1970
                self.dataFormatter.dateFormat = self.endTimeFormat
                self.endTimeLabel.text = self.dataFormatter.string(for: TimeUtil.changeTime(time: self.data.endDateTime))

            } else {
                self.data.endDateTime = TimeInterval(df.date(from: dateString)!.timestamp)
                self.dataFormatter.dateFormat = self.endTimeFormat
                self.endTimeLabel.text = self.dataFormatter.string(for: TimeUtil.changeTime(time: self.data.endDateTime))
            }
        }
    }
}
