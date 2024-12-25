//
//  MaterialsGoogleDriverViewController.swift
//  TuneKey
//
//  Created by zyf on 2020/12/11.
//  Copyright © 2020 spelist. All rights reserved.
//
import Alamofire
import FirebaseAuth
import MJRefresh
import NVActivityIndicatorView
import UIKit
import GoogleSignIn
import GTMAppAuth

struct GoogleDriveMaterialPredownloadModel {
    enum Status {
        case downloading
        case failed
        case success
    }

    var id: String
    var file: TKMaterial
    var fileURL: URL?
    var task: DownloadRequest
    var status: Status = .downloading
    var progress: Double = 0
}

protocol MaterialsGoogleDriveViewControllerDelegate: AnyObject {
    func materialsGoogleDriveViewController(uploadFiles: [GoogleDriveFile])
    func materialsGoogleDriveViewController(predownloadFilesDone files: [GoogleDriveMaterialPredownloadModel])
}

extension MaterialsGoogleDriveViewController {
    enum ChildControllerType: String {
        case audio = "Audio"
        case photo = "Photo"
        case video = "Video"
        case document = "Document"
        case spreadsheet = "Spreadsheet"
        case presentation = "Presentation"
        case form = "Form"
        case drawing = "Drawing"
        case pdf = "PDF"
    }

    enum Step {
        case step1 // 选择文件
        case step2 // 文件预下载
    }
}

class MaterialsGoogleDriveViewController: TKBaseViewController {
    private var step: Step = .step1

    weak var delegate: MaterialsGoogleDriveViewControllerDelegate?

    private var contentView: TKView = TKView.create()
        .backgroundColor(color: ColorUtil.backgroundColor)

    private var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.medium(size: 16))
        .textColor(color: ColorUtil.main)
        .text(text: "Google Drive")
        .alignment(alignment: .center)
    private var closeButton: TKBlockButton = TKBlockButton(frame: .zero, title: "BACK", style: .cancel)
    private var uploadButton: TKBlockButton = TKBlockButton(frame: .zero, title: "UPLOAD")

    private var collectionViewLayout: CollectionViewAlignFlowLayout = CollectionViewAlignFlowLayout()
    private lazy var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)

    private var loadingView: TKView = {
        let view = TKView.create()
            .backgroundColor(color: .white)
        let animateView: NVActivityIndicatorView = .init(frame: .zero, type: .circleStrokeSpin, color: ColorUtil.main, padding: 0)
        animateView.addTo(superView: view) { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
        animateView.startAnimating()
        return view
    }()

    private lazy var getTokenView: TKView = {
        let view = TKView.create()
            .backgroundColor(color: .white)
        let button: TKBlockButton = TKBlockButton(frame: .zero, title: "Request google driver permission")
        button.addTo(superView: view) { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(50)
            make.centerY.equalToSuperview()
        }
        button.onTapped { [weak self] _ in
            self?.showGoogleSignIn(originalScopes: [])
        }
        return view
    }()

    private var refreshFooter: MJRefreshAutoNormalFooter?

    private lazy var pageViewManager: PageViewManager = {
        // 创建DNSPageStyle，设置样式
        let style = PageStyle()
        style.isShowBottomLine = true
        style.isTitleViewScrollEnabled = true
        style.titleViewBackgroundColor = UIColor.clear
        style.titleColor = ColorUtil.Font.primary
        style.titleSelectedColor = ColorUtil.main
        style.bottomLineColor = ColorUtil.main
        style.bottomLineWidth = 17
        style.isContentScrollEnabled = true
        style.titleFont = FontUtil.bold(size: 15)

        titles.forEach { title in
            if let controller = controllers[title] {
                controller.delegate = self
                addChild(controller)
            }
        }
        return PageViewManager(style: style, titles: titles, childViewControllers: children)
    }()

    private var titles: [String] = []
    private var controllers: [String: MaterialsGoogleDriveChildViewController] = [:]
    private var controllerTypes: [ChildControllerType] = [.audio, .photo, .video, .document, .spreadsheet, .presentation, .form, .drawing, .pdf]

    private var predownloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 10
        return queue
    }()

    private var token: GoogleAuthToken? {
        didSet {
            loadData()
        }
    }

    private var selectedImages: [String: UIImage] = [:]

    private var selectedFiles: [ChildControllerType: [GoogleDriveFile]] = [:] {
        didSet {
            updateUploadButton()
            _selectedFiles.removeAll()
            for (_, files) in selectedFiles {
                _selectedFiles += files
            }
        }
    }

    private var _selectedFiles: [GoogleDriveFile] = []

    private var predownloadFiles: [String: GoogleDriveMaterialPredownloadModel] = [:]

    private var isAllFilesLoaded: Bool = false

    private var excludeFiles: [String] = []

    convenience init(excludeFiles: [String] = []) {
        self.init(nibName: nil, bundle: nil)
        self.excludeFiles = excludeFiles
        titles = controllerTypes.compactMap { $0.rawValue }
        titles.forEach { title in
            if let type = ChildControllerType(rawValue: title) {
                logger.debug("初始化controller，当前类型： \(title) | \(type)")
                let controller = MaterialsGoogleDriveChildViewController(excludeFiles: excludeFiles)
                controller.type = type
                controllers[title] = controller
            }
        }
    }

    deinit {
        logger.debug("销毁Controller => MaterialsGoogleDriveViewController")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }

    private func show() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        }
    }

    private func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
        } completion: { _ in
            self.dismiss(animated: false) {
                completion?()
            }
        }
    }
}

extension MaterialsGoogleDriveViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.layer.cornerRadius = 15
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.addTo(superView: view) { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height - 80)
        }

        titleLabel.addTo(superView: contentView) { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(20)
        }
        let buttonWidth = (UIScreen.main.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right - 50) / 2
        closeButton.addTo(superView: contentView) { make in
            make.bottom.equalToSuperview().offset(-UiUtil.safeAreaBottom() - 20)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(50)
            make.width.equalTo(buttonWidth)
        }

        uploadButton.addTo(superView: contentView) { make in
            make.bottom.equalTo(closeButton.snp.bottom)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(50)
            make.width.equalTo(buttonWidth)
        }

        pageViewManager.titleView.style.titleMargin = 20
        pageViewManager.titleView.addTo(superView: contentView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(24)
        }

        pageViewManager.contentView.addTo(superView: contentView) { make in
            make.top.equalTo(pageViewManager.titleView.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(closeButton.snp.top).offset(-10)
        }

        loadingView.addTo(superView: contentView) { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(closeButton.snp.top).offset(-10)
        }

        getTokenView.addTo(superView: contentView) { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(closeButton.snp.top).offset(-10)
        }
        getTokenView.isHidden = true

        collectionView.addTo(superView: contentView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(uploadButton.snp.top).offset(-10)
        }
        let itemWidth = (UIScreen.main.bounds.width - 50) / 3
        collectionViewLayout.itemSize = CGSize(width: itemWidth, height: 160)
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 5
        collectionViewLayout.sectionInsetReference = .fromContentInset
        collectionView.dataSource = self
        collectionView.register(MaterialsGoogleDriveCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: MaterialsGoogleDriveCollectionViewCell.self))
        collectionView.isHidden = true
        collectionView.backgroundColor = view.backgroundColor
        collectionView.contentInset = .init(top: 20, left: 20, bottom: 20, right: -20)
        updateUploadButton()
    }

    private func updateUploadButton() {
        var count: Int = 0
        selectedFiles.compactMap { $0.value }.forEach { list in
            count += list.count
        }
        if count > 0 {
            uploadButton.enable()
        } else {
            uploadButton.disable()
        }
    }
}

