//
//  StudentDetailsViewController.swift
//  TuneKey
//  Created by Wht on 2019/8/20.
//  Copyright © 2019年 spelist. All rights reserved.
//

import Hero
import MessageUI
import PromiseKit
import SnapKit
import UIKit

class StudentDetailsViewController: TKBaseViewController {
    private var mainView = UIView()
    private var navigationBar: TKNormalNavigationBar!
    var studentData: TKStudent?
    var user: TKUser?
    private var lessonType: TKLessonType?
    private var tableView: UITableView!
    var isShowNavigationBar: Bool = true
    var isStudentEnter: Bool = false
    var isEditStudentInfo = false
    private var isEdit: Bool = false
    private var isLoadLesson: Bool = false
    private var lessonTypes: [TKLessonType]! = []
    private var scheduleConfigData: [TKLessonScheduleConfigure] = []

    private var buttonsLayout: TKView = TKView.create()

    private lazy var messageUnreadView: TKView = TKView.create()
        .corner(size: 11)
        .backgroundColor(color: ColorUtil.red)
    private lazy var messageContentLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 14))
        .textColor(color: .white)

    private var attendanceHeight: CGFloat = 84

    let items = [
        StudentDetailsCellStyle.userInfo,
        StudentDetailsCellStyle.lesson,
        StudentDetailsCellStyle.memo,
        StudentDetailsCellStyle.birthday,
        StudentDetailsCellStyle.attendance,
        StudentDetailsCellStyle.balance,
        StudentDetailsCellStyle.studentActivity,
        StudentDetailsCellStyle.achievement,
        StudentDetailsCellStyle.notes,
        StudentDetailsCellStyle.materials,
    ]

    private var materialsHeight: CGFloat = 0
    private var homeworkData: [TKPractice] = []
    private var achievementData: [TKAchievement] = []
    private var lessonSchedules: [TKLessonSchedule] = []
    private var scheduleData: [TKLessonSchedule] = []
    private var materialsData: [TKMaterial] = []
    private var achievementTop: CGFloat = -1

    private var chatButton: TKButton = {
        let button = TKButton.create()
            .title(title: "CHAT")
            .titleFont(font: FontUtil.bold(size: 15))
            .setImage(name: "message_white", size: CGSize(width: 22, height: 22))
            .backgroundColor(color: ColorUtil.main)
        button.corner(5)
        button.setShadows()
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        return button
    }()

    /// reschedule的数据 => key: configId | value: 重新预约的数据
    private var reschedulesData: [String: TKReschedule] = [:]

    private var latestTransaction: TKTransaction?
    private var nextBills: [TKInvoice] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.separatorStyle = .none
        logger.debug("进入学生详情页")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for item in items.enumerated() {
            if item.element == .lesson {
                if let cell = tableView.cellForRow(at: IndexPath(row: item.offset, section: 0)) as? StudentdetailLessonCell {
                    cell.refreshCorners()
                }
            }
        }
    }

    deinit {
        logger.debug("销毁 StudentDetailsViewController")
    }
}

extension StudentDetailsViewController {
    private func toChatDetail() {
        guard let student = studentData else { return }
        let id = student.studentId
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            ChatService.conversation.getPrivateFromLocal(userId: id)
                .done { [weak self] conversation in
                    guard let self = self else { return }
                    if let conversation = conversation {
                        MessagesViewController.show(conversation)
                    } else {
                        self.showFullScreenLoading()
                        ChatService.conversation.getPrivateWithoutLocal(id)
                            .done { conversation in
                                MessagesViewController.show(conversation)
                            }
                            .catch { [weak self] error in
                                self?.hideFullScreenLoading()
                                logger.error("获取会话失败: \(error)")
                                TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                            }
                    }
                }
                .catch { error in
                    logger.error("获取会话失败: \(error)")
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                }
        }
    }
}

// MARK: - View

