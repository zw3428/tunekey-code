//
//  SAchievementPracticeViewController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/25.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class SAchievementPracticeController: TKBaseViewController {
    var mainView = UIView()
    private var workHoursLabel: TKLabel!
    private var workHoursView: TKView!

    private var sessionsLabel: TKLabel!
    private var sessionsView: TKView!

    private var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewFlowLayout!
    private let weeklyStartRangeTime = Date().add(component: .day, value: -6).startOfDay.timestamp
    private let weeklyEndRangeTime = Date().endOfDay.timestamp
    var startRangeDate: Date!
    var endRangeDate: Date!
    private var homerworkData: [TKPractice] = []
    private var hoursData: [CGFloat] = [CGFloat](repeating: 0, count: 7)
    private var sessionsData: [CGFloat] = [CGFloat](repeating: 0, count: 7)
    private var nowTime = Date().endOfDay.timestamp
    
    private var isDataLoaded: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
}

// MARK: - View

extension SAchievementPracticeController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        initWeeklyView()
        initSessionsView()
        initCollectionView()
    }

    func initWeeklyView() {
        workHoursView = TKView.create()
            .showShadow()
            .gradientBackgroundColor(startColor: UIColor(named: "pink")!, endColor: UIColor(named: "purple")!, direction: .leftToRight, size: CGSize(width: (UIScreen.main.bounds.width - 50) / 2, height: 80))
            .corner(size: 8)
        mainView.addSubview(view: workHoursView) { make in
            make.top.equalToSuperview().offset(26)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(80)
            make.left.equalToSuperview().offset(20)
        }
        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "Total")
        workHoursView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(10)
        }

        let lineView = TKView.create()
            .backgroundColor(color: UIColor.white)
        workHoursView.addSubview(view: lineView) { make in
            make.top.equalToSuperview().offset(36.5)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
        }

        workHoursLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: UIColor.white)
            .text(text: "0")
        workHoursView.addSubview(view: workHoursLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
        }

        let suffixLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 16))
            .textColor(color: UIColor.white)
            .text(text: "hrs")
        workHoursView.addSubview(view: suffixLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(workHoursLabel.snp.right).offset(5)
        }
    }

    func initSessionsView() {
        sessionsView = TKView.create()
            .showShadow()
            .gradientBackgroundColor(startColor: UIColor(red: 68, green: 222, blue: 197), endColor: UIColor(red: 77, green: 189, blue: 247), direction: .leftToRight, size: CGSize(width: (UIScreen.main.bounds.width - 50) / 2, height: 80))
            .corner(size: 8)
        mainView.addSubview(view: sessionsView) { make in
            make.top.equalToSuperview().offset(26)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(80)
            make.right.equalToSuperview().offset(-20)
        }

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "Sessions")
        sessionsView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(10)
        }

        let lineView = TKView.create()
            .backgroundColor(color: UIColor.white)
        sessionsView.addSubview(view: lineView) { make in
            make.top.equalToSuperview().offset(36.5)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
        }

        sessionsLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "")
        sessionsView.addSubview(view: sessionsLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
        }

        let suffixLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 16))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "/ wk")
        sessionsView.addSubview(view: suffixLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(sessionsLabel.snp.right).offset(5)
        }
    }

    private func initCollectionView() {
        collectionViewLayout = UICollectionViewFlowLayout()
        var itemSize: CGSize!
        if UIScreen.main.bounds.width <= 450 {
            // 小屏幕
            itemSize = CGSize(width: UIScreen.main.bounds.width, height: 220)
        } else {
            itemSize = CGSize(width: (UIScreen.main.bounds.width - 20) / 2, height: 220)
        }
        collectionViewLayout.itemSize = itemSize
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = ColorUtil.backgroundColor
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        mainView.addSubview(view: collectionView) { make in
            make.top.equalTo(workHoursView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
        collectionView.register(InsightsDataChartCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: InsightsDataChartCollectionViewCell.self))
    }
}

// MARK: - Data

extension SAchievementPracticeController {
    override func initData() {
//        getPractice()
//        getWeekPractice()
    }
    
    private func loadData() {
        guard !isDataLoaded else { return }
        isDataLoaded = true
        akasync { [weak self] in
            guard let self = self, let student = StudentService.student else { return }
            do {
                let practiceData = try akawait(StudentService.award.getPractice(withStudioId: student.studioId, studentId: student.studentId, dateTimeRange: DateTimeRange(startTime: TimeInterval(self.startRangeDate.timestamp), endTime: TimeInterval(self.endRangeDate.timestamp))))
                updateUI {
                    self.homerworkData = practiceData.sorted(by: { $0.startTime > $1.startTime })
                    self.initPracticeHoursChart()
                }
            } catch {
                logger.error("发生错误: \(error)")
                self.isDataLoaded = false
            }
        }
    }

