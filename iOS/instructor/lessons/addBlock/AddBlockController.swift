//
//  AddBlockController.swift
//  TuneKey
//
//  Created by WHT on 2020/3/10.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class AddBlockController: TKBaseViewController {
    private var mainView = UIView()
    private var navigationBar: TKNormalNavigationBar!
    private var headerView: TKView!
    private var startTimeView: TKView!
    private var startTimeLabel: TKLabel!
    private var endTimeView: TKView!
    private var endTimeLabel: TKLabel!
    private var nextButton: TKBlockButton!
    private var dataFormatter = DateFormatter()
    private var data: TKBlock = TKBlock()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - View

extension AddBlockController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "Add Block", target: self)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initHeaderView()
        initStartTimeView()
        initEndTimeView()
        nextButton = TKBlockButton(frame: CGRect.zero, title: "CREATE")
        mainView.addSubview(view: nextButton) { make in
            make.top.equalTo(endTimeView.snp.bottom).offset(60)
            make.height.equalTo(50)
            make.width.equalTo(180)
            make.centerX.equalToSuperview()
        }
        nextButton.onTapped { [weak self] _ in
            self?.clickCreate()
        }
    }

    private func initHeaderView() {
        headerView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(navigationBar.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(94.3)
            })
        let titleImg = TKImageView.create()
            .setImage(name: "imgClaendar")
            .addTo(superView: headerView) { make in
                make.left.equalToSuperview().offset(20)
                make.centerY.equalToSuperview()
                make.size.equalTo(30)
            }
        _ = TKLabel.create()
            .text(text: "Block")
            .textColor(color: ColorUtil.Font.third)
            .font(font: FontUtil.bold(size: 18))
            .setLabelRowSpace(lineSpace: 0, wordSpace: 1)
            .addTo(superView: headerView) { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(titleImg.snp.right).offset(20)
            }
    }

    private func initStartTimeView() {
        startTimeView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(headerView.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })
        startTimeView.onViewTapped { [weak self] _ in
            self?.selectDate()
        }
        let arrowView = TKImageView.create()
            .setImage(name: "arrowRight")
            .addTo(superView: startTimeView) { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(22)
            }
        let infoLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.primary)
            .font(font: FontUtil.regular(size: 13))
            .text(text: "Start")
            .alignment(alignment: .right)
            .addTo(superView: startTimeView) { make in
                make.right.equalTo(arrowView.snp.left)
                make.centerY.equalToSuperview()
                make.width.equalTo(35)
            }
        startTimeLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.bold(size: 18))
            .addTo(superView: startTimeView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualTo(infoLabel.snp.left).offset(-20)
                make.left.equalToSuperview().offset(20)
            })
    }

    private func initEndTimeView() {
        endTimeView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(startTimeView.snp.bottom).offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(64)
            })
        endTimeView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            let startDate = TimeUtil.changeTime(time: self.data.startDateTime)
            let endDate = TimeUtil.changeTime(time: self.data.endDateTime)

            self.selectTime(type: 2, between: TKTimePicker.Time(hour: startDate.hour, minute: startDate.minute), defaultTime: TKTimePicker.Time(hour: endDate.hour, minute: endDate.minute))
        }
        let arrowView = TKImageView.create()
            .setImage(name: "arrowRight")
            .addTo(superView: endTimeView) { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(22)
            }
        let infoLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.primary)
            .font(font: FontUtil.regular(size: 13))
            .text(text: "End")
            .alignment(alignment: .right)
            .addTo(superView: endTimeView) { make in
                make.right.equalTo(arrowView.snp.left)
                make.centerY.equalToSuperview()
                make.width.equalTo(35)
            }
        endTimeLabel = TKLabel.create()
            .textColor(color: ColorUtil.Font.second)
            .font(font: FontUtil.bold(size: 18))
            .addTo(superView: endTimeView, withConstraints: { make in
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualTo(infoLabel.snp.left).offset(-20)
                make.left.equalToSuperview().offset(20)
            })
    }
}

