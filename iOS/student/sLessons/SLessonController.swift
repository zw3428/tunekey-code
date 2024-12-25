//
//  SLessonController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/18.
//  Copyright © 2019年 spelist. All rights reserved.
//

import AttributedString
import DZNEmptyDataSet
import FirebaseFirestore
import MJRefresh
import PromiseKit
import SnapKit
import UIKit

class SLessonController: TKBaseViewController {
//    private lazy var inviteTeacherView : TKView = {
//        let view = TKView.create()
//        let button = TKButton.create()
//            .titleFont(font: FontUtil.medium(size: 9))
//            .title(title: "INVITE")
//            .backgroundColor(color: ColorUtil.red)
//            .addTo(superView: view) { make in
//                make.width.equalTo(42)
//                make.height.equalTo(24)
//                make.right.equalToSuperview().offset(-20)
//                make.centerY.equalToSuperview()
//            }
//        button.cornerRadius = 3
//        button.onTapped { [weak self] _ in
//            self?.toInviteTeacher()
//        }
//        TKLabel.create()
//            .font(font: FontUtil.regular(size: 10))
//            .textColor(color: ColorUtil.Font.primary)
//            .text(text: "Reschedule? Interact with your instructors?\nInvite your instructor to unlock more cool features.")
//            .alignment(alignment: .left)
//            .setNumberOfLines(number: 0)
//            .addTo(superView: view) { make in
//                make.top.bottom.equalToSuperview()
//                make.left.equalToSuperview().offset(20)
//                make.right.equalTo(button.snp.left).offset(-20)
//            }
//        return view
//    }()

    private lazy var creditsLabel: Label = Label().textAlignment(.center)
    @Live private var credits: [TKCredit] = []

    private var mainView = UIView()
    private var addButton: TKButton = TKButton.create()
        .setImage(name: "icAddPrimary", size: .init(width: 22, height: 22))
    private var navigationBar: TKNormalNavigationBar!
    var messageTipPointer: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.main)
        .corner(size: 3)
    var mainController: MainViewController!
    private var oldOffset: CGPoint = .zero
    private var isTranscation: Bool = false

    private var emptyImageView: TKImageView = TKImageView.create()
        .setImage(name: "lesson_empty")
    private var emptyMsgLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 16))
        .textColor(color: ColorUtil.Font.primary)
        .text(text: "Add your lessons in minutes.\nIt's easy, we promise!")
        .setNumberOfLines(number: 0)
        .alignment(alignment: .center)
        .setLabelRowSpace(lineSpace: 0, wordSpace: 1)
    private var emptyAddLessonButton: TKBlockButton = TKBlockButton(frame: .zero, title: "ADD LESSON")

    // MARK: - nL: Next Lesson

    private var nLView: TKView!
    private var nLDayLabel: TKLabel!
    private var nLMonthLabel: TKLabel!
    private var nLTitleLabel: TKLabel!
    private var nLPracticeInfoLabel: TKLabel!
    private var nLHomeworkInfoLabel: TKLabel!
    private var arrowView: UIImageView!
    private var nLPracticeLabel: TKLabel!
    private var nLHomeworkLabel: TKLabel!
    private var cancelButton: TKLabel!
    private var rescheduleButton: TKLabel!
    private var makeUpButton: TKLabel!
    private var isShowBottomButton = false
    private var line: TKView!
    private let nLLeftView = TKView()
    private let nLRightView = TKView()

    // MARK: - pR: Pending Reschedule

    private var isPendingViewExpand = true
    private var isShowPendingView = true {
        didSet {
            if pRView != nil {
                pRView.snp.updateConstraints { make in
                    if isShowPendingView {
                        if isPendingViewExpand {
                            self.pRTimeView.isHidden = false
                            make.height.equalTo(155)
                        } else {
                            self.pRTimeView.isHidden = true
                            make.height.equalTo(60)
                        }

                    } else {
                        self.pRTimeView.isHidden = true
                        make.height.equalTo(0)
                    }
                }
            }
        }
    }

    private var pRView: TKView!
    private var pRStatusLabel: TKLabel!
    private var pRTimeView: TKView!
    private var pRTimeArrowView: UIImageView!
    // 老的时间
    private var pROldView: TKView!
    private var pROldTimeLabel: TKLabel!
    private var pROldDayLabel: TKLabel!
    private var pROldMonthLabel: TKLabel!
    // 新的时间(要修改的时间)
    private var pRNewView: TKView!
    private var pRNewTimeLabel: TKLabel!
    private var pRNewDayLabel: TKLabel!
    private var pRNewMonthLabel: TKLabel!
    private var pRPendingLabel: TKLabel!
    private var pRPendingBackButton: TKLabel!
    private var pRPendingCloseButton: TKLabel!
    private var pRPendingRescheduleButton: TKBlockButton!
    private var pRPendingConfirmButton: TKBlockButton!

    private var pRNewQuestionMarkImageView: TKImageView!
    private var makeUpView: TKView!
    private var makeUpStatusLabel: TKLabel!
    private var makeUpTimeView: TKView!
    // 老的时间
    private var makeUpOldView: TKView!
    private var makeUpOldTimeLabel: TKLabel!
    private var makeUpOldDayLabel: TKLabel!
    private var makeUpOldMonthLabel: TKLabel!
    // 新的时间(要makeUp改的时间)
    private var makeUpNewView: TKView!
    private var makeUpNewTimeLabel: TKLabel!
    private var makeUpNewDayLabel: TKLabel!
    private var makeUpNewMonthLabel: TKLabel!
    private var makeUpPendingLabel: TKLabel!
    private var makeUpNewQuestionMarkImageView: TKImageView!

    var tableView: UITableView!
    private var startTimestamp = 0
    private var endTimestamp = 0
    private var date = Date()
    var isLoadServicePolicy = false
    var isLoad: Bool = false
    private var isShowSignPolicy: Bool = false
    var studentData: TKStudent? {
        didSet {
            updateUI { [weak self] in
                guard let self = self else { return }
                logger.debug("学生数据: \(self.studentData?.toJSONString() ?? "")")
                self.addButton.isHidden = true
                if let studentData = self.studentData {
                    if studentData.studioId == "" {
                        // 没有绑定任何老师
                        if self.scheduleConfigs.count > 0 {
                            self.addButton.isHidden = false
                        } else {
                            self.addButton.isHidden = true
                        }
                    } else {
                        if studentData.studentApplyStatus == .apply {
                            self.addButton.isHidden = false
                        } else {
                            self.addButton.isHidden = true
                        }
                    }
                } else {
                    self.addButton.isHidden = false
                }
            }
        }
    }

    var teacherData: TKUser?
    private var lessonTypes: [TKLessonType] = []
    private var scheduleConfigs: [TKLessonScheduleConfigure] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadEmptyDataSet()
                logger.debug("获取到的学生config: \(self.scheduleConfigs.toJSONString() ?? "")")
                self.updateInviteTeacherView()
                if self.scheduleConfigs.count > 0 || self.nextLessonData != nil {
                    self.navigationBar?.showRightButton()
                    self.emptyImageView.isHidden = true
                    self.emptyMsgLabel.isHidden = true
                    self.emptyAddLessonButton.isHidden = true
                    if self.scheduleConfigs.filter({ $0.teacherId == "" }).count == 0 {
                        if let studentData = self.studentData {
                            if studentData.studioId == "" || studentData.studentApplyStatus == .apply {
                                if studentData.studentApplyStatus == .apply {
                                    self.rescheduleButton.text("RE-INVITE")
                                } else {
                                    self.rescheduleButton.text("ADD INSTRUCTOR")
                                }
                                self.cancelButton.text("DELETE LESSON")
                            } else {
                                self.cancelButton.text("CANCEL LESSON")
                                self.rescheduleButton.text("RESCHEDULE")
                            }
                        } else {
                            self.rescheduleButton.text("ADD INSTRUCTOR")
                            self.cancelButton.text("DELETE LESSON")
                        }
                    } else {
                        self.rescheduleButton.text("ADD INSTRUCTOR")
                        if let studentData = self.studentData, studentData.studentApplyStatus == .apply {
                            self.rescheduleButton.text("RE-INVITE")
                        }
                        self.cancelButton.text("DELETE LESSON")
                    }
                } else {
                    self.navigationBar?.hiddenRightButton()
                    if (self.studentData?.teacherId ?? "") == "" {
                        self.emptyImageView.isHidden = false
                        self.emptyMsgLabel.isHidden = false
                        self.emptyAddLessonButton.isHidden = false
                    } else {
                        self.emptyImageView.isHidden = true
                        self.emptyMsgLabel.isHidden = true
                        self.emptyAddLessonButton.isHidden = true
                    }
                }
            }
        }
    }

    var lessonSchedule: [TKLessonSchedule] = []

    // 全部从网上获取的日程
    private var webLessonSchedule: [TKLessonSchedule] = []
    // 用来存储已经存到本地的lesson
    private var lessonScheduleIdMap: [String: String] = [:]
    // 用来存储已经存到网络的lesson
    private var webLessonScheduleMap: [String: Bool] = [:]

    // 上一次加载的起始时间 previous
    private var previousCount: Int = 0
    // 上上次
    private var previousPreviousCount: Int = 0
    private var isLRefresh = false
    // nextLesson 数据
    var nextLessonData: TKLessonSchedule? {
        didSet {
            updateUI { [weak self] in
                guard let self = self else { return }
                logger.debug("设置下一次课程,当前课程不为空: \(self.nextLessonData?.toJSONString() ?? "")")
                self.tableView.reloadEmptyDataSet()
                logger.debug("获取到的学生config: \(self.scheduleConfigs.toJSONString() ?? "")")
                self.updateInviteTeacherView()
                if self.scheduleConfigs.count > 0 || self.nextLessonData != nil {
                    self.navigationBar?.showRightButton()
                    self.emptyImageView.isHidden = true
                    self.emptyMsgLabel.isHidden = true
                    self.emptyAddLessonButton.isHidden = true
                    if self.scheduleConfigs.filter({ $0.teacherId == "" }).count == 0 {
                        if let studentData = self.studentData {
                            if studentData.studioId == "" || studentData.studentApplyStatus == .apply {
                                if studentData.studentApplyStatus == .apply {
                                    self.rescheduleButton.text("RE-INVITE")
                                } else {
                                    self.rescheduleButton.text("ADD INSTRUCTOR")
                                }
                                self.cancelButton.text("DELETE LESSON")
                            } else {
                                self.cancelButton.text("CANCEL LESSON")
                                self.rescheduleButton.text("RESCHEDULE")
                            }
                        } else {
                            self.rescheduleButton.text("ADD INSTRUCTOR")
                            self.cancelButton.text("DELETE LESSON")
                        }
                    } else {
                        self.rescheduleButton.text("ADD INSTRUCTOR")
                        if let studentData = self.studentData, studentData.studentApplyStatus == .apply {
                            self.rescheduleButton.text("RE-INVITE")
                        }
                        self.cancelButton.text("DELETE LESSON")
                    }
                } else {
                    self.navigationBar?.hiddenRightButton()
                    if (self.studentData?.teacherId ?? "") == "" {
                        self.emptyImageView.isHidden = false
                        self.emptyMsgLabel.isHidden = false
                        self.emptyAddLessonButton.isHidden = false
                    } else {
                        self.emptyImageView.isHidden = true
                        self.emptyMsgLabel.isHidden = true
                        self.emptyAddLessonButton.isHidden = true
                    }
                }
            }
        }
    }

    private var rescheduleCountLabel: TKLabel!
    private var makeUpCountLabel: TKLabel!
    private var undoneRescheduleData: [TKReschedule] = []

    @Live private var unreadMessageCount: Int = 0
//    @Live private var isGroupMessageHidden: Bool = false
    private var groupMessageView: VStack!

    private var makeupData: [TKLessonCancellation] = []
    var policyData: TKPolicies? {
        didSet {
            logger.debug("获取到的policy数据: \(policyData?.toJSONString() ?? "")")
        }
    }

    private var cancelData: [TKLessonCancellation] = []
    private var rescheduleData: [TKReschedule] = []
    private var df: DateFormatter = DateFormatter()
    private var achievementData: [TKAchievement] = []
    private var practiceData: [TKPractice] = []
    private var lessonScheduleMaterials: [String: [TKLessonScheduleMaterial]] = [:]
    private var nextLessonPracticeData: [TKPractice]?
    private var isLoadedData = false
    var userNotifications: [TKUserNotification] = [] {
        didSet {
            logger.debug("设置新的用户通知数据: \(userNotifications.toJSONString() ?? "")")
            execUserNotifications()
        }
    }
    
    private var isGettingUndoneReschedule: Bool = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

extension SLessonController {
    func updateInviteTeacherView() {
        // 判断版本
//        guard let globalRole = ListenerService.shared.currentRole else { return }
//        switch globalRole {
//        case .parent:
//            if ParentService.shared.currentStudio == nil {
//                inviteTeacherView.isHidden = false
//                inviteTeacherView.snp.updateConstraints { make in
//                    make.height.equalTo(44)
//                }
//            } else {
//                inviteTeacherView.isHidden = true
//                inviteTeacherView.snp.updateConstraints { make in
//                    make.height.equalTo(0)
//                }
//            }
//        case .student:
//            if let studioId = ListenerService.shared.studentData.studentData?.studioId, !studioId.isEmpty {
//                inviteTeacherView.isHidden = true
//                inviteTeacherView.snp.updateConstraints { make in
//                    make.height.equalTo(0)
//                }
//            } else {
//                inviteTeacherView.isHidden = false
//                inviteTeacherView.snp.updateConstraints { make in
//                    make.height.equalTo(44)
//                }
//            }
//        default: return
//        }
//        if let studentData = studentData {
//            if studentData.teacherId != "" {
//                inviteTeacherView.isHidden = true
//                inviteTeacherView.snp.updateConstraints { make in
//                    make.height.equalTo(0)
//                }
//                return
//            }
//        }
//
//        inviteTeacherView.isHidden = false
//        inviteTeacherView.snp.updateConstraints { make in
//            make.height.equalTo(44)
//        }
    }
}

