//
//  ProfileSettingsTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/5.
//  Copyright © 2019年 spelist. All rights reserved.
//
import SnapKit
import UIKit

class ProfileSettingsTableViewCell: UITableViewCell, TKSwitchDelegate {
    weak var delegate: ProfileSettingsTableViewCellDelegate?

    private var backView: TKView!
    private var titleLabel: TKLabel!

    private var changePasswordView: TKView!
    private var enableScreenLockView: TKView!
    private var enableScreenLockSwitchView: TKSwitch!
    private var mergeAccountView: TKView!
    private var aboutUsView: TKView!
    private var calendarView: TKView!
    
    @Live var isUnpaidHidden: Bool = true
    lazy var paymentView: ViewBox = {
        ViewBox(paddings: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)) {
            VStack {
                ViewBox(paddings: UIEdgeInsets(top: 16, left: 20, bottom: 15, right: 20)) {
                    HStack(alignment: .center, spacing: 20) {
                        ImageView(image: UIImage(named: "billing")?.resizeImage(CGSize(width: 17, height: 22))).contentMode(.center).size(width: 22, height: 22)
                        Label("Payment").textColor(ColorUtil.Font.third).font(.bold(18))
                        HStack(alignment: .center) {
                            Label("Unpaid").textColor(ColorUtil.red).font(.regular(size: 13)).height(22).isHidden($isUnpaidHidden)
                            ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                        }
                    }
                }
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)) {
                    Divider(weight: 1, color: ColorUtil.dividingLine)
                }.height(1)
            }
        }
    }()
    

    private var contactUsView: TKView!
    var shakeToReportView: TKView = TKView()
    private var shakeToReportUnreadView: TKImageView = TKImageView.create()
        .setImage(color: ColorUtil.red)

    private var reportSwitchView: TKSwitch = TKSwitch()
    var reportInfoLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.Font.primary)
        .text(text: "")

    private var faqView: TKView = TKView.create()

    private var key: String = ""

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileSettingsTableViewCell {
    private func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
        contentView.addSubview(view: backView) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20).priority(.medium)
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Settings")
        backView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(20)
            make.height.equalTo(16)
        }

        initChangedPassword()
        initMergeAccount()
