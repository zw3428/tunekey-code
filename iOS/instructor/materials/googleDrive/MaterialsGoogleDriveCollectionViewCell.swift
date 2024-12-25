//
//  MaterialsGoogleDriveCollectionViewCell.swift
//  TuneKey
//
//  Created by zyf on 2020/12/11.
//  Copyright © 2020 spelist. All rights reserved.
//
import NVActivityIndicatorView
import UIKit

protocol MaterialsGoogleDriveCollectionViewCellDelegate: AnyObject {
    func materialsGoogleDriveCollectionViewCell(didSelect cell: MaterialsGoogleDriveCollectionViewCell, isSelected: Bool, file: GoogleDriveFile, withImage image: UIImage?)
}

class MaterialsGoogleDriveCollectionViewCell: UICollectionViewCell {
    weak var delegate: MaterialsGoogleDriveCollectionViewCellDelegate?
    private var file: GoogleDriveFile?

    private var iconImageView: TKImageView = TKImageView.create()
    private var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.Font.primary)
        .alignment(alignment: .center)

    private var selectIconImageView: TKImageView = TKImageView.create()

    private var loadingCoverView: TKView = TKView.create()
        .backgroundColor(color: UIColor.black.withAlphaComponent(0.4))

    private var loadingLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 15))
        .textColor(color: .white)
        .alignment(alignment: .center)

    private var loadingIndicatorView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: ColorUtil.main, padding: 2)

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
        initListener()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initListener() {
        EventBus.listen(key: .googleDrivePredownloadFileProgressChanged, target: self) { [weak self] notification in
            guard let self = self else { return }
            guard let file = self.file else { return }
            guard let model = notification?.object as? GoogleDriveMaterialPredownloadModel else { return }
            guard model.file.id == file.id else { return }
            logger.debug("[Google Drive] => 监听到下载进度变更: \(model.file.id) | \(model.progress)")
            if model.status == .downloading {
                self.loadingCoverView.isHidden = false
                self.loadingIndicatorView.startAnimating()
                if model.progress == 0.0 {
                    self.loadingLabel.text = ""
                } else {
                    self.loadingLabel.text = "\(Int(model.progress * 100))%"
                }
            } else {
                self.stopLoading()
            }
        }
    }

    deinit {
        EventBus.unregister(target: self)
    }

    private var loadedImage: Bool = false
}

extension MaterialsGoogleDriveCollectionViewCell {
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

        loadingCoverView.addTo(superView: containerView) { make in
            make.center.size.equalToSuperview()
        }

        loadingIndicatorView.addTo(superView: loadingCoverView) { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
            make.size.equalTo(40)
        }
        loadingIndicatorView.startAnimating()

        loadingLabel.addTo(superView: loadingCoverView) { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
        loadingLabel.text("0%")
        stopLoading()

        titleLabel.addTo(superView: contentView) { make in
            make.top.equalTo(containerView.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-2)
            make.height.equalTo(20)
        }

        selectIconImageView.addTo(superView: contentView) { make in
            make.top.equalTo(containerView.snp.top).offset(2)
            make.right.equalTo(containerView.snp.right).offset(-2)
            make.size.equalTo(22)
        }
        contentView.onViewTapped { [weak self] _ in
            self?.onContentViewTapped()
        }
    }

    private func stopLoading() {
        loadingCoverView.isHidden = true
        loadingIndicatorView.stopAnimating()
        loadingLabel.text = ""
    }

    private func startLoading() {
        loadingCoverView.isHidden = false
        loadingIndicatorView.startAnimating()
        loadingLabel.text = "0%"
    }

    func loadData(file: GoogleDriveFile, isSelectedType: Bool = false) {
        self.file = file
        loadedImage = false
        if isSelectedType {
            selectIconImageView.isHidden = true
        } else {
            if file.mimeType == "application/vnd.google-apps.folder" {
                // 文件夹
                selectIconImageView.isHidden = true
            } else {
                selectIconImageView.isHidden = false
                selectIconImageView.image = UIImage(named: isSelected ? "checkboxOn" : "checkboxOff")
            }
        }
        titleLabel.text = file.name

        if file.hasThumbnail {
            logger.debug("当前文件有缩略图：\(file.thumbnailLink)")
            iconImageView.setImage(url: file.thumbnailLink) { [weak self] error in
                guard let self = self else { return }
                if error != nil {
                    if let selfFile = self.file, selfFile.id == file.id {
                        self.setIconImage()
                    }
                } else {
                    self.loadedImage = true
                    self.iconImageView.snp.updateConstraints { make in
                        make.size.equalTo(108)
                    }
                }
            }
        } else {
            logger.debug("当前文件没有缩略图：\(file.mimeType)")
            setIconImage()
        }
    }

    private func setIconImage() {
        guard let file = file else { return }
        loadedImage = false
        // 判断文件类型是不是需要的这几个文件
        iconImageView.snp.updateConstraints { make in
            make.size.equalTo(108)
        }
        if file.mimeType.contains("audio") {
            iconImageView.setImage(name: "imgMp3")
        } else if file.mimeType.contains("image") {
            iconImageView.setImage(name: "imgJpg")
        } else if file.mimeType.contains("video") {
            iconImageView.setImage(name: "imgMp4")
        } else {
            switch file.mimeType {
            case "application/vnd.google-apps.audio":
                iconImageView.setImage(name: "imgMp3")
            case "application/vnd.google-apps.photo":
                iconImageView.setImage(name: "imgJpg")
            case "application/vnd.google-apps.video":
                iconImageView.setImage(name: "imgMp4")
            case "application/vnd.google-apps.document":
                iconImageView.setImage(name: "imgDocs")
            case "application/vnd.google-apps.spreadsheet":
                iconImageView.setImage(name: "imgSheets")
            case "application/vnd.google-apps.presentation":
                iconImageView.setImage(name: "imgSlides")
            case "application/vnd.google-apps.form":
                iconImageView.setImage(name: "imgForms")
            case "application/vnd.google-apps.drawing":
                iconImageView.setImage(name: "imgDrawing")
            default:
                iconImageView.setImage(url: file.iconLink)
                iconImageView.contentMode = .scaleAspectFit
                iconImageView.snp.updateConstraints { make in
                    make.size.equalTo(48)
                }
                break
            }
        }
    }

    private func onContentViewTapped() {
        guard let file = file else { return }
        isSelected.toggle()
        if file.mimeType == "application/vnd.google-apps.folder" {
            // 文件夹
            selectIconImageView.isHidden = true
        } else {
            selectIconImageView.isHidden = false
            selectIconImageView.image = UIImage(named: isSelected ? "checkboxOn" : "checkboxOff")
        }

        delegate?.materialsGoogleDriveCollectionViewCell(didSelect: self, isSelected: isSelected, file: file, withImage: loadedImage ? iconImageView.image : nil)
    }
}
