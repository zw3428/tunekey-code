//
//  ProfileReferralProgramTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2021/4/21.
//  Copyright © 2021 spelist. All rights reserved.
//

import UIKit

protocol ProfileReferralProgramTableViewCellDelegate: AnyObject {
    func profileReferralProgramTableViewCell(didTapped cell: ProfileReferralProgramTableViewCell)
}

class ProfileReferralProgramTableViewCell: UITableViewCell {
    weak var delegate: ProfileReferralProgramTableViewCellDelegate?

    var users: [TKReferralUserRecord] = []

    private let messageWithoutRedeemUsers: String = "Refer and get PRO for up to \(ReferralCodeConfig.limitOfMonthOfReferralUser)-month-free"
    private var message: String = "Got PRO for \(ReferralCodeConfig.numberOfMonthOfReferralUser)-month-free\n# redeemed"

    private lazy var containerView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 5)
        .showShadow()
        .showBorder(color: ColorUtil.borderColor)

    private lazy var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 18))
        .textColor(color: ColorUtil.Font.third)
        .text(text: "Referral Program")

    private lazy var referralButton: TKButton = TKButton.create()
        .backgroundColor(color: UIColor(r: 151, g: 189, b: 221))
        .title(title: "REFER A FRIEND")
        .titleFont(font: FontUtil.medium(size: 8.2))
        .titleColor(color: .white)
        .setShadow(shadowColor: UIColor(r: 151, g: 189, b: 221))

    private lazy var messageLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.Font.primary)
        .text(text: messageWithoutRedeemUsers)
        .setNumberOfLines(number: 2)

    private lazy var arrowImageView: TKImageView = TKImageView.create()
        .setImage(name: "arrowRight")

    private lazy var userAvatar1: TKAvatarView = TKAvatarView(frame: .zero)
    private lazy var userAvatar2: TKAvatarView = TKAvatarView(frame: .zero)
    private lazy var userAvatar3: TKAvatarView = TKAvatarView(frame: .zero)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
        bindEvents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileReferralProgramTableViewCell {
    private func initView() {
        containerView.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-5)
        }

        titleLabel.addTo(superView: containerView) { make in
            make.top.left.equalToSuperview().offset(20)
            make.height.equalTo(20)
        }
        referralButton.layer.cornerRadius = 3
        referralButton.addTo(superView: containerView) { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(88)
            make.height.equalTo(24)
        }
        messageLabel.changeLabelRowSpace(lineSpace: 4, wordSpace: 0)
        messageLabel.addTo(superView: containerView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(15)
            make.bottom.equalToSuperview().offset(-20).priority(.medium)
        }

        arrowImageView.addTo(superView: containerView) { make in
            make.bottom.equalTo(messageLabel.snp.bottom).offset(10)
            make.size.equalTo(22)
            make.right.equalToSuperview().offset(-20)
        }

        userAvatar3.addTo(superView: containerView) { make in
            make.centerY.equalTo(arrowImageView.snp.centerY)
            make.size.equalTo(20)
            make.right.equalTo(arrowImageView.snp.left)
        }

        userAvatar2.addTo(superView: containerView) { make in
            make.centerY.equalTo(userAvatar3)
            make.size.equalTo(userAvatar3)
            make.right.equalTo(userAvatar3.snp.left).offset(10)
        }

        userAvatar1.addTo(superView: containerView) { make in
            make.centerY.equalTo(userAvatar2)
            make.size.equalTo(userAvatar2)
            make.right.equalTo(userAvatar2.snp.left).offset(10)
        }

        containerView.sendSubviewToBack(userAvatar2)
        containerView.sendSubviewToBack(userAvatar3)

        userAvatar1.cornerRadius = 10
        userAvatar2.cornerRadius = 10
        userAvatar3.cornerRadius = 10

        userAvatar1.isHidden = true
        userAvatar2.isHidden = true
        userAvatar3.isHidden = true
        arrowImageView.isHidden = true
    }
}

extension ProfileReferralProgramTableViewCell {
    private func bindEvents() {
        referralButton.onTapped { [weak self] _ in
            self?.onReferralButtonTapped()
        }
        containerView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            guard self.users.count > 0 else { return }
            self.delegate?.profileReferralProgramTableViewCell(didTapped: self)
        }
    }

    private func onReferralButtonTapped() {
        TKTeacherReferral.show()
    }
}

extension ProfileReferralProgramTableViewCell {
    func loadData(users: [TKReferralUserRecord]) {
        self.users = users
        message = "Got PRO for \(ReferralCodeConfig.numberOfMonthOfReferralUser)-month-free\n\(users.count) redeemed"
        if users.count > 0 {
            arrowImageView.isHidden = false
            if users.count >= 1 {
                userAvatar3.isHidden = false
                userAvatar3.loadImage(userId: users[0].userId, name: users[0].userName)
            }
            if users.count >= 2 {
                userAvatar2.isHidden = false
                userAvatar2.loadImage(userId: users[1].userId, name: users[1].userName)
            }
            if users.count >= 3 {
                userAvatar1.isHidden = false
                userAvatar1.loadImage(userId: users[2].userId, name: users[2].userName)
            }
            messageLabel.numberOfLines = 2
            messageLabel.text(message)
            messageLabel.snp.updateConstraints { make in
                make.height.equalTo(44)
            }
            arrowImageView.snp.remakeConstraints { make in
                make.centerY.equalTo(messageLabel.snp.centerY).offset(10)
                make.size.equalTo(22)
                make.right.equalToSuperview().offset(-20)
            }
        } else {
            userAvatar1.isHidden = true
            userAvatar2.isHidden = true
            userAvatar3.isHidden = true
            arrowImageView.isHidden = true
            messageLabel.numberOfLines = 1
            messageLabel.text(messageWithoutRedeemUsers)
            messageLabel.snp.updateConstraints { make in
                make.height.equalTo(15)
            }
            arrowImageView.snp.remakeConstraints { make in
                make.top.equalTo(referralButton.snp.bottom).offset(10)
                make.size.equalTo(22)
                make.right.equalToSuperview().offset(-20)
            }
        }
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
    }
}
