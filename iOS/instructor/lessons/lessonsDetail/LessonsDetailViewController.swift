//
//  LessonsDetailViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/30.
//  Copyright © 2019年 spelist. All rights reserved.
//
import FirebaseFunctions
import Hero
import IQKeyboardManagerSwift
import SnapKit
import UIKit

class LessonsDetailViewController: TKBaseViewController {
    private var navigationBar: TKNormalNavigationBar!

    private var topStepBarView: TKView!
    private var topStepBar: TKStepBar!
    private var cellStepBar: TKStepBar?

    private var tableView: UITableView!

    private var topAvatarView: TKAvatarView!

    private var cellHeights: [CGFloat] = [253, 80, 80, 80, 80, 0, 0, 0]

    var titleString = ""

    private var data: [TKLessonSchedule] = []

    private var selectedPos = 0 {
        didSet {
            setMemo()
        }
    }

    var dateFormatter: DateFormatter = DateFormatter()
    private var finishLoading: LessonDetailLoadStatus = LessonDetailLoadStatus()

    private var nextButton: TKBlockButton!
    private var scheduleDate: Date!
    private var dataMap: [Int: TKLessonSchedule] = [:]
    private var materialsData: [Int: [TKMaterial]] = [:]

    private var countdownView: TKView = TKView.create()
        .corner(size: 30)
    private var countdownLabel: TKCountdownLabel = TKCountdownLabel()
    private var countdownImageView: UIImageView = UIImageView()

    private var studio: TKStudio?

    var memoString = "" {
        didSet {
            let index: Int
            switch data[selectedPos].lessonStatus {
            case .schedule:
                index = 3
            case .started:
                index = 6
            case .ended:
                index = 8
            }
            if let cell = tableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? LessonDetailsMemoTableViewCell {
                cell.memo = memoString
            }
        }
    }

    private var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 5
        return queue
    }()

    init(data: [TKLessonSchedule], selectedPos: Int) {
        self.data = data
        self.selectedPos = selectedPos
        super.init(nibName: nil, bundle: nil)
        setMemo()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dateFormatter.dateFormat = "MMM d"
        if selectedPos < data.count {
            let date = Date(seconds: data[selectedPos].getShouldDateTime())
            titleString = "\(date.toLocalFormat("EEE, MMM d"))"
        }
        navigationBar.titleLabel.text(titleString)
        topAvatarView.loadImageByOneLetter(userId: data[selectedPos].studentId, name: data[selectedPos].studentData?.name ?? "")
        guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appdelegate.isLessonPage = true
        checkClassNow()
        setMemo()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appdelegate.isLessonPage = false
    }

    override func onKeyboardShow(_ keyboardHeight: CGFloat) {
        super.onKeyboardShow(keyboardHeight)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80 + keyboardHeight, right: 0)
    }

    override func onKeyboardHide(_ keyboardHeight: CGFloat) {
        super.onKeyboardHide(keyboardHeight)
    }

    deinit {
        logger.debug("销毁 LessonsDetailViewController")
    }
}

// MARK: - View

extension LessonsDetailViewController {
    override func initView() {
        initNavigationBar()
        initTableView()

        topStepBarView = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
            .addTo(superView: view, withConstraints: { make in
                make.top.equalTo(navigationBar.snp.bottom)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
                make.height.equalTo(60)
            })

        topStepBar = TKStepBar()
        topStepBarView.addSubview(view: topStepBar) { make in
            make.center.equalToSuperview()
            make.width.equalTo((UIScreen.main.bounds.width * 0.9) - 40)
            make.height.equalTo(45)
        }
        topStepBar.set(text: ["Prep", "Lesson", "Recap"])
        topStepBarView.isHidden = true
        topStepBar.delegate = self
        nextButton = TKBlockButton(frame: CGRect.zero, title: "START LESSON")
        view.addSubview(view: nextButton) { make in
            make.width.equalTo(180)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
        nextButton.isHidden = true
        nextButton.onTapped { [weak self] _ in
            self?.clickNext()
        }
        initCountdownView()
    }

    private func initCountdownView() {
        view.addSubview(view: countdownView) { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-50)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-20)
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

    private func checkCountdownGuide() {
        let count: Int64 = SLCache.main.get(key: "tunekey:lessons:countdown_guide:showdCount")
        if count >= 3 {
            countdownImageView.isHidden = true
        } else {
            countdownImageView.isHidden = false
        }
    }

    private func initNavigationBar() {
        navigationBar = TKNormalNavigationBar(frame: .zero, title: titleString, rightButton: UIImage(named: "ic_more_primary")!, onRightButtonTapped: { [weak self] in
//            self?.toReschedule()'
            guard let self = self else { return }
            DispatchQueue.main.async {
                var actions: [TKPopAction.Item] = []
                let currentLesson = self.data[self.selectedPos]
                let d = Date()
                if d.timestamp < Int(currentLesson.getShouldDateTime()) {
                    actions = [
                        .init(title: "Student Balance", action: {
                            self.toCurrentLessonStudentsBalance()
                        }),
                        .init(title: "Reschedule", action: {
                            self.toReschedule()
                        }),
                        .init(title: "Cancel Lesson", action: {
                            self.showCancelLessonAlert()

                        }, tintColor: ColorUtil.red),
                    ]
                } else {
                    actions = [.init(title: "Student Balance", action: {
                        self.toCurrentLessonStudentsBalance()
                    })]
                }
                if currentLesson.rescheduled {
                    actions = [.init(title: "Student Balance", action: {
                        self.toCurrentLessonStudentsBalance()
                    })]
                }
                TKPopAction.show(items: actions, target: self)
            }
        })

        navigationBar.rightButton.isHidden = false
        view.addSubview(navigationBar)
        navigationBar.updateLayout(target: self)
        topAvatarView = TKAvatarView()
        topAvatarView.setRadius(11)
        view.addSubview(topAvatarView)
        topAvatarView.layer.opacity = 0
        view.addSubview(view: topAvatarView) { make in
            make.centerY.equalTo(navigationBar).offset(4)
            make.right.equalTo(-20)
            make.size.equalTo(22)
        }
    }

    private func showCancelLessonAlert() {
        let lessonSchedule: TKLessonSchedule = data[selectedPos]
        guard let config = lessonSchedule.lessonScheduleData else {
            return
        }
        if config.repeatType == .none {
            showCancelThisLessonAlert()
        } else {
            selectRescheduleType { [weak self] type in
                guard let self = self else { return }
                switch type {
                case .thisLesson:
                    self.showCancelThisLessonAlert()
                case .thisAndFollowingLessons, .allLessons:
                    self.showCancelMultipleLessonAlert(type: type, configId: config.id, selectedLessonSchedule: lessonSchedule)
                }
            }
        }
    }

    private func showCancelMultipleLessonAlert(type: TKRescheduleType, configId: String, selectedLessonSchedule: TKLessonSchedule) {
        let controller = SL.SLAlert()
        controller.modalPresentationStyle = .custom
        controller.titleString = "Cancel lesson?"
        controller.rightButtonColor = ColorUtil.main
        controller.leftButtonColor = ColorUtil.main
//        controller.rightButtonString = "GO BACK"
//        controller.leftButtonString = "CANCEL ANYWAYS"
        controller.rightButtonString = "I'm sure"
        controller.leftButtonString = "Go back"
        controller.rightButtonAction = {
            [weak self] in
            guard let self = self else { return }
            let mode: String
            switch type {
            case .allLessons:
                mode = ScheduleMode.all.rawValue
            case .thisAndFollowingLessons:
                mode = ScheduleMode.currentAndFollowing.rawValue
            default:
                return
            }
            self.showFullScreenLoadingNoAutoHide()
            Functions.functions().httpsCallable("scheduleService-cancelLesson")
                .call([
                    "scheduleMode": mode,
                    "lessonId": selectedLessonSchedule.id,
                ]) { _, error in
                    if let error = error {
                        logger.error("Cancel失败: \(error)")
                        TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                    } else {
                        self.dismiss(animated: true) {
                            TKToast.show(msg: TipMsg.cancellationSuccessful, style: .success)
                        }
                    }
                }
        }
        controller.leftButtonAction = {
        }
        controller.messageString = "We will remove your lesson from calendar if you confirm to cancel. Are you sure to cancel it?"
        controller.leftButtonFont = FontUtil.bold(size: 13)
        controller.rightButtonFont = FontUtil.bold(size: 13)
        present(controller, animated: false, completion: nil)
    }

    private func showCancelThisLessonAlert() {
        let controller = SL.SLAlert()
        controller.modalPresentationStyle = .custom
        controller.titleString = "Cancel lesson?"
        controller.rightButtonColor = ColorUtil.main
        controller.leftButtonColor = ColorUtil.main
        controller.leftButtonString = "GO BACK"
        controller.rightButtonString = "I'm sure"
        controller.rightButtonAction = {
            [weak self] in
            guard let self = self else { return }
            self.toCancelLesson()
        }
        controller.leftButtonAction = {
        }
        controller.messageString = "We will remove your lesson from calendar if you confirm to cancel. Are you sure to cancel it?"
        controller.leftButtonFont = FontUtil.bold(size: 13)
        controller.rightButtonFont = FontUtil.bold(size: 13)
        present(controller, animated: false, completion: nil)
    }

    private func toCurrentLessonStudentsBalance() {
        let currentLesson = data[selectedPos]
        let studentId = currentLesson.studentId
        showFullScreenLoadingNoAutoHide()
        UserService.student.getStudent(studentId: studentId)
            .done { [weak self] student in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                let controller = StudentDetailsBalanceViewController(student)
                controller.isStudentView = false
                controller.modalPresentationStyle = .fullScreen
                controller.hero.isEnabled = true
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                self.present(controller, animated: true, completion: nil)
            }
            .catch { [weak self] _ in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                TKToast.show(msg: TipMsg.connectionFailed, style: .error)
            }
    }

    private func initTableView() {
        tableView = UITableView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        tableView.delaysContentTouches = false
        tableView.backgroundColor = UIColor.white
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.tableHeaderView = UIView()
        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0

        tableView.register(LessonsDetailStudentsTableViewCell.self, forCellReuseIdentifier: String(describing: LessonsDetailStudentsTableViewCell.self))
        tableView.register(LessonsDetailLessonNotesTableViewCell.self, forCellReuseIdentifier: String(describing: LessonsDetailLessonNotesTableViewCell.self))
        tableView.register(LessonsDetailMaterialsTableViewCell.self, forCellReuseIdentifier: String(describing: LessonsDetailMaterialsTableViewCell.self))
        tableView.register(LessonsDetailAchievementTableViewCell.self, forCellReuseIdentifier: String(describing: LessonsDetailAchievementTableViewCell.self))
        tableView.register(LessonsDetailHomeworkTableViewCell.self, forCellReuseIdentifier: String(describing: LessonsDetailHomeworkTableViewCell.self))
        tableView.register(LessonDetailPracticeTableViewCell.self, forCellReuseIdentifier: String(describing: LessonDetailPracticeTableViewCell.self))
        tableView.register(LessonsDetailNextLessonPlanTableViewCell.self, forCellReuseIdentifier: String(describing: LessonsDetailNextLessonPlanTableViewCell.self))
        tableView.register(LessonDetailsMemoTableViewCell.self, forCellReuseIdentifier: LessonDetailsMemoTableViewCell.id)

//        let tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: TKScreen.width, height: 0))
//        tableFooterView.clipsToBounds = true
//        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 0, right: 20)) {
//            Label($memoString)
//                .textColor(ColorUtil.Font.primary)
//                .font(FontUtil.regular(size: 13))
//                .textAlignment(.center)
//                .numberOfLines(0)
//        }
//        .addTo(superView: tableFooterView) { make in
//            make.top.left.right.bottom.equalToSuperview()
//        }
//        tableFooterView.layer.opacity = 0
//        tableView.tableFooterView = tableFooterView
    }

    func getMaterialsHeight() -> CGFloat {
        var dataList = data[selectedPos].materilasData
        let folders = dataList.filter { $0.type == .folder }.compactMap { $0.id }
        dataList = dataList.filter { $0.folder == "" || ($0.folder != "" && !folders.contains($0.folder)) || $0.type == .folder }
        var height: CGFloat = 0
        var num = 0
        let screenWidth = UIScreen.main.bounds.width
        let width = (screenWidth - 50) / 3
        for item in dataList {
            if item.type == .youtube {
                height = height + 210 + 20
                num = 0
            } else {
                if num < 3 {
                    num = num + 1
                    if num == 1 {
                        height = height + width + 35 + 20
                    }
                } else {
                    num = 1
                    height = height + width + 35 + 20
                }
            }
        }
        return height + 80
    }
}

extension LessonsDetailViewController {
    // MARK: - data

