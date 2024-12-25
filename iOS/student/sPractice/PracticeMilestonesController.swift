//
//  PracticeMilestonesController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/26.
//  Copyright © 2019年 spelist. All rights reserved.
//

import AVFoundation
import HandyJSON
import RxSwift
import UIKit
import WebKit

class PracticeMilestonesController: TKBaseViewController {
    var mainView = UIView()
    private var webView: WKWebView!
    private var startPracticeButton: TKBlockButton!
    var targetController: SPracticeController!
    var isPlaying: Bool = false
    var beat: TKBeatPicker.Beat = TKBeatPicker.Beat(left: 4, right: 4)
    private var studentData: TKStudent!
    private var lesson: TKLessonSchedule!
    private var bpm = 120
    private var isEditBpm = false
    private let fileURL = Bundle.main.url(forResource: "assets/web/metronome", withExtension: "html")

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setMetronomeConfig()
    }

    private func setMetronomeConfig() {
        let config = SLCache.main.getString(key: "app:cache:metronome:config")
        logger.debug("应用节拍器缓存: \(config)")
        if config != "" {
            webView.evaluateJavaScript("recover('\(config)')") { _, error in
                logger.debug("应用节拍器缓存结束: \(String(describing: error))")
            }
        } else {
            webView.evaluateJavaScript("recover()") { _, error in
                logger.debug("应用节拍器初始化: \(String(describing: error))")
            }
        }
    }
}

// MARK: - View

extension PracticeMilestonesController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        initWebView()
//        startPracticeButton = TKBlockButton(frame: .zero, title: "START PRACTICE")
//        mainView.addSubview(view: startPracticeButton) { make in
//            make.width.equalTo(180)
//            make.height.equalTo(50)
//            make.bottom.equalTo(-20)
//            make.centerX.equalToSuperview()
//        }
//        startPracticeButton.onTapped { [weak self] _ in
//            guard let self = self else { return }
//            self.clicStartPracticeButton()
//        }
    }

    func initWebView() {
        let conf = WKWebViewConfiguration()
        conf.userContentController = WKUserContentController()
        conf.preferences.javaScriptEnabled = true
        conf.selectionGranularity = WKSelectionGranularity.character
        conf.allowsInlineMediaPlayback = true
        // 注册 js 消息通道
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "showBeatPickerDialog")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "showNotePickerDialog")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "startMetronome")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "stopMetronome")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "consoleLog")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "setBPM")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "saveMetronomeConfig")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "showNoSoundTips")

        // 注册播放方法
//        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "play")
//        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "pause")

        if #available(iOS 10.0, *) {
            conf.mediaTypesRequiringUserActionForPlayback = []
        } else {
            conf.mediaPlaybackRequiresUserAction = false
        }
        webView = WKWebView(frame: .zero, configuration: conf) // .zero
        webView.backgroundColor = ColorUtil.backgroundColor
        webView.isOpaque = false
        mainView.addSubview(view: webView) { make in
            make.edges.equalToSuperview()
        }
        webView.uiDelegate = self
        // 禁止顶部下拉 和 底部上拉效果
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.delegate = self
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.loadFileURL(fileURL!, allowingReadAccessTo: Bundle.main.bundleURL)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
    }

    func reload() {
        webView.loadFileURL(fileURL!, allowingReadAccessTo: Bundle.main.bundleURL)
    }
}

// MARK: - WebView

extension PracticeMilestonesController: WKUIDelegate, WKScriptMessageHandler, UIScrollViewDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView?.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none';", completionHandler: nil)
        self.webView?.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none';", completionHandler: nil)
        // 禁止放大缩小
        let injectionJSString = """
        var script = document.createElement('meta');\
        script.name = 'viewport';\
        script.content="width=device-width, initial-scale=1.0,maximum-scale=1.0, minimum-scale=1.0, user-scalable=no";\
        document.getElementsByTagName('head')[0].appendChild(script);
        """
        webView.evaluateJavaScript(injectionJSString, completionHandler: nil)
        print("=====webView加载完毕===")
        SL.Executor.runAsyncAfter(time: 0.1) { [weak self] in
            guard let self = self else { return }
            print("=sss==\(self.bpm)")
//            self.isEditBpm = true
//            self.webView.evaluateJavaScript("setBPMFromNative('\(self.beat.left!)','\(self.beat.right!)',\(self.bpm))") { _, err in
//                if let err = err {
//                    logger.debug("======\(err)")
//                }
//            }
            self.setMetronomeConfig()
        }
        let isShowed: Bool = SLCache.main.getBool(key: "\(UserService.user.id() ?? ""):showsMetronomeTip")
        if !isShowed {
            webView.evaluateJavaScript("showNoSoundTips()")
        }
    }

