//
//  ProfileUpgradeDetailViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/5.
//  Copyright © 2019年 spelist. All rights reserved.
//
import FirebaseAuth
import NVActivityIndicatorView
import PromiseKit
import RxSwift
import UIKit

extension ProfileUpgradeDetailViewController {
    static func show(level: TKTeacher.MemberLevel, target: UIViewController, isCouponUser: Bool = false, couponName: String = "") {
        let controller = ProfileUpgradeDetailViewController()
        controller.teacherMemberLevelId = level.rawValue
        controller.isCouponUser = isCouponUser
        controller.couponName = couponName
        controller.modalPresentationStyle = .custom
        target.present(controller, animated: false, completion: nil)
    }
}

class ProfileUpgradeDetailViewController: TKBaseViewController {
    private var contentView: TKView!
    private var okButton: TKBlockButton!
    private var cancelButton: TKLabel!
    private var topView: TKView!
    private var nextPaymentLabel: TKLabel!
    var isCouponUser: Bool = false
    var couponName: String = ""
    var haveCouponButton: TKButton = TKButton.create()
        .title(title: "Have coupon?")
        .titleFont(font: FontUtil.medium(size: 12))
        .titleColor(color: .white)
    var noCouponButton: TKButton = TKButton.create()
        .title(title: "No coupon?")
        .titleFont(font: FontUtil.medium(size: 12))
        .titleColor(color: .white)

    private var haveCouponButtonLoadingIndicator: NVActivityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: .white, padding: 0)

    private var loadingView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 5)
    private var loadingIndicatorView: NVActivityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: ColorUtil.main, padding: 0)
    private var loadingResultView: TKView = TKView.create()
        .backgroundColor(color: .clear)

    private var loadingLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 15))
        .textColor(color: ColorUtil.Font.fourth)
        .alignment(alignment: .center)

    private var contentViewHeight: CGFloat = 0
    private var infoLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.medium(size: 13))
        .textColor(color: .white)
        .alignment(alignment: .center)
    var teacherMemberLevelId = 1

    private var isUpgradeScreen: Bool = true {
        didSet {
            if isUpgradeScreen {
                okButton?.setTitle(title: "UPGRADE NOW")
            } else {
                okButton?.setTitle(title: "REDEEM NOW")
            }
        }
    }

    private lazy var codeTextField: UITextField = UITextField()
    private lazy var codeTextView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 5)
    private lazy var redeemCouponView: TKView = makeRedeemCouponView()

    private lazy var cancelDetailView: TKView = makeCancelDetailView()

    private var isPurchasing: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isExpireProShow = true
        }
        show()
        checkCoupon()
    }

    deinit {
        logger.debug("销毁升级界面")
        isExpireProShow = false
        setProExpireAlert()
    }
}