    struct LessonDetailLoadStatus {
        var studentIsLoadFinsh: Bool = false
        var practiceIsLoadFinsh: Bool = false
        var lessonPlanIsLoadFinsh: Bool = false
        var notesLoadFinsh: Bool = false
        var materialsIsLoadFinsh: Bool = false
        var achivementLoadFinsh: Bool = false
        var assignmentIsLoadFinsh: Bool = false
        var nextLessonPlanIsLoadFinsh: Bool = false
        // 或者用用RXSwift 写个方法 方法里面有6个请求 每个完事之后走next等所有都结束走 com
        mutating func initStatus() {
            studentIsLoadFinsh = false
            practiceIsLoadFinsh = false
            lessonPlanIsLoadFinsh = false
            notesLoadFinsh = false
            materialsIsLoadFinsh = false
            achivementLoadFinsh = false
            assignmentIsLoadFinsh = false
            nextLessonPlanIsLoadFinsh = false
        }
    }

    override func initData() {
        EventBus.listen(EventBus.IS_SHOW_FULL_SCREEN_COUNTDOWN, target: self) { [weak self] _ in
            guard let self = self else { return }
            guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            //  guard !appdelegate.isShowFullScreenCuntdown else { return }
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
        EventBus.listen(EventBus.REFRESH_COUNTDOWN, target: self) { [weak self] _ in
            guard let self = self else { return }
            guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            self.checkClassNow()
            if appdelegate.isShowFullScreenCuntdown {
                self.countdownView.isHidden = true
                self.countdownImageView.isHidden = true
            }
        }
        data[selectedPos].lessonStatus = .schedule
        cellHeights = [253, 80, 80, 80, 80, 0, 0, 0, 0]
        tableView.reloadData()

        showFullScreenLoading()
        queue.addOperation { [weak self] in
            guard let self = self else { return }
            self.getLessonSchedule()
        }
        scheduleDate = TimeUtil.changeTime(time: data[selectedPos].shouldDateTime)
        let d = Date()
        if d.timestamp < Int(data[selectedPos].getShouldDateTime()) {
            navigationBar.rightButton.isHidden = false
        } else {
            navigationBar.rightButton.isHidden = false
        }
        if data[selectedPos].rescheduled {
            navigationBar.rightButton.isHidden = false
        }
        queue.addOperation { [weak self] in
            guard let self = self else { return }
            self.addSubscribe(
                UserService.studio.getInfo()
                    .subscribe(onNext: { [weak self] data in
                        guard let self = self else { return }
                        if let data = data[true] {
                            self.studio = data
                        }
                        if let data = data[false] {
                            self.studio = data
                        }
                        OperationQueue.main.addOperation {
                            self.tableView.reloadData()
                        }
                    })
            )
        }
    }

    func getData() {
        getPreAndNextData()
        getLessonPlan()
        initLessonMaterialsData()
        initLessonAchievement()
        initHomework()
    }

    private func refreshView() {
        print("===\(data[selectedPos].lessonStatus)===\(finishLoading)")
        switch data[selectedPos].lessonStatus {
        case .schedule:
            // 3
            if finishLoading.studentIsLoadFinsh
                && finishLoading.practiceIsLoadFinsh
                && finishLoading.lessonPlanIsLoadFinsh {
                tableView.reloadData()
            }
            break
        case .started:
            // 6
            if finishLoading.studentIsLoadFinsh
                && finishLoading.practiceIsLoadFinsh
                && finishLoading.lessonPlanIsLoadFinsh
                && finishLoading.notesLoadFinsh
                && finishLoading.materialsIsLoadFinsh
                && finishLoading.achivementLoadFinsh {
                tableView.reloadData()
            }
            break
        case .ended:
            // 8
            if finishLoading.studentIsLoadFinsh
                && finishLoading.practiceIsLoadFinsh
                && finishLoading.lessonPlanIsLoadFinsh
                && finishLoading.notesLoadFinsh
                && finishLoading.materialsIsLoadFinsh
                && finishLoading.achivementLoadFinsh
                && finishLoading.assignmentIsLoadFinsh
                && finishLoading.nextLessonPlanIsLoadFinsh {
                tableView.reloadData()
            }
            break
        }
    }

    /// 计算上节课和下节课的数据
    func getPreAndNextData() {
        if data[selectedPos].lessonScheduleData == nil {
            return
        }

//        SL.Executor.runAsync { [weak self] in
//            guard let self = self else { return }
//            let preAndNextData = ScheduleUtil.getPreAndNextLesson(currentDate: TimeUtil.changeTime(time: self.data[self.selectedPos].shouldDateTime), lessonScheduleConfigure: self.data[self.selectedPos].lessonScheduleData, lessonType: self.data[self.selectedPos].lessonTypeData!)
//            if preAndNextData.nextSchedule != nil {
//                self.initPreAndNextData(isPre: false, preAndNextData: preAndNextData)
//            }
//            if preAndNextData.preScheudle != nil {
//                self.initPreAndNextData(isPre: true, preAndNextData: preAndNextData)
//            }
//        }
        var preAndNextData: (preScheudle: TKLessonSchedule?, nextSchedule: TKLessonSchedule?) = (preScheudle: nil, nextSchedule: nil)
        SL.Executor.runAsync { [weak self] in
            guard let self = self else { return }
            LessonService.lessonSchedule.getNextLessonNew(targetTime: Int(self.data[self.selectedPos].shouldDateTime), teacherId: self.data[self.selectedPos].teacherId, studentId: self.data[self.selectedPos].studentId) { [weak self] isS, docs in
                guard let self = self else { return }
                if isS {
                    if let docs = docs {
                        var data: TKLessonSchedule!
                        for doc in docs.documents {
                            if let doc = TKLessonSchedule.deserialize(from: doc.data()) {
                                data = doc
                            }
                        }
                        if data != nil {
                            preAndNextData.nextSchedule = data
                            print("=====下节课ID=\(data.id)")

                            self.initPreAndNextData(isPre: false, preAndNextData: preAndNextData)
                        }
                    }
                } else {
                }
            }
        }
        SL.Executor.runAsync { [weak self] in
            guard let self = self else { return }
            LessonService.lessonSchedule.getPreviousLessonNew(targetTime: Int(self.data[self.selectedPos].shouldDateTime), teacherId: self.data[self.selectedPos].teacherId, studentId: self.data[self.selectedPos].studentId) { [weak self] isS, docs in
                guard let self = self else { return }
                if isS {
                    if let docs = docs {
                        var data: TKLessonSchedule!
                        for doc in docs.documents {
                            if let doc = TKLessonSchedule.deserialize(from: doc.data()) {
                                data = doc
                            }
                        }
                        if data != nil {
                            preAndNextData.preScheudle = data
                            self.initPreAndNextData(isPre: true, preAndNextData: preAndNextData)
                        } else {
                            self.tableView.reloadData()
                        }
                    }
                } else {
                }
//                self.refreshView()
            }
        }

//        addSubscribe(
//            LessonService.lessonSchedule.getPreviousLessonNew(targetTime: Int(data[selectedPos].shouldDateTime), teacherId: data[selectedPos].teacherId, studentId: data[selectedPos].studentId)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
//                    var data: TKLessonSchedule!
//                    for doc in docs.documents {
//                        if let doc = TKLessonSchedule.deserialize(from: doc.data()) {
//                            data = doc
//                        }
//                    }
//                    if data != nil {
//                        preAndNextData.preScheudle = data
//                        print("=====上节课ID=\(data.id)")
//
//                        self.initPreAndNextData(isPre: true, preAndNextData: preAndNextData)
//                    }
//
//                }, onError: { err in
//                    logger.debug("获取失败:\(err)")
//                })
//        )
    }

    /// 根据上节课和下节课的ID获取课程
    func initPreAndNextData(isPre: Bool, preAndNextData: (preScheudle: TKLessonSchedule?, nextSchedule: TKLessonSchedule?)) {
        var id: String!
        if isPre {
            id = preAndNextData.preScheudle!.id
        } else {
            id = preAndNextData.nextSchedule!.id
        }
        addSubscribe(
            LessonService.lessonSchedule.getLessonScheduleById(id: id)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if data.from == .server {
                        if let doc = data.data() {
                            if let data = TKLessonSchedule.deserialize(from: doc) {
                                if isPre {
                                    self.data[self.selectedPos].preAndNextData.preScheudle = data
                                    self.getPreLessonPractice()
                                } else {
                                    self.data[self.selectedPos].preAndNextData.nextSchedule = data
                                    print("===下节课的数据==\(data.toJSONString(prettyPrint: true) ?? "")")
                                    self.getNextLessonPlan()
                                }
                            }
                        }
                    }
                }, onError: { err in
                    logger.debug("get lesson sechedule by id error: \(err)")
//                    self.finishLoading.nextLessonPlanIsLoadFinsh = true
//                    self.refreshView()
//                    self.finishLoading.practiceIsLoadFinsh = true
//                    self.refreshView()
                })
        )
    }

