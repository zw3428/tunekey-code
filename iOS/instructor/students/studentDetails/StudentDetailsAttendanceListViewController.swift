//
//  StudentDetailsAttendanceListViewController.swift
//  TuneKey
//
//  Created by zyf on 2023/1/13.
//  Copyright © 2023 spelist. All rights reserved.
//

import FirebaseFirestore
import MJRefresh
import SnapKit
import SwiftDate
import UIKit

class StudentDetailsAttendanceListViewController: TKBaseViewController {
    private var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Attendance")

    private lazy var tableView: UITableView = makeTableView()

    private var startTime: TimeInterval = Date().add(component: .month, value: -2).timeIntervalSince1970
    private var endTime: TimeInterval = Date().timeIntervalSince1970

    var student: TKStudent
    var lessonSchedules: [TKLessonSchedule] = []
    init(_ student: TKStudent) {
        self.student = student
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isDataLoaded: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
}

extension StudentDetailsAttendanceListViewController {
    private func makeTableView() -> UITableView {
        let tableView = UITableView()
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.register(AttendanceItemTableViewCell.self, forCellReuseIdentifier: AttendanceItemTableViewCell.id)
        tableView.dataSource = self
        tableView.delegate = self
        let footer = MJRefreshAutoNormalFooter { [weak self] in
            guard let self = self else { return }
            logger.debug("之前的startTime: \(self.startTime) | \(self.endTime)")
            self.endTime = self.startTime
            self.startTime = self.endTime - 2.months.timeInterval
            logger.debug("之后的startTime: \(self.startTime) | \(self.endTime)")
            self.fetchData()
        }
        footer.isRefreshingTitleHidden = true
        footer.setTitle("", for: .idle)
        footer.setTitle("Loading more...", for: .refreshing)
        footer.setTitle("", for: .noMoreData)
        footer.stateLabel?.font = FontUtil.regular(size: 15)
        footer.stateLabel?.textColor = ColorUtil.Font.primary
        tableView.mj_footer = footer
        return tableView
    }
}

extension StudentDetailsAttendanceListViewController {
    override func initView() {
        super.initView()
        enablePanToDismiss()
        navigationBar.updateLayout(target: self)
        tableView.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

extension StudentDetailsAttendanceListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AttendanceItemTableViewCell.id, for: indexPath) as! AttendanceItemTableViewCell
        cell.selectionStyle = .none
        let lesson = lessonSchedules[indexPath.row]
        let date = Date(seconds: lesson.shouldDateTime)
        cell.day = date.toLocalFormat("d")
        cell.month = date.toLocalFormat("MMM")
        cell.time = date.toLocalFormat("EEE, h:mm a")
        cell.attendance = lesson.attendance
        cell.contentView.onViewTapped { _ in
//            PopSheet().items([
//                .init(title: "Update Attendance") { [weak self] in
//                    guard let self = self, let lesson = lessonSchedules[safe: indexPath.row] else { return }
//                    self.updateAttendance(lesson)
//                },
//            ])
//            .show()
            
            let controller = StudioLessonDetailViewController([lesson], defaultIndex: 0)
            controller.enableHero()
            Tools.getTopViewController()?.present(controller, animated: true)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lessonSchedules.count
    }


    private func updateAttendance(_ lessonSchedule: TKLessonSchedule) {
        PopSheet().items([
            .init(title: "No-show") { [weak self] in
                guard let self = self else { return }
                self.showNoShowReason(for: lessonSchedule) { reason in
                    self.saveReportNoshowNote(for: lessonSchedule, note: reason)
                }
            },
            .init(title: "Late") { [weak self] in
                guard let self = self else { return }
                self.saveReportAttendance(for: lessonSchedule, attendance: "Late")
            },
            .init(title: "Present") { [weak self] in
                guard let self = self else { return }
                self.saveReportAttendance(for: lessonSchedule, attendance: "Present")
            },
        ]).show()
    }

