//
//  AchievementViewController.swift
//  TuneKey
//
//  Created by Wht on 2019/8/22.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class AchievementViewController: TKBaseViewController {
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "Award")
    var addButton: TKButton = TKButton.create().setImage(name: "icAddPrimary", size: CGSize(width: 22, height: 22))
    var filterButton: TKButton = TKButton.create().setImage(name: "filter", size: CGSize(width: 22, height: 22))
    var collectionView: UICollectionView!
    var data: [TKAchievement] = []
    var showData: [TKAchievement] = []
    var teacherId: String = ""
    var studentId: String = ""
    var achievementType: [TKPopAddAchievementController.PopAchievement] = []
    var isStudentEnter: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - View

extension AchievementViewController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        initNavigattionBarView()
        initCollectionView()
        collectionView.reloadData()
    }

    func initNavigattionBarView() {
        navigationBar.updateLayout(target: self)
        navigationBar.addSubview(filterButton)
        filterButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview().offset(4)
        }
        filterButton.onTapped { _ in
            self.clickFilter()
        }
        if !isStudentEnter {
            navigationBar.addSubview(addButton)
            addButton.snp.makeConstraints { make in
                make.right.equalTo(filterButton.snp.left).offset(-20)
                make.centerY.equalToSuperview().offset(4)
            }
            addButton.onTapped { _ in
                self.clickAdd()
            }
        }
        if let role = ListenerService.shared.currentRole {
            addButton.isHidden = role == .student
        }
    }

    func initCollectionView() {
        let collectionLayout = UICollectionViewFlowLayout()
        collectionLayout.scrollDirection = .vertical
        collectionLayout.minimumInteritemSpacing = 10
        collectionLayout.minimumLineSpacing = 10
        collectionLayout.estimatedItemSize = CGSize(width: UIScreen.main.bounds.width, height: 30)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = ColorUtil.backgroundColor

        mainView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
        }
        collectionView.register(AchieVementCell.self, forCellWithReuseIdentifier: String(describing: AchieVementCell.self))
    }
}

// MARK: - CollectionView

extension AchievementViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: AchieVementCell.self), for: indexPath) as! AchieVementCell
        cell.initItem(data: showData[indexPath.row])
        return cell
    }
}

// MARK: - Data

extension AchievementViewController {
    override func initData() {
        showData = data
        achievementType.append(TKPopAddAchievementController.PopAchievement(title: .all, isSelect: true))
        achievementType.append(TKPopAddAchievementController.PopAchievement(title: .hearing, isSelect: false))
        achievementType.append(TKPopAddAchievementController.PopAchievement(title: .musicSheet, isSelect: false))
        achievementType.append(TKPopAddAchievementController.PopAchievement(title: .notation, isSelect: false))
        achievementType.append(TKPopAddAchievementController.PopAchievement(title: .song, isSelect: false))
        achievementType.append(TKPopAddAchievementController.PopAchievement(title: .creativity, isSelect: false))
        achievementType.append(TKPopAddAchievementController.PopAchievement(title: .groupPlay, isSelect: false))
        achievementType.append(TKPopAddAchievementController.PopAchievement(title: .technique, isSelect: false))
        achievementType.append(TKPopAddAchievementController.PopAchievement(title: .dedication, isSelect: false))
        achievementType.append(TKPopAddAchievementController.PopAchievement(title: .improv, isSelect: false))
    }

    /// 筛选数据
    /// - Parameter selectType: 选择的Type
    func filterData(_ selectType: TKAchievementType) {
        showData.removeAll()
        if selectType == .all {
            showData = data
        } else {
            for item in data where item.type == selectType {
                showData.append(item)
            }
        }
        collectionView.reloadData()
    }
}

// MARK: - Action

extension AchievementViewController {
    func clickFilter() {
        TKPopAction.showSelectAchievementType(target: self, data: achievementType) { selectData in
            var selectType: TKAchievementType!
            for item in self.achievementType.enumerated() {
                self.achievementType[item.offset].isSelect = false
                if item.element.title == selectData.title {
                    self.achievementType[item.offset].isSelect = true
                    selectType = item.element.title
                }
            }
            self.filterData(selectType)
        }
    }

    func clickAdd() {
        TKPopAction.showAddAchievement(target: self) { [weak self] data in
            guard let self = self else { return }
            self.showFullScreenLoading()
            self.addAchievementStup1(data)
        }
    }

    func addAchievementStup1(_ data: TKAchievement) {
        print("===\(teacherId)===\(studentId)")
        addSubscribe(
            LessonService.lessonSchedule.getScheduleByStudentIdAndTeacherIdScheduleRightTime(tId: teacherId, sId: studentId)
                .timeout(RxTimeInterval.seconds(TIME_OUT_TIME), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] resultsData in
                    guard let self = self else { return }
                    logger.debug("===111===\(resultsData.toJSONString(prettyPrint: true) ?? "")")
                    if resultsData.count > 0 {
                        var data = data
                        data.scheduleId = resultsData[0].id
                        data.studentId = self.studentId
                        data.teacherId = self.teacherId
                        data.shouldDateTime = resultsData[0].shouldDateTime
                        self.hideFullScreenLoading()
                        self.showData.insert(data, at: 0)
                        self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
                        self.addAchievementStup2(data)
                    } else {
                        if self.showData.count > 0 {
                            var data = data
                            data.scheduleId = self.showData[0].scheduleId
                            data.studentId = self.studentId
                            data.teacherId = self.teacherId
                            data.shouldDateTime = self.showData[0].shouldDateTime
                            self.hideFullScreenLoading()
                            self.showData.insert(data, at: 0)
                            self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
                            self.addAchievementStup2(data)
                        } else {
                            TKToast.show(msg: "Add failed, please try again!", style: .warning)
                        }
                    }
                }, onError: { err in
                    TKToast.show(msg: "Add failed, please try again!", style: .warning)
                    logger.debug("===111===\(err)")
                })
        )
    }

    func addAchievementStup2(_ data: TKAchievement) {
        addSubscribe(
            LessonService.lessonSchedule.addAchievement(data: data)
                .subscribe(onNext: { data in
                    logger.debug("==222====\(data)")
                }, onError: { err in
                    logger.debug("==222===\(err)")
                    TKToast.show(msg: "Add failed, please try again!", style: .warning)
                })
        )
    }
}
