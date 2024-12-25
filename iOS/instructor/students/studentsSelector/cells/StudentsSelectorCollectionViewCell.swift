//
//  StudentsSelectorCollectionViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/9.
//  Copyright © 2019年 spelist. All rights reserved.
//

import Contacts
import UIKit
class StudentsSelectorCollectionViewCell: UICollectionViewCell {
    weak var delegate: StudentsSelectorCollectionViewCellDelegate?
    var cellStyle: StudentsCellStyle!
    var backView: TKView!
    var avatarImageView: TKAvatarView!
    var nameLabel: TKLabel!
    var contactLabel: TKLabel!
    var checkBoxImgView: TKImageView!
    var dividingLine = UIView()
    var arrowImgView = UIImageView()
    // resend or invite button
    var nextButton = TKBlockButton()
//    var localContactData: LocalContact!

    lazy var messageBarView: TKView = TKView.create()
        .backgroundColor(color: UIColor(r: 243, g: 243, b: 244))
        .corner(size: 3)
    private lazy var messageIconView: TKImageView = TKImageView.create()
        .setImage(name: "message_gray")
    private lazy var messageUnreadLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.medium(size: 10))
        .textColor(color: .white)
    private lazy var messageUnreadView: TKView = TKView.create()
        .corner(size: 10)
        .backgroundColor(color: ColorUtil.red)
    private lazy var messageContentLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 15))
        .textColor(color: ColorUtil.Font.primary)
    private lazy var messageTimeLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 12))
        .textColor(color: ColorUtil.Font.primary)
        .alignment(alignment: .right)

    private lazy var messageContainerView: TKView = {
        let view = TKView.create()
        messageBarView.addTo(superView: view) { make in
            make.bottom.equalToSuperview().offset(-16)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(28)
            make.left.equalToSuperview().offset(100)
        }

        messageIconView.addTo(superView: messageBarView) { make in
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(8)
        }
        messageUnreadView.addTo(superView: messageBarView) { make in
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(8)
        }
        messageUnreadLabel.addTo(superView: messageUnreadView) { make in
            make.center.equalToSuperview()
        }

        messageTimeLabel.addTo(superView: messageBarView) { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-8)
        }

        messageContentLabel.addTo(superView: messageBarView) { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(messageIconView.snp.right).offset(8)
            make.right.equalTo(messageTimeLabel.snp.left).offset(-8)
        }

        return view
    }()

    private var student: TKStudent?
    private var conversation: TKConversation?

    private var isLocal: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
        bindEvent()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentsSelectorCollectionViewCell: TKViewConfigurer {
    func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
        contentView.addSubview(backView)
        backView.snp.makeConstraints { make in
            make.center.size.equalToSuperview()
        }

        checkBoxImgView = TKImageView.create()
            .setImage(name: "checkboxOff")
            .setSize(size: CGSize(width: 22, height: 22))
        backView.addSubviews(checkBoxImgView)
        checkBoxImgView.snp.makeConstraints { make in
            make.size.equalTo(0)
            make.left.equalToSuperview().offset(0)
            make.top.equalToSuperview().offset(36)
        }

        avatarImageView = TKAvatarView(frame: CGRect.zero, size: 60, style: .normal, avatarImg: UIImage(named: "avatarBackground")!, name: "")
        backView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(17)
            make.left.equalTo(checkBoxImgView.snp.right).offset(20)
            make.size.equalTo(60)
        }

        contentView.addSubviews(dividingLine)
        dividingLine.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.left.equalToSuperview().offset(20)
        }
        dividingLine.backgroundColor = ColorUtil.dividingLine
        dividingLine.alpha = 0.5

        backView.addSubview(arrowImgView)
        arrowImgView.clipsToBounds = true
        arrowImgView.image = UIImage(named: "arrowRight")
        arrowImgView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(0)
            make.top.equalToSuperview().offset(36)
            make.height.equalTo(0)
            make.width.equalTo(0)
        }

        checkBoxImgView.snp.updateConstraints { make in
            make.size.equalTo(0)
            make.left.equalToSuperview().offset(0)
            make.top.equalToSuperview().offset(36)
        }
        backView.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.height.equalTo(0)
            make.width.equalTo(0)
            make.top.equalToSuperview().offset(33)
            make.right.equalTo(arrowImgView.snp.left)
        }
        nextButton.setFontSizeForregular(size: 10)

        nameLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
        backView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(24)
            make.left.equalTo(self.avatarImageView.snp.right).offset(20)
            make.right.equalTo(nextButton.snp.left).offset(-20).priority(999)
        }

        contactLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 15))
            .textColor(color: ColorUtil.Font.primary)
        contactLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.5)
        backView.addSubview(contactLabel)
        contactLabel.snp.makeConstraints { make in
            make.top.equalTo(self.nameLabel.snp.bottom).offset(5)
            make.left.equalTo(self.nameLabel.snp.left)
            make.right.equalTo(self.nameLabel.snp.right)
        }
        messageContainerView.clipsToBounds = true
        messageContainerView.addTo(superView: backView) { make in
//            make.top.equalTo(avatarImageView.snp.bottom)
            make.top.equalTo(contactLabel.snp.bottom).offset(9)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        messageUnreadView.isHidden = true
        messageUnreadLabel.text = ""
        messageTimeLabel.text = ""
        messageContentLabel.text = ""
        messageIconView.isHidden = true
    }

    func bindEvent() {
        backView.enableShadowAnimationOnTapped = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickCell))
        tap.numberOfTapsRequired = 1
        backView.isUserInteractionEnabled = true
        backView.addGestureRecognizer(tap)
        nextButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            logger.debug("点击nextButton")
            self.delegate?.studentsSelectorCollectionViewCell(didTappedAtButton: self)
        }
    }

    @objc func clickCell(sender: UITapGestureRecognizer) {
        if delegate?.studentsSelectorCollectionViewCellIsEdit() ?? false {
            delegate?.studentsSelectorCollectionViewCell(didTappedAtContentView: self)
            if cellStyle == .multipleSelection {
                if checkBoxImgView.image == UIImage(named: "checkboxOff") {
                    checkBoxImgView.image = UIImage(named: "checkboxOn")
                } else {
                    checkBoxImgView.image = UIImage(named: "checkboxOff")
                }
            }
        } else {
            if isLocal {
                delegate?.studentsSelectorCollectionViewCell(didTappedAtContentView: self)
                if cellStyle == .multipleSelection {
                    if checkBoxImgView.image == UIImage(named: "checkboxOff") {
                        checkBoxImgView.image = UIImage(named: "checkboxOn")
                    } else {
                        checkBoxImgView.image = UIImage(named: "checkboxOff")
                    }
                }
            } else {
                guard let student = self.student else {
                    logger.debug("学生数据为空")
                    return
                }
                logger.debug("到这里1")
                guard student.studentApplyStatus != .apply else {
                    logger.debug("学生数据木: \(student.toJSONString() ?? "")")
                    logger.debug("到这里2")
                    return
                }
                logger.debug("到这里3")
                delegate?.studentsSelectorCollectionViewCell(didTappedAtContentView: self)
                if cellStyle == .multipleSelection {
                    if checkBoxImgView.image == UIImage(named: "checkboxOff") {
                        checkBoxImgView.image = UIImage(named: "checkboxOn")
                    } else {
                        checkBoxImgView.image = UIImage(named: "checkboxOff")
                    }
                }
            }
        }
    }

    func initItem(_ style: StudentsCellStyle) {
        cellStyle = style
        switch cellStyle! {
        case .normal:
            initNormal()
            break
        case .singleSelection:
            initSingle()
            break
        case .multipleSelection:
            initMultipleSelection()
            break
        }
    }

    func initNormal() {
        arrowImgView.snp.updateConstraints { make in
            make.right.equalToSuperview().offset(-22)
            make.top.equalToSuperview().offset(36)
            make.height.equalTo(22)
            make.width.equalTo(22)
        }
        //        backView.addSubview(nextButton)
        nextButton.snp.updateConstraints { make in
            make.height.equalTo(0)
            make.width.equalTo(0)
            make.top.equalToSuperview().offset(33)
            make.right.equalTo(arrowImgView.snp.left)
        }
        checkBoxImgView.snp.updateConstraints { make in
            make.size.equalTo(0)
            make.left.equalToSuperview().offset(0)
            make.top.equalToSuperview().offset(36)
        }
    }

    func initSingle() {
        arrowImgView.snp.updateConstraints { make in
            make.right.equalToSuperview().offset(-22)
            make.top.equalToSuperview().offset(36)
            make.height.equalTo(22)
            make.width.equalTo(22)
        }
//        backView.addSubview(nextButton)
        nextButton.snp.updateConstraints { make in
            make.height.equalTo(0)
            make.width.equalTo(0)
            make.top.equalToSuperview().offset(33)
            make.right.equalTo(arrowImgView.snp.left)
        }
        checkBoxImgView.snp.updateConstraints { make in
            make.size.equalTo(0)
            make.left.equalToSuperview().offset(0)
            make.top.equalToSuperview().offset(36)
        }
    }

    func initMultipleSelection() {
        checkBoxImgView.snp.updateConstraints { make in
            make.size.equalTo(22)
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(36)
        }
        nextButton.snp.updateConstraints { make in
            make.height.equalTo(0)
            make.width.equalTo(0)
            make.top.equalToSuperview().offset(33)
            make.right.equalTo(arrowImgView.snp.left)
        }
        arrowImgView.snp.updateConstraints { make in
            make.right.equalToSuperview().offset(0)
            make.top.equalToSuperview().offset(36)
            make.height.equalTo(0)
            make.width.equalTo(0)
        }
    }

    func haveButton(text: String = "") {
        nextButton.snp.updateConstraints { make in
            if text == "" {
                make.width.equalTo(60)
            } else {
                make.width.equalTo(text.widthWithFont(font: nextButton.titleLabel!.font) + 20)
            }
            make.height.equalTo(28)
        }
    }
}

