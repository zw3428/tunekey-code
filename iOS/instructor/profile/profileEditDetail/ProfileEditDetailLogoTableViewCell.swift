//
//  ProfileEditDetailLogoTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/9.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileEditDetailLogoTableViewCell: UITableViewCell {
    weak var delegate: ProfileEditDetailLogoTableViewCellDelegate?

    var cellHeight: CGFloat = 146

    private var backView: TKView!
    private var avatarBackView: TKView!
    var avatarView: TKAvatarView!
    var changeTipLabel: TKLabel!
    private var uploadView: TKView!
    private var uploadProgressLabel: TKLabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
        bindEvents()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileEditDetailLogoTableViewCell {
    private func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        backView = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
        contentView.addSubview(view: backView) { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(146)
        }

        avatarBackView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 50)
        backView.addSubview(view: avatarBackView) { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.size.equalTo(100)
        }

        avatarView = TKAvatarView()
        avatarView.setSize(size: 98)
        avatarView.layer.masksToBounds = true
        avatarBackView.addSubview(view: avatarView) { make in
            make.size.equalTo(98)
            make.center.equalToSuperview()
        }

        uploadView = TKView.create()
            .backgroundColor(color: UIColor.black.withAlphaComponent(0.4))
            .corner(size: 50)
        uploadView.isHidden = true
        avatarBackView.addSubview(view: uploadView) { make in
            make.size.equalTo(100)
            make.center.equalToSuperview()
        }

        uploadProgressLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 13))
            .textColor(color: UIColor.white)
            .text(text: "0 %")
        uploadView.addSubview(view: uploadProgressLabel) { make in
            make.center.equalToSuperview()
        }

        changeTipLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 10))
            .textColor(color: ColorUtil.main)
            .text(text: "Change logo")
            .alignment(alignment: .left)
        backView.addSubview(view: changeTipLabel) { make in
            make.top.equalTo(avatarBackView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.height.equalTo(12)
        }
    }

    private func bindEvents() {
        avatarBackView.onViewTapped { [weak self] _ in
            self?.delegate?.profileEditDetailLogoTableViewCellTapped()
        }

        changeTipLabel.onViewTapped { [weak self] _ in
            self?.delegate?.profileEditDetailLogoTableViewCellTapped()
        }
    }

    func setLogoImage(image: UIImage?) {
        guard image != nil else {
            return
        }
        avatarView.loadImage(style: .normal, avatarImg: image!, name: "")
    }

    func setLogoImage(url: String) {
        avatarView.loadImage(storagePath: url, refreshCached: true, placeholderImage: UIImage(named: "placeholder2")!)
    }

    func setLogoImage(id: String) {
        avatarView.avatarImgView.contentMode = .scaleAspectFit
        avatarView.loadImage(userId: id, name: "") { [weak self] error in
            guard let self = self else { return }
            if let error {
                self.avatarView.loadImage(image: UIImage(named: "content_segment_camera")!.imageWithTintColor(color: .white).resizeImage(CGSize(width: 30, height: 30)))
                self.avatarView.avatarImgView.contentMode = .center
                self.avatarView.avatarImgView.backgroundColor = .clickable
            }
        }
    }

    func startUpload() {
        SL.Executor.runAsync { [weak self] in
            guard let self = self else { return }
            self.uploadView.layer.opacity = 0
            self.uploadView.isHidden = false
            self.uploadProgressLabel.isHidden = false
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.uploadView.layer.opacity = 1
            }
        }
    }

    func setProgress(progress: Int) {
        _ = uploadProgressLabel.text(text: "\(progress.description) %")
    }

    func stopUploadWithSuccess() {
        uploadProgressLabel.isHidden = true
        let layer = CAShapeLayer()
        layer.strokeColor = ColorUtil.main.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineCap = CAShapeLayerLineCap.round
        layer.lineJoin = CAShapeLayerLineJoin.round
        layer.lineWidth = 2

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 41.5, y: 52.5))
        path.addLine(to: CGPoint(x: 49.5, y: 59.5))
        path.addLine(to: CGPoint(x: 61.5, y: 46.5))
        layer.path = path.cgPath

        let pathAnimation = CABasicAnimation(keyPath: "strokeEnd")
        pathAnimation.duration = 0.5
        pathAnimation.fromValue = 0
        pathAnimation.toValue = 1
        layer.add(pathAnimation, forKey: "strokeEnd")
        uploadView.layer.addSublayer(layer)
        SL.Executor.runAsyncAfter(time: 1.5) { [weak self] in
            self?.uploadView.isHidden = true
        }
    }

    func stopUploadWithFailed() {
        uploadView.isHidden = true
    }
}

protocol ProfileEditDetailLogoTableViewCellDelegate: NSObjectProtocol {
    func profileEditDetailLogoTableViewCellTapped()
}
