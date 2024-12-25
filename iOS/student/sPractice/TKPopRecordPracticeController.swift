//
//  TKPopRecordPracticeController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/29.
//  Copyright © 2019年 spelist. All rights reserved.
//

import AVFoundation
import UIKit

class TKPopRecordPracticeController: TKBaseViewController {
    enum ShowType {
        case none
        case logTime
        case addPractice
    }

    enum PracticeType {
        case practice
        case log
    }

    private var mainView = UIView()
    private var backView = UIView()
    private var practiceCount = 0
    private var height: CGFloat = 0
    private var tableView: UITableView!
    private var historyTableView: UITableView!
    private var historyTableViewTag = 100
    private var addLayout: TKView!
    private var buttonLayout: TKView!
    private var leftButton: TKBlockButton!
    private var rightButton: TKBlockButton!
    private var titleLabel: TKLabel!
    private var textBox: TKTextBox!
    private var showType: ShowType = .none
    var practiceType: PracticeType = .practice
//    var schedule: TKLessonSchedule!
    var practiceHistoryData: [TKPractice] = []
    var practiceData: [TKPractice] = []
    var selectInde = 0
    var titleString: String! = ""
    var confirmAction: ((_ practices: [TKPractice]) -> Void)?
    var confirmLog: (() -> Void)?
    var confirmForVideo: ((TKPractice) -> Void)?
    var dayStartTime = Date().startOfDay.timestamp

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }

    override func onKeyboardShow(_ keyboardHeight: CGFloat) {
        super.onKeyboardShow(keyboardHeight)
        mainView.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.mainView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
            var historyHeight: CGFloat = 0
            self.practiceHistoryData.forEachItems { item, _ in
                historyHeight += item.name.getLableHeigh(font: FontUtil.regular(size: 17), width: UIScreen.main.bounds.width - 60) + 20
            }
            if historyHeight > 150 {
                historyHeight = 150
            }
            self.mainView.snp.updateConstraints { make in
                make.height.equalTo(231 + UiUtil.safeAreaBottom() + historyHeight)
            }
            self.historyTableView.snp.updateConstraints { make in
                make.height.equalTo(historyHeight)
            }
        }, completion: nil)
    }

    override func onKeyboardHide(_ keyboardHeight: CGFloat) {
        super.onKeyboardHide(keyboardHeight)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            var historyHeight: CGFloat = 0
            self.practiceHistoryData.forEachItems { item, _ in
                historyHeight += item.name.getLableHeigh(font: FontUtil.regular(size: 17), width: UIScreen.main.bounds.width - 60) + 20
            }
            if historyHeight > 300 {
                historyHeight = 300
            }
            SL.Animator.run(time: 0.3, animation: {
                self.mainView.snp.updateConstraints { make in
                    make.height.equalTo(231 + UiUtil.safeAreaBottom() + historyHeight)
                }
                self.historyTableView.snp.updateConstraints { make in
                    make.height.equalTo(historyHeight)
                }
            }) { _ in
            }
            self.mainView.transform = .identity
        }, completion: nil)
    }
}

// MARK: - View

extension TKPopRecordPracticeController {
    override func initView() {
        initBackView()
        practiceData.forEachItems { _, offset in
            if offset == 0 {
                practiceData[0]._isSelect = true
            }
        }
        practiceCount = practiceData.count
        view.backgroundColor = UIColor.clear
        var tableViewHeight = getTableViewHeight()
        if tableViewHeight > 300 {
            tableViewHeight = 300
        }
        height = 213 + tableViewHeight + UiUtil.safeAreaBottom()
        view.addSubview(view: mainView) { make in
            make.height.equalTo(height)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalToSuperview()
        }

        mainView.backgroundColor = UIColor.white
        mainView.setTopRadius()
        mainView.transform = CGAffineTransform(translationX: 0, y: height)
        titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .text(text: "\(titleString!)")
            .textColor(color: ColorUtil.Font.primary)
            .addTo(superView: mainView, withConstraints: { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(19)
                make.height.equalTo(20)
            })
        initTableView()
        initAddLayout()
        initBottomButtonLyout()
        initAddPractoce()
    }

