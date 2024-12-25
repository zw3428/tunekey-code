//
//  ContactUsSelectorViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/5/10.
//  Copyright © 2021 spelist. All rights reserved.
//
import HandyJSON
import MessageUI
import NVActivityIndicatorView
import UIKit

extension ContactUsSelectorViewController {
    struct FollowUs: HandyJSON {
        var image: String = ""
        var title: String = ""
        var schemaUrl: String = ""
        var failedUrl: String = ""
        var id: Int = 0
    }
}

class ContactUsSelectorViewController: TKBaseViewController {
    private var isShowed: Bool = false

    private var isFollowUsShow: Bool = false

    private let contactUsOptionsViewOffset: CGFloat = 305 + UiUtil.safeAreaBottom() + 10

    private lazy var contactUsOptionsView: TKView = {
        let view = TKView.create()
            .backgroundColor(color: .clear)
        cancelButton.addTo(superView: view) { make in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(57)
        }

        buttonsView.addTo(superView: view) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(228)
        }
        return view
    }()

    private var cancelButton: TKButton = TKButton.create()
        .backgroundColor(color: .white)
        .titleFont(font: FontUtil.bold(size: 20))
        .titleColor(color: ColorUtil.Font.primary)
        .title(title: "Cancel")
        .corner(13)

    private lazy var buttonsView: TKView = {
        let view = TKView.create()
            .backgroundColor(color: .white)
            .corner(size: 13)
        view.clipsToBounds = true
        let imageInsets: UIEdgeInsets = .init(top: 0, left: -8, bottom: 0, right: 0)
        let titleInsets: UIEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: 0)
        messageUsButton.imageEdgeInsets = imageInsets
        messageUsButton.titleEdgeInsets = titleInsets
        messageUsButton.addTo(superView: view) { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(57)
        }

        textUsButton.imageEdgeInsets = imageInsets
        textUsButton.titleEdgeInsets = titleInsets
        textUsButton.addTo(superView: view) { make in
            make.top.equalTo(messageUsButton.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(57)
        }

        emailUsButton.imageEdgeInsets = imageInsets
        emailUsButton.titleEdgeInsets = titleInsets
        emailUsButton.addTo(superView: view) { make in
            make.top.equalTo(textUsButton.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(57)
        }

        followUsButton.imageEdgeInsets = imageInsets
        followUsButton.titleEdgeInsets = titleInsets
        followUsButton.addTo(superView: view) { make in
            make.top.equalTo(emailUsButton.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(57)
        }
        TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)
            .addTo(superView: view) { make in
                make.bottom.equalTo(messageUsButton.snp.bottom)
                make.height.equalTo(1)
                make.left.right.equalToSuperview()
            }
        TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)
            .addTo(superView: view) { make in
                make.bottom.equalTo(textUsButton.snp.bottom)
                make.height.equalTo(1)
                make.left.right.equalToSuperview()
            }
        TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)
            .addTo(superView: view) { make in
                make.bottom.equalTo(emailUsButton.snp.bottom)
                make.height.equalTo(1)
                make.left.right.equalToSuperview()
            }
        return view
    }()

    private var messageUsButton: TKButton = TKButton.create()
        .title(title: "Message us")
        .titleFont(font: FontUtil.bold(size: 20))
        .titleColor(color: ColorUtil.main)
        .setImage(name: "tk_send", size: .init(width: 22, height: 22))
        .backgroundColor(color: .white)
    private var textUsButton: TKButton = TKButton.create()
        .title(title: "Text us")
        .titleFont(font: FontUtil.bold(size: 20))
        .titleColor(color: ColorUtil.main)
        .setImage(name: "tk_sms", size: .init(width: 22, height: 22))
        .backgroundColor(color: .white)
    private var emailUsButton: TKButton = TKButton.create()
        .title(title: "Email us")
        .titleFont(font: FontUtil.bold(size: 20))
        .titleColor(color: ColorUtil.main)
        .setImage(name: "tk_email", size: .init(width: 22, height: 22))
        .backgroundColor(color: .white)
    private var followUsButton: TKButton = TKButton.create()
        .title(title: "Follow us")
        .titleFont(font: FontUtil.bold(size: 20))
        .titleColor(color: ColorUtil.main)
        .setImage(name: "tk_social", size: .init(width: 22, height: 22))
        .backgroundColor(color: .white)

    private lazy var followUsCollectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .zero
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        return layout
    }()

    private lazy var followUsCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: followUsCollectionViewLayout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ContactUsFollowUsItemCell.self, forCellWithReuseIdentifier: String(describing: ContactUsFollowUsItemCell.self))
        return collectionView
    }()

    private lazy var followUsContainerView: TKView = self.makeFollowUsContainerView()
    private lazy var followUsLoadingIndicator: NVActivityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: ColorUtil.main, padding: 0)
    private lazy var followUsCancelButton: TKButton = TKButton.create()
        .backgroundColor(color: .white)
        .titleFont(font: FontUtil.bold(size: 20))
        .titleColor(color: ColorUtil.Font.primary)
        .title(title: "Cancel")
        .corner(13)

    private let followUsViewOffset: CGFloat = 425 + UiUtil.safeAreaBottom()

    private var followUsDataSource: [FollowUs] = []

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        followUsCollectionViewLayout.itemSize = CGSize(width: (followUsCollectionView.bounds.width - 20) / 3, height: (followUsCollectionView.bounds.height - 10) / 2)
    }
}

