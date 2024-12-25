//
//  YoutubePlayerViewController.swift
//  TuneKey
//
//  Created by Wht on 2019/9/4.
//  Copyright © 2019年 spelist. All rights reserved.
//

import NVActivityIndicatorView
import UIKit
import YoutubePlayer_in_WKWebView
import youtube_ios_player_helper


class YoutubePlayerViewController: UIViewController {
    var onViewLoadFailed: (() -> Void)? = nil
    var mainView = UIView()
//    var playerView: WKYTPlayerView!
    var playerView: YTPlayerView = YTPlayerView()
    var materialsData: TKMaterial!
    var returnView = TKView()
    var returnImgView = UIImageView()
    var placeholderImgView = UIImageView()
    var placeholderCoverView = View().backgroundColor(.black)
    var loadingIndicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))

    func enablePanToDismiss() {
        if hero.isEnabled {
            let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleScreenEdgePan(_:)))
            gesture.edges = .left
            view.addGestureRecognizer(gesture)
        }
    }

    @objc private func handleScreenEdgePan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            dismiss(animated: true, completion: nil)
        case .changed:
            let progress = sender.translation(in: nil).x / view.bounds.width
            Hero.shared.update(progress)
        default:
            if (sender.translation(in: nil).x + sender.velocity(in: nil).x) / view.bounds.width > 0.5 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        statusBarStyle = .default
    }

    var statusBarStyle: UIStatusBarStyle = .lightContent

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

    var isStatusBarHidden = false {
        didSet {
        }
    }

    override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }

    private var isPlayInited: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        statusBarStyle = .lightContent
        guard !isPlayInited else { return }
        isPlayInited = true
        if let id = Tools.extractYouTubeId(from: materialsData.url) {
            logger.debug("准备开始播放youtube video: \(id)")
            playerView.load(withVideoId: id)
        } else if let id = Tools.extractYouTubePlaylistId(from: materialsData.url) {
            logger.debug("准备播放playlist: \(id)")
            playerView.load(withPlaylistId: id)
        } else {
            logger.debug("提取id失败,准备返回并跳转浏览器播放")
            dismiss(animated: true) { [weak self] in
                self?.onViewLoadFailed?()
            }
        }
    }
}

// MARK: - View

extension YoutubePlayerViewController {
    func initView() {
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidExitFullScreen), name: UIWindow.didBecomeHiddenNotification, object: nil)
        view.backgroundColor = UIColor.black
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = UIColor.black
        mainView.addSubview(returnView)

        returnView.layer.cornerRadius = 10
//        returnView.backgroundColor = UIColor(red: 17 / 255, green: 17 / 255, blue: 17 / 255, alpha: 1)
        returnView.backgroundColor = .clear
        returnView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(15)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(15)
//            make.top.equalToSuperview().offset(15)
//            make.left.equalToSuperview().offset(15)
            make.height.equalTo(22)
            make.width.equalTo(22)
        }
        returnView.addSubview(returnImgView)
//        returnImgView.image = UIImage(named: "whiteCross")
        returnImgView.image = UIImage(named: "ic_close_green")
        returnImgView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }
        returnView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            self.playerView.stopVideo()
            //                self.playerView = nil
            UIApplication.shared.setStatusBarHidden(false, with: .fade)
            self.dismiss(animated: true, completion: nil)
//            if self.playerView != nil {
//            }
        }

//        playerView = WKYTPlayerView(frame: CGRect.zero)

//        playerView.webView?.tag = 100
        mainView.addSubview(playerView)
//        playerView.isHidden = true
        playerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
//            make.top.equalToSuperview().offset(UiUtil.safeAreaTop())
            make.top.equalTo(returnView.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-UiUtil.safeAreaBottom())
//            make.centerY.equalToSuperview()
//            make.height.equalTo(150)
        }
        
        logger.debug("准备播放URL: \(materialsData.url)")

