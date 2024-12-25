//
//  RescheduleController.swift
//  TuneKey
//
//  Created by Wht on 2019/12/3.
//  Copyright © 2019年 spelist. All rights reserved.
//

import SwiftDate
import UIKit

enum studentRescheduleButtonType {
    case refund
    case makeUp
    case reschedule
    case cancelLesson
    case refundAndMakeUp
    case cancelLessonAndReschedule
}

class RescheduleController: TKBaseViewController {
    private var mainView = UIView()
    private var navigationBar: TKNormalNavigationBar!

    private var selectedView: TKView!
    private var operatingButton: TKLabel!

    private var originalView: TKView!
    private var originalTimeLabel: TKLabel!
    private var originalDayLabel: TKLabel!
    private var originalMonthLabel: TKLabel!

    private var arrowView: TKImageView!

    private var updatedView: TKView!
    private var updatedTimeLabel: TKLabel!
    private var updatedDayLabel: TKLabel!
    private var updatedMonthLabel: TKLabel!

    private var scrollView: UIScrollView!
    private var scrollContentView: TKView!
    private var dateTimeView: TKDateTimeSelectorView!
    private var dateTimeViewHeight: CGFloat = 500

    var originalData: TKLessonSchedule!
    private var rescheduleData: TKReschedule!
    private var makeUpData: TKLessonCancellation!
    var updatedData: TKLessonSchedule!
    var buttonType: studentRescheduleButtonType! = .reschedule
    private let dateFormatter = DateFormatter()
    private var selectDate: Date!
    private var scheduleConfigs: [TKLessonScheduleConfigure]! = []
    private var currentSelectTimestamp = 0
    private var startTimestamp = 0
    private var endTimestamp = 0
    // 全部获取的日程
    private var lessonSchedule: [TKLessonSchedule] = []
    // 全部从网上获取的日程
    private var webLessonSchedule: [TKLessonSchedule] = []

    // 当前天的日程
    private var currentLessonSchedule: [TKLessonSchedule] = []
    // 以获取月份
    private var acquiredMonth: [String] = [] // yyyy-MM-dd

    private var blockData: [TKBlock] = []
    private var doneRescheduleData: [TKReschedule] = []

    private var eventConfig: [TKEventConfigure] = []
    // 用来存储已经存到本地的lesson
    private var lessonScheduleIdMap: [String: String] = [:]
    // 用来存储已经存到网络的lesson
    private var webLessonScheduleMap: [String: Bool] = [:]
    private var lessonTypes: [TKLessonType]! = []
    private var policyData: TKPolicies!
    // 当前时间段的时间
    private var currentMonthDate: Date!
    // 上一个选择的时间段开始时间
    private var previousStartDate: Date!
    // 上一个选择的时间段结束时间
    private var previousEndDate: Date!

    private var buttonLayout: TKView!
    private var centerButton: TKBlockButton!
    private var leftButton: TKBlockButton!
    private var rightButton: TKBlockButton!
    private var isMianController = false
    private var userData: TKUser!
    private var isEdit: Bool = false
    private var selectedTimeIsPreferred = false
    private var teacherNoConfirmRescheduleData: [TKReschedule] = []
    private var cancelLessonButton: TKLabel!

    var isForCredit: Bool = false
    var credit: TKCredit?
    var onCreditSent: ((TKCredit) -> Void)?

    init(originalData: TKLessonSchedule, buttonType: studentRescheduleButtonType, policyData: TKPolicies) {
        super.init(nibName: nil, bundle: nil)
        self.buttonType = buttonType
        self.originalData = originalData
        self.policyData = policyData
    }

    init(originalData: TKLessonSchedule, rescheduleData: TKReschedule, buttonType: studentRescheduleButtonType, policyData: TKPolicies, isEdit: Bool, isMianController: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        self.isMianController = isMianController
        self.buttonType = buttonType
        self.isEdit = isEdit
        self.originalData = originalData
        self.rescheduleData = rescheduleData
        self.policyData = policyData
    }

    init(originalData: TKLessonSchedule, makeUpData: TKLessonCancellation, buttonType: studentRescheduleButtonType, policyData: TKPolicies, isMianController: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        self.isMianController = isMianController
        self.buttonType = buttonType
        self.makeUpData = makeUpData
        self.originalData = originalData
        self.policyData = policyData
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - View

extension RescheduleController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "Reschedule", target: self)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initSelectedView()
        initScrollView()
        initDateTimeView()
        initButtonView()
        refreshButton()
    }

    private func initScrollView() {
        scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delaysContentTouches = false
        scrollView.backgroundColor = UIColor.white
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 180, right: 0)
        mainView.addSubview(view: scrollView) { make in
            make.top.equalTo(selectedView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
        scrollContentView = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
            .addTo(superView: scrollView, withConstraints: { make in
                make.edges.equalTo(scrollView).inset(UIEdgeInsets.zero)
                make.height.equalTo(524 + 15)
                make.width.equalTo(scrollView)
            })
        scrollContentView.backgroundColor = UIColor.white

        scrollView.setTopRadius()
        operatingButton = TKLabel.create()
            .backgroundColor(color: UIColor.clear)
            .textColor(color: ColorUtil.Font.primary)
//            .alignment(alignment: .left)
            .font(font: FontUtil.medium(size: 13))
            .text(text: "")
            .addTo(superView: scrollContentView, withConstraints: { make in
                make.left.equalToSuperview().offset(14)
                make.right.equalToSuperview().offset(-15)
                make.top.equalToSuperview().offset(20)
            })
        operatingButton.lineBreakMode = .byWordWrapping
        operatingButton.numberOfLines = 0
        cancelLessonButton = TKLabel.create()
            .textColor(color: ColorUtil.red)
            .font(font: FontUtil.bold(size: 15))
            .text(text: "CANCEL LESSON")
            .addTo(superView: scrollContentView, withConstraints: { make in
                make.right.equalToSuperview().offset(-15)
//                make.height.equalTo(17.5)
                make.height.equalTo(0)
                make.top.equalTo(operatingButton.snp.bottom).offset(0)
            })
        cancelLessonButton.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.cancelLesson()
        }
    }

    private func initDateTimeView() {
        logger.debug("初始化日期选择器")
        dateTimeView = TKDateTimeSelectorView(frame: .zero)
        dateTimeView.delegate = self
        scrollContentView.addSubview(view: dateTimeView) { make in
//            make.top.equalToSuperview().offset(15)
            make.top.equalTo(cancelLessonButton.snp.bottom)

            make.left.right.equalToSuperview()
//            make.height.equalTo(524)
            make.bottom.equalToSuperview()
        }
        dateTimeView.backgroundColor = UIColor.white
    }

    private func initButtonView() {
        buttonLayout = TKView.create()
            .addTo(superView: mainView, withConstraints: { make in
                make.bottom.equalToSuperview().offset(-50)
                make.height.equalTo(50)
                if deviceType == .phone {
                    make.left.equalToSuperview().offset(20)
                    make.right.equalToSuperview().offset(-20)
                } else {
                    make.width.equalTo(360)
                    make.centerX.equalToSuperview()
                }
            })
        buttonLayout.backgroundColor = UIColor.clear

        centerButton = TKBlockButton(frame: .zero, title: "REFUND", style: .normal)
        centerButton.isHidden = true
        buttonLayout.addSubview(view: centerButton) { make in
            make.height.equalTo(50)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview()
        }
        var buttonWidth: CGFloat = 0
        if deviceType == .phone {
            buttonWidth = (UIScreen.main.bounds.width - 50) / 2
        } else {
            buttonWidth = 330 / 2
        }
        leftButton = TKBlockButton(frame: .zero, title: "REFUND", style: .cancel)
        rightButton = TKBlockButton(frame: .zero, title: "REFUND", style: .normal)
        rightButton.isHidden = true
        leftButton.isHidden = true

        buttonLayout.addSubview(view: leftButton) { make in
            make.width.equalTo(buttonWidth)
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        buttonLayout.addSubview(view: rightButton) { make in

            make.width.equalTo(buttonWidth)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        centerButton.onTapped { [weak self] _ in
            self?.clickCenterButton()
        }
        rightButton.onTapped { [weak self] _ in
            self?.clickRightButton()
        }
        leftButton.onTapped { [weak self] _ in
            self?.clickLeftButton()
        }
    }

    private func refreshButton() {
        rightButton.isHidden = true
        leftButton.isHidden = true
        centerButton.isHidden = true
        cancelLessonButton.snp.updateConstraints { make in
            make.height.equalTo(0)
            make.top.equalTo(operatingButton.snp.bottom).offset(0)
        }
        var text: String! = ""
        switch buttonType! {
        case .refund:
            centerButton.isHidden = false
            centerButton.setTitle(title: "REFUND")
            text = "There are no available times to reschedule a makeup at the moment. You can request a refund or decide later. See policies "
//            operatingButton.text("Can’t find any available time to makeup at this moment. You can request a refund or decide later. See policies")

        case .makeUp:
            centerButton.isHidden = false
            centerButton.disable()
            centerButton.setTitle(title: "MAKE UP")
            if policyData.makeupNoticeRequired != 0 {
                text = "Makeup your lesson no later than \(policyData.makeupNoticeRequired) hours before class. See policies"
//                operatingButton.text("Makeup your lesson no later than \(policyData.makeupNoticeRequired) hours before class. See policies")
            } else {
                text = "Makeup your lesson no later than before class. See policies "
//                operatingButton.text("Makeup your lesson no later than before class. See policies")
            }
            break
        case .reschedule:
            centerButton.isHidden = false
            centerButton.disable()
            if isEdit {
                centerButton.setTitle(title: "UPDATE")
            } else {
                centerButton.setTitle(title: "SEND REQUEST")
            }
            if policyData.rescheduleNoticeRequired != 0 {
                text = "Reschedule up until \(policyData.rescheduleNoticeRequired)  hours before class. See policies "
//                operatingButton.text("Reschedule your lesson up until \(policyData.rescheduleNoticeRequired) hours before class. See policies")
            } else {
                text = "Reschedule your lesson up until before class. See policies"
                operatingButton.text("Reschedule your lesson up until before class. See policies ")
            }
            break
        case .cancelLesson:
//            centerButton.isHidden = false
//            rightButton.isHidden = false
//                     leftButton.isHidden = false
            cancelLessonButton.snp.updateConstraints { make in
                make.height.equalTo(17.5)
                make.top.equalTo(operatingButton.snp.bottom).offset(15)
            }
            centerButton.setTitle(title: "CANCEL LESSON")
            if policyData.rescheduleNoticeRequired != 0 {
                text = "Reschedule up until \(policyData.rescheduleNoticeRequired)  hours before class. You can also cancel a lesson. See policies "
//                operatingButton.text("Reschedule your lesson up until \(policyData.rescheduleNoticeRequired) hours before class. You can also cancel the lesson this class. See policies")
            } else {
                text = "Reschedule your lesson up until before class. You can also cancel this class. See policies "
                // operatingButton.text("Reschedule your lesson up until before class. You can also cancel this class.  See policies")
            }
            break
        case .refundAndMakeUp:
            if selectDate == nil {
                centerButton.isHidden = false
                centerButton.setTitle(title: "REFUND")
            } else {
                rightButton.isHidden = false
                leftButton.isHidden = false
                leftButton.setTitle(title: "REFUND")
                rightButton.setTitle(title: "MAKE UP")
            }
            if policyData.makeupNoticeRequired != 0 {
                text = "Makeup your lesson no later than \(policyData.makeupNoticeRequired) hours before class. You can request a refund if you can't find any available time to makeup. See policies "
                //    operatingButton.text("Makeup your lesson no later than \(policyData.makeupNoticeRequired) hours before class. You can request a refund if you can't find any available time to makeup. See policies")
            } else {
                text = "Makeup your lesson no later than before class. You can request a refund if you can't find any available time to makeup. See policies "
                //   operatingButton.text("Makeup your lesson no later than before class. You can request a refund if you can't find any available time to makeup.  See policies")
            }
            break
        case .cancelLessonAndReschedule:
//            rightButton.isHidden = false
//            leftButton.isHidden = false
//            leftButton.setTitle(title: "CANCEL LESSON")
//                rightButton.setTitle(title: "RESCHEDULE")
            print("=====走到我这里面")
            centerButton.isHidden = false
            centerButton.setTitle(title: "SEND REQUEST")
            cancelLessonButton.snp.updateConstraints { make in
                make.height.equalTo(17.5)
                make.top.equalTo(operatingButton.snp.bottom).offset(15)
            }

            if policyData.rescheduleNoticeRequired != 0 {
                text = "Reschedule up until \(policyData.rescheduleNoticeRequired) hours before class You can also cancel a lesson. See policies "
//                operatingButton.text("Reschedule your lesson up until \(policyData.rescheduleNoticeRequired) hours before class. You can also cancel the lesson this class.  See policies")
            } else {
                text = "Reschedule your lesson up until before class. You can also cancel this class. See policies "
                // operatingButton.text("Reschedule your lesson up until before class. You can also cancel this class.  See policies")
            }
            break
        }
        let attributedStrM: NSMutableAttributedString = NSMutableAttributedString()
        text = "\(text!) "
        let str1: NSAttributedString = NSAttributedString(string: "\(text!)", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.Font.primary, NSAttributedString.Key.font: FontUtil.medium(size: 13)])
        let image: UIImage = UIImage(named: "imgInfo")!
        let textAttachment: NSTextAttachment = NSTextAttachment()
        textAttachment.image = image
        textAttachment.bounds = CGRect(x: 0, y: -5, width: 20, height: 20)
        attributedStrM.append(str1)
        attributedStrM.append(NSAttributedString(attachment: textAttachment))
        operatingButton.attributedText = attributedStrM
        operatingButton.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            let controller = SPoliciesController()
            controller.studentData = ListenerService.shared.studentData.studentData
            controller.seePolicy = true
            controller.data = self.policyData
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.enablePanToDismiss()
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            self.present(controller, animated: true, completion: nil)
        }
    }

    // MARK: - 初始化SelectedView

    private func initSelectedView() {
        selectedView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showShadow()
            .corner(size: 5)
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalTo(20)
                make.right.equalTo(-20)
                make.top.equalTo(navigationBar.snp.bottom).offset(20)
                make.height.equalTo(146 - 40)
            })

        arrowView = TKImageView.create()
            .setImage(name: "icReschedule")
            .addTo(superView: selectedView, withConstraints: { make in
                make.size.equalTo(22)
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(37)
            })

        initOriginalView()
        initUpdatedView()