    func initBackView() {
        backView.backgroundColor = UIColor.black.withAlphaComponent(0)
        view.addSubview(view: backView) { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-UiUtil.safeAreaBottom())
        }
        backView.isUserInteractionEnabled = true
        backView.onViewTapped { [weak self] _ in
            self?.hide()
        }
    }

    func initTableView() {
        tableView = UITableView()
        var tableViewHeight = getTableViewHeight()
//        var tableViewHeight = getTableViewHeight()
        if tableViewHeight > 300 {
            tableViewHeight = 300
        }
        tableView.backgroundColor = UIColor.white
        mainView.addSubview(view: tableView) { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
            make.height.equalTo(tableViewHeight)
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        tableView.register(RecordPracticeCell.self, forCellReuseIdentifier: String(describing: RecordPracticeCell.self))
    }

    func initAddLayout() {
        addLayout = TKView.create()
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalTo(20)
                make.right.equalTo(-20)
                make.height.equalTo(22)
                make.top.equalTo(tableView.snp.bottom).offset(25)
            })
        let addImageView = UIImageView()
        addImageView.image = UIImage(named: "icAddPrimary")
        addLayout.addSubview(view: addImageView) { make in
            make.size.equalTo(22)
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        _ = TKLabel.create()
            .font(font: FontUtil.regular(size: 17))
            .textColor(color: ColorUtil.main)
            .text(text: "Add practice")
            .addTo(superView: addLayout, withConstraints: { make in
                make.left.equalTo(addImageView.snp.right).offset(20)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
            })
        addLayout.onViewTapped { [weak self] _ in
            self?.addPractice()
        }
    }

    func initBottomButtonLyout() {
        buttonLayout = TKView()
        mainView.addSubview(view: buttonLayout) { make in
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-30 - UiUtil.safeAreaBottom())
            if deviceType == .phone {
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            } else {
                make.width.equalTo(340)
                make.centerX.equalToSuperview()
            }
        }
        var buttonWidth: CGFloat = 0
        if deviceType == .phone {
            buttonWidth = (UIScreen.main.bounds.width - 50) / 2
        } else {
            buttonWidth = 330 / 2
        }
        leftButton = TKBlockButton(frame: CGRect.zero, title: "CANCEL", style: .cancel)
        buttonLayout.addSubview(leftButton)
        leftButton.snp.makeConstraints { make in
            make.width.equalTo(buttonWidth)
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        leftButton.onTapped { [weak self] _ in
            self?.hide()
        }
        if practiceType == .practice {
            rightButton = TKBlockButton(frame: CGRect.zero, title: "GET STARTED", style: .normal)
        } else {
            rightButton = TKBlockButton(frame: CGRect.zero, title: "ADD MINUTES", style: .normal)
        }
        rightButton.disable()
        buttonLayout.addSubview(rightButton)
        rightButton.snp.makeConstraints { make in
            make.width.equalTo(buttonWidth)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        rightButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            if self.practiceData.isSafeIndex(self.selectInde) {
                logger.debug("点击button, 已选择的数据: \(self.practiceData[self.selectInde].toJSONString() ?? "")")
            }
            self.clickRightButton()
        }
    }

    func initAddPractoce() {
        textBox = TKTextBox.create()
            .placeholder("Practice")
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
                make.top.equalTo(titleLabel.snp.bottom).offset(28)
            })
        textBox.isHidden = true

        historyTableView = UITableView()
        historyTableView.backgroundColor = UIColor.white
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.tableFooterView = UIView()
        historyTableView.allowsSelection = false
        historyTableView.separatorStyle = .none
        historyTableView.tag = historyTableViewTag
        historyTableView.register(PraticeHistoryCell.self, forCellReuseIdentifier: String(describing: PraticeHistoryCell.self))
        mainView.addSubview(view: historyTableView) { make in
            make.top.equalTo(textBox.snp.bottom).offset(10)
            make.height.equalTo(0)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        historyTableView.isHidden = true
    }
}

// MARK: - Data

extension TKPopRecordPracticeController {
    override func initData() {
        practiceData.forEachItems { _, offset in
            practiceData[offset]._isSelect = false
        }
        if practiceData.count > 0 {
            practiceData[0]._isSelect = true
            rightButton.enable()
        }
        tableView.reloadData()
    }

    func completeLog(data: TKPractice) {
        guard let length = Float(textBox.getValue().trimmingCharacters(in: .whitespacesAndNewlines)) else {
            TKToast.show(msg: "Please enter the correct duration!", style: .warning)
            return
        }
        var updateData: [String: Any] = ["totalTimeLength": length * 60, "done": true, "manualLog": true, "updateTime": "\(Date().timestamp)"]
        var previewsLogDate: Date?
        if let date = currentSelectedPracticeDate {
            updateData["startTime"] = date.timeIntervalSince1970
            currentSelectedPracticeDate = nil
            previewsLogDate = date
        }
        showFullScreenLoading()
        addSubscribe(
            LessonService.lessonSchedule.updatePractice(id: data.id, data: updateData)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    EventBus.send(EventBus.CHANGE_PRACTICE)
                    self.hideFullScreenLoading()
                    self.confirmLog?()
                    if let date = previewsLogDate {
                        EventBus.send(key: .addedPreviewsLog, object: date)
                    }
                    self.hide()
                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("获取失败:\(err)")
                })
        )
    }

