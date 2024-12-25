//
//  AddEventEndsEX.swift
//  TuneKey
//
//  Created by WHT on 2020/3/10.
//  Copyright © 2020 spelist. All rights reserved.
//

import Foundation
extension AddEventController {
    func endChangedData() {
        data.endType = endsType.endType
        data.endDate = endsType.endDate
        data.endCount = endsType.endCount
    }

    func endChangedHeight() {
        endContainerView.snp.updateConstraints { make in
            make.height.equalTo(endCellHeight)
        }
    }
}

extension AddEventController {
    func initEndsView() {
        endBoxView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .showShadow()
            .corner(size: 5)
        contentView.addSubview(endBoxView)
        endBoxView.snp.makeConstraints { make in
            make.top.equalTo(recurrenceView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10)
        }
        endContainerView = TKView.create()
            .backgroundColor(color: .white)
            .corner(size: 5)
            .addTo(superView: endBoxView, withConstraints: { make in
                make.height.equalTo(0)
                make.top.left.right.bottom.equalToSuperview()
            })
        endContainerView.clipsToBounds = true

        initTopView()
        initEndOnSomedayView()
        initEndAfterSomeTimesView()
    }

    private func initTopView() {
        topContainerView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: endContainerView, withConstraints: { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(64)
            })

        titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
            .text(text: "Ends")
            .addTo(superView: topContainerView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(20)
            })

        doesNotEndSwitch = TKSwitch()
        doesNotEndSwitch.onValueChanged { [weak self] isOn in
            guard let self = self else { return }
            if isOn {
                self.endsType.endType = .endAtSomeday
            } else {
                self.endsType.endType = .none
            }
            self.endChangedData()
            self.updateCheckBox()
            self.updateHeight()
        }
        topContainerView.addSubview(doesNotEndSwitch)
        doesNotEndSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(self.doesNotEndSwitch.size)
        }
    }

    private func initEndOnSomedayView() {
        endOnSomedayView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: endContainerView, withConstraints: { make in
                make.top.equalTo(self.topContainerView.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(54)
            })
        endOnSomedayView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.endOnSomedayTapped()
        }

        endOnSomedayCheckBox = TKImageView.create()
            .setImage(name: "radiobuttonOn")
        endOnSomedayView.addSubview(view: endOnSomedayCheckBox) { make in
            make.left.equalToSuperview().offset(40)
            make.size.equalTo(22)
            make.centerY.equalToSuperview()
        }

        endOnSomedayCheckBox.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.endOnSomedayTapped()
        }

        let prefixLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
            .text(text: "Ends on")
            .addTo(superView: endOnSomedayView) { make in
                make.left.equalTo(endOnSomedayCheckBox.snp.right).offset(8)
                make.centerY.equalToSuperview()
            }

        endOnSomedayDateView = TKView.create()
            .backgroundColor(color: UIColor(named: "buttonNotClickable")!)
            .corner(size: 5)
            .addTo(superView: endOnSomedayView, withConstraints: { make in
                make.top.equalToSuperview().offset(5)
                make.bottom.equalToSuperview().offset(-5)
                make.width.equalTo(100)
                make.left.equalTo(prefixLabel.snp.right).offset(8)
            })
        endOnSomedayDateView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if self.endsType.endType == TKEndType.endAtSomeday {
                self.endOnSomedayDateViewTapped()
            }
        }
        endOnSomedayDateLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
            .text(text: "")
            .alignment(alignment: .center)
            .addTo(superView: endOnSomedayDateView, withConstraints: { make in
                make.left.equalToSuperview().offset(8)
                make.right.equalToSuperview().offset(-8)
                make.centerY.equalToSuperview()
            })
    }

    private func initEndAfterSomeTimesView() {
        endAfterSomeTimesView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: endContainerView, withConstraints: { make in
                make.top.equalTo(endOnSomedayView.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            })
        endAfterSomeTimesView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.endAfterSometimesTapped()
        }
        endAfterSomeTimesCheckBox = TKImageView.create()
            .setImage(name: "checkboxOff")
        endAfterSomeTimesView.addSubview(view: endAfterSomeTimesCheckBox) { make in
            make.centerY.equalToSuperview().offset(-5)
            make.left.equalToSuperview().offset(40)
            make.size.equalTo(22)
        }
        //        endAfterSomeTimesCheckBox.onViewTapped { _ in
        //            self.endAfterSometimesTapped()
        //        }

        let prefixLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
            .text(text: "Ends after")
            .addTo(superView: endAfterSomeTimesView) { make in
                make.centerY.equalToSuperview().offset(-5)
                make.left.equalTo(endAfterSomeTimesCheckBox.snp.right).offset(8)
            }

        endAfterSomeTimesCountView = TKView.create()
            .backgroundColor(color: UIColor(named: "buttonNotClickable")!)
            .corner(size: 5)
            .addTo(superView: endAfterSomeTimesView, withConstraints: { make in
                make.top.equalToSuperview().offset(5)
                make.bottom.equalToSuperview().offset(-15)
                make.width.equalTo(110)
                make.left.equalTo(prefixLabel.snp.right).offset(8)
            })
        endAfterSomeTimesCountView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if self.endsType.endType == TKEndType.endAfterSometimes {
                self.endAfterSometimesCountViewTapped()
            }
        }
        endAfterSomeTimesCountLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
            .alignment(alignment: .center)
            .text(text: "10")
            .addTo(superView: endAfterSomeTimesCountView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(8)
                make.right.equalToSuperview().offset(-8)
            })

        _ = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.second)
            .text(text: "currence")
            .addTo(superView: endAfterSomeTimesView) { make in
                make.left.equalTo(endAfterSomeTimesCountView.snp.right).offset(8)
                make.centerY.equalToSuperview().offset(-5)
            }
    }
}