extension SLessonController {
    private func execUserNotifications() {
        guard let uid = UserService.user.id() else { return }
        var data: [TKReschedule] = []
        let oldData = undoneRescheduleData
        var newMsg: Bool = false
        userNotifications.forEach { notification in
            switch notification.category {
            case .scheduleCancelation:
                if let cancellationData = TKLessonCancellation.deserialize(from: notification.data) {
                    data.append(cancellationData.convertToReschedule())
                }
            case .rescheduleRequest, .rescheduleRequestConfirm, .rescheduleRetract:
                if let reschedule: TKReschedule = TKReschedule.deserialize(from: notification.data) {
                    if !newMsg {
                        if oldData.contains(where: { $0.id == reschedule.id }) {
                            // 旧数据包含这条数据,判断是否与旧数据相同,不同就算新消息
                            if let _reschedule: TKReschedule = oldData.find({ $0.id == reschedule.id }).first {
                                if !_reschedule.isEqual(reschedule) {
                                    // 判断当前的操作是不是自己发起的
                                    if reschedule.studentId == uid && reschedule.studentRevisedReschedule {
                                        newMsg = true
                                    }
                                }
                            }

                        } else {
                            newMsg = true
                        }
                    }
                    data.append(reschedule)
                }
            case .newLessonNote:
                if let lessonSchedule: TKLessonSchedule = TKLessonSchedule.deserialize(from: notification.data) {
                    var indexPaths: [IndexPath] = []
                    self.lessonSchedule.forEachItems { item, index in
                        if item.id == lessonSchedule.id {
                            self.lessonSchedule[index] = lessonSchedule
                            indexPaths.append(IndexPath(row: index, section: 0))
                        }
                    }
                    if indexPaths.count > 0 {
                        tableView.reloadRows(at: indexPaths, with: .none)
                    }
                }
            case .newAchievement:
                logger.debug("获取到新的Achievement")
            case .fileShared:
                logger.debug("获取到新的文件分享")
                if let lessonScheduleMaterial: TKLessonScheduleMaterial = TKLessonScheduleMaterial.deserialize(from: notification.data) {
                    if let list = lessonScheduleMaterials[lessonScheduleMaterial.lessonScheduleId] {
                        list.forEachItems { item, index in
                            if item.id == lessonScheduleMaterial.id {
                                lessonScheduleMaterials[lessonScheduleMaterial.lessonScheduleId]?[index] = lessonScheduleMaterial
                            }
                        }
                    }
                }
            default: break
            }
        }
        if newMsg {
            Tools.alert()
        }

        undoneRescheduleData = data
        print("====获取到的Reschedule 数据个数\(undoneRescheduleData.count)")
        updateViewsAfterNotificationsExec()
    }

    private func updateViewsAfterNotificationsExec() {
        navigationBar?.startLoading()

        updateRescheduleAndMakeUpView()
        guard studentData != nil else { return }
        df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a, MMM d" : "HH:mm MMM d"
        let d = Date()
        startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -1)).timestamp
        endTimestamp = d.timestamp
        getCancelLessonData()
        getReschedule()
        getPracticeData()
        getScheduleConfig()
        initNextLesson()
        getAchievement()
        reloadData()
        print("=我开始走啦")
//        EventBus.send(EventBus.REFRESH_STUDENT_UPCOMING_LIST, object: studentData)

        EventBus.send(EventBus.REFRESH_STUDENT_RESCHEDULE_LIST, object: undoneRescheduleData)
    }

    private func updateRescheduleAndMakeUpView() {
        initReschedule()
    }
}

extension SLessonController {
    override func bindEvent() {
        super.bindEvent()
        $credits.addSubscriber { [weak self] credits in
            guard let self = self else { return }
            if credits.isEmpty {
                self.creditsLabel.isHidden = true
                self.tableView.snp.remakeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(self.makeUpView.snp.bottom).offset(10)
                }
            } else {
                self.creditsLabel.isHidden = false
                self.tableView.snp.remakeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(self.creditsLabel.snp.bottom).offset(20)
                }
                let count = credits.count
                self.creditsLabel.attributed.text = ASAttributedString("You have \(count) credit\(count > 1 ? "s" : ""), ", .font(.cardBottomButton), .foreground(.secondary))
                    + ASAttributedString("tap to reschedule.", .font(.cardBottomButton), .foreground(.clickable), .action({
                        logger.debug("点击跳转使用credit")
                        self.toUseCredit()
                    }))
            }
        }
    }

    private func toMessageWithTeacher() {
        guard let teacher = teacherData else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.showFullScreenLoadingNoAutoHide()
            ChatService.conversation.getPrivate(userId: teacher.userId)
                .done { [weak self] conversation in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    MessagesViewController.show(conversation)
                }
                .catch { [weak self] error in
                    self?.hideFullScreenLoading()
                    logger.error("获取会话失败: \(error)")
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                }
        }
    }
}

// MARK: - View

extension SLessonController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "Lessons", rightButton: "UPCOMING", onRightButtonTapped: { [weak self] in
            guard let self = self else { return }
            self.clickReschedule()
        })
        addButton.addTo(superView: navigationBar) { make in
            make.size.equalTo(30)
            make.centerY.equalToSuperview().offset(4)
            make.left.equalToSuperview().offset(12)
        }
        addButton.isHidden = true
        addButton.onTapped { [weak self] _ in
            self?.onAddLessonButtonTapped()
        }
        navigationBar.hiddenLeftButton()
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }

        navigationBar.addSubview(view: messageTipPointer) { make in
            make.top.equalTo(navigationBar.rightButton.snp.top).offset(6)
            make.size.equalTo(6)
            make.left.equalTo(navigationBar.rightButton.snp.right)
        }
        messageTipPointer.isHidden = true

//        inviteTeacherView.addTo(superView: mainView) { make in
//            make.top.equalTo(navigationBar.snp.bottom)
//            make.left.right.equalToSuperview()
//            make.height.equalTo(0)
//        }
//        inviteTeacherView.isHidden = true

        initNextLessonView()
        initPendingRescheduleView()
        initMakeUpView()
        initGroupMessageView()
        initTableView()
        initEmptyViews()
        initListeners()
    }

    private func initEmptyViews() {
        emptyImageView.addTo(superView: mainView) { make in
            make.top.equalToSuperview().offset(88)
            make.width.equalTo(253)
            make.height.equalTo(200)
            make.centerX.equalToSuperview()
        }

        emptyMsgLabel.addTo(superView: mainView) { make in
            make.top.equalTo(emptyImageView.snp.bottom).offset(30)
            make.width.equalTo(emptyImageView.snp.width)
            make.height.equalTo(40)
            make.centerX.equalToSuperview()
        }

        emptyAddLessonButton.addTo(superView: mainView) { make in
            make.bottom.equalToSuperview().offset(-UIScreen.main.bounds.height * 0.18)
            make.width.equalTo(200)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
        }

        emptyAddLessonButton.onTapped { [weak self] _ in
            self?.onAddLessonButtonTapped()
        }

        emptyImageView.isHidden = true
        emptyMsgLabel.isHidden = true
        emptyAddLessonButton.isHidden = true
    }

    // MARK: - 初始化 NextLesson View

    private func initNextLessonView() {
        nLView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showShadow(color: ColorUtil.dividingLine)
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(navigationBar.snp.bottom).offset(10)
//                make.top.equalTo(inviteTeacherView.snp.bottom)
                make.left.equalTo(20)
                make.right.equalTo(-20)
                make.height.equalTo(0)
            })

        nLView.isHidden = true
        nLDayLabel = TKLabel.create()
            .text(text: "")
            .font(font: FontUtil.bold(size: 40))
            .alignment(alignment: .center)
            .textColor(color: ColorUtil.main)
            .adjustsFontSizeToFitWidth()
            .addTo(superView: nLView, withConstraints: { make in
                make.top.equalToSuperview().offset(10)
                make.left.equalToSuperview().offset(20)
                make.height.equalTo(50)
                make.width.equalTo(50)
            })
        nLMonthLabel = TKLabel.create()
            .text(text: "")
            .font(font: FontUtil.regular(size: 18))
            .textColor(color: ColorUtil.main)
            .addTo(superView: nLView, withConstraints: { make in
                make.top.equalTo(nLDayLabel.snp.bottom).offset(-3)
                make.centerX.equalTo(nLDayLabel)
            })
        arrowView = UIImageView()
        arrowView.image = UIImage(named: "arrowRight")
        nLView.addSubview(view: arrowView) { make in
            make.size.equalTo(22)
            make.top.equalTo(37)
            make.right.equalToSuperview().offset(-20)
        }
        nLTitleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .adjustsFontSizeToFitWidth()
            .text(text: "")
            .addTo(superView: nLView, withConstraints: { make in
                make.top.equalToSuperview().offset(20)
                make.left.equalTo(nLDayLabel.snp.right).offset(20)
                make.right.equalTo(arrowView.snp.left).offset(-8)
            })

        nLPracticeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .addTo(superView: nLView) { make in
                make.left.equalTo(nLDayLabel.snp.right).offset(20)
                make.top.equalTo(nLTitleLabel.snp.bottom).offset(5)
            }
        nLPracticeInfoLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "")
            .addTo(superView: nLView) { make in
                make.left.equalTo(nLPracticeLabel.snp.right)
                make.top.equalTo(nLTitleLabel.snp.bottom).offset(5)
                make.right.equalTo(-42)
            }

        nLHomeworkLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .addTo(superView: nLView) { make in
                make.left.equalTo(nLDayLabel.snp.right).offset(20)
                make.top.equalTo(nLPracticeLabel.snp.bottom).offset(0)
            }
        nLHomeworkInfoLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.red)
            .addTo(superView: nLView) { make in
                make.left.equalTo(nLHomeworkLabel.snp.right)
                make.top.equalTo(nLPracticeLabel.snp.bottom).offset(0)
                make.right.equalTo(-42)
            }
        cancelButton = TKLabel.create()
            .textColor(color: ColorUtil.red)
            .text(text: "CANCEL LESSON")
            .font(font: FontUtil.bold(size: 14))
            .alignment(alignment: .center)
            .addTo(superView: nLView, withConstraints: { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(50)
                make.left.equalToSuperview()
                make.width.equalTo((UIScreen.main.bounds.width - 40) / 2)
            })

        nLHomeworkLabel.text = "Assignment: "
        nLPracticeLabel.text = "Self study: "
        nLPracticeInfoLabel.text = "0 hrs"
        nLHomeworkInfoLabel.text = "No assignment"

        cancelButton.isHidden = true
        rescheduleButton = TKLabel.create()
            .textColor(color: ColorUtil.main)
            .text(text: "RESCHEDULE")
            .font(font: FontUtil.bold(size: 14))
            .alignment(alignment: .center)
            .addTo(superView: nLView, withConstraints: { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(50)
                make.right.equalToSuperview()
                make.width.equalTo((UIScreen.main.bounds.width - 40) / 2)
            })
        rescheduleButton.isHidden = true
        makeUpButton = TKLabel.create()
            .textColor(color: ColorUtil.main)
            .text(text: "MAKE UP")
            .font(font: FontUtil.bold(size: 14))
            .alignment(alignment: .center)
            .addTo(superView: nLView, withConstraints: { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(50)
                make.right.left.equalToSuperview()
            })
        makeUpButton.isHidden = true
        line = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: nLView) { make in
                make.bottom.equalTo(-50)
                make.height.equalTo(1)
                make.right.equalToSuperview().offset(-20)
                make.left.equalToSuperview().offset(20)
            }
        line.isHidden = true
        makeUpButton.onViewTapped { _ in
        }
        rescheduleButton.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            guard let studentData = self.studentData else { return }
            if studentData.studioId != "" {
                if studentData.studentApplyStatus == .apply {
                    // 再次邀请老师
                    CommonsService.shared.studentReinviteTeacher()
                } else {
                    self.rescheduleLesson()
                }
            } else {
                self.addTeacher()
            }
        }
        cancelButton.onViewTapped { [weak self] _ in
            guard let self = self, let user = ListenerService.shared.user else { return }
            switch user.currentUserDataVersion {
            case .singleTeacher:
                if self.scheduleConfigs.filter({ $0.teacherId == "" }).count == 0 {
                    self.cancelLesson()
                } else {
                    if let data = self.nextLessonData {
                        self.deleteLessonWithoutTeacher(data: data)
                    }
                }
            case .studio:
                self.cancelLessonV2()
            case let .unknown(version: version):
                fatalError("Unknown user data version: \(version)")
            }
        }
        nLView.addSubview(view: nLLeftView) { make in
            make.left.top.equalToSuperview()
            make.height.equalTo(96)
            make.width.equalTo((UIScreen.main.bounds.width - 40) * 0.7)
        }
        nLLeftView.onViewTapped { [weak self] _ in
            guard let self = self, let nextLesson = self.nextLessonData else { return }
            logger.debug("点击左边")
            guard !nextLesson.cancelled else { return }
            self.isShowBottomButton.toggle()
            SL.Animator.run(time: 0.3, animation: {
                self.nLView.snp.updateConstraints { make in
                    if self.isShowBottomButton {
                        make.height.equalTo(146)
                    } else {
                        make.height.equalTo(96)
                    }
                }
                self.view.layoutIfNeeded()
                if self.isShowBottomButton {
                    if self.nextLessonData?.cancelled ?? false {
                        self.rescheduleButton.isHidden = true
                        self.cancelButton.isHidden = true
                        self.makeUpButton.isHidden = false
                    } else {
                        self.rescheduleButton.isHidden = false
                        self.cancelButton.isHidden = false
                        self.makeUpButton.isHidden = true
                    }
                    self.line.isHidden = false
                } else {
                    self.rescheduleButton.isHidden = true
                    self.makeUpButton.isHidden = true
                    self.cancelButton.isHidden = true
                    self.line.isHidden = true
                }
            }) { _ in
            }
        }
        nLView.addSubview(view: nLRightView) { make in
            make.right.top.equalToSuperview()
            make.height.equalTo(96)
            make.width.equalTo((UIScreen.main.bounds.width - 40) * 0.3)
        }
        nLRightView.onViewTapped { [weak self] _ in
            guard let self = self, let nextLesson = self.nextLessonData else { return }
            // 获取上一次课的结束时间
            let controller = SLessonDetailsController(lessonSchedule: nextLesson)
            controller.modalPresentationStyle = .fullScreen
//            controller.isLoadoadPracticeData = true
            controller.endTime = Date().timeIntervalSince1970
            //        controller.lessonData = lessonSchedule[cell.tag]
            controller.hero.isEnabled = true
            controller.enablePanToDismiss()
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            self.present(controller, animated: true, completion: nil)
            self.hiddenNextLessonButton()
        }
        nLView.onViewTapped { _ in
            logger.debug("点击左边")
        }
    }

    // MARK: - 初始化 PendingReschedule View (pRView)

    private func initPendingRescheduleView() {
        pRView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow(color: ColorUtil.dividingLine)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(nLView.snp.bottom).offset(10)
                make.left.equalToSuperview().offset(20)
                make.height.equalTo(150)
                make.right.equalToSuperview().offset(-20)
            })
        pRView.onViewTapped { [weak self] _ in
            logger.debug("点击reschedule view")
            self?.clickRescheduleHistory()
        }
        pRPendingLabel = TKLabel.create()
            .text(text: "Pending: ")
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.regular(size: 15))
            .addTo(superView: pRView) { make in
                make.left.equalToSuperview().offset(20)
                make.width.equalTo(70)
                make.top.equalToSuperview().offset(20)
            }
        pRStatusLabel = TKLabel.create()
            .text(text: "Awaiting rescheduling confirmation")
            .textColor(color: ColorUtil.Font.third)
            .font(font: FontUtil.bold(size: 15))
            .adjustsFontSizeToFitWidth()
            .addTo(superView: pRView) { make in
//                make.height.equalTo(20)
                make.left.equalTo(pRPendingLabel.snp.right)
                make.top.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            }
