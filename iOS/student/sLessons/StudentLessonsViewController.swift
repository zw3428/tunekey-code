//
//  StudentLessonsViewController.swift
//  TuneKey
//
//  Created by 砚枫张 on 2023/7/11.
//  Copyright © 2023 spelist. All rights reserved.
//

import AttributedString
import DZNEmptyDataSet
import FirebaseFirestore
import Hero
import MJRefresh
import PromiseKit
import SnapKit
import SwiftDate
import UIKit

class StudentLessonsViewController: TKBaseViewController {
    var mainController: MainViewController?

    // MARK: - Views

    private lazy var addButton: Button = Button()
        .isShow($isAddButtonShow)
        .onTapped { [weak self] _ in
            self?.onAddLessonButtonTapped()
        }

    private lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Lessons", rightButton: "UPCOMING", onRightButtonTapped: { [weak self] in
        self?.onNavigationRightButtonTapped()
    })

    private lazy var tableView: TableView = makeTableView()

    // MARK: - Data

    @Live var credits: [TKCredit] = []
    @Live var isAddButtonShow: Bool = false

    @Live var nextLesson: TKLessonSchedule?
    @Live var nextLessonPracticeData: [TKPractice] = []
    @Live var nextLessonLocation: TKLocation?
    @Live var isNextLessonBottomButtonsShow: Bool = false

    @Live var practiceData: [TKPractice] = []
    @Live var achievementData: [TKAchievement] = []
    @Live var lessonScheduleMaterials: [String: [TKLessonScheduleMaterial]] = [:]
    @Live var followUps: [TKFollowUp] = []
    @Live var scheduleConfigs: [TKLessonScheduleConfigure] = []
    @Live var lessonTypes: [TKLessonType] = []

    @Live var lessonSchedules: [TKLessonSchedule] = []

    @Live var policyData: TKPolicies?

    var userNotifications: [TKUserNotification] = []

    @Live private var unreadMessageCount: Int = 0

    @Live var student: TKStudent?

    private var startTimestamp: TimeInterval = 0
    private var endTimestamp: TimeInterval = 0
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
}

extension StudentLessonsViewController {
    private func makeNextLessonView() -> ViewBox {
        ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
            VStack {
                ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
                    HStack(alignment: .center, spacing: 10) {
                        /// Date
                        VStack(alignment: .center) {
                            Label().textColor(.clickable)
                                .font(.bold(40))
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$nextLesson.addSubscriber { nextLesson in
                                        guard let nextLesson else { return }
                                        label.text(nextLesson.shouldDateTime.toLocalFormat("dd"))
                                    }
                                }
                            Label().textColor(.clickable)
                                .font(.medium(size: 18))
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$nextLesson.addSubscriber { nextLesson in
                                        guard let nextLesson else { return }
                                        label.text(nextLesson.shouldDateTime.toLocalFormat("MMM"))
                                    }
                                }
                        }
                        .width(60)

                        /// Middle info
                        VStack(spacing: 5) {
                            Label().textColor(.primary)
                                .font(.bold(18))
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$nextLesson.addSubscriber { nextLesson in
                                        guard let nextLesson else { return }
                                        let date = TimeUtil.changeTime(time: nextLesson.getShouldDateTime())
                                        label.text("Next lesson, \(date.toLocalFormat("hh:mm a"))")
                                            .adjustsFontSizeToFitWidth(true)
                                    }
                                }

                            /// Practice data
                            Label().apply { [weak self] label in
                                guard let self = self else { return }
                                self.$nextLessonPracticeData.addSubscriber { practiceData in
                                    let practiceString: String
                                    if practiceData.isEmpty {
                                        practiceString = "0 hrs"
                                    } else {
                                        let studyData: [TKPractice] = practiceData.filter({ !$0.assignment })
                                        var totalTime: CGFloat = 0
                                        for item in studyData {
                                            totalTime += item.totalTimeLength
                                        }
                                        if totalTime > 0 {
                                            totalTime = totalTime / 60 / 60
                                            if totalTime <= 0.1 {
                                                practiceString = "0.1 hrs"
                                            } else {
                                                practiceString = "\(totalTime.roundTo(places: 1)) hrs"
                                            }
                                        } else {
                                            practiceString = "0 hrs"
                                        }
                                    }

                                    label.attributed.text = ASAttributedString("Self study: ", .font(.medium(size: 13)), .foreground(.tertiary)) + ASAttributedString(string: practiceString, .font(.medium(size: 13)), .foreground(.primary))
                                }
                            }

                            /// Assignment
                            Label().apply { [weak self] label in
                                guard let self = self else { return }
                                self.$nextLessonPracticeData.addSubscriber { practiceData in
                                    let homeworkString: String
                                    let isComplete: Bool
                                    if practiceData.isEmpty {
                                        homeworkString = "No assignment"
                                        isComplete = false
                                    } else {
                                        let assignmentData = practiceData.filter({ $0.assignment })
                                        isComplete = assignmentData.satisfy({ $0.done })
                                        homeworkString = isComplete ? "Completed" : "Incomplete"
                                    }
                                    label.attributed.text = ASAttributedString(string: "Assignment: ", .font(.medium(size: 13)), .foreground(.tertiary)) + ASAttributedString(string: homeworkString, .font(.medium(size: 13)), .foreground(isComplete ? ColorUtil.kermitGreen : ColorUtil.red))
                                }
                            }

                            Label()
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$nextLessonLocation.addSubscriber { location in
                                        guard let location, location.id.isNotEmpty || location.place.isNotEmpty || location.remoteLink.isNotEmpty else {
                                            label.isHidden = true
                                            return
                                        }
                                        label.isHidden = false
                                        let subtitle: String = switch location.type {
                                        case .remote: "Online: "
                                        default: "Location: "
                                        }
                                        let locationText = ASAttributedString(string: subtitle, with: [.font(.medium(size: 13)), .foreground(.tertiary)])
                                        label.attributed.text = locationText
                                        switch location.type {
                                        case .remote:
                                            label.attributed.text = locationText + ASAttributedString(string: location.remoteLink, with: [.font(.medium(size: 13)), .foreground(.tertiary)])
                                        case .studioRoom:
                                            label.attributed.text = locationText
                                            var id = location.place
                                            if id.isEmpty {
                                                id = location.id
                                            }
                                            guard id.isNotEmpty else { return }
                                            StudentService.studio.getStudioRoom(id: id)
                                                .done { studioRoom in
                                                    if let studioRoom {
                                                        label.attributed.text = locationText + ASAttributedString(string: studioRoom.name, with: [.font(.medium(size: 13)), .foreground(.tertiary)])
                                                    }
                                                }
                                                .catch { error in
                                                    logger.error("获取studio room失败：\(error)")
                                                }
                                        default:
                                            label.attributed.text = locationText + ASAttributedString(string: location.place, with: [.font(.medium(size: 13)), .foreground(.tertiary)])
                                        }
                                    }
                                }
                        }

                        ImageView.iconArrowRight().size(width: 22, height: 22)
                    }
                }
                .cardStyle()
