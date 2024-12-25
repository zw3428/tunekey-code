//
//  LessonManagerViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/5.
//  Copyright © 2019年 spelist. All rights reserved.
//

import EventKit
import FirebaseFirestore
import FirebaseFunctions
import FSCalendar
import NVActivityIndicatorView
import PromiseKit
import SwiftDate
import SwiftEventBus
import UIKit

class LessonsViewController: TKBaseViewController {
    enum ScrollDirection {
        case pre
        case next
    }

    private let eventStore = EKEventStore()
    private var emptyView: UIView!
    private var emptyImageView: UIImageView!
    private var emptyLabel: UILabel!
    private var emptyButton: TKBlockButton!
    private var containerView: TKView!
    var contentView: TKView!

    private var navigationBar: TKView!
    private var loadingView: NVActivityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: ColorUtil.main, padding: 0)
    private var filterButton: TKButton!
    private var monthSelectIcon: TKImageView!
    private var monthSelectLabel: TKLabel!
    private var titleLabel: TKLabel!
    private var filterView: LessonFilterView!
    private var countdownView: TKView = TKView.create()
        .corner(size: 30)
//    private var countdownLabel: CountdownLabel = {
//        logger.debug("已创建countdownLabel")
//        return CountdownLabel()
//    }()
    private var countdownLabel: TKCountdownLabel = TKCountdownLabel()
    private var countdownImageView: UIImageView = UIImageView()

    private var addButton: TKButton!
    private var searchButton: TKButton!

    private var weekView: TKCalendarWeekView!
    var monthView: FSCalendar!
    private var calendarDisplayType: TKCalendarDisplayType = .month
    var agendaTableView: UITableView!

    var rescheduleAndMakeUpBackView: TKView!
    var rescheduleAndMakeUpView: TKView!
    var rescheduleAndMakeUpTableView: UITableView!
    var rescheduleAndMakeUpCallapseLabel: TKLabel!
    var rescheduleAndMakeUpMessageView: TKView!
    var rescheduleAndMakeUpMessageCountLabel: TKLabel!
    var rescheduleAndMakeUpMessageTieleLabel: TKLabel!

    // 用来存储每节课的开始时间 //以便于日历小绿点显示
    private var lessonStartDayTimeMap: [Int: Int] = [:]
    private var googleCalendarEventTimeMap: [Int: Int] = [:]
    private var appleCalendarEventTimeMap: [Int: Int] = [:]

    private var oldOffset: CGPoint = .zero
    private var isTranscation: Bool = false

    private var cellHeights: [CGFloat] = [100]

    private let dateFormatter = DateFormatter()

    private var scheduleConfigs: [TKLessonScheduleConfigure] = []
    private var lessonTypes: [TKLessonType]!
    private var currentSelectTimestamp = 0
    private var startTimestamp = 0
    private var endTimestamp = 0
    // 所有已经获取了的时间范围
    private var timeLeftTimestamp = 0
    private var timeRightTimestamp = 0

    private var scrollDirection: ScrollDirection?

    private var lessonScheduleListener: ListenerRegistration?

    // 全部获取的日程
    var lessonSchedule: [TKLessonSchedule] = []

    // weekView 所需要的Data
    private var weekLessonSchedule: [DefaultEvent] = []

    // 当前天的日程
//    private var currentLessonSchedule: [TKLessonSchedule] = []

    /// 按照天来分割的日程数据

    private var lessonScheduleByDay: [String: [TKLessonSchedule]] = [:]

    // 以获取月份
    private var blockData: [TKBlock] = []

    private var eventConfig: [TKEventConfigure] = []

    // 用来存储已经存到本地的lesson
    private var lessonScheduleIdMap: [String: TKLessonSchedule] = [:]
    // 当前时间段的时间
    private var currentMonthDate: Date!
    // 上一个选择的时间段开始时间
    private var previousStartDate: Date!
    // 上一个选择的时间段结束时间
    private var previousEndDate: Date!
    var rescheduleTableViewData = BehaviorRelay(value: [TKReschedule]())
    var toDayDate = Date().startOfDay
    var isScrolling: Bool! = false
    private var filterViewTimer: Timer?
    private var nextLessonTimer: Timer?

    private var weekSelectDate: Date! = Date()
    private var isHaveSchedule = SLCache.main.getBool(key: "\(UserService.user.id() ?? "")_isHaveSchedule")
    var notificationConfig: TKNotificationConfig?
    var isCheckingNotifications: Bool = false

    private var lastDateForMonth: Date?
    private var lastDateForWeek: Date?

    var studentData: [String: TKStudent] = [:] {
        didSet {
//            logger.debug("学生信息设置成功: \(studentData)")
            execStudentData()
        }
    }

    var googleCalendarEvents: [GoogleCalendarEvent] = [] {
        didSet {
            initWeekData()
        }
    }

    var appleCalendarEvents: [EKEvent] = []

    var userNotifications: [TKUserNotification] = [] {
        didSet {
            // 设置了通知,判断通知的类型来刷新不同区域的数据
            logger.debug("设置了通知数据: \(userNotifications.count) | \(userNotifications.toJSONString() ?? "nil")")
            execUserNotifications()
        }
    }

    private var isFirstLoad: Bool = false

    deinit {
        logger.debug("销毁LessonsViewController")
        filterViewTimer?.invalidate()
        filterViewTimer = nil
        nextLessonTimer?.invalidate()
        nextLessonTimer = nil
        SwiftEventBus.unregister(self)
    }

    private var triggerForBlock: Bool = false {
        didSet {
            checkAllTriggers()
        }
    }

    private var triggerForLessonSchedule: Bool = false {
        didSet {
            checkAllTriggers()
        }
    }

    private var triggerForEvent: Bool = false {
        didSet {
//            checkAllTriggers()
        }
    }

    private func checkAllTriggers() {
        guard triggerForBlock && triggerForLessonSchedule else {
            return
        }
//        OperationQueue.main.addOperation { [weak self] in
//            self?.monthView?.reloadData()
//            self?.initWeekData()
//        }
    }

//    let backgroundQueue = DispatchQueue(label: "com.spelist.tunekey:LessonsViewController", attributes: .concurrent)
    var backgroundQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = 10
        return queue
    }()
}

extension LessonsViewController {
    private func execStudentData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let data = self.rescheduleTableViewData.value
            for item in data.enumerated() {
                let studentId = item.element.studentId
                if studentId != "" {
                    if let student = self.studentData[studentId] {
                        data[item.offset].studentData = student
                    }
                }
            }
            self.rescheduleTableViewData.accept(data)

            for item in self.lessonSchedule.enumerated() {
                let studentId = item.element.studentId
                if studentId != "" {
                    if let student = self.studentData[studentId] {
                        self.lessonSchedule[item.offset].studentData = student
                    }
                }
            }
            self.lessonScheduleByDay.forEach { day, lessons in
                for item in lessons.enumerated() {
                    let studentId = item.element.studentId
                    if studentId != "" {
                        let student = self.studentData[studentId]
                        if let _student = student {
                            self.lessonScheduleByDay[day]?[item.offset].studentData = _student
                        }
                    }
                }
            }
        }
    }
}

/// 处理通知数据
extension LessonsViewController {
    private func execUserNotifications() {
        guard let uid = UserService.user.id() else { return }
        var data: [TKReschedule] = []
        var newMsg: Bool = false
        userNotifications.forEach { notification in
            if !newMsg {
                if notification.senderId != uid && notification.senderId != "" {
                    newMsg = true
                }
            }
            switch notification.category {
            case .rescheduleRequest, .rescheduleRequestConfirm, .rescheduleRetract:
                let dataString = notification.data
                if let reschedule: TKReschedule = TKReschedule.deserialize(from: dataString) {
                    if let studentData = studentData[reschedule.studentId] {
                        reschedule.studentData = studentData
                    }
                    data.append(reschedule)
                }
            case .scheduleCancelation, .scheduleCancelationConfirm:
                // 转换成TKReschedule对象
                if let cancelation: TKLessonCancellation = TKLessonCancellation.deserialize(from: notification.data) {
                    let reschedule = cancelation.convertToReschedule()
                    if let studentData = studentData[cancelation.studentId] {
                        reschedule.studentData = studentData
                    }
                    data.append(reschedule)
                }
                break
            default: break
            }
        }
        if newMsg {
            Tools.alert()
        }
        SLCache.main.set(key: "\(UserService.user.id() ?? "tunekey"):\(SLCache.RESCHEDULE_DATA)", value: data.toJSONString() ?? "")
        rescheduleTableViewData.accept(data)
//        UIApplication.shared.applicationIconBadgeNumber = data.count
        updateRescheduleAndMakeUpView()
        reloadData()
//        monthView?.reloadData()
    }

    func updateRescheduleAndMakeUpView() {
        logger.debug("刷新updateRescheduleAndMakeUpView")
        let data = rescheduleTableViewData.value
        var isHaveReschedule = false // 判断是否有reschedule
        for item in data where !item.isCancelLesson {
            isHaveReschedule = true
            break
        }
        if data.count > 0 {
            if isHaveReschedule {
                rescheduleAndMakeUpMessageTieleLabel?.text("Reschedule request")
            } else {
                rescheduleAndMakeUpMessageTieleLabel?.text("Cancellation")
            }
            rescheduleAndMakeUpMessageView?.isHidden = false
            rescheduleAndMakeUpMessageCountLabel?.text("\(data.count)")
            agendaTableView?.snp.updateConstraints { make in
                make.top.equalTo(rescheduleAndMakeUpMessageView.snp.bottom).offset(10)
            }
            if calendarDisplayType == .month {
                rescheduleAndMakeUpMessageView?.snp.remakeConstraints { make in
                    make.top.equalTo(monthView.snp.bottom)
                    make.left.equalTo(20)
                    make.right.equalTo(-20)
                    make.height.equalTo(60)
                }
            } else {
                rescheduleAndMakeUpMessageView?.snp.remakeConstraints { make in
                    make.top.equalTo(76)
                    make.left.equalTo(62)
                    make.right.equalTo(-20)
                    make.height.equalTo(60)
                }
            }
        } else {
            rescheduleAndMakeUpMessageView?.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            agendaTableView?.snp.updateConstraints { make in
                make.top.equalTo(rescheduleAndMakeUpMessageView.snp.bottom).offset(0)
            }
            rescheduleAndMakeUpMessageView?.isHidden = true
        }
    }
}

extension LessonsViewController {
    override func initView() {
        view.backgroundColor = ColorUtil.backgroundColor
        initContainerView()
        initEmptyView()
        initListenerForNotification()
        initListener()
        initCountdownView()
    }

    private func checkCountdownGuide() {
        let count: Int64 = SLCache.main.get(key: "tunekey:lessons:countdown_guide:showdCount")
        if count >= 3 {
            countdownImageView.isHidden = true
        } else {
            countdownImageView.isHidden = false
        }
    }

    private func initCountdownView() {
        containerView.addSubview(view: countdownView) { make in
            make.bottom.equalToSuperview().offset(-50)
            make.right.equalTo(-20)
            make.size.equalTo(60)
        }
        countdownView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        let font = UIFont(name: "HelveticaNeue-Bold", size: 18)
//        countdownLabel.height = 19.072
        countdownLabel.font = font
//        countdownLabel.animationType = .Evaporate
//        countdownLabel.timeFormat = "hh:mm:ss"
        countdownLabel.textColor = UIColor.white
        countdownLabel.textAlignment = .center
        countdownView.isHidden = true
        countdownView.addSubview(view: countdownLabel) { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        countdownLabel.countdownDelegate = self
        countdownView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.countdownView.isHidden = true
            self.countdownImageView.isHidden = true
            let controller = CountdownController()
            guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            appdelegate.isShowFullScreenCuntdown = true
            controller.modalPresentationStyle = .custom
            PresentTransition.presentWithAnimate(fromVC: self, toVC: controller)
        }

        guard let path = Bundle.main.path(forResource: "Tap", ofType: "gif") else { return }
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { return }
        let image = UIImage.sd_image(withGIFData: data)
        countdownImageView.addTo(superView: countdownView, withConstraints: { make in
            make.centerX.equalToSuperview().offset(10)
            make.centerY.equalToSuperview().offset(30)
            make.size.equalTo(60)
        })
        countdownImageView.image = image
        countdownImageView.startAnimating()
        countdownImageView.animationDuration = 2
        countdownImageView.animationRepeatCount = 999999
        countdownImageView.isHidden = true
        countdownImageView.transform = .init(rotationAngle: -(.pi * 0.2))
    }

    private func initEmptyView() {
        emptyView = UIView()
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(51)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        emptyView.isHidden = true

        emptyImageView = UIImageView(image: UIImage(named: "lesson_empty")!)
        emptyView.addSubview(emptyImageView)
        emptyImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(253)
            make.height.equalTo(200)
        }

