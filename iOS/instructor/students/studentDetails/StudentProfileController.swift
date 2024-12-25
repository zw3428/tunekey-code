//
//  StudentProfileController.swift
//  TuneKey
//
//  Created by wht on 2020/6/29.
//  Copyright © 2020 spelist. All rights reserved.
//

import MessageUI
import UIKit

class StudentProfileController: TKBaseViewController {
    var mainView = UIView()
    private var tableView: UITableView!
    var studentData: TKStudent!
    private var isEdit: Bool = false
    private var lessonTypes: [TKLessonType]! = []
    var isLoadData: Bool = false

    private var scheduleConfigData: [TKLessonScheduleConfigure] = []
    var isEditStudentInfo = false
    
    private var instruments: [String: TKInstrument] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.debug("进入profile")
    }
}

// MARK: - View

extension StudentProfileController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        initTableview()
    }

    func initTableview() {
        tableView = UITableView()

        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 80))
        tableView.delegate = self
        tableView.bounces = true
        tableView.dataSource = self
        tableView.separatorStyle = .none
        mainView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }
        tableView.estimatedRowHeight = 50

        tableView.estimatedSectionFooterHeight = 0

        tableView.estimatedSectionHeaderHeight = 0

        tableView.register(StudentDetailsUserInfoCell.self, forCellReuseIdentifier: String(describing: StudentDetailsUserInfoCell.self))
        tableView.register(StudentdetailLessonCell.self, forCellReuseIdentifier: String(describing: StudentdetailLessonCell.self))
    }
}

// MARK: - Data

extension StudentProfileController {
    override func initData() {
        getLessonType()
        loadAllInstruments()
        EventBus.listen(EventBus.CHANGE_SCHEDULE, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.getLessonType()
        }
    }
    
    private func loadAllInstruments() {
        InstrumentService.shared.loadAllInstruments()
            .done { instruments in
                instruments.forEach { instrument in
                    self.instruments[instrument.id.description] = instrument
                }
                self.tableView.reloadData()
            }
            .catch { error in
                logger.error("获取乐器失败: \(error)")
            }
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
                            self.getScheduleConfig()
                        }
                    }
                    if let data = data[false] {
                        if !isLoad {
                            self.lessonTypes = data
                            self.getScheduleConfig()
                        }
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }

                    self.isLoadData = true
                    self.tableView.reloadData()

                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func getScheduleConfig() {
        addSubscribe(
            LessonService.lessonScheduleConfigure.getScheduleConfigByStudentIdAndNoDelete(studentId: studentData.studentId, teacherId: studentData.teacherId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    self.scheduleConfigData.removeAll()
                    for doc in docs.documents {
                        if let doc = TKLessonScheduleConfigure.deserialize(from: doc.data()) {
                            for item in self.lessonTypes where item.id == doc.lessonTypeId {
                                doc.lessonType = item
                            }
                            if doc.lessonType != nil {
                                self.scheduleConfigData.append(doc)
                            }
                        }
                    }
                    self.isLoadData = true

                    self.tableView.reloadData()

                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.isLoadData = true
                    self.tableView.reloadData()
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func removeLesson(_ scheduleData: TKLessonScheduleConfigure, index: Int) {
        showFullScreenLoadingNoAutoHide()

        let nowTime = Date().timestamp
        if (scheduleData.repeatType == .none && scheduleData.startDateTime >= Double(nowTime)) || scheduleData.startDateTime >= Double(nowTime) {
            addSubscribe(
                CommonsService.shared.deleteLessonsAfterSpecificTimeBasedOnConfigId(time: nowTime, configId: scheduleData.id, studentId: scheduleData.studentId, teacherId: scheduleData.teacherId, isUpdate: false)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        EventBus.send(EventBus.CHANGE_SCHEDULE)
                        let studentId: String = self.scheduleConfigData[index].studentId
                        self.scheduleConfigData.remove(at: index)
                        self.tableView.reloadData()
                        print("成功")
                        if self.scheduleConfigData.count > 0 {
                            self.hideFullScreenLoading()
                            TKToast.show(msg: "Successfully deleted!", style: .success)
                        } else {
                            self.updataStudentList(studentId: studentId)
                        }
                    }, onError: { err in
                        logger.debug("获取失败:\(err)")
                        self.hideFullScreenLoading()
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    })
            )


        } else {

            addSubscribe(
                CommonsService.shared.deleteLessonsAfterSpecificTimeBasedOnConfigId(time: nowTime, configId: scheduleData.id, studentId: scheduleData.studentId, teacherId: scheduleData.teacherId, isUpdate: true)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }

                        EventBus.send(EventBus.CHANGE_SCHEDULE)
                        let studentId: String = self.scheduleConfigData[index].studentId
                        self.scheduleConfigData.remove(at: index)
                        self.tableView.reloadData()
                        if self.scheduleConfigData.count > 0 {
                            self.hideFullScreenLoading()
                            TKToast.show(msg: "Successfully deleted!", style: .success)
                        } else {
                            self.updataStudentList(studentId: studentId)
                        }

                    }, onError: { err in
                        logger.debug("获取失败:\(err)")
                        self.hideFullScreenLoading()
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    })
            )
        }
    }

    private func updataStudentList(studentId: String) {
        addSubscribe(
            UserService.student.updateStudent(studentId: studentId, updateData: ["invitedStatus":
                    "3"])
                .timeout(RxTimeInterval.seconds(TIME_OUT_TIME), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    EventBus.send(key: .refreshStudents)
                    TKToast.show(msg: "Successfully deleted!", style: .success)
                }, onError: { err in
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("获取失败:\(err)")
                })
        )
    }
}

// MARK: - TableView

