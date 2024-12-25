//
//  LessonsDetailAchievementTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/3.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class LessonsDetailAchievementTableViewCell: UITableViewCell {
    struct Item {
        var backView: TKView
        var iconImageView: TKImageView
        var titleLabel: TKLabel
        var contentLabel: TKLabel
        var height: CGFloat
    }

    weak var delegate: LessonsDetailAchievementTableViewCellDelegate?

    var cellHeight: CGFloat = 80

    var data: [TKAchievement] = []

    private var items: [Item] = []

    private var backView: TKView!
    private var iconImageView: TKImageView!
    private var titleLabel: TKLabel!
    var addButton: TKButton!
    private var contentLayout: UIStackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonsDetailAchievementTableViewCell {
    private func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        contentView.addSubview(backView)
        backView.snp.makeConstraints { make in
            make.top.equalTo(self.contentView)
            make.left.equalTo(self.contentView)
            make.right.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView)
            make.width.equalTo(UIScreen.main.bounds.width)
        }

        iconImageView = TKImageView.create()
            .setImage(name: "icAchievement")
            .setSize(22)
        backView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(backView).offset(30)
            make.left.equalTo(backView).offset(20)
            make.size.equalTo(22)
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Award")
            .alignment(alignment: .left)
        backView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(20)
            make.centerY.equalTo(iconImageView.snp.centerY)
        }

        addButton = TKButton.create()
            .setImage(name: "icAddPrimary", size: CGSize(width: 22, height: 22))
        addButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            logger.debug("add award button tapped")
            self.delegate?.lessonsDetailAchievementTableViewCellAddAchievementTapped()
        }
        backView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.top.equalTo(backView).offset(21)
            make.right.equalTo(backView).offset(-11)
            make.size.equalTo(40)
        }

        backView.addSubview(contentLayout)
        contentLayout.snp.makeConstraints { make in
            make.top.equalTo(addButton.snp.bottom).offset(10)
            make.left.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(0)
        }
        contentLayout.axis = .vertical
        contentLayout.spacing = 0
        contentLayout.alignment = .fill

        let bottomLine = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
        backView.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    func loadData(data: [TKAchievement]) {
        self.data = data
        contentLayout.removeAllArrangedSubviews()
        items.removeAll()
        var itemHeight: CGFloat = 0
        for item in data.enumerated() {
            let itemView = subviewForStackView(item.element, atIndex: item.offset)
            contentLayout.addArrangedSubview(itemView)
            itemView.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(items[item.offset].height)
            }
            itemHeight += items[item.offset].height
        }

        if data.count > 0 {
//            itemHeight = itemHeight + (data.count > 1 ? CGFloat(data.count * 10) : 0)
            contentLayout.snp.updateConstraints { make in
                make.height.equalTo(itemHeight)
            }
            cellHeight = itemHeight + 80
        } else {
            cellHeight = 80
        }
    }

    private func subviewForStackView(_ data: TKAchievement, atIndex index: Int) -> TKView {
        let view = TKView.create()
        let iconName: String
        let typeString: String
        switch data.type {
        case .technique:
            iconName = "icTechnique"
            typeString = "Technique"
        case .notation:
            iconName = "icNotation"
            typeString = "Theory"
        case .song:
            iconName = "icSong"
            typeString = "Song"
        case .improv:
            iconName = "icDedication"
            typeString = "Improvement"
        case .groupPlay:
            iconName = "icGroupPlay"
            typeString = "Group play"
        case .dedication:
            iconName = "icImprov"
            typeString = "Dedication"
        case .creativity:
            typeString = "Creativity"
            iconName = "icCreativity"
        case .hearing:
            typeString = "Listening"
            iconName = "icHearing"
        case .musicSheet:
            typeString = "Sight reading"
            iconName = "icMusicSheet"
        case .all:
            iconName = "icTechnique"
            typeString = "Technique"
        case .memorization:
            iconName = "icon_memorization"
            typeString = "Memorization"
        }

        guard iconName != "" else {
            return view
        }

        let iconImageView = TKImageView.create()
            .setImage(name: iconName)
            .addTo(superView: view) { make in
                make.size.equalTo(22)
                make.left.equalToSuperview().offset(20)
                make.top.equalToSuperview().offset(10)
            }

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 18))
            .setNumberOfLines(number: 0)
            .addTo(superView: view) { make in
                make.top.equalToSuperview().offset(10)
                make.left.equalTo(iconImageView.snp.right).offset(20)
                make.right.equalToSuperview()
            }
//        titleLabel.lineBreakMode = .byCharWrapping
        let titleString = "\(typeString): \(data.name)"
        let attributedString = Tools.attributenStringColor(text: titleString, selectedText: typeString, allColor: ColorUtil.Font.third, selectedColor: ColorUtil.Font.primary, font: FontUtil.regular(size: 18), fontSize: 18, selectedFontSize: 18, ignoreCase: true, charasetSpace: 0)

//        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.lineSpacing = 22
//        paragraphStyle.alignment = .left
//        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, titleString.count))
        attributedString.addAttribute(NSAttributedString.Key.kern, value: 0, range: NSMakeRange(0, titleString.count))
        titleLabel.attributedText = attributedString

        let contentLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 18))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: data.desc)
            .setNumberOfLines(number: 0)
            .addTo(superView: view) { make in
                make.left.equalTo(titleLabel.snp.left)
                make.top.equalTo(titleLabel.snp.bottom)
                make.right.equalToSuperview()
                make.bottom.equalToSuperview().offset(-10).priority(.medium)
            }
//        contentLabel.lineBreakMode = .byCharWrapping

//        titleLabel.layoutIfNeeded()
        var heightForTitleLabel = titleLabel.textHeight

        let titleText = titleLabel.attributedText!.string
//        if let attributes = titleLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
        heightForTitleLabel =  titleString.heightWithFont(font: FontUtil.regular(size: 18), fixedWidth: UIScreen.main.bounds.width - 82)
//        }
        print("=====titleHeight:\(heightForTitleLabel)===\(UIScreen.main.bounds.width - 82)")

        titleLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalTo(iconImageView.snp.right).offset(20)
            make.right.equalToSuperview()
            make.height.equalTo(heightForTitleLabel)
        }
//        contentLabel.layoutIfNeeded()
//        let heightForContentLabel = contentLabel.text!.getLableHeigh(font: FontUtil.regular(size: 18), width: UIScreen.main.bounds.width - 82)
        let heightForContentLabel = contentLabel.text!.heightWithFont(font: FontUtil.regular(size: 18), fixedWidth: UIScreen.main.bounds.width - 82)
        print("=====contentHeight:\(heightForContentLabel)")
        contentLabel.snp.remakeConstraints { make in
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10).priority(.medium)
            make.height.equalTo(heightForContentLabel)
        }

        let height = heightForTitleLabel + heightForContentLabel + 30 // 间距

        items.append(Item(backView: view, iconImageView: iconImageView, titleLabel: titleLabel, contentLabel: contentLabel, height: height))
        view.tag = index
        iconImageView.tag = index
        titleLabel.tag = index
        contentLabel.tag = index
        view.onViewTapped { [weak self] v in
            guard let self = self else { return }
            self.delegate?.lessonsDetailAchievementTableViewCellAchievementTapped(index: v.tag)
        }
        return view
    }
}

protocol LessonsDetailAchievementTableViewCellDelegate: NSObjectProtocol {
    func lessonsDetailAchievementTableViewCellAddAchievementTapped()
    func lessonsDetailAchievementTableViewCellAchievementTapped(index: Int)
}
