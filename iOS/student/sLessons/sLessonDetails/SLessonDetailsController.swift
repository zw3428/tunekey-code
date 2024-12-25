//
//  SLessonDetailsController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/21.
//  Copyright © 2019年 spelist. All rights reserved.
//

import AttributedString
import FirebaseFirestore
import MapKit
import RxSwift
import UIKit

class SLessonDetailsController: TKBaseViewController {
    private var mainView = UIView()
    private var navigationBar: TKNormalNavigationBar!
    private var tableView: UITableView!

    private var memoView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.backgroundColor)

    private lazy var topInfoView: ViewBox = makeTopInfoView()

    @Live private var memo: String = "" {
        didSet {
//            guard memo != "" else { return }
//            memoView.subviews.forEach({ $0.removeFromSuperview() })
//            var content: String = memo.replacingOccurrences(of: "\n", with: "")
//            content = content.trimmingCharacters(in: .whitespaces)
//            let regulaStr = "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)"
//            guard let regex = try? NSRegularExpression(pattern: regulaStr, options: []) else {
//                return
//            }
//            let results = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
//            var attrString = ASAttributedString(string: content, .font(FontUtil.regular(size: 13)), .foreground(ColorUtil.Font.primary))
//            for result in results {
//                attrString = attrString.set([.font(FontUtil.bold(size: 13)), .foreground(ColorUtil.main), .action({
//                    guard let range = Range(result.range, in: content) else { return }
//                    let value = content[range]
//                    logger.debug("点击了action: \(value)")
//                    guard let url = URL(string: String(value)) else { return }
//                    UIApplication.shared.open(url)
//                }) ], range: result.range)
//            }
//            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
//                Label()
//                    .textColor(ColorUtil.Font.fourth)
//                    .font(FontUtil.regular(size: 13))
//                    .textAlignment(.center)
//                    .numberOfLines(0)
//                    .apply { [weak self] label in
//                        guard let self = self else { return }
//                        label.attributed.text = attrString
//                        let height = memo.heightWithFont(font: FontUtil.regular(size: 13), fixedWidth: UIScreen.main.bounds.width - 40)
//                        logger.debug("计算出的memo的高度: \(height)")
//                        self.memoView.snp.updateConstraints { make in
//                            make.height.equalTo(height + 42)
//                        }
//                    }
//            }
//            .addTo(superView: memoView) { make in
//                make.top.left.right.bottom.equalToSuperview()
//            }
        }
    }

    @Live private var location: TKLocation?

    var lessonData: TKLessonSchedule!
    var beforeLessonData: TKLessonSchedule!
    var preLessonData: TKLessonSchedule? {
        didSet {
            updateCellCount()
        }
    }

    var nextLessonData: TKLessonSchedule? {
        didSet {
            updateCellCount()
        }
    }

    private func updateCellCount() {
        guard let currentLessonData = lessonData else { return }
        let now = Date().timeIntervalSince1970
        if currentLessonData.shouldDateTime > now {
            // 当前的课程是没有上的,判断上一次课程是否是已经上过了
            if let preLessonData = preLessonData {
                if preLessonData.shouldDateTime <= now {
                    // 上一次课程上过了,显示练习记录
                    cellCount = 4
                    tableView?.reloadData()
                } else {
                    // 上一次课程没有上过,证明是upcoming里的课
                    cellCount = 3
                    tableView?.reloadData()
                }
            } else {
                // 没有上一节课,显示
                cellCount = 4
                tableView?.reloadData()
            }
        } else {
            // 当前课程上过了,显示练习记录
            cellCount = 4
            tableView?.reloadData()
        }
    }

    private var practiceData: [TKPractice] = [] {
        didSet {
            lessonData?.practiceData = practiceData
        }
    }

    private var lessonScheduleConfig: TKLessonScheduleConfigure? {
        ListenerService.shared.studentData.scheduleConfigs.first(where: { $0.id == (lessonData?.lessonScheduleConfigId ?? "-") })
    }

    var cellCount: Int = 3

    var isReadAchievement = false

    private var materialsData: [TKMaterial] = []
    var cell3Heights: [CGFloat] = [74, 74, 74]
    var cell4Heights: [CGFloat] = [83 + 22, 74, 74, 74]
    private var notesIsShow = false
    private var achievementIsShow = false
    var endTime: TimeInterval!
    var isLoadoadPracticeData = false

    var isNoteFirst = true
    var isAchievementFirst = true
    var isShowAchievement: Bool = false
    var isShowMaterial: Bool = false

    var listeners: [ListenerRegistration?] = []

    private var newMaterials: Bool = false
    private var initedMaterials: Bool = false
    private var lessonScheduleMaterialsData: [TKLessonScheduleMaterial] = [] {
        didSet {
            guard !initedMaterials else { return }
            initedMaterials = true
            newMaterials = lessonScheduleMaterialsData.filter { !$0.studentRead }.count > 0
        }
    }

    private var achievementCellNeedOpen: Bool = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if achievementCellNeedOpen {
            achievementCellNeedOpen = false
            let row = cellCount == 3 ? 1 : 2
            if let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? SAchievementCell {
                cell.clickTitleView()
            }
        }
    }

    convenience init(lessonSchedule: TKLessonSchedule) {
        self.init(nibName: nil, bundle: nil)
        lessonData = lessonSchedule
        beforeLessonData = lessonSchedule
        logger.debug("当前的 lesson config：\(lessonSchedule.lessonScheduleConfigId)")
    }

    deinit {
        logger.debug("销毁学生课程详情页")
        listeners.forEach { listener in
            listener?.remove()
        }
    }
}

