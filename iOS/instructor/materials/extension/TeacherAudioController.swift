//
//  TeacherAudioController.swift
//  TuneKey
//
//  Created by wht on 2020/7/31.
//  Copyright © 2020 spelist. All rights reserved.
//

import AVFoundation
import HandyJSON
import IQKeyboardManagerSwift
import UIKit
import WebKit

class TeacherAudioControllerEx {
    static func toRecording(fatherController: UIViewController, isRightButtonConfirm: Bool = false, confirmAction: @escaping (_ title: String, _ path: String, _ totalTime: CGFloat, _ id: String, _ recordController: TeacherAudioController?) -> Void) {
        AVAudioSession.authorizeToMicrophone { isSuccess in
            if isSuccess {
                let controller = TeacherAudioController()
                controller.modalPresentationStyle = .custom
                controller.confirmAction = confirmAction
                controller.fatherController = fatherController
                controller.isRightButtonConfirm = isRightButtonConfirm
                fatherController.present(controller, animated: false) {
                }

            } else {
//                TKToast.show(msg: "To ecord audio please enable Permission in settings.", style: .warning)
                SL.Alert.show(target: fatherController, title: "Permission Denined", message: "Please enable permission to record in settings", centerButttonString: "OK") {
                }
            }
        }
    }
}

class TeacherAudioController: TKBaseViewController {
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

    var volumeList: [Float] = []
    // 开始录音 但是没有声音的 1秒钟10个 结束录音后自动剪裁
    var beforeRecordingVolumeList: [Float] = []
    // 是否要开始录音
    var isNeedStartRecoding = false

    var confirmAction: ((_ title: String, _ path: String, _ totalTime: CGFloat, _ id: String, _ recordController: TeacherAudioController?) -> Void)?

    // 0正常,1剪裁,2合并,3正在剪辑或者正在合并中还未选择
    var status: Int = 0
    private var backView = UIView()
    private var isEnterBackground = false
    // 是否要手动调用录音
    private var isManualRecording = false
    private var isFirstRecording = true

    var isRightButtonConfirm: Bool = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        print("======")
        show()
        webView.hack_removeInputAccessory()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override func onKeyboardShow(_ keyboardHeight: CGFloat) {
        super.onKeyboardShow(keyboardHeight)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.mainView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
        }, completion: nil)
    }

    override func onKeyboardHide(_ keyboardHeight: CGFloat) {
        super.onKeyboardHide(keyboardHeight)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.mainView.transform = .identity
        }, completion: nil)
    }
}

// MARK: - View

extension TeacherAudioController {
    override func initView() {
        print("==========")
        initData()
        initBackView()
        view.backgroundColor = UIColor.clear
        view.addSubview(mainView)

        mainView.snp.makeConstraints { make in
            make.height.equalTo(280 + UiUtil.safeAreaBottom())
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalToSuperview()
        }
        mainView.backgroundColor = UIColor.white
        mainView.setTopRadius()
        mainView.transform = CGAffineTransform(translationX: 0, y: 280)

        initWebView()
    }

    func initBackView() {
        backView.backgroundColor = UIColor.black.withAlphaComponent(0)
        view.addSubview(view: backView) { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-UiUtil.safeAreaBottom())
        }
        backView.isUserInteractionEnabled = true
    }

    func show() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.backView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.mainView.transform = CGAffineTransform.identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            if self.isRightButtonConfirm {
                self.webView?.evaluateJavaScript("setRightButton('CONFIRM', true)")
            }
        }
    }

    func hide(completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: 0.2, animations: {
            self.backView.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.mainView.frame.origin = CGPoint(x: 0, y: TKScreen.height)
        }) { _ in
            self.dismiss(animated: false, completion: {
                completion()
            })
        }
    }

    func initWebView() {
        mainView.backgroundColor = ColorUtil.backgroundColor
        webView = WKWebView()
        mainView.addSubview(view: webView) { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(280)
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
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "closeAudioRecord")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "stopRecordAudio")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "uploadAudio")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "goBack")

        webView = WKWebView(frame: .zero, configuration: conf) // .zero
        webView.backgroundColor = ColorUtil.backgroundColor
        webView.isOpaque = false
        mainView.addSubview(view: webView) { make in
            make.edges.equalToSuperview()
        }
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        webView.uiDelegate = self
        // 禁止顶部下拉 和 底部上拉效果
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.delegate = self
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        let fileURL = Bundle.main.url(forResource: "assets/web/record.audio", withExtension: "html")
        webView.loadFileURL(fileURL!, allowingReadAccessTo: Bundle.main.bundleURL)
    }
}

