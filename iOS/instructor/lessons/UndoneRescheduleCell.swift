//
//  UndoneRescheduleCell.swift
//  TuneKey
//
//  Created by wht on 2020/4/30.
//  Copyright © 2020 spelist. All rights reserved.
//

import MessageUI
import UIKit

class UndoneRescheduleCell: UITableViewCell {
    private var mainView: TKView!

    private var pRView: TKView!
    private var pRStatusLabel: TKLabel!
    private var pRTimeView: TKView!
    // 老的时间
    private var pROldView: TKView!
    private var pROldTimeLabel: TKLabel!
    private var pROldDayLabel: TKLabel!
    private var pROldMonthLabel: TKLabel!
    // 新的时间(要修改的时间)
    var pRNewView: TKView!
    private var pRNewTimeLabel: TKLabel!
    private var pRNewDayLabel: TKLabel!
    private var pRNewMonthLabel: TKLabel!
    private var pRPendingLabel: TKLabel!
    var pRNewQuestionMarkImageView: TKImageView!
    var pRTimeArrowView: UIImageView!
    var pRPendingBackButton: TKLabel!
    var confirmButton: TKBlockButton!
    var rescheduleButton: TKBlockButton!
    var rejectButton: TKLabel!
    var closeButton: TKLabel!
    var bottomLine: TKView!

    private var data: TKReschedule?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UndoneRescheduleCell {
    func initView() {
        contentView.backgroundColor = UIColor.white
        mainView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.edges.equalToSuperview()
            })
        pRView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.bottom.equalToSuperview()
                make.height.equalTo(145)
                make.right.equalToSuperview().offset(-20)
            })
        pRPendingLabel = TKLabel.create()
            .text(text: "")
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.regular(size: 15))
            .addTo(superView: pRView) { make in
                make.left.equalToSuperview().offset(0)
                make.width.equalTo(70)
                make.top.equalToSuperview().offset(20)
            }
        pRStatusLabel = TKLabel.create()
            .text(text: "Awaiting rescheduling confirmation")
            .textColor(color: ColorUtil.Font.third)
            .font(font: FontUtil.bold(size: 15))
            .setNumberOfLines(number: 0)
            .addTo(superView: pRView) { make in
                make.left.equalTo(pRPendingLabel.snp.right)
                make.top.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(0)
            }

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
//                make.right.equalTo(pRTimeArrowView.snp.left).offset(-25)
                make.left.equalTo(20)
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

        confirmButton = TKBlockButton(frame: .zero, title: "CONFIRM", style: .normal)
        confirmButton.setFontSize(size: 10)

        pRView.addSubview(view: confirmButton) { make in
            make.height.equalTo(28)
            make.width.equalTo(62)
            make.bottom.equalTo(-10)
            make.right.equalToSuperview()
        }
        rescheduleButton = TKBlockButton(frame: .zero, title: "RESCHEDULE", style: .cancel)
        rescheduleButton.setFontSize(size: 10)
        pRView.addSubview(view: rescheduleButton) { make in
            make.height.equalTo(28)
            make.width.equalTo(90)
            make.bottom.equalTo(-10)
            make.right.equalTo(confirmButton.snp.left).offset(-20)
        }
        rejectButton = TKLabel.create()
            .text(text: "DECLINED")
            .textColor(color: ColorUtil.Font.fourth)
            .font(font: FontUtil.bold(size: 10))
        closeButton = TKLabel.create()
            .text(text: "CLOSE")
            .textColor(color: ColorUtil.Font.fourth)
            .font(font: FontUtil.bold(size: 10))
            .addTo(superView: pRView, withConstraints: { make in
                make.height.equalTo(28)
                make.bottom.equalTo(-10)
                make.right.equalToSuperview()
            })
        closeButton.isHidden = true
        pRPendingBackButton = TKLabel.create()
            .font(font: FontUtil.bold(size: 15))
            .alignment(alignment: .center)
            .textColor(color: ColorUtil.main)
            .text(text: "Retract?")
            .addTo(superView: pRView, withConstraints: { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(-10)
                make.height.equalTo(28)
            })
        pRPendingBackButton.isHidden = true

        pRView.addSubview(view: rejectButton) { make in
            make.height.equalTo(28)
            make.bottom.equalTo(-10)
            make.right.equalTo(rescheduleButton.snp.left).offset(-20)
        }

        // 分割线
        bottomLine = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: mainView) { make in
                make.bottom.right.equalToSuperview()
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(20)
            }

        pRStatusLabel.onViewTapped { [weak self] _ in
            self?.showEmailAndPhone()
        }
    }
}

