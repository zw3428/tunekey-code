//
//  TKPracticeRecordingListViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/1/25.
//  Copyright © 2022 spelist. All rights reserved.
//

import AttributedString
import AVFoundation
import AVKit
import FirebaseFirestore
import FirebaseStorage
import Hero
import MKRingProgressView
import PromiseKit
import SnapKit
import UIKit

class TKPracticeRecordingListViewController: TKBaseViewController {
    enum Style {
        case studentCompletePracticeWithVideo
        case studentCompletePracticeWithAudio
        case studentView
        case teacherView
    }

    var contentViewHeight: CGFloat = UIScreen.main.bounds.height * 0.7

    var contentView: TKView = TKView.create().backgroundColor(color: .white).corner(size: 10).maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

    var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.bold(size: 15))
        .textColor(color: ColorUtil.Font.fourth)
        .alignment(alignment: .center)

    var tipLabel: TKLabel = TKLabel.create()
        .setNumberOfLines(number: 0)
        .alignment(alignment: .center)

    var practiceTitleLabel: TKLabel = TKLabel.create().font(font: FontUtil.medium(size: 17)).textColor(color: ColorUtil.Font.second).alignment(alignment: .center)

    lazy var tableView: UITableView = makeTableView()

    var doneButton: TKBlockButton = TKBlockButton(frame: .zero, title: "DONE", style: .cancel)

    var practice: TKPractice

    var uploadProgress: [String: Float] = [:]
    var uploadTasks: [String: StorageUploadTask] = [:]

    var currentOpendCellIndexs: [Int] = [0]
    private var isShow: Bool = false

    var style: Style

    var recordData: [PracticeRecord] = []

    var needSave: Bool = false

    var currentVideoDownloadTask: StorageDownloadTask?

    init(_ practice: TKPractice, style: Style) {
        self.practice = practice
        if self.practice.teacherId == "", let teacherId = ListenerService.shared.studentData.studentData?.teacherId {
            self.practice.teacherId = teacherId
        }
        logger.debug("当前设置的练习数据: \(practice.toJSONString() ?? "")")
        self.style = style
        super.init(nibName: nil, bundle: nil)
        switch style {
        case .studentCompletePracticeWithVideo:
            recordData = []
            if let data = practice.recordData.filter({ !$0.upload && $0.format == ".mp4" }).sorted(by: { $0.startTime > $1.startTime }).first {
                recordData.append(data)
            }
        case .studentCompletePracticeWithAudio:
            let data = practice.recordData.filter({ !$0.upload && $0.format != ".mp4" }).sorted(by: { $0.startTime > $1.startTime })
            // 获取list
            recordData = []
            guard let startTime = data.first?.startTime else { return }
            data.forEachItems { record, _ in
                // 获取和第一条数据只差2秒之内的所有数据,证明是一批处理的数据
                if startTime - record.startTime <= 2 {
                    recordData.append(record)
                }
            }
            recordData = recordData.sorted(by: { $0.startTime > $1.startTime })
        case .studentView:
            recordData = practice.recordData.sorted(by: { $0.startTime > $1.startTime })
        case .teacherView:
            recordData = practice.recordData.filter({ $0.upload }).sorted(by: { $0.startTime > $1.startTime })
        }
        tableView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
}

extension TKPracticeRecordingListViewController {
    private func show() {
        guard !isShow else { return }
        isShow = true
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        }
    }

    private func hide() {
        logger.debug("消失")
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: self.contentViewHeight)
        } completion: { [weak self] _ in
            self?.dismiss(animated: false)
        }
    }
}

extension TKPracticeRecordingListViewController {
    private func makeTableView() -> UITableView {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RecordItemTableViewCell.self, forCellReuseIdentifier: RecordItemTableViewCell.id)
        return tableView
    }
}

