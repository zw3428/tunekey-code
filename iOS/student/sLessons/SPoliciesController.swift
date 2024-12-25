//
//  SPoliciesController.swift
//  TuneKey
//
//  Created by wht on 2020/6/28.
//  Copyright © 2020 spelist. All rights reserved.
//

import FirebaseStorageUI
import SDWebImage
import SnapKit
import UIKit

class SPoliciesController: SLBaseScrollViewController {
    var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Policies")
    var policiesLabel: TKLabel!
    var policiesView: TKView!

    private var checkBoxLabel: TKLabel!
    private var checkBoxView: TKImageView!
    private var buttonLayout: TKView!
//    private var signLaterButton: TKBlockButton!
    private var signNowButton: TKBlockButton!

    private var signView: TKView!
    private var avatarView: TKAvatarView!
    private var nameLabel: TKLabel!
    private var infoLabel: TKLabel!
    private var signImageView: TKImageView!
    private var signTimeLabel: TKLabel!

    private var dismissButton: TKBlockButton = TKBlockButton(frame: .zero, title: "DONE", style: .cancel)
    
    private var isChack = false
    var data: TKPolicies?
    var studentData: TKStudent?
    var signPolicy: Bool = false
    var seePolicy: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - View

extension SPoliciesController {
    override func initView() {
        super.initView()

        navigationBar.updateLayout(target: self)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UiUtil.safeAreaBottom() + 70, right: 0)
        scrollView.snp.remakeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        policiesView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
            .showShadow()
            .addTo(superView: contentView, withConstraints: { make in
                make.left.top.equalToSuperview().offset(20)
                if signPolicy {
                    make.right.equalToSuperview().offset(-20)
                } else if seePolicy {
                    make.right.equalToSuperview().offset(-20)
                } else {
                    make.right.bottom.equalToSuperview().offset(-20)
                }
            })
        policiesLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: policiesView, withConstraints: { make in
                make.left.top.equalToSuperview().offset(20)
                make.right.bottom.equalToSuperview().offset(-20)
            })
        policiesLabel.numberOfLines = 0
        if signPolicy {
            initSignView()
        }
        if seePolicy {
            initSignView()
        }
        
        dismissButton.addTo(superView: view) { make in
            make.bottom.equalToSuperview().offset(-UiUtil.safeAreaBottom())
            make.centerX.equalToSuperview()
            make.width.equalTo(180)
            make.height.equalTo(50)
        }
        dismissButton.isHidden = true
        dismissButton.onTapped { [weak self] _ in
            self?.dismiss(animated: true)
        }
    }

    private func initSignView() {
        checkBoxLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.fourth)
            .font(font: FontUtil.regular(size: 15))
            .text(text: "By signing, you agree to respect and abide by the studio's current policies as long as you are taking lessons with the instructor.")
            .addTo(superView: contentView, withConstraints: { make in
                make.top.equalTo(policiesView.snp.bottom).offset(20)
                make.right.equalTo(-20)
                make.left.equalTo(52)
            })
        checkBoxLabel.numberOfLines = 0
        checkBoxView = TKImageView()
        checkBoxView.setImage(name: "checkboxOffRed")
        contentView.addSubview(view: checkBoxView) { make in
            make.left.equalTo(20)
            make.size.equalTo(22)
            make.centerY.equalTo(checkBoxLabel)
        }
        checkBoxLabel.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if self.isChack {
                self.isChack = false
                self.checkBoxView.setImage(name: "checkboxOffRed")
                self.signNowButton?.disable()
            } else {
                self.isChack = true
                self.checkBoxView.setImage(name: "checkboxOn")
                self.signNowButton?.enable()
            }
        }
        checkBoxView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if self.isChack {
                self.isChack = false
                self.checkBoxView.setImage(name: "checkboxOffRed")
                self.signNowButton?.disable()
            } else {
                self.isChack = true
                self.checkBoxView.setImage(name: "checkboxOn")
                self.signNowButton?.enable()
            }
        }

