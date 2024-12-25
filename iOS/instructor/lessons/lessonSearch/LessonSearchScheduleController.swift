//
//  LessonSearchScheduleController.swift
//  TuneKey
//
//  Created by wht on 2020/4/2.
//  Copyright © 2020 spelist. All rights reserved.
//

import MJRefresh
import UIKit

class LessonSearchScheduleController: TKBaseViewController {
    private var mainView = UIView()
    private var navigationBar: TKNormalNavigationBar!
    private var tableView: UITableView!
    private var studentView: TKView!
    private var studentAvatarView: TKAvatarView!
    private var studentNameLabel: TKLabel!
    private var studentContactLabel: TKLabel!
    var scheduleConfigs: [TKLessonScheduleConfigure] = []
    var data: [TKLessonSchedule] = []
    var studentData: TKStudent!

    private let dateFormatter = DateFormatter()

    private var lessonTypes: [TKLessonType]! = []
    private var currentSelectTimestamp = 0
    private var startTimestamp = 0
    private var endTimestamp = 0
    // 全部获取的日程
    private var lessonSchedule: [TKLessonSchedule] = []

    // 用来存储已经存到本地的lessson
    private var lessonScheduleIdMap: [String: String] = [:]

    private var previousEndDate: Date!
    let teacherID = UserService.user.id()!
    var isShowSkeleton = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isShowSkeleton {
            isShowSkeleton = true
            logger.debug("======1111")
        }
    }
}

// MARK: - View

extension LessonSearchScheduleController {
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
        initStudentView()
        initTableView()
    }

    func initStudentView() {
        studentView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow()
            .corner(size: 5)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(navigationBar.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(94)
            })
        studentAvatarView = TKAvatarView()
        studentAvatarView.setSize(size: 60)

        studentView.addSubview(view: studentAvatarView) { make in
            make.size.equalTo(60)
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        studentNameLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.bold(size: 18))
            .addTo(superView: studentView, withConstraints: { make in
                make.left.equalTo(studentAvatarView.snp.right).offset(20)
                make.top.equalTo(studentAvatarView.snp.top).offset(3)
                make.right.equalToSuperview().offset(-20)
            })
        studentContactLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.primary)
            .font(font: FontUtil.regular(size: 15))
            .addTo(superView: studentView, withConstraints: { make in
                make.left.equalTo(studentAvatarView.snp.right).offset(20)
                make.top.equalTo(studentNameLabel.snp.bottom).offset(7)
                make.right.equalToSuperview().offset(-20)

            })
//        view.isSkeletonable = true
    }

    func initTableView() {
        tableView = UITableView()

        tableView.register(LessonSearchSchedulCell.self, forCellReuseIdentifier: String(describing: LessonSearchSchedulCell.self))
        tableView.delegate = self
        tableView.estimatedRowHeight = 90
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        studentView.heroID = "\(studentData.studentId)"
        mainView.addSubview(view: tableView) { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(studentView.snp.bottom).offset(20)
        }
        let footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            guard let self = self else { return }
            self.startTimestamp = self.endTimestamp
            self.endTimestamp = TimeUtil.endOfMonth(date: TimeUtil.changeTime(time: Double(self.startTimestamp)).add(component: .month, value: 3)).timestamp
            self.geScheduleData()
        })
//        footer.setTitle("Drag up to refresh", for: .idle)
        footer.setTitle("", for: .idle)

        footer.setTitle("Loading more...", for: .refreshing)
        footer.setTitle("No more lessons", for: .noMoreData)
        footer.stateLabel?.font = FontUtil.regular(size: 15)
        footer.stateLabel?.textColor = ColorUtil.Font.primary

        tableView.mj_footer = footer
    }
}

// MARK: - Data

extension LessonSearchScheduleController {
    override func initData() {
        let d = Date()

        startTimestamp = d.startOfDay.timestamp
        endTimestamp = TimeUtil.endOfMonth(date: d.add(component: .month, value: 3)).timestamp

        initStudentData()
        getLessonType()
    }

