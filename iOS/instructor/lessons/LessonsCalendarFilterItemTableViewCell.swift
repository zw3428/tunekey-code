//
//  LessonsCalendarFilterItemTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/17.
//  Copyright © 2019 spelist. All rights reserved.
//

import UIKit

class LessonsCalendarFilterItemTableViewCell: UITableViewCell {
    weak var delegate: LessonsCalendarFilterItemTableViewCellDelegate?

    private var titleLabel: TKLabel!
    private var selectedIconImageView: TKImageView!
    private var switchView: TKSwitch!

    private var index: IndexPath!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonsCalendarFilterItemTableViewCell {
    private func initView() {
        contentView.backgroundColor = UIColor.white
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(contentViewTapped)))
        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(22)
        }

        selectedIconImageView = TKImageView.create()
            .setImage(name: "checkPrimary")
        contentView.addSubview(selectedIconImageView)
        selectedIconImageView.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel)
            make.size.equalTo(22)
            make.right.equalToSuperview().offset(-20)
        }

        switchView = TKSwitch()
        contentView.addSubview(switchView)
        switchView.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(self.switchView.size)
        }
        switchView.isOn = false
        switchView.onValueChanged { [weak self] isOn in
            logger.debug("switch changed: \(isOn)")
            self?.delegate?.lessonsCalendarFilterItemTableViewCellIsGoogleCalendarShow(isShow: isOn)
        }
    }

    func loadData(title: String, isSelected: Bool, isSwitchShow: Bool, isSwitchOn: Bool = false, indexPath: IndexPath) {
        titleLabel.text(title)
        selectedIconImageView.isHidden = !isSelected
        switchView.isHidden = !isSwitchShow
        switchView.isOn = isSwitchOn
        index = indexPath
    }

    @objc private func contentViewTapped() {
        delegate?.lessonsCalendarFilterItemTableViewCellTapped(index: index)
    }
}

protocol LessonsCalendarFilterItemTableViewCellDelegate: NSObjectProtocol {
    func lessonsCalendarFilterItemTableViewCellTapped(index: IndexPath)
    func lessonsCalendarFilterItemTableViewCellIsGoogleCalendarShow(isShow: Bool)
}
