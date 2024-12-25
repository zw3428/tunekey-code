//
//  ProfileAboutUsViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/10/9.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileAboutUsViewController: TKBaseViewController {
    private var backButton: TKButton!

    private lazy var titles = ["Terms", "Privacy"]
    private lazy var titleMap: [String: TKBaseViewController] = [:]
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
            switch item.offset {
            case 0:
                let controller = ProfileAboutUsTermsOfUseViewController()
                controller.pos = 0
                titleMap[item.element] = controller
                addChild(controller)
            default:
                let controller = ProfileAboutUsTermsOfUseViewController()
                controller.pos = 1
                titleMap[item.element] = controller
                addChild(controller)
//                let controller = ProfileAboutUsPrivacyPolicyViewController()
//                titleMap[item.element] = controller
//                addChild(controller)
            }
        }
        return PageViewManager(style: style, titles: titles, childViewControllers: children)
    }()
}

extension ProfileAboutUsViewController {
    override func initView() {
        backButton = TKButton.create()
            .setImage(name: "back", size: CGSize(width: 22, height: 22))
            .addTo(superView: view, withConstraints: { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(11)
                make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left).offset(12)
                make.size.equalTo(30)
            })

        let titleView = pageViewManager.titleView
        view.addSubview(view: titleView) { make in
            make.centerY.equalTo(self.backButton.snp.centerY)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.6)
            make.height.equalTo(24)
        }
        view.addSubview(view: pageViewManager.contentView) { make in
            make.top.equalTo(titleView.snp.bottom).offset(10)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left).offset(2)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        
        if hero.isEnabled {
            let gestureForEdge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(_handleScreenEdgePan(_:)))
            gestureForEdge.edges = .left
            gestureForEdge.delegate = self
            view.addGestureRecognizer(gestureForEdge)
        }
    }

    override func bindEvent() {
        backButton.onTapped { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
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