// MARK: - data

extension StudentsSelectorCollectionViewCell {
    func loadConversation(_ conversation: TKConversation?) {
        guard let userId = UserService.user.id() else { return }
        self.conversation = conversation
        if let conversation = conversation {
            if let message = conversation.latestMessage {
                messageContainerView.snp.updateConstraints { make in
                    make.height.equalTo(44)
                }
                messageTimeLabel.text = conversation.latestMessageTimestamp.timeStringWithoutTime()
                messageContentLabel.text = message.messageText()
                if let user = conversation.users.filter({ $0.userId == userId }).first {
                    messageUnreadLabel.text = "\(user.unreadMessageCount)"
                    if user.unreadMessageCount <= 0 {
                        messageIconView.isHidden = false
                        messageUnreadView.isHidden = true
                    } else {
                        messageUnreadView.isHidden = false
                        messageIconView.isHidden = true
                    }
                } else {
                    messageIconView.isHidden = false
                    messageUnreadView.isHidden = true
                }
            } else {
                messageContainerView.snp.updateConstraints { make in
                    make.height.equalTo(0)
                }
                messageUnreadView.isHidden = true
                messageUnreadLabel.text = ""
                messageTimeLabel.text = ""
                messageContentLabel.text = ""
                messageIconView.isHidden = true
            }
        } else {
            logger.debug("[加载会话Item] => 当前会话是空的: \(tag)")
            messageContainerView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            messageUnreadView.isHidden = true
            messageUnreadLabel.text = ""
            messageTimeLabel.text = ""
            messageContentLabel.text = ""
            messageIconView.isHidden = true
        }
    }

