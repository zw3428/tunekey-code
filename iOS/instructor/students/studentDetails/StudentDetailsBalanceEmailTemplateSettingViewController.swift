//
//  StudentDetailsBalanceEmailTemplateSettingViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/3/7.
//  Copyright © 2022 spelist. All rights reserved.
//

import FirebaseFunctions
import SnapKit
import UIKit

class StudentDetailsBalanceEmailTemplateSettingViewController: TKBaseViewController {
    private var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Email Message")

    @Live var message: String = "" {
        didSet {
            logger.debug("当前的email: \(message)")
        }
    }

    @Live var isAddMessageButtonHidden: Bool = false
    @Live var isMessageHidden: Bool = true

    @Live var studioSignature: String = ""
    @Live var isSendingTestEmail: Bool = false

    @Live var isDeleteButtonHidden: Bool = false

    var onDeleteTapped: (() -> Void)?
    var onSaveTapped: ((String) -> Void)?

    var invoice: TKInvoice
    var student: TKStudent

    init(invoice: TKInvoice, student: TKStudent) {
        self.invoice = invoice
        self.student = student
        message = invoice.emailText
        logger.debug("初始化emailTemplate")
        super.init(nibName: nil, bundle: nil)
        if message == "" {
            isMessageHidden = true
            isAddMessageButtonHidden = false
        } else {
            isMessageHidden = false
            isAddMessageButtonHidden = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentDetailsBalanceEmailTemplateSettingViewController {
    override func initData() {
        super.initData()
        guard let userId = UserService.user.id() else { return }
        UserService.studio.getStudioInfo(teacherId: userId)
            .done { [weak self] studio in
                guard let self = self else { return }
                self.studioSignature = "Best,\n\n\(studio?.name ?? "")"
            }
            .catch { error in
                logger.error("获取studio失败: \(error)")
            }
    }
}

extension StudentDetailsBalanceEmailTemplateSettingViewController {
    override func initView() {
        super.initView()
        navigationBar.updateLayout(target: self)
        ViewBox(paddings: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)) {
            VStack {
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)) {
                    VStack {
                        Label("Subject:")
                            .textColor(ColorUtil.Font.fourth)
                            .font(FontUtil.regular(size: 13))
                        Label("Invoice #1 is issued")
                            .textColor(ColorUtil.Font.second)
                            .font(FontUtil.regular(size: 18))
                    }
                }
                Spacer(spacing: 20)
                ViewBox(paddings: .zero) {
                    VStack {
                        VScrollStack {
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
                                Label("Dear \(student.name),\n\nThe attached is the invoice #\(invoice.num) was issued today for $\(invoice.totalAmount).")
                                    .numberOfLines(0)
                                    .font(FontUtil.regular(size: 17))
                                    .textColor(ColorUtil.Font.second)
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
                                VStack {
                                    Label("Add additional message")
                                        .textColor(ColorUtil.main)
                                        .font(FontUtil.bold(size: 17))
                                        .numberOfLines(0)
                                        .isHidden($isAddMessageButtonHidden)
                                        .onViewTapped { [weak self] _ in
                                            self?.onAddMessageTapped()
                                        }
                                    HStack(alignment: .leading, spacing: 10) {
                                        Label($message)
                                            .textColor(ColorUtil.Font.second)
                                            .font(FontUtil.regular(size: 17))
                                            .numberOfLines(0)
                                        Button()
                                            .image(UIImage(named: "icEditPrimary"), for: .normal)
                                            .size(width: 22)
                                            .onTapped { [weak self] _ in
                                                self?.onAddMessageTapped()
                                            }
                                    }.isHidden($isMessageHidden)
                                }
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
                                Label($studioSignature)
                                    .numberOfLines(0)
                                    .font(FontUtil.regular(size: 17))
                                    .textColor(ColorUtil.Font.second)
                            }
                        }
                        .backgroundColor(.white)
                        Spacer(spacing: 10).backgroundColor(.white)
                        ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 20 + UiUtil.safeAreaBottom(), right: 20)) {
                            VStack {
                                Button()
                                    .title("SEND TEST EMAIL", for: .normal)
                                    .titleColor(ColorUtil.main, for: .normal)
                                    .font(FontUtil.bold(size: 17))
                                    .size(height: 20)
                                    .onTapped { [weak self] _ in
                                        self?.onSendTestEmailButtonTapped()
                                    }
                                Spacer(spacing: 30)
                                HStack(distribution: .fillEqually, spacing: 10) {
                                    BlockButton()
                                        .set(title: "DELETE", style: .delete)
                                        .isHidden($isDeleteButtonHidden)
                                        .onTapped { [weak self] _ in
                                            self?.onDeleteTapped?()
                                        }
                                    View().backgroundColor(.clear).size(width: 40).apply { [weak self] view in
                                        guard let self = self else { return }
                                        self.$isDeleteButtonHidden.addSubscriber { isHidden in
                                            view.isHidden = !isHidden
                                        }
                                    }
                                    BlockButton()
                                        .set(title: "SAVE", style: .normal)
                                        .onTapped { [weak self] _ in
                                            guard let self = self else { return }
                                            self.onSaveTapped?(self.message)
                                        }
                                    View().backgroundColor(.clear).size(width: 40).apply { [weak self] view in
                                        guard let self = self else { return }
                                        self.$isDeleteButtonHidden.addSubscriber { isHidden in
                                            view.isHidden = !isHidden
                                        }
                                    }
                                }
                                .apply { [weak self] stackView in
                                    guard let self = self else { return }
                                    self.$isDeleteButtonHidden.addSubscriber { isHidden in
                                        if isHidden {
                                            stackView.distribution = .fill
                                        } else {
                                            stackView.distribution = .fillEqually
                                        }
                                    }
                                }
                                .size(height: 50)
                            }
                        }.backgroundColor(.white)
                    }.apply { view in
                        view.setTopRadius()
                    }
                }
            }
        }.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

