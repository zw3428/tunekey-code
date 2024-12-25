//
//  StudentDetailsBalanceAddNewInvoiceViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/3/3.
//  Copyright © 2022 spelist. All rights reserved.
//

import FirebaseFirestore
import FirebaseFunctions
import SDWebImage
import SnapKit
import SwiftDate
import UIKit

class StudentDetailsBalanceAddNewInvoiceViewController: TKBaseViewController {
    private lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Invoice - \(self.student.name)", rightButton: "Preview") { [weak self] in
        self?.onPreviewTapped()
    }

    @Live var lessonTypeImage: UIImage = ImageUtil.getImage(color: ColorUtil.main)
    @Live var invoice: TKInvoice = TKInvoice() {
        didSet {
            if invoice.notes == "" {
                notes = "Optional"
            } else {
                let count = invoice.notes.components(separatedBy: "#tunekey#").filter({ $0.trimmingCharacters(in: .whitespacesAndNewlines) != "" }).count
                if count == 0 {
                    notes = "Optional"
                } else {
                    notes = "\(count)"
                }
            }
            if invoice.emailText == "" || invoice.emailText == "Optional" {
                emailTemplate = defaultEmailTemplate
            } else {
                emailTemplate = invoice.emailText
            }
        }
    }

    @Live var notes: String = "Optional"
    @Live var emailTemplate: String = "Optional"

    private var lessonScheduleConfigs: [TKLessonScheduleConfigure]?
    private var lessonConfigsContainerView: ViewBox?
    private var activeLessonScheduleConfigs: [TKLessonScheduleConfigure]? {
        didSet {
            if let lessonScheduleConfigs = lessonScheduleConfigs, let activeLessonScheduleConfigs = activeLessonScheduleConfigs, lessonScheduleConfigs.count == activeLessonScheduleConfigs.count {
                isLessonButtonHidden = true
            } else {
                isLessonButtonHidden = false
            }
        }
    }

    private var allLessonManualItem: [TKInvoice.ManualItem] = []
    private var activeLessonManualItem: [TKInvoice.ManualItem] = []

    private var isShowAllLessons: Bool = false {
        didSet {
            lessonButtonTitle = isShowAllLessons ? "See active only" : "See all lessons"
            refreshLessonConfigsContainerView()
        }
    }

    @Live private var lessonButtonTitle: String = "See all lessons"
    @Live private var isLessonButtonHidden: Bool = false

    private var lessonsQuantityLabels: [Label] = []

    private var adjustmentLabel: Label?

    private var discountLabel: Label?

    private var dueDateLabel: Label?
    
    private var defaultEmailTemplate: String = "Optional"

    var student: TKStudent
    init(_ student: TKStudent) {
        self.student = student
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isDataLoaded: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
}

extension StudentDetailsBalanceAddNewInvoiceViewController {
    private func loadData() {
        guard !isDataLoaded, let studio = ListenerService.shared.studioManagerData.studio else { return }
        isDataLoaded = true
        invoice.studentId = student.studentId
        invoice.teacherId = student.teacherId
        invoice.id = IDUtil.nextId(group: .lesson)?.description ?? ""
        invoice.num = 1
        invoice.type = .manual
        invoice.createTimestamp = Date().timeIntervalSince1970
        invoice.updateTimestamp = Date().timeIntervalSince1970
//        invoice.studioId = ListenerService.shared.teacherData.teacherInfo?.studioId ?? ""
        invoice.studioId = studio.id
        invoice.studioInfo = studio
        invoice.billToUserId = student.studentId
        invoice.billingTimestamp = DateInRegion(region: .localRegion).dateAtStartOf(.day).timeIntervalSince1970
        invoice.quickInvoiceDueDate = 7
        updateAmount()
        loadLessonScheduleConfigs()
//        loadStudioInfo()
        loadPaymentLinkAndEmailTemplate()
    }

    private func loadStudioInfo() {
        showFullScreenLoadingNoAutoHide()
        UserService.studio.getStudioInfo()
            .done { [weak self] studio in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                self.invoice.studioInfo = studio
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                logger.error("获取studio失败: \(error)")
            }
    }

    private func loadLessonScheduleConfigs() {
        guard let user = ListenerService.shared.user else { return }
        switch user.currentUserDataVersion {
        case .unknown(version: _):
            return
        case .singleTeacher:
            loadLessonScheduleConfigsV1()
        case .studio:
            loadLessonScheduleConfigsV2()
        }
    }

