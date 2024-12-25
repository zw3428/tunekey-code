//
//  ProfileEditDetailContactsTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/9.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileEditDetailContactsTableViewCell: UITableViewCell {
    var cellHeight: CGFloat = 474

    var address: TKPaymentAddress?

    weak var delegate: ProfileEditDetailContactsTableViewCellDelegate?

    private var backView: TKView!
    private var titleLabel: TKLabel!
    private var fullNameInputBox: TKTextBox!
    private var emailInputBox: TKTextBox!
    private var phoneInputBox: TKTextBox!
    private var addressInputBox: TKTextBox = TKTextBox().placeholder("Home Address")
    private var websiteInputBox: TKTextBox!
    private var lineView3: TKView!

    var toSigninOptionLabel: TKLabel = TKLabel.create()
        .setNumberOfLines(number: 0)
        .alignment(alignment: .center)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileEditDetailContactsTableViewCell {
    private func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
        contentView.addSubview(view: backView) { make in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(359)
        }

        let line = TKView.create()
            .backgroundColor(color: .white)
            .addTo(superView: contentView) { _ in
            }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Contacts")
            .addTo(superView: contentView, withConstraints: { make in
                make.centerY.equalTo(backView.snp.top)
                make.left.equalToSuperview().offset(40)
                make.height.equalTo(20)
            })
        line.snp.remakeConstraints { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.height.equalTo(4)
            make.left.equalTo(titleLabel.snp.left).offset(-2)
            make.right.equalTo(titleLabel.snp.right).offset(2)
        }

        fullNameInputBox = TKTextBox.create()
            .placeholder("Full name")
            .numberOfWordsLimit(50)
            .keyboardType(.default)
            .hideBorderAndShadowOnFocus(isHidden: true)
            .onTypeEnd({ [weak self] name in
                guard let self = self else { return }
                self.delegate?.profileEditDetailContactsTableViewCell(textBox: self.fullNameInputBox, nameChanged: name)
            })
            .onTyped({ [weak self] name in
                guard let self = self else { return }
                // self.fullNameInputBox.value(name.capitalized)
                self.fullNameInputBox.value(name)
            })
            .addTo(superView: backView, withConstraints: { make in
//                make.top.equalTo(titleLabel.snp.bottom).offset(20)
                make.top.equalToSuperview().offset(40)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            })

        let lineView1 = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
        backView.addSubview(view: lineView1) { make in
            make.bottom.equalTo(fullNameInputBox.snp.bottom)
            make.height.equalTo(1)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview()
        }
        let lineView2 = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))

        emailInputBox = TKTextBox.create()
            .placeholder("Contact email (not for sign-in)")
            .numberOfWordsLimit(200)
            .keyboardType(.emailAddress)
            .hideBorderAndShadowOnFocus(isHidden: true)
            .onTypeEnd({ [weak self] email in
                guard let self = self else { return }
                guard SL.FormatChecker.shared.isEmail(email) else {
                    self.emailInputBox.showWrong(autoHide: false)
                    lineView2.backgroundColor = ColorUtil.red
                    return
                }
                self.emailInputBox.reset()
                self.emailInputBox.hideBorderAndShadowOnFocus(isHidden: true)
                lineView2.backgroundColor = ColorUtil.dividingLine.withAlphaComponent(0.5)
                self.delegate?.profileEditDetailContactsTableViewCell(textBox: self.emailInputBox, emailChanged: email)
            })
            .onTyped({ [weak self] email in
                guard let self = self else { return }
                self.emailInputBox.value(email.lowercased())
            })
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalTo(fullNameInputBox.snp.bottom).offset(20)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            })

        backView.addSubview(view: lineView2) { make in
            make.bottom.equalTo(emailInputBox.snp.bottom)
            make.height.equalTo(1)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview()
        }

        phoneInputBox = TKTextBox.create()
            .placeholder("Phone")
            .prefix("+1")
            .keyboardType(.phonePad)
            .hideBorderAndShadowOnFocus(isHidden: true)
            .numberOfWordsLimit(10)
            .onTyped({ [weak self] phone in
                guard let self = self else { return }
                if phone != "" {
                    guard SL.FormatChecker.shared.isMobilePhone(phone) else {
                        self.phoneInputBox.showWrong(autoHide: false)
                        self.lineView3.backgroundColor(color: ColorUtil.red)
                        return
                    }
                }
                self.phoneInputBox.reset()
                self.phoneInputBox.hideBorderAndShadowOnFocus(isHidden: true)
                self.lineView3.backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))

            })
            .onTypeEnd({ [weak self] phone in
                guard let self = self else { return }
                if phone != "" {
                    guard SL.FormatChecker.shared.isMobilePhone(phone) else {
                        self.phoneInputBox.showWrong(autoHide: false)
                        self.lineView3.backgroundColor(color: ColorUtil.red)
                        return
                    }
                }
                self.phoneInputBox.reset()
                self.phoneInputBox.hideBorderAndShadowOnFocus(isHidden: true)
                self.lineView3.backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
                self.delegate?.profileEditDetailContactsTableViewCell(textBox: self.phoneInputBox, phoneChanged: phone)
            })
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalTo(emailInputBox.snp.bottom).offset(20)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            })
        TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: backView) { make in
                make.bottom.equalTo(phoneInputBox.snp.bottom)
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview()
            }
        addressInputBox
            .hideBorderAndShadowOnFocus(isHidden: true)
            .addTo(superView: backView) { make in
                make.top.equalTo(phoneInputBox.snp.bottom).offset(20)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            }
            .onTapped { [weak self] in
                guard let self = self else { return }
                let controller = StudioBillingSettingUpdateAddressPopWindowViewController()
                if let address = self.address {
                    controller.address = .init(addressLine: address.line1, city: address.city, country: address.country, state: address.state, zipCode: address.postal_code)
                }
                controller.onConfirmButtonTapped = { address in
                    let _address = TKPaymentAddress(city: address.city, country: address.country, line1: address.addressLine, line2: "", postal_code: address.zipCode, state: address.state)
                    self.delegate?.profileEditDetailContactsTableViewCell(addressChanged: _address)
                }
                controller.modalPresentationStyle = .custom
                Tools.getTopViewController()?.present(controller, animated: false)
            }

        lineView3 = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
        backView.addSubview(view: lineView3) { make in
            make.bottom.equalTo(addressInputBox.snp.bottom)
            make.height.equalTo(1)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview()
        }
        websiteInputBox = TKTextBox.create()
            .placeholder("URL")
            .numberOfWordsLimit(200)
            .keyboardType(.URL)
            .hideBorderAndShadowOnFocus(isHidden: true)
            .onTyped({ [weak self] website in
                guard let self = self else { return }
                if website != "" {
                    var _website: String = ""
                    if !website.contains("http://") && !website.contains("https://") {
                        _website = "https://\(website)"
                    } else {
                        _website = website
                    }

                    guard SL.FormatChecker.shared.isURL(_website) else {
                        self.websiteInputBox.showWrong(autoHide: false)
                        return
                    }
                }
                self.websiteInputBox.reset()
                self.websiteInputBox.hideBorderAndShadowOnFocus(isHidden: true)
            })
            .onTypeEnd({ [weak self] website in
                guard let self = self else { return }
                if website != "" {
                    var _website: String = ""
                    if !website.contains("http://") && !website.contains("https://") {
                        _website = "https://\(website)"
                    } else {
                        _website = website
                    }

                    guard SL.FormatChecker.shared.isURL(_website) else {
                        self.websiteInputBox.showWrong(autoHide: false)
                        return
                    }
                }
                self.websiteInputBox.reset()
                self.websiteInputBox.hideBorderAndShadowOnFocus(isHidden: true)
                self.delegate?.profileEditDetailContactsTableViewCell(textBox: self.websiteInputBox, websiteChanged: website)
            })
            .addTo(superView: backView, withConstraints: { make in
                make.top.equalTo(phoneInputBox.snp.bottom).offset(20)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            })
