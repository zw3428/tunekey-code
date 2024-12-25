//
//  TRecheduleController.swift
//  TuneKey
//  老师Rechedule 的页面
//  Created by WHT on 2020/3/16.
//  Copyright © 2020 spelist. All rights reserved.
//

import FirebaseFirestore
import FirebaseFunctions
import RxSwift
import UIKit

class TRecheduleController: TKBaseViewController {
    enum Mode {
        case reschedule
        case cancellation
    }

    private var mainView = UIView()
    private var navigationBar: TKNormalNavigationBar!
    private var nextButton: TKBlockButton!
    var defualSelectIndex = 0
    private var tableView: UITableView!
    private var tableViewData = BehaviorRelay(value: [TKLessonSchedule]())
    // 上一页选择的lesosn
    var data: [TKLessonSchedule] = []
    private var df = DateFormatter()

    var mode: Mode
    init(_ mode: Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View

extension TRecheduleController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        let title: String
        let buttonTitle: String
        switch mode {
        case .cancellation:
            title = "Cancel lesson"
            buttonTitle = "CANCEL LESSON"
        case .reschedule:
            title = "Reschedule"
            buttonTitle = "RESCHEDULE"
        }

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: title, target: self)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initTableview()
        nextButton = TKBlockButton(frame: .zero, title: buttonTitle)
        mainView.addSubview(view: nextButton) { make in
            make.height.equalTo(50)
            make.width.equalTo(180)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
        nextButton.disable()
        nextButton.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.clickNext()
        }
    }

    func initTableview() {
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView!.register(RecheduleSelectStudentCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 90, right: 0)
        let radiuView = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
            .addTo(superView: mainView) { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(navigationBar.snp.bottom).offset(20)
                make.bottom.equalToSuperview()
            }
        radiuView.setTopRadius()
        radiuView.addSubview(view: tableView) { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        addSubscribe(
            tableViewData.bind(to: tableView.rx.items) { [weak self] tableView, index, data in
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! RecheduleSelectStudentCell
                cell.tag = index
                if let self = self {
                    cell.initData(data: data, df: self.df)
                    cell.delegate = self
                }
                return cell
            }
        )
    }
}

// MARK: - Data

extension TRecheduleController {
    override func initData() {
        df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a, MMM d" : "HH:mm MMM d"
        data[defualSelectIndex].studentData!._isSelect = true
        nextButton.enable()
        tableViewData.accept(data)
    }

