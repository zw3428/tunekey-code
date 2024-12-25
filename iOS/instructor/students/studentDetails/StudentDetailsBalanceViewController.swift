//
//  StudentDetailsBalanceViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/3/2.
//  Copyright © 2022 spelist. All rights reserved.
//

import FirebaseFirestore
import PromiseKit
import SafariServices
import SnapKit
import UIKit

class StudentDetailsBalanceViewController: TKBaseViewController {
    @Live var isStudentView: Bool = false {
        didSet {
            if isStudentView {
                navigationBar.hiddenRightButton()
            }
        }
    }

    private lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "", rightButton: UIImage(named: "ic_more_primary")!) { [weak self] in
        guard let self = self else { return }
        if self.student.studentId == (UserService.user.id() ?? "") {
            self.onMoreTapped()
        } else {
            self.onAddButtonTapped()
        }
    }

    @Live var balanceString: String = "0"
    @Live var totalPaymentString: String = "0"
    @Live var fileTypeString: String = "Transaction - All"
    @Live var isEmptyViewHidden: Bool = true

    var transactionType: TKTransaction.TransactionType? {
        didSet {
            if let transactionType = transactionType {
                fileTypeString = "Transaction - \(transactionType.rawValue.capitalized)"
            } else {
                fileTypeString = "Transaction - All"
            }
        }
    }

    var unpaidInvoices: [TKInvoice] = [] {
        didSet {
            collectionView.snp.updateConstraints { make in
                if unpaidInvoices.count > 0 {
                    let height: CGFloat = 206
//                    if isStudentView {
//                        height = 145
//                    } else {
//                        height = 206
//                    }
                    make.height.equalTo(height)
                } else {
                    make.height.equalTo(0)
                }
            }
            if transactions.isEmpty && unpaidInvoices.isEmpty {
                isEmptyViewHidden = false
            } else {
                isEmptyViewHidden = true
            }
        }
    }

    var transactions: [TKTransaction] = [] {
        didSet {
            if transactions.isEmpty && unpaidInvoices.isEmpty {
                isEmptyViewHidden = false
            } else {
                isEmptyViewHidden = true
            }
//            tableView.isHidden = transactions.isEmpty
        }
    }

    private var invoiceConfig: TKInvoiceConfigV2?

    private lazy var balanceView: TKView = makeBalanceView()
    private lazy var totalPaymentView: TKView = makeTotalPaymentView()
    private lazy var tableView: UITableView = makeTableView()

    private lazy var collectionViewLayout: CenteredCollectionViewFlowLayout = {
        let layout = CenteredCollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let height: CGFloat = 206
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 40, height: height)
        return layout
    }()

    private lazy var collectionView: UICollectionView = makeCollectionView()
    var student: TKStudent {
        didSet {
            logger.debug("设置了学生信息: \(student.toJSONString() ?? "")")
            balanceString = "\(student.invoiceBalance.doubleValue.amountFormat())"
            totalPaymentString = "\(student.invoicePayment.doubleValue.amountFormat())"
        }
    }

    init(_ student: TKStudent) {
        self.student = student
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
        navigationBar.showRightButton()
    }
}

extension StudentDetailsBalanceViewController {
    private func makeBalanceView() -> TKView {
        let width = (UIScreen.main.bounds.width - 50) / 2
        let view = TKView.create()
            .gradientBackgroundColor(startColor: UIColor(hex: "#FF7B01"), endColor: UIColor(hex: "#FECC52"), direction: .leftToRight, size: CGSize(width: width, height: 80))
            .corner(size: 8)
            .showShadow()
        VStack {
            ViewBox(paddings: .init(top: 10, left: 10, bottom: 3, right: 10)) {
                Label()
                    .text("Balance")
                    .textColor(.white)
                    .font(FontUtil.regular(size: 13))
            }
            // 分割线
            View()
                .size(width: width, height: 1)
                .backgroundColor(ColorUtil.dividingLine)
            ViewBox(paddings: .init(top: 9, left: 10, bottom: 10, right: 10)) {
                HStack(distribution: .fillProportionally, alignment: .bottom, spacing: 6) {
                    Label()
                        .text("$")
                        .textColor(.white)
                        .font(FontUtil.bold(size: 16))
                        .size(width: 10, height: 20)
                    Label()
                        .text($balanceString)
                        .textColor(.white)
                        .font(FontUtil.bold(size: 24))
                        .size(width: nil, height: 24)
                }
            }
        }
        .addTo(superView: view) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        return view
    }

    private func makeTotalPaymentView() -> TKView {
        let width = (UIScreen.main.bounds.width - 50) / 2
        let view = TKView.create()
            .gradientBackgroundColor(startColor: UIColor(hex: "#A87FFF"), endColor: UIColor(hex: "#6B75FC"), direction: .leftToRight, size: CGSize(width: width, height: 80))
            .corner(size: 8)
            .showShadow()
        VStack {
            ViewBox(paddings: .init(top: 10, left: 10, bottom: 3, right: 10)) {
                Label()
                    .text("Total payment")
                    .textColor(.white)
                    .font(FontUtil.regular(size: 13))
            }
            // 分割线
            View()
                .size(width: width, height: 1)
                .backgroundColor(ColorUtil.dividingLine)
            ViewBox(paddings: .init(top: 9, left: 10, bottom: 10, right: 10)) {
                HStack(distribution: .fillProportionally, alignment: .bottom, spacing: 6) {
                    Label()
                        .text("$")
                        .textColor(.white)
                        .font(FontUtil.bold(size: 16))
                        .size(width: 10, height: 20)
                    Label()
                        .text($totalPaymentString)
                        .textColor(.white)
                        .font(FontUtil.bold(size: 24))
                        .size(width: nil, height: 24)
                }
            }
        }
        .addTo(superView: view) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        return view
    }

    private func makeTableView() -> UITableView {
        let tableView = UITableView()
        tableView.setTopRadius()
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = ColorUtil.dividingLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20 + UiUtil.safeAreaBottom(), right: 0)
        tableView.register(StudentDetailsBalanceTransactionTableViewCell.self, forCellReuseIdentifier: StudentDetailsBalanceTransactionTableViewCell.id)
        tableView.dataSource = self
        tableView.delegate = self

