//
//  StudentAutoPaymentViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/5/25.
//  Copyright © 2022 spelist. All rights reserved.
//

import FirebaseFunctions
import PromiseKit
import SnapKit
import UIKit

class StudentAutoPaymentViewController: TKBaseViewController {
    private var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Auto Payment")

    @Live private var isLoading: Bool = false
    @Live private var isPaymetnMethodsLoading: Bool = true

    @Live private var customer: TKCustomerAccount?
    @Live private var paymentMethods: [TKStripePaymentMethod] = []

    var student: TKStudent
    init(_ student: TKStudent) {
        self.student = student
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentAutoPaymentViewController {
    override func initView() {
        super.initView()
        navigationBar.updateLayout(target: self)
        ViewBox(paddings: .zero) {
            VScrollStack {
                ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                    VStack {
                        HStack(alignment: .firstBaseline) {
                            Label("Auto Payment").textColor(ColorUtil.Font.third).font(.bold(18)).height(20)
                            Switch().fit()
                        }
                        Spacer(spacing: 15)
                        Label("Next invoice day on 11/15/2021").textColor(ColorUtil.Font.primary).font(.regular(size: 13)).height(20)
                    }
                }
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)) {
                    Divider(weight: 1, color: ColorUtil.dividingLine)
                }.height(1)
                ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                    HStack(alignment: .center) {
                        Label("Payment method").textColor(ColorUtil.Font.third).font(.bold(18)).height(20)
                        LoadingView(CGSize(width: 22, height: 22)).size(width: 22, height: 22).isLoading($isPaymetnMethodsLoading)
                    }
                }
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)) {
                    Divider(weight: 1, color: ColorUtil.dividingLine)
                }.height(1)
                VList(withData: $paymentMethods) { paymentMethods in
                    for method in paymentMethods {
                        ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
                            VStack(spacing: 20) {
                                HStack(alignment: .center, spacing: 20) {
                                    ImageView().size(width: 22, height: 22).cornerRadius(11)
                                        .apply { [weak self] imageView in
                                            guard let self = self else { return }
                                            self.$customer.addSubscriber { customer in
                                                var isSelected: Bool = false
                                                if let customer = customer, let customerInfo = customer.customerInfo {
                                                    if customerInfo.invoice_settings.default_payment_method == method.id {
                                                        isSelected = true
                                                    }
                                                }
                                                if isSelected {
                                                    _ = imageView.image(UIImage(named: "radiobuttonOn"))
                                                } else {
                                                    _ = imageView.image(UIImage(named: "checkboxOff"))
                                                }
                                            }
                                        }

                                    Label().textColor(ColorUtil.Font.third).font(.bold(18)).height(22).apply { label in
                                        let type: String
                                        let number: String
                                        switch method.type {
                                        case .card:
                                            guard let card = method.card else { return }
                                            type = card.brand.name
                                            number = "***\(card.last4)"
                                        case .us_bank_account:
                                            guard let bankAccount = method.us_bank_account else { return }
                                            switch bankAccount.account_type {
                                            case .checking:
                                                type = "CHECKING"
                                            case .savings:
                                                type = "SAVING"
                                            }
                                            number = "***\(bankAccount.last4)"
                                        default: return
                                        }
                                        label.text("\(type) \(number)")
                                    }

                                    Button().image(UIImage(named: "ic_delete_gray"), for: .normal).size(width: 22, height: 22).onTapped { [weak self] _ in
                                        guard let self = self else { return }
                                        self.removePaymentMethod(method)
                                    }
                                }
                                Divider(weight: 1, color: ColorUtil.dividingLine)
                            }
                        }
                        .onViewTapped { [weak self] _ in
                            guard let self = self else { return }
                            self.setPaymentMethodAsDefault(method)
                        }
                    }
                }
                ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
                    VStack(spacing: 20) {
                        HStack(alignment: .center, spacing: 20) {
                            Spacer(spacing: 20)
                            ImageView(image: UIImage(named: "icAddPrimary")).size(width: 22, height: 22)
                            Label("Add").textColor(ColorUtil.main).font(.bold(18))
                        }
                        Divider(weight: 1, color: ColorUtil.dividingLine)
                    }
                }.onViewTapped { [weak self] _ in
                    guard let self = self else { return }
                    self.onAddPaymentMethodButtonTapped()
                }
            }
            .applyScrollView { [weak self] view in
                guard let self = self else { return }
                self.$customer.addSubscriber { customer in
                    if customer == nil {
                        view.isHidden = true
                    } else {
                        view.isHidden = false
                    }
                }
            }
        }
        .backgroundColor(.white)
        .apply { view in
            view.setTopRadius()
        }
        .addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }

        $isLoading.addSubscriber { [weak self] isLoading in
            guard let self = self else { return }
            if isLoading {
                self.navigationBar.startLoading()
            } else {
                self.navigationBar.stopLoading()
            }
        }
    }
}