//        paymentView.addTo(superView: backView) { make in
//            make.top.equalTo(mergeAccountView.snp.bottom)
//            make.left.right.equalToSuperview()
//        }
        initCalendarConnection()
        initAboutUs()
        initFAQView()
        initContactUs()
        initShakeReport()
        
    }

    private func initFAQView() {
        faqView.addTo(superView: backView) { make in
            make.top.equalTo(aboutUsView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
        }
        faqView.onViewTapped { [weak self] _ in
            self?.delegate?.profileSettingsTableViewCellFAQTapped()
        }
        initItemView(mainView: faqView, imageName: "faq", text: "FAQ", bottomLineShow: true)
    }

    private func initContactUs() {
        contactUsView = TKView.create()
        backView.addSubview(view: contactUsView) { make in
            make.top.equalTo(faqView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
        }
        contactUsView.onViewTapped { [weak self] _ in
            self?.delegate?.profileSettingsTableViewCellContactUsTapped()
        }
        initItemView(mainView: contactUsView, imageName: "icMessage", text: "Contact Us", bottomLineShow: true)
    }

    private func initShakeReport() {
        backView.addSubview(view: shakeToReportView) { make in
            make.top.equalTo(contactUsView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(90)
            make.bottom.equalToSuperview().offset(-20).priority(.medium)
        }

        let imageView = TKImageView.create()
            .setImage(name: "icChangeShake")
        shakeToReportView.addSubview(view: imageView) { make in
            make.top.equalTo(16)
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }
        reportSwitchView.isHidden = true
        shakeToReportView.addSubview(view: reportSwitchView) { make in
            make.centerY.equalTo(imageView)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(22)
            make.width.equalTo(55)
        }
        reportSwitchView.isOn = false
        reportSwitchView.delegate = self
        reportInfoLabel.numberOfLines = 0
        reportInfoLabel.font(FontUtil.regular(size: 13))
        reportInfoLabel.textColor(color: ColorUtil.Font.primary)
        let label = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .setNumberOfLines(number: 0)
        label.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        if UIScreen.isSmallerScreen {
            label.text("Report\na Bug")
        } else {
            label.text("Report a Bug")
        }
        shakeToReportView.addSubview(view: label) { make in
            make.centerY.equalTo(imageView)
            make.left.equalTo(imageView.snp.right).offset(20)
        }
        reportInfoLabel.text = "Send us feedback. We will update promptly."

        shakeToReportView.addSubview(view: reportInfoLabel) { make in
            make.left.equalTo(imageView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(imageView.snp.bottom).offset(11)
        }
        let rightImageView = TKImageView.create()
            .setImage(name: "arrowRight")
        shakeToReportView.addSubview(view: rightImageView) { make in
            make.centerY.equalTo(label.snp.centerY)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }
    }

    private func initChangedPassword() {
        changePasswordView = TKView.create()
            .backgroundColor(color: UIColor.white)
        backView.addSubview(view: changePasswordView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
        }
        changePasswordView.onViewTapped { [weak self] _ in
            self?.delegate?.profileSettingsTableViewCellChangePasswordTapped()
        }
        initItemView(mainView: changePasswordView, imageName: "icChangePassword", text: "Password", bottomLineShow: true)
    }

    private func initEnableScreenLock() {
        enableScreenLockView = TKView.create()
        backView.addSubview(view: enableScreenLockView) { make in
            make.top.equalTo(changePasswordView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        enableScreenLockView.layer.masksToBounds = true
        initItemView(mainView: enableScreenLockView, imageName: "icScreenLock", text: "Enable Screen Lock", bottomLineShow: true, rightSwich: true)
        enableScreenLockSwitchView.onValueChanged { [weak self] isOn in
            self?.delegate?.profileSettingsTableViewCell(enableScreenLockChanged: isOn)
        }
    }

    private func initMergeAccount() {
        mergeAccountView = TKView.create()
            .addTo(superView: backView, withConstraints: { make in
//                make.top.equalTo(enableScreenLockView.snp.bottom)
                make.top.equalTo(changePasswordView.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(54)
            })
        mergeAccountView.layer.masksToBounds = true

        mergeAccountView.onViewTapped { [weak self] _ in
            self?.delegate?.profileSettingsTableViewCellMergeAccountTapped()
        }
        initItemView(mainView: mergeAccountView, imageName: "profile", text: "Sign-in Options", bottomLineShow: true)
    }

    private func initCalendarConnection() {
        calendarView = TKView.create()
        backView.addSubview(view: calendarView) { make in
//            make.top.equalTo(mergeAccountView.snp.bottom)
            make.top.equalTo(mergeAccountView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
//            make.height.equalTo(0)
        }
        calendarView.layer.masksToBounds = true

        calendarView.onViewTapped { [weak self] _ in
            self?.delegate?.profileSettingsTableViewCellCalendarTapped()
        }
        initItemView(mainView: calendarView, imageName: "icCalendar", text: "Calendar Setting", bottomLineShow: true)
    }

    private func initAboutUs() {
        aboutUsView = TKView.create()
        backView.addSubview(view: aboutUsView) { make in
            make.top.equalTo(calendarView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
        }
        aboutUsView.onViewTapped { [weak self] _ in
            self?.delegate?.profileSettingsTableViewCellAboutUsTapped()
        }
        initItemView(mainView: aboutUsView, imageName: "icTerms", text: "Terms & Privacy", bottomLineShow: true)
    }

    private func initItemView(mainView: TKView, imageName: String, text: String, bottomLineShow: Bool, rightSwich: Bool = false) {
        let imageView = TKImageView.create()
            .setImage(name: imageName)
        mainView.addSubview(view: imageView) { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(22)
        }

        let label = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: text)
        label.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        mainView.addSubview(view: label) { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(imageView.snp.right).offset(20)
        }
        if rightSwich {
            let rightSwitchView = TKSwitch()
            mainView.addSubview(view: rightSwitchView) { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-10)
                make.size.equalTo(rightSwitchView.size)
            }
            rightSwitchView.isOn = false
            enableScreenLockSwitchView = rightSwitchView
        } else {
            let rightImageView = TKImageView.create()
                .setImage(name: "arrowRight")
            mainView.addSubview(view: rightImageView) { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(22)
            }
        }
        if bottomLineShow {
            let lineView = TKView.create()
                .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            mainView.addSubview(view: lineView) { make in
                make.left.equalToSuperview().offset(20)
                make.right.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
        }
    }

    func loadData(data: TKUser?) {
        if let data = data {
//            if !data.loginMethod.contains("1") {
//                mergeAccountView.snp.updateConstraints { make in
//                    make.height.equalTo(0)
//                }
//                titleLabel.snp.updateConstraints { (make) in
//                    make.bottom.equalToSuperview().offset(-172)
//                }
//            }
            if data.roleIds.contains("2") {
                calendarView.snp.updateConstraints { make in
                    make.height.equalTo(0)
                }
//                mergeAccountView.snp.updateConstraints { make in
//                    make.height.equalTo(0)
//                }
            }
        }
        if let userId = UserService.user.id() {
            let isEnable = SLCache.main.getBool(key: "\(userId):\(SLCache.IS_ENABLE_SHAKE_REPORT)")
            reportSwitchView.isOn = isEnable
        }
    }

    func tkSwitch(_ tkSwitch: TKSwitch, onValueChanged isOn: Bool) {
        if let userId = UserService.user.id() {
            SLCache.main.set(key: "\(userId):\(SLCache.IS_ENABLE_SHAKE_REPORT)", value: isOn)
        }
    }

    func showUnreadView(show: Bool) {
//        let attributedString = NSMutableAttributedString(string: "Shake to send us feedback. We will update promptly. SEE PROGRESS", attributes: [
//            .font: FontUtil.regular(size: 13),
//            .foregroundColor: ColorUtil.Font.primary,
//            .kern: 0.4,
//        ])
//        attributedString.addAttributes([
//            .font: FontUtil.bold(size: 13),
//            .foregroundColor: ColorUtil.main,
//        ], range: NSRange(location: 52, length: 12))
//        if show {
//            let textAttachment: NSTextAttachment = NSTextAttachment()
//            textAttachment.image = UIImage(named: "unreadImage")
//            textAttachment.bounds = CGRect(x: 0, y: 7, width: 6, height: 6)
//            attributedString.append(NSAttributedString(attachment: textAttachment))
//        }
//        reportInfoLabel.attributedText = attributedString
    }
}

protocol ProfileSettingsTableViewCellDelegate: NSObjectProtocol {
    func profileSettingsTableViewCell(enableScreenLockChanged isOn: Bool)
    func profileSettingsTableViewCellChangePasswordTapped()
    func profileSettingsTableViewCellMergeAccountTapped()
    func profileSettingsTableViewCellAboutUsTapped()
    func profileSettingsTableViewCellCalendarTapped()
    func profileSettingsTableViewCellContactUsTapped()
    func profileSettingsTableViewCellFAQTapped()
}
