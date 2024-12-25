//
//  StudentAddCardPaymentMethodViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/5/26.
//  Copyright © 2022 spelist. All rights reserved.
//

import SnapKit
import UIKit
import WebKit

class StudentAddCardPaymentMethodViewController: TKBasePopupViewController {
    private var currentContentViewHeight: CGFloat = 200
    override var contentViewHeight: CGFloat { 200 }

    private lazy var url: URL = URL(string: "https://www.tunekey.app/api/stripe/setup?cid=\(self.customer.customerId)&app=true")!

    private lazy var webView: WKWebView = makeWebView()

    @Live var isLoading: Bool = true

    var student: TKStudent
    var customer: TKCustomerAccount
    init(student: TKStudent, customer: TKCustomerAccount) {
        self.student = student
        self.customer = customer
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logger.debug("销毁StudentAddPaymentMethodViewController")
    }
}

extension StudentAddCardPaymentMethodViewController {
    private func makeWebView() -> WKWebView {
        let conf = WKWebViewConfiguration()
        conf.userContentController = WKUserContentController()
        conf.preferences.javaScriptEnabled = true
        conf.selectionGranularity = WKSelectionGranularity.character
        conf.allowsInlineMediaPlayback = true
        // 注册 js 消息通道
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "retrievedSetupIntent")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "back")
        conf.userContentController.add(WeakScriptMessageDelegate(self), name: "updateHeight")
        let webView = WKWebView(frame: .zero, configuration: conf)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20))
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        return webView
    }
}

extension StudentAddCardPaymentMethodViewController {
    override func initView() {
        super.initView()
        webView.addTo(superView: view) { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        LoadingView(CGSize(width: 40, height: 40)).isLoading($isLoading)
            .addTo(superView: view) { make in
                make.center.equalToSuperview()
                make.size.equalTo(40)
            }
    }
}

extension StudentAddCardPaymentMethodViewController: WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        logger.debug("加载完成")
        isLoading = false
        webView.evaluateJavaScript("initPage()")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "retrievedSetupIntent" {
            logger.debug("收到触发刷新")
            EventBus.send(key: .paymentMethodAddComplete)
            dismiss(animated: true)
        } else if message.name == "back" {
            dismiss(animated: true)
        } else if message.name == "updateHeight" {
            logger.debug("监听到高度更改调用: \(message.body)")
            guard let data = message.body as? [String: Any], let height = data["value"] as? Double else {
                logger.error("解析高度信息失败")
                return
            }
            let h = CGFloat(height) + UiUtil.safeAreaBottom()
            if self.currentContentViewHeight != h {
                self.currentContentViewHeight = h
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.updatePopupHeight(to: h)
                }
            }
        }
    }
}