extension TKPracticeRecordingListViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        updateContentViewHeight()
        contentView.addTo(superView: view) { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(contentViewHeight)
        }
        contentView.transform = CGAffineTransform(translationX: 0, y: contentViewHeight)

        titleLabel.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(24)
        }
        switch style {
        case .studentView, .teacherView:
            titleLabel.text = "Record History"
        case .studentCompletePracticeWithVideo, .studentCompletePracticeWithAudio:
            let formatTypes = recordData.compactMap({ $0.format }).filterDuplicates({ $0 })
            if formatTypes.contains(".mp4") {
                titleLabel.text = "Video Recording"
            } else {
                titleLabel.text = "Audio Recording"
            }
        }
        if style == .studentCompletePracticeWithVideo || style == .studentCompletePracticeWithAudio {
            tipLabel.addTo(superView: contentView) { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(30)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            }
            var totalTime: CGFloat = recordData.compactMap({ $0.duration }).reduce(0, { $0 + $1 })
            totalTime = totalTime / 60
            let timeString: String
            if totalTime <= 0.1 {
                timeString = "0.1 min"
            } else {
                let t = totalTime.roundTo(places: 1)
                timeString = "\(t) min\(t > 1 ? "s" : "")"
            }

            let string1: ASAttributedString = .init("You just completed \(timeString) practice.\nTap on ", .font(FontUtil.medium(size: 17)), .foreground(ColorUtil.Font.third))
            let img: ASAttributedString = .init(.image(UIImage(named: "ic_upload_primary")!))
            let string2: ASAttributedString = .init(" to upload the recordings for instructor's review.", .font(FontUtil.medium(size: 17)), .foreground(ColorUtil.Font.third))
            tipLabel.attributed.text = string1 + img + string2
        }

        practiceTitleLabel.addTo(superView: contentView) { make in
            if style == .studentCompletePracticeWithVideo || style == .studentCompletePracticeWithAudio {
                make.top.equalTo(tipLabel.snp.bottom).offset(30)
            } else {
                make.top.equalTo(titleLabel.snp.bottom).offset(30)
            }
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(20)
        }

        practiceTitleLabel.text = practice.name

        doneButton.addTo(superView: contentView) { make in
            make.bottom.equalToSuperview().offset(-20 - UiUtil.safeAreaBottom())
            make.centerX.equalToSuperview()
            make.width.equalTo(160)
            make.height.equalTo(50)
        }

        tableView.addTo(superView: contentView) { make in
            make.top.equalTo(practiceTitleLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(doneButton.snp.top).offset(-20)
        }
    }
}

extension TKPracticeRecordingListViewController {
    private func updateContentViewHeight() {
        if style == .studentCompletePracticeWithVideo || style == .studentCompletePracticeWithAudio {
//            contentViewHeight = (CGFloat(recordData.count) * 40 + 53) + 330
            contentViewHeight = (CGFloat(recordData.count) * (40 + 53)) + 330
        } else {
//            contentViewHeight = (CGFloat(recordData.count) * 40 + 53) + 280
            contentViewHeight = (CGFloat(recordData.count) * (40 + 53)) + 280
        }
        if contentViewHeight > UIScreen.main.bounds.height * 0.8 {
            contentViewHeight = UIScreen.main.bounds.height * 0.8
        }
    }
}