//                .height(100)
                .apply { [weak self] view in
                    guard let self = self else { return }
                    let leftView = View().backgroundColor(.clear)
                        .onViewTapped { _ in
                            self.onLeftNextLessonViewTapped()
                        }
                    let rightView = View().backgroundColor(.clear)
                        .onViewTapped { _ in
                            self.onRightNextLessonViewTapped()
                        }

                    leftView.addTo(superView: view) { make in
                        make.top.left.bottom.equalToSuperview()
                        make.width.equalToSuperview().multipliedBy(0.7)
                    }
                    rightView.addTo(superView: view) { make in
                        make.top.right.bottom.equalToSuperview()
                        make.width.equalToSuperview().multipliedBy(0.3)
                    }
                }

                ViewBox {
                    HStack(distribution: .fillEqually) {
                        Button().title("CANCEL LESSON", for: .normal)
                            .titleColor(ColorUtil.red, for: .normal)
                            .font(.bold(14))
                            .onTapped { [weak self] _ in
                                self?.onNextLessonCancelTapped()
                            }
                            .apply { [weak self] button in
                                guard let self = self else { return }
                                self.$nextLesson.addSubscriber { nextLesson in
                                    if let nextLesson, nextLesson.cancelled {
                                        button.isHidden = true
                                    } else {
                                        button.isHidden = false
                                    }
                                }
                            }
                        Button().title("RESCHEDULE", for: .normal)
                            .titleColor(.clickable, for: .normal)
                            .font(.bold(14))
                            .onTapped { [weak self] _ in
                                self?.onNextLessonRescheduleTapped()
                            }
                            .apply { [weak self] button in
                                guard let self = self else { return }
                                self.$nextLesson.addSubscriber { nextLesson in
                                    if let nextLesson, nextLesson.cancelled {
                                        button.isHidden = true
                                    } else {
                                        button.isHidden = false
                                    }
                                }
                            }
                        Button().title("MAKE UP", for: .normal)
                            .titleColor(.clickable, for: .normal)
                            .font(.bold(14))
                            .onTapped { [weak self] _ in
                                self?.onNextLessonMakeupTapped()
                            }
                            .apply { [weak self] button in
                                guard let self = self else { return }
                                self.$nextLesson.addSubscriber { nextLesson in
                                    if let nextLesson, nextLesson.cancelled {
                                        button.isHidden = false
                                    } else {
                                        button.isHidden = true
                                    }
                                }
                            }
                    }
                }
                .backgroundColor(.white)
                .cornerRadius(5)
                .showShadow(color: ColorUtil.dividingLine)
                .showBorder(color: ColorUtil.borderColor)
                .height(50)
                .apply { [weak self] view in
                    guard let self = self else { return }
                    self.$isNextLessonBottomButtonsShow.addSubscriber { isShow in
                        if isShow {
                            view.isHidden = false
                            view.layer.opacity = 0
                        }
                        UIView.animate(withDuration: 0.2) {
                            if isShow {
                                view.transform = .identity
                                view.layer.opacity = 1
                            } else {
                                view.transform = CGAffineTransform(translationX: 0, y: -50)
                                view.layer.opacity = 0
                            }
                        } completion: { _ in
                            if !isShow {
                                view.isHidden = true
                            }
                        }
                    }
                }
            }
        }
        .apply { [weak self] view in
            guard let self = self else { return }
            self.$nextLesson.addSubscriber { nextLesson in
                if nextLesson == nil {
                    view.isHidden = true
                } else {
                    view.isHidden = false
                }
            }
        }
    }

    private func makeTableView() -> TableView {
        let tableView = TableView()
            .backgroundColor(ColorUtil.backgroundColor)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.register(SLessonCell.self, forCellReuseIdentifier: String(describing: SLessonCell.self))
        tableView.emptyDataSetSource = self
        let footer = MJRefreshAutoNormalFooter { [weak self] in
            guard let self = self else { return }
            self.endTimestamp = self.startTimestamp - 1
            self.startTimestamp = DateInRegion(seconds: self.startTimestamp, region: .localRegion).dateByAdding(-3, .month).dateAtStartOf(.month).dateAtStartOf(.day).timeIntervalSince1970
            self.getPracticeData()
            self.getLessonSchedules()
        }
        footer.setTitle("", for: .idle)
        footer.setTitle("Loading more...", for: .refreshing)
        footer.setTitle("", for: .noMoreData)
        footer.stateLabel?.font = FontUtil.regular(size: 15)
        footer.stateLabel?.textColor = ColorUtil.Font.primary
        tableView.mj_footer = footer
        return tableView
    }

    private func makeCreditView() -> ViewBox {
        ViewBox(top: 10, left: 0, bottom: 10, right: 0) {
            Label().textAlignment(.center)
                .apply { [weak self] label in
                    guard let self = self else { return }
                    self.$credits.addSubscriber { credits in
                        label.isHidden = credits.isEmpty
                        let count = credits.count
                        label.attributed.text = ASAttributedString("You have \(count) credit\(count > 1 ? "s" : ""), ", .font(.cardBottomButton), .foreground(.secondary))
                            + ASAttributedString("tap to reschedule.", .font(.cardBottomButton), .foreground(.clickable), .action({
                                logger.debug("点击跳转使用credit")
                                self.toUseCredit()
                            }))
                    }
                }
        }
        .apply { [weak self] view in
            guard let self = self else { return }
            self.$credits.addSubscriber { credits in
                view.isHidden = credits.isEmpty
            }
        }
    }

    private func makeMessagesView() -> ViewBox {
        ViewBox {
            VStack(alignment: .center) {
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
                            Label().textColor(.white)
                                .backgroundColor(ColorUtil.red)
                                .font(.bold(9))
                                .textAlignment(.center)
                                .size(width: 20, height: 20)
                                .cornerRadius(10)
                                .masksToBounds(true)
                                .size(width: 20, height: 20)
                                .cornerRadius(10)
                                .backgroundColor(ColorUtil.red)
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$unreadMessageCount.addSubscriber { count in
                                        if count == 0 {
                                            label.isHidden = true
                                        } else {
                                            label.isHidden = false
                                        }
                                    }
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
                    .cardStyle()
                    Spacer(spacing: 10)
                }
                .width(UIScreen.main.bounds.width - 40)
                .onViewTapped { _ in
                    let controller = MessagesConversationsViewController()
                    controller.style = .fullScreen
                    controller.enableHero()
                    Tools.getTopViewController()?.present(controller, animated: true)
                }
            }
        }
    }

    private func makeFollowUpView() -> ViewBox {
        ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
            ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                HStack(alignment: .center, spacing: 10) {
                    Label("Reschedule request").textColor(.primary)
                        .font(.bold(15))
                    Label().textColor(.white)
                        .backgroundColor(ColorUtil.red)
                        .font(.bold(9))
                        .textAlignment(.center)
                        .size(width: 20, height: 20)
                        .cornerRadius(10)
                        .masksToBounds(true)
                        .apply { [weak self] label in
                            guard let self = self else { return }
                            self.$followUps.addSubscriber { reschedule in
                                let reschedule = reschedule.filter({ $0.dataType == .reschedule })
                                if reschedule.count == 0 {
                                    label.isHidden = true
                                } else {
                                    label.isHidden = false
                                    let countString: String
                                    if reschedule.count > 9 {
                                        countString = "9+"
                                    } else {
                                        countString = "\(reschedule.count)"
                                    }
                                    label.text(countString)
                                }
                            }
                        }
                }
            }
            .cardStyle()
            .onViewTapped { [weak self] _ in
                self?.onFollowUpsViewTapped()
            }
        }
        .apply { [weak self] view in
            guard let self = self else { return }
            self.$followUps.addSubscriber { _ in
                view.isHidden = self.getRescheduleData().isEmpty
            }
        }
    }

    private func makePendingNewLessonView() -> ViewBox {
        ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
            ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                HStack(alignment: .center, spacing: 10) {
                    Label("Pending new lesson").textColor(.primary)
                        .font(.bold(15))
                    Label().textColor(.white)
                        .backgroundColor(ColorUtil.red)
                        .font(.bold(9))
                        .textAlignment(.center)
                        .size(width: 20, height: 20)
                        .cornerRadius(10)
                        .masksToBounds(true)
                        .apply { [weak self] label in
                            guard let self = self else { return }
                            self.$followUps.addSubscriber { followUps in
                                if followUps.count == 0 {
                                    label.isHidden = true
                                } else {
                                    label.isHidden = false
                                    let countString: String
                                    if followUps.count > 9 {
                                        countString = "9+"
                                    } else {
                                        countString = "\(followUps.count)"
                                    }
                                    label.text(countString)
                                }
                            }
                        }
                }
            }
            .cardStyle()
            .onViewTapped { [weak self] _ in
                self?.onPendingNewLessonTapped()
            }
        }
        .apply { [weak self] view in
            guard let self = self else { return }
            self.$followUps.addSubscriber { followUps in
                let pendingNewLessonFollowUps = followUps.filter({ $0.dataType == .studentLessonConfigRequests })
                logger.debug("获取到的pending new lesson的数量: \(pendingNewLessonFollowUps.count) | followUp的数量: \(followUps.count)")
                view.isHidden = pendingNewLessonFollowUps.isEmpty
            }
        }
    }
}

