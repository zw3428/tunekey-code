//
//  BatchSettingLessonTypeCell.swift
//  TuneKey
//
//  Created by Wht on 2019/11/7.
//  Copyright © 2019 spelist. All rights reserved.
//

import UIKit

class BatchSettingLessonTypeCell: UITableViewCell {
    weak var delegate: BatchSettingLessonTypeCellDelegate?

    private var instrumentImageView: TKImageView!
    private var titleLabel: TKLabel!
    private var contentLabel: TKLabel!
    var isHaveLessonType = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BatchSettingLessonTypeCell {
    private func initView() {
        let backView: TKView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)

        contentView.addSubview(view: backView) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10)
        }
        backView.layer.cornerRadius = 5
        instrumentImageView = TKImageView.create()
            .setImage(color: ColorUtil.main)
            .setSize(60)
            .asCircle()
        backView.addSubview(view: instrumentImageView) { make in
//            make.left.equalToSuperview().offset(20)
//            make.size.equalTo(60)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(0)
            make.size.equalTo(0)
        }
        let arrowView = UIImageView()
        arrowView.image = UIImage(named: "arrowRight")
        backView.addSubview(view: arrowView) { make in
            make.size.equalTo(22)
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.third)
            .text(text: "Tap to select lesson type")
        titleLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        backView.addSubview(view: titleLabel) { make in
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(23)
            make.left.equalTo(instrumentImageView.snp.right).offset(20)
            make.right.equalTo(arrowView.snp.left).offset(-15)
        }

        contentLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
        backView.addSubview(view: contentLabel) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalTo(titleLabel.snp.right)
        }
        backView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.lessonTypeCell(cell: self)
        }
    }

    func loadData(data: TKLessonType?, instruments: [String: TKInstrument]) -> CGFloat {
        if let data = data {
            instrumentImageView.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(20)
                make.size.equalTo(60)
            }
            titleLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(25)
            }
            titleLabel.text(data.name)
            var content: String = ""
//            if data.type == .groupType {
//                content = "Group, "
//            } else {
//                content = "Private, "
//            }
            content += "\(data.timeLength.description) minutes"
            if data.price != -1 {
                content += ", $\((data.price).description)"
            }

            contentLabel.text(content)
            instrumentImageView.image = nil
            
            if let instrument = instruments[data.instrumentId] {
                if instrument.minPictureUrl == "" {
                    if #available(iOS 13.0, *) {
                        instrumentImageView.image = UIImage(named: "8|8_selected")?.resizeImage(CGSize(width: 35, height: 35)).withTintColor(ColorUtil.gray)
                    } else {
                        instrumentImageView.image = UIImage(named: "8|8")?.resizeImage(CGSize(width: 35, height: 35))
                    }
                    instrumentImageView.setBorder()
                    instrumentImageView.contentMode = .center
                } else {
                    instrumentImageView.contentMode = .scaleAspectFit
                    instrumentImageView.sd_setImage(with: URL(string: instrument.minPictureUrl), completed: nil)
                }
            } else {
                InstrumentService.shared.getInstrument(with: data.instrumentId) { [weak self] instrument in
                    guard let self = self else { return }
                    guard let instrument = instrument else { return }
                    if instrument.minPictureUrl == "" {
                        if #available(iOS 13.0, *) {
                            self.instrumentImageView.image = UIImage(named: "8|8_selected")?.resizeImage(CGSize(width: 35, height: 35)).withTintColor(ColorUtil.gray)
                        } else {
                            self.instrumentImageView.image = UIImage(named: "8|8")?.resizeImage(CGSize(width: 35, height: 35))
                        }
                        self.instrumentImageView.setBorder()
                        self.instrumentImageView.contentMode = .center
                    } else {
                        self.instrumentImageView.contentMode = .scaleAspectFit
                        self.instrumentImageView.sd_setImage(with: URL(string: instrument.minPictureUrl), completed: nil)
                    }
                }
            }
            return 113
        } else {
            instrumentImageView.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(0)
                make.size.equalTo(0)
            }
            titleLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(20)
            }
            titleLabel.text("Tap to select lesson type")
            return 73
        }
    }
}

protocol BatchSettingLessonTypeCellDelegate: NSObjectProtocol {
    func lessonTypeCell(cell: BatchSettingLessonTypeCell)
}