extension StudentDetailsViewController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Student Details")
        navigationBar.target = self
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            if isShowNavigationBar {
                make.height.equalTo(44)
            } else {
                make.height.equalTo(0)
            }
        }

        messageContentLabel.addTo(superView: messageUnreadView) { make in
            make.center.equalToSuperview()
        }
        messageUnreadView.isHidden = true
        initTableview()
    }

    func initTableview() {
        tableView = UITableView()
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.bounces = true
        tableView.dataSource = self
        tableView.separatorStyle = .none
        mainView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        tableView.register(StudentDetailsUserInfoCell.self, forCellReuseIdentifier: String(describing: StudentDetailsUserInfoCell.self))
        tableView.register(StudentDetailsInfoCell.self, forCellReuseIdentifier: String(describing: StudentDetailsInfoCell.self))
        tableView.register(StudentDetailsMaterialsCell.self, forCellReuseIdentifier: String(describing: StudentDetailsMaterialsCell.self))
        tableView.register(StudentdetailLessonCell.self, forCellReuseIdentifier: String(describing: StudentdetailLessonCell.self))
        tableView.register(StudentDetailsBalanceTableViewCell.self, forCellReuseIdentifier: StudentDetailsBalanceTableViewCell.id)
        tableView.register(StudentDetailsBirthdayTableViewCell.self, forCellReuseIdentifier: StudentDetailsBirthdayTableViewCell.id)
        tableView.register(StudentDetailsAttendanceTableViewCell.self, forCellReuseIdentifier: StudentDetailsAttendanceTableViewCell.id)
        tableView.register(StudentDetailsMemoTableViewCell.self, forCellReuseIdentifier: StudentDetailsMemoTableViewCell.id)
    }

    private func setButtonsLayout() {
        guard let student = studentData else { return }
        guard let role = ListenerService.shared.currentRole, role != .student else { return }

        buttonsLayout.subviews.forEach { view in
            view.removeFromSuperview()
        }
        buttonsLayout.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100)
        if student.invitedStatus == .none {
            if student.lessonTypeId != "" {
                let width = (UIScreen.main.bounds.width - 100) / 2
                // active
                TKButton.create()
                    .title(title: "Archive")
                    .titleFont(font: FontUtil.bold(size: 18))
                    .titleColor(color: ColorUtil.red)
                    .addTo(superView: buttonsLayout) { make in
                        make.width.equalTo(width)
//                        make.centerX.equalToSuperview()
                        make.left.equalToSuperview().offset(40)
                        make.height.equalTo(50)
                        make.centerY.equalToSuperview()
                    }
                    .onTapped { [weak self] _ in
                        self?.archiveStudent()
                    }

                chatButton.addTo(superView: buttonsLayout) { make in
                    make.width.equalTo(width)
                    make.right.equalToSuperview().offset(-40)
                    make.height.equalTo(50)
                    make.centerY.equalToSuperview()
                }
            } else {
                // inactive
                let width = (UIScreen.main.bounds.width - 80) / 3
                TKButton.create()
                    .title(title: "Archive")
                    .titleFont(font: FontUtil.bold(size: 18))
                    .titleColor(color: ColorUtil.main)
                    .addTo(superView: buttonsLayout) { make in
                        make.width.equalTo(width)
                        make.left.equalToSuperview().offset(20)
                        make.height.equalTo(50)
                        make.centerY.equalToSuperview()
                    }
                    .onTapped { [weak self] _ in
                        self?.archiveStudent()
                    }

                TKButton.create()
                    .title(title: "Delete")
                    .titleFont(font: FontUtil.bold(size: 18))
                    .titleColor(color: ColorUtil.red)
                    .addTo(superView: buttonsLayout) { make in
                        make.centerY.equalToSuperview()
                        make.width.equalTo(width)
                        make.height.equalTo(50)
                        make.centerX.equalToSuperview()
                    }
                    .onTapped { [weak self] _ in
                        self?.deleteStudent()
                    }

                chatButton.addTo(superView: buttonsLayout) { make in
                    make.centerY.equalToSuperview()
                    make.right.equalToSuperview().offset(-20)
                    make.width.equalTo(width)
                    make.height.equalTo(50)
                }
            }
        } else if student.invitedStatus == .archived {
            let width = (UIScreen.main.bounds.width - 100) / 2
            // archived
            TKButton.create()
                .title(title: "Delete")
                .titleFont(font: FontUtil.bold(size: 18))
                .titleColor(color: ColorUtil.red)
                .addTo(superView: buttonsLayout) { make in
                    make.centerY.equalToSuperview()
                    make.width.equalTo(width)
                    make.left.equalToSuperview().offset(40)
//                    make.centerX.equalToSuperview()
                    make.height.equalTo(50)
                }
                .onTapped { [weak self] _ in
                    self?.deleteStudent()
                }
            chatButton.addTo(superView: buttonsLayout) { make in
                make.width.equalTo(width)
                make.right.equalToSuperview().offset(-40)
                make.height.equalTo(50)
                make.centerY.equalToSuperview()
            }
        } else {
            let width = (UIScreen.main.bounds.width - 100) / 2
            // active
            TKButton.create()
                .title(title: "Archive")
                .titleFont(font: FontUtil.bold(size: 18))
                .titleColor(color: ColorUtil.red)
                .addTo(superView: buttonsLayout) { make in
                    make.width.equalTo(width)
//                    make.centerX.equalToSuperview()
                    make.left.equalToSuperview().offset(40)
                    make.height.equalTo(50)
                    make.centerY.equalToSuperview()
                }
                .onTapped { [weak self] _ in
                    self?.archiveStudent()
                }

            chatButton.addTo(superView: buttonsLayout) { make in
                make.width.equalTo(width)
                make.right.equalToSuperview().offset(-40)
                make.height.equalTo(50)
                make.centerY.equalToSuperview()
            }
        }
        messageUnreadView.addTo(superView: buttonsLayout) { make in
            make.top.equalTo(chatButton.snp.top).offset(-5)
            make.right.equalTo(chatButton.snp.right).offset(5)
            make.size.equalTo(22)
        }
        messageUnreadView.isHidden = true
        tableView.tableFooterView = buttonsLayout
    }

    func getMaterialsHeight() {
//        var height: CGFloat = 0
//        var num = 0
//        let screenWidth = UIScreen.main.bounds.width
//        let width = (screenWidth - 60) / 3
        materialsHeight = 82 + 70
//        var a = 0
//        if materialsData.count != 0 {
//            for item in materialsData.enumerated() where item.offset < 5 {
//                if num < 3 {
//                    num = num + 1
//                    if num == 1 {
//                        height = height + width + 75 + 20
//                        a += 1
//                    }
//                } else {
//                    num = 1
//                    height = height + width + 75 + 20
//                    a += 1
//                }
        ////                if item.element.type == .youtube {
        ////                    height = height + 210 + 35 + 20
        ////                    a += 1
        ////                    num = 0
        ////                } else {
        ////                    if num < 3 {
        ////                        num = num + 1
        ////                        if num == 1 {
        ////                            height = height + width + 75 + 20
        ////                            a += 1
        ////                        }
        ////                    } else {
        ////                        num = 1
        ////                        height = height + width + 75 + 20
        ////                        a += 1
        ////                    }
        ////                }
//            }
//            materialsHeight = height + 82
//        }
    }
}

extension StudentDetailsViewController {
    override func bindEvent() {
        super.bindEvent()
        chatButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.toChatDetail()
        }
    }
}

extension StudentDetailsViewController {
    private func archiveStudent() {
        guard let student = studentData else { return }
        SL.Alert.show(target: self, title: "", message: "Are you sure to Archive this student?", leftButttonString: "ARCHIVE", rightButtonString: "GO BACK", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
            guard let self = self else { return }
            self.showFullScreenLoading()
            self.addSubscribe(
                UserService.student.archive(studentIds: [student.studentId])
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        self.studentData?.invitedStatus = .archived
                        self.hideFullScreenLoading()
                        EventBus.send(EventBus.CHANGE_SCHEDULE_ONLINE)
                        EventBus.send(key: .teacherStudentListChanged)
                        self.setButtonsLayout()
                    }, onError: { [weak self] err in
                        guard let self = self else { return }
                        TKToast.show(msg: "Failed to archive, please try again later.", style: .warning)
                        self.hideFullScreenLoading()
                        logger.debug("======失败\(err)")
                    })
            )
        }) {
        }
    }

    private func deleteStudent() {
        guard let student = studentData else { return }
        SL.Alert.show(target: self, title: "", message: "Are you sure to delete this student?", leftButttonString: "DELETE", rightButtonString: "GO BACK", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
            guard let self = self else { return }
            self.showFullScreenLoading()
            self.addSubscribe(
                UserService.student.delete(studentIds: [student.studentId])
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        logger.debug("======成功")
                        self.hideFullScreenLoading()
                        EventBus.send(EventBus.CHANGE_SCHEDULE_ONLINE)
                        EventBus.send(key: .teacherStudentListChanged)
                        self.dismiss(animated: true, completion: nil)
                    }, onError: { [weak self] err in
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                        TKToast.show(msg: "Failed to delete, please try again later.", style: .warning)
                        logger.debug("======失败\(err)")
                    })
            )
        }) {
        }
    }
}

