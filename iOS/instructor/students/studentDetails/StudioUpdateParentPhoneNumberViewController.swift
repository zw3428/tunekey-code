//
//  StudioUpdateParentPhoneNumberViewController.swift
//  TuneKey
//
//  Created by 砚枫张 on 2023/5/26.
//  Copyright © 2023 spelist. All rights reserved.
//

import IQKeyboardManagerSwift
import SnapKit
import UIKit

class StudioUpdateParentPhoneNumberViewController: TKBaseViewController {
    private var contentView: ViewBox?
    private var phoneNumberTextBox: TKTextBox?

    lazy var countryForPhoneNumberTextField: UITextField = {
        let countryTextField = UITextField()
        countryTextField.textAlignment = .center
        countryTextField.borderStyle = .none
        countryTextField.tintColor = ColorUtil.main
        countryTextField.font = .bold(20)
        countryTextField.textColor = ColorUtil.Font.second
        countryTextField.keyboardType = .numberPad
        countryTextField.text = phoneNumber.country
        countryTextField.delegate = self
        countryTextField.addTarget(self, action: #selector(textFieldDidChangeText(_:)), for: .editingChanged)
        return countryTextField
    }()

    lazy var countryForPhoneNumberTextBox: TKView = {
        let view = TKView.create()
            .backgroundColor(color: .white)
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
        countryForPhoneNumberTextField.addTo(superView: view) { make in
            make.top.bottom.left.right.equalToSuperview()
        }
        return view
    }()

    private var suggestionKey: String = ""
    private var suggestionData: [TKPhoneNumberPrefix] = [] {
        didSet {
            if suggestionData.count == 0 {
                IQKeyboardManager.shared.shouldResignOnTouchOutside = true
                suggestionTableView.isHidden = true
            } else {
                IQKeyboardManager.shared.shouldResignOnTouchOutside = false
                suggestionTableView.isHidden = false
                suggestionTableView.reloadData()
                var height: CGFloat = CGFloat(suggestionData.count) * 50
                if height >= 150 {
                    height = 150
                }
                suggestionTableView.snp.remakeConstraints { make in
                    make.top.equalTo(countryForPhoneNumberTextBox.snp.bottom)
                    make.left.equalTo(countryForPhoneNumberTextBox.snp.left)
                    make.width.equalTo(200)
                    make.height.equalTo(height)
                }
            }
        }
    }

    private lazy var suggestionTableView: UITableView = makeSuggestionTableView()

    var onConfirmButtonTapped: ((TKPhoneNumber) -> Void)?

    @Live private var isConfirmButtonEnabled: Bool = false

    private var phoneNumberString: String = "" {
        didSet {
            logger.debug("更改phoneNumber: \(phoneNumberString)")
        }
    }
    private var country: String = "" {
        didSet {
            logger.debug("更改country: \(country)")
        }
    }

    var phoneNumber: TKPhoneNumber
    init(_ phoneNumber: TKPhoneNumber) {
        self.phoneNumber = phoneNumber
        super.init(nibName: nil, bundle: nil)
        country = phoneNumber.country
        phoneNumberString = phoneNumber.phoneNumber
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        logger.debug("销毁 => \(Self.describing)")
    }

    private var isShow: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
}

extension StudioUpdateParentPhoneNumberViewController {
    override func initView() {
        super.initView()
        contentView = ViewBox(top: 20, left: 20, bottom: 20 + UiUtil.safeAreaBottom(), right: 20) {
            VStack(spacing: 20) {
                Label("Update parent phone number").textColor(.tertiary)
                    .font(.cardTitle)
                HStack(alignment: .center, spacing: 10) {
                    ViewBox {
                        countryForPhoneNumberTextBox
                    }
                    .size(width: 80, height: 64)
                    TextBox().value(phoneNumber.phoneNumber)
                        .placeholder("Phone number")
                        .height(64)
                        .onTyped { [weak self] value in
                            guard let self = self else { return }
                            self.phoneNumberString = value.lowercased().trimmed
                            self.isConfirmButtonEnabled = !self.phoneNumberString.isEmpty && !self.country.isEmpty
                        }
                        .apply { [weak self] _, textBox in
                            guard let self = self else { return }
                            textBox.isShadowShow(false)
                                .keyboardType(.phonePad)
                            self.phoneNumberTextBox = textBox
                        }
                }

                HStack(distribution: .fillEqually, spacing: 10) {
                    BlockButton(title: "CANCEL", style: .cancel)
                        .height(50)
                        .onTapped { [weak self] _ in
                            guard let self = self else { return }
                            self.hide()
                        }

                    BlockButton(title: "CONFIRM", style: .normal)
                        .height(50)
                        .onTapped { [weak self] _ in
                            guard let self = self else { return }
                            logger.debug("点击confirm: \(self.phoneNumberString) | \(self.country)")
                            guard !self.phoneNumberString.isEmpty, !self.country.isEmpty else { return }
                            self.hide {
                                self.onConfirmButtonTapped?(TKPhoneNumber(country: self.country, phoneNumber: self.phoneNumberString))
                            }
                        }
                }
            }
        }
        .backgroundColor(.white)
        .cornerRadius(15)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        .addTo(superView: view) { make in
            make.left.right.bottom.equalToSuperview()
        }
        contentView?.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        suggestionTableView.addTo(superView: view) { _ in
        }
    }
}

extension StudioUpdateParentPhoneNumberViewController {
    private func show() {
        guard !isShow else { return }
        isShow = true
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView?.transform = .identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.phoneNumberTextBox?.selectAll()
        }
    }