extension StudentLessonsViewController: UITableViewDelegate, UITableViewDataSource, SLessonCellDelegate {
    func sLessonCellSchedule(clickCell cell: SLessonCell) {
        logger.debug("点击cell")
        var endTime: TimeInterval = 0
        // 获取当前课程的下一次课程
        let index = cell.tag - 1
        if index >= 0 {
            endTime = lessonSchedules[index].shouldDateTime
            logger.debug("当前课程不是最后一次课程")
        } else {
            // 当前课程是最后一次
            endTime = Date().timeIntervalSince1970
            logger.debug("当前课程是最后一次课程")
        }
        guard !lessonSchedules[cell.tag].cancelled && !(lessonSchedules[cell.tag].rescheduled && lessonSchedules[cell.tag].rescheduleId != "") else {
            return
        }

        let controller = SLessonDetailsController(lessonSchedule: lessonSchedules[cell.tag])
        controller.modalPresentationStyle = .fullScreen
        controller.endTime = endTime
//        controller.lessonData = lessonSchedule[cell.tag]
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lessonSchedules.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SLessonCell.self), for: indexPath) as! SLessonCell
        cell.tag = indexPath.row
        guard lessonSchedules.isSafeIndex(indexPath.row) else {
            return cell
        }
        let data = lessonSchedules[indexPath.row]
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
        cell.initData(data: lessonSchedules[indexPath.row], newMsg: newMsg)
        cell.delegate = self
        return cell
    }
}