extension ContactUsSelectorViewController {
    private func makeFollowUsContainerView() -> TKView {
        let view = TKView.create()

        followUsCancelButton.addTo(superView: view) { make in
            make.bottom.equalToSuperview().offset(-10 - UiUtil.safeAreaBottom())
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(57)
        }

        let topContainer = TKView.create()
            .backgroundColor(color: .white)
            .corner(size: 13)
            .addTo(superView: view) { make in
                make.bottom.equalTo(followUsCancelButton.snp.top).offset(-10)
                make.left.equalToSuperview().offset(10)
                make.right.equalToSuperview().offset(-10)
                make.height.equalTo(251)
            }

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 17))
            .textColor(color: ColorUtil.Font.second)
            .text(text: "Follow us")
            .addTo(superView: topContainer) { make in
                make.top.equalToSuperview().offset(20)
                make.centerX.equalToSuperview()
                make.height.equalTo(20)
            }

        followUsCollectionView.addTo(superView: topContainer) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-30)
        }

        followUsLoadingIndicator.addTo(superView: topContainer) { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
        followUsLoadingIndicator.startAnimating()
        return view
    }
}

extension ContactUsSelectorViewController {
    override func initView() {
        super.initView()

        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contactUsOptionsView.addTo(superView: view) { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(305)
        }
        contactUsOptionsView.transform = CGAffineTransform(translationX: 0, y: contactUsOptionsViewOffset)

        followUsContainerView.addTo(superView: view) { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(followUsViewOffset)
        }
        followUsContainerView.transform = CGAffineTransform(translationX: 0, y: followUsViewOffset)
    }

    func show() {
        guard !isShowed else { return }
        isShowed = true

        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contactUsOptionsView.transform = .identity
        }
    }

    func hide(dismiss: Bool = true, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            if self.isFollowUsShow {
            } else {
                self.contactUsOptionsView.transform = CGAffineTransform(translationX: 0, y: self.contactUsOptionsViewOffset)
            }
        } completion: { [weak self] _ in
            if dismiss {
                self?.dismiss(animated: false, completion: {
                    completion()
                })
            } else {
                completion()
            }
        }
    }
}

