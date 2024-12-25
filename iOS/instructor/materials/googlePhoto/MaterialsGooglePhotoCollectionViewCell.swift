//
//  MaterialsGooglePhotoCollectionViewCell.swift
//  TuneKey
//
//  Created by zyf on 2020/12/18.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

protocol MaterialsGooglePhotoCollectionViewCellDelegate: AnyObject {
    func materialsGooglePhotoCollectionViewCell(didSelect cell: MaterialsGooglePhotoCollectionViewCell, isSelected: Bool, file: GooglePhotoMediaItem)
}

class MaterialsGooglePhotoCollectionViewCell: UICollectionViewCell {
    weak var delegate: MaterialsGooglePhotoCollectionViewCellDelegate?

    private var file: GooglePhotoMediaItem?

    private var iconImageView: TKImageView = TKImageView.create()
    private var tipView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.folderBackground)
    private var tipLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.Font.primary)
        .alignment(alignment: .center)

    private var selectIconImageView: TKImageView = TKImageView.create()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MaterialsGooglePhotoCollectionViewCell {
    private func initView() {
        let containerView = TKView.create()
            .backgroundColor(color: .white)
            .addTo(superView: contentView) { make in
                make.top.equalToSuperview().offset(10)
                make.size.equalTo(108)
                make.centerX.equalToSuperview()
            }
        iconImageView.addTo(superView: containerView) { make in
            make.size.equalTo(108)
            make.center.equalToSuperview()
        }
        iconImageView.contentMode = .center
        iconImageView.cornerRadius = 5
        containerView.cornerRadius = 5
        containerView.setBorder(borderWidth: 1, borderColor: ColorUtil.borderColor)
        containerView.clipsToBounds = true

        selectIconImageView.addTo(superView: contentView) { make in
            make.top.equalTo(containerView.snp.top).offset(2)
            make.right.equalTo(containerView.snp.right).offset(-2)
            make.size.equalTo(22)
        }
        selectIconImageView.image = UIImage(named: "checkBoxOff")
        tipView.addTo(superView: containerView) { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(30)
        }

        tipLabel.addTo(superView: tipView) { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalToSuperview()
        }
        tipView.isHidden = true

        contentView.onViewTapped { [weak self] _ in
            self?.onContentViewTapped()
        }
    }

    private func onContentViewTapped() {
        guard let file = file else { return }
        if let video = file.mediaMetadata?.video {
            if video.status != .READY {
                return
            }
        }
        isSelected.toggle()
        selectIconImageView.image = UIImage(named: isSelected ? "checkboxOn" : "checkboxOff")

        delegate?.materialsGooglePhotoCollectionViewCell(didSelect: self, isSelected: isSelected, file: file)
    }

    public func loadData(file: GooglePhotoMediaItem) {
        self.file = file
        selectIconImageView.image = UIImage(named: isSelected ? "checkboxOn" : "checkboxOff")
        iconImageView.setImage(url: file.baseUrl)
        tipView.isHidden = true
        if let video = file.mediaMetadata?.video {
            if video.status != .READY {
                tipView.isHidden = false
                tipLabel.text(video.status.rawValue)
            }
        }
    }
}
