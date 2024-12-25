//
//  StudentsInviteLinkViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/5/21.
//  Copyright © 2021 spelist. All rights reserved.
//

import Photos
import NVActivityIndicatorView
import UIKit

class StudentsInviteLinkViewController: TKBaseViewController {
    private var loadingIndicator: NVActivityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: UIColor.white, padding: 0)
    private lazy var qrcodeImageView: TKImageView = TKImageView.create()
    private var saveQrcodeButton: TKButton = TKButton.create()
        .backgroundColor(color: UIColor.black.withAlphaComponent(0.4))
        .setImage(name: "download", size: CGSize(width: 16, height: 16))
    private lazy var linkLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: .black)
    private lazy var copyLinkButton: TKButton = TKButton.create()
        .setImage(name: "copy", size: .init(width: 14, height: 14))
    private lazy var backButton: TKButton = TKButton.create()
        .title(title: "Go back")
        .titleColor(color: ColorUtil.main)
        .titleFont(font: FontUtil.bold(size: 13))
    private lazy var shareButton: TKButton = TKButton.create()
        .title(title: "Share")
        .titleColor(color: ColorUtil.main)
        .titleFont(font: FontUtil.bold(size: 13))
    private lazy var contentView: TKView = makeContentView()

    private let contentViewSize: CGSize = .init(width: 270, height: 483)

    private var isShow: Bool = false

    private var url: String = ""

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }

    convenience init(url: String) {
        self.init(nibName: nil, bundle: nil)
        self.url = url
    }
}

extension StudentsInviteLinkViewController {
    private func makeContentView() -> TKView {
        let view = TKView.create()
            .backgroundColor(color: .white)
            .corner(size: 13)
        let titleLabel = TKLabel.create()
            .font(font: FontUtil.medium(size: 17))
            .textColor(color: UIColor.black)
            .text(text: "Invite link")
            .addTo(superView: view) { make in
                make.top.equalToSuperview().offset(20)
                make.centerX.equalToSuperview()
                make.height.equalTo(22)
            }

        let tipLabel: TKLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: .black)
            .text(text: "Here is your studio's unique QR-code with an invite link. Share to your students for automatic in-app registeration.")
            .setNumberOfLines(number: 0)
            .alignment(alignment: .center)
            .addTo(superView: view) { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
            }
        qrcodeImageView.addTo(superView: view) { make in
            make.top.equalTo(tipLabel.snp.bottom).offset(20)
            make.size.equalTo(200)
            make.centerX.equalToSuperview()
        }
        saveQrcodeButton.addTo(superView: view) { make in
            make.right.equalTo(qrcodeImageView.snp.right)
            make.bottom.equalTo(qrcodeImageView.snp.bottom)
            make.size.equalTo(32)
        }
        loadingIndicator.addTo(superView: view) { make in
            make.center.equalTo(qrcodeImageView)
            make.size.equalTo(40)
        }
        loadingIndicator.startAnimating()
        
        let linkLabelContainerView = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)
            .corner(size: 2)
            .addTo(superView: view) { make in
                make.top.equalTo(qrcodeImageView.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(14)
                make.right.equalToSuperview().offset(-14)
                make.height.equalTo(40)
            }

        linkLabel.addTo(superView: linkLabelContainerView) { make in
            make.top.left.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.right.equalToSuperview().offset(-34)
        }

        copyLinkButton.addTo(superView: linkLabelContainerView) { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(14)
        }

        let bottomLine = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)
            .addTo(superView: view) { make in
                make.bottom.equalToSuperview().offset(-51)
                make.height.equalTo(1)
                make.left.right.equalToSuperview()
            }

        let splitLine = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)
            .addTo(superView: view) { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(50)
                make.centerX.equalToSuperview()
                make.width.equalTo(1)
            }

        backButton.addTo(superView: view) { make in
            make.left.bottom.equalToSuperview()
            make.right.equalTo(splitLine.snp.left)
            make.top.equalTo(bottomLine.snp.bottom)
        }

        shareButton.addTo(superView: view) { make in
            make.right.bottom.equalToSuperview()
            make.left.equalTo(splitLine.snp.right)
            make.top.equalTo(bottomLine.snp.bottom)
        }
        return view
    }
}

extension StudentsInviteLinkViewController {
    override func initView() {
        super.initView()
        
        guard let qrImage = URL(string: url)?.qrImage(using: .black) else { return }
        qrcodeImageView.image = qrImage
        linkLabel.text = url
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.addTo(superView: view) { make in
            make.size.equalTo(contentViewSize)
            make.center.equalToSuperview()
        }
        contentView.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
        loadingIndicator.stopAnimating()
    }

    private func show() {
        guard !isShow else { return }
        isShow = true
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        }
    }

    private func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: false, completion: {
                completion?()
            })
        }
    }
}

extension StudentsInviteLinkViewController {
    override func bindEvent() {
        super.bindEvent()
        
        copyLinkButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            UIPasteboard.general.string = self.url
            TKToast.show(msg: "Copied", style: .success)
        }
        
        backButton.onTapped { [weak self] _ in
            self?.hide()
        }

        shareButton.onTapped { [weak self] _ in
            guard let self = self, let image = self.qrcodeImageView.image else { return }
            let url = self.url
            self.hide {
                Tools.openShare(items: [url, image])
            }
        }
        
        saveQrcodeButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            guard let image = self.qrcodeImageView.image else { return }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.saveImageCompletion(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func saveImageCompletion(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            logger.error("保存失败: \(error)")
            TKToast.show(msg: "Save image failed, please try again later.", style: .error)
        } else {
            TKToast.show(msg: "Save image successfully.", style: .success)
        }
    }
}
