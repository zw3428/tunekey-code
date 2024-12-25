//
//  SProfileUserInfoCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/19.
//  Copyright © 2019年 spelist. All rights reserved.
//

import SnapKit
import UIKit

class SProfileUserInfoCell: UITableViewCell {
    private var mainView: TKView!
    private var userAvatarView: TKAvatarView!
    private var userInfoView: TKView!
    private var userNameLabel: TKLabel!
    private var userPhoneLabel: TKLabel!
    private var userEmailLabel: TKLabel!
    weak var delegate: SProfileUserInfoCellDelegate?

    private var data: TKUser?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SProfileUserInfoCell {
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
            make.height.greaterThanOrEqualTo(100)
        }

        userAvatarView = TKAvatarView(frame: CGRect.zero)
        userAvatarView.layer.cornerRadius = 30
        userAvatarView.clipsToBounds = true
        mainView.addSubview(view: userAvatarView) { make in
            make.size.equalTo(60)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
        }
        let arrowView = UIImageView()
        arrowView.image = UIImage(named: "arrowRight")
        mainView.addSubview(view: arrowView) { make in
            make.size.equalTo(22)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
        userInfoView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: mainView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(userAvatarView.snp.right).offset(20)
                make.right.equalTo(arrowView.snp.left).offset(-10)
                make.bottom.equalToSuperview().offset(-20)
            })
        userNameLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: userInfoView, withConstraints: { make in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(23)
            })
        userPhoneLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .addTo(superView: userInfoView, withConstraints: { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(userNameLabel.snp.bottom).offset(4)
            })
        userEmailLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .addTo(superView: userInfoView, withConstraints: { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(userPhoneLabel.snp.bottom).offset(2)
                make.bottom.equalToSuperview().priority(.medium)
            })
        mainView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.profileUserInfoCell(clickCell: self)
        }
    }

    func initData(data: TKUser?, unpaidInvoices: [TKInvoice]) {
        guard let data = data else { return }
        self.data = data
        if unpaidInvoices.isEmpty {
            userNameLabel.text("\(data.name)")
            userPhoneLabel.text("\(data.phone)")
            userEmailLabel.text(text: "\(data.email)")
                .textColor(color: ColorUtil.Font.primary)
                .setNumberOfLines(number: 1)
        } else {
            userNameLabel.text("\(data.name)")
            userPhoneLabel.text("\(data.email)")
            userEmailLabel.text(text: unpaidInvoices.compactMap({ "$\($0.totalAmount) due \(Date(seconds: $0.billingTimestamp + (TimeInterval($0.quickInvoiceDueDate) * 86400)).toLocalFormat("MM/dd/yyyy"))" }).joined(separator: ", "))
                .textColor(color: ColorUtil.red)
                .setNumberOfLines(number: 0)
        }
        loadAvatar()
    }

    func loadAvatar() {
        guard let data = data else { return }
        logger.debug("加载头像: \(data.userId)")
        userAvatarView.loadImage(userId: data.userId, name: data.name, refreshCached: true)
    }
}

protocol SProfileUserInfoCellDelegate: AnyObject {
    func profileUserInfoCell(clickCell cell: SProfileUserInfoCell)
}
