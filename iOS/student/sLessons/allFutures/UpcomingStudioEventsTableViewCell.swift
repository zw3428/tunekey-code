//
//  UpcomingStudioEventsTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2023/1/19.
//  Copyright © 2023 spelist. All rights reserved.
//

import SnapKit
import UIKit

class UpcomingStudioEventsTableViewCell: UITableViewCell {
    static let id: String = String(describing: UpcomingStudioEventsTableViewCell.self)
    
    var tableView: UITableView?
    
    @Live var event: StudioEvent?
    @Live var backColor: UIColor = .white

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UpcomingStudioEventsTableViewCell {
    private func initView() {
        ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 10, right: 20)) {
            ViewBox(paddings: .zero) {
                StudioEventsItemView(width: UIScreen.main.bounds.width - 40)
                    .paddings(UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
                    .event($event)
                    .backColor($backColor)
                    .apply { [weak self] view in
                        guard let self = self else { return }
                        view.beforeHeightChanged = {
                            self.tableView?.beginUpdates()
                        }
                        view.afterHeightChanged = {
                            self.tableView?.endUpdates()
                        }
                        view.reloadData()
                    }
            }.apply { view in
                _ = view.showShadow()
                    .borderWidth(1)
                    .borderColor($backColor)
//                    .backgroundColor(.white)
                    .cornerRadius(5)
            }
        }.addTo(superView: contentView) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}