//        var buttonWidth: CGFloat = 0
//        if deviceType == .phone {
//            buttonWidth = (UIScreen.main.bounds.width - 50) / 2
//        } else {
//            buttonWidth = 330 / 2
//        }
        buttonLayout = TKView()

        contentView.addSubview(view: buttonLayout) { make in
            make.height.equalTo(52)
            make.top.equalTo(checkBoxLabel.snp.bottom).offset(40)
            if deviceType == .phone {
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            } else {
                make.width.equalTo(340)
                make.centerX.equalToSuperview()
            }
        }
        signNowButton = TKBlockButton(frame: CGRect.zero, title: "SIGN NOW", style: .normal)
        signNowButton.disable()
        buttonLayout.addSubview(signNowButton)
        signNowButton.onTapped { [weak self] _ in
            guard let self = self, let studentData = self.studentData else { return }
            let controller = DigitalSignatureController()
            if studentData.studioId.isEmpty {
                controller.teacherId = studentData.teacherId
            } else {
                controller.teacherId = studentData.studioId
            }
            controller.studentId = studentData.studentId
            controller.modalPresentationStyle = .custom
            controller.confirmAction = { [weak self] signature in
                guard let self = self else { return }
                self.buttonLayout.layer.masksToBounds = true
                self.buttonLayout.isHidden = true
                self.checkBoxLabel.isHidden = true
                self.checkBoxLabel.text = ""
                self.checkBoxView.isHidden = true
                self.checkBoxLabel.snp.updateConstraints { make in
                    make.top.equalTo(self.policiesView.snp.bottom).offset(0)
                }
                self.buttonLayout.snp.updateConstraints { make in
                    make.height.equalTo(0)
                    make.top.equalTo(self.checkBoxLabel.snp.bottom).offset(0)
                }

                self.signView.layer.masksToBounds = false
                self.signView.isHidden = false
                self.signView.snp.updateConstraints { make in
                    make.height.equalTo(368)
                    make.top.equalTo(self.buttonLayout.snp.bottom).offset(20)
                    make.bottom.equalToSuperview().offset(-20).priority(.medium)
                }
                let df = DateFormatter()
                df.dateFormat = "MM/dd/yyyy"
                self.infoLabel.text("Signed in \(df.string(from: Date()))")
                self.signTimeLabel.text("\(df.string(from: Date()))")
                guard let studentData = self.studentData else {
                    return
                }
                ListenerService.shared.studentData.studentData?.signPolicyTime = TimeInterval(Date().timestamp)
                self.avatarView.loadImage(storagePath: UserService.user.getAvatarUrl(with: studentData.studentId), style: .normal, name: studentData.name, refreshCached: true)
                self.signImageView.setImage(img: signature)
                self.nameLabel.text(studentData.name)
                self.dismissButton.isHidden = false
            }
            self.present(controller, animated: true, completion: nil)
        }
        signNowButton.snp.makeConstraints { make in
//            make.width.equalTo(buttonWidth)
//            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.width.equalTo(180)
        }
//        signLaterButton = TKBlockButton(frame: CGRect.zero, title: "SIGN LATER", style: .cancel)

//        buttonLayout.addSubview(signLaterButton)
//        signLaterButton.snp.makeConstraints { make in
//            make.width.equalTo(buttonWidth)
//            make.left.equalToSuperview()
//            make.top.equalToSuperview()
//            make.height.equalTo(50)
//        }
//        signLaterButton.onTapped { [weak self] _ in
//            guard let self = self else { return }
//            self.dismiss(animated: true, completion: nil)
//        }

        signView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
            .showShadow()
            .addTo(superView: contentView, withConstraints: { make in
                make.left.equalTo(20)
                make.right.equalTo(-20)
//                make.height.equalTo(368)
//                make.top.equalTo(buttonLayout.snp.bottom).offset(20)
                make.bottom.equalToSuperview().offset(-20).priority(.medium)
                make.height.equalTo(0)
                make.top.equalTo(buttonLayout.snp.bottom).offset(0)
//                make.bottom.equalToSuperview().offset(0).priority(.medium)
            })
        signView.layer.masksToBounds = true
        signView.isHidden = true
        avatarView = TKAvatarView()
        avatarView.setSize(size: 60)
        signView.addSubview(view: avatarView) { make in
            make.left.equalTo(20)
            make.size.equalTo(60)
            make.top.equalTo(20)
        }
        nameLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: signView, withConstraints: { make in
                make.top.equalTo(25.3)
                make.left.equalTo(avatarView.snp.right).offset(20)
                make.right.equalTo(-20)
            })
        infoLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .addTo(superView: signView, withConstraints: { make in
                make.left.equalTo(avatarView.snp.right).offset(20)
                make.right.equalTo(-20)
                make.top.equalTo(nameLabel.snp.bottom).offset(5)
            })
        signImageView = TKImageView()
        signImageView.backgroundColor = UIColor(r: 250, g: 250, b: 250)
        signView.addSubview(view: signImageView) { make in
            make.top.equalTo(avatarView.snp.bottom).offset(20)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.height.equalTo(252)
        }
        signTimeLabel = TKLabel.create()
            .textColor(color: UIColor.black)
            .addTo(superView: signView, withConstraints: { make in
                make.right.equalTo(signImageView.snp.right).offset(-10)
                make.bottom.equalTo(signImageView.snp.bottom).offset(-10)
            })
        signTimeLabel.font = UIFont(name: "Bradley Hand", size: 15)
        signImageView.contentMode = .scaleAspectFit
        if seePolicy {
            checkBoxLabel.isHidden = true
            checkBoxView.isHidden = true
            checkBoxLabel.text("")
            checkBoxLabel.snp.updateConstraints { make in
                make.top.equalTo(policiesView.snp.bottom).offset(0)
            }
        }

        guard let studentData = studentData else {
            return
        }
        avatarView.loadImage(storagePath: UserService.user.getAvatarUrl(with: studentData.studentId), style: .normal, name: studentData.name, refreshCached: true)
        nameLabel.text(studentData.name)
    }
}

