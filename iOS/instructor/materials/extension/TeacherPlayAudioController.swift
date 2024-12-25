//
//  TeacherPlayAudioController.swift
//  TuneKey
//
//  Created by wht on 2020/8/4.
//  Copyright © 2020 spelist. All rights reserved.
//

import Alamofire
import AVFoundation
import FirebaseStorage
import HandyJSON
import RxSwift
import SnapKit
import UIKit
import WebKit

class TeacherPlayAudioController: TKBaseViewController {
    enum From {
        case material
        case practice
    }

    var from: From = .material

    private var mainView = UIView()
    private var webView: WKWebView!
    var materialData: TKMaterial!
    var practice: TKPractice?
    var recordData: PracticeRecord?
    var url = ""
    var name = ""

    var playerItem: AVPlayerItem?
    var player: AVPlayer?
    
    var rate: Float = 1
    @Live var speed: String = "100%"

    @Live var isSpeedBarShow: Bool = false
    
    @Live var isShow: Bool = false
    
    private var isPlaying: Bool = false
    
    private var isPlayEnded: Bool = false
    
    private lazy var speedBarLabel: Label = Label($speed).textColor(.primary)
        .font(.content)
    private var speedRanges: [Double] = [0.5, 1, 1.5, 2.0, 2.5, 3.0]
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        runOnce { [weak self] in
            self?.show()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

extension TeacherPlayAudioController {
    @objc func onSliderChanged(_ slider: UISlider) {
        guard playerItem?.canPlayFastForward ?? false else { return }
        let value = slider.value
        rate = value
        updateSpeedBarLabel(value, slider: slider)
        let script = "setSpeed(\(value))"
        logger.debug("设置变速脚本: \(script)")
        webView.evaluateJavaScript(script)
        pause()
    }

    @objc func onSliderTouchEnded(_ slider: UISlider) {
        logger.debug("取消滑动: \(slider.value)")
        let range: Double = 0.02
        let value = Double(slider.value)
        let closestValue = speedRanges.min(by: { abs($0 - value) < abs($1 - value) })!
        // 检查是否在给定的范围内（正负0.2）
        if abs(value - closestValue) <= range {
            // 如果是，就将滑块的值设置为最接近的值
            slider.setValue(Float(closestValue), animated: true)
            updateSpeedBarLabel(Float(closestValue), slider: slider)
        }
        
        let script = "setSpeed(\(value))"
        logger.debug("设置变速脚本: \(script)")
        webView.evaluateJavaScript(script)
        rate = slider.value
        play()
    }
    
    private func updateSpeedBarLabel(_ value: Float, slider: UISlider) {
        speed = "\(Int(round(value * 100)))%"
        let centerX = (Double(value) - 0.5) / 2.5
        let width = UIScreen.main.bounds.width - 82
        speedBarLabel.snp.updateConstraints { make in
            make.centerX.equalTo(slider.snp.leading).offset(CGFloat(centerX) * width)
        }
        if speedRanges.contains(where: { $0 == Double(value) }) {
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.prepare()
            feedback.impactOccurred()
        }
    }
}

// MARK: - View

extension TeacherPlayAudioController {
    override func initView() {
        view.backgroundColor = UIColor.clear

        view.addSubview(mainView)

        mainView.snp.makeConstraints { make in
            make.height.equalTo(250)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalToSuperview()
        }
        mainView.backgroundColor = UIColor.white
        mainView.setTopRadius()
        mainView.transform = CGAffineTransform(translationX: 0, y: 250)
        initWebView()

        ViewBox(top: 0, left: 20, bottom: 0, right: 20) {
            ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                VStack(spacing: 40) {
                    Label("Speed").textColor(.tertiary)
                        .font(.cardTitle)
                    Slider().minimumValue(0.5)
                        .maximumValue(3)
                        .value(1)
                        .thumbTintColor(.clickable)
                        .minimumTrackTintColor(UIColor(hex: "#E6EFEC"))
                        .maximumTrackTintColor(UIColor(hex: "#E6EFEC"))
                        .height(24)
                        .apply { [weak self] slider in
                            guard let self = self else { return }
                            speedBarLabel.addTo(superView: slider) { make in
                                make.centerX.equalTo(slider.snp.leading).offset(0)
                                make.bottom.equalTo(slider.snp.top).offset(-10)
                            }
                            slider.addTarget(self, action: #selector(self.onSliderChanged(_:)), for: .valueChanged)
                            slider.addTarget(self, action: #selector(self.onSliderTouchEnded(_:)), for: [.touchUpInside, .touchUpOutside])
                            for subview in slider.subviews where type(of: subview).description() == "_UISlideriOSVisualElement" {
                                logger.debug("子view: \(type(of: subview))")
                            }
                            guard let superView = slider.subviews.first(where: { type(of: $0).description() == "_UISlideriOSVisualElement" }) else { return }
                            let width = UIScreen.main.bounds.width - 82
                            
                            for value in self.speedRanges {
                                logger.debug("设置原点: \(value)")
                                let dot = UIView()
                                dot.backgroundColor = UIColor(hex: "#E6EFEC")
                                dot.layer.cornerRadius = 5 // 圆点的半径
                                dot.translatesAutoresizingMaskIntoConstraints = false
                                superView.addSubview(dot)

                                // 计算圆点在滑块上的位置
                                let dotCenterX = (Double(value) - 0.5) / 2.5
                                var offsetX = CGFloat(dotCenterX) * width
                                if dotCenterX == 0 {
                                    offsetX += 6
                                }
                                if dotCenterX == 1 {
                                    offsetX -= 3
                                }
                                dot.snp.makeConstraints { make in
                                    make.centerX.equalTo(slider.snp.leading).offset(offsetX)
                                    make.centerY.equalToSuperview().offset(1)
                                    make.width.height.equalTo(10)
                                }
                                superView.bringSubviewToFront(dot)
                            }

                            if let imageView = superView.subviews.first(where: { type(of: $0).description() == "UISliderImageView" }) {
                                superView.bringSubviewToFront(imageView)
                            }
                            
                            self.updateSpeedBarLabel(1, slider: slider)
                        }
                }
            }
            .backgroundColor(.white)
            .cornerRadius(10)
        }
        .addTo(superView: view) { make in
            make.bottom.equalTo(mainView.snp.top).offset(-20)
            make.left.right.equalToSuperview()
        }
        .apply { [weak self] view in
            guard let self = self else { return }
            self.$isSpeedBarShow.addSubscriber { isShow in
                UIView.animate(withDuration: 0.2) {
                    if isShow {
                        view.transform = .identity
                    } else {
                        view.transform = CGAffineTransform.init(translationX: 0, y: UIScreen.main.bounds.height)
                    }
                }
            }
            self.view.sendSubviewToBack(view)
        }
        
        
        Label().textColor(.clickable)
            .font(.tagContent)
            .isShow($isShow)
            .apply { [weak self] label in
                guard let self = self else { return }
                self.$speed.addSubscriber { speed in
                    label.text = "Speed:\(speed)"
                }
            }
            .addTo(superView: mainView) { make in
                make.top.equalToSuperview().offset(70)
                make.right.equalToSuperview().offset(-10)
            }
            .onViewTapped { [weak self] _ in
                guard let self = self else { return }
                self.isSpeedBarShow.toggle()
            }
    }

    func initWebView() {
        mainView.backgroundColor = ColorUtil.backgroundColor
        webView = WKWebView()
        mainView.addSubview(view: webView) { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(250)
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
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "closeAudioPage")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "getAudioUrl")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "consoleLog")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "play")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "pause")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "setSpeed")

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
        let fileURL = Bundle.main.url(forResource: "assets/web/teacher.play.audio", withExtension: "html")
        webView.loadFileURL(fileURL!, allowingReadAccessTo: Bundle.main.bundleURL)
    }

    func show() {
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.mainView.transform = CGAffineTransform.identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.isShow = true
        }
    }

    func hide(completion: @escaping () -> Void = {}) {
        isSpeedBarShow = false
        UIView.animate(withDuration: 0.3, animations: {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.mainView.frame.origin = CGPoint(x: 0, y: TKScreen.height)
        }) { _ in
            self.dismiss(animated: false, completion: {
            })
        }
    }
}