    func initData(localContactData: LocalContact) {
        isLocal = true
        nameLabel.text(localContactData.fullName)
        contactLabel.text(localContactData.email != "" ? localContactData.email : localContactData.phone)
        avatarImageView.loadImage(avatarUrl: "", name: localContactData.fullName)
        switch cellStyle! {
        case .normal:
            break
        case .singleSelection:
            break
        case .multipleSelection:
            checkBoxImgView.image = localContactData.isSelect ? UIImage(named: "checkboxOn")! : UIImage(named: "checkboxOff")!
            break
        }
    }

    func initData(studentData: TKStudent, unconfirmdLessonConfigs: [TKLessonScheduleConfigure] = []) {
        isLocal = false
        student = studentData
        nameLabel.text(studentData.name)
        contactLabel.setNumberOfLines(number: 1)
        contactLabel.snp.remakeConstraints { make in
            make.top.equalTo(self.nameLabel.snp.bottom).offset(5)
            make.left.equalTo(self.nameLabel.snp.left)
            make.right.equalTo(self.nameLabel.snp.right)
        }
        logger.debug("当前学生的用户信息[\(studentData.email)]: \(studentData.userInfo?.toJSONString() ?? "")")
        if let user = studentData.userInfo {
            if !user.active {
                logger.debug("当前学生: \(studentData.email) 未激活")
                contactLabel.text("Action required:\nSign in with \(user.email)")
                contactLabel.setNumberOfLines(number: 2)
                contactLabel.snp.remakeConstraints { make in
                    make.top.equalTo(self.nameLabel.snp.bottom).offset(5)
                    make.left.equalTo(self.nameLabel.snp.left)
                    make.right.equalToSuperview().offset(-20)
                }
            } else {
                if user.latestSigninTimestamp == 0 {
                    contactLabel.text(studentData.phone != "" ? studentData.phone : studentData.email)
                } else {
                    contactLabel.text(TimeUtil.timeToStringForStudentsItem(seconds: user.latestSigninTimestamp))
                }
            }
        } else {
            if studentData.latestSigninTimestamp == 0 {
                contactLabel.text(studentData.phone != "" ? studentData.phone : studentData.email)
            } else {
                contactLabel.text(TimeUtil.timeToStringForStudentsItem(seconds: studentData.latestSigninTimestamp))
            }
        }

        // 显示用户最后一次登录的时间信息,或者状态信息
        avatarImageView.loadImage(storagePath: UserService.user.getAvatarUrl(with: studentData.studentId), style: .normal, name: studentData.name, refreshCached: true)
        switch cellStyle! {
        case .normal:
            initButtonType(studentData: studentData, unconfirmdLessonConfigs: unconfirmdLessonConfigs)
            break
        case .singleSelection:
            break
        case .multipleSelection:
            checkBoxImgView.image = studentData._isSelect ? UIImage(named: "checkboxOn")! : UIImage(named: "checkboxOff")!
            break
        }
        if !studentData._isNotSelectt {
            backView.isUserInteractionEnabled = true
        } else {
            backView.isUserInteractionEnabled = false
        }
    }