extension StudentProfileController: UITableViewDelegate, UITableViewDataSource, StudentDetailsUserInfoCellDelegate, StudentdetailLessonCellDelegate, NewStudentViewControllerDelegate {
    func newStudentViewControllerAddNewStudentRefData(email: String, name: String, phone: String) {
        print("====\(email)===\(name)==\(phone)")
        studentData.email = email
        studentData.name = name
        studentData.phone = phone
        tableView.reloadData()
    }

    func newStudentViewControllerAddNewStudentCompletion(isExampleStudent: Bool,email:String) {
    }

    func studentdetailLessonCell(clickEdit isEdit: Bool, cell: StudentdetailLessonCell) {
        print("点击了isEdit:\(isEdit)")
        self.isEdit = isEdit
        tableView.beginUpdates()
        cell.mainView.snp.updateConstraints { make in
            if isEdit {
                make.height.equalTo(40.5 + 82.0 + (Double(scheduleConfigData.count) * 83))
            } else {
                make.height.equalTo(40.5 + (Double(scheduleConfigData.count) * 83))
            }
        }
        cell.addLessonView.snp.updateConstraints { make in
            make.height.equalTo(self.isEdit ? 82 : 0).priority(.high)
        }
        cell.layoutIfNeeded()
        tableView.endUpdates()
    }

    func studentdetailLessonCell(clickAdd cell: StudentdetailLessonCell) {
        print("点击了clickAdd:")
        let controller = AddLessonDetailController(studentData: studentData)
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func studentdetailLessonCell(clickDelete index: Int) {
        print("点击了clickDelete:\(index)")
//        SL.Alert.show(target: self, title: "", message: "\(TipMsg.deleteLessonTip)", leftButttonString: "GO BACK", rightButtonString: "DELETE", leftButtonAction: {
//        }) { [weak self] in
//            guard let self = self else { return }
//            self.removeLesson(id: self.scheduleData[index].id, index: index)
//        }
        let scheduleData = self.scheduleConfigData[index]
        SL.Alert.show(target: self, title: "", message: "\(TipMsg.deleteLessonTip)", leftButttonString: "DELETE", rightButtonString: "GO BACK", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
            guard let self = self else { return }
            self.removeLesson(scheduleData, index: index)
        }) {
        }
    }

    func studentdetailLessonCell(clickLesson index: Int) {
        print("点击了clickLesson:\(index)")

        let controller = AddLessonDetailController(studentData: studentData, isReschedule: true)
        controller.isStudentDetailEnter = true
        controller.hero.isEnabled = true
        controller.oldScheduleConfig = scheduleConfigData[index]
        controller.rescheduleStartTime = Date().startOfDay.timestamp
        controller.isReschedule = true
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func clickInfoButton() {
        if isEditStudentInfo {
            showFullScreenLoading()
            addSubscribe(
                UserService.user.getUserIsActive(id: studentData.studentId)
                    .timeout(RxTimeInterval.seconds(10), scheduler: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] data in
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                        if data {
                            TKToast.show(msg: "This student has already been activated. You cannot change his info!", style: .warning)
                        } else {
                            showEditStudentInfoAlert()
                        }

                    }, onError: { [weak self] err in
                        self?.hideFullScreenLoading()
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                        logger.debug("获取失败:\(err)")
                    })
            )
            func showEditStudentInfoAlert() {
                let controller = NewStudentViewController()
                controller.isEdit = true
                controller.delegate = self
                controller.oldStudentData = studentData
                controller.modalPresentationStyle = .custom
                present(controller, animated: false, completion: nil)
            }

            return
        }

        var items: [TKPopAction.Item] = []
        if studentData.phone != "" {
            items.append(
                TKPopAction.Item(title: studentData.phone) {
                    let phone = "telprompt://\(self.studentData.phone)"
                    if UIApplication.shared.canOpenURL(URL(string: phone)!) {
                        UIApplication.shared.open(URL(string: phone)!, options: [:], completionHandler: nil)
                    }
                })
        }
        if studentData.email != "" {
            items.append(
                TKPopAction.Item(title: studentData.email) {
                    self.sendEmail()
                }
            )
        }
        TKPopAction.show(items: items, isCancelShow: true, target: self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoadData {
            return 2
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let id = String(describing: StudentDetailsUserInfoCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: id) as! StudentDetailsUserInfoCell
            cell.initData(studentData, isEditStudentInfo: isEditStudentInfo)
            cell.delegate = self
            cell.selectionStyle = .none
            return cell

        } else {
            let id = String(describing: StudentdetailLessonCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: id) as! StudentdetailLessonCell
            cell.selectionStyle = .none
            cell.delegate = self
            cell.initData(isEdit: isEdit, data: scheduleConfigData, instruments: instruments, reschedules: [:])
            return cell
        }
    }
}

// MARK: - Action

extension StudentProfileController {
}

extension StudentProfileController: MFMailComposeViewControllerDelegate {
    // MARK: - SendEmail

    func sendEmail() {
        // 0.首先判断设备是否能发送邮件
        if MFMailComposeViewController.canSendMail() {
            // 1.配置邮件窗口
            let mailView = configuredMailComposeViewController()
            // 2. 显示邮件窗口
            present(mailView, animated: true, completion: nil)
        } else {
            print("Whoop...设备不能发送邮件")
            showSendMailErrorAlert()
        }
    }

    // 提示框，提示用户设置邮箱
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Mail is not turned on", message: TipMsg.accessForEmailApp, preferredStyle: .alert)
        sendMailErrorAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
        present(sendMailErrorAlert, animated: true) {}
    }

    // MARK: - helper methods

    // 配置邮件窗口
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self

        // 设置邮件地址、主题及正文
        mailComposeVC.setToRecipients([studentData.email])
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
