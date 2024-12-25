//
//  RecordingController.swift
//  TuneKey
//
//  Created by wht on 2020/5/25.
//  Copyright © 2020 spelist. All rights reserved.
//

import AVFoundation
import HandyJSON
import UIKit
import WebKit

struct TKWebPractice: HandyJSON {
    var name: String! = ""
    var id: String! = ""
    var isSelected: Bool = false
}

class RecordingControllerEx {
    static func toRecording(practices: [TKPractice], mainController: MainViewController, fatherController: SPracticeController, confirmAction: @escaping (_ recordData: [H5PracticeRecord], _ totalTime: CGFloat, _ practiceId: String, _ isDone: Bool, _ recordController: RecordingController) -> Void) {
        var practiceDatas: [TKWebPractice] = []
        for item in practices {
            var practice = TKWebPractice()
            practice.name = item.name
            practice.id = item.id
            practice.isSelected = item._isSelect
            practiceDatas.append(practice)
        }

        AVAudioSession.authorizeToMicrophone { isSuccess in
            if isSuccess {
                logger.debug("选择的练习数据: \(practiceDatas.toJSONString() ?? "")")
                UIApplication.shared.isIdleTimerDisabled = true
                fatherController.logController?.tableView.isUserInteractionEnabled = false
                mainController.tabBar.isHidden = true
//                let height = mainController.tabBar.frame.height
//                mainController.tabBar.alpha = 0
                let controller = RecordingController()
                controller.modalPresentationStyle = .custom
                controller.practiceListData = practiceDatas
                controller.confirmAction = confirmAction
                controller.fatherController = fatherController
                fatherController.addChild(controller)
                controller.initView()
                controller.show()
            } else {
//                TKToast.show(msg: "To ecord audio please enable Permission in settings.", style: .warning)
            }
        }
    }
}

class RecordingController: TKBaseViewController {
    var mainView = UIView()
    var recoder: RecorderTool!
    var webView: WKWebView!
    var audios: [TKAudioModule] = []
    var cutAudio: TKAudioModule!
    var cutBeforeAudio: TKAudioModule!
    var margeAudio: TKAudioModule!
    var margeBeforeAudio: TKAudioModule!
    var margeAfterAudio: TKAudioModule!
    var fatherController: UIViewController!

    var practiceListData: [TKWebPractice] = []

    var volumeList: [Float] = []
    // 开始录音 但是没有声音的 1秒钟10个 结束录音后自动剪裁
    var beforeRecordingVolumeList: [Float] = []
    // 是否要开始录音
    var isNeedStartRecoding = false

    var confirmAction: ((_ recordData: [H5PracticeRecord], _ totalTime: CGFloat, _ practiceId: String, _ isDone: Bool, _ recordController: RecordingController) -> Void)?

    // 0正常,1剪裁,2合并
    var status: Int = 0
    private var backView = UIView()
    private var isEnterBackground = false
    // 是否要手动调用录音
    private var isManualRecording = false
    private var isFirstRecording = true

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("======")
//        show()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

// MARK: - View

extension RecordingController {
    override func initView() {
//        fatherController.view.backgroundColor = UIColor.clear
        initData()
        initBackView()
        fatherController.view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.height.equalTo(UIScreen.main.bounds.height <= 667 ? 292 : 380)
            make.left.equalTo(fatherController.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(fatherController.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalToSuperview()
        }
        mainView.backgroundColor = UIColor.white
        mainView.setTopRadius()
        mainView.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height <= 667 ? 292 : 380)
        initWebView()
    }

    func initBackView() {
//        backView.backgroundColor = UIColor.black.withAlphaComponent(0)
//        view.addSubview(view: backView) { make in
//            make.left.right.top.equalToSuperview()
//            make.bottom.equalToSuperview().offset(-UiUtil.safeAreaBottom())
//        }
//        backView.isUserInteractionEnabled = true
    }

    func show() {
        UIView.animate(withDuration: 0.3) {
//            self.backView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.mainView.transform = CGAffineTransform.identity
        }
    }