extension MaterialsGoogleDriveViewController {
    override func bindEvent() {
        super.bindEvent()
        closeButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            switch self.step {
            case .step1:
                self.hide()
            case .step2:
                self.collectionView.isHidden = true
                self.pageViewManager.contentView.isHidden = false
                self.pageViewManager.titleView.isHidden = false
                self.step = .step1
                self.predownloadQueue.cancelAllOperations()
                for (_, model) in self.predownloadFiles {
                    var _m = model
                    _m.status = .failed
                    EventBus.send(key: .googleDrivePredownloadFileProgressChanged, object: _m)
                    model.task.cancel()
                }
                self.predownloadFiles.removeAll()
                self.uploadButton.stopLoadingWithFailed()
                UIView.animate(withDuration: 0.2) {
                    self.contentView.snp.updateConstraints { make in
                        make.height.equalTo(UIScreen.main.bounds.height - 80)
                    }
                    self.contentView.layoutIfNeeded()
                }
            }
        }

        uploadButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            switch self.step {
            case .step1:
                self.pageViewManager.contentView.isHidden = true
                self.pageViewManager.titleView.isHidden = true
                self.collectionView.isHidden = false
                self.collectionView.reloadData()
                logger.debug("[Google Drvie] => 已经选择的文件有: \(self._selectedFiles.count)")
                self.step = .step2
                self.collectionView.layoutIfNeeded()
                var height = self.collectionView.contentSize.height + 120 + UiUtil.safeAreaBottom()
                let maxHeight = UIScreen.main.bounds.height - 80
                if height > maxHeight {
                    height = maxHeight
                }
                UIView.animate(withDuration: 0.2) {
                    self.contentView.snp.updateConstraints { make in
                        make.height.equalTo(height)
                    }
                    self.contentView.layoutIfNeeded()
                }

                self.predownload()
            case .step2:
                var files: [GoogleDriveFile] = []
                self.selectedFiles.compactMap { $0.value }.forEach { fileList in
                    files += fileList
                }
                files = files.filterDuplicates { $0.id }
                self.hide {
                    self.delegate?.materialsGoogleDriveViewController(uploadFiles: files)
                }
            }
        }
    }

    private func predownload() {
        uploadButton.startLoading {
        }
        // 构建所有的已选择的文件
        let uid = UserService.user.id() ?? ""
        let now = Date()
        _selectedFiles.forEach { file in
            let material = TKMaterial()
            material.id = file.id
            material.name = file.name
            material.folder = ""
            material.creatorId = uid
            material.createTime = "\(now.timestamp)"
            material.updateTime = "\(now.timestamp)"
            material.suffixName = file.fullFileExtension
            material.type = file.getTKMaterialFileType()
            var url: String = ""
            if file.webContentLink == "" {
                if file.webViewLink != "" {
                    url = file.webViewLink
                } else {
                    if file.hasThumbnail {
                        url = file.thumbnailLink
                    }
                }
            } else {
                url = file.webContentLink
            }
            material.url = url
            material.minPictureUrl = file.hasThumbnail ? file.thumbnailLink : file.iconLink
            material.fromType = .drive
            if material.type == .image || material.type == .video {
                material.status = .processing
            }

            self.predownloadQueue.addOperation { [weak self] in
                self?.downloadFileFromGoogleDrive(file: material, googleDriveFile: file)
            }
        }
    }

    private func downloadFileFromGoogleDrive(file: TKMaterial, googleDriveFile: GoogleDriveFile) {
        logger.debug("[Google Drive] => 添加新的下载任务")
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("temp").appendingPathComponent("googledrive").appendingPathComponent("\(file.id).\(googleDriveFile.fullFileExtension)")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        let task = AF.download(file.url, to: destination)
            .downloadProgress { progress in
                logger.debug("[Google Drive] => 下载进度: \(progress.completedUnitCount) / \(progress.totalUnitCount) | \(progress.fractionCompleted)")
                DispatchQueue.main.async {
                    if var file = self.predownloadFiles[file.id] {
                        file.status = .downloading
                        file.progress = progress.fractionCompleted
                        EventBus.send(key: .googleDrivePredownloadFileProgressChanged, object: file)
                    }
                }
            }
            .responseData { response in
                logger.debug("[Google Drive] => 下载完成")
                if let error = response.error {
                    // 下载失败
                    logger.error("[Google Drive] => 下载失败: \(error)")
                    DispatchQueue.main.async {
                        self.predownloadFiles[file.id]?.status = .failed
                        self.checkAllPredownloadFiles()
                    }
                } else {
                    logger.debug("[Google Drvie] => 下载之后的文件链接: \(response.fileURL?.absoluteString ?? "")")
                    // 下载成功
                    if let url = response.fileURL {
                        do {
                            let data = try Data(contentsOf: url)
                            if let string = String(data: data, encoding: .utf8) {
                                if string.contains("<html") {
                                    logger.error("[Google Drive] => 当前文件无权限下载: \(file.name)")
                                    // 判断是否是图片,如果是图片,下载缩略图
                                    if googleDriveFile.getTKMaterialFileType() == .image {
                                        if googleDriveFile.hasThumbnail {
                                            if file.url != googleDriveFile.thumbnailLink {
                                                file.url = googleDriveFile.thumbnailLink
                                                self.downloadFileFromGoogleDrive(file: file, googleDriveFile: googleDriveFile)
                                                return
                                            }
                                        }
                                    }
                                    DispatchQueue.main.async {
                                        self.predownloadFiles[file.id]?.status = .failed
                                        self.checkAllPredownloadFiles()
                                    }
                                    return
                                }
                            }
                        } catch {
                            logger.error("[Google Drive] => 加载文件失败: \(url)")
                        }
                        DispatchQueue.main.async {
                            self.predownloadFiles[file.id]?.fileURL = response.fileURL
                            self.predownloadFiles[file.id]?.status = .success
                            self.checkAllPredownloadFiles()
                        }
                    }
                }
            }
        DispatchQueue.main.async {
            var file: GoogleDriveMaterialPredownloadModel = .init(id: file.id, file: file, fileURL: nil, task: task)
            file.status = .downloading
            file.progress = 0.0
            self.predownloadFiles[file.id] = file
            EventBus.send(key: .googleDrivePredownloadFileProgressChanged, object: file)
        }
    }

    private func checkAllPredownloadFiles() {
        guard predownloadFiles.values.count > 0 else { return }
        var allDone: Bool = true
        var files: [GoogleDriveMaterialPredownloadModel] = []
        for (_, model) in predownloadFiles {
            files.append(model)
            if model.status == .downloading {
                allDone = false
                break
            }
        }

        if allDone {
            uploadButton.stopLoading { [weak self] in
                guard let self = self else { return }
                self.hide {
                    self.delegate?.materialsGoogleDriveViewController(predownloadFilesDone: files)
                }
            }
        }
    }
}

