//
//  ProfileMakeupPolicyViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/10/11.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileMakeupPolicyViewController: TKBaseViewController {
    private var navigationBar: TKNormalNavigationBar!
    private var tableView: UITableView!
    private var cell: SetPoliciesMakeupPoliciesTableViewCell!
    private var saveButton: TKBlockButton!

    private var height: CGFloat = 0

    var data: TKMakeupPolicy!

    private var isSaveButtonEnable: Bool = false {
        didSet {
            if saveButton == nil {
                initSaveButton()
            }
            if isSaveButtonEnable {
                saveButton.enable()
            } else {
                saveButton.disable()
            }
        }
    }

    override func onViewAppear() {
        tableView.reloadData()
        isSaveButtonEnable = false
    }
}

extension ProfileMakeupPolicyViewController {
    override func initView() {
        enablePanToDismiss()
        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Makeup Policy",target:self)
        navigationBar.updateLayout(target: self)

        tableView = UITableView()
        tableView.allowsSelection = false
        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedRowHeight = 10
        tableView.separatorStyle = .none
        tableView.backgroundView?.backgroundColor = ColorUtil.backgroundColor
        tableView.backgroundColor = ColorUtil.backgroundColor
        addSubview(view: tableView) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        tableView.slTableView.setup(target: self, cellClasses: SetPoliciesMakeupPoliciesTableViewCell.self)
    }

    private func initSaveButton() {
        let view = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
        view.frame = CGRect(x: 0, y: 0, width: TKScreen.width, height: 100)
        tableView.tableFooterView = view
        saveButton = TKBlockButton(frame: .zero, title: "SAVE")
        saveButton.disable()
        view.addSubview(view: saveButton) { make in
            make.center.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(50)
        }
        saveButton.onTapped { [weak self] _ in
            self?.updateMakeupPolicy()
        }
    }

    private func updateMakeupPolicy() {
        saveButton.startLoading { [weak self] in
            guard let self = self else { return }
            UserService.teacher.updateMakeupPolicy(data: self.data) { [weak self] isSuccess in
                guard let self = self else { return }
                if isSuccess {
                    self.saveButton.stopLoading { [weak self] in
                        guard let self = self else { return }
                        self.saveButton.disable()
                    }
                } else {
                    self.saveButton.stopLoadingWithFailed {
                        TKToast.show(msg: "Failed, try again later", style: .error)
                    }
                }
            }
        }
    }
}

extension ProfileMakeupPolicyViewController: SetPoliciesMakeupPoliciesTableViewCellDelegate {
    func setPoliciesMakeupPoliciesTableViewCell(dataChanged data: TKMakeupPolicy) {
        self.data = data
        isSaveButtonEnable = true
    }

    func setPoliciesMakeupPoliciesTableViewCell(heightChanged height: CGFloat) {
        SL.Executor.runAsync { [weak self] in
            guard let self = self else { return }
            self.tableView.beginUpdates()
            self.height = height
            self.tableView.endUpdates()
            self.isSaveButtonEnable = true
        }
    }

    func setPoliciesMakeupPoliciesTableViewCell(noticeRequiredChanged isOpen: Bool) {
        guard data != nil else {
            return
        }
        if isOpen {
            data.noticeRequired = 7
        } else {
            data.noticeRequired = 0
        }
        if cell != nil {
            cell.updateNoticeRequiredDays(days: data.noticeRequired)
        }
        isSaveButtonEnable = true
    }

    func setPoliciesMakeupPoliciesTableViewCellNoticeRequiredDaysTapped() {
        var data: [NSAttributedString] = []
        for i in 1 ... 7 {
            let text = Tools.attributenStringColor(text: "\(i) Days", selectedText: "Days", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.Font.third, font: FontUtil.bold(size: 32), fontSize: 32, selectedFontSize: 22, ignoreCase: true, charasetSpace: 0)
            data.append(text)
        }
        TKPicker.show(title: "Select days", data: data, defaultIndex: self.data.noticeRequired == 0 ? 0 : self.data.noticeRequired - 1, target: self, onChanged: { _, _ in
        }) { [weak self] index in
            logger.debug("选择了: \(index)")
            guard let self = self else { return }
            self.data.noticeRequired = index + 1
            if self.cell != nil {
                self.cell.updateNoticeRequiredDays(days: index + 1)
            }
            self.isSaveButtonEnable = true
        }
    }