    func getPreLessonPractice() {
        addSubscribe(
            LessonService.lessonSchedule.getPracticeByStartTimeAndSId(startTime: data[selectedPos].preAndNextData.preScheudle!.shouldDateTime, endTime: data[selectedPos].shouldDateTime, studentId: data[selectedPos].studentId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    self.data[self.selectedPos].isHavePreLesson = true
//                    if let data = data[.cache] {
//                        if data.count != 0 {
//                            isLoad = true
//                            self.data[self.selectedPos].preAssignmentData = data
                    ////                            self.finishLoading.practiceIsLoadFinsh = true
                    ////                            self.refreshView()
                    ////                            let index = IndexPath(row: 1, section: 0)
//                            print("getPreLessonPractice1lessonType:\(self.data[self.selectedPos].lessonStatus)")
//                            self.tableView.reloadData()
//                        }
//                    }
                    if let data = data[.server] {
                        self.data[self.selectedPos].preAssignmentData = data
                        logger.debug("getPreLessonPractice2lessonType:\(self.data[self.selectedPos].lessonStatus)")
                        self.tableView.reloadData()
                    }
                }, onError: { err in
                    logger.debug("======\(err)")
//                    self.finishLoading.practiceIsLoadFinsh = true
//                    self.refreshView()
                })
        )
    }

    func getNextLessonPlan() {
        addSubscribe(
            LessonService.lessonSchedule
                .getLessonPlans(lessonScheduleId: data[selectedPos].preAndNextData.nextSchedule!.id)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    self.data[self.selectedPos].isHaveNextLesson = true
                    if let data = data[.server] {
                        self.data[self.selectedPos].nextLessonPlan = data
                        if self.data[self.selectedPos].lessonStatus == .ended {
                            let index = IndexPath(row: 7, section: 0)
                            self.tableView.reloadData()
                        }
                    }
                    if let data = data[.cache] {
                        logger.debug("获取到的下节课的Lesosn plan\(data.toJSONString(prettyPrint: true) ?? "")")
                        self.data[self.selectedPos].nextLessonPlan = data
                        if self.data[self.selectedPos].lessonStatus == .ended {
                            let index = IndexPath(row: 7, section: 0)
                            self.tableView.reloadData()
                        }
                    }
                }, onError: { err in
                    logger.debug("======获取LessonPlan失败:\(err)")
//                    self.finishLoading.nextLessonPlanIsLoadFinsh = true
//                    self.refreshView()
                })
        )
    }

    func initHomework() {
        logger.debug("开始获取作业数据: \(data[selectedPos].id)")
        addSubscribe(
            LessonService.lessonSchedule.getPracticeByScheduleId(sId: data[selectedPos].id)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache] {
                        if data.count != 0 {
                            self.data[self.selectedPos].allPracticeData = data
//                            self.data[self.selectedPos].practiceData = data.filter({ $0.assignment })
//                            self.data[self.selectedPos].practiceData = data.filter({ d -> Bool in
//                                d.startTime == d.shouldDateTime
//                            })
                            self.data[self.selectedPos].practiceData = data.filter({ $0.assignment })
                                .filter({ $0.startTime == $0.shouldDateTime })
                            self.tableView.reloadData()
                        }
                    }
                    if let data = data[.server] {
                        self.data[self.selectedPos].allPracticeData = data
//                        self.data[self.selectedPos].practiceData = data.filter({ $0.assignment })
//                        self.data[self.selectedPos].practiceData = data.filter({ d -> Bool in
//                            d.startTime == d.shouldDateTime
//                        })
                        self.data[self.selectedPos].practiceData = data.filter({ $0.assignment })
                            .filter({ $0.startTime == $0.shouldDateTime })

                        self.tableView.reloadData()
                    }
//                    self.refreshView()
                }, onError: { err in
                    logger.debug("======\(err)")
//                    self.finishLoading.assignmentIsLoadFinsh = true
//                    self.refreshView()
                })
        )
    }

    func initLessonAchievement() {
        if data[selectedPos].lessonStatus == .schedule {
            return
        }
        addSubscribe(
            LessonService.lessonSchedule.getAchievementByScheduleId(sId: data[selectedPos].id)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache] {
                        if data.count != 0 {
                            self.data[self.selectedPos].achievement = data
                            if self.data[self.selectedPos].lessonStatus != .schedule {
                                self.tableView.reloadData()
                            }
                        }
                    }
                    if let data = data[.server] {
                        self.data[self.selectedPos].achievement = data

                        if self.data[self.selectedPos].lessonStatus != .schedule {
                            self.tableView.reloadData()
                        }
                    }
                }, onError: { _ in
                    logger.error("====获取Achievement失败")
//                    self.finishLoading.achivementLoadFinsh = true
//                    self.refreshView()
                })
        )
    }

    /// 获取MaterialsData
    func initLessonMaterialsData() {
        if let material = materialsData[selectedPos] {
            data[selectedPos].materilasData = material
            SL.Executor.runAsyncAfter(time: 0.5) { [weak self] in
                guard let self = self else { return }
                if self.data[self.selectedPos].lessonStatus == .schedule {
                    return
                }
                self.cellHeights[4] = self.getMaterialsHeight()
                self.tableView.reloadData()
//                self.finishLoading.materialsIsLoadFinsh = true
//                self.refreshView()
            }
//
            return
        }
        if data[selectedPos].lessonStatus == .schedule {
            return
        }
        addSubscribe(
            LessonService.lessonSchedule.getLessonScheduleMaterialByScheduleId(id: data[selectedPos].id)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache] {
                        let data = data.filterDuplicates({ $0.materialId })
                        self.data[self.selectedPos].lessonScheduleMaterials = data
                        self.initMaterialsData(lessonMaterials: data)
                    }
                    if let data = data[.server] {
                        let data = data.filterDuplicates({ $0.materialId })
                        self.data[self.selectedPos].lessonScheduleMaterials = data
                        self.initMaterialsData(lessonMaterials: data)
                    }
                    print("=获取到的啊哈哈哈======\(self.data[self.selectedPos].lessonScheduleMaterials.toJSONString(prettyPrint: true) ?? "")")
                }, onError: { err in
                    logger.debug("======\(err)")
                    //                    self.finishLoading.materialsIsLoadFinsh = true
                    //                    self.refreshView()
                })
        )
//        if data[self.selectedPos].lessonStatus == .schedule {
//            return
//        }
    }

    func initMaterialsData(lessonMaterials: [TKLessonScheduleMaterial]) {
        if data[selectedPos].lessonStatus == .schedule {
            return
        }
        if lessonMaterials.count == 0 {
            data[selectedPos].materilasData = []
            cellHeights[4] = 80
            tableView.reloadData()
            //        finishLoading.materialsIsLoadFinsh = true
            //        refreshView()
            return
        }
        addSubscribe(
            MaterialService.shared.materialListByTeacher(tId: data[selectedPos].teacherId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var webData: [TKMaterial] = []
                    for item in docs.documents {
                        if let doc = TKMaterial.deserialize(from: item.data()) {
                            webData.append(doc)
                        }
                    }
                    if self.data[self.selectedPos].lessonStatus != .schedule {
                        var data: [TKMaterial] = []
                        for item in lessonMaterials {
                            if webData.contains(where: { d -> Bool in
                                let isHave = d.id == item.materialId
                                if isHave {
                                    data.append(d)
                                }
                                return isHave
                            }) {
                            }
                        }

                        self.data[self.selectedPos].materilasData = data
                        self.cellHeights[4] = self.getMaterialsHeight()
                        self.tableView.reloadData()
                        self.materialsData[self.selectedPos] = data
                    }

                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    /// 初始化lessonStatus 和 底部Button 显示的样式
    func initLessonStatus() {
        guard !data.isEmpty else { return }
        if selectedPos >= data.count {
            selectedPos = 0
        }
        let time = Date().timestamp
        let shouldEndTime = Int(data[selectedPos].getShouldDateTime()) + (data[selectedPos].shouldTimeLength * 60)
        if data[selectedPos].lessonStatus == .schedule {
            if time >= Int(data[selectedPos].getShouldDateTime()) && time < shouldEndTime && data[selectedPos].lessonStatus != .started {
                data[selectedPos].lessonStatus = .started
            }
        }

        if time >= shouldEndTime && data[selectedPos].lessonStatus != .ended {
            data[selectedPos].lessonStatus = .ended
        }
//        finishLoading.initStatus()
//        finishLoading.studentIsLoadFinsh = true
//        finishLoading.nextLessonPlanIsLoadFinsh = true
//        refreshView()
        print("dddd:\(data[selectedPos].lessonStatus)")
        tableView.reloadData()

        getData()

        if data[selectedPos].lessonStatus == .schedule {
//            if data[selectedPos].lessonPlan.count > 0 {
//                nextButton.isHidden = false
//            } else {
//                nextButton.isHidden = true
//            }
            nextButton.isHidden = false
            topStepBar.update(index: 0)
        } else if data[selectedPos].lessonStatus == .started {
            nextButton.isHidden = false
            nextButton.setTitle(title: "FINISH CLASS")
            topStepBar.update(index: 1)
        } else {
            nextButton.isHidden = true
            topStepBar.update(index: 2)
        }
        dataMap[selectedPos] = data[selectedPos]
        let d = Date()
        if d.timestamp < Int(data[selectedPos].getShouldDateTime()) {
            navigationBar.rightButton.isHidden = false
        } else {
            navigationBar.rightButton.isHidden = false
        }
        if data[selectedPos].rescheduled {
            navigationBar.rightButton.isHidden = false
        }
        topAvatarView.loadImageByOneLetter(userId: data[selectedPos].studentId, name: data[selectedPos].studentData?.name ?? "")
        topAvatarView.layer.opacity = 0
        dateFormatter.dateFormat = "MMM d"
        titleString = dateFormatter.string(from: TimeUtil.changeTime(time: Double(data[selectedPos].getShouldDateTime())))
//        data[self.selectedPos].materilasData = []
//        cellHeights[4] = getMaterialsHeight()
    }

    /// 获取当前天你的日程
    func getLessonSchedule() {
        var ids: [String] = []
        for item in data {
            ids.append(item.id)
        }

        addSubscribe(
            LessonService.lessonSchedule.getLessonScheduleByIds(ids: ids)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if let data = data[.cache] {
                        for item in self.data.enumerated() {
                            for newItem in data where newItem.id == item.element.id {
                                self.data[item.offset].refreshData(newData: newItem)
                                self.dataMap[self.selectedPos] = self.data[item.offset]
                            }
                        }
                        self.initLessonStatus()
                    }
                    if let data = data[.server] {
                        for item in self.data.enumerated() {
                            for newItem in data where newItem.id == item.element.id {
                                self.data[item.offset].refreshData(newData: newItem)
                                self.dataMap[self.selectedPos] = self.data[item.offset]
                            }
                        }
                        self.initLessonStatus()
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    self.initLessonStatus()
                    logger.debug("======获取lessonschedule失败:\(err)")
                })
        )
    }

    /// 获取LessonPlan
    func getLessonPlan() {
        addSubscribe(
            LessonService.lessonSchedule
                .getLessonPlans(lessonScheduleId: data[selectedPos].id)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.server] {
                        self.data[self.selectedPos].lessonPlan = data
                        let index = IndexPath(row: 2, section: 0)
                        print("2lessonType:\(self.data[self.selectedPos].lessonStatus)")
                        self.tableView.reloadData()
                    }
                    if let data = data[.cache] {
                        self.data[self.selectedPos].lessonPlan = data
                        let index = IndexPath(row: 2, section: 0)
                        print("2lessonType:\(self.data[self.selectedPos].lessonStatus)")
                        self.tableView.reloadData()
                    }
                }, onError: { err in
                    logger.debug("======获取LessonPlan失败:\(err)")
//                    self.finishLoading.lessonPlanIsLoadFinsh = true
//                    self.refreshView()
                })
        )
    }

    /// 更新lessonSchedul
    /// - Parameter data: 要更新的数据
    func updateLessonschedule(data: [String: Any]) {
        let id = self.data[selectedPos].id
        addSubscribe(
            LessonService.lessonSchedule
                .updateLessonSchedule(lessonScheduleId: id, data: data)
                .subscribe(onNext: { _ in
                }, onError: { err in
                    logger.debug("====更新Schedule失败=\(err)")
                })
        )
    }
}

extension LessonsDetailViewController: TKStepBarDelegate {
    func clickTKStepBar(isDone: Bool, index: Int) {
        print("===\(isDone)====\(index)")
        if isDone {
            if index == 0 {
                if data[selectedPos].lessonStatus != .schedule {
                    tableView.contentOffset.y = 171

                } else {
                    tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                }

            } else if index == 1 {
                tableView.scrollToRow(at: IndexPath(row: 3, section: 0), at: .middle, animated: true)
            } else if index == 2 {
                tableView.scrollToRow(at: IndexPath(row: 6, section: 0), at: .top, animated: true)
            }
        }
    }