// MARK: - Data

extension AddBlockController {
    override func initData() {
        var currentDate = Date()
        if currentDate.hour > 23 {
            currentDate = currentDate.add(component: .hour, value: 2)
        }
        data.startDateTime = TimeInterval(currentDate.timestamp)
        data.endDateTime = currentDate.add(component: .hour, value: 1).timeIntervalSince1970
        dataFormatter.dateFormat = Locale.is12HoursFormat() ? "dd MMM yyyy, hh:mm a" : "dd MMM yyyy, HH:mm"
        startTimeLabel.text = dataFormatter.string(from: currentDate)
        endTimeLabel.text = dataFormatter.string(from: currentDate.add(component: .hour, value: 1))
    }
}

// MARK: - TableView

extension AddBlockController {
}

// MARK: - Action

extension AddBlockController {
    /// 创建Block
    func clickCreate() {
        let time = "\(Date().timestamp)"
        data.id = time
        if let id = IDUtil.nextId(group: .lesson) {
            data.id = "\(id)"
        }
        data.teacherId = UserService.user.id()!
        data.createTime = time
        data.updateTime = time

        showFullScreenLoading()
        addSubscribe(
            LessonService.block.add(data: data)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    logger.debug("===成功===")
                    self.dismiss(animated: true) {
                        TKToast.show(msg: TipMsg.createSuccessful, style: .success)
                    }

                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    logger.debug("====失败==\(err)")
                    TKToast.show(msg: TipMsg.faildCreate, style: .warning)
                })
        )
    }

    /// 选择时间
    func selectDate() {
        TKDatePicker.show { [weak self] date in
            guard let self = self else { return }
            let date = date.toString().toDate("YYYY-MM-dd", region: .local)!.date
            self.data.startDateTime = TimeInterval(date.timestamp)
            self.data.endDateTime = date.add(component: .hour, value: 1).timeIntervalSince1970
            self.startTimeLabel.text = self.dataFormatter.string(from: date)
            self.endTimeLabel.text = self.dataFormatter.string(from: date.add(component: .hour, value: 1))
            self.selectTime(type: 1, between: TKTimePicker.Time(hour: 0, minute: 0), defaultTime: TKTimePicker.Time(hour: 0, minute: 0))
        }
    }

    /// 选择时间
    /// - Parameters:
    ///   - type: 1是起始时间 2是结束时间
    ///   - between: 时间选择器的开始时间
    ///   - defaultTime: 时间选择器的默认时间
    func selectTime(type: Int, between: TKTimePicker.Time, defaultTime: TKTimePicker.Time) {
        TKTimePicker.show(between: between, and: TKTimePicker.Time(hour: 23, minute: 59), defaultTime: defaultTime, target: self) { [weak self] selectTime in
            guard let self = self else { return }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            var date = TimeUtil.changeTime(time: self.data.startDateTime)
            if type == 2 {
                date = TimeUtil.changeTime(time: self.data.endDateTime)
            }
            let dateString = "\(df.string(from: date)) \(selectTime.hour!):\(selectTime.minute!)"
            df.dateFormat = "yyyy-MM-dd HH:mm"
            if type == 1 {
                self.data.startDateTime = TimeInterval(df.date(from: dateString)!.timestamp)
                self.startTimeLabel.text = self.dataFormatter.string(from: TimeUtil.changeTime(time: self.data.startDateTime))
                self.data.endDateTime = df.date(from: dateString)!.add(component: .hour, value: 1).timeIntervalSince1970
                self.endTimeLabel.text = self.dataFormatter.string(for: TimeUtil.changeTime(time: self.data.endDateTime))

            } else {
                self.data.endDateTime = TimeInterval(df.date(from: dateString)!.timestamp)
                self.endTimeLabel.text = self.dataFormatter.string(for: TimeUtil.changeTime(time: self.data.endDateTime))
            }
        }
    }
}