extension MaterialsGoogleDriveViewController {
    override func initData() {
        super.initData()
        initAuth()
    }

    private func initAuth() {
        UserService.user.getGoogleAuthToken(type: .drive)
            .done { [weak self] token in
                guard let self = self else { return }
                if let token = token {
                    if !token.scope.contains(GlobalFields.GoogleAuthScope.drive) {
                        var scopes: [String] = []
                        if token.scope.contains(GlobalFields.GoogleAuthScope.calendar) {
                            scopes.append(GlobalFields.GoogleAuthScope.calendar)
                        }
                        if token.scope.contains(GlobalFields.GoogleAuthScope.photo) {
                            scopes.append(GlobalFields.GoogleAuthScope.photo)
                        }
                        self.showGoogleSignIn(originalScopes: scopes)
                    } else {
                        self.token = token
                    }
                } else {
                    // 当前token未申请,唤起申请token
                    self.showGoogleSignIn(originalScopes: [])
                }
            }
            .catch { [weak self] _ in
                guard let self = self else { return }
                logger.error("获取token出错,显示主动触发按钮")
                self.loadingView.isHidden = true
                self.getTokenView.isHidden = false
            }
    }

    private func loadData() {
        loadingView.isHidden = true
        getTokenView.isHidden = true
        controllers.forEach { _, controller in
            controller.token = self.token
        }
        if let controller = controllers[titles[pageViewManager.titleView.currentIndex]] {
            logger.debug("加载数据: [\(pageViewManager.titleView.currentIndex)]")
            controller.loadData()
        }
    }
}

