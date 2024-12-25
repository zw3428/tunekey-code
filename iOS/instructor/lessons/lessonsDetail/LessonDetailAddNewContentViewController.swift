//
//  LessonDetailAddNewContentViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/3/5.
//  Copyright © 2022 spelist. All rights reserved.
//

import SnapKit
import UIKit

class LessonDetailAddNewContentViewController: TKBaseViewController {
    override var isPad: Bool {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.contains("iPad")
    }

    @Live var titleAlignment: NSTextAlignment = .left
    @Live var titleString: String = "Add Homework"
    @Live var leftButtonString: String = "CANCEL"
    @Live var rightButtonString: String = "CREATE"

    @Live var leftButtonStyle: TKBlockButton.Style = .cancel
    @Live var rightButtonStyle: TKBlockButton.Style = .normal
    
    @Live var font: UIFont? = FontUtil.bold(size: 18)
    
    @Live var isCloseButtonShow: Bool = false

    var contentViewHeight: CGFloat = 160 + 37 + UiUtil.safeAreaBottom()
    private var contentView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 15)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

    var textView: UITextView?

    var text: String = ""

    public var onLeftButtonTapped: ((String) -> Void)?
    public var onRightButtonTapped: ((String) -> Void)?

    private var isShow: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
}

extension LessonDetailAddNewContentViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.addTo(superView: view) { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(contentViewHeight)
        }
        contentView.transform = CGAffineTransform(translationX: 0, y: contentViewHeight)

        ViewBox(paddings: UIEdgeInsets(top: 17, left: 20, bottom: 20, right: 20)) {
            VStack {
                VStack(spacing: 20) {
                    HStack {
                        Label($titleString)
                            .textColor(ColorUtil.Font.fourth)
                            .font(FontUtil.regular(size: 15))
                            .textAlignment($titleAlignment)
                            .size(height: 24)
                    }.size(height: 24)
                    TextView()
                        .text(text)
                        .font($font)
                        .textColor(ColorUtil.Font.third)
                        .tintColor(ColorUtil.main)
                        .cornerRadius(5)
                        .borderColor(ColorUtil.borderColor)
                        .borderWidth(1)
                        .delegate(self)
                        .apply { [weak self] textView in
                            guard let self = self else { return }
                            self.textView = textView
                            self.textView?.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                            textView.textContainer.lineFragmentPadding = 5
                            textView.textContainerInset = .init(top: 10, left: 10, bottom: 10, right: 10)
                        }
                        .size(height: 60)
                    HStack(distribution: .fillEqually, spacing: 10) {
                        BlockButton()
                            .set(title: $leftButtonString, style: $leftButtonStyle)
                            .onBlockButtonTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.view.endEditing(true)
                                self.onLeftButtonTapped?(self.text)
                            }
                            .size(height: 50)
                        BlockButton()
                            .set(title: $rightButtonString, style: $rightButtonStyle)
                            .onBlockButtonTapped { [weak self] _ in
                                guard let self = self else { return }
                                self.view.endEditing(true)
                                self.onRightButtonTapped?(self.text)
                            }
                            .size(height: 50)
                    }.size(height: 50)
                }
                if !isPad || UiUtil.safeAreaBottom() != 0 {
                    Spacer(spacing: 20)
                }
            }
        }
        .addTo(superView: contentView) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        
        Button().image(UIImage(named: "ic_close_green")?.resizeImage(CGSize(width: 22, height: 22)), for: .normal)
            .isShow($isCloseButtonShow)
            .onTapped { [weak self] _ in
                self?.hide()
            }
            .addTo(superView: contentView) { make in
                make.top.equalToSuperview()
                make.right.equalToSuperview()
                make.size.equalTo(62)
            }
        
    }
}

extension LessonDetailAddNewContentViewController {
    private func show() {
        guard !isShow else { return }
        isShow = true
        textView?.text = text
        textView?.sizeThatFits(CGSize(width: view.bounds.width - 40, height: CGFloat.greatestFiniteMagnitude))
        var textViewHeight = (textView?.contentSize.height ?? 0) + 20
        if textViewHeight < 57 {
            textViewHeight = 57
        }
        contentViewHeight = 160 + UiUtil.safeAreaBottom() + textViewHeight
        if contentViewHeight > 378 {
            contentViewHeight = 378
        }
        contentView.snp.updateConstraints { make in
            make.height.equalTo(contentViewHeight)
        }
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            guard let textView = self.textView else { return }
            textView.becomeFirstResponder()
            textView.setContentOffset(CGPoint(x: 0, y: textView.contentOffset.y), animated: true)
        }
    }

    func hide() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: self.contentViewHeight)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: false, completion: nil)
        }
    }
}

extension LessonDetailAddNewContentViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        logger.debug("text view did changed")
        updateHeight(textView: textView)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        self.text = (textView.text! as NSString).replacingCharacters(in: range, with: text) as String
        updateHeight(textView: textView)
        return true
    }

    private func updateHeight(textView: UITextView) {
        var textViewHeight = textView.contentSize.height + 20
        if textViewHeight < 57 {
            textViewHeight = 57
        }
        contentViewHeight = 160 + UiUtil.safeAreaBottom() + textViewHeight
        if contentViewHeight > 378 {
            contentViewHeight = 378
        }
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.contentView.snp.updateConstraints { make in
                make.height.equalTo(self.contentViewHeight)
            }
        }
    }
}
