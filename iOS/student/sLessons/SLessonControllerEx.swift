//
//  SLessonControllerEx.swift
//  TuneKey
//
//  Created by WHT on 2020/7/16.
//  Copyright © 2020 spelist. All rights reserved.
//

import FirebaseFirestore
import Foundation
import UIKit

extension SLessonController {
    func deleteLessonWithoutTeacher(data: TKLessonSchedule) {
        // 获取config

        guard let config = ListenerService.shared.studentData.scheduleConfigs.filter({ $0.id == data.lessonScheduleConfigId }).first else { return }

        if config.repeatType == .none {
            SL.Alert.show(target: self, title: "Warning", message: "Are you sure you want to delete this lesson?", leftButttonString: "Go back", rightButtonString: "Delete") {
            } rightButtonAction: {
                LessonService.lessonSchedule.studentDeleteLessonWithoutTeacher(data: data, deleteUpcoming: false)
                    .done { _ in
                        self.hideFullScreenLoading()
                        self.nextLessonData = nil
                        self.refreshNextLessonView()
                        self.initNextLesson()
                        TKToast.show(msg: "Removed this lesson successfully")
                    }
                    .catch { _ in
                        self.hideFullScreenLoading()
                        TKToast.show(msg: "Remove failed, try again later", style: .error)
                    }
            }

        } else {
            SL.Alert.show(target: self, title: "Warning", message: "Are you sure you want to delete this lesson?", leftButttonString: "Go back", centerButttonString: "This and upcoming lessons", rightButtonString: "Only this lesson") {
            } centerButtonAction: {
                self.showFullScreenLoading()
                LessonService.lessonSchedule.studentDeleteLessonWithoutTeacher(data: data, deleteUpcoming: true)
                    .done { _ in
                        self.hideFullScreenLoading()
                        self.nextLessonData = nil
                        self.refreshNextLessonView()
                        self.initNextLesson()
                        TKToast.show(msg: "Removed this lesson successfully")
                    }
                    .catch { _ in
                        self.hideFullScreenLoading()
                        TKToast.show(msg: "Remove failed, try again later", style: .error)
                    }
            } rightButtonAction: {
                self.showFullScreenLoading()
                LessonService.lessonSchedule.studentDeleteLessonWithoutTeacher(data: data, deleteUpcoming: false)
                    .done { _ in
                        self.hideFullScreenLoading()
                        self.nextLessonData = nil
                        self.refreshNextLessonView()
                        self.initNextLesson()
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
            guard let nextLessonData = nextLessonData else { return }
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
            guard let studentData = studentData else { return }
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
        guard let nextLessonData = nextLessonData else { return }
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
        guard let studentData = studentData else { return }
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
        guard let nextLessonData = nextLessonData else { return }
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
                guard let self = self, let nextLessonData = self.nextLessonData else { return }
                self.addCancellation(type: 1, schedule: nextLessonData, rescheduleId: rescheduleId, isReschedule: isReschedule)
            }
            controller.rightButtonAction = {
            }
            controller.messageString = message
            controller.leftButtonFont = FontUtil.bold(size: 13)
            controller.rightButtonFont = FontUtil.bold(size: 13)
            present(controller, animated: false, completion: nil)
            hiddenNextLessonButton()

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
                guard let self = self, let nextLessonData = self.nextLessonData else { return }
                self.addCancellation(type: 2, schedule: nextLessonData, rescheduleId: rescheduleId, isReschedule: isReschedule)
            }
            controller.rightButtonAction = {
            }
            controller.messageString = message
            controller.leftButtonFont = FontUtil.bold(size: 13)
            controller.rightButtonFont = FontUtil.bold(size: 13)
            present(controller, animated: false, completion: nil)
            hiddenNextLessonButton()

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

    private func addCancellation(type: Int, schedule: TKLessonSchedule, rescheduleId: String?, isReschedule: Bool = false) {
        guard let studentData = studentData else { return }
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
                        self.nextLessonData?.cancelled = true
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
            guard let studentData = self.studentData else { return }
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
                        self.nextLessonData?.cancelled = true
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

    /// 点击Cancel 显示该课程正在Reschedule的Alert
    /// - Parameters:
    ///   - type:type: Int, _ cell: AllFuturesCell
    ///   - cell:
    private func showCancelReschduleAlert(_ type: Int) {
        guard let nextLessonData = self.nextLessonData else { return }
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
                            self.hiddenNextLessonButton()
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
        hiddenNextLessonButton()
    }
}

extension SLessonController: SInviteTeacherViewControllerDelegate {
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

extension SLessonController {
    func rescheduleLesson() {
        guard let policyData = policyData, let nextLessonData = nextLessonData else { return }
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
                hiddenNextLessonButton()

                break
            default:
                break
            }
        }
        func openRescheduleController() {
            guard let nextLessonData = self.nextLessonData else { return }
            hideFullScreenLoading()

            let controller = RescheduleController(originalData: nextLessonData, buttonType: .reschedule, policyData: policyData)
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.enablePanToDismiss()
            //        controller.originalData = nextLessonData
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            present(controller, animated: true, completion: nil)
            hiddenNextLessonButton()
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
        guard let studentData = studentData else { return }
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
        guard let policyData = policyData, let nextLessonData = nextLessonData else { return }
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
                            self.hiddenNextLessonButton()

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
                                self.hiddenNextLessonButton()
                            }
                            controller.rightButtonAction = {
                            }

                            controller.leftButtonFont = FontUtil.bold(size: 13)
                            controller.rightButtonFont = FontUtil.bold(size: 13)
                            self.present(controller, animated: false, completion: nil)
                            self.hiddenNextLessonButton()
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

