//
//  ProfileUserInfoTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/5.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileUserInfoTableViewCell: UITableViewCell {
    weak var delegate: ProfileUserInfoTableViewCellDelegate?

    private var backView: TKView!
    private var avatarView: TKAvatarView!
    private var titleLabel: TKLabel!
    private var nameLabel: TKLabel!
    private var rightArrowImageView: TKImageView!
    
    private var studio: TKStudio?
    private var user: TKUser?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileUserInfoTableViewCell {
    private func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
        backView.onViewTapped { [weak self] _ in
            self?.delegate?.profileUserInfoTableViewCellTapped()
        }
        contentView.addSubview(view: backView) { make in
            make.top.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20).priority(.medium)
        }

        avatarView = TKAvatarView()
        avatarView.layer.cornerRadius = 30
        avatarView.clipsToBounds = true
        backView.addSubview(view: avatarView) { make in
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(60)
            make.centerY.equalToSuperview()
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "")
            .setNumberOfLines(number: 0)
//        titleLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        titleLabel.numberOfLines = 0
        backView.addSubview(view: titleLabel) { make in
            make.top.equalToSuperview().offset(27)
            make.left.equalTo(avatarView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-64)
            make.height.equalTo(20)
        }

        nameLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "")
        backView.addSubview(view: nameLabel) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.left.equalTo(avatarView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-26)
            make.height.equalTo(15)
        }

        rightArrowImageView = TKImageView.create()
            .setImage(name: "arrowRight")
            .setSize(22)
        backView.addSubview(view: rightArrowImageView) { make in
            make.size.equalTo(22)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
    }

    func loadData(user: TKUser?, studio: TKStudio?) {
        self.studio = studio
        self.user = user
        if let studio = studio {
            loadAvatar()
//            avatarView.loadImage(storagePath: Tools.getStudioAvatarPath(id: studio.id), style: .normal, name: studio.name, refreshCached: true)
            if titleLabel.text != studio.name {
                
                //titleLabel.text(studio.name.capitalized)
titleLabel.text(studio.name)
            }
            let height = studio.name.heightWithFont(font:  FontUtil.bold(size: 18), fixedWidth: UIScreen.main.bounds.width - 204)
            logger.debug("标题的高度: \(height)")
            titleLabel.snp.updateConstraints { (make) in
                make.height.equalTo(height)
            }
        }
        if let user = user {
            //nameLabel.text(user.name.capitalized)
            nameLabel.text(user.name)
        }
    }
    
    func loadAvatar() {
//        if let studio = self.studio {
////            avatarView.loadImage(storagePath: Tools.getStudioAvatarPath(id: studio.id), style: .normal, name: studio.name, refreshCached: true)
//            avatarView.loadImage(studioId: studio.id, name: studio.name)
//
//        }
        if let user = self.user {
            avatarView.loadImage(userId: user.userId, name: studio?.name ?? "")
        }
    }
}

protocol ProfileUserInfoTableViewCellDelegate: NSObjectProtocol {
    func profileUserInfoTableViewCellTapped()
}