        let view = TKView.create()
            .frame(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
            .backgroundColor(color: .white)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

        ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
            HStack {
                Label($fileTypeString)
                    .textColor(ColorUtil.Font.primary)
                    .font(FontUtil.regular(size: 13))
                ImageView(image: UIImage(named: "filter"))
                    .size(width: 22)
                    .onViewTapped { [weak self] _ in
                        self?.onTransactionFilterTapped()
                    }
            }
        }
        .addTo(superView: view) { make in
            make.top.left.right.bottom.equalToSuperview()
        }

        tableView.tableHeaderView = view

        return tableView
    }

    private func makeCollectionView() -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = ColorUtil.backgroundColor
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(StudentDetailsBalanceUnpaidItemCollectionViewCell.self, forCellWithReuseIdentifier: StudentDetailsBalanceUnpaidItemCollectionViewCell.id)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.decelerationRate = .fast
        return collectionView
    }
}

extension StudentDetailsBalanceViewController {
    override func initView() {
        super.initView()
        enablePanToDismiss()
        navigationBar.updateLayout(target: self)
        navigationBar.title = student.name
        let topViewWidth = (UIScreen.main.bounds.width - 50) / 2
        balanceView.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.width.equalTo(topViewWidth)
            make.height.equalTo(80)
        }

        totalPaymentView.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(topViewWidth)
            make.height.equalTo(80)
        }

        collectionView.addTo(superView: view) { make in
            make.top.equalTo(balanceView.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }

        tableView.addTo(superView: view) { make in
            make.top.equalTo(collectionView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }

        ViewBox(paddings: UIEdgeInsets(top: 80, left: 37, bottom: 200 + UiUtil.safeAreaBottom(), right: 37)) {
            VStack(distribution: .equalSpacing) {
                ImageView(image: UIImage(named: "invoices_empty"))
                    .size(height: 180)
                BlockButton()
                    .set(title: "NEW INVOICE", style: .normal)
                    .size(width: 260, height: 50)
                    .isHidden($isStudentView)
                    .onTapped { [weak self] _ in
                        logger.debug("点击按钮了")
                        self?.onAddButtonTapped()
                    }
            }
        }
        .backgroundColor(ColorUtil.backgroundColor)
        .isHidden($isEmptyViewHidden)
        .addTo(superView: view) { make in
            make.top.equalTo(balanceView.snp.bottom)
            make.bottom.left.right.equalToSuperview()
        }
        initListeners()
    }
}

extension StudentDetailsBalanceViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        unpaidInvoices.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StudentDetailsBalanceUnpaidItemCollectionViewCell.id, for: indexPath) as! StudentDetailsBalanceUnpaidItemCollectionViewCell
        let invoice = unpaidInvoices[indexPath.item]
        logger.debug("当前渲染的invoice: \(invoice.toJSONString() ?? "")")
        if invoice.markAsPay {
            cell.topTitleString = "Unconfirmed payment"
        } else {
            cell.topTitleString = "Invoice unpaid"
        }
        cell.title = student.name
        cell.amountString = "$\(invoice.totalAmount)"
        cell.lessonTypeString = invoice.manualItems.compactMap({ $0.description }).joined(separator: ", ")
        cell.invoiceInfoString = invoice.numString()
        cell.dueDateString = "Due to \(Date(seconds: invoice.billingTimestamp + (TimeInterval(invoice.quickInvoiceDueDate) * 86400)).toLocalFormat("M/dd/yyyy"))"
        if isStudentView {
            if invoice.markAsPay {
                cell.buttonString = "UNDO MARKED"
            } else {
                cell.buttonString = "PAY NOW"
            }
        } else {
            if invoice.markAsPay {
                cell.buttonString = "CONFIRM RECEIVED"
            } else {
                cell.buttonString = "RECORD PAYMENT"
            }
        }
        cell.isButtonEnabled = true
        cell.buttonColor = ColorUtil.main
//        if invoice.status == .paying {
//            cell.buttonString = "PROCESSING"
//            cell.isButtonEnabled = false
//            cell.buttonColor = ColorUtil.Font.primary
//        }
        cell.isStudentView = isStudentView
        if invoice.paidAmount.compare(0) == .orderedDescending {
            cell.paidAmount = "$\(invoice.paidAmount)"
        } else {
            cell.paidAmount = ""
        }
        // 计算还未支付的价格 = 总价 - 已支付的价格 - 抹去的价格
//        let unpaidAmount: Dollar = invoice.totalAmount - invoice.paidAmount - invoice.waivedAmount
//        if invoice.status == .paying {
//            cell.paidAmount = "Paid \(invoice.totalAmount.string)"
//            cell.paidAmountColor = ColorUtil.Font.primary
//        } else {
        let unpaidAmount: Dollar = invoice.totalAmount.subtracting(invoice.paidAmount).subtracting(invoice.waivedAmount)
        cell.paidAmount = "Unpaid $\(unpaidAmount.doubleValue.amountFormat())"
        if unpaidAmount.compare(0) == .orderedDescending {
            if invoice.markAsPay {
                cell.paidAmount = "Paid $\(unpaidAmount.doubleValue.amountFormat())"
                cell.paidAmountColor = ColorUtil.Font.primary
            } else {
                cell.paidAmountColor = ColorUtil.red
            }
        } else {
            cell.paidAmountColor = ColorUtil.Font.primary
        }
