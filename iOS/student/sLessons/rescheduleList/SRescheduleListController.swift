//
//  SRescheduleListController.swift
//  TuneKey
//
//  Created by wht on 2020/4/24.
//  Copyright © 2020 spelist. All rights reserved.
//

import MessageUI
import UIKit

class SRescheduleListController: TKBaseViewController {
    private var mainView = UIView()
    private var navigationBar: TKNormalNavigationBar!
    private var tableView: UITableView!
    var tableViewData = BehaviorRelay(value: [TKReschedule]())
    var data: [TKReschedule] = []
    private var policyData: TKPolicies!
    var teacherUser: TKUser?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - View

extension SRescheduleListController {
    override func initView() {
        enablePanToDismiss()
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
        tableView!.register(SRescheduleListCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorStyle = .none
        mainView.addSubview(view: tableView) { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
        }
        addSubscribe(
            tableViewData.bind(to: tableView.rx.items) { tableView, index, _ in
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! SRescheduleListCell
                cell.tag = index
                cell.selectionStyle = .none
                cell.initData(reschedule: self.data[index], teacherUser: self.teacherUser)
                logger.debug("当前渲染的数据: \(self.data[safe: index]?.toJSONString() ?? "")")
                cell.pRPendingBackButton.onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    self.clickBackToOriginal(index)
                }
                cell.pRPendingConfirmButton.onViewTapped { [weak self] _ in
                    guard let self = self, let user = ListenerService.shared.user else { return }
                    switch user.currentUserDataVersion {
                    case let .unknown(version: version):
                        logger.error("Known version: \(version)")
                        return
                    case .singleTeacher:
                        self.confirmTeacherReschedule(index)
                    case .studio:
                        self.confirmTeacherRescheduleV2(index)
                    }
                }
                cell.pRPendingRescheduleButton.onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    if self.data[index].senderId != self.data[index].studentId {
                        self.toReschedule(self.data[index])
                    } else {
                        self.toReschedule(self.data[index], type: 1)
                    }
                }
                cell.pRStatusLabel.onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    if let info = cell.teacherUser {
                        self.showEmailAndPhone(userInfo: info)
                    }
                }
                cell.pRPendingCloseButton.onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    self.readReschedule(index: index)
                }
                return cell
            }
        )
        addSubscribe(
            tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                // cell 点击事件
                if self.data[indexPath.row].retracted || self.data[indexPath.row].confirmType != .unconfirmed {
                    return
                }
                if self.data[indexPath.row].senderId != self.data[indexPath.row].studentId {
                    self.toReschedule(self.data[indexPath.row])
                } else {
                    self.toReschedule(self.data[indexPath.row], type: 1)
                }
            })
        )
    }
}

// MARK: - Data

extension SRescheduleListController {
    override func initData() {
        tableViewData.accept(data)
        if let user = ListenerService.shared.user {
            switch user.currentUserDataVersion {
            case let .unknown(version: version):
                logger.debug("unknown version: \(version)")
                return
            case .singleTeacher:
                getPoliceData()
                getTeacherUser()
            case .studio:
                getPoliceDataV2()
                getStudioCreatorUser()
            }
        }
    }

