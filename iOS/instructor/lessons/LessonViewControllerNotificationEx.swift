//
//  LessonViewControllerNotificationEx.swift
//  TuneKey
//
//  Created by WHT on 2020/7/15.
//  Copyright © 2020 spelist. All rights reserved.
//

import SwiftDate
import Foundation
import UIKit

extension LessonsViewController {
    func initNotification() {
        // 需要添加到notification中的
//        logger.debug("通知 => 检查通知数据")
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            self.loadStudentData()
            self.getNotificationConfig { config, error in
                guard let config = config else {
                    logger.error("获取通知配置失败: \(String(describing: error))")
                    return
                }
                self.notificationConfig = config
                self.checkNotificationData(config: config)
            }
        }
    }

    func checkNotificationData(config: TKNotificationConfig) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
        logger.debug("通知 => 我进入了checkNotificationData: \(self.isCheckingNotifications)")

            guard !self.isCheckingNotifications else { return }
            self.isCheckingNotifications = true
            var data: [TKLessonSchedule] = []
            let nowTime = Date().timestamp
//            logger.debug("通知 => 准备添加的数据: \(self.lessonSchedule.count)")
            for item in self.lessonSchedule where item.getShouldDateTime() > Double(nowTime) && item.type == .lesson {
                data.append(item.copy())
            }
//        logger.debug("通知 => 要添加的通知数据: \(data.toJSON())")
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            // 获取要提醒的提前时间
            let times = config.reminderTimes.filter { $0 < 1440 }
            let hasNextDayLesson: Bool = config.reminderTimes.contains(1440)
//            logger.debug("通知 => 提前通知的时间: \(times)")
            data = data.sorted { (item1, item2) -> Bool in
                item1.shouldDateTime < item2.shouldDateTime
            }
            let now = Date()
//            let today = Date(year: now.year, month: now.month, day: now.day, hour: 0, minute: 0, second: 0, nanosecond: 0, region: .localRegion)
            let today = DateInRegion(now, region: .localRegion).dateAtStartOf(.day)