//        let operatingView = TKView.create()
//            .backgroundColor(color: ColorUtil.Button.Background.disabled)
//            .addTo(superView: selectedView, withConstraints: { make in
//                make.left.equalToSuperview()
//                make.right.equalToSuperview()
//                make.bottom.equalToSuperview()
//                make.height.equalTo(50)
//            })

//        operatingButton.numberOfLines = 2
//        operatingView.setBottomRadius(radius: 5)
    }

    // MARK: - 初始化OriginalView

    private func initOriginalView() {
        originalView = TKView.create()
            .addTo(superView: selectedView, withConstraints: { make in
                make.height.equalTo(73)
                make.top.equalTo(18)
                make.left.equalTo(30)
            })
        originalTimeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .text(text: "Time")
            .textColor(color: ColorUtil.Font.second)
            .addTo(superView: originalView, withConstraints: { make in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(15)
            })
        originalDayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.main)
            .addTo(superView: originalView, withConstraints: { make in
                make.left.equalToSuperview()
                make.height.equalTo(47)
                make.top.equalTo(originalTimeLabel.snp.bottom)
            })
        originalMonthLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.main)
            .text(text: "Date")
            .addTo(superView: originalView, withConstraints: { make in
                make.left.equalTo(originalDayLabel.snp.right).offset(9)
                make.bottom.equalTo(originalDayLabel.snp.bottom)
            })
        _ = TKLabel.create()
            .text(text: "Original")
            .font(font: FontUtil.medium(size: 10))
            .textColor(color: ColorUtil.Font.fourth)
            .addTo(superView: originalView, withConstraints: { make in
                make.left.equalToSuperview()
                make.top.equalTo(originalDayLabel.snp.bottom).offset(-2)
            })
    }

    // MARK: - 初始化UpdatedView

    private func initUpdatedView() {
        updatedView = TKView.create()
            .addTo(superView: selectedView, withConstraints: { make in
                make.height.equalTo(73)
                make.top.equalTo(18)
                make.left.equalTo(arrowView.snp.right).offset(30)
            })
        updatedTimeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .text(text: "Time")
            .textColor(color: ColorUtil.Font.second)
            .addTo(superView: updatedView, withConstraints: { make in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(15)
            })
        updatedDayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.main)
            .addTo(superView: updatedView, withConstraints: { make in
                make.left.equalToSuperview()
                make.height.equalTo(47)
                make.top.equalTo(updatedTimeLabel.snp.bottom)
            })
        updatedMonthLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Date")
            .addTo(superView: updatedView, withConstraints: { make in
                make.left.equalTo(updatedDayLabel.snp.right)
                make.bottom.equalTo(updatedDayLabel.snp.bottom)
            })
        _ = TKLabel.create()
            .text(text: "Updated")
            .font(font: FontUtil.medium(size: 10))
            .textColor(color: ColorUtil.Font.fourth)
            .addTo(superView: updatedView, withConstraints: { make in
                make.left.equalToSuperview()
                make.top.equalTo(originalDayLabel.snp.bottom).offset(-2)
            })
    }
}

extension RescheduleController: TKDateTimeSelectorViewDelegate {
    func tkDateTimeSelectorViewClickOtherTimeInfo() {
        SL.Alert.show(target: self, title: "", message: "Tunekey's scheduling system tries to group lessons together to greatly increase efficiency and convenience for your instructor", centerButttonString: "OK") {
        }
    }

    func tkDateTimeSelectorView(currentPageDidChange calendar: FSCalendar) {
        let date = calendar.currentPage
        if date.timestamp >= previousStartDate.timestamp && date.timestamp <= previousEndDate.timestamp {
            return
        }
        if currentMonthDate.timestamp <= date.timestamp {
            currentMonthDate = date.add(component: .month, value: 1)
        } else {
            currentMonthDate = date.add(component: .month, value: -1)
        }
        previousStartDate = date.startOfMonth().startOfDay
        previousEndDate = date.endOfMonth().endOfDay
        startTimestamp = TimeUtil.startOfMonth(date: currentMonthDate).timestamp
        endTimestamp = TimeUtil.endOfMonth(date: currentMonthDate).timestamp
        print("startTimestamp:\(startTimestamp)===\(endTimestamp)===\(date.toStringa())===\(previousEndDate.toStringa())")
        initScheduleData()
    }

    // MARK: - DateTimeSelectorView

    func tkDateTimeSelectorView(heightChanged height: CGFloat) {
        dateTimeViewHeight = height
        scrollContentView.snp.updateConstraints { make in
            make.height.equalTo(height + 50)
        }
        scrollView.layoutIfNeeded()
    }

    func tkDateTimeSelectorView(timeRangeChanged timeRange: TKTimeRange) {
    }

    func tkDateTimeSelectorView(_ dateTimeSelectorView: TKDateTimeSelectorView, dateSelected date: Date) {
    }

    func tkDateTimeSelectorViewCancelTapped(_ dateTimeSelectorView: TKDateTimeSelectorView) {
    }

    func tkDateTimeSelectorView(shouldScroll dateTimeSelectorView: TKDateTimeSelectorView, offset: CGFloat) {
        logger.debug("变更高度: \(offset)")
        scrollView.setContentOffset(CGPoint(x: 0, y: offset + 40), animated: true)
    }

    func tkDateTimeSelectorViewConfirmTapped(_ dateTimeSelectorView: TKDateTimeSelectorView, date: TKTime) {
//        selectedTimeIsPreferred = date.isPreferred
        selectedTimeIsPreferred = false
        let date = TimeUtil.changeTime(time: Double(date.timestamp))
        logger.debug("选择的时间: \(date.toLocalFormat("yyyy-MM-dd HH:mm:ss"))")
        selectDate = date
        dateFormatter.dateFormat = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"
        updatedTimeLabel.text("\(dateFormatter.string(from: date))")
        updatedDayLabel.text("\(date.day)")
        updatedMonthLabel.text("\(TimeUtil.getMonthShortName(month: date.month))")
        updatedMonthLabel.textColor = ColorUtil.main

        switch buttonType! {
        case .refund:
            buttonType = .refundAndMakeUp
            refreshButton()
            return
        case .makeUp:
            centerButton.enable()
            return
        case .reschedule:
            centerButton.enable()
            return
        case .cancelLesson:
            buttonType = .cancelLessonAndReschedule
            refreshButton()
            return
        case .refundAndMakeUp:
            refreshButton()
            return

        case .cancelLessonAndReschedule:

            return
        }
    }
}