    private func loadLessonScheduleConfigsV1() {
        let lessonTypes = ListenerService.shared.teacherData.lessonTypes
        // 获取当前学生的所有课程
        LessonService.lessonScheduleConfigure.getStudentLessonConfigs(studentId: student.studentId, teacherId: student.teacherId)
            .done { [weak self] data in
                guard let self = self else { return }
                logger.debug("获取到的lessonScheduleConfig数量: \(data.count)")
                self.setupLessonScheduleConfigs(data: data, withLessonTypes: lessonTypes)
            }
            .catch { error in
                logger.error("获取lessonConfig失败: \(error)")
            }
    }

    private func loadLessonScheduleConfigsV2() {
        guard let studio = ListenerService.shared.studioManagerData.studio else {
            logger.error("无法获取studio信息")
            return
        }
        DatabaseService.collections.lessonScheduleConfigure()
            .whereField("studioId", isEqualTo: studio.id)
            .whereField("studentId", isEqualTo: student.studentId)
            .whereField("delete", isEqualTo: false)
            .getDocumentsData(TKLessonScheduleConfigure.self, source: .server) { [weak self] data, error in
                guard let self = self else { return }
                if let error {
                    logger.error("获取lesson config 失败: \(error)")
                } else {
                    self.setupLessonScheduleConfigs(data: data, withLessonTypes: ListenerService.shared.studioManagerData.lessonTypes)
                }
            }
//        LessonService.lessonScheduleConfigure.fetchConfigs(withStudioId: studio.id)
//            .done { [weak self] data in
//                guard let self = self else { return }
//                self.setupLessonScheduleConfigs(data: data, withLessonTypes: ListenerService.shared.studioManagerData.lessonTypes)
//            }
//            .catch { error in
//                logger.error("获取LessonScheduleConfig失败: \(error)")
//            }
    }

    private func setupLessonScheduleConfigs(data: [TKLessonScheduleConfigure], withLessonTypes lessonTypes: [TKLessonType]) {
        for (i, lessonScheduleConfig) in data.enumerated() {
            if let lessonType = lessonTypes.first(where: { $0.id == lessonScheduleConfig.lessonTypeId }) {
                data[i].lessonType = lessonType
            }
            lessonScheduleConfig.lessonEndDateAndCount = LessonUtil.getLessonEndDateAndCount(data: lessonScheduleConfig)
        }
        lessonScheduleConfigs = data
        invoice.manualItems = []
        activeLessonScheduleConfigs = []
        for item in data {
            var isThisItemActive: Bool = false
            var quantity: Int = 0
            // 判断当前课程是否已经结束
            if let lessonEndDateAndCount = item.lessonEndDateAndCount {
                switch lessonEndDateAndCount.type {
                case .none:
                    if lessonEndDateAndCount.count > 0 {
                        // 未结束
                        activeLessonScheduleConfigs?.append(item)
                        isThisItemActive = true
                        quantity = 4
                    } else {
                        quantity = 0
                    }
                case .unlimited:
                    quantity = 4
                    activeLessonScheduleConfigs?.append(item)
                    isThisItemActive = true
                case .noLoop:
                    if lessonEndDateAndCount.daysRemaining > 0 {
                        quantity = 4
                        activeLessonScheduleConfigs?.append(item)
                        isThisItemActive = true
                    } else {
                        quantity = 0
                    }
                }
            }

            let price: NSDecimalNumber
            if item.specialPrice >= 0 {
                price = NSDecimalNumber(value: item.specialPrice)
            } else {
                price = item.lessonType?.price ?? 0
            }

            let manualItem = TKInvoice.ManualItem(lessonConfigId: item.id, description: item.lessonType?.name ?? "", quantity: quantity, price: price, amount: price.multiplying(by: NSDecimalNumber(value: quantity)))
            allLessonManualItem.append(manualItem)
            if isThisItemActive {
                activeLessonManualItem.append(manualItem)
            }
        }

        // 判断是否都已经结束,如果都已经结束,就全部设置成1
        if allLessonManualItem.filter({ $0.quantity == 0 }).count == allLessonManualItem.count {
            // 都已经结束
            allLessonManualItem.forEachItems { _, i in
                self.allLessonManualItem[i].quantity = 1
            }
        }
        if activeLessonScheduleConfigs?.isEmpty ?? false {
            isShowAllLessons = true
        }
        refreshLessonConfigsContainerView()
    }

