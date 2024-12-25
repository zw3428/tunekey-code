//
//  LessonsDetailStudentsTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/3.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class LessonsDetailStudentsTableViewCell: UITableViewCell {
    var cellHeight: CGFloat = 250

    var data: [TKLessonSchedule] = []

    weak var delegate: LessonsDetailStudentsTableViewCellDelegate?
    var selectedPos: Int = 0

    private var collectionView: UICollectionView!
    private var collectionViewLayout: CenteredCollectionViewFlowLayout = CenteredCollectionViewFlowLayout()

    private var cardSwitch: XLCardSwitch!

    var stepBar: TKStepBar?

    var lessonTypes: [String: TKLessonType] = [:]
    var configs: [String: TKLessonScheduleConfigure] = [:]

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension LessonsDetailStudentsTableViewCell {
    private func initView() {
        backgroundColor = ColorUtil.backgroundColor
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.itemSize = CGSize(width: UIScreen.main.bounds.width * 0.9, height: 250)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = ColorUtil.backgroundColor
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.decelerationRate = .fast
//        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalTo(self.contentView)
            make.height.equalTo(250)
        }
        collectionView.register(LessonsDetailStudentsItemCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: LessonsDetailStudentsItemCollectionViewCell.self))
    }

    func loadData(data: [TKLessonSchedule], selectedPos: Int) {
        self.data = data
        // 获取所有的configs和lessonTypes
        if ListenerService.shared.currentRole == .studioManager {
            cellHeight = 270
        } else {
            cellHeight = 250
        }
        [TKLessonType].get(data.compactMap { $0.lessonTypeId })
            .done { [weak self] lessonTypes in
                guard let self = self else { return }
                lessonTypes.forEach { lessonType in
                    self.lessonTypes[lessonType.id] = lessonType
                }
                self.collectionView.reloadData()
            }
            .catch { error in
                logger.error("获取lessonTypes失败: \(error)")
            }

        [TKLessonScheduleConfigure].get(data.compactMap { $0.lessonScheduleConfigId })
            .done { [weak self] configs in
                guard let self = self else { return }
                configs.forEach { config in
                    self.configs[config.id] = config
                }
                self.collectionView.reloadData()
            }
            .catch { error in
                logger.error("获取configs失败: \(error)")
            }

        collectionView.reloadData()
        if selectedPos != self.selectedPos {
            self.selectedPos = selectedPos
            DispatchQueue.main.async {
                self.collectionViewLayout.scrollToPage(index: selectedPos, animated: true)
            }
        }
    }
}

extension LessonsDetailStudentsTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, LessonsDetailStudentsItemCollectionViewCellDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentCenterdPage = collectionViewLayout.currentCenteredPage
        if currentCenterdPage != indexPath.item {
            collectionViewLayout.scrollToPage(index: indexPath.item, animated: true)
        }
    }

    func lessonsDetailStudentsItemCollectionViewCell() {
        delegate?.lessonsDetailStudentsTableViewCell(cell: self)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let offsetX = scrollView.contentOffset.x
//        let index: Int = Int(offsetX / UIScreen.main.bounds.width)
        guard let index = collectionViewLayout.currentCenteredPage else { return }
        logger.debug("监听到页面变化: \(index)")
        selectedPos = index
        delegate?.lessonsDetailStudentsTableViewCellStudentItemChanged(index: index)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: LessonsDetailStudentsItemCollectionViewCell.self), for: indexPath) as! LessonsDetailStudentsItemCollectionViewCell
        cell.tag = indexPath.row
        cell.delegate = self
        stepBar = cell.stepBar
        var hasPre: Bool = false
        var hasNext: Bool = false
        let index = indexPath.item
        if index > 0 && index <= data.count - 1 {
            hasPre = true
        }

        if index < data.count - 1 {
            hasNext = true
        }
        let lessonSchedule = data[indexPath.item]
        let config: TKLessonScheduleConfigure? = configs[lessonSchedule.lessonScheduleConfigId]
        lessonSchedule.lessonScheduleData = config
        let lessonType: TKLessonType? = lessonTypes[lessonSchedule.lessonTypeId]
        lessonSchedule.lessonTypeData = lessonType
        cell.initData(data: lessonSchedule, hasPre: hasPre, hasNext: hasNext, config: config, lessonType: lessonType)

        return cell
    }
}

protocol LessonsDetailStudentsTableViewCellDelegate: NSObjectProtocol {
    func lessonsDetailStudentsTableViewCellStudentItemChanged(index: Int)

    func lessonsDetailStudentsTableViewCell(cell: LessonsDetailStudentsTableViewCell)
}