    func hide(completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: 0.3, animations: {
//            self.backView.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.mainView.frame.origin = CGPoint(x: 0, y: TKScreen.height)
        }) { _ in
//            self.dismiss(animated: false, completion: {
//                completion()
//            })
            self.mainView.removeFromSuperview()
            self.removeFromParent()
        }
    }

    func initWebView() {
        mainView.backgroundColor = ColorUtil.backgroundColor
        webView = WKWebView()
        
        mainView.addSubview(view: webView) { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height <= 667 ? 292 : 380)
        }
        let conf = WKWebViewConfiguration()
        conf.userContentController = WKUserContentController()
        conf.preferences.javaScriptEnabled = true
        conf.selectionGranularity = WKSelectionGranularity.character
        conf.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            conf.mediaTypesRequiringUserActionForPlayback = []
        } else {
            conf.mediaPlaybackRequiresUserAction = false
        }
        // 注册 js 消息通道
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "startLocalRecord")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "stopLocalRecord")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "cutInLocal")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "closePractice")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "finishPractice")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "cancelCutOrMerge")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "saveCutOrMerge")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "mergeInLocal")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "readDuaraion")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "consoleLog")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "initDB")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "backToPopup")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "recordDone")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "startPlayRecord")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "cancelUploadRecordPiece")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "uploadRecordPiece")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "pause")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "play")

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
        let fileURL = Bundle.main.url(forResource: "assets/web/practice.record.v2", withExtension: "html")
        webView.loadFileURL(fileURL!, allowingReadAccessTo: Bundle.main.bundleURL)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        let fun = { [weak self] in
            guard let self = self else { return }
            self.viewDidLoad()
        }
    }
}

// MARK: - Data

extension RecordingController {
    override func initData() {
        EventBus.listen(EventBus.ENTER_FRONT_DESK, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.isEnterBackground = false
            if self.isManualRecording {
                self.isManualRecording = false
                self.recording()
            }
        }
        EventBus.listen(EventBus.ENTER_BACKGROUND, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.isEnterBackground = true
        }
    }

    private func margeAudio(data: TKAudioOperating, duration: CGFloat) {
        let id = "\(IDUtil.nextId(group: .audio)!)"
        var beforeIndex = 0
        var afterIndex = 0
        var beforePath = ""
        var afterPath = ""
        for item in audios.enumerated() {
            if item.element.id == data.beforeId {
                beforeIndex = item.offset
                beforePath = item.element.audioPath
            }
            if item.element.id == data.afterId {
                afterIndex = item.offset
                afterPath = item.element.audioPath
            }
        }
        audios[beforeIndex].duration = data.beforeDuration
        audios[beforeIndex].index = data.beforeIndex
        audios[beforeIndex].isUpload = data.beforeIsUpload
        margeBeforeAudio = audios[beforeIndex]

        audios[afterIndex].duration = data.afterDuration
        audios[afterIndex].index = data.afterIndex
        audios[afterIndex].isUpload = data.afterIsUpload

        margeAfterAudio = audios[afterIndex]

        RecorderTool.sharedManager.audioMerge(outId: id, audioFileUrls: [beforePath, afterPath]) { [weak self] isSuccess, path in
            if isSuccess {
                let fileData = try! Data(contentsOf: URL(fileURLWithPath: path))
                var base64 = fileData.base64EncodedString(options: .endLineWithLineFeed)
                base64 = "data:audio/x-m4a;base64,\(base64)"
                self?.margeAudio = TKAudioModule(id: id, audioPath: path, index: data.beforeIndex, duration: "\(duration)", base64: base64, isUpload: data.isUpload)
                OperationQueue.main.addOperation {
                    logger.debug("======\(data.beforeIndex!)===\(duration)===\(id)")
                    self?.webView.evaluateJavaScript("updatePieces('\(data.beforeIndex!)','\(id)','\(base64)','\(duration)')") { _, err in
                        if let err = err {
                            logger.debug("======\(err)")
                        }
                    }
                }
            }
        }
    }

