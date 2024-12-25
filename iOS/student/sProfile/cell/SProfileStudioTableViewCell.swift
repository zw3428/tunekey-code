//
//  SProfileStudioTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2022/5/25.
//  Copyright © 2022 spelist. All rights reserved.
//

import UIKit

class SProfileStudioTableViewCell: TKBaseTableViewCell {
    static let id: String = String(describing: SProfileStudioTableViewCell.self)
    var tableView: UITableView?
    @Live var studios: [TKStudio] = []
    @Live var isLoading: Bool = true
    var onAddButtonTapped: (() -> Void)?
}

extension SProfileStudioTableViewCell {
    private func refreshUI(_ closure: @escaping () -> Void) {
        updateUI { [weak self] in
            guard let self = self else { return }
            self.tableView?.beginUpdates()
            closure()
            self.tableView?.endUpdates()
        }
    }
}

extension SProfileStudioTableViewCell {
    override func initViews() {
        super.initViews()
        ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)) {
            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 10, right: 20)) {
                VStack {
                    HStack(alignment: .center) {
                        Label("Studio info").textColor(ColorUtil.Font.primary).font(.regular(size: 13)).height(20)
                        LoadingView(CGSize(width: 22, height: 22)).size(width: 22, height: 22).isLoading($isLoading)
                        Button().image(UIImage(named: "icAddPrimary"), for: .normal)
                            .size(width: 22, height: 22)
                            .apply { [weak self] button in
                                guard let self = self else { return }
                                self.$isLoading.addSubscriber { isLoading in
                                    if isLoading {
                                        button.isHidden = true
                                    } else {
                                        if self.studios.isEmpty {
                                            button.isHidden = false
                                        } else {
                                            button.isHidden = true
                                        }
                                    }
                                }
                                
                                self.$studios.addSubscriber { studios in
                                    if self.isLoading {
                                        button.isHidden = true
                                    } else {
                                        if studios.isEmpty {
                                            button.isHidden = false
                                        } else {
                                            button.isHidden = true
                                        }
                                    }
                                }
                            }
                            .onTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.onAddButtonTapped?()
                            }
                    }
                    Spacer(spacing: 10).apply { [weak self] view in
                        guard let self = self else { return }
                        self.$studios.addSubscriber { studios in
                            self.refreshUI {
                                if studios.isEmpty {
                                    view.isHidden = false
                                } else {
                                    view.isHidden = true
                                }
                            }
                        }
                    }
                    VList(withData: $studios) { studios in
                        for (index, studio) in studios.enumerated() {
                            ViewBox(paddings: UIEdgeInsets(top: 17, left: 0, bottom: 17, right: 0)) {
                                HStack(alignment: .center, spacing: 20) {
                                    AvatarView(size: 60).size(width: 60, height: 60).loadAvatar(withStudioId: studio.id, name: studio.name)
                                    VStack(spacing: 8) {
                                        // studio name
                                        Label().text(studio.name).font(.bold(18)).textColor(ColorUtil.Font.third).height(20)
                                        Label().font(.regular(size: 15)).textColor(ColorUtil.Font.primary).apply {label in
                                            if studio.addressDetail.isValid {
                                                label.text(studio.addressDetail.addressString)
                                                label.isHidden = false
                                            } else {
                                                label.isHidden = true
                                            }
                                        }
                                        Label().font(.regular(size: 15)).textColor(ColorUtil.Font.primary).apply { label in
                                            if studio.email != "" {
                                                label.text(studio.email)
                                            } else {
                                                label.text("")
                                            }
                                        }
                                    }
                                }
                            }
                            if index < studios.count - 1 {
                                ViewBox {
                                    Divider(weight: 1, color: ColorUtil.dividingLine)
                                }.height(1)
                            }
                        }
                    }
//                    .apply { [weak self] view in
//                        guard let self = self else { return }
//                        self.$studio.addSubscriber { studio in
//                            self.refreshUI {
//                                if studio == nil {
//                                    view.isHidden = true
//                                } else {
//                                    view.isHidden = false
//                                }
//                            }
//                        }
//                    }
                }
            }.cardStyle()
        }.fill(in: contentView)
//        $studios.addSubscriber { [weak self] studio in
//            guard let self = self else { return }
//            if let studio = studio {
//                self.avatarModel = .init(id: studio.id, name: studio.name)
//            } else {
//                self.avatarModel = .init(id: "", name: "")
//            }
//        }
    }
}