    func setPoliciesMakeupPoliciesTableViewCell(makeupPeriodChanged isOpen: Bool) {
        guard data != nil else {
            return
        }
        if isOpen {
            data.makeupPeriod = 30
        } else {
            data.makeupPeriod = 0
        }
        if cell != nil {
            cell.updateMakeupPeriod(days: data.makeupPeriod)
        }
        isSaveButtonEnable = true
    }

    func setPoliciesMakeupPoliciesTableViewCellMakeupPeriodDaysTapped() {
        var data: [NSAttributedString] = []
        for i in 1 ... 30 {
            let text = Tools.attributenStringColor(text: "\(i) Days", selectedText: "Days", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.Font.third, font: FontUtil.bold(size: 32), fontSize: 32, selectedFontSize: 22, ignoreCase: true, charasetSpace: 0)
            data.append(text)
        }
        TKPicker.show(title: "Select days", data: data, defaultIndex: self.data.makeupPeriod == 0 ? 0 : self.data.makeupPeriod - 1, target: self, onChanged: { _, _ in }) { [weak self] index in
            guard let self = self else { return }
            self.data.makeupPeriod = index + 1
            if self.cell != nil {
                self.cell.updateMakeupPeriod(days: index + 1)
            }
        }
        isSaveButtonEnable = true
    }

    func setPoliciesMakeupPoliciesTableViewCellWeekDayFromTapped(data: TKPolicySelectedDay) {
        var _data = data
        TKTimePicker.show(between: TKTimePicker.Time(hour: 0, minute: 0), and: TKTimePicker.Time(hour: 22, minute: 59), defaultTime: TKTimePicker.Time(hour: data.fromHour, minute: data.fromMinute), target: self) { [weak self] time in
            guard let self = self else { return }
            logger.debug("selected time: \(time)")
            _data.fromHour = time.hour
            _data.fromMinute = time.minute
            // 判断结束时间是否大于初始时间,最短拉开10分钟间隔
            if _data.fromHour == _data.toHour {
                if _data.fromMinute >= _data.toMinute {
                    if _data.toMinute >= 50 {
                        _data.toHour += 1
                        _data.toMinute = 0
                    } else {
                        _data.toMinute += 10
                    }
                }
            } else if _data.fromHour > _data.toHour {
                _data.toHour = _data.fromHour + 1
                _data.toMinute = 0
            }
            for item in self.data.selectedDays.enumerated() {
                if _data.dayOfWeek == item.element.dayOfWeek {
                    self.data.selectedDays[item.offset] = _data
                    break
                }
            }

            self.cell.updateSelectedDays(data: _data)
            self.isSaveButtonEnable = true
        }
    }

    func setPoliciesMakeupPoliciesTableViewCellWeekDayToTapped(data: TKPolicySelectedDay) {
        var startHour: Int = 0
        var startMinute: Int = 0
        if data.fromMinute >= 50 {
            startHour = data.fromHour + 1
            startMinute = 0
        } else {
            startHour = data.fromHour
            startMinute = data.fromMinute + 10
        }
        var _data = data
        TKTimePicker.show(between: TKTimePicker.Time(hour: startHour, minute: startMinute), and: TKTimePicker.Time(hour: 23, minute: 50), defaultTime: TKTimePicker.Time(hour: data.toHour, minute: data.toMinute), target: self) { [weak self] time in
            guard let self = self else { return }
            _data.toHour = time.hour
            _data.toMinute = time.minute
            for item in self.data.selectedDays.enumerated() {
                if _data.dayOfWeek == item.element.dayOfWeek {
                    self.data.selectedDays[item.offset] = _data
                    break
                }
            }
            self.cell.updateSelectedDays(data: _data)
            self.isSaveButtonEnable = true
        }
    }
}

extension ProfileMakeupPolicyViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return height
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SetPoliciesMakeupPoliciesTableViewCell.self), for: indexPath) as! SetPoliciesMakeupPoliciesTableViewCell
        self.cell = cell
        if data != nil {
            cell.loadData(data: data)
        }
        cell.delegate = self
        height = cell.cellHeight
        return cell
    }
}