extension StudentDetailsBalanceEmailTemplateSettingViewController {
    private func onAddMessageTapped() {
        let controller = LessonDetailAddNewContentViewController()
        controller.titleAlignment = .center
        controller.titleString = "Message"
        controller.rightButtonString = "SAVE"
        controller.text = message
        controller.modalPresentationStyle = .custom
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] text in
            guard let self = self else { return }
            self.message = text
            if text == "" {
                self.isMessageHidden = true
                self.isAddMessageButtonHidden = false
            } else {
                self.isMessageHidden = false
                self.isAddMessageButtonHidden = true
            }
            controller.hide()
        }

        present(controller, animated: false, completion: nil)
    }

    private func onSendTestEmailButtonTapped() {
        let controller = TextFieldPopupViewController()
        controller.titleString = "Send test email"
        controller.titleAlignment = .center
        controller.rightButtonString = "SEND"
        controller.keyboardType = .emailAddress
        controller.placeholder = "Email"
        if let email = ListenerService.shared.user?.email {
            controller.text = email
        }
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] email in
            controller.hide()
            self?.sendTestEmail(toEmail: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        }
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

    private func sendTestEmail(toEmail email: String) {
        logger.debug("发送邮件: \(email)")
        showFullScreenLoadingNoAutoHide()
        invoice.emailText = message
        Functions.functions().httpsCallable("invoiceService-sendInvoiceTestEmail")
            .call([
                "email": email,
                "invoice": invoice.toJSON() ?? [:],
            ]) { [weak self] result, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("发送失败: \(error)")
                    TKToast.show(msg: "Send test email failed, please try again later.", style: .error)
                } else {
                    logger.debug("发送结果: \(String(describing: result?.data))")
                    TKToast.show(msg: "Email sent.", style: .success)
                }
            }
    }
}
