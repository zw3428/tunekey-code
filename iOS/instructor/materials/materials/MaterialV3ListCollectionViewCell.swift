//
//  MaterialV3ListCollectionViewCell.swift
//  TuneKey
//
//  Created by 砚枫张 on 2024/4/25.
//  Copyright © 2024 spelist. All rights reserved.
//

import SDWebImage
import SnapKit
import UIKit

class MaterialV3ListCollectionViewCell: TKBaseCollectionViewCell {
    private var avatarsContainerView: View = View()
    
    var id: String = ""
    
    @Live var isPlayButtonShow: Bool = false
    @Live var playButtonSize: CGSize = .zero
    @Live var makePlayButtonCenter: Bool = false
    @Live var iconImage: MaterialV3GridCollectionViewCell.IconImage = .init(name: "", url: "", size: .zero)
    @Live var avatars: [AvatarView.Model] = []
    @Live var title: NSAttributedString = .init(string: "")
    @Live var info: String = ""
    @Live var isEditable: Bool = false
    @Live var isFileSelected: Bool = false
    
    var onMoreButtonTapped: VoidFunc?
}

extension MaterialV3ListCollectionViewCell {
    override func initViews() {
        super.initViews()

        ViewBox {
            VStack {
                ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                    HStack (alignment: .center, spacing: 10) {
                        ImageView().size(width: 22, height: 22)
                            .isShow($isEditable)
                            .apply { [weak self] imageView in
                                guard let self = self else { return }
                                self.$isFileSelected.addSubscriber { isFileSelected in
                                    let image = if isFileSelected {
                                        "checkboxOn"
                                    } else {
                                        "checkboxOff"
                                    }
                                    imageView.image = UIImage(named: image)
                                }
                            }
                        HStack(alignment: .top, spacing: 10) {
                            VStack {
                                ImageView()
                                    .backgroundColor(.white)
                                    .cornerRadius(5)
                                    .borderWidth(1)
                                    .borderColor(.border)
                                    .masksToBounds(true)
                                    .size(width: 60, height: 60)
                                    .apply { [weak self] imageView in
                                        guard let self = self else { return }
                                        let playButton: ImageView = ImageView(image: UIImage(named: "mateialPlay"))
                                            .isHidden($isPlayButtonShow)
                                        playButton.addTo(superView: imageView) { _ in
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
                                
                                View().placeholderable(for: .vertical)
                            }
                            
                            VStack(spacing: 6) {
                                HStack (alignment: .top, spacing: 10){
                                    Label().attributedText($title)
                                        .textColor(.primary)
                                        .font(.title)
                                        .numberOfLines(3)
                                    
                                    VStack(alignment: .trailing) {
                                        Button().image(UIImage(named: "ic_more_primary"), for: .normal)
                                            .size(width: 22, height: 22)
                                            .onTapped { [weak self] _ in
                                                guard let self = self else { return }
                                                self.onMoreButtonTapped?()
                                            }
                                    }.width(40)
                                }
                                
                                HStack(alignment: .center, spacing: 10){
                                    Label($info).textColor(.tertiary)
                                        .font(.content)
                                    avatarsContainerView.size(width: 40, height: 20)
                                }
                                
                                View().placeholderable(for: .vertical)
                            }
                        }
                    }
                }
                
                ViewBox(left: 20, right: 20) {
                    Divider(weight: 1, color: .line)
                }.height(1)
            }
        }
        .fill(in: contentView)
    }
}

extension MaterialV3ListCollectionViewCell {
    override func bindEvents() {
        super.bindEvents()

        $avatars.addSubscriber { [weak self] avatars in
            guard let self = self else { return }
            self.avatarsContainerView.subviews.forEach({ $0.removeFromSuperview() })
            var previousAvatarView: AvatarView?
            for (_, avatar) in avatars.prefix(3).enumerated() {
                let avatarView = AvatarView(size: 20)
                    .loadAvatar(withUser: avatar)
                    .addTo(superView: avatarsContainerView) { make in
                        make.centerY.equalToSuperview()
                        make.size.equalTo(20)
                        if let previousAvatarView {
                            make.right.equalTo(previousAvatarView.snp.centerX)
                        } else {
                            make.right.equalToSuperview()
                        }
                    }

                previousAvatarView = avatarView
            }
        }
    }
}
