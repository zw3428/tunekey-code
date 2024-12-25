//
//  SettingScheduleController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/6.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class BatchSettingScheduleController: TKBaseViewController {
    var mainView = UIView()
    var index: Int!
    var tableView: UITableView!
//    var nextButton: TKBlockButton!
    var parentController: NewStudentScheduleController!

    weak var delegate: BatchSettingScheduleControllerDelegate?

    var cellHeights: [CGFloat] = [73, 74, 74, 74]
    var cellCount = 1
    var recurrenceCell: AddLessonScheduleDetailRecurrenceTableViewCell?
    var lessonTypeData: TKLessonType?
    private var timeRange: TKTimeRange!
    var lessonScheduleConfigure: TKLessonScheduleConfigure = TKLessonScheduleConfigure()
    private var endsType: AddLessonScheduleDetailDoesNotEndTableViewCell.EndsType!
    private var instruments: [String: TKInstrument] = [:]

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }
}

// MARK: - View

extension BatchSettingScheduleController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        tableView = UITableView()
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 100, right: 0)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none

        tableView.register(BatchSettingLessonTypeCell.self, forCellReuseIdentifier: String(describing: BatchSettingLessonTypeCell.self))
        tableView.register(AddLessonScheduleDetailDateTimeTableViewCell.self, forCellReuseIdentifier: String(describing: AddLessonScheduleDetailDateTimeTableViewCell.self))
        tableView.register(AddLessonScheduleDetailRecurrenceTableViewCell.self, forCellReuseIdentifier: String(describing: AddLessonScheduleDetailRecurrenceTableViewCell.self))
        tableView.register(AddLessonScheduleDetailDoesNotEndTableViewCell.self, forCellReuseIdentifier: String(describing: AddLessonScheduleDetailDoesNotEndTableViewCell.self))
        mainView.addSubview(view: tableView) { make in
            make.bottom.left.right.top.equalToSuperview()
        }
    }
}

// MARK: - TableView

extension BatchSettingScheduleController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: BatchSettingLessonTypeCell.self)) as! BatchSettingLessonTypeCell
            cellHeights[indexPath.row] = cell.loadData(data: lessonTypeData, instruments: instruments)
            cell.delegate = self
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AddLessonScheduleDetailDateTimeTableViewCell.self), for: indexPath) as! AddLessonScheduleDetailDateTimeTableViewCell
            cell.selectionStyle = .none
            if timeRange != nil {
                var timeLength = 60
                if lessonTypeData != nil {
                    timeLength = lessonTypeData!.timeLength
                }
                if lessonScheduleConfigure.startDateTime > 0 {
                    cell.loadData(timeRange: timeRange, lessonTime: timeLength, selectDate: TimeUtil.changeTime(time: Double(lessonScheduleConfigure.startDateTime)))
                } else {
                    cell.loadData(timeRange: timeRange, lessonTime: timeLength, selectDate: nil)
                }
            }
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AddLessonScheduleDetailRecurrenceTableViewCell.self), for: indexPath) as! AddLessonScheduleDetailRecurrenceTableViewCell
            cellHeights[indexPath.row] = cell.cellHeight
            cell.selectionStyle = .none
            cell.delegate = self
            if lessonScheduleConfigure.startDateTime > 0 {
                cell.selectedDate = Date(seconds: lessonScheduleConfigure.startDateTime)
                cell.enableSwitch()
            } else {
                cell.selectedDate = nil
                cell.disableSwitch()
            }
            recurrenceCell = cell
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AddLessonScheduleDetailDoesNotEndTableViewCell.self), for: indexPath) as! AddLessonScheduleDetailDoesNotEndTableViewCell
            cell.delegate = self
            cell.showType(lessonType: lessonTypeData)
            if endsType != nil {
                var isEnabled: Bool = false
                if lessonScheduleConfigure.startDateTime != 0 && lessonScheduleConfigure.repeatType != .none {
                    isEnabled = true
                }
                cell.loadData(endsType: endsType, startDate: TimeUtil.changeTime(time: Double(lessonScheduleConfigure.startDateTime)).startOfDay, isEnabled: isEnabled, isOpend: lessonScheduleConfigure.endType != .none)
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: BatchSettingLessonTypeCell.self)) as! BatchSettingLessonTypeCell
            cellHeights[indexPath.row] = cell.loadData(data: lessonTypeData, instruments: instruments)
            cell.delegate = self
            return cell
        }
    }
}