    private func initStudentData() {
        studentAvatarView.loadImage(userId: studentData.studentId, name: studentData.name)
        studentNameLabel.text(studentData.name)
        studentContactLabel.text(studentData.email)
        navigationBar.title = "\(studentData.name)"
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
                            self.geScheduleData()
                        }
                    }
                    if let data = data[false] {
                        if !isLoad {
                            self.lessonTypes = data
                            self.geScheduleData()
                        }
                    }
                })
        )
    }

    func geScheduleData() {
//        let sortData = ScheduleUtil.getSchedule(startTime: startTimestamp, endTime: endTimestamp, data: scheduleConfigs, lessonTypes: lessonTypes)
        var newData: [TKLessonSchedule] = []
        print("开始时间 :\(self.startTimestamp)==结束时间=\(self.endTimestamp)")

        LessonService.lessonSchedule.refreshLessonSchedule(startTime: startTimestamp , endTime: endTimestamp )
            .done { [weak self] _ in
                guard let self = self else { return }
//                self.getWebData(localData: [], isUpdate: true)
                self.addSubscribe(
                    LessonService.lessonSchedule.getScheduleListByStudentId(studentId: self.studentData.studentId, teacherID: self.teacherID, startTime: self.startTimestamp, endTime: self.endTimestamp, isCache: false)
                        .subscribe(onNext: { [weak self] docs in
                            guard let self = self else { return }
                            var data: [TKLessonSchedule] = []
                            for doc in docs.documents {
                                if var d = TKLessonSchedule.deserialize(from: doc.data()) {
                                    var isHave = false
                                    for item in self.scheduleConfigs where item.id == d.lessonScheduleConfigId {
                                        isHave = true
                                        d.lessonScheduleData = item
                                    }
                                    guard isHave else { continue }

                                    d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)

                                    if self.lessonScheduleIdMap[d.id] == nil {
                                        self.lessonScheduleIdMap[d.id] = d.id
                                        if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
                                            continue
                                        }
                                        d.studentData = self.studentData

                                        self.lessonSchedule.append(d)
                                        newData.append(d)
                                    }

                                    data.append(d)
                                }
                            }
                            logger.debug("======\(data.toJSONString(prettyPrint: true) ?? "")")
//                            for sortItem in sortData.enumerated() {
//                                let id = "\(sortItem.element.teacherId):\(sortItem.element.studentId):\(Int(sortItem.element.shouldDateTime))"
//                                for item in self.scheduleConfigs where item.id == sortData[sortItem.offset].lessonScheduleConfigId {
//                                    sortData[sortItem.offset].lessonScheduleData = item
//                                }
//                                sortData[sortItem.offset].id = id
//                                sortData[sortItem.offset].studentData = self.studentData
//                            }
//
//                            for sortItem in sortData.enumerated() {
//                                let id = "\(sortItem.element.teacherId):\(sortItem.element.studentId):\(Int(sortItem.element.shouldDateTime))"
//                                sortData[sortItem.offset].id = id
//                                sortData[sortItem.offset].studentData = self.studentData
//                                // 整理lesson 去除 已经存在在lessonSchedule 中的
//                                if self.lessonScheduleIdMap[id] == nil {
//                                    var isCancelOfRescheduled = false
//                                    for item in data where id == item.id {
//                                        if item.cancelled || (item.rescheduled && item.rescheduleId != "") {
//                                            isCancelOfRescheduled = true
//                                        }
//                                    }
//                                    if !isCancelOfRescheduled {
//                                        self.lessonSchedule.append(sortItem.element)
//                                        newData.append(sortItem.element)
//                                        self.lessonScheduleIdMap[id] = id
//                                    }
//                                }
//                            }
                            self.sortData(newData: newData)

                        }, onError: { [weak self] err in
                            guard let self = self else { return }
                            logger.debug("获取失败:\(err)")
//                            for sortItem in sortData.enumerated() {
//                                let id = "\(sortItem.element.teacherId):\(sortItem.element.studentId):\(Int(sortItem.element.shouldDateTime))"
//                                sortData[sortItem.offset].id = id
//                                sortData[sortItem.offset].studentData = self.studentData
//                                if self.lessonScheduleIdMap[id] == nil {
//                                    newData.append(sortItem.element)
//                                    self.lessonSchedule.append(sortItem.element)
//                                    self.lessonScheduleIdMap[id] = id
//                                    self.sortData(newData: newData)
//                                }
//                            }

                        })
                )
            }
            .catch { error in
                logger.error("刷新课程失败: \(error)")
            }
    }

    func sortData(newData: [TKLessonSchedule]) {
        logger.debug("======\(newData.toJSONString(prettyPrint: true) ?? "")")

        data.append(contentsOf: newData)
        if tableView.mj_footer != nil {
            tableView.mj_footer!.endRefreshing()
            if newData.count == 0 {
                tableView.mj_footer!.endRefreshingWithNoMoreData()
            } else {
                tableView.mj_footer!.resetNoMoreData()
            }
        }

        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
        }
    }
}

// MARK: - TableView

extension LessonSearchScheduleController: UITableViewDelegate, UITableViewDataSource, LessonSearchSchedulCellDelegate {
    func lessonSearchSchedul(clickCell cell: LessonSearchSchedulCell) {
        let controller = LessonsDetailViewController(data: [data[cell.tag]], selectedPos: 0)
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonSearchSchedulCell.self), for: indexPath) as! LessonSearchSchedulCell
        cell.delegate = self
        cell.tag = indexPath.row
        cell.initData(data: data[indexPath.row])

        return cell
    }
}

// MARK: - Action

extension LessonSearchScheduleController {
}