// MARK: - TableView

extension StudentDetailsViewController: UITableViewDelegate, UITableViewDataSource, StudentDetailsUserInfoCellDelegate, StudentDetailsMaterialsCellDelegate, StudentDetailsInfoCellDelegate, StudentdetailLessonCellDelegate {
    func studentdetailLessonCell(clickEdit isEdit: Bool, cell: StudentdetailLessonCell) {
        print("点击了isEdit:\(isEdit)")
        self.isEdit = isEdit
        tableView.beginUpdates()
        cell.mainView.snp.updateConstraints { make in
            if isEdit {
                make.height.equalTo(40.5 + 82.0 + (Double(scheduleConfigData.count) * 115))
            } else {
                make.height.equalTo(40.5 + (Double(scheduleConfigData.count) * 115))
            }
        }
        cell.addLessonView.snp.updateConstraints { make in
            make.height.equalTo(isEdit ? 82 : 0).priority(.high)
        }
        cell.layoutIfNeeded()
        tableView.endUpdates()
    }

    func studentdetailLessonCell(clickAdd cell: StudentdetailLessonCell) {
        print("点击了clickAdd:")
        if isStudentEnter {
            return
        }
        guard let studentData = studentData else { return }
        let controller = AddLessonDetailController(studentData: studentData)
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
        isEdit = false
        tableView.reloadData()
        setButtonsLayout()
    }

    func studentdetailLessonCell(clickDelete index: Int) {
        if isStudentEnter {
            return
        }
        let scheduleData = scheduleConfigData[index]
        SL.Alert.show(target: self, title: "", message: "\(TipMsg.deleteLessonTip)", leftButttonString: "DELETE", rightButtonString: "GO BACK", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main, leftButtonAction: { [weak self] in
            guard let self = self else { return }
            self.isEdit = false
            self.tableView.reloadData()
            self.removeLesson(scheduleData, index: index)
        }) {
        }
    }

    func studentdetailLessonCell(clickLesson index: Int) {
        if isStudentEnter {
            return
        }
        guard let studentData = studentData else { return }
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
        isEdit = false
        tableView.reloadData()
        setButtonsLayout()
    }

    func studentDetailsMaterialsCell(heightChanged height: CGFloat) {
        tableView.beginUpdates()
        materialsHeight = height
        tableView.endUpdates()
    }

    func clickCell(materialsData: TKMaterial, cell: MaterialsCell) {
        MaterialsHelper.cellClick(materialsData: materialsData, cell: cell, mController: self)
    }

