//
//  ProfileUpgradeProTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/5.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileUpgradeProTableViewCell: UITableViewCell {
    weak var delegate: ProfileUpgradeProTableViewCellDelegate?

    private var backView: TKView!
    private var titleLabel: TKLabel!
    private var upgradeProButton: TKLabel!
    private var tipLabel: TKLabel!
    private var proImgView: TKImageView = TKImageView()

    private var eventImageView: TKImageView = TKImageView.create()
    private var eventTitleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 13))
        .textColor(color: ColorUtil.Font.third)
    private var eventDescLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.regular(size: 13))
        .textColor(color: ColorUtil.Font.fourth)
        .setNumberOfLines(number: 0)
    private var eventButton: TKButton = TKButton.create()
        .titleFont(font: FontUtil.medium(size: 8))
        .titleColor(color: .white)
        .backgroundColor(color: ColorUtil.red)
        .corner(5)
    private lazy var eventView: TKView = makeEventView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileUpgradeProTableViewCell {
    private func makeEventView() -> TKView {
        let view = TKView.create()
        view.addSubviews(eventImageView, eventTitleLabel, eventDescLabel, eventButton)
        eventImageView.snp.makeConstraints { _ in
        }
        eventTitleLabel.snp.makeConstraints { _ in
        }
        eventDescLabel.snp.makeConstraints { _ in
        }
        eventButton.snp.makeConstraints { _ in
        }
        return view
    }
}

extension ProfileUpgradeProTableViewCell {
    private func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showShadow()
            .corner(size: 5)
            .showBorder(color: ColorUtil.borderColor)
        contentView.addSubview(view: backView) { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(88)
//            make.bottom.equalToSuperview().offset(-45).priority(.medium)
        }
        eventView.clipsToBounds = true
        eventView.addTo(superView: contentView) { make in
            make.top.equalTo(backView.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(0)
            make.height.equalTo(0)
            make.bottom.equalToSuperview().offset(-10).priority(.medium)
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "TuneKey PRO")
        backView.addSubview(view: titleLabel) { make in
            make.top.equalToSuperview().offset(21)
            make.left.equalToSuperview().offset(20)
        }

        upgradeProButton = TKLabel.create()
            .text(text: "PRO")
            .alignment(alignment: .center)
            .font(font: FontUtil.medium(size: 8.3))
            .textColor(color: UIColor.white)
        upgradeProButton.cornerRadius = 3
        upgradeProButton.backgroundColor = UIColor(named: "red")!
        upgradeProButton.setShadows()
        upgradeProButton.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.48)
        backView.addSubview(view: upgradeProButton) { make in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(42)
            make.height.equalTo(24)
        }
        proImgView.setImage(name: "toastSuccess")
        backView.addSubview(view: proImgView) { make in
            make.right.equalTo(upgradeProButton.snp.right).offset(9)
            make.top.equalTo(upgradeProButton.snp.top).offset(-9)
            make.width.equalTo(18)
            make.height.equalTo(18)
        }
        proImgView.isHidden = true

        tipLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Upgrade for unlimited access!")
        tipLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.4)
        backView.addSubview(view: tipLabel) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(20)
        }
        
        upgradeProButton.onViewTapped { [weak self] _ in
            self?.delegate?.profileUpgradeProTableViewCellButtonTapped()
        }
        backView.onViewTapped { [weak self] _ in
            self?.delegate?.profileUpgradeProTableViewCellButtonTapped()
        }
