//
//  ProfileMergeAccountTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/10/10.
//  Copyright © 2019年 spelist. All rights reserved.
//

import FirebaseAuth
import UIKit

class ProfileMergeAccountTableViewCell: UITableViewCell {
    weak var delegate: ProfileMergeAccountTableViewCellDelegate?

    private var step1View: TKView!

    private var step2AccountLabel: TKLabel!
    private var step2VerifyTextBox: TKTextBox!
    private var step2VerifyMsgSentTipLabel: TKLabel!
    private var step2ResendButton: TKBlockButton!
    private var step2View: TKView!

    private var step3AccountTextBox: TKTextBox!
    private var step3VerifyTextBox: TKTextBox!
    private var step3ResendButton: TKBlockButton!
    private var step3View: TKView!

    private var account: String = ""
    private var newAccount: String = ""

    private var timer: Timer!

    private var step2Key: String = ""
    private var step2Code: String = ""

    private var step3Key: String = ""
    private var step3Code: String = ""

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.timer = nil
    }
}

extension ProfileMergeAccountTableViewCell {
    private func initView() {
        backgroundColor = ColorUtil.backgroundColor
        contentView.backgroundColor = ColorUtil.backgroundColor
        initStep1View()
        initStep2View()
        initStep3View()
    }

    private func initStep1View() {
        step1View = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalToSuperview()
                make.width.equalToSuperview()
                make.left.equalToSuperview().offset(0)
                make.height.equalTo(450)
            })

        let image = TKImageView.create()
            .setImage(name: "imgChengeNumber")
            .addTo(superView: step1View) { make in
                make.top.equalToSuperview().offset(80)
                make.centerX.equalToSuperview()
                make.width.equalTo(200)
                make.height.equalTo(120)
            }

        let tipLabel1 = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Use Merge Account to migrate your account info, groups and settings from your current account to a new account. You can’t undo this change.")
            .addTo(superView: step1View) { make in
                make.top.equalTo(image.snp.bottom).offset(30)
                make.left.equalToSuperview().offset(30)
                make.right.equalToSuperview().offset(-30)
            }
        tipLabel1.numberOfLines = 0
        tipLabel1.lineBreakMode = .byWordWrapping

        let tipLabel2 = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "To proceed, confirm the verification email received by your new email and tap Next to verify that number.")
            .addTo(superView: step1View) { make in
                make.top.equalTo(tipLabel1.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(30)
                make.right.equalToSuperview().offset(-30)
            }
        tipLabel2.numberOfLines = 0
        tipLabel2.lineBreakMode = .byWordWrapping

        let nextButton = TKBlockButton(frame: .zero, title: "NEXT")
        step1View.addSubview(view: nextButton) { make in
            make.bottom.equalToSuperview()
            make.width.equalTo(180)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
        }
        nextButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                guard let self = self else { return }
                self.step1View.snp.updateConstraints({ make in
                    make.left.equalToSuperview().offset(-TKScreen.width)
                })
                self.step2View.snp.updateConstraints({ make in
                    make.left.equalToSuperview().offset(0)
                })
                self.contentView.layoutIfNeeded()
            })
            self.sendVerificationCodeToOldEmail()
        }
    }

    private func initStep2View() {
        step2View = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview().offset(TKScreen.width)
                make.width.equalToSuperview()
                make.height.equalToSuperview()
            })

        step2AccountLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "")
            .alignment(alignment: .center)
            .addTo(superView: step2View) { make in
                make.top.equalToSuperview().offset(60)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            }

        step2VerifyTextBox = TKTextBox.create()
            .placeholder("Verification code")
            .prefix("T-")
            .keyboardType(.numberPad)
            .inputType(.text)
            .numberOfWordsLimit(6)
            .addTo(superView: step2View, withConstraints: { make in
                make.top.equalTo(step2AccountLabel.snp.bottom).offset(40)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-110)
                make.height.equalTo(64)
            })

        step2VerifyMsgSentTipLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "We have been sent the verification code to your account email, check it please.")
            .addTo(superView: step2View) { make in
                make.top.equalTo(step2VerifyTextBox.snp.bottom).offset(2)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            }
        step2VerifyMsgSentTipLabel.numberOfLines = 0
        step2VerifyMsgSentTipLabel.lineBreakMode = .byWordWrapping

        step2ResendButton = TKBlockButton(frame: .zero, title: "RESEND")
        step2ResendButton.disable()
        step2ResendButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.step2ResendButton.disable()
            self.sendVerificationCodeToOldEmail()
        }
        step2View.addSubview(view: step2ResendButton) { make in
            make.top.equalTo(step2VerifyTextBox.snp.top)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(80)
            make.height.equalTo(step2VerifyTextBox.snp.height)
        }

        let nextButton = TKBlockButton(frame: .zero, title: "NEXT")
        nextButton.disable()
        nextButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.verifyCodeForOldEmail(button: nextButton)
        }
        step2View.addSubview(view: nextButton) { make in
            make.top.equalTo(step2VerifyMsgSentTipLabel.snp.bottom).offset(20)
            make.width.equalTo(120)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
        }
        _ = step2VerifyTextBox.onTyped { value in
            if value.count == 6 {
                nextButton.enable()
            } else {
                nextButton.disable()
            }
        }
    }

    private func initStep3View() {
        step3View = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
            .addTo(superView: contentView, withConstraints: { make in
                make.left.equalToSuperview().offset(TKScreen.width)
                make.width.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalToSuperview()
            })

        step3AccountTextBox = TKTextBox.create()
            .placeholder("New email")
            .inputType(.text)
            .keyboardType(.emailAddress)
            .addTo(superView: step3View, withConstraints: { make in
                make.top.equalToSuperview().offset(40)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })

        let verifyView = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
            .addTo(superView: step3View) { make in
                make.top.equalTo(step3AccountTextBox.snp.bottom).offset(20)
                make.width.equalToSuperview()
                make.centerX.equalToSuperview()
                make.height.equalTo(64)
            }
        step3VerifyTextBox = TKTextBox.create()
            .placeholder("Verification code")
            .prefix("T-")
            .inputType(.text)
            .keyboardType(.numberPad)
            .addTo(superView: verifyView, withConstraints: { make in
                make.top.equalTo(step3AccountTextBox.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-110)
                make.height.equalTo(64)
            })

        step3ResendButton = TKBlockButton(frame: .zero, title: "SEND")
        verifyView.addSubview(view: step3ResendButton) { make in
            make.height.equalTo(64)
            make.width.equalTo(80)
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
        step3ResendButton.disable()

        step3ResendButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            logger.debug("on step3 resend button tapped")
            self.sendVerificationCodeToNewEmail()
        }

        step3AccountTextBox.onTyped({ [weak self] text in
            guard let self = self else { return }
            if SL.FormatChecker.shared.isEmail(text) {
                self.step3ResendButton.enable()
            } else {
                self.step3ResendButton.disable()
            }
        })

        let verifyButton = TKBlockButton(frame: .zero, title: "VERIFY")
        step3View.addSubview(view: verifyButton) { make in
            make.top.equalTo(verifyView.snp.bottom).offset(20)
            make.width.equalTo(120)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
        }
    }
}

