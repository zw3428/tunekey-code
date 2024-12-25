//
//  SRescheduleListCell.swift
//  TuneKey
//
//  Created by wht on 2020/4/24.
//  Copyright © 2020 spelist. All rights reserved.
//

import SwiftDate
import UIKit

class SRescheduleListCell: UITableViewCell {
    private var mainView: TKView!

    private var pRView: TKView!
    var pRStatusLabel: TKLabel!
    private var pRTimeView: TKView!
    // 老的时间
    private var pROldView: TKView!
    private var pROldTimeLabel: TKLabel!
    private var pROldDayLabel: TKLabel!
    private var pROldMonthLabel: TKLabel!
    // 新的时间(要修改的时间)
    private var pRNewView: TKView!
    private var pRNewTimeLabel: TKLabel!
    private var pRNewDayLabel: TKLabel!
    private var pRNewMonthLabel: TKLabel!
    private var pRPendingLabel: TKLabel!
    private var pRNewQuestionMarkImageView: TKImageView!
    var pRPendingBackButton: TKLabel!
    var pRPendingConfirmButton: TKBlockButton!
    var pRPendingRescheduleButton: TKBlockButton!
    var pRPendingCloseButton: TKLabel!
    private var pRTimeArrowView: UIImageView!

    var teacherUser: TKUser?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SRescheduleListCell {
    func initView() {
        contentView.backgroundColor = UIColor.white
        mainView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.edges.equalToSuperview()

            })
        pRView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow(color: ColorUtil.dividingLine)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.bottom.equalToSuperview().offset(-10)
                make.height.equalTo(145)
                make.right.equalToSuperview().offset(-20)
            })
        pRPendingLabel = TKLabel.create()
            .text(text: "Pending: ")
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.regular(size: 15))
            .addTo(superView: pRView) { make in
                make.left.equalToSuperview().offset(20)
                make.width.equalTo(70)
                make.top.equalToSuperview().offset(20)
            }
        pRStatusLabel = TKLabel.create()
            .text(text: "Awaiting rescheduling confirmation")
            .textColor(color: ColorUtil.Font.third)
            .font(font: FontUtil.bold(size: 15))
            .addTo(superView: pRView) { make in
                //                make.height.equalTo(20)
                make.left.equalTo(pRPendingLabel.snp.right)
                make.top.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-10)
            }
        //        pendingCountLabel.backgroundColor
        pRStatusLabel.numberOfLines = 0
        pRStatusLabel.lineBreakMode = .byWordWrapping

        pRTimeView = TKView.create()
            .addTo(superView: pRView) { make in
                make.right.left.equalToSuperview()
                make.top.equalTo(pRStatusLabel.snp.bottom).offset(20)
                make.height.equalTo(66)
            }
        pRTimeArrowView = UIImageView()
        pRTimeArrowView.image = UIImage(named: "icReschedule")
        pRTimeView.addSubview(view: pRTimeArrowView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }
        pROldView = TKView.create()
            .addTo(superView: pRTimeView, withConstraints: { make in
                make.top.bottom.equalToSuperview()
                make.right.equalTo(pRTimeArrowView.snp.left).offset(-25)
            })
        pROldTimeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.fourth)
            .text(text: "")
            .addTo(superView: pROldView, withConstraints: { make in
                make.top.left.equalToSuperview()
            })

        pROldDayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.Font.fourth)
            .text(text: "")
            .addTo(superView: pROldView, withConstraints: { make in
                make.bottom.left.equalToSuperview()
            })
        pROldMonthLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.Font.fourth)
            .text(text: "")
            .addTo(superView: pROldView, withConstraints: { make in
                make.bottom.equalToSuperview().offset(-4)
                make.left.equalTo(pROldDayLabel.snp.right).offset(9)
                make.right.equalToSuperview()
            })

        pRNewView = TKView.create()
            .addTo(superView: pRTimeView, withConstraints: { make in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(pRTimeArrowView.snp.right).offset(25)
            })
        pRNewView.layer.masksToBounds = true

        pRNewTimeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "")
            .addTo(superView: pRNewView, withConstraints: { make in
                make.top.left.equalToSuperview()
            })
        pRNewDayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: pRNewView, withConstraints: { make in
                make.bottom.left.equalToSuperview()
            })
        pRNewMonthLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: pRNewView, withConstraints: { make in
                make.bottom.equalToSuperview().offset(-4)
                make.left.equalTo(pRNewDayLabel.snp.right).offset(9)
                make.right.equalToSuperview()
            })

        //        pRNewQuestionMarkView = TKView.create()
        //            .addTo(superView: pRTimeView, withConstraints: { make in
        //                make.top.bottom.equalToSuperview()
        //                make.left.equalTo(pRTimeArrowView.snp.right).offset(30)
        //            })

        pRNewQuestionMarkImageView = TKImageView.create()
            .setImage(name: "redQuestionMark")
            .addTo(superView: pRTimeView) { make in
                make.height.equalTo(40)
                make.width.equalTo(32)
                make.left.equalTo(pRTimeArrowView.snp.right).offset(40)
                make.top.equalToSuperview().offset(15)
            }
        pRNewQuestionMarkImageView.isHidden = true
        pRNewView.isHidden = true

        pRPendingConfirmButton = TKBlockButton(frame: .zero, title: "CONFIRM")
        pRPendingConfirmButton.setFontSize(size: 10)
        pRView.addSubview(view: pRPendingConfirmButton) { make in
            make.height.equalTo(28)
            make.width.equalTo(62)
            make.right.equalTo(-20)
            make.bottom.equalTo(-20)
        }

        pRPendingRescheduleButton = TKBlockButton(frame: .zero, title: "RESCHEDULE", style: .cancel)
        pRPendingRescheduleButton.setFontSize(size: 10)
        pRView.addSubview(view: pRPendingRescheduleButton) { make in
            make.height.equalTo(28)
            make.width.equalTo(90)
            make.right.equalTo(pRPendingConfirmButton.snp.left).offset(-20)
            make.bottom.equalTo(-20)
        }
        pRPendingBackButton = TKLabel.create()
            .font(font: FontUtil.bold(size: 15))
            .alignment(alignment: .center)
            .textColor(color: ColorUtil.main)
            .text(text: "Retract?")
            .addTo(superView: pRView, withConstraints: { make in
                make.right.equalTo(pRPendingRescheduleButton.snp.left).offset(-20)
                make.centerY.equalTo(pRPendingRescheduleButton)
                make.height.equalTo(28)

            })
        pRPendingCloseButton = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.fourth)
            .text(text: "Close")
            .addTo(superView: pRView, withConstraints: { make in
                make.right.equalToSuperview().offset(-20)
                make.bottom.equalToSuperview().offset(-10)
                make.height.equalTo(28)
            })

        pRPendingRescheduleButton.isHidden = true
        pRPendingBackButton.isHidden = true
        pRPendingConfirmButton.isHidden = true
        pRPendingCloseButton.isHidden = true
    }
}

