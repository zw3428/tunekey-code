//
//  LessonsViewControllerEx.swift
//  TuneKey
//
//  Created by wht on 2020/5/7.
//  Copyright © 2020 spelist. All rights reserved.
//

import Foundation
import UIKit

extension LessonsViewController {
    func initRescheduleAndMakeUpMessageView() {
        rescheduleAndMakeUpMessageView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow(color: ColorUtil.dividingLine)
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalTo(self.monthView.snp.bottom)
                make.left.equalTo(20)
                make.right.equalTo(-20)
                make.height.equalTo(0)
            })
        rescheduleAndMakeUpMessageView.isHidden = true
        rescheduleAndMakeUpMessageCountLabel = TKLabel.create()
            .text(text: "0")
            .alignment(alignment: .center)
            .textColor(color: UIColor.white)
            .backgroundColor(color: ColorUtil.red)
            .font(font: FontUtil.bold(size: 9))
            .addTo(superView: rescheduleAndMakeUpMessageView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(20)
            })
        rescheduleAndMakeUpMessageCountLabel.layer.cornerRadius = 10
        rescheduleAndMakeUpMessageCountLabel.layer.masksToBounds = true
        rescheduleAndMakeUpMessageTieleLabel = TKLabel.create()
            .text(text: "Reschedule request")
            .textColor(color: ColorUtil.Font.third)
            .font(font: FontUtil.bold(size: 15))
            .addTo(superView: rescheduleAndMakeUpMessageView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(20)
            })
        rescheduleAndMakeUpMessageView.onViewTapped { [weak self] _ in
            logger.debug("点击rescheduleAndMakeUpMessageView")
            self?.showRescheduleAndMakeUpView()
        }
    }

    func initRescheduleView() {
        rescheduleAndMakeUpBackView = TKView.create()
            .backgroundColor(color: UIColor.black.withAlphaComponent(0.4))
            .addTo(superView: view, withConstraints: { make in
                make.center.size.equalToSuperview()
            })

        rescheduleAndMakeUpView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 10)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow(color: ColorUtil.dividingLine)
            .addTo(superView: rescheduleAndMakeUpBackView, withConstraints: { make in
//                make.top.equalToSuperview().offset(20)
                make.centerY.equalToSuperview()
                make.left.equalTo(20)
                make.right.equalTo(-20)
//                make.height.equalTo(400)
            })
        rescheduleAndMakeUpView.clipsToBounds = true
        rescheduleAndMakeUpView.onViewTapped { _ in
        }
        rescheduleAndMakeUpTableView = UITableView(frame: CGRect.zero, style: .plain)
//        rescheduleAndMakeUpTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 52, right: 0)
        rescheduleAndMakeUpTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20))
        rescheduleAndMakeUpTableView.tableFooterView = UIView()
        rescheduleAndMakeUpTableView.backgroundColor = UIColor.white
        rescheduleAndMakeUpTableView!.register(UndoneRescheduleCell.self, forCellReuseIdentifier: "Cell")
        rescheduleAndMakeUpTableView.separatorStyle = .none
        rescheduleAndMakeUpView.addSubview(view: rescheduleAndMakeUpTableView) { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().priority(.medium)
        }
        rescheduleAndMakeUpTableView.cornerRadius = 10

        addSubscribe(
            rescheduleTableViewData.bind(to: rescheduleAndMakeUpTableView.rx.items) { tableView, index, data in
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! UndoneRescheduleCell
                cell.tag = index
                cell.selectionStyle = .none
                logger.debug("当前的重新预约数据: \(data.toJSON() ?? [:])")
                cell.initData(reschedule: data, hasNext: index != self.rescheduleTableViewData.value.count - 1)
                cell.confirmButton.onTapped { [weak self] _ in
                    guard let self = self else { return }
                    self.hideRescheduleAndMakeUpView()
                    self.clickConfirm(index)
                }
                cell.closeButton.onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    if data.isCancelLesson {
                        self.hideRescheduleAndMakeUpView()
                        self.clickCloseCancelation(index)
                    } else if data.retracted {
                        LessonService.lessonSchedule.teacherReadRetractedReschedule(data: data)
                        self.rescheduleTableViewData.accept(self.rescheduleTableViewData.value.filter { $0.id != data.id })
                        self.rescheduleAndMakeUpMessageCountLabel.text = "\(self.rescheduleTableViewData.value.count)"
                        self.updateReschedulAndMakeUpViewHeight()
                        if self.rescheduleTableViewData.value.count == 0 {
                            self.hideRescheduleAndMakeUpView()
                            self.updateRescheduleAndMakeUpView()
                        }
                    } else {
                        logger.debug("点击close Button")
                        LessonService.lessonSchedule.teacherReadReschedule(data: [data])
                        self.rescheduleTableViewData.accept(self.rescheduleTableViewData.value.filter { $0.id != data.id })
                        self.rescheduleAndMakeUpMessageCountLabel.text = "\(self.rescheduleTableViewData.value.count)"
                        self.updateReschedulAndMakeUpViewHeight()
                        if self.rescheduleTableViewData.value.count == 0 {
                            self.hideRescheduleAndMakeUpView()
                            self.updateRescheduleAndMakeUpView()
                        }
                    }
                }
                cell.rejectButton.onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    self.hideRescheduleAndMakeUpView()
                    self.clickRescheduleDeclined(index)
                }
                cell.rescheduleButton.onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    self.hideRescheduleAndMakeUpView()
                    self.clickRescheduleReschedule(index)
                }
                cell.pRNewQuestionMarkImageView.onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    self.hideRescheduleAndMakeUpView()
                    self.clickRescheduleReschedule(index)
                }
                cell.pRPendingBackButton.onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    self.clickBackToOriginal(index)
                }
                cell.pRNewView.onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    self.hideRescheduleAndMakeUpView()
                    self.clickRescheduleReschedule(index)
                }
                return cell
            }
        )
//        rescheduleAndMakeUpCallapseLabel = TKLabel.create()
//            .textColor(color: ColorUtil.main)
//            .backgroundColor(color: UIColor.white)
//            .text(text: "Collapse")
//            .font(font: FontUtil.bold(size: 10))
//            .alignment(alignment: .center)
//            .addTo(superView: rescheduleAndMakeUpView, withConstraints: { make in
//                make.height.equalTo(52)
//                make.left.right.bottom.centerX.equalToSuperview()
//            })
//        rescheduleAndMakeUpCallapseLabel.cornerRadius = 10
//        rescheduleAndMakeUpCallapseLabel.setBottomRadius(radius: 5)
//        rescheduleAndMakeUpCallapseLabel.onViewTapped { [weak self] _ in
//            self?.hideRescheduleAndMakeUpView()
//        }

        let closeButton = TKButton.create()
            .setImage(name: "icCloseGray", size: CGSize(width: 22, height: 22))
            .addTo(superView: rescheduleAndMakeUpView) { make in
                make.top.equalToSuperview().offset(10)
                make.right.equalToSuperview().offset(-10)
                make.size.equalTo(40)
            }
        closeButton.onTapped { [weak self] _ in
            self?.hideRescheduleAndMakeUpView()
        }

        rescheduleAndMakeUpBackView.isHidden = true
        rescheduleAndMakeUpBackView.onViewTapped { [weak self] _ in
            self?.hideRescheduleAndMakeUpView()
        }
    }
}

