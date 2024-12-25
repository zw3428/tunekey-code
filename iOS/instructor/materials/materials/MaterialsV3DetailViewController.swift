//
//  MaterialsV3DetailViewController.swift
//  TuneKey
//
//  Created by 砚枫张 on 2024/4/24.
//  Copyright © 2024 spelist. All rights reserved.
//

import SnapKit
import UIKit

class MaterialsV3DetailViewController: TKBaseViewController {
    private lazy var contentView: ViewBox = makeContentView()
    private lazy var sharedCollectionView: UICollectionView = makeCollectionView()

    @Live private var collectionViewHeight: CGFloat = 24
    @Live private var isPlayButtonShow: Bool = false
    @Live private var playButtonSize: CGSize = .zero
    @Live private var makePlayButtonCenter: Bool = false

    private var infoRows: [String] = ["Owner", "Type", "Path", "Created", "Updated"]
    @Live private var infos: [String] = [String].init(repeating: "", count: 5)

    @Live var material: TKMaterial

    private var students: [TKStudent] = []

    init(_ material: TKMaterial) {
        self.material = material
        super.init(nibName: nil, bundle: nil)
        students = material.studentIds.compactMap({
            ListenerService.shared.studioManagerData.studentsMap[$0]
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runOnce { [weak self] in
            self?.show()
            self?.loadInfos()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let contentSize = sharedCollectionView.contentSize
        if contentSize.height != collectionViewHeight {
            collectionViewHeight = contentSize.height
        }
    }
}

extension MaterialsV3DetailViewController {
    private func makeContentView() -> ViewBox {
        ViewBox(top: 20, left: 20, bottom: UiUtil.safeAreaBottom(), right: 20) {
            VStack(spacing: 20) {
                ViewBox(top: 6, left: 0, bottom: 6, right: 0) {
                    Label("Details").textColor(.tertiary)
                        .font(.cardTitle)
                        .textAlignment(.center)
                }

                VScrollStack(spacing: 20) {
                    ViewBox(left: 20, right: 20) {
                        VStack(alignment: .center, spacing: 20) {
                            ImageView().size(width: 108, height: 108)
                                .cornerRadius(2)
                                .borderColor(.border)
                                .borderWidth(1)
                                .masksToBounds(true)
                                .apply { [weak self] imageView in
                                    guard let self = self else { return }
                                    self.onIconImageApply(imageView)
                                }

                            Label(material.name).textColor(.primary)
                                .font(.title)
                                .textAlignment(.center)
                                .numberOfLines(0)
                        }
                    }

                    ViewBox(left: 20, right: 20) {
                        Divider(weight: 1, color: .line)
                    }.height(1)

                    ViewBox(left: 20, right: 20) {
                        VStack(spacing: 10) {
                            VList(spacing: 10, withData: $infos) { [weak self] infos in
                                for (index, info) in infos.enumerated() {
                                    HStack(alignment: .top, spacing: 10) {
                                        Label("\((self?.infoRows ?? [])[index]):").textColor(.tertiary)
                                            .font(.content)
                                            .width(80)
                                        Label(info).textColor(.primary)
                                            .font(.content)
                                            .numberOfLines(0)
                                    }
                                }
                            }
                            HStack(alignment: .top, spacing: 10) {
                                Label("Shared:").textColor(.tertiary)
                                    .font(.content)
                                    .width(80)

                                ViewBox {
                                    sharedCollectionView
                                }.height($collectionViewHeight)
                            }
                        }
                    }
                }
            }
        }
        .cornerRadius(10)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        .backgroundColor(.white)
    }

    private func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewLeftAlignedLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 5
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.z.register(cell: SharedItemCollectionViewCell.self)
        collectionView.dataSource = self
        return collectionView
    }

    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.addTo(superView: view) { make in
            make.height.equalToSuperview().multipliedBy(0.8)
            make.left.right.bottom.equalToSuperview()
        }

        _ = contentView.transform(CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height))

        BlockButton(title: "BACK", style: .cancel)
            .size(width: 180, height: 50)
            .onTapped { [weak self] _ in
                self?.hide()
            }
            .addTo(superView: contentView) { make in
                make.bottom.equalToSuperview().offset(-UiUtil.safeAreaBottom())
                make.centerX.equalToSuperview()
                make.width.equalTo(180)
                make.height.equalTo(50)
            }
    }
}

extension MaterialsV3DetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        students.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SharedItemCollectionViewCell = collectionView.z.dequeueReusableCell(for: indexPath)
        let student = students[indexPath.item]
        cell.avatar = .init(id: student.studentId, name: student.name)
        cell.name = student.name
        return cell
    }
}

