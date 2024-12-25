//
//  MaterialsHelper.swift
//  TuneKey
//
//  Created by Wht on 2019/9/5.
//  Copyright © 2019年 spelist. All rights reserved.
//

import Alamofire
import AVFoundation
import AVKit
import Foundation
import Hero
import SafariServices
import UIKit

class MaterialsHelper {
    static func cellClick(materialsData: TKMaterial, cell: MaterialsCell? = nil, mController: TKBaseViewController) {
        logger.debug("当前文件数据： \(materialsData.toJSONString() ?? "")")
        if materialsData.status == .failed {
            clickLink(mController: mController, link: materialsData.url, name: materialsData.name, data: materialsData)
            return
        }
        switch materialsData.type {
        case .pdf:
            clickPDF(mController: mController, link: materialsData.url, withData: materialsData)
            break
        case .file:
            clickLink(mController: mController, link: materialsData.url, name: materialsData.name, data: materialsData)
            break
        case .ppt:
            clickLink(mController: mController, link: materialsData.url, name: materialsData.name, data: materialsData)

            break
        case .word:
            clickLink(mController: mController, link: materialsData.url, name: materialsData.name, data: materialsData)
            break
        case .txt:
//            clickFile(mController: mController, link: "MaterialsHelper")
            clickLink(mController: mController, link: materialsData.url, name: materialsData.name, data: materialsData)
            break
        case .image:
            clickImage(mController: mController, img: materialsData.url, title: materialsData.name)
            break
        case .mp3:
            clickAudio(mController: mController, url: materialsData.url, title: materialsData.name, data: materialsData)
            break
        case .video:
            clickVideo(mController: mController, materialsData: materialsData)
            break
        case .youtube:
            clickYoutube(mController: mController, materialsData: materialsData)
//            if Tools.extractYouTubeId(from: materialsData.url) != nil {
//            } else {
//                clickLink(mController: mController, link: materialsData.url)
//            }
//            clickLink(mController: mController, link: materialsData.url)
            break
        case .link:
            clickLink(mController: mController, link: materialsData.url, name: materialsData.name, data: materialsData)
            break
        case .none: break
        case .folder:
            break
        case .excel: break
        case .pages: break
        case .numbers: break
        case .keynote: break
        case .googleDoc, .googleSheet, .googleSlides, .googleForms, .googleDrawings: clickLink(mController: mController, link: materialsData.url, name: materialsData.name, data: materialsData)
        }
    }

