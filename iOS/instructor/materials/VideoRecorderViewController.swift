//
//  VideoRecorderViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/9/1.
//  Copyright © 2022 spelist. All rights reserved.
//

import AVFoundation
import GRDB
import MKRingProgressView
import NVActivityIndicatorView
import Photos
import SnapKit
import UIKit

class VideoRecorderViewController: TKBaseViewController, AVCaptureFileOutputRecordingDelegate {
    struct CompletionData {
        var id: String
        var url: URL
        var compressedURL: URL
    }

    // 视频捕获会话。它是input和output的桥梁。它协调着intput到output的数据传输
    let captureSession = AVCaptureSession()
    // 视频输入设备
    var videoDevice: AVCaptureDevice? = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
    // 音频输入设备
    let audioDevice: AVCaptureDevice? = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)

    // 将捕获到的视频输出到文件
    let fileOutput = AVCaptureMovieFileOutput()

    var timer: Timer?
    var time: TimeInterval = 0 {
        didSet {
//            let leftTime = 600 - time
//            timeLabel.text(text: "\(TimeUtil.secondsToMinsSeconds(time: Float(leftTime)))")
            timeLabel.text(text: "\(TimeUtil.secondsToMinsSeconds(time: Float(time))) / 10:00")
        }
    }

    var timeLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 15))
        .textColor(color: .white)
        .text(text: "10:00")

    var navigationBarView: TKView = TKView.create()
        .backgroundColor(color: .clear)

    var backButton: TKButton = TKButton.create()
        .setImage(image: GalleryBundle.image("gallery_close")!)

    var startRecordingInsideButton: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.red)
        .corner(size: 29)

    var progressBar: RingProgressView = RingProgressView(frame: .zero)
    var loadingView: NVActivityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: ColorUtil.main, padding: 0)

    var cameraChangeButton: TKButton = TKButton.create()
        .setImage(name: "camera_change", size: CGSize(width: 48, height: 48))

    lazy var startRecordingButton: TKView = {
        let view = TKView.create()
            .backgroundColor(color: .white)
            .corner(size: 32)
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = .evenOdd
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 64, height: 64), cornerRadius: 32)
        let maskPath = UIBezierPath(roundedRect: CGRect(x: 2, y: 2, width: 60, height: 60), cornerRadius: 30)
        path.append(maskPath)
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
        return view
    }()

    // 表示当时是否在录像中
    var isRecording = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.isRecording {
                    self.cameraChangeButton.isHidden = true
                }
                self.startRecordingInsideButton.layoutIfNeeded()
                UIView.animate(withDuration: 0.2) {
                    if self.isRecording {
                        self.startRecordingInsideButton.transform = CGAffineTransform(scaleX: 0.47, y: 0.47)
                        self.startRecordingInsideButton.corner(size: 14)
                    } else {
                        self.startRecordingInsideButton.transform = .identity
                        self.startRecordingInsideButton.corner(size: 29)
                    }
                }
            }
        }
    }

    var videoInput: AVCaptureDeviceInput?
    var previewLayer: CALayer?

    var id: String = ""
    var titleString: String = ""

    var onRecordCompletion: ((CompletionData) -> Void)?
}

extension VideoRecorderViewController {
    override func initView() {
        super.initView()
        // 添加视频、音频输入设备
        captureSession.beginConfiguration()
        if let videoDevice = videoDevice, let audioDevice = audioDevice {
            let videoInput = try! AVCaptureDeviceInput(device: videoDevice)
            captureSession.addInput(videoInput)
            self.videoInput = videoInput
            let audioInput = try! AVCaptureDeviceInput(device: audioDevice)
            captureSession.addInput(audioInput)
        }

        fileOutput.movieFragmentInterval = .invalid
        // 添加视频捕获输出
        captureSession.addOutput(fileOutput)
        captureSession.sessionPreset = .vga640x480
        captureSession.commitConfiguration()
        // 使用AVCaptureVideoPreviewLayer可以将摄像头的拍摄的实时画面显示在ViewController上
        let videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoLayer.frame = view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(videoLayer)
        previewLayer = videoLayer

        // 创建按钮
        initButton()
        navigationBarView.addTo(superView: view) { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(44 + UiUtil.safeAreaTop())
        }
        backButton.addTo(superView: navigationBarView) { make in
            make.size.equalTo(44)
            make.left.equalToSuperview()
            make.top.equalToSuperview()
        }

        timeLabel.addTo(superView: navigationBarView) { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton.snp.centerY)
        }

        backButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
        // 启动session会话
        captureSession.startRunning()
    }

    private func initButton() {
        startRecordingButton.addTo(superView: view) { make in
            make.size.equalTo(64)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-40)
        }

        startRecordingInsideButton.addTo(superView: view) { make in
            make.center.equalTo(startRecordingButton.snp.center)
            make.size.equalTo(58)
        }

        progressBar.addTo(superView: view) { make in
            make.center.equalTo(startRecordingButton.snp.center)
            make.size.equalTo(64)
        }
        progressBar.ringWidth = 6
        progressBar.startColor = ColorUtil.main
        progressBar.endColor = ColorUtil.main
        progressBar.progress = 0
        progressBar.isHidden = true
        loadingView.addTo(superView: view) { make in
            make.center.equalTo(startRecordingButton.snp.center)
            make.size.equalTo(64)
        }

        cameraChangeButton.addTo(superView: view) { make in
            make.centerY.equalTo(startRecordingButton.snp.centerY)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(48)
        }

        startRecordingButton.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if self.isRecording {
                // 正在录像,停止
                self.stopRecording()
            } else {
                self.startRecording()
            }
        }
        startRecordingInsideButton.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if self.isRecording {
                // 正在录像,停止
                self.stopRecording()
            } else {
                self.startRecording()
            }
        }

        cameraChangeButton.onTapped { [weak self] _ in
            self?.changeCamera()
        }
    }

    func changeCamera() {
        guard let device = videoDevice else { return }
        let position = device.position
        captureSession.beginConfiguration()
        if let videoInput = videoInput {
            captureSession.removeInput(videoInput)
        }
        var newVideoDevice: AVCaptureDevice?
        if position == .front {
            newVideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        } else {
            newVideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        }
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.duration = 0.3
        animation.type = CATransitionType(rawValue: "oglFlip")
        previewLayer?.add(animation, forKey: nil)
        let videoInput = try! AVCaptureDeviceInput(device: newVideoDevice!)
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            self.videoInput = videoInput
            videoDevice = newVideoDevice
        } else {
            if let vi = self.videoInput {
                captureSession.addInput(vi)
            }
        }
        captureSession.commitConfiguration()
    }

    // 开始按钮点击，开始录像
    func startRecording() {
        logger.debug("准备开始录像, 当前状态: \(isRecording)")
        id = IDUtil.nextId(group: .user)?.description ?? ""
        if !isRecording {
            // 设置录像的保存地址（在Documents目录下，名为temp.mp4
            let folderPath = StorageService.shared.getMaterialVideoFolderPath()
            let filePath: String = "\(folderPath)/\(id)_original.mp4"
            logger.debug("存储位置: \(filePath)")
            let fileURL: URL = URL(fileURLWithPath: filePath)
            // 启动视频编码输出
            fileOutput.startRecording(to: fileURL, recordingDelegate: self)

            // 记录状态：录像中...
            isRecording = true
            time = 0
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
                guard let self = self else { return }
                if self.time == 600 {
                    self.stopRecording()
                } else {
                    self.time += 1
                }
            })
        }
    }

    // 停止按钮点击，停止录像
    func stopRecording() {
        logger.debug("准备停止录像, 当前状态: \(isRecording)")
        if isRecording {
            // 停止视频编码输出
            fileOutput.stopRecording()
            // 记录状态：录像结束 as URL
            isRecording = false
            time = 0
            timer?.invalidate()
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        logger.debug("进入录制完成回调,当前时间: \(time)")
        timer?.invalidate()
        time = 0
        if let error = error {
            logger.debug("发生错误: \(error)")
            DispatchQueue.main.async {
                // 弹出提示框
                let alertController = UIAlertController(title: "发生错误: \(error.localizedDescription)",
                                                        message: nil, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "确定", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            logger.debug("录制完成, 准备压缩, file: \(outputFileURL.absoluteString)")
            let folderPath = StorageService.shared.getMaterialVideoFolderPath()
            compressVideo(url: outputFileURL, outputURL: URL(fileURLWithPath: "\(folderPath)/\(id).mp4"))
        }
    }

    func compressVideo(url: URL, outputURL: URL) {
        startRecordingInsideButton.isHidden = true
        startRecordingButton.isHidden = true
        progressBar.isHidden = false
        progressBar.progress = 0
        let videoCompressor = LightCompressor()
        videoCompressor.compressVideo(source: url, destination: outputURL, quality: .low, isMinBitRateEnabled: false, keepOriginalResolution: true, progressQueue: .main) { [weak self] progress in
            guard let self = self else { return }
            logger.debug("压缩进度: \(progress)")
            var p = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            if p > 1 {
                p = 1
            }
            self.progressBar.progress = p
            if p == 1 {
                self.progressBar.isHidden = true
                self.loadingView.startAnimating()
            }
        } completion: { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .onStart:
                    logger.debug("开始压缩")
                case let .onSuccess(path):
                    logger.debug("压缩成功: \(path)")
                    self.dismiss(animated: true) {
                        self.onRecordCompletion?(CompletionData(id: self.id, url: url, compressedURL: outputURL))
                    }
//                self.compressSuccess(originalURL: url, compressedURL: outputURL)
                case let .onFailure(error):
                    logger.error("压缩失败: \(error)")
                    TKToast.show(msg: "Save failed, please try again later.", style: .error)
                    self.dismiss(animated: true)
                case .onCancelled:
                    logger.debug("取消压缩")
                    TKToast.show(msg: "You've been cancelled.", style: .success)
                    self.dismiss(animated: true)
                }
            }
        }
    }

    func compressSuccess(originalURL: URL, compressedURL: URL) {
        // 删除原视频
        var fileSize: Int = 0
        do {
            try FileManager.default.removeItem(at: originalURL)
        } catch {
            logger.error("删除源视频失败: \(error)")
            fatalError("删除原视频失败: \(error)")
        }
        do {
            let attritubes = try FileManager.default.attributesOfItem(atPath: compressedURL.path)
            if let fs = attritubes[FileAttributeKey.size] as? UInt64 {
                fileSize = Int(fs)
            }
        } catch {
            logger.error("获取文件大小失败: \(error)")
            fatalError("获取文件大小失败: \(error)")
        }
        // 获取视频文件属性
        let asset = AVURLAsset(url: compressedURL)
        let time = asset.duration
        let seconds = Double(time.value) / Double(time.timescale)
    }
}