//    private func testPlay() {
//        guard let sound1String = getFileBase64(name: "m3_sound1", type: "wav"),
//              let sound2String = getFileBase64(name: "m3_sound2", type: "wav"),
//              let sound3String = getFileBase64(name: "m3_sound3", type: "wav") else {
//            logger.error("转换到的base64失败")
//            return
//        }
    ////        logger.debug("sounds: [\"\(sound1String)\", \"\(sound2String)\", \"\(sound3String)\"]")
//        webView.evaluateJavaScript("setSound('CUSTOM', ['\(sound1String)', '\(sound2String)', '\(sound3String)'], 'Muyu')") { _, error in
//            logger.debug("测试播放完成,是否有错误: \(String(describing: error))")
//        }
//    }
//
//    private func getFileBase64(name: String, type: String) -> String? {
//        guard let file = Bundle.main.path(forResource: name, ofType: type) else { return nil }
//        let fileURL = URL(fileURLWithPath: file)
//        do {
//            let fileData = try Data(contentsOf: fileURL)
//            let base64 = fileData.base64EncodedString(options: .endLineWithLineFeed)
//            return "data:audio/\(type);base64,\(base64)"
//        } catch {
//            logger.error("转换失败: \(error)")
//            return nil
//        }
//    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "showBeatPickerDialog" {
            TKBeatPicker.show(beat: beat, target: self) { beat in
                self.beat = beat
                logger.debug("======\(self.beat)")
                self.webView.evaluateJavaScript("resetCountAndBeat('\(beat.left!)','\(beat.right!)')") { _, err in
                    if let err = err {
                        logger.debug("======\(err)")
                    }
                }
            }
        }
        if message.name == "consoleLog" {
            print("Consol_logger = \(message.body)")
        }
        if message.name == "showNotePickerDialog" {
//            showNotePickerDialog()
        }
        if message.name == "œ" {
            print("====开始")
            isEditBpm = true
            isPlaying = true
        }
        if message.name == "stopMetronome" {
            print("====停止")
            isPlaying = false
        }
        if message.name == "setBPM" {
            if let body = message.body as? [String: Int], let bpm = body["value"] {
                if isEditBpm {
                    self.bpm = bpm
                }
            }
        }

        if message.name == "saveMetronomeConfig" {
            if let body = message.body as? [String: String], let config = body["value"] {
                logger.debug("缓存节拍器config: \(config)")
                SLCache.main.set(key: "app:cache:metronome:config", value: config)
            }
        }

//        if message.name == "play" {
//            // 播放
//            guard let data = message.body as? [String: Any], let moduleData = data["value"] as? [String: Any] else { return }
//            guard let optionData = MetronomeOption.deserialize(from: moduleData) else { return }
//            logger.debug("原始数据: \(data)")
//            logger.debug("加载后的option数据: \(optionData.toJSONString() ?? "")")
//            play(optionData)
//        }
//        if message.name == "pause" {
//            logger.debug("停止节拍器")
//            pause()
//        }
        
        if message.name == "showNoSoundTips" {
            guard let topController = Tools.getTopViewController() else { return }
            SL.Alert.show(
                target: topController,
                title: "No Sound?",
                message: """
                If you can't hear anything, try the below steps:
                1. Unlock ring / silent switch.
                2. Turn up the volume.
                """,
                leftButttonString: "Got It",
                rightButtonString: "Report A Bug",
                leftButtonColor: ColorUtil.main,
                rightButtonColor: ColorUtil.Font.primary) { [weak self] in
                    guard let self = self else { return }
                    SLCache.main.set(key: "\(UserService.user.id() ?? ""):showsMetronomeTip", value: true)
                    self.webView.evaluateJavaScript("hideNoSoundTips()")
                } rightButtonAction: {
                    let controller = ShowBugReportorListController()
                    controller.modalPresentationStyle = .fullScreen
                    controller.hero.isEnabled = true
                    controller.enablePanToDismiss()
                    controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                    Tools.getTopViewController()?.present(controller, animated: true, completion: nil)
                } onShow: { alert in
                    alert.messageLabel.textAlignment = .left
                }

        }
    }

    // 禁止WebView放大
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

extension PracticeMilestonesController: NotePickerViewControllerDelegate {
    /// 音符选择器选择音符之后
    /// - Parameter note: 音符类别
    func notePickerViewController(didSelectedNote note: TKNoteType) {
        logger.debug("选择的音符是: \(note)")
    }

    private func showNotePickerDialog() {
        logger.debug("唤起音符节奏选择器")
        var noteBasedType: NotePickerViewController.NoteBasedType = .full
        switch beat.right {
        case 1: noteBasedType = .full
        case 2: noteBasedType = .half
        case 4: noteBasedType = .quarter
        case 8: noteBasedType = .eighth
        default: noteBasedType = .full
        }
        let controller = NotePickerViewController(noteBasedType: noteBasedType, defaultNoteType: .full)
        controller.delegate = self
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }
}

