//
//  InsightsDataChartCollectionViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/4.
//  Copyright © 2019年 spelist. All rights reserved.
//

import ORCharts
import UIKit

class InsightsDataChartCollectionViewCell: UICollectionViewCell {
    enum Status {
        case weekly
        case monthly
        case quarterly
        case annually
    }

    private var backView: TKView!
    private var titleLabel: TKLabel!
    private var lineView: ORLineChartView!
    private var status: Status! = .weekly
    private var startDate = Date()
    // 0: weekly, 1: Monthly, 2: Quarterly, 3: Annually

    var data: [CGFloat] = []
    var teacherMemberLevel = 1
    var insightsCount = 0

    var suffix: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InsightsDataChartCollectionViewCell {
    private func initView() {
        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 10)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
//        backView.clipsToBounds = true
        contentView.addSubview(view: backView) { make in
            make.top.equalToSuperview().offset(0)
            make.bottom.equalToSuperview().offset(-20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "title")
        titleLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.5)
        backView.addSubview(view: titleLabel) { make in
            make.left.top.equalToSuperview().offset(20)
        }
        let maskView = TKView.create()
            .backgroundColor(color: UIColor.white)
        backView.addSubview(view: maskView) { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalTo(titleLabel.snp.bottom)
        }
        backView.sendSubviewToBack(maskView)

        lineView = ORLineChartView()
        lineView.delegate = self
        lineView.dataSource = self

        lineView.config.leftWidth = 40
        lineView.config.showShadowLine = false
        lineView.config.showVerticalBgline = false
        lineView.config.chartLineWidth = 1
        lineView.config.indicatorCircleWidth = 6
        backView.addSubview(view: lineView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(-10)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10)
        }
        backView.sendSubviewToBack(lineView)
    }

    func loadData(data: [CGFloat], color: UIColor, title: String, status: Status = .weekly, startDate: Date = Date(), teacherMemberLevel: Int = 1, insightsCount: Int = 0, suffix: String? = nil, insightsLimitCount: Int) {
        if let suffix = suffix {
            titleLabel.text("\(title) \(suffix)")
        } else {
            titleLabel.text(title)
        }
        self.teacherMemberLevel = teacherMemberLevel
        self.startDate = startDate
        self.status = status
        self.data = data
        self.insightsCount = insightsCount
        self.suffix = suffix

        if teacherMemberLevel == 1 && insightsCount >= insightsLimitCount {
            let color = UIColor(r: 230, g: 233, b: 235)
            lineView.config.gradientColors = [color.withAlphaComponent(0.36), color.withAlphaComponent(0)]
            lineView.config.chartLineColor = color
            lineView.config.indicatorLineColor = color
            lineView.config.indicatorTintColor = color
        } else {
            lineView.config.gradientColors = [color.withAlphaComponent(0.36), color.withAlphaComponent(0)]
            lineView.config.chartLineColor = color
            lineView.config.indicatorLineColor = color
            lineView.config.indicatorTintColor = color
        }
        lineView.config.style = .init(0)
        if data.count > 8 {
            lineView.config.bottomLabelWidth = 30
        } else {
            if data.count <= 8 && data.count > 5 {
                lineView.config.bottomLabelWidth = 50
            } else {
                lineView.config.style = .init(1)
            }
        }
//        if status == .annually || status == .quarterly {
//            let a = (UIScreen.main.bounds.width - 80) / 365
//            logger.debug("======\(a)")
//            lineView.config.bottomLabelWidth = a
//
//        } else {
//            lineView.config.bottomLabelWidth = 50
//        }

//        lineView.config.bottomLabelWidth = 30
        lineView.reloadData()

        let d = Date().startOfDay
        switch status {
        case .weekly:
            lineView.defaultSelectIndex = 0
            break
        case .monthly:
            lineView.defaultSelectIndex = lroundf(Float(TimeUtil.getApartDay(startData: startDate, endData: d)) / Float(3))
            break
        case .quarterly:
            lineView.defaultSelectIndex = lroundf(Float(TimeUtil.getApartDay(startData: startDate, endData: d)) / Float(7))
            break
        case .annually:
            lineView.defaultSelectIndex = lroundf(Float(TimeUtil.getApartDay(startData: startDate, endData: d)) / Float(30))
            // 尝试刷新前调用 defaultSelectIndex 变成 0

            break
        }
    }
}