//        websiteInputBox.layer.masksToBounds = true
//        let text = "Change sign-in email?\nGo to \"Settings > Sign in options\""
//        toSigninOptionLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: "Settings > Sign in options", allColor: ColorUtil.Font.fourth, selectedColor: ColorUtil.main, font: FontUtil.regular(size: 13), selectedFont: FontUtil.medium(size: 13), fontSize: 13, selectedFontSize: 13, ignoreCase: true, charasetSpace: 0)
//        toSigninOptionLabel.addTo(superView: contentView) { make in
//            make.top.equalTo(backView.snp.bottom).offset(10)
//            make.centerX.equalToSuperview()
//        }
    }
}

extension ProfileEditDetailContactsTableViewCell {
    func loadData(user: TKUser, role: TKUserRole = .teacher) {
//        _ = fullNameInputBox.value(user.name.capitalized)
        _ = fullNameInputBox.value(user.name)
        _ = emailInputBox.value(user.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
        _ = phoneInputBox.value(user.phone.trimmingCharacters(in: .whitespacesAndNewlines))
        _ = websiteInputBox.value(user.website)
        if let address = user.addresses.first, address.isValid {
            addressInputBox.value(address.addressString)
        } else {
            addressInputBox.value("")
        }
        if role == .student {
            websiteInputBox.layer.masksToBounds = true
            websiteInputBox.snp.updateConstraints { make in
                make.height.equalTo(0)
                make.top.equalTo(phoneInputBox.snp.bottom).offset(0)
            }
            lineView3.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            backView.snp.updateConstraints { make in
                make.height.equalTo(359)
            }
        }
    }
}

protocol ProfileEditDetailContactsTableViewCellDelegate: NSObjectProtocol {
    func profileEditDetailContactsTableViewCell(textBox: TKTextBox, nameChanged name: String)
    func profileEditDetailContactsTableViewCell(textBox: TKTextBox, emailChanged email: String)
    func profileEditDetailContactsTableViewCell(textBox: TKTextBox, phoneChanged phone: String)
    func profileEditDetailContactsTableViewCell(textBox: TKTextBox, websiteChanged website: String)
    func profileEditDetailContactsTableViewCell(addressChanged address: TKPaymentAddress)
}