extension LessonsViewController {
    func hideRescheduleAndMakeUpView() {
        tabBarController?.tabBar.isHidden = false
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.rescheduleAndMakeUpView.transform = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
            self?.rescheduleAndMakeUpBackView.layer.opacity = 0
//            self?.tabBarController?.tabBar.transform = .identity
            self?.tabBarController?.tabBar.alpha = 1
        }, completion: { [weak self] _ in
            self?.rescheduleAndMakeUpBackView.isHidden = true
        })
    }

    func updateReschedulAndMakeUpViewHeight() {
        var height: CGFloat = CGFloat(rescheduleTableViewData.value.count) * 188 + 20
        logger.debug("TableView的高度为: \(height)")
        let maxHeight = UIScreen.main.bounds.height * 0.8
        if height >= maxHeight {
            height = maxHeight
        }
        if height <= 230 {
            height = 230
        }
        rescheduleAndMakeUpTableView.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(height)
            make.bottom.equalToSuperview().priority(.medium)
        }
    }

    func showRescheduleAndMakeUpView(completion: (() -> Void)? = nil) {
        rescheduleAndMakeUpTableView.reloadData()
        rescheduleAndMakeUpTableView.layoutIfNeeded()
        updateReschedulAndMakeUpViewHeight()
        rescheduleAndMakeUpView.transform = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
        rescheduleAndMakeUpBackView.layer.opacity = 0
        rescheduleAndMakeUpBackView.isHidden = false
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.rescheduleAndMakeUpView.transform = .identity
            self?.rescheduleAndMakeUpBackView.layer.opacity = 1
//            self?.tabBarController?.tabBar.transform = CGAffineTransform(translationX: 0, y: self?.tabBarController?.tabBar.bounds.height ?? 0)
            self?.tabBarController?.tabBar.alpha = 0
        }, completion: { _ in
            completion?()
        })
    }

    func hidenRescheduleAndMakeUpMessageView() {
        guard rescheduleAndMakeUpMessageView.layer.opacity != 0 else { return }

        SL.Animator.run(time: 0.3) { [weak self] in
            self?.rescheduleAndMakeUpMessageView.layer.opacity = 0
        }
    }

    func showRescheduleAndMakeUpMessageView() {
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            guard self.rescheduleAndMakeUpMessageView.layer.opacity != 1 else { return }
            SL.Animator.run(time: 0.3) { [weak self] in
                self?.rescheduleAndMakeUpMessageView.layer.opacity = 1
            }
        }
    }
}