//        pRStatusLabel.numberOfLines = 1
//        pendingCountLabel.backgroundColor
        rescheduleCountLabel = TKLabel.create()
            .text(text: "")
            .alignment(alignment: .center)
            .textColor(color: UIColor.white)
            .backgroundColor(color: ColorUtil.red)
            .font(font: FontUtil.bold(size: 9))
            .addTo(superView: pRView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(20)
            })
        rescheduleCountLabel.layer.cornerRadius = 10
        rescheduleCountLabel.layer.masksToBounds = true

        pRTimeView = TKView.create()
            .addTo(superView: pRView) { make in
                make.right.left.equalToSuperview()
                make.top.equalTo(pRStatusLabel.snp.bottom).offset(20)
                make.height.equalTo(66)
            }
        pRTimeView.layer.masksToBounds = true
        pRTimeArrowView = UIImageView()
        pRTimeArrowView.image = UIImage(named: "icReschedule")
        pRTimeView.addSubview(view: pRTimeArrowView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }
        pROldView = TKView.create()
            .addTo(superView: pRTimeView, withConstraints: { make in
                make.top.bottom.equalToSuperview()
//                make.right.equalTo(pRTimeArrowView.snp.left).offset(-25)
                make.left.equalToSuperview().offset(20)
            })
        pROldView.layer.masksToBounds = true
        pROldView.clipsToBounds = true
        pROldTimeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.fourth)
            .text(text: "")
            .addTo(superView: pROldView, withConstraints: { make in
                make.top.left.equalToSuperview()
            })

        pROldDayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.Font.fourth)
            .text(text: "")
            .addTo(superView: pROldView, withConstraints: { make in
                make.bottom.left.equalToSuperview()
            })
        pROldMonthLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.Font.fourth)
            .text(text: "")
            .addTo(superView: pROldView, withConstraints: { make in
                make.bottom.equalToSuperview().offset(-4)
                make.left.equalTo(pROldDayLabel.snp.right).offset(9)
                make.right.equalToSuperview()
            })

        pRNewView = TKView.create()
            .addTo(superView: pRTimeView, withConstraints: { make in
                make.top.bottom.equalToSuperview()
//                make.left.equalTo(pRTimeArrowView.snp.right).offset(25)
                make.right.equalToSuperview().offset(-20)
            })
        pRNewView.layer.masksToBounds = true

        pRNewTimeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "")
            .addTo(superView: pRNewView, withConstraints: { make in
                make.top.left.equalToSuperview()
            })
        pRNewDayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: pRNewView, withConstraints: { make in
                make.bottom.left.equalToSuperview()
            })
        pRNewMonthLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: pRNewView, withConstraints: { make in
                make.bottom.equalToSuperview().offset(-4)
                make.left.equalTo(pRNewDayLabel.snp.right).offset(9)
                make.right.equalToSuperview()
            })
        pRNewView.isHidden = true

        pRView.isHidden = true
        pRView.snp.updateConstraints { make in
            make.height.equalTo(0)
        }

        pRNewQuestionMarkImageView = TKImageView.create()
            .setImage(name: "redQuestionMark")
            .addTo(superView: pRTimeView) { make in
                make.height.equalTo(40)
                make.width.equalTo(32)
                make.left.equalTo(pRTimeArrowView.snp.right).offset(40)
                make.top.equalToSuperview().offset(15)
            }
        pRNewQuestionMarkImageView.isHidden = true
        pRPendingConfirmButton = TKBlockButton(frame: .zero, title: "CONFIRM")
        pRPendingConfirmButton.setFontSize(size: 10)
        pRView.addSubview(view: pRPendingConfirmButton) { make in
            make.height.equalTo(28)
            make.width.equalTo(62)
            make.right.equalTo(-20)
            make.bottom.equalTo(-20)
        }

        pRPendingRescheduleButton = TKBlockButton(frame: .zero, title: "RESCHEDULE", style: .cancel)
        pRPendingRescheduleButton.setFontSize(size: 10)
        pRView.addSubview(view: pRPendingRescheduleButton) { make in
            make.height.equalTo(28)
            make.width.equalTo(90)
            make.right.equalTo(pRPendingConfirmButton.snp.left).offset(-20)
            make.bottom.equalTo(-20)
        }

        pRPendingBackButton = TKLabel.create()
            .font(font: FontUtil.bold(size: 15))
            .alignment(alignment: .center)
            .textColor(color: ColorUtil.main)
            .text(text: "Retract?")
            .addTo(superView: pRView, withConstraints: { make in
                make.right.equalTo(pRPendingRescheduleButton.snp.left).offset(-20)
                make.centerY.equalTo(pRPendingRescheduleButton)
                make.height.equalTo(28)
            })

        pRPendingCloseButton = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.fourth)
            .text(text: "Close")
            .addTo(superView: pRView, withConstraints: { make in
                make.right.equalToSuperview().offset(-20)
                make.bottom.equalToSuperview().offset(-10)
                make.height.equalTo(28)
            })

        pRPendingRescheduleButton.isHidden = true
        pRPendingBackButton.isHidden = true
        pRPendingConfirmButton.isHidden = true
        pRPendingBackButton.onViewTapped { [weak self] _ in
            self?.clickBackToOriginal()
        }
        pRPendingConfirmButton.onViewTapped { [weak self] _ in
            self?.confirmTeacherReschedule()
        }
        pRPendingRescheduleButton.onViewTapped { [weak self] _ in
            self?.clickRescheduleHistory()
        }
        pRPendingCloseButton.onViewTapped { [weak self] _ in
            guard let self = self, let user = ListenerService.shared.user else { return }
            switch user.currentUserDataVersion {
            case .singleTeacher:
                self.readReschedule()
            case .studio:
                self.readRescheduleV2()
            case let .unknown(version: version):
                fatalError("Wrong data version: \(version)")
            }
        }
    }

    private func readReschedule() {
        guard let reschedule = undoneRescheduleData.first, let uid = UserService.user.id() else { return }
        showFullScreenLoading()
        DatabaseService.collections.userNotifications()
            .document("\(reschedule.id):\(uid)")
            .updateData(["read": true]) { [weak self] error in
                self?.hideFullScreenLoading()
                guard let self = self else { return }
                if let error = error {
                    logger.error("更新失败: \(error)")
                } else {
                    for item in self.userNotifications.enumerated() {
                        var notification = item.element
                        let index = item.offset
                        if let item = TKReschedule.deserialize(from: notification.data) {
                            if item.id == reschedule.id {
                                var userNotificationList = self.userNotifications
                                notification.read = true
                                userNotificationList[index] = notification
                                self.userNotifications = userNotificationList
                                break
                            }
                        }
                    }
                }
            }
    }

    // MARK: - 初始化 MakeUp View (makeUpView)

    private func initMakeUpView() {
        makeUpView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow(color: ColorUtil.dividingLine)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(pRView.snp.bottom).offset(0)
                make.left.equalToSuperview().offset(20)
                make.height.equalTo(0)
                make.right.equalToSuperview().offset(-20)
            })
        //        pRView.layer.masksToBounds = true
        makeUpView.isHidden = true
        makeUpView.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        makeUpPendingLabel = TKLabel.create()
            .text(text: "Pending: ")
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.regular(size: 15))
            .addTo(superView: makeUpView) { make in
                make.left.equalToSuperview().offset(20)
                make.width.equalTo(70)
                make.top.equalToSuperview().offset(20)
            }
        makeUpStatusLabel = TKLabel.create()
            .text(text: "Make up credit")
            .textColor(color: ColorUtil.Font.third)
            .font(font: FontUtil.bold(size: 15))
            .adjustsFontSizeToFitWidth()
            .addTo(superView: makeUpView) { make in
                //                make.height.equalTo(20)
                make.left.equalTo(makeUpPendingLabel.snp.right)
                make.top.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-10)
            }

        makeUpCountLabel = TKLabel.create()
            .text(text: "2")
            .alignment(alignment: .center)
            .textColor(color: UIColor.white)
            .backgroundColor(color: ColorUtil.main)
            .font(font: FontUtil.bold(size: 9))
            .addTo(superView: makeUpView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(20)
            })
        makeUpCountLabel.layer.cornerRadius = 10
        makeUpCountLabel.layer.masksToBounds = true

        makeUpTimeView = TKView.create()
            .addTo(superView: makeUpView) { make in
                make.right.left.equalToSuperview()
                make.top.equalTo(makeUpStatusLabel.snp.bottom).offset(20)
                make.height.equalTo(66)
            }
        makeUpTimeView.layer.masksToBounds = true
        let makeUpTimeArrowView = UIImageView()
        makeUpTimeArrowView.image = UIImage(named: "icReschedule")
        makeUpTimeView.addSubview(view: makeUpTimeArrowView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }
        makeUpOldView = TKView.create()
            .addTo(superView: makeUpTimeView, withConstraints: { make in
                make.top.bottom.equalToSuperview()
                make.right.equalTo(makeUpTimeArrowView.snp.left).offset(-25)
            })

        makeUpOldTimeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "")
            .addTo(superView: makeUpOldView, withConstraints: { make in
                make.top.left.equalToSuperview()
            })

        makeUpOldDayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: makeUpOldView, withConstraints: { make in
                make.bottom.left.equalToSuperview()
            })
        makeUpOldMonthLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: makeUpOldView, withConstraints: { make in
                make.bottom.equalToSuperview().offset(-4)
                make.left.equalTo(makeUpOldDayLabel.snp.right).offset(9)
                make.right.equalToSuperview()
            })

        makeUpNewView = TKView.create()
            .addTo(superView: makeUpTimeView, withConstraints: { make in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(makeUpTimeArrowView.snp.right).offset(25)
            })
        makeUpNewTimeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "")
            .addTo(superView: makeUpNewView, withConstraints: { make in
                make.top.left.equalToSuperview()
            })
        makeUpNewDayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: makeUpNewView, withConstraints: { make in
                make.bottom.left.equalToSuperview()
            })
        makeUpNewMonthLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: makeUpNewView, withConstraints: { make in
                make.bottom.equalToSuperview().offset(-4)
                make.left.equalTo(makeUpNewDayLabel.snp.right).offset(9)
                make.right.equalToSuperview()
            })
        makeUpNewQuestionMarkImageView = TKImageView.create()
            .setImage(name: "greenQuestionMark")
            .addTo(superView: makeUpTimeView) { make in
                make.height.equalTo(40)
                make.width.equalTo(32)
                make.left.equalTo(makeUpTimeArrowView.snp.right).offset(40)
                make.top.equalToSuperview().offset(15)
            }
        makeUpNewQuestionMarkImageView.isHidden = true
        makeUpNewView.isHidden = true
        makeUpView.onViewTapped { [weak self] _ in
            self?.clickRescheduleHistory(isMakeUp: true)
        }
    }

    func hiddenNextLessonButton() {
        guard isShowBottomButton else { return }
        isShowBottomButton = false
        SL.Animator.run(time: 0.3) { [weak self] in
            guard let self = self else { return }
            self.nLView.snp.updateConstraints { make in
                make.height.equalTo(96)
            }
            self.view.layoutIfNeeded()
            self.rescheduleButton.isHidden = true
            self.makeUpButton.isHidden = true
            self.cancelButton.isHidden = true
            self.line.isHidden = true
        }
    }

    private func initGroupMessageView() {
        groupMessageView = VStack(alignment: .center) {
            VStack {
                Spacer(spacing: 10)
                ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                    HStack(alignment: .center, spacing: 20) {
                        Label("Messages").textColor(.primary)
                            .font(.cardTitle)
                        ImageView(image: UIImage(named: "icMessage")!.imageWithTintColor(color: .clickable))
                            .size(width: 22, height: 22)
                            .apply { [weak self] imageView in
                                guard let self = self else { return }
                                self.$unreadMessageCount.addSubscriber { count in
                                    if count == 0 {
                                        imageView.isHidden = false
                                    } else {
                                        imageView.isHidden = true
                                    }
                                }
                            }
                        ViewBox {
                            HStack(alignment: .center) {
                                Label().textColor(.white)
                                    .font(.bold(9))
                                    .textAlignment(.center)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$unreadMessageCount.addSubscriber { count in
                                            let countString: String
                                            if count > 9 {
                                                countString = "9+"
                                            } else {
                                                countString = "\(count)"
                                            }
                                            label.text(countString)
                                        }
                                    }
                            }
                        }
                        .cornerRadius(8)
                        .backgroundColor(ColorUtil.red)
                    }
                }
                .cardStyle()
                Spacer(spacing: 10)
            }
            .width(UIScreen.main.bounds.width - 40)
            .onViewTapped { [weak self] _ in
                guard let self = self else { return }
                let controller = MessagesConversationsViewController()
                controller.style = .fullScreen
                controller.enableHero()
                Tools.getTopViewController()?.present(controller, animated: true)
            }
        }
        .addTo(superView: mainView) { make in
            make.top.equalTo(makeUpView.snp.bottom)
            make.left.right.equalToSuperview()
        }
    }

    private func initMessagesView() {
    }

    // MARK: - initTableView

    private func initTableView() {
        creditsLabel.addTo(superView: mainView) { make in
            make.top.equalTo(groupMessageView.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
        }
        creditsLabel.isHidden = true
        tableView = UITableView()
        mainView.addSubview(view: tableView) { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(groupMessageView.snp.bottom).offset(10)
        }
        tableView.emptyDataSetSource = self
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.register(SLessonCell.self, forCellReuseIdentifier: String(describing: SLessonCell.self))
        let footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            guard let self = self else { return }
            self.isLRefresh = true
            self.startTimestamp = TimeUtil.endOfMonth(date: TimeUtil.changeTime(time: Double(self.startTimestamp)).add(component: .month, value: -3)).timestamp
            self.getPracticeData()
            self.initScheduleData()
        })
//        footer.setTitle("Drag up to refresh", for: .idle)
        footer.setTitle("", for: .idle)
        footer.setTitle("Loading more...", for: .refreshing)
        footer.setTitle("", for: .noMoreData)
        footer.stateLabel?.font = FontUtil.regular(size: 15)
        footer.stateLabel?.textColor = ColorUtil.Font.primary
        tableView.mj_footer = footer
//        let header = MJRefreshNormalHeader {
//            let d = Date()
//            self.previousCount = 0
//            self.previousPreviousCount = 0
//            self.isLRefresh = false
//            self.startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -1)).timestamp
//            self.endTimestamp = d.add(component: .day, value: 1).startOfDay.timestamp - 1
//            self.getUndoneReschedule()
//            self.initNextLesson()
//            self.initScheduleData()
//        }
//        header.stateLabel?.font = FontUtil.regular(size: 15)
//        header.stateLabel?.textColor = ColorUtil.Font.primary
//        header.setTitle("Pull down to refresh", for: .idle)
//        header.setTitle("Release to refresh", for: .pulling)
//        header.setTitle("Loading ...", for: .refreshing)
//        header.lastUpdatedTimeLabel?.isHidden = true
//        tableView.mj_header = header
    }
}

// MARK: - Data