extension TKPracticeRecordingListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        guard recordData.count > 1 else {
            return
        }
        var open: Bool = true
        if currentOpendCellIndexs.contains(indexPath.row) {
            open = false
            currentOpendCellIndexs.removeElements({ $0 == indexPath.row })
        } else {
            currentOpendCellIndexs.append(indexPath.row)
        }

        tableView.beginUpdates()
        if let cell = tableView.cellForRow(at: indexPath) as? RecordItemTableViewCell {
            cell.timeLabel.snp.updateConstraints { make in
                if open {
                    make.bottom.equalToSuperview().offset(-63).priority(.medium)
                } else {
                    make.bottom.equalToSuperview().offset(-10).priority(.medium)
                }
            }
            cell.arrowImageView.transform = .identity
        }

        tableView.endUpdates()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recordData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecordItemTableViewCell.id, for: indexPath) as! RecordItemTableViewCell
        cell.timeLabel.snp.updateConstraints { make in
            if currentOpendCellIndexs.contains(indexPath.row) {
                make.bottom.equalToSuperview().offset(-63).priority(.medium)
            } else {
                make.bottom.equalToSuperview().offset(-10).priority(.medium)
            }
        }
        if indexPath.row == recordData.count - 1 {
            cell.bottomLine.isHidden = true
        } else {
            cell.bottomLine.isHidden = false
        }
        if currentOpendCellIndexs.contains(indexPath.row) {
            cell.arrowImageView.transform = .identity
        } else {
            cell.arrowImageView.transform = CGAffineTransform(rotationAngle: .pi)
        }
        let data = recordData[indexPath.row]
        cell.timeLabel.text = Date(seconds: data.startTime).toLocalFormat("\(Locale.is12HoursFormat() ? "hh:mm:ss a" : "HH:mm:ss"), MM/dd/yyyy")
        if data.format == ".mp4" {
            cell.playButton.setImage(name: "ic_video_play_primary", size: CGSize(width: 22, height: 22))
        } else {
            cell.playButton.setImage(name: "icPlayPrimary", size: CGSize(width: 22, height: 22))
        }
        if data.upload {
            cell.uploadButton.setImage(name: "ic_upload_success_primary", size: CGSize(width: 22, height: 22))
        } else {
            cell.uploadButton.setImage(name: "ic_upload_primary", size: CGSize(width: 22, height: 22))
        }

        if let progress = uploadProgress[data.id] {
            let fileSize: String
            if data.fileSize < 600 {
                fileSize = "\(data.fileSize)KB"
            } else {
                fileSize = "\((Double(data.fileSize) / 1048576).roundTo(places: 2))MB"
            }
            let uploadedFileSize: Int = Int(progress * Float(data.fileSize))
            let uploadFileSize: String
            if uploadedFileSize < 600 {
                uploadFileSize = "\(uploadedFileSize)KB"
            } else {
                uploadFileSize = "\((Double(uploadedFileSize) / 1048576).roundTo(places: 2))MB"
            }
            cell.timeLengthLabel.text = "\(uploadFileSize) / \(fileSize)"
            cell.uploadProgressView.progress = Double(progress)
            cell.uploadProgressView.isHidden = false
            cell.uploadButton.isHidden = true
        } else {
            cell.timeLengthLabel.text = TimeUtil.secondsToMinsSeconds(time: Float(data.duration))
            cell.uploadProgressView.progress = 0
            cell.uploadProgressView.isHidden = true
            cell.uploadButton.isHidden = false
        }

        if style == .teacherView {
            cell.shareButton.snp.remakeConstraints { make in
                make.top.equalTo(cell.arrowImageView.snp.bottom).offset(20)
                make.centerX.equalTo(cell.arrowImageView.snp.centerX)
                make.size.equalTo(22)
            }
            cell.uploadButton.isHidden = true
            cell.deleteButton.isHidden = true
        } else {
            cell.shareButton.snp.remakeConstraints { make in
                make.centerY.equalTo(cell.deleteButton.snp.centerY)
                make.right.equalTo(cell.uploadButton.snp.left).offset(-40)
                make.size.equalTo(22)
            }
            cell.uploadButton.isHidden = false
            cell.deleteButton.isHidden = false
        }

        cell.uploadButton.onTapped { [weak self] _ in
            self?.uploadRecordData(at: indexPath.row)
        }
        cell.deleteButton.onTapped { [weak self] _ in
            self?.deleteRecordData(at: indexPath.row)
        }
        cell.shareButton.onTapped { [weak self] _ in
            self?.shareFile(at: indexPath.row)
        }
        cell.playButton.onTapped { [weak self] _ in
            self?.playFile(at: indexPath.row)
        }
        cell.uploadProgressView.onViewTapped { [weak self] _ in
            self?.stopUpload(at: indexPath.row)
        }
        return cell
    }
}