    func initButtonType(studentData: TKStudent, unconfirmdLessonConfigs: [TKLessonScheduleConfigure] = []) {
        switch studentData.studentApplyStatus {
        case .apply:
            haveButton()
            nextButton.title = "Accept"
            nextButton.setStyle(style: .accept)
            nextButton.setFontSize(size: 10)
        case .confirm:
            if unconfirmdLessonConfigs.count > 0 {
                haveButton(text: "Confirm Lesson")
                nextButton.title = "Confirm Lesson"
                nextButton.setStyle(style: .warning)
                nextButton.setFontSize(size: 10)
            } else {
                setButtonTypeWithApplyNone(studentData: studentData)
            }
        case .none:
            setButtonTypeWithApplyNone(studentData: studentData)
        case .reject:
            break
        }
    }

    private func setButtonTypeWithApplyNone(studentData: TKStudent) {
        switch studentData.getStudentType() {
        case .none:
            initNormal()
        case .invite:
            haveButton()
            nextButton.title = "Re-invite"
            nextButton.setStyle(style: .invite)
            nextButton.setFontSize(size: 10)
        case .addLesson:
            nextButton.snp.updateConstraints { make in
                make.height.equalTo(28)
                make.width.equalTo(72)
            }
            nextButton.title = "Add Lesson"
            nextButton.setStyle(style: .invite)
            nextButton.setFontSize(size: 10)
        case .resend:
            haveButton()
            nextButton.title = "Re-invite"
            nextButton.setStyle(style: .invite)
            nextButton.setFontSize(size: 10)
        case .rejected:
            haveButton()
            nextButton.title = "Rejected"
            nextButton.setStyle(style: .rejected)
            nextButton.setFontSize(size: 10)

        case .newLesson:
            nextButton.snp.updateConstraints { make in
                make.height.equalTo(28)
                make.width.equalTo(72)
            }
            nextButton.title = "New Lesson"
            nextButton.setStyle(style: .invite)
            nextButton.setFontSize(size: 10)
        }
    }
}

@objc protocol StudentsSelectorCollectionViewCellDelegate: NSObjectProtocol {
//    func studentsCell(cell: StudentsSelectorCollectionViewCell)
    func studentsSelectorCollectionViewCell(didTappedAtButton cell: StudentsSelectorCollectionViewCell)
    func studentsSelectorCollectionViewCell(didTappedAtContentView cell: StudentsSelectorCollectionViewCell)

    func studentsSelectorCollectionViewCellIsEdit() -> Bool
}