extension SLessonController {
    private func initListeners() {
        EventBus.listen(EventBus.CHANGE_SCHEDULE, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a, MMM d" : "HH:mm MMM d"
            let d = Date()
            self.startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -1)).timestamp
            self.endTimestamp = d.add(component: .month, value: 1).endOfDay.timestamp
            self.initNextLesson()
            self.getUndoneReschedule()
        }
        EventBus.listen(EventBus.CHANGE_RESCHEDULE, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a, MMM d" : "HH:mm MMM d"
            let d = Date()
            self.startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -1)).timestamp
            self.endTimestamp = d.add(component: .month, value: 1).endOfDay.timestamp
            self.initNextLesson()
            self.getUndoneReschedule()
        }

        EventBus.listen(key: .studentInfoChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.reloadData()
        }

        EventBus.listen(key: .studentAchievementChanged, target: self) { [weak self] _ in
            self?.reloadData()
        }

        EventBus.listen(key: .studentConfigChanged, target: self) { [weak self] _ in
            logger.debug("监听到学生的config发生更改")
            self?.reloadData()
        }

        EventBus.listen(EventBus.DATA_UPGRAD_BY_LESSON, target: self) { [weak self] _ in
            print("接收到刷新消息6")
            self?.reloadData()
        }

        EventBus.listen(key: .studentTeacherChanged, target: self) { [weak self] _ in
            self?.studentData = ListenerService.shared.studentData.studentData
            self?.getScheduleConfig()
            self?.nextLessonData = nil
            self?.refreshNextLessonView()
            self?.lessonSchedule = []
            self?.tableView?.reloadData()
            self?.initData()
        }

        EventBus.listen(EventBus.CHANGE_PRACTICE, target: self) { [weak self] _ in
            guard let self = self else { return }
//            self.navigationBar?.startLoading()
            self.updateViewsAfterNotificationsExec()
        }

        EventBus.listen(key: .parentDataLoaded, target: self) { [weak self] _ in
            self?.reloadData()
        }
        EventBus.listen(key: .parentKidSelected, target: self) { [weak self] _ in
            self?.reloadData()
        }
    }

    override func initData() {
        emptyImageView.isHidden = true
        emptyMsgLabel.isHidden = true
        emptyAddLessonButton.isHidden = true
        df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a, MMM d" : "HH:mm MMM d"
        let d = Date()
        startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -3)).timestamp
//        endTimestamp = d.add(component: .day, value: 1).startOfDay.timestamp - 1
        endTimestamp = d.add(component: .month, value: 1).endOfDay.timestamp
        getStudentData()

        updateViewsAfterNotificationsExec()
        loadGroupMessage()
        getUndoneReschedule()
    }

    private func reloadData() {
        logger.debug("重新加载所有数据")
        navigationBar?.startLoading()
        df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a, MMM d" : "HH:mm MMM d"
        let d = Date()
        startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -1)).timestamp
        endTimestamp = d.add(component: .month, value: 1).endOfDay.timestamp
        lessonTypes = []
        scheduleConfigs = []
        lessonSchedule = []
        nextLessonData = nil
        refreshNextLessonView()
        achievementData = []
        practiceData = []
        getStudentData()
        loadCredits()
