//
//  SAchievementMilestonesController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/25.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class SAchievementMilestonesController: TKBaseViewController {
    var mainView = UIView()

    private var achievementsLabel: TKLabel!
    private var achievementsView: TKView!

    private var topRatedLabel: TKLabel!
    private var topRatedView: TKView!

    private var tableView: UITableView!
    private var data: [TKAchievement] = []
    
    private var isDataLoaded: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
}

// MARK: - View

extension SAchievementMilestonesController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        initAchievementsView()
        initTopRatedView()
        initTableView()
    }

    func initAchievementsView() {
        achievementsView = TKView.create()
            .gradientBackgroundColor(startColor: UIColor(red: 168, green: 127, blue: 255), endColor: UIColor(red: 107, green: 117, blue: 252), direction: .leftToRight, size: CGSize(width: (UIScreen.main.bounds.width - 50) / 2, height: 80))
            .corner(size: 8)
        achievementsView.clipsToBounds = true
        mainView.addSubview(view: achievementsView) { make in
            make.top.equalToSuperview().offset(26)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(80)
            make.left.equalToSuperview().offset(20)
        }
        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "Awards")
        achievementsView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(10)
        }

        let lineView = TKView.create()
            .backgroundColor(color: UIColor.white)
        achievementsView.addSubview(view: lineView) { make in
            make.top.equalToSuperview().offset(36.5)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
        }

        achievementsLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: UIColor.white)
            .text(text: "0")
        achievementsView.addSubview(view: achievementsLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
        }

        let suffixLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 16))
            .textColor(color: UIColor.white)
            .text(text: "total")
        achievementsView.addSubview(view: suffixLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(achievementsLabel.snp.right).offset(5)
        }
    }

    func initTopRatedView() {
        topRatedView = TKView.create()
            .gradientBackgroundColor(startColor: UIColor(red: 255, green: 136, blue: 134), endColor: UIColor(red: 247, green: 196, blue: 152), direction: .leftToRight, size: CGSize(width: (UIScreen.main.bounds.width - 50) / 2, height: 80))
            .corner(size: 8)
        topRatedView.clipsToBounds = true
        mainView.addSubview(view: topRatedView) { make in
            make.top.equalToSuperview().offset(26)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(80)
            make.right.equalToSuperview().offset(-20)
        }

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "Top rated")
        topRatedView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(10)
        }

        let lineView = TKView.create()
            .backgroundColor(color: UIColor.white)
        topRatedView.addSubview(view: lineView) { make in
            make.top.equalToSuperview().offset(36.5)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
        }

        topRatedLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .adjustsFontSizeToFitWidth()
            .text(text: "")
        topRatedView.addSubview(view: topRatedLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
    }

    func initTableView() {
        tableView = UITableView()
        mainView.addSubview(view: tableView) { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(topRatedView.snp.bottom).offset(20)
        }
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        tableView.register(MilestonesCell.self, forCellReuseIdentifier: String(describing: MilestonesCell.self))
    }
}

// MARK: - Data

extension SAchievementMilestonesController {
    override func initData() {
//        getAchievementData()
    }

    private func loadData() {
        guard !isDataLoaded else { return }
        isDataLoaded = true
        akasync { [weak self] in
            guard let self = self, let student = StudentService.student else { return }
            do {
                let achievementData = try akawait(StudentService.award.getAchievement(withStudioId: student.studioId, studentId: student.studentId))
                updateUI {
                    self.initAchievementData(achievementData)
                }
            } catch {
                self.isDataLoaded = false
                logger.error("发生错误: \(error)")
            }
        }
    }
    
    private func getAchievementData() {
        var isLoad = false
        addSubscribe(
            UserService.teacher.studentGetTKStudent()
                .subscribe(onNext: { data in
                    if let data = data[.cache] {
                        isLoad = true
//                        self.studentData = data
                        getData(tId: data.teacherId, sId: data.studentId)
                    }
                    if let data = data[.server] {
                        if !isLoad {
                            getData(tId: data.teacherId, sId: data.studentId)
                        }
                    }

                }, onError: { err in
                    logger.debug("获取学生信息失败:\(err)")
                })
        )
        func getData(tId: String, sId: String) {
            addSubscribe(
                LessonService.lessonSchedule.getScheduleAchievementByStudentIdAndTeacherId(tId: tId, sId: sId)
                    .subscribe(onNext: { data in
//                        guard let self = self else { return }
                        if let data = data[.cache] {
                            initAchievementData(data)
                        }
                        if let data = data[.server] {
                            initAchievementData(data)
                        }

                    }, onError: { err in
                        logger.debug("获取失败:\(err)")
                    })
            )
        }
        func initAchievementData(_ data: [TKAchievement]) {
            self.data = data
            tableView.reloadData()
            achievementsLabel.text("\(self.data.count)")
            guard data.count > 0 else { return
                topRatedLabel.text = "None"
            }
            let counts: [TKAchievementType: Int] = data.reduce(into: [:]) { $0[$1.type, default: 0] += 1 }
            var topRated: TKAchievementType = .dedication
            var topCount = 0
            for item in counts where item.value > topCount {
                topRated = item.key
                topCount = item.value
            }
            switch topRated {
            case .all:
                break
            case .technique:
                topRatedLabel.text = "Technique"
            case .notation:
                topRatedLabel.text = "Theory"
            case .song:
                topRatedLabel.text = "Song"
            case .improv:
                topRatedLabel.text = "Improvement"
            case .groupPlay:
                topRatedLabel.text = "Group play"
            case .dedication:
                topRatedLabel.text = "Dedication"
            case .creativity:
                topRatedLabel.text = "Creativity"
            case .hearing:
                topRatedLabel.text = "Listening"
            case .musicSheet:
                topRatedLabel.text = "Sight reading"
            case .memorization:
                topRatedLabel.text = "Memorization"
            }
        }
    }
    func initAchievementData(_ data: [TKAchievement]) {
        self.data = data
        tableView.reloadData()
        achievementsLabel.text("\(self.data.count)")
        guard data.count > 0 else { return
            topRatedLabel.text = "None"
        }
        let counts: [TKAchievementType: Int] = data.reduce(into: [:]) { $0[$1.type, default: 0] += 1 }
        var topRated: TKAchievementType = .dedication
        var topCount = 0
        for item in counts where item.value > topCount {
            topRated = item.key
            topCount = item.value
        }
        switch topRated {
        case .all:
            break
        case .technique:
            topRatedLabel.text = "Technique"
        case .notation:
            topRatedLabel.text = "Theory"
        case .song:
            topRatedLabel.text = "Song"
        case .improv:
            topRatedLabel.text = "Improvement"
        case .groupPlay:
            topRatedLabel.text = "Group play"
        case .dedication:
            topRatedLabel.text = "Dedication"
        case .creativity:
            topRatedLabel.text = "Creativity"
        case .hearing:
            topRatedLabel.text = "Listening"
        case .musicSheet:
            topRatedLabel.text = "Sight reading"
        case .memorization:
            topRatedLabel.text = "Memorization"
        }
    }
}

// MARK: - TableView

extension SAchievementMilestonesController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MilestonesCell.self), for: indexPath) as! MilestonesCell
        cell.selectionStyle = .none
        cell.initData(data: data[indexPath.row])
        return cell
    }
}

// MARK: - Action

extension SAchievementMilestonesController {
}
