//
//  AchievementCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/21.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class SAchievementCell: UITableViewCell {
    private var mainView: TKView!
    private var arrowView: UIImageView!
    private var contentHeight: CGFloat = 0
    var cellHeight: CGFloat = 74
    var isShow = false
    private var contentLabel: TKLabel!
    private var contentLayout = UIStackView()

    private let tipPointView = TKView.create()
        .backgroundColor(color: ColorUtil.main)
        .corner(size: 3)

    weak var delegate: SAchievementCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SAchievementCell {
    func initView() {
        contentView.backgroundColor = UIColor.white
        mainView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.edges.equalToSuperview()
            })
        let titleView = TKView.create()
            .addTo(superView: mainView) { make in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(74)
            }
        titleView.onViewTapped { [weak self] _ in
            self?.clickTitleView()
        }
        let iconView = UIImageView()
        iconView.image = UIImage(named: "icAchievement")
        titleView.addSubview(view: iconView) { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(32)
            make.size.equalTo(22)
        }

        tipPointView.addTo(superView: titleView) { make in
            make.top.equalTo(iconView.snp.top).offset(-3)
            make.left.equalTo(iconView.snp.right)
            make.size.equalTo(6)
        }

        _ = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .text(text: "Award")
            .textColor(color: ColorUtil.Font.third)
            .addTo(superView: titleView) { make in
                make.left.equalTo(iconView.snp.right).offset(20)
                make.top.equalTo(32)
            }
        arrowView = UIImageView()
        arrowView.image = UIImage(named: "icArrowDown")
        titleView.addSubview(view: arrowView) { make in
            make.size.equalTo(22)
            make.top.equalTo(32)
            make.right.equalTo(-20)
        }
        contentLayout.axis = .vertical
        contentLayout.spacing = 10
        contentLayout.alignment = .fill
        mainView.addSubview(view: contentLayout) { make in
            make.right.equalToSuperview().offset(-20)
            make.left.equalTo(iconView.snp.right).offset(20)
            make.top.equalTo(titleView.snp.bottom)
            make.height.equalTo(0)
        }
        mainView.clipsToBounds = true

        // 分割线
        _ = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
            .addTo(superView: mainView) { make in
                make.bottom.right.equalToSuperview()
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(20)
            }
    }

    // MARK: - clickTitleView

    func clickTitleView() {
        isShow.toggle()
        cellHeight = 74
        if contentHeight != 0 {
            cellHeight = isShow ? (74 + contentHeight + 20) : 74
        }
        SL.Animator.run(time: 0.2) { [weak self] in
            guard let self = self else { return }
            if self.isShow {
                self.arrowView.transform = CGAffineTransform.identity
                    .rotated(by: CGFloat(Double.pi))
            } else {
                self.arrowView.transform = CGAffineTransform.identity
            }
            self.contentLayout.snp.updateConstraints({ make in
                make.height.equalTo(self.contentHeight)
            })
            self.layoutIfNeeded()
        }
        delegate?.achievementCell(clickCell: self, cellHeight: cellHeight, isShow: isShow)
    }
}

extension SAchievementCell {
    func initContentLayout(text: String, highlightText: String) {
        let contentLabel: TKLabel = TKLabel()
        contentLayout.addArrangedSubview(contentLabel)
        contentLabel.textColor(color: ColorUtil.Font.primary).font(font: FontUtil.regular(size: 18)).text("")
        contentLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.changeLabelRowSpace(lineSpace: 20, wordSpace: 0)
        let text = "\(text)"
        let height = text.heightWithFont(font: FontUtil.regular(size: 18), fixedWidth: UIScreen.main.bounds.width - 82)
        contentHeight += height
        contentLabel.attributedText = Tools.attributenStringColor(text: text, selectedText: highlightText, allColor: ColorUtil.Font.primary, selectedColor: ColorUtil.Font.third, font: FontUtil.regular(size: 18), fontSize: 18, selectedFontSize: 18, ignoreCase: true, charasetSpace: 0)
    }

    func initData(data: TKLessonSchedule, isShow: Bool, _ isReadAchievement: Bool) {
        self.isShow = isShow
        contentLayout.removeAllArrangedSubviews()
        contentHeight = 0
        for item in data.achievement {
            let name = item.name
            var title = ""
            switch item.type {
            case .all:
                title = ""
            case .technique:
                title = "Technique"
            case .notation:
                title = "Notation"
            case .song:
                title = "Song"
            case .improv:
                title = "Improvement"
            case .groupPlay:
                title = "Group Play"
            case .dedication:
                title = "Dedication"
            case .creativity:
                title = "Creativity"
            case .hearing:
                title = "Hearing"
            case .musicSheet:
                title = "Music reading"
            case .memorization:
                title = item.typeName
            }
            initContentLayout(text: "\(title): \(name)\n\(item.desc)", highlightText: name)
        }
        tipPointView.isHidden = !isReadAchievement

        if data.achievement.count != 0 {
            arrowView.isHidden = false
            contentHeight = contentHeight + CGFloat((data.achievement.count - 1) * 10)
        } else {
            arrowView.isHidden = true
        }
        if isShow {
            arrowView.transform = CGAffineTransform.identity
                .rotated(by: CGFloat(Double.pi))
        } else {
            arrowView.transform = CGAffineTransform.identity
        }
        contentLayout.snp.updateConstraints({ make in
            make.height.equalTo(self.contentHeight)
        })
    }
}

protocol SAchievementCellDelegate: NSObjectProtocol {
    func achievementCell(clickCell cell: SAchievementCell, cellHeight: CGFloat, isShow: Bool)
}
