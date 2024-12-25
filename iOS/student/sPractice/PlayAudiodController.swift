//
//  PlayAudiodController.swift
//  TuneKey
//
//  Created by wht on 2020/5/28.
//  Copyright © 2020 spelist. All rights reserved.
//

//
//  RecordingController.swift
//  TuneKey
//
//  Created by wht on 2020/5/25.
//  Copyright © 2020 spelist. All rights reserved.
//

import HandyJSON
import UIKit
import WebKit
protocol PlayAudiodControllerDelegate: NSObjectProtocol {
    /// 删除录音
    /// - Parameters:
    ///   - deleteIds: 要删除ids
    ///   - storagePath: 要删除的存储路径
    ///   - index: 上一页选中的第几个item 中的 第几个练习
    func playAudiodController(deleteIndex: [Int], storagePath: [String], indexPath: IndexPath)
}

class PlayAudiodController: TKBaseViewController {
    struct AudioModel: HandyJSON {
        var duration: CGFloat! = 0
        var time: TimeInterval! = 0
        var isDelete: Bool! = false
        var id: String!
    }

    struct AudioModelByReturn: HandyJSON {
        var duration: String! = "0"
        var time: String! = "0"
        var isDelete: Bool! = false
        var id: String!
    }

    private var mainView = UIView()
    private var webView: WKWebView!
    var isEdit = false
    var data: TKPractice!

    /// 上一页选中的第几个item 中的 第几个练习
    var indexPath: IndexPath!
    weak var delegate: PlayAudiodControllerDelegate?
    private var backView = UIView()
    private var url = ""
    private var audioDatas: [AudioModel] = []

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

// MARK: - View

extension PlayAudiodController {
    override func initView() {
        view.backgroundColor = UIColor.clear

        initBackView()
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
    }

    func initBackView() {
        backView.backgroundColor = UIColor.black.withAlphaComponent(0)
        view.addSubview(view: backView) { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-UiUtil.safeAreaBottom())
        }
        backView.isUserInteractionEnabled = true
//        backView.onViewTapped { [weak self] _ in
//            self?.hide()
//        }
    }

    func show() {
        UIView.animate(withDuration: 0.3) {
            self.backView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.mainView.transform = CGAffineTransform.identity
        }
    }

    func hide(completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: 0.3, animations: {
            self.backView.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.mainView.frame.origin = CGPoint(x: 0, y: TKScreen.height + 500)
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
        let fileURL = Bundle.main.url(forResource: "assets/web/play.audio", withExtension: "html")
        webView.loadFileURL(fileURL!, allowingReadAccessTo: Bundle.main.bundleURL)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
    }
}

// MARK: - Data

extension PlayAudiodController {
    override func initData() {
        print("\(data.toJSONString(prettyPrint: true) ?? "")")
        for item in data.recordData.enumerated() {
            var audioData = AudioModel()
            audioData.id = item.element.id
//            if data.recordDurations.count > item.offset {
//                audioData.duration = data.recordDurations[item.offset]
//            }
//            if data.recordTimes.count > item.offset {
//                audioData.time = data.recordTimes[item.offset] * 1000
//            }
            audioData.duration = item.element.duration
            audioData.time = item.element.startTime * 1000
            if audioData.time == 0 {
                logger.debug("添加startTime")
//                audioData.time = Double(data.createTime) ?? data.startTime * 1000
                audioData.time = data.startTime * 1000
            }
            if audioData.duration == 0 {
                audioData.duration = 90.0
            }
            audioDatas.append(audioData)
        }
        logger.debug("当前显示的录音数据: \(audioDatas.toJSONString() ?? "")")
        audioDatas = audioDatas.filterDuplicates { $0.id }
//        getUrl()
    }

    func getUrl(index: Int) {
//        showFullScreenLoading()
        addSubscribe(
            StorageService.shared.getDownloadURL(path: "/practice/\(data.recordData[index].id)\(data.recordData[index].format)")
                .subscribe(onNext: { [weak self] url in
                    guard let self = self else { return }
//                    self.hideFullScreenLoading()
                    print("\(url)")
                    self.webView.evaluateJavaScript("playOnlineAudio('\(url)')") { _, err in
                        if let err = err {
                            logger.debug("======\(err)")
                        }
                    }
                }, onError: { err in
                    self.hideFullScreenLoading()
                    print("\(err)")

                })
        )
    }

