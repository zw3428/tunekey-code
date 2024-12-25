//
//  StudentDetailsUserInfoCell.swift
//  TuneKey
//
//  Created by Wht on 2019/8/20.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class StudentDetailsUserInfoCell: UITableViewCell {
    var backView: UIView!
    private var avatarView: TKAvatarView!
    private var nameLabel: TKLabel!
    private var infoLabel: TKLabel!
    var infoButton: BigRangeButton!
    private var labelView = UIView()
        
    var studentData: TKStudent!
    weak var delegate: StudentDetailsUserInfoCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentDetailsUserInfoCell {
    func initData(_ studentData: TKStudent, isEditStudentInfo: Bool = false) {
        self.studentData = studentData
        nameLabel.text(studentData.name)
        avatarView.loadImage(storagePath: UserService.user.getAvatarUrl(with: studentData.studentId), name: studentData.name)
        infoLabel.text("\(studentData.email)")
        if isEditStudentInfo {
            infoButton.setImage(UIImage(named: "arrowRight"), for: .normal)
            backView.onViewTapped { [weak self] _ in
                self?.delegate?.clickInfoButton()
            }
        }
    }

    func initLessonType(lessonType: TKLessonType) {
        if lessonType.price != -1 {
            infoLabel.text("\(lessonType.timeLength.description) minutes, $\(lessonType.price.description)")
        } else {
            infoLabel.text("\(lessonType.timeLength.description) minutes")
        }
    }
}

// InitView
extension StudentDetailsUserInfoCell {
    func initView() {
        backgroundColor = ColorUtil.backgroundColor
        backView = UIView()
        contentView.addSubview(backView)
        backView.setShadows()
        backView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(100)
        }
        backView.backgroundColor = UIColor.white

        avatarView = TKAvatarView()
        avatarView.setSize(size: 60)

        backView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.size.equalTo(60)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
        }

        infoButton = BigRangeButton()
        backView.addSubview(infoButton)
        infoButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(22)
        }
        infoButton.setImage(UIImage(named: "imgInfo"), for: .normal)
        infoButton.addTarget(self, action: #selector(clickInfoButton), for: .touchUpInside)

        backView.addSubview(labelView)
        labelView.backgroundColor = UIColor.white
        labelView.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(20)
            make.height.equalTo(47)
            make.centerY.equalToSuperview()
            make.right.equalTo(infoButton.snp.left).offset(-10)
        }
        nameLabel = TKLabel()
        infoLabel = TKLabel()
        labelView.addSubviews(nameLabel, infoLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(2)
            make.height.equalTo(23)
        }
        nameLabel.textColor(color: ColorUtil.Font.third).font(FontUtil.bold(size: 18))
        infoLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-2)
            make.height.equalTo(20)
        }
        infoLabel.textColor(color: ColorUtil.Font.primary).font(FontUtil.regular(size: 13))
        
//        chatButton.addTo(superView: contentView) { make in
//            make.top.equalTo(backView.snp.bottom).offset(25)
//            make.height.equalTo(50)
//            make.width.equalTo(120)
//            make.centerX.equalToSuperview()
//        }
    }

    // 按钮点击事件
    @objc func clickInfoButton(sender: UIButton) {
        delegate?.clickInfoButton()
    }
}

protocol StudentDetailsUserInfoCellDelegate: AnyObject {
    func clickInfoButton()
}
