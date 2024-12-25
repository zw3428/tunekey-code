//
//  MaterialsCell.swift
//  TuneKey
//
//  Created by Wht on 2019/8/29.
//  Copyright © 2019年 spelist. All rights reserved.
//
import SnapKit
import UIKit
import SDWebImage

class MaterialsCell: UICollectionViewCell {
    var backView: UIView!
    var showView: UIView!
    var typeImageView: UIImageView!
    var typeImageBackView: TKView = TKView.create()
    var studioLogoImageView: TKAvatarView = TKAvatarView()
//    private var fromTeacherImageView: TKView = {
//        let view = TKView.create()
//        view.layer.cornerRadius = 5
//        view.layer.maskedCorners = [.layerMaxXMinYCorner]
//        view.clipsToBounds = true
//
//        let layer = CAShapeLayer()
//        layer.cornerRadius = 5
//        layer.maskedCorners = [.layerMaxXMinYCorner]
//        let path = UIBezierPath()
//        path.move(to: CGPoint(x: 0, y: 0))
//        path.addLine(to: CGPoint(x: 50, y: 50))
//        path.addLine(to: CGPoint(x: 50, y: 0))
//        path.addLine(to: CGPoint(x: 0, y: 0))
//        layer.path = path.cgPath
//        layer.backgroundColor = ColorUtil.main.cgColor
//        layer.fillColor = ColorUtil.main.cgColor
//        view.layer.addSublayer(layer)
//        TKImageView.create()
//            .setImage(name: "share-from-teacher")
//            .addTo(superView: view) { make in
//                make.top.equalToSuperview().offset(3)
//                make.right.equalToSuperview().offset(-3)
//                make.size.equalTo(22)
//            }
    ////        view.backgroundColor = ColorUtil.main
//        return view
//    }()

    private var childImageView1: TKImageView = .create()
    private var childImageView2: TKImageView = .create()
    private var childImageView3: TKImageView = .create()
    private var childImageView4: TKImageView = .create()
    var playImageView: TKPlayerButton!
    var titleLabel: TKLabel!
    var timeLabel: TKLabel!
    var linkLabel: TKLabel!
    var studentView: UIView!
    var studentAvatarView: TKFoldingAvatar!

//    private var processingView: TKView = {
//        let view = TKView.create()
//            .backgroundColor(color: ColorUtil.folderBackground)
//            .corner(size: 5)
//            .maskCorner(masks: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
//        TKLabel.create()
//            .font(font: FontUtil.regular(size: 13))
//            .textColor(color: ColorUtil.Font.fourth)
//            .text(text: "PROCESSING")
//            .alignment(alignment: .center)
//            .setNumberOfLines(number: 1)
//            .addTo(superView: view) { make in
//                make.left.right.equalToSuperview()
//                make.centerY.equalToSuperview()
//            }
//        return view
//    }()

    var checkImage: UIImageView!
    // showView初始的size
    var cellInitialSize: CGSize!
    var isLoad = false
    weak var delegate: MaterialsCellDelegate?
    var isEdit = false
    var itemData: TKMaterial!
    var isSelect: Bool!

    var imagePlaceholder: UIImage = ImageUtil.getImage(color: UIColor(named: "imagePlaceholder")!)

