//
//  ProfileLessonTypesTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/5.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

protocol ProfileLessonTypesTableViewCellDelegate: NSObjectProtocol {
    func profileLessonTypesTableViewCellMoreTapped()
}

class ProfileLessonTypesTableViewCell: UITableViewCell {
    weak var delegate: ProfileLessonTypesTableViewCellDelegate?

    private var data: [TKLessonType] = []

    private var backView: TKView!
    private var titleLabel: TKLabel!
    private var lessonTypesStackView: UIStackView!
    private var buttonView: TKView!
    private var addImageView: TKImageView!
    private var addButtonLabel: TKLabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileLessonTypesTableViewCell {
    private func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor

        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .corner(size: 5)
        contentView.addSubview(view: backView) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.bottom.right.equalToSuperview().offset(-20)
        }
        let buttonView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: backView) { make in
                make.top.equalToSuperview().offset(5)
                make.left.right.equalToSuperview()
                make.height.equalTo(40)
            }
        buttonView.onViewTapped { [weak self] _ in
            self?.delegate?.profileLessonTypesTableViewCellMoreTapped()
        }
        titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .alignment(alignment: .left)
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Lesson Types")
        backView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(20)
            make.right.equalTo(-20)
            make.height.equalTo(15)
        }

        let moreButton = TKButton.create()
            .setImage(name: "arrowRight", size: CGSize(width: 22, height: 22))
            .addTo(superView: backView) { make in
                make.centerY.equalTo(titleLabel.snp.centerY)
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(22)
            }
        moreButton.onTapped { [weak self] _ in
            self?.delegate?.profileLessonTypesTableViewCellMoreTapped()
        }

        lessonTypesStackView = UIStackView()
        lessonTypesStackView.distribution = .fill
        lessonTypesStackView.axis = .vertical
        lessonTypesStackView.alignment = .fill
        lessonTypesStackView.spacing = 0
        backView.addSubview(view: lessonTypesStackView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10).priority(.medium)
        }
    }

    func loadData(data: [TKLessonType], instruments: [String: TKInstrument]) {
        _ = lessonTypesStackView.arrangedSubviews.compactMap {
            lessonTypesStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        self.data = data
        for item in data.enumerated() {
            if item.offset > 2 {
                break
            }
            let view = TKView.create()
                .backgroundColor(color: UIColor.white)
            view.tag = item.offset
            let pointView = TKImageView.create()
                .setSize(60)
                .asCircle()
            if let instrument = instruments[item.element.instrumentId] {
                if instrument.minPictureUrl == "" {
                    if #available(iOS 13.0, *) {
                        pointView.image = UIImage(named: "8|8_selected")?.resizeImage(CGSize(width: 35, height: 35)).withTintColor(ColorUtil.gray)
                    } else {
                        pointView.image = UIImage(named: "8|8")?.resizeImage(CGSize(width: 35, height: 35))
                    }
                    pointView.setBorder()
                    pointView.contentMode = .center
                } else {
                    pointView.contentMode = .scaleAspectFit
                    pointView.sd_setImage(with: URL(string: instrument.minPictureUrl), completed: nil)
                }
            } else {
                InstrumentService.shared.getInstrument(with: item.element.instrumentId) { instrument in
                    guard let instrument = instrument else { return }
                    if instrument.minPictureUrl == "" {
                        if #available(iOS 13.0, *) {
                            pointView.image = UIImage(named: "8|8_selected")?.resizeImage(CGSize(width: 35, height: 35)).withTintColor(ColorUtil.gray)
                        } else {
                            pointView.image = UIImage(named: "8|8")?.resizeImage(CGSize(width: 35, height: 35))
                        }
                        pointView.setBorder()
                        pointView.contentMode = .center
                    } else {
                        pointView.contentMode = .scaleAspectFit
                        pointView.sd_setImage(with: URL(string: instrument.minPictureUrl), completed: nil)
                    }
                }
            }
            view.addSubview(view: pointView) { make in
                make.left.equalToSuperview()
                make.size.equalTo(60)
                make.centerY.equalToSuperview()
            }

            let height = item.element.name.heightWithFont(font: FontUtil.bold(size: 18), fixedWidth: UIScreen.main.bounds.width - 60 - 20 - 20 - 20)

            let titleLabel = TKLabel.create()
                .font(font: FontUtil.bold(size: 18))
                .textColor(color: ColorUtil.Font.third)
                .text(text: item.element.name)
                .setNumberOfLines(number: 0)
            titleLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
            view.addSubview(view: titleLabel) { make in
                make.top.equalToSuperview().offset(18.5)
                make.left.equalTo(pointView.snp.right).offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(height)
            }
            var detailString: String = ""
//            if item.element.type == TKLessonTypeFormat.groupType {
//                detailString += "Group"
//            } else {
//                detailString += "Private"
//            }

            detailString += "\(item.element.timeLength.description) minutes"
            if item.element.price != -1 {
                detailString += ", $\((item.element.price).description)"
            }
            let detailLabel = TKLabel.create()
                .font(font: FontUtil.regular(size: 13))
                .textColor(color: ColorUtil.Font.primary)
                .text(text: detailString)
            view.addSubview(view: detailLabel) { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(5)
                make.left.equalTo(titleLabel.snp.left)
                make.right.equalToSuperview().offset(-20)
                make.bottom.equalToSuperview().offset(-23).priority(.medium)
                make.height.equalTo(16)
            }
            if item.offset != data.count - 1 && item.offset != 2 {
                let lineView = TKView.create()
                    .backgroundColor(color: ColorUtil.dividingLine.withAlphaComponent(0.5))
                view.addSubview(view: lineView) { make in
                    make.left.equalToSuperview().offset(20)
                    make.bottom.equalToSuperview()
                    make.right.equalToSuperview()
                    make.height.equalTo(1)
                }
            }
            lessonTypesStackView.addArrangedSubview(view)
        }
    }
}