    func reschedule(isToBolock: Bool, msg: String, afterTime: String = "") {
        showFullScreenLoadingNoAutoHide()
        var selectLesson: [TKLessonSchedule] = []
        var reschedules: [TKReschedule] = []
        let time = "\(Date().timestamp)"
        for item in data where item.studentData!._isSelect {
            selectLesson.append(item)
            let reschedule = TKReschedule()
            reschedule.id = item.id
            reschedule.teacherId = item.teacherId
            reschedule.studentId = item.studentId
            reschedule.scheduleId = item.id
            reschedule.shouldTimeLength = item.shouldTimeLength
            reschedule.senderId = item.teacherId
            reschedule.confirmerId = item.studentId
            reschedule.confirmType = .unconfirmed
            reschedule.timeBefore = "\(item.shouldDateTime)"
            reschedule.timeAfter = afterTime
            reschedule.createTime = time
            reschedule.updateTime = time
            reschedules.append(reschedule)
        }
        addSubscribe(
            LessonService.lessonSchedule.reschedule(schedule: selectLesson, reschedule: reschedules, msg: msg)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    print("reschedule 成功 ")
                    self.hideFullScreenLoading()
                    if isToBolock {
                        if let p = self.presentingViewController!.presentingViewController {
                            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: {
                                let controller = AddBlockController()
                                controller.modalPresentationStyle = .fullScreen
                                controller.hero.isEnabled = true
                                controller.enablePanToDismiss()
                                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                                p.present(controller, animated: true, completion: nil)
                            })
                        }
                    } else {
                        OperationQueue.main.addOperation {
                            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: {
                                TKToast.show(msg: "Rescheduled successfully!", style: .success)
                            })
                        }
                    }

                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    let error = err as NSError
                    if error.code == 0 {
                        if let reschedule = TKReschedule.deserialize(from: error.domain) {
                            var userId = ""
                            if let uid = UserService.user.id() {
                                if reschedule.teacherId == uid {
                                    userId = reschedule.studentId
                                } else {
                                    userId = reschedule.teacherId
                                }
                            }
                            if userId != "" {
                                UserService.user.getUserInfo(id: userId)
                                    .done { user in
                                        self.hideFullScreenLoading()
                                        TKAlert.show(target: self, title: "Something wrong", message: TipMsg.updatingLessonAndTryLater(name: user.name), buttonString: "SEE UPDATE") {
                                        }
                                    }
                                    .catch { _ in
                                        self.hideFullScreenLoading()
                                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                                    }
                                return
                            }
                        }
                    } else if error.code == 1 {
                        self.hideFullScreenLoading()
                        TKAlert.show(target: self, title: "Too late", message: TipMsg.updateLessonAndTryLaterWhenOccupieded, buttonString: "SEE UPDATE") {
                        }
                        return
                    }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                })
        )
    }


    private func selectTime() {
        var selectData: TKLessonSchedule!
        for item in data where item.studentData!._isSelect {
            selectData = item
        }
        var reschedulesData: [TKReschedule] = []
        if SLCache.main.getString(key: "\(UserService.user.id() ?? "tunekey"):\(SLCache.RESCHEDULE_DATA)") != "" {
            if let localData = [TKReschedule].deserialize(from: SLCache.main.getString(key: "\(UserService.user.id() ?? "tunekey"):\(SLCache.RESCHEDULE_DATA)")) as? [TKReschedule], localData.count > 0 {
                reschedulesData = localData
            }
        }
        logger.debug("要传递的reschedule数据: \(reschedulesData.toJSONString() ?? "")")
        let controller = TKPopTeacherAvailableTimeController()
        controller.modalPresentationStyle = .custom
        controller.selectDate = Date(seconds: selectData.shouldDateTime)
        controller.selectedLessonData = [selectData]
        controller.rescheduleData = reschedulesData
        controller.timeLength = selectData.shouldTimeLength
        present(controller, animated: false, completion: nil)
        controller.onDone { [weak self] date in
            guard let self = self else { return }
            OperationQueue.main.addOperation { [weak self] in
                guard let self = self else { return }
                self.showFullScreenLoadingNoAutoHide()
                TimeUtil.getTimeForRescheduleTimeSelector(localSelectedTime: date.timeIntervalSince1970, lessonConfigId: selectData.lessonScheduleConfigId)
                    .done { dateTimestamp in
                        self.hideFullScreenLoading()
                        self.sendMessonAction(afterTime: "\(dateTimestamp)")
                    }
                    .catch { error in
                        logger.error("获取reschedule时间失败: \(error)")
                        self.hideFullScreenLoading()
                    }
            }
        }
    }

    enum RescheduleType: String {
        case thisLesson = "THIS_LESSON"
        case thisAndFollowingLessons = "THIS_AND_FOLLOWING_LESSONS"
        case allLessons = "ALL_LESSONS"
    }

    private func selectRescheduleLessons(completion: @escaping (RescheduleType) -> Void) {
        TKPopAction.show(
            items: [
                .init(title: "This lesson") {
                    completion(.thisLesson)
                },
                .init(title: "This & following lessons") {
                    completion(.thisAndFollowingLessons)
                },
                .init(title: "All lessons") {
                    completion(.allLessons)
                },
            ],
            target: self)
    }

    private func reschedule(with rescheduleType: RescheduleType, newTime: TimeInterval, lessonSchedule: TKLessonSchedule) {
        guard rescheduleType != .thisLesson else { return }
        showFullScreenLoadingNoAutoHide()
        Functions.functions().httpsCallable("lessonService-rescheduleLessonsWithType")
            .call([
                "rescheduleType": rescheduleType.rawValue,
                "newTime": newTime,
                "scheduleConfigId": lessonSchedule.lessonScheduleConfigId,
                "selectedLessonScheduleId": lessonSchedule.id,
            ]) { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("发生错误: \(error)")
                    TKToast.show(msg: "Reschedule wrong, please try again later.", style: .error)
                } else {
                    DispatchQueue.main.async {
                        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: {
                            TKToast.show(msg: "Rescheduled successfully!", style: .success)
                        })
                    }
                }
            }
    }
}