extension ProfileMergeAccountTableViewCell {
    func loadData(account: String) {
        self.account = account
        step2AccountLabel.text(account)
    }

    private func sendVerificationCodeToOldEmail() {
        guard account != "", SL.FormatChecker.shared.isEmail(account) else {
            return
        }
        step2ResendButton.startLoading { [weak self] in
            guard let self = self else { return }
            CommonsService.shared.sendVerificationCodeToEmail(email: self.account) { [weak self] isSuccess, key in
                guard let self = self else { return }
                if !isSuccess {
                    self.step2ResendButton.stopLoadingWithFailed {
                        TKToast.show(msg: TipMsg.sendFailed, style: .warning)
                    }
                } else {
                    self.step2Key = key!
                    self.step2ResendButton.stopLoading(completion: { [weak self] in
                        guard let self = self else { return }
                        self.step2ResendButton.disable()
                        self.step2ResendButton.timeDown(time: 30, onTimeDown: { [weak self] remainingTime in
                            guard let self = self else { return }
                            self.step2ResendButton.setTitle(title: "\(remainingTime)")
                        }, completion: { [weak self] in
                            guard let self = self else { return }
                            self.step2ResendButton.setTitle(title: "RESEND")
                            self.step2ResendButton.enable()
                        })
                    })
                }
            }
        }
    }

    private func verifyCodeForOldEmail(button: TKBlockButton) {
        guard step2Key != "" else {
            return
        }

        let code = step2VerifyTextBox.getValue()
        button.startLoading { [weak self] in
            guard let self = self else { return }
            CommonsService.shared.checkVerificationCode(email: self.account, code: code, key: self.step2Key) { [weak self] isValid,_  in
                guard let self = self else { return }
                if isValid {
                    button.stopLoading {
                        logger.debug("success")
                        UIView.animate(withDuration: 0.2, animations: { [weak self] in
                            guard let self = self else { return }
                            self.step3View.snp.updateConstraints({ make in
                                make.left.equalToSuperview().offset(0)
                            })
                            self.step2View.snp.updateConstraints({ make in
                                make.left.equalToSuperview().offset(-TKScreen.width)
                            })

                            self.contentView.layoutIfNeeded()
                        })
                    }
                } else {
                    button.stopLoadingWithFailed()
                    self.step2VerifyTextBox.showWrong()
                }
            }
        }
    }

    private func sendVerificationCodeToNewEmail() {
        newAccount = step3AccountTextBox.getValue()
        guard newAccount != "", SL.FormatChecker.shared.isEmail(newAccount) else {
            return
        }
        guard newAccount != account else {
            step3AccountTextBox.showWrong()
            TKToast.show(msg: TipMsg.newEmailBeOldEmail, style: .error)
            return
        }
        step3ResendButton.startLoading { [weak self] in
            guard let self = self else { return }
            CommonsService.shared.sendVerificationCodeToEmail(email: self.newAccount) { [weak self] isSuccess, key in
                guard let self = self else { return }
                if !isSuccess {
                    self.step3ResendButton.stopLoadingWithFailed {
                        TKToast.show(msg: TipMsg.sendFailed, style: .warning)
                    }
                } else {
                    self.step3Key = key!
                    self.step3ResendButton.stopLoading(completion: { [weak self] in
                        guard let self = self else { return }
                        self.step3ResendButton.disable()
                        self.step3ResendButton.timeDown(time: 30, onTimeDown: { [weak self] remainingTime in
                            guard let self = self else { return }
                            self.step3ResendButton.setTitle(title: "\(remainingTime)")
                        }, completion: { [weak self] in
                            guard let self = self else { return }
                            self.step3ResendButton.setTitle(title: "RESEND")
                            self.step3ResendButton.enable()
                        })
                    })
                }
            }
        }
    }

    private func verifyCodeForOldEmail() {
    }
}

protocol ProfileMergeAccountTableViewCellDelegate: NSObjectProtocol {
}