// MARK: - webview

extension TeacherPlayAudioController: WKUIDelegate, WKScriptMessageHandler, UIScrollViewDelegate, WKNavigationDelegate {
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
//        print("url:\(url)\nname:\(name)")
//        webView.evaluateJavaScript("playOnlineAudio('\(url)','\(name)')") { _, err in
//            if let err = err {
//                logger.debug("======\(err)")
//            }
//        }
        RecorderTool.sharedManager.volumeBig()
        EventBus.send(EventBus.PLAY_AUDIO_STOP_METRONOME)
        logger.debug("======加载完毕")
        download()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "closeAudioPage" {
            hide()
        } else if message.name == "consoleLog" {
            print("Consol_logger = \(message.body)")
        } else if message.name == "play" {
            logger.debug("点击播放: \(message.body)")
            guard let data = message.body as? [String: TimeInterval] else { return }
            guard let currentTime = data["currentTime"] else { return }
            let targetTime: CMTime = CMTime(seconds: currentTime, preferredTimescale: 1000000)
            logger.debug("当前时间: \(currentTime) | 目标时间: \(targetTime)")
            player?.seek(to: targetTime)
            player?.play()
            isPlaying = true
        } else if message.name == "pause" {
            guard let data = message.body as? [String: TimeInterval] else { return }
            guard let currentTime = data["currentTime"] else { return }
            let targetTime: CMTime = CMTime(seconds: currentTime, preferredTimescale: 1000000)
            logger.debug("点击暂停: \(message.body)")
            player?.seek(to: targetTime)
            player?.pause()
            isPlaying = false
            guard let time = player?.currentTime(), let duration = playerItem?.duration else { return }
            let secondsOfTotal = CMTimeGetSeconds(duration)
            let secondsOfCurrent = CMTimeGetSeconds(time)
            logger.debug("总时间: \(secondsOfTotal) | 当前时间: \(secondsOfCurrent)")
            if secondsOfTotal - secondsOfCurrent < 0.5 {
                isPlayEnded = true
            }
        } else if message.name == "setSpeed" {
            logger.debug("调用设置变速")
            isSpeedBarShow = true
        }
    }

    // 禁止WebView放大
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