extension StudentLessonsViewController: DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        if scheduleConfigs.count > 0 {
            // 有课程,还没有上过,没有历史课程
            return UIImage(named: "lesson_empty")
        } else {
            if (student?.teacherId ?? "") == "" {
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
            if nextLesson == nil {
                return NSAttributedString(string: "Your lesson will be ready once your instructor confirm your lesson.", attributes: [NSAttributedString.Key.font: FontUtil.bold(size: 16), NSAttributedString.Key.foregroundColor: ColorUtil.Font.primary])
            }
            return NSAttributedString(string: "Enjoy your lessons.", attributes: [NSAttributedString.Key.font: FontUtil.bold(size: 16), NSAttributedString.Key.foregroundColor: ColorUtil.Font.primary])
        } else {
            if (student?.teacherId ?? "") == "" {
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

extension StudentLessonsViewController {
    override func initView() {
        super.initView()
        navigationBar.updateLayout(target: self)
        navigationBar.hiddenLeftButton()
        addButton.addTo(superView: navigationBar) { make in
            make.size.equalTo(30)
            make.centerY.equalToSuperview().offset(4)
            make.left.equalToSuperview().offset(12)
        }

        VStack {
            makeNextLessonView()

            makeFollowUpView()

            makePendingNewLessonView()

            makeMessagesView()

            makeCreditView()

            tableView
        }.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }
    }
}

// MARK: - Load Data

extension StudentLessonsViewController {
    private func loadData() {
        startTimestamp = DateInRegion(region: .localRegion).dateByAdding(-3, .month).dateAtStartOf(.month).dateAtStartOf(.day).timeIntervalSince1970
        endTimestamp = DateInRegion(region: .localRegion).timeIntervalSince1970
        getStudentData()
        getPolicyData()
        getNextLesson()
        getPracticeData()
        getAchievementData()
        getScheduleConfigs()
        getLessonSchedules()
        getCredits()
        getUnreadMessageCount()
        getUndoneReschedule()
    }

    private func getStudentData() {
        guard let currentRole = ListenerService.shared.currentRole else {
            logger.error("无法获取当前角色")
            return
        }
        navigationBar.startLoading()
        if currentRole == .student {
            student = ListenerService.shared.studentData.studentData
        } else {
            student = ParentService.shared.currentStudent
        }
    }

    private func getPolicyData() {
        guard let studentData = student else { return }
        navigationBar.startLoading()
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
            } else if !studentData.teacherId.isEmpty {
                self.policyData = try akawait(UserService.teacher.getPolicy(withTeacherId: studentData.teacherId))
                if self.policyData == nil {
                    self.policyData = TKPolicies()
                    self.policyData?.userId = studentData.teacherId
                }
            }
            updateUI {
                self.navigationBar.stopLoading()
            }
        }
    }

    private func getNextLesson() {
        guard let student else { return }
        logger.debug("获取学生：\(student.studentId) | \(student.studioId) 的下一节课")
        navigationBar.startLoading()
        StudentService.lessons.getNextLesson(studioId: student.studioId, studentId: student.studentId)
            .done { [weak self] lessonSchedule in
                guard let self = self else { return }
                self.nextLesson = lessonSchedule
                logger.debug("获取到的下节课： \(lessonSchedule?.toJSONString() ?? "")")
                if lessonSchedule == nil {
                    self.navigationBar.rightButton.isHidden = true
                    self.nextLessonLocation = nil
                } else {
                    self.navigationBar.rightButton.isHidden = false
                    self.getNextLessonLocation()
                }
                updateUI {
                    self.navigationBar.stopLoading()
                }
            }
            .catch { error in
                logger.error("获取下节课失败：\(error)")
            }
    }

    private func getNextLessonLocation() {
        guard let nextLesson else { return }
        let configId = nextLesson.lessonScheduleConfigId
        StudentService.lessons.getLessonScheduleConfig(withId: configId)
            .done { [weak self] lessonScheduleConfig in
                guard let self = self else { return }
                self.nextLessonLocation = lessonScheduleConfig?.location
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                self.nextLessonLocation = nil
                logger.error("获取lesson location失败: \(error)")
            }
    }

    private func getPracticeData() {
        guard let student else { return }
        navigationBar.startLoading()
        StudentService.lessons.getPractice(withTimeRange: DateTimeRange(startTime: startTimestamp, endTime: endTimestamp), studentId: student.studentId, studioId: student.studioId)
            .done { [weak self] practice in
                guard let self = self else { return }
                self.practiceData = practice
                updateUI {
                    self.navigationBar.stopLoading()
                }
            }
            .catch { error in
                logger.error("获取练习数据失败: \(error)")
            }
    }

    private func getAchievementData() {
        guard let student else { return }
        StudentService.lessons.getAchievements(student.studentId)
            .done { [weak self] achievement in
                guard let self = self else { return }
                self.achievementData = achievement
                updateUI {
                    self.navigationBar.stopLoading()
                }
            }
            .catch { error in
                logger.error("获取 achievement 失败：\(error)")
            }
    }

    private func getScheduleConfigs() {
        guard let student else { return }
        navigationBar.startLoading()
        akasync { [weak self] in
            guard let self = self else { return }
            self.scheduleConfigs = try akawait(StudentService.lessons.getLessonScheduleConfigs(studioId: student.studioId, studentId: student.studentId))
            logger.debug("获取到的 lessonConfig 数量: \(self.scheduleConfigs.count)")
            let lessonTypeIds = self.scheduleConfigs.compactMap({ $0.lessonTypeId })
            self.lessonTypes = try akawait(StudentService.lessons.getLessonTypes(lessonTypeIds))
            try akawait(LessonService.lessonScheduleConfigure.studioRefreshLessonSchedules(with: self.scheduleConfigs, startTime: TimeInterval(self.startTimestamp), endTime: TimeInterval(self.endTimestamp)))
            updateUI {
                self.navigationBar.stopLoading()
                self.tableView.reloadData()
                self.getLessonSchedules()
            }
        }
    }

    private func getLessonSchedules() {
        guard let student else { return }
        navigationBar.startLoading()
        StudentService.lessons.getLessonSchedule(withStudentId: student.studentId, studioId: student.studioId, dateTimeRange: DateTimeRange(startTime: startTimestamp, endTime: endTimestamp))
            .done { [weak self] lessonSchedules in
                guard let self = self else { return }
                self.lessonSchedules += lessonSchedules
                self.lessonSchedules = self.lessonSchedules.filterDuplicates({ $0.id }).sorted(by: { $0.shouldDateTime > $1.shouldDateTime })
                logger.debug("获取到的课程数量: \(lessonSchedules.count)")
                updateUI {
                    if lessonSchedules.isEmpty {
                        self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                    } else {
                        self.tableView.mj_footer?.endRefreshing()
                    }
                    self.navigationBar.stopLoading()
                    self.tableView.reloadData()
                    self.getLessonScheduleMaterials()
                }
            }
            .catch { error in
                logger.error("获取课程失败：\(error)")
            }
    }

    private func getLessonScheduleMaterials() {
        let ids = lessonSchedules.compactMap { $0.id }
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

    private func getCredits() {
        guard let student else { return }
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

    private func getUnreadMessageCount() {
        DBService.message.listAllUnreadMessages { [weak self] messages in
            guard let self = self else { return }
            self.unreadMessageCount = messages.count
        }
    }

    private func getUndoneReschedule() {
        followUps = ListenerService.shared.studentData.followUps
    }
}

extension StudentLessonsViewController {
    override func bindEvent() {
        super.bindEvent()
        $nextLesson.addSubscriber { [weak self] nextLesson in
            guard let self = self else { return }
            if nextLesson == nil {
                _ = self.navigationBar.rightButton.title(title: "ADD LESSON")
            } else {
                _ = self.navigationBar.rightButton.title(title: "UPCOMING")
            }
        }

        EventBus.listen(key: .studentFollowUpsChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.getUndoneReschedule()
        }

        EventBus.listen(key: .studentConfigChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.loadData()
        }
    }
}

extension StudentLessonsViewController: AllFuturesControllerDelegate {
    func allFuturesController(clickPendingLesson id: String) {
    }

    private func onNavigationRightButtonTapped() {
        if nextLesson == nil {
            onAddLessonTapped()
        } else {
            onUpcomingTapped()
        }
    }

    private func onUpcomingTapped() {
        let controller = AllFuturesController()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.studentData = student
        controller.lessonTypes = lessonTypes
        controller.scheduleConfigs = scheduleConfigs
        controller.enablePanToDismiss()
        controller.delegate = self
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    private func onAddLessonTapped() {
        PopSheet()
            .items([
                .init(title: "Join Group Lesson", action: { [weak self] in
                    self?.onJoinGroupLessonTapped()
                }),
                .init(title: "Add Private Lesson", action: { [weak self] in
                    self?.onAddPrivateLessonTapped()
                }),
            ])
            .show()
    }

    private func onAddPrivateLessonTapped() {
        let controller = StudioAddLessonForStudentViewController(student)
        controller.skipSteps = [.addInstructors, .addStudent, .selectStudent]
        controller.modalPresentationStyle = .custom
        Tools.getTopViewController()?.present(controller, animated: false)
    }

    private func onJoinGroupLessonTapped() {
        let controller = StudioGroupLessonSelectorViewController()
        controller.modalPresentationStyle = .custom
        Tools.getTopViewController()?.present(controller, animated: false)
        controller.onGroupLessonSelected = { lessons in
            guard let lesson = lessons.first else { return }
            let controller = GroupLessonJoinViewController(lessonScheduleConfigId: lesson.id)
            controller.modalPresentationStyle = .custom
            Tools.getTopViewController()?.present(controller, animated: false)
        }
    }
}

extension StudentLessonsViewController {
    private func onAddLessonButtonTapped() {
    }

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

extension StudentLessonsViewController {
    private func onLeftNextLessonViewTapped() {
        guard let nextLesson, !nextLesson.cancelled else { return }
        isNextLessonBottomButtonsShow.toggle()
    }

    private func onRightNextLessonViewTapped() {
        guard let nextLesson else {
            logger.debug("无法获取到下一节课")
            return
        }
        let controller = SLessonDetailsController(lessonSchedule: nextLesson)
        controller.modalPresentationStyle = .fullScreen
        controller.endTime = Date().timeIntervalSince1970
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        Tools.getTopViewController()?.present(controller, animated: true, completion: nil)
        isNextLessonBottomButtonsShow = false
    }
}

extension StudentLessonsViewController {
    private func onNextLessonCancelTapped() {
        guard let user = ListenerService.shared.user else { return }
        switch user.currentUserDataVersion {
        case .singleTeacher:
            if scheduleConfigs.filter({ $0.teacherId == "" }).count == 0 {
                cancelLesson()
            } else {
                if let data = nextLesson {
                    deleteLessonWithoutTeacher(data: data)
                }
            }
        case .studio:
            cancelLessonV2()
        case let .unknown(version: version):
            fatalError("Unknown user data version: \(version)")
        }
        isNextLessonBottomButtonsShow = false
    }

    private func onNextLessonRescheduleTapped() {
        guard let studentData = student else {
            logger.debug("当前无法获取学生信息")
            return
        }
        logger.debug("获取到了学生信息，可以继续: \(studentData.toJSONString() ?? "")")
        if studentData.studioId != "" {
            logger.debug("当前学生的studioId不为空")
            if studentData.studentApplyStatus == .apply {
                logger.debug("当前学生的状态是apply")
                // 再次邀请老师
                CommonsService.shared.studentReinviteTeacher()
            } else {
                logger.debug("开始准备Reschedule课程")
                rescheduleLesson()
            }
        } else {
            addTeacher()
        }
    }

    private func onNextLessonMakeupTapped() {
    }
}

extension StudentLessonsViewController {
    private func onFollowUpsViewTapped() {
        let controller = SRescheduleListController()
        controller.data = getRescheduleData()
        controller.enableHero()
        present(controller, animated: true, completion: nil)
    }

    private func onPendingNewLessonTapped() {
        let controller = StudentPendingNewLessonsViewController()
        controller.enableHero()
        Tools.getTopViewController()?.present(controller, animated: true)
    }

    private func getRescheduleData() -> [TKReschedule] {
        var rescheduleData: [TKReschedule] = []
        for followUp in ListenerService.shared.studentData.followUps {
            if let reschedule = followUp.rescheduleData {
                reschedule.id = followUp.id
                if !(followUp.status == .archived && reschedule.studentRead) {
                    rescheduleData.append(reschedule)
                } else if followUp.status == .pending {
                    rescheduleData.append(reschedule)
                }
            }
        }
        return rescheduleData
    }

    private func getPendingNewLessonData() -> [TKFollowUp] {
        ListenerService.shared.studentData.followUps.filter({ $0.dataType.rawValue == "STUDENT_LESSON_CONFIG_REQUESTS" })
    }
}

// MARK: - CANCEL NEXT LESSON START

extension StudentLessonsViewController {
    func deleteLessonWithoutTeacher(data: TKLessonSchedule) {
        // 获取config

        guard let config = ListenerService.shared.studentData.scheduleConfigs.filter({ $0.id == data.lessonScheduleConfigId }).first else { return }

        if config.repeatType == .none {
            SL.Alert.show(target: self, title: "Warning", message: "Are you sure you want to delete this lesson?", leftButttonString: "Go back", rightButtonString: "Delete") {
            } rightButtonAction: { [weak self] in
                guard let self = self else { return }
                LessonService.lessonSchedule.studentDeleteLessonWithoutTeacher(data: data, deleteUpcoming: false)
                    .done { _ in
                        self.hideFullScreenLoading()
                        self.getNextLesson()
                        TKToast.show(msg: "Removed this lesson successfully")
                    }
                    .catch { _ in
                        self.hideFullScreenLoading()
                        TKToast.show(msg: "Remove failed, try again later", style: .error)
                    }
            }

        } else {
            SL.Alert.show(target: self, title: "Warning", message: "Are you sure you want to delete this lesson?", leftButttonString: "Go back", centerButttonString: "This and upcoming lessons", rightButtonString: "Only this lesson") {
            } centerButtonAction: { [weak self] in
                guard let self = self else { return }
                self.showFullScreenLoading()
                LessonService.lessonSchedule.studentDeleteLessonWithoutTeacher(data: data, deleteUpcoming: true)
                    .done { _ in
                        self.hideFullScreenLoading()
                        self.getNextLesson()
                        TKToast.show(msg: "Removed this lesson successfully")
                    }
                    .catch { _ in
                        self.hideFullScreenLoading()
                        TKToast.show(msg: "Remove failed, try again later", style: .error)
                    }
            } rightButtonAction: { [weak self] in
                guard let self = self else { return }
                self.showFullScreenLoading()
                LessonService.lessonSchedule.studentDeleteLessonWithoutTeacher(data: data, deleteUpcoming: false)
                    .done { _ in
                        self.hideFullScreenLoading()
                        self.getNextLesson()
                        TKToast.show(msg: "Removed this lesson successfully")
                    }
                    .catch { _ in
                        self.hideFullScreenLoading()
                        TKToast.show(msg: "Remove failed, try again later", style: .error)
                    }
            }
        }
    }

    func cancelLesson() {
        guard let policyData = policyData else { return }
        showFullScreenLoading()
        func cancelLesson(cell: AllFuturesCell) {
            guard let nextLessonData = nextLesson else { return }
            showFullScreenLoading()

            guard nextLessonData.cancelled else {
                // 说明已经Cancel
                showCancelLessonAlert(type: 4, rescheduleId: nil)
                return
            }
            guard policyData.allowMakeup || policyData.allowRefund else {
                // 说明不可以makeup 也不可以 refund
                showCancelLessonAlert(type: 1, rescheduleId: nil)
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
                                showCancelLessonAlert(type: 3, rescheduleId: nil)
                            } else {
                                if (endTime + (policyData.refundNoticeRequired * 60 * 60)) <= Int(nextLessonData.shouldDateTime) {
                                    //  在规定的时间段内
                                    showCancelLessonAlert(type: 3, rescheduleId: nil)
                                } else {
                                    showCancelLessonAlert(type: 1, rescheduleId: nil)
                                }
                            }
                        } else {
                            // 没次数
                            showCancelLessonAlert(type: 1, rescheduleId: nil)
                        }

                    } else {
                        // limited times  没有开启,此处需要判断notice Required是否开启
                        if policyData.refundNoticeRequired == 0 {
                            // 关闭状态,显示第三个弹窗
                            showCancelLessonAlert(type: 3, rescheduleId: nil)
                        } else {
                            if (endTime + (policyData.refundNoticeRequired * 60 * 60)) <= Int(nextLessonData.shouldDateTime) {
                                //  在规定的时间段内
                                showCancelLessonAlert(type: 3, rescheduleId: nil)
                            } else {
                                showCancelLessonAlert(type: 1, rescheduleId: nil)
                            }
                        }
                    }

                } else {
                    // 不支持Refund
                    showCancelLessonAlert(type: 1, rescheduleId: nil)
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
                            showCancelLessonAlert(type: 2, rescheduleId: nil)
                        } else {
                            if (endTime + (policyData.makeupNoticeRequired * 60 * 60)) <= Int(nextLessonData.shouldDateTime) {
                                //  在规定的时间段内,显示第二个弹窗
                                showCancelLessonAlert(type: 2, rescheduleId: nil)
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
                        showCancelLessonAlert(type: 2, rescheduleId: nil)
                    } else {
                        if (endTime + (policyData.makeupNoticeRequired * 60 * 60)) <= Int(nextLessonData.shouldDateTime) {
                            //  在规定的时间段内,显示第二个弹窗
                            showCancelLessonAlert(type: 2, rescheduleId: nil)
                        } else {
                            // 不在时间段内, 走 refund流程
                            refund(data)
                        }
                    }
                }
            }
            guard let studentData = student else { return }
            addSubscribe(
                UserService.teacher.getRescheduleMakeupRefundHistory(type: [.makeup, .refund], teacherId: studentData.teacherId, studentId: studentData.studentId)
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
        guard let nextLessonData = nextLesson else { return }
        guard !nextLessonData.cancelled else {
            // 说明已经Cancel
            showCancelLessonAlert(type: 4, rescheduleId: nil)
            return
        }
        guard policyData.allowMakeup || policyData.allowRefund else {
            // 说明不可以makeup 也不可以 refund
            showCancelLessonAlert(type: 1, rescheduleId: nil)
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
                            showCancelLessonAlert(type: 3, rescheduleId: nil)
                        } else {
                            if (endTime + (policyData.refundNoticeRequired * 60 * 60)) <= Int(nextLessonData.shouldDateTime) {
                                //  在规定的时间段内
                                showCancelLessonAlert(type: 3, rescheduleId: nil)
                            } else {
                                showCancelLessonAlert(type: 1, rescheduleId: nil)
                            }
                        }
                    } else {
                        // 没次数
                        showCancelLessonAlert(type: 1, rescheduleId: nil)
                    }

                } else {
                    // limited times  没有开启,此处需要判断notice Required是否开启
                    if policyData.refundNoticeRequired == 0 {
                        // 关闭状态,显示第三个弹窗
                        showCancelLessonAlert(type: 3, rescheduleId: nil)
                    } else {
                        if (endTime + (policyData.refundNoticeRequired * 60 * 60)) <= Int(nextLessonData.shouldDateTime) {
                            //  在规定的时间段内
                            showCancelLessonAlert(type: 3, rescheduleId: nil)
                        } else {
                            showCancelLessonAlert(type: 1, rescheduleId: nil)
                        }
                    }
                }

            } else {
                // 不支持Refund
                showCancelLessonAlert(type: 1, rescheduleId: nil)
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
                        showCancelLessonAlert(type: 2, rescheduleId: nil)
                    } else {
                        if (endTime + (policyData.makeupNoticeRequired * 60 * 60)) <= Int(nextLessonData.shouldDateTime) {
                            //  在规定的时间段内,显示第二个弹窗
                            showCancelLessonAlert(type: 2, rescheduleId: nil)
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
                    showCancelLessonAlert(type: 2, rescheduleId: nil)
                } else {
                    if (endTime + (policyData.makeupNoticeRequired * 60 * 60)) <= Int(nextLessonData.shouldDateTime) {
                        //  在规定的时间段内,显示第二个弹窗
                        showCancelLessonAlert(type: 2, rescheduleId: nil)
                    } else {
                        // 不在时间段内, 走 refund流程
                        refund(data)
                    }
                }
            }
        }
        guard let studentData = student else { return }
        addSubscribe(
            UserService.teacher.getRescheduleMakeupRefundHistory(type: [.makeup, .refund], teacherId: studentData.teacherId, studentId: studentData.studentId)
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

    /// 显示cancelLessonAlert
    /// - Parameters:
    ///   - type:  1:不退款也不可以makeup 2:Makeup 3:退款
    ///   - cell:
    ///   - isNoReschedule: 判断是不是正在Reschedule
    private func showCancelLessonAlert(type: Int, rescheduleId: String?, isReschedule: Bool = false) {
        guard let nextLessonData = nextLesson else { return }
        // 1:不退款也不可以makeup 2:Makeup 3:退款 4:不可以Cancel
        hideFullScreenLoading()
        logger.debug("======\(type)")
        var title = ""
        var message = ""
        if !isReschedule {
            if nextLessonData.rescheduled {
                showCancelReschduleAlert(type)
                return
            }
        }

        switch type {
        case 1:
            title = "Cancel lesson?"
            message = "\(TipMsg.cancelNow)"
            let controller = SL.SLAlert()
            controller.modalPresentationStyle = .custom
            controller.titleString = title
            controller.rightButtonColor = ColorUtil.main
            controller.leftButtonColor = ColorUtil.red
            controller.rightButtonString = "GO BACK"
            controller.leftButtonString = "CANCEL ANYWAYS"
            controller.leftButtonAction = {
                [weak self] in
                guard let self = self, let nextLessonData = self.nextLesson else { return }
                self.addCancellation(type: 1, schedule: nextLessonData, rescheduleId: rescheduleId, isReschedule: isReschedule)
            }
            controller.rightButtonAction = {
            }
            controller.messageString = message
            controller.leftButtonFont = FontUtil.bold(size: 13)
            controller.rightButtonFont = FontUtil.bold(size: 13)
            present(controller, animated: false, completion: nil)
            isNextLessonBottomButtonsShow = false
            break
        case 2:
            title = "Cancel lesson?"
            message = "If you decided to cancel now, you will receive session credit for a later date. "
            //            SL.Alert.show(target: self, title: title, message: message, leftButttonString: "No", rightButtonString: "Yes", rightButtonColor: ColorUtil.red, leftButtonAction: {
            //            }) { [weak self] in
            //                guard let self = self else { return }
            //                // 多了一条MakeUp的信息
            //                self.addCancellation(type: 2, schedule: self.nextLessonData, rescheduleId: rescheduleId, isReschedule: isReschedule)
            //            }

            let controller = SL.SLAlert()
            controller.modalPresentationStyle = .custom
            controller.titleString = title
            controller.rightButtonColor = ColorUtil.main
            controller.leftButtonColor = ColorUtil.red
            controller.rightButtonString = "GO BACK"
            controller.leftButtonString = "CANCEL NOW"
            controller.leftButtonAction = { [weak self] in
                guard let self = self, let nextLessonData = self.nextLesson else { return }
                self.addCancellation(type: 2, schedule: nextLessonData, rescheduleId: rescheduleId, isReschedule: isReschedule)
            }
            controller.rightButtonAction = {
            }
            controller.messageString = message
            controller.leftButtonFont = FontUtil.bold(size: 13)
            controller.rightButtonFont = FontUtil.bold(size: 13)
            present(controller, animated: false, completion: nil)
            isNextLessonBottomButtonsShow = false

            break
        case 3:
            getLessonType(schedule: nextLessonData, isReschedule: isReschedule, rescheduleId: rescheduleId)
            break
        case 4:

            break
        default:
            break
        }
    }

    /// 点击Cancel 显示该课程正在Reschedule的Alert
    /// - Parameters:
    ///   - type:type: Int, _ cell: AllFuturesCell
    ///   - cell:
    private func showCancelReschduleAlert(_ type: Int) {
        guard let nextLessonData = nextLesson else { return }
        showFullScreenLoading()
        addSubscribe(
            LessonService.lessonSchedule.getRescheduleByOldScheduleId(oldScheduleId: nextLessonData.id)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    guard docs.from == .server else { return }
                    self.hideFullScreenLoading()

                    var data: [TKReschedule] = []
                    for doc in docs.documents {
                        if let doc = TKReschedule.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }
                    if data.count == 0 {
                        SL.Alert.show(target: self, title: "", message: TipMsg.connectionFailed, centerButttonString: "OK") {
                        }
                    } else {
                        if data[0].timeAfter == "" {
                            // 说明是老师发起的Reschedule 学生还未配置时间
                            self.showCancelLessonAlert(type: type, rescheduleId: data[0].id, isReschedule: true)
                        } else {
                            //                            let df = DateFormatter()
                            //                            df.dateFormat = "MMM d, hh:mm a"

                            //                            SL.Alert.show(target: self, title: "Prompt", message: "This lesson is pending on confirmation of rescheduling to \(df.string(from: TimeUtil.changeTime(time: Double(data[0].timeAfter)!))). Would you like to continue to cancel?", leftButttonString: "CANCEL", rightButtonString: "OK", leftButtonAction: {
                            //                            }) { [weak self] in
                            //                                self?.showCancelLessonAlert(type: type, cell, rescheduleId: data[0].id, isReschedule: true)
                            //                            }

                            let controller = SL.SLAlert()
                            controller.modalPresentationStyle = .custom
                            controller.titleString = ""
                            controller.rightButtonColor = ColorUtil.main
                            controller.leftButtonColor = ColorUtil.red
                            controller.rightButtonString = "GO BACK"
                            controller.leftButtonString = "CANCEL ANYWAYS"
                            controller.messageString = "This lession is pending to be rescheduled. Cancel anyways?"
                            controller.leftButtonAction = {
                                [weak self] in
                                guard let self = self else { return }
                                self.showCancelLessonAlert(type: type, rescheduleId: data[0].id, isReschedule: true)
                            }
                            controller.rightButtonAction = {
                            }

                            controller.leftButtonFont = FontUtil.bold(size: 13)
                            controller.rightButtonFont = FontUtil.bold(size: 13)
                            self.present(controller, animated: false, completion: nil)
                            self.isNextLessonBottomButtonsShow = false
                        }
                    }

                }, onError: { [weak self] err in
                    guard let self = self else { return }

                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)

                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func addCancellation(type: Int, schedule: TKLessonSchedule, rescheduleId: String?, isReschedule: Bool = false) {
        guard let studentData = student else { return }
        // 1:不退款也不可以makeup 2:Makeup 3:退款
        showFullScreenLoading()
        let time = "\(Date().timestamp)"
        let cancellationData = TKLessonCancellation()
        var sendType = 0
        cancellationData.id = schedule.id
        cancellationData.oldScheduleId = schedule.id
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

        // MARK: - TimeBefore 要修改的地方

        cancellationData.timeBefore = "\(schedule.shouldDateTime)"
        cancellationData.createTime = time
        cancellationData.updateTime = time
        if !isReschedule {
            addSubscribe(
                LessonService.lessonSchedule.cancelSchedule(data: cancellationData)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                        sendHis()
                        CommonsService.shared.sendEmailToTeacherForCancellation(studentName: studentData.name, lessonStartTime: Int(schedule.shouldDateTime), teacherId: schedule.teacherId, type: sendType)
                        TKToast.show(msg: TipMsg.cancellationSuccessful, style: .success)
                        self.nextLesson?.cancelled = true
                    }, onError: { [weak self] err in
                        self?.hideFullScreenLoading()
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                        logger.debug("获取失败:\(err)")
                    })
            )
        } else {
            guard let rescheduleId = rescheduleId else {
                hideFullScreenLoading()
                TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                return
            }
            guard let studentData = student else { return }
            addSubscribe(
                LessonService.lessonSchedule.cancelSchedule(data: cancellationData, rescheduleId: rescheduleId)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }

                        self.hideFullScreenLoading()
                        sendHis()
                        CommonsService.shared.sendEmailToTeacherForCancellation(studentName: studentData.name, lessonStartTime: Int(schedule.getShouldDateTime()), teacherId: schedule.teacherId, type: sendType)

                        //                        self.dismiss(animated: true) {
                        //                            TKToast.show(msg: TipMsg.cancellationSuccessful, style: .success)
                        //                        }
                        TKToast.show(msg: TipMsg.cancellationSuccessful, style: .success)
                        self.nextLesson?.cancelled = true
//                            self.tableView.reloadRows(at: [IndexPath(row: cell.tag, section: 0)], with: .none)
                    }, onError: { [weak self] err in
                        self?.hideFullScreenLoading()
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                        logger.debug("获取失败:\(err)")
                    })
            )
        }

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

    private func getLessonType(schedule: TKLessonSchedule, isReschedule: Bool, rescheduleId: String?) {
        guard let policyData = policyData else { return }
        let title = "Cancel lesson?"
        //                        let message = "A $\(doc.price.description) adjustment will be deducted from the balance on your next bill if you decide to cancal this lesson."
        let remainingTime = Date().timestamp + policyData.refundNoticeRequired * 60 * 60
        var hour: CGFloat = CGFloat((schedule.shouldDateTime - Double(remainingTime)) / 60 / 60).roundTo(places: 1)
        var message = "You will receive credit if you cancel within the next \(hour) hours"
        if hour > 24 {
            hour = (hour / 24).roundTo(places: 0)
            message = "You will receive credit if you cancel within the next \(Int(hour)) days"
        }

        //                        self.policyData.

        //        SL.Alert.show(target: self, title: title, message: message, leftButttonString: "No", rightButtonString: "Yes", rightButtonColor: ColorUtil.red, leftButtonAction: {
        //        }) {
        //            self.addCancellation(type: 3, schedule: schedule, rescheduleId: rescheduleId, isReschedule: isReschedule)
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
            self.addCancellation(type: 3, schedule: schedule, rescheduleId: rescheduleId, isReschedule: isReschedule)
        }
        controller.rightButtonAction = {
        }

        controller.leftButtonFont = FontUtil.bold(size: 13)
        controller.rightButtonFont = FontUtil.bold(size: 13)
        present(controller, animated: false, completion: nil)
        isNextLessonBottomButtonsShow = false
    }
}