extension ProfileUpgradeDetailViewController {
    private func makeRedeemCouponView() -> TKView {
        let view = TKView.create()
            .backgroundColor(color: ColorUtil.main)
        noCouponButton.addTo(superView: view) { make in
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        let proTitleLabel: TKLabel = TKLabel.create()
            .font(font: FontUtil.medium(size: 24))
            .textColor(color: .white)
            .text(text: "PRO")
            .addTo(superView: view) { make in
                make.top.equalToSuperview().offset(30)
                make.centerX.equalToSuperview()
                make.height.equalTo(30)
            }

        codeTextView.addTo(superView: view) { make in
            make.top.equalTo(proTitleLabel.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }

        codeTextField.addTo(superView: codeTextView) { make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-5)
        }
        codeTextField.addTarget(self, action: #selector(onCouponTextFieldTyped), for: .editingChanged)
        codeTextField.font = FontUtil.medium(size: 20)
        codeTextField.textColor = ColorUtil.Font.third
        codeTextField.tintColor = ColorUtil.main
        codeTextField.textAlignment = .center

        TKLabel.create()
            .font(font: FontUtil.medium(size: 13))
            .textColor(color: .white)
            .text(text: "Type your coupon code")
            .addTo(superView: view) { make in
                make.top.equalTo(codeTextView.snp.bottom).offset(10)
                make.centerX.equalToSuperview()
            }

        return view
    }

    private func makeCancelDetailView() -> TKView {
        let view = TKView.create()
            .backgroundColor(color: .white)
            .corner(size: 13)
        let titleLabel = TKLabel.create()
            .font(font: FontUtil.medium(size: 17))
            .textColor(color: .black)
            .text(text: "6 steps to unsubscribe PRO")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalToSuperview().offset(20)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(22)
            }
        let titleFont = FontUtil.medium(size: 13)
        let titleColor = UIColor.black
        let detailFont = FontUtil.regular(size: 13)
        let detailColor = UIColor.black
        let step1TitleLabel = TKLabel.create()
            .font(font: titleFont)
            .textColor(color: titleColor)
            .text(text: "Step1. Open your iPhone's Settings")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(17)
            }

        let step1DetailLabel = TKLabel.create()
            .font(font: detailFont)
            .textColor(color: detailColor)
            .setNumberOfLines(number: 0)
            .text(text: "You'll usually find this app on the home screen.")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(step1TitleLabel.snp.bottom).offset(5)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
            }
        let step2TitleLabel = TKLabel.create()
            .font(font: titleFont)
            .textColor(color: titleColor)
            .text(text: "Step2. Tap your name")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(step1DetailLabel.snp.bottom).offset(16)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(17)
            }

        let step2DetailLabel = TKLabel.create()
            .font(font: detailFont)
            .textColor(color: detailColor)
            .setNumberOfLines(number: 0)
            .text(text: "It's at the top of the screen.")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(step2TitleLabel.snp.bottom).offset(5)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
            }
        let step3TitleLabel = TKLabel.create()
            .font(font: titleFont)
            .textColor(color: titleColor)
            .text(text: "Step3. Tap Subscriptions")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(step2DetailLabel.snp.bottom).offset(16)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(17)
            }

        let step3DetailLabel = TKLabel.create()
            .font(font: detailFont)
            .textColor(color: detailColor)
            .setNumberOfLines(number: 0)
            .text(text: "A list of subscriptions for apps and services will appear.")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(step3TitleLabel.snp.bottom).offset(5)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
            }
        let step4TitleLabel = TKLabel.create()
            .font(font: titleFont)
            .textColor(color: titleColor)
            .setNumberOfLines(number: 0)
            .text(text: "Step4. Tap the subscription you want to cancel.")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(step3DetailLabel.snp.bottom).offset(16)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(34)
            }

        let step4DetailLabel = TKLabel.create()
            .font(font: detailFont)
            .textColor(color: detailColor)
            .setNumberOfLines(number: 0)
            .text(text: "Information about the subscription will appear.")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(step4TitleLabel.snp.bottom).offset(5)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
            }
        let step5TitleLabel = TKLabel.create()
            .font(font: titleFont)
            .textColor(color: titleColor)
            .text(text: "Step5. Tap Cancel Subscription")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(step4DetailLabel.snp.bottom).offset(16)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(17)
            }

        let step5DetailLabel = TKLabel.create()
            .font(font: detailFont)
            .textColor(color: detailColor)
            .setNumberOfLines(number: 0)
            .text(text: "It's in red text at the bottom of the page. A confirmation message will appear.")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(step5TitleLabel.snp.bottom).offset(5)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
            }
        let step6TitleLabel = TKLabel.create()
            .font(font: titleFont)
            .textColor(color: titleColor)
            .text(text: "Step6. Tap Confirm")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(step5DetailLabel.snp.bottom).offset(16)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(17)
            }

        TKLabel.create()
            .font(font: detailFont)
            .textColor(color: detailColor)
            .setNumberOfLines(number: 0)
            .text(text: "Now that you've unsubscribed, you will not be billed again for this service. You can still access the features until the subscription expires in the date shown.")
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(step6TitleLabel.snp.bottom).offset(5)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.bottom.lessThanOrEqualToSuperview().offset(-70)
            }
        TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)
            .addTo(superView: view) { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(1)
                make.bottom.equalToSuperview().offset(-41)
            }
        let cancelButton = TKButton.create()
            .title(title: "Go back")
            .titleFont(font: FontUtil.medium(size: 17))
            .titleColor(color: ColorUtil.main)
            .addTo(superView: view) { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(40)
            }
        cancelButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.2) {
                self.cancelDetailView.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
            } completion: { _ in
                self.cancelDetailView.isHidden = true
            }
        }
        return view
    }
}