        emptyLabel = UILabel()
        emptyLabel.text = "Add your lessons in minutes.\n It's easy, we promise!"
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = ColorUtil.Font.primary
        emptyLabel.changeLabelRowSpace(lineSpace: 0.8, wordSpace: 0.89)
        emptyLabel.font = FontUtil.bold(size: 16)
        emptyLabel.textAlignment = .center
        emptyView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyImageView.snp.bottom).offset(28)
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.height.equalTo(40)
        }

        emptyButton = TKBlockButton(frame: CGRect.zero, title: "ADD LESSON")
        emptyButton.onTapped { [weak self] _ in
            self?.showAddPop()
        }
        emptyView.addSubview(emptyButton)
        emptyButton.snp.makeConstraints { make in
//            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(50)
            print("===sdsdsd==\(UIScreen.main.bounds.height)")
            if UIScreen.main.bounds.height > 670 {
                make.top.equalTo(emptyLabel.snp.bottom).offset(120)
            } else {
                make.top.equalTo(emptyLabel.snp.bottom).offset(65)
            }
        }
    }

    private func initContainerView() {
        containerView = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        initNavigationBar()
        initContentView()
        initCalendar()
        initRescheduleAndMakeUpMessageView()

        initAgendaTableView()
        initRescheduleView()
        let calendarViewType = SLCache.main.getString(key: SLCache.CALENDAR_VIEW)
        if let calendarViewType = Int(calendarViewType) {
            calendarDisplayType = TKCalendarDisplayType(rawValue: calendarViewType)!
        }
        let d = Date()
        monthView.select(d)

        previousStartDate = TimeUtil.startOfMonth(date: d)
        previousEndDate = TimeUtil.endOfMonth(date: d)
        currentMonthDate = TimeUtil.startOfMonth(date: d)
        currentSelectTimestamp = monthView?.selectedDate?.timestamp ?? d.timestamp
        startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -2)).timestamp
        endTimestamp = TimeUtil.endOfMonth(date: d.add(component: .month, value: 6)).timestamp
        filterView.clickView(type: calendarDisplayType)

//        updateCalendar()
    }

    private func initNavigationBar() {
        navigationBar = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
        containerView.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        let imageName: String
        switch calendarDisplayType {
        case .month:
            imageName = "ic_calendar_month"
        case .day:
            imageName = "ic_calendar_1day"
        case .threeDays:
            imageName = "ic_calendar_3day"
        case .week:
            imageName = "ic_calendar_7day"
        }
        filterButton = TKButton.create()
//            .title(title: "View")
            .setImage(name: imageName, size: CGSize(width: 22, height: 22))
            .titleColor(color: ColorUtil.main)
            .titleFont(font: FontUtil.bold(size: 13))
        filterButton.onTapped { [weak self] _ in
            logger.debug("filter tapped")
            guard let self = self else { return }
//            self?.filterTapped()
            self.filterViewTimer?.invalidate()
            self.filterViewTimer = nil
            self.filterView.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.filterView.transform = CGAffineTransform.identity
            }

            self.filterViewTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { _ in
                if self.filterView?.isHidden ?? false {
                    SL.Animator.run(time: 0.3, animation: { [weak self] in
                        print("=====我要隐藏了")
                        self?.filterView?.transform = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
                    }) { _ in
                        self.filterView?.isHidden = true
                        self.filterViewTimer?.invalidate()
                        self.filterViewTimer = nil
                    }
                }
            })
        }
        navigationBar.addSubview(filterButton)
        filterButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(4)
            make.height.equalTo(22)
            make.left.equalToSuperview().offset(20)
        }

        monthSelectLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.main)
            .alignment(alignment: .center)
        monthSelectLabel.numberOfLines = 1
        monthSelectLabel.isHidden = true
        weak var weakself = self
        monthSelectLabel.addGestureRecognizer(UITapGestureRecognizer(target: weakself, action: #selector(monthSelectTapped(_:))))
        monthSelectLabel.isUserInteractionEnabled = true
        navigationBar.addSubview(monthSelectLabel)
        monthSelectLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(4)
            make.left.equalTo(filterButton.snp.right).offset(10)
        }

        monthSelectIcon = TKImageView.create()
//            .setImage(name: "icArrowDown")
//            .setSize(0)
        monthSelectIcon.addGestureRecognizer(UITapGestureRecognizer(target: weakself, action: #selector(monthSelectTapped(_:))))
        monthSelectIcon.isUserInteractionEnabled = true
        navigationBar.addSubview(monthSelectIcon)
        monthSelectIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(4)
            make.left.equalTo(monthSelectLabel.snp.right).offset(1)
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .text(text: "Lessons")
            .textColor(color: ColorUtil.Font.fourth)
            .alignment(alignment: .center)
        navigationBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(4)
        }

        loadingView.startAnimating()
        navigationBar.addSubview(view: loadingView) { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.left.equalTo(titleLabel.snp.right).offset(2)
            make.size.equalTo(18)
        }

        let doubleTapGesture = UITapGestureRecognizer(target: weakself, action: #selector(onDoubleTapped(_:)))
        doubleTapGesture.numberOfTouchesRequired = 1
        doubleTapGesture.numberOfTapsRequired = 2
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(doubleTapGesture)

        searchButton = TKButton.create()
            .setImage(name: "search_primary", size: CGSize(width: 22, height: 22))
        searchButton.onTapped { [weak self] _ in
            guard let self = self, self.scheduleConfigs != nil else { return }
            let controller = LessonSearchController(data: self.scheduleConfigs, eventDatas: self.eventConfig)
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.enablePanToDismiss()
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            self.present(controller, animated: true, completion: nil)
        }
        navigationBar.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(22)
            make.height.equalTo(22)
        }

        addButton = TKButton.create()
            .setImage(name: "icAddPrimary", size: CGSize(width: 22, height: 22))
        addButton.onTapped { [weak self] _ in
            logger.debug("add button tapped")
            self?.showAddPop()
        }
        navigationBar.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(4)
            make.right.equalTo(searchButton.snp.left).offset(-20)
            make.width.equalTo(22)
            make.height.equalTo(22)
        }
        filterView = LessonFilterView()
        filterView.isHidden = true
        containerView.addSubview(view: filterView) { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(60)
        }
        filterView.transform = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
        filterView.changeSelect = { [weak self] type in
            guard let self = self else { return }
            // 获取现在定位的日期
            var date: Date?
            if self.monthView != nil && self.weekView != nil {
                if self.calendarDisplayType == .month {
                    if !self.monthView.isHidden {
                        date = self.monthView?.selectedDate
                    }
                } else {
                    if !self.weekView.isHidden {
                        date = self.weekView.getDatesInCurrentPage(isScrolling: true).first
                        logger.debug("获取到的weekView显示的日期：\(date?.toFormat("yyyy-MM-dd") ?? "")")
                    }
                }
            }
            self.calendarDisplayType = type
            logger.debug("日历显示模式变更: \(type.rawValue)")
            self.updateCalendar()
            let imageName: String
            switch type {
            case .month:
                imageName = "ic_calendar_month"
            case .day:
                imageName = "ic_calendar_1day"
            case .threeDays:
                imageName = "ic_calendar_3day"
            case .week:
                imageName = "ic_calendar_7day"
            }
            self.filterButton.setImage(name: imageName, size: CGSize(width: 22, height: 22))
            if type == .month {
                self.rescheduleAndMakeUpMessageView.layer.opacity = 1
            } else {
                self.rescheduleAndMakeUpMessageView.layer.opacity = 0
                SL.Executor.runAsyncAfter(time: 0.5) {
                    self.showRescheduleAndMakeUpMessageView()
                }
            }
            if let currentDate = date {
                if self.calendarDisplayType == .month {
                    self.monthView.setCurrentPage(currentDate, animated: false)
                } else {
                    logger.debug("更新WeekView到日期： \(currentDate.toFormat("yyyy-MM-dd"))")
                    self.weekView.updateWeekView(to: currentDate)
                }
            }

            self.filterViewTimer?.invalidate()
            self.filterViewTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { _ in
                if self.filterView?.isHidden != true {
                    SL.Animator.run(time: 0.3, animation: { [weak self] in
                        print("=====我要隐藏了")
                        self?.filterView?.transform = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
                    }) { [weak self] _ in
                        guard let self = self else { return }
                        self.filterView?.isHidden = true
                        self.filterViewTimer?.invalidate()
                        self.filterViewTimer = nil
                    }
                }
            })
        }
        filterView.clickClose = { [weak self] in
            guard let self = self else { return }
            self.filterViewTimer?.invalidate()
            self.filterViewTimer = nil
            SL.Animator.run(time: 0.3, animation: {
                self.filterView?.transform = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
            }) { _ in
                self.filterView?.isHidden = true
            }
        }
    }

    private func initContentView() {
        contentView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        containerView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }
        contentView.isHidden = true
    }

    private func initCalendar() {
        weekView = TKCalendarWeekView()
        contentView.addSubview(weekView)
        weekView.snp.makeConstraints { make in
            make.center.size.equalToSuperview()
        }
        weekView.isHidden = true
        weekView.delegate = self
        weekView.baseDelegate = self

        monthView = FSCalendar()
        monthView.calendarWeekdayView.isHidden = true
        monthView.placeholderType = .none
        monthView.delegate = self
        monthView.dataSource = self
        contentView.addSubview(monthView)
        monthView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(300)
        }
        monthView.headerHeight = 0
        monthView.calendarHeaderView.isHidden = true
        let appearance = monthView.appearance
        appearance.weekdayTextColor = ColorUtil.Font.fourth
        appearance.weekdayFont = FontUtil.bold(size: 13)
        appearance.titleFont = FontUtil.bold(size: 20)
        appearance.titleSelectionColor = UIColor.white
        appearance.titleDefaultColor = ColorUtil.Font.third
        appearance.selectionColor = ColorUtil.main
        appearance.titleTodayColor = ColorUtil.main
        appearance.todayColor = UIColor.white
        appearance.eventDefaultColor = ColorUtil.main
        appearance.eventSelectionColor = ColorUtil.main
        appearance.borderRadius = 0.4

        let weekDayView = TKMonthViewWeekView()
        monthView.addSubview(view: weekDayView) { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(25)
        }

//        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTapped(_:)))
//        doubleTapGesture.numberOfTouchesRequired = 1
//        doubleTapGesture.numberOfTapsRequired = 2
//
//        monthView.addGestureRecognizer(doubleTapGesture)
    }

    @objc private func onDoubleTapped(_ sender: UITapGestureRecognizer) {
        EventBus.send(key: .scrollToToday)
    }

    private func initAgendaTableView() {
        agendaTableView = UITableView()
        agendaTableView.delegate = self
        agendaTableView.dataSource = self
        agendaTableView.bounces = true
        agendaTableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
//        agendaTableView.separatorColor = ColorUtil.dividingLine.withAlphaComponent(0.5)
        agendaTableView.tableFooterView = UIView()
        agendaTableView.separatorStyle = .none
        contentView.addSubview(agendaTableView)
        agendaTableView.register(LessonsCalendarAgendaTableViewCell.self, forCellReuseIdentifier: String(describing: LessonsCalendarAgendaTableViewCell.self))
        agendaTableView.snp.makeConstraints { make in
            make.top.equalTo(rescheduleAndMakeUpMessageView.snp.bottom).offset(0)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateTitle()
        forceOrientationPortrait()
        checkClassNow()
        guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appdelegate.isLessonPage = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appdelegate.isLessonPage = false
    }

    private func updateTitle() {
        guard monthView != nil, let date = monthView?.currentPage else { return }
        dateFormatter.dateFormat = "MMMM"
        monthSelectLabel.text(dateFormatter.string(from: date))
        logger.debug("当前的年份: \(date.month)")
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        guard weekView != nil else {
//            return
//        }
//        JZWeekViewHelper.viewTransitionHandler(to: size, weekView: weekView)
    }

    private func updateCalendar() {
        monthView.isHidden = true
        weekView.isHidden = true
        agendaTableView.isHidden = true
        if rescheduleTableViewData.value.count > 0 {
            rescheduleAndMakeUpMessageView.layer.opacity = 1
        }

        var numberOfDay: Int = 1
        switch calendarDisplayType {
        case .month:
            SLCache.main.set(key: SLCache.CALENDAR_VIEW, value: "30")
            monthView.isHidden = false
            agendaTableView.isHidden = false
        case .day:
            SLCache.main.set(key: SLCache.CALENDAR_VIEW, value: "1")
            numberOfDay = 1
            weekView.isHidden = false
        case .threeDays:
            SLCache.main.set(key: SLCache.CALENDAR_VIEW, value: "3")
            numberOfDay = 3
            weekView.isHidden = false
        case .week:
            SLCache.main.set(key: SLCache.CALENDAR_VIEW, value: "7")
            numberOfDay = 7
            weekView.isHidden = false
        }

        if calendarDisplayType == .month {
            rescheduleAndMakeUpMessageView.snp.remakeConstraints { make in
                make.top.equalTo(monthView.snp.bottom)
                make.left.equalTo(20)
                make.right.equalTo(-20)
                if rescheduleTableViewData.value.count > 0 {
                    make.height.equalTo(60)
                } else {
                    make.height.equalTo(0)
                }
            }
            contentView
                .showBorder(color: ColorUtil.borderColor)
                .corner(size: 10)
                .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        } else {
            contentView
                .corner(size: 0)
                .showBorder(color: .clear)

            rescheduleAndMakeUpMessageView.snp.remakeConstraints { make in
                make.top.equalTo(76)
                make.left.equalTo(62)
                make.right.equalTo(-20)
                if rescheduleTableViewData.value.count > 0 {
                    make.height.equalTo(60)
                } else {
                    make.height.equalTo(0)
                }
            }
        }
        getAppleCalendarEvents()
        reloadGoogleCalendarEvents()
        monthView?.reloadData()
        weekView?.setupCalendar(numOfDays: numberOfDay, setDate: monthView?.selectedDate ?? Date(), allEvents: JZWeekViewHelper.getIntraEventsByDate(originalEvents: weekLessonSchedule), scrollType: .pageScroll, firstDayOfWeek: .Sunday, currentTimelineType: .section, visibleTime: Date(), scrollableRange: nil)
    }
}

// MARK: - month calendar

extension LessonsViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    func calendar(_ calendar: FSCalendar, titleFor date: Date) -> String? {
        if date.day == 1 {
            dateFormatter.dateFormat = "MMM"
        } else {
            dateFormatter.dateFormat = "d"
        }
        return dateFormatter.string(from: date)
    }

    func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
        if date.month == 1 && date.day == 1 {
            dateFormatter.dateFormat = "YYYY"
            return dateFormatter.string(from: date)
        }
        return nil
    }

    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        // 日历左右翻动
        let date = calendar.currentPage
        if let lastDateForMonth = lastDateForMonth {
            // 判断是向前了还是向后了
            if date.timestamp < lastDateForMonth.timestamp {
                scrollDirection = .pre
            } else if date.timestamp > lastDateForMonth.timestamp {
                scrollDirection = .next
            } else {
                scrollDirection = nil
            }
        } else {
            scrollDirection = nil
        }
        lastDateForMonth = date
        updateTitle()
        if date.timestamp >= previousStartDate.timestamp && date.timestamp <= previousEndDate.timestamp {
            // 走进到这里说明是在周日历模式 且  不需要加载加一个月的数据
            return
        }

        let startDate = TimeUtil.startOfMonth(date: date).add(component: .month, value: -2)
        let endDate = startDate.add(component: .month, value: 5)

        if currentMonthDate.timestamp <= date.timestamp {
            currentMonthDate = date.add(component: .month, value: 1)
        } else {
            currentMonthDate = date.add(component: .month, value: -1)
        }
        previousStartDate = TimeUtil.startOfMonth(date: date)
        previousEndDate = TimeUtil.endOfMonth(date: date)
