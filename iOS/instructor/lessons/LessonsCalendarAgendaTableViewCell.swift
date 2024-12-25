//
//  LessonsCalendarAgendaTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/27.
//  Copyright © 2019年 spelist. All rights reserved.
//
import EventKit
import UIKit

class LessonsCalendarAgendaTableViewCell: UITableViewCell {
    weak var delegate: LessonsCalendarAgendaTableViewCellDelegate?

    private var backView: TKView!
    private var avatarView: TKAvatarView!
    private var timeLabel: TKLabel!
    private var nameLabel: TKLabel!
    private var rightArrowImageView: TKImageView!
    private var data: TKLessonSchedule!
    private var blockAndEventAvatarView: TKLabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonsCalendarAgendaTableViewCell {
    private func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
        backView.enableShadowAnimationOnTapped = true
        backView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.lessonsCalendarAgendaTableViewCellTapped(cell: self)
        }
        contentView.addSubview(backView)
        backView.snp.makeConstraints { make in
            make.top.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(-10)
            make.height.equalTo(100)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        avatarView = TKAvatarView()
        avatarView.setSize(size: 60)

        backView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(backView).offset(20)
            make.size.equalTo(60)
        }

        nameLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .alignment(alignment: .left)
            .text(text: "")
        nameLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        backView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(backView).offset(27)
            make.left.equalTo(avatarView.snp.right).offset(20)
            make.right.equalTo(backView).offset(-35)
        }

        timeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.second)
            .alignment(alignment: .left)
            .text(text: "")
        backView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.left.equalTo(avatarView.snp.right).offset(20)
            make.right.equalTo(backView).offset(-20)
        }

        rightArrowImageView = TKImageView.create()
            .setImage(name: "arrowRight")
            .setSize(22)
        backView.addSubview(rightArrowImageView)
        rightArrowImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(22)
            make.right.equalToSuperview().offset(-20)
        }
        blockAndEventAvatarView = TKLabel.create()
            .alignment(alignment: .center)
            .textColor(color: ColorUtil.Font.primary)
            .font(font: FontUtil.bold(size: 18))
            .addTo(superView: backView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(backView).offset(20)
                make.size.equalTo(0)
            })
        blockAndEventAvatarView.layer.cornerRadius = 30
        blockAndEventAvatarView.layer.masksToBounds = true
        blockAndEventAvatarView.isHidden = true
    }

    func loadData(data: GoogleCalendarEventForShow?) {
        nameLabel.text = data?.summary ?? ""
        timeLabel.snp.updateConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(15)
        }
        avatarView.loadImage(image: UIImage(named: "ic_google")!)
        blockAndEventAvatarView.isHidden = false
        blockAndEventAvatarView.text = ""
        blockAndEventAvatarView.backgroundColor = UIColor(r: 235, g: 237, b: 238, alpha: 0.32)
        blockAndEventAvatarView.snp.updateConstraints { make in
            make.size.equalTo(60)
        }
    }
    func loadData(data: EKEvent?) {
        nameLabel.text = data?.title ?? ""
        timeLabel.snp.updateConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(15)
        }
        avatarView.loadImage(image: UIImage(named: "ic_apple")!)
        blockAndEventAvatarView.isHidden = false
        blockAndEventAvatarView.text = ""
        blockAndEventAvatarView.backgroundColor = UIColor(r: 235, g: 237, b: 238, alpha: 0.32)
        blockAndEventAvatarView.snp.updateConstraints { make in
            make.size.equalTo(60)
        }
    }

    func loadData(data: TKLessonSchedule) {
        var borderColor: UIColor
        if data.shouldDateTime < TimeInterval(Date().timestamp) {
            borderColor = ColorUtil.borderColor
        } else {
            if data.rescheduled {
                logger.debug("被Reschedule的数据: \(data.toJSONString() ?? "")")
                borderColor = ColorUtil.red
            } else {
                borderColor = ColorUtil.borderColor
            }
            if data.type == .lesson {
                if data.getShouldDateTime() < TimeInterval(Date().timestamp) {
                    borderColor = ColorUtil.borderColor
                }
            }
        }
        backView.showBorder(color: borderColor)
        rightArrowImageView.isHidden = true
        blockAndEventAvatarView.isHidden = true
        blockAndEventAvatarView.snp.updateConstraints { make in
            make.size.equalTo(0)
        }
        
        switch data.type {
        case .lesson:
            timeLabel.snp.updateConstraints { make in
                make.top.equalTo(nameLabel.snp.bottom).offset(6)
            }
            avatarView.isHidden = false
            rightArrowImageView.isHidden = false
            nameLabel.text = data.studentData?.name
            avatarView.loadImage(userId: data.studentId, name: data.studentData?.name ?? "")
        case .event:
            nameLabel.text = data.eventConfigData.title
            timeLabel.snp.updateConstraints { make in
                make.top.equalTo(nameLabel.snp.bottom).offset(15)
            }
            avatarView.isHidden = true
            blockAndEventAvatarView.isHidden = false
            blockAndEventAvatarView.text = "Event"
            blockAndEventAvatarView.backgroundColor = UIColor(r: 235, g: 237, b: 238, alpha: 0.32)
            blockAndEventAvatarView.snp.updateConstraints { make in
                make.size.equalTo(60)
            }
        case .block:
            nameLabel.text = ""
            timeLabel.snp.updateConstraints { make in
                make.top.equalTo(nameLabel.snp.bottom).offset(15)
            }
            blockAndEventAvatarView.isHidden = false
            blockAndEventAvatarView.text = "Off"
            avatarView.isHidden = true
            blockAndEventAvatarView.backgroundColor = UIColor(r: 235, g: 237, b: 238)
            blockAndEventAvatarView.snp.updateConstraints { make in
                make.size.equalTo(60)
            }
        case .googleCalendarEvent:
            loadData(data: data.googleCalendarEvent)
        case .appleCalendarEvent:
            loadData(data: data.appleCalendarEvent)
        case .reschedule:
            break
        }
        timeLabel.text = "\(data.getDateLimitV2().start) - \(data.getDateLimitV2().end)"
//        timeLabel.text = "\(Date(seconds: data.shouldDateTime).toLocalFormat("hh:mm a")) - \(Date(seconds: data.shouldDateTime + Double(data.shouldTimeLength * 60)).toLocalFormat("hh:mm a"))"
    }

    func showBorder() {
    }

    func hideBorder() {
    }
}

protocol LessonsCalendarAgendaTableViewCellDelegate: NSObjectProtocol {
    func lessonsCalendarAgendaTableViewCellTapped(cell: LessonsCalendarAgendaTableViewCell)
}