    // MARK: - Action

    func clickNext() {
        switch data[selectedPos].lessonStatus {
        case .schedule:
            data[selectedPos].lessonStatus = .started
            nextButton.setTitle(title: "FINISH CLASS")
            topStepBar.update(index: 1)
            updateLessonschedule(data: ["lessonStatus": 1])
            break
        case .started:
            data[selectedPos].lessonStatus = .ended
            nextButton.isHidden = true
            topStepBar.update(index: 2)
            updateLessonschedule(data: ["lessonStatus": 2])
            break
        case .ended:
            break
        }
        tableView.reloadData()
    }

    func toCancelLesson() {
        let lesson = data[selectedPos]
        guard !lesson.cancelled else {
            TKToast.show(msg: "This lesson has been cancelled before!", style: .warning)
            return
        }

        guard !lesson.rescheduled else {
            TKToast.show(msg: "This lesson has been rescheduled before!", style: .warning)
            return
        }
        showFullScreenLoading()
        Functions.functions().httpsCallable("scheduleService-cancelLesson")
            .call([
                "lessonId": lesson.id,
                "scheduleMode": ScheduleMode.current.rawValue,
            ]) { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("取消失败: \(error)")
                    TKToast.show(msg: "Cancellation failed, please try again later.", style: .error)
                } else {
                    self.data.removeElements { $0.id == lesson.id }
                    logger.debug("[老师取消课程] => 删除完之后,剩余课程: \(self.data.toJSONString() ?? "")")
                    EventBus.send(EventBus.CHANGE_SCHEDULE)
                    if self.data.count == 0 {
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        self.selectedPos = 0
                        self.topAvatarView.loadImageByOneLetter(userId: self.data[self.selectedPos].studentId, name: self.data[self.selectedPos].studentData?.name ?? "")
                        self.tableView.reloadData()
                    }
                }
            }

//        let cancellationData = TKLessonCancellation()
//        let time = "\(Date().timestamp)"
//        cancellationData.id = lesson.id
//        cancellationData.oldScheduleId = lesson.id
//        cancellationData.type = .noRefundAndMakeup
//        cancellationData.studentId = lesson.studentId
//        cancellationData.teacherId = lesson.teacherId
//        cancellationData.timeBefore = lesson.shouldDateTime.description
//        cancellationData.createTime = time
//        cancellationData.updateTime = time
//        LessonService.lessonSchedule.cancelScheduleFromTeacher(data: cancellationData)
//            .done { [weak self] _ in
//                guard let self = self else { return }
//                DispatchQueue.main.async {
//                    self.hideFullScreenLoading()
//                    logger.debug("[老师取消课程] => 完成,开始检查剩余课程,当前未删除的课程: \(self.data.toJSONString() ?? "")")
//                    self.data.removeElements { $0.id == lesson.id }
//                    logger.debug("[老师取消课程] => 删除完之后,剩余课程: \(self.data.toJSONString() ?? "")")
//                    EventBus.send(EventBus.CHANGE_SCHEDULE)
//                    if self.data.count == 0 {
//                        self.dismiss(animated: true, completion: nil)
//                    } else {
//                        self.selectedPos = 0
//                        self.topAvatarView.loadImageByOneLetter(userId: self.data[self.selectedPos].studentId, name: self.data[self.selectedPos].studentData?.name ?? "")
//                        self.tableView.reloadData()
//                    }
//                }
//            }
//            .catch { _ in
//                TKToast.show(msg: "Cancellation failed, please try again!", style: .error)
//                self.hideFullScreenLoading()
//            }
    }

    func toReschedule() {
        let lessonSchedule: TKLessonSchedule = data[selectedPos]
        guard let config = lessonSchedule.lessonScheduleData else {
            return
        }

        logger.debug("当前课程的config: \(config.toJSONString() ?? "")")
        if config.repeatType == .none {
            var rescheduleData: [TKLessonSchedule] = []
            var index = 0
            for item in data.enumerated() where !item.element.cancelled && !item.element.rescheduled && Date().timestamp <
                Int(item.element.getShouldDateTime()) && item.element.studentData != nil {
                if item.element.id == data[selectedPos].id {
                    index = item.offset
                }
                rescheduleData.append(item.element.copy())
            }
            for item in rescheduleData.enumerated() where data[index].id == item.element.id {
                index = item.offset
                continue
            }
            if rescheduleData.count == 0 {
                return
            }

            let controller = TRecheduleController(.reschedule)
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.data = rescheduleData
            controller.defualSelectIndex = index
            controller.enablePanToDismiss()
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            present(controller, animated: true, completion: nil)
        } else {
            selectRescheduleType { [weak self] rescheduleType in
                guard let self = self else { return }
                switch rescheduleType {
                case .thisLesson:
                    var rescheduleData: [TKLessonSchedule] = []
                    var index = 0
                    for item in self.data.enumerated() where !item.element.cancelled && !item.element.rescheduled && Date().timestamp <
                        Int(item.element.getShouldDateTime()) && item.element.studentData != nil {
                        if item.element.id == self.data[self.selectedPos].id {
                            index = item.offset
                        }
                        rescheduleData.append(item.element.copy())
                    }
                    for item in rescheduleData.enumerated() where self.data[index].id == item.element.id {
                        index = item.offset
                        continue
                    }
                    if rescheduleData.count == 0 {
                        return
                    }

                    let controller = TRecheduleController(.reschedule)
                    controller.modalPresentationStyle = .fullScreen
                    controller.hero.isEnabled = true
                    controller.data = rescheduleData
                    controller.defualSelectIndex = index
                    controller.enablePanToDismiss()
                    controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                    self.present(controller, animated: true, completion: nil)
                case .thisAndFollowingLessons, .allLessons:
                    // 获取当前课程的config
                    let newConfig = TKLessonScheduleConfigure()
                    newConfig.id = IDUtil.nextId(group: .lesson)?.description ?? ""
                    newConfig.teacherId = config.teacherId
                    newConfig.studentId = config.studentId
                    newConfig.lessonTypeId = config.lessonTypeId
                    newConfig.startDateTime = lessonSchedule.shouldDateTime
                    newConfig.repeatType = config.repeatType
                    newConfig.repeatTypeWeekDay = config.repeatTypeWeekDay
                    newConfig.repeatTypeMonthDayType = config.repeatTypeMonthDayType
                    newConfig.repeatTypeMonthDay = config.repeatTypeMonthDay
                    newConfig.endType = config.endType
                    newConfig.endDate = config.endDate
                    newConfig.endCount = config.endCount
                    newConfig.specialPrice = config.specialPrice
                    newConfig.createTime = ""
                    newConfig.updateTime = ""
                    newConfig.studentLocalData = config.studentLocalData
                    newConfig.studentData = config.studentData
                    newConfig.lessonType = config.lessonType
                    newConfig.delete = false
                    newConfig.rrule = ""
                    newConfig.memo = config.memo

                    let controller = LessonDetailRescheduleForLessonsPopupViewController(newConfig, oldConfig: config, selectedLessonScheduleId: lessonSchedule.id)
                    controller.rescheduleType = rescheduleType
                    controller.modalPresentationStyle = .custom
                    self.present(controller, animated: false)
                    break
                }
            }
        }
    }

    private func selectRescheduleType(completion: @escaping (TKRescheduleType) -> Void) {
        TKPopAction.show(
            items: [
                .init(title: "This lesson", action: {
                    completion(.thisLesson)
                }),
                .init(title: "This & following lessons", action: {
                    completion(.thisAndFollowingLessons)
                }),
                .item(title: "All lessons", action: {
                    completion(.allLessons)
                }),
            ],
            target: self)
    }
}

extension LessonsDetailViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: -  TableView

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        logger.debug("offsetY:\(offsetY)")
        if ListenerService.shared.currentRole == .studioManager {
            topStepBarView.isHidden = offsetY < 180
        } else {
            topStepBarView.isHidden = offsetY < 170
        }
        let date = Date(seconds: data[selectedPos].getShouldDateTime())
        if offsetY > 170 {
            titleString = "\(date.toLocalFormat("MMM d, h:mm a"))"
        } else {
            titleString = "\(date.toLocalFormat("EEE, MMM d"))"
        }
        navigationBar.titleLabel.text(titleString)
        var alpha: Float = 1
        if offsetY <= 150 {
            alpha = Float(offsetY) / 150
        }
        if !data[selectedPos].rescheduled && data[selectedPos].getShouldDateTime() > Double(Date().timestamp) {
            if alpha == 0 {
                navigationBar.showRightButton()
            } else {
                navigationBar.hiddenRightButton()
            }
        }
        topAvatarView.layer.opacity = alpha
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if data.count != 0 {
            switch data[selectedPos].lessonStatus {
            case .schedule:
                return 4
            case .started:
                return 7
            case .ended:
                return 9
            }
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch data[selectedPos].lessonStatus {
        case .schedule:
            return initPrepCell(tableView: tableView, indexPath: indexPath)
        case .started:
            return initLessonCell(tableView: tableView, indexPath: indexPath)
        case .ended:
            return initRecapCell(tableView: tableView, indexPath: indexPath)
        }
    }

    // MARK: - initPrepCell

    func initPrepCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailStudentsTableViewCell.self), for: indexPath) as! LessonsDetailStudentsTableViewCell
            cell.delegate = self
            cell.loadData(data: data, selectedPos: selectedPos)
            cellStepBar = cell.stepBar
            if let stepBar = cellStepBar {
                stepBar.delegate = self
            }
            cellHeights[indexPath.row] = cell.cellHeight
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonDetailPracticeTableViewCell.self), for: indexPath) as! LessonDetailPracticeTableViewCell
            cell.delegate = self
            cell.initData(data: data[selectedPos].preAssignmentData)
            cellHeights[indexPath.row] = cell.cellHeight
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailNextLessonPlanTableViewCell.self), for: indexPath) as! LessonsDetailNextLessonPlanTableViewCell
            cell.isNext = false
            cell.delegate = self
            cell.tag = indexPath.row
            cell.loadData(data: data[selectedPos].lessonPlan, style: -1, sId: data[selectedPos].id)
            cellHeights[indexPath.row] = cell.cellHeight
            if data[selectedPos].teacherId == (ListenerService.shared.user?.userId ?? "") {
                cell.addButton?.isHidden = false
            } else {
                cell.addButton?.isHidden = true
            }
            return cell
