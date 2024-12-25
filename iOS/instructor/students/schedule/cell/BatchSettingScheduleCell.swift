//
//  BatchSettingScheduleCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/4.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class BatchSettingScheduleCell: UICollectionViewCell {
    var nameLabel = TKLabel()
    var avatarView: TKAvatarView!
    var localContactData: LocalContact!
    weak var delegate: BatchSettingCellDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BatchSettingScheduleCell {
    func initView() {
        avatarView = TKAvatarView(frame: CGRect.zero, size: 50, style: .rightTopHaveImage, avatarImg: UIImage(named: "avatarBackground")!, name: "")
        addSubviews(nameLabel, avatarView)
        nameLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.height.equalTo(13)
        }
        nameLabel.alignment(alignment: .center).textColor(color: ColorUtil.Font.fourth).font(font: FontUtil.medium(size: 10)).text("Name")

        avatarView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(50)
            make.bottom.equalTo(nameLabel.snp.top).offset(-4)
        }
        onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.BatchSettingCell(cell: self)
        }
    }

    func initData(localContactData: StudentScheduleData) {
        nameLabel.text(localContactData.student.fullName)
        if localContactData.student.avatarUrl != nil {
            avatarView.loadImage(style: .rightTopHaveImage, avatarUrl: localContactData.student.avatarUrl, name: localContactData.student.fullName)
        } else if localContactData.student.avatarData != nil {
            avatarView.loadImage(style: .rightTopHaveImage, avatarData: localContactData.student.avatarData!, name: localContactData.student.fullName)
        } else {
            avatarView.loadImage(style: .rightTopHaveImage, avatarUrl: "", name: localContactData.student.fullName)
        }
        switch localContactData.type {
        case .completed:
            avatarView.setSize(size: 50)
            avatarView.setStyle(style: .rightTopHaveImage)
            avatarView.setRightTopImage(image: UIImage(named: "checkboxOn")!)
            break
        case .uncompleted:
            avatarView.setSize(size: 50)
            avatarView.setStyle(style: .rightTopHaveImage)
            avatarView.setRightTopImage(image: UIImage(named: "checkboxQuestionMark")!)
            break
        }
        if localContactData.isSelect {
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                self.avatarView.snp.updateConstraints { make in
                    make.size.equalTo(60)
                }
                self.avatarView.setSize(size: 60)
                self.layoutIfNeeded()
            }
            nameLabel.textColor = ColorUtil.main
            avatarView.setStyle(style: .normal)
        } else {
            avatarView.snp.updateConstraints { make in
                make.size.equalTo(50)
            }
            nameLabel.textColor = ColorUtil.Font.fourth
        }
    }
}

protocol BatchSettingCellDelegate: NSObjectProtocol {
    func BatchSettingCell(cell: BatchSettingScheduleCell)
}
