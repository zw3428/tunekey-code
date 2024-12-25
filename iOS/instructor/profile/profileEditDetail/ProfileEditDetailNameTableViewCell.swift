//
//  ProfileEditDetailNameTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/9.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileEditDetailNameTableViewCell: UITableViewCell {
    weak var delegate: ProfileEditDetailNameTableViewCellDelegate?

    var cellHeight: CGFloat = 134

    var nameInputBox: TKTextBox!
    var skipLabel: TKLabel = TKLabel.create()
        .alignment(alignment: .right)
//        .textColor(color: ColorUtil.main)
//        .font(font: FontUtil.regular(size: 15))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileEditDetailNameTableViewCell {
    private func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        nameInputBox = TKTextBox.create()
            .placeholder("Studio name")
            .numberOfWordsLimit(50)
            .onTyped({ [weak self] text in
                guard let self = self else { return }
                // self.nameInputBox.value(text.capitalized)
                self.nameInputBox.value(text)
                self.delegate?.profileEditDetailNameTableViewCell(textBox: self.nameInputBox, nameChanged: text)
            })
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalToSuperview().offset(10)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })
        let text = "Haven't a studio name? Skip for now."
        let selectedText = "Skip for now."
        skipLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: selectedText, allColor: ColorUtil.Font.fourth, selectedColor: ColorUtil.main, font: FontUtil.medium(size: 15), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
        skipLabel.addTo(superView: contentView) { make in
            make.right.equalTo(nameInputBox.snp.right)
            make.top.equalTo(nameInputBox.snp.bottom).offset(20)
        }
    }

    func loadData(defaultName: String) {
        nameInputBox.value(defaultName)
    }

    func focusTextBox() {
        nameInputBox.focus()
    }
}

protocol ProfileEditDetailNameTableViewCellDelegate: NSObjectProtocol {
    func profileEditDetailNameTableViewCell(textBox: TKTextBox, nameChanged name: String)
}