    func refreshData(startRangeDate: Date, endRangeDate: Date) {
        self.startRangeDate = startRangeDate
        self.endRangeDate = endRangeDate
        let count = TimeUtil.getApartDay(startData: startRangeDate, endData: endRangeDate) + 1
        hoursData = [CGFloat](repeating: 0, count: count)
        sessionsData = hoursData
        getPractice()
    }

    private func getWeekPractice() {
        addSubscribe(
            LessonService.lessonSchedule.getScheduleAssignmentByStudentIdAndInTime(studentId: UserService.user.id() ?? "", startTime: weeklyStartRangeTime, endTime: weeklyEndRangeTime)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKAssignment] = []

                    for doc in docs.documents {
                        if let doc = TKAssignment.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }
                    var totalTime: CGFloat = 0
                    for item in data {
                        var timeLength: CGFloat = (item.timeLength / 60 / 60)
                        if timeLength > 0 {
                            if timeLength < 0.1 {
                                timeLength = 0.1
                            }
                        }
                        totalTime += timeLength
                    }
                    if totalTime == 0 {
                        self.workHoursLabel.text("0")
                    } else {
                        self.workHoursLabel.text("\(totalTime.roundTo(places: 1))")
                    }
                    self.sessionsLabel.text("\(data.count)")
                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func getPractice() {
//        print("id:\(UserService.user.id() ?? "")===\(startRangeDate.toString())===\(endRangeDate.toString())")
        addSubscribe(
//            LessonService.lessonSchedule.getScheduleAssignmentByStudentIdAndInTime(studentId: UserService.user.id() ?? "", startTime: startRangeDate.timestamp, endTime: endRangeDate.timestamp)
            LessonService.lessonSchedule.getPracticeByStartTimeAndSId(startTime: TimeInterval(startRangeDate.timestamp), endTime: TimeInterval(endRangeDate.timestamp), studentId: UserService.user.id() ?? "")
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if var data = data[.cache] {
                        data.sort { (a, b) -> Bool in
                            a.startTime > b.startTime
                        }
                        self.homerworkData = data
                    }
                    if var data = data[.server] {
                        data.sort { (a, b) -> Bool in
                            a.startTime > b.startTime
                        }
                        self.homerworkData = data
                    }
                    self.initPracticeHoursChart()

                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func initPracticeHoursChart() {
        hoursData = [CGFloat](repeating: 0, count: hoursData.count)
        sessionsData = [CGFloat](repeating: 0, count: sessionsData.count)
        var totalTimeLength:CGFloat = 0
        var totalSessions = 0
        for item in homerworkData {
            let createTime = Double(item.createTime) ?? 0
            let createDate = TimeUtil.changeTime(time: createTime)
            let index = TimeUtil.getApartDay(startData: startRangeDate, endData: createDate)

            guard item.shouldDateTime <= Double(nowTime) else {
                continue
            }

            if index >= 0 && index < hoursData.count {
                var timeLength: CGFloat = (item.totalTimeLength / 60 / 60).roundTo(places: 1)
                if timeLength > 0 {
                    if timeLength < 0.1 {
                        timeLength = 0.1
                    }
                }
                totalTimeLength += timeLength
                totalSessions += 1
                hoursData[index] += timeLength
                sessionsData[index] += 1
            }
        }

        
        
        
        if totalTimeLength == 0 {
            workHoursLabel.text("0")
        } else {
            workHoursLabel.text("\(totalTimeLength.roundTo(places: 1))")
        }
        sessionsLabel.text("\(totalSessions)")

        collectionView.reloadData()
    }
}

// MARK: - CollectionView

extension SAchievementPracticeController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: InsightsDataChartCollectionViewCell.self), for: indexPath) as! InsightsDataChartCollectionViewCell
        if indexPath.item == 0 {
            cell.loadData(data: hoursData, color: UIColor(named: "purple")!, title: "Hours", startDate: startRangeDate, insightsLimitCount: 10)
        } else {
            cell.loadData(data: sessionsData, color: UIColor(red: 78, green: 188, blue: 250), title: "Sessions", startDate: startRangeDate, insightsLimitCount: 10)
        }
        return cell
    }
}

// MARK: - Action

extension SAchievementPracticeController {
}