    func download(index: Int) {
        let ref = Storage.storage().reference().child("/practice/\(data.recordData[index].id)\(data.recordData[index].format)")

        let path = "\(RecorderTool.sharedManager.composeDir())log-\(data.recordData[index].id)\(data.recordData[index].format)"
        let localURL = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        webView.evaluateJavaScript("percentFromLocal(0)") { _, err in
            if let err = err {
                logger.debug("===1===\(err)")
            }
        }
        print("==是否已经有此文件=\(fileManager.fileExists(atPath: path))")
        if fileManager.fileExists(atPath: path) {
            getFile(format: data.recordData[index].format, url: localURL)
            return
        }

        let downloadTask = ref.write(toFile: localURL) { [weak self] _, err in
            guard let self = self else { return }
            if let err = err {
                print("====下载失败\(err)")
            } else {
                print("=====下载成功")
                self.getFile(format: self.data.recordData[index].format, url: localURL)
            }
        }
        downloadTask.observe(.progress) { snapshot in
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
    }

    private func getFile(format: String, url: URL) {
        let fileData = try! Data(contentsOf: url)
        var format = "x-m4a"
        if format == ".aac" {
            format = "aac"
        }
        var base64 = fileData.base64EncodedString(options: .endLineWithLineFeed)
        base64 = "data:audio/\(format);base64,\(base64)"
        print("完成")
        webView.evaluateJavaScript("percentFromLocal(100)") { _, err in
            if let err = err {
                logger.debug("==2====\(err)")
            }
        }
        webView.evaluateJavaScript("playBase64Audio('\(base64)')") { _, err in
            if let err = err {
                logger.debug("==3====\(err)")
            }
        }
    }
}

// MARK: - webview

extension PlayAudiodController: WKUIDelegate, WKScriptMessageHandler, UIScrollViewDelegate, WKNavigationDelegate {
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
        print("\(audioDatas.toJSONString(prettyPrint: true) ?? "")")
        webView.evaluateJavaScript("initPlayList('\(audioDatas.toJSONString() ?? "")','\(data.name)',\(isEdit))") { _, err in
            if let err = err {
                logger.debug("======\(err)")
            }
        }
        RecorderTool.sharedManager.volumeBig()
        EventBus.send(EventBus.PLAY_AUDIO_STOP_METRONOME)
        logger.debug("======加载完毕")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "closeAudioPage" {
            guard let body = message.body as? [String: Any], let data = [AudioModelByReturn].deserialize(from: body["list"] as? String) as? [AudioModelByReturn] else {
                hide()
                return
            }
            var storagePath: [String] = []
            var indexs: [Int] = []

            for item in data.enumerated() where item.element.isDelete {
//                ids.append(item.id)
                indexs.append(item.offset)
                for j in self.data.recordData.enumerated() where j.element.id == item.element.id {
                    storagePath.append("/practice/\(j.element.id)\(j.element.format)")
                }
            }
            print("=====\(indexs)")
            if indexs.count > 0 {
                delegate?.playAudiodController(deleteIndex: indexs, storagePath: storagePath, indexPath: indexPath)
            }
            hide()
        }
        if message.name == "getAudioUrl" {
            print("2323232323\(message.body)")
//            guard let body = message.body as? [String: String], let id = body["id"] else {
//                return
//            }
//            var index = 0
//            for item in data.recordData.enumerated() where id == item.element.id {
//                index = item.offset
//            }
//            getUrl(index: index)
            guard let body = message.body as? [String: String], let id = body["id"] else {
                return
            }
            var index = 0
            for item in data.recordData.enumerated() where id == item.element.id {
                index = item.offset
            }
            download(index: index)
        }
        if message.name == "startGet" {
            print("\(message.body)")
            guard let body = message.body as? [String: String], let id = body["id"] else {
                return
            }
            var index = 0
            for item in data.recordData.enumerated() where id == item.element.id {
                index = item.offset
            }
            download(index: index)
        }
        if message.name == "consoleLog" {
            print("Consol_logger = \(message.body)")
        }
    }

    // 禁止WebView放大
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

// MARK: - Action

extension PlayAudiodController {
}