extension ContactUsSelectorViewController {
    private func showInputTextToText() {
        guard MFMessageComposeViewController.canSendText() else { return }
        let controller = MFMessageComposeViewController()
        controller.body = ""
        controller.recipients = ["+14088688371"]
        controller.messageComposeDelegate = self
        present(controller, animated: true, completion: nil)
    }

    private func showInputTextToEmail() {
        hide(dismiss: false) { [weak self] in
            guard let self = self else { return }
            guard MFMailComposeViewController.canSendMail() else { return }
            TKPopAction.show(items: [TKPopAction.Item(title: "support@tunekey.app", action: {
                TKToast.show(msg: "Copied", style: .success)
                UIPasteboard.general.string = "support@tunekey.app"
                let controller = MFMailComposeViewController()
                controller.mailComposeDelegate = self
                controller.setSubject("Subject")
                controller.setToRecipients(["support@tunekey.app"])
                controller.setMessageBody("", isHTML: false)
                self.present(controller, animated: true, completion: nil)
            })], target: self)
        }
    }
}

extension ContactUsSelectorViewController {
    override func bindEvent() {
        super.bindEvent()
        view.onViewTapped { [weak self] _ in
            self?.hide {
            }
        }

        cancelButton.onTapped { [weak self] _ in
            self?.view.endEditing(true)
            self?.hide {
            }
        }

        textUsButton.onTapped { [weak self] _ in
            self?.showInputTextToText()
        }
        emailUsButton.onTapped { [weak self] _ in
            self?.showInputTextToEmail()
        }

        messageUsButton.onTapped { [weak self] _ in
            self?.toMessageSupportCenter()
        }

        followUsButton.onTapped { [weak self] _ in
            self?.showFollowUsView()
        }

        followUsCancelButton.onTapped { [weak self] _ in
            self?.hideFollowUsView()
        }
    }
}

extension ContactUsSelectorViewController {
    private func loadFollowUsResources() {
        logger.debug("[FollowUs内容下载] => 开始")
        DatabaseService.collections.config().document("followUsResource")
            .getDocument { snapshot, error in
                guard let data = snapshot?.data() else {
                    logger.error("[FollowUs内容下载] => 获取FollowUs资源失败: \(String(describing: error))")
                    return
                }

                guard let resources: [Any] = data["resources"] as? [Any] else {
                    logger.error("[FollowUs内容下载] => 获取FollowUs的资源内容失败")
                    return
                }

                guard let dataList = [FollowUs].deserialize(from: resources) as? [FollowUs] else {
                    logger.error("[FollowUs内容下载] => 解析FollowUs资源内容失败")
                    return
                }

                self.followUsDataSource = dataList
                self.followUsLoadingIndicator.stopAnimating()
                self.followUsCollectionView.reloadData()
            }
    }

    private func showFollowUsView() {
        loadFollowUsResources()
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.contactUsOptionsView.transform = CGAffineTransform(translationX: 0, y: self.contactUsOptionsViewOffset)
        } completion: { [weak self] _ in
            UIView.animate(withDuration: 0.2) {
                self?.followUsContainerView.transform = .identity
            }
        }
    }

    private func hideFollowUsView(withDismiss: Bool = false) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.followUsContainerView.transform = CGAffineTransform(translationX: 0, y: self.followUsViewOffset)
        } completion: { [weak self] _ in
            if withDismiss {
                self?.dismiss(animated: false, completion: nil)
            } else {
                UIView.animate(withDuration: 0.2) {
                    self?.contactUsOptionsView.transform = .identity
                }
            }
        }
    }
}