extension SLessonDetailsController {
    private func getLessonShceduleConfig() {
        LessonService.lessonScheduleConfigure.getLessonScheduleConfig(byConfigId: lessonData.lessonScheduleConfigId)
            .done { [weak self] config in
                guard let self = self else { return }
                if let config = config {
//                    self.memo = config.memo
                    self.memo = "This is test memo, this is test memo, with link: https://zoom.us/linkspofijsodifj"
                    self.location = config.location
                }
            }
            .catch { error in
                logger.error("获取config失败: \(error)")
            }
    }

    private func checkStudentReadNote() {
        logger.debug("开始已读notes")
        guard let lessonSchedule = lessonData, !lessonSchedule.studentReadTeacherNote else {
            logger.debug("当前notes已读")
            return
        }
        addSubscribe(
            LessonService.lessonSchedule.studentReadLessonNote(lessonSchedule: lessonSchedule)
                .subscribe(
                    onNext: { _ in
                        logger.debug("已读教师Note成功")
                    }, onError: { err in
                        logger.debug("已读教师Note: \(err)")
                    }
                )
        )
    }

    private func checkStudentReadAchievements() {
        logger.debug("开始已读achievement")
        guard let lessonSchedule = lessonData else { return }
        logger.debug("准备已读achievements")
        let achievements = lessonSchedule.achievement.filter { !$0.studentRead }
        logger.debug("获取到的achievements数量: \(achievements.count)")
        if !isReadAchievement {
            isReadAchievement = achievements.count > 0
        }
        guard achievements.count > 0 else { return }
        logger.debug("开始已读achievements")
        LessonService.lessonSchedule.studentReadAchievements(achievements: achievements)
            .done { _ in
                logger.debug("已读教师Achievements成功")
            }
            .catch { error in
                logger.debug("已读教师Achievements失败: \(error)")
            }
    }

    private func checkStudentReadMaterial() {
        logger.debug("开始已读materials: \(lessonScheduleMaterialsData.toJSONString() ?? "")")
        let data = lessonScheduleMaterialsData.filter { !$0.studentRead }
        LessonService.lessonSchedule.studentReadMaterials(data)
            .done { _ in
                logger.debug("已读材料成功")
            }
            .catch { error in
                logger.error("已读材料失败: \(error)")
            }
    }
}

// MARK: - View