    private static func clickImage(mController: UIViewController, img: String, title: String) {
        logger.debug("预览图片: \(img)")
        let controller = PreviewViewController(image: img)
        controller.hero.isEnabled = true
        controller.titleString = title
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .fade, dismissing: .fade)
        mController.present(controller, animated: true)
    }

    private static func clickVideo(mController: UIViewController, materialsData: TKMaterial) {
        logger.debug("视频预览: \(materialsData.url)")
        let w: CGFloat = UIScreen.main.bounds.width
        let h: CGFloat = w * 9 / 16
        let y: CGFloat = UIScreen.main.bounds.height / 2 - (h / 2)

        let imageView = UIImageView(frame: CGRect(x: 0, y: y, width: w, height: h))
        imageView.setImageForUrl(imageUrl: materialsData.minPictureUrl, placeholderImage: ImageUtil.getImage(color: ColorUtil.imagePlaceholderDark))
        imageView.heroID = materialsData.minPictureUrl
        imageView.contentMode = .scaleAspectFill
        // check if exists in local
        let localPath = StorageService.shared.getMaterialVideoFolderPath() + "/\(materialsData.id).mp4"
        logger.debug("检查是否存在于本地: \(localPath)")
        let player: AVPlayer
        let url: URL
        if FileManager.default.fileExists(atPath: localPath) {
            logger.debug("存在于本地: \(localPath)")
            player = AVPlayer(url: URL(fileURLWithPath: localPath))
            url = URL(fileURLWithPath: localPath)
        } else {
            guard let videoURL = URL(string: materialsData.url) else { return }
            player = AVPlayer(url: videoURL)
            url = videoURL
        }
//        let controller = TKAVPlayerViewController(.init(url: url, name: materialsData.name, cover: URL(string: materialsData.minPictureUrl)!))
//        controller.modalPresentationStyle = .fullScreen
//        mController.present(controller, animated: true)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.contentOverlayView?.addSubview(imageView)

        playerViewController.hero.isEnabled = true
        playerViewController.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        mController.present(playerViewController, animated: true) {
            playerViewController.player?.play()
            let appdelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.isForceAllDerictions = true
            SL.Executor.runAsyncAfter(time: 1) {
                SL.Animator.run(time: 0.5, animation: {
                    imageView.alpha = 0
                }) { _ in
                }
            }
        }
    }

    private static func clickYoutube(mController: UIViewController, materialsData: TKMaterial) {
        let jumpToSafari = {
            MaterialsHelper.jumpToWebView(materialsData.url, name: materialsData.name)
//            DispatchQueue.main.async {
//                guard let url = URL(string: materialsData.url) else { return }
//                if #available(iOS 10, *) {
//                    UIApplication.shared.open(url, options: [:],
//                                              completionHandler: {
//                                                  _ in
//                                              })
//                } else {
//                    UIApplication.shared.openURL(url)
//                }
//            }
        }
        if Tools.extractYouTubeId(from: materialsData.url) == nil && Tools.extractYouTubePlaylistId(from: materialsData.url) == nil {
            logger.debug("提取id失败: \(materialsData.url)")
            jumpToSafari()
            return
        }
        let controller = YoutubePlayerViewController()
        controller.materialsData = materialsData
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        let image: UIImage?
        if #available(iOS 13.0, *) {
            image = UIImage(systemName: "safari")?.withTintColor(ColorUtil.main, renderingMode: .alwaysOriginal).resizeImage(CGSize(width: 22, height: 22))
        } else {
            image = UIImage(named: "safari")?.resizeImage(CGSize(width: 22, height: 22))
        }
        Button().image(image, for: .normal)
            .onTapped { _ in
                jumpToSafari()
            }
            .backgroundColor(.clear)
            .cornerRadius(10)
            .addTo(superView: controller.view) { make in
                make.top.equalToSuperview().offset(5 + UiUtil.safeAreaTop())
                make.right.equalToSuperview().offset(-5)
                make.width.equalTo(60)
                make.height.equalTo(47)
            }
        controller.onViewLoadFailed = jumpToSafari
        mController.present(controller, animated: true)
    }

    private static func clickLink(mController: UIViewController, link: String, name: String = "", data: TKMaterial) {
        if link.contains("youtube.com") || link.contains("youtu.be") {
            clickYoutube(mController: mController, materialsData: data)
        } else {
            jumpToWebView(link, name: name)
        }
    }
    
    private static func jumpToWebView(_ link: String, name: String) {
        var link = link
        if !link.contains("http") {
            link = "http://\(link)"
        }
        if let url = URL(string: link) {
            //            let controller = SFSafariViewController(url: url)
            let controller = CommonsWebViewViewController(url)
            controller.navigationBar.backButton.setImage(name: "ic_close_green", size: CGSize(width: 22, height: 22))
            if #available(iOS 13.0, *) {
                let image = UIImage(systemName: "safari")!.withTintColor(ColorUtil.main, renderingMode: .alwaysOriginal)
                controller.navigationBar.rightButton.setImage(image: image, size: CGSize(width: 22, height: 22))
            } else {
                controller.navigationBar.rightButton.setImage(name: "safari", size: CGSize(width: 22, height: 22))
            }
            controller.onNavigationBarRightButtonTapped = {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:],
                                              completionHandler: {
                        _ in
                    })
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
            controller.navigationTitle = name
            controller.modalPresentationStyle = .fullScreen
            controller.enablePanToDismiss()
            controller.hero.isEnabled = true
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            Tools.getTopViewController()?.present(controller, animated: true)
        }
    }

    private static func clickFile(mController: UIViewController, link: String) {
        let url = Bundle.main.url(forResource: "apple", withExtension: "pdf")
        let documentInteractionController = UIDocumentInteractionController(url: url!)
        documentInteractionController.presentOpenInMenu(from: CGRect.zero, in: mController.view, animated: true)
    }

    private static func clickAudio(mController: UIViewController, url: String, title: String, data: TKMaterial) {
        let controller = TeacherPlayAudioController()
        controller.url = url
        controller.materialData = data
        controller.name = title
        controller.modalPresentationStyle = .custom
        mController.present(controller, animated: false, completion: nil)
    }

//    func clickMp3(_ cell: MaterialsCell, url: String) {
//        if playingCell != nil && cell.tag != playingCell.tag {
//            playingCell.playImageView!.setStatus(.stop)
//        }
//        playingCell = cell
//        if cell.playImageView!.previosStatus == .stop {
//            cell.playImageView!.play(url)
//        } else if cell.playImageView!.previosStatus == .playing {
//            cell.playImageView!.setStatus(.stop)
//        } else {
//            cell.playImageView!.setStatus(.stop)
//        }
//    }
}

