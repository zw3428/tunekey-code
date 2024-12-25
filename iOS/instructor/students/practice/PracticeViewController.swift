//
//  PracticeViewController.swift
//  TuneKey
//
//  Created by Wht on 2019/8/22.
//  Copyright © 2019年 spelist. All rights reserved.
//
import DZNEmptyDataSet
import FirebaseFirestore
import MJRefresh
import PromiseKit
import RxSwift
import SnapKit
import UIKit

class PracticeViewController: TKBaseViewController {
    enum PracticeViewType {
        case studentDetail
        case lessonDetail
    }

    private var mainView = UIView()
    private var navigationBar: TKNormalNavigationBar!
    private var collectionView: UICollectionView!
    private var tableView: UITableView!
    var practiceData: [TKPractice] = []
    var data: [TKPracticeAssignment] = []
    var type: PracticeViewType = .lessonDetail
    var teacherId: String = ""
    var studentId: String = ""
    private var startTime: Int = 0
    private var endTime: Int = 0
    private var isLRefresh = false
    // 上一次加载的个数
    private var previousCount: Int = 0
    // 上上次
    private var previousPreviousCount: Int = 0
    private var isFirst = true
    var isShowIncomplete = false
    var addedPracticeIds: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView?.reloadData()
    }
}

// MARK: - View

extension PracticeViewController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "Practice", target: self)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initTableView()
    }

    func initTableView() {
        tableView = UITableView()
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        mainView.addSubview(tableView)
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.emptyDataSetSource = self
        tableView.register(PracticeCellV2.self, forCellReuseIdentifier: String(describing: PracticeCellV2.self))
        if type == .studentDetail {
            let footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
                guard let self = self else { return }
                self.isLRefresh = true
                self.endTime = self.startTime
                self.startTime = TimeUtil.endOfMonth(date: TimeUtil.changeTime(time: Double(self.startTime)).add(component: .month, value: -3)).timestamp
                self.getLessonData()
            })
//            footer.setTitle("Drag up to refresh", for: .idle)
            footer.setTitle("", for: .idle)

            footer.setTitle("Loading more...", for: .refreshing)
            footer.setTitle("No more lessons", for: .noMoreData)
            footer.stateLabel?.font = FontUtil.regular(size: 15)
            footer.stateLabel?.textColor = ColorUtil.Font.primary
            tableView.mj_footer = footer
            tableView.mj_footer!.isHidden = true
        }
    }
}

extension PracticeViewController: UITableViewDelegate, UITableViewDataSource, PracticeCellV2Delegate {
    func practiceCellV2(cellDidTapped cell: PracticeCellV2, data: TKPracticeAssignment) {
        var totalTime: CGFloat = 0
        for item in data.practice {
            totalTime += item.totalTimeLength
        }
        logger.debug("totalTime: \(totalTime) => \((totalTime / 3600).roundTo(places: 1))")
        guard totalTime > 0 else { return }
        if studentId == "" {
            for item in data.practice {
                if item.studentId != "" {
                    studentId = item.studentId
                    break
                }
            }
        }

        let controller = PracticeDetailViewController(data, studentId: studentId)
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func practiceCellV2(clickPlay cell: PracticeCellV2, data: TKPractice) {
//        let controller = PlayAudiodController()
//        controller.data = data
        let controller = TKPracticeRecordingListViewController(data, style: .teacherView)
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PracticeCellV2.self), for: indexPath) as! PracticeCellV2
        cell.tag = indexPath.row
        cell.delegate = self
        let item = data[indexPath.row]
        if type == .studentDetail {
            cell.initData(data: item, isShowIncomplete: indexPath.row == 0 ? true : false)
        } else {
            cell.initData(data: item, isShowIncomplete: isShowIncomplete)
        }
        return cell
    }
}

extension PracticeViewController: DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "practice_empty")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        Tools.attributenStringColor(text: "No practice log yet!\nTo practice more motivate to learn more.", selectedText: "", allColor: ColorUtil.Font.fourth, selectedColor: ColorUtil.Font.fourth, font: FontUtil.regular(size: 17), fontSize: 17)
    }
}