extension SRescheduleListCell {
    func initData(reschedule: TKReschedule, teacherUser: TKUser?) {
        self.teacherUser = teacherUser
        pRPendingBackButton.isHidden = true
        pRPendingRescheduleButton.isHidden = true
        pRPendingConfirmButton.isHidden = true
        pRPendingCloseButton.isHidden = true
        if reschedule.isCancelLesson {
            pRStatusLabel.attributedText = Tools.attributenStringColor(text: "\(teacherUser?.name ?? "") cancelled this lesson", selectedText: teacherUser?.name ?? "", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
            if let time = TimeInterval(reschedule.timeBefore) {
                let dateInRegion = DateInRegion(seconds: time, region: .localRegion)
                let time = NSMutableAttributedString(string: dateInRegion.toFormat("hh:mm a"))
                time.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, time.length))
                pROldTimeLabel.attributedText = time

                let day = NSMutableAttributedString(string: dateInRegion.toFormat("d"))
                day.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, day.length))
                pROldDayLabel.attributedText = day

                let month = NSMutableAttributedString(string: dateInRegion.toFormat("MMM"))
                month.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, month.length))
                pROldMonthLabel.attributedText = month
            }
            pRPendingLabel.snp.updateConstraints { make in
                make.width.equalTo(0)
            }
            pRPendingCloseButton.isHidden = false
            pRTimeArrowView.isHidden = true
            pRNewView.isHidden = true
            return
        }
        pRTimeArrowView.isHidden = false
        if reschedule.timeAfter != "" && Double(reschedule.timeAfter) ?? 0 < Date().timeIntervalSince1970 {
            reschedule.timeAfter = ""
        }
        pRNewView.isHidden = false

        // MARK: - TimeBefore 修改过的地方

        reschedule.getTimeBeforeInterval { [weak self] time in
            guard let self = self else { return }
            let dateInRegion = DateInRegion(seconds: time, region: .localRegion)
            self.pROldTimeLabel.text("\(dateInRegion.toFormat("hh:mm a"))")
            self.pROldDayLabel.text("\(dateInRegion.day)")
            self.pROldMonthLabel.text("\(TimeUtil.getMonthShortName(month: dateInRegion.month))")
        }
        var labelHeight: CGFloat = 20
        var buttonHeight: CGFloat = 48
        var pendingWidth: CGFloat = 0

        pRStatusLabel.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(20)
        }
        pRPendingBackButton.snp.remakeConstraints { make in
            make.right.equalTo(pRPendingRescheduleButton.snp.left).offset(-20)
            make.centerY.equalTo(pRPendingRescheduleButton)
            make.height.equalTo(28)
        }
        if reschedule.timeAfter != "" {
            pRPendingLabel.snp.updateConstraints { make in
                make.width.equalTo(70)
                make.left.equalToSuperview().offset(20)
            }
            pendingWidth = 0
            pRNewView.isHidden = false
            pRNewQuestionMarkImageView.isHidden = true
            pRStatusLabel.text("Awaiting rescheduling confirmation")

            // MARK: - TimeAfter 修改过的地方

            reschedule.getTimeAfterInterval { [weak self] time in
                guard let self = self else { return }
                logger.debug("获取到的之后的时间: \(time)")
                let dateInRegion = DateInRegion(seconds: time, region: .localRegion)
                self.pRNewTimeLabel.text(dateInRegion.toFormat("hh:mm a"))
                self.pRNewDayLabel.text("\(dateInRegion.day)")
                self.pRNewMonthLabel.text("\(TimeUtil.getMonthShortName(month: dateInRegion.month))")
            }
            if reschedule.senderId == UserService.user.id() ?? "" {
//                pRStatusLabel.text("Awaiting rescheduling confirmation")

                if teacherUser != nil && teacherUser!.name != "" {
                    pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Awaiting rescheduling confirmation from \(teacherUser!.name)", selectedText: teacherUser!.name, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                } else {
                    pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Awaiting rescheduling confirmation", selectedText: "", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                }
                pendingWidth = 70
                pRPendingBackButton.isHidden = false

                pRPendingRescheduleButton.snp.updateConstraints { make in
                    make.width.equalTo(0)
                }
                pRPendingConfirmButton.snp.updateConstraints { make in
                    make.width.equalTo(0)
                    make.right.equalTo(0)
                }
                pRPendingBackButton.snp.remakeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.centerY.equalTo(pRPendingRescheduleButton).offset(10)
                    make.height.equalTo(28)
                }

                if reschedule.teacherRevisedReschedule {
                    pRPendingRescheduleButton.isHidden = false
                    pRPendingConfirmButton.isHidden = false
                    pRPendingLabel.snp.updateConstraints { make in
                        make.width.equalTo(0)
                    }
                    pendingWidth = 0

                    if teacherUser != nil && teacherUser!.name != "" {
                        pRStatusLabel.attributedText = Tools.attributenStringColor(text: "\(teacherUser!.name) sent a reschedule request", selectedText: teacherUser!.name, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                    } else {
                        pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Your instructor sent a reschedule request", selectedText: "", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                    }

                    pRPendingRescheduleButton.snp.updateConstraints { make in
                        make.width.equalTo(0)
                    }
                    pRStatusLabel.snp.updateConstraints { make in
                        make.top.equalToSuperview().offset(10)
                    }
                    pRPendingRescheduleButton.snp.updateConstraints { make in
                        make.width.equalTo(90)
                    }
                    pRPendingConfirmButton.snp.updateConstraints { make in
                        make.width.equalTo(62)
                        make.right.equalTo(-20)
                    }
                    pRPendingBackButton.snp.remakeConstraints { make in
                        make.right.equalTo(pRPendingRescheduleButton.snp.left).offset(-20)
                        make.centerY.equalTo(pRPendingRescheduleButton)
                        make.height.equalTo(28)
                    }
                }
            } else {
                if reschedule.studentRevisedReschedule {
                    if teacherUser != nil && teacherUser!.name != "" {
                        pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Awaiting rescheduling confirmation from \(teacherUser!.name)", selectedText: teacherUser!.name, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                    } else {
                        pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Awaiting rescheduling confirmation", selectedText: "", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                    }
                    pRPendingConfirmButton.snp.updateConstraints { make in
                        make.width.equalTo(0)
                        make.right.equalTo(0)
                    }
                    pRPendingLabel.snp.updateConstraints { make in
                        make.width.equalTo(70)
                    }
                    pendingWidth = 70
                    pRPendingRescheduleButton.isHidden = true
                    pRPendingConfirmButton.isHidden = true
                } else {
                    pRPendingRescheduleButton.isHidden = false
                    pRPendingConfirmButton.isHidden = false
                    pRPendingConfirmButton.snp.updateConstraints { make in
                        make.width.equalTo(62)
                        make.right.equalTo(-20)
                    }
                    pRPendingLabel.snp.updateConstraints { make in
                        make.width.equalTo(0)
                    }
                    pendingWidth = 0
                    if teacherUser != nil && teacherUser!.name != "" {
                        pRStatusLabel.attributedText = Tools.attributenStringColor(text: "\(teacherUser!.name) sent a reschedule request", selectedText: teacherUser!.name, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                    } else {
                        pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Your instructor sent a reschedule request", selectedText: "", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                    }
                }
                pRPendingBackButton.isHidden = true
                pRPendingRescheduleButton.snp.updateConstraints { make in
                    make.width.equalTo(90)
                }
            }
            if reschedule.retracted {
                var teacherName: String = ""
                if let name = teacherUser?.name {
                    teacherName = name
                }
                let statusText = "\(teacherName) retracted the reschedule request"
                pRPendingLabel.snp.updateConstraints { make in
                    make.width.equalTo(0)
                    make.left.equalToSuperview().offset(20)
                }
                pRPendingCloseButton.isHidden = false
                pRPendingConfirmButton.isHidden = true
                pRPendingRescheduleButton.isHidden = true
                pRPendingBackButton.isHidden = true
//                pRView.snp.updateConstraints { make in
//                    make.height.equalTo(173)
//                }
                pRStatusLabel.attributedText = Tools.attributenStringColor(text: statusText, selectedText: teacherName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
            }
        } else {
            pRNewTimeLabel.text = ""
            pRNewDayLabel.text = ""
            pRNewMonthLabel.text = ""
            if teacherUser != nil && teacherUser!.name != "" {
                pRStatusLabel.attributedText = Tools.attributenStringColor(text: "\(teacherUser!.name) sent a reschedule request", selectedText: teacherUser!.name, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
            } else {
                pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Your instructor sent a reschedule request", selectedText: "", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
            }
            pRNewView.isHidden = true
            pRNewQuestionMarkImageView.isHidden = false
            pRPendingLabel.snp.updateConstraints { make in
                make.width.equalTo(0)
            }
            buttonHeight = 0
            pendingWidth = 0
            if reschedule.senderId == UserService.user.id() ?? "" {
                pRPendingBackButton.isHidden = false
                buttonHeight = 48
                pRPendingBackButton.snp.remakeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.centerY.equalTo(pRPendingRescheduleButton).offset(10)
                    make.height.equalTo(28)
                }
                if teacherUser != nil && teacherUser!.name != "" {
                    pRStatusLabel.attributedText = Tools.attributenStringColor(text: "\(teacherUser!.name) sent a reschedule request", selectedText: teacherUser!.name, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                } else {
                    pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Your instructor sent a reschedule request", selectedText: "", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
                }

//                if reschedule.teacherRevisedReschedule {
//                    if teacherUser != nil && teacherUser!.name != "" {
//                        pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Reschedule request from \(teacherUser!.name)", selectedText: teacherUser!.name, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
//                    } else {
//                        pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Reschedule request from your teacher", selectedText: "", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
//                    }
//                } else {
//                    pRPendingLabel.snp.updateConstraints { make in
//                        make.width.equalTo(70)
//                        make.left.equalToSuperview().offset(20)
//                    }
//                    pendingWidth = 70
//                    if teacherUser != nil && teacherUser!.name != "" {
//                        pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Awaiting rescheduling confirmation from \(teacherUser!.name)", selectedText: teacherUser!.name, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
//                    } else {
//                        pRStatusLabel.attributedText = Tools.attributenStringColor(text: "Awaiting rescheduling confirmation", selectedText: "", allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
//                    }
//                }
            }

            if reschedule.retracted {
                var teacherName: String = ""
                if let name = teacherUser?.name {
                    teacherName = name
                }
                buttonHeight = 48
                let statusText = "\(teacherName) retracted the reschedule request"
                pRPendingLabel.snp.updateConstraints { make in
                    make.width.equalTo(0)
                    make.left.equalToSuperview().offset(20)
                }
                pRPendingCloseButton.isHidden = false
                pRPendingConfirmButton.isHidden = true
                pRPendingRescheduleButton.isHidden = true
                pRPendingBackButton.isHidden = true

                pRStatusLabel.attributedText = Tools.attributenStringColor(text: statusText, selectedText: teacherName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
            }
        }
        if reschedule.confirmType != .unconfirmed {
            var teacherName: String = ""
            if let name = teacherUser?.name {
                teacherName = name
            }
            var statusText: String = ""
            if reschedule.retracted {
                statusText = "\(teacherName) retracted the reschedule request"
            } else {
                switch reschedule.confirmType {
                case .unconfirmed: break
                case .refuse: statusText = "\(teacherName) declineded the reschedule request"
                case .confirmed: statusText = "\(teacherName) confirmed the reschedule request"
                }
            }
            buttonHeight = 48
            pendingWidth = 0
            if statusText != "" {
                pRPendingLabel.snp.updateConstraints { make in
                    make.width.equalTo(0)
                    make.left.equalToSuperview().offset(20)
                }
                pRPendingCloseButton.isHidden = false
                pRPendingConfirmButton.isHidden = true
                pRPendingRescheduleButton.isHidden = true
                pRPendingBackButton.isHidden = true

                pRStatusLabel.attributedText = Tools.attributenStringColor(text: statusText, selectedText: teacherName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
            }
        }

        if pRStatusLabel.attributedText != nil {
            labelHeight = pRStatusLabel.attributedText!.string.getLableHeigh(font: FontUtil.bold(size: 15), width: UIScreen.main.bounds.width - 40 - 40 - pendingWidth)
        }
        if pRPendingCloseButton.isHidden &&
            pRPendingConfirmButton.isHidden &&
            pRPendingRescheduleButton.isHidden &&
            pRPendingBackButton.isHidden {
            buttonHeight = 20
        }
        if !pRPendingCloseButton.isHidden {
            buttonHeight = 40
        }
        pRView.snp.updateConstraints { make in
            make.height.equalTo(125 + labelHeight + buttonHeight)
        }
    }
}
