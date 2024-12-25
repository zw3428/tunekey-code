//
//  ProfileShakeToReportTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2020/9/8.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class ProfileShakeToReportTableViewCell: UITableViewCell, TKSwitchDelegate {
    private var boxView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 5)
        .showBorder(color: ColorUtil.borderColor)
        .showShadow()

    private var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 18))
        .textColor(color: ColorUtil.Font.third)
        .text(text: "Shake to report")

    private var switchView: TKSwitch = TKSwitch()

    var infoLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.Font.primary)
        .text(text: "")
    var unreadView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.red)
        .corner(size: 3)
    private var key: String = ""

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileShakeToReportTableViewCell {
    private func initView() {
        backgroundColor = ColorUtil.backgroundColor
        addSubview(view: boxView) { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(54)
        }
        addSubview(view: infoLabel) { make in
            make.left.equalToSuperview().offset(40)
            make.top.equalTo(boxView.snp.bottom).offset(10)
            make.right.equalToSuperview().offset(-40)
            make.bottom.equalToSuperview().offset(-10)
        }
        let attributedString = NSMutableAttributedString(string: "Shake to send us feedback. We will update promptly. SEE PROGRESS", attributes: [
            .font: FontUtil.regular(size: 13),
            .foregroundColor: ColorUtil.Font.primary,
            .kern: 0.4,
        ])
        attributedString.addAttributes([
            .font: FontUtil.bold(size: 13),
            .foregroundColor: ColorUtil.main,
        ], range: NSRange(location: 48, length: 12))

        infoLabel.attributedText = attributedString
        infoLabel.numberOfLines = 0

        boxView.addSubview(view: titleLabel) { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        boxView.addSubview(view: switchView) { make in
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
            make.width.equalTo(55)
        }
        switchView.delegate = self

        addSubview(view: unreadView) { make in
            make.bottom.equalTo(infoLabel.snp.bottom).offset(-4)
            make.size.equalTo(6)
            make.left.equalTo(infoLabel.snp.right).offset(2)
        }
    }

    func tkSwitch(_ tkSwitch: TKSwitch, onValueChanged isOn: Bool) {
        if let userId = UserService.user.id() {
            SLCache.main.set(key: "\(userId):\(SLCache.IS_ENABLE_SHAKE_REPORT)", value: isOn)
        }
    }

    func initData() {
        if let userId = UserService.user.id() {
            let isEnable = SLCache.main.getBool(key: "\(userId):\(SLCache.IS_ENABLE_SHAKE_REPORT)")
            switchView.isOn = isEnable
        }
    }
}
