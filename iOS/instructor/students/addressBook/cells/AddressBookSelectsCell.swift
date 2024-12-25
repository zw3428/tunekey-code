//
//  AddressBookSelectsCell.swift
//  TuneKey
//
//  Created by Wht on 2019/8/15.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class AddressBookSelectsCell: UICollectionViewCell {
    var nameLabel = TKLabel()
    var avatarView: TKAvatarView!
    var closeButton: TKButton = TKButton.create()
        .setImage(name: "close")
    var localContactData: LocalContact!
    var appContactData: TKStudent!
    var user: TKUser?
    var delegate: AddressBookSelectsCellDelegate!

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AddressBookSelectsCell {
    func initView() {
        avatarView = TKAvatarView(frame: CGRect.zero, size: 60, style: .rightTopHaveImage, avatarImg: UIImage(named: "avatarBackground")!, name: "")
        addSubviews(nameLabel, avatarView, closeButton)
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.height.width.equalTo(60)
        }
        avatarView.setSize(size: 60)
        avatarView.setStyle(style: .normal)
//        avatarView.setRightTopImage(image: UIImage(named: "close")!)

        closeButton.snp.makeConstraints { make in
            make.size.equalTo(22)
            make.top.equalTo(avatarView.snp.top)
            make.left.equalTo(avatarView.snp.right).offset(-11)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.height.equalTo(13)
        }
        nameLabel.alignment(alignment: .center).textColor(color: ColorUtil.Font.fourth).font(font: FontUtil.medium(size: 10)).text("Name")

        closeButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.addressBookCell(cell: self)
        }
        avatarView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.addressBookCell(cell: self)
        }
    }
}

// MARK: - data

extension AddressBookSelectsCell {
    func initData(localContactData: LocalContact) {
        self.localContactData = localContactData
        nameLabel.text(localContactData.fullName)
        closeButton.isHidden = false
        if localContactData.avatarUrl != nil {
            avatarView.loadImage(style: .rightTopHaveImage, avatarUrl: localContactData.avatarUrl, name: localContactData.fullName)
        } else if localContactData.avatarData != nil {
            avatarView.loadImage(style: .rightTopHaveImage, avatarData: localContactData.avatarData!, name: localContactData.fullName)
        } else {
            avatarView.loadImage(style: .rightTopHaveImage, avatarUrl: "", name: localContactData.fullName)
        }
    }

    func initData(appContactData: TKStudent) {
        self.appContactData = appContactData
        nameLabel.text = appContactData.name
        avatarView.loadImage(storagePath: Tools.getUserAvatarPath(id: appContactData.studentId), style: .rightTopHaveImage, name: appContactData.name)
        if !appContactData._isNotSelectt {
            avatarView.isUserInteractionEnabled = true
            closeButton.isHidden = false
            avatarView.loadImage(storagePath: Tools.getUserAvatarPath(id: appContactData.studentId), name: appContactData.name)
        } else {
            avatarView.isUserInteractionEnabled = false
            closeButton.isHidden = true
            avatarView.loadImage(storagePath: Tools.getUserAvatarPath(id: appContactData.studentId), name: appContactData.name)
        }
    }
}

protocol AddressBookSelectsCellDelegate {
    func addressBookCell(cell: AddressBookSelectsCell)
}
