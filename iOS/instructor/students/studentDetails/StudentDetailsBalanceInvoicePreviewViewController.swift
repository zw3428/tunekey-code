//
//  StudentDetailsBalanceInvoicePreviewViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/3/8.
//  Copyright © 2022 spelist. All rights reserved.
//

import SnapKit
import UIKit
import WebKit

class StudentDetailsBalanceInvoicePreviewViewController: TKBaseViewController {
    var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Preview")
    lazy var webView = makeWebView()
    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(frame: CGRect(x: CGFloat(0), y: 0, width: UIScreen.main.bounds.width, height: 2))
        progressView.tintColor = ColorUtil.main
        progressView.trackTintColor = ColorUtil.backgroundColor
        return progressView
    }()

    var invoice: TKInvoice
    var studio: TKStudio
    var teacher: TKTeacher
    init(invoice: TKInvoice, studio: TKStudio, teacher: TKTeacher) {
        self.invoice = invoice
        self.studio = studio
        self.teacher = teacher
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StudentDetailsBalanceInvoicePreviewViewController {
    private func makeWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController = WKUserContentController()
        config.preferences.javaScriptEnabled = true
        config.selectionGranularity = WKSelectionGranularity.character
        config.allowsInlineMediaPlayback = true
        config.userContentController.add(WeakScriptMessageDelegate(self), name: "invoiceReady")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = ColorUtil.backgroundColor
        webView.isOpaque = false
        webView.uiDelegate = self
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        // 禁止顶部下拉 和 底部上拉效果
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        // 监听加载进度
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        return webView
    }
}

extension StudentDetailsBalanceInvoicePreviewViewController {
    override func initView() {
        super.initView()
        navigationBar.updateLayout(target: self)
        progressView.addTo(superView: webView) { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(2)
        }
        webView.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        if let url = URL(string: "https://tunekey.app/invoice/preview") {
            webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30))
        }
    }
}

extension StudentDetailsBalanceInvoicePreviewViewController: WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.alpha = 1.0
            logger.debug("网页加载进度: \(webView.estimatedProgress)")
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
            if webView.estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.2) {
                    self.progressView.alpha = 0
                } completion: { _ in
                    self.progressView.setProgress(0.0, animated: false)
                }
            }
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "invoiceReady" {
            logger.debug("收到invoiceReady消息")
            webView.evaluateJavaScript("getDevice(true)", completionHandler: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                let invoice = self.invoice.toJSONString() ?? ""
                let teacherInfo = self.teacher.toJSONString() ?? ""
                let studioInfo = self.studio.toJSONString() ?? ""
                let script = "getManualInvoiceData(\(invoice), \(studioInfo), \(teacherInfo))"
                logger.debug("当前的执行脚本: \(script)")
                self.webView.evaluateJavaScript(script) { _, error in
                    if let error = error {
                        logger.error("调用设置invoice失败: \(error)")
                    }
                }
            }
        }
    }
}