//        case 3:
//            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailNextLessonPlanTableViewCell.self), for: indexPath) as! LessonsDetailNextLessonPlanTableViewCell
//            cell.isNext = false
//            cell.delegate = self
//            cell.tag = indexPath.row
//
//            cell.loadData(data: data[selectedPos].lessonPlan, style: 0, sId: data[selectedPos].id)
//            cellHeights[indexPath.row] = cell.cellHeight
//            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: LessonDetailsMemoTableViewCell.id, for: indexPath) as! LessonDetailsMemoTableViewCell
            cell.delegate = self
            cell.setMemo(memoString, attendance: data[selectedPos].attendance)
            // 判断当前课程是否开始
            let start = data[selectedPos].shouldDateTime
            let now = Date().timeIntervalSince1970
            if now >= start && !data[selectedPos].rescheduled && data[selectedPos].rescheduleId == "" {
                cell.isRecordAttendanceHidden = false
            } else {
                cell.isRecordAttendanceHidden = true
            }
            cellHeights[indexPath.row] = cell.cellHeight
            cell.onRecordAttendanceTapped = { [weak self] in
                self?.onRecordAttendanceTapped()
            }
            return cell
        default:
            fatalError("Wrong index")
        }
    }

    // MARK: - initLessonCell

    func initLessonCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailStudentsTableViewCell.self), for: indexPath) as! LessonsDetailStudentsTableViewCell
            cell.delegate = self
            cell.loadData(data: data, selectedPos: selectedPos)
            cellStepBar = cell.stepBar
            if let stepBar = cellStepBar {
                stepBar.delegate = self
            }
            cellHeights[indexPath.row] = cell.cellHeight
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonDetailPracticeTableViewCell.self), for: indexPath) as! LessonDetailPracticeTableViewCell
            cell.delegate = self
            cell.initData(data: data[selectedPos].preAssignmentData)

            cellHeights[indexPath.row] = cell.cellHeight
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailNextLessonPlanTableViewCell.self), for: indexPath) as! LessonsDetailNextLessonPlanTableViewCell
            cell.isNext = false
            cell.delegate = self
            cell.tag = indexPath.row
            cell.loadData(data: data[selectedPos].lessonPlan, style: 0, sId: data[selectedPos].id)
            cellHeights[indexPath.row] = cell.cellHeight
            if data[selectedPos].teacherId == (ListenerService.shared.user?.userId ?? "") {
                cell.addButton?.isHidden = false
            } else {
                cell.addButton?.isHidden = true
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailLessonNotesTableViewCell.self), for: indexPath) as! LessonsDetailLessonNotesTableViewCell
            cell.delegate = self
            cell.loadData(data: data[selectedPos], studio: studio)
            cellHeights[indexPath.row] = cell.cellHeight
            if data[selectedPos].teacherId == (ListenerService.shared.user?.userId ?? "") {
                cell.addButton?.isHidden = false
            } else {
                cell.addButton?.isHidden = true
            }
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailMaterialsTableViewCell.self), for: indexPath) as! LessonsDetailMaterialsTableViewCell
            cell.loadData(data: data[selectedPos].materilasData, height: cellHeights[indexPath.row])
            cell.delegate = self
            if data[selectedPos].teacherId == (ListenerService.shared.user?.userId ?? "") {
                cell.addButton?.isHidden = false
            } else {
                cell.addButton?.isHidden = true
            }
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailHomeworkTableViewCell.self), for: indexPath) as! LessonsDetailHomeworkTableViewCell
            cell.delegate = self

            var showCopyButton: Bool = false
            let assignmentData = data[selectedPos].preAssignmentData.filter({ $0.assignment })
            let practiceData = data[selectedPos].practiceData
            if practiceData.isEmpty {
                if !assignmentData.isEmpty {
                    showCopyButton = true
                }
            }
            logger.debug("刷新作业cell: \(showCopyButton) | \(assignmentData.count) | \(practiceData.count)")
            logger.debug("现在的作业: \(practiceData.toJSONString() ?? "")")
            cell.loadData(data: practiceData, sId: data[selectedPos].id, showCopyButton: showCopyButton)
            cellHeights[indexPath.row] = cell.cellHeight
            cell.copyFromLastLessonButton.onTapped { [weak self] _ in
                guard let self = self else { return }
                let lessonData = self.data[self.selectedPos]
                let list = assignmentData
                list.forEachItems { _, index in
                    list[index].id = IDUtil.nextId(group: .lesson)?.description ?? ""
                    list[index].lessonScheduleId = lessonData.id
                    list[index].createTime = Date().timeIntervalSince1970.description
                    list[index].updateTime = Date().timeIntervalSince1970.description
                    list[index].done = false
                    list[index].studentId = self.data[self.selectedPos].studentId
                    list[index].teacherId = self.data[self.selectedPos].teacherId
                    list[index].startTime = self.data[self.selectedPos].shouldDateTime
                    list[index].scheduleConfigId = self.data[self.selectedPos].lessonScheduleConfigId
                    list[index].assignment = true
                    list[index].shouldDateTime = self.data[self.selectedPos].shouldDateTime
                    list[index].totalTimeLength = 0
                }
                self.data[self.selectedPos].practiceData = list.filterDuplicates({ $0.name.trimmingCharacters(in: .whitespacesAndNewlines) })
                self.showFullScreenLoadingNoAutoHide()
                self.saveAssignment()
                self.tableView.reloadData()
            }
            if data[selectedPos].teacherId == (ListenerService.shared.user?.userId ?? "") {
                cell.addButton?.isHidden = false
            } else {
                cell.addButton?.isHidden = true
            }
            return cell
        case 6:
            let cell = tableView.dequeueReusableCell(withIdentifier: LessonDetailsMemoTableViewCell.id, for: indexPath) as! LessonDetailsMemoTableViewCell
            cell.delegate = self
            // 判断当前课程是否开始
            let start = data[selectedPos].shouldDateTime
            let now = Date().timeIntervalSince1970
            if now >= start && !data[selectedPos].rescheduled && data[selectedPos].rescheduleId == "" {
                cell.isRecordAttendanceHidden = false
            } else {
                cell.isRecordAttendanceHidden = true
            }
            cell.setMemo(memoString, attendance: data[selectedPos].attendance)
            cellHeights[indexPath.row] = cell.cellHeight
            cell.onRecordAttendanceTapped = { [weak self] in
                self?.onRecordAttendanceTapped()
            }
            return cell
        default:
            fatalError("Wrong index")
        }
    }

    // MARK: - initRecapCell

    func initRecapCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailStudentsTableViewCell.self), for: indexPath) as! LessonsDetailStudentsTableViewCell
            cell.delegate = self
            cell.loadData(data: data, selectedPos: selectedPos)
            cellStepBar = cell.stepBar
            if let stepBar = cellStepBar {
                stepBar.delegate = self
            }
            cellHeights[indexPath.row] = cell.cellHeight
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonDetailPracticeTableViewCell.self), for: indexPath) as! LessonDetailPracticeTableViewCell
            cell.delegate = self
            cell.initData(data: data[selectedPos].preAssignmentData)

            cellHeights[indexPath.row] = cell.cellHeight
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailNextLessonPlanTableViewCell.self), for: indexPath) as! LessonsDetailNextLessonPlanTableViewCell
            cell.isNext = false
            cell.delegate = self
            cell.tag = indexPath.row
            cell.loadData(data: data[selectedPos].lessonPlan, style: 0, sId: data[selectedPos].id)
            cellHeights[indexPath.row] = cell.cellHeight
            if data[selectedPos].teacherId == (ListenerService.shared.user?.userId ?? "") {
                cell.addButton?.isHidden = false
            } else {
                cell.addButton?.isHidden = true
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailLessonNotesTableViewCell.self), for: indexPath) as! LessonsDetailLessonNotesTableViewCell
            cell.delegate = self
            cell.loadData(data: data[selectedPos], studio: studio)
            cellHeights[indexPath.row] = cell.cellHeight
            if data[selectedPos].teacherId == (ListenerService.shared.user?.userId ?? "") {
                cell.addButton?.isHidden = false
            } else {
                cell.addButton?.isHidden = true
            }
            return cell
        case 4:

            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailMaterialsTableViewCell.self), for: indexPath) as! LessonsDetailMaterialsTableViewCell
            cell.loadData(data: data[selectedPos].materilasData, height: cellHeights[indexPath.row])
            cell.delegate = self
//            cellHeights[indexPath.row] = cell.cellHeight
            if data[selectedPos].teacherId == (ListenerService.shared.user?.userId ?? "") {
                cell.addButton?.isHidden = false
            } else {
                cell.addButton?.isHidden = true
            }
            return cell
        case 6:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailAchievementTableViewCell.self), for: indexPath) as! LessonsDetailAchievementTableViewCell
            cell.delegate = self
            cell.loadData(data: data[selectedPos].achievement)
            cellHeights[indexPath.row] = cell.cellHeight
            if data[selectedPos].teacherId == (ListenerService.shared.user?.userId ?? "") {
                cell.addButton?.isHidden = false
            } else {
                cell.addButton?.isHidden = true
            }
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailHomeworkTableViewCell.self), for: indexPath) as! LessonsDetailHomeworkTableViewCell
            cell.delegate = self

            var showCopyButton: Bool = false
            let assignmentData = data[selectedPos].preAssignmentData.filter({ $0.assignment })
            let practiceData = data[selectedPos].practiceData
            if practiceData.isEmpty {
                if !assignmentData.isEmpty {
                    showCopyButton = true
                }
            }
            logger.debug("刷新作业cell: \(showCopyButton) | \(assignmentData.count) | \(practiceData.count)")
            cell.loadData(data: practiceData, sId: data[selectedPos].id, showCopyButton: showCopyButton)
            cellHeights[indexPath.row] = cell.cellHeight
            cell.copyFromLastLessonButton.onTapped { [weak self] _ in
                guard let self = self else { return }
                let lessonData = self.data[self.selectedPos]
                let list = assignmentData
                list.forEachItems { _, index in
                    list[index].id = IDUtil.nextId(group: .lesson)?.description ?? ""
                    list[index].lessonScheduleId = lessonData.id
                    list[index].createTime = Date().timeIntervalSince1970.description
                    list[index].updateTime = Date().timeIntervalSince1970.description
                    list[index].done = false
                    list[index].studentId = self.data[self.selectedPos].studentId
                    list[index].teacherId = self.data[self.selectedPos].teacherId
                    list[index].startTime = self.data[self.selectedPos].shouldDateTime
                    list[index].scheduleConfigId = self.data[self.selectedPos].lessonScheduleConfigId
                    list[index].assignment = true
                    list[index].shouldDateTime = self.data[self.selectedPos].shouldDateTime
                    list[index].totalTimeLength = 0
                }
                self.data[self.selectedPos].practiceData = list.filterDuplicates({ $0.name.trimmingCharacters(in: .whitespacesAndNewlines) })
                self.showFullScreenLoadingNoAutoHide()
                self.saveAssignment()
                self.tableView.reloadData()
            }
            if data[selectedPos].teacherId == (ListenerService.shared.user?.userId ?? "") {
                cell.addButton?.isHidden = false
            } else {
                cell.addButton?.isHidden = true
            }
            return cell
        case 7:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsDetailNextLessonPlanTableViewCell.self), for: indexPath) as! LessonsDetailNextLessonPlanTableViewCell
            cell.isNext = true
            cell.delegate = self
            cell.tag = indexPath.row
            if data[selectedPos].preAndNextData.nextSchedule != nil {
                cell.loadData(data: data[selectedPos].nextLessonPlan, sId: data[selectedPos].preAndNextData.nextSchedule!.id)
            } else {
                cell.loadNoDataView()
            }
            cellHeights[indexPath.row] = cell.cellHeight
            if data[selectedPos].teacherId == (ListenerService.shared.user?.userId ?? "") {
                cell.addButton?.isHidden = false
            } else {
                cell.addButton?.isHidden = true
            }
            return cell
        case 8:
            let cell = tableView.dequeueReusableCell(withIdentifier: LessonDetailsMemoTableViewCell.id, for: indexPath) as! LessonDetailsMemoTableViewCell
            cell.delegate = self
            // 判断当前课程是否开始
            let start = data[selectedPos].shouldDateTime
            let now = Date().timeIntervalSince1970
            if now >= start && !data[selectedPos].rescheduled && data[selectedPos].rescheduleId == "" {
                cell.isRecordAttendanceHidden = false
            } else {
                cell.isRecordAttendanceHidden = true
            }
            cell.setMemo(memoString, attendance: data[selectedPos].attendance)
            cellHeights[indexPath.row] = cell.cellHeight
            cell.onRecordAttendanceTapped = { [weak self] in
                self?.onRecordAttendanceTapped()
            }
            return cell
        default:
            fatalError("Wrong index")
        }
    }
}

