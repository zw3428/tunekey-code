//
//  ProfileNotificationCell.swift
//  TuneKey
//
//  Created by wht on 2020/6/22.
//  Copyright © 2020 spelist. All rights reserved.
//

import SnapKit
import UIKit

class ProfileNotificationCell: UITableViewCell {
    static let id = ProfileNotificationCell.describing
    struct ReminderTime {
        var value: Int
        var title: String
        var isSelected: Bool
    }

    var tableView: UITableView?

    private var mainView: TKView = TKView.create()
        .backgroundColor(color: UIColor.white)
        .corner(size: 5)
        .showBorder(color: ColorUtil.borderColor)
        .showShadow(color: ColorUtil.dividingLine)

    private var cancelLessonView: TKView!
    private var cancelLessonSwitchView: TKSwitch!

    private var rescheduleConfirmedView: TKView!
    private var rescheduleConfirmedSwitchView: TKSwitch!

    private var reminderView: ProfileNotificationsReminderView!
//    private var reminderView: TKView!
    private var reminderSwitchView: TKSwitch!
    private var reminderTimesSelectorView: TKView!
    private var reminderTimesSelectorCollectionView: UICollectionView!

    var reminderTimeData: [ReminderTime] = [
        ReminderTime(value: 15, title: "15min", isSelected: false),
        ReminderTime(value: 30, title: "30min", isSelected: false),
        ReminderTime(value: 60, title: "1hr", isSelected: false),
        ReminderTime(value: 120, title: "2hrs", isSelected: false),
        ReminderTime(value: 180, title: "3hrs", isSelected: false),
        ReminderTime(value: 240, title: "4hrs", isSelected: false),
        ReminderTime(value: 300, title: "5hrs", isSelected: false),
        ReminderTime(value: 1440, title: "1day", isSelected: false),
    ]

    weak var delegate: ProfileNotificationCellDelegate?

    enum ProfileNotificationType {
        case rescheduleConfirmed
        case cancelLesson
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileNotificationCell {
    func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        
        contentView.addSubview(view: mainView) { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10)
        }

        let notificationsLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Notifications")
            .addTo(superView: mainView) { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.top.equalToSuperview().offset(18)
                make.height.equalTo(20)
            }

        cancelLessonView = TKView.create()
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview()
                make.top.equalTo(notificationsLabel.snp.bottom).offset(10)
                make.height.equalTo(0)
            })
        cancelLessonView.clipsToBounds = true
        cancelLessonSwitchView = TKSwitch()
        cancelLessonSwitchView.delegate = self
        cancelLessonView.addSubview(view: cancelLessonSwitchView) { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
            make.width.equalTo(55)
        }
        _ = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Cancellation")
            .addTo(superView: cancelLessonView) { make in
                make.left.equalToSuperview()
//                make.bottom.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
            }
        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: cancelLessonView, withConstraints: { make in
                make.left.bottom.right.equalToSuperview()
                make.height.equalTo(1)
            })

        // rescheduleConfirmedView
        rescheduleConfirmedView = TKView.create()
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview()
                make.top.equalTo(cancelLessonView.snp.bottom)
                make.height.equalTo(0)
            })
        rescheduleConfirmedView.clipsToBounds = true
        rescheduleConfirmedSwitchView = TKSwitch()
        rescheduleConfirmedSwitchView.delegate = self
        rescheduleConfirmedView.addSubview(view: rescheduleConfirmedSwitchView) { make in
            make.right.equalToSuperview().offset(-20)
//            make.bottom.equalToSuperview().offset(-9)
            make.centerY.equalToSuperview()

            make.height.equalTo(22)
            make.width.equalTo(55)
        }
        _ = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Makeup")
            .addTo(superView: rescheduleConfirmedView) { make in
                make.left.equalToSuperview()
//                make.bottom.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
            }

        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: rescheduleConfirmedView, withConstraints: { make in
                make.left.bottom.right.equalToSuperview()
                make.height.equalTo(1)
            })

        reminderView = ProfileNotificationsReminderView()
        reminderView.delegate = self
        mainView.addSubview(view: reminderView) { make in
            make.top.equalTo(notificationsLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
            make.bottom.equalToSuperview().priority(.medium)
        }
    }
}

extension ProfileNotificationCell: ProfileNotificationsReminderViewDelegate {
    func profileNotificationsReminderView(heightChanged height: CGFloat) {
        tableView?.beginUpdates()
        reminderView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        tableView?.endUpdates()
    }

    func profileNotificationsReminderView(dataChanged data: [ProfileNotificationsReminderView.ReminderTime], isOn: Bool) {
        // MARK: - 数据变更

        delegate?.profileNotification(reminderDataChanged: data, isOn: isOn)
    }
}

extension ProfileNotificationCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.item
        reminderTimeData[index].isSelected.toggle()
        collectionView.reloadItems(at: [indexPath])
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        reminderTimeData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ReminderTimesSelectorCollectionViewCell.self), for: indexPath) as! ReminderTimesSelectorCollectionViewCell
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

extension ProfileNotificationCell: TKSwitchDelegate {
    func initData(data: TKNotificationConfig) {
        rescheduleConfirmedSwitchView.isOn = data.rescheduleConfirmedNotificationOpened
        cancelLessonSwitchView.isOn = data.cancelLessonConfirmedNotificationOpened
        reminderView.setupData(times: data.reminderTimes, isOn: data.reminderOpened)
    }

    func tkSwitch(_ tkSwitch: TKSwitch, onValueChanged isOn: Bool) {
        switch tkSwitch {
        case rescheduleConfirmedSwitchView:
            delegate?.profileNotification(select: self, isOn: isOn, type: .rescheduleConfirmed)
            break
        case cancelLessonSwitchView:
            delegate?.profileNotification(select: self, isOn: isOn, type: .cancelLesson)
            break
//        case reminderSwitchView:
//            DispatchQueue.main.async {
//                self.tableView?.beginUpdates()
//                self.reminderView.snp.updateConstraints { make in
//                    make.height.equalTo(isOn ? 184 : 54)
//                }
//                self.tableView?.endUpdates()
//            }

        default:
            break
        }
    }
}

protocol ProfileNotificationCellDelegate: NSObjectProtocol {
    func profileNotification(clickHomeworkReminder cell: ProfileNotificationCell)
    func profileNotification(select cell: ProfileNotificationCell, isOn: Bool, type: ProfileNotificationCell.ProfileNotificationType)
    func profileNotification(reminderDataChanged data: [ProfileNotificationsReminderView.ReminderTime], isOn: Bool)
}

class ReminderTimesSelectorCollectionViewCell: UICollectionViewCell {
    var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
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