// MARK: - TableView

extension TRecheduleController: RecheduleSelectStudentCellDelegate {
    func clickCell(cell: RecheduleSelectStudentCell) {
        var isSelect = false
        for item in data.enumerated() {
            if cell.tag == item.offset {
                data[item.offset].studentData!._isSelect = !data[item.offset].studentData!._isSelect
            }
            if !isSelect && data[item.offset].studentData!._isSelect {
                isSelect = true
            }
        }
        tableViewData.accept(data)

        if isSelect {
            nextButton.enable()
        } else {
            nextButton.disable()
        }
    }
}

// MARK: - Action

extension TRecheduleController {
    func clickNext() {
        logger.debug("点击下一步按钮")
        switch mode {
        case .cancellation:
            let controller = SL.SLAlert()
            controller.modalPresentationStyle = .custom
            controller.titleString = "Cancel lesson?"
            controller.rightButtonColor = ColorUtil.main
            controller.leftButtonColor = ColorUtil.red
            controller.rightButtonString = "GO BACK"
            controller.leftButtonString = "CANCEL ANYWAYS"
            controller.leftButtonAction = {
                [weak self] in
                guard let self = self else { return }
                self.cancelLessons()
            }
            controller.rightButtonAction = {
            }
            controller.messageString = ""
            controller.leftButtonFont = FontUtil.bold(size: 13)
            controller.rightButtonFont = FontUtil.bold(size: 13)
            present(controller, animated: false, completion: nil)
        case .reschedule:
            var count = 0
            for item in data where item.studentData!._isSelect {
                count += 1
            }
            if count == 1 {
//                selectTime()
                showDateTimeAndLocationSelectorView()
            } else {
                sendMessonAction()
            }
        }
    }

    func cancelLessons() {
        var selectLesson: [TKLessonSchedule] = []
        var cancellationData: [TKLessonCancellation] = []
        let time = "\(Date().timestamp)"
        for item in data where item.studentData!._isSelect {
            selectLesson.append(item)
            let cancellationDataItem: TKLessonCancellation = .init()
            cancellationDataItem.id = item.id
            cancellationDataItem.oldScheduleId = item.id
            cancellationDataItem.type = .noRefundAndMakeup
            cancellationDataItem.studentId = item.studentId
            cancellationDataItem.teacherId = item.teacherId
            cancellationDataItem.timeBefore = item.shouldDateTime.description
            cancellationDataItem.createTime = time
            cancellationDataItem.updateTime = time
        }
    }

