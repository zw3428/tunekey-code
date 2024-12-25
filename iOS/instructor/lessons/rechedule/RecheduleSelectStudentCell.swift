//
//  RecheduleSelectStudentCell.swift
//  TuneKey
//
//  Created by WHT on 2020/3/23.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit
protocol RecheduleSelectStudentCellDelegate: NSObjectProtocol {
    func clickCell(cell: RecheduleSelectStudentCell)
}

class RecheduleSelectStudentCell: UITableViewCell {
    private var mainView: TKView!
    private var avatarView: TKAvatarView!
    private var timeLabel: TKLabel!
    private var nameLabel: TKLabel!
    private var checkImage: TKImageView!
    private var data: TKLessonSchedule!
    weak var delegate: RecheduleSelectStudentCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initItemView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RecheduleSelectStudentCell {
    func initItemView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        mainView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.edges.equalToSuperview()
                make.height.equalTo(94)
            })
        mainView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.clickCell(cell: self)
        }
        checkImage = TKImageView.create()
            .setImage(name: "checkboxOff")
            .addTo(superView: mainView, withConstraints: { make in
                make.size.equalTo(22)
                make.left.equalToSuperview().offset(20)
                make.centerY.equalToSuperview()
            })

        avatarView = TKAvatarView()
        avatarView.setSize(size: 60)

        mainView.addSubview(view: avatarView) { make in
            make.size.equalTo(60)
            make.centerY.equalToSuperview()
            make.left.equalTo(checkImage.snp.right).offset(20)
        }
        timeLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalTo(avatarView.snp.right).offset(20)
                make.top.equalTo(avatarView.snp.top).offset(3)
                make.height.equalTo(20)
            })
        nameLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.primary)
            .addTo(superView: mainView, withConstraints: { make in
                make.left.equalTo(avatarView.snp.right).offset(20)
                make.height.equalTo(20)
                make.top.equalTo(timeLabel.snp.bottom).offset(7)
            })

        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: mainView) { make in
                make.bottom.right.equalToSuperview()
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(20)
            }
    }
}

extension RecheduleSelectStudentCell {
    func initData(data: TKLessonSchedule, df: DateFormatter) {
        self.data = data
        checkImage.setImage(name: data.studentData!._isSelect ? "checkboxOn" : "checkboxOff")
        avatarView.loadImage(userId: data.studentData!.studentId, name: data.studentData!.name)
        nameLabel.text(data.studentData!.name)
        timeLabel.text(df.string(from: TimeUtil.changeTime(time: data.getShouldDateTime())))
    }
}