    var shareButton: TKButton = TKButton.create()
        .title(title: "Share")
        .titleFont(font: FontUtil.bold(size: 12))
        .titleColor(color: ColorUtil.main)

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
        initEvent()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View

extension MaterialsCell {
    func initEvent() {
        showView.isUserInteractionEnabled = true
        showView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickItem)))
        titleLabel.isUserInteractionEnabled = true
        titleLabel.onTouchesBegan { [weak self] _, _ in
            self?.titleLabel.textColor(color: ColorUtil.main)
        }
        titleLabel.onTouchesMoved { [weak self] _, _ in
            self?.titleLabel.textColor(color: ColorUtil.main)
        }
        titleLabel.onTouchesEnded { [weak self] _, _ in
            guard let self = self else { return }
            self.titleLabel.textColor(color: ColorUtil.Font.primary)
            self.delegate?.materialsCell(titleLabelDidSelectedAt: self.tag, cell: self)
            Tools.shake(.short)
        }
        titleLabel.onTouchesCancelled { [weak self] _, _ in
            self?.titleLabel.textColor(color: ColorUtil.Font.primary)
        }

        shareButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.materialsCell(shareButtonTappedAt: self.tag, cell: self)
        }
        studentView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.materialsCell(shareButtonTappedAt: self.tag, cell: self)
        }
    }

    @objc private func clickItem(sender: UITapGestureRecognizer) {
        guard let data = itemData else { return }
        if isEdit {
            if data.isOwnMaterials {
                itemData._isSelected.toggle()
                delegate?.clickItem(materialsData: itemData, cell: self)
                return
            }
        }
        delegate?.clickItem(materialsData: itemData, cell: self)
    }

    func initView() {
        backView = UIView()
        contentView.clipsToBounds = true
        contentView.addSubview(backView)
        //        backView.setTKBorderAndRaius()
        backView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
        backView.backgroundColor = ColorUtil.backgroundColor
        backView.clipsToBounds = true

        showView = UIView()
        backView.addSubview(showView)
        showView.snp.makeConstraints { make in
            make.width.equalTo(self.contentView.frame.width)
            make.height.equalTo(self.contentView.frame.width)
            make.left.top.equalToSuperview()
        }
        showView.backgroundColor = ColorUtil.backgroundColor
        showView.setTKBorderAndRaius()
        typeImageBackView.corner(size: 5)
            .backgroundColor(color: .clear)
        typeImageBackView.addTo(superView: showView) { make in
            make.edges.equalToSuperview()
        }
        typeImageView = UIImageView()
        typeImageView.backgroundColor = ColorUtil.folderBackground
        showView.addSubview(typeImageView)
        typeImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(28)
            make.right.equalToSuperview().offset(-28)
            make.top.equalToSuperview().offset(22)
            make.bottom.equalToSuperview().offset(-22)
        }
        typeImageView.contentMode = .center
        typeImageView.image = UIImage(named: "imgMp3")

        studioLogoImageView.setBorder(borderWidth: 1, borderColor: ColorUtil.backgroundColor)
        studioLogoImageView.layer.cornerRadius = 8
        studioLogoImageView.clipsToBounds = true
        studioLogoImageView.addTo(superView: showView) { make in
            make.top.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-2)
            make.size.equalTo(16)
        }
        studioLogoImageView.isHidden = true

//        fromTeacherImageView.addTo(superView: showView) { make in
//            make.top.equalToSuperview()
//            make.right.equalToSuperview()
//            make.size.equalTo(50)
//        }
//        fromTeacherImageView.isHidden = true
        childImageView1.cornerRadius = 5
        childImageView2.cornerRadius = 5
        childImageView3.cornerRadius = 5
        childImageView4.cornerRadius = 5
        childImageView1.isHidden = true
        childImageView2.isHidden = true
        childImageView3.isHidden = true
        childImageView4.isHidden = true
        childImageView1.contentMode = .scaleAspectFill
        childImageView2.contentMode = .scaleAspectFill
        childImageView3.contentMode = .scaleAspectFill
        childImageView4.contentMode = .scaleAspectFill
        let contentWidth: CGFloat = (UIScreen.main.bounds.width - 50) / 3
        let imageViewSize = (contentWidth - 15) / 2
        childImageView1.addTo(superView: showView) { make in
            make.top.left.equalToSuperview().offset(5)
            make.size.equalTo(imageViewSize)
        }
        childImageView2.addTo(superView: showView) { make in
            make.top.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.size.equalTo(imageViewSize)
        }
        childImageView3.addTo(superView: showView) { make in
            make.left.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
            make.size.equalTo(imageViewSize)
        }
        childImageView4.addTo(superView: showView) { make in
            make.bottom.right.equalToSuperview().offset(-5)
            make.size.equalTo(imageViewSize)
        }

        playImageView = TKPlayerButton()
        showView.addSubview(playImageView)
        playImageView.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.size.equalTo(40)
        }
        playImageView.isHidden = true

        titleLabel = TKLabel()
        titleLabel.setNumberOfLines(number: 2)
        backView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(showView.snp.left)
            make.right.equalTo(showView.snp.right)