    private func cutAudio(data: TKAudioOperating, duration: CGFloat) {
        var index = 0
        for item in audios.enumerated() where item.element.id == data.id {
            index = item.offset
        }
        audios[index].duration = data.total
        audios[index].index = data.index
        audios[index].isUpload = data.isUpload
        cutBeforeAudio = audios[index]

        let id = "\(IDUtil.nextId(group: .audio)!)"
        RecorderTool.sharedManager.audioCrop(outId: id, patch: audios[data.index].audioPath, startTime: Int64(Float(data.start)!), endTime: Int64(Float(data.end)!)) { [weak self] isSuccess, path in
            if isSuccess {
                logger.debug("======剪裁成功:\(duration)")
                //                    self?.audios.append(TKAudioModule(id: id, audioPath: path))
                let fileData = try! Data(contentsOf: URL(fileURLWithPath: path))
                var base64 = fileData.base64EncodedString(options: .endLineWithLineFeed)
                base64 = "data:audio/x-m4a;base64,\(base64)"
                self?.cutAudio = TKAudioModule(id: id, audioPath: path, index: data.index, duration: "\(duration)", base64: base64, isUpload: data.isUpload)

                OperationQueue.main.addOperation {
                    logger.debug("======\(data.index!)===\(duration)===\(id)")
                    self?.webView.evaluateJavaScript("updatePieces('\(data.index!)','\(id)','\(base64)','\(duration)')") { _, err in
                        if let err = err {
                            logger.debug("======\(err)")
                        }
                    }
                }

            } else {
                logger.debug("======失败")
            }
        }
    }
}

extension RecordingController {
    // MARK: - 音频相关

    func recording() {
        let id = "\(IDUtil.nextId(group: .audio)!)"
        RecorderTool.sharedManager.startRecord(id: id)
        beforeRecordingVolumeList.removeAll()
        audios.append(TKAudioModule(id: id, audioPath: RecorderTool.sharedManager.aacPath!, index: audios.count, duration: "", base64: ""))
    }

    func stop(isAutoPlay: Bool) {
        RecorderTool.sharedManager.stopRecord()
        isNeedStartRecoding = false
        print("==没有声音的个数=\(beforeRecordingVolumeList.count)")
        if beforeRecordingVolumeList.count > 15 && RecorderTool.sharedManager.currentTime != nil {
            // 此处需要剪裁
            let id = "\(IDUtil.nextId(group: .audio)!)"
            print("=====\(RecorderTool.sharedManager.currentTime!)")
            RecorderTool.sharedManager.audioCrop(outId: id, patch: RecorderTool.sharedManager.aacPath!, startTime: Int64(beforeRecordingVolumeList.count / 10), endTime: Int64(RecorderTool.sharedManager.currentTime!)) { [weak self] isSuccess, path in
                guard let self = self else { return }
                if isSuccess {
                    logger.debug("======剪裁成功:\(path)")

                    let fileData = try! Data(contentsOf: URL(fileURLWithPath: path))
                    var base64 = fileData.base64EncodedString(options: .endLineWithLineFeed)
                    base64 = "data:audio/x-m4a;base64,\(base64)"
//                    self?.cutAudio = TKAudioModule(id: id, audioPath: path, index: data.index, duration: "\(duration)", base64: base64, isUpload: data.isUpload)
                    self.audios[self.audios.count - 1].id = id
                    self.audios[self.audios.count - 1].audioPath = path
                    let id = self.audios[self.audios.count - 1].id!
                    print("\(RecorderTool.sharedManager.aacPath!)====暂停的Id:\(id)")
                    self.audios[self.audios.count - 1].base64 = base64
                    OperationQueue.main.addOperation {
                        self.webView.evaluateJavaScript("listenStopRecord('\(base64)','\(id)','\(isAutoPlay)')") { [weak self] _, err in
                            guard let self = self else { return }
                            if let err = err {
                                logger.debug("======\(err)")
                            } else {
                                self.volumeList.removeAll()
                            }
                        }
                    }

                } else {
                    logger.debug("======失败")
                }
            }
        } else {
            initStopRecording(isAutoPlay)
        }
    }