extension UndoneRescheduleCell {
    // MARK: - Data

    func initData(reschedule: TKReschedule, hasNext: Bool = true) {
        pRPendingBackButton.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-10)
            make.height.equalTo(28)
        }
        bottomLine.isHidden = !hasNext
        if reschedule.timeAfter != "" && Double(reschedule.timeAfter) ?? 0 < Date().timeIntervalSince1970 {
            reschedule.timeAfter = ""
        }
        data = reschedule
        let df = DateFormatter()
        df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a": "HH:mm"
        reschedule.getTimeBeforeInterval { (time) in
            let beforeDate = Date(seconds: time)
            print("===beforeDate.timestamp:===\(beforeDate.timestamp)=====\(df.string(from: beforeDate))")
            self.pROldTimeLabel.text("\(df.string(from: beforeDate))")
            self.pROldTimeLabel.attributedText = NSMutableAttributedString(string: "\(df.string(from: beforeDate))")
            self.pROldDayLabel.text("\(beforeDate.day)")
            self.pROldDayLabel.attributedText = NSMutableAttributedString(string: "\(beforeDate.day)")
            self.pROldMonthLabel.text("\(TimeUtil.getMonthShortName(month: beforeDate.month))")
            self.pROldMonthLabel.attributedText = NSMutableAttributedString(string: "\(TimeUtil.getMonthShortName(month: beforeDate.month))")
        }
        var text = "Reschedule request "
        if reschedule.makeup {
            text = "Make up request "
        }
        var studentName = ""
        if reschedule.studentData != nil {
            logger.debug("学生姓名: 学生不是空的")
            studentName = reschedule.studentData!.name
            text = "\(text) from \(studentName)"
        } else {
            logger.debug("学生姓名: 学生是空的")
            text = "\(text)"
        }
        logger.debug("学生姓名: \(studentName)")
        pRPendingLabel.text("")
        closeButton.isHidden = true
        rejectButton.isHidden = true
        confirmButton.isHidden = true
        rescheduleButton.isHidden = true
        pRPendingBackButton.isHidden = true
        confirmButton.snp.updateConstraints { make in
            make.width.equalTo(62)
        }
        rescheduleButton.snp.updateConstraints { make in
            make.right.equalTo(confirmButton.snp.left).offset(-20)
        }
        pRTimeArrowView.isHidden = false
        var height: CGFloat = 125
        var pendingWidth: CGFloat = 0
        pRPendingLabel.snp.updateConstraints { make in
            make.width.equalTo(0)
            make.left.equalToSuperview().offset(0)
        }
        pRPendingLabel.text("")
        logger.debug("Reschedule Cell => \(reschedule.toJSONString() ?? "")")
        if reschedule.isCancelLesson {
            logger.debug("Reschedule Cell => 当前reschedule是cancelation")
            pRTimeArrowView.isHidden = true
            closeButton.isHidden = false
            pRNewView.isHidden = true
            pRNewQuestionMarkImageView.isHidden = true
            pendingWidth = 0
            pRPendingLabel.snp.updateConstraints { make in
                make.width.equalTo(0)
                make.left.equalToSuperview().offset(0)
            }
            let time = NSMutableAttributedString(string: "\(pROldTimeLabel.text!)")
            time.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, time.length))
            pROldTimeLabel.attributedText = time

            let day = NSMutableAttributedString(string: "\(pROldDayLabel.text!)")
            day.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, day.length))
            pROldDayLabel.attributedText = day

            let month = NSMutableAttributedString(string: "\(pROldMonthLabel.text!)")
            month.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, month.length))
            pROldMonthLabel.attributedText = month

            text = "\(studentName) canceled the lesson"
            pRStatusLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: studentName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
            height = 152
        } else if reschedule.retracted {
            logger.debug("Reschedule Cell => 当前是被撤销的reschedule")
            if !reschedule.teacherRead && reschedule.retractor != UserService.user.id()! {
                pRTimeArrowView.isHidden = false
                closeButton.isHidden = false
                pRNewView.isHidden = true
                pRNewQuestionMarkImageView.isHidden = true
                pendingWidth = 0
                pRPendingLabel.snp.updateConstraints { make in
                    make.width.equalTo(0)
                    make.left.equalToSuperview().offset(0)
                }
                if reschedule.timeAfter != "" {
                    pRNewView.isHidden = false
                    pRNewQuestionMarkImageView.isHidden = true
                    // MARK: - TimeAfter 修改过的地方
                    reschedule.getTimeAfterInterval {[weak self] (time) in
                        guard let self = self else{return}
                        let afterDate = Date(seconds: time)
                        self.pRNewTimeLabel.text("\(df.string(from: afterDate))")
                        self.pRNewDayLabel.text("\(afterDate.day)")
                        self.pRNewMonthLabel.text("\(TimeUtil.getMonthShortName(month: afterDate.month))")
                    }
                }
                text = "\(studentName) retraced the reschedule request"

                pRStatusLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: studentName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
                height = 152
            }
        } else if reschedule.senderId == UserService.user.id()! || (reschedule.confirmerId == UserService.user.id()! && reschedule.teacherRevisedReschedule) {
            logger.debug("Reschedule Cell => 走到了判断里")


            // 发送者是学生,确认者是自己,自己还没有操作
            if (reschedule.confirmType == .confirmed || reschedule.confirmType == .refuse) && !reschedule.teacherRead {
                logger.debug("Reschedule Cell => 判断1")
                pRTimeArrowView.isHidden = false
                closeButton.isHidden = false
                pRNewView.isHidden = true
                pRNewQuestionMarkImageView.isHidden = true
                pendingWidth = 0
                pRPendingLabel.snp.updateConstraints { make in
                    make.width.equalTo(0)
                    make.left.equalToSuperview().offset(0)
                }
                if reschedule.timeAfter != "" {
                    logger.debug("Reschedule Cell => 判断2")
                    pRNewView.isHidden = false
                    pRNewQuestionMarkImageView.isHidden = true
                    // MARK: - TimeAfter 修改过的地方
                    reschedule.getTimeAfterInterval {[weak self] (time) in
                        guard let self = self else{return}
                        let afterDate = Date(seconds: time)
                        self.pRNewTimeLabel.text("\(df.string(from: afterDate))")
                        self.pRNewDayLabel.text("\(afterDate.day)")
                        self.pRNewMonthLabel.text("\(TimeUtil.getMonthShortName(month: afterDate.month))")
                    }
                }
                if reschedule.retracted {
                    text = "\(studentName) retraced the reschedule request"
                } else {
                    if reschedule.confirmType == .confirmed {
                        text = "\(studentName) confirmed the reschedule request"
                    } else if reschedule.confirmType == .refuse {
                        text = "\(studentName) declined the reschedule request"
                    }
                }

                pRStatusLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: studentName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
                height = 152
            } else {
                logger.debug("Reschedule Cell => 判断3")
                pRNewView.isHidden = true
                pRNewQuestionMarkImageView.isHidden = false
                pendingWidth = 70
                pRPendingLabel.snp.updateConstraints { make in
                    make.width.equalTo(70)
                    make.left.equalToSuperview().offset(0)
                }
                pRPendingBackButton.isHidden = false
                pRPendingLabel.text("Pending: ")
                text = "Awaiting reschedule confirmation from"
                if studentName == "" {
                    text = "Awaiting reschedule confirmation"
                } else {
                    text = "\(text) \(studentName)"
                }
                pRStatusLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: studentName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
                height = 152
                if reschedule.timeAfter != "" {
                    logger.debug("Reschedule Cell => 判断4")
                    pRNewView.isHidden = false
                    pRNewQuestionMarkImageView.isHidden = true
                    // MARK: - TimeAfter 修改过的地方
                    reschedule.getTimeAfterInterval {[weak self] (time) in
                        guard let self = self else{return}
                        let afterDate = Date(seconds: time)
                        self.pRNewTimeLabel.text("\(df.string(from: afterDate))")
                        self.pRNewDayLabel.text("\(afterDate.day)")
                        self.pRNewMonthLabel.text("\(TimeUtil.getMonthShortName(month: afterDate.month))")
                    }
                    if reschedule.studentRevisedReschedule {
                        // 显示按钮
                        logger.debug("Reschedule Cell => 判断5")
                        text = "\(studentName) sent a reschedule request"
                        pRStatusLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: studentName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
                        pendingWidth = 0
                        pRPendingLabel.text("")
                        pRPendingLabel.snp.updateConstraints { make in
                            make.width.equalTo(0)
                            make.left.equalToSuperview().offset(0)
                        }
                        confirmButton.isHidden = false
                        rescheduleButton.isHidden = false
                    }
                    if reschedule.senderId == UserService.user.id()! {
                        pRPendingBackButton.isHidden = false
                        pRPendingBackButton.snp.remakeConstraints { make in
                            if rescheduleButton.isHidden {
                                make.centerX.equalToSuperview()
                            } else {
                                make.right.equalTo(rescheduleButton.snp.left).offset(-20)
                            }
                            make.bottom.equalTo(-10)
                            make.height.equalTo(28)
                        }
                    } else {
                        pRPendingBackButton.isHidden = true
                    }
                    height = 162
                }
            }
        } else {
            logger.debug("Reschedule Cell => 判断6")
            pRPendingLabel.snp.updateConstraints { make in
                make.width.equalTo(0)
                make.left.equalToSuperview().offset(0)
            }
            pRNewView.isHidden = false

            pRNewQuestionMarkImageView.isHidden = true

            if reschedule.teacherRevisedReschedule {
                logger.debug("Reschedule Cell => 判断7")
                text = "Awaiting reschedule confirmation from"
                if studentName == "" {
                    text = "Awaiting reschedule confirmation"
                } else {
                    text = "\(text) \(studentName)"
                }
                pendingWidth = 70
                pRPendingLabel.snp.updateConstraints { make in
                    make.width.equalTo(70)
                    make.left.equalToSuperview().offset(0)
                }
                pRPendingLabel.text("Pending: ")

                if reschedule.senderId == UserService.user.id()! {
                    pRPendingBackButton.isHidden = false
                    pRPendingBackButton.snp.remakeConstraints { make in
                        make.right.equalTo(rescheduleButton.snp.left).offset(-20)
                        make.bottom.equalTo(-10)
                        make.height.equalTo(28)
                    }
                } else {
                    pRPendingBackButton.isHidden = true
                }
            } else {
                logger.debug("Reschedule Cell => 判断8")
                rejectButton.isHidden = false
                confirmButton.isHidden = false
                rescheduleButton.isHidden = false
                height = 162
                pRPendingLabel.snp.updateConstraints { make in
                    make.width.equalTo(0)
                    make.left.equalToSuperview().offset(0)
                }
                pRPendingLabel.text("")
            }
            if reschedule.timeAfter != "" {
                logger.debug("Reschedule Cell => 判断9")
                reschedule.getTimeAfterInterval { (time) in
                    let afterDate = Date(seconds: time)
                    self.pRNewTimeLabel.text("\(df.string(from: afterDate))")
                    self.pRNewDayLabel.text("\(afterDate.day)")
                    self.pRNewMonthLabel.text("\(TimeUtil.getMonthShortName(month: afterDate.month))")
                }
            } else {
                logger.debug("Reschedule Cell => 判断10")
                if reschedule.studentData != nil {
                    text = "\(studentName) sent a reschedule request"
                } else {
                    text = "\(text)"
                }
                pRPendingLabel.snp.updateConstraints { make in
                    make.width.equalTo(0)
                    make.left.equalToSuperview().offset(0)
                }
                pRNewView.isHidden = false

                pRNewQuestionMarkImageView.isHidden = false
                pRNewView.isHidden = true
                if !reschedule.teacherRevisedReschedule {
                    logger.debug("Reschedule Cell => 判断11")
                    confirmButton.isHidden = true
                    confirmButton.snp.updateConstraints { make in
                        make.width.equalTo(0)
//                        make.width.equalTo(62)
                    }
                    rescheduleButton.snp.updateConstraints { make in
                        make.right.equalTo(confirmButton.snp.left).offset(0)
                    }
                }
            }

            pRStatusLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: studentName, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.main, font: FontUtil.bold(size: 15), fontSize: 15)
        }
        var labelHeight: CGFloat = 20
        if pRStatusLabel.attributedText != nil {
            labelHeight = pRStatusLabel.attributedText!.string.getLableHeigh(font: FontUtil.bold(size: 15), width: UIScreen.main.bounds.width - 40 - 40 - pendingWidth)
        }

        pRView.snp.updateConstraints { make in
            make.height.equalTo(height + labelHeight)
        }
        logger.debug("cell高度:\(height + labelHeight)")
    }

    func showBorder() {
//        pRView.layer.borderWidth = 1
//        pRView.layer.borderColor = UIColor.clear.cgColor

        let boxView = TKView.create()
            .backgroundColor(color: .clear)
            .showBorder(color: ColorUtil.red)
            .addTo(superView: pRView) { make in
                make.center.size.equalToSuperview()
            }

        boxView.layer.opacity = 0

        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
            boxView.layer.opacity = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
                    boxView.layer.opacity = 0
                }, completion: { _ in
                    boxView.removeFromSuperview()
                })
            }
        }
    }
}

