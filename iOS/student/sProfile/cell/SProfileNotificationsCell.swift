//
//  SProfileNotificationsCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/19.
//  Copyright © 2019年 spelist. All rights reserved.
//

import SnapKit
import UIKit

class SProfileNotificationsCell: UITableViewCell {
    var tableView: UITableView?

    private var mainView: TKView!
    private var homeworkReminderView: TKView!
    private var homeworkReminderInfoLabel: TKLabel!

    private var lessonNotesView: TKView!
    private var lessonNotesSwitchView: TKSwitch!

    private var lessonNewAchievementView: TKView!
    private var lessonNewAchievementSwitchView: TKSwitch!

    private var fileSharedView: TKView!
    private var fileSharedSwitchView: TKSwitch!

    private var rescheduleConfirmedView: TKView!
    private var rescheduleConfirmedSwitchView: TKSwitch!

    private var reminderView: ProfileNotificationsReminderView = ProfileNotificationsReminderView()

    var practiceReminderSwitch: TKSwitch = TKSwitch(frame: .zero)
    var practiceReminderWorkdayTime1: TKSelectedButton = TKSelectedButton(icon: UIImage(named: "ic_add_gray_small")!)
    var practiceReminderWorkdayTime2: TKSelectedButton = TKSelectedButton(icon: UIImage(named: "ic_add_gray_small")!)
    var practiceReminderWorkdayTime3: TKSelectedButton = TKSelectedButton(icon: UIImage(named: "ic_add_gray_small")!)

    var practiceReminderWeekendTime1: TKSelectedButton = TKSelectedButton(icon: UIImage(named: "ic_add_gray_small")!)
    var practiceReminderWeekendTime2: TKSelectedButton = TKSelectedButton(icon: UIImage(named: "ic_add_gray_small")!)
    var practiceReminderWeekendTime3: TKSelectedButton = TKSelectedButton(icon: UIImage(named: "ic_add_gray_small")!)

    lazy var practiceReminderView: TKView = makePracticeReminderView()

    weak var delegate: SProfileNotificationsCellDelegate?

    enum ProfileNotificationType {
        case homeworkReminder
        case lessonNotes
        case newAchievement
        case fileShared
        case rescheduleConfirmed
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SProfileNotificationsCell {
    private func makePracticeReminderView() -> TKView {
        let view = TKView.create()
        let titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .text(text: "Practice Reminder")
            .addTo(superView: view) { make in
                make.top.equalToSuperview().offset(20)
                make.left.equalToSuperview().offset(20)
                make.height.equalTo(20)
            }
        practiceReminderSwitch.addTo(superView: view) { make in
            make.size.equalTo(practiceReminderSwitch.size)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(20)
        }

        let workdayTipLabel: TKLabel = TKLabel.create()
            .text(text: "Weekday")
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.fourth)
            .addTo(superView: view) { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(28)
                make.left.equalToSuperview().offset(20)
                make.width.equalTo(60)
                make.height.equalTo(15)
            }
        let buttonWidth = (UIScreen.main.bounds.width - 170) / 3
        practiceReminderWorkdayTime1.addTo(superView: view) { make in
            make.width.equalTo(buttonWidth)
            make.height.equalTo(32)
            make.centerY.equalTo(workdayTipLabel.snp.centerY)
            make.left.equalTo(workdayTipLabel.snp.right).offset(10)
        }

        practiceReminderWorkdayTime2.addTo(superView: view) { make in
            make.width.equalTo(buttonWidth)
            make.height.equalTo(32)
            make.centerY.equalTo(workdayTipLabel.snp.centerY)
            make.left.equalTo(practiceReminderWorkdayTime1.snp.right).offset(10)
        }

        practiceReminderWorkdayTime3.addTo(superView: view) { make in
            make.width.equalTo(buttonWidth)
            make.height.equalTo(32)
            make.centerY.equalTo(workdayTipLabel.snp.centerY)
            make.left.equalTo(practiceReminderWorkdayTime2.snp.right).offset(10)
        }

        let weekendTipLabel: TKLabel = TKLabel.create()
            .text(text: "Weekend")
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.fourth)
            .addTo(superView: view) { make in
                make.top.equalTo(workdayTipLabel.snp.bottom).offset(27)
                make.left.equalToSuperview().offset(20)
                make.width.equalTo(62)
                make.height.equalTo(15)
            }
        practiceReminderWeekendTime1.addTo(superView: view) { make in
            make.width.equalTo(buttonWidth)
            make.height.equalTo(32)
            make.centerY.equalTo(weekendTipLabel.snp.centerY)
            make.left.equalTo(weekendTipLabel.snp.right).offset(8)
        }
        practiceReminderWeekendTime2.addTo(superView: view) { make in
            make.width.equalTo(buttonWidth)
            make.height.equalTo(32)
            make.centerY.equalTo(weekendTipLabel.snp.centerY)
            make.left.equalTo(practiceReminderWeekendTime1.snp.right).offset(10)
        }
        practiceReminderWeekendTime3.addTo(superView: view) { make in
            make.width.equalTo(buttonWidth)
            make.height.equalTo(32)
            make.centerY.equalTo(weekendTipLabel.snp.centerY)
            make.left.equalTo(practiceReminderWeekendTime2.snp.right).offset(10)
        }

        
        let selectedColor = ColorUtil.main
        let unselectedColor = ColorUtil.Font.fourth
        practiceReminderWorkdayTime1.titleColor(selected: selectedColor, unselected: unselectedColor)
        practiceReminderWorkdayTime2.titleColor(selected: selectedColor, unselected: unselectedColor)
        practiceReminderWorkdayTime3.titleColor(selected: selectedColor, unselected: unselectedColor)
        practiceReminderWeekendTime1.titleColor(selected: selectedColor, unselected: unselectedColor)
        practiceReminderWeekendTime2.titleColor(selected: selectedColor, unselected: unselectedColor)
        practiceReminderWeekendTime3.titleColor(selected: selectedColor, unselected: unselectedColor)

