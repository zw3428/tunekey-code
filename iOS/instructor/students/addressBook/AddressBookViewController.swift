//
//  AddressBookViewController.swift
//  TuneKey
//
//  Created by Wht on 2019/8/15.
//  Copyright © 2019年 spelist. All rights reserved.
//

import Contacts
import FirebaseCore
import Foundation
import GoogleSignIn
import GTMAppAuth
import SnapKit
import SWXMLHash
import UIKit

protocol AddressBookViewControllerDelegate: NSObjectProtocol {
    func addressBookViewController(_ controller: AddressBookViewController, backTappedWithId id: String)
    func addressBookViewController(_ controller: AddressBookViewController, selectedLocalContacts: [LocalContact], userInfo: [String: Any])
    func addressBookViewController(_ controller: AddressBookViewController, selectedStudents studentsIds: [String])
}

extension AddressBookViewControllerDelegate {
    func addressBookViewController(_ controller: AddressBookViewController, selectedStudents studentsIds: [String]) {
    }
}

class AddressBookViewController: TKBaseViewController {
    enum ShowType {
        case googleContact
        case addressBook
        case appContact
        case appContactSingleChoice
    }

    enum From {
        case materials
        case materialsMultiple
        case other
    }

    var userInfo: [String: Any] = [:]

    var justSelection: Bool = false

    weak var delegate: AddressBookViewControllerDelegate?
    var onStudentSelected: (([String]) -> Void)?

    var from: From = .other

    var defaultIds: [String] = []

    let SELECT_COLLECTION_TAG = 836914

    var isSelectAll: Bool = true // 是否显示select all
    var isShowSelectAll: Bool = false // 是否显示select all
    var isShowAllStudent = false
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    var searchBar: TKSearchBar!
    var searchBarContainer: TKView!
    var selectsView = UIView()
    var selectsCollectionViewLayout: UICollectionViewFlowLayout!
    var scrollBarBackView = UIView()
    var selectsCollectionView: UICollectionView!

    var studentListView = UIView()
    var studentListCollectionView: UICollectionView!
    var studentListCollectionLayout: UICollectionViewFlowLayout!
    var materials: [TKMaterial] = []
    var nextView = UIView()
    var backButton = TKBlockButton()
    var nextButton = TKBlockButton()
    var shareSilentlyButton: Button = Button().title("Share Silently", for: .normal)
        .titleColor(.clickable, for: .normal)
        .font(.content)
//    var mContacts: [CNContact] = []
    var showType: ShowType = .appContact
    var appContactsOriginalData: [TKStudent] = []
    var appContacts: [TKStudent] = []
    var appSelectContacts: [TKStudent] = [] {
        didSet {
            logger.debug("已选择的用户: \(appSelectContacts.compactMap { $0.studentId })")
            shareSilentlyButton.isEnabled = true
            if appSelectContacts.count > 0 {
                if from == .materials || from == .materialsMultiple {
                    nextButton.enable()
                    nextButton.setTitle(title: "SHARE")
                } else {
                    nextButton.enable()
                }
            } else {
                if from == .materials || from == .materialsMultiple {
                    nextButton.enable()
                    nextButton.setTitle(title: "DONE")
                } else {
                    shareSilentlyButton.isEnabled = false
                    nextButton.disable()
                }
            }

            scrollBarBackView.snp.updateConstraints { make in
                make.width.equalTo((100 * appSelectContacts.count) - 46)
            }
            if CGFloat(100 * appSelectContacts.count) >= UIScreen.main.bounds.width {
                scrollBarBackView.isHidden = false
                selectsCollectionView.showsHorizontalScrollIndicator = true
            } else {
                scrollBarBackView.isHidden = true
                selectsCollectionView.showsHorizontalScrollIndicator = false
            }
        }
    }

    var localContactStudentEmailMap: [String: Bool] = [:]
    // 本地通讯录原始数据
    var localContactsOriginalData: [LocalContact] = []
    // local 和 googleContact 的Data
    var localContacts: [LocalContact] = []
    var isLoad = false
    var localSelectContacts: [LocalContact] = [] {
        didSet {
            if localSelectContacts.count > 0 {
                nextButton.enable()
                shareSilentlyButton.isEnabled = true
            } else {
                shareSilentlyButton.isEnabled = false
                nextButton.disable()
            }

            scrollBarBackView.snp.updateConstraints { make in
                make.width.equalTo((100 * localSelectContacts.count) - 46)
            }
            if CGFloat(100 * localSelectContacts.count) >= UIScreen.main.bounds.width {
                scrollBarBackView.isHidden = false
                selectsCollectionView.showsHorizontalScrollIndicator = true
            } else {
                scrollBarBackView.isHidden = true
                selectsCollectionView.showsHorizontalScrollIndicator = false
            }
        }
    }

    var emptyView: UIView!
    var emptyImageView = UIImageView()
    var emptyLabel = TKLabel()
    var emptyButton = TKBlockButton()
    