extension ProfileUpgradeDetailViewController {
    override func initView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
        contentView.clipsToBounds = true
//        var width = UIScreen.main.bounds.width * 0.75
//        if width > 300 {
//            width = 300
//        }
        let height: CGFloat = 500
        contentViewHeight = height
        view.addSubview(view: contentView) { make in
//            make.width.equalTo(width)
            make.width.equalTo(UIScreen.main.bounds.width - 80)
            make.height.equalTo(height)
            make.center.equalToSuperview()
        }

        topView = TKView.create()
            .backgroundColor(color: ColorUtil.main)
        contentView.addSubview(view: topView) { make in
            make.height.equalTo(196)
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        haveCouponButtonLoadingIndicator.addTo(superView: topView) { make in
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(22)
        }
        haveCouponButtonLoadingIndicator.startAnimating()
        haveCouponButton.addTo(superView: topView) { make in
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        haveCouponButton.isHidden = true

        let proLebal = TKLabel.create()
            .font(font: FontUtil.medium(size: 24))
            .textColor(color: UIColor.white)
            .alignment(alignment: .center)
            .text(text: "PRO")
        topView.addSubview(view: proLebal) { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(30)
        }

        let priceLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 70))
            .alignment(alignment: .left)
            .textColor(color: UIColor.white)
            .text(text: "9")
        topView.addSubview(view: priceLabel) { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(66)
            make.height.equalTo(70)
        }

        let prefixLabel = TKLabel.create()
            .font(font: FontUtil.medium(size: 24))
            .alignment(alignment: .center)
            .textColor(color: UIColor.white.withAlphaComponent(0.7))
            .text(text: "$")
        topView.addSubview(view: prefixLabel) { make in
            make.top.equalTo(priceLabel.snp.top)
            make.right.equalTo(priceLabel.snp.left).offset(-6)
        }

        let suffixLabel = TKLabel.create()
            .font(font: FontUtil.medium(size: 24))
            .textColor(color: UIColor.white.withAlphaComponent(0.7))
            .text(text: ".99/mo")
        topView.addSubview(view: suffixLabel) { make in
            make.bottom.equalTo(priceLabel.snp.bottom).offset(-4)
            make.left.equalTo(priceLabel.snp.right)
        }
        infoLabel.setNumberOfLines(number: 0)
        infoLabel
            .addTo(superView: topView) { make in
                make.left.equalToSuperview().offset(10)
                make.right.equalToSuperview().offset(-10)
                make.bottom.equalToSuperview().offset(-30)
            }

        nextPaymentLabel = TKLabel.create()
            .font(font: FontUtil.medium(size: 13))
            .textColor(color: UIColor.white)
            .alignment(alignment: .center)
            .text(text: "")
            .addTo(superView: topView, withConstraints: { make in
                make.top.equalTo(suffixLabel.snp.bottom).offset(32)
                make.centerX.equalToSuperview()
            })
        nextPaymentLabel.isHidden = true

