//
//  StudioDetailsBalanceAddNewInvoicePaymentLinksViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/7/15.
//  Copyright © 2022 spelist. All rights reserved.
//

import IQKeyboardManagerSwift
import UIKit

class StudioDetailsBalanceAddNewInvoicePaymentLinksViewController: TKBaseViewController {
    @Live var titleAlignment: NSTextAlignment = .left
    @Live var titleString: String = ""
    @Live var leftButtonString: String = "CANCEL"
    @Live var rightButtonString: String = "CREATE"

    @Live var leftButtonStyle: TKBlockButton.Style = .cancel
    @Live var rightButtonStyle: TKBlockButton.Style = .normal
    @Live var placeholder1: String?
    @Live var placeholder2: String?
    @Live var placeholder3: String?
    @Live var keyboardType: UIKeyboardType = .default

    var leftButton: TKBlockButton?
    var rightButton: TKBlockButton?

    var contentViewHeight: CGFloat = 371 
    private var contentView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 15)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

    var textBox1: TKTextBox?
    var textBox2: TKTextBox?
    var textBox3: TKTextBox?

    var texts: [String] = ["", "", ""]

    public var onLeftButtonTapped: (([String]) -> Void)?
    public var onRightButtonTapped: (([String]) -> Void)?

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

extension StudioDetailsBalanceAddNewInvoicePaymentLinksViewController {
    override func initView() {
        super.initView()
        if texts.count != 3 {
            texts = ["", "", ""]
        }
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
                            .textAlignment($titleAlignment)
                            .size(height: 24)
                    }.size(height: 24)
                    VStack(spacing: 20) {
                        TextBox()
                            .placeholder($placeholder1)
                            .keyboardType($keyboardType)
                            .apply { [weak self] _, textBox in
                                guard let self = self else { return }
                                textBox.isShadowShow(false)
                                textBox.onTyped { value in
                                    self.texts[0] = value
                                    if self.texts
                                        .filter({ $0 != "" })
                                        .compactMap({ $0.contains("http") ? $0 : "http://\($0)" })
                                        .allSatisfy({ SL.FormatChecker.shared.isURL($0) }) {
                                        self.rightButton?.enable()
                                    } else {
                                        self.rightButton?.disable()
                                    }
                                }
                                self.textBox1 = textBox
                            }.size(height: 60)
                        TextBox()
                            .placeholder($placeholder2)
                            .keyboardType($keyboardType)
                            .apply { [weak self] _, textBox in
                                guard let self = self else { return }
                                textBox.isShadowShow(false)
                                textBox.onTyped { value in
                                    self.texts[1] = value
                                    if self.texts
                                        .filter({ $0 != "" })
                                        .compactMap({ $0.contains("http") ? $0 : "http://\($0)" })
                                        .allSatisfy({ SL.FormatChecker.shared.isURL($0) }) {
                                        self.rightButton?.enable()
                                    } else {
                                        self.rightButton?.disable()
                                    }
                                }
                                self.textBox2 = textBox
                            }.size(height: 60)
                        TextBox()
                            .placeholder($placeholder3)
                            .keyboardType($keyboardType)
                            .apply { [weak self] _, textBox in
                                guard let self = self else { return }
                                textBox.isShadowShow(false)
                                textBox.onTyped { value in
                                    self.texts[2] = value
                                    if self.texts
                                        .filter({ $0 != "" })
                                        .compactMap({ $0.contains("http") ? $0 : "http://\($0)" })
                                        .allSatisfy({ SL.FormatChecker.shared.isURL($0) }) {
                                        self.rightButton?.enable()
                                    } else {
                                        self.rightButton?.disable()
                                    }
                                }
                                self.textBox3 = textBox
                            }.size(height: 60)
                    }
                    HStack(distribution: .fillEqually, spacing: 10) {
                        BlockButton()
                            .set(title: $leftButtonString, style: $leftButtonStyle)
                            .onBlockButtonTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.onLeftButtonTapped?(self.texts)
                            }
                            .size(height: 50)
                            .apply { [weak self] button in
                                self?.leftButton = button
                            }
                        BlockButton()
                            .set(title: $rightButtonString, style: $rightButtonStyle)
                            .onBlockButtonTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.onRightButtonTapped?(self.texts)
                            }
                            .size(height: 50)
                            .apply { [weak self] button in
                                self?.rightButton = button
                            }
                    }.size(height: 50)
                }
//                if UiUtil.safeAreaBottom() != 0 {
//                    Spacer(spacing: UiUtil.safeAreaBottom())
//                }
            }
        }
        .addTo(superView: contentView) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}

extension StudioDetailsBalanceAddNewInvoicePaymentLinksViewController {
    private func show() {
        guard !isShow else { return }
        isShow = true
        if texts.count == 3 {
            textBox1?.value(texts[0])
            textBox2?.value(texts[1])
            textBox3?.value(texts[2])
        }
        if texts
            .filter({ $0 != "" })
            .compactMap({ $0.contains("http") ? $0 : "http://\($0)" })
            .allSatisfy({ SL.FormatChecker.shared.isURL($0) }) {
            rightButton?.enable()
        } else {
            rightButton?.disable()
        }
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.textBox1?.focus()
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