// MARK: - Data

extension SPoliciesController {
    override func initData() {
        var studioName = "\(SLCache.main.getString(key: SLCache.STUDIO_NAME))"
        if studioName != "" {
            studioName = "\(studioName) Policies"
        } else {
            studioName = "Policies Statement"
        }
        navigationBar.title = studioName

        if data != nil {
            initPolicyText()
        } else {
            navigationBar.startLoading()
            getPolicyData()
        }
        if signPolicy {
            navigationBar.title = "Sign Policies"
        }
        if seePolicy {
            buttonLayout.layer.masksToBounds = true
            buttonLayout.isHidden = true
            checkBoxLabel.isHidden = true
            checkBoxLabel.text = ""
            checkBoxView.isHidden = true
            checkBoxLabel.snp.updateConstraints { make in
                make.top.equalTo(self.policiesView.snp.bottom).offset(0)
            }
            buttonLayout.snp.updateConstraints { make in
                make.height.equalTo(0)
                make.top.equalTo(self.checkBoxLabel.snp.bottom).offset(0)
            }

            guard let studentData = studentData, studentData.signPolicyTime != 0 else {
                return
            }
            signView.layer.masksToBounds = false
            signView.isHidden = false
            signView.snp.updateConstraints { make in
                make.height.equalTo(368)
                make.top.equalTo(self.buttonLayout.snp.bottom).offset(20)
                make.bottom.equalToSuperview().offset(-20).priority(.medium)
            }
            let df = DateFormatter()
            df.dateFormat = "MM/dd/yyyy"
            infoLabel.text("Signed in \(df.string(from: Date()))")
            signTimeLabel.text("\(df.string(from: Date()))")

            avatarView.loadImage(storagePath: UserService.user.getAvatarUrl(with: studentData.studentId), style: .normal, name: studentData.name, refreshCached: true)
            signImageView.sd_setImage(with: Storage.storage().reference(withPath: "/signature/\(studentData.teacherId):\(studentData.studentId).png"), maxImageSize: 1024000000, placeholderImage: nil, options: [SDWebImageOptions.refreshCached], context: nil, progress: nil) { [weak self] _, _, _, _ in
                self?.signTimeLabel.text("\(df.string(from: TimeUtil.changeTime(time: studentData.signPolicyTime)))")
            }
            nameLabel.text(studentData.name)
        }
    }

    private func getPolicyData() {
        guard let studentData = studentData else { return }
        addSubscribe(
            UserService.teacher.getPoliciesById(policiesId: studentData.teacherId)
                .subscribe(onNext: { [weak self] doc in
                    guard let self = self else { return }
                    if doc.exists {
                        if let data = TKPolicies.deserialize(from: doc.data()) {
                            self.data = data
                            self.initPolicyText()
                        }
                    }
                    if doc.from == .server {
                        self.hideFullScreenLoading()
                        self.navigationBar.stopLoading()
                    }

                }, onError: { [weak self] err in
//                    self?.navigationBar.hideLoading()
                    self?.getPolicyData()
                    logger.debug("======\(err)")
                })
        )
    }

    func initPolicyText() {
        guard let data = data else { return }
        if data.description == "" {
            policiesLabel.text = data.getDefaultDescription()
        } else {
            policiesLabel.text = data.description
        }
    }
}

// MARK: - TableView

extension SPoliciesController {
}

// MARK: - Action

extension SPoliciesController {
}