extension InsightsDataChartCollectionViewCell: ORLineChartViewDelegate, ORLineChartViewDataSource {
    func numberOfHorizontalData(of chartView: ORLineChartView) -> Int {
        return data.count
    }

    func chartView(_ chartView: ORLineChartView, valueForHorizontalAt index: Int) -> CGFloat {
        if teacherMemberLevel == 1 && insightsCount >= 100 {
            return CGFloat(arc4random() % (20 - 10) + 10)
        } else {
//            if status == .annually {
//                return (data[index] / 12).roundTo(places: 2)
//            } else {
//                return data[index]
//            }
            switch status! {
            case .weekly:
                return data[index].roundTo(places: 1)
            case .monthly:
                return (data[index] / 3).roundTo(places: 1)
            case .quarterly:
                return (data[index] / 7).roundTo(places: 1)
            case .annually:
                return (data[index] / 30).roundTo(places: 1)
            }
        }
//        return CGFloat(arc4random() % (15 - 10) + 10)
    }

    func chartView(_ chartView: ORLineChartView, titleForHorizontalAt index: Int) -> String {
        switch status! {
        case .weekly:
//            return TimeUtil.getWeekDayShotName(weekDay: index)
            let d = startDate.add(component: .day, value: index)
            return "\(d.month)/\(d.day)"
        case .monthly:
            let d = startDate.add(component: .day, value: index * (index == 0 ? 0 : 3))
            return "\(d.month)/\(d.day)"
        case .quarterly:
            let d = startDate.add(component: .day, value: index * (index == 0 ? 0 : 7))
            return "\(d.month)/\(d.day)"
        case .annually:
            let d = startDate.add(component: .month, value: index)
            return "\(TimeUtil.getMonthShortName(month: d.month))"
        }
    }

    func chartView(_ chartView: ORLineChartView, attributedStringForIndicaterAt index: Int) -> NSAttributedString {
        if index > data.count - 1 {
            return NSAttributedString(string: "", attributes: [NSAttributedString.Key.font: FontUtil.regular(size: 10), NSAttributedString.Key.foregroundColor: UIColor.white])
        } else {
            switch status! {
            case .weekly:
                return NSAttributedString(string: "\(data[index].roundTo(places: 1))", attributes: [NSAttributedString.Key.font: FontUtil.regular(size: 10), NSAttributedString.Key.foregroundColor: UIColor.white])
            case .monthly:

                return NSAttributedString(string: "\((data[index] / 3).roundTo(places: 2))", attributes: [NSAttributedString.Key.font: FontUtil.regular(size: 10), NSAttributedString.Key.foregroundColor: UIColor.white])
            case .quarterly:
                return NSAttributedString(string: "\((data[index] / 7).roundTo(places: 2))", attributes: [NSAttributedString.Key.font: FontUtil.regular(size: 10), NSAttributedString.Key.foregroundColor: UIColor.white])
            case .annually:
                return NSAttributedString(string: "\((data[index] / 30).roundTo(places: 2))  hrs/day on May", attributes: [NSAttributedString.Key.font: FontUtil.regular(size: 10), NSAttributedString.Key.foregroundColor: UIColor.white])
            }
        }
    }

    func labelAttrbutesForHorizontal(of chartView: ORLineChartView) -> [NSAttributedString.Key: Any] {
        return [NSAttributedString.Key.font: FontUtil.regular(size: 10), NSAttributedString.Key.foregroundColor: ColorUtil.Font.fourth]
    }

    func labelAttrbutesForVertical(of chartView: ORLineChartView) -> [NSAttributedString.Key: Any] {
        return [NSAttributedString.Key.font: FontUtil.regular(size: 10), NSAttributedString.Key.foregroundColor: ColorUtil.Font.fourth]
    }
}