    var isShareSilently: Bool = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        studentListCollectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if showType == .googleContact {
            if !isLoad {
                isLoad = true
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.getGoogleContact()
                }
            }
        }
        checkDefaultIds()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if #available(iOS 13, *) {
            if scrollView.subviews.count > 1 {
                let views = scrollView.subviews[scrollView.subviews.count - 1].subviews
                if let view = views.first {
                    view.backgroundColor = ColorUtil.main
                }
//                (scrollView.subviews[scrollView.subviews.count - 1].subviews[0]).backgroundColor = ColorUtil.main // verticalIndicator
            }

            if scrollView.subviews.count > 2 {
                let views = scrollView.subviews[scrollView.subviews.count - 2].subviews
                if let view = views.first {
                    view.backgroundColor = ColorUtil.main
                }
//                (scrollView.subviews[scrollView.subviews.count - 2].subviews[0]).backgroundColor = ColorUtil.main // horizontalIndicator
            }
        } else {
            if let verticalIndicator: UIImageView = (scrollView.subviews[scrollView.subviews.count - 1] as? UIImageView) {
                verticalIndicator.image = nil
                verticalIndicator.backgroundColor = ColorUtil.main
            }

            if let horizontalIndicator: UIImageView = (scrollView.subviews[scrollView.subviews.count - 2] as? UIImageView) {
                horizontalIndicator.image = nil
                horizontalIndicator.backgroundColor = ColorUtil.main
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    deinit {
        logger.debug("销毁 AddressBookViewController")
    }
}

extension AddressBookViewController: TKNormalNavigationBarDelegate {
    func backButtonTapped() {
        logger.debug("点击返回键")
        if materials.count == 1 && (from == .materials || from == .materialsMultiple) {
            logger.debug("条件符合,调用代理")
            delegate?.addressBookViewController(self, backTappedWithId: materials.first!.id)
        }
    }
}

// MARK: - View

extension AddressBookViewController {
    private func initEmptyView() {
        if emptyView != nil {
            emptyView.isHidden = false
        } else {
            emptyView = UIView()
            mainView.addSubview(emptyView)
            emptyView.addSubviews(emptyImageView, emptyLabel, emptyButton)
            emptyView.snp.makeConstraints { make in
                make.top.equalTo(navigationBar.snp.bottom).offset(51)
                make.left.equalToSuperview().offset(0)
                make.right.equalToSuperview().offset(0)
                make.height.equalTo(393)
            }
            emptyImageView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.centerX.equalToSuperview()
                make.width.equalTo(300)
                make.height.equalTo(200)
            }
            emptyLabel.snp.makeConstraints { make in
                make.top.equalTo(emptyImageView.snp.bottom).offset(30)
                make.left.equalTo(30)
                make.right.equalTo(-30)
                make.centerX.equalToSuperview()
            }
            emptyButton.snp.makeConstraints { make in
                make.top.equalTo(emptyLabel.snp.bottom).offset(65)
                make.height.equalTo(50)
                make.width.equalTo(200)
                make.centerX.equalToSuperview()
            }

            emptyImageView.image = UIImage(named: "imgNostudents")
            emptyLabel.textColor(color: ColorUtil.Font.primary).alignment(alignment: .center).font(font: FontUtil.bold(size: 16)).text("Add your students in minutes.\nIt's easy, we promise!")
            emptyLabel.numberOfLines = 0
            emptyLabel.changeLabelRowSpace(lineSpace: 0.8, wordSpace: 0.89)
            emptyButton.setTitle(title: "ADD STUDENT")
            emptyButton.onTapped { [weak self] _ in
                guard let self = self else { return }
                self.clickAddStudent()
            }
        }
    }

    override func initView() {
        view.backgroundColor = UIColor.white
        view.addSubview(mainView)

        mainView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        if isShowSelectAll {
            var title = "Contacts"
            if showType == .addressBook {
                title = "Device contacts"
            } else if showType == .googleContact {
                title = "Google contacts"
            }
            navigationBar = TKNormalNavigationBar(frame: .zero, title: "\(title)", rightButton: "Select all", rightButtonColor: ColorUtil.main, target: self, onRightButtonTapped: { [weak self] in
                self?.onNavRightButtonTapped()
            })
        } else {
            var title = "Contacts"
            if showType == .addressBook {
                title = "Device contacts"
            } else if showType == .googleContact {
                title = "Google contacts"
            }
            navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "\(title)", target: self)
        }

        navigationBar.delegate = self
        mainView.addSubviews(navigationBar, selectsView, studentListView, nextView)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initSearchBar()
        initSelectsView()
        initNextView()
        initStudentListView()
        if showType == .appContactSingleChoice {
            nextButton.isHidden = true
            shareSilentlyButton.isHidden = true
            nextView.isHidden = true
            studentListView.snp.remakeConstraints { make in
                make.top.equalTo(selectsView.snp.bottom).offset(20)
                make.right.left.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
    }

    func initSearchBar() {
        searchBar = TKSearchBar()
        searchBar.delegate = self
        searchBarContainer = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
        mainView.addSubview(searchBarContainer)
        searchBarContainer.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(36)
        }
        searchBarContainer.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.height.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
    }

    func initSelectsView() {
        selectsView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(searchBarContainer.snp.bottom).offset(0)
            // make.top.equalTo(searchBarContainer.snp.bottom).offset(20)
            // make.height.equalTo(99)
            make.height.equalTo(0)
        }
        selectsCollectionViewLayout = UICollectionViewFlowLayout()
        selectsCollectionViewLayout.itemSize = CGSize(width: 100, height: 97)
        selectsCollectionViewLayout.minimumLineSpacing = 0
        selectsCollectionViewLayout.minimumInteritemSpacing = 0
        selectsCollectionViewLayout.scrollDirection = .horizontal
        selectsCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: selectsCollectionViewLayout)
        selectsView.addSubview(selectsCollectionView)
        selectsCollectionView.bounces = false
        selectsCollectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(97)
        }
        selectsCollectionView.register(AddressBookSelectsCell.self, forCellWithReuseIdentifier: String(describing: AddressBookSelectsCell.self))

        selectsCollectionView.delegate = self
        selectsCollectionView.dataSource = self
        selectsCollectionView.backgroundColor = ColorUtil.backgroundColor
        // 滚动条偏移量
        selectsCollectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 20, bottom: selectsCollectionView.bounds.size.width, right: 20)
        selectsCollectionView.insertSubview(scrollBarBackView, at: 0)
        scrollBarBackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(23)
            make.height.equalTo(2)
            make.width.equalTo(0)
            make.top.equalToSuperview().offset(92)
        }
        // 设置滚动条一直显示
        selectsCollectionView.tag = SELECT_COLLECTION_TAG
        selectsCollectionView.flashScrollIndicators()
        selectsCollectionView.setContentHuggingPriority(.defaultLow, for: .vertical)

        if CGFloat(100 * localSelectContacts.count) >= UIScreen.main.bounds.width {
            scrollBarBackView.isHidden = false
        } else {
            scrollBarBackView.isHidden = true
        }
        scrollBarBackView.backgroundColor = ColorUtil.Button.Background.disabled
    }

    func initNextView() {
        nextView.addSubviews(nextButton)
        nextView.backgroundColor = UIColor.white

        nextView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        switch from {
        case .materials:
            nextView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(90)
            }
            let width = (UIScreen.main.bounds.width - 60) / 2
            shareSilentlyButton.addTo(superView: nextView) { make in
                make.bottom.equalToSuperview().offset(-20)
                make.centerX.equalToSuperview()
            }
            nextButton.setTitle(title: "SHARE")
            nextButton.snp.makeConstraints { make in
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(50)
                make.width.equalTo(width)
//                make.centerY.equalToSuperview()
                make.bottom.equalTo(shareSilentlyButton.snp.top).offset(-10)
            }
            backButton.setTitle(title: "CANCEL")
            backButton.setStyle(style: .cancel)
            backButton.onTapped { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }
            nextView.addSubviews(backButton)
            backButton.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(20)
                make.height.equalTo(50)
                make.width.equalTo(width)
//                make.centerY.equalToSuperview()
                make.bottom.equalTo(shareSilentlyButton.snp.top).offset(-10)
            }
            break
        case .other:

            nextView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(50)
            }
            nextButton.setTitle(title: "NEXT")
            nextButton.snp.makeConstraints { make in
                make.centerX.centerY.equalToSuperview()
                make.height.equalTo(50)
                make.width.equalTo(180)
            }
            break
        case .materialsMultiple:

            nextView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(90)
            }
            let width = (UIScreen.main.bounds.width - 60) / 2
            shareSilentlyButton.addTo(superView: nextView) { make in
                make.bottom.equalToSuperview().offset(-20)
                make.centerX.equalToSuperview()
            }
            nextButton.setTitle(title: "SHARE")
            nextButton.snp.makeConstraints { make in
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(50)
                make.width.equalTo(width)
//                make.centerY.equalToSuperview()
                make.bottom.equalTo(shareSilentlyButton.snp.top).offset(-10)
            }
            backButton.setTitle(title: "CANCEL")
            backButton.setStyle(style: .cancel)
            backButton.onTapped { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }
            nextView.addSubviews(backButton)
            backButton.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(20)
                make.height.equalTo(50)
                make.width.equalTo(width)
