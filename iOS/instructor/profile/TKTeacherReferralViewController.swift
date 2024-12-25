//
//  TKTeacherReferralViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/4/22.
//  Copyright © 2021 spelist. All rights reserved.
//

import UIKit

struct TKTeacherReferral {
    static func show() {
        guard let topController = Tools.getTopViewController() as? TKBaseViewController else { return }
        topController.showFullScreenLoadingNoAutoHide()

        CommonsService.shared.teacherReferralCode { code, _ in
            if let code = code {
                logger.debug("获取到的code: \(code.toJSONString() ?? "")")
                topController.hideFullScreenLoading()
                let controller = TKTeacherReferralViewController(code: code)
                controller.modalPresentationStyle = .custom
                topController.present(controller, animated: false, completion: nil)
            } else {
                topController.updateFullScreenLoadingMsg(msg: "Get referral code failed, please try again later.")
                topController.hideFullScreenLoading(delay: 2)
            }
        }
    }
}

class TKTeacherReferralViewController: TKBaseViewController {
    private var code: TKReferralCode?

    private let offsetOfContentView: CGFloat = 504 + UiUtil.safeAreaBottom() + ((UIScreen.main.bounds.height - 504) / 2)

    private var contentView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.blue)
        .corner(size: 5)

    private var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.medium(size: 20))
        .textColor(color: .white)
        .text(text: "Referral program")

    private lazy var couponView: TKCouponView = makeCouponView()

    private lazy var codeLabelBackView: TKView = TKView.create()
        .backgroundColor(color: .white)

    private lazy var codeLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 20))
        .textColor(color: ColorUtil.main)
        .setNumberOfLines(number: 1)
        .alignment(alignment: .center)

    private lazy var cardView: TKView = makeCardView()

    private lazy var cardTitleLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.Font.primary)
        .text(text: "TuneKey PRO")
    private lazy var referralButton: TKBlockButton = TKBlockButton(frame: .zero, title: "REFER NOW")
    private lazy var cancelButton: TKButton = TKButton.create()
        .titleFont(font: FontUtil.medium(size: 15))
        .title(title: "No, thanks")
        .titleColor(color: ColorUtil.red)

    private var isShowd: Bool = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        codeLabelBackView.dottedBorder(color: ColorUtil.main)
        show()
    }

    convenience init(code: TKReferralCode) {
        self.init(nibName: nil, bundle: nil)
        self.code = code
//        codeLabel.text(code.referralCode)
//        cardTitleLabel.text("\(ReferralCodeConfig.numberOfMonthOfTargetUser)-Month-Free TuneKey PRO")
        couponView
            .subtitle("\(ReferralCodeConfig.numberOfMonthOfTargetUser)-month-free")
            .content(code.referralCode)
    }
}

extension TKTeacherReferralViewController {
    private func makeCouponView() -> TKCouponView {
        let couponView = TKCouponView(frame: .zero)
        couponView.isSmall = true
        couponView.setup(title: "Referral coupon", subtitle: "1-month-free", contents: [
            "Unlimited students",
            "Unlimited materials",
            "Unlock business insides",
        ])
        couponView.leftCircle.backgroundColor = ColorUtil.blue
        couponView.rightCircle.backgroundColor = ColorUtil.blue
        couponView.leftVerticalLine.backgroundColor = ColorUtil.blue
        couponView.rightVerticalLine.backgroundColor = ColorUtil.blue
        couponView.cornerRadius = 10
        return couponView
    }
}