// MARK: - Data

extension TeacherPlayAudioController {
    override func initData() {
    }

    func download() {
        switch from {
        case .material:
            downloadMaterials()
        case .practice:
            downloadPractice()
        }
    }

    private func downloadPractice() {
        guard from == .practice, let recordData = recordData else { return }
        let path = "\(RecorderTool.sharedManager.composeDir())log-\(recordData.id)\(recordData.format)"
        let localURL = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            getFile(format: recordData.format, url: localURL)
            return
        }
        guard recordData.upload else {
            TKToast.show(msg: "This practice record haven't upload yet.", style: .error)
            return
        }
        // 本地不存在,进行下载
        webView.evaluateJavaScript("percentFromLocal(0)") { _, err in
            if let err = err {
                logger.debug("===1===\(err)")
            }
        }
        StorageService.shared.downloadFile(path: "/practice/\(recordData.id)\(recordData.format)", saveTo: path) { [weak self] progress, _ in
            guard let self = self else { return }
            self.webView.evaluateJavaScript("percentFromLocal(\(progress))") { _, _ in
            }

        } completion: { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                TKToast.show(msg: "Download file failed, please try again later.", style: .error)
                logger.error("下载音频失败 => \(path): \(error)")
            } else {
                self.getFile(format: recordData.format, url: localURL)
            }
        }
    }

    private func downloadMaterials() {
        let path = "\(RecorderTool.sharedManager.composeDir())log-\(materialData.id).\(materialData.suffixName)"
        logger.debug("下载到本地文件，地址为: \(path) ｜ 原始地址： \(materialData.url)")
        let localURL = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            getFile(format: materialData.suffixName, url: localURL)
            return
        }
        // 判断是否是firestorage
        if materialData.url.contains("firebasestorage") {
//            let storagePath = "/materials/\(materialData.creatorId)/\(materialData.id).\(materialData.suffixName)"
            let storagePath = materialData.storagePatch
            let ref = Storage.storage().reference().child(storagePath)
            print("==是否已经有此文件=\(fileManager.fileExists(atPath: path))")
            webView.evaluateJavaScript("percentFromLocal(0)") { _, err in
                if let err = err {
                    logger.debug("===1===\(err)")
                }
            }
            let downloadTask = ref.write(toFile: localURL) { [weak self] _, err in
                guard let self = self else { return }
                if let err = err {
                    print("====下载失败\(err)")
                } else {
                    print("=====下载成功")
                    self.getFile(format: self.materialData.suffixName, url: localURL)
                }
            }
            downloadTask.observe(.progress) { [weak self] snapshot in
                guard let self = self else { return }
                // A progress event occurred
                let progress = Int(snapshot.progress!.fractionCompleted * 100)
                if progress > 0 && progress < 100 {
                    print(progress)
                    self.webView.evaluateJavaScript("percentFromLocal(\(progress))") { _, err in
                        if let err = err {
                            logger.debug("==??=\(progress)===\(err)")
                        }
                    }
                }
            }
        } else {
            // 直接下载，使用AF
            UserService.user.getGoogleAuthToken(type: .drive)
                .done { [weak self] token in
                    guard let self = self else { return }
                    if let token = token {
                        let destination: DownloadRequest.Destination = { _, _ in
                            (localURL, [.removePreviousFile, .createIntermediateDirectories])
                        }
                        self.webView.evaluateJavaScript("percentFromLocal(0)") { _, err in
                            if let err = err {
                                logger.debug("===1===\(err)")
                            }
                        }
                        AF.download(self.materialData.url, headers: ["Authorization": "Bearer \(token.accessToken)"], to: destination)
                            .downloadProgress { progress in
                                let p = (progress.completedUnitCount / progress.totalUnitCount) * 100
                                logger.debug("下载进度： \(progress.completedUnitCount) | \(progress.totalUnitCount) | \(String(describing: progress.fileCompletedCount)) | \(progress.fileTotalCount)")
                                self.webView.evaluateJavaScript("percentFromLocal(\(p))") { _, err in
                                    if let err = err {
                                        logger.debug("==??=\(progress)===\(err)")
                                    }
                                }
                            }
                            .response { res in
                                if let error = res.error {
                                    logger.error("下载失败： \(error)")
                                } else {
                                    logger.debug("下载完成")
                                    self.getFile(format: self.materialData.suffixName, url: localURL)
                                }
                            }
                    }
                }
                .catch { _ in
                }
        }
    }

    private func getFile(format: String, url: URL) {
        let fileData = try! Data(contentsOf: url)
        var format = "x-m4a"
        if format == ".aac" {
            format = "aac"
        }
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem!)
        var base64 = fileData.base64EncodedString(options: .endLineWithLineFeed)
        base64 = "data:audio/\(format);base64,\(base64)"
        print("完成")
        webView.evaluateJavaScript("percentFromLocal(100)") { _, err in
            if let err = err {
                logger.debug("==2====\(err)")
            }
        }
        var name: String
        switch from {
        case .material:
            name = materialData.name
        case .practice:
            name = (practice?.name ?? "")
        }
        name = name.data(using: .utf8)?.base64EncodedString(options: .endLineWithLineFeed) ?? ""
        name = name
            .replacingOccurrences(of: "\"", with: "”")
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\'", with: "’")
        let script = "playBase64Audio('\(base64)','\(name)')"
        webView.evaluateJavaScript(script) { _, err in
            if let err = err {
                logger.debug("==3====\(err)")
            }
        }
        // 注册通知，监听播放结束事件
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem // 传入播放项作为对象参数
        )
    }
    
    

    // 实现播放结束时的回调方法
    @objc func playerDidFinishPlaying(note: NSNotification) {
        logger.debug("播放结束")
        isPlayEnded = true
    }
    
    func play() {
        guard let time = playerItem?.currentTime() else { return }
        webView.evaluateJavaScript("playAfterPause()")
        isPlaying = true
        if isPlayEnded {
            player?.seek(to: .zero)
        }
        player?.play()
        player?.rate = rate
        logger.debug("当前的rate: \(player?.rate) | 实际rate: \(rate)")
    }
    
    func pause() {
        guard isPlaying else { return }
        player?.pause()
        isPlaying = false
        webView.evaluateJavaScript("pauseAudio()")
    }
}