//            make.height.equalTo(20)
            make.top.equalTo(showView.snp.bottom).offset(20)
        }
        titleLabel.textColor(color: ColorUtil.Font.primary).font(FontUtil.regular(size: 13))
        titleLabel.text("FileName")

        linkLabel = TKLabel()
        backView.addSubview(linkLabel)
        linkLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(0)
            make.top.equalTo(titleLabel.snp.bottom).offset(0)
        }
        linkLabel.textColor(color: ColorUtil.Font.fourth).font(FontUtil.regular(size: 10))
        linkLabel.text("Link")

        timeLabel = TKLabel()
        backView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(13)
            make.top.equalTo(linkLabel.snp.bottom).offset(2)
        }
        timeLabel.textColor(color: ColorUtil.Font.fourth).font(FontUtil.regular(size: 10))
        timeLabel.text("Time")
        timeLabel.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.materialsCell(titleLabelDidSelectedAt: self.tag, cell: self)
        }

        shareButton.addTo(superView: backView) { make in
            make.left.equalToSuperview()
            make.top.equalTo(timeLabel.snp.bottom).offset(2)
            make.height.equalTo(20)
        }
        shareButton.isHidden = true

        studentView = UIView()
        backView.addSubview(studentView)
        studentView.snp.makeConstraints { make in
            make.left.equalToSuperview()
//            make.top.equalTo(timeLabel.snp.bottom).offset(6)
            make.top.equalTo(timeLabel.snp.bottom).offset(2)
            make.right.equalToSuperview()
//            make.height.equalTo(20)
            make.height.equalTo(0)
        }

        studentAvatarView = TKFoldingAvatar(frame: CGRect.zero, size: 20)
        studentView.addSubview(studentAvatarView)
        studentAvatarView.layer.masksToBounds = true
        studentAvatarView.snp.makeConstraints { make in
            make.right.left.top.equalToSuperview()
            make.height.equalTo(0)
        }
        studentAvatarView.onTapped { [weak self] in
            guard let self = self else { return }
            logger.debug("student avatar view tapped")
            self.delegate?.materialsCell(shareButtonTappedAt: self.tag, cell: self)
        }
//        viewAll = TKLabel()
//        viewAll.textColor(color: ColorUtil.main).font(font: FontUtil.bold(size: 12)).text("view all")
//        studentView.addSubview(viewAll)
//        viewAll.snp.makeConstraints { make in
//            make.right.equalToSuperview()
        ////            make.height.equalTo(20)
//            make.height.equalTo(0)
//        }
        checkImage = UIImageView()
        backView.addSubview(checkImage)
        checkImage.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(22)
        }
        checkImage.image = UIImage(named: "checkboxOffBlack")
        checkImage.isHidden = true
        checkImage.onViewTapped { [weak self] _ in
            guard let self = self, let data = self.itemData, data.isOwnMaterials else { return }
            data._isSelected.toggle()
            self.delegate?.materialsCell(checkBoxDidTappedAt: self.tag, materialsData: data, cell: self)
        }

