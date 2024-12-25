//
//  MaterialV3GridCollectionViewCell.swift
//  TuneKey
//
//  Created by 砚枫张 on 2024/4/23.
//  Copyright © 2024 spelist. All rights reserved.
//

import SDWebImage
import SnapKit
import UIKit

extension MaterialV3GridCollectionViewCell {
    struct IconImage {
        var name: String
        var url: String
        var size: CGSize
    }
}

class MaterialV3GridCollectionViewCell: TKBaseCollectionViewCell {
    private var avatarsContainerView: View = View()

    var id: String = ""
    
    @Live var iconImage: IconImage = .init(name: "", url: "", size: .zero)
    @Live var title: NSAttributedString = .init(string: "")
    @Live var subtitle: String = ""
    @Live var avatars: [AvatarView.Model] = []
    @Live var isPlayButtonShow: Bool = false
    @Live var playButtonSize: CGSize = .zero
    @Live var makePlayButtonCenter: Bool = false

    @Live var isEditable: Bool = false
    @Live var isFileSelected: Bool = false

    var onMoreButtonTapped: VoidFunc?
}

extension MaterialV3GridCollectionViewCell {
    override func initViews() {
        super.initViews()

        ViewBox(top: 0, left: 0, bottom: 0, right: 0) {
            VStack {
                ImageView()
                    .backgroundColor(.white)
                    .cornerRadius(5)
                    .borderWidth(1)
                    .borderColor(.border)
                    .masksToBounds(true)
                    .size(width: 108, height: 108)
                    .apply { [weak self] imageView in
                        guard let self = self else { return }
                        let playButton: ImageView = ImageView(image: UIImage(named: "mateialPlay"))
                            .isHidden($isPlayButtonShow)
                        playButton.addTo(superView: imageView) { _ in
                        }

                        let selectImageView = ImageView()
                            .addTo(superView: imageView) { make in
                                make.top.equalToSuperview().offset(10)
                                make.right.equalToSuperview().offset(-10)
                                make.size.equalTo(22)
                            }

                        self.$isEditable.addSubscriber { isEditable in
                            if isEditable {
                                selectImageView.isHidden = false
                            } else {
                                selectImageView.isHidden = true
                            }
                        }

                        self.$isFileSelected.addSubscriber { isFileSelected in
                            let image = if isFileSelected {
                                "checkboxOn"
                            } else {
                                "checkboxOff"
                            }
                            selectImageView.image = UIImage(named: image)
                        }

                        self.$playButtonSize.addSubscriber { size in
                            playButton.snp.remakeConstraints { make in
                                if self.makePlayButtonCenter {
                                    make.center.equalToSuperview()
                                } else {
                                    make.right.equalToSuperview().offset(-10)
                                    make.bottom.equalToSuperview().offset(-10)
                                }
                                make.size.equalTo(size)
                            }
                        }
                        self.$makePlayButtonCenter.addSubscriber { makePlayButtonCenter in
                            playButton.snp.remakeConstraints { make in
                                if makePlayButtonCenter {
                                    make.center.equalToSuperview()
                                } else {
                                    make.right.equalToSuperview().offset(-10)
                                    make.bottom.equalToSuperview().offset(-10)
                                }
                                make.size.equalTo(self.playButtonSize)
                            }
                        }
                        self.$iconImage.addSubscriber { iconImage in
                            if iconImage.name.isNotEmpty {
                                _ = imageView.image(UIImage(named: iconImage.name)?.resizeImage(iconImage.size))
                                    .contentMode(.center)
                            } else if iconImage.url.isNotEmpty {
                                imageView.contentMode(.scaleAspectFill)
                                    .sd_setImage(with: URL(string: iconImage.url)!)
                            } else {
                                _ = imageView.image(UIImage(named: "imagePlaceholder")?.resizeImage(CGSize(width: 60, height: 60)))
                                    .contentMode(.center)
                            }
                        }
                    }
                Spacer(spacing: 10)
                ViewBox(left: 10, right: 10) {
                    VStack {
                        VStack(spacing: 2) {
                            Label().attributedText($title)
                                .textColor(.primary)
                                .font(.content)

                            Label($subtitle).textColor(.tertiary)
                                .font(.tinyContent)
                        }
                        Spacer(spacing: 7)
                        HStack(spacing: 5) {
                            avatarsContainerView
                            Button().image(UIImage(named: "ic_more_primary"), for: .normal)
                                .size(width: 22, height: 22)
                                .onTapped { [weak self] _ in
                                    guard let self = self else { return }
                                    self.onMoreButtonTapped?()
                                }
                        }
                    }
                }
            }
        }.fill(in: contentView)
    }

    override func bindEvents() {
        super.bindEvents()

        $avatars.addSubscriber { [weak self] avatars in
            guard let self = self else { return }
            self.avatarsContainerView.subviews.forEach({ $0.removeFromSuperview() })
            var previousAvatarView: AvatarView?
            for avatar in avatars {
                let avatarView = AvatarView(size: 20)
                    .loadAvatar(withUser: avatar)
                    .addTo(superView: avatarsContainerView) { make in
                        make.centerY.equalToSuperview()
                        make.size.equalTo(20)
                        if let previousAvatarView {
                            make.left.equalTo(previousAvatarView.snp.centerX)
                        } else {
                            make.left.equalToSuperview()
                        }
                    }

                previousAvatarView = avatarView
            }
        }
    }
}