//        startTimestamp = TimeUtil.startOfMonth(date: currentMonthDate).timestamp
        startTimestamp = startDate.timestamp
//        endTimestamp = TimeUtil.endOfMonth(date: currentMonthDate).timestamp
        endTimestamp = endDate.timestamp
        initEventData()
        getAppleCalendarEvents()
        initLessonSchedule(force: false)
        refreshLessons()
    }

    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        // 日历周月切换
        monthView.snp.updateConstraints { make in
            make.height.equalTo(bounds.height)
        }
        view.layoutIfNeeded()
        if monthView.scope == .week {
            return
        }
        let date = calendar.currentPage
        updateTitle()
        if date.timestamp >= previousStartDate.timestamp && date.timestamp <= previousEndDate.timestamp {
            return
        }
        if currentMonthDate.timestamp <= date.timestamp {
            currentMonthDate = date.add(component: .month, value: 1)
        } else {
            currentMonthDate = date.add(component: .month, value: -1)
        }
        previousStartDate = TimeUtil.startOfMonth(date: date)
        previousEndDate = TimeUtil.endOfMonth(date: date)
        let startDate = TimeUtil.startOfMonth(date: date).add(component: .month, value: -2)
        let endDate = startDate.add(component: .month, value: 5)
        startTimestamp = startDate.timestamp
        endTimestamp = endDate.timestamp
//        startTimestamp = TimeUtil.startOfMonth(date: currentMonthDate).timestamp
//        endTimestamp = TimeUtil.endOfMonth(date: currentMonthDate).timestamp
        initEventData()
        initLessonSchedule(force: false)
        refreshLessons()
    }

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        // 日期点击
        currentSelectTimestamp = calendar.selectedDate!.timestamp
//        currentLessonSchedule.removeAll()

        getCurrentSchedule()
    }

    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let dateTimestamp = date.startOfDay.timestamp
//        if dateTimestamp < toDayDate.timestamp {
//            return 1
//        }
        if lessonStartDayTimeMap[dateTimestamp] != nil {
            return 1
        } else {
            var count: Int = 0
            if googleCalendarEventTimeMap[dateTimestamp] != nil {
                count += 1
            }

            if appleCalendarEventTimeMap[dateTimestamp] != nil {
                count += 1
            }
            return count
        }
    }

    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
        if date.timestamp < toDayDate.timestamp {
            return ColorUtil.Font.fourth
        } else {
            for item in rescheduleTableViewData.value where !item.isCancelLesson {
                let d = Date(seconds: TimeInterval(Double(item.timeBefore) ?? 0))
                if d.year == date.year && d.month == date.month && d.day == date.day {
                    return ColorUtil.red
                }
            }
            return ColorUtil.main
        }
    }

    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
        if date.timestamp < toDayDate.timestamp {
            return [ColorUtil.Font.fourth]
        } else {
            // 判断当前有没有reschedule的数据
            for item in rescheduleTableViewData.value where !item.isCancelLesson {
                let d = Date(seconds: TimeInterval(Double(item.timeBefore) ?? 0))
                if d.year == date.year && d.month == date.month && d.day == date.day {
                    return [ColorUtil.red]
                }
            }
            let dateTimestamp = date.startOfDay.timestamp
            // 判断是否有课程
            if lessonStartDayTimeMap[dateTimestamp] != nil {
                return [ColorUtil.main]
            } else {
                var colors: [UIColor] = []
                if googleCalendarEventTimeMap[dateTimestamp] != nil {
                    colors.append(ColorUtil.googleEvents)
                }
                if appleCalendarEventTimeMap[dateTimestamp] != nil {
                    colors.append(ColorUtil.appleEvents)
                }
                return colors
            }
        }
    }

    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        if date.timeIntervalSince1970 < toDayDate.timeIntervalSince1970 {
            return ColorUtil.Font.fourth
        } else {
            return ColorUtil.Font.third
        }
    }

    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventSelectionColorsFor date: Date) -> [UIColor]? {
        if date.timestamp < toDayDate.timestamp {
            return [ColorUtil.Font.fourth]
        } else {
            for item in rescheduleTableViewData.value where !item.isCancelLesson {
                let d = Date(seconds: TimeInterval(Double(item.timeBefore) ?? 0))
                if d.year == date.year && d.month == date.month && d.day == date.day {
                    return [ColorUtil.red]
                }
            }
            let dateTimestamp = date.startOfDay.timestamp
            // 判断是否有课程
            if lessonStartDayTimeMap[dateTimestamp] != nil {
                return [ColorUtil.main]
            } else {
                var colors: [UIColor] = []
                if googleCalendarEventTimeMap[dateTimestamp] != nil {
                    colors.append(ColorUtil.googleEvents)
                }
                if appleCalendarEventTimeMap[dateTimestamp] != nil {
                    colors.append(ColorUtil.appleEvents)
                }
//                return [ColorUtil.Shadow.main.withAlphaComponent(0.48)]
                return colors
            }
        }
    }
}

// MARK: - week calendar

extension LessonsViewController: TKCalendarWeekViewDelegate, JZBaseViewDelegate {
    func calendarWeekViewScrollToContentOffset(_ scrollView: UIScrollView, contentOffset: CGPoint) {
        
    }
    
    func calendarWeekViewScrollViewWillBegin(_ scrollView: UIScrollView) {
        
    }
    
    func calendarWeekViewScrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }

    func calendarWeekViewScrollViewWillBegin() {
        if rescheduleTableViewData.value.count > 0 && calendarDisplayType != .month {
            hidenRescheduleAndMakeUpMessageView()
        }
        isScrolling = true
    }

    func calendarWeekViewScrollViewDidEnd(lastDate: Date?, currentDate: Date?, withScrollDirection scrollDirection: TKCalendarWeekView.ScrollDirection?, withScrollView scrollView: UIScrollView) {
        lastDateForWeek = lastDate
        if let scrollDirection = scrollDirection {
            switch scrollDirection {
            case .pre:
                self.scrollDirection = .pre
            case .next:
                self.scrollDirection = .next
            }
        }
//        if let currentDate = currentDate, let lastDate = lastDate {
//            if currentDate.timestamp < lastDate.timestamp {
//                scrollDirection = .pre
//            } else if currentDate.timestamp > lastDate.timestamp {
//                scrollDirection = .next
//            } else {
//                scrollDirection = nil
//            }
//        }
        getAppleCalendarEvents()
        isScrolling = false
        SL.Executor.runAsyncAfter(time: 0.5) { [weak self] in
            guard let self = self else { return }
            if self.rescheduleTableViewData.value.count > 0 && !self.isScrolling {
                self.showRescheduleAndMakeUpMessageView()
            }
        }
    }

    func calendarWeekViewDisplayType() -> TKCalendarDisplayType {
        return calendarDisplayType
    }

    func calendarWeekViewRescheduleData() -> [TKReschedule] {
        return rescheduleTableViewData.value
    }

    func calendarWeekViewHasEvent(by date: Date) -> Bool {
        if lessonStartDayTimeMap[date.startOfDay.timestamp] != nil {
            return true
        } else {
            return false
        }
    }

    func calendarWeekView(_ weakView: TKCalendarWeekView, allDayAppleEventAt date: Date) -> [EKEvent] {
        let d = date.startOfDay
        return appleCalendarEvents.filter { $0.startDate.startOfDay == d }
    }

    func calendarWeekView(click data: DefaultEvent) {
        switch data.type {
        case .default:
            if let event = data.event {
                if event.type == .lesson {
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    var currentData: [TKLessonSchedule] = []
                    var index: Int = 0
                    for item in weekView.allEventsBySection where dateFormatter.string(from: item.key) == event.startDate {
                        for event in item.value {
                            if let selectedEvent = event as? DefaultEvent, let _event = selectedEvent.event {
                                if _event.type == .lesson {
                                    currentData.append(_event)
                                }
                            }
                        }
                    }
                    currentData.sort { a, b -> Bool in
                        a.shouldDateTime < b.shouldDateTime
                    }
                    for item in currentData.enumerated() where item.element.shouldDateTime == event.shouldDateTime {
                        index = item.offset
                    }
                    let controller = LessonsDetailViewController(data: currentData, selectedPos: index)
                    controller.hero.isEnabled = true
                    controller.modalPresentationStyle = .fullScreen
                    controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                    controller.enablePanToDismiss()
                    present(controller, animated: true, completion: nil)

                } else if event.type == .event {
                    toEventDetail(event)

                } else if event.type == .block {
                    toBlockDetail(event)
                }
            }
        case .google: break
        case .apple: break
        case .studioEvent:
            logger.debug("Studio Event 被点击")
        }
    }

    func initDateDidChange(_ weekView: JZBaseWeekView, initDate: Date) {
        if !self.weekView.isHidden {
            let date = initDate.add(component: .day, value: weekView.numOfDays)
            print("=week滑动的日历======\(initDate.toString())===\(date.toString())")
            weekSelectDate = date
            monthView?.setCurrentPage(weekSelectDate, animated: false)
            updateTitle()

            if date.timestamp >= previousStartDate.timestamp && date.timestamp <= previousEndDate.timestamp {
                // 走进到这里说明是在周日历模式 且  不需要加载加一个月的数据
                return
            }
            if currentMonthDate.timestamp <= date.timestamp {
                currentMonthDate = date.add(component: .month, value: 1)
            } else {
                currentMonthDate = date.add(component: .month, value: -1)
            }
            previousStartDate = TimeUtil.startOfMonth(date: date)
            previousEndDate = TimeUtil.endOfMonth(date: date)
            let startDate = TimeUtil.startOfMonth(date: date).add(component: .month, value: -2)
            let endDate = startDate.add(component: .month, value: 6)
            startTimestamp = startDate.timestamp
            endTimestamp = endDate.timestamp
//            startTimestamp = TimeUtil.startOfMonth(date: currentMonthDate).timestamp
//            endTimestamp = TimeUtil.endOfMonth(date: currentMonthDate).timestamp
            initEventData()
            initLessonSchedule(force: false)
            refreshLessons()
        }
    }
}

// MARK: - Data

extension LessonsViewController {
    override func initData() {
        logger.debug("Lessons => 初始化数据")
        let d = Date()
        previousStartDate = TimeUtil.startOfMonth(date: d)
        previousEndDate = TimeUtil.endOfMonth(date: d)
        currentMonthDate = TimeUtil.startOfMonth(date: d)
        currentSelectTimestamp = d.timestamp
        startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -2)).timestamp
        endTimestamp = TimeUtil.endOfMonth(date: d.add(component: .month, value: 6)).timestamp
//        getLessonType()
//        getBlockData()
//        getEventConfigData()
//        getTeacherNoReadCancellationLessonData()
//        getGoogleCalendarEvents()
        initListeners()
        reloadGoogleCalendarEvents()
