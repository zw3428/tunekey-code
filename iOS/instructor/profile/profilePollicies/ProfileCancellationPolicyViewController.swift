//
//  ProfileCancellationPolicyViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/10/11.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileCancellationPolicyViewController: TKBaseViewController {
    private var navigationBar: TKNormalNavigationBar!
    private var tableView: UITableView!
    private var saveButton: TKBlockButton!

    private var cell: SetPoliciesCancellationTableViewCell!

    private var isSaveButtonEnable: Bool = false {
        didSet {
            if saveButton == nil {
                initSavedButton()
            }
            if isSaveButtonEnable {
                saveButton.enable()
            } else {
                saveButton.disable()
            }
        }
    }

    var data: TKCancellationPolicy!

    private var height: CGFloat = 0

    override func onViewAppear() {
        tableView.reloadData()
        isSaveButtonEnable = false
    }
}

extension ProfileCancellationPolicyViewController {
    override func initView() {
        enablePanToDismiss()
        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Cancellation Policy",target:self)
        navigationBar.updateLayout(target: self)

        tableView = UITableView()
        tableView.allowsSelection = false
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 10
        tableView.backgroundView?.backgroundColor = ColorUtil.backgroundColor
        tableView.backgroundColor = ColorUtil.backgroundColor
        addSubview(view: tableView) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        tableView.slTableView.setup(target: self, cellClasses: SetPoliciesCancellationTableViewCell.self)
    }

    private func initSavedButton() {
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
            self?.updateCancellationPolicy()
        }
    }

    private func updateCancellationPolicy() {
        saveButton.startLoading { [weak self] in
            guard let self = self else { return }
            UserService.teacher.updateCancellationPolicy(data: self.data) { [weak self] isSuccess in
                guard let self = self else { return }
                if isSuccess {
                    self.saveButton.stopLoading { [weak self] in
                        guard let self = self else { return }
                        self.saveButton.disable()
                    }
                } else {
                    self.saveButton.stopLoadingWithFailed {
                        TKToast.show(msg: TipMsg.updateFailed, style: .error)
                    }
                }
            }
        }
    }
}

extension ProfileCancellationPolicyViewController: SetPoliciesCancellationTableViewCellDelegate {
    func setPoliciesCancellationTableViewCell(heightChanged height: CGFloat) {
        SL.Executor.runAsync { [weak self] in
            guard let self = self else { return }
            self.tableView.beginUpdates()
            self.height = height
            self.tableView.endUpdates()
            self.isSaveButtonEnable = true
        }
    }

    func setPoliciesCancellationTableViewCellNoticeRequiredDaysTapped() {
        isSaveButtonEnable = true

        var data: [NSAttributedString] = []
        for i in 1 ... 30 {
            let text = Tools.attributenStringColor(text: "\(i) Days", selectedText: "Days", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.Font.third, font: FontUtil.bold(size: 32), fontSize: 32, selectedFontSize: 22, ignoreCase: true, charasetSpace: 0)
            data.append(text)
        }
//        TKPicker.show(title: "Select days", data: data, defaultIndex: self.data.noticeRequired == 0 ? 0 : self.data.noticeRequired - 1, target: self) { (index) in
//            logger.debug("选择了: \(index)")
//            self.data.noticeRequired = index + 1
//            if self.cell == nil {
//                self.cell = (self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! SetPoliciesCancellationTableViewCell)
//            }
//            self.cell.updateNoticeRequiredDays(days: index + 1)
//            self.isSaveButtonEnable = true
//        }
    }

    func setPoliciesCancellationTableViewCell(dataChanged data: TKCancellationPolicy) {
        self.data = data
        logger.debug("更改的数据: \(data.toJSONString(prettyPrint: true) ?? "")")
        isSaveButtonEnable = true
    }
}

extension ProfileCancellationPolicyViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return height
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SetPoliciesCancellationTableViewCell.self), for: indexPath) as! SetPoliciesCancellationTableViewCell
        cell.delegate = self
        height = cell.cellHeight
        if data != nil {
//            cell.loadData(data: data)
        }
        return cell
    }
}