    private func loadPaymentLinkAndEmailTemplate() {
        guard let teacherId = UserService.user.id() else { return }
        logger.debug("获取最后一份invoice => 开始")
        DatabaseService.collections.invoice()
            .whereField("type", isEqualTo: TKInvoice.InvoiceType.manual.rawValue)
            .whereField("teacherId", isEqualTo: teacherId)
            .order(by: "createTimestamp", descending: true)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    logger.error("获取最后一份invoice => 获取上一份invoice失败: \(error)")
                } else {
                    if let doc = snapshot?.documents.first, let invoice = TKInvoice.deserialize(from: doc.data()) {
                        self.invoice.emailText = invoice.emailText
                        self.emailTemplate = invoice.emailText
                        if self.emailTemplate.isEmpty || self.emailTemplate == "Optional" {
                            self.emailTemplate = self.defaultEmailTemplate
                        }
                        self.invoice.notes = invoice.notes
                        let count = invoice.notes.components(separatedBy: "#tunekey#").filter({ $0.trimmingCharacters(in: .whitespacesAndNewlines) != "" }).count
                        if count == 0 {
                            self.notes = "Optional"
                        } else {
                            self.notes = "\(count)"
                        }
                        logger.debug("获取最后一份invoice => 完成: \(self.notes)")
                    } else {
                        logger.debug("获取最后一份invoice => 未找到上一份invoice")
                    }
                }
            }
    }

    private func updateAmount() {
        var amount: Dollar = 0
        var subtotalAmount: Dollar = 0
        var totalAmount: Dollar = 0
        if isShowAllLessons {
            for (i, item) in allLessonManualItem.enumerated() {
                amount = amount.adding(item.price.multiplying(by: NSDecimalNumber(value: item.quantity)))
//                amount += (item.price * Decimal(item.quantity))
//                allLessonManualItem[i].amount = Decimal(item.quantity) * item.price
                allLessonManualItem[i].amount = NSDecimalNumber(value: item.quantity).multiplying(by: item.price)
            }
        } else {
            for (i, item) in activeLessonManualItem.enumerated() {
//                amount += (item.price * Decimal(item.quantity))
                amount = amount.adding(item.price.multiplying(by: NSDecimalNumber(value: item.quantity)))
//                activeLessonManualItem[i].amount = Decimal(item.quantity) * item.price
                activeLessonManualItem[i].amount = NSDecimalNumber(value: item.quantity).multiplying(by: item.price)
            }
        }
        subtotalAmount = amount
        totalAmount = subtotalAmount
        if let adjustment = invoice.otherFees.first {
            totalAmount = adjustment.amount.adding(totalAmount)
        }
        totalAmount = totalAmount.subtracting(invoice.discount)
        invoice.subtotalAmount = subtotalAmount
        invoice.totalAmount = totalAmount
        invoice.amount = amount
        invoice.quantity = 1
        invoice.price = amount
        if isShowAllLessons {
            invoice.manualItems = allLessonManualItem
        } else {
            invoice.manualItems = activeLessonManualItem
        }
        logger.debug("更新amount之后的invoice数据: \(invoice.toJSONString(prettyPrint: true) ?? "")")
        let billingDate = Date(seconds: invoice.billingTimestamp)
        let dueDate = billingDate.add(component: .day, value: invoice.quickInvoiceDueDate)
        _ = dueDateLabel?.text(dueDate.toLocalFormat("MM/dd/yyyy"))
    }
}

