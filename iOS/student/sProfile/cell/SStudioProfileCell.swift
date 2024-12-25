//
//  SStudioProfileCell.swift
//  TuneKey
//
//  Created by wht on 2020/5/22.
//  Copyright © 2020 spelist. All rights reserved.
//
import NVActivityIndicatorView
import SnapKit
import UIKit

class SStudioProfileCell: UITableViewCell {
    private var conversation: TKConversation?

    private var mainView: TKView!
    private var titleLabel: TKLabel!
    private var pendingLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.red)
        .text(text: "Pending")
    var loadingIndicatorView: NVActivityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: ColorUtil.main, padding: 0)
    var studioNameLabel: TKLabel!
    var teacherNameLabel: TKLabel!
    var avatarView: TKAvatarView!
    var studioStackView: UIStackView!
    var arrowImageView: TKImageView = TKImageView.create()
        .setImage(name: "arrowRight")
    var inviteTeacherButton: TKButton = TKButton.create()
        .titleColor(color: .white)
        .title(title: "INVITE INSTRUCTOR")
        .titleFont(font: FontUtil.bold(size: 10))
        .backgroundColor(color: ColorUtil.main)

    var chatIconButton: TKButton = TKButton.create()
        .setImage(name: "message", size: CGSize(width: 22, height: 22))
    
    lazy var latestMessageView: LatestMessageView = LatestMessageView()

    weak var delegate: SStudioProfileCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SStudioProfileCell {
    func initView() {
        contentView.backgroundColor = UIColor.white

        mainView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow(color: ColorUtil.dividingLine)
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.bottom.right.equalTo(-20)
            })

        titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .alignment(alignment: .left)
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Studio Info")
        mainView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(20)
        }
        pendingLabel.addTo(superView: mainView) { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.right.equalToSuperview().offset(-20)
        }
        pendingLabel.isHidden = true

        loadingIndicatorView.addTo(superView: mainView) { make in
            make.size.equalTo(22)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
        loadingIndicatorView.startAnimating()
        studioStackView = UIStackView()
        studioStackView.distribution = .fillEqually
        studioStackView.axis = .vertical
        studioStackView.alignment = .fill
        studioStackView.spacing = 0
        mainView.addSubview(view: studioStackView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
//            make.bottom.equalToSuperview().offset(-10)
        }

        chatIconButton.addTo(superView: mainView) { make in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }
        chatIconButton.isHidden = true

        inviteTeacherButton.cornerRadius = 2.2
        mainView.addSubview(view: inviteTeacherButton) { make in
            make.centerY.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(24)
            make.right.equalToSuperview().offset(-24)
        }
        inviteTeacherButton.isHidden = true
        inviteTeacherButton.onTapped { [weak self] _ in
            self?.delegate?.sStudioProfileCellInviteTeacherButtonTapped()
        }

        arrowImageView.addTo(superView: mainView) { make in
            make.centerY.equalTo(studioStackView.snp.centerY)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }
        arrowImageView.isHidden = true

        latestMessageView.addTo(superView: mainView) { make in
            make.top.equalTo(studioStackView.snp.bottom)
            make.left.equalToSuperview().offset(90)
            make.height.equalTo(0)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-16).priority(.medium)
        }
        latestMessageView.isHidden = true

        latestMessageView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.sStudioProfileCell(didTappedConversation: self.conversation)
        }

        chatIconButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.sStudioProfileCell(didTappedConversation: self.conversation)
        }
    }

    func initNilData() {
        logger.debug("未查询到教师和studio信息")
        inviteTeacherButton.isHidden = false
        loadingIndicatorView.stopAnimating()
        studioStackView.removeAllArrangedSubviews()
        pendingLabel.isHidden = true
        arrowImageView.isHidden = true
    }

    func initData(data: [(teacher: TKUser?, studio: TKStudio?)], isPending: Bool = false) {
        loadingIndicatorView.stopAnimating()
        pendingLabel.isHidden = !isPending
        inviteTeacherButton.isHidden = true
        studioStackView.removeAllArrangedSubviews()
        arrowImageView.isHidden = false
        for item in data.enumerated() {
            if item.element.studio == nil {
                continue
            }
            let view = TKView.create()
                .backgroundColor(color: UIColor.white)
            view.tag = item.offset
            view.onViewTapped { [weak self] _ in
                self?.delegate?.sStudioProfileCell(click: item.offset)
            }
            let avatarView: TKAvatarView = TKAvatarView()
            avatarView.layer.cornerRadius = 30
            avatarView.clipsToBounds = true
            avatarView.loadImage(storagePath: Tools.getStudioAvatarPath(id: item.element.studio!.id), style: .normal, name: item.element.studio!.name, refreshCached: true)
            view.addSubview(view: avatarView) { make in
                make.left.equalToSuperview()
                make.size.equalTo(60)
                make.centerY.equalToSuperview()
            }

            let titleLabel = TKLabel.create()
                .font(font: FontUtil.bold(size: 18))
                .textColor(color: ColorUtil.Font.third)
                .text(text: item.element.studio!.name)
            titleLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
            view.addSubview(view: titleLabel) { make in
                make.top.equalToSuperview().offset(18.5)
                make.left.equalTo(avatarView.snp.right).offset(10)
                make.right.equalToSuperview().offset(-20)
            }
            var detailString: String = ""
            if item.element.teacher != nil {
                detailString = item.element.teacher!.name
            }
            let detailLabel = TKLabel.create()
                .font(font: FontUtil.regular(size: 13))
                .textColor(color: ColorUtil.Font.primary)
                .text(text: detailString)
            view.addSubview(view: detailLabel) { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(5)
                make.left.equalTo(titleLabel.snp.left)
                make.right.equalToSuperview().offset(-20)
                make.bottom.equalToSuperview().offset(-23).priority(.medium)
            }
            if item.offset != data.count - 1 {
                let lineView = TKView.create()
                    .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
                view.addSubview(view: lineView) { make in
                    make.left.equalToSuperview().offset(20)
                    make.bottom.equalToSuperview()
                    make.right.equalToSuperview()
                    make.height.equalTo(1)
                }
            }
            studioStackView.addArrangedSubview(view)
        }
        loadConversation(conversation)
    }

    func loadConversation(_ conversation: TKConversation?) {
        self.conversation = conversation
        guard !loadingIndicatorView.isAnimating else { return }
        latestMessageView.loadConversation(conversation)
        if let conversation = conversation, conversation.latestMessage != nil {
            logger.debug("加载会话数据,当前会话数据存在")
            latestMessageView.snp.remakeConstraints { make in
                make.top.equalTo(studioStackView.snp.bottom)
                make.left.equalToSuperview().offset(90)
                make.height.equalTo(28)
                make.right.equalToSuperview().offset(-20)
                make.bottom.equalToSuperview().offset(-16).priority(.medium)
            }
            latestMessageView.isHidden = false
            chatIconButton.isHidden = true
        } else {
            logger.debug("加载会话数据,当前会话数据不存在")
            latestMessageView.snp.remakeConstraints { make in
                make.top.equalTo(studioStackView.snp.bottom)
                make.left.equalToSuperview().offset(90)
                make.height.equalTo(0)
                make.right.equalToSuperview().offset(-20)
                make.bottom.equalToSuperview().offset(-16).priority(.medium)
            }
            latestMessageView.isHidden = true
            chatIconButton.isHidden = false
        }
    }
}

protocol SStudioProfileCellDelegate: AnyObject {
    func sStudioProfileCell(click index: Int)
    func sStudioProfileCellInviteTeacherButtonTapped()
    func sStudioProfileCell(didTappedConversation conversation: TKConversation?)
}