// MARK: - Data

extension PracticeViewController {
    override func initData() {
        let date = Date()
        if endTime == 0 {
            endTime = date.timestamp
        }
//        if startTime == 0 {
//            startTime = date.add(component: .year, value: -3).timestamp
//        }
        startTime = 0
        logger.debug("当前的联系数据: \(self.practiceData.count)")
        if type == .studentDetail {
            logger.debug("查看学生练习详情")
            getLessonData()
        } else {
            navigationBar.startLoading()
            getLessonDataForStudent()
        }
    }

    func getLessonDataForStudent() {
        guard data.count > 1 else {
            logger.debug("数据数量为空")
            navigationBar.stopLoading()
            return
        }
        let studentId: String = data.first?.practice.first?.studentId ?? ""
        let startTime: TimeInterval = data.first?.startTime ?? 0
        let endTime: TimeInterval = data.first?.endTime ?? 0
        data[0].practice = []
        tableView.reloadData()
        logger.debug("准备计算的参数: \(studentId) - \(Date(seconds: startTime).toLocalFormat("yyyy-MM-dd")) - \(Date(seconds: endTime).toLocalFormat("yyyy-MM-dd"))")
        getPracticeData(studentId, startTime: startTime, endTime: endTime)
            .done { [weak self] practice in
                guard let self = self else { return }
                var addedPracticeIds: [String] = []
                var newData: [TKPractice] = []
                for oldItem in practice {
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
                self.data[0].practice = newData
                self.tableView.reloadData()
                self.navigationBar.stopLoading()
            }
            .catch { error in
                logger.error("获取练习数据失败: \(error)")
            }
    }

    func getPracticeData(_ studentId: String, startTime: TimeInterval, endTime: TimeInterval) -> Promise<[TKPractice]> {
        return Promise { resolver in
            DatabaseService.collections.practice()
                .whereField("studentId", isEqualTo: studentId)
                .whereField("startTime", isGreaterThan: startTime)
                .whereField("startTime", isLessThanOrEqualTo: endTime)
                .getDocuments { snapshot, error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        if let data = [TKPractice].deserialize(from: snapshot?.documents.compactMap { $0.data() }) as? [TKPractice] {
                            resolver.fulfill(data)
                        } else {
                            resolver.fulfill([])
                        }
                    }
                }
        }
    }

    func getLessonData() {
        guard let user = ListenerService.shared.user else { return }
        logger.debug("当前用户版本: \(user.currentUserDataVersion)")
        switch user.currentUserDataVersion {
        case .unknown(version: _):
            return
        case .singleTeacher:
            getLessonDataV1()
        case .studio:
            getLessonDataV2()
        }
    }
    
