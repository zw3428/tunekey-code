//
//  InsightsTeachingWorkHoursSelectViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/4.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class InsightsTeachingWorkHoursSelectViewController: TKBaseViewController {
    var completion: (Int) -> Void = { _ in }

    var defaultData: Int = 0

    private var data: [Int] = [30, 35, 40, 45, 50, 55, 60, 65, 70]

    private var currentIndex: Int = 0

    private var backView: TKView!
    private var titleLabel: TKLabel!
    private var workHoursStackView: UIStackView!
    private var closeButton: TKButton!
    private var doneButton: TKButton!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
}

extension InsightsTeachingWorkHoursSelectViewController {
    override func initView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

        view.addSubview(view: backView) { make in
            make.top.equalToSuperview().offset(UIScreen.main.bounds.height)
            make.left.right.equalToSuperview()
            make.height.equalTo(CGFloat(data.count) * 50 + 150)
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 15))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Set target week hours")
            .alignment(alignment: .center)
        backView.addSubview(view: titleLabel) { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }

        workHoursStackView = UIStackView()
        workHoursStackView.axis = .vertical
        workHoursStackView.alignment = .fill
        workHoursStackView.distribution = .fillEqually
        workHoursStackView.spacing = 0
        backView.addSubview(view: workHoursStackView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(30)
            make.left.right.equalToSuperview()
            make.height.equalTo(CGFloat(data.count) * 50)
        }

        closeButton = TKButton.create()
            .title(title: "Close")
            .titleColor(color: ColorUtil.Font.primary)
            .titleFont(font: FontUtil.bold(size: 18))
        closeButton.backgroundColor = UIColor.white
        backView.addSubview(view: closeButton) { make in
            make.top.equalTo(workHoursStackView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(60)
        }

        doneButton = TKButton.create()
            .title(title: "Done")
            .titleColor(color: ColorUtil.main)
            .titleFont(font: FontUtil.bold(size: 18))
        backView.addSubview(view: doneButton) { make in
            make.top.equalTo(workHoursStackView.snp.bottom).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(60)
        }
    }

    override func initData() {
        for item in data.enumerated() {
            let view = TKView.create()
                .backgroundColor(color: item.element == defaultData ? ColorUtil.main : UIColor.white)
            view.tag = item.offset
            let label = TKLabel.create()
                .alignment(alignment: .center)
            label.attributedText = Tools.attributenStringColor(text: item.element.description + " hrs", selectedText: "hrs", allColor: item.element == defaultData ? UIColor.white : ColorUtil.Font.third, selectedColor: item.element == defaultData ? UIColor.white : ColorUtil.Font.third, font: FontUtil.medium(size: 32), fontSize: 32, selectedFontSize: 22, ignoreCase: true, charasetSpace: 0)
            view.addSubview(view: label) { make in
                make.center.equalToSuperview()
            }
            view.onViewTapped { [weak self] _ in
                guard let self = self else { return }
                self.hoursTapped(index: item.offset)
            }
            workHoursStackView.addArrangedSubview(view)
        }
    }

    private func updateData() {
        for view in workHoursStackView.arrangedSubviews {
            if view.tag == currentIndex {
                view.backgroundColor = ColorUtil.main
            } else {
                view.backgroundColor = UIColor.white
            }
            for label in view.subviews {
                if label is TKLabel {
                    (label as! TKLabel).attributedText = Tools.attributenStringColor(text: data[view.tag].description + " hrs", selectedText: "hrs", allColor: (view.tag != currentIndex) ? ColorUtil.Font.third : UIColor.white, selectedColor: (view.tag != currentIndex) ? ColorUtil.Font.third : UIColor.white, font: FontUtil.medium(size: 32), fontSize: 32, selectedFontSize: 22, ignoreCase: true, charasetSpace: 0)
                }
            }
        }
    }

    private func hoursTapped(index: Int) {
        currentIndex = index
        updateData()
    }

    override func bindEvent() {
        view.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.hide {
            }
        }

        backView.onViewTapped { _ in
        }

        closeButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            logger.debug("close button tapped")
            self.hide {}
        }

        doneButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            logger.debug("done button tapped")
            self.hide { [weak self] in
                guard let self = self else { return }
                self.completion(self.data[self.currentIndex])
            }
        }
    }

    private func show() {
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.backView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(UIScreen.main.bounds.height - (CGFloat(self.data.count) * 50 + 150) - self.view.safeAreaInsets.bottom)
            }
            self.view.layoutIfNeeded()
        }) { _ in
        }
    }

    private func hide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.backView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(UIScreen.main.bounds.height)
            }
            self.view.layoutIfNeeded()
        }) { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: false, completion: {
                completion()
            })
        }
    }
}