//                make.centerY.equalToSuperview()
                make.bottom.equalTo(shareSilentlyButton.snp.top).offset(-10)
            }
        }

        nextButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.isShareSilently = false
            self.clickNextButton()
        }
        nextButton.disable()
        shareSilentlyButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.isShareSilently = true
            self.clickNextButton()
        }
    }

    func initStudentListView() {
        studentListView.backgroundColor = UIColor.white
        studentListView.snp.makeConstraints { make in
            make.top.equalTo(selectsView.snp.bottom).offset(20)
            make.right.left.equalToSuperview()
            make.bottom.equalTo(nextView.snp.top)
        }
        studentListView.setTopRadius()
        studentListCollectionLayout = UICollectionViewFlowLayout()
        studentListCollectionLayout.minimumLineSpacing = 0
        studentListCollectionLayout.minimumInteritemSpacing = 0
        studentListCollectionLayout.scrollDirection = .vertical
        studentListCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: studentListCollectionLayout)
        studentListView.addSubview(studentListCollectionView)
        studentListCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }

        studentListCollectionView.tag = 9002
        studentListCollectionView.delegate = self
        studentListCollectionView.dataSource = self
        studentListCollectionView.backgroundColor = UIColor.white
        // 适配大屏幕和横屏
        updateCollectionViewLayout()
        enableScreenRotateListener { [weak self] in
            guard let self = self else { return }
            self.updateCollectionViewLayout()
        }
        studentListCollectionView.register(StudentsSelectorCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: StudentsSelectorCollectionViewCell.self))
    }
}

extension AddressBookViewController {
    private func onNavRightButtonTapped() {
        if studentListCollectionView.tag == SELECT_COLLECTION_TAG {
            if showType == .appContact || showType == .appContactSingleChoice {
                // appSelectContacts.count
                appSelectContacts.forEachItems { _, index in
                    if !appSelectContacts[index]._isNotSelectt {
                        appSelectContacts[index]._isSelect = isSelectAll
                    }
                }
            } else {
                // localSelectContacts.count
                localSelectContacts.forEachItems { _, index in
                    localSelectContacts[index].isSelect = isSelectAll
                }
            }
        } else {
            if showType == .appContact || showType == .appContactSingleChoice {
                // appContacts.count
                appContacts.forEachItems { _, index in
                    if !appContacts[index]._isNotSelectt {
                        appContacts[index]._isSelect = isSelectAll
                    }
                }
            } else {
                // localContacts.count
                localContacts.forEachItems { _, index in
                    localContacts[index].isSelect = isSelectAll
                }
            }
        }
        checkIfSelectedAll()
        reloadDataForSelectAll()
    }

    private func reloadDataForSelectAll() {
        studentListCollectionView.reloadData()
        var show: Bool = false
        if showType == .appContact || showType == .appContactSingleChoice {
            appSelectContacts = appContacts.filter { $0._isSelect }
            show = appSelectContacts.count > 0
        } else {
            localSelectContacts = localContacts.filter { $0.isSelect }
            show = localSelectContacts.count > 0
        }
        if show {
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                self.selectsView.snp.updateConstraints { make in
                    make.top.equalTo(self.searchBarContainer.snp.bottom).offset(20)
                    make.height.equalTo(99)
                }
                self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                self.selectsView.snp.updateConstraints { make in
                    make.top.equalTo(self.searchBarContainer.snp.bottom).offset(0)
                    make.height.equalTo(0)
                }
                self.view.layoutIfNeeded()
            }
        }
        selectsCollectionView.reloadData()
    }
}

// MARK: - CollectionView

