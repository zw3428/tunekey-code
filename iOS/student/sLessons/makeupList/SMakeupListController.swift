//
//  SMakeupListController.swift
//  TuneKey
//
//  Created by wht on 2020/4/26.
//  Copyright © 2020 spelist. All rights reserved.
//

import Foundation
import UIKit
class SMakeupListController: TKBaseViewController {
    private var mainView = UIView()
    private var navigationBar: TKNormalNavigationBar!
    private var tableView: UITableView!
    private var tableViewData = BehaviorRelay(value: [TKLessonCancellation]())
    var data: [TKLessonCancellation] = []
    private var policyData: TKPolicies!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - View

extension SMakeupListController {
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
        initTableview()
    }

    func initTableview() {
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView!.register(SMakeupListCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorStyle = .none
        mainView.addSubview(view: tableView) { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
        }
        addSubscribe(
            tableViewData.bind(to: tableView.rx.items) { [weak self] tableView, index, _ in
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! SMakeupListCell
                cell.tag = index
                cell.selectionStyle = .none
                if let self = self {
                    cell.initData(reschedule: self.data[index])
                }
                return cell
            }
        )
        addSubscribe(
            tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                // cell 点击事件
                logger.debug("======\(indexPath.row)")

                self.toReschedule(self.data[indexPath.row])

            })
        )
    }
}

// MARK: - Data

extension SMakeupListController {
    override func initData() {
        tableViewData.accept(data)
        getPoliceData()
    }

    func getPoliceData() {
        showFullScreenLoading()
        addSubscribe(
            UserService.teacher.getPoliciesById(policiesId: data[0].teacherId)
                .subscribe(onNext: { [weak self] doc in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if doc.exists {
                        if let data = TKPolicies.deserialize(from: doc.data()) {
                            self.policyData = data
                        }
                    }

                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()

                    logger.debug("======\(err)")
                })
        )
    }
}

// MARK: - TableView

extension SMakeupListController {
}

// MARK: - Action

extension SMakeupListController {
    func toReschedule(_ data: TKLessonCancellation) {
        // 显示cancel lesson 和 reschedule
        showFullScreenLoading()
        var isLoad = false
        addSubscribe(
            LessonService.lessonSchedule.getLessonScheduleById(id: data.oldScheduleId)
                .subscribe(onNext: { doc in
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
                            var day = ((toDayStart.timestamp - firstRescheduleTime) % (self.policyData.rescheduleLimitTimesPeriod * 30 * 24 * 60 * 60))
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
                            if count < self.policyData.refundLimitTimesAmount {
                                buttonType = .refundAndMakeUp
                            } else {
                                buttonType = .makeUp
                            }
                        } else {
                            buttonType = .refundAndMakeUp
                        }

                        let controller = RescheduleController(originalData: scheduleData, makeUpData: data, buttonType: buttonType, policyData: self.policyData)
                        controller.modalPresentationStyle = .fullScreen
                        controller.hero.isEnabled = true
                        controller.enablePanToDismiss()
                        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                        self.present(controller, animated: true, completion: nil)
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
}
