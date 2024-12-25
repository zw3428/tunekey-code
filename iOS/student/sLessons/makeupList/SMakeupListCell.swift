//
//  SMakeupListCell.swift
//  TuneKey
//
//  Created by wht on 2020/4/26.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class SMakeupListCell: UITableViewCell {
    private var mainView: TKView!

    private var pRView: TKView!
    private var pRStatusLabel: TKLabel!
    private var pRTimeView: TKView!
    // 老的时间
    private var pROldView: TKView!
    private var pROldTimeLabel: TKLabel!
    private var pROldDayLabel: TKLabel!
    private var pROldMonthLabel: TKLabel!
    // 新的时间(要修改的时间)
    private var pRNewView: TKView!
    private var pRNewTimeLabel: TKLabel!
    private var pRNewDayLabel: TKLabel!
    private var pRNewMonthLabel: TKLabel!
    private var pRPendingLabel: TKLabel!
    private var pRNewQuestionMarkImageView: TKImageView!
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SMakeupListCell {
    func initView() {
        contentView.backgroundColor = UIColor.white
        mainView = TKView.create()
            .addTo(superView: contentView, withConstraints: { make in
                make.edges.equalToSuperview()

            })
        pRView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow(color: ColorUtil.dividingLine)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.bottom.equalToSuperview().offset(-10)
                make.height.equalTo(145)
                make.right.equalToSuperview().offset(-20)
            })
        pRPendingLabel = TKLabel.create()
            .text(text: "")
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.regular(size: 15))
            .addTo(superView: pRView) { make in
                make.left.equalToSuperview().offset(20)
                make.width.equalTo(70)
                make.top.equalToSuperview().offset(20)
            }
        pRStatusLabel = TKLabel.create()
            .text(text: "")
            .textColor(color: ColorUtil.Font.third)
            .font(font: FontUtil.bold(size: 15))
            .adjustsFontSizeToFitWidth()
            .addTo(superView: pRView) { make in
                //                make.height.equalTo(20)
                make.left.equalTo(pRPendingLabel.snp.right)
                make.top.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-10)
            }
        //        pRStatusLabel.numberOfLines = 1
        //        pendingCountLabel.backgroundColor

        pRTimeView = TKView.create()
            .addTo(superView: pRView) { make in
                make.right.left.equalToSuperview()
                make.top.equalTo(pRStatusLabel.snp.bottom).offset(20)
                make.height.equalTo(66)
            }
        let pRTimeArrowView = UIImageView()
        pRTimeArrowView.image = UIImage(named: "icReschedule")
        pRTimeView.addSubview(view: pRTimeArrowView) { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }
        pROldView = TKView.create()
            .addTo(superView: pRTimeView, withConstraints: { make in
                make.top.bottom.equalToSuperview()
                make.right.equalTo(pRTimeArrowView.snp.left).offset(-25)
            })
        pROldTimeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "")
            .addTo(superView: pROldView, withConstraints: { make in
                make.top.left.equalToSuperview()
            })

        pROldDayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: pROldView, withConstraints: { make in
                make.bottom.left.equalToSuperview()
            })
        pROldMonthLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: pROldView, withConstraints: { make in
                make.bottom.equalToSuperview().offset(-4)
                make.left.equalTo(pROldDayLabel.snp.right).offset(9)
                make.right.equalToSuperview()
            })

        pRNewView = TKView.create()
            .addTo(superView: pRTimeView, withConstraints: { make in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(pRTimeArrowView.snp.right).offset(25)
            })
        pRNewView.layer.masksToBounds = true

        pRNewTimeLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "")
            .addTo(superView: pRNewView, withConstraints: { make in
                make.top.left.equalToSuperview()
            })
        pRNewDayLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 40))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: pRNewView, withConstraints: { make in
                make.bottom.left.equalToSuperview()
            })
        pRNewMonthLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: ColorUtil.main)
            .text(text: "")
            .addTo(superView: pRNewView, withConstraints: { make in
                make.bottom.equalToSuperview().offset(-4)
                make.left.equalTo(pRNewDayLabel.snp.right).offset(9)
                make.right.equalToSuperview()
            })

        //        pRNewQuestionMarkView = TKView.create()
        //            .addTo(superView: pRTimeView, withConstraints: { make in
        //                make.top.bottom.equalToSuperview()
        //                make.left.equalTo(pRTimeArrowView.snp.right).offset(30)
        //            })

        pRNewQuestionMarkImageView = TKImageView.create()
            .setImage(name: "greenQuestionMark")
            .addTo(superView: pRTimeView) { make in
                make.height.equalTo(40)
                make.width.equalTo(32)
                make.left.equalTo(pRTimeArrowView.snp.right).offset(40)
                make.top.equalToSuperview().offset(15)
            }
        pRNewQuestionMarkImageView.isHidden = true
        pRNewView.isHidden = true
    }
}

extension SMakeupListCell {
    func initData(reschedule: TKLessonCancellation) {
        let r = reschedule.convertToReschedule()
        // MARK: - TimeBefore 修改过的地方
        r.getTimeBeforeInterval {[weak self] (time) in
            guard let self = self else{return}
            let beforeDate = Date(seconds: time)
            let df = DateFormatter()
            df.dateFormat = "hh:mm a"
            self.pROldTimeLabel.text("\(df.string(from: beforeDate))")
            self.pROldDayLabel.text("\(beforeDate.day)")
            self.pROldMonthLabel.text("\(TimeUtil.getMonthShortName(month: beforeDate.month))")

        }
        
        pRStatusLabel.text("Make up credit")
        pRNewView.isHidden = true
        pRNewQuestionMarkImageView.isHidden = false
        pRPendingLabel.snp.updateConstraints { make in
            make.width.equalTo(0)
        }
    }
}