extension LessonsDetailViewController: LessonsDetailHomeworkTableViewCellDelegate {
    private func checkIfNeedReloadHomeworkCell() {
        if data[selectedPos].practiceData.isEmpty || data[selectedPos].allPracticeData.isEmpty {
//            switch data[selectedPos].lessonStatus {
//            case .schedule:
//                return
//            case .started:
//                cell = tableView.cellForRow(at: IndexPath(row: 5, section: 0)) as? LessonsDetailHomeworkTableViewCell
//            case .ended:
//                cell = tableView.cellForRow(at: IndexPath(row: 6, section: 0)) as? LessonsDetailHomeworkTableViewCell
//            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 5, section: 0)) as? LessonsDetailHomeworkTableViewCell {
                var showCopyButton: Bool = false
                let assignmentData = data[selectedPos].preAssignmentData.filter({ $0.assignment })
                let practiceData = data[selectedPos].practiceData
                if practiceData.isEmpty {
                    if !assignmentData.isEmpty {
                        showCopyButton = true
                    }
                }
                cell.loadData(data: practiceData, sId: data[selectedPos].id, showCopyButton: showCopyButton, isForce: false)
            }
        }
    }

    // MARK: - HomeworkTableViewCellDelegate

    func lessonsDetailHomeworkTableViewCellAddHomeworkTapped(withView button: TKButton, completion: @escaping () -> Void) {
        let controller = LessonDetailAddNewContentViewController()
        controller.titleString = "Add homework"
        controller.leftButtonString = "CANCEL"
        controller.rightButtonString = "CREATE"
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }

        controller.onRightButtonTapped = { [weak self] text in
            guard let self = self else { return }
            self.showFullScreenLoading()
            let assignment = TKPractice()
            let time = Date().timestamp
            assignment.updateTime = "\(time)"
            assignment.createTime = "\(time)"
            assignment.lessonScheduleId = self.data[self.selectedPos].id
            if let id = IDUtil.nextId() {
                assignment.id = "\(id)"
            } else {
                assignment.id = "\(time)"
            }
            assignment.name = text
            if assignment.assignmentId == "" {
                let id = "\(IDUtil.nextId(group: .lesson) ?? Int64(Date().timestamp))"
                assignment.assignmentId = id
            }
            assignment.studentId = self.data[self.selectedPos].studentId
            assignment.teacherId = self.data[self.selectedPos].teacherId
            assignment.startTime = self.data[self.selectedPos].shouldDateTime
            assignment.scheduleConfigId = self.data[self.selectedPos].lessonScheduleConfigId
            assignment.assignment = true
            assignment.shouldDateTime = self.data[self.selectedPos].shouldDateTime
            self.saveAssignment(assignment: assignment) { error in
                self.hideFullScreenLoading()
                controller.hide()
                if let error = error {
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                    logger.error("添加错误: \(error)")
                } else {
                    self.data[self.selectedPos].practiceData.append(assignment)
                }
                self.tableView.reloadData()
            }
        }
    }

    func lessonsDetailHomeworkTableViewCell(editAt index: Int) {
        let controller = LessonDetailAddNewContentViewController()
        controller.titleString = "Edit homework"
        controller.leftButtonString = "DELETE"
        controller.rightButtonString = "SAVE"
        controller.leftButtonStyle = .delete
        controller.text = data[selectedPos].practiceData[index].name
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
        controller.onLeftButtonTapped = { [weak self] _ in
            guard let self = self else { return }
            self.showFullScreenLoadingNoAutoHide()
            self.deleteAssignment(id: self.data[self.selectedPos].practiceData[index].id) { error in
                self.hideFullScreenLoading()
                controller.hide()
                if let error = error {
                    logger.error("删除失败: \(error)")
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                } else {
                    self.data[self.selectedPos].practiceData.remove(at: index)
                }
                self.tableView.reloadData()
            }
        }
        controller.onRightButtonTapped = { [weak self] text in
            guard let self = self else { return }
            controller.showFullScreenLoadingNoAutoHide()
            guard self.data.isSafeIndex(self.selectedPos) else {
                controller.hideFullScreenLoading()
                return
            }
            let oldName = self.data[self.selectedPos].practiceData[index].name
            self.data[self.selectedPos].practiceData[index].name = text
            self.saveAssignment(assignment: self.data[self.selectedPos].practiceData[index]) { error in
                controller.hideFullScreenLoading()
                controller.hide()
                if let error = error {
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                    logger.error("添加错误: \(error)")
                    self.data[self.selectedPos].practiceData[index].name = oldName
                }
                self.tableView.reloadData()
            }
        }
    }

    func lessonsDetailHomeworkTableViewCellAddHomeworkTapped(assignment: TKPractice) {
//        data[selectedPos].practiceData.append(assignment)
    }

    func lessonsDetailHomeworkTableViewCell(heightChanged height: CGFloat) {
        tableView.beginUpdates()
        cellHeights[6] = height
        tableView.endUpdates()
    }

    func lessonsDetailHomeworkTableViewCell(deleted index: Int, height: CGFloat) {
//        guard index < data[selectedPos].practiceData.count else { return }
//        tableView.beginUpdates()
//        deleteAssignment(id: data[selectedPos].practiceData[index].id)
//        data[selectedPos].practiceData.remove(at: index)
//        cellHeights[6] = height
//        tableView.endUpdates()
//        checkIfNeedReloadHomeworkCell()
    }

    func lessonsDetailHomeworkTableViewCell(textChanged text: String, height: CGFloat, at index: Int) {
//        tableView.beginUpdates()
//        data[selectedPos].practiceData[index].name = text
//        cellHeights[6] = height
//        tableView.endUpdates()
    }

    func lessonsDetailHomeworkTableViewCell(done assignment: TKPractice) {
//        if assignment.name != "" {
//            let assignment = assignment
//            if assignment.assignmentId == "" {
//                let id = "\(IDUtil.nextId(group: .lesson) ?? Int64(Date().timestamp))"
//                assignment.assignmentId = id
//            }
//            assignment.studentId = data[selectedPos].studentId
//            assignment.teacherId = data[selectedPos].teacherId
//            assignment.startTime = data[selectedPos].shouldDateTime
//            assignment.scheduleConfigId = data[selectedPos].lessonScheduleConfigId
//            assignment.assignment = true
//            assignment.shouldDateTime = data[selectedPos].shouldDateTime
//            upLoadAssignment(assignment: assignment)
//        }
//        if data[selectedPos].practiceData.isEmpty {
//            tableView.reloadRows(at: [IndexPath(row: 6, section: 0)], with: .none)
//        }
    }

    func saveAssignment() {
        let assignmentList = data[selectedPos].practiceData
        guard !assignmentList.isEmpty else { return }
        addSubscribe(
            LessonService.lessonSchedule.addPractices(data: assignmentList)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    logger.debug("==saveAssignment==success")
                    self.hideFullScreenLoading()
                    self.checkIfNeedReloadHomeworkCell()
                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    logger.debug("==saveAssignment====\(err)")
                })
        )
    }

    func saveAssignment(assignment: TKPractice, completion: ((Error?) -> Void)? = nil) {
        addSubscribe(
            LessonService.lessonSchedule.addPractice(data: assignment)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.checkIfNeedReloadHomeworkCell()
                    completion?(nil)
                }, onError: { err in
                    completion?(err)
                })
        )
    }

    func deleteAssignment(id: String, completion: ((Error?) -> Void)? = nil) {
        addSubscribe(
            LessonService.lessonSchedule.deletePractice(id: id)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.checkIfNeedReloadHomeworkCell()
                    completion?(nil)
                }, onError: { err in
                    completion?(err)
                })
        )
    }
}

extension LessonsDetailViewController: LessonsDetailAchievementTableViewCellDelegate {
    func lessonsDetailAchievementTableViewCellAchievementTapped(index: Int) {
        TKPopAction.showEditAchievement(target: self, oldData: data[selectedPos].achievement[index], confirmAction: { [weak self] newData in
            guard let self = self else { return }
            self.data[self.selectedPos].achievement[index].name = newData.name
            self.data[self.selectedPos].achievement[index].type = newData.type
            self.data[self.selectedPos].achievement[index].desc = newData.desc
            self.updateAchievement(achievement: self.data[self.selectedPos].achievement[index])
            self.tableView.reloadData()
        }) { [weak self] in
            guard let self = self else { return }
            self.deleteAchievement(id: self.data[self.selectedPos].achievement[index].id)
            if self.data[self.selectedPos].achievement.count > index {
                self.data[self.selectedPos].achievement.remove(at: index)
            }
            self.tableView.reloadData()
        }
    }

    // MARK: - AchievementTableViewCellDelegate

    func lessonsDetailAchievementTableViewCellAddAchievementTapped() {
        TKPopAction.showAddAchievement(target: self) { [weak self] data in
            guard let self = self else { return }
            logger.debug(data.toJSONString(prettyPrint: true) ?? "")
            var data = data
            data.scheduleId = self.data[self.selectedPos].id
            data.studentId = self.data[self.selectedPos].studentId
            data.teacherId = self.data[self.selectedPos].teacherId
            data.shouldDateTime = self.data[self.selectedPos].shouldDateTime
            self.data[self.selectedPos].achievement.append(data)
            self.addAchievement(achievement: data)
            self.tableView.reloadData()
        }
    }

    func addAchievement(achievement: TKAchievement) {
        addSubscribe(
            LessonService.lessonSchedule.addAchievement(data: achievement)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    logger.debug("=ADDAchievement成功=====")
                    self.tableView.reloadData()
                }, onError: { err in
                    logger.debug("=ADDAchievement失败=====\(err)")
                })
        )
    }

    func deleteAchievement(id: String) {
        addSubscribe(
            LessonService.lessonSchedule.deleteAchievement(id: id)
                .subscribe(onNext: { _ in
                    logger.debug("====deleteAchievement成功=====")
                }, onError: { err in
                    logger.debug("====deleteAchievement失败=====\(err)")
                })
        )
    }

    func updateAchievement(achievement: TKAchievement) {
        print(achievement.toJSONString(prettyPrint: true) ?? "")
        addSubscribe(
            LessonService.lessonSchedule.updateAchievement(id: achievement.id, data: ["type": achievement.type.rawValue, "name": achievement.name, "desc": achievement.desc])
                .subscribe(onNext: { _ in
//                    logger.debug("=updateAchievement成功=====")
                }, onError: { _ in
//                    logger.debug("=updateAchievement失败=====\(err)")
                })
        )
    }
}

