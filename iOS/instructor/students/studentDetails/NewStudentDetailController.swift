//
//  NewStudentDetailController.swift
//  TuneKey
//
//  Created by wht on 2020/6/29.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class NewStudentDetailController: TKBaseViewController {
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    var studentData: TKStudent!
    private var contentView: TKView!
    private var tableView: UITableView!
    var isEditStudentInfo = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private lazy var titles = ["Profile", "Activities"]

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
        style.isContentScrollEnabled = true
        style.titleFont = FontUtil.bold(size: 15)

        for item in titles.enumerated() {
            switch item.offset {
            case 0:
                let controller = StudentProfileController()
                controller.studentData = studentData
                controller.isEditStudentInfo = isEditStudentInfo
                addChild(controller)
            case 1:
                let controller = StudentDetailsViewController()
                controller.isShowNavigationBar = false
                controller.studentData = studentData
                controller.isEditStudentInfo = isEditStudentInfo

                addChild(controller)

            default:
                let controller = StudentDetailsViewController()
                controller.isShowNavigationBar = false

                controller.studentData = studentData

                addChild(controller)
            }
        }
        return PageViewManager(style: style, titles: titles, childViewControllers: children)
    }()
}

// MARK: - View

extension NewStudentDetailController {
    override func initView() {
        enablePanToDismiss()
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "Student Detail", target: self)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initPageView()
    }

    func initPageView() {
        contentView = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
        mainView.addSubview(view: contentView) { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
            make.right.equalToSuperview()
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        let titleView = pageViewManager.titleView
        contentView.addSubview(view: titleView) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(50)
            make.right.equalToSuperview().offset(-50)
            make.height.equalTo(24)
        }

        contentView.addSubview(view: pageViewManager.contentView) { make in
            make.top.equalTo(titleView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
        pageViewManager.contentView.scrollDelegate = self
        let gestureForEdge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(_handleScreenEdgePan(_:)))
        gestureForEdge.edges = .left
        gestureForEdge.delegate = self
        pageViewManager.contentView.addGestureRecognizer(gestureForEdge)
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


extension NewStudentDetailController: PageContentViewScrollDelegate {
    func contentView(_ contentView: PageContentView, didSelectedAt index: Int) {
        logger.debug("选择index: \(index)")
    }

    func contentView(_ contentView: PageContentView, scrollingWith sourceIndex: Int, targetIndex: Int, progress: CGFloat) {
        logger.debug("progress: \(progress)")
    }

    func contentView(_ contentView: PageContentView, didScrollWith contentOffset: CGPoint) {
        logger.debug("content offset: \(contentOffset)")
    }
}

// MARK: - Data

extension NewStudentDetailController {
    override func initData() {
    }
}

// MARK: - TableView

extension NewStudentDetailController {
}

// MARK: - Action

extension NewStudentDetailController {
}
