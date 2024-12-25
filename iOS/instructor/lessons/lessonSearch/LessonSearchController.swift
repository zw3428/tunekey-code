//
//  LessonSearchController.swift
//  TuneKey
//
//  Created by WHT on 2020/3/6.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit
struct TKLessonSearchModel {
    var studentData: TKStudent?
    var eventData: TKEventConfigure?
    var type: LessonSearchType = .student
}

enum LessonSearchType {
    case student
    case event
}

class LessonSearchController: TKSearchViewController {
    private var searchResultView: TKView!
    private var collectionViewLayout: UICollectionViewFlowLayout!
    private var collectionView: UICollectionView!
    var scheduleConfigs: [TKLessonScheduleConfigure] = []
    var eventDatas: [TKEventConfigure] = []
    var studentDatas: [TKStudent] = []
    var data: [TKLessonSearchModel] = []

    var showData: [TKLessonSearchModel] = []

    init(data: [TKLessonScheduleConfigure], eventDatas: [TKEventConfigure]) {
        super.init(nibName: nil, bundle: nil)
        scheduleConfigs = data
        self.eventDatas = eventDatas
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.focus()
    }
}

// MARK: - View

extension LessonSearchController {
    override func initView() {
        super.initView()
        searchResultView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: mainView, withConstraints: { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.top.equalTo(searchView.snp.bottom).offset(24)
            })
        searchBar.delegate = self
        initCollectionView()
    }

    func initCollectionView() {
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.allowsSelection = false
        collectionView.backgroundColor = UIColor.white
        searchResultView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }
        updateCollectionViewLayout()
        enableScreenRotateListener { [weak self] in
            self?.updateCollectionViewLayout()
        }

        collectionView.register(StudentsSelectorCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: StudentsSelectorCollectionViewCell.self))
        collectionView.register(LessonSearchEventCell.self, forCellWithReuseIdentifier: String(describing: LessonSearchEventCell.self))
    }

    private func updateCollectionViewLayout() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.collectionView.setNeedsLayout()
            self.collectionView.layoutIfNeeded()
            if self.collectionView.frame.width > 650 {
                // 大屏幕, 两列，中间留出 10 的间距
                self.collectionViewLayout.itemSize = CGSize(width: self.collectionView.frame.width / 2 - 10, height: 94)
            } else {
                // 小屏幕
                self.collectionViewLayout.itemSize = CGSize(width: self.collectionView.frame.width, height: 94)
            }
        }
    }
}

// MARK: - Data

extension LessonSearchController {
    override func initData() {
        var studentMap: [String: Bool] = [:]
        for item in scheduleConfigs {
            if studentMap[item.studentId] == nil {
                studentMap[item.studentId] = true
            }
        }
        let json: String = SLCache.main.get(key: SLCache.STUDENT_LIST)
        if let studentData = [TKStudent].deserialize(from: json) as? [TKStudent] {
            if studentData.count > 0 {
                for item in studentData where studentMap[item.studentId] != nil {
//                        studentDatas.append(item!)
                    var lessonSearchModel = TKLessonSearchModel()
                    lessonSearchModel.studentData = item
                    lessonSearchModel.type = .student
                    data.append(lessonSearchModel)
                }
            }
        }

        for item in eventDatas {
            var lessonSearchModel = TKLessonSearchModel()
            lessonSearchModel.eventData = item
            lessonSearchModel.type = .event
            data.append(lessonSearchModel)
        }

        logger.debug("\(studentDatas.toJSONString(prettyPrint: true) ?? "")")
    }
}

// MARK: - TableView

extension LessonSearchController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, StudentsSelectorCollectionViewCellDelegate {
    func studentsSelectorCollectionViewCellIsEdit() -> Bool {
        return false
    }
    func studentsSelectorCollectionViewCell(didTappedAtButton cell: StudentsSelectorCollectionViewCell) {
        studentsCell(cell: cell)
    }

    func studentsSelectorCollectionViewCell(didTappedAtContentView cell: StudentsSelectorCollectionViewCell) {
        studentsCell(cell: cell)
    }

    func studentsCell(cell: StudentsSelectorCollectionViewCell) {
        cell.backView.heroID = "\(showData[cell.tag].studentData!.studentId)"

        var scheduleConfig: [TKLessonScheduleConfigure] = []
        for item in scheduleConfigs where showData[cell.tag].studentData!.studentId == item.studentId {
            scheduleConfig.append(item)
        }
        let controller = LessonSearchScheduleController()
        controller.modalPresentationStyle = .fullScreen
        controller.scheduleConfigs = scheduleConfig
        controller.studentData = showData[cell.tag].studentData!
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func clickEventCell(index: Int) {
        guard showData.count > index && showData[index].eventData != nil else { return }

        if let presentingViewController = self.presentingViewController {
            dismiss(animated: false) {
                let controller = AddEventController()
                controller.isEdit = true
                controller.modalPresentationStyle = .fullScreen
                controller.hero.isEnabled = true
                controller.data = self.showData[index].eventData!
                controller.enablePanToDismiss()
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                presentingViewController.present(controller, animated: true, completion: nil)
            }
        }
    }

    // 192.33 246
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch showData[indexPath.row].type {
        case .student:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: StudentsSelectorCollectionViewCell.self), for: indexPath) as! StudentsSelectorCollectionViewCell
            cell.tag = indexPath.row
            cell.delegate = self
            cell.initItem(.singleSelection)
            cell.initData(studentData: showData[indexPath.row].studentData!)
            return cell
        case .event:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: LessonSearchEventCell.self), for: indexPath) as! LessonSearchEventCell
            cell.tag = indexPath.row
            cell.initData(data: showData[indexPath.row].eventData!)
            cell.onViewTapped { [weak self] _ in
                self?.clickEventCell(index: indexPath.row)
            }
            return cell
        }
    }
}

// MARK: - Action

extension LessonSearchController: TKSearchBarDelegate {
    func tkSearchBar(textChanged searchBar: TKSearchBar, text: String) {
        search(searchBar, text)
    }

    func search(_ searchBar: TKSearchBar, _ text: String) {
        if text.count == 0 {
            showData.removeAll()
            collectionView.reloadData()
        } else {
            showData = []

            let pre3 = NSPredicate(format: "SELF CONTAINS[cd] %@", text.lowercased())
//            for item in studentDatas {
//                if pre3.evaluate(with: item.name.lowercased()) {
//                    showData.append(item)
//                }
//            }
            for item in data {
                switch item.type {
                case .student:
                    if pre3.evaluate(with: item.studentData!.name.lowercased()) {
                        showData.append(item)
                    }
                case .event:
                    if pre3.evaluate(with: item.eventData!.title.lowercased()) {
                        showData.append(item)
                    }
                }
            }

            collectionView.reloadData()
            if showData.count > 0 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
            }
        }
    }
}
