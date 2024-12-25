//
//  SAddLessonViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/1/22.
//  Copyright © 2021 spelist. All rights reserved.
//

import FirebaseFirestore
import FirebaseFunctions
import UIKit

class SAddLessonViewController: TKBaseViewController {
    enum Step {
        case lessonType
        case time
        case recurrence(_ isOpen: Bool)
    }

    private lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Add Lesson")
    private lazy var tableView: UITableView = UITableView(frame: .zero)
    private lazy var confirmButton: TKBlockButton = TKBlockButton(frame: .zero, title: "CONFIRM")

    private var currentStep: Step = .lessonType

    private var allInstruments: [TKInstrument] = []

    private var cellHeights: [CGFloat] = [74, 74, 74, 74]

    private var selectedInstrument: TKInstrument? {
        didSet {
            if startDate != nil && selectedInstrument != nil {
                confirmButton.enable()
            } else {
                confirmButton.disable()
            }
        }
    }

    private var repeatDays: RepeatDays = RepeatDays()
    private var timeRange: TKTimeRange = .getDefault()
    private var lessonScheduleConfigure: TKLessonScheduleConfigure = TKLessonScheduleConfigure()
    private var endsType: AddLessonScheduleDetailDoesNotEndTableViewCell.EndsType = .init(endType: .none, endDate: TimeInterval(Date().add(component: .day, value: 1).timestamp), endCount: 10)
    private var startDate: Date? {
        didSet {
            if startDate != nil && selectedInstrument != nil {
                confirmButton.enable()
            } else {
                confirmButton.disable()
            }
        }
    }
}

extension SAddLessonViewController {
    override func initView() {
        super.initView()
        navigationBar.updateLayout(target: self)

        confirmButton.addTo(superView: view) { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.width.equalTo(180)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
        }
        confirmButton.disable()

        tableView.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.bottom.equalTo(confirmButton.snp.top)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        }
        tableView.backgroundColor = view.backgroundColor
        tableView.register(ProfileEditDetailInstrumentTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileEditDetailInstrumentTableViewCell.self))
        tableView.register(AddLessonScheduleDetailDateTimeTableViewCell.self, forCellReuseIdentifier: String(describing: AddLessonScheduleDetailDateTimeTableViewCell.self))
        tableView.register(AddLessonScheduleDetailRecurrenceTableViewCell.self, forCellReuseIdentifier: String(describing: AddLessonScheduleDetailRecurrenceTableViewCell.self))
        tableView.register(AddLessonScheduleDetailDoesNotEndTableViewCell.self, forCellReuseIdentifier: String(describing: AddLessonScheduleDetailDoesNotEndTableViewCell.self))
        tableView.register(ProfileEditDetailInstrumentV2TableViewCell.self, forCellReuseIdentifier: String(describing: ProfileEditDetailInstrumentV2TableViewCell.self))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20))
        tableView.allowsSelection = false
    }

    override func bindEvent() {
        super.bindEvent()
        confirmButton.onTapped { [weak self] button in
            guard let self = self else { return }
            button.startLoading(at: self.view) {
                self.onConfirmButtonTapped()
            }
        }
    }

    private func onConfirmButtonTapped() {
        guard let selectedInstrument = selectedInstrument, let startDate = startDate, let userId = UserService.user.id() else { return }
        // 整理数据
        let lessonScheduleConfig = TKLessonScheduleConfigure()
        // 创建lessonType
        let lessonTypeId = IDUtil.nextId(group: .lesson)?.description ?? ""
        let now = Date().timestamp.description
        let lessonType = TKLessonType(id: lessonTypeId, teacherId: "", instrumentId: selectedInstrument.id.description, timeLength: 60, price: 0, type: .privateType, name: "", deleted: false, package: 0, createTime: now, updateTime: now)
        lessonScheduleConfig.id = IDUtil.nextId(group: .lesson)?.description ?? ""
        lessonScheduleConfig.teacherId = ""
        lessonScheduleConfig.studentId = userId
        lessonScheduleConfig.lessonTypeId = lessonTypeId
        lessonScheduleConfig.startDateTime = TimeInterval(startDate.timestamp)
        lessonScheduleConfig.repeatType = repeatDays.repeatType
        let diff = TimeUtil.getUTCWeekdayDiff(timestamp: startDate.timestamp)
        var weekdays: [Int] = []
        for day in repeatDays.repeatTypeWeekDay {
            var _day = day + diff
            if _day < 0 {
                _day = 6
            } else if _day > 6 {
                _day = 0
            }
            weekdays.append(_day)
        }
        lessonScheduleConfig.repeatTypeWeekDay = weekdays
        lessonScheduleConfig.repeatTypeMonthDayType = repeatDays.repeatTypeMonthDayType
        lessonScheduleConfig.repeatTypeMonthDay = repeatDays.repeatTypeMonthDay
        lessonScheduleConfig.endType = endsType.endType
        lessonScheduleConfig.endDate = endsType.endDate
        lessonScheduleConfig.endCount = endsType.endCount
        lessonScheduleConfig.createTime = now
        lessonScheduleConfig.updateTime = now
        logger.debug("当前添加的数据: \(lessonScheduleConfig.toJSONString() ?? "")")
        Functions.functions().httpsCallable("studentAddLessonScheduleConfig")
            .call([
                "lessonType": lessonType.toJSON() ?? [:],
                "config": lessonScheduleConfig.toJSON() ?? [:]
            ]) { result, error in
                if let error = error {
                    logger.error("学生添加课程失败: \(error)")
                    self.confirmButton.stopLoadingWithFailed {
                        TKToast.show(msg: TipMsg.failed, style: .error)
                    }
                } else {
                    LoggerUtil.shared.log(.studentAddLessons)
                    
                    if let data = result?.data as? [String: Any], let result = FuncResult.deserialize(from: data) {
                        logger.debug("学生添加课程结果: \(data)")
                        if result.code == 0 {
                            logger.debug("学生添加课程成功")
                            EventBus.send(key: .studentConfigChanged)
                            self.confirmButton.stopLoading {
                                self.dismiss(animated: true) {
                                    TKToast.show(msg: TipMsg.saveSuccessful, style: .success)
                                }
                            }
                        } else {
                            self.confirmButton.stopLoadingWithFailed {
                                TKToast.show(msg: result.msg, style: .error)
                            }
                        }
                        return
                    }

                    self.confirmButton.stopLoadingWithFailed {
                        TKToast.show(msg: "Failed, please try again later.", style: .error)
                    }
                }
            }
    }
}

