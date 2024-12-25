//
//  MaterialsGoogleDriveChildViewController.swift
//  TuneKey
//
//  Created by zyf on 2020/12/24.
//  Copyright © 2020 spelist. All rights reserved.
//

import Alamofire
import DZNEmptyDataSet
import FirebaseAuth
import MJRefresh
import NVActivityIndicatorView
import UIKit

protocol MaterialsGoogleDriveChildViewControllerDelegate: AnyObject {
    func materialsGoogleDriveChildViewController(tokenChanged token: GoogleAuthToken)
    func materialsGoogleDriveChildViewController(selectedFilesChanged files: [GoogleDriveFile], for type: MaterialsGoogleDriveViewController.ChildControllerType)
    func materialsGoogleDriveChildViewControllerAuthFailed()
    func materialsGoogleDriveChildViewController(selectedImage image: UIImage, id: String)
}

class MaterialsGoogleDriveChildViewController: TKBaseViewController {
    weak var delegate: MaterialsGoogleDriveChildViewControllerDelegate?

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

    private var refreshFooter: MJRefreshAutoNormalFooter?

    private var isLoaded: Bool = false
    private var isAllFilesLoaded: Bool = false

    var token: GoogleAuthToken?

    private var files: [String] = []
    private var dataSource: [String: GoogleDriveFile] = [:]
    private var selectedFiles: [String] = [] {
        didSet {
            let result = selectedFiles.compactMap { dataSource[$0] }
            logger.debug("返回的已选择的文件：\(result.count)")
            delegate?.materialsGoogleDriveChildViewController(selectedFilesChanged: result, for: type)
        }
    }

    private var nextPageToken: String = ""

    private var excludeFiles: [String] = []
    var type: MaterialsGoogleDriveViewController.ChildControllerType = .audio

    private var failedCount: Int = 0

    convenience init(excludeFiles: [String] = []) {
        self.init(nibName: nil, bundle: nil)
        self.excludeFiles = excludeFiles
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.debug("显示视图，开始判断是否加载过")
        if isLoaded {
            listFiles()
        } else {
            loadData()
        }
    }
}

extension MaterialsGoogleDriveChildViewController {
    private func getMimeType() -> String {
        switch type {
        case .audio: return "(mimeType='application/vnd.google-apps.audio' or mimeType contains 'audio/')"
        case .photo: return "(mimeType='application/vnd.google-apps.photo' or mimeType contains 'image/')"
        case .video: return "(mimeType='application/vnd.google-apps.video' or mimeType contains 'video/')"
        case .document: return "mimeType='application/vnd.google-apps.document'"
        case .spreadsheet: return "mimeType='application/vnd.google-apps.spreadsheet'"
        case .presentation: return "mimeType='application/vnd.google-apps.presentation'"
        case .form: return "mimeType='application/vnd.google-apps.form'"
        case .drawing: return "mimeType='application/vnd.google-apps.drawing'"
        case .pdf: return "mimeType='application/pdf'"
        }
    }
}

extension MaterialsGoogleDriveChildViewController {
    override func initView() {
        super.initView()
        let itemWidth = (UIScreen.main.bounds.width - 50) / 3
        collectionViewLayout.itemSize = CGSize(width: itemWidth, height: 160)
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 5
        collectionViewLayout.sectionInsetReference = .fromContentInset
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.emptyDataSetSource = self
        collectionView.contentInset = .init(top: 20, left: 20, bottom: 20, right: -20)
        collectionView.backgroundColor = ColorUtil.backgroundColor
        collectionView.addTo(superView: view) { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        let footer = MJRefreshAutoNormalFooter { [weak self] in
            guard let self = self, !self.isAllFilesLoaded else { return }
            self.listFiles()
        }
        footer.isRefreshingTitleHidden = true
        collectionView.mj_footer = footer
        refreshFooter = footer

        collectionView.register(MaterialsGoogleDriveCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: MaterialsGoogleDriveCollectionViewCell.self))
        loadingView.addTo(superView: view) { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        loadingView.isHidden = true
    }
}

extension MaterialsGoogleDriveChildViewController {
    func loadData() {
        files.removeAll()
        dataSource.removeAll()
        selectedFiles.removeAll()
        listFiles()
    }