extension SLessonDetailsController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "", target: self)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
//        memoView.addTo(superView: mainView) { make in
//            make.top.equalTo(navigationBar.snp.bottom)
//            make.left.right.equalToSuperview()
//            make.height.equalTo(0)
//        }

        topInfoView.addTo(superView: mainView) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.equalToSuperview()
        }
        initTableView()
    }

    private func makeTopInfoView() -> ViewBox {
        ViewBox {
            ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
                VStack(spacing: 10) {
                    Label().textColor(ColorUtil.Font.fourth)
                        .font(FontUtil.regular(size: 13))
                        .textAlignment(.center)
                        .numberOfLines(0)
                        .apply { [weak self] label in
                            guard let self = self else { return }
                            self.$memo.addSubscriber { memo in
                                label.isHidden = memo.isEmpty
                            }
                        }
                    Label()
                        .textAlignment(.center)
                        .numberOfLines(0)
                        .apply { [weak self] label in
                            guard let self = self else { return }
                            self.$location.addSubscriber { location in
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
                                    label.attributed.text = locationText + ASAttributedString(string: location.remoteLink, with: [.font(.medium(size: 13)), .foreground(.tertiary), .underline(.single, color: .tertiary), .action {
                                        guard let url = URL(string: location.remoteLink) else { return }
                                        UIApplication.shared.open(url)
                                    }])
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
                                                var attributes: [ASAttributedString.Attribute] = [.font(.medium(size: 13)), .foreground(.tertiary), .action {
                                                    guard let studio = ListenerService.shared.studentData.studioData else { return }
                                                    PopSheet()
                                                        .items([
                                                            .init(title: "Copy Address", action: {
                                                                UIPasteboard.general.string = studio.addressDetail.addressString
                                                                TKToast.show(msg: "Copied.", style: .success)
                                                            }),
                                                            .init(title: "Open Map", action: {
                                                                self.openMapWithAddress(address: studio.addressDetail.addressString)
                                                            }),
                                                        ])
                                                        .show()
                                                }]
                                                if let studio = ListenerService.shared.studentData.studioData {
                                                    if studio.addressDetail.isValid {
                                                        attributes.append(.underline(.single, color: .tertiary))
                                                    }
                                                }
                                                label.attributed.text = locationText + ASAttributedString(string: studioRoom.name, with: attributes)
                                            }
                                        }
                                        .catch { error in
                                            logger.error("获取studio room失败：\(error)")
                                        }
                                default:
                                    var attributes: [ASAttributedString.Attribute] = [.font(.medium(size: 13)), .foreground(.tertiary), .action({
                                        PopSheet()
                                            .items([
                                                .init(title: "Copy Address", action: {
                                                    UIPasteboard.general.string = location.place
                                                    TKToast.show(msg: "Copied.", style: .success)
                                                }),
                                                .init(title: "Open Map", action: {
                                                    self.openMapWithAddress(address: location.place)
                                                }),
                                            ])
                                            .show()
                                    })]
                                    if location.place.isNotEmpty {
                                        attributes.append(.underline(.single, color: .tertiary))
                                    }
                                    label.attributed.text = locationText + ASAttributedString(string: location.place, with: attributes)
                                }
                            }
                        }
                }
            }
            .apply { [weak self] view in
                guard let self = self else { return }
                self.$memo.addSubscriber { memo in
                    if memo.isEmpty && self.location == nil {
                        view.isHidden = true
                    } else {
                        view.isHidden = false
                    }
                }

                self.$location.addSubscriber { location in
                    if self.memo.isEmpty && location == nil {
                        view.isHidden = true
                    } else {
                        view.isHidden = false
                    }
                }
            }
        }
    }

    func initTableView() {
        tableView = UITableView()
        tableView.backgroundColor = UIColor.white
        tableView.setTopRadius()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 40, right: 0)
        tableView.register(SPreparationCell.self, forCellReuseIdentifier: String(describing: SPreparationCell.self))
        tableView.register(SLessonNotes2Cell.self, forCellReuseIdentifier: String(describing: SLessonNotes2Cell.self))
        tableView.register(SAchievementCell.self, forCellReuseIdentifier: String(describing: SAchievementCell.self))
        tableView.register(SMaterialsCell.self, forCellReuseIdentifier: String(describing: SMaterialsCell.self))
        mainView.addSubview(view: tableView) { make in
            make.top.equalTo(topInfoView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

// MARK: - Data

extension SLessonDetailsController {
    override func initData() {
        navigationBar.title = "\(TimeUtil.changeTime(time: lessonData.getShouldDateTime()).toLocalFormat(Locale.is12HoursFormat() ? "MMM dd, hh:mm a" : "MMM dd, HH:mm"))"
        initListener()
        getNextLesson()
        getPreLesson()
        getLessonShceduleConfig()
    }

    private func initListener() {
        guard let endTime = endTime, let lessonData = lessonData else { return }
        initLessonScheduleListener()
        initHomeworkListener(lessonData: lessonData, endTime: endTime)
        initAchievementListener()
        initMaterialsListener()
    }

    private func getPreLesson() {
        guard let teacherId = lessonData?.teacherId, let studentId = lessonData?.studentId, let time = lessonData?.shouldDateTime, let lessonTypeId = lessonData?.lessonTypeId else { return }
        DatabaseService.collections.lessonSchedule()
            .whereField("teacherId", isEqualTo: teacherId)
            .whereField("studentId", isEqualTo: studentId)
            .whereField("cancelled", isEqualTo: false)
            .whereField("rescheduled", isEqualTo: false)
            .whereField("lessonTypeId", isEqualTo: lessonTypeId)
            .whereField("shouldDateTime", isLessThan: Int(time))
            .order(by: "shouldDateTime", descending: true)
            .getDocuments(source: .server) { snapshot, error in
                if let error = error {
                    logger.error("[获取最后一次上的课] => 失败: \(error)")
                } else {
                    logger.debug("[获取最后一次上的课] => 完成,数量: \(String(describing: snapshot?.documents.count))")
                    if let docs = snapshot?.documents, docs.count > 0, let lesson = TKLessonSchedule.deserialize(from: docs.first?.data()) {
                        logger.debug("[获取最后一次上的课] => 结果: \(lesson.toJSONString() ?? "")")
                        self.preLessonData = lesson
                    } else {
                        logger.debug("[获取最后一次上的课] => 结果为空")
                        self.preLessonData = nil
                    }
                }
            }
    }

    private func getNextLesson() {
        // 获取最后一次上的课
        guard let teacherId = lessonData?.teacherId, let studentId = lessonData?.studentId, let time = lessonData?.shouldDateTime, let lessonTypeId = lessonData?.lessonTypeId else { return }
        logger.debug("[获取下一次上的课] => 开始查询,条件 teacherId[\(teacherId)] | studentId[\(studentId)] | false | false | shouldDateTime[\(time)]")
        DatabaseService.collections.lessonSchedule()
            .whereField("teacherId", isEqualTo: teacherId)
            .whereField("studentId", isEqualTo: studentId)
            .whereField("cancelled", isEqualTo: false)
            .whereField("rescheduled", isEqualTo: false)
            .whereField("lessonTypeId", isEqualTo: lessonTypeId)
            .whereField("shouldDateTime", isGreaterThan: Int(time))
            .order(by: "shouldDateTime", descending: false)
            .limit(to: 1)
            .getDocuments(source: .server) { snapshot, error in
                if let error = error {
                    logger.error("[获取下一次上的课] => 失败: \(error)")
                } else {
                    logger.debug("[获取下一次上的课] => 完成,数量: \(String(describing: snapshot?.documents.count))")
                    if let docs = snapshot?.documents, docs.count > 0, let lesson = TKLessonSchedule.deserialize(from: docs.first?.data()) {
                        logger.debug("[获取下一次上的课] => 结果: \(lesson.toJSONString() ?? "")")
                        self.nextLessonData = lesson
                    } else {
                        logger.debug("[获取下一次上的课] => 结果为空")
                        self.nextLessonData = nil
                    }
                }
            }
    }

    private func initLessonScheduleListener() {
        let id = lessonData.id
        let listener = DatabaseService.collections.lessonSchedule()
            .document(id)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let snapshot = snapshot else {
                    logger.error("监听lesson数据出错：\(String(describing: error))")
                    return
                }
                if let lessonData = TKLessonSchedule.deserialize(from: snapshot.data()) {
                    let practiceData = self.lessonData.practiceData
                    let achievement = self.lessonData.achievement
                    let materials = self.lessonData.materilasData
                    self.lessonData = lessonData
                    self.lessonData.practiceData = practiceData
                    self.lessonData.achievement = achievement
                    self.lessonData.materilasData = materials
                }
                self.checkStudentReadNote()
                self.initLessonNotes()
            }
        listeners.append(listener)
    }

    private func initHomeworkListener(lessonData: TKLessonSchedule, endTime: TimeInterval) {
        logger.debug("[练习记录获取] => 开始,条件 studentId[\(lessonData.studentId)] | startTime[\(lessonData.shouldDateTime)] | endTime[\(endTime)]")
        let listener = DatabaseService.collections.practice()
            .whereField("studentId", isEqualTo: lessonData.studentId)
//            .whereField("startTime", isLessThan: endTime)
            .whereField("startTime", isGreaterThanOrEqualTo: lessonData.shouldDateTime)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, _ in
                guard let self = self else { return }
                guard let snapshot = snapshot else { return }
                let data: SnapshotData<TKPractice> = snapshot.handleSnapshot()
                logger.debug("[练习记录获取] => 结果: \(data.added.count) | \(data.modified.count)")
                self.lessonData.practiceData += data.added
                data.modified.forEach { item in
                    self.lessonData.practiceData.forEachItems { _item, index in
                        if item.id == _item.id {
                            self.lessonData.practiceData[index] = item
                        }
                    }
                }

                data.removed.forEach { item in
                    self.lessonData.practiceData.removeElements { $0.id == item.id }
                }
                self.initHomeworkData()
            }
        listeners.append(listener)
    }

    private func initAchievementListener() {
        guard let lessonData = lessonData else { return }
        let listener = DatabaseService.collections.achievement()
            .whereField("scheduleId", isEqualTo: lessonData.id)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let snapshot = snapshot else {
                    logger.error("监听achievement数据出错：\(String(describing: error))")
                    return
                }

                let data: SnapshotData<TKAchievement> = snapshot.handleSnapshot()
                logger.debug("监听到的所有achievement: \(data.added.toJSONString() ?? "") | \(data.modified.toJSONString() ?? "") | \(data.removed.toJSONString() ?? "")")
                data.added.forEach { item in
                    if !self.lessonData.achievement.contains(where: { $0.id == item.id }) {
                        self.lessonData.achievement += data.added
                    }
                }

                data.modified.forEach { item in
                    self.lessonData.achievement.forEachItems { _item, index in
                        if item.id == _item.id {
                            self.lessonData.achievement[index] = item
                        }
                    }
                }

                data.removed.forEach { item in
                    self.lessonData.achievement.removeElements { $0.id == item.id }
                }
                print("====achievement个数==\(self.lessonData.achievement.count)")
                self.checkStudentReadAchievements()
                self.initAchievement()
            }
        listeners.append(listener)
    }

    private func initMaterialsListener() {
        guard let lessonData = lessonData else { return }
        let listener = DatabaseService.collections.lessonScheduleMaterial()
            .whereField("lessonScheduleId", isEqualTo: lessonData.id)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let snapshot = snapshot else {
                    logger.error("监听用户Materials数据出错： \(String(describing: error))")
                    return
                }
                let data: SnapshotData<TKLessonScheduleMaterial> = snapshot.handleSnapshot()
                self.lessonScheduleMaterialsData += data.added
                data.modified.forEach { item in
                    self.lessonScheduleMaterialsData.forEachItems { _item, index in
                        if item.id == _item.id {
                            self.lessonScheduleMaterialsData[index] = item
                        }
                    }
                }

                data.removed.forEach { item in
                    self.lessonScheduleMaterialsData.removeElements { $0.id == item.id }
                }
                self.checkStudentReadMaterial()
                self.getMaterialsDetails(self.lessonScheduleMaterialsData)
            }
        listeners.append(listener)
    }

    /**
     获取作业
     */
    func getHomeworkData() {
        var isLoad = false
        addSubscribe(
            LessonService.lessonSchedule.getPracticeByStartTimeAndSId(startTime: lessonData.shouldDateTime, endTime: endTime, studentId: lessonData.studentId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
//                    if let data = data[.cache] {
//                        if data.count != 0 {
//                            isLoad = true
                    ////                            self.data[self.selectedPos].preAssignmentData = data
                    ////                            self.tableView.reloadData()
//
//                            self.lessonData.practiceData = data
//                            self.initHomeworkData()
//                        }
//                    }
                    if let data = data[.server] {
                        print("=1===\(data.count)")

//                        if !isLoad {
//                            self.data[self.selectedPos].preAssignmentData = data
//                            self.tableView.reloadData()
//                            self.lessonData.practiceData = data
//                            self.initHomeworkData()
//                        }
                        self.lessonData.practiceData = data
                        self.initHomeworkData()
                    }
                }, onError: { err in
                    logger.debug("======\(err)")
                    //                    self.finishLoading.practiceIsLoadFinsh = true
                    //                    self.refreshView()
                })
        )
    }

    func initHomeworkData() {
//        var data: [TKPractice] = []
        let practiceData = lessonData.practiceData.filterDuplicates({ $0.id })
        logger.debug("合并前的数据: \(practiceData.toJSONString() ?? "")")
        var addedPracticeIds: [String] = []
//        practiceData.forEachItems { item, _ in
//            if item.assignment {
//                var index = -1
//                for newItem in data.enumerated() where newItem.element.lessonScheduleId == item.lessonScheduleId && newItem.element.name == item.name && newItem.element.startTime != item.startTime {
//                    index = newItem.offset
//                }
//                if index >= 0 {
//                    data[index].recordData += item.recordData
//                    if item.done {
//                        data[index].done = true
//                    }
//                    data[index].totalTimeLength += item.totalTimeLength
//                } else {
//                    data.append(item)
//                }
//            } else {
//                data.append(item)
//            }
//        }
        var newData: [TKPractice] = []
        for oldItem in practiceData {
            var pos: Int = -1
            for (i, newItem) in newData.enumerated() {
                if newItem.name == oldItem.name {
                    pos = i
                }
            }
            if pos == -1 {
                if !newData.contains(where: { $0.id == oldItem.id }) {
                    newData.append(oldItem)
                }
            } else {
                if !addedPracticeIds.contains(oldItem.id) {
                    let newItem = newData[pos]
                    newItem.recordData += oldItem.recordData
                    newItem.totalTimeLength = newItem.totalTimeLength + oldItem.totalTimeLength
                    newData[pos] = newItem
                    addedPracticeIds.append(oldItem.id)
                }
            }
        }
        newData = newData.sorted(by: { i1, i2 in
            var time1: TimeInterval = 0
            var time2: TimeInterval = 0
            if let t1 = i1.recordData.sorted(by: { $0.startTime > $1.startTime }).first?.startTime {
                time1 = t1
            } else {
                time1 = i1.startTime
            }
            if let t2 = i2.recordData.sorted(by: { $0.startTime > $1.startTime }).first?.startTime {
                time2 = t2
            } else {
                time2 = i2.startTime
            }
            return time1 > time2
        })
        lessonData.practiceData = newData
        self.practiceData = newData
        logger.debug("重新渲染练习cell: \(cellCount) | \(lessonData.practiceData.toJSONString() ?? "")")
        tableView?.reloadData()
    }

    /// 初始化并Notes
    func initLessonNotes() {
        if (lessonData.teacherNote != "" || lessonData.studentNote != "") && !notesIsShow {
            notesIsShow = true
        } else {
            notesIsShow = false
        }
//        tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        tableView?.reloadData()
    }

    /// 获取Achievement
    func getAchievement() {
        var isLoad = false
        addSubscribe(
            LessonService.lessonSchedule.getAchievementByScheduleId(sId: lessonData.id)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache] {
                        if data.count > 0 {
                            isLoad = true
                            self.lessonData.achievement = data
                            self.initAchievement()
                        }
                    }
                    if let data = data[.server] {
                        if !isLoad {
                            self.lessonData.achievement = data
                            self.initAchievement()
                        }
                    }

                }, onError: { [weak self] err in
                    self?.initAchievement()
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func initAchievement() {
        if lessonData.achievement.count > 0 && !achievementIsShow {
            achievementIsShow = true
        } else {
            achievementIsShow = false
        }
//        tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
        tableView?.reloadData()
    }

    /// 获取Materials
    func getMaterials() {
        var isLoad = false
        addSubscribe(
            LessonService.lessonSchedule.getLessonScheduleMaterialByScheduleId(id: lessonData.id)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache] {
                        if data.count > 0 {
                            isLoad = true
                            let data = data.filterDuplicates({ $0.materialId })
                            self.getMaterialsDetails(data)
                        }
                    }
                    if let data = data[.server] {
                        if !isLoad {
                            let data = data.filterDuplicates({ $0.materialId })
                            self.getMaterialsDetails(data)
                        }
                    }

                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func getMaterialsDetails(_ lessonMaterials: [TKLessonScheduleMaterial]) {
        addSubscribe(
            MaterialService.shared.materialListByTeacher(tId: lessonData.teacherId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }

                    var webData: [TKMaterial] = []
                    for item in docs.documents {
                        if let doc = TKMaterial.deserialize(from: item.data()) {
                            webData.append(doc)
                        }
                    }
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
                    self.lessonData.materilasData = data
                    self.initMaterials()
                }, onError: { err in
                    //                    guard let self = self else { return }

                    logger.debug("======\(err)")
                })
        )
    }

    func initMaterials() {
//        tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .none)
        tableView?.reloadData()
    }
}