//            let nextWeek = today.add(component: .day, value: 8).timestamp
            let nextWeek = today.dateByAdding(8, .day).timestamp
            let dataList = data.filter { $0.getShouldDateTime() <= Double(nextWeek) }.sorted { $0.shouldDateTime > $1.shouldDateTime }
            for _item in dataList.enumerated() {
                let item = _item.element
//                let date = Date(seconds: item.getShouldDateTime(), region: .localRegion)
                let date = DateInRegion(seconds: item.shouldDateTime, region: .localRegion)
//                logger.debug("通知 => 准备开始自己算数据: \(item.id)")
//                logger.debug("通知 => 当前数据的预计上课时间: \(item.shouldDateTime) => 转换后: \(date.year)-\(date.month)-\(date.day) \(date.hour):\(date.minute)")
                for time in times {
                    // 当前的time是提前的分钟
//                    let timeForReminder = date.add(component: .minute, value: -time)
                    let timeForReminder = date.dateByAdding(-time, .minute)
                    // logger.debug("通知 => 计算出来需要提前的时间:  \(timeForReminder.year)-\(timeForReminder.month)-\(timeForReminder.day) \(timeForReminder.hour):\(timeForReminder.minute)")
                    // 注册当前时间到通知中
                    self.addEventToNotification(date: timeForReminder, data: item, timeLeft: time)
                }
            }

            if hasNextDayLesson {
                // 获取明天的所有课程
                data = data.sorted { (item1, item2) -> Bool in
                    item1.shouldDateTime < item2.shouldDateTime
                }
//                let tomorrow = Date().add(component: .day, value: 1)
                let tomorrow = DateInRegion(Date(), region: .localRegion).dateByAdding(1, .day)
                var dateComponents: DateComponents?
                var id: String?
                var body: String = "You're scheduled to teach "
                var numberOfLesson: Int = 0
                var studentsData: [TimeInterval: (String, String)] = [:]
                let dateFormmater = DateFormatter()
                dateFormmater.dateFormat = "hh:mm a"
                for item in data.enumerated() {
//                    let date = Date(seconds: item.element.getShouldDateTime(), region: .localRegion)
                    let date = DateInRegion(seconds: item.element.shouldDateTime, region: .localRegion)
                    if item.offset == 0 {
                        id = item.element.id
                        dateComponents = DateComponents(calendar: .current, timeZone: .current, year: date.year, month: date.month, day: date.day, hour: date.hour, minute: date.minute, second: date.second)
                    }
                    if date.compare(toDate: tomorrow, granularity: .day) == .orderedSame {
                        // 当前课程是明天的课程
                        if let student = self.studentData[item.element.studentId] {
                            numberOfLesson += 1
//                            let time = dateFormmater.string(from: date)
                            let time = date.toFormat("hh:mm a", locale: Locales.current)
                            studentsData[item.element.getShouldDateTime()] = (student.name, time)
                        }
                    }
//                    if date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day {
//                    }
                }
                guard studentsData.count > 0 else {
                    logger.debug("明天没有课程,不需要通知")
                    self.isCheckingNotifications = false
                    return
                }
                body += "\(numberOfLesson) lesson"
                if numberOfLesson > 1 {
                    body += "s "
                } else {
                    body += " "
                }
                body += "tomorrow with "
                let timeList = studentsData.sorted { $0.0 < $1.0 }

                for item in timeList.enumerated() {
                    if item.offset == timeList.count - 1 {
                        body += "and "
                    }
                    body += "\(item.element.value.0) at \(item.element.value.1)"
                    if item.offset == timeList.count - 1 {
                        body += "."
                    } else {
                        body += ", "
                    }
                }
//                logger.debug("通知 => 提前一天的通知内容: \(body)")
                if let dateComponents = dateComponents, let id = id {
                    self.addEventToNotification(subtitle: "Reminder for tomorrow's lesson", body: body, date: dateComponents, id: "\(id):1440")
                }
            }

            self.isCheckingNotifications = false
        }
    }

    private func addEventToNotification(subtitle: String, body: String, date: DateComponents, id: String) {
        logger.debug("通知 => 插入通知队列: \(id) | 时间: \(DateInRegion(components: date, region: .localRegion)?.toFormat("yyyy-MM-dd HH:mm:ss", locale: Locales.current))")
        let content = UNMutableNotificationContent()
        content.badge = 0
        content.title = "Tunekey"
        content.subtitle = subtitle
        content.body = body
        content.categoryIdentifier = "com.spelist.tunekey.\(id)"
//        content.sound = UNNotificationSound.default
        content.sound = UNNotificationSound.default
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        let request = UNNotificationRequest(identifier: "com.spelist.tunekey:\(id)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { err in
            if let err = err {
                logger.debug("通知 => 添加课程提醒结果: \(String(describing: err))")
            }
//            logger.debug("通知 => 添加课程提醒完成, 时间: \(date.year!)-\(date.month!)-\(date.day!) \(date.hour!):\(date.minute!):\(date.second!)")
        }
    }

    private func addEventToNotification(date: DateInRegion, data: TKLessonSchedule, timeLeft: Int) {
//        logger.debug("通知 => 准备数据,即将插入通知队列")
        let studentId = data.studentId
        var name: String = ""
        if let student = studentData[studentId] {
            name = student.name
        }
        var time: String = ""
        if timeLeft > 60 {
            let h = Int(timeLeft / 60)
            let min = Int(timeLeft % 60)
            time = "\(h) hour\(h > 1 ? "s" : "")"
            if min > 0 {
                time += " \(min) minute\(min > 1 ? "s" : "")"
            }
        } else {
            time = "\(timeLeft) minute\(timeLeft > 1 ? "s" : "")"
        }
//        logger.debug("通知 => 准备插入通知队列")
        addEventToNotification(subtitle: "Reminder for today's lesson", body: "You're scheduled to teach a lesson in \(time) with \(name)", date: DateComponents(calendar: .current, timeZone: .current, year: date.year, month: date.month, day: date.day, hour: date.hour, minute: date.minute, second: date.second), id: "\(data.id):\(timeLeft)")
    }

    func initListenerForNotification() {
        EventBus.listenOnBackground(key: .notification_update, target: self) { [weak self] notification in
            guard let self = self else { return }
            if let config = notification?.object as? TKNotificationConfig {
//                logger.debug("通知 => 监听到通知配置有更改")
                self.notificationConfig = config
                self.checkNotificationData(config: config)
            }
        }
    }

    func getNotificationConfig(completion: @escaping (_ config: TKNotificationConfig?, _ error: Error?) -> Void) {
//        logger.debug("通知 => 检查通知数据")
        if let id = UserService.user.id() {
            DatabaseService.collections.userNotificationConfig()
                .document(id)
                .getDocument { snapshot, err in
                    if let err = err {
                        completion(nil, err)
                    } else {
                        guard let config = TKNotificationConfig.deserialize(from: snapshot?.data()) else {
                            completion(nil, TKError.nilDataResponse(nil))
                            return
                        }
                        completion(config, nil)
                    }
                }
        } else {
            completion(nil, TKError.userNotLogin)
        }
    }
}