// MARK: - Data

extension RescheduleController {
    override func initData() {
        print("===\(originalData.id)")
        showFullScreenLoading()
        initOriginalLesson()
        let d = Date()
        previousStartDate = d.startOfMonth().startOfDay
        previousEndDate = d.endOfMonth().endOfDay
//               calendarView.select(d)
        currentMonthDate = d.startOfMonth().startOfDay
//               currentSelectTimestamp = calendarView.selectedDate?.timestamp ?? d.timestamp
//        startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -1)).timestamp
        startTimestamp = d.add(component: .month, value: -1).startOfMonth().startOfDay.timestamp
//        endTimestamp = TimeUtil.endOfMonth(date: d.add(component: .month, value: 1)).timestamp
        endTimestamp = d.add(component: .month, value: 1).endOfMonth().endOfDay.timestamp

        getTeacherEvenet()
        getTeacherBlock()
        getTeacherUnConfimReschedule()
        getLessonTypes()
        getStudentUserInfo()
    }

    func getTeacherUnConfimReschedule() {
        guard let user = ListenerService.shared.user else { return }
        switch user.currentUserDataVersion {
        case .singleTeacher:
            getTeacherUnConfimRescheduleV1()
        case .studio:
            getTeacherUnConfimRescheduleV2()
        case .unknown(version: _):
            break
        }
    }