extension SAddLessonViewController {
    override func initData() {
        super.initData()
        loadAllInstrument { [weak self] in
            guard let self = self else { return }
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileEditDetailInstrumentTableViewCell {
                cell.loadingHide(data: self.allInstruments)
            }
        }
    }

    private func loadAllInstrument(completion: @escaping () -> Void) {
        InstrumentService.shared.listAllInstruments { [weak self] isSuccess, data in
            guard let self = self else { return }
            if isSuccess {
                var data = data
                data.sort { (a, b) -> Bool in
                    a.name < b.name
                }
                data.sort { (a, b) -> Bool in
                    a.category < b.category
                }
                self.allInstruments = data
                completion()
            }
        }
    }
}
extension SAddLessonViewController: ProfileEditDetailInstrumentV2TableViewCellDelegate, InstrumentsSelectorViewControllerDelegate {
    func instrumentsSelectorViewController(didSelectInstruments instruments: [TKInstrument]) {
        
    }
    
    func profileEditDetailInstrumentV2TableViewCellDidTapped() {
        let controller = InstrumentsSelectorViewController()
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }
    func instrumentsSelectorViewController(didSelectInstrument instrument: TKInstrument) {
        var isNew: Bool = false
        if selectedInstrument == nil {
            isNew = true
        }
        selectedInstrument = instrument
        if isNew {
            currentStep = .time
        }
        tableView.reloadData()
    }
}

extension SAddLessonViewController: UITableViewDataSource, UITableViewDelegate {
    private func cellsCount() -> Int {
        switch currentStep {
        case .lessonType: return 1
        case .time: return 2
        case let .recurrence(isOpen):
            if isOpen {
                return 4
            } else {
                return 3
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        cellHeights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cellsCount()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        switch index {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileEditDetailInstrumentV2TableViewCell.self), for: indexPath) as! ProfileEditDetailInstrumentV2TableViewCell
            cellHeights[indexPath.row] = cell.cellHeight
            cell.loadData(selectedInstrument)
            cell.delegate = self
            return cell
//            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileEditDetailInstrumentTableViewCell.self), for: indexPath) as! ProfileEditDetailInstrumentTableViewCell
//            cell.delegate = self
//            cell.index = 0
//            cell.loadData(instrument: selectedInstrument, number: 0)
//            cellHeights[0] = cell.cellHeight
//            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AddLessonScheduleDetailDateTimeTableViewCell.self), for: indexPath) as! AddLessonScheduleDetailDateTimeTableViewCell
            cell.delegate = self
            cell.tag = 1
            cellHeights[1] = 84
            cell.loadData(timeRange: timeRange, lessonTime: 60, selectDate: startDate)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AddLessonScheduleDetailRecurrenceTableViewCell.self), for: indexPath) as! AddLessonScheduleDetailRecurrenceTableViewCell
            cell.delegate = self
            cell.tag = 2
            cell.initData(data: repeatDays)
            cellHeights[2] = cell.cellHeight
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AddLessonScheduleDetailDoesNotEndTableViewCell.self), for: indexPath) as! AddLessonScheduleDetailDoesNotEndTableViewCell
            cell.delegate = self
            cellHeights[3] = cell.cellHeight
            cell.loadData(endsType: endsType, startDate: Date(), isEnabled: true, isOpend: false)
            return cell
        default:
            fatalError()
        }
    }
}