extension TKPracticeRecordingListViewController {
    override func bindEvent() {
        super.bindEvent()
        doneButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.practice.done = true
            switch self.style {
            case .studentCompletePracticeWithAudio, .studentCompletePracticeWithVideo:
                self.showFullScreenLoading()
                self.saveData { [weak self] error in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        if let error = error {
                            logger.error("保存失败: \(error)")
                            TKToast.show(msg: "Save failed, please try again later.", style: .error)
                        }
                        self.hideFullScreenLoading()
                        self.hide()
                    }
                }
            case .studentView:
                if !self.needSave {
                    self.hide()
                } else {
                    self.showFullScreenLoading()
                    self.saveData { [weak self] error in
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            if let error = error {
                                logger.error("保存失败: \(error)")
                                TKToast.show(msg: "Save failed, please try again later.", style: .error)
                            }
                            self.hideFullScreenLoading()
                            self.hide()
                        }
                    }
                }
            case .teacherView:
                DispatchQueue.main.async {
                    self.hide()
                }
            }
        }
    }

    private func saveData(completion: @escaping (Error?) -> Void) {
        for itemData in recordData {
            for (i, item) in practice.recordData.enumerated() {
                if itemData.id == item.id {
                    practice.recordData[i] = itemData
                }
            }
        }
        if practice.teacherId == "", let teacherId = ListenerService.shared.studentData.studentData?.teacherId {
            practice.teacherId = teacherId
        }
        logger.debug("当前要保存的练习数据: \(practice.toJSONString() ?? "")")
        LessonService.lessonSchedule.updatePracticeData(practice) { error in
            completion(error)
        }
    }
}

extension TKPracticeRecordingListViewController {
    private func stopUpload(at index: Int) {
        let recordData = recordData[index]
        if let task = uploadTasks[recordData.id] {
            task.cancel()
        }
        uploadTasks.removeValue(forKey: recordData.id)
        uploadProgress.removeValue(forKey: recordData.id)
        for (i, item) in self.recordData.enumerated() {
            if item.id == recordData.id {
                tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .none)
            }
        }
    }

    private func uploadRecordData(at index: Int) {
        let recordData = recordData[index]
        guard !recordData.upload else { return }
        let filePath: String
        if recordData.format == ".mp4" {
            let folderPath = StorageService.shared.getPracticeFileFolderPath()
            filePath = "\(folderPath)/\(recordData.id)\(recordData.format)"
        } else {
            filePath = "\(RecorderTool.sharedManager.composeDir())log-\(recordData.id)\(recordData.format)"
        }
        logger.debug("要上传的文件URL: \(filePath)")

        let toURL = "/practice/\(recordData.id)\(recordData.format)"
        needSave = true
        uploadProgress[recordData.id] = 0.0
        for (i, item) in self.recordData.enumerated() {
            if item.id == recordData.id {
                if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? RecordItemTableViewCell {
                    if cell.uploadProgressView.isHidden {
                        cell.uploadProgressView.isHidden = false
                    }
                    if !cell.uploadButton.isHidden {
                        cell.uploadButton.isHidden = true
                    }
                }
            }
        }
        StorageService.shared.uploadLocalFile(with: URL(fileURLWithPath: filePath), to: toURL) { [weak self] progress, task in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.uploadTasks[recordData.id] = task
                self.uploadProgress[recordData.id] = Float(progress)
                for (i, item) in self.recordData.enumerated() {
                    if item.id == recordData.id {
                        if let cell = self.tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? RecordItemTableViewCell {
                            let fileSize: String
                            if recordData.fileSize < 600 {
                                fileSize = "\(recordData.fileSize)KB"
                            } else {
                                fileSize = "\((Double(recordData.fileSize) / 1048576).roundTo(places: 2))MB"
                            }
                            let uploadedFileSize: Int = Int(progress * Double(recordData.fileSize))
                            let uploadFileSize: String
                            if uploadedFileSize < 600 {
                                uploadFileSize = "\(uploadedFileSize)KB"
                            } else {
                                uploadFileSize = "\((Double(uploadedFileSize) / 1048576).roundTo(places: 2))MB"
                            }
                            cell.timeLengthLabel.text = "\(uploadFileSize) / \(fileSize)"
                            cell.uploadProgressView.progress = progress
                            if cell.uploadProgressView.isHidden {
                                cell.uploadProgressView.isHidden = false
                            }
                            if !cell.uploadButton.isHidden {
                                cell.uploadButton.isHidden = true
                            }
                        }
                        break
                    }
                }
            }
        } completion: { [weak self] error in
            guard let self = self else { return }
            self.uploadProgress.removeValue(forKey: recordData.id)
            if let error = error {
                logger.error("上传文件失败: \(error)")
                let err = error as NSError
                if err.code == -13040 {
                    TKToast.show(msg: "Your uploading has been removed!", style: .success)
                } else {
                    TKToast.show(msg: "Upload failed, please try again later.", style: .error)
                }
            } else {
                DispatchQueue.main.async {
                    CommonsService.shared.sendNotificationForStudentUploadedPracticeFile(practiceId: self.practice.id)
                    for (i, item) in self.recordData.enumerated() {
                        if item.id == recordData.id {
                            self.recordData[i].upload = true
                            logger.debug("重新渲染: \(i)")
                            self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .none)
                            break
                        }
                    }
                    TKToast.show(msg: "Upload successfully", style: .success)
                    self.saveData { _ in
                    }
                }
            }
        }
    }
}