// MARK: - Data

extension PracticeMilestonesController {
    override func initData() {
        getStudentData()
        EventBus.listen(EventBus.CHANGE_PRACTICE, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.getPreLesson()
        }
//        EventBus.listen(EventBus.ENTER_FRONT_DESK, target: self) { [weak self] _ in
//            guard let self = self else { return }
//            self.isPlaying = false
//        }
        EventBus.listen(EventBus.ENTER_BACKGROUND, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.stopMetronome()
            self.isPlaying = false
        }
        EventBus.listen(EventBus.STOP_METRONOME, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.stopMetronome()
            self.isPlaying = false
        }
        EventBus.listen(EventBus.PLAY_AUDIO_STOP_METRONOME, target: self) { [weak self] _ in
            guard let self = self else { return }
            guard self.isPlaying else { return }
            self.isPlaying = false
            self.webView.evaluateJavaScript("stopPlay()") { _, err in
                if let err = err {
                    logger.debug("======\(err)")
                }
            }
        }
    }

    /// 停止节拍器 1.点击其他Item时 2.播放其他音乐时 3.退出到后台时候
    func stopMetronome() {
        webView.evaluateJavaScript("stopPlay()") { _, err in
            if let err = err {
                logger.debug("======\(err)")
            }
        }
        isEditBpm = false
        reload()
    }

    func getPreLesson() {
        guard let studentData else { return }
        var isLoad = false
        addSubscribe(
            LessonService.lessonSchedule.getPreviousLesson(targetTime: Date().timestamp, teacherId: studentData.teacherId, studentId: studentData.studentId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKLessonSchedule] = []
                    if !isLoad {
                        for doc in docs.documents {
                            if let doc = TKLessonSchedule.deserialize(from: doc.data()) {
                                data.append(doc)
                            }
                        }
                        if data.count > 0 {
                            isLoad = true
                            self.lesson = data[0]
                            self.getHomeworkData(lesson: data[0])
                        }
                    }

                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func getHomeworkData(lesson: TKLessonSchedule) {
        var isLoad = false

        addSubscribe(
            LessonService.lessonSchedule.getScheduleAssignmentByScheduleId(sId: lesson.id)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache] {
                        if data.count > 0 {
                            isLoad = true
                        }
                        self.lesson.assignmentData = data
                    }
                    if let data = data[.server] {
                        if !isLoad {
                            self.lesson.assignmentData = data
                        }
                    }
                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    /// 获取学生自己的详情
    private func getStudentData() {
        var isLoad = false
        addSubscribe(
            UserService.teacher.studentGetTKStudent()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache] {
                        isLoad = true
                        self.studentData = data
                        self.getPreLesson()
                    }
                    if let data = data[.server] {
                        if !isLoad {
                            self.studentData = data
                            self.getPreLesson()
                        }
                    }

                }, onError: { err in
                    self.hideFullScreenLoading()
                    logger.debug("获取学生信息失败:\(err)")
                })
        )
    }
}

// MARK: - Action

extension PracticeMilestonesController {
    func clicStartPracticeButton() {
//        if lesson == nil {
//            return
//        }
//        let schedule = lesson.copy()
//        let controller = TKPopRecordPracticeController()
//        controller.practiceType = .practice
//        controller.titleString = "Practice"
//        controller.schedule = schedule
//        controller.confirmAction = { [weak self] practices in
//            guard let self = self else { return }
//            //            RecordingControllerEx.toRecording(assignment: practices, fatherController: self)
//            print("=============")
//            self.targetController?.showRecordingController(assignment: practices, schedule: schedule)
//        }
//        controller.modalPresentationStyle = .custom
//        present(controller, animated: false, completion: nil)

        guard targetController.practiceData.count > 0 else {
            return
        }
        targetController.practiceData[0].practice.forEachItems { item, _ in
            for hItem in targetController.practiceHistoryData.enumerated().reversed() where hItem.element.name == item.name {
                targetController.practiceHistoryData.remove(at: hItem.offset)
            }
        }

        let controller = TKPopRecordPracticeController()
        controller.practiceType = .practice
        controller.practiceHistoryData = targetController.practiceHistoryData
        controller.titleString = "Record Practice"
        controller.practiceData = targetController.practiceData[0].practice
        //        controller.schedule = lessonSchedule[0].copy()
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
        controller.confirmAction = { [weak self] practices in
            guard let self = self else { return }
            self.targetController?.showRecordingController(practices: practices)
        }
    }
}

extension PracticeMilestonesController {
}