extension AddressBookViewController: UICollectionViewDelegate, UICollectionViewDataSource, StudentsSelectorCollectionViewCellDelegate, AddressBookSelectsCellDelegate {
    func studentsSelectorCollectionViewCellIsEdit() -> Bool {
        return false
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    func studentsSelectorCollectionViewCell(didTappedAtButton cell: StudentsSelectorCollectionViewCell) {
        studentsCell(cell: cell)
    }

    func studentsSelectorCollectionViewCell(didTappedAtContentView cell: StudentsSelectorCollectionViewCell) {
        studentsCell(cell: cell)
    }

    func addressBookCell(cell: AddressBookSelectsCell) {
        if showType == .appContact {
            logger.debug("点击了cell")
            let previousCount = appSelectContacts.count
            var index: IndexPath?
            for item in appContacts.enumerated().reversed() {
                if item.element.studentId == appSelectContacts[cell.tag].studentId {
                    appContacts[item.offset]._isSelect = false
                    appContactsOriginalData[item.offset]._isSelect = false
                    index = IndexPath(row: item.offset, section: 0)
                }
            }
            appSelectContacts.remove(at: cell.tag)
            if appSelectContacts.count > 0 {
                if previousCount <= 0 {
                    UIView.animate(withDuration: 0.2) { [weak self] in
                        guard let self = self else { return }
                        self.selectsView.snp.updateConstraints { make in
                            make.top.equalTo(self.searchBarContainer.snp.bottom).offset(20)
                            make.height.equalTo(99)
                        }
                        self.view.layoutIfNeeded()
                    }
                }

            } else {
                if previousCount > 0 {
                    UIView.animate(withDuration: 0.2) { [weak self] in
                        guard let self = self else { return }
                        self.selectsView.snp.updateConstraints { make in
                            make.top.equalTo(self.searchBarContainer.snp.bottom).offset(0)
                            make.height.equalTo(0)
                        }
                        self.view.layoutIfNeeded()
                    }
                }
            }
            if let indexPath = index {
                studentListCollectionView.reloadItems(at: [indexPath])
            }
            selectsCollectionView.reloadData()
        } else if showType == .appContactSingleChoice {
        } else {
            let previousCount = appSelectContacts.count
            var index: IndexPath!
            for item in localContacts.enumerated().reversed() {
                if item.element.id == localSelectContacts[cell.tag].id {
                    localContacts[item.offset].isSelect = false
                    localContactsOriginalData[item.offset].isSelect = false
                    index = IndexPath(row: item.offset, section: 0)
                }
            }
            localSelectContacts.remove(at: cell.tag)
            if localSelectContacts.count > 0 {
                if previousCount <= 0 {
                    UIView.animate(withDuration: 0.2) { [weak self] in
                        guard let self = self else { return }
                        self.selectsView.snp.updateConstraints { make in
                            make.top.equalTo(self.searchBarContainer.snp.bottom).offset(20)
                            make.height.equalTo(99)
                        }
                        self.view.layoutIfNeeded()
                    }
                }

            } else {
                if previousCount > 0 {
                    UIView.animate(withDuration: 0.2) { [weak self] in
                        guard let self = self else { return }
                        self.selectsView.snp.updateConstraints { make in
                            make.top.equalTo(self.searchBarContainer.snp.bottom).offset(0)
                            make.height.equalTo(0)
                        }
                        self.view.layoutIfNeeded()
                    }
                }
            }
            studentListCollectionView.reloadItems(at: [index])
            selectsCollectionView.reloadData()

//            let previousCount = localSelectContacts.count
//            localContacts[cell.tag].isSelect = !localContacts[cell.tag].isSelect
//            localContactsOriginalData[cell.tag].isSelect = !localContactsOriginalData[cell.tag].isSelect
//
//            if localContacts[cell.tag].isSelect {
//                localSelectContacts.append(localContacts[cell.tag])
//            } else {
//                for item in localSelectContacts.enumerated().reversed() {
//                    if item.element.id == localContacts[cell.tag].id {
//                        localSelectContacts.remove(at: item.offset)
//                    }
//                }
//            }
//            if localSelectContacts.count > 0 {
//                if previousCount <= 0 {
//                    UIView.animate(withDuration: 0.2) {
//                        self.selectsView.snp.updateConstraints { make in
//                            make.top.equalTo(self.searchBarContainer.snp.bottom).offset(20)
//                            make.height.equalTo(99)
//                        }
//                        self.view.layoutIfNeeded()
//                    }
//                }
//
//            } else {
//                if previousCount > 0 {
//                    UIView.animate(withDuration: 0.2) {
//                        self.selectsView.snp.updateConstraints { make in
//                            make.top.equalTo(self.searchBarContainer.snp.bottom).offset(0)
//                            make.height.equalTo(0)
//                        }
//                        self.view.layoutIfNeeded()
//                    }
//                }
//            }
//            studentListCollectionView.reloadItems(at: [index])
//            selectsCollectionView.reloadData()
        }
    }

    func studentsCell(cell: StudentsSelectorCollectionViewCell) {
        logger.debug("当前点击的索引: \(cell.tag)")
        onStudentCellTapped(index: cell.tag)
    }

    private func onStudentCellTapped(index: Int) {
        logger.debug("当前的索引为: \(index)")
        if showType == .appContact {
            let previousCount = appSelectContacts.count
            logger.debug("被选中的数据: \(appContactsOriginalData[index]._isSelect) | \(appContacts[index]._isSelect)")
            appContacts[index]._isSelect.toggle()
            appContactsOriginalData[index]._isSelect.toggle()
            if appContacts[index]._isSelect {
                logger.debug("要添加的数据: \(appContacts[index].toJSON() ?? [:])")
//                appSelectContacts.append(appContacts[index])
                appSelectContacts.insert(appContacts[index], at: 0)
            } else {
                appSelectContacts.forEachItems { item, i in
                    if item.studentId == appContacts[index].studentId {
                        appSelectContacts.remove(at: i)
                    }
                }
            }
            if appSelectContacts.count > 0 {
                if previousCount <= 0 {
                    UIView.animate(withDuration: 0.2) { [weak self] in
                        guard let self = self else { return }
                        self.selectsView.snp.updateConstraints { make in
                            make.top.equalTo(self.searchBarContainer.snp.bottom).offset(20)
                            make.height.equalTo(99)
                        }
                        self.view.layoutIfNeeded()
                    }
                }
            } else {
                if previousCount > 0 {
                    UIView.animate(withDuration: 0.2) { [weak self] in
                        guard let self = self else { return }
                        self.selectsView.snp.updateConstraints { make in
                            make.top.equalTo(self.searchBarContainer.snp.bottom).offset(0)
                            make.height.equalTo(0)
                        }
                        self.view.layoutIfNeeded()
                    }
                }
            }
            selectsCollectionView.reloadData()
            studentListCollectionView.reloadData()
        } else if showType == .appContactSingleChoice {
            if let presentingViewController = presentingViewController {
                dismiss(animated: false) { [weak self] in
                    guard let self = self else { return }
                    let controller = AddLessonDetailController(studentData: self.appContacts[index])
                    controller.hero.isEnabled = true
                    controller.modalPresentationStyle = .fullScreen
                    controller.enablePanToDismiss()
                    controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                    presentingViewController.present(controller, animated: true, completion: nil)
                }
            }

        } else {
            let previousCount = localSelectContacts.count
            localContacts[index].isSelect = !localContacts[index].isSelect
            localContactsOriginalData[index].isSelect = !localContactsOriginalData[index].isSelect

            if localContacts[index].isSelect {
                localSelectContacts.append(localContacts[index])
            } else {
                for item in localSelectContacts.enumerated().reversed() {
                    if item.element.id == localContacts[index].id {
                        localSelectContacts.remove(at: item.offset)
                    }
                }
            }
            if localSelectContacts.count > 0 {
                if previousCount <= 0 {
                    UIView.animate(withDuration: 0.2) { [weak self] in
                        guard let self = self else { return }
                        self.selectsView.snp.updateConstraints { make in
                            make.top.equalTo(self.searchBarContainer.snp.bottom).offset(20)
                            make.height.equalTo(99)
                        }
                        self.view.layoutIfNeeded()
                    }
                }

            } else {
                if previousCount > 0 {
                    UIView.animate(withDuration: 0.2) { [weak self] in
                        guard let self = self else { return }
                        self.selectsView.snp.updateConstraints { make in
                            make.top.equalTo(self.searchBarContainer.snp.bottom).offset(0)
                            make.height.equalTo(0)
                        }
                        self.view.layoutIfNeeded()
                    }
                }
            }
            selectsCollectionView.reloadData()
        }
        checkIfSelectedAll()
        logger.debug("选了的数据: \(appSelectContacts.toJSONString() ?? "nil")")
    }

    /// 检测是否所有的都选中了,只要有一个未选中,就显示全选
    private func checkIfSelectedAll() {
        guard isShowSelectAll else { return }
        if showType == .appContact || showType == .appContactSingleChoice {
            isSelectAll = appContacts.filter { !$0._isSelect }.count > 0
        } else {
            isSelectAll = localContacts.filter { !$0.isSelect }.count > 0
        }
        navigationBar.rightButton.title(title: isSelectAll ? "Select All" : "Unselect All")
        logger.debug("当前是否全选: \(isSelectAll)")
        studentListCollectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == SELECT_COLLECTION_TAG {
            if showType == .appContact || showType == .appContactSingleChoice {
                return appSelectContacts.count
            } else {
                return localSelectContacts.count
            }
        } else {
            if showType == .appContact || showType == .appContactSingleChoice {
                return appContacts.count
            } else {
                return localContacts.count
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == SELECT_COLLECTION_TAG {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: AddressBookSelectsCell.self), for: indexPath) as! AddressBookSelectsCell
            cell.tag = indexPath.row
            cell.delegate = self
            if showType == .appContact {
                cell.initData(appContactData: appSelectContacts[indexPath.row])
            } else {
                cell.initData(localContactData: localSelectContacts[indexPath.row])
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: StudentsSelectorCollectionViewCell.self), for: indexPath) as! StudentsSelectorCollectionViewCell
            cell.tag = indexPath.row
            cell.delegate = self
            if showType == .appContactSingleChoice {
                cell.initItem(.singleSelection)
            } else {
                cell.initItem(.multipleSelection)
            }
            if showType == .appContact || showType == .appContactSingleChoice {
                cell.initData(studentData: appContacts[indexPath.row])
            } else {
                cell.initData(localContactData: localContacts[indexPath.row])
            }
            return cell
        }
    }
}

