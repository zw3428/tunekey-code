//
//  StudentPendingNewLessonsViewController.swift
//  TuneKey
//
//  Created by 砚枫张 on 2023/9/1.
//  Copyright © 2023 spelist. All rights reserved.
//

import SnapKit
import UIKit

class StudentPendingNewLessonsViewController: TKBaseViewController {
    private lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "New lesson")
    private var followUps: [TKFollowUp] = []
    private var teacherUsers: [String: TKUser] = [:]
    private var lessonTypes: [String: TKLessonType] = [:]

    private lazy var tableView: UITableView = makeTableView()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runOnce { [weak self] in
            guard let self = self else { return }
            self.reloadData()
        }
    }
}

extension StudentPendingNewLessonsViewController {
    private func makeTableView() -> UITableView {
        TableView().separatorStyle(.none)
            .dataSource(self)
            .delegate(self)
            .backgroundColor(ColorUtil.backgroundColor)
            .apply { tableView in
                tableView.z.register(cell: ItemTableViewCell.self)
            }
    }
}

extension StudentPendingNewLessonsViewController {
    override func initView() {
        super.initView()
        navigationBar.updateLayout(target: self)
        tableView.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    func reloadData() {
        navigationBar.startLoading()
        followUps = ListenerService.shared.studentData.followUps.filter({ $0.dataType == .studentLessonConfigRequests && $0.status == .pending })
        tableView.reloadData()
        akasync { [weak self] in
            guard let self = self else { return }
            let teacherIds = followUps.compactMap({ $0.studentLessonConfigRequest?.config.teacherId }).filter({ $0.isNotEmpty })
            var willLoadTeacherIds: [String] = []
            for teacherId in teacherIds {
                if !self.teacherUsers.keys.contains(teacherId) {
                    willLoadTeacherIds.append(teacherId)
                }
            }

            if willLoadTeacherIds.isNotEmpty {
                let teacherUsers = try akawait(UserService.user.getUsersInfo(ids: willLoadTeacherIds))
                for (userId, teacherUser) in teacherUsers {
                    self.teacherUsers[userId] = teacherUser
                }
            }

            let lessonTypeIds = followUps.compactMap({ $0.studentLessonConfigRequest?.config.lessonTypeId }).filter({ $0.isNotEmpty })
            var willLoadLessonTypeIds: [String] = []
            for lessonTypeId in lessonTypeIds {
                if !self.lessonTypes.keys.contains(lessonTypeId) {
                    willLoadLessonTypeIds.append(lessonTypeId)
                }
            }

            if willLoadLessonTypeIds.isNotEmpty {
                let lessonTypes = try akawait(LessonService.lessonType.getByIds(ids: willLoadLessonTypeIds))
                for lessonType in lessonTypes {
                    self.lessonTypes[lessonType.id] = lessonType
                }
            }

            updateUI {
                self.navigationBar.stopLoading()
                self.tableView.reloadData()
            }
        }
    }

    override func bindEvent() {
        super.bindEvent()
        EventBus.listen(key: .studentFollowUpsChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.reloadData()
        }
    }
}

extension StudentPendingNewLessonsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        followUps.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ItemTableViewCell = tableView.z.dequeueReusableCell(for: indexPath)
        let followUp = followUps[indexPath.row]
        if let lessonConfig = followUp.studentLessonConfigRequest?.config {
            cell.startDateTime = lessonConfig.startDateTime
            var lessonDetailStrings: [String] = []
            if let lessonType = lessonTypes[lessonConfig.lessonTypeId] {
                lessonDetailStrings.append(lessonType.name)
            }
            switch lessonConfig.repeatType {
            case .none, .monthly:
                lessonDetailStrings.append("No repeat")
            case .weekly:
                lessonDetailStrings.append("Weekly")
            case .biWeekly:
                lessonDetailStrings.append("Bi-weekly")
            }
            if lessonConfig.repeatType == .weekly || lessonConfig.repeatType == .biWeekly {
                let diff = TimeUtil.getUTCWeekdayDiffV2(timestamp: Int(lessonConfig.startDateTime))
                var weekdays: [Int] = []
                for day in lessonConfig.repeatTypeWeekDay {
                    var _day = day - diff
                    if _day < 0 {
                        _day = 6
                    } else if _day > 6 {
                        _day = 0
                    }
                    weekdays.append(_day)
                }
                lessonDetailStrings.append(weekdays.sorted(by: { $0 < $1 }).compactMap({ TimeUtil.getWeekDayShotName(weekDay: $0) }).joined(separator: ", "))
            }
            cell.lessonDetailInfo = lessonDetailStrings.joined(separator: ", ")
            cell.teacherName = teacherUsers[lessonConfig.teacherId]?.name ?? ""
        }
        cell.onCancelTapped = { [weak self] in
            guard let self = self else { return }
            self.cancelPendingFollowUp(followUp)
        }