    private func showNoShowReason(for lessonSchedule: TKLessonSchedule, completion: @escaping (String) -> Void) {
        let controller = TextFieldAndListViewController()
        controller.placeholder = "Note (optional)"
        controller.titleString = "Report attendance"
        controller.list = ["Late", "Unexcused", "Excused (Holiday)", "Excused (Weather)", "Excused (Medical situation)"]
        controller.text = ""
        present(controller, animated: true)
        controller.onLeftButtonTapped = { _ in
            controller.dismiss(animated: true)
        }

        controller.onRightButtonTapped = { text in
            controller.dismiss(animated: true) {
                completion(text)
            }
        }
    }

    private func saveReportNoshowNote(for lessonSchedule: TKLessonSchedule, note: String) {
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller().name("scheduleService-reportNoShow")
            .appendData(key: "lessonId", value: lessonSchedule.id)
            .appendData(key: "noShowUserIds", value: [lessonSchedule.studentId])
            .call { [weak self] result, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    TKToast.show(msg: "Report no-show failed, please try again later.", style: .error)
                    logger.error("report no-show失败: \(error)")
                } else {
                    if let funcResult = FuncResult.deserialize(from: result?.data as? [String: Any]), funcResult.code == 0, let followUp = TKFollowUp.deserialize(from: funcResult.data as? [String: Any]) {
                        let type: TKLessonSchedule.Attendance.AttendanceType
                        if note.lowercased().contains("unexcused") {
                            type = .unexcused
                        } else {
                            type = .excused
                        }
                        lessonSchedule.attendance = [.init(id: "", userId: "", type: type, note: note, createTime: .now)]
                        self.showReportedNoShow(followUp: followUp)
                    }
                    self.tableView.reloadData()
                }
            }
    }

    private func saveReportAttendance(for lessonSchedule: TKLessonSchedule, attendance: String) {
        logger.debug("report attendance: \(lessonSchedule.id) -> \(attendance)")
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller().name("scheduleService-reportAttendanceNote")
            .appendData(key: "lessonId", value: lessonSchedule.id)
            .appendData(key: "note", value: attendance)
            .call { [weak self] result, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    TKToast.show(msg: "Report attendance failed, please try again later.", style: .error)
                    logger.error("存储失败: \(error)")
                } else {
                    if let funcResult = FuncResult.deserialize(from: result?.data as? [String: Any]), let attendance = TKLessonSchedule.Attendance.deserialize(from: funcResult.data as? [String: Any]) {
                        lessonSchedule.attendance = [attendance]
                    }
                    self.tableView.reloadData()
                }
            }
    }

    private func showReportedNoShow(followUp: TKFollowUp) {
        let controller = StudioLessonReportedNoShowViewController()
        present(controller, animated: true)

        controller.onDoneTapped = {
            logger.debug("点击Done")
            controller.dismiss(animated: true)
        }

        controller.onFollowUpsTapped = { [weak self] in
            guard let self = self else { return }
            controller.dismiss(animated: true) {
                self.jumpToFollowUpsViewController()
            }
        }
    }

    private func jumpToFollowUpsViewController() {
        let controller = StudioCalendarFollowUpsViewController()
        controller.enableHero()
        Tools.getTopViewController()?.present(controller, animated: true, completion: nil)
    }
}

extension StudentDetailsAttendanceListViewController {
    private func loadData() {
        guard !isDataLoaded else { return }
        isDataLoaded = true
        fetchData()
    }

