//
//  MaterialsV3FilterViewController.swift
//  TuneKey
//
//  Created by 砚枫张 on 2024/4/22.
//  Copyright © 2024 spelist. All rights reserved.
//

import SnapKit
import UIKit

class MaterialsV3FilterViewController: TKBaseViewController {
    private lazy var navigationBar: TKNormalNavigationBar = .init(frame: .zero, title: "Setting", rightButton: "Reset") {
    }

    var folderId: String

    @Live var filter: MaterialsFilter

    private var defaultApplyTos: [MaterialsFilter.ApplyTo] = [.current, .all]
    private var defaultViewTypes: [MaterialsFilter.ViewType] = [.grid, .list]
    private var defaultSortBys: [MaterialsFilter.SortBy] = [.updateDate, .fileName]
    private var defaultOrderBys: [MaterialsFilter.Order] = [.asc, .desc]
    private var defaultGroupingBys: [MaterialsFilter.GroupingBy] = [.day, .week, .month, .fileType]

    private var couldSave: Bool = false

    init(_ folderId: String) {
        self.folderId = folderId
        if let filter = MaterialsFilter.get(folderId) {
            self.filter = filter
        } else {
            filter = .init(folderId: folderId, applyTo: .all, view: .grid, sortBy: .updateDate, order: .desc, groupingBy: .day)
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        couldSave = true
    }
}

extension MaterialsV3FilterViewController {
    override func initView() {
        super.initView()

        navigationBar.updateLayout(target: self)
        VScrollStack {
            ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                VStack(spacing: 10) {
                    Label("Apply to").textColor(.primary)
                        .font(.title)
                    HStack(alignment: .center, spacing: 10) {
                        for applyTo in defaultApplyTos {
                            ViewBox(top: 15, left: 10, bottom: 15, right: 10) {
                                Label(applyTo.title)
                                    .textColor(.primary)
                                    .font(.content)
                                    .textAlignment(.center)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$filter.addSubscriber { filter in
                                            if filter.applyTo == applyTo {
                                                label.textColor = .clickable
                                            } else {
                                                label.textColor = .primary
                                            }
                                        }
                                    }
                            }
                            .cornerRadius(4.4)
                            .borderColor(.border)
                            .borderWidth(1)
                            .contentHuggingPriority(.defaultHigh, for: .horizontal)
                            .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                let checkView = UIImageView(image: UIImage(named: "checkboxOn"))
                                checkView.addTo(superView: view) { make in
                                    make.centerY.equalTo(view.snp.top)
                                    make.centerX.equalTo(view.snp.right)
                                    make.size.equalTo(16)
                                }
                                self.$filter.addSubscriber { filter in
                                    if filter.applyTo == applyTo {
                                        view.borderColor(.clickable)
                                        checkView.isHidden = false
                                    } else {
                                        view.borderColor(.border)
                                        checkView.isHidden = true
                                    }
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.filter.applyTo = applyTo
                            }
                        }
                        View().placeholderable(for: .horizontal)
                    }
                }
            }
            ViewBox(left: 20) {
                Divider(weight: 1, color: .line)
            }.height(1)

            ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                VStack(spacing: 10) {
                    Label("View").textColor(.primary)
                        .font(.title)
                    HStack(alignment: .center, spacing: 10) {
                        for viewType in defaultViewTypes {
                            ViewBox(top: 15, left: 10, bottom: 15, right: 10) {
                                Label(viewType.title)
                                    .textColor(.primary)
                                    .font(.content)
                                    .textAlignment(.center)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$filter.addSubscriber { filter in
                                            if filter.view == viewType {
                                                label.textColor = .clickable
                                            } else {
                                                label.textColor = .primary
                                            }
                                        }
                                    }
                            }
                            .cornerRadius(4.4)
                            .borderColor(.border)
                            .borderWidth(1)
                            .contentHuggingPriority(.defaultHigh, for: .horizontal)
                            .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                let checkView = UIImageView(image: UIImage(named: "checkboxOn"))
                                checkView.addTo(superView: view) { make in
                                    make.centerY.equalTo(view.snp.top)
                                    make.centerX.equalTo(view.snp.right)
                                    make.size.equalTo(16)
                                }
                                self.$filter.addSubscriber { filter in
                                    if filter.view == viewType {
                                        view.borderColor(.clickable)
                                        checkView.isHidden = false
                                    } else {
                                        view.borderColor(.border)
                                        checkView.isHidden = true
                                    }
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.filter.view = viewType
                            }
                        }
                        View().placeholderable(for: .horizontal)
                    }
                }
            }

            ViewBox(left: 20) {
                Divider(weight: 1, color: .line)
            }.height(1)

            ViewBox(top: 20, left: 20, bottom: 10, right: 20) {
                VStack(spacing: 10) {
                    Label("Sort").textColor(.primary)
                        .font(.title)
                    HStack(alignment: .center, spacing: 10) {
                        for sortBy in defaultSortBys {
                            ViewBox(top: 15, left: 10, bottom: 15, right: 10) {
                                Label(sortBy.title)
                                    .textColor(.primary)
                                    .font(.content)
                                    .textAlignment(.center)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$filter.addSubscriber { filter in
                                            if filter.sortBy == sortBy {
                                                label.textColor = .clickable
                                            } else {
                                                label.textColor = .primary
                                            }
                                        }
                                    }
                            }
                            .cornerRadius(4.4)
                            .borderColor(.border)
                            .borderWidth(1)
                            .contentHuggingPriority(.defaultHigh, for: .horizontal)
                            .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                let checkView = UIImageView(image: UIImage(named: "checkboxOn"))
                                checkView.addTo(superView: view) { make in
                                    make.centerY.equalTo(view.snp.top)
                                    make.centerX.equalTo(view.snp.right)
                                    make.size.equalTo(16)
                                }
                                self.$filter.addSubscriber { filter in
                                    if filter.sortBy == sortBy {
                                        view.borderColor(.clickable)
                                        checkView.isHidden = false
                                    } else {
                                        view.borderColor(.border)
                                        checkView.isHidden = true
                                    }
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.filter.sortBy = sortBy
                            }
                        }

                        View().placeholderable(for: .horizontal)
                    }
                }
            }

            ViewBox(top: 10, left: 20, bottom: 20, right: 20) {
                VStack(spacing: 10) {
                    Label("Order").textColor(.primary)
                        .font(.title)
                    HStack(alignment: .center, spacing: 10) {
                        for orderBy in defaultOrderBys {
                            ViewBox(top: 15, left: 10, bottom: 15, right: 10) {
                                Label(orderBy.title)
                                    .textColor(.primary)
                                    .font(.content)
                                    .textAlignment(.center)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$filter.addSubscriber { filter in
                                            if filter.order == orderBy {
                                                label.textColor = .clickable
                                            } else {
                                                label.textColor = .primary
                                            }
                                        }
                                    }
                            }
                            .cornerRadius(4.4)
                            .borderColor(.border)
                            .borderWidth(1)
                            .contentHuggingPriority(.defaultHigh, for: .horizontal)
                            .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                let checkView = UIImageView(image: UIImage(named: "checkboxOn"))
                                checkView.addTo(superView: view) { make in
                                    make.centerY.equalTo(view.snp.top)
                                    make.centerX.equalTo(view.snp.right)
                                    make.size.equalTo(16)
                                }
                                self.$filter.addSubscriber { filter in
                                    if filter.order == orderBy {
                                        view.borderColor(.clickable)
                                        checkView.isHidden = false
                                    } else {
                                        view.borderColor(.border)
                                        checkView.isHidden = true
                                    }
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.filter.order = orderBy
                            }
                        }

                        View().placeholderable(for: .horizontal)
                    }
                }
            }

            ViewBox(left: 20) {
                Divider(weight: 1, color: .line)
            }.height(1)

            ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        HStack(alignment: .center, spacing: 10) {
                            Label("Grouping").textColor(.primary)
                                .font(.title)

                            Switch().fit()
                                .apply { [weak self] switchView in
                                    guard let self = self else { return }
                                    self.$filter.addSubscriber { filter in
                                        switchView.isOn(filter.isGroupingByEnabled)
                                    }
                                }
                                .onValueChanged { [weak self] isOn in
                                    guard let self = self else { return }
                                    self.filter.isGroupingByEnabled = isOn
                                }
                        }
                        Label("The files can be grouped by subject and the list collapsed or expanded accordingly.")
                            .textColor(.tertiary)
                            .font(.content)
                            .numberOfLines(2)
                    }

                    HStack(alignment: .center, spacing: 10) {
                        for groupingBy in defaultGroupingBys {
                            ViewBox(top: 15, left: 10, bottom: 15, right: 10) {
                                Label(groupingBy.title)
                                    .textColor(.primary)
                                    .font(.content)
                                    .textAlignment(.center)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$filter.addSubscriber { filter in
                                            if filter.groupingBy == groupingBy {
                                                label.textColor = .clickable
                                            } else {
                                                label.textColor = .primary
                                            }
                                        }
                                    }
                            }
                            .cornerRadius(4.4)
                            .borderColor(.border)
                            .borderWidth(1)
                            .contentHuggingPriority(.defaultHigh, for: .horizontal)
                            .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                let checkView = UIImageView(image: UIImage(named: "checkboxOn"))
                                checkView.addTo(superView: view) { make in
                                    make.centerY.equalTo(view.snp.top)
                                    make.centerX.equalTo(view.snp.right)
                                    make.size.equalTo(16)
                                }
                                self.$filter.addSubscriber { filter in
                                    if filter.groupingBy == groupingBy {
                                        view.borderColor(.clickable)
                                        checkView.isHidden = false
                                    } else {
                                        view.borderColor(.border)
                                        checkView.isHidden = true
                                    }
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.filter.groupingBy = groupingBy
                            }
                        }
                        View().placeholderable(for: .horizontal)
                    }
                    .apply { [weak self] view in
                        guard let self = self else { return }
                        self.$filter.addSubscriber { filter in
                            view.isHidden = !filter.isGroupingByEnabled
                        }
                    }
                }
            }
        }
        .cornerRadius(10)
        .maskedCorners([.layerMinXMinYCorner, .layerMaxXMinYCorner])
        .borderColor(.line)
        .borderWidth(1)
        .addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

extension MaterialsV3FilterViewController {
    override func bindEvent() {
        super.bindEvent()
        $filter.addSubscriber { [weak self] filter in
            guard let self = self else { return }
            guard self.couldSave else { return }
            logger.debug("监听到Filter更新：\(filter.toJSONString() ?? "")")
            if filter.applyTo == .current {
                var _filter = filter
                _filter.folderId = self.folderId
                _filter.save()
            } else {
                filter.save()
            }
            EventBus.send(key: .materialsFilterChanged)
        }
    }

    private func onResetButtonTapped() {
        filter = .init(folderId: filter.folderId, applyTo: .all, view: .grid, sortBy: .updateDate, order: .desc, isGroupingByEnabled: false, groupingBy: .day)
    }
}
