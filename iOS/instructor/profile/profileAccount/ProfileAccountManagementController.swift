//
//  ProfileAccountManagementController.swift
//  TuneKey
//
//  Created by WHT on 2020/3/8.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class ProfileAccountManagementController: TKBaseViewController {
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - View

extension ProfileAccountManagementController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "", target: self)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
    }
}

// MARK: - Data

extension ProfileAccountManagementController {
    override func initData() {
    }
}

// MARK: - TableView

extension ProfileAccountManagementController {
}

// MARK: - Action

extension ProfileAccountManagementController {
}