    private func fetchData() {
        logger.debug("获取attendance: \(startTime) - \(endTime)")
        navigationBar.startLoading()
        var query: Query = DatabaseService.collections.lessonSchedule()
            .whereField("studentId", isEqualTo: student.studentId)
        if student.studioId.isEmpty {
            logger.debug("老版本数据查询")
            query = query.whereField("teacherId", isEqualTo: student.teacherId)
        } else {
            logger.debug("新版本数据查询")
            query = query.whereField("studioId", isEqualTo: student.studioId)
        }
        query.whereField("shouldDateTime", isLessThanOrEqualTo: endTime)
            .whereField("shouldDateTime", isGreaterThan: startTime)
            .order(by: "shouldDateTime", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.navigationBar.stopLoading()
                if let error = error {
                    self.tableView.mj_footer?.endRefreshing()
                    logger.error("获取课程失败: \(error)")
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                } else {
                    if let documents = snapshot?.documents, let data: [TKLessonSchedule] = [TKLessonSchedule].deserialize(from: documents.compactMap({ $0.data() })) as? [TKLessonSchedule] {
                        let result = data.filter({ (!$0.rescheduled && $0.rescheduleId == "") || $0.cancelled })
                        self.lessonSchedules += result
                        if result.isEmpty {
                            self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                        } else {
                            self.tableView.mj_footer?.endRefreshing()
                        }
                    } else {
                        self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                        self.lessonSchedules = []
                    }
                    self.tableView.reloadData()
                }
                self.tableView.reloadData()
            }
    }
}

extension StudentDetailsAttendanceListViewController {
    class AttendanceItemTableViewCell: UITableViewCell {
        static let id: String = String(describing: AttendanceItemTableViewCell.self)

        @Live var day: String = ""
        @Live var month: String = ""

        @Live var time: String = ""
        @Live var attendance: [TKLessonSchedule.Attendance] = []

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initView()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func initView() {
            ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
                ViewBox(paddings: UIEdgeInsets(top: 20, left: 30, bottom: 20, right: 20)) {
                    HStack(alignment: .top, spacing: 30) {
                        VStack {
                            Label($day).textColor(ColorUtil.main)
                                .font(FontUtil.bold(size: 40))
                                .size(height: 30)
                                .textAlignment(.center)
                                .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                                .contentHuggingPriority(.defaultHigh, for: .vertical)
                                .contentCompressionResistancePriority(.defaultHigh, for: .vertical)
                            Label($month).textColor(ColorUtil.main)
                                .font(FontUtil.medium(size: 20))
                                .size(height: 25)
                                .textAlignment(.center)
                                .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                                .contentHuggingPriority(.defaultHigh, for: .vertical)
                                .contentCompressionResistancePriority(.defaultHigh, for: .vertical)
                            View().backgroundColor(.clear)
                                .contentHuggingPriority(.defaultLow, for: .vertical)
                                .contentCompressionResistancePriority(.defaultLow, for: .vertical)
                        }
                        VStack(spacing: 10) {
                            Label($time).textColor(ColorUtil.Font.third)
                                .font(FontUtil.bold(size: 18))
                            VList(withData: $attendance) { attendance in
                                for attendanceItem in attendance.sorted(by: { $0.createTime > $1.createTime }) {
                                    HStack {
                                        Label(attendanceItem.type.title).textColor(attendanceItem.type.color)
                                            .font(FontUtil.bold(size: 13))
                                            .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                            .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                                        Label(Date(seconds: attendanceItem.createTime).toLocalFormat("h:mm a, M/d/yyyy"))
                                            .textColor(ColorUtil.Font.primary)
                                            .font(FontUtil.regular(size: 13))
                                            .textAlignment(.right)
                                            .contentHuggingPriority(.defaultLow, for: .horizontal)
                                            .contentCompressionResistancePriority(.defaultLow, for: .horizontal)
                                    }
                                }
                            }.apply { [weak self] view in
                                guard let self = self else { return }
                                self.$attendance.addSubscriber { attendance in
                                    view.isHidden = attendance.isEmpty
                                }
                            }

                            Label("Normal").textColor(ColorUtil.main)
                                .font(FontUtil.bold(size: 13))
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$attendance.addSubscriber { attendance in
                                        label.isHidden = !attendance.isEmpty
                                    }
                                }
                        }
                        HStack(alignment: .center) {
                            ImageView.iconArrowRight().size(width: 22, height: 22)
                        }
                    }
                }.apply { view in
                    _ = view.showShadow()
                        .borderWidth(1)
                        .borderColor(ColorUtil.borderColor)
                        .backgroundColor(.white)
                        .cornerRadius(5)
                }
            }.addTo(superView: contentView) { make in
                make.top.left.right.bottom.equalToSuperview()
            }
        }
    }
}
