//
//  UpdateMaterialsTitleViewController.swift
//  TuneKey
//
//  Created by zyf on 2020/7/3.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

protocol UpdateMaterialsTitleViewControllerDelegate: NSObjectProtocol {
    func updateMaterialsTitleViewController(nextButtonTappedWithTitle title: String, id: String)
}

class UpdateMaterialsTitleViewController: TKBaseViewController {
    weak var delegate: UpdateMaterialsTitleViewControllerDelegate?
    var onCancelTapped: VoidFunc?

    var id: String = ""
    var defaultTitle: String = ""

    private var contentViewHeight: CGFloat = 214

    private var contentView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 10)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

    private var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .text(text: "Update title")
        .textColor(color: ColorUtil.Font.primary)

    private var titleTextBox: TKTextBox = TKTextBox.create()
        .placeholder("Title")
        .keyboardType(.default)
        .inputType(.text)

    private var cancelButton: TKBlockButton = TKBlockButton(frame: .zero, title: "Cancel", style: .cancel)
    private var nextButton: TKBlockButton = TKBlockButton(frame: .zero, title: "Confirm", style: .normal)

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()

        if defaultTitle.lowercased().contains("untitled folder") {
            titleTextBox.selectAll()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        initView()
//        bindEvent()
    }

    override func initView() {
        contentViewHeight += view.safeAreaInsets.bottom
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        view.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if self.titleTextBox.isFocus() {
                self.titleTextBox.blur()
            } else {
                self.hide()
            }
        }

        view.addSubview(view: contentView) { make in
            make.top.equalTo(view.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(contentViewHeight)
        }
        contentView.onViewTapped { _ in
        }

        contentView.addSubview(view: titleLabel) { make in
            make.height.equalTo(20)
            make.top.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        contentView.addSubview(view: titleTextBox) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(64)
        }

        let width = (UIScreen.main.bounds.width - 60) / 2
        contentView.addSubview(view: cancelButton) { make in
            make.width.equalTo(width)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-20)
            make.left.equalToSuperview().offset(20)
        }

        contentView.addSubview(view: nextButton) { make in
            make.width.equalTo(width)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-20)
            make.right.equalToSuperview().offset(-20)
        }
    }

    private func show() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: -self.contentViewHeight)
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            self.titleTextBox.focus()
            self.titleTextBox.value(self.defaultTitle)
        })
    }

    private func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self?.contentView.transform = .identity
        }, completion: { [weak self] _ in
            self?.dismiss(animated: false, completion: {
                completion?()
            })
        })
    }
}

extension UpdateMaterialsTitleViewController {
    override func bindEvent() {
        cancelButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.hide { self.onCancelTapped?() }
        }

        nextButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            // 获取自己所在的文件夹
            var folder: TKMaterial?
            let data = ListenerService.shared.teacherData.homeMaterials
            data.forEach { item in
                if item.id == self.id {
                } else if item.type == .folder {
                    item.materials.forEach { childItem in
                        if childItem.id == self.id {
                            folder = item
                        }
                    }
                }
            }
            var duplicated: Bool = false
            if let folder = folder {
                if folder.materials.filter({ $0.name.lowercased() == self.titleTextBox.getValue().lowercased() && $0.id != self.id }).count > 0 {
                    duplicated = true
                }
            } else {
                if data.filter({ $0.name.lowercased() == self.titleTextBox.getValue().lowercased() && $0.id != self.id }).count > 0 {
                    duplicated = true
                }
            }
            if duplicated {
                self.titleTextBox.showWrong()
                TKToast.show(msg: "Duplicate name", style: .warning)
                return
            }

            self.hide {
                self.delegate?.updateMaterialsTitleViewController(nextButtonTappedWithTitle: self.titleTextBox.getValue(), id: self.id)
            }
        }
    }
}