// MARK: - TableView

extension SLessonDetailsController: UITableViewDelegate, UITableViewDataSource, SLessonNotesCellDelegate, SAchievementCellDelegate, SMaterialsCellDelegate, SPreparationCellDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    func materialsCell(clickMaterial cell: SMaterialsCell, material: TKMaterial, materialCell: MaterialsCell) {
        logger.debug("跳转到新的页面展示")
        let controller = Materials2ViewController(type: .list, isEdit: false, data: lessonData.materilasData)
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func preparationCell(cell: SPreparationCell) {
        guard let nextLessonData = nextLessonData, let preLessonData = preLessonData, let lessonData = lessonData else { return }
        var practiceDatas: [TKPracticeAssignment] = []
        var practiceData = TKPracticeAssignment()
        let now = Date().timeIntervalSince1970
        if lessonData.shouldDateTime > now {
            logger.debug("当前的课程是没有上的,所以设置起始时间为上一次课:\(preLessonData.shouldDateTime) -> \(now)")
            practiceData.startTime = preLessonData.shouldDateTime
            practiceData.endTime = now
        } else {
            logger.debug("当前课程是上过了的,所以设置起始时间为当前课程: \(lessonData.shouldDateTime) -> \(nextLessonData.shouldDateTime)")
            practiceData.startTime = lessonData.shouldDateTime
            practiceData.endTime = nextLessonData.shouldDateTime
        }
        practiceData.practice = lessonData.practiceData
        logger.debug("设置数据: \(practiceData.toJSONString() ?? "")")
        practiceDatas.append(practiceData)
//        var addedPracticeIds: [String] = []
//        for item in practiceDatas.enumerated() {
//            practiceDatas[item.offset].practice = item.element.practice.filterDuplicates { $0.id }
//        }
//        var _data = practiceDatas
//        for (index, tkAssignment) in _data.enumerated() {
//            var newData: [TKPractice] = []
//            for oldItem in tkAssignment.practice {
//                var pos: Int = -1
//                for (i, newItem) in newData.enumerated() {
//                    if newItem.name == oldItem.name {
//                        pos = i
//                    }
//                }
//                if pos == -1 {
//                    if !newData.contains(where: { $0.id == oldItem.id }) {
//                        newData.append(oldItem)
//                    }
//                } else {
//                    if !addedPracticeIds.contains(oldItem.id) {
//                        let newItem = newData[pos]
//                        newItem.recordData += oldItem.recordData
//                        newItem.totalTimeLength = newItem.totalTimeLength + oldItem.totalTimeLength
//                        newData[pos] = newItem
//                        addedPracticeIds.append(oldItem.id)
//                    }
//                }
//            }
//            _data[index].practice = newData.sorted(by: { i1, i2 in
//                var time1: TimeInterval = 0
//                var time2: TimeInterval = 0
//                if let t1 = i1.recordData.sorted(by: { $0.startTime > $1.startTime }).first?.startTime {
//                    time1 = t1
//                } else {
//                    time1 = i1.startTime
//                }
//                if let t2 = i2.recordData.sorted(by: { $0.startTime > $1.startTime }).first?.startTime {
//                    time2 = t2
//                } else {
//                    time2 = i2.startTime
//                }
//                return time1 > time2
//            })
//        }
//
//        for (index, tkAssignment) in _data.enumerated() {
//            for (j, item) in tkAssignment.practice.enumerated() {
//                _data[index].practice[j].recordData = item.recordData.filterDuplicates({ $0.id })
//            }
//        }
//        logger.debug("即将设置的数据: \(_data.toJSONString() ?? "")")
        let controller = PracticeViewController()
        controller.data = practiceDatas
        controller.hero.isEnabled = true
        controller.isShowIncomplete = nextLessonData.isFirstLesson
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func materialsCell(clickCell cell: SMaterialsCell, cellHeight: CGFloat, isShow: Bool) {
        isShowMaterial = isShow
        tableView.beginUpdates()
        if cellCount == 3 {
            cell3Heights[2] = cellHeight
        } else {
            cell4Heights[3] = cellHeight
        }
        tableView.endUpdates()
    }

    func achievementCell(clickCell cell: SAchievementCell, cellHeight: CGFloat, isShow: Bool) {
        isShowAchievement = isShow
        tableView.beginUpdates()
        if cellCount == 3 {
            cell3Heights[1] = cellHeight
        } else {
            cell4Heights[2] = cellHeight
        }
        tableView.endUpdates()
    }

    func LessonNotesCell(clickCell cell: SLessonNotesCell, cellHeight: CGFloat) {
        tableView.beginUpdates()
        if cellCount == 3 {
            cell3Heights[0] = cellHeight
        } else {
            cell4Heights[1] = cellHeight
        }
        tableView.endUpdates()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if cellCount == 3 {
            return cell3Heights[indexPath.row]
        }
        return cell4Heights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cellCount == 3 {
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SLessonNotes2Cell.self), for: indexPath) as! SLessonNotes2Cell
                cell.tag = indexPath.row
                cell.delegate = self
                cell.loadData(lessonData, newMsg: beforeLessonData.teacherNote != "" && !beforeLessonData.studentReadTeacherNote)
//                cell3Heights[0] = cell.cellHeight + 22
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SAchievementCell.self), for: indexPath) as! SAchievementCell
                cell.tag = indexPath.row
                cell.initData(data: lessonData, isShow: isShowAchievement, isReadAchievement)
                cell.delegate = self
                if achievementIsShow && isAchievementFirst {
                    isAchievementFirst = false
                    achievementCellNeedOpen = true
                }
