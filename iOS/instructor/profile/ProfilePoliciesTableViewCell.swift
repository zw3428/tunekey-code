//
//  ProfilePoliciesTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/5.
//  Copyright © 2019年 spelist. All rights reserved.
//

import SnapKit
import UIKit

class ProfilePoliciesTableViewCell: UITableViewCell {
    weak var delegate: ProfilePoliciesTableViewCellDelegate?

    private var backView: TKView!
    private var titleLabel: TKLabel!

    private var makeupView: TKView!
    private var makeupDetailLabel: TKLabel!

    private var cancellationView: TKView!
    private var cancellationDetailLabel: TKLabel!

    private var availabilityView: TKView!
    private var availabilityDetailLabel: TKLabel!
    private var messageView: TKView!
    private var descriptionLabel: TKLabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfilePoliciesTableViewCell {
    private func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
        contentView.addSubview(view: backView) { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10)
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Policies")
        backView.addSubview(view: titleLabel) { make in
            make.left.top.equalToSuperview().offset(20)
            make.height.equalTo(16)
//            make.bottom.equalToSuperview().offset(-263)
        }

        let descriptionView = TKView.create()
            .addTo(superView: backView) { make in
                make.top.equalTo(titleLabel.snp.top)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(22)
                make.width.equalTo(100)
            }
        descriptionView.onViewTapped { [weak self] _ in
            self?.delegate?.profilePoliciesTableViewCellDescriptionPolicyTapped()
        }
        let descriptionRightImageView = TKImageView.create()
            .setImage(name: "arrowRight")
            .addTo(superView: descriptionView) { make in
                make.top.equalToSuperview()
                make.size.equalTo(22)
                make.right.equalToSuperview()
            }
        descriptionLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 12))
            .textColor(color: ColorUtil.main)
            .text(text: "STATEMENT")
            .addTo(superView: descriptionView, withConstraints: { make in
                make.centerY.equalTo(descriptionRightImageView)
                make.left.equalToSuperview()
                make.width.equalTo(70)
            })
        messageView = TKView()
            .backgroundColor(color: ColorUtil.red)
            .corner(size: 3)
            .addTo(superView: descriptionView, withConstraints: { (make) in
                make.size.equalTo(6)
                make.top.equalTo(descriptionLabel.snp.top).offset(-1)
                make.left.equalTo(descriptionLabel.snp.right)
            })
        messageView.isHidden = true
        cancellationView = TKView.create()
            .backgroundColor(color: UIColor.white)
        backView.addSubview(view: cancellationView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(83)
        }
        cancellationView.onViewTapped { [weak self] _ in
            self?.delegate?.profilePoliciesTableViewCellCancellationPolicyTapped()
        }

        let cancellationTitleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Cancellation policies")
        cancellationView.addSubview(view: cancellationTitleLabel) { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(20)
        }

        cancellationDetailLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Needs configuration")
        cancellationDetailLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.5)
        cancellationDetailLabel.lineBreakMode = .byTruncatingTail

        cancellationView.addSubview(view: cancellationDetailLabel) { make in
            make.top.equalTo(cancellationTitleLabel.snp.bottom).offset(7)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-40)
        }

        let cancellationRightImageView = TKImageView.create()
            .setImage(name: "arrowRight")
        cancellationView.addSubview(view: cancellationRightImageView) { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }

        let lineView1 = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
        cancellationView.addSubview(view: lineView1) { make in
            make.left.equalToSuperview().offset(20)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        makeupView = TKView.create()
            .backgroundColor(color: UIColor.white)
        backView.addSubview(view: makeupView) { make in
            make.top.equalTo(cancellationView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(83)
        }
        makeupView.onViewTapped { [weak self] _ in
            self?.delegate?.profilePoliciesTableViewCellMakeupPolicyTapped()
        }

        let makeupTitleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Reschedule policies")
        makeupView.addSubview(view: makeupTitleLabel) { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(20)
        }

        makeupDetailLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Needs configuration")
        makeupDetailLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.5)
        makeupDetailLabel.lineBreakMode = .byTruncatingTail

        makeupView.addSubview(view: makeupDetailLabel) { make in
            make.top.equalTo(makeupTitleLabel.snp.bottom).offset(7)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-40)
        }

        let makeupRightImageView = TKImageView.create()
            .setImage(name: "arrowRight")
        makeupView.addSubview(view: makeupRightImageView) { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }

        let lineView = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
        makeupView.addSubview(view: lineView) { make in
            make.left.equalToSuperview().offset(20)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        availabilityView = TKView.create()
            .backgroundColor(color: UIColor.white)
        backView.addSubview(view: availabilityView) { make in
            make.top.equalTo(makeupView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(83)
            make.bottom.equalToSuperview().priority(.medium)
        }
        availabilityView.onViewTapped { [weak self] _ in
            self?.delegate?.profilePoliciesTableViewCellAvailabilityPolicyTapped()
        }

        let availabilityTitleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Make-up availability")
        availabilityView.addSubview(view: availabilityTitleLabel) { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(20)
        }

        availabilityDetailLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Needs configuration")
        availabilityDetailLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.5)
        availabilityDetailLabel.lineBreakMode = .byTruncatingTail

        availabilityView.addSubview(view: availabilityDetailLabel) { make in
            make.top.equalTo(availabilityTitleLabel.snp.bottom).offset(7)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-40)
        }

        let availabilityRightImageView = TKImageView.create()
            .setImage(name: "arrowRight")
        availabilityView.addSubview(view: availabilityRightImageView) { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }
    }
}

