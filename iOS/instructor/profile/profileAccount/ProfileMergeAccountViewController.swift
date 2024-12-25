//
//  ProfileMergeAccountViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/10/10.
//  Copyright © 2019年 spelist. All rights reserved.
//

import FirebaseAuth
import UIKit

class ProfileMergeAccountViewController: TKBaseViewController {
    private var navigationBar: TKNormalNavigationBar!
    private var tableView: UITableView!

    private var account: String = "" {
        didSet {
            logger.debug("Current user account: \(account)")
        }
    }
}

extension ProfileMergeAccountViewController {
    override func initData() {
        if let user = Auth.auth().currentUser {
            account = user.email!
            tableView.reloadData()
        }
    }
}

extension ProfileMergeAccountViewController {
    override func initView() {
        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Merge Account",target:self)
        navigationBar.updateLayout(target: self)

        tableView = UITableView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 10
        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = UIView()
        tableView.backgroundView?.backgroundColor = ColorUtil.backgroundColor
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.slTableView.setup(target: self, cellClasses: ProfileMergeAccountTableViewCell.self)
        addSubview(view: tableView) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }
}

extension ProfileMergeAccountViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TKScreen.width > TKScreen.height ? TKScreen.width : TKScreen.height
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileMergeAccountTableViewCell.self), for: indexPath) as! ProfileMergeAccountTableViewCell
        cell.loadData(account: account)
        return cell
    }
}