        let label0 = TKLabel.create()
            .font(font: FontUtil.bold(size: 20))
            .alignment(alignment: .center)
            .textColor(color: UIColor(red: 6, green: 37, blue: 60))
            .text(text: "PRO includes")
        label0.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.77)
        contentView.addSubview(view: label0) { make in
            make.top.equalTo(topView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        redeemCouponView.addTo(superView: contentView) { make in
            make.height.equalTo(196)
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        redeemCouponView.isHidden = true

        let infoImageView = TKImageView.create()
            .setImage(name: "imgInfo")
            .asCircle()
            .addTo(superView: contentView) { make in
                make.centerY.equalTo(label0.snp.centerY)
                make.left.equalTo(label0.snp.right).offset(6)
                make.size.equalTo(22)
            }

        infoImageView.onViewTapped { [weak self] _ in
            self?.toMoreDetail()
        }

        let check1 = TKImageView.create()
            .setImage(name: "checkPrimary")
            .setSize(22)
        contentView.addSubview(view: check1) { make in
            make.top.equalTo(label0.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(30)
            make.size.equalTo(22)
        }
        let label1 = TKLabel.create()
            .font(font: FontUtil.medium(size: UIScreen.isSmallerScreen ? 13 : 18))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Unlimited students")
        label1.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.2)
        contentView.addSubview(view: label1) { make in
            make.centerY.equalTo(check1)
            make.left.equalTo(check1.snp.right).offset(4)
            make.right.equalToSuperview()
        }

        let check2 = TKImageView.create()
            .setImage(name: "checkPrimary")
            .setSize(22)
        contentView.addSubview(view: check2) { make in
            make.top.equalTo(label1.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(30)
            make.size.equalTo(22)
        }
        let label2 = TKLabel.create()
            .font(font: FontUtil.medium(size: UIScreen.isSmallerScreen ? 13 : 18))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Unlimited materials")
        label2.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.2)
        contentView.addSubview(view: label2) { make in
            make.centerY.equalTo(check2)
            make.left.equalTo(check2.snp.right).offset(4)
            make.right.equalToSuperview()
        }

        let check3 = TKImageView.create()
            .setImage(name: "checkPrimary")
            .setSize(22)
        contentView.addSubview(view: check3) { make in
            make.top.equalTo(label2.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(30)
            make.size.equalTo(22)
        }
        let label3 = TKLabel.create()
            .font(font: FontUtil.medium(size: UIScreen.isSmallerScreen ? 13 : 18))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Unlock business insides")
        label3.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.2)
        contentView.addSubview(view: label3) { make in
            make.centerY.equalTo(check3)
            make.left.equalTo(check3.snp.right).offset(4)
            make.right.equalToSuperview()
        }

        okButton = TKBlockButton(frame: .zero, title: "UPGRADE NOW", style: TKBlockButton.Style.normal)
        contentView.addSubview(view: okButton) { make in
            make.top.equalTo(label3.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(160)
            make.height.equalTo(44)
        }
        cancelButton = TKLabel.create()
            .text(text: "No, thanks")
            .alignment(alignment: .center)
            .textColor(color: UIColor(named: "red")!)
            .font(font: FontUtil.medium(size: 15))
        cancelButton.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.58)
        contentView.addSubview(view: cancelButton) { make in
            make.top.equalTo(okButton.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(130)
            make.height.equalTo(24)
        }

        let termOfUseAndPolicyLabel = TKLabel.create()
            .font(font: FontUtil.medium(size: 13))
            .textColor(color: .white)
            .alignment(alignment: .center)
            .addTo(superView: contentView) { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().offset(-10)
            }
        let string = "Terms of Use and Privacy Policy"
        let attributedText = NSMutableAttributedString(string: string, attributes: [
            .font: FontUtil.regular(size: 13),
            .foregroundColor: ColorUtil.Font.primary,
            .kern: 0.0,
        ])
        if let range = string.matchRange("Terms of Use").first {
            attributedText.addAttribute(.foregroundColor, value: ColorUtil.Font.third, range: range)
            attributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
        if let range = string.matchRange("Privacy Policy").first {
            attributedText.addAttribute(.foregroundColor, value: ColorUtil.Font.third, range: range)
            attributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
        termOfUseAndPolicyLabel.attributedText = attributedText

        termOfUseAndPolicyLabel.onViewTapped { [weak self] _ in
            let controller = ProfileAboutUsViewController()
            controller.hero.isEnabled = true
            controller.hero.modalAnimationType = .selectBy(presenting: .pageIn(direction: .up), dismissing: .pageOut(direction: .down))
            controller.modalPresentationStyle = .custom
            self?.present(controller, animated: true, completion: nil)
        }

        initLoadingView()
        contentView.transform = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
        contentView.layer.opacity = 0

        cancelDetailView.addTo(superView: view) { make in
            make.width.equalTo(UIScreen.main.bounds.width - 80)
            make.center.equalToSuperview()
        }
        cancelDetailView.isHidden = true
    }

    private func initLoadingView() {
        loadingView.addTo(superView: view) { make in
            make.center.equalToSuperview()
            make.width.equalTo(contentView.snp.width)
//            make.height.equalTo(120)
        }

        loadingResultView.addTo(superView: loadingView) { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(40)
        }

        loadingIndicatorView.addTo(superView: loadingView) { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(40)
        }
        loadingIndicatorView.startAnimating()

        loadingLabel.numberOfLines = 0
        loadingLabel.addTo(superView: loadingView) { make in
            make.top.equalToSuperview().offset(80)
            make.bottom.equalToSuperview().offset(-20).priority(.medium)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(20)
        }
        loadingLabel.text = "Purchasing..."
        loadingView.layer.opacity = 0
        view.sendSubviewToBack(loadingView)
    }

    private func showPro() {
        isUpgradeScreen = true
        haveCouponButton.isHidden = true
        okButton.isHidden = true
        cancelButton.text(text: "CLOSE")
        cancelButton.textColor(color: ColorUtil.main)
        cancelButton.snp.remakeConstraints { make in
            make.top.equalTo(okButton.snp.bottom).offset(-20)
            make.centerX.equalToSuperview()
            make.width.equalTo(160)
            make.height.equalTo(44)
        }
        cancelButton.setRadius(5)
        cancelButton.setBorder(borderWidth: 1, borderColor: ColorUtil.main)
        topView.backgroundColor(color: ColorUtil.Font.primary)
        if isCouponUser && couponName != "" {
            if let teacherInfo = ListenerService.shared.studioManagerData.teacherInfo {
                if teacherInfo.autoSubscribeType == 0 {
                    // 不是自动订阅
                    infoLabel.text = ""
                    getProDescBasedOnCoupon(teacherInfo)
                        .done { [weak self] desc in
                            self?.infoLabel.text = desc
                        }
                        .catch { [weak self] _ in
                            self?.infoLabel.text("Currently PRO, stop at \(Date(seconds: teacherInfo.nextPaymentTime).toLocalFormat("MMM d, yyyy"))")
                        }
                } else {
                    var text = "Next renewal day is \(Date(seconds: teacherInfo.nextPaymentTime).toLocalFormat("M/dd"))\nCancel anytime."
                    if teacherInfo.memberUpgradePlatform != .ios {
                        text = text.replacingOccurrences(of: "\nCancel anytime.", with: "")
                        let attributeText = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font: FontUtil.medium(size: 13), NSAttributedString.Key.foregroundColor: UIColor.white])
                        infoLabel.attributedText = attributeText
                    } else {
                        let attributeText = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font: FontUtil.medium(size: 13), NSAttributedString.Key.foregroundColor: UIColor.white])
                        attributeText.setAttributes([NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.underlineColor: UIColor.white], range: NSRange(location: 25, length: 6))
                        infoLabel.attributedText = attributeText
                    }
                }
            } else {
                infoLabel.text("Currently PRO,\n\(couponName) coupon applied.")
            }

            infoLabel.numberOfLines = 0
            infoLabel.snp.updateConstraints { make in
                make.left.equalTo(20)
                make.right.equalTo(-20)
            }
            contentView.snp.updateConstraints { make in
                make.height.equalTo(510)
            }
            topView.snp.updateConstraints { make in
                make.height.equalTo(206)
            }
        } else {
            if let teacherInfo = ListenerService.shared.studioManagerData.teacherInfo {
                if teacherInfo.autoSubscribeType == 0 {
                    // 不是自动订阅
                    infoLabel.text = ""
                    getProDescBasedOnCoupon(teacherInfo)
                        .done { [weak self] desc in
                            self?.infoLabel.text = desc
                        }
                        .catch { [weak self] _ in
                            self?.infoLabel.text("Currently PRO, stop at \(Date(seconds: teacherInfo.nextPaymentTime).toLocalFormat("MMM d, yyyy"))")
                        }
                } else {
                    var text = "Next renewal day is \(Date(seconds: teacherInfo.nextPaymentTime).toLocalFormat("M/dd"))\nCancel anytime."
                    if teacherInfo.memberUpgradePlatform != .ios {
                        text = text.replacingOccurrences(of: "\nCancel anytime.", with: "")
                        let attributeText = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font: FontUtil.medium(size: 13), NSAttributedString.Key.foregroundColor: UIColor.white])
                        infoLabel.attributedText = attributeText
                    } else {
                        let attributeText = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font: FontUtil.medium(size: 13), NSAttributedString.Key.foregroundColor: UIColor.white])
                        attributeText.setAttributes([NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.underlineColor: UIColor.white], range: NSRange(location: 25, length: 6))
                        infoLabel.attributedText = attributeText
                    }
                }
            } else {
                infoLabel.text("Currently PRO, stop anytime")
            }
        }
    }

    func show() {
        guard !isPurchasing else { return }
        if isUpgradeScreen {
            redeemCouponView.transform = CGAffineTransform(translationX: contentView.bounds.width, y: 0)
            redeemCouponView.isHidden = false
        } else {
            topView.transform = CGAffineTransform(translationX: -contentView.bounds.width, y: 0)
            topView.isHidden = false
        }
        if teacherMemberLevelId == 2 {
            showPro()
        }

        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
            self.contentView.layer.opacity = 1
//            self.contentView.snp.updateConstraints { make in
//                make.top.equalToSuperview().offset((UIScreen.main.bounds.height - self.contentViewHeight - self.view.safeAreaInsets.bottom) / 2)
//            }
//            self.view.layoutIfNeeded()
        }) { _ in
        }
    }

    func hide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
            self.contentView.layer.opacity = 0
