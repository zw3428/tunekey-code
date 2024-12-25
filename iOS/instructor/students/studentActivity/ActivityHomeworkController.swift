//
//  ActivityHomeworkController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/8.
//  Copyright © 2019 spelist. All rights reserved.
//

import UIKit

class ActivityHomeworkController: TKBaseViewController {
    var mainView = UIView()
    var collectionView: UICollectionView!
    var homeworkData: [TKAssignment] = []
    var practiceAssignment: [TKPracticeAssignment] = []
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - View

extension ActivityHomeworkController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        initCollectionView()
    }

    func initCollectionView() {
        let collectionLayout = UICollectionViewFlowLayout()
        collectionLayout.scrollDirection = .vertical
        collectionLayout.minimumInteritemSpacing = 10
        collectionLayout.minimumLineSpacing = 10
        print("====\(UIScreen.main.bounds.width)")
        collectionLayout.estimatedItemSize = CGSize(width: UIScreen.main.bounds.width - 10 , height: 64)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        collectionView.backgroundColor = ColorUtil.backgroundColor
        collectionView.delegate = self
        collectionView.dataSource = self
        mainView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(10)
        }
        collectionView.register(StudentHomeworkCell.self, forCellWithReuseIdentifier: String(describing: StudentHomeworkCell.self))
    }
}

// MARK: - CollectionView

extension ActivityHomeworkController: UICollectionViewDelegate, UICollectionViewDataSource, StudentHomeworkCellDelegate {
    func studentHomeworkCellCell(clickPlay index: Int, cell: StudentHomeworkCell) {
        let controller = PlayAudiodController()
        controller.data = practiceAssignment[cell.tag].practice[index]
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return practiceAssignment.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let id = String(describing: StudentHomeworkCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! StudentHomeworkCell
        cell.tag = indexPath.row
        cell.delegate = self
        cell.initData(practiceAssignment: practiceAssignment[indexPath.row])
        return cell
    }
}

// MARK: - Data

extension ActivityHomeworkController {
    override func initData() {
        let d = DateFormatter()
        d.dateFormat = "MMM d"
        for i in homeworkData {
            var isHave = false
            let time = d.string(from: TimeUtil.changeTime(time: i.shouldDateTime))
            var ps = TKPracticeAssignment()
            ps.time = time
            for j in practiceAssignment.enumerated() where j.element.time == time {
                isHave = true
                practiceAssignment[j.offset].assignments.append(i)
            }
            if !isHave {
                ps.assignments.append(i)
                practiceAssignment.append(ps)
            }
        }

        collectionView.reloadData()
    }
}

// MARK: - Action

extension ActivityHomeworkController {
}
