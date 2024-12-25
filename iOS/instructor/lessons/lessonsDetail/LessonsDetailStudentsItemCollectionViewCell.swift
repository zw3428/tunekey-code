//
//  LessonsDetailStudentsCollectionViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/30.
//  Copyright © 2019年 spelist. All rights reserved.
//

// import CollectionViewPagingLayout
import UIKit

// extension LessonsDetailStudentsItemCollectionViewCell: ScaleTransformView {
// }

class LessonsDetailStudentsItemCollectionViewCell: UICollectionViewCell {
    private var containerView: TKView!
    private var backView: TKView!
    private var avatarView: TKAvatarView!
    private var nameLabel: TKLabel!
    private var detailLabel: TKLabel!
    private var rightArrowView: TKImageView!

    private var timeLineLeft: TKView!
    private var timeLineRight: TKView!
    private var arrowLeftView: TKImageView = TKImageView.create()
        .setImage(name: "arrow_left_double")
    private var lineLeftCover: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.backgroundColor)
    private var arrowRightView: TKImageView = TKImageView.create()
        .setImage(name: "arrow_right_double")
    private var lineRightCover: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.backgroundColor)
    private var timeLabel: TKLabel!
    weak var delegate: LessonsDetailStudentsItemCollectionViewCellDelegate!
    var stepBar: TKStepBar!

    private var teacherAvatarView: TKAvatarView = TKAvatarView()
    private var teacherNameLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.Font.fourth)

    private var edgeConstraints: [NSLayoutConstraint]?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ColorUtil.backgroundColor
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonsDetailStudentsItemCollectionViewCell {
    private func initView() {
        containerView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.center.size.equalToSuperview()
            })
        initTopViews()
        initTimeLineViews()
        contentView.backgroundColor = stepBar.backgroundColor
    }

    private func initTopViews() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
        containerView.addSubview(backView)
        backView.snp.makeConstraints { make in
            make.top.equalTo(self.containerView).offset(25)
            make.left.equalTo(self.containerView).offset(5)
            make.right.equalTo(self.containerView).offset(-5)
            make.height.equalTo(100)
        }
        backView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.lessonsDetailStudentsItemCollectionViewCell()
        }

        avatarView = TKAvatarView()
        avatarView.setSize(size: 60)
        backView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(60)
        }

        nameLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
        nameLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        backView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(27)
            make.left.equalTo(avatarView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-40)
        }

        rightArrowView = TKImageView.create()
            .setImage(name: "arrowRight")
            .setSize(22)
        backView.addSubview(rightArrowView)
        rightArrowView.snp.makeConstraints { make in
            make.centerY.equalTo(avatarView.snp.centerY)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }
        
        detailLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .setNumberOfLines(number: 2)
        backView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.left.equalTo(avatarView.snp.right).offset(20)
//            make.right.equalToSuperview().offset(-20)
            make.right.equalTo(rightArrowView.snp.left)
        }
    }

    private func initTimeLineViews() {
        timeLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 15))
            .textColor(color: ColorUtil.Font.fourth)
        timeLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.83)
        containerView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(backView.snp.bottom).offset(15)
            make.centerX.equalToSuperview()
        }

        stepBar = TKStepBar()
        containerView.addSubview(stepBar)
        stepBar.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-27.5)
            make.left.equalTo(self.containerView).offset(20)
            make.right.equalTo(self.containerView).offset(-20)
            make.height.equalTo(45)
        }
        stepBar.set(text: ["Prep", "Lesson", "Recap"])
        containerView.backgroundColor = stepBar.backgroundColor

        timeLineLeft = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)
            .corner(size: 0.5)
        containerView.addSubview(timeLineLeft)
        timeLineLeft.snp.makeConstraints { make in
//            make.top.equalTo(backView.snp.bottom).offset(25)
            make.centerY.equalTo(stepBar)
            make.height.equalTo(1)
            make.left.equalToSuperview()
            make.right.equalTo(stepBar.snp.left)
        }
        containerView.addSubview(view: lineLeftCover) { make in
            make.centerY.equalTo(timeLineLeft.snp.centerY)
            make.height.equalTo(timeLineLeft.snp.height)
            make.left.equalToSuperview().offset(20)
            make.width.equalTo(40)
        }

        containerView.addSubview(view: arrowLeftView) { make in
            make.center.equalTo(lineLeftCover)
            make.size.equalTo(14)
        }

        timeLineRight = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)
            .corner(size: 0.5)
        containerView.addSubview(timeLineRight)
        timeLineRight.snp.makeConstraints { make in
//            make.top.equalTo(backView.snp.bottom).offset(25)
            make.centerY.equalTo(stepBar)
            make.height.equalTo(1)
            make.right.equalToSuperview()
            make.left.equalTo(stepBar.snp.right)
        }

        containerView.addSubview(view: lineRightCover) { make in
            make.centerY.equalTo(timeLineRight.snp.centerY)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(timeLineRight.snp.height)
            make.width.equalTo(40)
        }

        containerView.addSubview(view: arrowRightView) { make in
            make.center.equalTo(lineRightCover)
            make.size.equalTo(14)
        }
    }
}