//                cell3Heights[1] = cell.cellHeight
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SMaterialsCell.self), for: indexPath) as! SMaterialsCell
                cell.tag = indexPath.row
                cell.materialsData = lessonData.materilasData
                cell.getMaterialsHeight()
                cell.newMsg(newMaterials, isShow: isShowMaterial)
                cell.delegate = self
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SPreparationCell.self), for: indexPath) as! SPreparationCell
                cell.tag = indexPath.row
                cell.delegate = self
                lessonData.practiceData = practiceData
                if lessonData.shouldDateTime <= Date().timeIntervalSince1970 {
                    cell.titleLabel.text("Practice after lesson")
                } else {
                    cell.titleLabel.text("Preparation")
                }
                cell.initData(data: lessonData)
                return cell
            }
        } else {
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SPreparationCell.self), for: indexPath) as! SPreparationCell
                cell.tag = indexPath.row
                cell.delegate = self
                if lessonData.shouldDateTime <= Date().timeIntervalSince1970 {
                    cell.titleLabel.text("Practice after lesson")
                } else {
                    cell.titleLabel.text("Preparation")
                }
                if let nextLessonData = nextLessonData {
                    nextLessonData.practiceData = practiceData
                    logger.debug("加载练习cell, 当前练习数据2: \(practiceData.toJSONString() ?? "") \n \(lessonData.practiceData.toJSONString() ?? "")")
                    cell.initData(data: nextLessonData)
                } else {
                    logger.debug("没有练习数据")
                    cell.initDataWithNoneData()
                }
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SLessonNotes2Cell.self), for: indexPath) as! SLessonNotes2Cell
                cell.tag = indexPath.row
                cell.delegate = self
                cell.loadData(lessonData, newMsg: beforeLessonData.teacherNote != "" && !beforeLessonData.studentReadTeacherNote)
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SAchievementCell.self), for: indexPath) as! SAchievementCell
                cell.tag = indexPath.row
                cell.initData(data: lessonData, isShow: isShowAchievement, isReadAchievement)
                cell.delegate = self
                if achievementIsShow && isAchievementFirst {
                    isAchievementFirst = false
                    achievementCellNeedOpen = true
                }
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SMaterialsCell.self), for: indexPath) as! SMaterialsCell
                cell.tag = indexPath.row
                cell.materialsData = lessonData.materilasData
                cell.getMaterialsHeight()
                cell.newMsg(newMaterials, isShow: isShowMaterial)
                cell.delegate = self
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SPreparationCell.self), for: indexPath) as! SPreparationCell
                cell.tag = indexPath.row
                cell.delegate = self
                lessonData.practiceData = practiceData
                logger.debug("加载练习cell, 当前练习数据1: \(practiceData.toJSONString() ?? "") \n \(lessonData.practiceData.toJSONString() ?? "")")
                cell.initData(data: lessonData)
                return cell
            }
        }
    }
}