//        initNextLesson()
//        let data = ListenerService.shared.studentData
//        if let newData = data.studentData {
//            if studentData != nil {
//                if studentData!.studentApplyStatus != .apply && studentData!.studentApplyStatus != .reject {
//                    if newData.signPolicyTime == 0 && !isShowSignPolicy {
//                        showSignPolicyController()
//                    }
//                }
//            } else {
//                if newData.signPolicyTime == 0 && (newData.studentApplyStatus != .apply && newData.studentApplyStatus != .reject) {
//                    showSignPolicyController()
//                }
//            }
//        }
//        studentData = data.studentData
//        achievementData = data.achievementData
//        getScheduleConfig()
//        initShowData()
//        tableView.reloadData()
//        navigationBar?.stopLoading()
        initNextLesson()
        let data = ListenerService.shared.studentData
        if let newData = data.studentData {
            if studentData != nil {
                if studentData!.studentApplyStatus != .apply && studentData!.studentApplyStatus != .reject {
                    if newData.signPolicyTime == 0 && !isShowSignPolicy {
                        showSignPolicyController()
                    }
                }
            } else {
                if newData.signPolicyTime == 0 && (newData.studentApplyStatus != .apply && newData.studentApplyStatus != .reject) {
                    showSignPolicyController()
                }
            }
        }
        studentData = data.studentData
        achievementData = data.achievementData
        getScheduleConfig()
        initShowData()
        tableView.reloadData()
        navigationBar?.stopLoading()
        loadGroupMessage()
        getUndoneReschedule()
    }

    func getPracticeData() {
        guard let studentData = studentData else { return }
        addSubscribe(
            LessonService.lessonSchedule.getPracticeByStartTimeAndSId(startTime: TimeInterval(startTimestamp), endTime: TimeInterval(endTimestamp), studentId: studentData.studentId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache] {
                        self.practiceData = data
                    }
                    if let data = data[.server] {
                        self.practiceData = data
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func getPoliceData() {
        guard let studentData = studentData, studentData.teacherId != "", studentData.studentApplyStatus == .confirm || studentData.studentApplyStatus == .none else { return }
        UserService.teacher.getPolicy(withTeacherId: studentData.teacherId)
            .done { [weak self] policy in
                guard let self = self else { return }
                self.isLoadServicePolicy = true
                self.policyData = policy
                if studentData.signPolicyTime == 0 && !self.isShowSignPolicy && (studentData.studentApplyStatus != .apply && studentData.studentApplyStatus != .reject) {
                    self.showSignPolicyController()
                }
            }
            .catch { error in
                logger.error("获取policy失败: \(error)")
            }
//        addSubscribe(
//            UserService.teacher.getPoliciesById(policiesId: studentData.teacherId)
//                .subscribe(onNext: { [weak self] doc in
//                    guard let self = self else { return }
//                    if doc.exists {
//                        if let data = TKPolicies.deserialize(from: doc.data()) {
//                            self.policyData = data
//                        }
//                    }
//                    if doc.from == .server {
//                        self.isLoadServicePolicy = true
//                        if studentData.signPolicyTime == 0 && !self.isShowSignPolicy && (studentData.studentApplyStatus != .apply && studentData.studentApplyStatus != .reject) {
//                            self.showSignPolicyController()
//                        }
//                    }
//                }, onError: { err in
//                    logger.debug("======\(err)")
//                })
//        )
    }

    /// 获取学生自己的详情
    private func getStudentData() {
        logger.debug("StudentLesson => 开始加载数据")
        guard let currentRole = ListenerService.shared.currentRole else {
            logger.debug("StudentLesson => 无法获取当前的角色")
            return
        }
        navigationBar?.startLoading()
        if currentRole == .student {
            self.studentData = ListenerService.shared.studentData.studentData
        } else {
            self.studentData = ParentService.shared.currentStudent
        }
        // StudentLesson => 获取到当前student: Del3ldDzVcN61LHfRFR4UBk9hch2
        logger.debug("StudentLesson => 获取到当前student: \(studentData?.studentId ?? "nil")")
        guard let studentData = studentData else {
            logger.debug("StudentLesson => 当前student为空")
            tableView?.reloadData()
            navigationBar.stopLoading()
            return
        }
        if studentData.signPolicyTime == 0 && !isShowSignPolicy && (studentData.studentApplyStatus != .apply && studentData.studentApplyStatus != .reject) {
            showSignPolicyController()
        }
//        getTeacherData()
//            .done { [weak self] _ in
//                guard let self = self else { return }
//                self.isLoad = true
//                self.getPracticeData()
//                self.getAchievement()
//                self.getPoliceData()
//                self.getCancelLessonData()
//                self.getReschedule()
//                self.getScheduleConfig()
//                self.initReschedule()
//                if self.studentData == nil {
//                    UserService.user.getUser(id: UserService.user.id() ?? "")
//                        .done { user in
//                            if let user = user {
//                                self.studentData = TKStudent(teacherId: "", studentId: user.userId, name: user.name, phone: user.phone, email: user.email, invitedStatus: .none, lessonTypeId: "", isUploadedAvatar: false, statusHistory: [], studentApplyStatus: .none, createTime: "", updateTime: "")
//                                self.mainController.getStudentLessonData(studentId: self.studentData!.studentId, teacherId: self.studentData!.teacherId)
//                            } else {
//                                logger.error("用户信息为空")
//                            }
//                            self.navigationBar?.stopLoading()
//                        }
//                        .catch { error in
//                            logger.error("获取用户信息失败: \(error)")
//                            self.navigationBar?.stopLoading()
//                        }
//                } else {
//                    self.mainController.getStudentLessonData(studentId: self.studentData!.studentId, teacherId: self.studentData!.teacherId)
//                    self.navigationBar?.stopLoading()
//                }
//            }
//            .catch { err in
//                self.navigationBar?.stopLoading()
//                logger.debug("获取学生信息失败:\(err)")
//            }

        updateUI { [weak self] in
            guard let self = self else { return }
            self.navigationBar?.startLoading()
        }
        logger.debug("StudentLesson => 开始加载数据")
        akasync { [weak self] in
            guard let self = self else { return }
            if !studentData.studioId.isEmpty {
                // 有studio
                // 获取studio 创建者的Id
                let studioInfo = try akawait(UserService.studio.getStudioInfo(studentData.studioId))
                self.policyData = try akawait(UserService.teacher.getPolicy(withTeacherId: studioInfo.creatorId))
                if self.policyData == nil {
                    self.policyData = TKPolicies()
                    self.policyData?.userId = studioInfo.creatorId
                }
                self.isLoadServicePolicy = true
            } else if !studentData.teacherId.isEmpty {
                self.teacherData = try akawait(StudentService.lessons.getTeacherUser(studentData.teacherId))
                self.policyData = try akawait(UserService.teacher.getPolicy(withTeacherId: studentData.teacherId))
                if self.policyData == nil {
                    self.policyData = TKPolicies()
                    self.policyData?.userId = studentData.teacherId
                }
                self.isLoadServicePolicy = true
            } else {
                self.teacherData = nil
            }

            self.practiceData = try akawait(StudentService.lessons.getPractice(withTimeRange: DateTimeRange(startTime: TimeInterval(self.startTimestamp), endTime: TimeInterval(self.endTimestamp)), studentId: studentData.studentId, studioId: studentData.studioId))
            self.achievementData = try akawait(StudentService.lessons.getAchievements(studentData.studentId))
            self.scheduleConfigs = try akawait(StudentService.lessons.getLessonScheduleConfigs(studioId: studentData.studioId, studentId: studentData.studentId))
            let lessonTypeIds = self.scheduleConfigs.compactMap({ $0.lessonTypeId })
            self.lessonTypes = try akawait(StudentService.lessons.getLessonTypes(lessonTypeIds))
            self.nextLessonData = try akawait(StudentService.lessons.getNextLesson(studioId: studentData.studioId, studentId: studentData.studentId))
            try akawait(LessonService.lessonScheduleConfigure.studioRefreshLessonSchedules(with: self.scheduleConfigs, startTime: TimeInterval(self.startTimestamp), endTime: TimeInterval(self.endTimestamp)))
            self.lessonSchedule = try akawait(StudentService.lessons.getLessonSchedule(withStudentId: studentData.studentId, studioId: studentData.studioId, dateTimeRange: DateTimeRange(startTime: TimeInterval(self.startTimestamp), endTime: TimeInterval(self.endTimestamp))))

            updateUI {
                logger.debug("StudentLesson => 数据加载完成")
                self.navigationBar?.stopLoading()
                for (index, lesson) in self.lessonSchedule.enumerated() {
                    self.lessonSchedule[index].initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
                    if self.lessonScheduleIdMap[lesson.id] == nil {
                        self.lessonScheduleIdMap[lesson.id] = lesson.id
                        self.previousCount += 1
                    }
                }
                self.refreshNextLessonView()
                self.initShowData()
                self.tableView.reloadData()
                self.initScheduleStudent()
                if studentData.signPolicyTime == 0 && !self.isShowSignPolicy && (studentData.studentApplyStatus != .apply && studentData.studentApplyStatus != .reject) {
                    self.showSignPolicyController()
                }
            }
        }
    }

    private func getAchievement() {
        guard let studentData = studentData else { return }
        addSubscribe(
            LessonService.lessonSchedule.getAchievementByStudentId(studentId: studentData.studentId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    if let data: [TKAchievement] = [TKAchievement].deserialize(from: docs.documents.compactMap { $0.data() }) as? [TKAchievement] {
                        self.achievementData = data
                        self.initShowData()
                        self.tableView.reloadData()
                    }
                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func getStudioInfo() {
        guard let studentData = studentData, studentData.teacherId != "" else { return }
        addSubscribe(
            UserService.studio.studentGetStudioInfo(teacherId: studentData.teacherId)
                .subscribe(onNext: { data in
                    SLCache.main.set(key: SLCache.STUDIO_NAME, value: data.name)
                }, onError: { _ in
                })
        )
    }

    private func getCancelLessonData() {
        guard let studentData = studentData else { return }
        addSubscribe(
            LessonService.lessonSchedule.studentGetCancellationListByStudentId(studentId: studentData.studentId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKLessonCancellation] = []
                    for doc in docs.documents {
                        if let doc = TKLessonCancellation.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }
                    self.cancelData = data
                }, onError: { [weak self] err in
                    self?.cancelData = []
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func getMakeupData() {
        guard let studentData = studentData else { return }
        addSubscribe(
            LessonService.lessonSchedule.studentGetCancellationListByUndoneAndSutdentId(studentId: studentData.studentId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKLessonCancellation] = []

                    for doc in docs.documents {
                        if let doc = TKLessonCancellation.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }

                    self.makeupData = data
                    self.initMakeUpData()

                }, onError: { [weak self] err in
                    self?.makeupData = []
                    self?.initMakeUpData()
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func initMakeUpData() {
        if makeupData.count > 0 {
            makeUpView.isHidden = false

            if makeupData.count >= 2 {
                makeUpCountLabel.isHidden = false
                makeUpView.snp.updateConstraints { make in
                    make.height.equalTo(60)
                    make.top.equalTo(pRView.snp.bottom).offset(10)
                }
                makeUpPendingLabel.snp.updateConstraints { make in
                    make.width.equalTo(0)
                }
                makeUpOldTimeLabel.text = ""
                makeUpOldDayLabel.text = ""
                makeUpOldMonthLabel.text = ""
                makeUpCountLabel.text("\(makeupData.count)")
                makeUpNewView.isHidden = true
                makeUpNewQuestionMarkImageView.isHidden = true
            } else {
                makeUpCountLabel.isHidden = true
                makeUpView.snp.updateConstraints { make in
                    make.height.equalTo(150)
                    make.top.equalTo(pRView.snp.bottom).offset(10)
                }
                let reschedule = makeupData[0]

                // MARK: - TimeBefore 修改过的地方

                reschedule.convertToReschedule().getTimeBeforeInterval { [weak self] time in
                    guard let self = self else { return }
                    let beforeDate = Date(seconds: time)
                    let df = DateFormatter()
                    df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"
                    self.makeUpOldTimeLabel.text("\(df.string(from: beforeDate))")
                    self.makeUpOldDayLabel.text("\(beforeDate.day)")
                    self.makeUpOldMonthLabel.text("\(TimeUtil.getMonthShortName(month: beforeDate.month))")
                }

                makeUpNewView.isHidden = true
                makeUpNewQuestionMarkImageView.isHidden = false
                makeUpPendingLabel.snp.updateConstraints { make in
                    make.width.equalTo(0)
                }
            }

        } else {
            makeUpView.isHidden = true
            makeUpNewQuestionMarkImageView.isHidden = true
            makeUpOldTimeLabel.text = ""
            makeUpOldDayLabel.text = ""
            makeUpOldMonthLabel.text = ""
            makeUpView.snp.updateConstraints { make in
                make.height.equalTo(0)
                make.top.equalTo(pRView.snp.bottom).offset(0)
            }
        }
    }

    private func getReschedule() {
        guard let studentData = studentData else { return }
        LessonService.lessonSchedule.getStudentReschedules(studentData)
            .done { [weak self] data in
                guard let self = self else { return }
                logger.debug("获取到的Reschedule: \(data.toJSONString() ?? "")")
                self.rescheduleData = data
            }
            .catch { error in
                logger.error("获取Reschedule失败: \(error)")
            }
//        addSubscribe(
//            LessonService.lessonSchedule.getRescheduleByStudentId(sId: studentData.studentId)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
//                    var data: [TKReschedule] = []
//                    for doc in docs.documents {
//                        if let doc = TKReschedule.deserialize(from: doc.data()) {
//                            data.append(doc)
//                        }
//                    }
//                    self.rescheduleData = data
//                }, onError: { [weak self] err in
//                    self?.rescheduleData = []
//                    logger.debug("获取失败:\(err)")
//                })
//        )
    }

    private func getLessonScheduleMaterials() {
        let ids = lessonSchedule.compactMap { $0.id }
        guard ids.count > 0 else { return }
        LessonService.lessonSchedule.getLessonScheduleMaterialByScheduleIds(ids: ids)
            .done { [weak self] results in
                guard let self = self else { return }
                ids.forEach { id in
                    self.lessonScheduleMaterials[id] = results.filter { $0.lessonScheduleId == id }
                }
                self.tableView.reloadData()
            }
            .catch { error in
                logger.error("获取Lesson schedule materials失败: \(error)")
            }
    }

    private func getUndoneReschedule() {
        guard let studentData = studentData else {
            return
        }
        guard !isGettingUndoneReschedule else { return }
        isGettingUndoneReschedule = true
        LessonService.lessonSchedule.getStudentUndoneReschedules(studentData)
            .done { [weak self] reschedules in
                guard let self = self else { return }
                logger.debug("获取到的未完成的reschedule: \(reschedules.count)")
                self.undoneRescheduleData = reschedules
                self.initReschedule()
                EventBus.send(EventBus.REFRESH_STUDENT_RESCHEDULE_LIST, object: reschedules)
                self.isGettingUndoneReschedule = false
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                self.undoneRescheduleData = []
                self.initReschedule()
                self.isGettingUndoneReschedule = false
                logger.debug("获取未完成的reschedule失败:\(error)")
            }
//        addSubscribe(
//            LessonService.lessonSchedule.getUndoneRescheduleByStudentId(sId: studentData.studentId)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
//                    logger.debug("=====reschedule:=\(docs.count)")
//                    if let data: [TKReschedule] = [TKReschedule].deserialize(from: docs.documents.compactMap { $0.data() }) as? [TKReschedule] {
//                        self.undoneRescheduleData = data
//                        self.initReschedule()
//                        EventBus.send(EventBus.REFRESH_STUDENT_RESCHEDULE_LIST, object: data)
//                    }
//                }, onError: { [weak self] err in
//                    self?.undoneRescheduleData = []
//                    self?.initReschedule()
//                    logger.debug("获取失败:\(err)")
//                })
//        )
    }

    private func initReschedule() {
        pRNewQuestionMarkImageView?.setImage(name: "redQuestionMark")
        var pendingWidth: CGFloat = 0
        pRPendingCloseButton?.isHidden = true
        pRPendingBackButton?.isHidden = false
        pRPendingLabel?.snp.updateConstraints { make in
            pendingWidth = 70
            make.width.equalTo(70)
            make.left.equalToSuperview().offset(20)
        }
        if undoneRescheduleData.count > 0 {
            pRView?.isHidden = false
            pRPendingBackButton?.isHidden = true
            pRPendingRescheduleButton?.isHidden = true
            pRPendingConfirmButton?.isHidden = true
            pRPendingBackButton?.snp.remakeConstraints { make in
                make.right.equalTo(pRPendingRescheduleButton.snp.left).offset(-20)
                make.centerY.equalTo(pRPendingRescheduleButton)
                make.height.equalTo(28)
            }
            pRView?.snp.updateConstraints { make in
                make.top.equalTo(nLView.snp.bottom).offset(10)
            }
            if undoneRescheduleData.count >= 2 {
                logger.debug("当前Reschedule数量有2个以上,直接显示消息盒子")
                rescheduleCountLabel?.isHidden = false
                pRView?.snp.updateConstraints { make in
                    make.height.equalTo(60)
                    make.top.equalTo(nLView.snp.bottom).offset(10)
                }
                pRPendingLabel?.snp.updateConstraints { make in
                    pendingWidth = 0
                    make.width.equalTo(0)
                }
                pRStatusLabel?.text("Reschedule request")
                pROldTimeLabel?.text = ""
                pROldDayLabel?.text = ""
                pROldMonthLabel?.text = ""
                pRNewTimeLabel?.text = ""
                pRNewDayLabel?.text = ""
                pRNewMonthLabel?.text = ""
                rescheduleCountLabel?.text("\(undoneRescheduleData.count)")
                pRNewView?.isHidden = true
                pRTimeArrowView?.isHidden = true
                pRNewQuestionMarkImageView?.isHidden = true
            } else {
                logger.debug("当前Reschedule数量只有一个,开始解析当前数据")
                let reschedule = undoneRescheduleData[0]
                rescheduleCountLabel?.isHidden = true

                pRTimeArrowView?.isHidden = false
                pRNewView?.isHidden = false

                if reschedule.timeAfter != "" && Double(reschedule.timeAfter) ?? 0 < Date().timeIntervalSince1970 {
                    reschedule.timeAfter = ""
                }

                // MARK: - TimeBefore 修改过的地方

                reschedule.getTimeBeforeInterval { [weak self] time in
                    guard let self = self else { return }
                    let beforeDate = Date(seconds: time)
                    let df = DateFormatter()
                    df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"
                    self.pROldTimeLabel?.text("\(df.string(from: beforeDate))")
                    self.pROldDayLabel?.text("\(beforeDate.day)")
                    self.pROldMonthLabel?.text("\(TimeUtil.getMonthShortName(month: beforeDate.month))")
                }

                pRStatusLabel?.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(20)
                }
                if reschedule.timeAfter != "" {
                    logger.debug("已经选择了Reschedule后的时间")
                    pRPendingLabel?.snp.updateConstraints { make in
                        pendingWidth = 70
                        make.width.equalTo(70)
                        make.left.equalToSuperview().offset(20)
                    }
                    pRStatusLabel?.numberOfLines = 0
                    pRNewView?.isHidden = false
                    pRNewQuestionMarkImageView?.isHidden = true
                    pRStatusLabel?.text("Awaiting rescheduling confirmation")

                    // MARK: - TimeAfter 修改过的地方

                    reschedule.getTimeAfterInterval { [weak self] time in
                        guard let self = self else { return }
                        let afterDate = Date(seconds: time)
                        let df = DateFormatter()
                        df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"
                        self.pRNewTimeLabel?.text("\(df.string(from: afterDate))")
                        self.pRNewDayLabel?.text("\(afterDate.day)")
                        self.pRNewMonthLabel?.text("\(TimeUtil.getMonthShortName(month: afterDate.month))")
                    }
                    pRView?.snp.updateConstraints { make in
                        make.height.equalTo(193)
                    }
                    if reschedule.senderId == UserService.user.id() ?? "" {
                        pRStatusLabel?.text("Awaiting rescheduling confirmation")
                        pRPendingBackButton?.isHidden = false
                        pRPendingRescheduleButton?.snp.updateConstraints { make in
                            make.width.equalTo(0)
                        }
                        pRPendingConfirmButton?.snp.updateConstraints { make in
                            make.width.equalTo(0)
                            make.right.equalTo(0)
                        }
                        pRPendingBackButton?.snp.remakeConstraints { make in
                            make.centerX.equalToSuperview()
                            make.centerY.equalTo(pRPendingRescheduleButton).offset(10)
                            make.height.equalTo(28)
                        }
                        if reschedule.teacherRevisedReschedule {
                            pRPendingRescheduleButton?.isHidden = false
                            pRPendingConfirmButton?.isHidden = false
                            pRPendingLabel?.snp.updateConstraints { make in
                                pendingWidth = 0
                                make.width.equalTo(0)
                            }
                            pRPendingBackButton?.snp.remakeConstraints { make in
                                make.right.equalTo(pRPendingRescheduleButton.snp.left).offset(-20)
                                make.centerY.equalTo(pRPendingRescheduleButton)
                                make.height.equalTo(28)
                            }
                            var teacherName: String = "Your instructor"
                            if let name = teacherData?.name {
                                teacherName = name
                            }
                            pRStatusLabel?.text("\(teacherName) sent a reschedule request")

                            pRPendingRescheduleButton?.snp.updateConstraints { make in
                                make.width.equalTo(0)
                            }
                            pRStatusLabel?.snp.updateConstraints { make in
                                make.top.equalToSuperview().offset(20)
                            }
                            pRStatusLabel?.numberOfLines = 0
                            pRPendingRescheduleButton?.snp.updateConstraints { make in
                                make.width.equalTo(90)
                            }
                            pRPendingConfirmButton?.snp.updateConstraints { make in
                                make.width.equalTo(62)
                                make.right.equalTo(-20)
                            }
                            pRPendingBackButton?.snp.remakeConstraints { make in
                                make.right.equalTo(pRPendingRescheduleButton.snp.left).offset(-20)
                                make.centerY.equalTo(pRPendingRescheduleButton)
                                make.height.equalTo(28)
                            }
                        }
                    } else {
                        if reschedule.studentRevisedReschedule {
                            pRStatusLabel?.text("Awaiting rescheduling confirmation")
                            pRPendingConfirmButton?.snp.updateConstraints { make in
                                make.width.equalTo(0)
                                make.right.equalTo(0)
                            }
                            pRPendingLabel?.snp.updateConstraints { make in
                                pendingWidth = 70
                                make.width.equalTo(70)
                            }
                            pRPendingRescheduleButton?.isHidden = true
                            pRPendingConfirmButton?.isHidden = true

                            pRView?.snp.updateConstraints { make in
                                make.height.equalTo(173)
                            }
                        } else {
                            pRPendingRescheduleButton?.isHidden = false
                            pRPendingConfirmButton?.isHidden = false
                            pRPendingConfirmButton?.snp.updateConstraints { make in
                                make.width.equalTo(62)
                                make.right.equalTo(-20)
                            }
                            pRPendingLabel?.snp.updateConstraints { make in
                                pendingWidth = 0
                                make.width.equalTo(0)
                            }
                            var teacherName: String = "Your instructor"
                            if let name = teacherData?.name {
                                teacherName = name
                            }
                            pRStatusLabel?.text("\(teacherName) sent a reschedule request")
                            pRView?.snp.updateConstraints { make in
                                make.height.equalTo(193)
                            }
                        }
                        pRPendingBackButton?.isHidden = true
                        pRPendingRescheduleButton?.snp.updateConstraints { make in
                            make.width.equalTo(90)
                        }
                    }

                    if reschedule.retracted {
                        var teacherName: String = "Your instructor"
                        if let name = teacherData?.name {
                            teacherName = name
                        }
                        let statusText = "\(teacherName) retracted the reschedule request"
                        pRPendingLabel?.snp.updateConstraints { make in
                            pendingWidth = 0
                            make.width.equalTo(0)
                            make.left.equalToSuperview().offset(20)
                        }
                        pRPendingCloseButton?.isHidden = false
                        pRPendingConfirmButton?.isHidden = true
                        pRPendingRescheduleButton?.isHidden = true
                        pRPendingBackButton?.isHidden = true
                        pRView?.snp.updateConstraints { make in
                            make.height.equalTo(173)
                        }
                        pRStatusLabel?.attributedText = Tools.attributenStringColor(text: statusText, selectedText: teacherName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
                    }
                    if reschedule.isCancelLesson {
                        var teacherName: String = "Your instructor"
                        if let name = teacherData?.name {
                            teacherName = name
                        }
                        pRStatusLabel?.attributedText = Tools.attributenStringColor(text: "\(teacherName) cancelled this lesson", selectedText: teacherName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                        if let time = TimeInterval(reschedule.timeBefore) {
                            let date = Date(seconds: time)

                            let time = NSMutableAttributedString(string: date.toLocalFormat(Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"))
                            time.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, time.length))
                            pROldTimeLabel?.attributedText = time

                            let day = NSMutableAttributedString(string: date.toLocalFormat("d"))
                            day.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, day.length))
                            pROldDayLabel?.attributedText = day

                            let month = NSMutableAttributedString(string: date.toLocalFormat("MMM"))
                            month.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, month.length))
                            pROldMonthLabel?.attributedText = month
                        }
                        pRPendingLabel?.snp.updateConstraints { make in
                            make.width.equalTo(0)
                        }
                        pRPendingCloseButton?.isHidden = false
                        pRTimeArrowView?.isHidden = true
                        pRNewView?.isHidden = true
                        pRNewQuestionMarkImageView?.isHidden = true
                    }
                } else {
                    logger.debug("没有选择了Reschedule后的时间")
                    pRNewTimeLabel?.text = ""
                    pRNewDayLabel?.text = ""
                    pRNewMonthLabel?.text = ""
                    var teacherName: String = "Your instructor"
                    if let name = teacherData?.name {
                        teacherName = name
                    }
                    pRStatusLabel?.text = "\(teacherName) sent a reschedule request"
                    pRNewView?.isHidden = true
                    pRNewQuestionMarkImageView?.isHidden = false
                    pRPendingLabel?.snp.updateConstraints { make in
                        pendingWidth = 0
                        make.width.equalTo(0)
                    }
                    pRView?.snp.updateConstraints { make in
                        make.height.equalTo(150)
                    }
                    if reschedule.senderId == UserService.user.id() ?? "" {
                        pRPendingBackButton?.snp.remakeConstraints { make in
                            make.centerX.equalToSuperview()
                            if let pRPendingRescheduleButton {
                                make.centerY.equalTo(pRPendingRescheduleButton).offset(10)
                            }
                            make.height.equalTo(28)
                        }

                        pRView?.snp.updateConstraints { make in
                            make.height.equalTo(193)
                        }
                        if !reschedule.teacherRevisedReschedule {
                            var teacherName: String = "Your instructor"
                            if let name = teacherData?.name {
                                teacherName = name
                            }
                            pRStatusLabel?.text("\(teacherName) sent a reschedule request")
                        }
                    }

                    if reschedule.retracted {
                        var teacherName: String = "Your instructor"
                        if let name = teacherData?.name {
                            teacherName = name
                        }
                        let statusText = "\(teacherName) retracted the reschedule request"
                        pRPendingLabel?.snp.updateConstraints { make in
                            pendingWidth = 0
                            make.width.equalTo(0)
                            make.left.equalToSuperview().offset(20)
                        }
                        pRPendingCloseButton?.isHidden = false
                        pRPendingConfirmButton?.isHidden = true
                        pRPendingRescheduleButton?.isHidden = true
                        pRPendingBackButton?.isHidden = true
                        pRView?.snp.updateConstraints { make in
                            make.height.equalTo(173)
                        }
                        pRStatusLabel?.attributedText = Tools.attributenStringColor(text: statusText, selectedText: teacherName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
                    }
                    if reschedule.isCancelLesson {
                        var teacherName: String = "Your instructor"
                        if let name = teacherData?.name {
                            teacherName = name
                        }
                        pRStatusLabel?.attributedText = Tools.attributenStringColor(text: "\(teacherName) cancelled this lesson", selectedText: teacherName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                        if let time = TimeInterval(reschedule.timeBefore) {
                            let date = Date(seconds: time)

                            let time = NSMutableAttributedString(string: date.toLocalFormat(Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"))
                            time.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, time.length))
                            pROldTimeLabel?.attributedText = time

                            let day = NSMutableAttributedString(string: date.toLocalFormat("d"))
                            day.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, day.length))
                            pROldDayLabel?.attributedText = day

                            let month = NSMutableAttributedString(string: date.toLocalFormat("MMM"))
                            month.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, month.length))
                            pROldMonthLabel?.attributedText = month
                        }
                        pRPendingLabel?.snp.updateConstraints { make in
                            make.width.equalTo(0)
                        }
                        pRPendingCloseButton?.isHidden = false
                        pRTimeArrowView?.isHidden = true
                        pRNewView?.isHidden = true
                        pRNewQuestionMarkImageView?.isHidden = true
                    }
                }
                if reschedule.confirmType != .unconfirmed {
                    var teacherName: String = "Your instructor"
                    if let name = teacherData?.name {
                        teacherName = name
                    }
                    var statusText: String = ""
                    if reschedule.retracted {
                        statusText = "\(teacherName) retracted the reschedule request"
                    } else {
                        switch reschedule.confirmType {
                        case .unconfirmed: break
                        case .refuse: statusText = "\(teacherName) declineded the reschedule request"
                        case .confirmed: statusText = "\(teacherName) confirmed the reschedule request"
                        }
                    }
                    if statusText != "" {
                        pRPendingLabel?.snp.updateConstraints { make in
                            pendingWidth = 0
                            make.width.equalTo(0)
                            make.left.equalToSuperview().offset(20)
                        }
                        pRPendingCloseButton?.isHidden = false
                        pRPendingConfirmButton?.isHidden = true
                        pRPendingRescheduleButton?.isHidden = true
                        pRPendingBackButton?.isHidden = true
                        pRView?.snp.updateConstraints { make in
                            make.height.equalTo(173)
                        }
                        pRStatusLabel?.attributedText = Tools.attributenStringColor(text: statusText, selectedText: teacherName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
                    }
                }
                var labelHeight: CGFloat = 0
                var buttonHeight: CGFloat = 68
                if (pRPendingCloseButton?.isHidden ?? false) &&
                    (pRPendingConfirmButton?.isHidden ?? false) &&
                    (pRPendingRescheduleButton?.isHidden ?? false) &&
                    (pRPendingBackButton?.isHidden ?? false) {
                    buttonHeight = 20
                }

                if !(pRPendingCloseButton?.isHidden ?? false) {
                    buttonHeight = 40
                }

                if pRStatusLabel?.text != "" {
                    labelHeight = pRStatusLabel?.text!.heightWithFont(font: FontUtil.bold(size: 15), fixedWidth: UIScreen.main.bounds.width - 40 - 40 - pendingWidth) ?? 0
                }
                if let attrText = pRStatusLabel?.attributedText {
                    let attr = attrText.attributes(at: 0, effectiveRange: nil)
                    labelHeight = attrText.string.heightWithStringAttributes(attributes: attr, fixedWidth: UIScreen.main.bounds.width - 40 - 40 - pendingWidth)
                }

                pRView?.snp.updateConstraints { make in
                    make.height.equalTo(125 + labelHeight + buttonHeight)
                }
            }
        } else {
            pRView?.isHidden = true
            pROldTimeLabel?.text = ""
            pROldDayLabel?.text = ""
            pROldMonthLabel?.text = ""
            pRNewTimeLabel?.text = ""
            pRNewDayLabel?.text = ""
            pRNewMonthLabel?.text = ""
            pRView?.snp.updateConstraints { make in
                make.height.equalTo(0)
                if let nLView {
                    make.top.equalTo(nLView.snp.bottom).offset(0)
                }
            }
        }
    }

    // 获取LessonType
    private func getLessonType(ids: [String]) {
        LessonService.lessonType.getByIds(ids: ids)
            .done { [weak self] lessonTypes in
                guard let self = self else { return }
                self.lessonTypes = lessonTypes
                self.initNextLesson()
                self.initScheduleData()
            }
            .catch { error in
                logger.error("获取失败:\(error)")
            }
//        addSubscribe(
//            LessonService.lessonType.getByIds(ids: ids)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
//                    if isLoad {
//                        return
//                    }
//                    var data: [TKLessonType] = []
//                    for doc in docs.documents {
//                        if let doc = TKLessonType.deserialize(from: doc.data()) {
//                            data.append(doc)
//                        }
//                    }
//                    self.lessonTypes = data
//                    if data.count > 0 {
//                        isLoad = true
//                    }
//                    print("===获取到的LesosnType:\(data.toJSONString(prettyPrint: true) ?? "")")
//                    self.initNextLesson()
//                    self.initScheduleData()
        ////                    if doc.exists {
        ////                        if let data = TKLessonType.deserialize(from: doc.data()) {
        ////                            isLoad = true
        ////                            self.lessonTypes = data
        ////                            self.getScheduleConfig()
        ////                        }
        ////                    }
//                }, onError: { err in
//                    logger.debug("获取失败:\(err)")
//                })
//        )
    }

    /// 获取课程配置信息
    private func getScheduleConfig() {
        scheduleConfigs = ListenerService.shared.studentData.scheduleConfigs
        let lessonTypeIds: [String] = scheduleConfigs.compactMap { $0.lessonTypeId }
        if lessonTypeIds.count > 0 {
            getLessonType(ids: lessonTypeIds)
        } else {
            initScheduleData()
        }
//        guard let studentData = studentData else { return }
//        addSubscribe(
//            LessonService.lessonScheduleConfigure.getScheduleConfigByStudentId(studentId: studentData.studentId)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
//                    var data: [TKLessonScheduleConfigure] = []
//                    var lessonTypeIds: [String] = []
//                    for doc in docs.documents {
//                        if let doc = TKLessonScheduleConfigure.deserialize(from: doc.data()) {
//                            lessonTypeIds.append(doc.lessonTypeId)
//                            data.append(doc)
//                        }
//                    }
//                    self.scheduleConfigs = data
//                    logger.debug("获取到的课程配置信息: \(data.toJSONString() ?? "")")
//                    if lessonTypeIds.count > 0 {
//                        self.getLessonType(ids: lessonTypeIds)
//                    } else {
//                        self.initScheduleData()
//                    }
//                }, onError: { err in
//                    logger.debug("获取失败:\(err)")
//                })
//        )
    }

    /// 整理数据
    private func initScheduleData() {
        guard studentData != nil else { return }
        logger.debug("重新获取 lesson 数据")
        guard lessonTypes.count > 0 else {
            logger.error("当前用户没有LessonType")
            if tableView.mj_header != nil {
                tableView.mj_header!.endRefreshing()
            }
            if tableView.mj_footer != nil {
                tableView.mj_footer!.endRefreshing()
                tableView.mj_footer!.endRefreshingWithNoMoreData()
            }
            return
        }
        tableView.mj_footer?.resetNoMoreData()
        guard let studentData = studentData else { return }
        navigationBar?.startLoading()
        LessonService.lessonSchedule.studentRefreshLessonSchedule(config: scheduleConfigs, lessonTypes: lessonTypes, startTime: startTimestamp, endTime: endTimestamp)
            .done { [weak self] _ in
                guard let self = self else { return }
                LessonService.lessonSchedule.getStudentLessons(studentData, startTime: self.startTimestamp, endTime: self.endTimestamp)
                    .done { lessons in
                        for lesson in lessons {
                            lesson.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
                            if self.lessonScheduleIdMap[lesson.id] == nil {
                                self.lessonScheduleIdMap[lesson.id] = lesson.id
                                self.previousCount += 1
                                self.lessonSchedule.append(lesson)
                            } else {
                                self.lessonSchedule.forEachItems { item, index in
                                    if item.id == lesson.id {
                                        self.lessonSchedule[index] = lesson
                                    }
                                }
                            }
                        }

                        self.initScheduleStudent()
                        self.initShowData()
                        self.navigationBar?.stopLoading()
                    }
                    .catch { error in
                        logger.error("获取课程失败: \(error)")
                    }
//                self.getOnlineData(studentDatas: studentDatas)
//                var teacherId: String = studentData.teacherId
//                if studentData.studentApplyStatus == .apply {
//                    teacherId = ""
//                }
//                self.addSubscribe(
//                    LessonService.lessonSchedule.getScheduleListByStudentId(studentId: studentData.studentId, teacherID: teacherId, startTime: self.startTimestamp, endTime: self.endTimestamp, isCache: false)
//                        .subscribe(onNext: { [weak self] docs in
//                            guard let self = self else { return }
//                            logger.debug("获取到的课程数量: \(docs.count)")
//                            var data: [TKLessonSchedule] = []
//                            for doc in docs.documents {
//                                if let d = TKLessonSchedule.deserialize(from: doc.data()) {
                ////                                    guard self.scheduleConfigs.contains(where: { ($0.id == d.lessonScheduleConfigId) }) else { continue }
//                                    d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
//                                    if self.lessonScheduleIdMap[d.id] == nil {
//                                        self.lessonScheduleIdMap[d.id] = d.id
//                                        self.previousCount += 1
//                                        self.lessonSchedule.append(d)
//                                    } else {
//                                        self.lessonSchedule.forEachItems { item, index in
//                                            if item.id == d.id {
//                                                self.lessonSchedule[index] = d
//                                            }
//                                        }
//                                    }
//                                    data.append(d)
//                                }
//                            }
//                            logger.debug("重新获取 lesson 数据的结果: \(self.lessonSchedule.toJSONString() ?? "")")
                ////                            for sortItem in sortData.enumerated() {
                ////                                let id = "\(sortItem.element.teacherId):\(sortItem.element.studentId):\(Int(sortItem.element.shouldDateTime))"
                ////                                sortData[sortItem.offset].id = id
                ////                                // 整理lesson 去除 已经存在在lessonSchedule 中的
                ////                                if self.lessonScheduleIdMap[id] == nil {
                ////                                    var isCancelOfRescheduled = false
                ////                                    for item in data where id == item.id {
                ////                                        //                                if item.cancelled || (item.rescheduled && item.rescheduleId != "") {
                ////                                        //                                    isCancelOfRescheduled = true
                ////                                        //                                }
                ////                                    }
                ////                                    if !isCancelOfRescheduled {
                ////                                        self.previousCount += 1
                ////                                        self.lessonSchedule.append(sortItem.element)
                ////                                        self.lessonScheduleIdMap[id] = id
                ////                                    }
                ////                                }
                ////                            }
                ////                            print("=sortData===-=\(sortData.count)===\(self.lessonSchedule.count)")
//                            self.initScheduleStudent()
//                            self.initShowData()
//                            self.navigationBar?.stopLoading()
                ////                            self.previousCount = 0
//
                ////                            self.addLesson(localData: sortData)
//
//                        }, onError: { err in
                ////                            guard let self = self else { return }
//                            logger.debug("获取失败:\(err)")
                ////                            for sortItem in sortData.enumerated() {
                ////                                let id = "\(sortItem.element.teacherId):\(sortItem.element.studentId):\(Int(sortItem.element.shouldDateTime))"
                ////                                sortData[sortItem.offset].id = id
                ////                                if self.lessonScheduleIdMap[id] == nil {
                ////                                    self.previousCount += 1
                ////                                    self.lessonSchedule.append(sortItem.element)
                ////                                    self.lessonScheduleIdMap[id] = id
                ////                                }
                ////                            }
                ////                            self.initScheduleStudent()
                ////                            self.initShowData()
                ////                            self.previousCount = 0
                ////                            self.addLesson(localData: sortData)
//
//                        })
//                )
            }
            .catch { error in
                logger.error("刷新课程失败: \(error)")
            }
    }

    private func initScheduleStudent() {
        for item in lessonSchedule.enumerated() where lessonSchedule[item.offset].studentData == nil || lessonSchedule[item.offset].id == "" {
            lessonSchedule[item.offset].id = "\(item.element.teacherId):\(item.element.studentId):\(Int(item.element.shouldDateTime))"
            lessonSchedule[item.offset].studentData = studentData
        }

        getLessonScheduleMaterials()
    }

    private func addLesson2(localData: [TKLessonSchedule]) {
        guard let studentData = studentData else { return }
        var teacherId: String = studentData.teacherId
        if studentData.studentApplyStatus == .apply {
            teacherId = ""
        }
        addSubscribe(
            LessonService.lessonSchedule.getScheduleListByStudentId(studentId: studentData.studentId, teacherID: teacherId, startTime: startTimestamp, endTime: endTimestamp)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKLessonSchedule] = []
                    for doc in docs.documents {
                        if let d = TKLessonSchedule.deserialize(from: doc.data()) {
                            guard self.scheduleConfigs.contains(where: { $0.id == d.lessonScheduleConfigId }) else { continue }

                            d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
                            var isHave = false
                            for item in self.lessonSchedule.enumerated().reversed() where item.element.id == d.id {
                                isHave = true
//                                if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
//                                    self.lessonSchedule.remove(at: item.offset)
//                                } else {
                                self.lessonSchedule[item.offset].refreshData(newData: d)
//                                }
                            }
                            if !isHave {
                                if self.lessonScheduleIdMap[d.id] == nil {
                                    self.lessonScheduleIdMap[d.id] = d.id
//                                    if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
//                                        continue
//                                    }
                                    self.previousCount += 1
                                    self.lessonSchedule.append(d)
                                }
                            }
                            data.append(d)
                        }
                    }

                    self.initScheduleStudent()
                    self.initShowData()
                    self.initLesson(addData: localData, lessonSchedule: data)

                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func initLesson(addData: [TKLessonSchedule], lessonSchedule: [TKLessonSchedule]) {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
        var lessonSchedule = lessonSchedule
        lessonSchedule.sort { a, b -> Bool in
            a.shouldDateTime > b.shouldDateTime
        }

        for item in lessonSchedule {
            let id = "\(item.teacherId):\(item.studentId):\(Int(item.shouldDateTime))"
            if webLessonScheduleMap[id] == nil {
                webLessonSchedule.append(item)
                webLessonScheduleMap[id] = true
            }
        }
        var addLessonData: [TKLessonSchedule] = []
        for item in addData where webLessonScheduleMap["\(item.teacherId):\(item.studentId):\(Int(item.shouldDateTime))"] == nil && item.type == .lesson {
            addLessonData.append(item)
        }
//        addLessonSchedules(lessonSchedule: addLessonData)
//    }
    }

    /// 把需要添加的数据添加到网上
    /// - Parameter lessonSchedule: 需要添加的数据
    private func addLessonSchedules(lessonSchedule: [TKLessonSchedule]) {
        if lessonSchedule.count == 0 {
            return
        }
        addSubscribe(
            LessonService.lessonSchedule.addLessonSchedules(schedules: lessonSchedule)
                .subscribe(onNext: { data in
                    logger.debug("======addLessonSchedules成功了?:\(data)")
                }, onError: { err in
                    logger.debug("======addLessonSchedules失败了?:\(err)")
                })
        )
    }

    /// 整理要显示的数据
    private func initShowData() {
        var newData: [TKLessonSchedule] = []
        for item in lessonSchedule.enumerated().reversed() {
            lessonSchedule[item.offset].achievement = []
            if item.element.getShouldDateTime() > Double(date.timestamp) {
                lessonSchedule.remove(at: item.offset)
            } else {
                if item.element.cancelled {
                    for data in cancelData where data.oldScheduleId == item.element.id {
                        lessonSchedule[item.offset].cancelLessonData = data
                    }
                }
                if item.element.rescheduled {
                    for data in rescheduleData where data.scheduleId == item.element.id {
                        lessonSchedule[item.offset].rescheduleLessonData = data
                    }
                }
                for data in achievementData where data.scheduleId == item.element.id {
                    lessonSchedule[item.offset].achievement.append(data)
                }
                if !item.element.cancelled && !(item.element.rescheduled && item.element.rescheduleId != "") {
                    newData.append(item.element)
                }
            }
        }
        newData.sort { x, y -> Bool in
            x.shouldDateTime > y.shouldDateTime
        }
        let nowTime = Date().timeIntervalSince1970
        newData.forEachItems { item, offset in
            newData[offset].practiceData = []
            var endTime: TimeInterval = nowTime
            if offset != 0 {
                endTime = newData[offset - 1].shouldDateTime
            }
            let startTime: TimeInterval = item.shouldDateTime

            for pData in practiceData where pData.startTime >= startTime && pData.startTime < endTime {
                newData[offset].practiceData.append(pData)
            }

            for lItem in lessonSchedule.enumerated() where item.id == lItem.element.id {
                if offset == 0 {
                    lessonSchedule[lItem.offset].isFirstLesson = true
                }
                lessonSchedule[lItem.offset].practiceData = newData[offset].practiceData
                if lessonSchedule[lItem.offset].practiceData.count > 0 {
                    var newPData: [TKPractice] = []
                    lessonSchedule[lItem.offset].practiceData.forEachItems { item, _ in
                        if item.assignment {
                            var index = -1
                            for newItem in newPData.enumerated() where newItem.element.lessonScheduleId == item.lessonScheduleId && newItem.element.name == item.name && newItem.element.startTime != item.startTime {
                                index = newItem.offset
                            }
                            if index >= 0 {
                                newPData[index].recordData += item.recordData
                                if item.done {
                                    newPData[index].done = true
                                }
                                newPData[index].totalTimeLength += item.totalTimeLength
                            } else {
                                newPData.append(item)
                            }
                        } else {
                            newPData.append(item)
                        }
                    }
                    lessonSchedule[lItem.offset].practiceData = newPData
                    newData[offset].practiceData = newPData
                }
            }
            if offset == 0 {
                if newData[offset].practiceData.count > 0 {
                    var assignmentData: [TKPractice] = []
                    var studyData: [TKPractice] = []
                    for item in newData[offset].practiceData {
                        if !item.assignment {
                            studyData.append(item)
                        } else {
                            assignmentData.append(item)
                        }
                    }

                    var totalTime: CGFloat = 0
                    for item in studyData {
                        totalTime += item.totalTimeLength
                    }
                    nextLessonPracticeData = newData[offset].practiceData
                    if nextLessonData != nil {
                        nextLessonData!.practiceData = newData[offset].practiceData
                    }
                    if totalTime > 0 {
                        totalTime = totalTime / 60 / 60
                        if totalTime <= 0.1 {
                            nLPracticeInfoLabel.text("0.1 hrs")
                        } else {
                            nLPracticeInfoLabel.text("\(totalTime.roundTo(places: 1)) hrs")
                        }
                    } else {
                        nLPracticeInfoLabel.text("0 hrs")
                    }

                    guard assignmentData.count > 0 else {
                        nLHomeworkInfoLabel.text("No assignment")
                        nLHomeworkInfoLabel.textColor = ColorUtil.red
                        return
                    }
                    var isComplete = true
                    for item in assignmentData where !item.done {
                        isComplete = false
                    }
                    nLHomeworkInfoLabel.text("\(isComplete ? "Completed" : "Incomplete")")

                    nLHomeworkInfoLabel.textColor = isComplete ? ColorUtil.kermitGreen : ColorUtil.red
                } else {
                    nLPracticeInfoLabel.text = "0 hrs"
                    nLHomeworkInfoLabel.text = "No assignment"
                }
            }
        }

        lessonSchedule.sort { x, y -> Bool in
            x.shouldDateTime > y.shouldDateTime
        }

        tableView.mj_footer?.endRefreshing()
        if isLRefresh {
            if previousCount + previousPreviousCount == 0 {
                tableView.mj_footer?.endRefreshingWithNoMoreData()
            } else {
                tableView.mj_footer?.resetNoMoreData()
            }
        } else {
            tableView.mj_footer?.resetNoMoreData()
        }
        tableView.reloadData()
        previousPreviousCount = previousCount
    }

    private func getCancelLesson() {
    }

    /// 初始化下一节课
    func initNextLesson() {
//        guard let studentData = studentData else { return }
//        navigationBar?.startLoading()
//        LessonService.lessonSchedule.getStudentNextLesson(studentData)
//            .done { [weak self] lesson in
//                guard let self = self else { return }
//                self.nextLessonData = lesson
//                logger.debug("获取到的下一节课：\(lesson?.id ?? "")")
//                self.refreshNextLessonView()
//                self.navigationBar?.stopLoading()
//            }
//            .catch { error in
//                logger.error("获取下一节课失败: \(error)")
//            }
//        var nextLesson: TKLessonSchedule!
//        var teacherId: String = studentData.teacherId
//        if studentData.studentApplyStatus == .apply {
//            teacherId = ""
//        }
//        addSubscribe(
//            LessonService.lessonSchedule.getNextLesson(targetTime: Date().timestamp, teacherId: teacherId, studentId: studentData.studentId)
//                .subscribe(onNext: { [weak self] docs in
//                    logger.debug("获取下一次课结束: \(docs.count)")
//                    var data: TKLessonSchedule!
//                    for doc in docs.documents {
//                        if let doc = TKLessonSchedule.deserialize(from: doc.data()) {
//                            data = doc
//                        }
//                    }
//                    if data != nil {
//                        nextLesson = data
//                    }
//                    self?.nextLessonData = nextLesson
        ////                    initData()
//                    self?.refreshNextLessonView()
//                    self?.navigationBar?.stopLoading()
//
//                }, onError: { [weak self] err in
//                    self?.navigationBar?.stopLoading()
//
//                    logger.debug("获取失败:\(err)")
//                })
//        )
//
    }

    func refreshNextLessonView() {
        logger.debug("刷新最新的课程，当前最新的课程是否为空： \(nextLessonData == nil)")
        if nextLessonData != nil {
            nLView?.isHidden = false
            nLView?.snp.updateConstraints { make in
                if self.isShowBottomButton {
                    make.height.equalTo(146)
                } else {
                    make.height.equalTo(96)
                }
            }
            view.layoutIfNeeded()
            if isShowBottomButton {
                if nextLessonData?.cancelled ?? false {
                    rescheduleButton.isHidden = true
                    cancelButton.isHidden = true
                    makeUpButton.isHidden = false
                } else {
                    rescheduleButton.isHidden = false
                    cancelButton.isHidden = false
                    makeUpButton.isHidden = true
                }
                line.isHidden = false
            } else {
                rescheduleButton.isHidden = true
                makeUpButton.isHidden = true
                cancelButton.isHidden = true
                line.isHidden = true
            }
            if let nextLessonPracticeData = nextLessonPracticeData {
                nextLessonData?.practiceData = nextLessonPracticeData
            }
            tkDF.dateFormat = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"
            let nextLessonShouldDate = TimeUtil.changeTime(time: nextLessonData?.getShouldDateTime() ?? 0)
            nLTitleLabel.text = "Next lesson, \(tkDF.string(from: nextLessonShouldDate))"
            nLMonthLabel.text = TimeUtil.getMonthShortName(month: nextLessonShouldDate.month)
            nLDayLabel.text = "\(nextLessonShouldDate.day)"
//                getNextHomework()

        } else {
            nLView?.isHidden = true
            isShowBottomButton = false
            rescheduleButton.isHidden = true
            makeUpButton.isHidden = true
            cancelButton.isHidden = true
            line.isHidden = true
            nLView?.snp.updateConstraints { make in
//                make.top.equalTo(inviteTeacherView.snp.bottom).offset(10)
                make.height.equalTo(0)
            }
        }
    }

    private func getNextHomework() {
        print("开始获取作业")
        guard let nextLessonData = nextLessonData else { return }
        var isLoad = false
        addSubscribe(
            LessonService.lessonSchedule.getScheduleAssignmentByScheduleId(sId: nextLessonData.id)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache] {
                        if data.count > 0 {
                            isLoad = true
                            initNextHomework(data: data[0])
                        } else {
                            self.nLTitleLabel.snp.updateConstraints { make in
                                make.top.equalToSuperview().offset(36)
                            }
                        }
                    }
                    if let data = data[.server] {
                        if !isLoad {
                            if data.count > 0 {
                                initNextHomework(data: data[0])
                            } else {
                                self.nLTitleLabel.snp.updateConstraints { make in
                                    make.top.equalToSuperview().offset(36)
                                }
                            }
                        }
                    }

                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
        func initNextHomework(data: TKAssignment) {
            nLTitleLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(17)
            }
            nLHomeworkLabel.text = "Assignment: "
            nLPracticeLabel.text = "Self study: "
            nLPracticeInfoLabel.text = "0 hrs"
            if data.done {
                nLHomeworkInfoLabel.text = "Completed"
            } else {
                nLHomeworkInfoLabel.text = "Incomplete"
            }
        }
    }

    func makeUptoReschedule(_ data: TKLessonCancellation) {
        // 显示cancel lesson 和 reschedule
        showFullScreenLoading()
        var isLoad = false
        addSubscribe(
            LessonService.lessonSchedule.getLessonScheduleById(id: data.oldScheduleId)
                .subscribe(onNext: { [weak self] doc in
                    guard let self = self else { return }

                    if !isLoad {
                        if let doc = doc.data() {
                            isLoad = true
                            if let scheduleData = TKLessonSchedule.deserialize(from: doc) {
                                getHis(scheduleData)
                            }
                        }
                    }

                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("======\(err)")
                })
        )

        func getHis(_ scheduleData: TKLessonSchedule) {
            guard let policyData = policyData else { return }
            addSubscribe(
                UserService.teacher.getRescheduleMakeupRefundHistory(type: [.refund], teacherId: data.teacherId, studentId: data.studentId)
                    .subscribe(onNext: { [weak self] docs in

                        guard let self = self else {
                            return
                        }

                        guard docs.from == .server else {
                            return
                        }
                        self.hideFullScreenLoading()

                        var hisData: [TKRescheduleMakeupRefundHistory] = []
                        for doc in docs.documents {
                            if let doc = TKRescheduleMakeupRefundHistory.deserialize(from: doc.data()) {
                                hisData.append(doc)
                            }
                        }
                        var buttonType: studentRescheduleButtonType = .makeUp
                        if hisData.count > 0 {
                            let date = Date()
                            let toDayStart = date.startOfDay
                            let firstRescheduleTime = TimeUtil.changeTime(time: Double(hisData[0].createTime)!).startOfDay.timestamp
                            var day = ((toDayStart.timestamp - firstRescheduleTime) % (policyData.rescheduleLimitTimesPeriod * 30 * 24 * 60 * 60))
                            day = day / 60 / 60 / 24
                            let startTime = toDayStart.add(component: .day, value: -day).timestamp
                            let endTime = date.timestamp
                            var count = 0
                            for item in hisData {
                                if let time = Int(item.createTime) {
                                    if time >= startTime && time <= endTime {
                                        count += 1
                                    }
                                }
                            }
                            if count < policyData.refundLimitTimesAmount {
                                buttonType = .refundAndMakeUp
                            } else {
                                buttonType = .makeUp
                            }
                        } else {
                            buttonType = .refundAndMakeUp
                        }

                        let controller = RescheduleController(originalData: scheduleData, makeUpData: data, buttonType: buttonType, policyData: policyData, isMianController: true)
                        controller.modalPresentationStyle = .fullScreen
                        controller.hero.isEnabled = true
                        controller.enablePanToDismiss()
                        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                        self.present(controller, animated: true, completion: nil)
                        self.hiddenNextLessonButton()
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
    }

    /// 去Reschedule 页面
    /// - Parameters:
    ///   - data:
    ///   - type: 0是老师发起的,1是要更改
    func rescheduletoReschedule(_ data: TKReschedule, type: Int = 0) {
        // 显示cancel lesson 和 reschedule
        guard !data.isCancelLesson else {
            logger.debug("当前课程是cancel")
            return
        }
        guard let policyData = policyData else {
            logger.debug("无法获取policy")
            return
        }
        guard data.confirmType == .unconfirmed else {
            logger.debug("reschedule confirm type 不正确")
            return
        }
        logger.debug("点击修改Reschedule")
        showFullScreenLoading()
        var isLoad = false
        addSubscribe(
            LessonService.lessonSchedule.getLessonScheduleById(id: data.scheduleId)
                .subscribe(onNext: { [weak self] doc in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if !isLoad {
                        if let doc = doc.data() {
                            isLoad = true
                            if let scheduleData = TKLessonSchedule.deserialize(from: doc) {
                                if type == 0 {
                                    logger.debug("修改Reschedule1")
                                    let controller = RescheduleController(originalData: scheduleData, rescheduleData: data, buttonType: .cancelLesson, policyData: policyData, isEdit: false, isMianController: true)
                                    controller.modalPresentationStyle = .fullScreen
                                    controller.hero.isEnabled = true
                                    controller.enablePanToDismiss()
                                    controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                                    self.present(controller, animated: true, completion: nil)
                                    self.hiddenNextLessonButton()
                                } else {
                                    logger.debug("修改Reschedule2")
                                    let controller = RescheduleController(originalData: scheduleData, rescheduleData: data, buttonType: .reschedule, policyData: policyData, isEdit: true, isMianController: true)
                                    controller.modalPresentationStyle = .fullScreen
                                    controller.hero.isEnabled = true
                                    controller.enablePanToDismiss()
                                    controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                                    self.present(controller, animated: true, completion: nil)
                                    self.hiddenNextLessonButton()
                                }
                            }
                        }
                    }

                }, onError: { err in
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("======\(err)")
                })
        )
    }

    func backToOriginalReschedule(reschedule: TKReschedule) {
        showFullScreenLoading()
        addSubscribe(
            LessonService.lessonSchedule.backToOriginalReschedule(rescheduleData: reschedule)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.rescheduleSuccessful, style: .success)
                    self.pRView.isHidden = true
                    self.pROldTimeLabel.text = ""
                    self.pROldDayLabel.text = ""
                    self.pROldMonthLabel.text = ""
                    self.pRNewTimeLabel.text = ""
                    self.pRNewDayLabel.text = ""
                    self.pRNewMonthLabel.text = ""
                    self.pRView.snp.updateConstraints { make in
                        make.height.equalTo(0)
                        make.top.equalTo(self.nLView.snp.bottom).offset(0)
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    logger.debug("获取失败:\(err)")
                    let error = err as NSError
                    if error.code == 0 {
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
                                    TKAlert.show(target: self, title: "Something wrong", message: TipMsg.updatingLessonAndTryLater(name: user.name), buttonString: "SEE UPDATE") {
                                    }
                                }
                                .catch { _ in
                                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                                }
                        } else {
                            TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                        }
                    } else {
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    }
                })
        )
    }

    func confirmTeacherReschedule() {
        logger.debug("点击")
        let reschedule = undoneRescheduleData[0]
        guard !reschedule.isCancelLesson, let user = ListenerService.shared.user else { return }
        showFullScreenLoading()
        let successFunction = { [weak self] in
            guard let self = self else { return }
            EventBus.send(EventBus.CHANGE_SCHEDULE)

            // MARK: - 还差发送邮件

            self.hideFullScreenLoading()
            self.pRView.isHidden = true
            self.pROldTimeLabel.text = ""
            self.pROldDayLabel.text = ""
            self.pROldMonthLabel.text = ""
            self.pRNewTimeLabel.text = ""
            self.pRNewDayLabel.text = ""
            self.pRNewMonthLabel.text = ""
            self.pRView.snp.updateConstraints { make in
                make.height.equalTo(0)
                make.top.equalTo(self.nLView.snp.bottom).offset(0)
            }
            TKToast.show(msg: "Successfully!", style: .success)
        }
        
        let failedFunction: (Error?) -> Void = { [weak self] error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
            logger.debug("获取失败:\(String(describing: error))")
        }
        switch user.currentUserDataVersion {
        case .unknown(version: _):
            return
        case .singleTeacher:
            addSubscribe(
                LessonService.lessonSchedule.confirmReschedule(rescheduleData: reschedule)
                    .subscribe(onNext: { _ in
                        successFunction()

                    }, onError: { error in
                        failedFunction(error)
                    })
            )
        case .studio:
            FunctionsCaller().name("scheduleService-confirmReschedule")
                .appendData(key: "id", value: reschedule.id)
                .call { _, error in
                    if let error {
                        failedFunction(error)
                    } else {
                        successFunction()
                    }
                }
        }
        
    }
}

extension SLessonController {
    private func loadCredits() {
        guard let student = StudentService.student else { return }
        logger.debug("加载credits: \(student.studioId) | \(student.studentId)")
        DatabaseService.collections.credit()
            .whereField("studioId", isEqualTo: student.studioId)
            .whereField("studentId", isEqualTo: student.studentId)
            .getDocumentsData(TKCredit.self) { [weak self] credits, error in
                guard let self = self else { return }
                if let error {
                    logger.error("加载credits失败: \(error)")
                } else {
                    self.credits = credits
                }
            }
    }

    private func loadGroupMessage() {
//        guard let studioId = ListenerService.shared.studentData.studioData?.id else {
//            logger.debug("获取groupMessage: 无法获取student或studioId")
//            return
//        }
//        akasync { [weak self] in
//            guard let self = self else { return }
//            let conversation = try akawait(ChatService.conversation.get(studioId))
//            if let conversation = conversation, conversation.latestMessageId != "" {
//                self.isGroupMessageHidden = false
//            } else {
//                self.isGroupMessageHidden = true
//            }
//        }
    }

    private func onGroupMessageButtonTapped() {
        guard let studioId = ListenerService.shared.studentData.studioData?.id else {
            logger.debug("获取groupMessage: 无法获取student或studioId")
            return
        }
        showFullScreenLoadingNoAutoHide()
        akasync { [weak self] in
            guard let self = self else { return }
            let conversation = try akawait(ChatService.conversation.get(studioId))
            self.hideFullScreenLoading()
            guard let conversation = conversation else {
                logger.error("获取不到conversation")
                return
            }
            DispatchQueue.main.async {
                MessagesViewController.show(conversation)
            }
        }
    }
}

// MARK: - TableView

extension SLessonController: UITableViewDelegate, UITableViewDataSource, SLessonCellDelegate {
    func sLessonCellSchedule(clickCell cell: SLessonCell) {
        clickCell(cell)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard !isTranscation else {
//            return
//        }
//        guard isShowPendingView else {
//            return
//        }
//        guard scrollView.contentSize.height > scrollView.frame.height else {
//            return
//        }
//
//        if scrollView.contentOffset.y <= 10 {
//            if !isPendingViewExpand {
//                isTranscation = true
//                SL.Animator.run(time: 0.2, animation: {
//                    self.pRView.snp.updateConstraints({ make in
//                        make.height.equalTo(145)
//                    })
//                    self.view.layoutIfNeeded()
//                }) { _ in
//                    self.pRTimeView.isHidden = false
//                    self.isPendingViewExpand = true
//                    self.isTranscation = false
//                }
//            }
//        }
//        if oldOffset.y <= scrollView.contentOffset.y && scrollView.contentOffset.y >= 0 {
//            if scrollView.contentOffset.y >= 100 {
//                // 向上滚动 ,隐藏View
//                if isPendingViewExpand {
//                    SL.Animator.run(time: 0.2, animation: {
//                        self.pRView.snp.updateConstraints({ make in
//                            make.height.equalTo(60)
//                        })
//                        self.view.layoutIfNeeded()
//                    }) { _ in
//                        self.pRTimeView.isHidden = true
//                        self.isPendingViewExpand = false
//                        self.isTranscation = false
//                    }
//                }
//            }
//        }
//        oldOffset = scrollView.contentOffset
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lessonSchedule.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SLessonCell.self), for: indexPath) as! SLessonCell
        cell.tag = indexPath.row
        guard lessonSchedule.isSafeIndex(indexPath.row) else {
            return cell
        }
        let data = lessonSchedule[indexPath.row]
        var newMsg: Bool = false
        if data.teacherNote != "" && !data.studentReadTeacherNote {
            newMsg = true
            logger.debug("新note")
        }
        if data.achievement.count > 0 {
            if data.achievement.filter({ !$0.studentRead }).count > 0 {
                newMsg = true
                logger.debug("新achievement")
            }
        }
        if let lessonScheduleMaterials = lessonScheduleMaterials[data.id] {
            if lessonScheduleMaterials.filter({ !$0.studentRead }).count > 0 {
                newMsg = true
                logger.debug("新材料: \(lessonScheduleMaterials.filter({ !$0.studentRead }).toJSONString() ?? "")")
            }
        }
//        logger.debug("重新加载课程cell,是否有新消息:\(newMsg) | 当前数据: \(data.toJSONString() ?? "")")

        cell.initData(data: lessonSchedule[indexPath.row], df: df, newMsg: newMsg)
        cell.delegate = self
        return cell
    }
}

extension SLessonController: DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        if scheduleConfigs.count > 0 {
            // 有课程,还没有上过,没有历史课程
            return UIImage(named: "lesson_empty")
        } else {
            if (studentData?.teacherId ?? "") == "" {
                // 没有课程也没有老师
                return UIImage()
            } else {
                // 有老师,但是没有Lesson
                return UIImage(named: "lesson_empty")
            }
        }
    }

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if scheduleConfigs.count > 0 {
            // 有课程,还没有上过,没有历史课程
            // 判断有没有下一节课
            if nextLessonData == nil {
                return NSAttributedString(string: "Your lesson will be ready once your instructor confirm your lesson.", attributes: [NSAttributedString.Key.font: FontUtil.bold(size: 16), NSAttributedString.Key.foregroundColor: ColorUtil.Font.primary])
            }
            return NSAttributedString(string: "Enjoy your lessons.", attributes: [NSAttributedString.Key.font: FontUtil.bold(size: 16), NSAttributedString.Key.foregroundColor: ColorUtil.Font.primary])
        } else {
            if (studentData?.teacherId ?? "") == "" {
                // 没有课程也没有老师
                return NSAttributedString(string: "", attributes: [NSAttributedString.Key.font: FontUtil.regular(size: 15)])
            } else {
                // 有老师,但是没有Lesson
                return NSAttributedString(string: "Your lesson will be ready once your instructor confirm your lesson.", attributes: [NSAttributedString.Key.font: FontUtil.bold(size: 16), NSAttributedString.Key.foregroundColor: ColorUtil.Font.primary])
            }
        }
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        -40
    }
}

extension SLessonController: AllFuturesControllerDelegate {
    func allFuturesController(clickPendingLesson id: String) {
        if undoneRescheduleData.count >= 2 {
            let controller = SRescheduleListController()
            controller.data = undoneRescheduleData
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.enablePanToDismiss()
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            present(controller, animated: true, completion: nil)
            hiddenNextLessonButton()
        }
    }

    // MARK: - Action

    private func showSignPolicyController() {
        guard let studentData = studentData, studentData.studentApplyStatus != .apply && studentData.studentApplyStatus != .reject, let policyData = policyData else { return }
        guard isLoadServicePolicy else { return }

        isShowSignPolicy = true
        guard policyData.sendRequest else { return }
        var studioName = "\(SLCache.main.getString(key: SLCache.STUDIO_NAME))"
        if studioName == "" {
            studioName = "Has"
        } else {
            studioName = "\(studioName) has"
        }

        SL.Alert.show(target: self, title: "Policies statement released", message: "\(studioName) updated its policies statement, please sign the new statement.", centerButttonString: "SEE POLICIES") {
            OperationQueue.main.addOperation { [weak self] in
                guard let self = self else { return }
                let controller = SPoliciesController()
                controller.navigationBar.hiddenLeftButton()
                controller.data = self.policyData
                controller.studentData = self.studentData
                controller.signPolicy = true
                controller.modalPresentationStyle = .fullScreen
                controller.hero.isEnabled = true
                controller.enablePanToDismiss()
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                self.present(controller, animated: true, completion: nil)
            }
        }
//        SL.Alert.show(target: self, title: "Policies statement released", message: "\(studioName) updated its policies statement, please sign the new statement.", leftButttonString: "LATER", rightButtonString: "SEE POLICIES") {
//        } rightButtonAction: {
//
//        }
    }

    func clickBackToOriginal() {
        let reschedule: TKReschedule = undoneRescheduleData[0]
        guard !reschedule.isCancelLesson else { return }

        SL.Alert.show(target: self, title: "Retract request", message: "\(TipMsg.cancelReschedul)", leftButttonString: "YES", rightButtonString: "NO", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
            self?.backToOriginalReschedule(reschedule: reschedule)
        }) {
        }
    }

    func clickRescheduleHistory(isMakeUp: Bool = false) {
        if isMakeUp {
            if makeupData.count >= 2 {
                let controller = SMakeupListController()
                controller.data = makeupData
                controller.modalPresentationStyle = .fullScreen
                controller.hero.isEnabled = true
                controller.enablePanToDismiss()

                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                present(controller, animated: true, completion: nil)
                hiddenNextLessonButton()
            } else {
                makeUptoReschedule(makeupData[0])
            }
        } else {
            if undoneRescheduleData.count >= 2 {
                let controller = SRescheduleListController()
                controller.data = undoneRescheduleData
                controller.modalPresentationStyle = .fullScreen
                controller.hero.isEnabled = true
                controller.enablePanToDismiss()

                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                present(controller, animated: true, completion: nil)
                hiddenNextLessonButton()
            } else if undoneRescheduleData.count == 1 {
                guard let rescheduleData = undoneRescheduleData.first else { return }
                logger.debug("准备开始reschedule, 当前reschedule: \(rescheduleData.retracted) | \(rescheduleData.confirmType)")
                if rescheduleData.retracted || rescheduleData.confirmType != .unconfirmed {
                    return
                }
                logger.debug("通过判断,进入第二层")
                if rescheduleData.senderId != rescheduleData.studentId {
                    rescheduletoReschedule(rescheduleData)
                } else {
                    rescheduletoReschedule(rescheduleData, type: 1)
                }
            }
        }
    }

    func clickReschedule() {
//        let controller = RescheduleController()
//        controller.modalPresentationStyle = .fullScreen
//        controller.hero.isEnabled = true
//        controller.enablePanToDismiss()
//        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//        present(controller, animated: true, completion: nil)

        let controller = AllFuturesController()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.studentData = studentData
        controller.lessonTypes = lessonTypes
        controller.scheduleConfigs = scheduleConfigs
        controller.enablePanToDismiss()
        controller.delegate = self
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
        hiddenNextLessonButton()
    }

    // MARK: - 点击cell

    func clickCell(_ cell: SLessonCell) {
        var endTime: TimeInterval = 0
//        if cell.tag != 0 {
//            var newData: [TKLessonSchedule] = []
//            var pos = 0
//            for item in lessonSchedule where !item.cancelled && !(item.rescheduled && item.rescheduleId != "") {
//                if item.id == lessonSchedule[cell.tag].id {
//                    pos = newData.count
//                }
//                newData.append(item)
//            }
//            if pos != 0 {
//                endTime = newData[pos + 1].shouldDateTime
//            }
//        }
        // 获取当前课程的下一次课程
        logger.debug("当前点击的index: \(cell.tag) | \(lessonSchedule.count)")
        let index = cell.tag - 1
        if index >= 0 {
            endTime = lessonSchedule[index].shouldDateTime
            logger.debug("当前课程不是最后一次课程")
        } else {
            // 当前课程是最后一次
            endTime = Date().timeIntervalSince1970
            logger.debug("当前课程是最后一次课程")
        }
        guard !lessonSchedule[cell.tag].cancelled && !(lessonSchedule[cell.tag].rescheduled && lessonSchedule[cell.tag].rescheduleId != "") else {
            return
        }
        let controller = SLessonDetailsController(lessonSchedule: lessonSchedule[cell.tag])
        controller.modalPresentationStyle = .fullScreen
        controller.endTime = endTime
//        controller.lessonData = lessonSchedule[cell.tag]
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
        hiddenNextLessonButton()
    }
}