extension StudentDetailsBalanceAddNewInvoiceViewController {
    override func initView() {
        super.initView()
        enablePanToDismiss()
        navigationBar.updateLayout(target: self)
        navigationBar.hiddenRightButton()

        ViewBox(paddings: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)) {
            VScrollStack {
                // lesson & quantity view
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)) {
                    ViewBox(paddings: .zero) {
                        VStack {
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
                                HStack {
                                    Label("Quantity")
                                        .textColor(ColorUtil.Font.fourth)
                                        .font(FontUtil.regular(size: 13))
                                        .contentCompressionResistancePriority(.defaultLow, for: .horizontal)
                                    Spacer(spacing: 20)
                                    Button()
                                        .title($lessonButtonTitle, for: .normal)
                                        .font(FontUtil.bold(size: 13))
                                        .titleColor(ColorUtil.main, for: .normal)
                                        .isHidden($isLessonButtonHidden)
                                        .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                                        .onTapped { [weak self] _ in
                                            self?.isShowAllLessons.toggle()
                                        }
                                }
                            }
                            .size(width: nil, height: 35)
                            ViewBox(paddings: .zero) {
                                ViewBox(paddings: .init(top: 10, left: 0, bottom: 10, right: 0)) {
                                    LoadingView(CGSize(width: 30, height: 30))
                                }
                            }.bind(&lessonConfigsContainerView)
                        }
                    }
                    .backgroundColor(.white)
                    .showBorder()
                    .showShadow()
                    .corner(size: 5)
                }
                Spacer(spacing: 20)
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)) {
                    ViewBox(paddings: .zero) {
                        VStack {
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
                                Label("Adjustment & discount")
                                    .textColor(ColorUtil.Font.fourth)
                                    .font(FontUtil.regular(size: 13))
                                    .size(height: 15)
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                                VStack {
                                    HStack {
                                        Label("Adjustment")
                                            .font(FontUtil.bold(size: 18))
                                            .textColor(ColorUtil.Font.third)
                                        Label("Optional")
                                            .textColor(ColorUtil.Font.fourth)
                                            .font(FontUtil.regular(size: 13))
                                            .textAlignment(.right)
                                            .apply { [weak self] label in
                                                self?.adjustmentLabel = label
                                            }
                                        ImageView(image: UIImage(named: "arrowRight")?.sd_resizedImage(with: CGSize(width: 22, height: 22), scaleMode: .fill))
                                            .size(width: 22)
                                    }
                                    Spacer(spacing: 10)
                                    Label("Previous balance, tax & other fee")
                                        .font(FontUtil.regular(size: 13))
                                        .textColor(ColorUtil.Font.fourth)
                                        .size(height: 15)
                                }.onViewTapped { [weak self] _ in
                                    self?.onAdjusmentTapped()
                                }
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)) {
                                Divider(weight: 1, color: ColorUtil.dividingLine)
                                    .size(height: 1)
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                                HStack {
                                    Label("Discount")
                                        .textColor(ColorUtil.Font.third)
                                        .font(FontUtil.bold(size: 18))
                                    Label("Optional")
                                        .textColor(ColorUtil.Font.fourth)
                                        .font(FontUtil.regular(size: 13))
                                        .textAlignment(.right)
                                        .apply { [weak self] label in
                                            self?.discountLabel = label
                                        }
                                    ImageView(image: UIImage(named: "arrowRight")?.sd_resizedImage(with: CGSize(width: 22, height: 22), scaleMode: .fill))
                                        .size(width: 22)
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                self?.onDiscountTapped()
                            }
                        }
                    }
                    .backgroundColor(.white)
                    .showBorder()
                    .showShadow()
                    .corner(size: 5)
                }
                Spacer(spacing: 20)
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)) {
                    ViewBox(paddings: .zero) {
                        VStack {
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
                                Label("Payment link & email")
                                    .textColor(ColorUtil.Font.fourth)
                                    .font(FontUtil.regular(size: 13))
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                                VStack(spacing: 10) {
                                    HStack {
                                        //                                    Label("Notes on Invoice")
                                        Label("Payment link")
                                            .font(FontUtil.bold(size: 18))
                                            .textColor(ColorUtil.Font.third)
                                        Label($notes)
                                            .textColor(ColorUtil.Font.fourth)
                                            .font(FontUtil.regular(size: 13))
                                            .textAlignment(.right)
                                            .numberOfLines(2)
                                            .size(width: 120)
                                        ImageView(image: UIImage(named: "arrowRight")?.sd_resizedImage(with: CGSize(width: 22, height: 22), scaleMode: .fill))
                                            .contentMode(.center)
                                            .size(width: 22)
                                    }
                                    Label("PayPal, Venmo, Stripe, ...")
                                        .textColor(ColorUtil.Font.primary)
                                        .font(FontUtil.regular(size: 13))
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                self?.onNotesTapped()
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)) {
                                Divider(weight: 1, color: ColorUtil.dividingLine)
                                    .size(height: 1)
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                                HStack {
                                    Label("Email Template")
                                        .textColor(ColorUtil.Font.third)
                                        .font(FontUtil.bold(size: 18))
                                    Label($emailTemplate)
                                        .textColor(ColorUtil.Font.fourth)
                                        .font(FontUtil.regular(size: 13))
                                        .textAlignment(.right)
                                        .numberOfLines(0)
                                        .size(width: 120)
                                    ImageView(image: UIImage(named: "arrowRight")?.sd_resizedImage(with: CGSize(width: 22, height: 22), scaleMode: .fill))
                                        .contentMode(.center)
                                        .size(width: 22)
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                self?.onEmailTemplateCellTapped()
                            }
                        }
                    }
                    .backgroundColor(.white)
                    .showBorder()
                    .showShadow()
                    .corner(size: 5)
                }
                Spacer(spacing: 20)
                ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)) {
                    ViewBox(paddings: .zero) {
                        VStack {
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)) {
                                Label("Due date")
                                    .textColor(ColorUtil.Font.fourth)
                                    .font(FontUtil.regular(size: 13))
                                    .size(height: 15)
                            }
                            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                                HStack {
                                    Label("Due date")
                                        .font(FontUtil.bold(size: 18))
                                        .textColor(ColorUtil.Font.third)
                                    Label()
                                        .textColor(ColorUtil.Font.fourth)
                                        .font(FontUtil.regular(size: 13))
                                        .textAlignment(.right)
                                        .numberOfLines(0)
                                        .size(width: 120)
                                        .apply { [weak self] label in
                                            guard let self = self else { return }
                                            self.dueDateLabel = label
                                        }
                                    ImageView(image: UIImage(named: "arrowRight")?.sd_resizedImage(with: CGSize(width: 22, height: 22), scaleMode: .fill))
                                        .contentMode(.center)
                                }
                            }.onViewTapped { [weak self] _ in
                                self?.onDueDateTapped()
                            }
                        }
                    }
                    .backgroundColor(.white)
                    .showBorder()
                    .showShadow()
                    .corner(size: 5)
                }
                ViewBox(paddings: UIEdgeInsets(top: 40, left: 20, bottom: 20, right: 20)) {
                    HStack(spacing: 20) {
                        BlockButton()
                            .set(title: "PREVIEW", style: .cancel)
                            .size(width: (UIScreen.main.bounds.width - 60) * 0.375, height: 50)
                            .onTapped { [weak self] _ in
                                self?.onPreviewTapped()
                            }
                        BlockButton()
                            .set(title: "CREATE & SEND", style: .normal)
                            .size(height: 50)
                            .onTapped { [weak self] _ in
                                self?.onSendNowButtonTapped()
                            }
                    }
                }
            }
        }
        .addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