    func clickMaterialsCell() {
        toMaterials()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch items[indexPath.row] {
        case .userInfo:
            return 120
        case .lesson:
            if isLoadLesson {
                var stackHeight: CGFloat = 0
                for item in scheduleConfigData {
                    if reschedulesData[item.id] != nil {
                        if item.repeatType == .none {
                            stackHeight += 138
                        } else {
                            stackHeight += 150
                        }
                    } else {
                        stackHeight += 115
                    }
                }
                if isEdit {
                    return CGFloat(40.5 + 82.0 + stackHeight + 20)
                } else {
                    if scheduleConfigData.count == 0 {
                        if isStudentEnter {
                            return 0
                        } else {
                            return CGFloat(40.5 + 82 + 20)
                        }
                    } else {
                        return CGFloat(40.5 + stackHeight + 20)
                    }
                }
            } else {
                return 0
            }
        case .balance:
            var height: CGFloat = 84
            if !nextBills.isEmpty || latestTransaction != nil {
                height += 10
                if !nextBills.isEmpty {
                    let invoiceString: [String] = nextBills.compactMap({ "$\($0.totalAmount.doubleValue.amountFormat()) due \(Date(seconds: $0.billingTimestamp + (TimeInterval($0.quickInvoiceDueDate) * 86400)).toLocalFormat("MM/dd/yyyy"))" })
                    let selectedText = invoiceString.joined(separator: ", ")
                    let allText = "\(selectedText)"
                    let text = Tools.attributenStringColor(text: allText, selectedText: selectedText, allColor: ColorUtil.Font.fourth, selectedColor: ColorUtil.Font.second, font: FontUtil.regular(size: 13), selectedFont: FontUtil.regular(size: 13), fontSize: 13, selectedFontSize: 13, ignoreCase: true, charasetSpace: 0)
                    height += text.height(withFixedWidth: UIScreen.main.bounds.width - 82 - 40 - 52)
                }
                if latestTransaction != nil {
                    height += 17
                }
            }

            return height
        case .studentActivity:
            return homeworkData.count > 0 ? 133 : 0
        case .achievement:
            return achievementData.count > 0 ? 133 : 0
        case .notes:
            return scheduleData.count > 0 ? 133 : 0
        case .materials:
            return materialsHeight
        case .birthday:
            return 134
        case .attendance:
            return attendanceHeight
        case .memo:
            return 134
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .userInfo:
            let id = String(describing: StudentDetailsUserInfoCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: id) as! StudentDetailsUserInfoCell
            if let studentData = studentData {
                cell.initData(studentData, isEditStudentInfo: isEditStudentInfo)
            }
            cell.delegate = self
            cell.selectionStyle = .none
            if isStudentEnter {
                cell.infoButton.setImage(UIImage(named: "arrowRight"), for: .normal)
                cell.backView.onViewTapped { [weak self] _ in
                    self?.clickInfoButton()
                }
            }
            return cell
        case .lesson:
            let id = String(describing: StudentdetailLessonCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: id) as! StudentdetailLessonCell
            cell.selectionStyle = .none
            cell.delegate = self
            cell.initData(isEdit: isEdit, data: scheduleConfigData, isStudentEnter: isStudentEnter, isLoadLesson: isLoadLesson, instruments: ListenerService.shared.instrumentsMap, reschedules: reschedulesData)
            return cell
        case .attendance:
            let cell = tableView.dequeueReusableCell(withIdentifier: StudentDetailsAttendanceTableViewCell.id, for: indexPath) as! StudentDetailsAttendanceTableViewCell
            if !lessonSchedules.isEmpty {
                if let firstLesson = lessonSchedules.filter({ $0.shouldDateTime <= Date().timeIntervalSince1970 }).sorted(by: { $0.shouldDateTime > $1.shouldDateTime }).first {
                    if let firstAttendance = firstLesson.attendance.sorted(by: { $0.createTime > $1.createTime }).first?.desc {
                        cell.latestAttendance = firstAttendance
                    } else {
                        cell.latestAttendance = "Normal @ \(Date(seconds: firstLesson.shouldDateTime).toLocalFormat("h:mm a, MM/dd/yyyy"))"
                    }
                } else {
                    cell.latestAttendance = ""
                }
            }
            attendanceHeight = cell.getCellHeight()

            cell.contentView.onViewTapped { [weak self] _ in
                guard let self = self, let student = self.studentData else { return }
                let controller = StudentDetailsAttendanceListViewController(student)
                controller.modalPresentationStyle = .fullScreen
                controller.hero.isEnabled = true
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                self.present(controller, animated: true)
            }
            return cell
        case .balance:
            let cell = tableView.dequeueReusableCell(withIdentifier: StudentDetailsBalanceTableViewCell.id, for: indexPath) as! StudentDetailsBalanceTableViewCell
            cell.lastPaymentAmount = ""
            var lastPayment: NSAttributedString?
            var nextBillString: NSAttributedString?
            if let lastPaymentTransaction = latestTransaction {
                let selectedText = "$\(lastPaymentTransaction.amount.doubleValue.amountFormat()) on \(Date(seconds: lastPaymentTransaction.createTimestamp).toLocalFormat("MM/dd/yyyy"))"
                lastPayment = Tools.attributenStringColor(text: "Last payment: \(selectedText)", selectedText: selectedText, allColor: ColorUtil.Font.fourth, selectedColor: ColorUtil.Font.second, font: FontUtil.regular(size: 13), selectedFont: FontUtil.regular(size: 13), fontSize: 13, selectedFontSize: 13, ignoreCase: true, charasetSpace: 0)
            }
            if !nextBills.isEmpty {
                let invoiceString: [String] = nextBills.compactMap({ "$\($0.totalAmount.doubleValue.amountFormat()) due \(Date(seconds: $0.billingTimestamp + (TimeInterval($0.quickInvoiceDueDate) * 86400)).toLocalFormat("MM/dd/yyyy"))" })
                let selectedText = invoiceString.joined(separator: ", ")
                nextBillString = Tools.attributenStringColor(text: "\(selectedText)", selectedText: selectedText, allColor: ColorUtil.red, selectedColor: ColorUtil.red, font: FontUtil.regular(size: 13), selectedFont: FontUtil.regular(size: 13), fontSize: 13, selectedFontSize: 13, ignoreCase: true, charasetSpace: 0)
            }
            cell.loadData(lastPayment: lastPayment, nextBill: nextBillString)
            if isStudentEnter {
                cell.addInvoiceButton.isHidden = true
            } else {
                cell.addInvoiceButton.isHidden = false
                if let studentData = studentData {
                    if studentData.invoiceBalance == 0 {
                        cell.addInvoiceButton.title(title: "  Add invoice  ")
                    } else {
                        cell.addInvoiceButton.title(title: "  Record payment  ")
                    }
                }
            }

            cell.contentView.onViewTapped { [weak self] _ in
                self?.onBalanceCellTapped()
            }
            cell.addInvoiceButton.onTapped { [weak self] _ in
                self?.onBalanceCellTapped()
            }
            return cell
        case .studentActivity:
            let id = String(describing: StudentDetailsInfoCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: id) as! StudentDetailsInfoCell
            cell.delegate = self
            cell.initItem(style: items[indexPath.row], homeworkData: homeworkData, achievementData: achievementData, scheduleData: scheduleData, achievementTop: achievementTop)
            cell.selectionStyle = .none
            return cell
        case .achievement:
            let id = String(describing: StudentDetailsInfoCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: id) as! StudentDetailsInfoCell
            cell.delegate = self
            cell.initItem(style: items[indexPath.row], homeworkData: homeworkData, achievementData: achievementData, scheduleData: scheduleData, achievementTop: achievementTop)
            cell.selectionStyle = .none
            return cell
        case .notes:
            let id = String(describing: StudentDetailsInfoCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: id) as! StudentDetailsInfoCell
            cell.delegate = self
            cell.initItem(style: items[indexPath.row], homeworkData: homeworkData, achievementData: achievementData, scheduleData: scheduleData, achievementTop: achievementTop)
            cell.selectionStyle = .none
            return cell
        case .materials:
            let id = String(describing: StudentDetailsMaterialsCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: id) as! StudentDetailsMaterialsCell
            materialsHeight = cell.cellHeight
            cell.data = Array<TKMaterial>(materialsData.prefix(5))
            cell.tag = indexPath.row
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
        case .birthday:
            let cell = tableView.dequeueReusableCell(withIdentifier: StudentDetailsBirthdayTableViewCell.id, for: indexPath) as! StudentDetailsBirthdayTableViewCell
            logger.debug("加载birthday,用户数据是否存在: \(user?.toJSONString() ?? "")")
            if let user = user {
                cell.birthday = user.birthday
            } else {
                cell.birthday = 0
            }
            cell.contentView.onViewTapped { [weak self] _ in
                guard let self = self else { return }
                let controller = DatePickerViewController()
                if let user = self.user {
                    let defaultDate = DateInRegion(seconds: user.birthday, region: .localRegion)
                    controller.selectedYear = defaultDate.year
                    controller.selectedMonth = defaultDate.month
                    controller.selectedDay = defaultDate.day
                }
                controller.modalPresentationStyle = .custom
                Tools.getTopViewController()?.present(controller, animated: false)
                controller.onDateSelected = { [weak self] date in
                    guard let self = self else { return }
                    guard let user = self.user else { return }
                    self.showFullScreenLoadingNoAutoHide()
                    UserService.user.updateUserBirthday(user.userId, birthday: date.timeIntervalSince1970)
                        .done { _ in
                            self.hideFullScreenLoading()
                            self.user?.birthday = date.timeIntervalSince1970
                            cell.birthday = date.timeIntervalSince1970
                        }
                        .catch { error in
                            self.hideFullScreenLoading()
                            TKToast.show(msg: "Update student birthday failed, please try it later.", style: .error)
                            logger.error("发生错误: \(error)")
                        }
                }
            }
            return cell
        case .memo:
            let cell = tableView.dequeueReusableCell(withIdentifier: StudentDetailsMemoTableViewCell.id, for: indexPath) as! StudentDetailsMemoTableViewCell
            if let memo = studentData?.memo, !memo.isEmpty {
                cell.memo = memo
            } else {
                cell.memo = "Optional"
            }
            cell.contentView.onViewTapped { [weak self] _ in
                self?.onMemoTapped()
            }
            return cell
        }
    }