//        }
        cell.onButtonTapped = { [weak self] in
            self?.onUnpaidInvoiceButtonTapped(atIndex: indexPath.item)
        }
        cell.contentView.onViewTapped { [weak self] _ in
            self?.onInvoiceTapped(atIndex: indexPath.item)
        }
        return cell
    }

    private func onUnpaidInvoiceButtonTapped(atIndex index: Int) {
        let invoice = unpaidInvoices[index]
        logger.debug("准备支付invoice: \(invoice.id)")
        // TODO: - 修改为和家长一样
        if isStudentView {
            // 唤起付款界面
            // 获取可用的接受的支付方式
            if invoice.markAsPay {
                onMarkAsPayTapped(invoice, markAsPay: false)
            } else {
                let studioId = invoice.studioId
                
                var items: [PopSheet.Item] = []
                showFullScreenLoadingNoAutoHide()
                akasync {
                    let paymentLinks = try akawait(PaymentService.shared.fetchStudioAccetpedPaymentLinks(studioId: studioId))
//                    if paymentLinks.isNotEmpty {
//                        items.append(.init(title: "Payment Link", action: { [weak self] in
//                            guard let self = self else { return }
//                            self.onStudentSelectPaymentMethods(invoice)
//                        }))
//                    }
                    
                    for paymentLink in paymentLinks {
                        items.append(.init(title: paymentLink.name.uppercased(), action: { [weak self] in
                            guard let self = self else { return }
                            logger.debug("选择Paymentlink: \(paymentLink)")
                            self.payInvoiceWithLink(withLink: paymentLink, invoice: invoice)
                        }))
                    }

                    let account = try akawait(PaymentService.shared.fetchStudioAcceptedPaymentAccount(studioId: studioId))
                    if let accountInfo = account?.accountInfo, accountInfo.requirements.disabled_reason == nil {
                        items.append(.init(title: "Credit & Debit Card or Bank", action: { [weak self] in
                            guard let self = self else { return }
                            self.payInvoiceWithCardOrBank(withInvoice: invoice)
                        }))
                    }
                    items.append(
                        .init(title: "Mark As Paid", action: { [weak self] in
                            self?.onMarkAsPayTapped(invoice, markAsPay: !invoice.markAsPay)
                        })
                    )
                    updateUI { [weak self] in
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                        PopSheet().items(items)
                            .show()
                    }
                }
            }
        } else {
            // 老师记录
            logger.debug("老师进行记录payment")
            onUnpaidInvoiceButtonTapped(withInvoice: invoice)
        }
    }

    private func onStudentSelectPaymentMethods(_ invoice: TKInvoice) {
        let controller = StudioAcceptPaymentMethodsSelectorViewController(invoice.studioId)
        controller.modalPresentationStyle = .custom
        Tools.getTopViewController()?.present(controller, animated: false, completion: nil)
        controller.onPaymentSelected = { [weak self] method in
            guard let self = self else { return }
            switch method.category {
            case .link:
                guard let link = method.link else { return }
                self.payInvoiceWithLink(withLink: link, invoice: invoice)
            case .card, .bank:
                    break
            }
        }
    }

    private func payInvoiceWithLink(withLink link: TKLink, invoice: TKInvoice) {
        // 添加记录
        showFullScreenLoadingNoAutoHide()
        Functions.functions().httpsCallable("invoiceService-sendPaidRequestForInvoice")
            .call(["invoiceId": invoice.id, "paymentLink": link.link]) { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("发生错误: \(error)")
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                } else {
                    // 成功,跳转
                    let controller = SFSafariViewController(url: URL(string: link.link)!)
                    Tools.getTopViewController()?.present(controller, animated: true, completion: nil)
                }
            }
    }

    private func payInvoiceWithCardOrBank(withInvoice invoice: TKInvoice) {
        logger.debug("使用stripe支付: \(invoice.id)")
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller("paymentStripe-fetchPaymentLinkForInvoice")
            .appendData(key: "id", value: invoice.id)
            .call { [weak self] result, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    logger.error("发生错误: \(error)")
                    TKToast.show(msg: "Can not fetch payment link, please try again later.", style: .error)
                } else {
                    if let funcResult = FuncResult.deserialize(from: result?.data as? [String: Any]), funcResult.code == 0, let paymentLinkResult = PaymentLinkResult.deserialize(from: funcResult.data as? [String: Any]), let url = URL(string: paymentLinkResult.url) {
                        logger.debug("创建支付链接完成: \(paymentLinkResult.url)")
                        UIApplication.shared.open(url)
                    } else {
                        TKToast.show(msg: "Can not fetch payment link, please try again later.", style: .error)
                    }
                }
            }

