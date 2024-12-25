//
//  StudentActivityController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/8.
//  Copyright © 2019 spelist. All rights reserved.
//

import UIKit

class StudentActivityController: TKBaseViewController {
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    var role: TKUserRole!
    var homeworkData: [TKAssignment] = []
    var selfStudyData: [TKAssignment] = []
    private lazy var titles = ["Self Study", "Homework"]
    private lazy var titleMap = [String: TKBaseViewController]()
    private lazy var pageViewManager: PageViewManager = {
        // 创建DNSPageStyle，设置样式
        let style = PageStyle()
        style.isShowBottomLine = true
        style.isTitleViewScrollEnabled = false
        style.titleViewBackgroundColor = UIColor.clear
        style.titleColor = ColorUtil.Font.primary
        style.titleSelectedColor = ColorUtil.main
        style.bottomLineColor = ColorUtil.main
        style.bottomLineWidth = 17
        style.titleFont = FontUtil.bold(size: 15)
        for item in titles.enumerated() {
            if item.offset == 0 {
                let controller = ActivityPractiveController()
                controller.data = selfStudyData
                titleMap[item.element] = controller
                addChild(controller)
            } else {
                let controller = ActivityHomeworkController()
                controller.homeworkData = self.homeworkData
                titleMap[item.element] = controller
                addChild(controller)
            }
        }
        return PageViewManager(style: style, titles: titles, childViewControllers: children)
    }()

    init(role: TKUserRole) {
        super.init(nibName: nil, bundle: nil)
        self.role = role
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View

extension StudentActivityController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        let title = (role == .student) ? "Preparation" : "Practice"
        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: title, target: self)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initContentView()
        let gestureForEdge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(_handleScreenEdgePan(_:)))
        gestureForEdge.edges = .left
        gestureForEdge.delegate = self
        view.addGestureRecognizer(gestureForEdge)
    }

    func initContentView() {
        let titleView = pageViewManager.titleView
        mainView.addSubviews(titleView)
        titleView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
            make.width.equalTo(247)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
        }
        let contentView = pageViewManager.contentView
        mainView.addSubview(pageViewManager.contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(2)
            make.right.bottom.equalToSuperview()
        }
    }
    @objc private func _handleScreenEdgePan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            dismiss(animated: true, completion: nil)
        case .changed:
            let progress = sender.translation(in: nil).x / view.bounds.width
            Hero.shared.update(progress)
        default:
            if (sender.translation(in: nil).x + sender.velocity(in: nil).x) / view.bounds.width > 0.5 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }
}

extension StudentActivityController {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Data

extension StudentActivityController {
    override func initData() {
    }
}

// MARK: - Action

extension StudentActivityController {
}