// MARK: - Data

extension BatchSettingScheduleController {
    override func initData() {
        loadAllInstruments()
        endsType = AddLessonScheduleDetailDoesNotEndTableViewCell.EndsType()
        endsType.endType = .none
        endsType.endCount = 10
        let currentDate = Date()
        endsType.endDate = currentDate.add(component: .month, value: 1).timeIntervalSince1970
        timeRange = TKTimeRange.getDefault()
        if cellCount > 1 {
            tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        }
    }
    
    private func loadAllInstruments() {
        InstrumentService.shared.loadAllInstruments()
            .done { instruments in
                instruments.forEach { instrument in
                    self.instruments[instrument.id.description] = instrument
                }
                self.tableView.reloadData()
            }
            .catch { error in
                logger.error("获取乐器失败: \(error)")
            }
    }
}

// MARK: - Action

extension BatchSettingScheduleController: BatchSettingLessonTypeCellDelegate, TypeLessonViewControllerDelegate, AddLessonScheduleDetailDateTimeTableViewCellDelegate, AddLessonScheduleDetailRecurrenceTableViewCellDelegate, AddLessonScheduleDetailDoesNotEndTableViewCellDelegate {
    // MARK: - LessonType 相关-------------------------------

    func typeLessonViewController(didSelected lessonType: TKLessonType) {
        lessonTypeData = lessonType
        lessonScheduleConfigure.lessonTypeId = lessonType.id
        lessonScheduleConfigure.teacherId = lessonType.teacherId
        lessonScheduleConfigure.startDateTime = 0
        if lessonType.package > 0 {
            lessonScheduleConfigure.endType  = .endAfterSometimes
            lessonScheduleConfigure.endCount = lessonType.package
            endsType.endType = .endAfterSometimes
            endsType.endCount = lessonType.package
        }else{
            lessonScheduleConfigure.endType  = .none
            lessonScheduleConfigure.endCount = 10
            endsType.endType = .none
            endsType.endCount = 10
        }
        delegate?.batchSettingSchedule(dataChanged: lessonScheduleConfigure, controller: self)
        
        cellCount = 2
        tableView.reloadData()
    }

    func lessonTypeCell(cell: BatchSettingLessonTypeCell) {
        let controller = LessonTypesViewController(style: .fullScreen)
        controller.from = .profile
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.isSelector = true
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        controller.enablePanToDismiss()
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }

    // MARK: - Time 相关-------------------------------

    func addLessonScheduleDetailDateTimeTableViewCellTapped() {
        parentController.showSelectTime(lastTime: lessonScheduleConfigure.startDateTime, timeLength: lessonTypeData!.timeLength) { [weak self] date in
            guard let self = self else { return }
            self.lessonScheduleConfigure.startDateTime = TimeInterval(date.timestamp)
            self.endsType.endDate = Date(seconds: TimeInterval(date.timestamp), region: .local).add(component: .month, value: 1).timeIntervalSince1970
            self.cellCount = 3
            self.tableView.reloadData()
            if let cell = self.recurrenceCell {
                cell.enableSwitch()
                cell.selectedDate = Date(seconds: self.lessonScheduleConfigure.startDateTime)
                cell.resetData()
            }
            self.delegate?.batchSettingSchedule(dataChanged: self.lessonScheduleConfigure, controller: self)
        }
    }

    func addLessonScheduleDetailDateTimeTableViewCell(heightChanged height: CGFloat) {
        SL.Executor.runAsync { [weak self] in
            guard let self = self else { return }
            self.tableView.beginUpdates()
            self.cellHeights[1] = height
            self.tableView.endUpdates()
        }
    }

