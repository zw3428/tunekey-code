//
//  MaterialFolderCollectionViewCell.swift
//  TuneKey
//
//  Created by zyf on 2020/10/16.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class MaterialFolderCollectionViewCell: UICollectionViewCell {
    private var containerView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 5)
        .showBorder(color: ColorUtil.borderColor)
        .showShadow()
    private var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.Font.primary)
        .alignment(alignment: .center)

    private var centerIconView: TKImageView = TKImageView.create()

    private lazy var homeIconImage: UIImage = UIImage(named: "home")!
    private lazy var addIconImage: UIImage = UIImage(named: "icAddPrimary")!
    private lazy var folderIconImage: UIImage = UIImage(named: "materials_selected")!

    private var imageView1: TKImageView = TKImageView.create()
    private var imageView2: TKImageView = TKImageView.create()
    private var imageView3: TKImageView = TKImageView.create()
    private var imageView4: TKImageView = TKImageView.create()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MaterialFolderCollectionViewCell {
    private func initView() {
        contentView.backgroundColor = .white
        containerView.backgroundColor = ColorUtil.folderBackground
        containerView.addTo(superView: contentView) { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(contentView.snp.width)
        }

        centerIconView.addTo(superView: containerView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }

        imageView1.cornerRadius = 5
        imageView2.cornerRadius = 5
        imageView3.cornerRadius = 5
        imageView4.cornerRadius = 5

        imageView1.contentMode = .scaleAspectFill
        imageView2.contentMode = .scaleAspectFill
        imageView3.contentMode = .scaleAspectFill
        imageView4.contentMode = .scaleAspectFill
        let imageViewSize = (contentView.frame.width - 15) / 2
        imageView1.addTo(superView: containerView) { make in
            make.left.top.equalToSuperview().offset(5)
            make.size.equalTo(imageViewSize)
        }

        imageView2.addTo(superView: containerView) { make in
            make.top.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.size.equalTo(imageViewSize)
        }

        imageView3.addTo(superView: containerView) { make in
            make.left.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
            make.size.equalTo(imageViewSize)
        }

        imageView4.addTo(superView: containerView) { make in
            make.bottom.right.equalToSuperview().offset(-5)
            make.size.equalTo(imageViewSize)
        }

        titleLabel.addTo(superView: contentView) { make in
            make.top.equalTo(containerView.snp.bottom).offset(5)
            make.left.right.equalToSuperview()
            make.height.equalTo(20)
        }
    }

    func loadData(data: TKMaterialFolderModel) {
        if data.isSelected {
            containerView.showBorder(color: ColorUtil.main, width: 2)
        } else {
            containerView.showBorder(color: ColorUtil.borderColor, width: 2)
        }
        centerIconView.isHidden = true
        imageView1.isHidden = true
        imageView2.isHidden = true
        imageView3.isHidden = true
        imageView4.isHidden = true
        switch data.type {
        case .home:
            titleLabel.text = "Home"
            centerIconView.isHidden = false
            centerIconView.image = homeIconImage
        case .createNewFolder:
            titleLabel.text = "New folder"
            centerIconView.isHidden = false
            centerIconView.image = addIconImage
        case .folder:
            titleLabel.text = data.data?.name ?? ""
            guard let material = data.data, material.type == .folder else {
                return
            }
            centerIconView.isHidden = false
            centerIconView.image = folderIconImage
//            if material.materials.count > 0 {
//                let materials = material.materials
//                if materials.count >= 1 {
//                    let item = materials[0]
//                    // 获取封面图片
//                    setImageView(imageView: imageView1, data: item)
//                }
//                if materials.count >= 2 {
//                    let item = materials[1]
//                    setImageView(imageView: imageView2, data: item)
//                }
//
//                if materials.count >= 3 {
//                    let item = materials[2]
//                    setImageView(imageView: imageView3, data: item)
//                }
//
//                if materials.count >= 4 {
//                    let item = materials[3]
//                    setImageView(imageView: imageView4, data: item)
//                }
//            } else {
//                centerIconView.isHidden = false
//                centerIconView.image = folderIconImage
//            }
        }
    }

    private func setImageView(imageView: TKImageView, data: TKMaterial) {
        imageView.isHidden = false
        switch data.type {
        case .none, .folder: break
        case .file: imageView.image = UIImage(named: "otherFile")
        case .pdf: imageView.image = UIImage(named: "imgPdf")
        case .image: imageView.setImageForUrl(imageUrl: data.url, placeholderImage: ImageUtil.getImage(color: ColorUtil.imagePlaceholderDark))
        case .txt: imageView.image = UIImage(named: "imgTxt")
        case .word: imageView.image = UIImage(named: "imgDoc")
        case .ppt: imageView.image = UIImage(named: "imgPpt")
        case .mp3: imageView.image = UIImage(named: "imgMp3")
        case .video: imageView.setImageForUrl(imageUrl: data.minPictureUrl, placeholderImage: ImageUtil.getImage(color: ColorUtil.imagePlaceholderDark))
        case .youtube: imageView.setImageForUrl(imageUrl: data.minPictureUrl, placeholderImage: ImageUtil.getImage(color: ColorUtil.imagePlaceholderDark))
        case .link: imageView.setImageForUrl(imageUrl: data.minPictureUrl, placeholderImage: UIImage(named: "linkResource")!)
        case .excel: imageView.image = UIImage(named: "imgExecl")
        case .pages: imageView.image = UIImage(named: "imgPages")
        case .numbers: imageView.image = UIImage(named: "imgNumbers")
        case .keynote: imageView.image = UIImage(named: "imgKeynotes")
        case .googleDoc: imageView.image = UIImage(named: "imgDocs")
        case .googleSheet: imageView.image = UIImage(named: "imgSheets")
        case .googleSlides: imageView.image = UIImage(named: "imgSlides")
        case .googleForms: imageView.image = UIImage(named: "imgForms")
        case .googleDrawings: imageView.image = UIImage(named: "imgDrawing")
        }
    }
}