        return view
    }
}

extension SProfileNotificationsCell {
    func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        mainView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow(color: ColorUtil.dividingLine)
        contentView.addSubview(view: mainView) { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        let notificationsLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Notifications")
            .addTo(superView: mainView) { make in
                make.left.equalToSuperview().offset(20)
                make.top.equalToSuperview().offset(18)
                make.height.equalTo(20)
            }

        homeworkReminderView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: mainView, withConstraints: { make in
//                make.top.equalTo(notificationsLabel.snp.bottom).offset(30)
//                make.height.equalTo(64)
                make.top.equalTo(notificationsLabel.snp.bottom).offset(0)
                make.height.equalTo(0)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview()
            })
        homeworkReminderView.layer.masksToBounds = true
        homeworkReminderView.isHidden = true
        let arrowView = UIImageView()
        arrowView.image = UIImage(named: "arrowRight")
        homeworkReminderView.addSubview(view: arrowView) { make in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview()
            make.size.equalTo(22)
        }

        let homeworkRemiderLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Homework Reminder")
            .addTo(superView: homeworkReminderView) { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview()
            }
        homeworkReminderInfoLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Configuration")
            .addTo(superView: homeworkReminderView, withConstraints: { make in
                make.top.equalTo(homeworkRemiderLabel.snp.bottom).offset(7)
                make.left.equalToSuperview()
                make.right.equalTo(arrowView.snp.left).offset(-10)
            })
        homeworkReminderView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.profileNotification(clickHomeworkReminder: self)
        }
        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: homeworkReminderView, withConstraints: { make in
                make.left.bottom.right.equalToSuperview()
                make.height.equalTo(1)
            })
        // lessonNotesView
        lessonNotesView = TKView.create()
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalToSuperview().offset(20)
//                 make.left.equalToSuperview().offset(30)
                make.right.equalToSuperview()
                make.top.equalTo(homeworkReminderView.snp.bottom).offset(10)
                make.height.equalTo(54)
            })
        lessonNotesSwitchView = TKSwitch()
        lessonNotesSwitchView.delegate = self
        lessonNotesView.addSubview(view: lessonNotesSwitchView) { make in
            make.right.equalToSuperview().offset(-20)
//            make.bottom.equalToSuperview().offset(-9)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
            make.width.equalTo(55)
        }
        _ = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Lesson Notes")
            .addTo(superView: lessonNotesView) { make in
                make.left.equalToSuperview()
//                make.bottom.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
            }
        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: lessonNotesView, withConstraints: { make in
                make.left.bottom.right.equalToSuperview()
                make.height.equalTo(1)
            })
        // lessonNewAchievementView
        lessonNewAchievementView = TKView.create()
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview()
                make.top.equalTo(lessonNotesView.snp.bottom)
                make.height.equalTo(54)
            })
        lessonNewAchievementSwitchView = TKSwitch()
        lessonNewAchievementSwitchView.delegate = self
        lessonNewAchievementView.addSubview(view: lessonNewAchievementSwitchView) { make in
            make.right.equalToSuperview().offset(-20)
//            make.bottom.equalToSuperview().offset(-9)
            make.centerY.equalToSuperview()

            make.height.equalTo(22)
            make.width.equalTo(55)
        }
        _ = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "New Award")
            .addTo(superView: lessonNewAchievementView) { make in
                make.left.equalToSuperview()
//                make.bottom.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
            }
        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: lessonNewAchievementView, withConstraints: { make in
                make.left.bottom.right.equalToSuperview()
                make.height.equalTo(1)
            })
        // fileSharedView
        fileSharedView = TKView.create()
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview()
                make.top.equalTo(lessonNewAchievementView.snp.bottom)
                make.height.equalTo(54)
            })
        fileSharedSwitchView = TKSwitch()
        fileSharedSwitchView.delegate = self
        fileSharedView.addSubview(view: fileSharedSwitchView) { make in
            make.right.equalToSuperview().offset(-20)
//            make.bottom.equalToSuperview().offset(-9)
            make.centerY.equalToSuperview()

            make.height.equalTo(22)
            make.width.equalTo(55)
        }
        _ = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "File Shared")
            .addTo(superView: fileSharedView) { make in
                make.left.equalToSuperview()
//                make.bottom.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
            }
        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: fileSharedView, withConstraints: { make in
                make.left.bottom.right.equalToSuperview()
                make.height.equalTo(1)
            })
        // rescheduleConfirmedView
        rescheduleConfirmedView = TKView.create()
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview()
                make.top.equalTo(fileSharedView.snp.bottom)
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
            .text(text: "Reschedule Confirmed")
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

        mainView.addSubview(view: reminderView) { make in
//            make.top.equalTo(rescheduleConfirmedView.snp.bottom)
            make.top.equalTo(fileSharedView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
        }
        reminderView.delegate = self
        TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)
            .addTo(superView: mainView) { make in
                make.bottom.equalTo(reminderView.snp.bottom)
                make.right.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.height.equalTo(1)
            }
        practiceReminderView.addTo(superView: mainView) { make in
            make.top.equalTo(reminderView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
            make.bottom.equalToSuperview().priority(.medium)
        }
        practiceReminderView.clipsToBounds = true
    }
}