extension LessonsDetailStudentsItemCollectionViewCell {
    func initData(data: TKLessonSchedule, hasPre: Bool = false, hasNext: Bool = false, config: TKLessonScheduleConfigure?, lessonType: TKLessonType?) {
        avatarView.loadImage(userId: data.studentId, name: data.studentData?.name ?? "")
        nameLabel.text = data.studentData?.name ?? ""
        if let lessonScheduleData = data.lessonScheduleData, let config = config {
            var text = ""
            if let lessonType = data.lessonTypeData {
                text = "\(lessonType.timeLength)min\(lessonType.timeLength > 0 ? "s" : "") at \(TimeUtil.changeTime(time: data.getShouldDateTime()).toLocalFormat(Locale.is12HoursFormat() ? "hh: mm a" : "HH:mm"))"
            }
            let diff = TimeUtil.getUTCWeekdayDiff(timestamp: Int(config.startDateTime * 1000))
            let weeks: [Int] = lessonScheduleData.repeatTypeWeekDay.compactMap {
                var i = $0 + (-diff)
                if i < 0 {
                    i = 6
                } else if i > 6 {
                    i = 0
                }
                return i
            }
            text += ", "
            text += weeks.sorted(by: { $0 < $1 }).compactMap({ TimeUtil.getWeekDayShotName(weekDay: $0 ).capitalized }).joined(separator: ", ")
            
            switch lessonScheduleData.repeatType {
            case .none:
                break
            case .weekly:
                if text != "" {
                    text += ", "
                }
                text += "Weekly"
                break
            case .biWeekly:
                if text != "" {
                    text += ", "
                }
                text += "Bi-weekly"
                break
            case .monthly:
                if text != "" {
                    text += ", "
                }
                text += "Monthly"
                break
            }
            detailLabel.text = text
//            if let config = config, let lessonType = lessonType {
//                let originalPrice = "$\(lessonType.price.description)"
//                var specialPrice = ""
//                var detailText = ""
//                if config.specialPrice >= 0 {
//                    specialPrice = "$\(config.specialPrice.descWithCleanZero)"
//                }
//                detailText += "\(originalPrice)\(specialPrice != "" ? " " : "")\(specialPrice) / lesson, \(lessonType.timeLength) mins"
//                var ranges: [NSRange] = []
//                if specialPrice != "" {
//                    ranges += detailText.nsranges(of: originalPrice)
//                }
//                if lessonType.package > 0 && config.repeatType != .none {
//                    let originalTotalPrice = "$\((lessonType.price as Decimal) * Decimal(lessonType.package))"
//                    let specialTotalPrice: String
//                    if config.specialPrice >= 0 {
//                        specialTotalPrice = "$\((config.specialPrice * Double(lessonType.package)).descWithCleanZero) "
//                    } else {
//                        specialTotalPrice = ""
//                    }
//                    detailText += "\n\(originalTotalPrice) \(specialTotalPrice)for \(lessonType.package) lesson\(lessonType.package > 1 ? "s" : "")"
//                    if config.specialPrice >= 0 {
//                        ranges += detailText.nsranges(of: originalTotalPrice)
//                    }
//                }
//
//                let attributeText: NSMutableAttributedString = NSMutableAttributedString(string: detailText)
//                attributeText.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorUtil.Font.primary, range: NSRange(location: 0, length: detailText.count))
//                for range in ranges {
//                    attributeText.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSNumber(value: 1), range: range)
//                    attributeText.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorUtil.Font.primary.withAlphaComponent(0.5), range: range)
//                }
//                detailLabel.attributedText = attributeText
//            } else {
//                var text = ""
//                if let lessonType = data.lessonTypeData {
//                    text = "\(lessonType.timeLength)min\(lessonType.timeLength > 0 ? "s" : "") at \(TimeUtil.changeTime(time: data.getShouldDateTime()).toLocalFormat(Locale.is12HoursFormat() ? "hh: mm a" : "HH:mm"))"
//                }
//                switch lessonScheduleData.repeatType {
//                case .none:
//                    break
//                case .weekly:
//                    if text != "" {
//                        text += ", "
//                    }
//                    text += "Weekly"
//                    break
//                case .biWeekly:
//                    if text != "" {
//                        text += ", "
//                    }
//                    text += "Bi-weekly"
//                    break
//                case .monthly:
//                    if text != "" {
//                        text += ", "
//                    }
//                    text += "Monthly"
//                    break
//                }
//                detailLabel.text = text
//            }
        }
        if ListenerService.shared.currentRole == .studioManager {
            let teacherId = data.teacherId
            TKUser.get(teacherId)
                .done { [weak self] user in
                    guard let self = self else { return }
                    if let user = user {
                        DispatchQueue.main.async {
                            self.backView.snp.updateConstraints { make in
                                make.height.equalTo(120)
                            }
                            self.teacherAvatarView.loadImage(userId: user.userId, name: user.name)
                            self.teacherNameLabel.text(user.name)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.teacherAvatarView.isHidden = true
                            self.teacherNameLabel.isHidden = true
                            self.backView.snp.updateConstraints { make in
                                make.height.equalTo(100)
                            }
                        }
                    }
                }
                .catch { error in
                    logger.error("获取教师失败: \(error)")
                }
        } else {
            backView.snp.updateConstraints { make in
                make.height.equalTo(100)
            }
            teacherAvatarView.isHidden = true
            teacherNameLabel.isHidden = true
        }

        let d = DateFormatter()
        d.dateFormat = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"
        timeLabel.text = d.string(from: TimeUtil.changeTime(time: data.getShouldDateTime()))
//        timeLabel.text = Date(seconds: data.shouldDateTime).toLocalFormat("hh:mm a")
        switch data.lessonStatus {
        case .schedule:
            stepBar.update(index: 0)
            break
        case .started:
            stepBar.update(index: 1)
            break
        case .ended:
            stepBar.update(index: 2)
            break
        }

        lineLeftCover.isHidden = true
        arrowLeftView.isHidden = true
        timeLineLeft.isHidden = !hasPre

        lineRightCover.isHidden = true
        arrowRightView.isHidden = true
        timeLineRight.isHidden = !hasNext
    }
}

protocol LessonsDetailStudentsItemCollectionViewCellDelegate: NSObjectProtocol {
    func lessonsDetailStudentsItemCollectionViewCell()
}