//        StripePayment.pay(invoiceId: invoice.id) { [weak self] result in
//            guard let self = self else { return }
//            updateUI {
//                self.hideFullScreenLoading()
//            }
//            switch result {
//            case .completed:
//                logger.debug("支付完成")
//                updateUI {
//                    TKToast.show(msg: "Payment successful", style: .success)
//                    self.loadData()
//                }
//            case .canceled:
//                logger.debug("支付取消")
//                TKToast.show(msg: "Payment canceled", style: .warning)
//            case let .failed(error):
//                logger.error("支付错误: \(error)")
//                TKToast.show(msg: "Payment failed, reason: \(error)", style: .error)
//            }
//        }
    }

    private func onUnpaidInvoiceButtonTapped(withInvoice invoice: TKInvoice) {
        let controller = StudioBalanceRecordAmountViewController()
        controller.paymentMethodsTypeSelectorGroup = TKRadioGroup(["CASH", "CHECK"])
        controller.titleString = "Record Payment"
        controller.placeholder = "Amount"
        controller.keyboardType = .decimalPad
        controller.paymentMethod = .cash
        controller.rightButtonString = "RECORD"
        let amount = (invoice.totalAmount - invoice.paidAmount).doubleValue.descWithCleanZero
        controller.textBox?.value(amount)
        controller.text = amount
        controller.onLeftButtonTapped = { _, _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] amountString, paymentMethod in
            guard let self = self else { return }
            let amount = NSDecimalNumber(string: amountString)
            controller.view.endEditing(true)
            controller.hide()
            self.recordPayment(withInvoice: invoice, amount: amount, paymentMethod: paymentMethod)
        }
        controller.onTextChanged = { text, _, rightButton in
            if text != "" {
                let amount = NSDecimalNumber(string: text)
                if amount.compare(0) == .orderedDescending {
                    rightButton.enable()
                } else {
                    rightButton.disable()
                }
//                let maxAmount = invoice.totalAmount - invoice.paidAmount - invoice.waivedAmount
//                if amount.compare(maxAmount) == .orderedDescending {
//                    controller.textBox?.value(maxAmount.doubleValue.descWithCleanZero)
//                    controller.text = maxAmount.doubleValue.descWithCleanZero
//                }
            } else {
                rightButton.disable()
            }
        }
        if let topViewController = Tools.getTopViewController() {
            controller.pop(from: topViewController) {
                controller.textBox?.prefix(GlobalFields.currencySymbol)
                controller.rightButton?.disable()
            }
        }
    }

    private func recordPayment(withInvoice invoice: TKInvoice, amount: Dollar, paymentMethod: TKTransaction.PaymentMethod) {
        guard let userId = UserService.user.id() else { return }
        showFullScreenLoadingNoAutoHide()
        Functions.functions().httpsCallable("invoiceService-recordPaymentForManualInvoice")
            .call([
                "invoiceId": invoice.id,
                "recordorId": userId,
                "amount": amount,
                "paymentMethod": paymentMethod.rawValue,
            ]) { [weak self] result, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let resultData = result?.data as? [String: Any], let funcResult = FuncResult.deserialize(from: resultData) {
                    if funcResult.code == 200 {
                        updateUI {
                            self.loadData()
                        }
                        TKToast.show(msg: "Successfully", style: .success)
                    } else {
                        TKToast.show(msg: "Record payment failed, please try again later.", style: .error)
                    }
                } else {
                    logger.error("record payment发生错误: \(String(describing: error))")
                    TKToast.show(msg: "Record payment failed, please try again later.", style: .error)
                }
            }
    }

    private func onMarkAsPayTapped(_ invoice: TKInvoice, markAsPay: Bool) {
        logger.debug("支付invoice: \(invoice.id) | \(invoice.studioId)")
        guard let userId = UserService.user.id() else { return }
        showFullScreenLoadingNoAutoHide()
        Firestore.firestore().runTransaction { transaction, pointer in
            do {
                let invoiceDoc = try transaction.getDocument(DatabaseService.collections.invoice().document(invoice.id))
                if !invoiceDoc.exists {
                    pointer?.pointee = NSError(domain: "invoice can not be found", code: 404, userInfo: [:])
                }
                let invoiceData = invoiceDoc.data()
                if let invoice = TKInvoice.deserialize(from: invoiceData) {
                    if markAsPay {
                        let statusChangeHistoryItem = TKInvoiceStatusChangeHistory(id: IDGenerator.nextId(), invoiceId: invoice.id, userId: userId, from: invoice.status, to: .markedAsPaid, timestamp: .now, transactionId: "", transaction: nil)
                        transaction.updateData(["markAsPay": markAsPay, "statusChangeHistory": FieldValue.arrayUnion([statusChangeHistoryItem.toJSON() ?? [:]])], forDocument: DatabaseService.collections.invoice().document(invoice.id))
                    } else {
                        var statusChangeHistory = invoice.statusChangeHistory
                        statusChangeHistory.removeElements({ $0.to == .markedAsPaid })
                        transaction.updateData(["markAsPay": markAsPay, "statusChangeHistory": statusChangeHistory.toJSON()], forDocument: DatabaseService.collections.invoice().document(invoice.id))
                    }
                }
            } catch {
                pointer?.pointee = error as NSError
            }
            return nil
        } completion: { [weak self] _, error in
            guard let self = self else { return }
            self.hideFullScreenLoading()
            if let error {
                if markAsPay {
                    TKToast.show(msg: "Mark invoice paid failed, please try again later.", style: .error)
                } else {
                    TKToast.show(msg: "Undo marked failed, please try again later.", style: .error)
                }
                logger.error("标记失败: \(error)")
            } else {
                self.loadData()
                TKToast.show(msg: "Successfully.", style: .success)
            }
        }
    }
}

extension StudentDetailsBalanceViewController {
    private func onInvoiceButtonTappedWhenStudentView(invoice: TKInvoice) {
        if !invoice.markAsPay {
            SL.Alert.show(target: self, title: "Mark as paid?", message: "Online payment will be available soon, instead, you can mark this as a paid invoice if you already paid offline.", leftButttonString: "GO BACK", rightButtonString: "MARK AS PAID", leftButtonColor: ColorUtil.Font.primary, rightButtonColor: ColorUtil.main) {
            } rightButtonAction: { [weak self] in
                self?.onMarkAsPay(invoice: invoice)
            }
        } else {
            SL.Alert.show(target: self, title: "Undo marked?", message: "Tap on CONFIRM to restore this as a unpaid invoice.", leftButttonString: "GO BACK", rightButtonString: "CONFIRM", leftButtonColor: ColorUtil.Font.primary, rightButtonColor: ColorUtil.main) {
            } rightButtonAction: { [weak self] in
                self?.onUndoMarked(invoice: invoice)
            }
        }
    }

    private func onMarkAsPay(invoice: TKInvoice) {
        showFullScreenLoadingNoAutoHide()
        logger.debug("开始修改invoice为markAsPay: \(invoice.toJSONString() ?? "")")
        DatabaseService.collections.invoice()
            .document(invoice.id)
            .updateData(["markAsPay": true]) { [weak self] error in
                guard let self = self else { return }
                logger.debug("调用更改完成")
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("发生错误: \(error)")
                    TKToast.show(msg: "Mark as paid failed, please try again later.", style: .error)
                } else {
                    logger.debug("更改成功")
                    for (index, item) in self.unpaidInvoices.enumerated() {
                        if item.id == invoice.id {
                            self.unpaidInvoices[index].markAsPay = true
                            logger.debug("修改之后的invoice: \(self.unpaidInvoices[index].toJSONString() ?? "")")
                            self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                            break
                        }
                    }
                }
            }
    }

    private func onUndoMarked(invoice: TKInvoice) {
        showFullScreenLoadingNoAutoHide()
        DatabaseService.collections.invoice()
            .document(invoice.id)
            .updateData(["markAsPay": false]) { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("发生错误: \(error)")
                    TKToast.show(msg: "Mark as paid failed, please try again later.", style: .error)
                } else {
                    for (index, item) in self.unpaidInvoices.enumerated() {
                        if item.id == invoice.id {
                            self.unpaidInvoices[index].markAsPay = false
                            self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                            break
                        }
                    }
                }
            }
    }
}