extension LessonsDetailViewController: LessonsDetailStudentsTableViewCellDelegate, LessonDetailPracticeTableViewCellDelegate {
    func lessonDetailPracticeTableViewCell(cell: LessonDetailPracticeTableViewCell) {
        var practiceDatas: [TKPracticeAssignment] = []
        var data: [TKPractice] = []
        var isShowIncomplete = false
        if self.data[selectedPos].preAndNextData.preScheudle != nil {
            self.data[selectedPos].preAssignmentData.forEachItems { item, _ in
                if item.assignment {
                    var index = -1
                    for newItem in data.enumerated() where newItem.element.lessonScheduleId == item.lessonScheduleId && newItem.element.name == item.name && newItem.element.startTime != item.startTime {
                        index = newItem.offset
                    }
                    if index >= 0 {
                        data[index].recordData += item.recordData
                        if item.done {
                            data[index].done = true
                        }
                        data[index].totalTimeLength += item.totalTimeLength
                    } else {
                        data.append(item)
                    }
                } else {
                    data.append(item)
                }
            }
            self.data[selectedPos].preAssignmentData = data.filterDuplicates { $0.id }

            var practiceData = TKPracticeAssignment()
            practiceData.startTime = self.data[selectedPos].preAndNextData.preScheudle!.shouldDateTime
            practiceData.practice = self.data[selectedPos].preAssignmentData.filterDuplicates { $0.id }

            practiceData.endTime = self.data[selectedPos].shouldDateTime
            isShowIncomplete = self.data[selectedPos].shouldDateTime >= Date().timeIntervalSince1970

            practiceDatas.append(practiceData)
        }
        for item in practiceDatas.enumerated() {
            practiceDatas[item.offset].practice = item.element.practice.filterDuplicates { $0.id }
        }

        let controller = PracticeViewController()

        controller.data = practiceDatas
        controller.isShowIncomplete = isShowIncomplete
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    // MARK: - StudentsTableViewCellDelegate

    func lessonsDetailStudentsTableViewCell(cell: LessonsDetailStudentsTableViewCell) {
        guard let studentData = data[selectedPos].studentData else {
            return
        }
//        let controller = StudentDetailsViewController()
//        controller.hero.isEnabled = true
//        controller.modalPresentationStyle = .fullScreen
//        controller.studentData = studentData
//        controller.enablePanToDismiss()
//        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//        present(controller, animated: true, completion: nil)
//        let controller = NewStudentDetailController()
//        controller.modalPresentationStyle = .fullScreen
//        controller.hero.isEnabled = true
//        controller.studentData = studentData
//        controller.enablePanToDismiss()
//        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//        present(controller, animated: true, completion: nil)
        let controller = StudentDetailsViewController()
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.studentData = studentData
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func lessonsDetailStudentsTableViewCellStudentItemChanged(index: Int) {
        if index != selectedPos {
            selectedPos = index
            tableView.contentOffset.y = 0
            initLessonStatus()
        }
    }

    private func setMemo() {
        let lesson = data[selectedPos]
        let index = selectedPos
        if let config = lesson.lessonScheduleData {
            memoString = config.memo
        } else {
            LessonService.lessonScheduleConfigure.getLessonScheduleConfig(byConfigId: lesson.lessonScheduleConfigId)
                .done { [weak self] config in
                    guard let self = self, let config = config else { return }
                    guard self.selectedPos == index else { return }
                    self.memoString = config.memo
                }
                .catch { [weak self] error in
                    guard let self = self else { return }
                    logger.error("获取config失败: \(error)")
                    self.memoString = ""
                }
        }
    }
}

extension LessonsDetailViewController: LessonsDetailLessonNotesTableViewCellDelegate {
    // MARK: - NotesTableViewCellDelegate

    func lessonsDetailLessonNotesTableViewCell(done text: String) {
        let lessonSchedule = data[selectedPos]
        addSubscribe(
            LessonService.lessonSchedule.updateLessonScheduleNotesForTeacher(lessonSchedule: lessonSchedule, note: text.trimmingCharacters(in: .whitespacesAndNewlines))
                .subscribe(onNext: { _ in
                }, onError: { _ in
                })
        )
    }

    func lessonsDetailLessonNotesTableViewCell(heightChanged height: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) is LessonsDetailLessonNotesTableViewCell {
                self.tableView.beginUpdates()
                self.cellHeights[3] = height
                self.tableView.endUpdates()
            }
        }
    }

    func lessonsDetailLessonNotesTableViewCell(textChanged text: String, height: CGFloat, at index: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) is LessonsDetailLessonNotesTableViewCell {
                self.tableView.beginUpdates()
                self.data[self.selectedPos].teacherNote = text
                self.cellHeights[3] = height
                self.tableView.endUpdates()
            }
        }
    }

    func lessonsDetailLessonNotesTableViewCellAddLessonTapeed(addButton: TKButton, completion: @escaping () -> Void) {
//        data[selectedPos].teacherNote = ""
        scrollBeforeKeyboardShow(addButton)
        DispatchQueue.main.async {
            completion()
        }
    }

    func lessonsDetailLessonNotesTableViewCell(removeAt index: Int, height: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) is LessonsDetailLessonNotesTableViewCell {
                self.tableView.beginUpdates()
                self.data[self.selectedPos].teacherNote = ""
                self.cellHeights[3] = height
                self.tableView.endUpdates()
            }
        }
    }

    private func scrollBeforeKeyboardShow(_ targetView: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let point = targetView.convert(targetView.center, to: self.view)
            logger.debug("点击的位置: \(point.x) | \(point.y)")
            let offset = UIScreen.main.bounds.height - point.y
            if offset < 300 {
                let offsetY = 300 - offset + 70
                logger.debug("当前点击位置在键盘之下,需要往上滚动: \(offsetY)")
                let contentOffset = self.tableView.contentOffset
                self.tableView.setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y + offsetY), animated: true)
            }
        }
    }
}

extension LessonsDetailViewController: LessonsDetailMaterialsTableViewCellDelegate, MaterialsViewControllerListDelegate {
    // MARK: - MaterialsTableViewCellDelegate

    func lessonsDetailMaterialsTableViewCell(click: TKMaterial, materilaCell: MaterialsCell) {
        MaterialsHelper.cellClick(materialsData: click, cell: materilaCell, mController: self)
    }

    func lessonsDetailMaterialsTableViewCell(selectedData: [TKMaterial]) {
        var selectIds: [String] = []
        for item in selectedData {
            selectIds.append(item.id)
        }
        logger.debug("进入材料分享页面,当前选中的材料Id: \(selectIds)")
        let controller = Materials2ViewController(type: .share(selectIds), isEdit: false, data: nil)
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        controller.onConfirmed = { [weak self] selectedData, _ in
            self?.materialsViewController(selectData: selectedData)
        }
        present(controller, animated: true, completion: nil)
    }

    func materialsViewController(selectData: [TKMaterial]) {
        var addData: [TKMaterial] = []
        var deleteDate: [TKMaterial] = []

        // 1.新的有老的没有:需要Add, 2.新的有老的也有:不用管, 3.新的没有老的有:要删除
        for item in selectData {
            let isHave = data[selectedPos].materilasData.contains { d -> Bool in
                d.id == item.id
            }
            if !isHave {
                addData.append(item)
            }
        }
        for item in data[selectedPos].materilasData {
            let isHave = selectData.contains { d -> Bool in
                d.id == item.id
            }
            if !isHave {
                deleteDate.append(item)
            }
        }
        data[selectedPos].materilasData = selectData
        materialsData[selectedPos] = data[selectedPos].materilasData
        cellHeights[4] = getMaterialsHeight()
        addMaterials(addData, deleteDate)
        tableView.reloadData()
    }

    func addMaterials(_ addData: [TKMaterial], _ deleteDate: [TKMaterial]) {
        var materialsDatas: [TKLessonScheduleMaterial] = []
        var materialsIds: [String] = []
        var studentIds: [String] = []
        var shareData: [String: [String]] = [:]
        studentIds.append(data[selectedPos].studentId)
        var deleteList: [TKLessonScheduleMaterial] = []
        for item in deleteDate {
            for oldData in data[selectedPos].lessonScheduleMaterials.enumerated().reversed() where item.id == oldData.element.materialId {
                deleteList.append(oldData.element)
                data[selectedPos].lessonScheduleMaterials.remove(at: oldData.offset)
            }
        }

        for item in addData {
            materialsIds.append(item.id)
            shareData[item.id] = item.studentIds
            shareData[item.id]?.append(contentsOf: studentIds)
            let time = "\(Date().timestamp)"
            var s = TKLessonScheduleMaterial()
            if let id = IDUtil.nextId(group: .lesson) {
                s.id = "\(id)"
            } else {
                s.id = time
            }
            s.lessonScheduleId = data[selectedPos].id
            s.studentId = data[selectedPos].studentId
            s.teacherId = data[selectedPos].teacherId
            s.shouldDateTime = data[selectedPos].shouldDateTime
            s.materialId = item.id
            s.updateTime = time
            s.createTime = time
            materialsDatas.append(s)
            data[selectedPos].lessonScheduleMaterials.append(s)
        }

        addSubscribe(
            LessonService.lessonSchedule.addLessonScheduleMaterialAndDelete(addData: materialsDatas, deleteData: deleteList)
                .subscribe(onNext: { _ in
                    logger.error("上传成功")
                }, onError: { err in
                    logger.error("上传失败\(err)")
                })
        )
    }
}

// MARK: - LessonPlanTableViewCellDelegate

extension LessonsDetailViewController: LessonsDetailNextLessonPlanTableViewCellDelegate {
    func lessonsDetailNextLessonPlanTableViewCellOnTextViewFocus() {
    }

    func lessonsDetailNextLessonPlanTableViewCell(check index: Int, plan: TKLessonPlan, cell: LessonsDetailNextLessonPlanTableViewCell) {
        if cell.tag == 2 {
            data[selectedPos].lessonPlan[index] = plan
        }
        if cell.tag == 7 {
            data[selectedPos].nextLessonPlan[index] = plan
        }
        updateLessonPlan(id: plan.id, data: ["done": plan.done])
//        upLoadLessonPlan(plan: plan)
    }

    func lessonsDetailNextLessonPlanTableViewCell(done plan: TKLessonPlan, cell: LessonsDetailNextLessonPlanTableViewCell) {
        if plan.plan != "" {
            var plan = plan
//            if data[selectedPos].lessonStatus == .schedule {
//            } else if data[selectedPos].lessonStatus == .ended {
//                plan.id
//            }
            plan.studentId = data[selectedPos].studentId
            plan.teacherId = data[selectedPos].teacherId
            if cell.tag == 2 {
                plan.shouldDateTime = data[selectedPos].shouldDateTime
                upLoadLessonPlan(plan: plan)
            } else if cell.tag == 7 {
                if data[selectedPos].preAndNextData.nextSchedule != nil {
                    print("===我要添加的数据的\(data[selectedPos].preAndNextData.nextSchedule!.toJSONString(prettyPrint: true) ?? "")")
                    plan.shouldDateTime = data[selectedPos].preAndNextData.nextSchedule!.shouldDateTime
                    upLoadLessonPlan(plan: plan)
                }
            }
        }
    }

    func lessonsDetailNextLessonPlanTableViewCell(textChanged text: String, height: CGFloat, at index: Int, cell: LessonsDetailNextLessonPlanTableViewCell) {
        tableView.beginUpdates()
        if cell.tag == 2 {
            data[selectedPos].lessonPlan[index].plan = text
            cellHeights[2] = height
        }
        if cell.tag == 7 {
            data[selectedPos].nextLessonPlan[index].plan = text
            cellHeights[7] = height
        }
        tableView.endUpdates()
    }