//        reloadData()
        execUserNotifications()
    }

    private func initListeners() {
        EventBus.listen(EventBus.CHANGE_SCHEDULE, target: self) { [weak self] _ in
            print("接收到刷新消息1")
            self?.reloadData()
        }

        EventBus.listen(EventBus.CHANGE_SCHEDULE_ONLINE, target: self) { [weak self] _ in
            print("接收到刷新消息2")
            self?.reloadData()
        }

        EventBus.listen(key: .teacherStudentListChanged, target: self) { [weak self] _ in
            print("接收到刷新消息3")
            self?.loadStudentData()
        }

        EventBus.listen(key: .teacherLessonChanged, target: self) { [weak self] _ in
            print("接收到刷新消息4")
            self?.reloadData()
        }

        EventBus.listen(key: .teacherLessonTypeChanged, target: self) { [weak self] _ in
            print("接收到刷新消息5")
            self?.reloadData()
        }
        EventBus.listen(EventBus.DATA_UPGRAD_BY_LESSON, target: self) { [weak self] _ in
            print("接收到刷新消息6")
            self?.reloadData()
        }

        EventBus.listen(key: .teacherAppleCalendarEventsChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.getAppleCalendarEvents()
            self.getCurrentSchedule()
            if self.calendarDisplayType == .month {
                self.monthView.reloadData()
            } else {
                self.initWeekData()
            }
        }

        EventBus.listen(key: .appleCalendarStatusChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.getAppleCalendarEvents()
            self.getCurrentSchedule()
        }

        EventBus.listen(key: .googleCalendarUnlink, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.googleCalendarEventTimeMap = [:]
            self.reloadData()
        }

        EventBus.listen(EventBus.IS_SHOW_FULL_SCREEN_COUNTDOWN, target: self) { [weak self] _ in
            guard let self = self else { return }
            guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
//            guard !appdelegate.isShowFullScreenCuntdown else { return }
            print("==========\(appdelegate.isShowFullScreenCuntdown)")
            if appdelegate.lessonNow == nil {
                self.countdownView.isHidden = true
                self.countdownImageView.isHidden = true
            } else {
                if appdelegate.isShowFullScreenCuntdown {
                    self.countdownView.isHidden = true
                    self.countdownImageView.isHidden = true
                } else {
                    self.countdownView.isHidden = false
                    self.checkCountdownGuide()
                }
            }
        }

        EventBus.listen(key: .teacherGoogleCalendarEventsChagned, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.reloadGoogleCalendarEvents()
        }
    }

    private func reloadGoogleCalendarEvents() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let st = Date().timeIntervalSince1970
            logger.debug("[Google日历] => 准备开始整理Google日历的所有events,共有[\(ListenerService.shared.teacherData.googleCalendarEventsForShow.count)]条数据")
            ListenerService.shared.teacherData.googleCalendarEventsForShow.forEach { calendarEvent in
                let date = Date(seconds: calendarEvent.startDateTime).startOfDay
                let key = "\(date.timestamp)"
                // logger.debug("[崩溃测试] => 获取数据的key - 1259: \(key)")
                var lessonList = self.lessonScheduleByDay[key]
                if lessonList == nil {
                    lessonList = []
                }
//                lessonList?.removeElements { $0.type == .googleCalendarEvent }
                if !lessonList!.contains(where: { item in
                    item.id == calendarEvent.id
                }) {
                    var replace: Bool = false
                    var index: Int = 0
                    for e in lessonList!.enumerated() {
                        if let event = e.element.appleCalendarEvent {
                            if event.title == calendarEvent.summary {
                                replace = true
                                index = e.offset
                                break
                            }
                        }
                    }
                    let schedule = TKLessonSchedule()
                    schedule.id = calendarEvent.id
                    schedule.type = .googleCalendarEvent
                    schedule.googleCalendarEvent = calendarEvent
                    schedule.shouldDateTime = calendarEvent.startDateTime
                    schedule.shouldTimeLength = Int((calendarEvent.endDateTime - calendarEvent.startDateTime) / 60)
                    if replace {
                        lessonList![index] = schedule
                        // 现在替换了,把原有的点删除掉
                        self.appleCalendarEventTimeMap[date.timestamp] = nil
                    } else {
                        lessonList!.append(schedule)
                    }
                }

                if let _lessonList = lessonList {
                    self.lessonScheduleByDay[key] = _lessonList
                }
            }

            ListenerService.shared.teacherData.googleCalendarEventsForShow.forEach { event in
                let date = Date(seconds: event.startDateTime).startOfDay
                self.googleCalendarEventTimeMap[date.timestamp] = 1
            }
            let et = Date().timeIntervalSince1970
            logger.debug("[Google日历] => 整理Google日历的耗时: \(et - st)")
            self.monthView?.reloadData()
        }
    }

    private func reloadData() {
        // MARK: - 要刷新的数据

        logger.debug("重新加载数据")

        triggerForBlock = false
        triggerForLessonSchedule = false
        triggerForEvent = false
        timeLeftTimestamp = 0
        timeRightTimestamp = 0
        scrollDirection = nil
        startTimestamp = 0
        endTimestamp = 0
        loadingView.startAnimating()
        eventConfig = []
        blockData = []
        lessonSchedule = []
//        currentLessonSchedule = []
        lessonScheduleIdMap = [:]
        lessonStartDayTimeMap = [:]

        if let d = monthView?.selectedDate {
            previousStartDate = TimeUtil.startOfMonth(date: d)
            previousEndDate = TimeUtil.endOfMonth(date: d)
            //            self.monthView.select(d)
            currentMonthDate = TimeUtil.startOfMonth(date: d)
            currentSelectTimestamp = monthView?.selectedDate?.timestamp ?? d.timestamp
            startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -2)).timestamp
            endTimestamp = TimeUtil.endOfMonth(date: d.add(component: .month, value: 6)).timestamp
        }

        let data = ListenerService.shared.teacherData
        lessonTypes = data.lessonTypes
        scheduleConfigs = data.scheduleConfigs
        initBlockData(data: ListenerService.shared.teacherData.blockList)
        eventConfig = data.eventConfigs
        initEventData()