extension StudentDetailsBalanceAddNewInvoiceViewController {
    private func getManualItemInfoLabel(lessonScheduleConfig: TKLessonScheduleConfigure) -> String {
        guard let lessonType = lessonScheduleConfig.lessonType else { return "" }
        let price: Double
        if lessonScheduleConfig.specialPrice >= 0 {
            price = lessonScheduleConfig.specialPrice
        } else {
            price = Double(truncating: lessonType.price)
        }
        var string = "\(lessonType.timeLength) minutes, $\(price.roundTo(places: 2)) / lesson,\n\(Date(seconds: lessonScheduleConfig.startDateTime).toLocalFormat("h:mm a"))"
        switch lessonScheduleConfig.repeatType {
        case .none:
            string += " \(Date(seconds: lessonScheduleConfig.startDateTime).toLocalFormat("M/d/yyyy"))"
            break
        case .weekly, .biWeekly:
            if lessonScheduleConfig.repeatTypeWeekDay.sorted(by: { $0 < $1 }) == [1, 2, 3, 4, 5] {
                string += ", every weekday"
            } else if lessonScheduleConfig.repeatTypeWeekDay.sorted(by: { $0 < $1 }) == [6, 7] {
                string += ", every weekend"
            } else {
                var days: [String] = []
                for weekday in lessonScheduleConfig.repeatTypeWeekDay.sorted(by: { $0 < $1 }) {
                    switch weekday {
                    case 0:
                        days.append("Sunday")
                    case 1:
                        days.append("Monday")
                    case 2:
                        days.append("Tuesday")
                    case 3:
                        days.append("Wednesday")
                    case 4:
                        days.append("Thursday")
                    case 5:
                        days.append("Friday")
                    case 6:
                        days.append("Saturday")
                    default:
                        break
                    }
                }
                string += ", every \(days.joined(separator: "/"))"
            }
            break
        case .monthly:
            break
        }
        return string
    }