extension TKTeacherReferralViewController {
    private func makeCardView() -> TKView {
        let view = TKView.create()
            .backgroundColor(color: .white)
            .corner(size: 5)

        cardTitleLabel.addTo(superView: view) { make in
            make.top.equalToSuperview().offset(25)
            make.left.equalToSuperview().offset(30)
            make.height.equalTo(15)
        }

        let logoImageView: TKImageView = TKImageView.create()
            .setImage(name: "logo")
            .addTo(superView: view) { make in
                make.top.equalToSuperview().offset(50)
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(48)
            }

        codeLabelBackView.addTo(superView: view) { make in
            make.top.equalToSuperview().offset(50)
            make.left.equalToSuperview().offset(30)
            make.height.equalTo(48)
            make.right.equalTo(logoImageView.snp.left).offset(-10)
        }

        codeLabel.addTo(superView: codeLabelBackView) { make in
            make.center.equalToSuperview()
        }

        let checkView1 = TKImageView.create()
            .setImage(name: "checkPrimary")
            .addTo(superView: view) { make in
                make.top.equalTo(codeLabelBackView.snp.bottom).offset(20)
                make.size.equalTo(22)
                make.left.equalToSuperview().offset(30)
            }
        TKLabel.create()
            .font(font: FontUtil.medium(size: UIScreen.isSmallerScreen ? 11 : 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Unlimited students")
            .setLabelRowSpace(lineSpace: 0, wordSpace: 0.2)
            .addTo(superView: view) { make in
                make.top.equalTo(checkView1.snp.top)
                make.left.equalTo(checkView1.snp.right).offset(4)
                make.height.equalTo(22)
                make.right.equalToSuperview().offset(-20)
            }
        let checkView2 = TKImageView.create()
            .setImage(name: "checkPrimary")
            .addTo(superView: view) { make in
                make.top.equalTo(checkView1.snp.bottom).offset(7)
                make.size.equalTo(22)
                make.left.equalToSuperview().offset(30)
            }
        TKLabel.create()
            .font(font: FontUtil.medium(size: UIScreen.isSmallerScreen ? 11 : 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Unlimited materials")
            .setLabelRowSpace(lineSpace: 0, wordSpace: 0.2)
            .addTo(superView: view) { make in
                make.top.equalTo(checkView2.snp.top)
                make.left.equalTo(checkView2.snp.right).offset(4)
                make.height.equalTo(22)
                make.right.equalToSuperview().offset(-20)
            }
        let checkView3 = TKImageView.create()
            .setImage(name: "checkPrimary")
            .addTo(superView: view) { make in
                make.top.equalTo(checkView2.snp.bottom).offset(7)
                make.size.equalTo(22)
                make.left.equalToSuperview().offset(30)
            }
        TKLabel.create()
            .font(font: FontUtil.medium(size: UIScreen.isSmallerScreen ? 11 : 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Unlock business insides")
            .setLabelRowSpace(lineSpace: 0, wordSpace: 0.2)
            .addTo(superView: view) { make in
                make.top.equalTo(checkView3.snp.top)
                make.left.equalTo(checkView3.snp.right).offset(4)
                make.height.equalTo(22)
                make.right.equalToSuperview().offset(-20)
            }

        return view
    }
}

extension TKTeacherReferralViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)

        contentView.addTo(superView: view) { make in
            make.center.equalToSuperview()
            make.width.equalTo(286)
            make.height.equalTo(504)
        }

        titleLabel.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(25)
            make.centerX.equalToSuperview()
            make.height.equalTo(25)
        }

        couponView.addTo(superView: contentView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(17)
            make.centerX.equalToSuperview()
            make.height.equalTo(228)
            make.width.equalTo(260)
        }
        
        let bottomView: TKView = TKView.create()
            .backgroundColor(color: .white)
            .corner(size: 5)
            .maskCorner(masks: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            .addTo(superView: contentView) { make in
                make.bottom.left.right.equalToSuperview()
                make.height.equalTo(190)
            }

        let messageLabel: TKLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 12))
            .textColor(color: ColorUtil.Font.primary)
            .alignment(alignment: .center)
            .setNumberOfLines(number: 0)
            .text(text: "Get an \(ReferralCodeConfig.numberOfMonthOfTargetUser)-month-free coupon for both you and referred instructor.\nRedeem up to \(ReferralCodeConfig.limitOfMonthOfReferralUser) months for free.")
            .addTo(superView: bottomView) { make in
                make.top.equalToSuperview().offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            }

        referralButton.backgroundColor = ColorUtil.blue
        referralButton.layer.shadowColor = ColorUtil.blue.withAlphaComponent(0.4).cgColor
        referralButton.addTo(superView: bottomView) { make in
            make.width.equalTo(160)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.top.equalTo(messageLabel.snp.bottom).offset(30)
        }

        cancelButton.addTo(superView: bottomView) { make in
            make.top.equalTo(referralButton.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
            make.width.equalTo(130)
        }

        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.transform = CGAffineTransform(translationX: 0, y: offsetOfContentView)
    }
}

extension TKTeacherReferralViewController {
    func show() {
        guard !isShowd else {
            return
        }
        isShowd = true
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        }
    }

    func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: self.offsetOfContentView)
        } completion: { [weak self] _ in
            self?.dismiss(animated: false) {
                completion?()
            }
        }
    }
}

extension TKTeacherReferralViewController {
    override func bindEvent() {
        super.bindEvent()
        cancelButton.onTapped { [weak self] _ in
            self?.hide()
        }

        referralButton.onTapped { [weak self] _ in
            self?.onReferralButtonTapped()
        }
    }

    private func onReferralButtonTapped() {
        guard let code = code else { return }
        let title = "TuneKey, a music education artifact, tap link to start."
        let link = URL(string: code.deepLink)!
        let controller = UIActivityViewController(activityItems: [title, link] as [Any], applicationActivities: nil)
        present(controller, animated: true, completion: nil)
    }
}