//        if scheduleConfigs.count > 0 {
//            SLCache.main.set(key: "\(UserService.user.id()!)_isHaveSchedule", value: true)
//        } else {
//            SLCache.main.set(key: "\(UserService.user.id()!)_isHaveSchedule", value: false)
//        }
        initLessonSchedule(force: true)
    }

    private func getAppleCalendarEvents() {
        // 根据显示模式来获取当前的第一天和最后一天的日期
        logger.debug("[Apple日历] => 重新获取Apple Calendar Events")
        appleCalendarEvents.removeAll()
        guard CacheUtil.AppleCalendar.isLinked() else {
            logger.debug("[Apple日历] => 当前Apple Calendar 未 link")
            return
        }
        let startDate: Date = Date(seconds: TimeInterval(timeLeftTimestamp))
        let endDate: Date = Date(seconds: TimeInterval(timeRightTimestamp))
        logger.debug("[Apple日历] => 开始获取系统日历,时间范围: \(startDate) <-> \(endDate)")
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        var googleEvents: [Int: GoogleCalendarEventForShow] = [:]
        ListenerService.shared.teacherData.googleCalendarEventsForShow.forEach { event in
            googleEvents[Int(event.startDateTime)] = event
        }

        let eventList = eventStore.events(matching: predicate)
        var conflicting: [Int] = []
        appleCalendarEvents = eventList.filter {
            if let event = googleEvents[$0.startDate.timestamp] {
                if Int(event.startDateTime) == $0.startDate.timestamp && event.summary == ($0.title ?? "") && Int(event.endDateTime) == $0.endDate.timestamp {
                    conflicting.append($0.startDate.startOfDay.timestamp)
                    return false
                }
            }
            return true
        }
        appleCalendarEvents.forEach { event in
            let timestamp = event.startDate.startOfDay.timestamp
            if !conflicting.contains(timestamp) {
                appleCalendarEventTimeMap[timestamp] = 1
            }
        }
        conflicting.forEach { timestamp in
            appleCalendarEventTimeMap.removeValue(forKey: timestamp)
        }
        logger.debug("[Apple日历] => 获取到的系统日历日程: \(appleCalendarEvents.count)")
        appleCalendarEvents.forEach { event in
            if let date = event.startDate?.startOfDay {
                let key = "\(date.timestamp)"
                // logger.debug("[崩溃测试] => 获取数据的key - 1371: \(key)")
                var lessons = lessonScheduleByDay[key]
                if lessons == nil {
                    lessons = []
                }
                if !lessons!.contains(where: { $0.id == event.eventIdentifier }) {
                    // check if exists same event from google as same day
                    let sameEvents = lessons!.filter { item in
                        if item.type == .googleCalendarEvent {
                            if let e = item.googleCalendarEvent {
                                if e.summary == (event.title ?? "") && Int(e.startDateTime) == event.startDate.timestamp && Int(e.endDateTime) == event.endDate.timestamp {
                                    return true
                                }
                            }
                        }
                        return false
                    }
                    if sameEvents.count == 0 {
                        if !lessons!.contains(where: { item in
                            item.id == event.eventIdentifier
                        }) {
                            let schedule = TKLessonSchedule()
                            schedule.id = event.eventIdentifier
                            schedule.type = .appleCalendarEvent
                            schedule.appleCalendarEvent = event
                            schedule.shouldDateTime = TimeInterval(event.startDate.timestamp)
                            schedule.shouldTimeLength = Int((event.endDate.timestamp - event.startDate.timestamp) / 60)
                            lessons!.append(schedule)
                        }
                    }
                }
                if let lessons = lessons {
                    lessonScheduleByDay[key] = lessons.sorted(by: { $0.getShouldDateTime() < $1.getShouldDateTime() })
                }
            }
        }
    }

    private func getTeacherNoReadCancellationLessonData() {
        guard let teacherID = UserService.user.id() else { return }
        addSubscribe(
            LessonService.lessonSchedule
                .getTeacherNoReadCancellationLesson(teacherId: teacherID)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }

                    var data: [TKReschedule] = []
                    for doc in docs.documents {
                        if let doc = TKLessonCancellation.deserialize(from: doc.data()) {
                            let res = TKReschedule()
                            res.isCancelLesson = true
                            res.id = doc.id
                            res.studentId = doc.studentId
                            res.teacherId = doc.teacherId
                            res.scheduleId = doc.oldScheduleId
                            res.timeBefore = doc.timeBefore
                            if let student = self.studentData[res.studentId] {
                                res.studentData = student
                            }
                            data.append(res)
                        }
                    }
                    var rescheduleData = self.rescheduleTableViewData.value
                    for item in rescheduleData.enumerated().reversed() where item.element.isCancelLesson {
                        rescheduleData.remove(at: item.offset)
                    }

                    for canItem in data {
                        var isHave = false
                        for item in rescheduleData where item.id == canItem.id {
                            isHave = true
                        }
                        if !isHave {
                            rescheduleData.append(canItem)
                        }
                    }
                    var isHaveReschedule = false // 判断是否有reschedule
                    for item in rescheduleData where !item.isCancelLesson {
                        isHaveReschedule = true
                    }

                    self.rescheduleTableViewData.accept(rescheduleData)
                    if rescheduleData.count > 0 {
                        if isHaveReschedule {
                            self.rescheduleAndMakeUpMessageTieleLabel?.text("Reschedule request")
                        } else {
                            self.rescheduleAndMakeUpMessageTieleLabel?.text("Cancellation")
                        }
                        self.rescheduleAndMakeUpMessageView?.isHidden = false
                        self.rescheduleAndMakeUpMessageCountLabel?.text("\(rescheduleData.count)")
                        self.agendaTableView?.snp.updateConstraints { make in
                            make.top.equalTo(self.rescheduleAndMakeUpMessageView.snp.bottom).offset(10)
                        }
                        if self.calendarDisplayType == .month {
                            self.rescheduleAndMakeUpMessageView?.snp.remakeConstraints { make in
                                make.top.equalTo(self.monthView.snp.bottom)
                                make.left.equalTo(20)
                                make.right.equalTo(-20)
                                make.height.equalTo(60)
                            }
                        } else {
                            self.rescheduleAndMakeUpMessageView?.snp.remakeConstraints { make in
                                make.top.equalTo(50)
                                make.left.equalTo(62)
                                make.right.equalTo(-20)
                                make.height.equalTo(60)
                            }
                        }
                    } else {
                        self.rescheduleAndMakeUpMessageView?.snp.updateConstraints { make in
                            make.height.equalTo(0)
                        }
                        self.agendaTableView?.snp.updateConstraints { make in
                            make.top.equalTo(self.rescheduleAndMakeUpMessageView.snp.bottom).offset(0)
                        }
                        self.rescheduleAndMakeUpMessageView?.isHidden = true
                    }

                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    var rescheduleData = self.rescheduleTableViewData.value
                    for item in rescheduleData.enumerated().reversed() where item.element.isCancelLesson {
                        rescheduleData.remove(at: item.offset)
                    }
                    self.rescheduleTableViewData.accept(rescheduleData)
                    if rescheduleData.count > 0 {
                        self.rescheduleAndMakeUpMessageView?.isHidden = false
                        self.rescheduleAndMakeUpMessageCountLabel?.text("\(rescheduleData.count)")
                        self.agendaTableView?.snp.updateConstraints { make in
                            make.top.equalTo(self.rescheduleAndMakeUpMessageView.snp.bottom).offset(10)
                        }
                        if self.calendarDisplayType == .month {
                            self.rescheduleAndMakeUpMessageView?.snp.remakeConstraints { make in
                                make.top.equalTo(self.monthView.snp.bottom)
                                make.left.equalTo(20)
                                make.right.equalTo(-20)
                                make.height.equalTo(60)
                            }
                        } else {
                            self.rescheduleAndMakeUpMessageView?.snp.remakeConstraints { make in
                                make.top.equalTo(50)
                                make.left.equalTo(62)
                                make.right.equalTo(-20)
                                make.height.equalTo(60)
                            }
                        }
                    } else {
                        self.rescheduleAndMakeUpMessageView?.snp.updateConstraints { make in
                            make.height.equalTo(0)
                        }
                        self.agendaTableView?.snp.updateConstraints { make in
                            make.top.equalTo(self.rescheduleAndMakeUpMessageView.snp.bottom).offset(0)
                        }
                        self.rescheduleAndMakeUpMessageView?.isHidden = true
                    }

                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func loadStudentData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let students = ListenerService.shared.teacherData.studentList
            students.forEach { self.studentData[$0.studentId] = $0 }
        }
    }

    /// 删除和修改因为block而reschedule 的数据
    /// - Parameter selectDate:
    private func cancelUndoneRescheduleAndRemoveBlock(blockId: String, selectDate: Date) {
        showFullScreenLoading()
        addSubscribe(
            LessonService.lessonSchedule.getUnConfimRescheduleByTeacherCreate(teacherId: UserService.user.id() ?? "")
                .subscribe(onNext: { docs in
                    if docs.from == .server {
                        var data: [TKReschedule] = []
                        for doc in docs.documents {
                            if let doc = TKReschedule.deserialize(from: doc.data()) {
                                if selectDate.timestamp == TimeUtil.changeTime(time: Double(doc.timeBefore)!).startOfDay.timestamp {
                                    data.append(doc)
                                }
                            }
                        }
                        cancelReschedule(blockId, data)
                    }
                }, onError: { err in
                    cancelReschedule(blockId, [])
                    logger.debug("======\(err)")
                })
        )
        func cancelReschedule(_ blockId: String, _ data: [TKReschedule]) {
            addSubscribe(
                LessonService.lessonSchedule.cancelRescheduleAndRemoveBlock(blockId: blockId, rescheduleDatas: data)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        logger.debug("cancelReschedule 成功")
                        self.reloadData()
                        self.hideFullScreenLoading()

                    }, onError: { [weak self] err in
                        guard let self = self else { return }
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                        logger.debug("======\(err)")
                        self.hideFullScreenLoading()
                    })
            )
        }
    }

    func reschedule(selectDate: Date, _ data: [TKLessonSchedule], msg: String) {
        var selectLesson: [TKLessonSchedule] = []
        showFullScreenLoading()
        var reschedules: [TKReschedule] = []
        let time = "\(Date().timestamp)"
        for item in data {
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
            reschedule.createTime = time
            reschedule.updateTime = time
            reschedules.append(reschedule)
        }
        addSubscribe(
            LessonService.lessonSchedule.rescheduleNoSendEvent(schedule: selectLesson, reschedule: reschedules, atDate: selectDate, msg: msg)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
//                    self.addBlock(selectDate: selectDate)
                }, onError: { [weak self] err in
                    guard let self = self else { return }
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
                                    .done { [weak self] user in
                                        guard let self = self else { return }
                                        self.hideFullScreenLoading()
                                        TKAlert.show(target: self, title: "Something wrong", message: TipMsg.updatingLessonAndTryLater(name: user.name), buttonString: "SEE UPDATE") {
                                            self.showRescheduleAndMakeUpView()
                                        }
                                    }
                                    .catch { [weak self] _ in
                                        guard let self = self else { return }
                                        self.hideFullScreenLoading()
                                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                                    }
                                return
                            }
                        }
                    } else if error.code == 1 {
                        self.hideFullScreenLoading()
                        TKAlert.show(target: self, title: "Too late", message: TipMsg.updateLessonAndTryLaterWhenOccupieded, buttonString: "SEE UPDATE") {
                            self.showRescheduleAndMakeUpView()
                        }
                        return
                    }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                })
        )
    }

    func addBlock(selectDate: Date) {
        guard let teacherID = UserService.user.id() else { return }
        var data: TKBlock = TKBlock()
        let selectDate = selectDate.startOfDay
        let startTime = selectDate.timestamp
        let time = "\(Date().timestamp)"
        data.id = time
        if let id = IDUtil.nextId(group: .lesson) {
            data.id = "\(id)"
        }
        data.teacherId = teacherID
        data.createTime = time
        data.updateTime = time
        data.startDateTime = TimeInterval(startTime)
        data.endDateTime = TimeInterval(selectDate.endOfDay.timestamp)
        showFullScreenLoading()
        addSubscribe(
            LessonService.block.add(data: data)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    logger.debug("===成功===")
                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    logger.debug("====失败==\(err)")
                    TKToast.show(msg: TipMsg.faildCreate, style: .warning)
                })
        )
    }

    private func editBlock(selectDate: Date, msg: String) {
        guard let teacherID = UserService.user.id() else { return }
        showFullScreenLoading()
        let selectDate = selectDate.startOfDay
        let startTime = selectDate.timestamp
        let endTime = selectDate.add(component: .day, value: 2).endOfDay.timestamp
        var localData: [TKLessonSchedule] = []
        addSubscribe(
            LessonService.lessonSchedule.getScheduleList(teacherID: teacherID, startTime: startTime, endTime: endTime, isCache: true)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    for doc in docs.documents {
                        if let d = TKLessonSchedule.deserialize(from: doc.data()) {
                            var isNext = false
                            for item in self.scheduleConfigs where item.id == d.lessonScheduleConfigId {
                                isNext = true
                            }
                            guard isNext else { continue }
                            d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
                            if d.cancelled || d.rescheduled {
                                continue
                            }
                            localData.append(d)
                        }
                    }

                    // 过滤不是今天的日程
                    var sortData: [TKLessonSchedule] = []
                    for item in localData where item.getShouldDateTime() >= Double(startTime) && item.getShouldDateTime() <= Double(selectDate.endOfDay.timestamp) && item.type == .lesson {
                        sortData.append(item)
                    }
                    if sortData.count > 0 {
                        reschedule(sortData, msg: msg)
                    } else {
                        addBlock()
                    }

                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)

                    logger.debug("获取失败:\(err)")
                })
        )
        func reschedule(_ data: [TKLessonSchedule], msg: String) {
            var selectLesson: [TKLessonSchedule] = []
            showFullScreenLoading()
            var reschedules: [TKReschedule] = []
            let time = "\(Date().timestamp)"
            for item in data {
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
                reschedule.createTime = time
                reschedule.updateTime = time
                reschedules.append(reschedule)
            }
            addSubscribe(
                LessonService.lessonSchedule.rescheduleNoSendEvent(schedule: selectLesson, reschedule: reschedules, atDate: selectDate, msg: msg)
                    .subscribe(onNext: { _ in
//                        guard let self = self else { return }
//                        self.addBlock(selectDate: selectDate)
                    }, onError: { [weak self] err in
                        guard let self = self else { return }
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
                                        .done { [weak self] user in
                                            guard let self = self else { return }
                                            self.hideFullScreenLoading()
                                            TKAlert.show(target: self, title: "Something wrong", message: TipMsg.updatingLessonAndTryLater(name: user.name), buttonString: "SEE UPDATE") {
                                                self.showRescheduleAndMakeUpView()
                                            }
                                        }
                                        .catch { [weak self] _ in
                                            guard let self = self else { return }
                                            self.hideFullScreenLoading()
                                            TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                                        }
                                    return
                                }
                            }
                        } else if error.code == 1 {
                            self.hideFullScreenLoading()
                            TKAlert.show(target: self, title: "Too late", message: TipMsg.updateLessonAndTryLaterWhenOccupieded, buttonString: "SEE UPDATE") {
                                self.showRescheduleAndMakeUpView()
                            }
                            return
                        }
                        self.hideFullScreenLoading()
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    })
            )
        }

        func addBlock() {
            var data: TKBlock = TKBlock()
            let selectDate = selectDate.startOfDay
            let startTime = selectDate.timestamp
            let time = "\(Date().timestamp)"
            data.id = time
            if let id = IDUtil.nextId(group: .lesson) {
                data.id = "\(id)"
            }
            data.teacherId = teacherID
            data.createTime = time
            data.updateTime = time
            data.startDateTime = TimeInterval(startTime)
            data.endDateTime = TimeInterval(selectDate.endOfDay.timestamp)
            showFullScreenLoading()
            addSubscribe(
                LessonService.block.add(data: data)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                        logger.debug("===成功===")
                    }, onError: { [weak self] err in
                        self?.hideFullScreenLoading()
                        logger.debug("====失败==\(err)")
                        TKToast.show(msg: TipMsg.faildCreate, style: .warning)
                    })
            )
        }
    }

    private func getBlockData() {
        let userId = UserService.user.id()!
        addSubscribe(
            LessonService.block.list(teacherId: userId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    var d: [TKBlock] = []
                    for item in data.documents {
                        if let doc = TKBlock.deserialize(from: item.data()) {
                            d.append(doc)
                        }
                    }
                    print("BlockData个数:\(d.count)")
//                    if d.count != 0 {
                    self.initBlockData(data: d)
//                    }
                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func initBlockData(data: [TKBlock]) {
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            self.blockData = data
            self.dateFormatter.dateFormat = "yyyy-MM-dd"

            for item in self.lessonSchedule.enumerated().reversed() where item.element.type == .block {
                self.lessonSchedule.remove(at: item.offset)
                self.lessonScheduleIdMap[item.element.id] = nil
            }
            for lessonScheduleItem in self.lessonScheduleByDay {
                let lessons = lessonScheduleItem.value
                let day = lessonScheduleItem.key
                for item in lessons.enumerated().reversed() where item.element.type == .block {
                    self.lessonScheduleByDay[day]?.remove(at: item.offset)
                }
            }
//            self.lessonScheduleByDay.forEach { day, lessons in
//                for item in lessons.enumerated().reversed() where item.element.type == .block {
//                    // logger.debug("[崩溃测试] => 获取数据的key - 1839: \(day)")
//                    self.lessonScheduleByDay[day]?.remove(at: item.offset)
//                }
//            }
            for item in data {
                let date = Date(seconds: item.startDateTime).timestamp
                // logger.debug("[崩溃测试] => 获取数据的key - 1845: \(date)")
                var lessons = self.lessonScheduleByDay["\(date)"]
                if lessons == nil {
                    lessons = []
                }
                let schedule = TKLessonSchedule()
                schedule.id = item.id
                schedule.teacherId = item.teacherId
                schedule.startDate = self.dateFormatter.string(from: TimeUtil.changeTime(time: item.startDateTime))
                schedule.shouldDateTime = item.startDateTime
                schedule.shouldTimeLength = Int((item.endDateTime - item.startDateTime) / 60)
                schedule.blockData = item
                schedule.type = .block
                if self.lessonScheduleIdMap[item.id] == nil {
                    self.lessonScheduleIdMap[item.id] = schedule
                    self.lessonSchedule.append(schedule)
                }
                if !lessons!.contains(where: { $0.id == item.id }) {
                    lessons?.append(schedule)
                } else {
                    lessons!.forEachItems { _item, index in
                        if _item.id == item.id {
                            lessons![index] = schedule
                        }
                    }
                }
                self.lessonScheduleByDay["\(date)"] = lessons
            }
            let selectDate = self.dateFormatter.string(from: TimeUtil.changeTime(time: Double(self.currentSelectTimestamp)))
            //        currentLessonSchedule.removeAll()
            if let date = self.monthView?.selectedDate?.startOfDay {
                let key = "\(date.timestamp)"
                // logger.debug("[崩溃测试] => 获取数据的key - 1877: \(key)")
                if let currentLessons = self.lessonScheduleByDay[key] {
                    self.lessonScheduleByDay.forEach { _, lessons in
                        for item in lessons where item.startDate == selectDate {
                            let exists = currentLessons.contains(where: { $0.id == item.id })
                            var list = self.lessonScheduleByDay[key]
                            if list == nil {
                                list = []
                            }
                            if !exists {
                                list?.append(item)
                            } else {
                                list?.forEachItems({ _item, index in
                                    if item.id == _item.id {
                                        list?[index] = item
                                    }
                                })
                            }
                            if var list = list {
                                list.sort { x, y -> Bool in
                                    x.shouldDateTime < y.shouldDateTime
                                }
                                self.lessonScheduleByDay[key] = list
                            }
                        }
                    }
                }
            }
            self.triggerForBlock = true
        }
    }

    func getEventConfigData() {
        let userId = UserService.user.id() ?? ""
        addSubscribe(
            LessonService.event.list(teacherId: userId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    var d: [TKEventConfigure] = []
                    for item in data.documents {
                        if let doc = TKEventConfigure.deserialize(from: item.data()) {
                            d.append(doc)
                        }
                    }
                    self.eventConfig = d
                    self.initEventData()
                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func initEventData() {
//        let sortData = EventUtil.getEvent(startTime: startTimestamp, endTime: endTimestamp, data: eventConfig)
//        for item in sortData.enumerated() {
//            let id = "\(item.element.teacherId):\(Int(item.element.shouldDateTime))"
//            sortData[item.offset].id = id
//            if lessonScheduleIdMap[id] == nil {
//                lessonSchedule.append(item.element)
//                lessonScheduleIdMap[id] = item.element
//            }
//        }
        triggerForEvent = true
    }

    private func getLessonType() {
        var isLoad = false
        addSubscribe(
            LessonService.lessonType.list()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        if data.count != 0 {
                            isLoad = true
                            self.lessonTypes = data
                            self.getScheduleConfig()
                        }
                    }
                    if let data = data[false] {
                        if !isLoad {
                            self.lessonTypes = data
                            self.getScheduleConfig()
                        }
                    }
                })
        )
    }

    private func getScheduleConfig(isOnlyOnline: Bool = false) {
        addSubscribe(
            UserService.teacher.getScheduleConfigs()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if !isOnlyOnline {
                        if let data = data[true] {
                            self.scheduleConfigs = data
                            self.initLessonSchedule(force: false)
                        }
                    }
                    if let data = data[false] {
                        self.scheduleConfigs = data
                        self.initLessonSchedule(force: false)
                    }
                    logger.debug("[获取config] => 获取到的config: \(self.scheduleConfigs.toJSONString() ?? "")")
                    if self.scheduleConfigs.count > 0 {
                        SLCache.main.set(key: "\(UserService.user.id() ?? "")_isHaveSchedule", value: true)
                    } else {
                        SLCache.main.set(key: "\(UserService.user.id() ?? "")_isHaveSchedule", value: false)
                    }
                }, onError: { err in
                    logger.debug("=获取ScheduleConfig失败=====\(err)")
                })
        )
    }

    /// 把获取下来的数据转化成 WeekView的Data
    func initWeekData() {
        guard weekView != nil else {
            logger.debug("当前WeekView是空的")
            return
        }
//        guard !weekView!.isHidden else {
//            return
//        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
            self.weekLessonSchedule.removeAll()
            for item in self.lessonSchedule {
                let endtiem = (item.getShouldDateTime() + Double(item.shouldTimeLength * 60))
                let event = DefaultEvent(id: item.id, event: item, startDate: TimeUtil.changeTime(time: item.getShouldDateTime()), endDate: TimeUtil.changeTime(time: endtiem))
                self.weekLessonSchedule.append(event)
            }

            for event in ListenerService.shared.teacherData.googleCalendarEventsForShow {
                let startDate = Date(seconds: event.startDateTime)
                let endDate = Date(seconds: event.endDateTime)
                self.weekLessonSchedule.append(DefaultEvent(id: event.id, event: event, startDate: startDate, endDate: endDate))
            }

            for event in self.appleCalendarEvents {
                if let startDate = event.startDate, let endDate = event.endDate, let id = event.eventIdentifier {
                    self.weekLessonSchedule.append(DefaultEvent(id: id, event: event, startDate: startDate, endDate: endDate))
                }
            }
            let events = JZWeekViewHelper.getIntraEventsByDate(originalEvents: self.weekLessonSchedule)
            OperationQueue.main.addOperation {
                self.weekView?.forceReload(reloadEvents: events)
            }
        }
    }

    private func refreshLessons() {
        var startTime = Date().timestamp
        var endTime = startTime + 3600
        switch calendarDisplayType {
        case .month:
            if let monthView = monthView {
                startTime = monthView.currentPage.timestamp
                endTime = monthView.currentPage.add(component: .month, value: 12).timestamp
            } else {
                startTime = Date().timestamp
                endTime = Date().add(component: .month, value: 12).timestamp
            }
        default:
            if let weekView = weekView, let date = weekView.getDatesInCurrentPage(isScrolling: false).first {
                startTime = date.timestamp
                endTime = date.add(component: .month, value: 12).timestamp
            } else {
                startTime = Date().timestamp
                endTime = Date().add(component: .month, value: 12).timestamp
            }
        }

        logger.debug("刷新课程 => 参数: \(Date(seconds: TimeInterval(startTime))) | \(Date(seconds: TimeInterval(endTime)))")
        DispatchQueue.global(qos: .background).async {
            LessonService.lessonSchedule.refreshLessonSchedule(startTime: startTime, endTime: endTime)
                .done { _ in
                }
                .catch { error in
                    logger.error("刷新课程失败: \(error)")
                }
        }
    }

    private func initLessonSchedule(force: Bool) {
        guard scheduleConfigs != nil && scheduleConfigs.count != 0 && lessonTypes != nil else {
            loadingView.stopAnimating()
            SLCache.main.set(key: "\(UserService.user.id() ?? "")_isHaveSchedule", value: lessonSchedule.count > 0)
            if lessonSchedule.count > 0 || isHaveSchedule {
                contentView?.isHidden = false
                addButton?.isHidden = false
                searchButton?.isHidden = false
                filterButton?.isHidden = false
                emptyView?.isHidden = true
            } else {
                contentView?.isHidden = true
                addButton?.isHidden = true
                searchButton?.isHidden = true
                filterButton?.isHidden = true
                emptyView?.isHidden = false
            }
            return
        }

        var studentDatas: [TKStudent] = []
        let json: String = SLCache.main.get(key: SLCache.STUDENT_LIST)
        if let studentData = [TKStudent].deserialize(from: json) as? [TKStudent] {
            if studentData.count > 0 {
                studentDatas = studentData
            }
        }

        getOnlineData(studentDatas: studentDatas, force: force)
    }

    private func initScheduleStudent() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let json: String = SLCache.main.get(key: SLCache.STUDENT_LIST)
            if let studentData = [TKStudent].deserialize(from: json) {
                if studentData.count > 0 {
                    for item in self.lessonSchedule.enumerated().reversed() {
                        if let index = studentData.firstIndex(where: { $0!.studentId == item.element.studentId }) {
                            if index > 0 && self.lessonSchedule.count > index && item.element.type == .lesson && (self.lessonSchedule[item.offset].studentData == nil || self.lessonSchedule[item.offset].studentData!.name != studentData[index]!.name || self.lessonSchedule[item.offset].id == "") {
                                self.lessonSchedule[item.offset].id = "\(item.element.teacherId):\(item.element.studentId):\(Int(item.element.shouldDateTime))"
                                self.lessonSchedule[item.offset].studentData = studentData[index]
                            }
                        } else {
                            if item.element.type == .lesson {
                                self.lessonSchedule.remove(at: item.offset)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 获取今天的日程

    func getCurrentSchedule() {
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            self.agendaTableView?.reloadData()
        }
    }

    private func updateUIAfterDataChanged() {
        OperationQueue.main.addOperation { [weak self] in
            logger.debug("[更新UI] => 开始更新UI")
            guard let self = self else { return }
            self.loadingView.startAnimating()
            let t1 = Date().timeIntervalSince1970
            self.isHaveSchedule = self.lessonSchedule.count > 0
            if self.lessonSchedule.count > 0 {
                self.contentView?.isHidden = false
                self.addButton?.isHidden = false
                self.searchButton?.isHidden = false
                self.filterButton?.isHidden = false
                self.emptyView?.isHidden = true
            } else {
                self.contentView?.isHidden = true
                self.addButton?.isHidden = true
                self.searchButton?.isHidden = true
                self.filterButton?.isHidden = true
                self.emptyView?.isHidden = false
            }
            let t2 = Date().timeIntervalSince1970
            logger.debug("[更新UI] => 更新UI第一步耗时: \(t2 - t1)")
            let t3 = Date().timeIntervalSince1970
            logger.debug("[更新UI] => 更新UI第二步耗时: \(t3 - t2)")
            self.weekLessonSchedule = []
//            self.triggerForLessonSchedule = true
            self.monthView?.reloadData()
            self.initWeekData()
            let t4 = Date().timeIntervalSince1970
            logger.debug("[更新UI] => 更新UI第三步耗时: \(t4 - t3)")
            self.checkClassNow()
            self.initNotification()
            let t5 = Date().timeIntervalSince1970
            logger.debug("[更新UI] => 更新UI第四步耗时: \(t5 - t4)")
            logger.debug("[更新UI] => 更新UI总耗时: \(t5 - t1) | \(self.lessonScheduleByDay.count)")
            self.loadingView.stopAnimating()
            self.agendaTableView?.reloadData()
            LessonService.lessonSchedule.teacherCheckLessonsIfIsValid(lessonsMap: self.lessonScheduleByDay)
        }
    }

    private func getOnlineData(studentDatas: [TKStudent], force: Bool = false) {
        guard let teacherID = UserService.user.id() else { return }
        logger.debug("获取网络请求的数据: \(teacherID) | \(startTimestamp) | \(TimeUtil.changeTime(time: Double(startTimestamp)).toStringa()) | \(endTimestamp) | \(TimeUtil.changeTime(time: Double(endTimestamp)).toStringa())")
        var reset: Bool = false
        let now = Date().startOfDay
        if startTimestamp == 0 {
            startTimestamp = now.add(component: .month, value: -2).timestamp
        }
        if endTimestamp == 0 {
            endTimestamp = now.add(component: .month, value: 8).timestamp
        }
        if timeLeftTimestamp == 0 {
            timeLeftTimestamp = startTimestamp
            reset = true
        }
        if timeRightTimestamp == 0 {
            timeRightTimestamp = endTimestamp
            reset = true
        }
        // 判断是向前还是向后翻了
        if let scrollDirection = scrollDirection {
            logger.debug("判断翻动方向: \(scrollDirection)")
            switch scrollDirection {
            case .pre:
                logger.debug("向前翻")
                // 获取当前页面的日期
                if calendarDisplayType == .month {
                    if let date = monthView?.currentPage {
                        // 判断当前的日期时间,与开始时间是否小于2个月,如果小于,则开始获取
                        if abs(timeLeftTimestamp - date.timestamp) < 5253120 {
                            // 更换开始时间戳为date的前两个月
                            startTimestamp = date.add(component: .month, value: -2).timestamp
                        } else {
                            logger.debug("当前日期与开始日期之间小于2个月,不获取")
                            return
                        }
                    }
                } else {
                    if let date = weekView?.getDatesInCurrentPage(isScrolling: false).first {
                        if abs(timeLeftTimestamp - date.timestamp) < 5253120 {
                            startTimestamp = date.add(component: .month, value: -2).timestamp
                        } else {
                            logger.debug("当前日期与开始日期之间小于2个月,不获取")
                            return
                        }
                    }
                }
            case .next:
                logger.debug("向后翻")
                if calendarDisplayType == .month {
                    logger.debug("当前是月显示模式")
                    if let date = monthView?.currentPage {
                        // 如果当前日期与结束日期之间小于4个月,则开始获取
                        logger.debug("开始判断月")
                        if abs(timeRightTimestamp - date.timestamp) < 10506240 {
                            endTimestamp = date.add(component: .month, value: 12).timestamp
                        } else {
                            logger.debug("当前日期与结束日期之间大于4个月,不获取")
                            return
                        }
                    }
                } else {
                    if let date = weekView?.getDatesInCurrentPage(isScrolling: false).first {
                        if abs(timeRightTimestamp - date.timestamp) < 10506240 {
                            endTimestamp = date.add(component: .month, value: 12).timestamp
                        } else {
                            logger.debug("当前日期与结束日期之间大于4个月,不获取")
                            return
                        }
                    }
                }
                break
            }
        }
        if startTimestamp < timeLeftTimestamp || timeLeftTimestamp == 0 {
            timeLeftTimestamp = startTimestamp
            reset = true
        }
        if endTimestamp > timeRightTimestamp || timeRightTimestamp == 0 {
            timeRightTimestamp = endTimestamp
            reset = true
        }
        logger.debug("[监听数据] => 获取数据的时间范围: \(Date(seconds: TimeInterval(timeLeftTimestamp))) - \(Date(seconds: TimeInterval(timeRightTimestamp)))")
        if reset {
            logger.debug("[监听数据] => 刷新监听数据")
            var isRefresh: Bool = true
            let st = Date().timeIntervalSince1970
            loadingView.startAnimating()
            lessonScheduleListener?.remove()
            lessonScheduleListener = nil
            lessonScheduleListener = DatabaseService.collections
                .lessonSchedule()
                .whereField("teacherId", isEqualTo: teacherID)
                .whereField("shouldDateTime", isLessThanOrEqualTo: timeRightTimestamp)
                .whereField("shouldDateTime", isGreaterThanOrEqualTo: timeLeftTimestamp)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    OperationQueue.main.addOperation {
                        self.loadingView.startAnimating()
                    }
                    self.backgroundQueue.cancelAllOperations()
                    self.backgroundQueue.addOperation {
                        let dt = Date().timeIntervalSince1970
                        logger.debug("[监听数据] => 从开始刷新到结束进入监听耗时: \(dt - st) | 当前条件: \(Date(seconds: TimeInterval(self.timeLeftTimestamp))) - \(Date(seconds: TimeInterval(self.timeRightTimestamp)))")
                        logger.debug("[监听数据] => 进入监听回调")
                        if let error = error {
                            TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                            logger.error("[监听数据] => 监听Lesson Schedule失败: \(error)")
                        } else if let snapshot = snapshot {
                            logger.debug("[监听数据] => lessonSchedule有变更")
                            let t1 = Date()
                            logger.debug("[监听数据] => 开始整理数据")
                            DispatchQueue.main.async {
                                self.reloadGoogleCalendarEvents()
                                self.getAppleCalendarEvents()
                            }
                            if isRefresh {
                                isRefresh = false
                                self.lessonSchedule.removeAll()
                                self.lessonScheduleByDay.removeAll()
                                self.lessonScheduleIdMap.removeAll()
                                self.initBlockData(data: ListenerService.shared.teacherData.blockList)
                            }
                            var added: [TKLessonSchedule] = []
                            var modified: [TKLessonSchedule] = []
                            var removed: [TKLessonSchedule] = []
                            var addedData: [[String: Any]] = []
                            var modifiedData: [[String: Any]] = []
                            var removedData: [[String: Any]] = []
                            snapshot.documentChanges.forEach { diff in
                                switch diff.type {
                                case .added: addedData.append(diff.document.data())
                                case .modified: modifiedData.append(diff.document.data())
                                case .removed: removedData.append(diff.document.data())
                                }
                            }

                            logger.debug("[监听数据] => 数据数量, add: \(addedData.count), modified: \(modifiedData.count), removed: \(removedData.count)")
                            if let _added: [TKLessonSchedule] = [TKLessonSchedule].deserialize(from: addedData) as? [TKLessonSchedule] {
                                logger.debug("[监听数据] => 新增数据[\(_added.count)]")
                                added = _added
                            }

                            if let _modified: [TKLessonSchedule] = [TKLessonSchedule].deserialize(from: modifiedData) as? [TKLessonSchedule] {
                                logger.debug("[监听数据] => 变更数据[\(_modified.count)]")
                                modified = _modified
                            }

                            if let _removed: [TKLessonSchedule] = [TKLessonSchedule].deserialize(from: removedData) as? [TKLessonSchedule] {
                                logger.debug("[监听数据] => 删除数据[\(_removed.count)]")
                                removed = _removed
                            }

                            let t2 = Date()
                            logger.debug("[监听数据] => 整理第一步耗时: \(t2.timeIntervalSince1970 - t1.timeIntervalSince1970)")
                            if added.count > 0 || modified.count > 0 {
                                var configs: [String: TKLessonScheduleConfigure] = [:]
                                self.scheduleConfigs.forEach { config in
                                    configs[config.id] = config
                                }
                                var students: [String: TKStudent] = [:]
                                studentDatas.forEach { student in
                                    students[student.studentId] = student
                                }
                                var lessonTypes: [String: TKLessonType] = [:]
                                self.lessonTypes.forEach { lessonType in
                                    lessonTypes[lessonType.id] = lessonType
                                }

                                DispatchQueue.main.async {
                                    for item in added {
                                        guard let config = configs[item.lessonScheduleConfigId] else {
                                            logger.debug("[异常情况] => 没有config")
                                            continue
                                        }
                                        guard let student = students[item.studentId] else {
                                            logger.debug("[异常情况] => 没有学生")
                                            continue
                                        }
                                        item.studentData = student
                                        item.initShowData(lessonType: lessonTypes[item.lessonTypeId], config: config)
                                        var isHave = false
                                        for _item in self.lessonSchedule.enumerated().reversed() where _item.element.id == item.id {
                                            isHave = true
                                            if item.cancelled || (item.rescheduled && item.rescheduleId != "") {
                                                self.lessonSchedule.remove(at: _item.offset)
                                            } else {
                                                if _item.offset < self.lessonSchedule.count {
                                                    self.lessonSchedule[_item.offset] = item
                                                }
                                            }
                                        }

                                        if !isHave {
                                            if self.lessonScheduleIdMap[item.id] == nil {
                                                self.lessonScheduleIdMap[item.id] = item
                                                if item.cancelled || (item.rescheduled && item.rescheduleId != "") {
                                                    logger.debug("[异常情况] => 2: \(item.toJSONString() ?? "")")
                                                    continue
                                                }
                                                self.lessonSchedule.append(item)
                                            }
                                        }

                                        let date = Date(seconds: item.shouldDateTime).startOfDay.timestamp
                                        let key = "\(date)"
                                        // logger.debug("[崩溃测试] => 获取数据的key - 2415: \(key)")
                                        var list = self.lessonScheduleByDay[key]
                                        if list == nil {
                                            list = []
                                        }
                                        if item.cancelled || (item.rescheduled && item.rescheduleId != "") {
                                            list!.removeElements { $0.id == item.id }
                                        } else {
                                            list!.append(item)
                                        }
                                        list = list!.filterDuplicates { $0.id }
                                        if let list = list {
                                            self.lessonScheduleByDay[key] = list.sorted(by: { $0.getShouldDateTime() < $1.getShouldDateTime() })
                                        }
                                    }
                                }
                                logger.debug("进入修改数据: \(modified.count)")
                                for item in modified {
                                    guard let config = configs[item.lessonScheduleConfigId], let student = students[item.studentId] else {
                                        logger.debug("[异常情况] => 3: \(item.toJSONString() ?? "")")
                                        continue
                                    }
                                    logger.debug("[修改的数据] => \(item.toJSONString() ?? "")")
                                    item.studentData = student
                                    item.initShowData(lessonType: lessonTypes[item.lessonTypeId], config: config)
                                    var isHave = false
                                    for _item in self.lessonSchedule.enumerated().reversed() where _item.element.id == item.id {
                                        logger.debug("[修改的数据] => 修改的数据原来就有: \(_item.element.toJSONString() ?? "")")
                                        isHave = true
                                        if item.cancelled || (item.rescheduled && item.rescheduleId != "") {
                                            logger.debug("[修改的数据] => 修改的数据要隐藏掉")
                                            if _item.offset < self.lessonSchedule.count {
                                                self.lessonSchedule.remove(at: _item.offset)
                                            }
                                        } else {
                                            logger.debug("[修改的数据] => 修改得数据要替换掉")
                                            if _item.offset < self.lessonSchedule.count {
                                                self.lessonSchedule[_item.offset] = item
                                            }
                                        }
                                    }

                                    if !isHave {
                                        logger.debug("[修改的数据] => 修改得原数据不存在")
                                        if self.lessonScheduleIdMap[item.id] == nil {
                                            logger.debug("[修改的数据] => 修改得原数据不存在,进行修改测试")
                                            self.lessonScheduleIdMap[item.id] = item
                                            if item.cancelled || (item.rescheduled && item.rescheduleId != "") {
                                                logger.debug("[异常情况] => 4: \(item.toJSONString() ?? "")")
                                                continue
                                            }
                                            logger.debug("[修改的数据] => 修改得数据已添加")
                                            self.lessonSchedule.append(item)
                                        }
                                    }
                                    DispatchQueue.main.async {
                                        let date = Date(seconds: item.shouldDateTime).startOfDay.timestamp
                                        let key = "\(date)"
                                        // logger.debug("[崩溃测试] => 获取数据的key - 2452: \(key)")
                                        var list = self.lessonScheduleByDay[key]
                                        if list == nil {
                                            list = []
                                        }
                                        if item.cancelled || (item.rescheduled && item.rescheduleId != "") {
                                            list!.removeElements { $0.id == item.id }
                                        } else {
                                            for _item in list!.enumerated() {
                                                if _item.element.id == item.id {
                                                    logger.debug("[修改的数据] => \(item.toJSONString() ?? "") \n 原数据: \(_item.element.toJSONString() ?? "")")
                                                    list![_item.offset] = item
                                                    break
                                                }
                                            }
                                        }
                                        if let list = list {
                                            self.lessonScheduleByDay[key] = list.sorted(by: { $0.getShouldDateTime() < $1.getShouldDateTime() })
                                        }
                                    }
                                }
                            }
                            let t3 = Date()
                            logger.debug("[监听数据] => 整理第二步耗时: \(t3.timeIntervalSince1970 - t2.timeIntervalSince1970)")

                            removed.forEach { item in
                                DispatchQueue.main.async {
                                    self.lessonSchedule.removeElements { $0.id == item.id }
                                    self.lessonScheduleIdMap[item.id] = nil
                                    let date = Date(seconds: item.shouldDateTime).startOfDay.timestamp
                                    let key = "\(date)"
                                    // logger.debug("[崩溃测试] => 获取数据的key - 2476: \(key)")
                                    var list = self.lessonScheduleByDay[key]
                                    list?.removeElements { $0.id == item.id }
                                    if let list = list {
                                        self.lessonScheduleByDay[key] = list.sorted(by: { $0.getShouldDateTime() < $1.getShouldDateTime() })
                                    }
                                }
                            }
                            if removed.count > 0 || added.count > 0 || modified.count > 0 {
                                DispatchQueue.main.async {
                                    self.lessonStartDayTimeMap.removeAll()
                                    for item in self.lessonSchedule {
                                        let time = TimeUtil.changeTime(time: item.getShouldDateTime()).startOfDay.timestamp
                                        self.lessonStartDayTimeMap[time] = 1
                                    }
                                }
                            }
                            let t4 = Date()
                            logger.debug("[监听数据] => 整理第三步耗时: \(t4.timeIntervalSince1970 - t3.timeIntervalSince1970)")
                            SLCache.main.set(key: "\(UserService.user.id() ?? "")_isHaveSchedule", value: self.lessonSchedule.count > 0)
                            self.updateUIAfterDataChanged()
                        }
                    }
                }
        }
    }

    private func initSortData2(studentDatas: [TKStudent], docs: QuerySnapshot?) -> [TKLessonSchedule] {
        guard let docs = docs else { return [] }
        if let data: [TKLessonSchedule] = [TKLessonSchedule].deserialize(from: docs.documents.compactMap { $0.data() }) as? [TKLessonSchedule] {
            return data
        } else {
            return []
        }
    }

    private func initSortData(_ studentDatas: [TKStudent], docs: QuerySnapshot?) -> Promise<[TKLessonSchedule]> {
        return Promise { [weak self] resolver in
            guard let self = self else { return }
            guard let docs = docs else {
                //                return
                resolver.reject(TKError.nilDataResponse(""))
                return
            }
            //                logger.debug("检测Lesson同步情况 => 从网上获取的Lesson数据个数，未经过过滤：\(docs.documents.count)")
            var configs: [String: TKLessonScheduleConfigure] = [:]
            scheduleConfigs.forEach { config in
                configs[config.id] = config
            }

            var students: [String: TKStudent] = [:]
            studentDatas.forEach { student in
                students[student.studentId] = student
            }
            var lessonTypes: [String: TKLessonType] = [:]
            self.lessonTypes.forEach { lessonType in
                lessonTypes[lessonType.id] = lessonType
            }
//            var data:[TKLessonSchedule] = []
            for doc in docs.documents {
                if let d = TKLessonSchedule.deserialize(from: doc.data()) {
                    guard let config = configs[d.lessonScheduleConfigId], let student = students[d.studentId] else { continue }
                    d.studentData = student
                    d.initShowData(lessonType: lessonTypes[d.lessonTypeId], config: config)
                    //                            d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
//                    data.append(d)
//                    lessonStartDayTimeMap[TimeUtil.changeTime(time: d.getShouldDateTime()).startOfDay.timestamp] = 0
                    var isHave = false
                    for item in lessonSchedule.enumerated().reversed() where item.element.id == d.id {
                        isHave = true
                        if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
                            self.lessonSchedule.remove(at: item.offset)
                        } else {
                            self.lessonSchedule[item.offset].refreshData(newData: d)
                        }
                    }
                    if !isHave {
                        if lessonScheduleIdMap[d.id] == nil {
                            lessonScheduleIdMap[d.id] = d
                            if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
                                continue
                            }
                            lessonSchedule.append(d)
                            lessonStartDayTimeMap[TimeUtil.changeTime(time: d.getShouldDateTime()).startOfDay.timestamp] = 0
                        }
                    }
                    //                    data.append(d)
                }
            }
            //            lessonSchedule.removeElements { (schedule) -> Bool in
            //                let configId = schedule.lessonScheduleConfigId
            //                let remove = !self.scheduleConfigs.contains { (config) -> Bool in
            //                    config.id == configId
            //                }
            //                if remove {
            //                    if self.lessonScheduleIdMap[schedule.id] != nil {
            //                        self.lessonScheduleIdMap[schedule.id] = nil
            //                    }
            //                }
            //                if schedule.type == .lesson {
            //                    return remove
            //
            //                } else {
            //                    return false
            //                }
            //            }
            print("===计算走完")

            resolver.fulfill([])
        }
    }

    private func initLesson(addData: [TKLessonSchedule], lessonSchedule: [TKLessonSchedule], startTime: Int, endTime: Int) {
        print("个数????=======\(addData.count)")
//        addLessonSchedules(lessonSchedule: addData)
    }

    private func addLessonSchedules(lessonSchedule: [TKLessonSchedule]) {
        print("需要Add的数据的个数:\(lessonSchedule.count)")
        if lessonSchedule.count == 0 {
            return
        }
        SL.Executor.runAsync { [weak self] in
            guard let self = self else { return }
            self.addSubscribe(
                LessonService.lessonSchedule.addLessonSchedules(schedules: lessonSchedule)
                    .subscribe(onNext: { data in
                        logger.debug("======addLessonSchedules成功了?:\(data)")
                    }, onError: { err in
                        logger.debug("======addLessonSchedules失败了?:\(err)")
                    })
            )
        }
    }
}