    func clickInfoButton() {
        if isEditStudentInfo {
            guard let studentData = studentData else { return }
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
        if isStudentEnter {
            logger.debug("点击进入学生的edit页面")
            guard let user = ListenerService.shared.user else {
                logger.debug("当前用户没有信息,返回")
                return
            }
            logger.debug("进入个人信息修改页,当前用户信息: \(user.toJSONString() ?? "")")
            let controller = SProfileUserInfoController()
            controller.navigationBar.hiddenRightButton()
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.user = user
            controller.enablePanToDismiss()
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            present(controller, animated: true, completion: nil)

        } else {
            guard let studentData = studentData else { return }
            var items: [TKPopAction.Item] = []
            if studentData.phone != "" {
                items.append(
                    TKPopAction.Item(title: studentData.phone) {
                        let phone = "telprompt://\(studentData.phone)"
                        guard let url = URL(string: phone) else { return }
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    })
            }
            if studentData.email != "" {
                items.append(
                    TKPopAction.Item(title: studentData.email) { [weak self] in
                        guard let self = self else { return }
                        self.sendEmail()
                    }
                )
            }
            items.append(.init(title: "Edit name", action: {
                let controller = TeacherEditStudentNameViewController(studentData)
                controller.modalPresentationStyle = .custom
                Tools.getTopViewController()?.present(controller, animated: false, completion: nil)
            }))
            TKPopAction.show(items: items, isCancelShow: true, target: self)
        }
    }

    func clickStudentInfoCell(style: StudentDetailsCellStyle) {
        switch style {
        case .userInfo:
            break
        case .lesson:
            break
        case .balance:
            break
        case .studentActivity:
            toPractice()
            break
        case .achievement:
            toAchievement()
            break
        case .notes:
            toNotes()
            break
        case .materials:
            break
        case .birthday:
            logger.debug("点击birthday")
        case .attendance, .memo:
            break
        }
    }
}

// MARK: - Data

extension StudentDetailsViewController {
    override func initData() {
        refreshUnreadCount()
        initAchievementData()
        initScheduleData()
        initMaterilasData()
        getLessonType()
        getStudentBalanceLastPaymentInfo()
        getStudentNextBillInfo()
        loadUser()
        EventBus.listen(EventBus.CHANGE_SCHEDULE, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.getLessonType()
        }
        EventBus.listen(key: .unreadCountChanged, target: self) { [weak self] _ in
            self?.refreshUnreadCount()
        }
        EventBus.listen(key: .conversationSyncSuccess, target: self) { [weak self] _ in
            self?.refreshUnreadCount()
        }

        EventBus.listen(key: .teacherStudentListChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            guard let studentId = self.studentData?.studentId else { return }
            DispatchQueue.main.async {
                self.studentData = ListenerService.shared.teacherData.studentList.first(where: { $0.studentId == studentId })
                self.tableView?.reloadData()
            }
        }

        EventBus.listen(key: .manualInvoiceAddSuccessfully, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.getStudentNextBillInfo()
            self.getStudentBalanceLastPaymentInfo()
        }
        EventBus.listen(key: .manualInvoiceVoidSuccessfully, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.getStudentNextBillInfo()
            self.getStudentBalanceLastPaymentInfo()
        }
        EventBus.listen(key: .manualInvoiceWaiveSuccessfully, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.getStudentNextBillInfo()
            self.getStudentBalanceLastPaymentInfo()
        }
        EventBus.listen(key: .manualInvoiceRefundSuccessfully, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.getStudentNextBillInfo()
            self.getStudentBalanceLastPaymentInfo()
        }
    }

    private func loadAllRecentllyReschedule() {
        // 根据config,获取最近的没有到的reschedule数据
        logger.debug("[Reschedule获取] => 开始")
        guard scheduleConfigData.count > 0 else { return }
        let configIds = scheduleConfigData.compactMap { $0.id }
        let actions: [Promise<[String: TKReschedule]>] = configIds.compactMap { loadRecentllyRescheduleData(configId: $0) }
        when(fulfilled: actions)
            .done { [weak self] result in
                guard let self = self else { return }
                result.forEach { item in
                    for (key, value) in item {
                        self.reschedulesData[key] = value
                    }
                }
                for item in self.items.enumerated() {
                    if item.element == .lesson {
                        self.tableView.reloadRows(at: [IndexPath(row: item.offset, section: 0)], with: .none)
                        break
                    }
                }
                self.setButtonsLayout()
            }
            .catch { error in
                logger.error("[Reschedule获取] => 查询出错: \(error)")
            }
    }