// pdf
extension MaterialsHelper {
    private static func clickPDF(mController: TKBaseViewController, link: String, withData data: TKMaterial) {
        logger.debug("点击PDF: \(link)")
        DispatchQueue.main.async {
            mController.showFullScreenLoading()
            // 下载当前PDF
            let path = StorageService.shared.getPDFPath(id: data.id)
            // 判断当前文件是否存在
            if FileManager.default.fileExists(atPath: path) {
                logger.debug("本地存在,直接读取")
                DispatchQueue.main.async {
                    let url = URL(fileURLWithPath: path)
                    if let doc = document(url) {
                        let image = UIImage(named: "")
                        mController.hideFullScreenLoading()
                        let controller = PDFViewController.createNew(with: doc, title: "", actionButtonImage: image, actionStyle: .activitySheet)
                        controller.modalPresentationStyle = .fullScreen
                        mController.present(controller, animated: true, completion: {
                            MaterialsHelper.addShareButtonToPDFPreviewController(controller, withLocalFilePath: path, data: data)
                        })
                    } else {
                        mController.hideFullScreenLoading()
                        TKToast.show(msg: "PDF file not found", style: .error)
                    }
                }
            } else {
                logger.debug("保存PDF到文件夹: \(data.id)")
                StorageService.shared.downloadFile(url: link, saveTo: path) { progress, _ in
                    logger.debug("下载进度: \(progress)")
                    mController.updateFullScreenLoadingMsg(msg: "Downloading, \((progress * Double(100)).roundTo(places: 2))%")
                } completion: { error in
                    if let error = error {
                        logger.error("下载失败,直接网络读取: \(error)")
                        DispatchQueue.main.async {
                            let remotePDFDocumentURLPath = link
                            if let remotePDFDocumentURL = URL(string: remotePDFDocumentURLPath), let doc = document(remotePDFDocumentURL) {
                                let image = UIImage(named: "")
                                mController.hideFullScreenLoading()
                                let controller = PDFViewController.createNew(with: doc, title: "", actionButtonImage: image, actionStyle: .activitySheet)
                                controller.modalPresentationStyle = .fullScreen
                                mController.present(controller, animated: true, completion: nil)
                            } else {
                                mController.hideFullScreenLoading()
                                print("Document named \(remotePDFDocumentURLPath) not found")
                                TKToast.show(msg: "PDF file not found", style: .error)
                            }
                        }
                    } else {
                        logger.debug("下载成功,本地读取")
                        DispatchQueue.main.async {
                            let url = URL(fileURLWithPath: path)
                            if let doc = document(url) {
                                let image = UIImage(named: "")
                                mController.hideFullScreenLoading()
                                let controller = PDFViewController.createNew(with: doc, title: "", actionButtonImage: image, actionStyle: .activitySheet)
                                controller.modalPresentationStyle = .fullScreen
                                mController.present(controller, animated: true, completion: {
                                    MaterialsHelper.addShareButtonToPDFPreviewController(controller, withLocalFilePath: path, data: data)
                                })
                            } else {
                                mController.hideFullScreenLoading()
                                TKToast.show(msg: "PDF file not found", style: .error)
                            }
                        }
                    }
                }
            }
        }
    }

    private static func addShareButtonToPDFPreviewController(_ controller: PDFViewController, withLocalFilePath: String, data: TKMaterial) {
        let url = URL(fileURLWithPath: withLocalFilePath)
        let shareButton: TKImageView = TKImageView.create()
            .setImage(name: "share")
        shareButton.addTo(superView: controller.view) { make in
            make.size.equalTo(32)
            make.right.equalTo(controller.view.safeAreaLayoutGuide.snp.right).offset(-20)
            make.bottom.equalTo(controller.view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        shareButton.onViewTapped { _ in
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            // 如果是ipad, 那么需要使用pop的方式显示方向界面
            if UIDevice.current.userInterfaceIdiom == .pad {
                let popOver = activityVC.popoverPresentationController
                popOver?.sourceView = controller.view
                popOver?.sourceRect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 340)
            }
            controller.present(activityVC, animated: true, completion: nil)
        }
    }

    /// Initializes a document with the name of the pdf in the file system
    static func document(_ name: String) -> PDFDocument? {
        guard let documentURL = Bundle.main.url(forResource: name, withExtension: "pdf") else { return nil }
        return PDFDocument(url: documentURL)
    }

    /// Initializes a document with the data of the pdf
    static func document(_ data: Data) -> PDFDocument? {
        return PDFDocument(fileData: data, fileName: "Sample PDF")
    }

    /// Initializes a document with the remote url of the pdf
    static func document(_ remoteURL: URL) -> PDFDocument? {
        return PDFDocument(url: remoteURL)
    }
}
