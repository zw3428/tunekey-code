//
//  ProfileAboutUsTermsOfUseViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/10/9.
//  Copyright © 2019 spelist. All rights reserved.
//

import UIKit
import WebKit
class ProfileAboutUsTermsOfUseViewController: TKBaseViewController {
    private var mainView = UIView()
    private var webView: WKWebView!
    var pos = 0
}

// MARK: - View

extension ProfileAboutUsTermsOfUseViewController {
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
    }

    func initWebView() {
        let conf = WKWebViewConfiguration()
        conf.userContentController = WKUserContentController()
        conf.preferences.javaScriptEnabled = true
        conf.selectionGranularity = WKSelectionGranularity.character
        conf.allowsInlineMediaPlayback = true
        
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "onTermsLinkTapped")

        webView = WKWebView(frame: .zero, configuration: conf) // .zero
        webView.backgroundColor = ColorUtil.backgroundColor
        webView.isOpaque = false
        mainView.addSubview(view: webView) { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        webView.uiDelegate = self
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        // 禁止顶部下拉 和 底部上拉效果
        webView.scrollView.bounces = false
        webView.scrollView.delegate = self
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        var url = URL(string: "https://tunekey.app/terms/mobile")
        if pos == 1 {
            url = URL(string: "https://tunekey.app/policy/mobile")
        }
        // 根据url创建请求
        let urlRequest = URLRequest(url: url!, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 10)
        webView.load(urlRequest)
        showFullScreenLoading()
    }
}

extension ProfileAboutUsTermsOfUseViewController: WKUIDelegate, UIScrollViewDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        logger.debug("网页数据加载成功")
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
        hideFullScreenLoading()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        logger.debug("监听消息: \(message.name) | \(message.body)")
        if message.name == "onTermsLinkTapped" {
            guard let data = message.body as? [String: String], let _url = data["value"] else { return }
            guard let url = URL(string: _url) else { return }
            guard UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.open(url, options: [:]) { _ in
            }
        }
    }

    // 禁止WebView放大
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.decelerationRate = UIScrollView.DecelerationRate.normal
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
    }
}

// MARK: - Data

extension ProfileAboutUsTermsOfUseViewController {
    override func initData() {
    }
}

// MARK: - TableView

extension ProfileAboutUsTermsOfUseViewController {
}

// MARK: - Action

extension ProfileAboutUsTermsOfUseViewController {
}