extension UndoneRescheduleCell {
    private func showEmailAndPhone() {
        guard let topController = Tools.getTopViewController(), let studentData = data?.studentData else { return }

        var items: [TKPopAction.Item] = []
        if studentData.email != "" {
            items.append(TKPopAction.Item(title: studentData.email) { [weak self] in
                self?.sendEmail(email: studentData.email)
            })
        }

        if studentData.phone != "" {
            items.append(TKPopAction.Item(title: studentData.phone) {
                let phone = "telprompt://\(studentData.phone)"
                if let url = URL(string: phone) {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            })
        }

        TKPopAction.show(items: items, isCancelShow: true, target: topController)
    }
}

extension UndoneRescheduleCell: MFMailComposeViewControllerDelegate {
    func sendEmail(email: String) {
        // 0.首先判断设备是否能发送邮件
        if MFMailComposeViewController.canSendMail() {
            // 1.配置邮件窗口
            let mailView = configuredMailComposeViewController(email: email)
            // 2. 显示邮件窗口
            Tools.getTopViewController()?.present(mailView, animated: true, completion: nil)
        } else {
            print("Whoop...设备不能发送邮件")
            showSendMailErrorAlert()
        }
    }

    // 提示框，提示用户设置邮箱
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Mail is not turned on", message: TipMsg.accessForEmailApp, preferredStyle: .alert)
        sendMailErrorAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
        Tools.getTopViewController()?.present(sendMailErrorAlert, animated: true) {}
    }

    // MARK: - helper methods

    // 配置邮件窗口
    func configuredMailComposeViewController(email: String) -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self

        // 设置邮件地址、主题及正文
        mailComposeVC.setToRecipients([email])
        mailComposeVC.setSubject("")
        mailComposeVC.setMessageBody("", isHTML: false)

        return mailComposeVC
    }

    // MARK: - Mail Delegate

    // 用户退出邮件窗口时被调用
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result.rawValue {
        case MFMailComposeResult.sent.rawValue:
            print("邮件已发送")
        case MFMailComposeResult.cancelled.rawValue:
            print("邮件已取消")
        case MFMailComposeResult.saved.rawValue:
            print("邮件已保存")
        case MFMailComposeResult.failed.rawValue:
            print("邮件发送失败")
        default:
            print("邮件没有发送")
            break
        }
        controller.dismiss(animated: true, completion: nil)
    }
}