// MARK: - 学生添加Lesson

extension SLessonController {
    private func onAddLessonButtonTapped() {
        let controller = SAddLessonViewController()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .push(direction: .right))
        present(controller, animated: true, completion: nil)
    }
}

extension SLessonController {
    private func toUseCredit() {
        guard let student = StudentService.student, !credits.isEmpty else { return }
        let controller = StudioStudentCreditsViewController(student: student, credits: credits)
        controller.enableHero()
        controller.onCreditsChanged = { [weak self] credits in
            guard let self = self else { return }
            self.credits = credits
        }
        present(controller, animated: true)
    }
}

extension SLessonController {
    private func readRescheduleV2() {
        // 已读followUp
        showFullScreenLoadingNoAutoHide()
        guard let reschedule = undoneRescheduleData.first else { return }
        let id = reschedule.id
        DatabaseService.collections.followUps()
            .document(id)
            .updateData([
                "data.studentRead": true,
            ]) { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    logger.error("已读reschedule失败: \(error)")
                } else {
                    logger.debug("已读reschedule成功")
                    self.undoneRescheduleData.first?.studentRead = true
                    self.initReschedule()
                }
            }
    }
}

extension SLessonController {
    func cancelLessonV2() {
        SL.Alert.show(target: self, title: "Cancel lesson?", message: "Are you sure cancel this lesson?", leftButttonString: "CANCEL", rightButtonString: "Go back") { [weak self] in
            guard let self = self, let nextLesson = self.nextLessonData else { return }
            self.commitCancelLessonV2(nextLesson)
        } rightButtonAction: {
        }
    }

    func commitCancelLessonV2(_ lessonSchedule: TKLessonSchedule) {
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller()
            .name("scheduleService-cancelLesson")
            .data([
                "scheduleMode": "CURRENT",
                "lessonId": lessonSchedule.id,
            ])
            .call { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    logger.error("cancelLesson失败: \(error)")
                    TKToast.show(msg: "Cancel lesson failed, please try again later.", style: .error)
                } else {
                    self.initNextLesson()
                }
            }
    }
}
