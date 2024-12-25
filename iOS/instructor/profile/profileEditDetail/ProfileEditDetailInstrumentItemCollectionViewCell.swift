//
//  ProfileEditDetailInstrumentItemCollectionViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/9.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileEditDetailInstrumentItemCollectionViewCell: UICollectionViewCell {
    var data: TKInstrument!
    var isItemSelected: Bool = false

    var selectedView: TKView = TKView.create()
        .backgroundColor(color: UIColor.black.withAlphaComponent(0.4))
    var selectedContainerView: TKView = TKView.create()
    
    var imageView: TKImageView!
    private var nameLabel: TKLabel!
    private var coverView: TKView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileEditDetailInstrumentItemCollectionViewCell {
    private func initView() {
        contentView.backgroundColor = UIColor.white

        imageView = TKImageView.create()
            .setSize(contentView.frame.width)
            .asCircle()
        contentView.addSubview(view: imageView) { make in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(self.contentView.snp.width)
            make.centerX.equalToSuperview()
        }
        selectedView.addTo(superView: contentView) { make in
            make.center.equalTo(imageView)
            make.size.equalTo(imageView)
        }
        selectedView.isHidden = true
        selectedContainerView.addTo(superView: selectedView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }

        nameLabel = TKLabel.create()
            .font(font: FontUtil.medium(size: 10))
            .textColor(color: ColorUtil.Font.fourth)
            .alignment(alignment: .center)
            .setNumberOfLines(number: 0)
        contentView.addSubview(view: nameLabel) { make in
//            make.bottom.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(5)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    func loadData(data: TKInstrument) {
        self.data = data
        if data.minPictureUrl != "" {
            imageView.setImage(url: data.minPictureUrl)
            imageView.borderWidth = 0
            imageView.contentMode = .scaleAspectFit
        } else {
            imageView.contentMode = .center
            if #available(iOS 13.0, *) {
                imageView.image = UIImage(named: "8|8")?.resizeImage(CGSize(width: 50, height: 50)).withTintColor(ColorUtil.gray)
            } else {
                imageView.image = UIImage(named: "8|8")?.resizeImage(CGSize(width: 50, height: 50))
                imageView.tintColor = ColorUtil.gray
            }
            imageView.setBorder()
        }
        nameLabel.text(data.name)
    }
}