extension TKPracticeRecordingListViewController {
    private func deleteRecordData(at index: Int) {
        let data = recordData[index]
        // 判断当前文件是否存在于本地和云上
        let isUploaded = data.upload
        if isUploaded {
            // 不管本地的是否存在
            SL.Alert.show(
                target: self,
                title: "Remove recording?",
                message: "Tap on 'Cloud Only', your recording will be removed from the cloud, not local file. You still can access it on your device.",
                leftButttonString: "Cancel",
                centerButttonString: "Cloud & Local",
                rightButtonString: "Cloud Only"
            ) {
            } centerButtonAction: { [weak self] in
                guard let self = self else { return }
                self.deleteRecordDataAfterAlert(atIndex: index)
            } rightButtonAction: { [weak self] in
                guard let self = self else { return }
                self.deleteRecordDataFile(atIndex: index)
            } onShow: { alert in
                alert.rightButton.textColor(color: ColorUtil.red)
                alert.centerButton.textColor(color: ColorUtil.red)
                alert.leftButton.textColor(color: ColorUtil.main)
            }
        } else {
            SL.Alert.show(
                target: self,
                title: "Delete recording?",
                message: "Your recording will be deleted permanently, are you sure to continue?",
                leftButttonString: "Delete",
                rightButtonString: "Cancel",
                leftButtonColor: ColorUtil.red,
                rightButtonColor: ColorUtil.main
            ) { [weak self] in
                guard let self = self else { return }
                self.deleteRecordDataAfterAlert(atIndex: index)
            } rightButtonAction: {
            }
        }
    }