// MARK: - Data

extension AddressBookViewController {
    override func initData() {
        getLocalStudentData()
        EventBus.listen(key: .refreshStudents, target: self) { [weak self] _ in
            guard let self = self else { return }
            if self.showType == .appContactSingleChoice {
                self.getAppContact()
            }
        }
        switch showType {
        case .googleContact:
//            getGoogleContact()
            break
        case .addressBook:
            getLocalContact()
            break
        case .appContact:
            getAppContact()
            break
        case .appContactSingleChoice:
            getAppContact()
        }
    }

    private func checkDefaultIds() {
        guard defaultIds.count > 0 else { return }
        if showType == .appContact || showType == .appContactSingleChoice {
            // appContacts.count
            print("====\(appContacts.count)")
            appContacts.forEachItems { item, index in
                if defaultIds.contains(item.studentId) {
                    if from == .materialsMultiple {
                        appContacts[index]._isNotSelectt = true
                    }
                    appContacts[index]._isSelect = true
                }
            }
            appContacts.sort { a, b -> Bool in
                a.name > b.name
            }
            appContacts.sort { a, _ -> Bool in
                !a._isNotSelectt
            }
            appContactsOriginalData.forEachItems { item, index in
                if defaultIds.contains(item.studentId) {
                    if from == .materialsMultiple {
                        appContactsOriginalData[index]._isNotSelectt = true
                    }
                    appContactsOriginalData[index]._isSelect = true
                }
            }
            appContactsOriginalData.sort { a, b -> Bool in
                a.name > b.name
            }
            appContactsOriginalData.sort { a, _ -> Bool in
                !a._isNotSelectt
            }
        } else {
            // localContacts.count
            localContacts.forEachItems { item, index in
                if defaultIds.contains(item.id) {
                    localContacts[index].isSelect = true
                }
            }
            localContactsOriginalData.forEachItems { item, index in
                if defaultIds.contains(item.id) {
                    localContactsOriginalData[index].isSelect = true
                }
            }
        }
        checkIfSelectedAll()
        reloadDataForSelectAll()
    }

    func getAppContact() {
        guard let user = ListenerService.shared.user else { return }
        switch user.currentUserDataVersion {
        case let .unknown(version: _):
            break
        case .singleTeacher:
            getAppContactV1()
        case .studio:
            getAppContactV2()
        }
    }