    private func getTeacherUser() {
        guard let teacher = data.first?.teacherId else { return }
        var isLoad = false
        addSubscribe(
            UserService.user.getUserInfoById(userId: teacher)
                .subscribe(onNext: { [weak self] doc in
                    guard let self = self else { return }
                    if !isLoad {
                        if let doc = TKUser.deserialize(from: doc.data()) {
                            isLoad = true
                            self.teacherUser = doc
                            self.tableView.reloadData()
                        }
                    }

                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }
    
    private func getStudioCreatorUser() {
        guard let studioInfo = ListenerService.shared.studentData.studioData, !studioInfo.creatorId.isEmpty else { return }
        UserService.user.getUser(id: studioInfo.creatorId)
            .done { [weak self] user in
                guard let self = self else { return }
                self.teacherUser = user
                self.tableView.reloadData()
            }
            .catch { error in
                logger.error("获取 studio creator 信息失败： \(error)")
            }
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

    private func getPoliceDataV2() {
        guard let data = data.first else { return }
        showFullScreenLoadingNoAutoHide()
        UserService.studio.getPolicy(studioId: data.studioId)
            .done { [weak self] policy in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                self.policyData = policy
                logger.debug("获取到的policy数据: \(policy.toJSONString() ?? "")")
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                logger.error("获取policy失败: \(error)")
                self.hideFullScreenLoading()
            }
    }

    func backToOriginalReschedule(_ index: Int) {
        showFullScreenLoading()
//        addSubscribe(
//            LessonService.lessonSchedule.backToOriginalReschedule(rescheduleData: data[index])
//                .subscribe(onNext: { [weak self] _ in
//                    guard let self = self else { return }
//                    self.hideFullScreenLoading()
//                    TKToast.show(msg: TipMsg.retractSuccessful, style: .success)
//                    self.data.remove(at: index)
//                    self.tableViewData.accept(self.data)
//                    EventBus.send(EventBus.CHANGE_SCHEDULE)
//
//                }, onError: { [weak self] err in
//                    guard let self = self else { return }
//                    self.hideFullScreenLoading()
//                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
//                    logger.debug("获取失败:\(err)")
//                })
//        )
        
        LessonService.lessonSchedule.retrachReschedule(id: data[index].id)
            .done { [weak self] _ in
                guard let self = self else { return }
                updateUI { 
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.retractSuccessful, style: .success)
                    self.data.remove(at: index)
                    self.tableViewData.accept(self.data)
                    EventBus.send(EventBus.CHANGE_SCHEDULE)
                }
            }
            .catch { [weak self] err in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                logger.debug("获取失败:\(err)")
            }
    }

    func confirmTeacherReschedule(_ index: Int) {
        let data = self.data[index]
        guard !data.isCancelLesson else { return }
        showFullScreenLoadingNoAutoHide()
        addSubscribe(
            LessonService.lessonSchedule.confirmReschedule(rescheduleData: data)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    EventBus.send(EventBus.CHANGE_SCHEDULE)
                    self.hideFullScreenLoading()
                    TKToast.show(msg: "Successfully!", style: .success)
                    self.data.remove(at: index)
                    self.tableViewData.accept(self.data)
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func confirmTeacherRescheduleV2(_ index: Int) {
        guard data.isSafeIndex(index) else { return }
        let data = self.data[index]
        guard !data.isCancelLesson else { return }
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller().name("scheduleService-confirmReschedule")
            .appendData(key: "id", value: data.id)
            .call { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    logger.error("确认失败: \(error)")
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                } else {
                    TKToast.show(msg: "Successfully!", style: .success)
                    if self.data.isSafeIndex(index) {
                        self.data.remove(at: index)
                        self.tableViewData.accept(self.data)
                    }
                }
            }
    }

    private func readReschedule(index: Int) {
        let reschedule = data[index]
        showFullScreenLoadingNoAutoHide()
        logger.debug("read reschedule: \(reschedule.id)")
        DatabaseService.collections.followUps()
            .document(reschedule.id)
            .updateData(["data.studentRead": true]) { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                    logger.error("更新失败: \(error)")
                } else {
                    TKToast.show(msg: "Successfully!", style: .success)
                    EventBus.send(EventBus.CHANGE_SCHEDULE)
                }
            }
//        DatabaseService.collections.userNotifications()
//            .document("\(reschedule.id):\(uid)")
//            .updateData(["read": true]) { [weak self] error in
//                self?.hideFullScreenLoading()
//                guard let self = self else { return }
//                if let error = error {
//                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
//
//                    logger.error("更新失败: \(error)")
//                } else {
//                    TKToast.show(msg: "Successfully!", style: .success)
//                    EventBus.send(EventBus.CHANGE_SCHEDULE)
//                    self.hideFullScreenLoading()
//                }
//            }
    }
}

// MARK: - TableView

extension SRescheduleListController {
}

// MARK: - Action

extension SRescheduleListController {
    func clickBackToOriginal(_ index: Int) {
        guard !data[index].isCancelLesson else { return }
        SL.Alert.show(target: self, title: "Retract request", message: "\(TipMsg.cancelReschedul)", leftButttonString: "YES", rightButtonString: "NO", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
            self?.backToOriginalReschedule(index)

        }) {
        }
    }

    func toReschedule(_ data: TKReschedule, type: Int = 0) {
        // type = 0 是老师的reschedule //type = 1 是去Edit
        // 显示cancel lesson 和 reschedule
        guard !data.isCancelLesson, let policyData else {
            logger.debug("无法获取到 policy data")
            return
        }
        showFullScreenLoading()
        var isLoad = false
        addSubscribe(
            LessonService.lessonSchedule.getLessonScheduleById(id: data.scheduleId)
                .subscribe(onNext: { [weak self] doc in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if !isLoad {
                        if let doc = doc.data() {
                            isLoad = true
                            if let scheduleData = TKLessonSchedule.deserialize(from: doc) {
                                var policy = policyData
                                if data.senderId == scheduleData.teacherId {
                                    policy.allowMakeup = true
                                    policy.allowReschedule = true
                                    policy.allowRefund = true
                                }
                                if type == 0 {
                                    let controller = RescheduleController(originalData: scheduleData, rescheduleData: data, buttonType: .cancelLesson, policyData: policy, isEdit: false)
                                    controller.modalPresentationStyle = .fullScreen
                                    controller.hero.isEnabled = true
                                    controller.enablePanToDismiss()
                                    controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                                    self.present(controller, animated: true, completion: nil)
                                } else {
                                    let controller = RescheduleController(originalData: scheduleData, rescheduleData: data, buttonType: .reschedule, policyData: policy, isEdit: true)
                                    controller.modalPresentationStyle = .fullScreen
                                    controller.hero.isEnabled = true
                                    controller.enablePanToDismiss()
                                    controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                                    self.present(controller, animated: true, completion: nil)
                                }
                            }
                        }
                    }

                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("======\(err)")
                })
        )
    }
}

extension SRescheduleListController {
    private func showEmailAndPhone(userInfo: TKUser) {
        var items: [TKPopAction.Item] = []
        if userInfo.email != "" {
            items.append(TKPopAction.Item(title: userInfo.email) { [weak self] in
                self?.sendEmail(email: userInfo.email)
            })
        }

        if userInfo.phone != "" {
            items.append(TKPopAction.Item(title: userInfo.phone) {
                let phone = "telprompt://\(userInfo.phone)"
                if let url = URL(string: phone) {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            })
        }

        TKPopAction.show(items: items, isCancelShow: true, target: self)
    }
}

extension SRescheduleListController: MFMailComposeViewControllerDelegate {
    func sendEmail(email: String) {
        // 0.首先判断设备是否能发送邮件
        if MFMailComposeViewController.canSendMail() {
            // 1.配置邮件窗口
            let mailView = configuredMailComposeViewController(email: email)
            // 2. 显示邮件窗口
            Tools.getTopViewController()?.present(mailView, animated: true, completion: nil)
        } else {
            print("Whoop...设备不能发送邮件")
            showSendMailErrorAlert()
        }
    }

    // 提示框，提示用户设置邮箱
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Mail is not turned on", message: TipMsg.accessForEmailApp, preferredStyle: .alert)
        sendMailErrorAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
        Tools.getTopViewController()?.present(sendMailErrorAlert, animated: true) {}
    }

    // MARK: - helper methods

    // 配置邮件窗口
    func configuredMailComposeViewController(email: String) -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self

        // 设置邮件地址、主题及正文
        mailComposeVC.setToRecipients([email])
        mailComposeVC.setSubject("")
        mailComposeVC.setMessageBody("", isHTML: false)

        return mailComposeVC
    }

    // MARK: - Mail Delegate

    // 用户退出邮件窗口时被调用
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result.rawValue {
        case MFMailComposeResult.sent.rawValue:
            print("邮件已发送")
        case MFMailComposeResult.cancelled.rawValue:
            print("邮件已取消")
        case MFMailComposeResult.saved.rawValue:
            print("邮件已保存")
        case MFMailComposeResult.failed.rawValue:
            print("邮件发送失败")
        default:
            print("邮件没有发送")
            break
        }
        controller.dismiss(animated: true, completion: nil)
    }
}