extension StudentAutoPaymentViewController {
    override func initData() {
        super.initData()
        loadCustomerInfo()
        initListener()
    }

    private func loadCustomerInfo() {
        logger.debug("开始加载customer")
        isLoading = true
        Functions.functions().httpsCallable("paymentService4Stripe-fetchCustomerForStudentSelf")
            .call { [weak self] result, error in
                guard let self = self else { return }
                self.isLoading = false
                if let error = error {
                    logger.error("获取customer失败: \(error)")
                    TKToast.show(msg: "Fetch data failed, please try again later.", style: .error)
                } else {
                    if let result = result, let funcResult = FuncResult.deserialize(from: result.data as? [String: Any]), let customer = TKCustomerAccount.deserialize(from: funcResult.data as? [String: Any]) {
                        logger.debug("解析customer成功: \(customer.toJSONString() ?? "")")
                        self.customer = customer
                        self.loadPaymentMethods()
                    } else {
                        logger.debug("解析customer失败: \(String(describing: result?.data))")
                    }
                }
            }
    }

    private func loadPaymentMethods() {
        backgroundTask { [weak self] in
            guard let self = self else { return }
            guard let customer = self.customer else { return }
            self.isLoading = true
            self.isPaymetnMethodsLoading = true
            logger.debug("开始加载paymentMethods")
            Functions.functions().httpsCallable("paymentService4Stripe-fetchPaymentMethods")
                .call(["customerId": customer.customerId]) { result, error in
                    self.isLoading = false
                    self.isPaymetnMethodsLoading = false
                    if let error = error {
                        logger.error("加载paymentMethods失败: \(error)")
                        TKToast.show(msg: "Fetch payment methods failed, please try again later.", style: .error)
                    } else {
                        if let funcResult = FuncResult.deserialize(from: result?.data as? [String: Any]), let data = funcResult.data as? [[String: Any]], let methods = [TKStripePaymentMethod].deserialize(from: data) as? [TKStripePaymentMethod] {
                            logger.debug("获取paymentMethods成功, 数量: \(methods.count)")
                            self.paymentMethods = methods
                        } else {
                            logger.debug("解析paymentMethods失败: \(String(describing: result?.data))")
                        }
                    }
                }
        }
    }

    private func initListener() {
        EventBus.listen(key: .paymentMethodAddComplete, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.loadPaymentMethods()
        }
    }
}

extension StudentAutoPaymentViewController {
    private func setPaymentMethodAsDefault(_ paymentMethod: TKStripePaymentMethod) {
        guard let customer = customer else {
            logger.error("Customer info is empty")
            return
        }
        SL.Alert.show(target: self, title: "Set payment method as default?", message: "Are you sure you want to set this payment method as default?", leftButttonString: "Go back", rightButtonString: "Confirm", leftButtonColor: ColorUtil.Font.primary, rightButtonColor: ColorUtil.main) {
        } rightButtonAction: { [weak self] in
            guard let self = self else { return }
            self.showFullScreenLoading()
            Functions.functions().httpsCallable("paymentService4Stripe-setPaymentMethodAsDefault")
                .call([
                    "customerId": customer.customerId,
                    "methodId": paymentMethod.id,
                ]) { result, error in
                    self.hideFullScreenLoading()
                    guard let result = result else {
                        logger.error("设置失败: \(String(describing: error))")
                        return
                    }

                    guard let funcResult = FuncResult.deserialize(from: result.data as? [String: Any]), let customer = TKCustomerAccount.deserialize(from: funcResult.data as? [String: Any]) else {
                        logger.error("解析结果失败: \(String(describing: error))")
                        return
                    }
                    logger.debug("设置默认支付方式成功: \(customer.toJSONString() ?? "")")
                    self.customer = customer
                }
        }
    }