extension MaterialsV3DetailViewController {
    private func onIconImageApply(_ imageView: ImageView) {
        let playButton: ImageView = ImageView(image: UIImage(named: "mateialPlay"))
        playButton.addTo(superView: imageView) { _ in
        }
        $playButtonSize.addSubscriber { size in
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
        $makePlayButtonCenter.addSubscriber { makePlayButtonCenter in
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
        $isPlayButtonShow.addSubscriber { isShow in
            playButton.isHidden = !isShow
        }

        let iconImage = getMaterialIcomImage()
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

extension MaterialsV3DetailViewController {
    private func show() {
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.sharedCollectionView.reloadData()
        }
    }

    private func hide() {
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
        } completion: { [weak self] _ in
            self?.dismiss(animated: false)
        }
    }
}

extension MaterialsV3DetailViewController {
    private func getMaterialIcomImage() -> MaterialV3GridCollectionViewCell.IconImage {
        var imageURL: String = ""
        var imageName: String = ""
        var imageSize: CGSize = .zero
        switch material.type {
        case .folder:
            imageName = "folder_empty"
            imageSize = .init(width: 48, height: 48)
        case .none:
            break
        case .file:
            imageName = "otherFile"
            imageSize = .init(width: 44, height: 56)
        case .pdf:
            imageName = "imgPdf"
        case .image:
            if material.status == .failed {
                imageName = "imgJpg"
            } else {
                imageURL = material.url
            }
        case .txt:
            imageName = "imgTxt"
            imageSize = .init(width: 44, height: 56)
        case .word:
            imageName = "imgDoc"
            imageSize = .init(width: 44, height: 56)
        case .ppt:
            imageName = "imgPpt"
            imageSize = .init(width: 44, height: 56)
        case .mp3:
            imageName = "imgMp3"
            imageSize = .init(width: 44, height: 56)
        case .video:
            imageURL = material.minPictureUrl
        case .youtube:
            imageURL = material.minPictureUrl
        case .link:
            imageURL = material.minPictureUrl
        case .excel:
            imageName = "imgExecl"
            imageSize = .init(width: 44, height: 56)
        case .pages:
            imageName = "imgPages"
            imageSize = .init(width: 44, height: 56)
        case .numbers:
            imageName = "imgNumbers"
            imageSize = .init(width: 44, height: 56)
        case .keynote:
            imageName = "imgKeynotes"
            imageSize = .init(width: 44, height: 56)
        case .googleDoc:
            imageName = "imgDocs"
            imageSize = .init(width: 44, height: 56)
        case .googleSheet:
            imageName = "imgSheets"
            imageSize = .init(width: 44, height: 56)
        case .googleSlides:
            imageName = "imgSlides"
            imageSize = .init(width: 44, height: 56)
        case .googleForms:
            imageName = "imgForms"
            imageSize = .init(width: 44, height: 56)
        case .googleDrawings:
            imageName = "imgDrawing"
            imageSize = .init(width: 44, height: 56)
        }

        return .init(name: imageName, url: imageURL, size: imageSize)
    }
}

extension MaterialsV3DetailViewController {
    private func loadInfos() {
        loadOwner()
        loadPath()
        infos[1] = getType()
        infos[3] = TimeInterval(material.createTime)?.toLocalFormat("hh:mm a, MM/dd/yyyy") ?? ""
        infos[4] = TimeInterval(material.updateTime)?.toLocalFormat("hh:mm a, MM/dd/yyyy") ?? ""
    }

    private func loadOwner() {
        UserService.user.getUserInfo(id: material.creatorId)
            .done { [weak self] user in
                guard let self = self else { return }
                self.infos[0] = user.name
            }
            .catch { error in
                logger.error("加载owner失败：\(error)")
            }
    }

    private func loadPath() {
        akasync { [weak self] in
            guard let self = self else { return }
            var currentMaterial: TKMaterial? = self.material
            var paths: [String] = [self.material.name]
            while let _material = currentMaterial, _material.folder.isNotEmpty {
                let folderId = _material.folder
                if let folder = try akawait(DatabaseService.collections.material().document(folderId).getDocumentData(TKMaterial.self)) {
                    currentMaterial = folder
                    paths.insert(folder.name, at: 0)
                } else {
                    currentMaterial = nil
                }
            }
            logger.debug("获取到的paths: \(paths)")
            self.infos[2] = "/\(paths.joined(separator: "/"))"
        }
    }

    private func getType() -> String {
        switch material.type {
        case .file:
            "File"
        case .image:
            "Image"
        case .ppt:
            "PPT"
        case .word:
            "Word"
        case .mp3:
            "Audio"
        case .video:
            "Video"
        case .youtube:
            "Youtube"
        case .link:
            "Link"
        case .txt:
            "Txt"
        case .pdf:
            "PDF"
        case .excel:
            "Excel"
        case .pages:
            "Page"
        case .numbers:
            "Number"
        case .keynote:
            "Keynote"
        case .googleDoc:
            "Google Doc"
        case .googleSheet:
            "Google Sheet"
        case .googleSlides:
            "Google Slides"
        case .googleForms:
            "Google Form"
        case .googleDrawings:
            "Google Drawing"
        case .folder:
            "Folder"
        case .none:
            ""
        }
    }
}

extension MaterialsV3DetailViewController {
    class SharedItemCollectionViewCell: TKBaseCollectionViewCell {
        @Live var avatar: AvatarView.Model = .init(id: "", name: "")
        @Live var name: String = ""
    }
}

extension MaterialsV3DetailViewController.SharedItemCollectionViewCell {
    override func initViews() {
        super.initViews()
        let avatarView: AvatarView = AvatarView(size: 20).loadAvatar(withUser: $avatar)
        let label = Label($name).textColor(.primary)
            .font(.content)

        avatarView.addTo(superView: contentView) { make in
            make.size.equalTo(20)
            make.left.equalToSuperview().offset(2)
            make.centerY.equalToSuperview()
        }

        label.addTo(superView: contentView) { make in
            make.right.equalToSuperview().offset(-10)
            make.top.bottom.equalToSuperview()
            make.left.equalTo(avatarView.snp.right).offset(5)
            make.height.equalTo(24)
        }

        contentView.cornerRadius = 12
        contentView.backgroundColor = UIColor(hex: "#F0F7F5")
    }
}