extension StudentDetailsBalanceViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: StudentDetailsBalanceTransactionTableViewCell.id, for: indexPath) as! StudentDetailsBalanceTransactionTableViewCell
        let transaction = transactions[indexPath.row]
        cell.titleString = student.name
        switch transaction.transactionType {
        case .pay:
            if isStudentView {
                cell.amountString = "$\(transaction.amount.doubleValue.amountFormat())"
//                cell.amountIcon = UIImage(named: "ic_arrow_down")
                cell.amountIcon = nil
            } else {
                cell.amountString = "$\(transaction.amount.doubleValue.amountFormat())"
                cell.amountIcon = UIImage(named: "ic_arrow_up")
            }
            cell.transactionTypeString = "Lesson payment"
        case .refund:
            cell.transactionTypeString = "Refund"
            if isStudentView {
                cell.amountString = "-$\(transaction.amount.doubleValue.amountFormat())"
//                cell.amountIcon = UIImage(named: "ic_arrow_up")
                cell.amountIcon = nil
            } else {
                cell.amountString = "-$\(transaction.amount.doubleValue.amountFormat())"
                cell.amountIcon = UIImage(named: "ic_arrow_down")
            }
        case .waive:
            cell.transactionTypeString = "Waive $\(transaction.amount.doubleValue.amountFormat())"
            cell.amountString = "$0.00"
            cell.amountIcon = nil
        case .void:
            cell.transactionTypeString = "Void $\(transaction.amount.doubleValue.amountFormat())"
            cell.amountString = "$0.00"
            cell.amountIcon = nil
        case .payout:
            break
        }
        if let invoice = transaction.invoice {
            cell.invoiceInfoString = "Invoice \(invoice.numString()) | \(Date(seconds: transaction.createTimestamp).toLocalFormat("MM/dd/yyyy"))"
        } else {
            cell.invoiceInfoString = Date(seconds: transaction.createTimestamp).toLocalFormat("MM/dd/yyyy")
        }
        cell.contentView.onViewTapped { [weak self] _ in
            self?.onTransactionTapped(atIndex: indexPath.row)
        }
        return cell
    }
}

extension StudentDetailsBalanceViewController {
    func loadData(withLoading: Bool = true) {
        if withLoading {
//            showFullScreenLoadingNoAutoHide()
            navigationBar.startLoading()
        }
        akasync { [weak self] in
            guard let self = self else { return }
            do {
                self.invoiceConfig = try akawait(self.loadInvoiceConfig())
                try akawait(self.loadUnpaidInvoices())
                try akawait(self.loadTransactions())
                try akawait(self.loadStudentInfo())
                if withLoading {
                    DispatchQueue.main.async {
                        self.navigationBar.stopLoading()
                    }
                }
            } catch {
                logger.error("加载数据错误: \(error)")
                DispatchQueue.main.async {
//                    self.hideFullScreenLoading()
                    self.navigationBar.stopLoading()
                }
            }
        }
    }

    private func loadInvoiceConfig() -> Promise<TKInvoiceConfigV2?> {
        DatabaseService.collections.invoiceConfigV2()
            .document("\(student.studioId):\(student.studentId)")
            .getDocumentData(TKInvoiceConfigV2.self)
    }

    @discardableResult private func loadUnpaidInvoices() -> Promise<Void> {
        Promise { resolver in
            akasync { [weak self] in
                guard let self = self else { return resolver.fulfill(()) }
                logger.debug("加载未支付的invoices")
                let studioId: String
                if self.student.studioId != "" {
                    studioId = self.student.studioId
                } else if let studio = ListenerService.shared.studioManagerData.studio {
                    studioId = studio.id
                } else if let teacherInfo = ListenerService.shared.teacherData.teacherInfo {
                    studioId = teacherInfo.studioId
                } else if let teacherInfo = ListenerService.shared.studentData.teacherData {
                    studioId = teacherInfo.studioId
                } else {
                    if let studioInfo = try akawait(UserService.studio.getStudioInfo(teacherId: self.student.teacherId)) {
                        studioId = studioInfo.id
                    } else {
                        DispatchQueue.main.async {
                            resolver.reject(TKError.userNotLogin)
                        }
                        return
                    }
                }
                guard !studioId.isEmpty else {
                    logger.error("获取studioId失败")
                    return
                }
                DatabaseService.collections.invoice()
                    .whereField("studioId", isEqualTo: studioId)
                    .whereField("studentId", isEqualTo: self.student.studentId)
                    .whereField("status", in: [TKInvoiceStatus.paying.rawValue, TKInvoiceStatus.created.rawValue, TKInvoiceStatus.sent.rawValue, TKInvoiceStatus.waived.rawValue])
                    .order(by: "billingTimestamp", descending: false)
                    //                .limit(to: 1)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            logger.error("获取未支付的invoices失败: \(error)")
                            self.unpaidInvoices = []
                            self.collectionView.reloadData()
                            resolver.reject(error)
                        } else {
                            if var data: [TKInvoice] = [TKInvoice].deserialize(from: snapshot?.documents.compactMap({ $0.data() })) as? [TKInvoice] {
                                // TODO: - 还要计算是否expire
                                for item in data {
                                    if item.status == .waived && item.waivedAmount + item.paidAmount == item.totalAmount {
                                        data.removeElements({ $0.id == item.id })
                                    }
                                }
                                self.unpaidInvoices = data

                            } else {
                                self.unpaidInvoices = []
                            }
                            logger.debug("获取未支付的invoice数据完成: \(self.unpaidInvoices.count)")
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                            resolver.fulfill(())
                        }
                    }
            }
        }
    }

    @discardableResult private func loadTransactions() -> Promise<Void> {
        Promise { resolver in
            akasync { [weak self] in
                guard let self = self else { return }
                do {
                    let studioId: String
                    if self.student.studioId != "" {
                        studioId = self.student.studioId
                    } else if let studio = ListenerService.shared.studioManagerData.studio {
                        studioId = studio.id
                    } else if let teacherInfo = ListenerService.shared.teacherData.teacherInfo {
                        studioId = teacherInfo.studioId
                    } else if let teacherInfo = ListenerService.shared.studentData.teacherData {
                        studioId = teacherInfo.studioId
                    } else {
                        if let studioInfo = try akawait(UserService.studio.getStudioInfo(teacherId: self.student.teacherId)) {
                            studioId = studioInfo.id
                        } else {
                            DispatchQueue.main.async {
                                resolver.reject(TKError.userNotLogin)
                            }
                            return
                        }
                    }
                    var query = DatabaseService.collections.transactions()
                        .whereField("studioId", isEqualTo: studioId)
                        .whereField("payerId", isEqualTo: self.student.studentId)
                    if let transactionType = self.transactionType {
                        query = query.whereField("transactionType", isEqualTo: transactionType.rawValue)
                    }
                    logger.debug("获取transaction的参数: \(studioId) | \(self.student.studentId)")
                    query.order(by: "createTimestamp", descending: true)
                        .getDocuments { [weak self] snapshot, error in
                            guard let self = self else { return }
                            if let error = error {
                                logger.error("获取transaction错误: \(error)")
                                DispatchQueue.main.async {
                                    resolver.reject(error)
                                }
                            } else {
                                if let data: [TKTransaction] = [TKTransaction].deserialize(from: snapshot?.documents.compactMap({ $0.data() })) as? [TKTransaction] {
                                    self.transactions = data
                                } else {
                                    self.transactions = []
                                }
                                logger.debug("加载交易信息完成: \(self.transactions.count)")
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    resolver.fulfill(())
                                }
                            }
                        }
                } catch {
                    DispatchQueue.main.async {
                        resolver.reject(error)
                    }
                }
            }
        }
    }

    @discardableResult private func loadStudentInfo() -> Promise<Void> {
        Promise { resolver in
            logger.debug("加载学生信息")
            let studentId = student.studentId
            let id: String
            guard let user = ListenerService.shared.user else {
                return resolver.reject(TKError.userNotLogin)
            }
            switch user.currentUserDataVersion {
            case let .unknown(version: _):
                return resolver.reject(TKError.error("User data version is unknown"))
            case .singleTeacher:
                id = student.teacherId
            case .studio:
                id = student.studioId
            }

            DatabaseService.collections.teacherStudentList()
                .document("\(id):\(studentId)")
                .getDocument { [weak self] snapshot, error in
                    guard let self = self else { return }
                    if let error = error {
                        logger.error("获取学生数据失败: \(error)")
                        resolver.reject(error)
                    } else {
                        if let data: TKStudent = TKStudent.deserialize(from: snapshot?.data()) {
                            DispatchQueue.main.async {
                                self.student = data
                            }
                        }
                        logger.debug("加载学生信息完成")
                        resolver.fulfill(())
                    }
                }
        }
    }
}

