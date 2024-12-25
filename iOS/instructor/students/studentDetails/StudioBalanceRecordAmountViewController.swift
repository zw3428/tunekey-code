//
//  StudioBalanceRecordAmountViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/3/20.
//  Copyright © 2022 spelist. All rights reserved.
//

import IQKeyboardManagerSwift
import UIKit

extension StudioBalanceRecordAmountViewController {
    func pop(from viewController: UIViewController, completion: (() -> Void)? = nil) {
        modalPresentationStyle = .custom
        viewController.present(self, animated: false, completion: completion)
    }
}

class StudioBalanceRecordAmountViewController: TKBaseViewController {
    @Live var titleString: String = ""
    @Live var placeholder: String?
    @Live var keyboardType: UIKeyboardType = .decimalPad
    @Live var leftButtonString: String = "CANCEL"
    @Live var rightButtonString: String = "RECORD"
    @Live var leftButtonStyle: TKBlockButton.Style = .cancel
    @Live var rightButtonStyle: TKBlockButton.Style = .normal
    var onTextChanged: ((_ value: String, _ leftButton: TKBlockButton, _ rightButton: TKBlockButton) -> Void)?

    var leftButton: TKBlockButton?
    var rightButton: TKBlockButton?
    var paymentMethodsTypeSelectorGroup: TKRadioGroup = TKRadioGroup(["CASH", "CHECK", "E-Transfer"])

    var contentViewHeight: CGFloat = 240 + UiUtil.safeAreaBottom()
    private var contentView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 15)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
    var textBox: TKTextBox?

    var text: String = ""
    public var onLeftButtonTapped: ((String, TKTransaction.PaymentMethod) -> Void)?
    public var onRightButtonTapped: ((String, TKTransaction.PaymentMethod) -> Void)?
    var paymentMethod: TKTransaction.PaymentMethod = .cash

    private var isShow: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        IQKeyboardManager.shared.enable = false
        show()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        IQKeyboardManager.shared.enable = true
    }

    override func onKeyboardShow(_ keyboardHeight: CGFloat) {
        super.onKeyboardShow(keyboardHeight)
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.contentView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
        }
    }

    override func onKeyboardHide(_ keyboardHeight: CGFloat) {
        super.onKeyboardHide(keyboardHeight)
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.contentView.transform = .identity
        }
    }
}

extension StudioBalanceRecordAmountViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.addTo(superView: view) { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(contentViewHeight)
        }
        contentView.transform = CGAffineTransform(translationX: 0, y: contentViewHeight)

        ViewBox(paddings: UIEdgeInsets(top: 17, left: 20, bottom: 20, right: 20)) {
            VStack {
                VStack(spacing: 20) {
                    HStack {
                        Label($titleString)
                            .textColor(ColorUtil.Font.fourth)
                            .font(FontUtil.regular(size: 15))
                            .textAlignment(.center)
                            .size(height: 24)
                    }.size(height: 24)
                    VStack {
                        TextBox()
                            .placeholder($placeholder)
                            .keyboardType($keyboardType)
                            .apply { [weak self] _, textBox in
                                guard let self = self else { return }
                                textBox.isShadowShow(false)
                                textBox.onTyped { value in
                                    self.text = value
                                    if let leftButton = self.leftButton, let rightButton = self.rightButton {
                                        self.onTextChanged?(value, leftButton, rightButton)
                                    }
                                }
                                self.textBox = textBox
                            }.size(height: 60)
                        Spacer(spacing: 10)
                        View().apply { [weak self] view in
                            guard let self = self else { return }
                            self.paymentMethodsTypeSelectorGroup.addTo(superView: view) { make in
                                make.top.bottom.equalToSuperview()
                                make.right.equalToSuperview()
                            }
                            self.paymentMethodsTypeSelectorGroup.onItemSelected { index in
                                switch index {
                                case 0:
                                    self.paymentMethod = .cash
                                case 1:
                                    self.paymentMethod = .checkbook
                                case 2:
                                    self.paymentMethod = .eTransfer
                                default:
                                    break
                                }
                            }
                        }.size(height: 22)
                    }
                    HStack(distribution: .fillEqually, spacing: 10) {
                        BlockButton()
                            .set(title: $leftButtonString, style: $leftButtonStyle)
                            .onBlockButtonTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.onLeftButtonTapped?(self.text, self.paymentMethod)
                            }
                            .size(height: 50)
                            .apply { [weak self] button in
                                self?.leftButton = button
                            }
                        BlockButton()
                            .set(title: $rightButtonString, style: $rightButtonStyle)
                            .onBlockButtonTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.onRightButtonTapped?(self.text, self.paymentMethod)
                            }
                            .size(height: 50)
                            .apply { [weak self] button in
                                self?.rightButton = button
                            }
                    }.size(height: 50)
                }
                if UiUtil.safeAreaBottom() != 0 {
                    Spacer(spacing: UiUtil.safeAreaBottom())
                }
            }
        }
        .addTo(superView: contentView) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}

extension StudioBalanceRecordAmountViewController {
    private func show() {
        guard !isShow else { return }
        isShow = true
        switch paymentMethod {
        case .cash:
            paymentMethodsTypeSelectorGroup.select(at: 0)
        case .checkbook:
            paymentMethodsTypeSelectorGroup.select(at: 1)
        default:
            paymentMethod = .cash
            paymentMethodsTypeSelectorGroup.select(at: 0)
        }
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            if self.text != "" {
                self.textBox?.value(self.text)
                if let amount = Decimal(string: self.text)?.doubleValue.roundTo(places: 0), amount > 0 {
                    self.rightButton?.enable()
                }
            }
            self.textBox?.focus()
        }
    }

    func hide() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: self.contentViewHeight)
        } completion: { _ in
            self.dismiss(animated: false, completion: nil)
        }
    }
}