extension LessonsViewController {
    func clickCloseCancelation(_ index: Int) {
        showFullScreenLoading()
        let reschedule = rescheduleTableViewData.value[index]
        addSubscribe(
            LessonService.lessonSchedule.confirmCancelation(id: reschedule.id)
                .timeout(RxTimeInterval.seconds(TIME_OUT_TIME), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    EventBus.send(EventBus.CHANGE_SCHEDULE)
                    self.hideFullScreenLoading()
                    TKToast.show(msg: "Successfully!", style: .success)
                    var data = self.rescheduleTableViewData.value
                    data.removeElements { $0.id == reschedule.id }
                    self.rescheduleTableViewData.accept(data)
                    if data.count == 0 {
                        self.rescheduleAndMakeUpMessageView.snp.updateConstraints { make in
                            make.height.equalTo(0)
                        }
                        self.agendaTableView.snp.updateConstraints { make in
                            make.top.equalTo(self.rescheduleAndMakeUpMessageView.snp.bottom).offset(0)
                        }
                        self.rescheduleAndMakeUpMessageView.isHidden = true
                        self.hideRescheduleAndMakeUpView()
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    /// 点击拒绝Reschedule
    /// - Parameter index:
    func clickRescheduleDeclined(_ index: Int) {
        let reschedule = rescheduleTableViewData.value[index]
        TKPopAction.showSendMessage(target: self, titleString: "Message to students (optional)", leftButtonString: "CANCEL", rightButtonString: "DECLINED", isCancelRightTop: false) { [weak self] message in
            guard let self = self else { return }
            logger.debug("======\(message)")
            self.showFullScreenLoading()

            self.addSubscribe(
                LessonService.lessonSchedule.teacherDeclinedReschedule(rescheduleData: reschedule)
                    .timeout(RxTimeInterval.seconds(TIME_OUT_TIME), scheduler: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        EventBus.send(EventBus.CHANGE_SCHEDULE)
//                        CommonsService.shared.sendEmailNotificationForRescheduleNewTime(rescheduleId: self.rescheduleTableViewData.value[index].id, type: 2, msg: "\(message)")
                        self.hideFullScreenLoading()
                        TKToast.show(msg: "Successfully!", style: .success)
//                        var data = self.rescheduleTableViewData.value
//                        data.remove(at: index)
//                        self.rescheduleTableViewData.accept(data)
//                        if data.count == 0 {
//                            self.rescheduleAndMakeUpMessageView.snp.updateConstraints { make in
//                                make.height.equalTo(0)
//                            }
//                            self.agendaTableView.snp.updateConstraints { make in
//                                make.top.equalTo(self.rescheduleAndMakeUpMessageView.snp.bottom).offset(0)
//                            }
//                            self.rescheduleAndMakeUpMessageView.isHidden = true
//                            self.hideRescheduleAndMakeUpView()
//                        }
                    }, onError: { [weak self] err in
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                        logger.debug("获取失败:\(err)")
                    })
            )
        }
    }

    /// 点击重新修改预约时间
    /// - Parameter index:
    func clickRescheduleReschedule(_ index: Int) {
        logger.debug("点击重新修改预约时间: \(index)")
        let reschedule = rescheduleTableViewData.value[index]
        showFullScreenLoading()
        LessonService.lessonSchedule.getReschedule(id: reschedule.id)
            .done {[weak self] rescheduleData in
                guard let self = self else {return}
                self.hideFullScreenLoading()
                let controller = TKPopTeacherAvailableTimeController()
                controller.modalPresentationStyle = .custom
                controller.rescheduleData = self.rescheduleTableViewData.value
                controller.timeLength = reschedule.shouldTimeLength
                self.present(controller, animated: false, completion: nil)

                controller.onDone { [weak self] dateTime in
                    guard let self = self else { return }
                    self.showFullScreenLoadingNoAutoHide()
                    logger.debug("重新选择的时间: \(dateTime.toLocalFormat("yyyy-MM-dd HH:mm:ss"))")
                    TimeUtil.getTimeForRescheduleTimeSelector(localSelectedTime: dateTime.timeIntervalSince1970, lessonScheduleId: reschedule.scheduleId)
                        .done { dateTimestamp in
                            self.addSubscribe(
                                // MARK: - TimeAfter 要修改的地方
                                LessonService.lessonSchedule.updateReschedule(reschedule: rescheduleData, timeAfter: "\(dateTimestamp)", teacherRevisedReschedule: true, studentRevisedReschedule: false)
                                    .subscribe(onNext: { [weak self] _ in
                                        guard let self = self else { return }
                                        EventBus.send(EventBus.CHANGE_SCHEDULE)
                                        CommonsService.shared.sendEmailNotificationForRescheduleNewTime(rescheduleId: self.rescheduleTableViewData.value[index].id, type: 2, msg: "")
                                        self.hideFullScreenLoading()
                                        TKToast.show(msg: "Rescheduled successfully!", style: .success)
                                        let data = self.rescheduleTableViewData.value
                                        data[index].teacherRevisedReschedule = true
                                        data[index].timeAfter = "\(dateTimestamp)"
                                        self.rescheduleTableViewData.accept(data)

                                    }, onError: { [weak self] err in
                                        guard let self = self else { return }
                                        logger.debug("获取失败:\(err)")
                                        let error = err as NSError
                                        if error.code == 0 {
                                            var userId = ""
                                            if let uid = UserService.user.id() {
                                                if rescheduleData.teacherId == uid {
                                                    userId = rescheduleData.studentId
                                                } else {
                                                    userId = rescheduleData.teacherId
                                                }
                                            }
                                            if userId != "" {
                                                UserService.user.getUserInfo(id: userId)
                                                    .done {[weak self] user in
                                                        guard let self = self else{return}
                                                        self.hideFullScreenLoading()
                                                        TKAlert.show(target: self, title: "Something wrong", message: TipMsg.updatingLessonAndTryLater(name: user.name), buttonString: "SEE UPDATE") {
                                                            self.showRescheduleAndMakeUpView()
                                                        }
                                                    }
                                                    .catch {[weak self] _ in
                                                        guard let self = self else{return}
                                                        self.hideFullScreenLoading()
                                                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                                                    }
                                                return
                                            }
                                        } else if error.code == 1 {
                                            self.hideFullScreenLoading()
                                            TKAlert.show(target: self, title: "Too late", message: TipMsg.updateLessonAndTryLaterWhenOccupieded, buttonString: "SEE UPDATE") {
                                                self.showRescheduleAndMakeUpView()
                                            }
                                            return
                                        }
                                        self.hideFullScreenLoading()
                                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                                    })
                            )
                        }
                        .catch { error in
                            logger.error("获取时间戳失败: \(error)")
                            TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                        }
                    
                }
            }
            .catch { error in
                self.hideFullScreenLoading()
                logger.error("获取Reschedule数据失败: \(error)")
                TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
            }
    }

    func clickBackToOriginal(_ index: Int) {
        let reschedule = rescheduleTableViewData.value[index]
        SL.Alert.show(target: self, title: "Retract request", message: "\(TipMsg.cancelReschedul)", leftButttonString: "YES", rightButtonString: "NO", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
            self?.backToOriginalReschedule(reschedule)
        }) {
        }
    }

    func backToOriginalReschedule(_ reschedule: TKReschedule) {
        showFullScreenLoading()
        addSubscribe(
            LessonService.lessonSchedule.backToOriginalReschedule(rescheduleData: reschedule)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.retractSuccessful, style: .success)
                    for item in self.lessonSchedule.enumerated() where item.element.id == reschedule.scheduleId {
                        self.lessonSchedule[item.offset].rescheduled = false
                    }

                    var data = self.rescheduleTableViewData.value
                    data.removeElements { $0.id == reschedule.id }
                    self.rescheduleTableViewData.accept(data)
                    if data.count == 0 {
                        self.rescheduleAndMakeUpMessageView.snp.updateConstraints { make in
                            make.height.equalTo(0)
                        }
                        self.agendaTableView.snp.updateConstraints { make in
                            make.top.equalTo(self.rescheduleAndMakeUpMessageView.snp.bottom).offset(0)
                        }
                        self.rescheduleAndMakeUpMessageView.isHidden = true
                    }
                    self.hideRescheduleAndMakeUpView()
                    self.monthView?.reloadData()
                    self.getCurrentSchedule()
                    self.initWeekData()
                    EventBus.send(EventBus.CHANGE_SCHEDULE)

                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
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
                                    self.hideFullScreenLoading()
                                    TKAlert.show(target: self, title: "Something wrong", message: TipMsg.updatingLessonAndTryLater(name: user.name), buttonString: "SEE UPDATE") {
                                        self.showRescheduleAndMakeUpView()
                                    }
                                }
                                .catch { _ in
                                    self.hideFullScreenLoading()
                                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                                }
                            return
                        }
                    } else if error.code == 1 {
                        self.hideFullScreenLoading()
                        TKAlert.show(target: self, title: "Too late", message: TipMsg.updateLessonAndTryLaterWhenOccupieded, buttonString: "SEE UPDATE") {
                            self.showRescheduleAndMakeUpView()
                        }
                        return
                    }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                })
        )
    }

    /// 点击同意Reschedule
    /// - Parameter index:
    func clickConfirm(_ index: Int) {
//        self.resda
        showFullScreenLoading()
        let reschedule = rescheduleTableViewData.value[index]
        addSubscribe(
            LessonService.lessonSchedule.confirmReschedule(rescheduleData: reschedule)
                .timeout(RxTimeInterval.seconds(TIME_OUT_TIME), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    EventBus.send(EventBus.CHANGE_SCHEDULE)

                    self.hideFullScreenLoading()
                    TKToast.show(msg: "Successfully!", style: .success)
//                    var data = self.rescheduleTableViewData.value
//                    data.remove(at: index)
//                    self.rescheduleTableViewData.accept(data)
//                    CommonsService.shared.sendEmailNotificationForRescheduleNewTime(rescheduleId: self.rescheduleTableViewData.value[index].id, type: 2, msg: "")
                    if self.rescheduleTableViewData.value.count == 0 {
                        self.rescheduleAndMakeUpMessageView.snp.updateConstraints { make in
                            make.height.equalTo(0)
                        }
                        self.agendaTableView.snp.updateConstraints { make in
                            make.top.equalTo(self.rescheduleAndMakeUpMessageView.snp.bottom).offset(0)
                        }
                        self.rescheduleAndMakeUpMessageView.isHidden = true
                        self.hideRescheduleAndMakeUpView()
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
