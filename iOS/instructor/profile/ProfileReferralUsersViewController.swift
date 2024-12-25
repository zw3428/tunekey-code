//
//  ProfileReferralUsersViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/4/23.
//  Copyright © 2021 spelist. All rights reserved.
//

import UIKit

class ProfileReferralUsersViewController: TKBaseViewController {
    var users: [TKReferralUserRecord] = []

    private var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Redeemed")

    private lazy var tableView: UITableView = makeTableView()
}

extension ProfileReferralUsersViewController {
    private func makeTableView() -> UITableView {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.register(ProfileReferralUsersTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileReferralUsersTableViewCell.self))
        tableView.dataSource = self
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.layer.shadowColor = ColorUtil.Shadow.main.cgColor
        tableView.layer.shadowOpacity = 0.4
        tableView.layer.shadowRadius = SHADOW_RADIUS
        tableView.layer.shadowOffset = CGSize(width: 0, height: SHADOW_OFFSET)
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = ColorUtil.borderColor.cgColor
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.cornerRadius = 5
        return tableView
    }
}

extension ProfileReferralUsersViewController {
    override func initView() {
        super.initView()
        enablePanToDismiss()
        TKView.create()
            .showShadow()
        users = ListenerService.shared.teacherData.referralUseRecord

        navigationBar.updateLayout(target: self)

        tableView.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(users.count * 84)
        }
        updateData()
    }
}

extension ProfileReferralUsersViewController {
    override func initData() {
        super.initData()
        EventBus.listen(key: .teacherReferralUseRecordChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.updateData()
            }
        }
    }

    private func updateData() {
        users = ListenerService.shared.teacherData.referralUseRecord
        tableView.reloadData()
        var height: CGFloat = CGFloat(users.count) * 84
        let maxHeight: CGFloat = UIScreen.main.bounds.height - 44 - UiUtil.safeAreaTop() - UiUtil.safeAreaBottom() - 10 - 20
        if height > maxHeight {
            height = maxHeight
        }
        tableView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }
}

extension ProfileReferralUsersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileReferralUsersTableViewCell.self), for: indexPath) as! ProfileReferralUsersTableViewCell
        let user = users[indexPath.row]
        cell.avatarView.loadImage(userId: user.userId, name: user.userName)
        cell.nameLabel.text(user.userName)
        if let timeinterval = Int(user.datetime) {
            let date = Date(seconds: TimeInterval(timeinterval))
            cell.timeLabel.text("Redeemed at \(date.toLocalFormat("h:mma M/d/yyyy"))")
        }

        if indexPath.row == users.count - 1 {
            cell.lineView.isHidden = true
        } else {
            cell.lineView.isHidden = false
        }
        return cell
    }
}

class ProfileReferralUsersTableViewCell: UITableViewCell {
    var containerView: TKView = TKView.create()
        .backgroundColor(color: .white)

    var avatarView: TKAvatarView = TKAvatarView(frame: .zero)
    var nameLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 18))
        .textColor(color: ColorUtil.Font.third)

    var timeLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.Font.primary)

    var lineView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.dividingLine)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileReferralUsersTableViewCell {
    private func initView() {
        containerView.addTo(superView: contentView) { make in
            make.top.bottom.left.right.equalToSuperview()
            make.height.equalTo(84)
        }

        lineView.addTo(superView: containerView) { make in
            make.height.equalTo(1)
            make.right.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(40)
        }
        lineView.isHidden = true

        avatarView.addTo(superView: containerView) { make in
            make.size.equalTo(60)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
        }
        avatarView.cornerRadius = 30

        nameLabel.addTo(superView: containerView) { make in
            make.top.equalToSuperview().offset(23)
            make.left.equalTo(avatarView.snp.right).offset(20)
            make.height.equalTo(21)
            make.right.equalToSuperview().offset(-20)
        }

        timeLabel.addTo(superView: containerView) { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(5)
            make.left.equalTo(nameLabel.snp.left)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(21)
        }
    }
}
