//
//  SupportConversationItemCellTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2021/5/26.
//  Copyright © 2021 spelist. All rights reserved.
//

import UIKit

protocol SupportConversationItemCellTableViewCellDelegate: AnyObject {
    func supportConversationItemCellTableViewCell(didTapped conversation: TKConversation)
    func supportConversationItemCellTableViewCell(didTappedAvatar conversation: TKConversation)
}

class SupportConversationItemCellTableViewCell: UITableViewCell {
    weak var delegate: SupportConversationItemCellTableViewCellDelegate?
    private var conversation: TKConversation?

    private lazy var avatarView: TKAvatarView = TKAvatarView(frame: .zero, name: "")
    private lazy var userNameLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 18))
        .textColor(color: ColorUtil.Font.second)
    private lazy var timeLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 12))
        .textColor(color: ColorUtil.Font.primary)
        .alignment(alignment: .right)
    private lazy var latestMessageLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 15))
        .textColor(color: ColorUtil.Font.primary)

    private lazy var unreadMessageCountLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.medium(size: 10))
        .textColor(color: .white)
        .alignment(alignment: .center)
    private lazy var unreadMessageView: TKView = {
        let view = TKView.create()
            .backgroundColor(color: ColorUtil.red)
            .corner(size: 10)
        unreadMessageCountLabel.addTo(superView: view) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SupportConversationItemCellTableViewCell {
    private func initView() {
        avatarView.cornerRadius = 30
        avatarView.addTo(superView: contentView) { make in
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(60)
            make.top.equalToSuperview().offset(17)
            make.bottom.equalToSuperview().offset(-17).priority(.medium)
        }
        unreadMessageView.addTo(superView: contentView) { make in
            make.right.equalTo(avatarView.snp.right)
            make.top.equalTo(avatarView.snp.top)
            make.size.equalTo(20)
        }
        unreadMessageView.isHidden = true

        timeLabel.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(27)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(15)
        }

        userNameLabel.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(24)
            make.left.equalTo(avatarView.snp.right).offset(20)
            make.right.equalTo(timeLabel.snp.left).offset(-20)
            make.height.equalTo(21)
        }

        latestMessageLabel.addTo(superView: contentView) { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(10)
            make.left.equalTo(avatarView.snp.right).offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        contentView.onViewTapped { [weak self] _ in
            guard let self = self, let conversation = self.conversation else { return }
            self.delegate?.supportConversationItemCellTableViewCell(didTapped: conversation)
        }
        
        avatarView.onViewTapped { [weak self] _ in
            guard let self = self, let conversation = self.conversation else { return }
            self.delegate?.supportConversationItemCellTableViewCell(didTappedAvatar: conversation)
        }
    }
}

extension SupportConversationItemCellTableViewCell {
    func loadData(_ conversation: TKConversation) {
        guard let userId = UserService.user.id() else { return }
        self.conversation = conversation
        logger.debug("加载Conversation: \(conversation.creatorId) -> \(conversation.users.toJSONString()  ?? "")")
        if var user = conversation.users.filter({ $0.userId == conversation.creatorId }).first {
            logger.debug("加载对方用户: \(user.toJSONString() ?? "")")
            avatarView.loadImage(userId: user.userId, name: user.nickname)
            userNameLabel.text = user.nickname
            
            if user.nickname == "" {
                logger.debug("获取用户信息: \(user.userId)")
                UserService.user.getUserInfo(id: user.userId)
                    .done { [weak self] u in
                        guard let self = self else { return }
                        guard u.userId == conversation.creatorId else {
                            return
                        }
                        self.avatarView.loadImage(userId: u.userId, name: u.name)
                        self.userNameLabel.text = u.name
                        user.nickname = u.name
                        user.converTo().save()
                    }
                    .catch { error in
                        logger.error("获取用户id失败: \(error)")
                    }
            }
        }
        if let user = conversation.users.filter({ $0.userId == userId }).first {
            logger.debug("加载自己信息: \(user.toJSONString() ?? "")")
            if user.unreadMessageCount > 0 {
                unreadMessageView.isHidden = false
                unreadMessageCountLabel.text = user.unreadMessageCount > 9 ? "9+" : "\(user.unreadMessageCount)"
            } else {
                unreadMessageView.isHidden = true
            }
        }

        if let latestMessage = conversation.latestMessage {
            logger.debug("当前要显示的: \(latestMessage.toJSONString() ?? "")")
            self.latestMessageLabel.text = latestMessage.messageText()
            self.timeLabel.text = latestMessage.datetime.timeString()
        } else {
            if conversation.latestMessageId != "" {
                let messageId = conversation.latestMessageId
                DBService.message.get(messageId)
                    .done { [weak self] message in
                        guard let self = self else { return }
                        guard let c = self.conversation else {
                            return
                        }
                        guard c.id == conversation.id else {
                            self.loadData(c)
                            return
                        }
                        if let message = message {
                            self.latestMessageLabel.text = message.messageText()
                            self.timeLabel.text = message.datetime.timeString()
                        } else {
                            self.latestMessageLabel.text = ""
                            self.timeLabel.text = ""
                        }
                    }
                    .catch { [weak self] error in
                        guard let self = self else { return }
                        guard let c = self.conversation else { return }
                        guard c.id == conversation.id else {
                            self.loadData(c)
                            return
                        }
                        self.latestMessageLabel.text = ""
                        self.timeLabel.text = ""
                        logger.error("获取聊天失败: \(error)")
                    }
            }
        }
        
    }
}
