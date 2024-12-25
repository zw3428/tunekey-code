//
//  ProfileNotificationsReminderView.swift
//  TuneKey
//
//  Created by zyf on 2020/7/6.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

protocol ProfileNotificationsReminderViewDelegate: NSObjectProtocol {
    func profileNotificationsReminderView(heightChanged height: CGFloat)
    func profileNotificationsReminderView(dataChanged data: [ProfileNotificationsReminderView.ReminderTime], isOn: Bool)
}

extension ProfileNotificationsReminderView {
    struct ReminderTime {
        var value: Int
        var title: String
        var isSelected: Bool
    }
}

class ProfileNotificationsReminderView: UIView {
    weak var delegate: ProfileNotificationsReminderViewDelegate?
    private var switchView: TKSwitch = TKSwitch()
    private var selectorView: TKView = TKView.create()
    private var selectorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let width = (UIScreen.main.bounds.width - 30 - 60) / 4
        layout.itemSize = CGSize(width: width, height: 40)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        return collectionView
    }()

    var reminderTimeData: [ReminderTime] = [
        ReminderTime(value: 5, title: "5min", isSelected: false),
        ReminderTime(value: 10, title: "10min", isSelected: false),
        ReminderTime(value: 15, title: "15min", isSelected: false),
        ReminderTime(value: 30, title: "30min", isSelected: false),
        ReminderTime(value: 60, title: "1hr", isSelected: false),
        ReminderTime(value: 120, title: "2hrs", isSelected: false),
        ReminderTime(value: 180, title: "3hrs", isSelected: false),
        ReminderTime(value: 1440, title: "1day", isSelected: false)
    ]

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupData(times: [Int], isOn: Bool) {
        switchView.isOn = isOn
        reminderTimeData.forEachItems { item, index in
            reminderTimeData[index].isSelected = times.contains(item.value)
        }
        updateView()
    }
}

extension ProfileNotificationsReminderView {
    private func initView() {
        let reminderTitleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Lesson Reminder")
            .addTo(superView: self) { make in
                make.top.equalToSuperview().offset(16.5)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-80)
                make.height.equalTo(20)
            }
        switchView = TKSwitch()
        switchView.delegate = self
        switchView.addTo(superView: self) { make in
            make.centerY.equalTo(reminderTitleLabel.snp.centerY)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(switchView.size)
        }
        selectorView = TKView.create()
            .addTo(superView: self, withConstraints: { make in
                make.top.equalToSuperview().offset(54)
                make.left.right.bottom.equalToSuperview()
            })
        selectorView.clipsToBounds = true
        selectorView.addSubview(view: selectorCollectionView) { make in
            make.top.right.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-40).priority(.medium)
        }
        selectorCollectionView.delegate = self
        selectorCollectionView.dataSource = self
        selectorCollectionView.register(ProfileNotificationsReminderViewCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ProfileNotificationsReminderViewCollectionViewCell.self))

        _ = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "before the lesson")
            .addTo(superView: selectorView, withConstraints: { make in
                make.bottom.equalToSuperview().offset(-20)
                make.left.equalToSuperview().offset(20)
            })
    }
}

extension ProfileNotificationsReminderView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.item
        reminderTimeData[index].isSelected.toggle()
        collectionView.reloadItems(at: [indexPath])
        delegate?.profileNotificationsReminderView(dataChanged: reminderTimeData, isOn: switchView.isOn)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        reminderTimeData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ProfileNotificationsReminderViewCollectionViewCell.self), for: indexPath) as! ProfileNotificationsReminderViewCollectionViewCell
        let index = indexPath.item
        let data = reminderTimeData[index]
        cell.backgroundColor = .white
        cell.titleLabel.text(data.title)
        cell.checkImageView.isHidden = !data.isSelected
        if data.isSelected {
            cell.titleLabel.textColor(color: ColorUtil.main)
            cell.itemView.showBorder(color: ColorUtil.main)
        } else {
            cell.titleLabel.textColor(color: ColorUtil.Font.primary)
            cell.itemView.showBorder(color: ColorUtil.borderColor)
        }
        return cell
    }
}

extension ProfileNotificationsReminderView: TKSwitchDelegate {
    func tkSwitch(_ tkSwitch: TKSwitch, onValueChanged isOn: Bool) {
        updateView()
    }

    private func updateView() {
        let isOn = switchView.isOn
        delegate?.profileNotificationsReminderView(heightChanged: isOn ? 184 : 54)
        delegate?.profileNotificationsReminderView(dataChanged: reminderTimeData, isOn: isOn)
    }
}

class ProfileNotificationsReminderViewCollectionViewCell: UICollectionViewCell {
    var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 13))
        .alignment(alignment: .center)
    var itemView: TKView = TKView.create()
        .showBorder(color: ColorUtil.borderColor)
        .corner(size: 5)

    var checkImageView: TKImageView = TKImageView.create()
        .setImage(name: "checkboxOn")

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(view: itemView) { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-2)
            make.right.equalToSuperview().offset(-10)
        }

        contentView.addSubview(view: checkImageView) { make in
            make.size.equalTo(16)
            make.top.equalTo(itemView.snp.top).offset(-8)
            make.right.equalTo(itemView.snp.right).offset(8)
        }
        titleLabel.addTo(superView: itemView) { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
