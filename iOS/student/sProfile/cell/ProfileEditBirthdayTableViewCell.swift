//
//  ProfileEditBirthdayTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2023/1/11.
//  Copyright © 2023 spelist. All rights reserved.
//

import UIKit

class ProfileEditBirthdayTableViewCell: UITableViewCell {
    static let id: String = String(describing: ProfileEditBirthdayTableViewCell.self)
    var onBirthdayTapped: (() -> Void)?

    @Live var isViewAppeared: Bool = false
    @Live private var placeholder: String? = "Birthday (optional)"
    @Live var birthday: TimeInterval = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileEditBirthdayTableViewCell {
    private func initViews() {
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            ViewBox(paddings: .zero) {
                TextBox().placeholder($placeholder)
                    .withViewDidAppear($isViewAppeared)
                    .apply { [weak self] _, textBox in
                        guard let self = self else { return }
                        textBox.setEnabled(enabled: false)
                        self.$birthday.addSubscriber { birthday in
                            if birthday == 0 {
                                textBox.value("")
                            } else {
                                textBox.value(Date(seconds: birthday).toLocalFormat("M/d/yyyy"))
                            }
                        }
                    }
            }
            .cardStyle()
            .borderWidth(0)
            .apply { view in
                View().onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    self.onBirthdayTapped?()
                }
                .addTo(superView: view) { make in
                    make.edges.equalToSuperview()
                }
            }
        }
        .backgroundColor(ColorUtil.backgroundColor)
        .addTo(superView: contentView) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}