extension ProfilePoliciesTableViewCell {
    func initData(data: TKPolicies) {
        var makeupString = ""
        var cancellationString = ""
        var availabilityString = ""
        messageView.isHidden = true
        if data.unReleaseDescriptionTime != 0 {
            if !data.readeUnReleaseDescription {
                messageView.isHidden = false
            }
        }
        if data.setLater {
            makeupString = "Needs configuration"
            cancellationString = "Needs configuration"
            availabilityString = "Needs configuration"
        } else {
            availabilityView.snp.updateConstraints { make in
                make.height.equalTo(data.allowReschedule ? 83 : 0)
            }
            availabilityView.isHidden = !data.allowReschedule
            if data.allowReschedule {
                if data.rescheduleNoticeRequired != 0 {
                    makeupString = "\(data.rescheduleNoticeRequired) hrs notice"
                }
                if data.rescheduleLimitTimes {
                    if makeupString == "" {
                        makeupString += "\(makeupString)\(data.rescheduleLimitTimesAmount) times within \(data.rescheduleLimitTimesPeriod) months"
                    }else{
                        makeupString += ", \(data.rescheduleLimitTimesAmount) times within \(data.rescheduleLimitTimesPeriod) months"
                    }
                }
                if makeupString == "" {
                    makeupString = "Allow reschedule"
                }
            } else {
                makeupString = "Not allow reschedule"
            }
            if data.allowRefund {
                if data.refundNoticeRequired != 0 {
                    var string = ""
                    if data.refundNoticeRequired >= 24 {
                        let day = data.refundNoticeRequired / 24
                        string = "\(day) \(day > 1 ? "days" : "day")"
                    } else {
                        string = "\(data.refundNoticeRequired) hrs"
                    }
                    cancellationString = "\(string) notice"
                }
                if data.refundLimitTimes {
                    if cancellationString == "" {
                        cancellationString += "\(cancellationString)\(data.refundLimitTimesAmount) times within \(data.refundLimitTimesPeriod) months"
                    } else {
                        cancellationString += ", \(data.refundLimitTimesAmount) times within \(data.refundLimitTimesPeriod) months"
                    }
                }
                if cancellationString == "" {
                    cancellationString = "Allow cancellation"
                }
            } else {
                cancellationString = "Needs configuration"
            }
//            if  data.
            availabilityString = data.availabilityToString()
        }

        makeupDetailLabel.text(makeupString)
        cancellationDetailLabel.text(cancellationString)
        availabilityDetailLabel.text(availabilityString)
    }
}

protocol ProfilePoliciesTableViewCellDelegate: NSObjectProtocol {
    func profilePoliciesTableViewCellMakeupPolicyTapped()
    func profilePoliciesTableViewCellCancellationPolicyTapped()
    func profilePoliciesTableViewCellAvailabilityPolicyTapped()
    func profilePoliciesTableViewCellDescriptionPolicyTapped()
}