// MARK: - Data

extension TeacherAudioController {
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
                    print("======\(data.beforeIndex!)===\(duration)===\(id)")
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

extension TeacherAudioController {
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
                    if self.audios.count == 2 {
                        self.continueToMergeAudio()
                        return
                    }
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
        print("\(RecorderTool.sharedManager.aacPath!)====暂停的Id:\(id)")
        audios[audios.count - 1].base64 = data
        if audios.count == 2 {
            continueToMergeAudio()
            return
        }
        webView.evaluateJavaScript("listenStopRecord('\(data)','\(id)','\(isAutoPlay)')") { [weak self] _, err in
            guard let self = self else { return }
            if let err = err {
                logger.debug("======\(err)")
            } else {
                self.volumeList.removeAll()
            }
        }
    }

    /// 继续后合并音频
    func continueToMergeAudio() {
        print("开始合并")
        let id = "\(IDUtil.nextId(group: .audio)!)"
        //        margeAudio(data: data, duration: duration)
        let beforePath = audios[0].audioPath!
        let afterPath = audios[1].audioPath!

        RecorderTool.sharedManager.audioMerge(outId: id, audioFileUrls: [beforePath, afterPath]) { [weak self] isSuccess, path in
            guard let self = self else { return }
            if isSuccess {
                print("合并成功")
                let fileData = try! Data(contentsOf: URL(fileURLWithPath: path))
                var base64 = fileData.base64EncodedString(options: .endLineWithLineFeed)
                base64 = "data:audio/x-m4a;base64,\(base64)"
                let data = TKAudioModule(id: id, audioPath: path, index: 0, duration: "", base64: base64, isUpload: true)
                self.audios.removeAll()
                self.audios.append(data)
                OperationQueue.main.addOperation {
                    self.webView.evaluateJavaScript("listenStopRecord('\(base64)','\(id)','\(true)')") { [weak self] _, err in
                        guard let self = self else { return }
                        if let err = err {
                            logger.debug("======\(err)")
                        } else {
                            self.volumeList.removeAll()
                        }
                    }
                }
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

extension TeacherAudioController: WKUIDelegate, WKScriptMessageHandler, UIScrollViewDelegate, WKNavigationDelegate {
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
        webView.evaluateJavaScript("setDefaultTitle('Audio \(CacheUtil.materials.audioCount() + 1)')") { _, err in
            if let err = err {
                logger.debug("======\(err)")
            }
        }

        recorderScale()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        logger.debug("接受到消息: \(message.name)")
        if message.name == "startLocalRecord" {
            if !isEnterBackground {
                isManualRecording = false
                recording()
            } else {
                isManualRecording = true
            }
            UIApplication.shared.isIdleTimerDisabled = true
        }
        if message.name == "stopLocalRecord" {
            logger.debug("======关闭")
            //            mainView.snp.updateConstraints { make in
            //                logger.debug("======更改高度")
            //
            //                make.height.equalTo(350)
            //            }
            //            RecorderTool.sharedManager.volumeBig()
            isFirstRecording = false

            stop(isAutoPlay: false)
        }
        if message.name == "consoleLog" {
            print("Consol_logger = \(message.body)")
        }
        if message.name == "closeAudioRecord" {
            RecorderTool.sharedManager.stopRecord()
            hide()
        }
        if message.name == "startPlayRecord" {
            // 开始播放音频
            EventBus.send(EventBus.PLAY_AUDIO_STOP_METRONOME)
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

        if message.name == "uploadAudio" {
//            logger.debug("===\(message.body)===")
            guard let body = message.body as? [String: Any], let data = TKAudioModule.deserialize(from: body["data"] as? String), let title = body["title"] as? String else {
                logger.debug("消息不全")
                return
            }
            let path = audios[0].audioPath
            let totalTime: CGFloat = Tools.stringToFloat(str: data.duration)
            hide {
                self.confirmAction?(title, path!, totalTime, data.id, self)
            }
//            hide {}
        }
        if message.name == "stopRecordAudio" {
            SL.Animator.run(time: 0.3) { [weak self] in
                self?.mainView.snp.updateConstraints { make in
                    make.height.equalTo(350)
                }
                self?.view.layoutIfNeeded()
            }
        }
        if message.name == "goBack" {
            SL.Animator.run(time: 0.3) { [weak self] in
                self?.mainView.snp.updateConstraints { make in
                    make.height.equalTo(280)
                }
                self?.view.layoutIfNeeded()
            }
        }

//        if message.name == "backToPopup" {
//            guard let body = message.body as? [String: Any], let data = [TKAudioModule].deserialize(from: body["data"] as? [Any]) as? [TKAudioModule], let lodId = body["logId"] as? String else { return }
//            var path = ""
//            var totalTime: CGFloat = 0
//            var id = ""
//            for item in data {
//                if item.isUpload {
//                    for j in audios where j.id == item.id {
//                        path = j.audioPath
//                        id = item.id
//                    }
//                }
//                totalTime += Tools.stringToFloat(str: item.duration)
//            }
//            confirmAction?(path, totalTime, id, lodId, false, self)
//            webView.evaluateJavaScript("pauseRecordFromNative()") { _, err in
//                if let err = err {
//                    logger.debug("======\(err)")
//                }
//            }
//        }
//        if message.name == "recordDone" {
//            guard let body = message.body as? [String: Any], let data = [TKAudioModule].deserialize(from: body["data"] as? [Any]) as? [TKAudioModule], let lodId = body["logId"] as? String else { return }
//            var path = ""
//            var totalTime: CGFloat = 0
//            var id = ""
//            for item in data {
//                if item.isUpload {
//                    for j in audios where j.id == item.id {
//                        path = j.audioPath
//                        id = item.id
//                    }
//                }
//                print("是否上传=====\(item.isUpload)")
//
//                totalTime += Tools.stringToFloat(str: item.duration)
//            }
//            webView.evaluateJavaScript("pauseRecordFromNative()") { [weak self] _, err in
//                guard let self = self else { return }
//                if let err = err {
//                    logger.debug("======\(err)")
//                }
//            }
//
//            confirmAction?(path, totalTime, id, lodId, true, self)
        ////            hide {
        ////            }
//        }

        if message.name == "cancelCutOrMerge" {
            logger.debug("======点击取消剪裁-此处需要删除刚才剪裁成功的文件==然后调用js方法吧之前的传给js ==\(status)")
            if status == 1 {
                guard audios.count > 0 else { return }
                var param = TKTeacherCutOrMergeModule()
                param.id = audios[0].id
                param.base64 = audios[0].base64
                param.duration = audios[0].duration

                print("====\(param.toJSONString(prettyPrint: true) ?? "")")
                webView.evaluateJavaScript("cancelCutOrMerge('\(param.toJSONString() ?? "")')") { _, err in
                    if let err = err {
                        logger.debug("======\(err)")
                    }
                }
                cutAudio = nil
                cutBeforeAudio = nil
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
    }

    // 禁止WebView放大
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

// MARK: - Action

extension TeacherAudioController {
}

fileprivate final class InputAccessoryHackHelper: NSObject {
    @objc var inputAccessoryView: AnyObject? { return nil }
}

extension WKWebView {
    func hack_removeInputAccessory() {
        print("s")
        guard let target = scrollView.subviews.first(where: {
            String(describing: type(of: $0)).hasPrefix("WKContent")
        }), let superclass = target.superclass else {
            return
        }

        let noInputAccessoryViewClassName = "\(superclass)_NoInputAccessoryView"
        var newClass: AnyClass? = NSClassFromString(noInputAccessoryViewClassName)

        if newClass == nil, let targetClass = object_getClass(target), let classNameCString = noInputAccessoryViewClassName.cString(using: .ascii) {
            newClass = objc_allocateClassPair(targetClass, classNameCString, 0)

            if let newClass = newClass {
                objc_registerClassPair(newClass)
            }
        }

        guard let noInputAccessoryClass = newClass, let originalMethod = class_getInstanceMethod(InputAccessoryHackHelper.self, #selector(getter: InputAccessoryHackHelper.inputAccessoryView)) else {
            return
        }
        class_addMethod(noInputAccessoryClass.self, #selector(getter: InputAccessoryHackHelper.inputAccessoryView), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        object_setClass(target, noInputAccessoryClass)
    }
}
