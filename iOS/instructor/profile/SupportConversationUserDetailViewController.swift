//
//  SupportConversationUserDetailViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/5/28.
//  Copyright © 2021 spelist. All rights reserved.
//

import UIKit
import WebKit

class SupportConversationUserDetailViewController: TKBaseViewController {
    private let navigation: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "")

    private lazy var configuration: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        config.userContentController = WKUserContentController()
        config.preferences.javaScriptEnabled = true
        config.selectionGranularity = WKSelectionGranularity.character
        config.allowsInlineMediaPlayback = true

        config.userContentController.add(WeakScriptMessageDelegate(self), name: "onTermsLinkTapped")
        return config
    }()

    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = ColorUtil.backgroundColor
        webView.isOpaque = false
        webView.uiDelegate = self
        // 禁止顶部下拉 和 底部上拉效果
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        return webView
    }()

    private var userId: String = ""

    private var isLoaded: Bool = false

    convenience init(_ userId: String) {
        self.init(nibName: nil, bundle: nil)
        self.userId = userId
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isLoaded else { return }
        isLoaded = true
        guard let url = URL(string: "https://tunekey.app/d/user/\(userId)") else { return }
        let urlRequest = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 10)
        webView.load(urlRequest)
        showFullScreenLoading()
    }
}

extension SupportConversationUserDetailViewController {
    override func initView() {
        super.initView()
        enablePanToDismiss()
        navigation.updateLayout(target: self)
        webView.addTo(superView: view) { make in
            make.top.equalTo(navigation.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

extension SupportConversationUserDetailViewController: WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        logger.debug("网页数据加载成功")
        webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none';", completionHandler: nil)
        webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none';", completionHandler: nil)
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
    }
}