    private func deleteRecordDataFile(atIndex index: Int) {
        let data = recordData[index]
        guard data.upload else { return }
        recordData[index].upload = false
        practice.recordData[index].upload = false
        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        showFullScreenLoadingNoAutoHide()
        saveData { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.hideFullScreenLoading()
                self.tableView.reloadData()
                if let error = error {
                    logger.error("保存失败: \(error)")
                    self.recordData[index].upload = true
                    self.practice.recordData[index].upload = true
                    TKToast.show(msg: "Remove failed, please try again later.", style: .error)
                } else {
                    TKToast.show(msg: "Remove successfully", style: .success)
                }

                let path = "/practice/\(data.id)\(data.format)"
                logger.debug("删除文件: \(path)")
                Storage.storage().reference().child(path)
                    .delete { error in
                        logger.debug("删除文件完成: \(String(describing: error)) | \(path)")
                    }
            }
        }
    }

    private func deleteRecordDataAfterAlert(atIndex index: Int) {
        let data = recordData[index]
        recordData.remove(at: index)
        for (i, item) in practice.recordData.enumerated() {
            if item.id == data.id {
                practice.recordData.remove(at: i)
                break
            }
        }
        showFullScreenLoadingNoAutoHide()
        saveData { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("保存失败: \(error)")
                    self.recordData.insert(data, at: index)
                    self.practice.recordData.append(data)
                    TKToast.show(msg: "Remove failed, please try again later.", style: .error)
                } else {
                    TKToast.show(msg: "Remove successfully", style: .success)
                    if self.practice.recordData.isEmpty {
                        self.hide()
                    }
                    let path = "/practice/\(data.id)\(data.format)"
                    logger.debug("删除文件: \(path)")
                    Storage.storage().reference().child(path)
                        .delete { error in
                            logger.debug("删除文件完成: \(String(describing: error)) | \(path)")
                        }
                }
                self.tableView.reloadData()
            }
        }
    }

    private func shareFile(at index: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let data = self.recordData[index]
            let folderPath = StorageService.shared.getPracticeFileFolderPath()
            let filePath = "\(folderPath)/\(data.id)\(data.format)"
            let fileURL = URL(fileURLWithPath: filePath)

            var filesToShare: [Any] = []
            if FileManager.default.fileExists(atPath: filePath) {
                filesToShare.append(fileURL)
            } else {
                guard data.upload else {
                    TKToast.show(msg: "This practice record haven't upload yet.", style: .error)
                    return
                }
                filesToShare.append(StorageService.shared.getPracticeFileURL(id: data.id, format: data.format))
            }
            let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
        }
    }

    private func playFile(at index: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let data = self.recordData[index]
            if data.format == ".mp4" {
                let folderPath = StorageService.shared.getPracticeFileFolderPath()
                let filePath = "\(folderPath)/\(data.id)\(data.format)"
                let fileURL = URL(fileURLWithPath: filePath)
                if !FileManager.default.fileExists(atPath: filePath) {
                    guard data.upload else {
                        TKToast.show(msg: "This practice record haven't upload yet.", style: .error)
                        return
                    }
                    guard let url = URL(string: StorageService.shared.getPracticeFileURL(id: data.id, format: data.format)) else {
                        return
                    }
                    self.playVideo(url: url, data: data)
                } else {
                    self.playVideo(url: fileURL, data: data)
                }
            } else {
                let controller = TeacherPlayAudioController()
                controller.url = ""
                controller.from = .practice
                controller.practice = self.practice
                controller.recordData = data
                controller.name = self.practice.name
                controller.modalPresentationStyle = .custom
                Tools.getTopViewController()?.present(controller, animated: false, completion: nil)
            }
        }
    }

    private func playVideo(url: URL, data: PracticeRecord) {
        let playerViewController = AVPlayerViewController()
        let downloadProgressView: RingProgressView = RingProgressView()
        downloadProgressView.tintColor = .white
        downloadProgressView.startColor = .white
        downloadProgressView.endColor = .white
        downloadProgressView.ringWidth = 4
        var needDownload: Bool = false
        if url.absoluteString.contains("https://") {
            needDownload = true
            let folderPath = StorageService.shared.getPracticeFileFolderPath()
            let filePath = "\(folderPath)/\(data.id)\(data.format)"
            StorageService.shared.downloadFile(url: url.absoluteString, saveTo: filePath) { [weak self] progress, task in
                logger.debug("下载进度: \(progress)")
                downloadProgressView.progress = progress
                self?.currentVideoDownloadTask = task
            } completion: { error in
                if let error = error {
                    logger.error("下载视频失败: \(error)")
                } else {
                    downloadProgressView.removeFromSuperview()
                    let fileURL = URL(fileURLWithPath: filePath)
                    let player = AVPlayer(url: fileURL)
                    playerViewController.player = player
                    player.play()
                }
            }
        } else {
            let player = AVPlayer(url: url)
            playerViewController.player = player
        }
        
        Tools.getTopViewController()?.present(playerViewController, animated: true) {
            if !needDownload {
                playerViewController.player?.play()
            } else {
                downloadProgressView.progress = 0
                downloadProgressView.addTo(superView: playerViewController.view) { make in
                    make.center.equalToSuperview()
                    make.size.equalTo(40)
                }
                playerViewController.view.bringSubviewToFront(downloadProgressView)
            }
            if let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate {
                appdelegate.isForceAllDerictions = true
            }
        }
    }
}