//        showView.addSubview(view: processingView) { make in
//            make.left.right.bottom.equalToSuperview()
//            make.height.equalTo(30)
//        }
//        processingView.isHidden = true
    }

    func edit(_ isEdit: Bool) {
        self.isEdit = isEdit
        checkImage.isHidden = !isEdit
        if !(itemData?.isOwnMaterials ?? false) {
            checkImage.image = UIImage(named: "ban")
        } else {
            checkImage.image = UIImage(named: "checkboxOff")
        }
//        if isEdit {
//            fromTeacherImageView.isHidden = true
//        } else {
//            if (itemData?.isOwnMaterials ?? false) {
//                fromTeacherImageView.isHidden = true
//            } else {
//                fromTeacherImageView.isHidden = false
//            }
//        }
    }

    func updateCheckBox() {
        guard let itemData = itemData else { return }
        if itemData.type == .folder {
            if itemData.materials.filter({ !$0._isSelected }).count > 0 && itemData.materials.filter({ $0._isSelected }).count > 0 {
                checkImage.image = UIImage(named: "checkBoxUnAll")
                showView.borderWidth = 1
            } else {
                if itemData._isSelected {
                    showView.borderWidth = 1
                    checkImage.image = UIImage(named: "checkboxOn")
                } else {
                    showView.borderWidth = 0
                    checkImage.image = UIImage(named: "checkboxOff")
                }
            }
        } else {
            logger.debug("更新checkBox,当前数据: \(itemData.id) | 是否已经选中: \(itemData._isSelected)")
            showView.borderWidth = itemData._isSelected ? 1 : 0
            checkImage.image = itemData._isSelected ? UIImage(named: "checkboxOn") : UIImage(named: "checkboxOff")
        }
    }

    func initData(materialsData: TKMaterial, isShowStudentAvatarView: Bool = true, isMainMaterial: Bool = false, searchKey: String = "", onlyShare: Bool = false) {
        itemData = materialsData
        let materialsId = materialsData.id
        logger.debug("当前文件: [\(materialsData.name)] 是否是我的文件: \(materialsData.isOwnMaterials)")
        typeImageView.borderWidth = 0
        if itemData.isOwnMaterials {
            typeImageBackView.setBorder(borderWidth: 0, borderColor: ColorUtil.red)
        } else {
            if let studio = ListenerService.shared.studentData.studioData, studio.storefrontColor != "" {
                typeImageBackView.setBorder(borderWidth: 1, borderColor: UIColor(hex: "#\(studio.storefrontColor)"))
            } else {
                typeImageBackView.setBorder(borderWidth: 1, borderColor: ColorUtil.main)
            }
        }
        isLoad = true
        // 判断是否已经全选了
//        processingView.isHidden = materialsData.status != .processing
        updateCheckBox()
        showView.snp.updateConstraints { make in
            make.width.equalTo(cellInitialSize.width)
            make.height.equalTo(cellInitialSize.height)
        }

        typeImageView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.top.equalToSuperview().offset(26)
            make.bottom.equalToSuperview().offset(-26)
        }

        titleLabel.snp.updateConstraints { make in
            make.top.equalTo(showView.snp.bottom).offset(10)
        }

        linkLabel.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        timeLabel.snp.updateConstraints { make in
            make.top.equalTo(linkLabel.snp.bottom).offset(2)
        }
        typeImageView.layer.cornerRadius = 0
        typeImageView.clipsToBounds = false

        playImageView.snp.remakeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.size.equalTo(40)
        }
        playImageView.isHidden = true

        typeImageView.backgroundColor = UIColor.white
        typeImageView.contentMode = .scaleToFill
        showView.setShadows(withBorder: false)

        typeImageView.hero.id = ""
        typeImageView.hero.id = nil
        timeLabel.text(TimeUtil.compareCurrentTime(str: Double(materialsData.createTime)!))
        if onlyShare {
            shareButton.isHidden = false
        } else {
            if isShowStudentAvatarView {
                let ids: [String] = (materialsData.studentData.compactMap { $0.studentId } + materialsData.studentIds).filterDuplicates { $0 }.sorted(by: { $0 < $1 })
                logger.debug("当前渲染学生头像,文件Id: \(materialsData.id) | \(materialsData.name) -> \(ids)")
                if isMainMaterial {
                    shareButton.isHidden = ids.count > 0
                }
                studentView.snp.updateConstraints { make in
                    make.height.equalTo(ids.count > 0 ? 20 : 0)
                }
                //            viewAll.snp.updateConstraints { make in
                //                make.height.equalTo(materialsData.studentIds.count > 3 ? 20 : 0)
                //            }

                studentAvatarView.snp.updateConstraints { make in
                    make.height.equalTo(ids.count > 0 ? 20 : 0)
                }
                if ids.count > 0 {
                    var avatars: [TKUserAvatar] = []
                    for item in Array(ids.prefix(3)) {
                        var avatar = TKUserAvatar()
                        avatar.id = item
                        // 获取名字
                        let name: String = ListenerService.shared.studioManagerData.studentsMap[item]?.name ?? ""
                        avatar.name = name
                        avatars.append(avatar)
                    }
                    studentAvatarView.setData(avatarData: avatars)
                }
            } else {
                backView.backgroundColor = UIColor.white
                showView.backgroundColor = UIColor.white
            }
        }

        childImageView1.isHidden = true
        childImageView2.isHidden = true
        childImageView3.isHidden = true
        childImageView4.isHidden = true
        typeImageView.isHidden = false
        showView.backgroundColor = ColorUtil.backgroundColor
        var titleText: String = ""
        contentView.hero.id = materialsData.id
        var setTypeImageBorder: Bool = false
        switch materialsData.type {
        case .folder:
            // 判断有多少文件
//            contentView.hero.id = materialsData.id
            showView.backgroundColor = ColorUtil.folderBackground
            showView.backgroundColor = .white
//            let materials = materialsData.materials
//            if materials.count > 0 {
//                typeImageView.isHidden = true
//            } else {
            typeImageView.isHidden = false
            typeImageView.contentMode = .center
            typeImageView.backgroundColor = .clear
            typeImageView.image = UIImage(named: "folder_empty")?.resizeImage(CGSize(width: 48, height: 48))
//            }
            childImageView1.isHidden = true
            childImageView2.isHidden = true
            childImageView3.isHidden = true
            childImageView4.isHidden = true
//            let imageViewSize = (contentView.bounds.width - 15) / 2
//            childImageView1.snp.remakeConstraints { make in
//                make.top.left.equalToSuperview().offset(5)
//                make.size.equalTo(imageViewSize)
//            }
//            childImageView2.snp.remakeConstraints { make in
//                make.top.equalToSuperview().offset(5)
//                make.right.equalToSuperview().offset(-5)
//                make.size.equalTo(imageViewSize)
//            }
//            childImageView3.snp.remakeConstraints { make in
//                make.left.equalToSuperview().offset(5)
//                make.bottom.equalToSuperview().offset(-5)
//                make.size.equalTo(imageViewSize)
//            }
//            childImageView4.snp.remakeConstraints { make in
//                make.bottom.right.equalToSuperview().offset(-5)
//                make.size.equalTo(imageViewSize)
//            }

//            if materials.count >= 1 {
//                setChildImageView(imageView: childImageView1, data: materials[0])
//            }
//
//            if materials.count >= 2 {
//                setChildImageView(imageView: childImageView2, data: materials[1])
//            }
//
//            if materials.count >= 3 {
//                setChildImageView(imageView: childImageView3, data: materials[2])
//            }
//            if materials.count >= 4 {
//                setChildImageView(imageView: childImageView4, data: materials[3])
//            }
            titleLabel.text(materialsData.name)
            titleText = materialsData.name.capitalized
        case .none:
            break
        case .file:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "otherFile")
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
            typeImageView.contentMode = .scaleAspectFill
            break
        case .pdf:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgPdf")
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
            typeImageView.contentMode = .scaleAspectFill
            break
        case .image:
            showView.backgroundColor = .white
            setTypeImageBorder = true
            if materialsData.status == .failed {
                typeImageView.backgroundColor = .white
                typeImageView.image = UIImage(named: "imgJpg")
                typeImageView.contentMode = .center
            } else {
//                typeImageView.setImageForUrl(imageUrl: materialsData.url, placeholderImage: imagePlaceholder)
                typeImageView.sd_setImage(with: URL(string: materialsData.url), placeholderImage: imagePlaceholder, completed: { image, error, cacheType, imageURL in
                    if imageURL?.absoluteString ?? "" != materialsData.url {
                        logger.debug("图片地址不正确")
                    }
                })
                typeImageView.contentMode = .scaleAspectFill
            }
            typeImageView.hero.id = materialsData.url
            titleLabel.text("\(materialsData.name.capitalized).jpg")
            titleText = "\(materialsData.name.capitalized).jpg"
            showView.borderWidth = 0
            typeImageView.layer.cornerRadius = 5
            typeImageView.clipsToBounds = true
            typeImageView.snp.updateConstraints { make in
                make.left.bottom.top.right.equalToSuperview().offset(0)
            }
            break
        case .txt:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgTxt")
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
            typeImageView.contentMode = .scaleAspectFill
            break
        case .word:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgDoc")
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
            typeImageView.contentMode = .scaleAspectFill
            break
        case .ppt:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgPpt")
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
            typeImageView.contentMode = .scaleAspectFill
            break
        case .mp3:
            showView.backgroundColor = .white
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgMp3")
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
            typeImageView.contentMode = .scaleAspectFill
            playImageView.isHidden = false
            playImageView.snp.remakeConstraints { make in
//                make.centerY.centerX.equalToSuperview()
                make.right.equalTo(-8)
                make.bottom.equalTo(-8)
                make.size.equalTo(20)
            }
            break
        case .video:
            setTypeImageBorder = true