    func getLessonDataV1() {
        navigationBar.startLoading()
        logger.debug("加载数据: \(teacherId) | \(studentId) | \(startTime) | \(endTime)")

        addSubscribe(
            LessonService.lessonSchedule.getScheduleListByTeacherIdAndStudentId(teacherId: teacherId, studentId: studentId, startTime: startTime, endTime: endTime, isCache: false)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    self.tableView.mj_footer?.isHidden = false
                    
                    var data: [TKLessonSchedule] = []
                    for doc in docs.documents {
                        if let doc = TKLessonSchedule.deserialize(from: doc.data()) {
                            if doc.rescheduled && doc.rescheduleId != "" || doc.cancelled {
                                continue
                            }
                            data.append(doc)
                        }
                    }

                    data.sort { (a, b) -> Bool in
                        a.shouldDateTime > b.shouldDateTime
                    }
                    logger.debug("获取到的课程总量: \(docs.count) | 过滤后的数量: \(data.count)")
                    self.initShowData(lessonData: data)
                    self.navigationBar.stopLoading()
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.navigationBar.stopLoading()
                    if self.tableView.mj_footer != nil {
                        self.tableView.mj_footer!.isHidden = false
                    }
                    logger.debug("获取失败:\(err)")
                })
        )
    }
    
    func getLessonDataV2() {
        guard let studioId = ListenerService.shared.studioManagerData.studio?.id else { return }
        LessonService.lessonSchedule.getLessonSchedule(withStudioId: studioId, studentId: studentId, startTime: TimeInterval(startTime), endTime: TimeInterval(endTime))
            .done { [weak self] data in
                guard let self = self else { return }
                self.initShowData(lessonData: data)
                self.navigationBar.stopLoading()
                if data.isEmpty {
                    self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                }
            }
            .catch { error in
                self.navigationBar.stopLoading()
                if self.tableView.mj_footer != nil {
                    self.tableView.mj_footer!.isHidden = false
                }
                logger.error("获取失败: \(error)")
            }
    }

    func initShowData(lessonData: [TKLessonSchedule]) {
        logger.debug("课程数量: \(lessonData.count)")
        if lessonData.isEmpty {
            var showData = TKPracticeAssignment()
            let startDateTime = practiceData.sorted(by: { $0.startTime > $1.startTime }).first?.startTime ?? 0
            showData.startTime = startDateTime
            showData.endTime = -1
            logger.debug("showData end time: \(showData.endTime)")
            for practiceItem in practiceData.enumerated().reversed() where practiceItem.element.startTime >= startDateTime && practiceItem.element.startTime <= (showData.endTime == -1 ? Date().timeIntervalSince1970 : showData.endTime) {
                if practiceItem.element.teacherId == "" || practiceItem.element.teacherId == teacherId {
                    showData.practice.append(practiceItem.element)
                    practiceData.remove(at: practiceItem.offset)
                }
            }
            self.previousCount += 1
            data.append(showData)
        } else {
            // 自己的end 是上一条的start - 1天
            lessonData.forEachItems { item, offset in
                var showData = TKPracticeAssignment()
                let startDateTime = TimeUtil.changeTime(time: item.shouldDateTime).timeIntervalSince1970
                showData.startTime = item.shouldDateTime
                if offset == 0 {
                    showData.endTime = -1
                } else {
                    showData.endTime = lessonData[offset - 1].shouldDateTime
                }
                logger.debug("showData end time: \(showData.endTime)")
                for practiceItem in practiceData.enumerated().reversed() where practiceItem.element.startTime >= startDateTime && practiceItem.element.startTime <= (showData.endTime == -1 ? Date().timeIntervalSince1970 : showData.endTime) {
                    if practiceItem.element.teacherId == "" || practiceItem.element.teacherId == teacherId {
                        showData.practice.append(practiceItem.element)
                        practiceData.remove(at: practiceItem.offset)
                    }
                }
                self.previousCount += 1
                data.append(showData)
            }
        }
        logger.debug("合并之前: \(data.compactMap({ (Date(seconds: $0.startTime).toLocalFormat("yyyy-MM-dd"), $0.practice.count) }))")
        for (index, tkAssignment) in data.enumerated() {
            var newData: [TKPractice] = []
            for oldItem in tkAssignment.practice {
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
            data[index].practice = newData.sorted(by: { i1, i2 in
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
        }

        // 过滤练习数据

        for (index, tkAssignment) in data.enumerated() {
            for (j, item) in tkAssignment.practice.enumerated() {
                data[index].practice[j].recordData = item.recordData.filterDuplicates({ $0.id })
            }
        }

        if tableView.mj_footer != nil {
            tableView.mj_footer!.endRefreshing()
            if isLRefresh {
                if previousCount + previousPreviousCount == 0 {
                    tableView.mj_footer!.endRefreshingWithNoMoreData()
                } else {
                    tableView.mj_footer!.resetNoMoreData()
                }
            } else {
                tableView.mj_footer!.resetNoMoreData()
            }
        }
        previousPreviousCount = previousCount
        previousCount = 0
        tableView.reloadData()
    }
}
