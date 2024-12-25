//
//  StudentDetailsBalanceAddNewQuantityUpdateViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/3/4.
//  Copyright © 2022 spelist. All rights reserved.
//

import SnapKit
import UIKit

class StudentDetailsBalanceAddNewQuantityUpdateViewController: TKBaseViewController {
    private let contentViewHeight: CGFloat = 200 + UiUtil.safeAreaBottom()
    private var contentView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 15)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

    var quantity: Int = 0
    private var textBox: TKTextBox?

    var onCancelTapped: (() -> Void)?
    var onConfirmTapped: ((Int) -> Void)?

    private var isShow: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
}

extension StudentDetailsBalanceAddNewQuantityUpdateViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.addTo(superView: view) { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(contentViewHeight)
        }
        contentView.transform = CGAffineTransform(translationX: 0, y: contentViewHeight)

        ViewBox(paddings: UIEdgeInsets(top: 17, left: 20, bottom: 20, right: 20)) {
            VStack(distribution: .equalSpacing, spacing: 20) {
                Label("Lesson & Quantity")
                    .textColor(ColorUtil.Font.fourth)
                    .font(FontUtil.bold(size: 15))
                    .size(height: 24)
                    .textAlignment(.center)
                TextBox().apply { [weak self] _, textBox in
                    guard let self = self else { return }
                    textBox.placeholder(nil)
                        .isShadowShow(false)
                        .keyboardType(.numberPad)
                        .inputType(.number)
                        .value(self.quantity.description)
                        .onTyped { value in
                            if value == "" {
                                self.quantity = 0
                            } else {
                                if let v = Int(value) {
                                    self.quantity = v
                                } else {
                                    self.quantity = 0
                                }
                            }
                        }
                    self.textBox = textBox
                }.size(height: 60)
                HStack(distribution: .fillEqually, spacing: 10) {
                    BlockButton()
                        .set(title: "CANCEL", style: .cancel)
                        .size(height: 50)
                        .onTapped { [weak self] _ in
                            guard let self = self else { return }
                            self.onCancelTapped?()
                        }
                    BlockButton()
                        .set(title: "CONFIRM", style: .normal)
                        .size(height: 50)
                        .onTapped { [weak self] _ in
                            guard let self = self else { return }
                            self.onConfirmTapped?(self.quantity)
                        }
                }.size(height: 50)
                if UiUtil.safeAreaBottom() != 0 {
                    Spacer(spacing: 1)
                }
            }
        }
        .addTo(superView: contentView) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}

extension StudentDetailsBalanceAddNewQuantityUpdateViewController {
    private func show() {
        guard !isShow else { return }
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        } completion: { [weak self] _ in
            self?.textBox?.focus()
        }
    }

    func hide() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: self.contentViewHeight)
        } completion: { [weak self] _ in
            self?.dismiss(animated: false, completion: nil)
        }
    }
}