//        upgradeProButton.onTapped { [weak self] _ in
//        }
    }

    func initData(teacher: TKTeacher, event: TKSystemEvent?) {
        proImgView.isHidden = true
        upgradeProButton.backgroundColor = UIColor(named: "red")!
        upgradeProButton.setBorder(borderWidth: 0, borderColor: UIColor.clear)
        upgradeProButton.textColor(color: UIColor.white)

        if teacher.memberLevelId == 2 {
            proImgView.isHidden = false
            upgradeProButton.backgroundColor = UIColor.white
            upgradeProButton.textColor(color: UIColor(named: "red")!)

            upgradeProButton.setBorder(borderWidth: 0.5, borderColor: UIColor(named: "red")!)
            titleLabel.text("Currently PRO")
            tipLabel.text = "Enjoy the unlimited access."
//            backView.snp.updateConstraints { (make) in
//                make.bottom.equalToSuperview().offset(-20).priority(.medium)
//            }
        } else {
            titleLabel.text("TuneKey PRO")
            tipLabel.text = "Upgrade for unlimited access!"
//            backView.snp.updateConstraints { (make) in
//                make.bottom.equalToSuperview().offset(-45).priority(.medium)
//            }
        }

        if let event = event {
            eventButton.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(event.buttonSize.height)
                make.width.equalTo(event.buttonSize.width)
            }
            eventButton.title(title: event.buttonTitle)
                .titleColor(color: UIColor(hex: event.buttonTitleColor))
                .backgroundColor(color: UIColor(hex: event.buttonBackgroundColor))
                
            if event.buttonImage == "" {
                eventButton.imageView?.image = nil
            } else {
                eventButton.setImage(withURL: event.buttonImage)
            }
            eventImageView.setImage(url: event.imageURL)
            eventImageView.contentMode = .scaleAspectFit
            if event.imageURL != "" {
                eventImageView.isHidden = false
                eventImageView.snp.remakeConstraints { make in
                    make.top.equalToSuperview().offset(10)
                    make.left.equalToSuperview().offset(20)
                    make.width.equalTo(event.imageSize.width)
                    make.height.equalTo(event.imageSize.height)
                }
            } else {
                eventImageView.isHidden = true
            }
            eventTitleLabel.text = event.title
            if event.title != "" {
                eventTitleLabel.isHidden = false
                eventTitleLabel.snp.remakeConstraints { make in
                    make.top.equalToSuperview().offset(10)
                    if event.imageURL == "" {
                        make.left.equalToSuperview().offset(20)
                    } else {
                        make.left.equalTo(eventImageView.snp.right).offset(10)
                    }
                    make.right.equalTo(eventButton.snp.left).offset(-10)
                }
            } else {
                eventTitleLabel.isHidden = true
            }
            eventDescLabel.text = event.desc
            if event.desc != "" {
                eventDescLabel.isHidden = false
                eventDescLabel.snp.remakeConstraints { make in
                    if event.title == "" {
                        make.top.equalToSuperview().offset(10)
                    } else {
                        make.top.equalTo(eventTitleLabel.snp.bottom).offset(4)
                    }
                    if event.imageURL == "" {
                        make.left.equalToSuperview().offset(20)
                    } else {
                        make.left.equalTo(eventImageView.snp.right).offset(10)
                    }
                    make.right.equalTo(eventButton.snp.left).offset(-10)
                }
            } else {
                eventDescLabel.isHidden = true
            }
            logger.debug("event的大小: \(event.size.toJSONString() ?? "")")
            eventView.snp.updateConstraints { make in
                make.height.equalTo(event.size.height)
                if event.size.width == 0 {
                    make.width.equalTo(UIScreen.main.bounds.width - 40)
                } else {
                    make.width.equalTo(event.size.width)
                }
            }
            eventView.isHidden = false
            eventView.onViewTapped { _ in
                CommonsWebViewViewController.show(event.url)
            }
            eventDescLabel.onViewTapped { _ in
                CommonsWebViewViewController.show(event.url)
            }
            eventButton.onTapped { _ in
                CommonsWebViewViewController.show(event.url)
            }
            eventTitleLabel.onViewTapped { _ in
                CommonsWebViewViewController.show(event.url)
            }
            eventImageView.onViewTapped { _ in
                CommonsWebViewViewController.show(event.url)
            }
        } else {
            eventView.isHidden = true
            eventView.snp.updateConstraints { make in
                make.height.equalTo(0)
                make.width.equalTo(UIScreen.main.bounds.width - 40)
            }
        }
    }
    
    
}

protocol ProfileUpgradeProTableViewCellDelegate: NSObjectProtocol {
    func profileUpgradeProTableViewCellButtonTapped()
}