    private func listFiles() {
        guard let token = token else { return }
        if isLoaded {
            refreshFooter?.beginRefreshing()
        } else {
            loadingView.isHidden = false
        }
        logger.debug("开始加载数据，token: \("Bearer \(token.accessToken)")")
        isLoaded = true
        let task = AF.request("https://www.googleapis.com/drive/v3/files",
                              method: .get,
                              parameters: ["fields": "*", "pageToken": nextPageToken, "q": getMimeType()],
                              headers: ["Authorization": "Bearer \(token.accessToken)"])

        task.responseJSON { [weak self] response in
            guard let self = self else { return }
            guard let data = response.data, let dataString = String(data: data, encoding: .utf8) else {
                return
            }
            if dataString.contains("error") {
                task.cancel()
                logger.debug("返回错误： \(dataString)")
                if dataString.contains("authError") {
                    self.delegate?.materialsGoogleDriveChildViewControllerAuthFailed()
                    return
                } else {
                    self.failedCount += 1
                    if self.failedCount >= 5 {
                        self.failedCount = 0
                        self.delegate?.materialsGoogleDriveChildViewControllerAuthFailed()
                        return
                    } else {
                        self.refreshFooter?.endRefreshing()
                        UserService.user.refreshGoogleAuthToken(type: .drive)
                            .done { tokenData in
                                self.token = tokenData
                                self.delegate?.materialsGoogleDriveChildViewController(tokenChanged: token)
                                logger.debug("重新刷新了token")
                                self.listFiles()
                            }
                            .catch { error in
                                logger.error("刷新失败: \(error)")
                                DispatchQueue.main.async {
                                    self.loadingView.isHidden = true
                                }
                            }
                    }
                }
                return
            } else if let result = GoogleDriveList.deserialize(from: dataString) {
                if self.nextPageToken == "" {
                    self.files = result.files.filter { !self.excludeFiles.contains($0.id) }.compactMap { $0.id }
                } else {
                    self.files += result.files.filter { !self.excludeFiles.contains($0.id) }.compactMap { $0.id }
                }
                result.files.forEach { file in
                    self.dataSource[file.id] = file
                }
                logger.debug("获取数据成功,数量: \(self.files.count)")
                self.loadingView.isHidden = true
                self.collectionView.reloadData()
                self.nextPageToken = result.nextPageToken
                if result.nextPageToken == "" {
                    self.isAllFilesLoaded = true
                    // 没有下一页
                    self.refreshFooter?.isHidden = true
                    self.refreshFooter?.endRefreshingWithNoMoreData()
                } else {
                    self.refreshFooter?.endRefreshing()
                }
            } else {
                logger.error("返回错误: \(response)")
                self.loadingView.isHidden = true
            }
        }
    }
}

extension MaterialsGoogleDriveChildViewController: MaterialsGoogleDriveCollectionViewCellDelegate {
    func materialsGoogleDriveCollectionViewCell(didSelect cell: MaterialsGoogleDriveCollectionViewCell, isSelected: Bool, file: GoogleDriveFile, withImage image: UIImage?) {
        logger.debug("选中：\(isSelected) | \(file.id)")
        if isSelected {
            selectedFiles.append(file.id)
        } else {
            selectedFiles.removeElements { $0 == file.id }
        }
        if let image = image {
            delegate?.materialsGoogleDriveChildViewController(selectedImage: image, id: file.id)
        }
    }
}

extension MaterialsGoogleDriveChildViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return files.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MaterialsGoogleDriveCollectionViewCell.self), for: indexPath) as! MaterialsGoogleDriveCollectionViewCell
        if files.isSafeIndex(indexPath.item) {
            if let file = dataSource[files[indexPath.item]] {
                cell.isSelected = selectedFiles.contains(file.id)
                cell.loadData(file: file)
            }
        }
        cell.delegate = self
        return cell
    }
}

extension MaterialsGoogleDriveChildViewController: DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        UIImage(named: "imgNoMaterials")!
    }
}