extension SAddLessonViewController: AddLessonScheduleDetailDoesNotEndTableViewCellDelegate {
    func addLessonScheduleDetailDoesNotEndTableViewCell(isOnChanged isOn: Bool) {
    }

    func addLessonScheduleDetailDoesNotEndTableViewCell(heightChanged height: CGFloat) {
        tableView.beginUpdates()
        cellHeights[3] = height
        tableView.endUpdates()
    }

    func addLessonScheduleDetailDoesNotEndTableViewCell(dataChanged: AddLessonScheduleDetailDoesNotEndTableViewCell.EndsType) {
        endsType = dataChanged
    }
}

extension SAddLessonViewController: ProfileEditDetailInstrumentTableViewCellDelegate {
    func profileEditDetailInstrumentTableViewCell(currentInstrumentChanged instrument: TKInstrument, target: ProfileEditDetailInstrumentTableViewCell) {
        var isNew: Bool = false
        if selectedInstrument == nil {
            isNew = true
        }
        selectedInstrument = instrument
        target.close(with: instrument)
        target.loadData(instrument: instrument, number: 0)
        if isNew {
            currentStep = .time
        }
        tableView.reloadData()
    }

    func profileEditDetailInstrumentTableViewCell(heightChanged height: CGFloat, at index: Int) {
        view.endEditing(true)
        tableView.beginUpdates()
        cellHeights[index] = height
        tableView.endUpdates()
    }

    func profileEditDetailInstrumentTableViewCell(tappedAt index: Int) {
    }

    func profileEditDetailInstrumentTableViewCell(isEditing: Bool) {
    }

    func profileEditDetailInstrumentTableViewCell(removeAt index: Int) {
    }
}

extension SAddLessonViewController: AddLessonScheduleDetailDateTimeTableViewCellDelegate {
    func addLessonScheduleDetailDateTimeTableViewCellTapped() {
        let controller = TKPopSelectScheduleStartTimeController()
        controller.modalPresentationStyle = .custom
        if lessonScheduleConfigure.startDateTime != 0 {
            if lessonScheduleConfigure.startDateTime >= Date().timeIntervalSince1970 {
                controller.selectDate = TimeUtil.changeTime(time: lessonScheduleConfigure.startDateTime)
            } else {
                controller.selectDate = Date()
            }
        }
        controller.data = []
        controller.timeLength = 60

        present(controller, animated: false) { }
        controller.onDone({ [weak self] date in
            guard let self = self else { return }
            logger.debug("选择了时间: \(date)")
            self.startDate = date
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? AddLessonScheduleDetailDateTimeTableViewCell {
                cell.loadData(timeRange: self.timeRange, lessonTime: 60, selectDate: date)
            }
            self.currentStep = .recurrence(false)
            self.tableView.reloadData()
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? AddLessonScheduleDetailRecurrenceTableViewCell {
                cell.enableSwitch()
            }
        })
    }

    func addLessonScheduleDetailDateTimeTableViewCell(heightChanged height: CGFloat) {
        tableView.beginUpdates()
        cellHeights[1] = height
        tableView.endUpdates()
    }

    func addLessonScheduleDetailDateTimeTableViewCell(dateSelected date: TKDateTime) {
        if let time = date.convertToTimestamp() {
            lessonScheduleConfigure.startDateTime = time
            if lessonScheduleConfigure.startDateTime != 0 {
                if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? AddLessonScheduleDetailRecurrenceTableViewCell {
                    cell.enableSwitch()
                    cell.selectedDate = Date(seconds: lessonScheduleConfigure.startDateTime)
                }
                endsType.endDate = Date(seconds: time, region: .local).add(component: .month, value: 1).timeIntervalSince1970
                tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
            }
        } else {
            TKToast.show(msg: "Time you selected is wrong, try again!", style: .error)
        }
    }
}

extension SAddLessonViewController: AddLessonScheduleDetailRecurrenceTableViewCellDelegate {
    func addLessonScheduleDetailRecurrenceTableViewCell(repeatTypeChanged repeatType: TKRepeatType) {
    }

    func addLessonScheduleDetailRecurrenceTableViewCell(repeatChanged repeatDays: RepeatDays) {
        self.repeatDays = repeatDays
        currentStep = .recurrence(repeatDays.repeatType != .none)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    func addLessonScheduleDetailRecurrenceTableViewCell(heightChanged height: CGFloat) {
        tableView.beginUpdates()
        cellHeights[2] = height
        tableView.endUpdates()
    }
}