extension TKPracticeRecordingListViewController {
    class RecordItemTableViewCell: UITableViewCell {
        static let id: String = String(describing: RecordItemTableViewCell.self)

        var isOpen: Bool = false

        var containerView: TKView = TKView.create().backgroundColor(color: .white)

        var timeLabel: TKLabel = TKLabel.create().font(font: FontUtil.medium(size: 17)).textColor(color: ColorUtil.Font.second)
        var timeLengthLabel: TKLabel = TKLabel.create().font(font: FontUtil.regular(size: 13)).textColor(color: ColorUtil.Font.fourth).alignment(alignment: .right)
        var arrowImageView: TKImageView = TKImageView.create()
            .setImage(name: "icArrowTop")
        var playButton: TKButton = TKButton.create()
        var shareButton: TKButton = TKButton.create().setImage(name: "ic_share_primary", size: CGSize(width: 22, height: 22))
        var uploadButton: TKButton = TKButton.create().setImage(name: "ic_upload_primary", size: CGSize(width: 22, height: 22))
        var deleteButton: TKButton = TKButton.create().setImage(name: "ic_delete_gray", size: CGSize(width: 22, height: 22))

        var uploadProgressView: RingProgressView = {
            let progressView = RingProgressView()
            let color: UIColor = UIColor(hex: "#7FDEFE")!
            progressView.tintColor = color
            progressView.ringWidth = 2
            progressView.startColor = color
            progressView.endColor = color
            return progressView
        }()

        var bottomLine: TKView = TKView.create()
            .backgroundColor(color: ColorUtil.dividingLine)

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            initViews()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func initViews() {
            selectionStyle = .none
            containerView.addTo(superView: contentView) { make in
                make.top.left.right.bottom.equalToSuperview()
            }
            containerView.clipsToBounds = true
            arrowImageView.addTo(superView: containerView) { make in
                make.top.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.size.equalTo(22)
            }

            timeLengthLabel.addTo(superView: containerView) { make in
                make.right.equalTo(arrowImageView.snp.left).offset(-10)
                make.centerY.equalTo(arrowImageView.snp.centerY)
            }

            timeLabel.addTo(superView: containerView) { make in
                make.top.equalToSuperview().offset(20)
                make.left.equalToSuperview().offset(20)
                make.right.equalTo(timeLengthLabel.snp.left).offset(-10)
                make.height.equalTo(20)
                make.bottom.equalToSuperview().offset(-20).priority(.medium)
            }

            deleteButton.addTo(superView: containerView) { make in
                make.top.equalTo(timeLabel.snp.bottom).offset(20)
                make.centerX.equalTo(arrowImageView.snp.centerX)
                make.size.equalTo(22)
            }

            uploadButton.addTo(superView: containerView) { make in
                make.centerY.equalTo(deleteButton.snp.centerY)
                make.right.equalTo(deleteButton.snp.left).offset(-40)
                make.size.equalTo(22)
            }

            shareButton.addTo(superView: containerView) { make in
                make.centerY.equalTo(deleteButton.snp.centerY)
                make.right.equalTo(uploadButton.snp.left).offset(-40)
                make.size.equalTo(22)
            }

            playButton.addTo(superView: containerView) { make in
                make.centerY.equalTo(deleteButton.snp.centerY)
                make.right.equalTo(shareButton.snp.left).offset(-40)
                make.size.equalTo(22)
            }

            bottomLine.addTo(superView: containerView) { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(0.5)
                make.bottom.equalToSuperview().offset(-1)
            }

            uploadProgressView.addTo(superView: containerView) { make in
                make.center.equalTo(uploadButton.snp.center)
                make.size.equalTo(22)
            }
        }
    }
}