    /// 弹出发送消息的弹窗
    func sendMessonAction(afterTime: String = "") {
        let isConfirmNowHidden = self.data.filter({ $0.studentData!._isSelect }).count > 1
        logger.debug("是否隐藏confirmNow: \(isConfirmNowHidden)")
        TKPopAction.showSendMessage(target: self, titleString: "Message to students(optional)", leftButtonString: "CANCEL", rightButtonString: "SEND REQUEST", isConfirmNowHidden: isConfirmNowHidden) { [weak self] message in
            guard let self = self else { return }
//            self.reschedule(isToBolock: false, msg: message, afterTime: afterTime)
//            self.sendRescheduleV2(msg: message, afterTime: TimeInterval(afterTime) ?? 0)
            self.reschedule(isToBolock: false, msg: message, afterTime: afterTime)
        } onConfirmTapped: { [weak self] message in
            guard let self = self else { return }
            logger.debug("on confirm tapped: \(afterTime)")
            guard afterTime != "" else { return }
            logger.debug("time开始")
            guard let doubleTime = Double(afterTime) else { return }
            let time = Int(doubleTime)
            logger.debug("time结束")
            guard let lessonSchedule = self.data.first(where: { $0.studentData!._isSelect }) else {
                logger.debug("未选择lessonSchedule: \(self.data.compactMap({ $0.studentData!._isSelect }))")
                return
            }
            logger.debug("开始")
            self.showFullScreenLoadingNoAutoHide()
            Functions.functions().httpsCallable("scheduleService-confirmRescheduleDirectlly")
                .call(["lessonScheduleId": lessonSchedule.id, "timeAfter": time]) {result, error in
                    self.hideFullScreenLoading()
                    if let error = error {
                        TKToast.show(msg: "Reschedule failed, please try again later.", style: .error)
                        logger.error("reschedule 失败:\(error)")
                    } else {
                        DispatchQueue.main.async {
                            EventBus.send(key: .teacherLessonChanged)
                            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: {
                                TKToast.show(msg: "Rescheduled successfully!", style: .success)
                            })
                        }
                    }
                }
        }
    }

    /// 弹出选择方式的弹窗
    func selectAction() {
        TKPopAction.show(items: [TKPopAction.Item(title: "Only this lesson", action: { [weak self] in
                guard let self = self else { return }
                self.sendMessonAction()
            }),
            TKPopAction.Item(title: "All the upcoming", action: { [weak self] in
                guard let self = self else { return }
                self.modifyAllLessonAction()
            })], target: self)
    }

    // 修改schedule
    func modifyAllLessonAction() {
        var studentData: TKStudent!
        var schedule: TKLessonScheduleConfigure!

        for item in data where item.studentData!._isSelect {
            studentData = item.studentData!
            schedule = item.lessonScheduleData
            schedule.lessonType = item.lessonTypeData
        }

        let controller = AddLessonDetailController(studentData: studentData, isReschedule: true)
        controller.hero.isEnabled = true
        controller.oldScheduleConfig = schedule
        controller.rescheduleStartTime = Date().startOfDay.timestamp
        controller.isReschedule = true
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func showDateTimeAndLocationSelectorView() {
        let controller = StudioDateTimeAndLocationSelectorViewController()
        controller.onSelected = { [weak self] time, location in
            guard let self = self else { return }
            controller.dismiss(animated: true)
            self.sendRescheduleV2(msg: "", newTime: time, location: location)
        }
        present(controller, animated: true)
    }
    
    func sendRescheduleV2(msg: String, newTime: TimeInterval, location: TKLocation?) {
        guard let lessonSchedule = data.first else { return }
        showFullScreenLoadingNoAutoHide()
        Functions.functions().httpsCallable("scheduleService-sendReschedule")
            .call([
                "studioId": lessonSchedule.studioId,
                "subStudioId": lessonSchedule.subStudioId,
                "newTime": newTime,
                "newLocation": location?.toJSON() ?? [:],
                "newTeacherId": "",
                "lessonScheduleId": lessonSchedule.id,
            ]) { [weak self] _, error in
                guard let self = self else { return }
                if let error = error {
                    logger.error("发起reschedule失败: \(error)")
                    self.hideFullScreenLoading()
                } else {
                    self.hideFullScreenLoading()
                    OperationQueue.main.addOperation {
                        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: {
                            TKToast.show(msg: "Rescheduled successfully!", style: .success)
                        })
                    }
                }
            }
    }
}