        return cell
    }

    private func cancelPendingFollowUp(_ followUp: TKFollowUp) {
        SL.Alert.show(target: self, title: "Cancel lesson?", message: "The instructor of the lesson you applied for has not confirmed yet, are you sure you want to cancel it? If you sure, after cancellation, you can reapply for any lesson you want to learn.", leftButttonString: "Cancel", rightButtonString: "Go back", leftButtonColor: ColorUtil.red, rightButtonColor: .clickable) { [weak self] in
            self?.submitCancelPendingFollowUp(followUp)
        } rightButtonAction: {
        } onShow: { alert in
            alert.leftButton.text = "CANCEL"
        }
    }

    private func submitCancelPendingFollowUp(_ followUp: TKFollowUp) {
        logger.debug("提交取消课程申请: \(followUp.toJSONString() ?? "")")
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller("scheduleService-studentCancelRequestedLesson")
            .appendData(key: "id", value: followUp.id)
            .call { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    logger.error("取消失败: \(error)")
                    TKToast.show(msg: "Cancel lesson failed, please try again later.", style: .error)
                } else {
                    self.followUps.removeElements({ $0.id == followUp.id })
                    self.tableView.reloadData()
                }
            }
    }
}

extension StudentPendingNewLessonsViewController {
    class ItemTableViewCell: TKBaseTableViewCell {
        @Live var startDateTime: TimeInterval = 0
        @Live var lessonDetailInfo: String = ""
        @Live var teacherName: String = ""

        var onCancelTapped: VoidFunc?

        override func initViews() {
            super.initViews()
            ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
                ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                    VStack(spacing: 15) {
                        HStack(alignment: .center) {
                            Label("Pending").textColor(.tertiary)
                                .font(.cardTitle)
                            Button().title("Cancel", for: .normal)
                                .titleColor(.clickable, for: .normal)
                                .font(.cardTopButton)
                                .onTapped { [weak self] _ in
                                    self?.onCancelTapped?()
                                }
                        }
                        HStack(spacing: 15) {
                            VStack {
                                Label().textColor(.primary)
                                    .font(.bold(32))
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$startDateTime.addSubscriber { startDateTime in
                                            label.text(startDateTime.toLocalFormat("dd"))
                                        }
                                    }
                                Label().textColor(.primary)
                                    .font(.content)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$startDateTime.addSubscriber { startDateTime in
                                            label.text(startDateTime.toLocalFormat("MMM"))
                                        }
                                    }
                                View().backgroundColor(.clear)
                                    .contentHuggingPriority(.defaultLow, for: .vertical)
                                    .contentCompressionResistancePriority(.defaultLow, for: .vertical)
                            }.width(50)

                            VStack(spacing: 10) {
                                Label().textColor(.primary)
                                    .font(.content)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$startDateTime.addSubscriber { startDateTime in
                                            label.text(startDateTime.toLocalFormat("EEE, hh:mm a"))
                                        }
                                    }
                                Label($lessonDetailInfo)
                                    .textColor(.tertiary)
                                    .font(.content)
                                    .numberOfLines(0)
                                Label($teacherName)
                                    .textColor(.tertiary)
                                    .font(.content)
                            }
                        }
                    }
                }.cardStyle()
            }
            .backgroundColor(ColorUtil.backgroundColor)
            .fill(in: contentView)
        }
    }
}