// MARK: - tableView

extension LessonsViewController: UITableViewDelegate, UITableViewDataSource {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard calendarDisplayType == .month else {
            return
        }
        guard !isTranscation else {
            return
        }
        if scrollView.contentOffset.y <= -10 {
            if monthView.scope != .month {
                isTranscation = true
                DispatchQueue.main.async { [weak self] in
                    self?.monthView.setScope(.month, animated: true)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.monthView.collectionView?.reloadData()
                }
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
                    guard let self = self else { return }
                    self.isTranscation = false
                }
            }
        }
        if oldOffset.y <= scrollView.contentOffset.y && scrollView.contentOffset.y >= 0 {
            if scrollView.contentOffset.y >= 10 {
                // 向上滚动
                if monthView.scope != .week {
                    isTranscation = true
                    DispatchQueue.main.async { [weak self] in
                        self?.monthView.setScope(.week, animated: true)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        self?.monthView.collectionView?.reloadData()
                    }
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
                        guard let self = self else { return }
                        self.isTranscation = false
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let currentDate = monthView?.selectedDate?.startOfDay {
            let key = "\(currentDate.timestamp)"
            let lessons = lessonScheduleByDay[key]
            logger.debug("当前日期的课程数量: \(lessons?.count ?? -1)")
            return lessons?.count ?? 0
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsCalendarAgendaTableViewCell.self), for: indexPath) as! LessonsCalendarAgendaTableViewCell
        cell.tag = indexPath.row
        cell.delegate = self
        if let currentDate = monthView?.selectedDate?.startOfDay {
            let key = "\(currentDate.timestamp)"
            if let lessons = lessonScheduleByDay[key]?.sorted(by: { $0.getShouldDateTime() < $1.getShouldDateTime() }) {
                if indexPath.row < lessons.count {
                    cell.loadData(data: lessons.sorted(by: { $0.getShouldDateTime() < $1.getShouldDateTime() })[indexPath.row])
                }
            }
        }
        return cell
    }
}