//        playerView.loadVideo(byURL: materialsData.url, startSeconds: 0)
//        playerView.loadVideo(byURL: materialsData.url, startSeconds: 0, suggestedQuality: .auto)
        

        playerView.delegate = self
        placeholderCoverView.addTo(superView: mainView) { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(UiUtil.safeAreaTop())
            make.bottom.equalToSuperview().offset(-UiUtil.safeAreaBottom())
        }
        mainView.addSubview(placeholderImgView)
        placeholderImgView.hero.id = materialsData.minPictureUrl
        placeholderImgView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(200)
            make.centerY.equalToSuperview()
        }
        placeholderImgView.setImageForUrl(imageUrl: materialsData.minPictureUrl, placeholderImage: UIImage(named: "linkResource")!)
        placeholderImgView.contentMode = .scaleAspectFill
        // 设置图片超出容器的部分不显示
        placeholderImgView.clipsToBounds = true
        mainView.addSubview(loadingIndicator)
        loadingIndicator.type = .circleStrokeSpin
        loadingIndicator.color = ColorUtil.main
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        showLoader()
        mainView.bringSubviewToFront(returnView)
    }
}

extension YoutubePlayerViewController: YTPlayerViewDelegate {
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        logger.debug("[YTPlayer] => player 准备完成")
        playerView.playVideo()
        loadingIndicator.stopAnimating()
        placeholderImgView.isHidden = true
        _ = placeholderCoverView.isHidden(true)
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        logger.debug("[YTPlayer] => state变更: \(state)")
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo quality: YTPlaybackQuality) {
        logger.debug("[YTPlayer] => 清晰度变更: \(quality)")
    }
    
    func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
        switch error {
        case .html5Error:
            logger.debug("[YTPlayer] => 播放器错误: HTML5 Error")
        case .invalidParam:
            logger.debug("[YTPlayer] => 播放器错误: Invalid param")
        case .notEmbeddable:
            logger.debug("[YTPlayer] => 播放器错误: not Embeddable")
        case .videoNotFound:
            logger.debug("[YTPlayer] => 播放器错误: Video not found")
        case .unknown:
            logger.debug("[YTPlayer] => 播放器错误: unknown")
        @unknown default:
            logger.debug("[YTPlayer] => 播放器错误: Default")
        }
        dismissAndJumpToSafariPlay()
    }
    
    private func dismissAndJumpToSafariPlay() {
        let url = materialsData.url
        dismiss(animated: true) {
            guard let url = URL(string: url) else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Data

//extension YoutubePlayerViewController: WKYTPlayerViewDelegate {
//    func playerViewDidBecomeReady(_ playerView: WKYTPlayerView) {
//        logger.debug("======playerViewDidBecomeReady")
//        playerView.playVideo()
//    }
//
//    func playerView(_ playerView: WKYTPlayerView, didChangeTo state: WKYTPlayerState) {
//        logger.debug("======didChangeToState:\(state.rawValue)===\(Tools.getTopViewController() == self)")
//        switch state {
//        case .playing:
//            hideLoader()
//            placeholderImgView.isHidden = true
//            playerView.isHidden = false
//        case .unstarted:
//            break
//        case .ended:
//            break
//        case .paused:
//            break
//        case .buffering:
//            break
//        case .queued:
//            break
//        case .unknown:
//            break
//        @unknown default:
//            break
//        }
//    }
//
//    func playerView(_ playerView: WKYTPlayerView, didChangeTo quality: WKYTPlaybackQuality) {
//        logger.debug("======didChangeToQuality:\(quality.rawValue)")
//    }
//
//    func playerView(_ playerView: WKYTPlayerView, receivedError error: WKYTPlayerError) {
//        logger.debug("======receivedError:\(error)")
//    }
//
//    func playerView(_ playerView: WKYTPlayerView, didPlayTime playTime: Float) {
////        logger.debug("======didPlayTime:\(playTime)")
//    }
//
//    func playerViewIframeAPIDidFailed(toLoad playerView: WKYTPlayerView) {
//        logger.debug("======playerViewIframeAPIDidFailed")
//    }
//}

// MARK: - Action

extension YoutubePlayerViewController {
    @objc func videoDidExitFullScreen() {
//        if playerView != nil {
//            playerView.getPlayerState { [weak self] state, _ in
//                guard let self = self else { return }
//                if state.rawValue == 3 {
//                    self.playerView.stopVideo()
//                    self.playerView = nil
//                    UIApplication.shared.setStatusBarHidden(false, with: .fade)
//                    self.dismiss(animated: true, completion: nil)
//                }
//            }
//        }
    }

    func showLoader() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
    }

    func hideLoader() {
        loadingIndicator.isHidden = true
    }
}