//    func complete(data: TKAssignment, isShowLoading: Bool) {
//        if isShowLoading {
//            showFullScreenLoading()
//        }
//
//        addSubscribe(
//            LessonService.lessonSchedule.updateAssignment(id: data.id, data: ["done": true, "timeLength": data.timeLength, "recordIds": data.recordIds, "recordFormats": data.recordFormats, "startTime": data.startTime, "lastTimeLength": data.lastTimeLength])
//                .subscribe(onNext: { [weak self] _ in
//                    guard let self = self else { return }
//                    EventBus.send(EventBus.CHANGE_PRACTICE)
//                    self.hideFullScreenLoading()
//                    self.hide()
//                }, onError: { [weak self] err in
//                    self?.hideFullScreenLoading()
//                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
//                    logger.debug("获取失败:\(err)")
//                })
//        )
//    }

    func addAssignment() {
        guard let studentData = StudentService.student else { return }
        
        let addData = TKPractice()
        let time = "\(Date().timestamp)"
        addData.id = time
        if let id = IDUtil.nextId(group: .lesson) {
            addData.id = "\(id)"
        }
        addData.studioId = studentData.studioId
        addData.subStudioId = studentData.subStudioId
        addData.studentId = studentData.studentId
        addData.startTime = Date().timeIntervalSince1970
        addData.totalTimeLength = 0
        addData.name = textBox.getValue().trimmingCharacters(in: .whitespacesAndNewlines)
        addData.createTime = time
        addData.updateTime = time
        addData._isSelect = true
        view.endEditing(true)
        showFullScreenLoading()
        addSubscribe(
            LessonService.lessonSchedule.addPractice(data: addData)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    EventBus.send(EventBus.CHANGE_PRACTICE)
                    self.practiceCount += 1

                    for item in self.practiceData.enumerated() {
                        self.practiceData[item.offset]._isSelect = false
                    }
                    self.practiceData.append(addData)
                    var tableViewHeight = self.getTableViewHeight()
                    if tableViewHeight > 300 {
                        tableViewHeight = 300
                    }
                    self.height = 213 + tableViewHeight + UiUtil.safeAreaBottom()
                    self.tableView.reloadData()
                    self.tableView.scrollToRow(at: IndexPath(row: self.practiceData.count - 1, section: 0), at: .bottom, animated: true)
                    self.rightButton.disable()
                    self.selectInde = self.practiceData.count - 1

                    SL.Animator.run(time: 0.2, animation: {
                        self.mainView.snp.updateConstraints { make in
                            make.height.equalTo(self.height)
                        }
                        self.tableView.snp.updateConstraints({ make in
                            make.height.equalTo(tableViewHeight)
                        })
                        self.historyTableView.snp.updateConstraints({ make in
                            make.height.equalTo(0)
                        })
                        self.view.layoutIfNeeded()
//                        for item in self.practiceData where item._isSelect {
//                            self.rightButton.enable()
//                        }
                        self.showType = .none
                        self.tableView.isHidden = false
                        self.addLayout.isHidden = false
                        self.textBox.isHidden = true
                        self.historyTableView.isHidden = true
                        self.hideFullScreenLoading()
                        self.rightButton.disable()
                        self.clickRightButton()

                    }) { _ in
                        self.textBox.clearText()
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

extension TKPopRecordPracticeController {
    override func bindEvent() {
        super.bindEvent()

        textBox?.onTyped { [weak self] value in
            guard let self = self, let textBox = self.textBox else { return }
            if textBox.placeholderLabel.text == "mins" {
                if let mins = Int(value) {
                    if mins > 300 {
                        textBox.value("300")
                    }
                }
            }
            self.onTypeEnd(string: value)
        }
    }
}

// MARK: - TableView

extension TKPopRecordPracticeController: UITableViewDelegate, UITableViewDataSource, RecordPracticeCellDelegate {
    func recordPracticeCell(clickCell cell: RecordPracticeCell) {
        practiceData.forEachItems { _, offset in
            practiceData[offset]._isSelect = false
        }
        practiceData[cell.tag]._isSelect = true

        rightButton.enable()
        selectInde = cell.tag
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return schedule.assignmentData.count
        if tableView.tag == historyTableViewTag {
            return practiceHistoryData.count
        } else {
            return practiceData.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == historyTableViewTag {
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PraticeHistoryCell.self), for: indexPath) as! PraticeHistoryCell
            cell.tag = indexPath.row
            cell.titleLabel.text("\((practiceHistoryData[indexPath.row].name).trimmingCharacters(in: .whitespacesAndNewlines))")
            cell.onViewTapped { [weak self] _ in
                guard let self = self else { return }
                self.textBox.value(self.practiceHistoryData[indexPath.row].name)
                if (self.practiceHistoryData[indexPath.row].name).count > 0 {
                    self.rightButton.enable()
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RecordPracticeCell.self), for: indexPath) as! RecordPracticeCell
            cell.tag = indexPath.row
            cell.delegate = self
            cell.initData(data: practiceData[indexPath.row])
            return cell
        }
    }

    private func getTableViewHeight() -> CGFloat {
        var height: CGFloat = 0
//        for item in schedule.assignmentData {
//            height += item.assignment.getLableHeigh(font: FontUtil.regular(size: 17), width: UIScreen.main.bounds.width - 20 - 50 - 10 - 20 - 22 - 20) + 20
//        }
        practiceData.forEachItems { item, _ in
            height += item.name.getLableHeigh(font: FontUtil.regular(size: 17), width: UIScreen.main.bounds.width - 142) + 20
        }

        return height + 10
    }
}

// MARK: - Action

extension TKPopRecordPracticeController {
    func addPractice() {
        var historyHeight: CGFloat = 0
        practiceHistoryData.forEachItems { item, _ in
            historyHeight += item.name.getLableHeigh(font: FontUtil.regular(size: 17), width: UIScreen.main.bounds.width - 60) + 20
        }
        if historyHeight > 300 {
            historyHeight = 300
        }
        historyTableView.snp.updateConstraints { make in
            make.height.equalTo(historyHeight)
        }
        historyTableView.isHidden = false
        SL.Animator.run(time: 0.2, animation: { [weak self] in
            guard let self = self else { return }
            self.mainView.snp.updateConstraints { make in
                make.height.equalTo(231 + UiUtil.safeAreaBottom() + historyHeight)
            }
            self.rightButton.disable()
            self.view.layoutIfNeeded()
            _ = self.textBox.inputType(TKTextBox.InputType.text)
            _ = self.textBox.keyboardType(.default)
            _ = self.textBox.placeholder("practice")
            self.showType = .addPractice
            self.tableView.isHidden = true
            self.addLayout.isHidden = true
            self.titleLabel.text("Add practice")
            if self.practiceType == .practice {
                self.rightButton.setTitle(title: "GET STARTED")
            } else {
                self.rightButton.setTitle(title: "ADD MINUTES")
            }
            self.textBox.isHidden = false
            if self.practiceHistoryData.count == 0 {
                self.textBox.setFocus()
            }
        }) { [weak self] _ in
            self?.textBox?.focus()
        }
    }

    func clickRightButton() {
        logger.debug("showType: \(showType)")
        switch showType {
        case .none:
            if practiceType == .log {
                SL.Animator.run(time: 0.3) { [weak self] in
                    guard let self = self else { return }
                    self.mainView.snp.updateConstraints { make in
                        make.height.equalTo(231 + UiUtil.safeAreaBottom())
                    }
                    self.view.layoutIfNeeded()
                    self.rightButton.disable()
                    self.showType = .logTime
                    _ = self.textBox.inputType(TKTextBox.InputType.number)
                    _ = self.textBox.keyboardType(.numberPad)
                    _ = self.textBox.placeholder("mins")
                    if let date = currentSelectedPracticeDate {
                        self.titleLabel.text("Log for \(date.toLocalFormat("MM/dd/yyyy"))")
                    } else {
                        self.titleLabel.text("Practice time")
                    }
                    self.rightButton.setTitle(title: "CONFIRM")
                    self.tableView.isHidden = true
                    self.addLayout.isHidden = true
                    self.textBox.isHidden = false
                    var timeLength: CGFloat = 0

                    timeLength = self.practiceData[self.selectInde].totalTimeLength

                    if timeLength > 0 {
                        timeLength = (timeLength / 60).roundTo(places: 1)
                        self.textBox.value("\(timeLength)")
                    }

                    self.textBox.setFocus()
                }
            } else {
                hide { [weak self] in
                    guard let self = self else { return }
                    self.confirmAction?(self.practiceData)
                    self.confirmForVideo?(self.practiceData[self.selectInde])
                }
            }
        case .logTime:
            if practiceType == .log {
                completeLog(data: practiceData[selectInde])
            }
        case .addPractice:
            rightButton.disable()
            addAssignment()
        }
    }

    func onTypeEnd(string: String) {
        if string.count == 0 {
            rightButton.disable()
        } else {
            rightButton.enable()
        }
    }
}

extension TKPopRecordPracticeController {
    func show() {
        UIView.animate(withDuration: 0.3) {
            self.backView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.mainView.transform = CGAffineTransform.identity
        }
    }

    @objc func clickBack(sender: UITapGestureRecognizer) {
        hide()
    }

    func hide(completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: 0.3, animations: {
            self.backView.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.mainView.frame.origin = CGPoint(x: 0, y: TKScreen.height)
        }) { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: false, completion: {
                completion()
            })
        }
    }
}