    func lessonsDetailNextLessonPlanTableViewCellAddTapped(withView addButton: TKButton, completion: @escaping () -> Void) {
        let controller = LessonDetailAddNewContentViewController()
        controller.titleString = "Add lesson plan"
        controller.leftButtonString = "CANCEL"
        controller.rightButtonString = "CREATE"
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] text in
            guard let self = self else { return }
            self.showFullScreenLoading()
            var plan = TKLessonPlan()
            let time = Date().timestamp
            plan.plan = text
            plan.updateTime = "\(time)"
            plan.createTime = "\(time)"
            if let id = IDUtil.nextId() {
                plan.id = "\(id)"
            } else {
                plan.id = "\(time)"
            }
            plan.studentId = self.data[self.selectedPos].studentId
            plan.teacherId = self.data[self.selectedPos].teacherId
            if self.data[self.selectedPos].lessonStatus == .schedule {
                plan.lessonScheduleId = self.data[self.selectedPos].id
                plan.shouldDateTime = self.data[self.selectedPos].shouldDateTime
                self.upLoadLessonPlan(plan: plan) { error in
                    self.hideFullScreenLoading()
                    controller.hide()
                    if let error = error {
                        logger.error("上传失败: \(error)")
                    } else {
                        self.data[self.selectedPos].lessonPlan.append(plan)
                        self.tableView.reloadData()
                    }
                }
            } else if self.data[self.selectedPos].lessonStatus == .ended {
                if self.data[self.selectedPos].preAndNextData.nextSchedule != nil {
                    plan.lessonScheduleId = self.data[self.selectedPos].preAndNextData.nextSchedule!.id
                    plan.shouldDateTime = self.data[self.selectedPos].preAndNextData.nextSchedule!.shouldDateTime
                    self.upLoadLessonPlan(plan: plan) { error in
                        self.hideFullScreenLoading()
                        controller.hide()
                        if let error = error {
                            logger.error("上传失败: \(error)")
                        } else {
                            self.data[self.selectedPos].nextLessonPlan.append(plan)
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }

    func lessonsDetailNextLessonPlanTableViewCell(editAt index: Int) {
        guard selectedPos < data.count else { return }
        let itemData = data[selectedPos]
        var plan: TKLessonPlan
        switch itemData.lessonStatus {
        case .schedule:
            guard index < itemData.lessonPlan.count else { return }
            plan = itemData.lessonPlan[index]
        case .ended:
            guard index < itemData.nextLessonPlan.count else { return }
            plan = itemData.nextLessonPlan[index]
        default:
            return
        }
        let controller = LessonDetailAddNewContentViewController()
        controller.titleString = "Add lesson plan"
        controller.leftButtonString = "DELETE"
        controller.rightButtonString = "SAVE"
        controller.leftButtonStyle = .delete
        controller.text = plan.plan
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
        controller.onLeftButtonTapped = { [weak self] _ in
            guard let self = self else { return }
            self.showFullScreenLoadingNoAutoHide()
            self.deleteLessonPlan(id: plan.id, completion: { error in
                self.hideFullScreenLoading()
                controller.hide()
                if let error = error {
                    logger.error("发生错误: \(error)")
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                } else {
                    switch itemData.lessonStatus {
                    case .schedule:
                        guard index < itemData.lessonPlan.count else { return }
                        itemData.lessonPlan.remove(at: index)
                        self.tableView.reloadData()
                    case .ended:
                        guard index < itemData.nextLessonPlan.count else { return }
                        itemData.nextLessonPlan.remove(at: index)
                        self.tableView.reloadData()
                    default:
                        break
                    }
                }
            })
        }

        controller.onRightButtonTapped = { [weak self] text in
            guard let self = self else { return }
            plan.plan = text
            self.showFullScreenLoadingNoAutoHide()
            self.updateLessonPlan(id: plan.id, data: ["plan": text], completion: { error in
                self.hideFullScreenLoading()
                controller.hide()
                if let error = error {
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                } else {
                    switch itemData.lessonStatus {
                    case .schedule:
                        guard index < itemData.lessonPlan.count else { return }
                        itemData.lessonPlan[index] = plan
                        self.tableView.reloadData()
                    case .ended:
                        guard index < itemData.nextLessonPlan.count else { return }
                        itemData.nextLessonPlan[index] = plan
                        self.tableView.reloadData()
                    default:
                        break
                    }
                }
            })
        }
    }

    func lessonsDetailNextLessonPlanTableViewCellAddTapped(plan: TKLessonPlan, cell: LessonsDetailNextLessonPlanTableViewCell) {
        if cell.tag == 2 {
            data[selectedPos].lessonPlan.append(plan)
//            if nextButton.isHidden && data[selectedPos].lessonPlan.count > 0 && data[selectedPos].lessonStatus != .ended {
//                nextButton.isHidden = false
//            }
        }
        if cell.tag == 7 {
            data[selectedPos].nextLessonPlan.append(plan)
        }
//        switch data[selectedPos].lessonStatus {
//        case .schedule:
//            data[selectedPos].lessonPlan.append(plan)
//            if nextButton.isHidden && data[selectedPos].lessonPlan.count > 0 {
//                nextButton.isHidden = false
//            }
//            break
//        case .started:
//            break
//        case .ended:
//            data[selectedPos].nextLessonPlan.append(plan)
//            break
//        }
    }

    func lessonsDetailNextLessonPlanTableViewCell(heightChanged height: CGFloat, cell: LessonsDetailNextLessonPlanTableViewCell) {
        tableView.beginUpdates()
        if cell.tag == 2 {
            cellHeights[2] = height
        }
        if cell.tag == 7 {
            cellHeights[7] = height
        }
//        switch data[selectedPos].lessonStatus {
//        case .schedule:
//            cellHeights[2] = height
//            break
//        case .started:
//            break
//        case .ended:
//            cellHeights[7] = height
//            break
//        }
        tableView.endUpdates()
    }

    func lessonsDetailNextLessonPlanTableViewCell(deleted index: Int, height: CGFloat, cell: LessonsDetailNextLessonPlanTableViewCell) {
        guard selectedPos < data.count, index < data[selectedPos].lessonPlan.count else {
            return
        }
        tableView.beginUpdates()
        if cell.tag == 2 {
            deleteLessonPlan(id: data[selectedPos].lessonPlan[index].id)
            data[selectedPos].lessonPlan.remove(at: index)
            cellHeights[2] = height
//            if nextButton.isHidden && data[selectedPos].lessonPlan.count > 0 && data[selectedPos].lessonStatus != .ended {
//                nextButton.isHidden = false
//            }
        }
        if cell.tag == 7 {
            deleteLessonPlan(id: data[selectedPos].nextLessonPlan[index].id)
            data[selectedPos].nextLessonPlan.remove(at: index)
            cellHeights[7] = height
        }
//        switch data[selectedPos].lessonStatus {
//        case .schedule:
//            deleteLessonPlan(id: data[selectedPos].lessonPlan[index].id)
//            data[selectedPos].lessonPlan.remove(at: index)
//            cellHeights[2] = height
//            if nextButton.isHidden && data[selectedPos].lessonPlan.count > 0 {
//                nextButton.isHidden = false
//            }
//            break
//        case .started:
//            break
//        case .ended:
//            deleteLessonPlan(id: data[selectedPos].nextLessonPlan[index].id)
//            data[selectedPos].nextLessonPlan.remove(at: index)
//            cellHeights[7] = height
//            break
//        }
        tableView.endUpdates()
    }

    func upLoadLessonPlan(plan: TKLessonPlan, completion: ((Error?) -> Void)? = nil) {
        addSubscribe(
            LessonService.lessonSchedule.addLessonPlan(plan: plan)
                .subscribe(onNext: { _ in
                    completion?(nil)
                    logger.debug("======添加Plan成功")
                }, onError: { err in
                    completion?(err)
                    logger.debug("======添加Plan失败:\(err)")
                })
        )
    }

    func deleteLessonPlan(id: String, completion: ((Error?) -> Void)? = nil) {
        addSubscribe(
            LessonService.lessonSchedule.deleteLessonPlan(id: id)
                .subscribe(onNext: { _ in
                    completion?(nil)
                    logger.debug("======删除Plan成功")
                }, onError: { err in
                    completion?(err)
                    logger.debug("======删除Plan失败:\(err)")
                })
        )
    }

    func updateLessonPlan(id: String, data: [AnyHashable: Any], completion: ((Error?) -> Void)? = nil) {
        addSubscribe(
            LessonService.lessonSchedule.updateLessonPlan(id: id, data: data)
                .subscribe(onNext: { _ in
                    completion?(nil)
                    logger.debug("======更新Plan成功")
                }, onError: { err in
                    completion?(err)
                    logger.debug("======更新Plan失败:\(err)")
                })
        )
    }
}

extension LessonsDetailViewController: TKCountdownLabelDelegate {
    /// 检测是否正在上课
    func checkClassNow() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

            if let lesson = appdelegate.lessonNow {
                if !appdelegate.isShowFullScreenCuntdown {
                    let endTime = lesson.getShouldDateTime() + (Double(lesson.shouldTimeLength) * Double(60))
                    let toTime = Date(timeIntervalSince1970: endTime)
                    self.countdownLabel.setCountDownDate(targetDate: toTime)
                    self.countdownLabel.start()
                    self.countdownView.isHidden = false
                    self.checkCountdownGuide()
                    appdelegate.lessonNow = lesson
                }
            } else {
                self.countdownView.isHidden = true
                self.countdownImageView.isHidden = true
                appdelegate.lessonNow = nil
            }
        }
    }

    func countdownFinished() {
        countdownView.isHidden = true
        countdownImageView.isHidden = true
        guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appdelegate.lessonNow = nil
        checkClassNow()
    }
}

extension LessonsDetailViewController: LessonDetailsMemoTableViewCellDelegate {
    func lessonDetailsMemoTableViewCell(heightChanged height: CGFloat) {
        tableView.beginUpdates()
        switch data[selectedPos].lessonStatus {
        case .schedule:
            cellHeights[3] = height
        case .started:
            cellHeights[6] = height
        case .ended:
            cellHeights[8] = height
        }
        tableView.endUpdates()
    }
}

extension LessonsDetailViewController {
    private func onRecordAttendanceTapped() {
        TKPopAction.show(items: [
            .init(title: "Present", action: { [weak self] in
                self?.recordAttendance(.present)
            }),
            .init(title: "Excused", action: { [weak self] in
                self?.recordAttendance(.excused)
            }),
            .init(title: "Unexcused", action: { [weak self] in
                self?.recordAttendance(.unexcused)
            }),
            .init(title: "Late", action: { [weak self] in
                self?.recordAttendance(.late)
            }),
        ], isCancelShow: true, target: self)
    }

    private func recordAttendance(_ type: TKLessonSchedule.Attendance.AttendanceType) {
        guard data.isSafeIndex(selectedPos) else { return }
        let item = data[selectedPos]
        let attendance = TKLessonSchedule.Attendance(id: IDUtil.nextId()?.description ?? "", type: type, createTime: Date().timeIntervalSince1970)
        showFullScreenLoadingNoAutoHide()
        DatabaseService.collections.lessonSchedule()
            .document(item.id)
            .updateData(["attendance": FieldValue.arrayUnion([attendance.toJSON() ?? [:]])]) { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("更新attendance失败: \(error)")
                    TKToast.show(msg: "Record attendance failed, please try again later.", style: .error)
                } else {
                    self.data[self.selectedPos].attendance.append(attendance)
                    self.tableView?.reloadData()
                }
            }
    }
}
