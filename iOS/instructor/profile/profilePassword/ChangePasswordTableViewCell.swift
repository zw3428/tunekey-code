//
//  ChangePasswordTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/27.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ChangePasswordTableViewCell: UITableViewCell {
    weak var delegate: ChangePasswordTableViewCellDelegate?

    private var oldPasswordTextBox: TKTextBox!
    private var newPasswordTextBox: TKTextBox!
    private var confirmNewPasswordTextBox: TKTextBox!
    private var changeButton: TKBlockButton!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ChangePasswordTableViewCell {
    private func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        oldPasswordTextBox = TKTextBox.create()
            .isPassword(true)
            .placeholder("Your old password")
            .inputType(.text)
            .keyboardType(.default)
            .numberOfWordsLimit(GlobalFields.maxPasswordLength)
            .onTyped({ [weak self] _ in
                self?.onPasswordType()
            })
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalToSuperview().offset(20)
                make.left.equalToSuperview().offset(40)
                make.right.equalToSuperview().offset(-40)
                make.height.equalTo(64)
            })

        newPasswordTextBox = TKTextBox.create()
            .placeholder("Your new password")
            .isPassword(true)
            .inputType(.text)
            .keyboardType(.default)
            .numberOfWordsLimit(GlobalFields.maxPasswordLength)
            .onTyped({ [weak self] _ in
                self?.onPasswordType()
            })
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalTo(oldPasswordTextBox.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(40)
                make.right.equalToSuperview().offset(-40)
                make.height.equalTo(64)
            })

        confirmNewPasswordTextBox = TKTextBox.create()
            .placeholder("Confirm your new password")
            .isPassword(true)
            .inputType(.text)
            .keyboardType(.default)
            .numberOfWordsLimit(GlobalFields.maxPasswordLength)
            .onTyped({ [weak self] _ in
                self?.onPasswordType()
            })
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalTo(newPasswordTextBox.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(40)
                make.right.equalToSuperview().offset(-40)
                make.height.equalTo(64)
            })

        changeButton = TKBlockButton(frame: .zero, title: "CHANGE")
        contentView.addSubview(view: changeButton) { make in
            make.top.equalTo(confirmNewPasswordTextBox.snp.bottom).offset(60)
            make.centerX.equalToSuperview()
            make.width.equalTo(180)
            make.height.equalTo(50)
        }

        changeButton.disable()
        changeButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            if self.newPasswordTextBox.getValue() == self.confirmNewPasswordTextBox.getValue() {
                self.delegate?.changePasswordTableViewCell(changeButtonTapped: self.changeButton, oldPassword: self.oldPasswordTextBox.getValue(), newPassword: self.newPasswordTextBox.getValue())
            } else {
                self.delegate?.changePasswordTableViewCellShowPasswordError(msg: "New password and confirmation password are inconsistent")
                self.newPasswordTextBox.showWrong()
                self.confirmNewPasswordTextBox.showWrong()
            }
        }
    }

    private func onPasswordType() {
        logger.debug("调用on Password type")
        if oldPasswordTextBox.getValue() != "" && newPasswordTextBox.getValue() != "" && confirmNewPasswordTextBox.getValue() != "" {
            changeButton.enable()
        }
    }
}

protocol ChangePasswordTableViewCellDelegate: NSObjectProtocol {
    func changePasswordTableViewCell(changeButtonTapped button: TKBlockButton, oldPassword: String, newPassword: String)
    func changePasswordTableViewCellShowPasswordError(msg: String)
}