extension SProfileNotificationsCell: ProfileNotificationsReminderViewDelegate {
    func profileNotificationsReminderView(heightChanged height: CGFloat) {
        tableView?.beginUpdates()
        reminderView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        tableView?.endUpdates()
    }

    func profileNotificationsReminderView(dataChanged data: [ProfileNotificationsReminderView.ReminderTime], isOn: Bool) {
        // 数据变更
        let times: [Int] = data.compactMap { $0.isSelected ? $0.value : nil }
        delegate?.profileNotification(onReminderDataChangedWith: times, isOn: isOn)
    }
}

extension SProfileNotificationsCell: TKSwitchDelegate {
    func initData(data: TKNotificationConfig) {
        lessonNotesSwitchView.isOn = data.notesNotificationOpened
        lessonNewAchievementSwitchView.isOn = data.newAchievementNotificationOpened
        fileSharedSwitchView.isOn = data.fileSharedNotificationOpened
        rescheduleConfirmedSwitchView.isOn = data.rescheduleConfirmedNotificationOpened
        if data.homeworkReminderTime == -1 {
            homeworkReminderInfoLabel.text("Configuration")
        } else {
            let date = TimeUtil.changeTime(time: Double(Date().startOfDay.timestamp + data.homeworkReminderTime))
            logger.debug("======\(date.timestamp)")
//            let df = DateFormatter()
            tkDF.dateFormat = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"

            homeworkReminderInfoLabel.text(tkDF.string(from: date))
        }

        reminderView.setupData(times: data.reminderTimes, isOn: data.reminderOpened)
    }

    func tkSwitch(_ tkSwitch: TKSwitch, onValueChanged isOn: Bool) {
        switch tkSwitch {
        case rescheduleConfirmedSwitchView:
            delegate?.profileNotification(select: self, isOn: isOn, type: .rescheduleConfirmed)
            break
        case fileSharedSwitchView:
            delegate?.profileNotification(select: self, isOn: isOn, type: .fileShared)
            break
        case lessonNewAchievementSwitchView:
            delegate?.profileNotification(select: self, isOn: isOn, type: .newAchievement)
            break
        case lessonNotesSwitchView:
            delegate?.profileNotification(select: self, isOn: isOn, type: .lessonNotes)
            break
        default:
            break
        }
    }
}

protocol SProfileNotificationsCellDelegate: NSObjectProtocol {
    func profileNotification(clickHomeworkReminder cell: SProfileNotificationsCell)
    func profileNotification(select cell: SProfileNotificationsCell, isOn: Bool, type: SProfileNotificationsCell.ProfileNotificationType)
    func profileNotification(onReminderDataChangedWith times: [Int], isOn: Bool)
}