extension LessonsViewController: LessonsCalendarAgendaTableViewCellDelegate {
    func lessonsCalendarAgendaTableViewCellTapped(cell: LessonsCalendarAgendaTableViewCell) {
        logger.debug("点击cell")
        guard let date = monthView?.selectedDate?.startOfDay else { return }
        let key = "\(date.timestamp)"
        // logger.debug("[崩溃测试] => 获取数据的key - 2781: \(key)")
        guard let currentLessonSchedule = lessonScheduleByDay[key]?.sorted(by: { $0.getShouldDateTime() < $1.getShouldDateTime() })
            .sorted(by: { $0.getShouldDateTime() < $1.getShouldDateTime() }) else { return }
        guard currentLessonSchedule.count > cell.tag else { return }
        switch currentLessonSchedule[cell.tag].type {
        case .lesson: toLessonDetail(cell)
        case .event: toEventDetail(currentLessonSchedule[cell.tag])
        case .block: toBlockDetail(currentLessonSchedule[cell.tag])
        case .reschedule: toLessonDetail(cell)
        case .googleCalendarEvent, .appleCalendarEvent:
            break
        }
    }

    func toBlockDetail(_ data: TKLessonSchedule) {
        let oldDate = TimeUtil.changeTime(time: data.shouldDateTime).startOfDay
        TKPopAction.show(items: [
            TKPopAction.Item(title: "Edit", action: { [weak self] in
                TKDatePicker.show(oldDate: oldDate) { [weak self] date in
                    guard let self = self else { return }
                    let date = date.toString().toDate("YYYY-MM-dd", region: .local)!.date
                    if date.timestamp != oldDate.timestamp {
                        self.editBlock(selectDate: date, msg: "")
                        self.cancelUndoneRescheduleAndRemoveBlock(blockId: data.blockData.id, selectDate: oldDate)
                    }
                }
            }),
            TKPopAction.Item(title: "Delete", action: { [weak self] in
                guard let self = self else { return }
                self.cancelUndoneRescheduleAndRemoveBlock(blockId: data.blockData.id, selectDate: oldDate)
            }),
        ], tapBackgroundAction: .dismiss, isCancelShow: true, target: self)
    }