    func initStopRecording(_ isAutoPlay: Bool) {
        let fileData = try! Data(contentsOf: URL(fileURLWithPath: RecorderTool.sharedManager.aacPath!))
        let base64 = fileData.base64EncodedString(options: .endLineWithLineFeed)
        let data = "data:audio/aac;base64,\(base64)"

        let id = audios[audios.count - 1].id!
        audios[audios.count - 1].base64 = data
        webView.evaluateJavaScript("listenStopRecord('\(data)','\(id)','\(isAutoPlay)')") { [weak self] _, err in
            guard let self = self else { return }
            if let err = err {
                logger.debug("======\(err)")
            } else {
                self.volumeList.removeAll()
            }
        }
    }

    func recorderScale() {
        RecorderTool.sharedManager.recorderScale = { [weak self] db in
            guard let self = self else { return }
//            print("音量百分比\(db)")
            if self.isNeedStartRecoding {
                self.webView.evaluateJavaScript("updateDB('\(db)')") { _, err in
                    if let err = err {
                        logger.debug("====initDB:==\(err)")
                    }
                }
                self.initVolumeList(volume: db)
            } else {
                self.beforeRecordingVolumeList.append(db)
                if db >= 0.14 || !self.isFirstRecording {
                    self.isNeedStartRecoding = true
                    self.webView.evaluateJavaScript("listenStartRecord()") { _, err in
                        if let err = err {
                            logger.debug("======\(err)")
                        }
                    }
                }
            }
        }
    }

    func initVolumeList(volume: Float) {
        if volumeList.count > 49 {
            volumeList.remove(at: 0)
        }
        volumeList.append(volume)
        // 这两种方法都可以
//        print("数组中大于0.1的:\(volumeList.filter{$0 > 0.1}.count)")
//        print("数组是否有大于0.1的:\(volumeList.contains{$0 > 0.1})")
        guard volumeList.count >= 50 else { return }
        if volumeList.contains(where: { $0 > 0.1 }) {
        } else {
            print("5秒钟内声音都小于0.1")
            stop(isAutoPlay: true)
        }
    }
}

extension RecordingController: WKUIDelegate, WKScriptMessageHandler, UIScrollViewDelegate, WKNavigationDelegate {
    // MARK: - webview

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
        logger.debug("======加载完毕")
        if UIScreen.main.bounds.height <= 667 {
            print("屏幕尺寸过小需要变小")
            webView.evaluateJavaScript("adaptIOS12()") { _, err in
                if let err = err {
                    logger.debug("====initLog err:==\(err)")
                }
            }
        }
        for (index, item) in practiceListData.enumerated() {
            practiceListData[index].name = item.name
                .replacingOccurrences(of: "\"", with: "”")
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\'", with: "’")
        }
        let jsonString = practiceListData.toJSONString() ?? ""
        let initLogScript = "initLog('\(jsonString)')"
        logger.debug("初始化log脚本: \(initLogScript)")
        webView.evaluateJavaScript(initLogScript) { _, err in
            if let err = err {
                logger.debug("====initLog err:==\(err)")
            }
        }
        recorderScale()
        print("-=-=-=-=-=-=-WebView 注入成功")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("-=-=-=-=-=-=-进入webkit回调, message: \(message.name)")
        if message.name == "startLocalRecord" {
            if !isEnterBackground {
                isManualRecording = false
                recording()
            } else {
                isManualRecording = true
            }
            UIApplication.shared.isIdleTimerDisabled = true
        }
        if message.name == "consoleLog" {
            print("Consol_logger = \(message.body)")
        }
        if message.name == "startPlayRecord" {
            // 开始播放音频
            EventBus.send(EventBus.PLAY_AUDIO_STOP_METRONOME)
        }
        if message.name == "stopLocalRecord" {
            isFirstRecording = false
            logger.debug("======关闭")
//            mainView.snp.updateConstraints { make in
//                logger.debug("======更改高度")
//
//                make.height.equalTo(430)
//            }
//            RecorderTool.sharedManager.volumeBig()
            stop(isAutoPlay: false)
        }