    func getAppContactV1() {
        addSubscribe(
            UserService.student.getStudentList()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
//                    var showDats: [TKStudent] = []
//                    if let data = data[true] {
//                        if !self.isShowAllStudent {
//                            self.appContacts = data.compactMap {
//                                switch $0.invitedStatus {
//                                case .none:
//                                    if $0.lessonTypeId != "" {
//                                        return $0
//                                    }
//                                case .sentPendding, .confirmed, .rejected:
//                                    return $0
//                                default:
//                                    break
//                                }
//                                return nil
//                            }
//                        } else {
//                            self.appContacts = data
//                        }
//                    }
                    if let data = data[false] {
                        if !self.isShowAllStudent {
                            self.appContacts = data.compactMap {
                                switch $0.invitedStatus {
                                case .none:
                                    if $0.lessonTypeId != "" {
                                        return $0
                                    }
                                case .sentPendding, .confirmed, .rejected:
                                    return $0
                                default:
                                    break
                                }
                                return nil
                            }
                        } else {
                            self.appContacts = data
                        }
                    }
                    if self.showType == .appContactSingleChoice {
                        if self.appContacts.count == 0 {
                            self.initEmptyView()
                            self.studentListView.isHidden = true
                            self.searchBar.isHidden = true
                        } else {
                            self.studentListView.isHidden = false
                            self.searchBar.isHidden = false
                            if self.emptyView != nil {
                                self.emptyView.isHidden = true
                            }
                        }
                    }
                    self.checkDefaultIds()
                    self.appContactsOriginalData = self.appContacts
                    logger.debug("加载学生列表数据")
                    self.studentListCollectionView.reloadData()
                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    func getAppContactV2() {
        let data = ListenerService.shared.studioManagerData.students
        logger.debug("是否显示全部：\(isShowAllStudent)")
        if !isShowAllStudent {
            appContacts = data.compactMap {
                switch $0.invitedStatus {
                case .none:
                    if $0.lessonTypeId != "" {
                        return $0
                    }
                case .sentPendding, .confirmed, .rejected:
                    return $0
                default:
                    break
                }
                return nil
            }
        } else {
            appContacts = data
        }
        if showType == .appContactSingleChoice {
            if appContacts.count == 0 {
                initEmptyView()
                studentListView.isHidden = true
                searchBar.isHidden = true
            } else {
                studentListView.isHidden = false
                searchBar.isHidden = false
                if emptyView != nil {
                    emptyView.isHidden = true
                }
            }
        }
        checkDefaultIds()
        appContactsOriginalData = appContacts
        logger.debug("加载学生列表数据")
        studentListCollectionView.reloadData()
    }

//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//        print("***********************************************************")
//        print("signIn - didSignInForUser")
//        if let error = error {
//            print("Error 1 :\(error)")
//
    ////            OperationQueue.main.addOperation {
    ////                self.navigationBar.stopLoading()
    ////                self.dismiss(animated: true, completion: nil)
    ////            }
//        } else {
//            // Get google contacts
//            let urlString = "https://www.google.com/m8/feeds/contacts/default/thin?max-results=10000"
//            let formattedToken: String = String(format: "Bearer %@", GIDSignIn.sharedInstance().currentUser.authentication.accessToken!)
//
//            let url = URL(string: urlString)
//            let request = NSMutableURLRequest(url: url!)
//            var contactTemporary: [String: Bool] = [:]
//
//            request.httpMethod = "GET"
//            request.setValue(formattedToken, forHTTPHeaderField: "Authorization")
//            request.setValue("3.0", forHTTPHeaderField: "GData-Version")
    ////            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
//            let sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.ephemeral
//            sessionConfiguration.httpAdditionalHeaders = ["Authorization": formattedToken, "GData-Version": "3.0"]
//            let session = URLSession(configuration: sessionConfiguration)
//
//            session.dataTask(with: url!, completionHandler: { [weak self] data, _, error in
//                guard let self = self else { return }
//                if error != nil {
//                    DispatchQueue.main.async {
//                        self.navigationBar.stopLoading()
//                    }
//                    print("Error 2 :\(error!)")
//                } else {
//                    if let data {
//                        let string = String(data: data, encoding: .utf8)
//                        logger.debug("返回的结果: \(string)")
//                    }
//                    let xml = SWXMLHash.parse(data!)
//                    do {
//                        self.localContacts = try xml["feed"]["entry"].value()
//                        for item in self.localContacts.enumerated().reversed() {
//                            if item.element.fullName == "" || (item.element.email == "") {
//                                self.localContacts.remove(at: item.offset)
//                            }
//                            if contactTemporary["\(item.element.fullName ?? ""):\(item.element.email ?? "")"] == nil {
//                                contactTemporary["\(item.element.fullName ?? ""):\(item.element.email ?? "")"] = true
//                            } else {
//                                self.localContacts.remove(at: item.offset)
//                            }
//                            if self.localContactStudentEmailMap[item.element.email ?? ""] != nil {
//                                self.localContacts.remove(at: item.offset)
//                            }
//                        }
//                        self.localContactsOriginalData = self.localContacts
//                        DispatchQueue.main.async {
//                            self.navigationBar.stopLoading()
//                            self.studentListCollectionView.reloadData()
//                        }
//                    } catch let error {
//                        DispatchQueue.main.async {
//                            self.navigationBar.stopLoading()
//                        }
//                        print("失败\(error)")
//                    }
//                }
//            }).resume()
//        }
//    }

    // MARK: - 获取Google通讯录内的人

    func getGoogleContact() {
        navigationBar.startLoading()
//        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
//        GIDSignIn.sharedInstance().delegate = self
//        GIDSignIn.sharedInstance().scopes = ["https://www.googleapis.com/auth/contacts.readonly"]
//
        ////         "https://www.google.com/m8/feeds", "https://www.googleapis.com/auth/user.birthday.read",
//        GIDSignIn.sharedInstance()?.presentingViewController = self
//        GIDSignIn.sharedInstance().signIn()

        GIDSignIn.sharedInstance.signIn(withPresenting: self, hint: nil, additionalScopes: ["https://www.googleapis.com/auth/contacts.readonly"]) { [weak self] _, error in
            guard let self = self else { return }
            if let error {
                logger.error("获取失败: \(error)")
            } else {
            }
        }
    }

    private func getLocalStudentData() {
        let json: String = SLCache.main.get(key: SLCache.STUDENT_LIST)
        if let studentData = [TKStudent].deserialize(from: json) {
            if studentData.count > 0 {
                for item in studentData {
                    if let student = item {
                        switch student.invitedStatus {
                        case .none:
                            if student.lessonTypeId != "" {
                                localContactStudentEmailMap[student.email] = true
                            }
                        case .sentPendding, .confirmed, .rejected:
                            localContactStudentEmailMap[student.email] = true
                        default:
                            break
                        }
                    }
                }
            }
        }
    }

    // MARK: - 获取手机通讯录内的人

    func getLocalContact() {
        navigationBar.startLoading()
        var contactTemporary: [String: Bool] = [:]
        Tools.getLocalContact(completion: { [weak self] contacts in
            guard let self = self else { return }
            OperationQueue.main.addOperation {
                let whitespace = NSCharacterSet.whitespaces
                var phoneMap: Dictionary<String, String> = [:]
                for contact in contacts! {
                    // 姓名
                    let name = "\(contact.givenName) \(contact.middleName) \(contact.familyName)".trimmingCharacters(in: whitespace)
                    var phones: [String] = []
                    var email: String = ""
                    if contact.phoneNumbers.count > 0 {
                        phones = contact.phoneNumbers.compactMap { $0.value.stringValue }
                    }
                    if contact.emailAddresses.count > 0 {
                        email = contact.emailAddresses[0].value as String
                    }
                    if phones.count != 0 {
                        for phone in phones {
                            let regex = try! NSRegularExpression(pattern: "[^0-9]", options: [])
                            let _phone = regex.stringByReplacingMatches(in: phone, options: [], range: NSMakeRange(0, phone.count), withTemplate: "")
                            if _phone.count > 4 && _phone.count < 13 {
                                phoneMap[_phone] = name
                            }
                        }
                    }
                    if self.justSelection {
                        for phone in phones {
                            guard phone != "" && name != "" else { continue }
                            var localContact = LocalContact()
                            localContact.id = UUID().uuidString
                            localContact.isSelect = false
                            localContact.fullName = name
                            localContact.email = email
                            localContact.phone = phone
                            if contact.imageDataAvailable {
                                localContact.avatarData = contact.imageData
                            }
                            guard contactTemporary["\(name):\(email):\(phone)"] == nil else {
                                continue
                            }
                            guard self.localContactStudentEmailMap[email] == nil else {
                                continue
                            }
                            self.localContacts.append(localContact)
                            contactTemporary["\(name):\(email):\(phone)"] = true
                        }

                    } else {
                        if (email != "") && name != "" {
                            if phones.count > 0 {
                                for phone in phones {
                                    var localContact = LocalContact()
                                    localContact.id = UUID().uuidString
                                    localContact.isSelect = false
                                    localContact.fullName = name
                                    localContact.email = email
                                    localContact.phone = phone
                                    if contact.imageDataAvailable {
                                        localContact.avatarData = contact.imageData
                                    }
                                    guard contactTemporary["\(name):\(email):\(phone)"] == nil else {
                                        continue
                                    }
                                    guard self.localContactStudentEmailMap[email] == nil else {
                                        continue
                                    }
                                    self.localContacts.append(localContact)
                                    contactTemporary["\(name):\(email):\(phone)"] = true
                                }
                            } else {
                                var localContact = LocalContact()
                                localContact.id = UUID().uuidString
                                localContact.isSelect = false
                                localContact.fullName = name
                                localContact.email = email
                                localContact.phone = ""
                                if contact.imageDataAvailable {
                                    localContact.avatarData = contact.imageData
                                }
                                guard contactTemporary["\(name):\(email):"] == nil else {
                                    continue
                                }
                                guard self.localContactStudentEmailMap[email] == nil else {
                                    continue
                                }
                                self.localContacts.append(localContact)
                                contactTemporary["\(name):\(email):"] = true
                            }
                        }
                    }
                }
                if self.localContacts.count > 0 {
                    self.localContacts = self.localContacts.sorted(by: { $0.fullName < $1.fullName })
                }

                self.checkDefaultIds()
                self.localContactsOriginalData = self.localContacts
                self.navigationBar.stopLoading()
                self.studentListCollectionView.reloadData()
            }
        })
    }

    func containsLoaclContacts(name: String, phone: String, email: String) -> Bool {
        let isContains = localContacts.contains { item -> Bool in
            item.fullName == name && item.phone == phone && item.email == email
        }
        return isContains
    }
}

extension AddressBookViewController: NewStudentViewControllerDelegate {
    func newStudentViewControllerAddNewStudentRefData(email: String, name: String, phone: String) {
    }

    func newStudentViewControllerAddNewStudentCompletion(isExampleStudent: Bool, email: String) {
    }

    func clickAddStudent() {
        TKPopAction.show(
            items: TKPopAction.Item(title: "New student", action: { [weak self] in
                guard let self = self else { return }
                let controller = NewStudentViewController()
                controller.delegate = self
                controller.modalPresentationStyle = .custom
                self.present(controller, animated: false, completion: nil)
            }),
            TKPopAction.Item(title: "Google contact", action: { [weak self] in
                guard let self = self else { return }
                let controller = AddressBookViewController()
                controller.showType = .googleContact
                controller.hero.isEnabled = true
                controller.modalPresentationStyle = .fullScreen
                controller.enablePanToDismiss()
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                self.present(controller, animated: true, completion: nil)
            }),
            TKPopAction.Item(title: "Address book", action: { [weak self] in
                guard let self = self else { return }
                let controller = AddressBookViewController()
                controller.showType = .addressBook
                controller.hero.isEnabled = true
                controller.modalPresentationStyle = .fullScreen
                controller.enablePanToDismiss()
                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                self.present(controller, animated: true, completion: nil)
            }),
            isCancelShow: true, target: self)
    }
}

// MARK: - Action

extension AddressBookViewController: TKSearchBarDelegate {
    // MARK: - 搜索栏搜索回调

    func tkSearchBar(textChanged searchBar: TKSearchBar, text: String) {
        if showType == .appContact || showType == .appContactSingleChoice {
            if text.count == 0 {
                appContacts = appContactsOriginalData
                studentListCollectionView.reloadData()
                if appContacts.count > 0 {
                    OperationQueue.main.addOperation { [weak self] in
                        guard let self = self else { return }
                        self.studentListCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                    }
                }
            } else {
                initAppSearchData(text: text)
            }
        } else {
            if text.count == 0 {
                localContacts = localContactsOriginalData
                studentListCollectionView.reloadData()
                if localContacts.count > 0 {
                    OperationQueue.main.addOperation { [weak self] in
                        guard let self = self else { return }
                        self.studentListCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                    }
                }
            } else {
                initLocalSearchData(text: text)
            }
        }
    }

    func initAppSearchData(text: String) {
        appContacts = []
        let pre3 = NSPredicate(format: "SELF CONTAINS[cd] %@", text.lowercased())
        for item in appContactsOriginalData {
            if pre3.evaluate(with: item.name.lowercased()) {
                appContacts.append(item)
            }
        }
        studentListCollectionView.reloadData()
        if appContacts.count > 0 {
            OperationQueue.main.addOperation { [weak self] in
                guard let self = self else { return }
                self.studentListCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }
    }

    // MARK: - 整理搜索Data

    func initLocalSearchData(text: String) {
        localContacts = []
        let pre3 = NSPredicate(format: "SELF CONTAINS[cd] %@", text.lowercased())
        for item in localContactsOriginalData {
            if pre3.evaluate(with: item.fullName.lowercased()) {
                localContacts.append(item)
            }
        }
        studentListCollectionView.reloadData()
        if localContacts.count > 0 {
            OperationQueue.main.addOperation { [weak self] in
                guard let self = self else { return }
                self.studentListCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }
    }

    private func updateCollectionViewLayout() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.studentListCollectionView.setNeedsLayout()
            self.studentListCollectionView.layoutIfNeeded()
            if self.studentListCollectionView.frame.width > 650 {
                // 大屏幕12345
                self.studentListCollectionLayout.itemSize = CGSize(width: self.studentListCollectionView.frame.width / 2 - 10, height: 94)
            } else {
                // 小屏幕
                self.studentListCollectionLayout.itemSize = CGSize(width: self.studentListCollectionView.frame.width, height: 94)
            }
        }
    }

    private func clickNextButton() {
//        TKToast.show(msg: "Invites sent", style: .success, duration: 0.5, target: self) {
//            self.dismiss(animated: true, completion: nil)
//        }
        if showType == .appContact {
            let studentId: [String] = appSelectContacts.compactMap { $0.studentId }
            dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.delegate?.addressBookViewController(self, selectedStudents: studentId)
                self.onStudentSelected?(studentId)
            }
//            nextButton.startLoading {
//            }
//            var materialIds: [String] = []
//            var data: [String: [String]] = [:]
//            for item in materials.enumerated() {
//                materialIds.append(item.element.id)
//                data[item.element.id] = studentId
            ////                data[item.element.id]?.append(contentsOf: studentId)
//            }
//            logger.debug("要分享的材料ID: \(materialIds) | 要分享的用户: \(studentId)")

//            addSubscribe(
//                MaterialService.shared.shareMaterial(data: data, studentIds: studentId, materialIds: materialIds, isMaterialShare: true)
//                    .subscribe(onNext: { [weak self] _ in
//                        guard let self = self else { return }
//                        self.nextButton.stopLoading()
//                        EventBus.send(key: .refreshMaterials)
//                        self.dismiss(animated: true, completion: nil)
//                    }, onError: { [weak self] err in
//                        logger.debug("======\(err)")
//                        guard let self = self else { return }
//                        TKToast.show(msg: TipMsg.shareFailed, style: .warning)
//                        self.nextButton.stopLoading()
//                    })
//            )

//            MaterialService.shared.shareMaterial(materialIds: materialIds, studentIds: studentId)
//                .done { [weak self] _ in
//                    guard let self = self else { return }
//                    self.nextButton.stopLoading()
//                    EventBus.send(key: .refreshMaterials)
//                    self.dismiss(animated: true, completion: nil)
//                }
//                .catch { [weak self] err in
//                    logger.debug("======\(err)")
//                    guard let self = self else { return }
//                    TKToast.show(msg: TipMsg.shareFailed, style: .warning)
//                    self.nextButton.stopLoading()
//                }

        } else {
            var studentData: [UserService.Student.TKAddNewStudent] = []
            for item in localSelectContacts {
                var student: UserService.Student.TKAddNewStudent = UserService.Student.TKAddNewStudent()
                student.email = item.email.lowercased()
                student.name = item.fullName.lowercased()
                student.phone = item.phone
                studentData.append(student)
            }
            nextButton.startLoading {
            }

            guard !justSelection else {
                dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.addressBookViewController(self, selectedLocalContacts: self.localSelectContacts, userInfo: self.userInfo)
                }
                return
            }

            addSubscribe(
                UserService.student.addNewStudents(students: studentData)
                    .subscribe(onNext: { [weak self] data in
                        guard let self = self else { return }

                        logger.debug("====获取Id成功==\(data)")
                        self.nextButton.stopLoading()
                        var selectDataList: [StudentScheduleData] = []
                        for item in self.localSelectContacts.enumerated() {
                            var selectData = StudentScheduleData()
                            selectData.student = item.element
                            selectData.student.id = data[item.offset]
                            if item.offset == 0 {
                                selectData.isSelect = true
                            }
                            selectDataList.append(selectData)
                        }
                        self.startController(selectDataList: selectDataList)
                    }, onError: { [weak self] err in
                        guard let self = self else { return }

                        self.nextButton.stopLoading()
                        TKToast.show(msg: TipMsg.saveStudentFailed, style: .warning)
                        logger.debug("======\(err)")
                    })
            )
        }
    }

    func startController(selectDataList: [StudentScheduleData]) {
        if let presentingViewController = presentingViewController {
            dismiss(animated: false) {
                let controller = NewStudentScheduleController()
                controller.hero.isEnabled = true

                controller.studentDatas = selectDataList
                controller.modalPresentationStyle = .fullScreen

                controller.enablePanToDismiss()

                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                presentingViewController.present(controller, animated: true, completion: nil)
            }
        }
    }
}