    private func refreshLessonConfigsContainerView() {
        let lessonConfigs: [TKLessonScheduleConfigure]
        let manualItems: [TKInvoice.ManualItem]
        if isShowAllLessons {
            lessonConfigs = lessonScheduleConfigs ?? []
            manualItems = allLessonManualItem
        } else {
            lessonConfigs = activeLessonScheduleConfigs ?? []
            manualItems = activeLessonManualItem
        }
        updateAmount()
        lessonsQuantityLabels = []
        logger.debug("刷新lesson数据视图, lesson config数量: \(lessonConfigs.count)")
        if !lessonConfigs.isEmpty {
            lessonConfigsContainerView?.rebuild(paddings: .zero) {
                VStack {
                    for (i, manualItem) in manualItems.enumerated() {
                        ViewBox(paddings: UIEdgeInsets(top: 17, left: 0, bottom: 13, right: 0)) {
                            HStack {
                                Spacer(spacing: 20)
                                ViewBox(paddings: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)) {
                                    VStack {
                                        ImageView()
                                            .image($lessonTypeImage)
                                            .cornerRadius(12)
                                            .masksToBounds(true)
                                            .size(width: 24, height: 24)
                                            .apply { imageView in
                                                if let lessonType = lessonConfigs.first(where: { manualItem.lessonConfigId == $0.id })?.lessonType, let instrument = ListenerService.shared.instrumentsMap[lessonType.instrumentId] {
                                                    logger.debug("加载乐器图片: \(instrument.minPictureUrl)")
                                                    imageView.sd_setImage(with: URL(string: instrument.minPictureUrl), completed: nil)
                                                }
                                            }
                                        Spacer(spacing: 40)
                                    }
                                }.size(width: 24)
                                Spacer(spacing: 20)
                                VStack {
                                    Label(lessonConfigs.first(where: { $0.id == manualItem.lessonConfigId })!.lessonType?.name ?? "")
                                        .textColor(ColorUtil.Font.third)
                                        .font(FontUtil.bold(size: 18))
                                        .size(height: 22)
                                    Spacer(spacing: 3.5)
                                    Label(getManualItemInfoLabel(lessonScheduleConfig: lessonConfigs.first(where: { $0.id == manualItem.lessonConfigId })!))
                                        .textColor(ColorUtil.Font.fourth)
                                        .font(FontUtil.regular(size: 13))
                                        .numberOfLines(0)
                                }
                                ViewBox(paddings: UIEdgeInsets(top: 0, left: 0, bottom: 42, right: 0)) {
                                    ViewBox(paddings: .zero) {
                                        HStack {
                                            Label("X \(manualItem.quantity.description)")
                                                .textColor(ColorUtil.Font.primary)
                                                .font(FontUtil.medium(size: 13))
                                                .textAlignment(.right)
                                                .tag(i)
                                                .apply { label in
                                                    self.lessonsQuantityLabels.append(label)
                                                }
                                                .onViewTapped { [weak self] _ in
                                                    self?.onQuantityTapped(at: i)
                                                }
                                            ImageView()
                                                .image(UIImage(named: "arrowRight"))
                                                .size(width: 22, height: 22)
                                        }
                                    }
                                    .size(height: 22)
                                }
                                Spacer(spacing: 20)
                            }
                        }
                        if i != manualItems.count - 1 {
                            ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)) {
                                Divider(weight: 1, color: ColorUtil.dividingLine)
                                    .size(height: 1)
                            }
                        }
                    }
                }
            }
        } else {
            lessonConfigsContainerView?.rebuild(paddings: .zero) {
                ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
                    Label("There's no lesson yet")
                        .font(FontUtil.regular(size: 15))
                        .textColor(ColorUtil.Font.primary)
                        .textAlignment(.center)
                }
            }
        }
    }
}

extension StudentDetailsBalanceAddNewInvoiceViewController {
    override func bindEvent() {
        super.bindEvent()
    }