    private func loadRecentllyRescheduleData(configId: String) -> Promise<[String: TKReschedule]> {
        return Promise { resovler in
            // 先获取最近的被reschedule的课程
            DatabaseService.collections.lessonSchedule()
                .whereField("lessonScheduleConfigId", isEqualTo: configId)
                .whereField("rescheduled", isEqualTo: true)
                .whereField("shouldDateTime", isGreaterThanOrEqualTo: Date().timestamp)
                .order(by: "shouldDateTime", descending: true)
                .getDocuments { snapshot, error in
                    guard let data = [TKLessonSchedule].deserialize(from: snapshot?.documents.compactMap { $0.data() }) as? [TKLessonSchedule] else {
                        logger.debug("[Reschedule获取] => 没有获取成功,错误: \(String(describing: error))")
                        return resovler.fulfill([:])
                    }
                    logger.debug("[Reschedule获取] => config[\(configId)] 获取出来的schedule数据: \(data.toJSONString() ?? "")")
                    var list = data.filter { $0.rescheduleId.count > 0 }
                    list.sort { l1, l2 in
                        l1.shouldDateTime < l2.shouldDateTime
                    }
                    logger.debug("[Reschedule获取] => 过滤掉的数据: \(list.toJSONString() ?? "")")
                    guard let lessonSchedule = list.first else {
                        return resovler.fulfill([:])
                    }
                    // 根据当前的rescheduleId获取reschedule数据
                    let rescheduleId = lessonSchedule.rescheduleId
                    guard rescheduleId.count > 0 else { return resovler.fulfill([:]) }
                    logger.debug("[Reschedule获取] => 获取Reschedule数据: \(rescheduleId)")
                    DatabaseService.collections.lessonReSchedule()
                        .whereField("rescheduleId", isEqualTo: rescheduleId)
                        .getDocuments(completion: { snapshot, _ in
                            guard let data = [TKReschedule].deserialize(from: snapshot?.documents.compactMap { $0.data() }) as? [TKReschedule], let reschedule = data.first else {
                                resovler.fulfill([:])
                                return
                            }
                            logger.debug("[Reschedule获取] => 获取出来的reschedule数据: \(reschedule.toJSONString() ?? "")")
                            resovler.fulfill([configId: reschedule])
                        })
                }
        }
    }

//    private func loadAllInstruments() {
//        InstrumentService.shared.loadAllInstruments()
//            .done { [weak self] instruments in
//                guard let self = self else { return }
//                instruments.forEach { instrument in
//                    self.instruments[instrument.id.description] = instrument
//                }
//                for item in self.items.enumerated() {
//                    if item.element == .lesson {
//                        self.tableView.reloadRows(at: [IndexPath(row: item.offset, section: 0)], with: .none)
//                        break
//                    }
//                }
//            }
//            .catch { error in
//                logger.error("获取所有乐器失败: \(error)")
//            }
//    }

    private func refreshUnreadCount() {
        guard let student = studentData, let userId = UserService.user.id() else { return }
        ChatService.conversation.getPrivateFromLocal(userId: student.studentId)
            .done { [weak self] conversation in
                guard let self = self else { return }
                var count: Int = 0
                if let conversation = conversation {
                    if let user = conversation.users.filter({ $0.userId == userId }).first {
                        count = user.unreadMessageCount
                    }
                }
                logger.debug("未读消息数量: \(count)")
                if count > 0 {
                    self.messageUnreadView.isHidden = false
                    self.messageContentLabel.text = count.description
                } else {
                    self.messageContentLabel.text = ""
                    self.messageUnreadView.isHidden = true
                }
            }
            .catch { error in
                logger.error("获取本地会话失败: \(error)")
            }
    }

