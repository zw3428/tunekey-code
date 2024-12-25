//
//  MaterialsGooglePhotoViewController.swift
//  TuneKey
//
//  Created by zyf on 2020/12/18.
//  Copyright © 2020 spelist. All rights reserved.
//

import FirebaseCore
import Alamofire
import FirebaseAuth
import MJRefresh
import NVActivityIndicatorView
import UIKit
import GoogleSignIn
import GTMAppAuth

protocol MaterialsGooglePhotoViewControllerDelegate: AnyObject {
    func materialsGooglePhotoViewController(uploadFiles: [GooglePhotoMediaItem])
}

class MaterialsGooglePhotoViewController: TKBaseViewController {
    weak var delegate: MaterialsGooglePhotoViewControllerDelegate?

    private var titleLabel: TKLabel = TKLabel.create()
        .font(font: FontUtil.medium(size: 16))
        .textColor(color: ColorUtil.main)
        .text(text: "Google Photo")
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
        let button: TKBlockButton = TKBlockButton(frame: .zero, title: "Request google photo permission")
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

    private var token: GoogleAuthToken? {
        didSet {
            loadData()
        }
    }

    private var files: [String] = []
    private var dataSource: [String: GooglePhotoMediaItem] = [:]
    private var selectedFiles: [String] = []

    private var nextPageToken: String = ""
    private var isAllFilesLoaded: Bool = false

    private var excludeFiles: [String] = []

    convenience init(excludeFiles: [String] = []) {
        self.init(nibName: nil, bundle: nil)
        self.excludeFiles = excludeFiles
    }

    deinit {
        logger.debug("销毁 Google Photos controller")
    }
}

extension MaterialsGooglePhotoViewController {
    override func initView() {
        super.initView()
        titleLabel.addTo(superView: view) { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(20)
        }
        let buttonWidth = (UIScreen.main.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right - 50) / 2
        closeButton.addTo(superView: view) { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(20)
            make.height.equalTo(50)
            make.width.equalTo(buttonWidth)
        }

        uploadButton.addTo(superView: view) { make in
            make.bottom.equalTo(closeButton.snp.bottom)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-20)
            make.height.equalTo(50)
            make.width.equalTo(buttonWidth)
        }

        let itemWidth = (UIScreen.main.bounds.width - 50) / 3
        collectionViewLayout.itemSize = CGSize(width: itemWidth, height: 130)
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 5
//        collectionViewLayout.sectionInsetReference = .fromContentInset
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.contentInset = .init(top: 20, left: 20, bottom: 20, right: -20)
        collectionView.backgroundColor = ColorUtil.backgroundColor
        collectionView.addTo(superView: view) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(closeButton.snp.top).offset(-10)
        }
        collectionView.register(MaterialsGooglePhotoCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: MaterialsGooglePhotoCollectionViewCell.self))
        let footer = MJRefreshAutoNormalFooter { [weak self] in
            guard let self = self, !self.isAllFilesLoaded else { return }
            self.listFiles()
        }
        footer.isRefreshingTitleHidden = true
        collectionView.mj_footer = footer
        refreshFooter = footer

        loadingView.addTo(superView: view) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(closeButton.snp.top).offset(-10)
        }

        getTokenView.addTo(superView: view) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(closeButton.snp.top).offset(-10)
        }
        getTokenView.isHidden = true
        updateUploadButton()
    }

    private func updateUploadButton() {
        if selectedFiles.count > 0 {
            uploadButton.enable()
        } else {
            uploadButton.disable()
        }
    }

    override func bindEvent() {
        super.bindEvent()
        closeButton.onTapped { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }

        uploadButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            let files: [GooglePhotoMediaItem] = self.selectedFiles.compactMap { self.dataSource[$0] }
            self.dismiss(animated: true) {
                self.delegate?.materialsGooglePhotoViewController(uploadFiles: files)
            }
        }
    }
}

extension MaterialsGooglePhotoViewController {
    override func initData() {
        super.initData()
        initAuth()
    }

    private func loadData() {
        loadingView.isHidden = false
        getTokenView.isHidden = true
        listFiles()
    }

    private func listFiles() {
        guard !isAllFilesLoaded else { return }
        guard let token = token else {
            logger.error("获取token失败")
            return
        }
        refreshFooter?.beginRefreshing()
        AF.request("https://photoslibrary.googleapis.com/v1/mediaItems",
                   parameters: ["pageSize": 50, "pageToken": nextPageToken],
                   headers: ["Authorization": "Bearer \(token.accessToken)"])
            .responseJSON { [weak self] response in
                guard let self = self else { return }
                guard let data = response.data, let dataString = String(data: data, encoding: .utf8) else {
                    return
                }
                logger.debug("获取到的结果: \(dataString)")
                if dataString.contains("error") {
                    UserService.user.refreshGoogleAuthToken(type: .photos)
                        .done { tokenData in
                            self.token = tokenData
                            self.listFiles()
                        }
                        .catch { error in
                            logger.error("刷新失败: \(error)")
                            DispatchQueue.main.async {
                                self.loadingView.isHidden = true
                                self.getTokenView.isHidden = false
                            }
                        }
                    return
                } else if let result = GooglePhotoMediaItemsListResult.deserialize(from: dataString) {
                    if self.nextPageToken == "" {
                        self.files = result.mediaItems
                            .filter {
                                if $0.mimeType.contains("video") {
                                    return false
                                }
                                if !self.excludeFiles.contains($0.id) {
                                    return true
                                }
                                return true
                            }.compactMap { $0.id }
                    } else {
                        self.files += result.mediaItems
                            .filter {
                                if $0.mimeType.contains("video") {
                                    return false
                                }
                                if !self.excludeFiles.contains($0.id) {
                                    return true
                                }
                                return true
                            }.compactMap { $0.id }
                    }
                    result.mediaItems.forEach { item in
                        self.dataSource[item.id] = item
                    }

                    logger.debug("获取数据成功, 数量: \(self.files.count)")
                    self.loadingView.isHidden = true
                    self.getTokenView.isHidden = true
                    self.collectionView.reloadData()
                    self.nextPageToken = result.nextPageToken
                    if result.nextPageToken == "" {
                        self.isAllFilesLoaded = true
                        // 没有下一页
                        self.refreshFooter?.endRefreshingWithNoMoreData()
                    } else {
                        self.refreshFooter?.endRefreshing()
                    }
                } else {
                    logger.error("返回错误: \(response.description)")
                    self.loadingView.isHidden = true
                    self.getTokenView.isHidden = false
                }
            }
    }