//            self.contentView.snp.updateConstraints { make in
//                make.top.equalToSuperview().offset(-self.contentViewHeight)
//            }
//            self.view.layoutIfNeeded()
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    private func checkCoupon() {
        guard let userId = UserService.user.id() else { return }
        when(fulfilled: CommonsService.shared.checkUserCanUseReferralCode(), DynamicLinkService.shared.checkIfUseCoupon(userId: userId))
            .done { [weak self] referralCodeUse, couponUse in
                guard let self = self else { return }
                self.haveCouponButtonLoadingIndicator.stopAnimating()
                logger.debug("获取到的coupon检测结果: \(referralCodeUse) | \(couponUse)")
//                if referralCodeUse && !couponUse {
//                    self.haveCouponButton.isHidden = false
//                } else {
//                    self.haveCouponButton.isHidden = true
//                }
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                logger.error("检测是否使用过coupon失败: \(error)")
                self.haveCouponButtonLoadingIndicator.stopAnimating()
//                self.haveCouponButton.isHidden = false
            }
    }

    struct SortTimeModule {
        enum Category {
            case coupon
            case referralCode
            case referralCodeByOthers
            case promoCode
        }

        var category: Category
        var datetime: TimeInterval
    }

    private func getProDescBasedOnCoupon(_ teacher: TKTeacher) -> Promise<String> {
        return Promise { resolver in
            when(fulfilled: CommonsService.shared.getCouponUsed(), CommonsService.shared.getReferralCodeUseRecord(), CommonsService.shared.getReferralCodeUseByOthers(), CommonsService.shared.getPromoCodesHistory())
                .done { param, referralRecord, referralOthers, promoCodeHistory in
                    var desc: String = ""
                    let firstPaymentTime = TimeInterval(teacher.firstPaymentTime) ?? 0
                    var modules: [SortTimeModule] = []
                    if let param = param, let record = param.1 {
                        modules.append(.init(category: .coupon, datetime: TimeInterval(record.createTime) ?? 0))
                    }
                    if let promoCodeHistory = promoCodeHistory {
                        modules.append(.init(category: .promoCode, datetime: promoCodeHistory.startTime))
                    }
                    if let referralRecord = referralRecord {
                        modules.append(.init(category: .referralCode, datetime: TimeInterval(referralRecord.datetime) ?? 0))
                    }
                    if !referralOthers.isEmpty {
                        if let record = referralOthers.sorted(by: { (TimeInterval($0.datetime) ?? 0) > TimeInterval($1.datetime) ?? 0 }).first {
                            modules.append(.init(category: .referralCodeByOthers, datetime: TimeInterval(record.datetime) ?? 0))
                        }
                    }
                    if let firstData = modules.sorted(by: { $0.datetime > $1.datetime }).first {
                        switch firstData.category {
                        case .coupon:
                            if let param = param?.0 {
                                desc += "\(param.time)-month-free"
                            }
                        case .referralCode:
                            if referralRecord != nil {
                               desc = "1-month-free"
                           }
                        case .referralCodeByOthers:
                            if referralOthers.count > 0 {
                                let mon = referralOthers.count > ReferralCodeConfig.limitOfMonthOfReferralUser ? ReferralCodeConfig.limitOfMonthOfReferralUser : referralOthers.count
                                desc = "\(mon)-month-free"
                            }
                        case .promoCode:
                            if let promoCodeHistory = promoCodeHistory {
                                desc += "\(Int(promoCodeHistory.duration))-month-free"
                            }
                        }
                    } else {
                        desc = "Currently PRO, stop on \(Date(seconds: teacher.nextPaymentTime).toLocalFormat("M/dd/yyyy"))"
                    }
//                    if let param = param?.0 {
//                        desc += "\(param.time)-month-free"
//                    } else if let promoCodeHistory = promoCodeHistory {
//                        desc += "\(Int(promoCodeHistory.duration))-month-free"
//                    } else if referralRecord != nil {
//                        logger.debug("获取到的当前用户的referral: \(referralRecord?.toJSONString() ?? "")")
//                        desc += "1-month-free"
//                    } else if referralOthers.count > 0 {
//                        let mon = referralOthers.count > ReferralCodeConfig.limitOfMonthOfReferralUser ? ReferralCodeConfig.limitOfMonthOfReferralUser : referralOthers.count
//                        desc = "\(mon)-month-free"
//                    }
                    if desc == "" {
                        desc = "Currently PRO, will stop on \(Date(seconds: teacher.nextPaymentTime).toLocalFormat("M/dd/yyyy"))"
                    } else {
                        var endDate: String = ""
                        if let firstData = modules.sorted(by: { $0.datetime > $1.datetime }).first {
                            switch firstData.category {
                            case .coupon:
                                if let param = param?.0 {
                                    let dateTime = firstPaymentTime + TimeInterval(param.time) * Date.secondOfMonth
                                    endDate = "\nPRO will stop on \(Date(seconds: dateTime).toLocalFormat("M/dd/yyyy")), No charge"
                                }
                            case .referralCode:
                                if let referralRecord = referralRecord {
                                    if let useTime = TimeInterval(referralRecord.datetime) {
                                        let dateTime = useTime + 2626560
                                        endDate = "\nPRO will stop on \(Date(seconds: dateTime).toLocalFormat("M/dd/yyyy")), No charge"
                                    }
                                }
                            case .referralCodeByOthers:
                                if referralOthers.count > 0 {
                                    let datetime = firstPaymentTime + TimeInterval(referralOthers.count) * Date.secondOfMonth
                                    endDate = "\nPRO will stop on \(Date(seconds: datetime).toLocalFormat("M/dd/yyyy")), No charge"
                                }
                            case .promoCode:
                                if let promoCodeHistory = promoCodeHistory {
                                    let dateTime = Date(milliseconds: Int(promoCodeHistory.endTime))
                                    endDate = "\nPRO will stop on \(dateTime.toLocalFormat("M/dd/yyyy")), No charge"
                                }
                            }
                        } else {
                            endDate = "will stop on \(Date(seconds: teacher.nextPaymentTime).toLocalFormat("M/dd/yyyy"))"
                        }
//                        if let param = param?.0 {
//                            let dateTime = firstPaymentTime + TimeInterval(param.time) * Date.secondOfMonth
//                            endDate = "\nPRO will stop on \(Date(seconds: dateTime).toLocalFormat("M/dd/yyyy")), No charge"
//                        } else if let promoCodeHistory = promoCodeHistory {
//                            let dateTime = Date(milliseconds: Int(promoCodeHistory.endTime))
//                            endDate = "\nPRO will stop on \(dateTime.toLocalFormat("M/dd/yyyy")), No charge"
//                        } else if let referralRecord = referralRecord {
//                            if let useTime = TimeInterval(referralRecord.datetime) {
//                                let dateTime = useTime + 2626560
//                                endDate = "\nPRO will stop on \(Date(seconds: dateTime).toLocalFormat("M/dd/yyyy")), No charge"
//                            }
//                        } else if referralOthers.count > 0 {
//                            let datetime = firstPaymentTime + TimeInterval(referralOthers.count) * Date.secondOfMonth
//                            endDate = "\nPRO will stop on \(Date(seconds: datetime).toLocalFormat("M/dd/yyyy")), No charge"
//                        }
                        desc += " coupon was applied.\(endDate)"
                    }
                    resolver.fulfill(desc)
                }
                .catch { error in
                    logger.error("获取coupon使用记录失败: \(error)")
                    resolver.fulfill("Currently PRO, stop at \(Date(seconds: teacher.nextPaymentTime).toLocalFormat("M/dd/yyyy"))")
                }
        }
    }

    private func startUpgrade() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.contentView.transform = .init(scaleX: 0.00001, y: 0.00001)
            self.contentView.layer.opacity = 0
            self.loadingView.layer.opacity = 1
        }, completion: nil)
    }

    private func upgradeDone(isSuccess: Bool, message: String?) {
        var msg: String = ""
        if let message = message {
            msg = message
        } else {
            if isSuccess {
                msg = "Success"
            } else {
                msg = "Failed, please try again later."
            }
        }
        loadingLabel.text = msg
        loadingLabel.layoutIfNeeded()
        let width = loadingLabel.frame.width
        let height = msg.heightWithFont(font: FontUtil.regular(size: 15), fixedWidth: width)
        loadingLabel.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        loadingIndicatorView.stopAnimating()
        loadingResultView.layer.sublayers?.forEach({ item in
            item.removeFromSuperlayer()
        })
        if isSuccess {
            let layer = loadingResultView.getCheckLayer(containerSize: 40, color: ColorUtil.main, animated: true)
            loadingResultView.layer.addSublayer(layer)
        } else {
            TKImageView(image: UIImage(named: "icCloseGray"))
                .addTo(superView: loadingResultView) { make in
                    make.center.size.equalToSuperview()
                }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.hide {
            }
        }
    }

    func upgrade() {
        logger.debug("点击升级")
        isPurchasing = true
        startUpgrade()
//        showFullScreenLoading()
        IAPService.shared.purchase { [weak self] isSuccess, message in
            guard let self = self else { return }
            logger.debug("购买结束,是否成功: \(isSuccess) | 是否有消息: \(message ?? "")")

            if isSuccess {
                OperationQueue.main.addOperation {
                    let data: [String: Any] = ["memberLevelId": 2, "subscribeTime": "\(Date().timestamp)"]
                    self.addSubscribe(
                        UserService.teacher.setData(data: data)
                            .subscribe(onNext: { [weak self] _ in
                                guard let self = self else { return }
                                self.upgradeDone(isSuccess: true, message: message)
                                EventBus.send(EventBus.CHANGE_MEMBER_LEVEL_ID, object: true)

                            }, onError: { [weak self] err in
                                guard let self = self else { return }
                                logger.debug("======\(err)")
                                self.hideFullScreenLoading()
                                self.hide {
                                    logger.debug("upgrade success")
                                }
                            })
                    )
                }
            } else {
                if let message = message, message == "tk:action:relogin" {
                    do {
                        try Auth.auth().signOut()
                        SL.Cache.shared.remove(key: "user:user_id")
                        SL.Cache.shared.remove(key: "user:teacher")
                        self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)

                    } catch {
                        logger.error("sign out error: \(error)")
                        TKToast.show(msg: "Failed to sign out, please try again later.", style: .error)
                    }
                } else {
                    self.upgradeDone(isSuccess: isSuccess, message: message)
                }
            }
        }
    }

    private func toMoreDetail() {
        if let url = URL(string: "https://tunekey.app/pricing") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension ProfileUpgradeDetailViewController {
    override func bindEvent() {
        super.bindEvent()

        infoLabel.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if self.infoLabel.text!.contains("Cancel") {
                self.cancelDetailView.transform = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
                self.cancelDetailView.isHidden = false
                UIView.animate(withDuration: 0.2) {
                    self.cancelDetailView.transform = .identity
                }
            }
        }

        okButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            if self.isUpgradeScreen {
                self.upgrade()
            } else {
                self.redeem()
            }
        }

        cancelButton.onViewTapped { [weak self] _ in
            self?.hide {
                logger.debug("cancel")
            }
        }

        haveCouponButton.onTapped { [weak self] _ in
            self?.isUpgradeScreen = false
            self?.changeScreen()
        }

        noCouponButton.onTapped { [weak self] _ in
            self?.isUpgradeScreen = true
            self?.changeScreen()
        }
    }

    private func changeScreen() {
        contentView.layoutIfNeeded()
        let width = contentView.bounds.width
        if isUpgradeScreen {
            UIView.animate(withDuration: 0.2) {
                self.topView.transform = .identity
                self.redeemCouponView.transform = CGAffineTransform(translationX: width, y: 0)
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.topView.transform = CGAffineTransform(translationX: -width, y: 0)
                self.redeemCouponView.transform = .identity
            } completion: { [weak self] _ in
                self?.codeTextField.becomeFirstResponder()
            }
        }
    }
}

extension ProfileUpgradeDetailViewController {
    private func redeem() {
        guard let text = codeTextField.text, text.count >= 4 else { return }
        showFullScreenLoadingNoAutoHide()
        DynamicLinkService.shared.execTeacherReferral(code: text) { [weak self] error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let error = error {
                logger.error("发生错误: \(error)")
                DispatchQueue.main.async {
                    self.codeTextField.text = ""
                    self.codeTextField.becomeFirstResponder()
                    self.codeTextView.showBorder(color: ColorUtil.red)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.codeTextView.borderWidth = 0
                    }
                }
            } else {
                self.isUpgradeScreen = true
                self.changeScreen()
                self.showPro()
            }
        }
    }

    @objc private func onCouponTextFieldTyped() {
        let text = codeTextField.text!
        codeTextField.text = text.uppercased()
    }
}
