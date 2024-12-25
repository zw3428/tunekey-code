//
//  StudentDetailsBalanceDueDateUpdateViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/3/7.
//  Copyright © 2022 spelist. All rights reserved.
//

import SnapKit
import UIKit

class StudentDetailsBalanceDueDateUpdateViewController: TKBaseViewController {
    private var contentView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 15)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

    private let contentViewHeight: CGFloat = 197 + UiUtil.safeAreaBottom()
    private var textBox: TKTextBox?

    var day: Int = 0

    var onCancelTapped: (() -> Void)?
    var onConfirmTapped: ((Int) -> Void)?

    private var isShow: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
}

extension StudentDetailsBalanceDueDateUpdateViewController {
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
                        Label("Due day")
                            .textColor(ColorUtil.Font.fourth)
                            .font(FontUtil.regular(size: 15))
                            .textAlignment(.center)
                            .size(height: 24)
                    }.size(height: 24)
                    HStack {
                        TextBox()
                            .apply { [weak self] _, textBox in
                                guard let self = self else { return }
                                textBox.isShadowShow(false)
                                    .placeholder(nil)
                                    .keyboardType(.numberPad)
                                    .value(self.day.description)
                                textBox.onTyped { value in
                                    self.day = Int(value) ?? 0
                                }
                                self.textBox = textBox
                            }.size(width: 100, height: 60)
                        Spacer(spacing: 10)
                        Label("days after invoice day")
                            .textColor(ColorUtil.Font.third)
                            .font(FontUtil.bold(size: 18))
                    }
                    HStack(distribution: .fillEqually, spacing: 10) {
                        BlockButton()
                            .set(title: "CANCEL", style: .cancel)
                            .onBlockButtonTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.onCancelTapped?()
                            }
                            .size(height: 50)
                        BlockButton()
                            .set(title: "CONFIRM", style: .normal)
                            .onBlockButtonTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.onConfirmTapped?(self.day)
                            }
                            .size(height: 50)
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

extension StudentDetailsBalanceDueDateUpdateViewController {
    private func show() {
        guard !isShow else { return }
        isShow = true
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
        } completion: { _ in
            self.dismiss(animated: false, completion: nil)
        }
    }
}