    private func initAuth() {
        UserService.user.getGoogleAuthToken(type: .photos)
            .done { [weak self] token in
                guard let self = self else { return }
                if let token = token {
                    if !token.scope.contains(GlobalFields.GoogleAuthScope.photo) {
                        var scopes: [String] = []
                        if token.scope.contains(GlobalFields.GoogleAuthScope.calendar) {
                            scopes.append(GlobalFields.GoogleAuthScope.calendar)
                        }
                        if token.scope.contains(GlobalFields.GoogleAuthScope.drive) {
                            scopes.append(GlobalFields.GoogleAuthScope.drive)
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
}

extension MaterialsGooglePhotoViewController {
    private func showGoogleSignIn(originalScopes: [String]) {
        logger.debug("准备登陆")
        loadingView.isHidden = false
        getTokenView.isHidden = true
//        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
//        GIDSignIn.sharedInstance()?.serverClientID = "276871124610-s00jpqv805isouub987hceercr7qsc0v.apps.googleusercontent.com"
////        var scopes = GIDSignIn.sharedInstance()?.scopes
////        scopes?.append(GlobalFields.GoogleAuthScope.photo)
////        originalScopes.forEach { scope in
////            scopes?.append(scope)
////        }
//        GIDSignIn.sharedInstance().scopes = [GlobalFields.GoogleAuthScope.photo]
//        GIDSignIn.sharedInstance().delegate = self
//        GIDSignIn.sharedInstance().presentingViewController = self
//        GIDSignIn.sharedInstance().signIn()
        
        GIDSignIn.sharedInstance.configuration = .init(clientID: FirebaseApp.app()?.options.clientID ?? "", serverClientID: "276871124610-s00jpqv805isouub987hceercr7qsc0v.apps.googleusercontent.com")
        GIDSignIn.sharedInstance.signIn(withPresenting: self, hint: nil, additionalScopes: [GlobalFields.GoogleAuthScope.photo]) { [weak self] result, error in
            guard let self = self else { return }
            if let err = error {
                logger.error("登录失败: \(err)")
                TKToast.show(msg: "Link google calendar failed: \(err.localizedDescription)", style: .error)
                loadingView.isHidden = true
            } else {
                self.loadingView.isHidden = false
                if let user = result?.user, let serverAuthCode = result?.serverAuthCode {
                    let token = user.accessToken.tokenString
                    logger.debug("登录完成, token: \(String(describing: token))")
                    logger.debug("登录完成,server auth code: \(serverAuthCode)")
                    logger.debug("登录完成,scopes: \(String(describing: user.grantedScopes))")
                    UserService.user.requestAuthForGoogle(code: serverAuthCode, type: .photos)
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

//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//        if let err = error {
//            logger.error("登录失败: \(err)")
//            TKToast.show(msg: "Link google calendar failed: \(err.localizedDescription)", style: .error)
//            loadingView.isHidden = true
//        } else {
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                self.loadingView.isHidden = false
//                if let user = user {
//                    let token = user.authentication.accessToken
//                    logger.debug("登录完成, token: \(String(describing: token))")
//                    logger.debug("登录完成,server auth code: \(String(describing: user.serverAuthCode))")
//                    logger.debug("登录完成,scopes: \(String(describing: user.grantedScopes))")
//                    UserService.user.requestAuthForGoogle(code: user.serverAuthCode, type: .photos)
//                        .done { token in
//                            logger.debug("请求token完成")
//                            self.loadingView.isHidden = true
//                            if let token = token {
//                                self.token = token
//                            } else {
//                                self.getTokenView.isHidden = false
//                            }
//                        }
//                        .catch { error in
//                            logger.error("请求token失败: \(error)")
//                            self.loadingView.isHidden = true
//                            self.getTokenView.isHidden = false
//                        }
//                } else {
//                    TKToast.show(msg: "You cancelled link google calendar", style: .warning)
//                    self.loadingView.isHidden = true
//                    self.getTokenView.isHidden = false
//                }
//            }
//        }
//    }
}

extension MaterialsGooglePhotoViewController: UICollectionViewDataSource, MaterialsGooglePhotoCollectionViewCellDelegate {
    func materialsGooglePhotoCollectionViewCell(didSelect cell: MaterialsGooglePhotoCollectionViewCell, isSelected: Bool, file: GooglePhotoMediaItem) {
        logger.debug("cell点击选中: \(isSelected)")
        if isSelected {
            selectedFiles.append(file.id)
        } else {
            selectedFiles.removeElements { $0 == file.id }
        }
        updateUploadButton()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        files.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MaterialsGooglePhotoCollectionViewCell.self), for: indexPath) as! MaterialsGooglePhotoCollectionViewCell
        cell.delegate = self
        if let item = dataSource[files[indexPath.item]] {
            cell.loadData(file: item)
        }
        return cell
    }
}