    func toEventDetail(_ data: TKLessonSchedule) {
//        currentLessonSchedule[cell.row]
        let controller = AddEventController()
        controller.isEdit = true
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.data = data.eventConfigData
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func toLessonDetail(_ cell: LessonsCalendarAgendaTableViewCell) {
        // 获取当前的数据

        guard let date = monthView?.selectedDate?.startOfDay else { return }
        let key = "\(date.timestamp)"
        // logger.debug("[崩溃测试] => 获取数据的key - 2831: \(key)")
        guard let currentLessonSchedule = lessonScheduleByDay[key]?.sorted(by: { $0.getShouldDateTime() < $1.getShouldDateTime() })
            .sorted(by: { $0.getShouldDateTime() < $1.getShouldDateTime() }) else { return }
        let item = currentLessonSchedule[cell.tag]

        var showRescheduleRequest: Bool = false
        if item.getShouldDateTime() < TimeInterval(Date().timestamp) {
            showRescheduleRequest = false
        } else {
            if item.rescheduled {
                showRescheduleRequest = true
            } else {
                showRescheduleRequest = false
            }
        }

        if showRescheduleRequest {
            // 显示弹窗
            showRescheduleAndMakeUpView { [weak self] in
                guard let self = self else { return }
//                rescheduleAndMakeUpTableView
                // 获取当前数据在第几行
                var index: Int?
                logger.debug("当前准备检查的数据: \(item.toJSON() ?? [:])")
                for itemData in self.rescheduleTableViewData.value.enumerated() {
                    logger.debug("当前准备对比的数据: \(itemData.element.toJSON() ?? [:])")
                    if item.id == itemData.element.scheduleId {
                        index = itemData.offset
                        break
                    }
                }
                guard index != nil else { return }
                let indexPath = IndexPath(row: index!, section: 0)
                DispatchQueue.main.async {
                    self.rescheduleAndMakeUpTableView.scrollToRow(at: indexPath, at: .none, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let cell = self.rescheduleAndMakeUpTableView.cellForRow(at: indexPath) as? UndoneRescheduleCell {
                            cell.showBorder()
                        }
                    }
                }
            }
        } else {
            var data: [TKLessonSchedule] = []
            var index = 0
            for item in currentLessonSchedule.enumerated() where item.element.type == .lesson {
                data.append(item.element)
                if currentLessonSchedule[cell.tag].id == item.element.id {
                    index = data.count - 1
                }
            }

            let controller = LessonsDetailViewController(data: data, selectedPos: index)
            controller.hero.isEnabled = true
            controller.modalPresentationStyle = .fullScreen
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            controller.enablePanToDismiss()
            present(controller, animated: true, completion: nil)
        }
    }
}

extension LessonsViewController: LessonsCalendarFilterViewControllerDelegate {
    func lessonsCalendarFilterViewControllerSelectCompletion(calendarDisplayType: TKCalendarDisplayType?, isGoogleCalendarShow: Bool) {
        if calendarDisplayType != nil {
            self.calendarDisplayType = calendarDisplayType!
            updateCalendar()
        }
    }
}

// MARK: - events

extension LessonsViewController {
    @objc private func monthSelectTapped(_ sender: UITapGestureRecognizer) {
        logger.debug("month select tapped")
        initData()

        // MARK: - 旋转icon
    }

    private func filterTapped() {
        let controller = LessonsCalendarFilterViewController()
        controller.selectedFilter = calendarDisplayType
        controller.delegate = self
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .down), dismissing: .pull(direction: .up))
        present(controller, animated: true, completion: nil)
    }

    private func showAddPop() {
        weak var weakSelf = self
        logger.debug("点击添加按钮")
        var actions: [TKPopAction.Item] = [
            TKPopAction.Item(title: "Lesson", action: { [weak self] in
                self?.toAddLesson()
            }),
        ]
        var existsDayOffItems: Bool = false
        if calendarDisplayType == .month {
            if let date = monthView.selectedDate?.startOfDay {
                let key = "\(date.timestamp)"
                // logger.debug("[崩溃测试] => 获取数据的key - 2933: \(key)")
                if let currentLessons = lessonScheduleByDay[key] {
                    // 判断当前有没有day-off的
                    if currentLessons.filter({ $0.type == .block }).count > 0 {
                        existsDayOffItems = true
                    }
                }
            }
        }
        if !existsDayOffItems {
            actions.append(TKPopAction.Item(title: "Take Day Off", action: { [weak self] in
                guard let self = self else { return }
                self.toAddBlock()
            }))
        }
        TKPopAction.show(items: actions, tapBackgroundAction: .dismiss, isCancelShow: true, target: weakSelf!)
    }

    private func toAddLesson() {
        let controller = AddressBookViewController()
        controller.showType = .appContactSingleChoice
        controller.hero.isEnabled = true
        controller.isShowAllStudent = true
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    private func toAddEvent() {
        let controller = AddEventController()
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        controller.enablePanToDismiss()
        present(controller, animated: true, completion: nil)
    }

    private func toAddBlock() {
        func add(selectTime: Int) {
            let selectDate = TimeUtil.changeTime(time: Double(selectTime))
            var title = "Take a day-off?"
            let df = DateFormatter()
            df.dateFormat = "MMMM d"
            let dString = df.string(from: selectDate)
            title = "Take a day-off on \(dString)?"
            if let date = monthView?.selectedDate?.startOfDay {
                let key = "\(date.timestamp)"
                // logger.debug("[崩溃测试] => 获取数据的key - 2981: \(key)")
                if let currentLessonSchedule = lessonScheduleByDay[key] {
                    for item in currentLessonSchedule where item.type == .block {
                        TKToast.show(msg: "The day you selected has been Take day off!", style: .warning)
                        return
                    }
                }
            }
            var lessonList: [TKLessonSchedule] = []
            let nowTime = Date().add(component: .minute, value: 10).timestamp
            for item in lessonSchedule where TimeUtil.changeTime(time: item.getShouldDateTime()).startOfDay.timestamp == selectTime && item.getShouldDateTime() >= Double(nowTime) && !item.cancelled && !item.rescheduled && item.type == .lesson {
                lessonList.append(item)
            }

            let count = lessonList.count

            if count == 0 {
                let controller = SL.SLAlert()
                controller.modalPresentationStyle = .custom
                controller.titleString = title
                controller.rightButtonColor = ColorUtil.main
                controller.leftButtonColor = ColorUtil.red
                controller.rightButtonString = "NOT NOW"
                controller.leftButtonString = "TAKE DAY-OFF"
                controller.messageString = "Are you sure to take day off ?"
                controller.leftButtonAction = { [weak self] in
                    guard let self = self else { return }
                    self.addBlock(selectDate: selectDate)
                }
                controller.rightButtonAction = {
                }
                controller.leftButtonFont = FontUtil.bold(size: 13)
                controller.rightButtonFont = FontUtil.bold(size: 13)
                present(controller, animated: false, completion: nil)

            } else {
                let message = "There are \(count) lessons on \(dString). We will send reschedule requests to your students, please follow up with your students to confirm the changes. Continue to set day-off?"
                let controller = SL.SLAlert()
                controller.modalPresentationStyle = .custom
                controller.titleString = title
                controller.rightButtonColor = ColorUtil.main
                controller.leftButtonColor = ColorUtil.red
                controller.rightButtonString = "NOT NOW"
                controller.leftButtonString = "TAKE DAY-OFF"
                controller.leftButtonAction = {
                    [weak self] in
                    guard let self = self else { return }
                    TKPopAction.showSendMessage(target: self, titleString: "Message to students (optional)", leftButtonString: "CANCEL", rightButtonString: "NEXT") { [weak self] msg in
                        // 设置完发送的message
                        guard let self = self else { return }
                        self.reschedule(selectDate: selectDate, lessonList, msg: msg)
                    }
                }
                controller.rightButtonAction = {
                }
                controller.messageString = message
                controller.leftButtonFont = FontUtil.bold(size: 13)
                controller.rightButtonFont = FontUtil.bold(size: 13)
                present(controller, animated: false, completion: nil)

//                SL.Alert.show(target: self, title: "Prompt", message: "\(message)", leftButttonString: "CONFIRM", rightButtonString: "NOT NOW", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
//                    guard let self = self else { return }
//                    // 确认 block
//
//                }) {
//                }
            }
        }

        if calendarDisplayType == .month && emptyView.isHidden {
            add(selectTime: currentSelectTimestamp)
        } else {
            var excludes: [Date] = []
            lessonScheduleByDay.forEach { _, lessons in
                excludes += lessons.filter { $0.type == .block }.compactMap { Date(seconds: $0.shouldDateTime) }
            }
            let startDate = Date().startOfDay
            TKDatePicker.show(startDate: startDate, exclude: excludes) { date in
                let date = date.toString().toDate("YYYY-MM-dd", region: .local)!.date.startOfDay
                add(selectTime: date.timestamp)
            }
        }
    }
}

// extension LessonsViewController: TypeLessonViewControllerDelegate {
//    func typeLessonViewController(didSelected lessonType: TKLessonType) {
//        // add sutdent
//        StudentsSelector.select(target: self) { [weak self] _ in
//            guard let self = self else { return }
//            let controller = AddLessonDetailViewController()
//            controller.hero.isEnabled = true
//            controller.modalPresentationStyle = .fullScreen
//            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .up), dismissing: .pull(direction: .down))
//            self.present(controller, animated: true, completion: nil)
//        }
//    }
// }
extension LessonsViewController {
    private func initListener() {
        EventBus.listen(key: .signOut, target: self) { [weak self] _ in
            logger.debug("监听到退出登录,课程监听器注销")
            self?.lessonScheduleListener?.remove()
            self?.lessonScheduleListener = nil
        }

        EventBus.listen(key: .scrollToToday, target: self) { [weak self] _ in
            self?.scrollToToday()
        }
    }

    func scrollToToday() {
        monthView?.select(Date(), scrollToDate: true)
        weekView?.scrollToToday()
        switch calendarDisplayType {
        case .month:
            currentSelectTimestamp = monthView!.selectedDate!.timestamp
//            currentLessonSchedule.removeAll()
            getCurrentSchedule()
        default:
            break
        }
    }
}

extension LessonsViewController: TKCountdownLabelDelegate {
    func countingAt(timeCounted: TimeInterval, timeRemaining: TimeInterval) {
    }

    /// 检测是否正在上课
    func checkClassNow() {
        guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.backgroundQueue.addOperation {
                let nowTime = Date().timestamp
                var lesson: TKLessonSchedule?

                var nextLesosns: [TKLessonSchedule] = []
                self.lessonSchedule.forEach { item in
                    if item.type == .lesson {
                        let endTime = Int(item.getShouldDateTime()) + (item.shouldTimeLength * 60)
                        if nowTime > Int(item.getShouldDateTime()) && nowTime < endTime && item.lessonStatus != .ended {
                            lesson = item
                        }
                        if nowTime < Int(item.getShouldDateTime()) {
                            nextLesosns.append(item)
                        }
                    }
                }
                nextLesosns.sort { a, b -> Bool in
                    a.shouldDateTime < b.shouldDateTime
                }
                self.nextLessonTimer?.invalidate()
                self.nextLessonTimer = nil
                if nextLesosns.count > 0 {
                    let difference = Int(nextLesosns[0].getShouldDateTime()) - nowTime + 2
                    appdelegate.nextLesson = nextLesosns[0]
                    self.nextLessonTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(difference), repeats: false, block: { _ in
                        guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                        if let nextLesson = appdelegate.nextLesson {
                            print("走到了这里面")
                            appdelegate.lessonNow = nextLesson
                            let endTime = appdelegate.lessonNow!.getShouldDateTime() + (Double(appdelegate.lessonNow!.shouldTimeLength) * Double(60))
                            let toTime = Date(timeIntervalSince1970: endTime)
                            DispatchQueue.main.async {
                                self.countdownLabel.setCountDownDate(targetDate: toTime)
                                self.countdownLabel.start()
                                if appdelegate.isShowFullScreenCuntdown {
                                    self.countdownImageView.isHidden = true
                                    self.countdownView.isHidden = true
                                } else {
                                    self.countdownView.isHidden = false
                                    self.checkCountdownGuide()
                                }
                            }
                            appdelegate.lessonNow = lesson
                        }
                        print("倒计时结束开始刷新")
                        appdelegate.nextLesson = nil
                        EventBus.send(EventBus.REFRESH_COUNTDOWN)
                        self.checkClassNow()
                    })
                }
                if let lesson = lesson {
                    if !appdelegate.isShowFullScreenCuntdown {
                        let endTime = lesson.getShouldDateTime() + (Double(lesson.shouldTimeLength) * Double(60))
                        let toTime = Date(timeIntervalSince1970: endTime)
                        DispatchQueue.main.async {
                            self.countdownLabel.setCountDownDate(targetDate: toTime)
                            self.countdownLabel.start()
                            self.countdownView.isHidden = false
                            self.checkCountdownGuide()
                        }
                        appdelegate.lessonNow = lesson
                    }

                } else {
                    DispatchQueue.main.async {
                        self.countdownView.isHidden = true
                        self.countdownImageView.isHidden = true
                    }
                    appdelegate.lessonNow = nil
                }
            }
        }
    }

    func countdownFinished() {
        print("我也要结束啦")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.countdownView.isHidden = true
            self.countdownImageView.isHidden = true
            guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            appdelegate.lessonNow = nil
            self.checkClassNow()
        }
    }
}
