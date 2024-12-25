//
//  TKCountdownLabel.swift
//  TuneKey
//
//  Created by zyf on 2022/12/10.
//  Copyright © 2022 spelist. All rights reserved.
//

import UIKit

protocol TKCountdownLabelDelegate: NSObjectProtocol {
    func countdownFinished()
}

class TKCountdownLabel: UILabel {
    static let actionkey: String = String(describing: TKCountdownLabel.self)
    weak var countdownDelegate: TKCountdownLabelDelegate?
    
    deinit {
        logger.debug("销毁 TKCountdownLabel")
    }
    
    
    private var targetDate: Date?
    func setCountDownDate(targetDate: Date) {
        self.targetDate = targetDate
    }

    func start() {
        globalTimerActions.removeValue(forKey: TKCountdownLabel.actionkey)
        globalTimerActions["\(TKCountdownLabel.actionkey):\(Date().timestamp)"] = { [weak self] now in
            self?.onRunning(now: now)
        }
    }

    private func onRunning(now: TimeInterval) {
        guard let targetDate = targetDate else { return }
        let currentDate = Date(timeIntervalSince1970: now)
        // 判断现在距离目标时间的时间,然后设置
        let calendar = Calendar(identifier: .gregorian)
        let comp = calendar.dateComponents([.day, .hour, .minute, .second], from: currentDate, to: targetDate)
        var labelText: String = ""
        if let day = comp.day,
           let hour = comp.hour,
           let minute = comp.minute,
           let second = comp.second {
            if day == 0 {
                if hour == 0 {
                    labelText = "\(minute >= 10 ? "\(minute)" : "0\(minute)"):\(second >= 10 ? "\(second)" : "0\(second)")"
                } else {
                    labelText = "\(hour >= 10 ? "\(hour)" : "0\(hour)"):\(minute >= 10 ? "\(minute)" : "0\(minute)"):\(second >= 10 ? "\(second)" : "0\(second)")"
                }
            } else {
                labelText = "\(day >= 10 ? "\(day)" : "0\(day)"):\(hour >= 10 ? "\(hour)" : "0\(hour)"):\(minute >= 10 ? "\(minute)" : "0\(minute)"):\(second >= 10 ? "\(second)" : "0\(second)")"
            }
        }
        text = labelText
        if now >= targetDate.timeIntervalSince1970 {
            countdownDelegate?.countdownFinished()
        }
    }
}