        if message.name == "cutInLocal" {
            status = 1
            guard let body = message.body as? [String: Any], let data = TKAudioOperating.deserialize(from: body["step"] as? [String: Any]), let duration = body["duration"] as? CGFloat else { return }
            logger.debug("======\(duration)===\(data.toJSONString(prettyPrint: true) ?? "")")
            cutAudio(data: data, duration: duration)
        }
        if message.name == "mergeInLocal" {
            status = 2
            guard let body = message.body as? [String: Any], let data = TKAudioOperating.deserialize(from: body["step"] as? [String: Any]), let duration = body["duration"] as? CGFloat else { return }
            logger.debug("======\(duration)===\(data.toJSONString(prettyPrint: true) ?? "")")
            margeAudio(data: data, duration: duration)
        }

        if message.name == "closePractice" {
            logger.debug("======closePractice")
            if RecorderTool.sharedManager.isRecordering {
                RecorderTool.sharedManager.stopRecord()
            }
            hide()
        }
        if message.name == "readDuaraion" {
            logger.debug("时间====\(message.body)===")
        }

        if message.name == "backToPopup" {
            guard let body = message.body as? [String: Any], let data = [TKAudioModule].deserialize(from: body["data"] as? String) as? [TKAudioModule], let lodId = body["logId"] as? String else { return }
            var totalTime: CGFloat = 0
            var reutrnData: [H5PracticeRecord] = []
            for item in data {
                var d = H5PracticeRecord()
                for j in audios where j.id == item.id {
                    d.path = j.audioPath
                    d.id = item.id
                }
                d.duration = Tools.stringToFloat(str: item.duration)
                reutrnData.append(d)
//                if item.isUpload {
//                }
                totalTime += Tools.stringToFloat(str: item.duration)
            }
            webView.evaluateJavaScript("pauseRecordFromNative()") { _, err in
                if let err = err {
                    logger.debug("======\(err)")
                }
            }
            print("======要开始暂停了")
            if RecorderTool.sharedManager.isRecordering {
                RecorderTool.sharedManager.stopRecord()

            } else {
                let time = (totalTime / 60).roundTo(places: 1)
                TKToast.show(msg: "Good work! You have completed \(time) minutes of practice.")
                confirmAction?(reutrnData, totalTime, lodId, false, self)
            }
        }
        if message.name == "recordDone" {
            guard let body = message.body as? [String: Any], let data = [TKAudioModule].deserialize(from: body["data"] as? String) as? [TKAudioModule], let lodId = body["logId"] as? String else {
                return
            }
            if RecorderTool.sharedManager.isRecordering {
                RecorderTool.sharedManager.stopRecord()
            }
            webView.evaluateJavaScript("pauseRecordFromNative()") { _, err in
                if let err = err {
                    logger.debug("======\(err)")
                }
            }
            var totalTime: CGFloat = 0
            print("\(data.toJSONString(prettyPrint: true) ?? "")")
            var reutrnData: [H5PracticeRecord] = []
            for item in data {
                var d = H5PracticeRecord()
                for j in audios where j.id == item.id {
                    d.path = j.audioPath
                    d.id = item.id
                }
                d.duration = Tools.stringToFloat(str: item.duration)
                reutrnData.append(d)
                totalTime += Tools.stringToFloat(str: item.duration)
            }
            logger.debug("当前audio的时间: \(totalTime)")
            let time = (totalTime / 60).roundTo(places: 1)
            SL.Alert.show(target: self, title: "Good work!", message: "You have completed \(time) minutes of practice.\n\nContinue recording?", leftButttonString: "CONTINUE", rightButtonString: "I'M DONE", leftButtonAction: { [weak self] in
                guard let self = self else { return }
                self.webView.evaluateJavaScript("continueRecordFromNative()") { _, err in
                    if let err = err {
                        logger.debug("======\(err)")
                    }
                }

            }) {
                self.webView.evaluateJavaScript("pauseRecordFromNative()") { _, err in
                    if let err = err {
                        logger.debug("======\(err)")
                    }
                }
                self.confirmAction?(reutrnData, totalTime, lodId, true, self)
            }
        }

