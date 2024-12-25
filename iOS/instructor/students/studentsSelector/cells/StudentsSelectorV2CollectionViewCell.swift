//
//  StudentsSelectorV2CollectionViewCell.swift
//  TuneKey
//
//  Created by zyf on 2022/11/14.
//  Copyright © 2022 spelist. All rights reserved.
//

import SnapKit
import UIKit

class StudentsSelectorV2CollectionViewCell: TKBaseCollectionViewCell {
    static let id: String = String(describing: StudentsSelectorV2CollectionViewCell.self)
    @Live var isSelect: Bool = false
    @Live var isSelection: Bool = false

    @Live var student: TKStudent?
    @Live var info: String = ""

    @Live var buttonTitle: String = ""
    @Live var buttonColor: UIColor = ColorUtil.main
    @Live var isButtonShow: Bool = false

    @Live var parent: TKUser?

    @Live var studentConversation: TKConversation?
    @Live var parentConversation: TKConversation?

    var onStudentTapped: VoidFunc?
}

extension StudentsSelectorV2CollectionViewCell {
    override func initViews() {
        super.initViews()
        let width: CGFloat
        if UIScreen.main.bounds.width > 650 {
            width = UIScreen.main.bounds.width / 2 - 10
        } else {
            width = UIScreen.main.bounds.width
        }
        ViewBox {
            VStack {
                ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                    VStack(spacing: 16) {
                        HStack(alignment: .center, spacing: 20) {
                            ImageView(image: UIImage(named: "checkboxOff")).size(width: 22, height: 22)
                                .isShow($isSelection)
                                .apply { [weak self] imageView in
                                    guard let self = self else { return }
                                    self.$isSelect.addSubscriber { isSelect in
                                        if isSelect {
                                            imageView.image = UIImage(named: "checkboxOn")
                                        } else {
                                            imageView.image = UIImage(named: "checkboxOff")
                                        }
                                    }
                                }
                            View().size(width: 60, height: 60)
                                .apply { view in
                                    AvatarView(size: 60)
                                        .apply { [weak self] avatarView in
                                            guard let self = self else { return }
                                            self.$student.addSubscriber { student in
                                                guard let student = student else { return }
                                                avatarView.loadAvatar(withUserId: student.studentId, name: student.name)
                                            }
                                        }
                                        .addTo(superView: view) { make in
                                            make.center.size.equalToSuperview()
                                        }
                                    AvatarView(size: 22).size(width: 22, height: 22)
                                        .apply { [weak self] avatarView in
                                            guard let self = self else { return }
                                            self.$parent.addSubscriber { parent in
                                                if let parent = parent {
                                                    avatarView.loadAvatar(withUserId: parent.userId, name: parent.name)
                                                    avatarView.isHidden = false
                                                } else {
                                                    avatarView.isHidden = true
                                                }
                                            }
                                        }
                                        .addTo(superView: view) { make in
                                            make.size.equalTo(22)
                                            make.right.bottom.equalToSuperview()
                                        }
                                }
                            VStack {
                                Label().textColor(ColorUtil.Font.third)
                                    .font(.bold(18))
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$student.addSubscriber { student in
                                            guard let student = student else { return }
                                            label.text = student.name
                                        }
                                    }
                                Label($info).textColor(ColorUtil.Font.primary)
                                    .font(.regular(size: 15))
                                    .numberOfLines(2)
                            }
                            .contentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
                            .contentHuggingPriority(.fittingSizeLevel, for: .horizontal)
                            Button().height(28)
                                .isShow($isButtonShow)
                                .apply { [weak self] button in
                                    guard let self = self else { return }
                                    self.$buttonTitle.addSubscriber { title in
                                        _ = button.title(title, for: .normal)
                                    }
                                    self.$buttonColor.addSubscriber { color in
                                        _ = button.backgroundColor(color)
                                    }
                                }
                            ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                        }
                        .onViewTapped { [weak self] _ in
                            self?.onStudentTapped?()
                        }

                        ViewBox(top: 0, left: 80, bottom: 0, right: 20) {
                            VStack(spacing: 16) {
                                ViewBox(top: 5, left: 10, bottom: 5, right: 10) {
                                    HStack(spacing: 10) {
                                        ImageView(image: UIImage(named: "message_gray")).size(width: 18, height: 18)
                                        Label().textColor(ColorUtil.Font.primary).font(.regular(size: 15))
                                            .contentHuggingPriority(.fittingSizeLevel, for: .horizontal)
                                            .contentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
                                            .apply { [weak self] label in
                                                guard let self = self else { return }
                                                self.$studentConversation.addSubscriber { conversation in
                                                    guard let conversation = conversation else { return }
                                                    guard let message = conversation.latestMessage else { return }
                                                    label.text = message.messageText()
                                                }
                                                self.$parentConversation.addSubscriber { parentConversation in
                                                    let studentConversation = self.studentConversation
                                                    let timeP = parentConversation?.latestMessageTimestamp ?? 0
                                                    let timeS = studentConversation?.latestMessageTimestamp ?? 0
                                                    guard timeP != 0 || timeS != 0 else { return }
                                                    var message: TKMessage?
                                                    if timeP > timeS {
                                                        // 家长的是最新的消息
                                                        message = parentConversation?.latestMessage
                                                    } else {
                                                        // 学生的是最新的消息
                                                        message = studentConversation?.latestMessage
                                                    }
                                                    label.text = message?.messageText() ?? ""
                                                }
                                                
                                                self.$studentConversation.addSubscriber { studentConversation in
                                                    let parentConversation = self.parentConversation
                                                    let timeP = parentConversation?.latestMessageTimestamp ?? 0
                                                    let timeS = studentConversation?.latestMessageTimestamp ?? 0
                                                    guard timeP != 0 || timeS != 0 else { return }
                                                    var message: TKMessage?
                                                    if timeP > timeS {
                                                        // 家长的是最新的消息
                                                        message = parentConversation?.latestMessage
                                                    } else {
                                                        // 学生的是最新的消息
                                                        message = studentConversation?.latestMessage
                                                    }
                                                    label.text = message?.messageText() ?? ""
                                                }
                                            }
                                        Label().textColor(ColorUtil.Font.primary).font(.regular(size: 15))
                                            .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                            .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                                            .apply { [weak self] label in
                                                guard let self = self else { return }
                                                self.$parentConversation.addSubscriber { parentConversation in
                                                    let studentConversation = self.studentConversation
                                                    let timeP = parentConversation?.latestMessageTimestamp ?? 0
                                                    let timeS = studentConversation?.latestMessageTimestamp ?? 0
                                                    guard timeP != 0 || timeS != 0 else { return }
                                                    var message: TKMessage?
                                                    if timeP > timeS {
                                                        // 家长的是最新的消息
                                                        message = parentConversation?.latestMessage
                                                    } else {
                                                        // 学生的是最新的消息
                                                        message = studentConversation?.latestMessage
                                                    }
                                                    label.text = message?.messageText() ?? ""
                                                }
                                                
                                                self.$studentConversation.addSubscriber { studentConversation in
                                                    let parentConversation = self.parentConversation
                                                    let timeP = parentConversation?.latestMessageTimestamp ?? 0
                                                    let timeS = studentConversation?.latestMessageTimestamp ?? 0
                                                    guard timeP != 0 || timeS != 0 else { return }
                                                    var message: TKMessage?
                                                    let role: String
                                                    if timeP > timeS {
                                                        // 家长的是最新的消息
                                                        message = parentConversation?.latestMessage
                                                        role = "Parent"
                                                    } else {
                                                        // 学生的是最新的消息
                                                        message = studentConversation?.latestMessage
                                                        role = "Student"
                                                    }
                                                    guard let message = message else { return }
                                                    label.text = "\(role), \(message.datetime.timeStringWithoutTime())"
                                                }
                                            }
                                    }
                                }
                                .backgroundColor(UIColor(hex: "#f3f3f4"))
                                .cornerRadius(3)
                            }
                        }
                        .apply { [weak self] view in
                            guard let self = self else { return }
                            self.$studentConversation.addSubscriber { studentConversation in
                                if studentConversation == nil && self.parentConversation == nil {
                                    view.isHidden = true
                                } else {
                                    view.isHidden = false
                                }
                            }

                            self.$parentConversation.addSubscriber { parentConversation in
                                if parentConversation == nil && self.studentConversation == nil {
                                    view.isHidden = true
                                } else {
                                    view.isHidden = false
                                }
                            }
                        }

                        /// tags
                        //                ViewBox(top: 0, left: 80, bottom: 0, right: 20) {
                        //                    HStack {
                        //                        Label()
                        //                    }
                        //                }
                    }
                }
                ViewBox(left: 20) {
                    Divider(weight: 1, color: ColorUtil.dividingLine)
                }.height(1)
            }
        }
        .width(width)
        .fill(in: contentView)
    }
}