extension SLessonDetailsController: SLessonNotes2CellDelegate {
    func sLessonNotes2Cell(heightChanged height: CGFloat) {
        tableView.beginUpdates()
        if cellCount == 3 {
            cell3Heights[0] = height
        } else {
            cell4Heights[1] = height
        }
        tableView.endUpdates()
    }

    func sLessonNotes2Cell(studentNotesChanged notes: String, height: CGFloat) {
        tableView.beginUpdates()
        lessonData.studentNote = notes
        if cellCount == 3 {
            cell3Heights[0] = height
        } else {
            cell4Heights[1] = height
        }
        tableView.endUpdates()
    }

    func sLessonNotes2Cell(noteUpdated note: String) {
        guard note.trimmingCharacters(in: .whitespacesAndNewlines) != "" else { return }
        updateLessonschedule(data: ["studentNote": note])
    }

    /// 更新lessonSchedul
    /// - Parameter data: 要更新的数据
    func updateLessonschedule(data: [String: Any]) {
        addSubscribe(
            LessonService.lessonSchedule
                .updateLessonSchedule(lessonScheduleId: lessonData.id, data: data)
                .subscribe(onNext: { _ in
                }, onError: { err in
                    logger.debug("====更新Schedule失败=\(err)")
                })
        )
    }
}

extension SLessonDetailsController {
    func openMapWithAddress(address: String) {
        // 使用 CLGeocoder 将地址字符串转换成地理坐标
        logger.debug("解析地址：\(address)")
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            // 处理可能的错误
            if let error = error {
                logger.error("Geocoding error: \(error)")
                return
            }

            if let placemark = placemarks?.first {
                // 使用地标创建一个 MKMapItem
                let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                mapItem.name = address // 可以指定地图项的名称

                // 设置启动地图应用时的选项
                let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]

                // 打开系统地图应用并显示该地址
                mapItem.openInMaps(launchOptions: launchOptions)
            }
        }
    }
}