extension StudentDetailsBalanceViewController {
    override func bindEvent() {
        super.bindEvent()
    }

    private func onTransactionFilterTapped() {
        TKPopAction.show(items: [
            .init(title: "All", action: { [weak self] in
                guard let self = self else { return }
                self.transactionType = nil
                self.showFullScreenLoadingNoAutoHide()
                akasync {
                    try akawait(self.loadTransactions())
                    DispatchQueue.main.async {
                        self.hideFullScreenLoading()
                    }
                }
            }),
            .init(title: TKTransaction.TransactionType.pay.rawValue.capitalized, action: { [weak self] in
                guard let self = self else { return }
                self.transactionType = .pay
                self.showFullScreenLoadingNoAutoHide()
                akasync {
                    try akawait(self.loadTransactions())
                    DispatchQueue.main.async {
                        self.hideFullScreenLoading()
                    }
                }
            }),
            .init(title: TKTransaction.TransactionType.refund.rawValue.capitalized, action: { [weak self] in
                guard let self = self else { return }
                self.transactionType = .refund
                self.showFullScreenLoadingNoAutoHide()
                akasync {
                    try akawait(self.loadTransactions())
                    DispatchQueue.main.async {
                        self.hideFullScreenLoading()
                    }
                }
            }),
            .init(title: TKTransaction.TransactionType.void.rawValue.capitalized, action: { [weak self] in
                guard let self = self else { return }
                self.transactionType = .void
                self.showFullScreenLoadingNoAutoHide()
                akasync {
                    try akawait(self.loadTransactions())
                    DispatchQueue.main.async {
                        self.hideFullScreenLoading()
                    }
                }
            }),
            .init(title: TKTransaction.TransactionType.waive.rawValue.capitalized, action: { [weak self] in
                guard let self = self else { return }
                self.transactionType = .waive
                self.showFullScreenLoadingNoAutoHide()
                akasync {
                    try akawait(self.loadTransactions())
                    DispatchQueue.main.async {
                        self.hideFullScreenLoading()
                    }
                }
            }),
        ], target: self)
    }

    private func onAddButtonTapped() {
        var items: [PopSheet.Item] = []
        if let invoiceConfig, invoiceConfig.status == .active {
            items.append(.init(title: "Personalize Auto-invoicing", action: { [weak self] in
                self?.showAutoInvoicing()
            }))
        }
        items.append(.init(title: "Add Manual invoice", action: { [weak self] in
            self?.showManualInvoice()
        }))
        PopSheet().items(items).show()
    }

    private func showAutoInvoicing() {
        let controller = StudioBillingAutoInvoicingEditViewController(student: student)
        controller.enableHero()
        present(controller, animated: true)
    }