    func addLessonScheduleDetailDateTimeTableViewCell(dateSelected date: TKDateTime) {
        if let time = date.convertToTimestamp() {
            lessonScheduleConfigure.startDateTime = time
            endsType.endDate = Date(seconds: time, region: .local).timeIntervalSince1970

            if lessonScheduleConfigure.startDateTime != 0 {
                cellCount = 3
                tableView.reloadData()
                if let cell = recurrenceCell {
                    cell.enableSwitch()
                    cell.selectedDate = Date(seconds: lessonScheduleConfigure.startDateTime)
                    cell.resetData()
                }
            }
            delegate?.batchSettingSchedule(dataChanged: lessonScheduleConfigure, controller: self)

        } else {
            TKToast.show(msg: "Time you selected is wrong, try again", style: .error)
        }
    }

    // MARK: - Recurrence 相关-------------------------------

    func addLessonScheduleDetailRecurrenceTableViewCell(repeatTypeChanged repeatType: TKRepeatType) {
    }

    func addLessonScheduleDetailRecurrenceTableViewCell(repeatChanged repeatDays: RepeatDays) {
        lessonScheduleConfigure.repeatType = repeatDays.repeatType

        lessonScheduleConfigure.repeatTypeWeekDay = repeatDays.repeatTypeWeekDay
        lessonScheduleConfigure.repeatTypeMonthDayType = repeatDays.repeatTypeMonthDayType
        lessonScheduleConfigure.repeatTypeMonthDay = repeatDays.repeatTypeMonthDay
        delegate?.batchSettingSchedule(dataChanged: lessonScheduleConfigure, controller: self)

        if repeatDays.repeatType == .none {
            cellCount = 3
            tableView.reloadData()
        } else {
            if cellCount == 4 {
//                tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .none)
            } else {
                cellCount = 4
                tableView.reloadData()
            }
        }
    }

    func addLessonScheduleDetailRecurrenceTableViewCell(heightChanged height: CGFloat) {
        SL.Executor.runAsync { [weak self] in
            guard let self = self else { return }
            self.tableView.beginUpdates()
            self.cellHeights[2] = height
            self.tableView.endUpdates()
        }
    }

    // MARK: - End 相关-------------------------------

    func addLessonScheduleDetailDoesNotEndTableViewCell(isOnChanged isOn: Bool) {
        logger.debug("does not end isOn: \(isOn)")
        if isOn {
            endsType.endType = .endAtSomeday
        } else {
            endsType.endType = .none
        }
    }

    func addLessonScheduleDetailDoesNotEndTableViewCell(dataChanged: AddLessonScheduleDetailDoesNotEndTableViewCell.EndsType) {
        //        let tkDate = value as! TKDate
        //            let dfmatter = DateFormatter()
        //            dfmatter.dateFormat = GlobalFields.dateFormat
        //            let endOnSomeDayDateString = dfmatter.string(from: tkDate.toString().toDate("YYYY-MM-dd", region: .local)!.date)
        //            logger.debug("======\(endOnSomeDayDateString)===\(tkDate.toString())===\(tkDate.toString().toDate("YYYY-MM-dd", region: .local)!.timeIntervalSince1970)")
        logger.debug(dataChanged.toJSONString(prettyPrint: true) ?? "")
        lessonScheduleConfigure.endType = dataChanged.endType
        lessonScheduleConfigure.endDate = dataChanged.endDate
        lessonScheduleConfigure.endCount = dataChanged.endCount
        delegate?.batchSettingSchedule(dataChanged: lessonScheduleConfigure, controller: self)
    }

    func addLessonScheduleDetailDoesNotEndTableViewCell(heightChanged height: CGFloat) {
        SL.Executor.runAsync { [weak self] in
            guard let self = self else { return }
            self.tableView.beginUpdates()
            self.cellHeights[3] = height
            self.tableView.endUpdates()
        }
    }
}

protocol BatchSettingScheduleControllerDelegate: NSObjectProtocol {
//    func batchSettingSchedule(editLessonType lessonType: TKLessonType, index: Int)
//    func batchSettingSchedule(editScheduleConfigure timer: TKLessonScheduleConfigure, endData: AddLessonScheduleDetailDoesNotEndTableViewCell.EndsType, index: Int)
    func batchSettingSchedule(dataChanged data: TKLessonScheduleConfigure, controller: BatchSettingScheduleController)
}