extension AddEventController {
    func initEndViewData(isOpend: Bool) {
//        doesNotEndSwitch.isEnabled = isEnabled

        if !isOpend {
            doesNotEndSwitch.isOn = false
            endsType.endType = .none
            endCellHeight = 0
            endChangedHeight()
        } else {
            updateView()
        }
        updateCheckBox()
    }

    private func updateView() {
        guard endsType != nil else {
            return
        }
        updateHeight()
        let dfmatter = DateFormatter()
        dfmatter.dateFormat = GlobalFields.dateFormat
        let date = TimeUtil.changeTime(time: endsType.endDate)
        let endOnSomeDayDateString = dfmatter.string(from: date.toString().toDate("YYYY-MM-dd", region: .local)!.date)
        endOnSomedayDateLabel.text(endOnSomeDayDateString)
//        let endOnSomeDayDateString = Date(seconds: endsType.endDate, region: .local).toFormat(GlobalFields.dateFormat)
//        endOnSomedayDateLabel.text(endOnSomeDayDateString)
        let width = endOnSomeDayDateString.widthWithFont(font: FontUtil.bold(size: 18))
        logger.debug("end on someday width: \(width)")
        endOnSomedayDateView.snp.updateConstraints { make in
            make.width.equalTo(width + 18)
        }

        endAfterSomeTimesCountLabel.text(endsType.endCount.description)
        let _width = endsType.endCount.description.widthWithFont(font: FontUtil.bold(size: 18))
        logger.debug("end after some times width: \(_width)")
        endAfterSomeTimesCountView.snp.updateConstraints { make in
            make.width.equalTo(_width + 30)
        }
    }

    private func updateHeight() {
        guard endsType != nil else {
            return
        }
        if endsType.endType == .none {
            endCellHeight = 64
        } else {
            endCellHeight = 64 + 54 + 54 + 10
        }
        endChangedHeight()
    }

    private func updateCheckBox() {
        _ = endAfterSomeTimesCheckBox.setImage(name: "checkboxOff")
        _ = endOnSomedayCheckBox.setImage(name: "checkboxOff")
        switch endsType.endType {
        case .none:
            break
        case .endAfterSometimes:
            _ = endAfterSomeTimesCheckBox.setImage(name: "radiobuttonOn")
        case .endAtSomeday:
            _ = endOnSomedayCheckBox.setImage(name: "radiobuttonOn")
        }
    }

    private func endOnSomedayTapped() {
        if endsType.endType == .endAtSomeday {
            _ = endOnSomedayCheckBox.setImage(name: "radiobuttonOn")
        } else {
            endsType.endType = .endAtSomeday
        }
        updateCheckBox()
        endChangedData()
    }

    private func endAfterSometimesTapped() {
        if endsType.endType == .endAfterSometimes {
            _ = endAfterSomeTimesCheckBox.setImage(name: "radiobuttonOn")
        } else {
            endsType.endType = .endAfterSometimes
        }
        updateCheckBox()
        endChangedData()
    }

    private func endOnSomedayDateViewTapped() {
//        TKDatePicker.show { [weak self] date in
//            guard let self = self else { return }
//            self.endsType.endDate = TimeInterval(date.toString().toDate("YYYY-MM-dd", region: .local)!.date.timestamp)
//            self.endChangedData()
//            let dfmatter = DateFormatter()
//            dfmatter.dateFormat = GlobalFields.dateFormat
//            let endOnSomeDayDateString = dfmatter.string(from: date.toString().toDate("YYYY-MM-dd", region: .local)!.date)
//            self.endOnSomedayDateLabel.text(endOnSomeDayDateString)
//        }
        var startDate = TimeUtil.changeTime(time: data.startDateTime)
        if startDate.timestamp < Date().timestamp {
            startDate = Date()
        }
        TKDatePicker.show(startDate: startDate) { [weak self] date in
            guard let self = self else { return }
            self.endsType.endDate = TimeInterval(date.toString().toDate("YYYY-MM-dd", region: .local)!.date.timestamp)
            self.endChangedData()
            let dfmatter = DateFormatter()
            dfmatter.dateFormat = GlobalFields.dateFormat
            let endOnSomeDayDateString = dfmatter.string(from: date.toString().toDate("YYYY-MM-dd", region: .local)!.date)
            self.endOnSomedayDateLabel.text(endOnSomeDayDateString)
            let width = endOnSomeDayDateString.getLableWidth(font: FontUtil.bold(size: 18), height: 21)
            self.endOnSomedayDateView.snp.updateConstraints { make in
                make.width.equalTo(width + 18)
            }
        }
    }

    private func endAfterSometimesCountViewTapped() {
        if let controller = Tools.getTopViewController() {
            TKPopAction.showEditPop(target: controller, placeholder: "currence", defaultValue: "\(endsType.endCount)", titleString: "Set currence", confirmAction: { [weak self] data in
                guard let self = self else { return }
                if let data: Int = Int(data) {
                    if data > 0 {
                        self.endAfterSomeTimesCountLabel.text("\(data)")
                        self.endsType.endCount = data
                    } else {
                        self.endAfterSomeTimesCountLabel.text("1")
                        self.endsType.endCount = 1
                    }
                } else {
                    self.endAfterSomeTimesCountLabel.text("1")
                    self.endsType.endCount = 1
                }
                self.endChangedData()
            }, onTyped: { textBox, value in
                if let v = Int(value) {
                    if v >= 999 {
                        textBox.value("999")
                    }
                }
            })
        }
    }
}