extension MaterialsGoogleDriveViewController {
    private func showGoogleSignIn(originalScopes: [String]) {
        loadingView.isHidden = false
        getTokenView.isHidden = true
//        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
//        GIDSignIn.sharedInstance()?.serverClientID = "276871124610-s00jpqv805isouub987hceercr7qsc0v.apps.googleusercontent.com"
////        var scopes = GIDSignIn.sharedInstance()?.scopes
////        scopes?.append(GlobalFields.GoogleAuthScope.drive)
////        originalScopes.forEach { scope in
////            scopes?.append(scope)
////        }
//        GIDSignIn.sharedInstance().scopes = [GlobalFields.GoogleAuthScope.drive]
//        GIDSignIn.sharedInstance().delegate = self
//        GIDSignIn.sharedInstance().presentingViewController = self
//        GIDSignIn.sharedInstance().signIn()
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self, hint: nil, additionalScopes: [GlobalFields.GoogleAuthScope.drive]) { [weak self] result, error in
            guard let self = self else { return }
            if let err = error {
                logger.error("登录失败: \(err)")
                TKToast.show(msg: "Link google calendar failed: \(err.localizedDescription)", style: .error)
                self.loadingView.isHidden = true
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.loadingView.isHidden = false
                    if let user = result?.user, let serverAuthCode = result?.serverAuthCode {
                        let token = user.accessToken.tokenString
                        logger.debug("登录完成, token: \(String(describing: token))")
                        logger.debug("登录完成,server auth code: \(serverAuthCode)")
                        logger.debug("登录完成,scopes: \(String(describing: user.grantedScopes))")
                        UserService.user.requestAuthForGoogle(code: serverAuthCode, type: .drive)
                            .done { token in
                                logger.debug("请求token完成")
                                self.loadingView.isHidden = true
                                if let token = token {
                                    self.token = token
                                } else {
                                    self.getTokenView.isHidden = false
                                }
                            }
                            .catch { error in
                                logger.error("请求token失败: \(error)")
                                self.loadingView.isHidden = true
                                self.getTokenView.isHidden = false
                            }
                    } else {
                        TKToast.show(msg: "You cancelled link google calendar", style: .warning)
                        self.loadingView.isHidden = true
                        self.getTokenView.isHidden = false
                    }
                }
            }
            
        }
    }
}

extension MaterialsGoogleDriveViewController: MaterialsGoogleDriveChildViewControllerDelegate {
    func materialsGoogleDriveChildViewController(selectedImage image: UIImage, id: String) {
        selectedImages[id] = image
    }

    func materialsGoogleDriveChildViewController(tokenChanged token: GoogleAuthToken) {
        self.token = token
        controllers.forEach { _, controller in
            controller.token = self.token
        }
    }

    func materialsGoogleDriveChildViewController(selectedFilesChanged files: [GoogleDriveFile], for type: ChildControllerType) {
        logger.debug("类别[\(type)] 选中的文件： \(files.count)")
        selectedFiles[type] = files
    }

    func materialsGoogleDriveChildViewControllerAuthFailed() {
        logger.debug("开始尝试刷新token")
        UserService.user.refreshGoogleAuthToken(type: .drive)
            .done { [weak self] token in
                guard let self = self else { return }
                logger.debug("刷新token成功")
                DispatchQueue.main.async {
                    self.token = token
                }
            }
            .catch { [weak self] _ in
                guard let self = self else { return }
                logger.debug("刷新token失败，唤起重新获取token")
                DispatchQueue.main.async {
                    self.getTokenView.isHidden = false
                }
            }
    }
}

extension MaterialsGoogleDriveViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        _selectedFiles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MaterialsGoogleDriveCollectionViewCell.self), for: indexPath) as! MaterialsGoogleDriveCollectionViewCell
        cell.loadData(file: _selectedFiles[indexPath.item], isSelectedType: true)
        return cell
    }
}