        if message.name == "cancelCutOrMerge" {
            print("======点击取消剪裁-此处需要删除刚才剪裁成功的文件==然后调用js方法吧之前的传给js ==\(status)")
            var param: TKCutOrMergeModule!
            if status == 1 {
                param = TKCutOrMergeModule()
                param.type = 0
                param.beforeIndex = "\(cutBeforeAudio.index.description)"
                param.beforeId = cutBeforeAudio.id
                param.beforeBase64 = cutBeforeAudio.base64
                param.beforeDuration = cutBeforeAudio.duration
                param.beforeIsUpload = cutBeforeAudio.isUpload
                print("====\(param.toJSONString(prettyPrint: true) ?? "")")
                webView.evaluateJavaScript("cancelCutOrMerge('\(param.toJSONString() ?? "")')") { _, err in
                    if let err = err {
                        logger.debug("======\(err)")
                    }
                }
                cutAudio = nil
                cutBeforeAudio = nil
            } else if status == 2 {
                param = TKCutOrMergeModule()
                param.type = 1
                param.beforeIndex = "\(margeBeforeAudio.index.description)"
                param.beforeId = margeBeforeAudio.id
                param.beforeBase64 = margeBeforeAudio.base64
                param.beforeDuration = margeBeforeAudio.duration
                param.beforeIsUpload = margeBeforeAudio.isUpload

                param.afterIndex = "\(margeAfterAudio.index.description)"
                param.afterId = margeAfterAudio.id
                param.afterBase64 = margeAfterAudio.base64
                param.afterDuration = margeAfterAudio.duration
                param.afterIsUpload = margeAfterAudio.isUpload
                print("====\(param.toJSONString(prettyPrint: true) ?? "")")
                webView.evaluateJavaScript("cancelCutOrMerge('\(param.toJSONString() ?? "")')") { _, err in
                    if let err = err {
                        logger.debug("======\(err)")
                    }
                }
                margeBeforeAudio = nil
                margeAfterAudio = nil
                margeAudio = nil
            } else {
                webView.evaluateJavaScript("cancelCutOrMerge()") { _, err in
                    if let err = err {
                        logger.debug("======\(err)")
                    }
                }
            }
            status = 0
        }

        if message.name == "saveCutOrMerge" {
            if status == 1 {
                logger.debug("======点击保存剪裁")
//                audios.append(cutAudio)
                audios[cutBeforeAudio.index] = cutAudio
                cutAudio = nil
                cutBeforeAudio = nil
            } else if status == 2 {
                audios.insert(margeAudio, at: margeBeforeAudio.index)
                for item in audios.enumerated().reversed() {
                    if item.element.id == margeAfterAudio.id {
                        audios.remove(at: item.offset)
                    }
                    if item.element.id == margeBeforeAudio.id {
                        audios.remove(at: item.offset)
                    }
                }
                margeBeforeAudio = nil
                margeAfterAudio = nil
                margeAudio = nil
                logger.debug("======点击保存合并\(audios.toJSONString(prettyPrint: true) ?? "")")
            }
            status = 0
        }
        if message.name == "uploadRecordPiece" {
            showUploadPop()
        }
        if message.name == "cancelUploadRecordPiece" {
            showUnUploadPop()
        }
    }

    // 禁止WebView放大
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }

    /// 显示上传提示的弹窗
    private func showUploadPop() {
        SL.Alert.show(target: self, title: "Uploaded", message: "Your recording has been uploaded and shared with your instructor.\nTap again to remove upload. Uploaded recordings can be found under \"Practice\" > \"Log\".", centerButttonString: "OK") {
        }
    }

    /// 显示取消上传的弹窗
    private func showUnUploadPop() {
        SL.Alert.show(target: self, title: "Uploaded", message: "This upload has been removed", centerButttonString: "OK") {
        }
    }
}

// MARK: - Action

extension RecordingController {
}