    private func getTeacherUnConfimRescheduleV1() {
        addSubscribe(
            LessonService.lessonSchedule.getTeacherReschedule(teacherId: originalData.teacherId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKReschedule] = []
                    var doneData: [TKReschedule] = []
                    let nowDate = Date()
                    for doc in docs.documents {
                        if let doc = TKReschedule.deserialize(from: doc.data()) {
                            if doc.confirmType == .unconfirmed && Int(Double(doc.timeBefore) ?? 0) > nowDate.timestamp {
                                if doc.timeAfter != "" {
                                    if Int(Double(doc.timeBefore) ?? 0) > nowDate.timestamp {
                                        data.append(doc)
                                    }
                                } else {
                                    data.append(doc)
                                }
                            }
                            if doc.confirmType == .confirmed {
                                doneData.append(doc)
                            }
                        }
                    }
                    self.doneRescheduleData = doneData

                    self.doneRescheduleData.forEach { item in
                        print("===完成的时间=\(TimeUtil.changeTime(time: Double(item.timeBefore) ?? 0).toStringa())")
                    }

                    self.teacherNoConfirmRescheduleData = data
                    self.initCalendarData()
                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func getTeacherUnConfimRescheduleV2() {
        let followUps = ListenerService.shared.studentData.followUps
        var doneRescheduleData: [TKReschedule] = []
        var undoneRescheduleData: [TKReschedule] = []
        // 获取没有过滤的 reschedule
        for followUp in followUps where followUp.dataType == .reschedule {
            if let reschedule = followUp.rescheduleData {
                reschedule.id = followUp.id
                if followUp.status == .pending {
                    undoneRescheduleData.append(reschedule)
                } else {
                    doneRescheduleData.append(reschedule)
                }
            }
        }
        self.doneRescheduleData = doneRescheduleData
        teacherNoConfirmRescheduleData = undoneRescheduleData
    }

    func getStudentUserInfo() {
        var isLoad = false
        addSubscribe(
            UserService.user.getInfo()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        isLoad = true
                        self.userData = data
                    }
                    if let data = data[false] {
                        if !isLoad {
                            self.userData = data
                        }
                    }
                }, onError: { err in
                    print("请求错误:\(err)")
                })
        )
    }

    func initOriginalLesson() {
        let d = TimeUtil.changeTime(time: originalData.getShouldDateTime())
        dateFormatter.dateFormat = "hh:mm a"
        originalTimeLabel.text("\(dateFormatter.string(from: d))")
        originalDayLabel.text("\(d.day)")
        originalMonthLabel.text("\(TimeUtil.getMonthShortName(month: d.month))")
        if isEdit && rescheduleData.timeAfter != "" {
            // MARK: - TimeAfter 修改过的地方

            rescheduleData.getTimeAfterInterval { [weak self] time in
                guard let self = self else { return }
                let date = Date(seconds: time)
                let df = DateFormatter()
                df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"
                self.updatedTimeLabel.text("\(df.string(from: date))")
                self.updatedDayLabel.text("\(date.day)")
                self.updatedMonthLabel.text("\(TimeUtil.getMonthShortName(month: date.month))")
                self.updatedMonthLabel.textColor = ColorUtil.main
            }
        }
    }

    /// 获取EventConfig
    func getTeacherEvenet() {
        addSubscribe(
            LessonService.event.list(teacherId: originalData.teacherId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    var d: [TKEventConfigure] = []
                    for item in data.documents {
                        if let doc = TKEventConfigure.deserialize(from: item.data()) {
                            d.append(doc)
                        }
                    }
                    logger.debug("======Evenet获取成功")
                    self.eventConfig = d
                    self.initEventData()
                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func initEventData() {
        let sortData = EventUtil.getEvent(startTime: startTimestamp, endTime: endTimestamp, data: eventConfig)
        logger.debug("EventDataCount:\(sortData.count)")
        for item in sortData {
            let id = "\(item.teacherId):\(Int(item.shouldDateTime))"
            if lessonScheduleIdMap[id] == nil {
                lessonSchedule.append(item)
                lessonScheduleIdMap[id] = id
            }
        }
        if sortData.count > 0 {
            initCalendarData()
        }
    }

    /// 获取block
    func getTeacherBlock() {
        addSubscribe(
            LessonService.block.list(teacherId: originalData.teacherId)
                .subscribe(onNext: { data in
                    var d: [TKBlock] = []
                    for item in data.documents {
                        if let doc = TKBlock.deserialize(from: item.data()) {
                            d.append(doc)
                        }
                    }

                    if d.count != 0 {
                        initBlockData(data: d)
                    }
                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
        func initBlockData(data: [TKBlock]) {
            blockData = data
            logger.debug("BlockDataCount:\(data.count)")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            for item in data {
                if lessonScheduleIdMap[item.id] == nil {
                    lessonScheduleIdMap[item.id] = item.id
                    let schedule = TKLessonSchedule()
                    schedule.id = item.id
                    schedule.teacherId = item.teacherId
                    schedule.startDate = dateFormatter.string(from: TimeUtil.changeTime(time: item.startDateTime))
                    schedule.shouldDateTime = item.startDateTime
                    schedule.shouldTimeLength = Int((item.endDateTime - item.startDateTime) / 60)
                    schedule.blockData = item
                    schedule.type = .block
                    lessonSchedule.append(schedule)
                }
            }
            if data.count > 0 {
                initCalendarData()
            }
        }
    }

    /// 获取老师LessonType()

    func getLessonTypes() {
        addSubscribe(
            LessonService.lessonType.getByTeacherId(teacherId: originalData.teacherId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    logger.debug("======\(docs.from)")
                    if docs.from == .server {
                        var data: [TKLessonType] = []
                        for doc in docs.documents {
                            if let doc = TKLessonType.deserialize(from: doc.data()) {
                                data.append(doc)
                            }
                        }
                        self.lessonTypes = data
                        self.getScheduleConfig()
                    }

                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    /// 获取老师Schedule配置信息
    func getScheduleConfig() {
        addSubscribe(
            LessonService.lessonScheduleConfigure.getScheduleConfigByTeacherId(teacherId: originalData.teacherId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()

                    var data: [TKLessonScheduleConfigure] = []
                    for doc in docs.documents {
                        if let doc = TKLessonScheduleConfigure.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }
                    self.scheduleConfigs = data
                    self.initScheduleData()
                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    logger.debug("======\(err)")
                })
        )
    }

    /// 整理数据
    private func initScheduleData() {
        guard let user = ListenerService.shared.user else { return }

        navigationBar?.startLoading()
        switch user.currentUserDataVersion {
        case let .unknown(version: version):
            logger.error("错误的数据版本: \(version)")
        case .singleTeacher:
            addLesson(localData: [])
        case .studio:
            getLessonScheduleV2()
        }
        LessonService.lessonSchedule.studentRefreshLessonSchedule(config: scheduleConfigs, lessonTypes: lessonTypes, startTime: startTimestamp, endTime: endTimestamp)
            .done { [weak self] _ in
                guard let self = self else { return }
                switch user.currentUserDataVersion {
                case let .unknown(version: version):
                    logger.error("错误的数据版本: \(version)")
                case .singleTeacher:
                    self.addLesson(localData: [])
                case .studio:
                    self.getLessonScheduleV2()
                }
            }
            .catch { error in
                logger.error("刷新课程失败: \(error)")
            }
    }

    private func initCalendarData() {
        logger.debug("调用calendar data")
        func initData(rescheduledLessons: [TKLessonSchedule]) {
            var shouldTime: [LessonService.LessonSchedule.ShouldTime] = []
            lessonSchedule.sort { x, y -> Bool in
                x.shouldDateTime < y.shouldDateTime
            }
            dateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
            var dayOffTimes: [Int] = []
            var shouldMap: [Int: [LessonService.LessonSchedule.ShouldTime]] = [:]

            for item in lessonSchedule.enumerated() {
                if let config = scheduleConfigs.first(where: { $0.id == item.element.lessonScheduleConfigId }) {
                    if config.endType == .endAtSomeday {
                        if config.endDate < item.element.shouldDateTime {
                            // 当前结束时间小于当前课的时间，这个课不正常，过滤掉
                            continue
                        }
                    }

                    let configHM = config.startDateTime.toLocalFormat("hh:mm")
                    let lessonHM = item.element.getShouldDateTime().toLocalFormat("hh:mm")
                    if configHM != lessonHM && rescheduledLessons.first(where: { $0.rescheduleId == item.element.id }) == nil {
                        continue
                    }
                }

                if item.element.rescheduled || item.element.rescheduleId.isNotEmpty {
                    continue
                }
                var data = LessonService.LessonSchedule.ShouldTime()
                data.id = item.element.id
                data.shouldDateTime = Int(item.element.getShouldDateTime())
                data.timeLength = item.element.shouldTimeLength
//                data.time = dateFormatter.string(from: TimeUtil.changeTime(time: Double(item.element.getShouldDateTime())))
                data.time = TimeInterval(data.shouldDateTime).toLocalFormat("yyyy-MM-dd hh:mm")
                data.index = item.offset

                shouldTime.append(data)
//                let startTime = TimeUtil.changeTime(time: Double(item.element.getShouldDateTime())).startOfDay.timestamp
                let startTime = DateInRegion(seconds: item.element.getShouldDateTime(), region: .localRegion).dateAtStartOf(.day).timestamp
                var list = shouldMap[startTime]
                if list == nil {
                    list = []
                }
                list!.append(data)
                list = list!.filterDuplicates({ $0.id })
                shouldMap[startTime] = list
                if data.timeLength == 1439 {
                    dayOffTimes.append(startTime)
                }
            }
            // 此处判断是判断是否有全天的day off 或者日程 如果有
            if dayOffTimes.count > 0 {
                dayOffTimes = dayOffTimes.filterDuplicates({ $0 })
                var needDeleteIndexs: [Int] = []
                for item in dayOffTimes {
                    if let should = shouldMap[item] {
                        for j in should.enumerated() {
                            if j.element.timeLength != 1439 {
                                needDeleteIndexs.append(j.element.index)
                            }
                        }
                    }
                }
                needDeleteIndexs.sort { a, b -> Bool in
                    a > b
                }
                for item in needDeleteIndexs {
                    shouldTime.remove(at: item)
                }
            }
            let sTime = Date().startOfDay.timestamp
            var eTime = previousEndDate.endOfDay.timestamp
            if !isForCredit {
                if policyData.limitDays != 0 {
                    let policyTime = Date().endOfDay.add(component: .day, value: policyData.limitDays).timestamp
                    if eTime > policyTime {
                        eTime = policyTime
                    }
                }
            }

            var availableData: [Int: [AvailableTimes]] = [:]
            guard let policy = policyData else { return }
            if let rescheduleData {
                if rescheduleData.senderId == originalData.teacherId {
                    policy.allowMakeup = true
                    policy.allowReschedule = true
                    policy.allowRefund = true
                }
            }
            logger.debug("准备获取可用时间: \(TimeInterval(sTime).toLocalFormat("yyyy-MM-dd HH:mm:ss")) -> \(TimeInterval(eTime).toLocalFormat("yyyy-MM-dd HH:mm:ss")) | timeLength: \(originalData.shouldTimeLength) | inAvailableTimes: \(shouldTime.count) | 课程数量: \(lessonSchedule.count)")
            addSubscribe(
                LessonService.lessonSchedule.studentGetTeacherAvailableTime(rangeStart: sTime, rangeEnd: eTime, timeLength: originalData.shouldTimeLength, inAvailableTimes: shouldTime, policy: policy)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default)) // 后台构建序列
                    .subscribe(onNext: { [weak self] data in
                        guard let self = self else { return }
                        OperationQueue.main.addOperation {
                            logger.debug("获取到的availableTime: \(data.count) | 完成的reschedule data: \(self.doneRescheduleData.count) | policy里的时间： \(self.policyData.lessonHours)")
                            var nowTime = Date().timestamp

                            if self.policyData.rescheduleNoticeRequired != 0 {
                                nowTime = nowTime + self.policyData.rescheduleNoticeRequired * 60 * 60
                            }
                            for item in self.doneRescheduleData where Int(Double(item.timeBefore) ?? 0) > nowTime {
                                let timestamp = Int(Double(item.timeBefore) ?? 0)
                                guard timestamp < Int(self.originalData.getShouldDateTime()) || timestamp > (Int(self.originalData.getShouldDateTime()) + (self.originalData.shouldTimeLength * 60)) else {
                                    continue
                                }
                                let startOfDay = TimeUtil.changeTime(time: Double(item.timeBefore) ?? 0).startOfDay.timestamp
                                var d = AvailableTimes()

                                d.timestamp = timestamp
                                d.isTop = true
                                d.endTimestamp = timestamp + self.originalData.shouldTimeLength
                                if availableData[startOfDay] == nil {
                                    availableData[startOfDay] = []
                                    availableData[startOfDay]!.append(d)
                                } else {
                                    let isHave = availableData[startOfDay]!.contains { time -> Bool in
                                        time.timestamp == timestamp
                                    }
                                    if !isHave {
                                        availableData[startOfDay]!.append(d)
                                    }
                                }
                            }

                            for item in data where item.timestamp > nowTime {
                                let startOfDay = TimeUtil.changeTime(time: Double(item.timestamp)).startOfDay.timestamp
                                if availableData[startOfDay] == nil {
                                    availableData[startOfDay] = []
                                    availableData[startOfDay]!.append(item)
                                } else {
                                    let isHave = availableData[startOfDay]!.contains { time -> Bool in
                                        time.timestamp == item.timestamp
                                    }
                                    if !isHave {
                                        availableData[startOfDay]!.append(item)
                                    }
                                }
                            }
                            for (key, value) in availableData {
                                logger.debug("整理后的可用时间： \(TimeInterval(key).toLocalFormat("yyyy-MM-dd HH:mm:ss")) -> \(value.compactMap({ TimeInterval($0.timestamp).toLocalFormat("yyyy-MM-dd HH:mm:ss") }))")
                            }
                            var removeTimes: [Int] = []
                            if self.policyData.lessonHours.count > 0 {
                                for item in shouldMap {
//                                    let itemDate = TimeUtil.changeTime(time: Double(item.key))
//                                    let weekDay = itemDate.getWeekday()

                                    let date = DateInRegion(seconds: TimeInterval(item.key), region: .localRegion)
                                    let weekDay = date.weekday - 1

                                    var totalHours: CGFloat = 0
//                                    item.value.filterDuplicates({ $0.shouldDateTime }).forEachItems { timeItem, _ in
//                                        totalHours += CGFloat(timeItem.timeLength)
//                                    }
                                    item.value.forEachItems { timeItem, _ in
                                        totalHours += CGFloat(timeItem.timeLength)
                                    }
                                    totalHours += CGFloat(self.originalData.shouldTimeLength)
                                    totalHours = totalHours / 60
                                    if date.dateAtStartOf(.day).toLocalFormat("yyyy-MM-dd HH:mm:ss") == "2023-12-28 00:00:00" {
                                        logger.debug("当前特殊时间: \(item.value.toJSONString() ?? "")")
                                    }
                                    logger.debug("当前计算的总的时间: \(totalHours) | 当前日期的总的可用时间: \(self.policyData.lessonHours[weekDay]) | 当前日期： \(date.dateAtStartOf(.day).toLocalFormat("yyyy-MM-dd HH:mm:ss")) | 当前时间是否要过滤掉：\(totalHours > CGFloat(self.policyData.lessonHours[weekDay]))")
                                    if totalHours > CGFloat(self.policyData.lessonHours[weekDay]) {
                                        removeTimes.append(date.dateAtStartOf(.day).timestamp)
                                    }
                                }
                            }
                            logger.debug("要删除的时间: \(removeTimes.compactMap({ DateInRegion(seconds: TimeInterval($0), region: .localRegion).toLocalFormat("yyyy-MM-dd HH:mm:ss") }))")

                            for item in availableData {
                                let isHave = removeTimes.contains { d -> Bool in
                                    d == item.key
                                }
                                if isHave {
                                    availableData[item.key] = nil
                                } else {
                                    if self.policyData.lessonHours.count > 0 {
                                        let itemDate = TimeUtil.changeTime(time: Double(item.key))
                                        let weekDay = itemDate.getWeekday()
                                        let time: CGFloat = CGFloat(self.originalData.shouldTimeLength) / CGFloat(60)
                                        if time > CGFloat(self.policyData.lessonHours[weekDay]) {
                                            availableData[item.key] = nil
                                        }
                                    }
                                }
                            }
                            // 获取课程，排除所有课程使用的时间
                            LessonService.lessonSchedule.studentGetTeacherLessonSchedules(startTime: TimeInterval(sTime), endTime: TimeInterval(eTime), teacherId: self.originalData.teacherId)
                                .done { lessonSchedules in
                                    for (dayTime, times) in availableData {
                                        let _times = times.filter { time in
                                            for lesson in lessonSchedules {
                                                let endTime = lesson.shouldDateTime + TimeInterval(lesson.shouldTimeLength) * 60
                                                if endTime >= TimeInterval(time.timestamp) && lesson.shouldDateTime <= TimeInterval(time.endTimestamp) {
                                                    return false
                                                }
                                            }

                                            return true
                                        }
                                        availableData[dayTime] = _times
                                    }
//                                    let times = availableData.compactMap({ key, values in
//                                        let valueString = values.compactMap({ value in
//                                            "\(TimeInterval(value.timestamp).toLocalFormat("yyyy-MM-dd HH:mm:ss")) - \(TimeInterval(value.endTimestamp).toLocalFormat("yyyy-MM-dd HH:mm:ss"))"
//                                        })
//                                        return "\(key) | \(valueString)"
//                                    })
//                                    logger.debug("开始获取可用时间  整理后的数据, 条件： \(TimeInterval(sTime).toLocalFormat("yyyy-MM-dd HH:mm:ss")) -> \(TimeInterval(eTime).toLocalFormat("yyyy-MM-dd HH:mm:ss")) 结果：\n\(times)")
                                    self.navigationBar?.stopLoading()
                                    availableData = self.filterAvailiableTimes(availableData)
                                    self.dateTimeView.refreshCancelData(data: availableData)
                                }
                                .catch { error in
                                    logger.debug("获取失败:\(error)")
                                }
                        }
                    }, onError: { err in
                        logger.debug("获取失败:\(err)")
                    })
            )
        }

        func preinitData() {
            // 获取所有的rescheduleId不为空的lesson
            guard let originalData else { return }
            LessonService.lessonSchedule.getLessonScheduleWithRescheduled(teacherId: originalData.teacherId, studioId: originalData.studioId)
                .done { rescheduledLessons in
                    initData(rescheduledLessons: rescheduledLessons)
                }
                .catch { _ in
                    initData(rescheduledLessons: [])
                }
        }

        print("=====teacherNoConfirmRescheduleData个数===\(teacherNoConfirmRescheduleData.count)")
        if teacherNoConfirmRescheduleData.count > 0 {
            let ids = teacherNoConfirmRescheduleData.compactMap { $0.scheduleId }
            LessonService.lessonSchedule.getLessonSchedules(ids: ids)
                .done { [weak self] result in
                    guard let self = self else { return }
                    let map = result.map
                    // 获取config
                    let configs = ListenerService.shared.getLessonScheduleConfigs()
                    var configsMap: [String: TKLessonScheduleConfigure] = [:]
                    configs.forEach { item in
                        configsMap[item.id] = item
                    }
                    // Reschedule 对应的时间
                    var timeMap: [String: Int] = [:]
                    self.teacherNoConfirmRescheduleData.forEach { reschedule in
                        if let lessonSchedule = map[reschedule.scheduleId], let config = configsMap[lessonSchedule.lessonScheduleConfigId] {
                            let diff = TimeUtil.getStartTimeDiffWithLocalTime(startTimestamp: Int(config.startDateTime), showTimestamp: Int(reschedule.timeAfter) ?? 0)
                            timeMap[reschedule.id] = diff
                        }
                    }
                    for item in self.teacherNoConfirmRescheduleData where item.timeAfter != "" {
                        let schedule = TKLessonSchedule()
                        schedule.id = "\(item.id):reschedule"
                        schedule.teacherId = item.teacherId
                        schedule.studentId = item.studentId
                        schedule.shouldDateTime = (Double(item.timeAfter) ?? 0.0) + Double((timeMap[item.id] ?? 0) * 3600)
                        print("====时间:\(schedule.shouldDateTime)===\(TimeUtil.changeTime(time: schedule.shouldDateTime).toStringa())")
                        schedule.shouldTimeLength = item.shouldTimeLength
                        schedule.type = .block
                        self.lessonSchedule.append(schedule)
                    }
                    preinitData()
                }
                .catch { [weak self] _ in
                    guard let self = self else { return }
                    for item in self.teacherNoConfirmRescheduleData where item.timeAfter != "" {
                        let schedule = TKLessonSchedule()
                        schedule.id = "\(item.id):reschedule"
                        schedule.teacherId = item.teacherId
                        schedule.studentId = item.studentId
                        schedule.shouldDateTime = Double(item.timeAfter)!
                        schedule.shouldTimeLength = item.shouldTimeLength
                        schedule.type = .block
                        self.lessonSchedule.append(schedule)
                    }
                    preinitData()
                }
        } else {
            preinitData()
        }
    }

    private func initScheduleStudent() {
        for item in lessonSchedule.enumerated() where lessonSchedule[item.offset].id == "" {
            lessonSchedule[item.offset].id = "\(item.element.teacherId):\(item.element.studentId):\(Int(item.element.shouldDateTime))"
        }
    }

    private func addLesson(localData: [TKLessonSchedule]) {
        logger.debug("准备获取lessonSchedule数据,参数: \(originalData.teacherId) | \(startTimestamp) | \(endTimestamp)")
        addSubscribe(
            LessonService.lessonSchedule.getScheduleList(teacherID: originalData.teacherId, startTime: startTimestamp, endTime: endTimestamp)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKLessonSchedule] = []
                    for doc in docs.documents {
                        if let d = TKLessonSchedule.deserialize(from: doc.data()) {
                            var isNext = false
                            for item in self.scheduleConfigs where item.id == d.lessonScheduleConfigId {
                                isNext = true
                            }
                            guard isNext else { continue }
                            d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
                            var isHave = false
                            for item in self.lessonSchedule.enumerated().reversed() where item.element.id == d.id {
                                isHave = true
                                if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
                                    self.lessonSchedule.remove(at: item.offset)
                                } else {
                                    self.lessonSchedule[item.offset].refreshData(newData: d)
                                }
                            }
                            if !isHave {
                                if self.lessonScheduleIdMap[d.id] == nil {
                                    self.lessonScheduleIdMap[d.id] = d.id
                                    if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
                                        continue
                                    }
                                    self.lessonSchedule.append(d)
                                }
                            }
                            data.append(d)
                        }
                    }
                    logger.debug("获取到的lessonSchedule: \(self.lessonSchedule.count)")
                    self.initScheduleStudent()
                    self.initCalendarData()
                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func getLessonScheduleV2() {
        guard let originalData else { return }
        StudentService.lessons.getLessonSchedule(withTeacherId: originalData.teacherId, dateTimeRange: DateTimeRange(startTime: TimeInterval(startTimestamp), endTime: TimeInterval(endTimestamp)))
            .done { [weak self] lessons in
                guard let self = self else { return }
                for d in lessons {
                    var isNext = false
                    for item in self.scheduleConfigs where item.id == d.lessonScheduleConfigId {
                        isNext = true
                    }
                    guard isNext else { continue }
                    d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
                    var isHave = false
                    for item in self.lessonSchedule.enumerated().reversed() where item.element.id == d.id {
                        isHave = true
                        if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
                            self.lessonSchedule.remove(at: item.offset)
                        } else {
                            self.lessonSchedule[item.offset].refreshData(newData: d)
                        }
                    }
                    if !isHave {
                        if self.lessonScheduleIdMap[d.id] == nil {
                            self.lessonScheduleIdMap[d.id] = d.id
                            if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
                                continue
                            }
                            self.lessonSchedule.append(d)
                        }
                    }
                }
                logger.debug("获取到的lessonSchedule: \(self.lessonSchedule.count)")
                self.initScheduleStudent()
                self.initCalendarData()
            }
            .catch { error in
                logger.error("获取课程失败: \(error)")
            }

//        DatabaseService.collections.lessonSchedule()
//            .whereField("studentId", isEqualTo: originalData.studentId)
//            .whereField("studioId", isEqualTo: originalData.studioId)
//            .whereField("shouldDateTime", isLessThanOrEqualTo: endTimestamp)
//            .whereField("shouldDateTime", isGreaterThanOrEqualTo: startTimestamp)
//            .getDocumentsData(TKLessonSchedule.self) { [weak self] lessons, error in
//                guard let self = self else { return }
//                if let error {
//                    logger.error("获取课程失败: \(error)")
//                } else {
//                    for d in lessons {
//                        var isNext = false
//                        for item in self.scheduleConfigs where item.id == d.lessonScheduleConfigId {
//                            isNext = true
//                        }
//                        guard isNext else { continue }
//                        d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
//                        var isHave = false
//                        for item in self.lessonSchedule.enumerated().reversed() where item.element.id == d.id {
//                            isHave = true
//                            if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
//                                self.lessonSchedule.remove(at: item.offset)
//                            } else {
//                                self.lessonSchedule[item.offset].refreshData(newData: d)
//                            }
//                        }
//                        if !isHave {
//                            if self.lessonScheduleIdMap[d.id] == nil {
//                                self.lessonScheduleIdMap[d.id] = d.id
//                                if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
//                                    continue
//                                }
//                                self.lessonSchedule.append(d)
//                            }
//                        }
//                    }
//                    logger.debug("获取到的lessonSchedule: \(self.lessonSchedule.count)")
//                    self.initScheduleStudent()
//                    self.initCalendarData()
//                }
//            }
    }

    /// Reschedule
    private func reschedule() {
        logger.debug("执行Reschedule")
        showFullScreenLoading()
        TimeUtil.getTimeForRescheduleTimeSelector(localSelectedTime: selectDate.timeIntervalSince1970, lessonConfigId: originalData.lessonScheduleConfigId)
            .done { [weak self] dateTimestamp in
                guard let self = self else { return }
                let time = "\(Date().timestamp)"
                let reschedule = TKReschedule()
                reschedule.id = self.originalData.id
                reschedule.teacherId = self.originalData.teacherId
                reschedule.studentId = self.originalData.studentId
                reschedule.scheduleId = self.originalData.id
                reschedule.senderId = self.originalData.studentId
                reschedule.confirmerId = self.originalData.teacherId
                reschedule.confirmType = .unconfirmed
                reschedule.shouldTimeLength = self.originalData.shouldTimeLength

                // MARK: - TimeBefore 要修改的地方

                reschedule.timeBefore = "\(self.originalData.shouldDateTime)"
                reschedule.timeAfter = "\(dateTimestamp)"
                reschedule.createTime = time
                reschedule.updateTime = time
                let id = reschedule.id
                if self.selectedTimeIsPreferred {
                    // 所选时间是推荐时间 不需要老师确认
                    let newScheduleData = TKLessonSchedule()
                    newScheduleData.id = "\(self.originalData.teacherId):\(self.originalData.studentId):\(Int(dateTimestamp))"
                    newScheduleData.instrumentId = self.originalData.instrumentId
                    newScheduleData.lessonTypeId = self.originalData.lessonTypeId
                    newScheduleData.lessonScheduleConfigId = self.originalData.lessonScheduleConfigId
                    newScheduleData.teacherId = self.originalData.teacherId
                    newScheduleData.studentId = self.originalData.studentId
                    newScheduleData.shouldDateTime = dateTimestamp
                    newScheduleData.shouldTimeLength = self.originalData.shouldTimeLength
                    newScheduleData.createTime = time
                    newScheduleData.updateTime = time
                    reschedule.confirmType = .confirmed
                    reschedule.rescheduleId = newScheduleData.id
                    self.addSubscribe(
                        LessonService.lessonSchedule.rescheduleNoNeedConfirm(schedule: self.originalData, reschedule: reschedule, newSchedule: newScheduleData)
                            .subscribe(onNext: { [weak self] _ in
                                guard let self = self else { return }
                                CommonsService.shared.sendEmailNotificationForRescheduleNewTime(rescheduleId: id, type: 3, msg: "")
                                sendRescheduleHis()
                                self.hideFullScreenLoading()
                                if self.isMianController {
                                    self.dismiss(animated: true) {
                                        TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                                    }
                                } else {
                                    self.dismiss(animated: true, completion: {
                                        TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                                    })
                                }

                            }, onError: { [weak self] err in
                                logger.debug("======\(err)")
                                self?.hideFullScreenLoading()

                                TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                            })
                    )

                } else {
                    // 所选时间不是推荐时间 需要老师确认
                    self.addSubscribe(
                        LessonService.lessonSchedule.reschedule(schedule: [self.originalData], reschedule: [reschedule])
                            .subscribe(onNext: { [weak self] _ in
                                guard let self = self else { return }
                                sendRescheduleHis()

                                self.hideFullScreenLoading()
                                if self.isMianController {
                                    self.dismiss(animated: true) {
                                        TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                                    }
                                } else {
                                    self.dismiss(animated: true, completion: {
                                        TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                                    })
                                }

                            }, onError: { [weak self] err in
                                logger.debug("======\(err)")
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
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                logger.error("获取时间失败: \(error)")
                self.hideFullScreenLoading()
                TKToast.show(msg: TipMsg.connectionFailed, style: .error)
            }

        func sendRescheduleHis() {
            let time = "\(Date().timestamp)"

            let his = TKRescheduleMakeupRefundHistory()

            his.updateTime = time
            his.createTime = time
            his.id = time
            if let id = IDUtil.nextId(group: .lesson) {
                his.id = "\(id)"
            }
            his.teacherId = originalData.teacherId
            his.studentId = originalData.studentId
            his.type = .reschedule
            UserService.teacher.setRescheduleMakeupRefundHistory(data: his)
        }
    }

    private func rescheduleV2() {
        guard let lessonSchedule = originalData else {
            logger.error("无法获取到原始Lesson")
            return
        }
        var studentData: TKStudent?
        if let student = ListenerService.shared.studentData.studentData {
            studentData = student
        } else if let student = StudentService.student {
            studentData = student
        } else if let student = ParentService.shared.currentStudent {
            studentData = student
        }
        guard let studentData else {
            logger.error("无法获取到学生信息")
            TKToast.show(msg: "Can not fetch student data, please try again later.", style: .error)
            return
        }
        logger.debug("执行RescheduleV2")
        showFullScreenLoading()
        TimeUtil.getTimeForRescheduleTimeSelector(localSelectedTime: selectDate.timeIntervalSince1970, lessonConfigId: originalData.lessonScheduleConfigId)
            .done { [weak self] dateTimestamp in
                guard let self = self else { return }
                FunctionsCaller()
                    .name("scheduleService-sendReschedule")
                    .data([
                        "studioId": studentData.studioId,
                        "subStudioId": studentData.subStudioId,
                        "newTime": dateTimestamp,
                        "lessonScheduleId": lessonSchedule.id,
                    ])
                    .call { _, error in
                        self.hideFullScreenLoading()
                        if let error {
                            logger.error("发送reschedule失败: \(error)")
                            TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                        } else {
                            logger.debug("发送reschedule 成功")
                            EventBus.send(EventBus.CHANGE_RESCHEDULE)
                            self.dismiss(animated: true) {
                                TKToast.show(msg: "Successfully", style: .success)
                            }
                        }
                    }
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                logger.error("获取时间失败: \(error)")
                TKToast.show(msg: TipMsg.connectionFailed, style: .error)
            }
    }

    /// 老师发起的 Reschedule
    func teacherInitiatedReschedule() {
        logger.debug("老师发起的 Reschedule")
        showFullScreenLoading()
        LessonService.lessonSchedule.getReschedule(id: rescheduleData.id)
            .done { [weak self] reschedule in
                guard let self = self else { return }
                TimeUtil.getTimeForRescheduleTimeSelector(localSelectedTime: self.selectDate.timeIntervalSince1970, lessonScheduleId: reschedule.scheduleId)
                    .done { dateTimestamp in
                        let newScheduleData = TKLessonSchedule()
                        let time = "\(Date().timestamp)"
                        newScheduleData.id = "\(self.originalData.teacherId):\(self.originalData.studentId):\(Int(dateTimestamp))"
                        newScheduleData.instrumentId = self.originalData.instrumentId
                        newScheduleData.lessonTypeId = self.originalData.lessonTypeId
                        newScheduleData.lessonScheduleConfigId = self.originalData.lessonScheduleConfigId
                        newScheduleData.teacherId = self.originalData.teacherId
                        newScheduleData.studentId = self.originalData.studentId
                        newScheduleData.shouldDateTime = dateTimestamp
                        newScheduleData.shouldTimeLength = self.originalData.shouldTimeLength
                        newScheduleData.createTime = time
                        newScheduleData.updateTime = time
                        self.addSubscribe(
                            LessonService.lessonSchedule.studentRescheduleTeacherInitiated(rescheduleData: reschedule, newSchedule: newScheduleData)
                                .subscribe(onNext: { [weak self] _ in
                                    guard let self = self else { return }
                                    self.hideFullScreenLoading()

                                    if self.isMianController {
                                        self.dismiss(animated: true) {
                                            TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                                        }
                                    } else {
                                        self.dismiss(animated: true, completion: {
                                            TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                                        })
                                    }
                                }, onError: { [weak self] err in
                                    guard let self = self else { return }
                                    logger.debug("当前的错误: \(err)")
                                    DispatchQueue.main.async {
                                        let error = err as NSError
                                        if error.code == 0 {
                                            var userId = ""
                                            if let uid = UserService.user.id() {
                                                if self.rescheduleData.teacherId == uid {
                                                    userId = self.rescheduleData.studentId
                                                } else {
                                                    userId = self.rescheduleData.teacherId
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
                                        } else if error.code == 1 {
                                            self.hideFullScreenLoading()
                                            TKAlert.show(target: self, title: "Too late", message: TipMsg.updateLessonAndTryLaterWhenOccupieded, buttonString: "SEE UPDATE") {
                                            }
                                            return
                                        }
                                        self.hideFullScreenLoading()
                                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                                    }
                                })
                        )
                    }
                    .catch { error in
                        logger.error("获取时间失败: \(error)")
                        self.hideFullScreenLoading()
                    }
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                logger.error("获取reschedule失败: \(error)")
                self.hideFullScreenLoading()
                TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
            }
    }

    func teacherInitiatedRescheduleV2() {
        logger.debug("老师发起的 Reschedule v2")
        showFullScreenLoading()
        // 调用api
        TimeUtil.getTimeForRescheduleTimeSelector(localSelectedTime: selectDate.timeIntervalSince1970, lessonScheduleId: rescheduleData.scheduleId)
            .done { [weak self] dateTimestamp in
                guard let self = self else { return }
                logger.debug("获取到的时间: \(dateTimestamp)")
                callFunction("scheduleService-updateReschedule", withData: ["id": self.rescheduleData.id, "newTime": dateTimestamp]) { _, error in
                    self.hideFullScreenLoading()
                    if let error {
                        logger.error("更改reschedule失败: \(error)")
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    } else {
                        EventBus.send(EventBus.CHANGE_RESCHEDULE)
                        self.dismiss(animated: true) {
                            TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                        }
                    }
                }
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                logger.error("选择时间失败: \(error)")
                self.hideFullScreenLoading()
                TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
            }
    }

    func refund() {
        guard makeUpData != nil else {
            TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
            return
        }
        showFullScreenLoading()
        addSubscribe(
            LessonService.lessonSchedule.updateCancellation(id: makeUpData.id, data: ["type": 2])
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    sendRefundHis()
                    EventBus.send(EventBus.CHANGE_SCHEDULE)

                    if self.isMianController {
                        self.dismiss(animated: true) {
                            TKToast.show(msg: TipMsg.refundSuccessful, style: .success)
                        }
                    } else {
//                        if let p = self.presentingViewController!.presentingViewController {
//                            p.dismiss(animated: true, completion: {
//                                TKToast.show(msg: TipMsg.refundSuccessful, style: .success)
//                            })
//                        }
                        self.dismiss(animated: true, completion: {
                            TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                        })
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("======\(err)")
                })
        )
        func sendRefundHis() {
            let time = "\(Date().timestamp)"

            let his = TKRescheduleMakeupRefundHistory()

            his.updateTime = time
            his.createTime = time
            his.id = time
            if let id = IDUtil.nextId(group: .lesson) {
                his.id = "\(id)"
            }
            his.teacherId = originalData.teacherId
            his.studentId = originalData.studentId
            his.type = .refund
            UserService.teacher.setRescheduleMakeupRefundHistory(data: his)
        }
    }

    func makeUp() {
        guard makeUpData != nil else {
            TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
            return
        }
        showFullScreenLoading()
        TimeUtil.getTimeForRescheduleTimeSelector(localSelectedTime: selectDate.timeIntervalSince1970, lessonConfigId: originalData.lessonScheduleConfigId)
            .done { [weak self] dateTimestamp in
                guard let self = self else { return }
                let newScheduleData = TKLessonSchedule()
                let time = "\(Date().timestamp)"
                newScheduleData.id = "\(self.originalData.teacherId):\(self.originalData.studentId):\(Int(dateTimestamp))"
                newScheduleData.instrumentId = self.originalData.instrumentId
                newScheduleData.lessonTypeId = self.originalData.lessonTypeId
                newScheduleData.lessonScheduleConfigId = self.originalData.lessonScheduleConfigId
                newScheduleData.teacherId = self.originalData.teacherId
                newScheduleData.studentId = self.originalData.studentId
                newScheduleData.shouldDateTime = dateTimestamp
                newScheduleData.shouldTimeLength = self.originalData.shouldTimeLength
                newScheduleData.createTime = time
                newScheduleData.updateTime = time
                if self.selectedTimeIsPreferred {
                    self.addSubscribe(
                        LessonService.lessonSchedule.makeUpNoNeedConfirm(makeUpDate: self.makeUpData, newSchedule: newScheduleData, oldSchedule: self.originalData)
                            .subscribe(onNext: { [weak self] _ in
                                guard let self = self else { return }
                                self.hideFullScreenLoading()
                                if self.isMianController {
                                    self.dismiss(animated: true) {
                                        TKToast.show(msg: TipMsg.makeupSuccessful, style: .success)
                                    }
                                } else {
                                    self.dismiss(animated: true, completion: {
                                        TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                                    })
                                }
                            }, onError: { [weak self] err in
                                guard let self = self else { return }
                                self.hideFullScreenLoading()
                                TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                                logger.debug("======\(err)")
                            })
                    )
                } else {
                    self.addSubscribe(
                        LessonService.lessonSchedule.makeUpLesson(makeUpDate: self.makeUpData, newSchedule: newScheduleData, oldSchedule: self.originalData)
                            .subscribe(onNext: { [weak self] _ in
                                guard let self = self else { return }
                                self.hideFullScreenLoading()
                                if self.isMianController {
                                    self.dismiss(animated: true) {
                                        TKToast.show(msg: TipMsg.makeupSuccessful, style: .success)
                                    }
                                } else {
                                    self.dismiss(animated: true, completion: {
                                        TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                                    })
                                }
                            }, onError: { [weak self] err in
                                guard let self = self else { return }
                                self.hideFullScreenLoading()
                                TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                                logger.debug("======\(err)")
                            })
                    )
                }
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                logger.error("获取时间失败: \(error)")
                TKToast.show(msg: TipMsg.connectionFailed, style: .error)
            }
    }

    private func showCancelLessonAlert(type: Int) {
        // 1:不退款也不可以makeup 2:Makeup 3:退款 4:不可以cancle
        hideFullScreenLoading()
        logger.debug("======\(type)")
        var title = ""
        var message = ""
        switch type {
        case 1:
            title = "Cancel lesson?"
            message = "You will NOT receive credit if you cancel."
            let controller = SL.SLAlert()
            controller.modalPresentationStyle = .custom
            controller.titleString = title
            controller.rightButtonColor = ColorUtil.main
            controller.leftButtonColor = ColorUtil.red
            controller.rightButtonString = "GO BACK"
            controller.leftButtonString = "CANCEL NOW"
            controller.messageString = message
            controller.leftButtonAction = {
                [weak self] in
                guard let self = self else { return }
                self.addCancellation(type: 1, schedule: self.originalData)
            }
            controller.rightButtonAction = {
            }
            controller.leftButtonFont = FontUtil.bold(size: 13)
            controller.rightButtonFont = FontUtil.bold(size: 13)
            present(controller, animated: false, completion: nil)

            break
        case 2:
            title = "Cancel lesson?"
            message = "You will receive a credit to reschedule at a later date if cancallation has been made at this moment."
//            SL.Alert.show(target: self, title: title, message: message, leftButttonString: "No", rightButtonString: "Yes", rightButtonColor: ColorUtil.red, leftButtonAction: {
//            }) { [weak self] in
//                guard let self = self else { return }
//                // 多了一条MakeUp的信息
//                self.addCancellation(type: 2, schedule: self.originalData)
//            }
//

            let controller = SL.SLAlert()
            controller.modalPresentationStyle = .custom
            controller.titleString = title
            controller.rightButtonColor = ColorUtil.main
            controller.leftButtonColor = ColorUtil.red
            controller.rightButtonString = "GO BACK"
            controller.leftButtonString = "CANCEL NOW"
            controller.leftButtonAction = {
                [weak self] in
                guard let self = self else { return }
                self.addCancellation(type: 2, schedule: self.originalData)
            }
            controller.rightButtonAction = {
            }
            controller.messageString = message
            controller.leftButtonFont = FontUtil.bold(size: 13)
            controller.rightButtonFont = FontUtil.bold(size: 13)
            present(controller, animated: false, completion: nil)

            break
        case 3:
            getLessonType(schedule: originalData)
            break
        case 4:
            break
        default:
            break
        }
    }

    private func addCancellation(type: Int, schedule: TKLessonSchedule) {
        // 1:不退款也不可以makeup 2:Makeup 3:退款
        showFullScreenLoading()
        let time = "\(Date().timestamp)"
        let cancellationData = TKLessonCancellation()
        cancellationData.id = schedule.id
        cancellationData.oldScheduleId = schedule.id
        var sendType = 0
        if type == 1 {
            cancellationData.type = .noRefundAndMakeup
            sendType = -1
        } else if type == 2 {
            cancellationData.type = .noNewSchedule
            sendType = 0
        } else {
            cancellationData.type = .refund
            sendType = 2
        }
        cancellationData.studentId = schedule.studentId
        cancellationData.teacherId = schedule.teacherId
        cancellationData.timeBefore = "\(schedule.shouldDateTime)"
        cancellationData.createTime = time
        cancellationData.updateTime = time

        addSubscribe(
            LessonService.lessonSchedule.cancelSchedule(data: cancellationData, rescheduleId: rescheduleData.id)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }

                    self.hideFullScreenLoading()
                    sendHis()
                    if let userData = self.userData {
                        CommonsService.shared.sendEmailToTeacherForCancellation(studentName: userData.name, lessonStartTime: Int(schedule.getShouldDateTime()), teacherId: schedule.teacherId, type: sendType)
                    }

                    if self.isMianController {
                        self.dismiss(animated: true) {
                            TKToast.show(msg: TipMsg.cancellationSuccessful, style: .success)
                        }
                    } else {
//                        if let p = self.presentingViewController!.presentingViewController {
//                            p.dismiss(animated: true, completion: {
//                                TKToast.show(msg: TipMsg.cancellationSuccessful, style: .success)
//                            })
//                        }
                        self.dismiss(animated: true, completion: {
                            TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                        })
                    }

                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("获取失败:\(err)")
                })
        )

        func sendHis() {
            if type != 1 {
                let time = "\(Date().timestamp)"

                let his = TKRescheduleMakeupRefundHistory()

                his.updateTime = time
                his.createTime = time
                his.id = time
                if let id = IDUtil.nextId(group: .lesson) {
                    his.id = "\(id)"
                }
                his.teacherId = schedule.teacherId
                his.studentId = schedule.studentId
                if type == 2 {
                    his.type = .makeup
                } else {
                    his.type = .refund
                }
                UserService.teacher.setRescheduleMakeupRefundHistory(data: his)
            }
        }
    }

    private func getLessonType(schedule: TKLessonSchedule) {
        let title = "Cancel lesson?"
        let remainingTime = Date().timestamp + policyData.refundNoticeRequired * 60 * 60
        let hour = CGFloat((schedule.shouldDateTime - Double(remainingTime)) / 60 / 60).roundTo(places: 1)
        let message = "You will receive credit if you cancel within the next \(hour) hours"
//        SL.Alert.show(target: self, title: title, message: message, leftButttonString: "No", rightButtonString: "Yes", rightButtonColor: ColorUtil.red, leftButtonAction: {
//        }) { [weak self] in
//            self?.addCancellation(type: 3, schedule: schedule)
//        }
        let controller = SL.SLAlert()
        controller.modalPresentationStyle = .custom
        controller.titleString = title
        controller.rightButtonColor = ColorUtil.main
        controller.leftButtonColor = ColorUtil.red
        controller.rightButtonString = "GO BACK"
        controller.leftButtonString = "CANCEL NOW"
        controller.messageString = message
        controller.leftButtonAction = {
            [weak self] in
            guard let self = self else { return }
            self.addCancellation(type: 3, schedule: schedule)
        }
        controller.rightButtonAction = {
        }
        controller.leftButtonFont = FontUtil.bold(size: 13)
        controller.rightButtonFont = FontUtil.bold(size: 13)
        present(controller, animated: false, completion: nil)

//        showFullScreenLoading()
//        var isLaoad = false
//        addSubscribe(
//            LessonService.lessonType.getById(lessonTypeId: schedule.lessonTypeId)
//                .subscribe(onNext: { [weak self] doc in
//                    guard let self = self else { return }
//                    if isLaoad {
//                        return
//                    }
//                    isLaoad = true
//                    self.hideFullScreenLoading()
//
//                    if let doc = TKLessonType.deserialize(from: doc.data()) {
//                        let title = "Cancel lesson?"
        ////                        let message = "A $\(doc.price.description) adjustment will be deducted from the balance on your next bill if you decide to cancal this lesson."
//
//                        let remainingTime = Date().timestamp + self.policyData.refundNoticeRequired * 60 * 60
//                        let hour = CGFloat((schedule.shouldDateTime - Double(remainingTime)) / 60 / 60).roundTo(places: 1)
//
        ////                        self.policyData.
//                        let message = "You will receive credit if you cancel within the next \(hour) hours"
//                        SL.Alert.show(target: self, title: title, message: message, leftButttonString: "No", rightButtonString: "Yes", rightButtonColor: ColorUtil.red, leftButtonAction: {
//                        }) { [weak self] in
//                            self?.addCancellation(type: 3, schedule: schedule)
//                        }
//                    } else {
//                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
//                    }
//
//                }, onError: { [weak self] err in
//                    self?.hideFullScreenLoading()
//                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
//                    logger.debug("获取失败:\(err)")
//                })
//        )
    }

    private func cancelLesson() {
        showFullScreenLoading()

        guard policyData.allowMakeup || policyData.allowRefund else {
            // 说明不可以makeup 也不可以 refund
            showCancelLessonAlert(type: 1)
            return
        }
        func initData(data: [TKRescheduleMakeupRefundHistory]) {
            // 具体流程查看 : https://naotu.baidu.com/file/d01ed378b66e078a52adf8b1877a9791
            if policyData.allowMakeup {
                makeUp(data)
            } else {
                refund(data)
            }
        }

        func refund(_ data: [TKRescheduleMakeupRefundHistory]) {
            // 走到流程中Refunde
            // 判断是否可以Refund
            if policyData.allowRefund {
                var count = 0
                let date = Date()
                let endTime = date.timestamp

                let toDayStart = date.startOfDay
                if data.count > 0 {
                    let firstRescheduleTime = TimeUtil.changeTime(time: Double(data[0].createTime)!).startOfDay.timestamp
                    var day = ((toDayStart.timestamp - firstRescheduleTime) % (policyData.refundLimitTimesPeriod * 30 * 30 * 24 * 60 * 60))
                    day = day / 60 / 60 / 24
                    let startTime = toDayStart.add(component: .day, value: -day).timestamp
                    for item in data where item.type == .refund {
                        if let time = Int(item.createTime) {
                            if time >= startTime && time <= endTime {
                                count += 1
                            }
                        }
                    }
                }

                if policyData.refundLimitTimes {
                    // limited times  开启
                    if count < policyData.refundLimitTimesAmount {
                        // 有次数,判断notice Required是否开启
                        if policyData.refundNoticeRequired == 0 {
                            // 关闭状态,显示第三个弹窗
                            showCancelLessonAlert(type: 3)
                        } else {
                            if (endTime + (policyData.refundNoticeRequired * 60 * 60)) <= Int(originalData.shouldDateTime) {
                                //  在规定的时间段内
                                showCancelLessonAlert(type: 3)
                            } else {
                                showCancelLessonAlert(type: 1)
                            }
                        }
                    } else {
                        // 没次数
                        showCancelLessonAlert(type: 1)
                    }

                } else {
                    // limited times  没有开启,此处需要判断notice Required是否开启
                    if policyData.refundNoticeRequired == 0 {
                        // 关闭状态,显示第三个弹窗
                        showCancelLessonAlert(type: 3)
                    } else {
                        if (endTime + (policyData.refundNoticeRequired * 60 * 60)) <= Int(originalData.shouldDateTime) {
                            //  在规定的时间段内
                            showCancelLessonAlert(type: 3)
                        } else {
                            showCancelLessonAlert(type: 1)
                        }
                    }
                }

            } else {
                // 不支持Refund
                showCancelLessonAlert(type: 1)
            }
        }
        func makeUp(_ data: [TKRescheduleMakeupRefundHistory]) {
            // 走到流程中 makeup
            var count = 0
            let date = Date()
            let endTime = date.timestamp

            let toDayStart = date.startOfDay
            if data.count > 0 {
                let firstRescheduleTime = TimeUtil.changeTime(time: Double(data[0].createTime)!).startOfDay.timestamp
                var day = ((toDayStart.timestamp - firstRescheduleTime) % (policyData.refundLimitTimesPeriod * 30 * 30 * 24 * 60 * 60))
                day = day / 60 / 60 / 24

                let startTime = toDayStart.add(component: .day, value: -day).timestamp
                for item in data where item.type == .makeup {
                    if let time = Int(item.createTime) {
                        if time >= startTime && time <= endTime {
                            count += 1
                        }
                    }
                }
            }
            if policyData.makeupLimitTimes {
                // limited times  开启
                if count < policyData.makeupLimitTimesAmount {
                    // 有次数,判断notice Required是否开启
                    if policyData.makeupNoticeRequired == 0 {
                        // 关闭状态,显示第二个弹窗
                        showCancelLessonAlert(type: 2)
                    } else {
                        if (endTime + (policyData.makeupNoticeRequired * 60 * 60)) <= Int(originalData.shouldDateTime) {
                            //  在规定的时间段内,显示第二个弹窗
                            showCancelLessonAlert(type: 2)
                        } else {
                            // 不在时间段内, 走 refund流程
                            refund(data)
                        }
                    }
                } else {
                    // 没次数,走refund 流程
                    refund(data)
                }

            } else {
                // limited times  没有开启,此处需要判断notice Required是否开启
                if policyData.makeupNoticeRequired == 0 {
                    // 关闭状态,显示第二个弹窗
                    showCancelLessonAlert(type: 2)
                } else {
                    if (endTime + (policyData.makeupNoticeRequired * 60 * 60)) <= Int(originalData.shouldDateTime) {
                        //  在规定的时间段内,显示第二个弹窗
                        showCancelLessonAlert(type: 2)
                    } else {
                        // 不在时间段内, 走 refund流程
                        refund(data)
                    }
                }
            }
        }
        addSubscribe(
            UserService.teacher.getRescheduleMakeupRefundHistory(type: [.makeup, .refund], teacherId: originalData.teacherId, studentId: originalData.studentId)
                .subscribe(onNext: { docs in
                    guard docs.from == .server else {
                        return
                    }
                    var data: [TKRescheduleMakeupRefundHistory] = []
                    for doc in docs.documents {
                        if let doc = TKRescheduleMakeupRefundHistory.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }

                    initData(data: data)

                }, onError: { [weak self] err in
                    guard let self = self else {
                        return
                    }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    /// 修改已经存在Reschedule
    func editReschedule() {
        logger.debug("执行修改Reschedule")
        showFullScreenLoading()
        TimeUtil.getTimeForRescheduleTimeSelector(localSelectedTime: selectDate.timeIntervalSince1970, lessonConfigId: originalData.lessonScheduleConfigId)
            .done { [weak self] dateTimestamp in
                guard let self = self else { return }
                if self.selectedTimeIsPreferred {
                    let newScheduleData = TKLessonSchedule()
                    let time = "\(Date().timestamp)"
                    newScheduleData.id = "\(self.originalData.teacherId):\(self.originalData.studentId):\(Int(dateTimestamp))"
                    newScheduleData.instrumentId = self.originalData.instrumentId
                    newScheduleData.lessonTypeId = self.originalData.lessonTypeId
                    newScheduleData.lessonScheduleConfigId = self.originalData.lessonScheduleConfigId
                    newScheduleData.teacherId = self.originalData.teacherId
                    newScheduleData.studentId = self.originalData.studentId
                    newScheduleData.shouldDateTime = dateTimestamp
                    newScheduleData.shouldTimeLength = self.originalData.shouldTimeLength
                    newScheduleData.createTime = time
                    newScheduleData.updateTime = time
                    self.addSubscribe(
                        LessonService.lessonSchedule.editRescheduleNoNeedConfirm(schedule: self.originalData, reschedule: self.rescheduleData, newSchedule: newScheduleData)
                            .subscribe(onNext: { [weak self] _ in
                                guard let self = self else { return }
                                DispatchQueue.main.async {
                                    CommonsService.shared.sendEmailNotificationForRescheduleNewTime(rescheduleId: self.rescheduleData.id, type: 3, msg: "")
                                    self.hideFullScreenLoading()
                                    if self.isMianController {
                                        self.dismiss(animated: true) {
                                            TKToast.show(msg: "Update Successfully!", style: .success)
                                        }
                                    } else {
                                        self.dismiss(animated: true, completion: {
                                            TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                                        })
                                    }
                                }

                            }, onError: { [weak self] err in
                                guard let self = self else { return }
                                let error = err as NSError
                                if error.code == 0 {
                                    var userId = ""
                                    if let uid = UserService.user.id() {
                                        if self.rescheduleData.teacherId == uid {
                                            userId = self.rescheduleData.studentId
                                        } else {
                                            userId = self.rescheduleData.teacherId
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

                } else {
                    var studentResvisedReschedule: Bool = false
                    if self.rescheduleData.senderId != (UserService.user.id() ?? "") {
                        studentResvisedReschedule = true
                    }

                    LessonService.lessonSchedule.getReschedule(id: self.rescheduleData.id)
                        .done { reschedule in
                            self.addSubscribe(
                                LessonService.lessonSchedule.updateReschedule(reschedule: reschedule, timeAfter: "\(dateTimestamp)", teacherRevisedReschedule: false, studentRevisedReschedule: studentResvisedReschedule)
                                    .subscribe(onNext: { [weak self] _ in
                                        guard let self = self else {
                                            return
                                        }
                                        CommonsService.shared.sendEmailNotificationForRescheduleNewTime(rescheduleId: reschedule.id, type: 1, msg: "")
                                        self.hideFullScreenLoading()
                                        EventBus.send(EventBus.CHANGE_SCHEDULE)

                                        if self.isMianController {
                                            self.dismiss(animated: true) {
                                                TKToast.show(msg: "Update successfully!", style: .success)
                                            }
                                        } else {
                                            self.dismiss(animated: true, completion: {
                                                TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                                            })
                                        }

                                    }, onError: { [weak self] err in
                                        guard let self = self else {
                                            return
                                        }
                                        let error = err as NSError
                                        if error.code == 0 {
                                            var userId = ""
                                            if let uid = UserService.user.id() {
                                                if self.rescheduleData.teacherId == uid {
                                                    userId = self.rescheduleData.studentId
                                                } else {
                                                    userId = self.rescheduleData.teacherId
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
                        .catch { [weak self] err in
                            guard let self = self else {
                                return
                            }
                            self.hideFullScreenLoading()
                            TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                            logger.debug("获取失败:\(err)")
                        }
                }
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                logger.error("获取失败: \(error)")
                self.hideFullScreenLoading()
                TKToast.show(msg: TipMsg.connectionFailed, style: .error)
            }
    }
}

// MARK: - Action

extension RescheduleController {
    func clickCenterButton() {
        logger.debug("点击中心的按钮,当前的按钮类型: \(buttonType!) | 是否是修改: \(isEdit)")
        guard let user = ListenerService.shared.user else { return }
        if isForCredit {
            sendRescheduleForCredit()
        } else {
            switch buttonType! {
            case .makeUp: makeUp()
            case .reschedule:
                if isEdit {
                    editReschedule()
                } else {
                    switch user.currentUserDataVersion {
                    case .singleTeacher: reschedule()
                    case .studio: rescheduleV2()
                    case let .unknown(version: version):
                        fatalError("Unknow user data version: \(version)")
                    }
                }
            case .cancelLesson: cancelLesson()
            case .refundAndMakeUp: refund()
            case .cancelLessonAndReschedule:
                switch user.currentUserDataVersion {
                case .singleTeacher:
                    teacherInitiatedReschedule()
                case .studio:
                    teacherInitiatedRescheduleV2()
                case let .unknown(version: version):
                    fatalError("Unknow user data version: \(version)")
                }
            default: return
            }
        }
    }

    func clickLeftButton() {
        logger.debug("点击左边的按钮,当前的按钮类型: \(buttonType!)")
        switch buttonType! {
        case .reschedule: reschedule()
        case .refundAndMakeUp: refund()
        case .cancelLessonAndReschedule: cancelLesson()
        default: return
        }
    }

    func clickRightButton() {
        logger.debug("点击右边的按钮,当前的按钮类型: \(buttonType!)")
        switch buttonType! {
        case .reschedule: reschedule()
        case .refundAndMakeUp: makeUp()
        case .cancelLessonAndReschedule:
            guard let user = ListenerService.shared.user else { return }
            switch user.currentUserDataVersion {
            case .singleTeacher:
                teacherInitiatedReschedule()
            case .studio:
                teacherInitiatedRescheduleV2()
            case let .unknown(version: version):
                fatalError("Unknow user data version: \(version)")
            }
        default: return
        }
    }
}

extension RescheduleController {
    private func sendRescheduleForCredit() {
        guard let credit = credit else { return }
        showFullScreenLoadingNoAutoHide()
        logger.debug("选择的时间: \(selectDate.toLocalFormat("yyyy-MM-dd HH:mm:ss"))")
        let creditId = credit.id
        let time = selectDate.timestamp
        callFunction("scheduleService-requestNewLessonFromCredit", withData: ["creditId": creditId, "time": time]) { [weak self] _, error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let error = error {
                TKToast.show(msg: "Request new lesson failed, please try again later.", style: .error)
                logger.error("发起request失败: \(error)")
            } else {
                self.dismiss(animated: true) {
                    TKToast.show(msg: "Successfully.", style: .success)
                    self.onCreditSent?(credit)
                }
            }
        }
    }
}

extension RescheduleController {
    func filterAvailiableTimes(_ data: [Int: [AvailableTimes]]) -> [Int: [AvailableTimes]] {
        var availableData: [Int: [AvailableTimes]] = data
        let calendar = Calendar.current
        for (key, times) in availableData {
            availableData[key] = times.filter({ time in
                // 判断并设置时间，要符合startTime
                let timestamp: TimeInterval = TimeInterval(time.timestamp)
                let date = Date(timeIntervalSince1970: timestamp)
                let components = calendar.dateComponents([.minute, .second], from: date)
                if let minutes = components.minute, let seconds = components.second {
                    switch self.policyData.rescheduleStartTime {
                    case .hour:
                        return minutes == 0 && seconds == 0
                    case .halfHour:
                        return minutes == 30 && seconds == 0
                    case .quarterHour:
                        return true
                    }
                } else {
                    return true
                }
            })
        }
        return availableData
    }
}