    private func removePaymentMethod(_ paymentMethod: TKStripePaymentMethod) {
        guard let customer = customer else {
            logger.error("Customer info is empty")
            return
        }
        SL.Alert.show(target: self, title: "Remove payment method?", message: "Are you sure to remove this payment method?", leftButttonString: "DELETE", rightButtonString: "Go back", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main) { [weak self] in
            guard let self = self else { return }
            self.showFullScreenLoadingNoAutoHide()
            Functions.functions().httpsCallable("paymentService4Stripe-deletePaymentMethod")
                .call([
                    "customerId": customer.customerId,
                    "methodId": paymentMethod.id,
                ]) { _, error in
                    self.hideFullScreenLoading()
                    if let error = error {
                        logger.error("删除错误: \(error)")
                        TKToast.show(msg: "Remove failed, please try again later.", style: .error)
                    } else {
                        self.paymentMethods.removeElements({ $0.id == paymentMethod.id })
                        TKToast.show(msg: "Remove successfully.", style: .success)
                    }
                }
        } rightButtonAction: {
        }
    }
}

extension StudentAutoPaymentViewController {
    private func onAddPaymentMethodButtonTapped() {
        TKPopAction.show(items: [
            .init(title: "Card", action: { [weak self] in
                guard let self = self else { return }
                self.showAddCardPaymentMethod()
            }),
            .init(title: "Bank account", action: { [weak self] in
                guard let self = self else { return }
                self.showAddBankAccountPaymentMethod()
            }),

        ], target: self)
    }

    private func fetchSetupIntentSecret(customerId: String, paymentMethod: String) -> Promise<String?> {
        Promise { resolver in
            Functions.functions().httpsCallable("paymentService4Stripe-fetchCustomerSetupIntentSecret")
                .call(["customerId": customerId, "paymentMethod": paymentMethod]) { result, error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        if let result = result, let funcResult = FuncResult.deserialize(from: result.data as? [String: Any]), let responseData = SetupIntentResponse.deserialize(from: funcResult.data as? [String: Any]) {
                            resolver.fulfill(responseData.setupIntentSecret)
                        } else {
                            resolver.fulfill(nil)
                        }
                    }
                }
        }
    }

    private func showAddCardPaymentMethod() {
        showAddPaymentMethod(paymentMethod: "card")
    }

    private func showAddBankAccountPaymentMethod() {
        showAddPaymentMethod(paymentMethod: "us_bank_account")
    }
    
    private func showAddPaymentMethod(paymentMethod: String) {
        guard let customer = self.customer else { return }
        self.showFullScreenLoadingNoAutoHide()
        akasync { [weak self] in
            guard let self = self else { return }
            guard let secret = try akawait(self.fetchSetupIntentSecret(customerId: customer.customerId, paymentMethod: paymentMethod)) else {
                updateUI {
                    TKToast.show(msg: "Fetch data failed, please try again later.", style: .error)
                }
                return
            }
            updateUI {
                self.hideFullScreenLoading()
            }
            logger.debug("secret: \(secret)")
            let setupResult = try akawait(StripePayment.show(setupIntentSecret: secret))
            switch setupResult {
            case .completed:
                logger.debug("setup completed")
                self.loadPaymentMethods()
            case .canceled:
                logger.debug("setup canceled")
            case let .failed(error):
                logger.error("setup failed: \(error)")
                TKToast.show(msg: "Add card failed, please try again later.", style: .error)
            }
        }
    }
}