    private func getLessonType() {
        logger.debug("开始获取lesson type")
        var isLoad = false
        if isStudentEnter {
            guard let studentData = studentData else { return }
            addSubscribe(
                LessonService.lessonType.getByTeacherId(teacherId: studentData.teacherId)
                    .subscribe(onNext: { [weak self] docs in
                        guard let self = self else { return }
                        var data: [TKLessonType] = []
                        for doc in docs.documents {
                            if let doc = TKLessonType.deserialize(from: doc.data()) {
                                data.append(doc)
                            }
                        }
                        print("获取到的lesson type 个数\(data.count)")
                        self.lessonTypes = data
                        self.getScheduleConfig()

                    }, onError: { [weak self] err in
                        guard let self = self else { return }
                        self.isLoadLesson = true
                        self.tableView.reloadData()
                        self.setButtonsLayout()
                        logger.debug("获取失败:\(err)")
                    })
            )
        } else {
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
                        self.isLoadLesson = true
                        self.tableView.reloadData()
                        self.setButtonsLayout()
                        logger.debug("获取失败:\(err)")
                    })
            )
        }
    }

    func getScheduleConfig() {
        guard let studentData = studentData else { return }
        addSubscribe(
            LessonService.lessonScheduleConfigure.getScheduleConfigByStudentIdAndNoDelete(studentId: studentData.studentId, teacherId: studentData.teacherId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    self.scheduleConfigData.removeAll()
                    logger.debug("获取到的schedule config docs数量: \(docs.count)")
                    for doc in docs.documents {
                        if let doc = TKLessonScheduleConfigure.deserialize(from: doc.data()) {
                            for item in self.lessonTypes where item.id == doc.lessonTypeId {
                                doc.lessonType = item
                            }

//                            if doc.lessonType != nil {
                            self.scheduleConfigData.append(doc)
                            doc.lessonEndDateAndCount = LessonUtil.getLessonEndDateAndCount(data: doc)
//                            }
                        }
                    }
                    print("获取到的ScheduleConfig 个数\(self.scheduleConfigData.count)")
//                    self.loadAllRecentllyReschedule()
                    self.isLoadLesson = true
                    self.tableView.reloadData()
                    self.setButtonsLayout()
                }, onError: { [weak self] err in
                    guard let self = self else { return }
//                    self.loadAllRecentllyReschedule()
                    self.isLoadLesson = true
                    self.tableView.reloadData()
                    self.setButtonsLayout()
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
                        for (index, item) in self.items.enumerated() where item == .lesson {
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }
                        self.setButtonsLayout()
                        print("成功")
                        if self.scheduleConfigData.count > 0 {
                            self.hideFullScreenLoading()
                            TKToast.show(msg: "Successfully deleted!", style: .success)
                        } else {
                            self.updataStudentList(studentId: studentId)
                        }
                    }, onError: { [weak self] err in
                        guard let self = self else { return }
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
                        for (index, item) in self.items.enumerated() where item == .lesson {
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }
                        if self.scheduleConfigData.count > 0 {
                            self.hideFullScreenLoading()
                            TKToast.show(msg: "Successfully deleted!", style: .success)
                        } else {
                            self.updataStudentList(studentId: studentId)
                        }
                        self.setButtonsLayout()
                    }, onError: { [weak self] err in
                        guard let self = self else { return }
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

    private func initHomeworkData(startTime: TimeInterval, isCache: Bool) {
        guard let studentData = studentData else { return }
        logger.debug("开始获取学生练习数据: \(studentData.studentId) -> startTime: \(startTime)")
//        LessonService.lessonSchedule.getPracticeData(studentData.studentId, startTime: 0)
        LessonService.lessonSchedule.getPracticeData(studentData.studentId, startTime: 0)
            .done { [weak self] data in
                guard let self = self else { return }
                var newData: [TKPractice] = []
                data.forEachItems { item, _ in
                    if item.assignment {
                        var index = -1
                        for newItem in newData.enumerated() where newItem.element.lessonScheduleId == item.lessonScheduleId && newItem.element.name == item.name && newItem.element.startTime != item.startTime {
                            index = newItem.offset
                        }
                        if index >= 0 {
                            newData[index].recordData += item.recordData
                            if item.done {
                                newData[index].done = true
                            }
                            newData[index].totalTimeLength += item.totalTimeLength
                        } else {
                            newData.append(item)
                        }
                    } else {
                        newData.append(item)
                    }
                }

                self.homeworkData = newData
                logger.debug("获取学生练习数据: \(newData.toJSONString() ?? "")")

                self.tableView.reloadData()
                self.setButtonsLayout()
            }
            .catch { error in
                logger.error("获取学生练习数据失败: \(error)")
            }
    }

    private func initAchievementData() {
        guard let studentData = studentData else { return }
        var isLoad = false
        addSubscribe(
            LessonService.lessonSchedule.getScheduleAchievementByTeacherId(tId:
                studentData.teacherId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache], data.count < 0 {
                        isLoad = true
                        self.sortAchievementdata(data)
                    }
                    if let data = data[.server] {
                        if !isLoad {
                            self.sortAchievementdata(data)
                        }
                    }
                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func getAchievementRanking(data: [String: Int]) -> Int {
        let data = data.sorted { a, b -> Bool in
            a.value > b.value
        }
        var index = 0 // 排名
        var lastCount = -1 // 最近一次的数量
        for item in data where lastCount - item.value != 0 {
            lastCount = item.value
            index += 1
            if item.key == studentData?.studentId ?? "" {
                break
            }
        }
        return index
    }

    private func sortAchievementdata(_ data: [TKAchievement]) {
        achievementData = []
        struct AchievemenSortData {
            var studentId: String = ""
            var count: Int = 0
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var sortData: [String: Int] = [:]
            let json: String = SLCache.main.get(key: SLCache.STUDENT_LIST)
            if let studentData = [TKStudent].deserialize(from: json) {
                for item in data {
                    for s in studentData {
                        if sortData[s!.studentId] != nil {
                            if item.studentId == s?.studentId {
                                sortData[s!.studentId] = sortData[s!.studentId]! + 1
                            }
                        } else {
                            if item.studentId == s?.studentId {
                                sortData[s!.studentId] = 1
                            } else {
                                sortData[s!.studentId] = 0
                            }
                        }
                    }
                }
            }

            if sortData.count != 0 {
                let index = self.getAchievementRanking(data: sortData)
                if index != 0 {
                    self.achievementTop = CGFloat(index) / CGFloat(sortData.count)
                    OperationQueue.main.addOperation {
                        self.tableView?.reloadData()
                        self.setButtonsLayout()
                    }
                }
            }
        }

        for item in data where item.studentId == studentData?.studentId ?? "" {
            achievementData.append(item)
        }
        if achievementData.count == 0 {
            OperationQueue.main.addOperation { [weak self] in
                guard let self = self else { return }
                self.tableView?.reloadData()
                self.setButtonsLayout()
            }
            return
        }
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            self.tableView?.reloadData()
            self.setButtonsLayout()
        }
    }

    private func initScheduleData() {
        guard let studentData = studentData else { return }
        addSubscribe(
            LessonService.lessonSchedule.getScheduleByStudentIdAndTeacherId(tId:
                studentData.teacherId, sId: studentData.studentId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    self.scheduleData.removeAll()
                    if let data = data[.cache] {
                        self.lessonSchedules = data
                        for item in data where item.teacherNote != "" || item.studentNote != "" {
                            self.scheduleData.append(item)
                        }
                        if data.count > 0 {
                            self.initHomeworkData(startTime: data[0].shouldDateTime, isCache: true)
                        }
                        self.tableView.reloadData()
                        self.setButtonsLayout()
                    }
                    if let data = data[.server] {
                        self.lessonSchedules = data
                        for item in data where item.teacherNote != "" {
                            self.scheduleData.append(item)
                        }
                        if data.count > 0 {
                            self.initHomeworkData(startTime: data[0].shouldDateTime, isCache: false)
                        }
                        self.tableView.reloadData()
                        self.setButtonsLayout()
                    }
                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func initMaterilasData() {
        guard let studentData = studentData else { return }
        addSubscribe(
            MaterialService.shared.materialListByTeacherAndStudentId(tId: studentData.teacherId, sId: studentData.studentId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKMaterial] = []
                    for item in docs.documents {
                        if let doc = TKMaterial.deserialize(from: item.data()) {
                            data.append(doc)
                        }
                    }
                    let folders = data.filter { $0.type == .folder }.compactMap { $0.id }
                    self.materialsData = data.filter({ $0.folder == "" || ($0.folder != "" && !folders.contains($0.folder)) })
                    self.getMaterialsHeight()
                    print("==获取到的materialsData个数=\(data.count)=")
                    self.tableView.reloadData()
                    self.setButtonsLayout()

                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func getMaterilasData(_ controlsData: [TKMaterialOpenControl]) {
        if controlsData.count == 0 {
            return
        }
        var ids: [String] = []
        for item in controlsData {
            ids.append(item.materialId)
        }
        addSubscribe(
            MaterialService.shared.materialListByIds(ids: ids)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache] {
                        self.materialsData = data
                        self.getMaterialsHeight()
                        self.tableView.reloadData()
                        self.setButtonsLayout()
                    }
                    if let data = data[.server] {
                        self.materialsData = data
                        self.getMaterialsHeight()
                        self.tableView.reloadData()
                        self.setButtonsLayout()
                    }
                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func getStudentBalanceLastPaymentInfo() {
        guard let student = studentData else { return }
        // 获取最后一个当前学生的支付订单
        DatabaseService.collections.transactions()
            .whereField("payerId", isEqualTo: student.studentId)
            .whereField("transactionType", isEqualTo: TKTransaction.TransactionType.pay.rawValue)
            .order(by: "createTimestamp", descending: true)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let doc = snapshot?.documents.first, let transaction = TKTransaction.deserialize(from: doc.data()) {
                    self.latestTransaction = transaction
                    logger.debug("[balance相关] => 获取到transaction: \(transaction.toJSONString() ?? "")")
                } else {
                    self.latestTransaction = nil
                    logger.error("[balance相关] => 当前获取最后交易失败: \(String(describing: error))")
                }
                self.reloadBalanceCell()
            }
    }

    private func getStudentNextBillInfo() {
        guard let student = studentData else { return }
        DatabaseService.collections.invoice()
            .whereField("studentId", isEqualTo: student.studentId)
            .whereField("teacherId", isEqualTo: student.teacherId)
            .whereField("status", in: [TKInvoiceStatus.created.rawValue, TKInvoiceStatus.sent.rawValue, TKInvoiceStatus.paying.rawValue])
            .order(by: "billingTimestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let docs = snapshot?.documents, let invoices: [TKInvoice] = [TKInvoice].deserialize(from: docs.compactMap({ $0.data() })) as? [TKInvoice] {
                    if self.isStudentEnter {
                        self.nextBills = invoices.filter({ !$0.markAsPay })
                    } else {
                        self.nextBills = invoices
                    }
                } else {
                    self.nextBills = []
                    logger.error("[balance相关] => 获取nextBill失败: \(String(describing: error))")
                }
                self.reloadBalanceCell()
            }
    }

    private func reloadBalanceCell() {
        for (index, item) in items.enumerated() {
            if item == .balance {
                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                break
            }
        }
    }

    private func loadUser() {
        guard let student = studentData else { return }
        UserService.user.getUserInfo(userId: student.studentId)
            .done { [weak self] user in
                guard let self = self else { return }
                logger.debug("获取到的用户个人信息: \(user?.toJSONString() ?? "")")
                self.user = user
                self.tableView.reloadData()
            }
            .catch { [weak self] error in
                logger.error("获取用户失败: \(error)")
                self?.tableView.reloadData()
            }
    }
}

// MARK: - Action

extension StudentDetailsViewController: MFMailComposeViewControllerDelegate, NewStudentViewControllerDelegate {
    func newStudentViewControllerAddNewStudentCompletion(isExampleStudent: Bool, email: String) {
    }

    func newStudentViewControllerAddNewStudentRefData(email: String, name: String, phone: String) {
        print("====\(email)===\(name)==\(phone)")
        studentData?.email = email
        studentData?.name = name
        studentData?.phone = phone
        tableView.reloadData()
        setButtonsLayout()
    }

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

        if let studentData = studentData {
            // 设置邮件地址、主题及正文
            mailComposeVC.setToRecipients([studentData.email])
        }
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

    func toPractice() {
        guard let studentData = studentData else { return }
        let controller = PracticeViewController()
        controller.studentId = studentData.studentId
        controller.teacherId = studentData.teacherId
        controller.practiceData = homeworkData
        controller.type = .studentDetail
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func toAchievement() {
        guard let studentData = studentData else { return }
        let controller = AchievementViewController()
        controller.hero.isEnabled = true
        controller.isStudentEnter = isStudentEnter
        controller.teacherId = studentData.teacherId
        controller.studentId = studentData.studentId
        controller.data = achievementData
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func toNotes() {
        let controller = NotesViewController()
        controller.hero.isEnabled = true
        controller.data = scheduleData.sorted(by: { $0.shouldDateTime > $1.shouldDateTime })
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func toMaterials() {
        let controller = Materials2ViewController(type: .list, isEdit: false, data: materialsData)
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }
}

extension StudentDetailsViewController {
    private func onBalanceCellTapped() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let student = self.studentData else { return }
            let controller = StudentDetailsBalanceViewController(student)
            controller.isStudentView = self.isStudentEnter
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            self.present(controller, animated: true, completion: nil)
        }
    }
}

extension StudentDetailsViewController {
    private func onMemoTapped() {
        guard let student = studentData else { return }
        let controller = LessonDetailAddNewContentViewController()
        controller.titleString = "Memo"
        controller.rightButtonString = "CONFIRM"
        controller.text = student.memo
        controller.modalPresentationStyle = .custom
        present(controller, animated: false)
        controller.onRightButtonTapped = { [weak self] text in
            guard let self = self else { return }
            controller.showFullScreenLoadingNoAutoHide()
            self.updateMemo(text, forStudent: student) { error in
                controller.hideFullScreenLoading()
                if let error = error {
                    TKToast.show(msg: "Update memo failed, please try again later.", style: .error)
                    logger.error("update memo failed: \(error)")
                } else {
                    controller.hide()
                    self.studentData?.memo = text
                    for (index, cell) in self.items.enumerated() where cell == .memo {
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    }
                }
            }
        }
    }

    private func updateMemo(_ memo: String, forStudent student: TKStudent, completion: @escaping (Error?) -> Void) {
        DatabaseService.collections.teacherStudentList()
            .document("\(student.teacherId):\(student.studentId)")
            .updateData(["memo": memo]) { error in
                completion(error)
            }
    }
}
