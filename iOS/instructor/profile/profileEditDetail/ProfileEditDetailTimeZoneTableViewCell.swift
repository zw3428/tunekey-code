//
//  ProfileEditDetailTimeZoneTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2023/1/13.
//  Copyright © 2023 spelist. All rights reserved.
//

import AttributedString
import SnapKit
import UIKit

class ProfileEditDetailTimeZoneTableViewCell: UITableViewCell {
    static let id: String = String(describing: ProfileEditDetailTimeZoneTableViewCell.self)

    @Live var cityName: String = ""
    @Live var timeZone: String = ""

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileEditDetailTimeZoneTableViewCell {
    private func initView() {
        ViewBox(paddings: UIEdgeInsets(top: 5, left: 20, bottom: 10, right: 20)) {
            VStack(spacing: 20) {
                ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                    VStack {
                        Label("Timezone").textColor(ColorUtil.Font.primary)
                            .font(FontUtil.regular(size: 13))
                            .size(height: 20)
                        Spacer(spacing: 20)
                        HStack(alignment: .center) {
                            Label($cityName).textColor(ColorUtil.Font.third)
                                .font(FontUtil.bold(size: 18))
                                .size(height: 20)
                                .contentHuggingPriority(.defaultLow, for: .horizontal)
                                .contentCompressionResistancePriority(.defaultLow, for: .horizontal)
                            Label($timeZone).textColor(ColorUtil.Font.primary)
                                .font(FontUtil.regular(size: 13))
                                .size(height: 20)
                                .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                        }
                        Spacer(spacing: 10)
                        Label("Go settings of your device to change the Timezone.").textColor(ColorUtil.Font.primary)
                            .font(FontUtil.regular(size: 13))
                            .numberOfLines(0)
                    }
                }
                .backgroundColor(.white)
                .apply { view in
                    _ = view.showShadow()
                        .borderWidth(1)
                        .borderColor(ColorUtil.borderColor)
                        .backgroundColor(.white)
                        .cornerRadius(5)
                }
                Label().numberOfLines(2)
                    .textAlignment(.center)
                    .apply { label in
                        let toSignInOptions = {
                            let controller = ProfileAccountController()
                            controller.modalPresentationStyle = .fullScreen
                            controller.hero.isEnabled = true
                            controller.enablePanToDismiss()
                            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                            Tools.getTopViewController()?.present(controller, animated: true, completion: nil)
                        }
                        label.attributed.text = ASAttributedString(string: "Change sign-in email?\nGo to \"", .font(FontUtil.regular(size: 13)), .foreground(ColorUtil.Font.primary))
                            + ASAttributedString(string: "Settings > Sign-in options", .font(FontUtil.regular(size: 13)), .foreground(ColorUtil.main), .action(toSignInOptions))
                            + ASAttributedString(string: "\"", .font(FontUtil.regular(size: 13)), .foreground(ColorUtil.Font.primary))
                    }
            }
        }
        .backgroundColor(ColorUtil.backgroundColor)
        .addTo(superView: contentView) { make in
            make.top.left.right.equalToSuperview()
        }
        let tzId = TimeZone.current.identifier
        let hourFromGMT = TimeZone.current.hourFromGMT
        timeZone = "\(TimeUtil.getTimeZone(withId: tzId))(GMT \(hourFromGMT >= 0 ? "+" : "")\(hourFromGMT))"
        cityName = TimeUtil.getCityName(fromTimeZone: tzId)
        logger.debug("当前的TimeZone: \(timeZone) | cityName: \(cityName)")
    }
}
