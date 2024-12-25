//
//  CountdownController.swift
//  TuneKey
//
//  Created by WHT on 2020/9/26.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit
class CountdownController: TKBaseViewController {
    var mainView = UIView()
    lazy var countdownLabel: TKCountdownLabel = TKCountdownLabel()
    var infoLabel: TKLabel!
    var infoLabel2: TKLabel!
    var currentTimer: Timer!
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        var count: Int64 = SLCache.main.get(key: "tunekey:lessons:countdown_guide:showdCount")
        logger.debug("当前count down: \(count)")
        count += 1
        SLCache.main.set(key: "tunekey:lessons:countdown_guide:showdCount", value: count)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    deinit {
        currentTimer?.invalidate()
        currentTimer = nil
    }
}

// MARK: - View

extension CountdownController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        view.backgroundColor = UIColor.clear
        mainView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        let contentView = TKView.create()
            .addTo(superView: mainView) { make in
                make.centerY.equalToSuperview().offset(-80)
                make.centerX.equalToSuperview()
            }
        
//        countdownLabel.height = 107.28
        countdownLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 90)
//        countdownLabel.animationType = .Evaporate
//        countdownLabel.timeFormat = "hh:mm:ss"
        countdownLabel.textColor = UIColor.white
        countdownLabel.contentMode = .left
        countdownLabel.textAlignment = .center
        countdownLabel.countdownDelegate = self

        contentView.addSubview(view: countdownLabel) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()

//            make.height.equalTo(200)
//            make.width.equalTo(218)
        }
        mainView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            appdelegate.isShowFullScreenCuntdown = false
            UIView.animate(withDuration: 0.3, animations: {
                self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
                self.mainView.backgroundColor = UIColor.black.withAlphaComponent(0)
                self.countdownLabel.alpha = 0
                self.infoLabel.alpha = 0
                self.infoLabel2.alpha = 0
//                self.mainView.frame.origin = CGPoint(x: 0, y: TKScreen.height)
            }) { _ in
                self.dismiss(animated: false, completion: {
                })
            }
//            self.dismiss(animated: false, completion: nil)
        }
        infoLabel = TKLabel.create()
            .textColor(color: UIColor.white)
            .alignment(alignment: .center)
            .addTo(superView: contentView, withConstraints: { make in
                make.left.equalTo(40)
                make.right.equalTo(-40)
                make.top.equalTo(countdownLabel.snp.bottom).offset(0)
            })
        infoLabel2 = TKLabel.create()
            .textColor(color: UIColor.white)
            .alignment(alignment: .center)
            .addTo(superView: contentView, withConstraints: { make in
                make.left.equalTo(40)
                make.right.equalTo(-40)
                make.top.equalTo(infoLabel.snp.bottom).offset(10)
                make.bottom.equalToSuperview()
            })
        infoLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 16)
        infoLabel2.font = UIFont(name: "HelveticaNeue-Medium", size: 16)

        infoLabel.text("Current time: \(Date().toLocalFormat("hh:mm a"))")

        infoLabel.numberOfLines = 0
        infoLabel2.numberOfLines = 0
        checkClassNow()
        currentTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if "Current time: \(Date().toLocalFormat("hh:mm a"))" != self.infoLabel.text {
                self.infoLabel.text("Current time: \(Date().toLocalFormat("hh:mm a"))")
            }
        }
    }
}

// MARK: - Data

extension CountdownController {
    override func initData() {
        EventBus.listen(EventBus.REFRESH_COUNTDOWN, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.checkClassNow()
        }
    }

    func checkClassNow() {
        guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        if let lesson = appdelegate.lessonNow {
            let endTime = lesson.getShouldDateTime() +  (Double(lesson.shouldTimeLength) * Double(60))
            logger.debug("设置countdownLabel: \(endTime) | \(Date(seconds: endTime).toLocalFormat("yyyy-MM-dd HH:mm:ss")) | \(Date(timeIntervalSince1970: endTime).toLocalFormat("yyyy-MM-dd HH:mm:ss"))")
//            let endTime = lesson.shouldDateTime + 60
            let toTime = Date(timeIntervalSince1970: endTime)
            countdownLabel.setCountDownDate(targetDate: toTime)
            countdownLabel.start()
            guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            appdelegate.lessonNow = lesson

//            var text = ""
//            text = "Lesson on \(lesson.getDateLimit().start)"
//            var text2 = ""
//            if let student = lesson.studentData {
//                text2 += "with \(student.name)"
//            }
//            infoLabel.text(text)
//            infoLabel2.text(text2)
            let df = DateFormatter()
            df.locale = NSLocale.system
            df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a": "HH:mm"
//            let text2 = "End time: \(lesson.getDateLimit().end)"
            let text2 = "End time: \(lesson.getDateLimitV2().end)"
            infoLabel2.text(text2)

        } else {
            guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            appdelegate.lessonNow = nil
        }
    }
}

// MARK: - TableView

extension CountdownController {
}

// MARK: - Action

extension CountdownController {
}
extension CountdownController: TKCountdownLabelDelegate {
    
    func countdownFinished() {
        print("我结束了")
        countdownLabel.text = "00:00"
        guard let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appdelegate.lessonNow = nil
    }
}