extension StudentLessonsViewController {
    func cancelLessonV2() {
        SL.Alert.show(target: self, title: "Cancel lesson?", message: "Are you sure cancel this lesson?", leftButttonString: "CANCEL", rightButtonString: "Go back") { [weak self] in
            guard let self = self, let nextLesson = self.nextLesson else { return }
            self.commitCancelLessonV2(nextLesson)
        } rightButtonAction: {
        }
    }

    func commitCancelLessonV2(_ lessonSchedule: TKLessonSchedule) {
        logger.debug("提交cancel课程: \(lessonSchedule.id)")
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
                    self.nextLesson = nil
                    self.getNextLesson()
                }
            }
    }
}

// MARK: - CANCEL NEXT LESSON END

// MARK: - RESCHEDULE NEXT LESSON START

extension StudentLessonsViewController {
    func rescheduleLesson() {
        guard let policyData = policyData, let nextLessonData = nextLesson else {
            logger.debug("无法获取 policy 或者 next lesson")
            return
        }
        showFullScreenLoading()
        func openNoRescheduleAlert(_ type: Int) {
            hideFullScreenLoading()
            // 1:正在reschedule, 2:不允许reschedule, 3:不在规定时间范围内, 4:次数不够
            switch type {
            case 1:
                getReschdeuleData()
                break
            case 2:
                SL.Alert.show(target: self, title: "Reschedule lesson?", message: "\(TipMsg.notAllowRescheduling1)", centerButttonString: "OK") {
                }
                break
            case 3:
                SL.Alert.show(target: self, title: "", message: "Rescheduling is discouraged beyond \(policyData.rescheduleNoticeRequired) hours before the lesson. You may still cancel, but not receive a refund or any credit. ", centerButttonString: "OK") {
                }
                break
            case 4:
                //                SL.Alert.show(target: self, title: "Prompt", message: "You already rescheduled \(policyData.rescheduleLimitTimesAmount) times in passed \(policyData.rescheduleLimitTimesPeriod) month, According to the studio's policy, you can't reschedule.", centerButttonString: "OK") {
                //                }
                /**
                 4:
                 Your instructor's policies allow reschedules per_month(s).
                 You have passed this limit and can NOT rechedule until 07/2.
                 However, you can cancel the lesson.
                 */
                //                SL.Alert.show(target: self, title: "Prompt", message: "Your instructor's policies allow \(policyData.rescheduleLimitTimesAmount) reschedules per \(policyData.rescheduleLimitTimesPeriod) month. You have passed this limit and can NOT rechedule. However, you can cancel the lesson.", leftButttonString: "GO BACK", rightButtonString: "CANCEL INSTEAD", leftButtonColor: ColorUtil.main, rightButtonColor: ColorUtil.red, leftButtonAction: {
                //                }) { [weak self] in
                //                    self?.cancelLesson(cell: cell)
                //                }
                let controller = SL.SLAlert()
                controller.modalPresentationStyle = .custom
                controller.titleString = "Oops!"
                controller.rightButtonColor = ColorUtil.main
                controller.leftButtonColor = ColorUtil.red
                controller.rightButtonString = "GO BACK"
                controller.leftButtonString = "CANCEL INSTEAD"
                controller.leftButtonAction = { [weak self] in
                    self?.cancelLesson()
                }
                controller.rightButtonAction = {
                }
                controller.messageString = "Your instructor's policies allow \(policyData.rescheduleLimitTimesAmount) reschedule\(policyData.rescheduleLimitTimesAmount <= 1 ? "" : "s") per \(policyData.rescheduleLimitTimesPeriod) month\(policyData.rescheduleLimitTimesPeriod <= 1 ? "" : "s"). You have passed this limit and can NOT reschedule. However, you can cancel the lesson."
                controller.leftButtonFont = FontUtil.bold(size: 13)
                controller.rightButtonFont = FontUtil.bold(size: 13)
                present(controller, animated: false, completion: nil)
                isNextLessonBottomButtonsShow = false

                break
            default:
                break
            }
        }
        func openRescheduleController() {
            guard let nextLessonData = nextLesson else { return }
            hideFullScreenLoading()

            let controller = RescheduleController(originalData: nextLessonData, buttonType: .reschedule, policyData: policyData)
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.enablePanToDismiss()
            //        controller.originalData = nextLessonData
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            present(controller, animated: true, completion: nil)
            isNextLessonBottomButtonsShow = false
        }

        guard !nextLessonData.rescheduled else {
            // 正在Reschedule 中
            openNoRescheduleAlert(1)

            return
        }
        guard policyData.allowReschedule else {
            // 不允许Reschedule
            openNoRescheduleAlert(2)
            return
        }
        guard policyData.rescheduleLimitTimes else {
            let time = Date().timestamp

            if policyData.rescheduleNoticeRequired != 0 {
                if (time + (policyData.rescheduleNoticeRequired * 60 * 60)) <= Int(nextLessonData.shouldDateTime) {
                    // 说明 时间大于规定可reschedule 的时间
                    openRescheduleController()
                } else {
                    // 说明 时间小于规定可reschedule 的时间
                    openNoRescheduleAlert(3)
                }

            } else {
                // 说明 可以无限reschedule 并且 只要在开课之前就可以Reschedule
                openRescheduleController()
            }

            return
        }
        guard let studentData = student else { return }
        addSubscribe(
            UserService.teacher.getRescheduleMakeupRefundHistory(type: [.reschedule], teacherId: studentData.teacherId, studentId: studentData.studentId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else {
                        return
                    }
                    guard docs.from == .server else {
                        return
                    }
                    var data: [TKRescheduleMakeupRefundHistory] = []
                    for doc in docs.documents {
                        if let doc = TKRescheduleMakeupRefundHistory.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }
                    if data.count > 0 {
                        let date = Date()
                        let toDayStart = date.startOfDay
                        let firstRescheduleTime = TimeUtil.changeTime(time: Double(data[0].createTime)!).startOfDay.timestamp
                        var day = ((toDayStart.timestamp - firstRescheduleTime) % (policyData.rescheduleLimitTimesPeriod * 30 * 24 * 60 * 60))
                        day = day / 60 / 60 / 24
                        let startTime = toDayStart.add(component: .day, value: -day).timestamp
                        let endTime = date.timestamp
                        var count = 0
                        for item in data {
                            if let time = Int(item.createTime) {
                                if time >= startTime && time <= endTime {
                                    count += 1
                                }
                            }
                        }
                        if count < policyData.rescheduleLimitTimesAmount {
                            if policyData.rescheduleNoticeRequired != 0 {
                                if (endTime + (policyData.rescheduleNoticeRequired * 60 * 60)) <= Int(nextLessonData.shouldDateTime) {
                                    // 说明有剩余次数 且 在规定的时间段内
                                    openRescheduleController()
                                } else {
                                    openNoRescheduleAlert(3)
                                }
                            } else {
                                // 说明 可以无限reschedule 并且还有剩余次数
                                openRescheduleController()
                            }
                        } else {
                            // 次数不够
                            openNoRescheduleAlert(4)
                        }

                    } else {
                        openRescheduleController()
                    }

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

    private func getReschdeuleData() {
        guard let policyData = policyData, let nextLessonData = nextLesson else { return }
        showFullScreenLoading()
        addSubscribe(
            LessonService.lessonSchedule.getRescheduleByOldScheduleId(oldScheduleId: nextLessonData.id)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    guard docs.from == .server else { return }
                    self.hideFullScreenLoading()

                    var data: [TKReschedule] = []
                    for doc in docs.documents {
                        if let doc = TKReschedule.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }
                    if data.count == 0 {
                        SL.Alert.show(target: self, title: "", message: "\(TipMsg.notAllowRescheduling)", centerButttonString: "OK") {
                        }
                    } else {
                        if data[0].timeAfter == "" {
                            // 说明是老师发起的Reschedule 学生还未配置时间
                            let controller = RescheduleController(originalData: nextLessonData, rescheduleData: data[0], buttonType: .cancelLesson, policyData: policyData, isEdit: false)
                            controller.modalPresentationStyle = .fullScreen
                            controller.hero.isEnabled = true
                            controller.enablePanToDismiss()
                            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                            self.present(controller, animated: true, completion: nil)
                            self.isNextLessonBottomButtonsShow = false

                        } else {
                            let controller = SL.SLAlert()
                            controller.modalPresentationStyle = .custom
                            controller.titleString = ""
                            controller.rightButtonColor = ColorUtil.main
                            controller.leftButtonColor = ColorUtil.red
                            controller.rightButtonString = "GO BACK"
                            controller.leftButtonString = "TO RESCHEDULE"
                            controller.messageString = "This lession is pending to be rescheduled. reschedule anyways? "
                            controller.leftButtonAction = {
                                [weak self] in
                                guard let self = self else { return }
                                let controller = RescheduleController(originalData: nextLessonData, rescheduleData: data[0], buttonType: .reschedule, policyData: policyData, isEdit: true)
                                controller.modalPresentationStyle = .fullScreen
                                controller.hero.isEnabled = true
                                controller.enablePanToDismiss()
                                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                                self.present(controller, animated: true, completion: nil)
                                self.isNextLessonBottomButtonsShow = false
                            }
                            controller.rightButtonAction = {
                            }

                            controller.leftButtonFont = FontUtil.bold(size: 13)
                            controller.rightButtonFont = FontUtil.bold(size: 13)
                            self.present(controller, animated: false, completion: nil)
                            self.isNextLessonBottomButtonsShow = false
                        }
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }

                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)

                    logger.debug("获取失败:\(err)")
                })
        )
    }
}

extension StudentLessonsViewController: SInviteTeacherViewControllerDelegate {
    func addTeacher() {
        guard let userId = UserService.user.id() else { return }
        showFullScreenLoading()
        UserService.user.getUser(id: userId)
            .done { [weak self] user in
                guard let self = self else { return }
                guard let user = user else {
                    self.updateFullScreenLoadingMsg(msg: "Init data failed, please try again later.")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                    }
                    return
                }
                CacheUtil.UserInfo.setUser(user: user)
                self.hideFullScreenLoading()
                DispatchQueue.main.async {
                    self.toInviteTeacher()
                }
            }
            .catch { _ in
                self.updateFullScreenLoadingMsg(msg: "Init data failed, please try again later.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                }
            }
    }

    func toInviteTeacher() {
        let controller = SInviteTeacherViewController()
        controller.delegate = self
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

    func sInviteTeacherViewControllerDismissed() {
    }
}

// MARK: - RESCHEDULE NEXT LESSON END
