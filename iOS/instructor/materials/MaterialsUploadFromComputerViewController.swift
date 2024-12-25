//
//  MaterialsUploadFromComputerViewController.swift
//  TuneKey
//
//  Created by zyf on 2020/12/8.
//  Copyright © 2020 spelist. All rights reserved.
//
import FirebaseFunctions
import UIKit

class MaterialsUploadFromComputerViewController: TKBaseViewController {
    private var link: String = ""

    private var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.medium(size: 17))
        .textColor(color: .black)
        .text(text: "Upload from computer")

    private var contentLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: .black)
        .text(text: "")
        .alignment(alignment: .center)
        .setNumberOfLines(number: 0)

    private var contentView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.dividingLine)

    private var backButton: TKButton = TKButton.create()
        .titleFont(font: FontUtil.bold(size: 13))
        .title(title: "GO BACK")
        .titleColor(color: ColorUtil.main)

    private var emailInfoToMeButton: TKButton = TKButton.create()
        .titleFont(font: FontUtil.bold(size: 13))
        .title(title: "EMAIL INFO TO ME")
        .titleColor(color: ColorUtil.main)
    
    private var copyLinkButton: TKButton = TKButton.create()
        .titleFont(font: FontUtil.bold(size: 13))
        .title(title: "COPY TO CLIPBOARD")
        .titleColor(color: ColorUtil.main)

    private var containerView: TKView = TKView.create()
        .backgroundColor(color: UIColor.white)
        .corner(size: 13)

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }

    convenience init(link: String) {
        self.init(nibName: nil, bundle: nil)
        self.link = link
        contentLabel.text = "Send your files to \nupload@tunekey.app\n or upload your files via the link \n(\(link)).\nWe will organize files for you\nin-app."
        contentLabel.onViewTapped { _ in
            self.copyLink()
        }
    }
}

extension MaterialsUploadFromComputerViewController {
    private func copyLink() {
        UIPasteboard.general.string = link
        TKToast.show(msg: "Link copied", style: .info)
    }
}

extension MaterialsUploadFromComputerViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        containerView.addTo(superView: view) { make in
            if UIDevice.current.isPad {
                make.width.equalTo(300)
            } else {
                make.width.equalTo(UIScreen.main.bounds.width - 100)
            }
            make.center.equalToSuperview()
        }

        titleLabel.addTo(superView: containerView) { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(22)
            make.top.equalToSuperview().offset(20)
        }

        contentView.addTo(superView: containerView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        contentLabel.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.bottom.equalToSuperview().offset(-5)
            make.height.equalTo(120)
        }

        let line1 = TKView.create()
            .backgroundColor(color: ColorUtil.borderColor)
            .addTo(superView: containerView) { make in
                make.top.equalTo(contentView.snp.bottom).offset(20)
                make.left.right.equalToSuperview()
                make.height.equalTo(1)
            }

        backButton.addTo(superView: containerView) { make in
            make.top.equalTo(line1.snp.bottom)
            make.bottom.equalToSuperview().priority(.medium)
            make.left.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.4)
            make.height.equalTo(54)
        }

        emailInfoToMeButton.addTo(superView: containerView) { make in
            make.top.equalTo(backButton.snp.top)
            make.left.equalTo(backButton.snp.right)
            make.right.equalToSuperview()
            make.height.equalTo(backButton.snp.height)
        }

        TKView.create()
            .backgroundColor(color: ColorUtil.borderColor)
            .addTo(superView: containerView) { make in
                make.top.equalTo(line1)
                make.width.equalTo(1)
                make.left.equalTo(backButton.snp.right)
                make.bottom.equalToSuperview()
            }

        containerView.transform = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
    }
}

extension MaterialsUploadFromComputerViewController {
    func show() {
        animate(timeInterval: 0.2) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.containerView.transform = .identity
        }
    }

    func hide(completion: (() -> Void)? = nil) {
        animate(timeInterval: 0.2) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.containerView.transform = .init(scaleX: 0.00001, y: 0.00001)
        } completion: {
            completion?()
            self.dismiss(animated: false, completion: nil)
        }
    }
}

extension MaterialsUploadFromComputerViewController {
    override func bindEvent() {
        super.bindEvent()

        backButton.onTapped { [weak self] _ in
            self?.hide()
        }

        emailInfoToMeButton.onTapped { [weak self] _ in
            self?.onEmailInfoToMeButtonTapped()
        }
    }

    private func onEmailInfoToMeButtonTapped() {
        CommonsService.shared.fetchEmailAttachment()
        hide {
            TKToast.show(msg: "Refreshing attachments from email", style: .success)
        }
    }
}