    private func hide(_ closure: VoidFunc? = nil) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView?.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: false) {
                closure?()
            }
        }
    }
}

extension StudioUpdateParentPhoneNumberViewController {
    private func makeSuggestionTableView() -> UITableView {
        let tableView = UITableView()
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = ColorUtil.dividingLine
        tableView.register(StudioBillingSettingUpdatePhoneNumberPopWindowViewController.SuggestionTableViewCell.self, forCellReuseIdentifier: StudioBillingSettingUpdatePhoneNumberPopWindowViewController.SuggestionTableViewCell.id)
        tableView.allowsSelection = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 50
        tableView.borderColor = ColorUtil.borderColor
        tableView.borderWidth = 1
        tableView.cornerRadius = 5
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        tableView.setShadows()
        return tableView
    }
}

extension StudioUpdateParentPhoneNumberViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.debug("点击了区号选择")
        let text = suggestionData[indexPath.row]
        logger.debug("选择了区号: \(text)")
        countryForPhoneNumberTextField.text = text.prefix
        country = text.prefix
        suggestionData.removeAll()
        tableView.reloadData()
        tableView.isHidden = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        phoneNumberTextBox?.focus()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suggestionData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: StudioBillingSettingUpdatePhoneNumberPopWindowViewController.SuggestionTableViewCell.id, for: indexPath) as! StudioBillingSettingUpdatePhoneNumberPopWindowViewController.SuggestionTableViewCell
        let prefix = suggestionData[indexPath.row]
        let text = "\(prefix.prefix) \(prefix.name)"
        cell.titleLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: suggestionKey, allColor: ColorUtil.Font.second, selectedColor: ColorUtil.main, font: .medium(size: 15), fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
        cell.selectionStyle = .none
        cell.contentView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            let text = self.suggestionData[indexPath.row]
            logger.debug("选择了区号: \(text)")
            self.countryForPhoneNumberTextField.text = text.prefix
            self.country = text.prefix
            self.suggestionData.removeAll()
            tableView.reloadData()
            tableView.isHidden = true
            IQKeyboardManager.shared.shouldResignOnTouchOutside = true
            self.phoneNumberTextBox?.focus()
        }
        return cell
    }
}

extension StudioUpdateParentPhoneNumberViewController: UITextFieldDelegate {
    @objc func textFieldDidChangeText(_ sender: UITextField) {
        var text = sender.text!
        if !text.contains("+") {
            text = "+\(text)"
        }
        logger.debug("输入的文字: \(text)")
        sender.text = text
        suggestionKey = text
        suggestionData = GlobalFields.phoneNumberPrefix.filter({ $0.prefix.lowercased().contains(text.lowercased()) })
        country = text
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        countryForPhoneNumberTextBox.borderColor = ColorUtil.main
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        countryForPhoneNumberTextBox.borderColor = ColorUtil.borderColor
        suggestionData.removeAll()
        suggestionTableView.reloadData()
        suggestionTableView.isHidden = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let proposeLength = (textField.text?.lengthOfBytes(using: String.Encoding.utf8))! - range.length + string.lengthOfBytes(using: String.Encoding.utf8)
        return proposeLength <= 5
    }
}
