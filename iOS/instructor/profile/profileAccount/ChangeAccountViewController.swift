//
//  ChangeAccountViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/30.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ChangeAccountViewController: TKBaseViewController {
    private var navigationBar: TKNormalNavigationBar!
    private var tableView: UITableView!
}

extension ChangeAccountViewController {
    override func initView() {
        enablePanToDismiss()

        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Change Number",target:self)
        navigationBar.updateLayout(target: self)

        tableView = UITableView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.slTableView.setup(target: self, cellClasses: ChangeAccountTableViewCell.self)
    }
}

extension ChangeAccountViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIScreen.main.bounds.height > UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ChangeAccountTableViewCell.self), for: indexPath) as! ChangeAccountTableViewCell
        return cell
    }
}
