//
//  PracticeDetailViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/1/28.
//  Copyright © 2021 spelist. All rights reserved.
//
import DZNEmptyDataSet
import RxSwift
import UIKit

class PracticeDetailViewController: TKBaseViewController {
    private var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "")
    private var tableView: UITableView = UITableView()

    private var data: TKPracticeAssignment? {
        didSet {
            logger.debug("当前设置的练习数据: \(data?.toJSONString() ?? "")")
        }
    }

    private var studentId: String = ""

    private var days: [Int] = []
    private var dataSource: [Int: [TKPractice]] = [:]

    convenience init(_ data: TKPracticeAssignment, studentId: String) {
        self.init(nibName: nil, bundle: nil)
        self.data = data
        self.studentId = studentId
    }
}

extension PracticeDetailViewController {
    override func initView() {
        super.initView()
        enablePanToDismiss()
        navigationBar.updateLayout(target: self)
//        if let data = data {
//            let startDateTime = Date(seconds: data.startTime)
//            let endDateTime: Date
//            let title: String
//            if data.endTime < 0 {
//                title = startDateTime.toLocalFormat("MMMM dd") + " - Today"
//            } else {
//                endDateTime = Date(seconds: data.endTime)
//                if startDateTime.month == endDateTime.month {
//                    title = startDateTime.toLocalFormat("MMMM dd") + " - " + endDateTime.toLocalFormat("dd")
//                } else {
//                    title = startDateTime.toLocalFormat("MMMM dd") + " - " + endDateTime.toLocalFormat("MMMM dd")
//                }
//            }
//
//            navigationBar.title = title
//        }
        navigationBar.title = "Practice"
        let headerView = UIView()
        headerView.backgroundColor = .white
        headerView.setTopRadius()
        headerView.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.height.equalTo(20)
        }
        tableView.addTo(superView: view) { make in
            make.top.equalTo(headerView.snp.bottom).offset(-10)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalToSuperview()
        }

        tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UiUtil.safeAreaBottom() + 20))
        tableView.register(PracticeDetailTableViewCell.self, forCellReuseIdentifier: String(describing: PracticeDetailTableViewCell.self))
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
    }

    override func initData() {
        super.initData()
        loadData()
    }

    private func loadData() {
        // 获取时间段内的所有练习记录
        guard let data = data else { return }
        navigationBar.startLoading()
        let startTime = data.startTime
        var endTime = data.endTime
        if endTime < 0 {
            endTime = TimeInterval(Date().endOfDay.timestamp)
        }
        let startDate = Date(seconds: startTime)
        let endDate = Date(seconds: endTime)
        logger.debug("查询参数: \(startTime) | \(endTime) | \(studentId) | \(startDate.toLocalFormat("yyyy-MM-dd HH:mm:ss")) -> \(endDate.toLocalFormat("yyyy-MM-dd HH:mm:ss")) | studentId: \(studentId)")
        DatabaseService.collections.practice()
            .whereField("studentId", isEqualTo: studentId)
            .whereField("startTime", isGreaterThanOrEqualTo: startTime)
            .whereField("startTime", isLessThanOrEqualTo: endTime)
            .getDocuments(source: .server) { [weak self] snapshot, error in
                guard let self = self else { return }
                self.navigationBar.stopLoading()
                if let error = error {
                    logger.error("获取练习记录失败: \(error)")
                } else {
                    if let docs = snapshot?.documents, let practiceData: [TKPractice] = [TKPractice].deserialize(from: docs.compactMap { $0.data() }) as? [TKPractice] {
                        self.days.removeAll()
                        for item in practiceData {
                            let day = Date(seconds: item.startTime).startOfDay.timestamp
                            if !self.days.contains(day) {
                                self.days.append(day)
                            }
                            var items = self.dataSource[day]
                            if items == nil {
                                items = []
                            }
                            items?.append(item)
                            self.dataSource[day] = items!
                        }
                    } else {
                        self.dataSource = [:]
                    }
                    self.days = self.days.sorted(by: { $0 > $1 })
                    logger.debug("获取之后的数据记录: \(self.dataSource.count)")
                    var addedPracticeIds: [String] = []
                    for (day, data) in self.dataSource {
                        var newData: [TKPractice] = []
                        for oldItem in data {
                            var pos: Int = -1
                            for (i, newItem) in newData.enumerated() {
                                if newItem.name == oldItem.name {
                                    logger.debug("[测试Practice] => 当前newItem: \(newItem.name) | oldItem: \(oldItem.name) | 相同:\(i)")
                                    pos = i
                                    break
                                }
                            }
                            logger.debug("[测试Practice] => 遍历到的pos: \(pos)")
                            if pos == -1 {
                                if !newData.contains(where: { $0.id == oldItem.id }) {
                                    newData.append(oldItem)
                                }
                            } else {
                                if !addedPracticeIds.contains(oldItem.id) {
                                    let newItem = newData[pos]
                                    newItem.recordData += oldItem.recordData
                                    newItem.totalTimeLength = newItem.totalTimeLength + oldItem.totalTimeLength
                                    newData[pos] = newItem
                                    addedPracticeIds.append(oldItem.id)
                                }
                            }
                        }
                        self.dataSource[day] = newData.sorted(by: { i1, i2 in
                            var time1: TimeInterval = 0
                            var time2: TimeInterval = 0
                            if let t1 = i1.recordData.sorted(by: { $0.startTime > $1.startTime }).first?.startTime {
                                time1 = t1
                            } else {
                                time1 = i1.startTime
                            }
                            if let t2 = i2.recordData.sorted(by: { $0.startTime > $1.startTime }).first?.startTime {
                                time2 = t2
                            } else {
                                time2 = i2.startTime
                            }
                            return time1 > time2
                        })
                    }
                    logger.debug("加载完成: \(self.dataSource.values.count)")
                    self.tableView.reloadData()
                }
            }
    }
}

extension PracticeDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        days.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PracticeDetailTableViewCell.self), for: indexPath) as! PracticeDetailTableViewCell
        cell.delegate = self
        let day = days[indexPath.row]
        if let items = dataSource[day] {
            cell.loadData(items)
        }
        return cell
    }
}

extension PracticeDetailViewController: PracticeDetailTableViewCellDelegate {
    func practiceDetailTableViewCell(playAudio data: TKPractice) {
        let controller = TKPracticeRecordingListViewController(data, style: .teacherView)
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
//        let controller = PlayAudiodController()
//        controller.data = data
//        controller.modalPresentationStyle = .custom
//        present(controller, animated: false, completion: nil)
    }
}
