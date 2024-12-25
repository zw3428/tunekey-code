//
//  ProfileStudioEventsTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2023/1/17.
//  Copyright © 2023 spelist. All rights reserved.
//

import Hero
import SnapKit
import UIKit

class ProfileStudioEventsTableViewCell: UITableViewCell {
    static let id: String = String(describing: ProfileStudioEventsTableViewCell.self)

    var tableView: UITableView?

    var onAddEventTapped: (() -> Void)?
    var onTitleViewTapped: (() -> Void)?
    var onEventTapped: ((StudioEvent) -> Void)?

    @Live var events: [StudioEvent] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileStudioEventsTableViewCell {
    private func initViews() {
        $events.subscribersWillUpdate = { [weak self] _ in
            self?.tableView?.beginUpdates()
        }
        $events.subscribersDidUpdate = { [weak self] _ in
            self?.tableView?.endUpdates()
        }
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            ViewBox(paddings: UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)) {
                VStack {
                    ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)) {
                        HStack(alignment: .center) {
                            Label("Studio Events").textColor(ColorUtil.Font.primary)
                                .font(FontUtil.regular(size: 13))
                            ImageView(image: UIImage(named: "arrowRight"))
                                .size(width: 22, height: 22)
                        }
                    }
                    .contentHuggingPriority(.defaultHigh, for: .vertical)
                    .contentCompressionResistancePriority(.defaultHigh, for: .vertical)
                    .onViewTapped { [weak self] _ in
                        guard let self = self else { return }
                        self.onTitleViewTapped?()
                    }
                    VList(withData: $events) { events in
                        for (index, event) in events.enumerated() {
                            VStack {
                                ViewBox(top: 20, left: 20, bottom: 10, right: 20) {
                                    HStack(spacing: 10) {
                                        VStack {
                                            // date
                                            VStack(alignment: .center) {
                                                Label().font(.bold(40))
                                                    .textColor(.clickable)
                                                    .textAlignment(.center)
                                                    .apply { label in
                                                        label.text(event.startTime.toLocalFormat("dd"))
                                                    }
                                                Label().font(.bold(20))
                                                    .textColor(.clickable)
                                                    .textAlignment(.center)
                                                    .apply { label in
                                                        label.text(event.startTime.toLocalFormat("MMM"))
                                                    }
                                            }
                                            .size(width: 60, height: 60)
                                            View().placeholderable(for: .vertical)
                                        }

                                        // content
                                        VStack(spacing: 10) {
                                            HStack(alignment: .center, spacing: 20) {
                                                Label().textColor(.primary)
                                                    .font(FontUtil.bold(size: 18))
                                                    .numberOfLines(0)
                                                    .minHeight(20)
                                                    .apply { label in
                                                        label.text(event.title)
                                                    }
                                                ImageView(image: UIImage(named: "arrowRight"))
                                                    .size(width: 22, height: 22)
                                            }

                                            Label().textColor(.tertiary)
                                                .font(FontUtil.regular(size: 13))
                                                .numberOfLines(2)
                                                .minHeight(15)
                                                .apply { label in
                                                    let startTime = event.startTime
                                                    let startDateTime = Date(seconds: startTime)
                                                    let endDateTime = Date(seconds: event.endTime)
                                                    let startDateInRegion = DateInRegion(startDateTime, region: .current)
                                                    let endDateInRegion = DateInRegion(endDateTime, region: .current)
                                                    let time: String
                                                    // 必须按照从小到大的顺序
                                                    if startDateInRegion.compare(.isSameDay(endDateInRegion)) {
                                                        // 同一天
                                                        time = "\(startDateTime.toLocalFormat("h:mm a")) - \(endDateTime.toLocalFormat("h:mm a, M/d/yyyy"))"
                                                    } else {
                                                        if startDateInRegion.compare(.isSameYear(endDateInRegion)) {
                                                            // 同一个年
                                                            time = "\(startDateTime.toLocalFormat("h:mm a, M/d")) - \(endDateTime.toLocalFormat("h:mm a, M/d/yyyy"))"
                                                        } else {
                                                            // 不同年
                                                            time = "\(startDateTime.toLocalFormat("h:mm a, M/d/yyyy")) - \(endDateTime.toLocalFormat("h:mm a, M/d/yyyy"))"
                                                        }
                                                    }
                                                    label.text(time)
                                                }

                                            Label().textColor(.tertiary)
                                                .font(FontUtil.regular(size: 13))
                                                .numberOfLines(3)
                                                .contentCompressionResistancePriority(.defaultHigh, for: .vertical)
                                                .apply { [weak self] label in
                                                    guard let self = self else { return }
                                                    self.tableView?.beginUpdates()
                                                    label.text(event.description)
                                                    self.tableView?.endUpdates()
                                                }
                                            View().backgroundColor(.clear)
                                                .contentHuggingPriority(.defaultLow, for: .vertical)
                                                .contentCompressionResistancePriority(.defaultLow, for: .vertical)
                                        }
                                    }
                                }
                                .onViewTapped { [weak self] _ in
                                    self?.onEventTapped?(event)
                                }
                                if index < events.count - 1 {
                                    ViewBox(left: 20, right: 20) {
                                        Divider(weight: 1, color: ColorUtil.dividingLine)
                                    }.height(1)
                                }
                            }
                        }
                    }
                }
            }
            .cardStyle()
        }
        .backgroundColor(ColorUtil.backgroundColor)
        .addTo(superView: contentView) { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().priority(.medium)
        }
    }
}