    private func showManualInvoice() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let controller = StudentDetailsBalanceAddNewInvoiceViewController(self.student)
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            self.present(controller, animated: true, completion: nil)
        }
    }

    private func onTransactionTapped(atIndex index: Int) {
        let transaction = transactions[index]
        logger.debug("点击transaction信息: \(transaction.toJSONString() ?? "")")
        let invoiceId = transaction.invoiceId
        let suffix: String
        if isStudentView {
            suffix = "/student"
        } else {
            suffix = "/teacher"
        }
        guard let url = URL(string: "https://tunekey.app/balance/transaction/\(invoiceId)\(suffix)") else { return }
        showFullScreenLoadingNoAutoHide()
        TKInvoice.get(id: invoiceId)
            .done { [weak self] invoice in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    let controller = CommonsWebViewViewController(url)
                    controller.navigationBar.rightButton.setImage(image: UIImage(named: "ic_more_primary")!)
                    controller.navigationBar.title = "Invoice"
                    controller.onNavigationBarRightButtonTapped = { [weak self] in
                        guard let self = self else { return }
                        var actions: [TKPopAction.Item] = [.init(title: "Share", action: {
                            controller.getInvoicePDF()
                        })]
                        if !self.isStudentView {
                            if invoice.status == .void {
                                actions.append(.init(title: "Remove", action: { [weak self] in
                                    guard let self = self else { return }
                                    self.removeVoidInvoice(invoiceId: invoice.id, in: controller)
                                }, tintColor: ColorUtil.red))
                            } else {
                                if (invoice.paidAmount + invoice.waivedAmount).compare(invoice.totalAmount) == .orderedAscending {
                                    actions += [
                                        .init(title: "Record payment", action: {
                                            self.onUnpaidInvoiceButtonTapped(withInvoice: invoice)
                                        }),
                                        .init(title: "Waive", action: {
                                            self.onWaiveInvoiceTapped(withInvoice: invoice)
                                        }),
                                    ]
                                }
                                if invoice.paidAmount == 0 {
                                    actions.append(.init(title: "Void", action: {
                                        self.voidInvoice(invoiceId: invoice.id)
                                    }, tintColor: ColorUtil.red))
                                }
                                if invoice.refundedAmount.compare(invoice.paidAmount) == .orderedAscending {
                                    actions.append(.init(title: "Refund", action: {
                                        self.refundInvoice(withInvoice: invoice)
                                    }, tintColor: ColorUtil.red))
                                }
                            }
                        }

                        TKPopAction.show(items: actions, target: controller)
                    }
                    controller.modalPresentationStyle = .fullScreen
                    controller.hero.isEnabled = true
                    controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                    self.present(controller, animated: true, completion: nil)
                }
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                logger.error("获取invoice失败: \(error)")
                self.hideFullScreenLoading()
            }
    }

    private func onInvoiceTapped(atIndex index: Int) {
        let invoice = unpaidInvoices[index]
        let suffix: String
        if isStudentView {
            suffix = "/student"
        } else {
            suffix = "/teacher"
        }
        guard let url = URL(string: "https://tunekey.app/balance/transaction/\(invoice.id)\(suffix)") else { return }
        let controller = CommonsWebViewViewController(url)
        controller.navigationBar.rightButton.setImage(image: UIImage(named: "ic_more_primary")!)
        controller.onNavigationBarRightButtonTapped = { [weak self] in
            guard let self = self else { return }
            var actions: [TKPopAction.Item] = [.init(title: "Share", action: {
                controller.getInvoicePDF()
            })]
            if !self.isStudentView {
                if invoice.status == .void {
                    actions.append(.init(title: "Remove", action: { [weak self] in
                        guard let self = self else { return }
                        self.removeVoidInvoice(invoiceId: invoice.id, in: controller)
                    }, tintColor: ColorUtil.red))
                } else {
                    if (invoice.paidAmount + invoice.waivedAmount).compare(invoice.totalAmount) == .orderedAscending {
                        actions += [
                            .init(title: "Record payment", action: {
                                self.onUnpaidInvoiceButtonTapped(atIndex: index)
                            }),
                            .init(title: "Waive", action: {
                                self.onWaiveInvoiceTapped(withInvoice: invoice)
                            }),
                        ]
                    }
                    if invoice.paidAmount == 0 {
                        actions.append(.init(title: "Void", action: {
                            self.voidInvoice(invoiceId: invoice.id)
                        }, tintColor: ColorUtil.red))
                    }
                    if invoice.refundedAmount.compare(invoice.paidAmount) == .orderedAscending {
                        actions.append(.init(title: "Refund", action: {
                            self.refundInvoice(withInvoice: invoice)
                        }, tintColor: ColorUtil.red))
                    }
                }
            }
            TKPopAction.show(items: actions, target: controller)
        }
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    private func onMoreTapped() {
        TKPopAction.show(items: [
            .init(title: "Auto payment", action: { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    let controller = StudentAutoPaymentViewController(self.student)
                    controller.enableHero()
                    self.present(controller, animated: true)
                }
            }),
//            .init(title: "Statement", action: {
//            }),
        ], target: self)
    }

    private func removeVoidInvoice(invoiceId: String, in controller: UIViewController) {
        SL.Alert.show(target: controller, title: "Remove?", message: "Are you sure remove this voided invoice right now?", leftButttonString: "Cancel", rightButtonString: "Remove", leftButtonColor: ColorUtil.main, rightButtonColor: ColorUtil.red) {
        } rightButtonAction: { [weak self] in
            guard let self = self else { return }
            controller.dismiss(animated: true) {
                self.showFullScreenLoadingNoAutoHide()
                Functions.functions().httpsCallable("invoiceService-removeVoidInvoice")
                    .call([
                        "invoiceId": invoiceId,
                    ]) { [weak self] result, error in
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                        if let error = error {
                            logger.error("调用失败: \(error)")
                            TKToast.show(msg: "Refund failed, please try again later.", style: .error)
                        } else {
                            if let result = result, let data = FuncResult.deserialize(from: result.data as? [String: Any]) {
                                if data.code == 200 {
                                    TKToast.show(msg: "Remove successfully", style: .success)
                                    EventBus.send(key: .manualInvoiceRemoveSuccessfully, object: invoiceId)
                                    self.unpaidInvoices.removeElements({ $0.id == invoiceId })
                                    self.transactions.removeElements({ $0.invoiceId == invoiceId })
                                    self.collectionView.reloadData()
                                    self.tableView.reloadData()
                                } else {
                                    TKToast.show(msg: "Unknow error, please try again later.", style: .error)
                                }
                            }
                        }
                    }
            }
        }
    }

    private func refundInvoice(withInvoice invoice: TKInvoice) {
        let controller = StudioBalanceRecordAmountViewController()
        controller.titleString = "Refund"
        controller.placeholder = "Amount"
        controller.keyboardType = .decimalPad
        controller.rightButtonString = "REFUND"
        controller.rightButtonStyle = .delete
        controller.onLeftButtonTapped = { _, _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] amountString, paymentMethod in
            guard let self = self else { return }
            let amount = NSDecimalNumber(string: amountString)
            guard amount.compare(0) == .orderedDescending else { return }
            logger.debug("写的钱数: \(amount)")
            controller.view.endEditing(true)
            controller.hide()
            self.callRefundInvoice(invoiceId: invoice.id, amount: amount, paymentMethod: paymentMethod)
        }
        controller.onTextChanged = { text, _, rightButton in
            if text != "" {
                let amount = NSDecimalNumber(string: text)
                if amount.compare(0) == .orderedDescending {
                    rightButton.enable()
                } else {
                    rightButton.disable()
                }
                let maxAmount = invoice.paidAmount
                if amount.compare(invoice.paidAmount) == .orderedDescending {
                    controller.textBox?.value(maxAmount.doubleValue.descWithCleanZero)
                    controller.text = maxAmount.doubleValue.descWithCleanZero
                }
            } else {
                rightButton.disable()
            }
        }
        if let topViewController = Tools.getTopViewController() {
            controller.pop(from: topViewController) {
                controller.textBox?.prefix(GlobalFields.currencySymbol)
                controller.rightButton?.disable()
            }
        }
    }

    private func callRefundInvoice(invoiceId: String, amount: Dollar, paymentMethod: TKTransaction.PaymentMethod) {
        guard let userId = UserService.user.id() else { return }
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller().name("invoiceService-refundForManualInvoice")
            .appendData(key: "invoiceId", value: invoiceId)
            .appendData(key: "amount", value: amount.doubleValue)
            .appendData(key: "recordorId", value: userId)
            .appendData(key: "paymentMethod", value: paymentMethod.rawValue)
            .call { [weak self] result, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("调用失败: \(error)")
                    TKToast.show(msg: "Refund failed, please try again later.", style: .error)
                } else {
                    if let result = result, let data = FuncResult.deserialize(from: result.data as? [String: Any]) {
                        if data.code == 200 {
                            TKToast.show(msg: "Refund successfully", style: .success)
                            EventBus.send(key: .manualInvoiceRefundSuccessfully, object: invoiceId)
                        } else {
                            TKToast.show(msg: "Unknow error, please try again later.", style: .error)
                        }
                    }
                }
            }
    }

    private func voidInvoice(invoiceId: String) {
        guard let userId = UserService.user.id() else { return }
        guard let topController = Tools.getTopViewController() else { return }

        SL.Alert.show(target: topController, title: "Void?", message: "Are you sure to avoid this invoice and permanently remove from student's account?", leftButttonString: "Cancel", rightButtonString: "Void", leftButtonColor: ColorUtil.main, rightButtonColor: ColorUtil.red) {
        } rightButtonAction: { [weak self] in
            guard let self = self else { return }
            self.showFullScreenLoadingNoAutoHide()
            Functions.functions().httpsCallable("invoiceService-voidForManualInvoice")
                .call([
                    "invoiceId": invoiceId,
                    "recordorId": userId,
                ]) { [weak self] result, error in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if let error = error {
                        logger.error("调用失败: \(error)")
                        TKToast.show(msg: "Void failed, please try again later.", style: .error)
                    } else {
                        if let result = result, let data = FuncResult.deserialize(from: result.data as? [String: Any]) {
                            if data.code == 200 {
                                TKToast.show(msg: "Void successfully", style: .success)
                                EventBus.send(key: .manualInvoiceVoidSuccessfully, object: invoiceId)
                            } else {
                                TKToast.show(msg: "Unknow error, please try again later.", style: .error)
                            }
                        }
                    }
                }
        }
    }

    private func onWaiveInvoiceTapped(withInvoice invoice: TKInvoice) {
        let controller = TextFieldPopupViewController()
        controller.titleString = "Waive"
        controller.placeholder = "Amount"
        controller.keyboardType = .decimalPad
        controller.titleAlignment = .center
        controller.rightButtonString = "WAIVE"
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] amountString in
            guard let self = self else { return }
            let amount = NSDecimalNumber(string: amountString)
            logger.debug("写的钱数: \(amount)")
            controller.view.endEditing(true)
            controller.hide()
            self.waiveInvoice(invoiceId: invoice.id, amount: amount)
        }
        controller.onTextChanged = { text, _, rightButton in
            if text != "" {
                let amount = NSDecimalNumber(string: text)
                if amount.compare(0) == .orderedDescending {
                    rightButton.enable()
                } else {
                    rightButton.disable()
                }
                let maxAmount = invoice.totalAmount - invoice.paidAmount - invoice.waivedAmount
                if amount.compare(maxAmount) == .orderedDescending {
                    controller.textBox?.value(maxAmount.doubleValue.descWithCleanZero)
                    controller.text = maxAmount.doubleValue.descWithCleanZero
                }
            } else {
                rightButton.disable()
            }
        }
        if let topViewController = Tools.getTopViewController() {
            controller.pop(from: topViewController) {
                controller.textBox?.prefix(GlobalFields.currencySymbol)
                controller.rightButton?.disable()
            }
        }
    }

    private func waiveInvoice(invoiceId: String, amount: Dollar) {
        guard let userId = UserService.user.id() else { return }
        showFullScreenLoadingNoAutoHide()
        Functions.functions().httpsCallable("invoiceService-waiveForManualInvoice")
            .call([
                "invoiceId": invoiceId,
                "amount": amount.doubleValue,
                "recordorId": userId,
            ]) { [weak self] result, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("调用失败: \(error)")
                    TKToast.show(msg: "Waive failed, please try again later.", style: .error)
                } else {
                    if let result = result, let data = FuncResult.deserialize(from: result.data as? [String: Any]) {
                        if data.code == 200 {
                            TKToast.show(msg: "Waive successfully", style: .success)
                            EventBus.send(key: .manualInvoiceWaiveSuccessfully, object: invoiceId)
                        } else {
                            TKToast.show(msg: "Unknow error, please try again later.", style: .error)
                        }
                    }
                }
            }
    }
}

extension StudentDetailsBalanceViewController {
    private func initListeners() {
        EventBus.listen(key: .manualInvoiceRefundSuccessfully, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.loadData()
        }

        EventBus.listen(key: .manualInvoiceWaiveSuccessfully, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.loadData()
        }
        EventBus.listen(key: .manualInvoiceVoidSuccessfully, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.loadData()
        }
        EventBus.listen(key: .manualInvoiceAddSuccessfully, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.loadUnpaidInvoices()
        }

        EventBus.listen(key: .dataVersionChanged, target: self) { [weak self] _ in
            updateUI {
                self?.loadData(withLoading: false)
            }
        }
    }
}