    private func onSendNowButtonTapped() {
        showFullScreenLoadingNoAutoHide()
        logger.debug("点击按钮")
        if isShowAllLessons {
            invoice.manualItems = allLessonManualItem
        } else {
            invoice.manualItems = activeLessonManualItem
        }
        Functions.functions().httpsCallable("invoiceService-createManualInvoice")
            .call(invoice.toJSON() ?? [:]) { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("创建invoice出错: \(error)")
                    TKToast.show(msg: "Send invoice failed, please try again later.", style: .error)
                } else {
                    EventBus.send(key: .manualInvoiceAddSuccessfully)
                    self.dismiss(animated: true) {
                        TKToast.show(msg: "Send invoice successfully.", style: .success)
                    }
                }
            }
    }

    private func onEmailTemplateCellTapped() {
        if isShowAllLessons {
            invoice.manualItems = allLessonManualItem
        } else {
            invoice.manualItems = activeLessonManualItem
        }
        if emailTemplate == "Optional" {
            invoice.emailText = ""
        } else {
            invoice.emailText = emailTemplate
        }
        logger.debug("准备唤起emailTemplate,当前email: \(invoice.emailText)")
        let controller = StudentDetailsBalanceEmailTemplateSettingViewController(invoice: invoice, student: student)
        controller.isDeleteButtonHidden = true
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
        controller.onDeleteTapped = { [weak self] in
            guard let self = self else { return }
            self.invoice.emailText = ""
            self.emailTemplate = "Optional"
            controller.dismiss(animated: true, completion: nil)
        }
        controller.onSaveTapped = { [weak self] text in
            guard let self = self else { return }
            self.invoice.emailText = text
            if text == "" {
                self.emailTemplate = "Optional"
            } else {
                self.emailTemplate = text
            }
            controller.dismiss(animated: true, completion: nil)
        }
    }

    private func onQuantityTapped(at index: Int) {
        let manualItem: TKInvoice.ManualItem
        if isShowAllLessons {
            manualItem = allLessonManualItem[index]
        } else {
            manualItem = activeLessonManualItem[index]
        }
        let controller = StudentDetailsBalanceAddNewQuantityUpdateViewController()
        controller.quantity = manualItem.quantity
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
        controller.onCancelTapped = {
            controller.hide()
        }
        controller.onConfirmTapped = { [weak self] quantity in
            guard let self = self else { return }
            controller.hide()
            if self.isShowAllLessons {
                self.allLessonManualItem[index].quantity = quantity
            } else {
                self.activeLessonManualItem[index].quantity = quantity
            }
            self.lessonsQuantityLabels[index].text = "X \(quantity.description)"
            self.updateAmount()
        }
    }

    private func onAdjusmentTapped() {
        var value: Double = 0
        if let adjustment = invoice.otherFees.first {
            value = adjustment.amount.doubleValue
        }
        let controller = StudentDetailsBalanceAmountPopupViewController()
        controller.value = value
        controller.titleString = "Adjustment"
        controller.onCancelTapped = {
            controller.hide()
        }

        controller.onConfirmTapped = { [weak self] value in
            guard let self = self else { return }
            controller.hide()
            if value > 0 {
                if self.invoice.otherFees.count == 0 {
                    self.invoice.otherFees.append(TKAmount(title: "Adjustment", amount: NSDecimalNumber(value: value), amountType: .flat))
                } else {
                    self.invoice.otherFees[0].amount = NSDecimalNumber(value: value)
                }
                self.adjustmentLabel?.text = "$\(value.descWithCleanZero)"
            } else {
                self.adjustmentLabel?.text = "Optional"
                self.invoice.otherFees = []
            }
            self.updateAmount()
        }
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

    private func onDiscountTapped() {
        let controller = StudentDetailsBalanceAmountPopupViewController()
        controller.value = invoice.discount.doubleValue
        controller.titleString = "Discount"
        controller.onCancelTapped = {
            controller.hide()
        }

        controller.onConfirmTapped = { [weak self] value in
            guard let self = self else { return }
            controller.hide()
            if value > 0 {
                self.discountLabel?.text = "$\(value.descWithCleanZero)"
                self.invoice.discount = NSDecimalNumber(value: value)
            } else {
                self.discountLabel?.text = "Optional"
                self.invoice.discount = 0
            }
            self.updateAmount()
        }
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }

    private func onDueDateTapped() {
//        let controller = StudentDetailsBalanceDueDateUpdateViewController()
//        controller.day = invoice.quickInvoiceDueDate
//        controller.modalPresentationStyle = .custom
//        controller.onCancelTapped = {
//            controller.hide()
//        }
//        controller.onConfirmTapped = { [weak self] day in
//            guard let self = self else { return }
//            controller.hide()
//            self.dueDateLabel?.text = "\(day) day\(day > 1 ? "s" : "") after invoice day"
//            self.invoice.quickInvoiceDueDate = day
//        }
//        present(controller, animated: false, completion: nil)
//        let billingDate = Date(seconds: invoice.billingTimestamp)
        let billingDate = DateInRegion(seconds: invoice.billingTimestamp, region: .localRegion)
        logger.debug("billing的时间: \(billingDate.toLocalFormat("yyyy-MM-dd HH:mm:ss"))")
//        let defaultDate = billingDate.add(component: .day, value: invoice.quickInvoiceDueDate)
        let defaultDate = billingDate.dateByAdding(invoice.quickInvoiceDueDate, .day)
        TKDatePicker.show(startDate: billingDate.date, oldDate: defaultDate.date) { [weak self] date in
            guard let self = self, let newDate = DateInRegion("\(date.year)-\(date.month)-\(date.day) 00:00:00", format: "yyyy-MM-dd HH:mm:ss", region: .localRegion) else { return }
            logger.debug("选择的时间: \(newDate.toLocalFormat("yyyy-MM-dd"))")
            let components = billingDate.getInterval(toDate: newDate, component: .day)
//            let period = Calendar.current.dateComponents([.day], from: billingDate, to: newDate)
//            guard let days = period.day else { return }
            let days = Int(components)
            self.invoice.quickInvoiceDueDate = days
            logger.debug("due date: \(days)")
            self.dueDateLabel?.text = "\(newDate.toLocalFormat("MM/dd/yyyy"))"
        }
    }

    private func onNotesTapped() {
//        let controller = LessonDetailAddNewContentViewController()
//        controller.titleString = "Invoice Notes"
//        controller.titleAlignment = .center
//        controller.rightButtonString = "SAVE"
//        controller.text = invoice.notes
//        controller.modalPresentationStyle = .custom
//        present(controller, animated: false, completion: nil)
//        controller.onLeftButtonTapped = { _ in
//            controller.hide()
//        }
//        controller.onRightButtonTapped = { [weak self] text in
//            guard let self = self else { return }
//            self.invoice.notes = text
//            controller.hide()
//        }

//        let controller = TextFieldPopupViewController()
        let controller = StudioDetailsBalanceAddNewInvoicePaymentLinksViewController()
        controller.titleString = "Payment link"
        controller.placeholder1 = "Payment link 1 (Optional)"
        controller.placeholder2 = "Payment link 2 (Optional)"
        controller.placeholder3 = "Payment link 3 (Optional)"
        controller.titleAlignment = .center
        controller.rightButtonString = "CONFIRM"
        controller.keyboardType = .URL
        var links = invoice.notes.components(separatedBy: "#tunekey#").compactMap({ String($0) }).filter({ $0 != "" })
        if links.count < 3 {
            for _ in links.count ..< 3 {
                links.append("")
            }
        }
        logger.debug("已经输入的links: \(links)")
        controller.texts = links

        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }

        controller.onRightButtonTapped = { [weak self] urls in
            guard let self = self else { return }
            self.invoice.notes = urls.filter({ $0.trimmingCharacters(in: .whitespacesAndNewlines) != "" }).compactMap({ "\($0)#tunekey#" }).joined(separator: "")
            logger.debug("已经设置的links: \(self.invoice.notes)")
            if urls.filter({ $0 != "" && $0.trimmingCharacters(in: .whitespacesAndNewlines) != "" }).isEmpty {
                self.notes = "Optional"
            } else {
                self.notes = urls.filter({ $0.trimmingCharacters(in: .whitespacesAndNewlines) != "" }).count.description
            }
            controller.hide()
        }
        controller.modalPresentationStyle = .custom
        present(controller, animated: true)
    }

    private func onPreviewTapped() {
//        guard let teacher = ListenerService.shared.teacherData.teacherInfo else { return }
        guard let teacher = ListenerService.shared.studioManagerData.teacherInfo else { return }
        showFullScreenLoadingNoAutoHide()
        akasync { [weak self] in
            guard let self = self else { return }
            let studio = try akawait(UserService.studio.getStudioInfo())
            DispatchQueue.main.async {
                self.hideFullScreenLoading()
                self.invoice.studioInfo = studio
                self.invoice.teacherInfo = teacher
                self.invoice.studentInfo = self.student
                let controller = StudentDetailsBalanceInvoicePreviewViewController(invoice: self.invoice, studio: studio, teacher: teacher)
                controller.enableHero()
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
}
