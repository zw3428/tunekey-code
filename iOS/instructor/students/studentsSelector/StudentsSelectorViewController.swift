//
//  SelectStudentsViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/9.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class StudentsSelector {
    static func select(target: UIViewController?, onSelected: @escaping (TKUser) -> ()) {
        let controller = StudentsSelectorViewController()
        controller.dismissAfterSelect = true
        controller.selectComplection = { student in
            onSelected(student)
        }
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        target?.present(controller, animated: true, completion: nil)
    }
}


class StudentsSelectorViewController: TKBaseViewController {

    var dismissAfterSelect: Bool = false

    var selectComplection: (TKUser) -> () = { _ in }

    private var navigationBar: TKNormalNavigationBar!
    private var searchBar: TKSearchBar!
    private var containerView: TKView!
    private var newContactButton: TKBlockButton!
    private var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewFlowLayout!
}

extension StudentsSelectorViewController {
    override func initView() {
        self.view.backgroundColor = ColorUtil.backgroundColor
        self.enablePanToDismiss()
        initNavigationBar()
        initSearchBar()
        initContainerView()
        initNewContactButton()
        initCollectionView()
    }

    private func initNavigationBar() {
        self.navigationBar = TKNormalNavigationBar(frame: .zero, title: "Select student", target: self)
        self.view.addSubview(self.navigationBar)
        self.navigationBar.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.height.equalTo(44)
        }
    }

    private func initSearchBar() {
        self.searchBar = TKSearchBar()
        let searchBarContainer = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
        self.view.addSubview(searchBarContainer)
        searchBarContainer.snp.makeConstraints { make in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.height.equalTo(36)
        }
        searchBarContainer.addSubview(self.searchBar)
        self.searchBar.snp.makeConstraints { make in
            make.height.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
    }

    private func initContainerView() {
        self.containerView = TKView.create()
            .corner(size: 15)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
        self.view.addSubview(self.containerView)
        self.containerView.snp.makeConstraints { make in
            make.top.equalTo(self.searchBar.snp.bottom).offset(20)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalToSuperview()
        }
    }

    private func initNewContactButton() {
        self.newContactButton = TKBlockButton(frame: .zero, title: "NEW CONTACT", style: .normal)
        self.containerView.addSubview(self.newContactButton)
        self.newContactButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-self.view.safeAreaInsets.bottom - 20)
            make.width.equalTo(180)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
        }
        newContactButton.onTapped { (_) in
            logger.debug("new contact button tapped")
            self.showNewStudent()
        }
    }
    
    private func showNewStudent() {
        let controller = NewStudentViewController()
//        controller.backImage = SL.Commons.shared.getScreenShot(target: self)
        controller.modalPresentationStyle = .custom
        self.present(controller, animated: false, completion: nil)
    }

    private func initCollectionView() {
        self.collectionViewLayout = UICollectionViewFlowLayout()
        self.collectionViewLayout.minimumLineSpacing = 0
        self.collectionViewLayout.minimumInteritemSpacing = 0
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = UIColor.white
        self.containerView.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.newContactButton.snp.top).offset(-10)
        }
        updateCollectionViewLayout()
        self.enableScreenRotateListener {
            self.updateCollectionViewLayout()
        }

        self.collectionView.register(StudentsSelectorCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: StudentsSelectorCollectionViewCell.self))
    }
}

extension StudentsSelectorViewController {
    private func updateCollectionViewLayout() {
        DispatchQueue.main.async {
            self.collectionView.setNeedsLayout()
            self.collectionView.layoutIfNeeded()
            if self.collectionView.frame.width > 650 {
                //大屏幕, 两列，中间留出 10 的间距
                self.collectionViewLayout.itemSize = CGSize(width: self.collectionView.frame.width / 2 - 10, height: 94)
            } else {
                //小屏幕
                self.collectionViewLayout.itemSize = CGSize(width: self.collectionView.frame.width, height: 94)
            }
        }
    }
}

// MARK: - search bar delegete
extension StudentsSelectorViewController: TKSearchBarDelegate {
    func tkSearchBar(textChanged searchBar: TKSearchBar, text: String) {

    }
}

// MARK: - collection view delegate and data source
extension StudentsSelectorViewController: UICollectionViewDelegate, UICollectionViewDataSource,StudentsSelectorCollectionViewCellDelegate {
    func studentsSelectorCollectionViewCellIsEdit() -> Bool {
        return false
    }
    func studentsSelectorCollectionViewCell(didTappedAtButton cell: StudentsSelectorCollectionViewCell) {
        studentsCell(cell: cell)
    }
    
    func studentsSelectorCollectionViewCell(didTappedAtContentView cell: StudentsSelectorCollectionViewCell) {
        studentsCell(cell: cell)
    }
    
    func studentsCell(cell: StudentsSelectorCollectionViewCell) {
        self.dismiss(animated: true) {
            self.selectComplection(TKUser())
        }
    }
    
   
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
       
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: StudentsSelectorCollectionViewCell.self), for: indexPath) as! StudentsSelectorCollectionViewCell
        cell.delegate = self
        cell.initItem(.singleSelection)
        return cell
    }
}
