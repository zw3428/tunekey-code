//
//  LessonsCalendarFilterViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/17.
//  Copyright © 2019 spelist. All rights reserved.
//

import UIKit

protocol LessonsCalendarFilterViewControllerDelegate: NSObjectProtocol {
    func lessonsCalendarFilterViewControllerSelectCompletion(calendarDisplayType: TKCalendarDisplayType?, isGoogleCalendarShow: Bool)
}

class LessonsCalendarFilterViewController: TKBaseViewController {
    weak var delegate: LessonsCalendarFilterViewControllerDelegate?

    private var navigationBar: TKNormalNavigationBar!
    private var containerView: TKView!
    private var tableView: UITableView!

    var selectedFilter: TKCalendarDisplayType?

    var isGoogleCalendarShow: Bool = false
}

extension LessonsCalendarFilterViewController {
    override func initView() {
        initNavigationBar()
        initContainerView()
        initTableView()
    }

    private func initNavigationBar() {
        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Filter", rightButton: "", target: self, onRightButtonTapped: {
        })
        navigationBar.updateLayout(target: self)
    }

    private func initContainerView() {
        containerView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
            .showBorder(color: ColorUtil.borderColor)
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        containerView.isHidden = true
    }

    private func initTableView() {
        tableView = UITableView()
        containerView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(self.view.safeAreaInsets.left)
            make.right.equalToSuperview().offset(self.view.safeAreaInsets.right)
            make.bottom.equalToSuperview().offset(-self.view.safeAreaInsets.bottom)
        }
        tableView.delegate = self
        tableView.dataSource = self

        tableView.estimatedRowHeight = 0
        tableView.tableFooterView = UIView()

        tableView.allowsSelection = false

        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

        tableView.register(LessonsCalendarFilterItemTableViewCell.self, forCellReuseIdentifier: String(describing: LessonsCalendarFilterItemTableViewCell.self))
    }
}

extension LessonsCalendarFilterViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = TKView.create()
            .backgroundColor(color: UIColor.white)
        let label = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: section == 0 ? "Calendar view" : "Display")
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.left.equalToSuperview().offset(20)
        }
        return view
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }

    func numberOfSections(in tableView: UITableView) -> Int {
//        return 2
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        } else {
//            return 1
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LessonsCalendarFilterItemTableViewCell.self), for: indexPath) as! LessonsCalendarFilterItemTableViewCell
        cell.delegate = self
        if indexPath.section == 0 {
            var title: String!
            var isSelected: Bool!
            switch indexPath.row {
            case 0:
                title = "Day"
                isSelected = selectedFilter != nil && selectedFilter == .day
            case 1:
                title = "3 Days"
                isSelected = selectedFilter != nil && selectedFilter == .threeDays
            case 2:
                title = "7 Days"
                isSelected = selectedFilter != nil && selectedFilter == .week
            default:
                title = "Week/Month"
                isSelected = selectedFilter != nil && selectedFilter == .month
            }
            cell.loadData(title: title, isSelected: isSelected, isSwitchShow: false, indexPath: indexPath)
        } else {
            cell.loadData(title: "Show Google Calendar", isSelected: false, isSwitchShow: true, isSwitchOn: isGoogleCalendarShow, indexPath: indexPath)
        }
        return cell
    }
}

extension LessonsCalendarFilterViewController: LessonsCalendarFilterItemTableViewCellDelegate {
    func lessonsCalendarFilterItemTableViewCellTapped(index: IndexPath) {
        if index.section == 0 {
            let row = index.row
            switch row {
            case 0:
                selectedFilter = .day
            case 1:
                selectedFilter = .threeDays
            case 2:
                selectedFilter = .week
            default:
                selectedFilter = .month
            }
            tableView.reloadData()
        }
        delegate?.lessonsCalendarFilterViewControllerSelectCompletion(calendarDisplayType: selectedFilter, isGoogleCalendarShow: isGoogleCalendarShow)
        dismiss(animated: true) {
        }
    }

    func lessonsCalendarFilterItemTableViewCellIsGoogleCalendarShow(isShow: Bool) {
        isGoogleCalendarShow = isShow
        delegate?.lessonsCalendarFilterViewControllerSelectCompletion(calendarDisplayType: selectedFilter, isGoogleCalendarShow: isGoogleCalendarShow)
    }
}