extension ContactUsSelectorViewController: UICollectionViewDataSource, UICollectionViewDelegate, ContactUsFollowUsItemCellDelegate {
    func contactUsFollowUsItemCell(didSelectAt index: Int) {
        hideFollowUsView(withDismiss: true)
        logger.debug("选择了: \(index)")
        let followUsOption = followUsDataSource[index]
        guard let url = URL(string: followUsOption.schemaUrl), let failedUrl = URL(string: followUsOption.failedUrl) else { return }
        guard UIApplication.shared.canOpenURL(url) else {
            UIApplication.shared.open(failedUrl, options: [:], completionHandler: nil)
            return
        }
        UIApplication.shared.open(url, options: [:]) { isSuccess in
            if !isSuccess {
                UIApplication.shared.open(failedUrl, options: [:], completionHandler: nil)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        followUsDataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ContactUsFollowUsItemCell.self), for: indexPath) as! ContactUsFollowUsItemCell
        cell.tag = indexPath.item
        cell.delegate = self
        let item = followUsDataSource[indexPath.item]
        cell.imageView.sd_setImage(with: URL(string: item.image), completed: nil)
        cell.titleLabel.text = item.title
        return cell
    }
}

extension ContactUsSelectorViewController {
    private func toMessageSupportCenter() {
        hide {
            guard let topController = Tools.getTopViewController() as? TKBaseViewController else { return }
            topController.showFullScreenLoadingNoAutoHide()
            DispatchQueue.global(qos: .background).async {
                StorageService.shared.uploadLogFile()
                StorageService.shared.uploadLocalDB()
            }
            ChatService.conversation.getSupportGroupConversation()
                .done { conversation in
                    topController.hideFullScreenLoading()
                    DispatchQueue.main.async {
                        MessagesViewController.show(conversation)
                    }
                }
                .catch { error in
                    logger.error("获取会话失败: \(error)")
                    topController.hideFullScreenLoading()
                    TKToast.show(msg: "Connect support center failed, please try again later.", style: .error)
                }
        }
    }
}


extension ContactUsSelectorViewController: MFMessageComposeViewControllerDelegate {
    private func sendMessageToText(message: String) {
        guard MFMessageComposeViewController.canSendText() else { return }
        let controller = MFMessageComposeViewController()
        controller.body = message
        controller.recipients = ["+14088688371"]
        controller.messageComposeDelegate = self
        present(controller, animated: true, completion: nil)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
        switch result {
        case .sent:
            hide {
                TKToast.show(msg: "Message sent successfully", style: .success)
            }
        case .cancelled:
            break
        case .failed:
            TKToast.show(msg: "Message send failed, please try again later.", style: .error)
        @unknown default:
            break
        }
    }
}

extension ContactUsSelectorViewController: MFMailComposeViewControllerDelegate {
    private func sendMessageToEmail(message: String) {
        guard MFMailComposeViewController.canSendMail() else { return }
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = self
        controller.setSubject("Subject")
        controller.setToRecipients(["support@tunekey.app"])
        controller.setMessageBody(message, isHTML: false)
        present(controller, animated: true, completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        switch result {
        case .sent:
            hide {
                TKToast.show(msg: "Message sent successfully", style: .success)
            }
        case .cancelled, .saved:
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
                self.contactUsOptionsView.transform = .identity
            }
        case .failed:
            TKToast.show(msg: "Message send failed, please try again later.", style: .error)
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
                self.contactUsOptionsView.transform = .identity
            }
        @unknown default:
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
                self.contactUsOptionsView.transform = .identity
            }
        }
    }
}

protocol ContactUsFollowUsItemCellDelegate: AnyObject {
    func contactUsFollowUsItemCell(didSelectAt index: Int)
}

class ContactUsFollowUsItemCell: UICollectionViewCell {
    weak var delegate: ContactUsFollowUsItemCellDelegate?

    var imageView: TKImageView = TKImageView.create()
    var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.medium(size: 10))
        .textColor(color: ColorUtil.Font.second)
        .alignment(alignment: .center)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white

        imageView.addTo(superView: contentView) { make in
            make.size.equalTo(40)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
        }

        titleLabel.addTo(superView: contentView) { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(13)
        }

        contentView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.contactUsFollowUsItemCell(didSelectAt: self.tag)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