//            typeImageView.setImageForUrl(imageUrl: materialsData.minPictureUrl, placeholderImage: imagePlaceholder)
            typeImageView.sd_setImage(with: URL(string: materialsData.minPictureUrl), placeholderImage: imagePlaceholder)
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
            typeImageView.contentMode = .scaleAspectFill
            typeImageView.layer.cornerRadius = 5
            typeImageView.hero.id = materialsData.minPictureUrl

            showView.borderWidth = 0
            typeImageView.clipsToBounds = true
            typeImageView.snp.updateConstraints { make in
                make.left.bottom.top.right.equalToSuperview().offset(0)
            }
            playImageView.isHidden = false
            break
        case .youtube:
            if materialsData.url.contains("youtu.be") || materialsData.url.contains("youtube.com/watch") || materialsData.url.contains("youtube.com/shorts") {
                setTypeImageBorder = true
//                typeImageView.setImageForUrl(imageUrl: materialsData.minPictureUrl, placeholderImage: imagePlaceholder)
                typeImageView.sd_setImage(with: URL(string: materialsData.minPictureUrl), placeholderImage: imagePlaceholder)
                typeImageView.backgroundColor = UIColor.black
                typeImageView.layer.cornerRadius = 5
                typeImageView.clipsToBounds = true
                showView.borderWidth = 0
                typeImageView.snp.updateConstraints { make in
                    make.left.bottom.top.right.equalToSuperview().offset(0)
                }
                typeImageView.hero.id = materialsData.minPictureUrl
                typeImageView.contentMode = .scaleAspectFit

                showView.snp.updateConstraints { make in
                    make.width.equalTo(cellInitialSize.width)
                    make.height.equalTo(cellInitialSize.height)
                }
                titleLabel.snp.updateConstraints { make in
                    make.top.equalTo(showView.snp.bottom).offset(10)
                }
                linkLabel.snp.updateConstraints { make in
                    make.height.equalTo(13)
                }
                timeLabel.snp.updateConstraints { make in
                    make.top.equalTo(linkLabel.snp.bottom).offset(4)
                }
                titleLabel.text(materialsData.name.capitalized)
                titleText = materialsData.name.capitalized
                linkLabel.text(materialsData.url)
                playImageView.isHidden = false
            } else {
                setTypeImageBorder = true
//                typeImageView.setImageForUrl(imageUrl: materialsData.minPictureUrl, placeholderImage: imagePlaceholder)
                typeImageView.sd_setImage(with: URL(string: materialsData.minPictureUrl), placeholderImage: imagePlaceholder)
                titleLabel.text(materialsData.name.capitalized)
                titleText = materialsData.name.capitalized
                typeImageView.contentMode = .scaleAspectFill
                typeImageView.layer.cornerRadius = 5
                typeImageView.hero.id = materialsData.minPictureUrl

                showView.borderWidth = 0
                typeImageView.clipsToBounds = true
                typeImageView.snp.updateConstraints { make in
                    make.left.bottom.top.right.equalToSuperview().offset(0)
                }
                playImageView.isHidden = true
            }
            break
        case .link:
            setTypeImageBorder = true
            showView.backgroundColor = .white
            typeImageView.sd_setImage(with: URL(string: materialsData.minPictureUrl), placeholderImage: UIImage(named: "linkResource")!, options: []) { [weak self] image, error, _, _ in
                guard let self = self else { return }
                if let error = error {
                    logger.error("load image error: \(error)")
                    self.typeImageView.snp.updateConstraints { make in
                        make.left.equalToSuperview().offset(32)
                        make.right.equalToSuperview().offset(-32)
                        make.top.equalToSuperview().offset(26)
                        make.bottom.equalToSuperview().offset(-26)
                    }
                    self.typeImageView.layer.cornerRadius = 0
                    self.typeImageView.clipsToBounds = false
                } else {
                    if let image = image {
                        self.typeImageView.image = image
                        self.typeImageView.snp.updateConstraints { make in
                            make.left.bottom.top.right.equalToSuperview().offset(0)
                        }
                        self.typeImageView.layer.cornerRadius = 5
                        self.typeImageView.clipsToBounds = true
                    } else {
                        self.typeImageView.snp.updateConstraints { make in
                            make.left.equalToSuperview().offset(32)
                            make.right.equalToSuperview().offset(-32)
                            make.top.equalToSuperview().offset(26)
                            make.bottom.equalToSuperview().offset(-26)
                        }
                        self.typeImageView.layer.cornerRadius = 0
                        self.typeImageView.clipsToBounds = false
                    }
                }
            }

            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
            linkLabel.text(materialsData.url)
            typeImageView.contentMode = .scaleAspectFit
            if materialsData.name == "" {
                let characterSet1 = CharacterSet(charactersIn: "http://")
                let characterSet2 = CharacterSet(charactersIn: "https://")
                let str1 = materialsData.url.trimmingCharacters(in: characterSet1)
                var str2 = str1.trimmingCharacters(in: characterSet2)
                if str2 == "" {
                    str2 = "Link"
                }
                titleLabel.text(str2)
            }
            break
        case .excel:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgExecl")
            typeImageView.contentMode = .scaleAspectFill
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
        case .pages:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgPages")
            typeImageView.contentMode = .scaleAspectFill
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
        case .numbers:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgNumbers")
            typeImageView.contentMode = .scaleAspectFill
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
        case .keynote:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgKeynotes")
            typeImageView.contentMode = .scaleAspectFill
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
        case .googleDoc:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgDocs")
            typeImageView.contentMode = .scaleAspectFill
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
        case .googleSheet:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgSheets")
            typeImageView.contentMode = .scaleAspectFill
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
        case .googleSlides:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgSlides")
            typeImageView.contentMode = .scaleAspectFill
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
        case .googleForms:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgForms")
            typeImageView.contentMode = .scaleAspectFill
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
        case .googleDrawings:
            showView.backgroundColor = .white
            typeImageView.backgroundColor = .white
            typeImageView.image = UIImage(named: "imgDrawing")
            typeImageView.contentMode = .scaleAspectFill
            titleLabel.text(materialsData.name.capitalized)
            titleText = materialsData.name.capitalized
        }
        titleLabel.attributedText = Tools.attributenStringColor(text: titleText, selectedText: searchKey, allColor: ColorUtil.Font.primary, selectedColor: ColorUtil.main, font: FontUtil.regular(size: 13), fontSize: 13, selectedFontSize: 13, ignoreCase: true, charasetSpace: 0)

        if setTypeImageBorder {
            if itemData.isOwnMaterials {
                typeImageView.setBorder(borderWidth: 0, borderColor: ColorUtil.red)
            } else {
                if let studio = ListenerService.shared.studentData.studioData, studio.storefrontColor != "" {
                    typeImageView.setBorder(borderWidth: 1, borderColor: UIColor(hex: "#\(studio.storefrontColor)").withAlphaComponent(1))
                } else {
                    typeImageView.setBorder(borderWidth: 1, borderColor: ColorUtil.main.withAlphaComponent(1))
                }
            }
        } else {
            typeImageView.borderWidth = 0
        }
    }

    private func setChildImageView(imageView: TKImageView, data: TKMaterial) {
        imageView.isHidden = false
        switch data.type {
        case .none, .folder:
            imageView.image = nil
        case .image:
            imageView.setImageForUrl(imageUrl: data.url, placeholderImage: imagePlaceholder)
            imageView.contentMode = .scaleAspectFill
        case .video:
            imageView.setImageForUrl(imageUrl: data.minPictureUrl, placeholderImage: imagePlaceholder)
            imageView.contentMode = .scaleAspectFill
        case .youtube:
            imageView.setImageForUrl(imageUrl: data.minPictureUrl, placeholderImage: imagePlaceholder)
            imageView.contentMode = .scaleAspectFill
        case .link:
            imageView.setImageForUrl(imageUrl: data.minPictureUrl, placeholderImage: UIImage(named: "linkResource")!)
            imageView.contentMode = .scaleAspectFill
        case .file:
            imageView.image = UIImage(named: "otherFile")
            imageView.contentMode = .scaleAspectFit
        case .pdf:
            imageView.image = UIImage(named: "imgPdf")
            imageView.contentMode = .scaleAspectFit
        case .txt:
            imageView.image = UIImage(named: "imgTxt")
            imageView.contentMode = .scaleAspectFit
        case .word:
            imageView.image = UIImage(named: "imgDoc")
            imageView.contentMode = .scaleAspectFit
        case .ppt:
            imageView.image = UIImage(named: "imgPpt")
            imageView.contentMode = .scaleAspectFit
        case .mp3:
            imageView.image = UIImage(named: "imgMp3")
            imageView.contentMode = .scaleAspectFit
        case .excel:
            imageView.image = UIImage(named: "imgExecl")
            imageView.contentMode = .scaleAspectFit
        case .pages:
            imageView.image = UIImage(named: "imgPages")
            imageView.contentMode = .scaleAspectFit
        case .numbers:
            imageView.image = UIImage(named: "imgNumbers")
            imageView.contentMode = .scaleAspectFit
        case .keynote:
            imageView.image = UIImage(named: "imgKeynotes")
            imageView.contentMode = .scaleAspectFit
        case .googleDoc:
            imageView.image = UIImage(named: "imgDocs")
            imageView.contentMode = .scaleAspectFit
        case .googleSheet:
            imageView.image = UIImage(named: "imgSheets")
            imageView.contentMode = .scaleAspectFit
        case .googleSlides:
            imageView.image = UIImage(named: "imgSlides")
            imageView.contentMode = .scaleAspectFit
        case .googleForms:
            imageView.image = UIImage(named: "imgForms")
            imageView.contentMode = .scaleAspectFit
        case .googleDrawings:
            imageView.image = UIImage(named: "imgDrawing")
            imageView.contentMode = .scaleAspectFit
        }
    }
}

extension MaterialsCell {
    func showFocus() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            guard let self = self else { return }
            self.showView.layer.borderColor = ColorUtil.main.cgColor
            self.showView.layer.borderWidth = 1
        }) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                UIView.animate(withDuration: 0.2) {
                    self.showView.setTKBorderAndRaius()
                }
            }
        }
    }
}

extension MaterialsCell {
    func border(show: Bool) {
        UIView.animate(withDuration: 0.2) {
            if show {
                self.showView.setBorder(borderWidth: 2, borderColor: ColorUtil.main)
            } else {
                self.showView.setBorder(borderWidth: 0, borderColor: ColorUtil.main)
            }
        }
    }
}

protocol MaterialsCellDelegate: AnyObject {
    func clickItem(materialsData: TKMaterial, cell: MaterialsCell)
    func materialsCell(checkBoxDidTappedAt index: Int, materialsData: TKMaterial, cell: MaterialsCell)
    func materialsCell(titleLabelDidSelectedAt index: Int, cell: MaterialsCell)
    func materialsCell(shareButtonTappedAt index: Int, cell: MaterialsCell)
}

extension MaterialsCellDelegate {
    func materialsCell(shareButtonTappedAt index: Int, cell: MaterialsCell) {
    }
}
