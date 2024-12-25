//
//  StudentSearchController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/14.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

extension StudentSearchController {
    static func present(target: UIViewController, students: [TKStudent]) {
        let controller = StudentSearchController()
        controller.hero.isEnabled = true
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.studentDatas = students
        controller.searchType = .teacherStudent
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        target.present(controller, animated: true, completion: nil)
    }
}

class StudentSearchController: TKSearchViewController {
    enum SearchType {
        case teacherStudent
        case materialStudent
    }

    private var searchResultView: TKView!
    private var collectionViewLayout: UICollectionViewFlowLayout!
    private var collectionView: UICollectionView!
    var studentDatas: [TKStudent]! = []
    var studentSearchData: [TKStudent]! = []
    var searchType: SearchType! = .teacherStudent
//    var searchType:
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.focus()
    }
}

// MARK: - View

extension StudentSearchController {
    override func initView() {
        super.initView()
        searchResultView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .showBorder(color: ColorUtil.borderColor)
            .addTo(superView: mainView, withConstraints: { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.top.equalTo(searchView.snp.bottom).offset(24)
            })
        searchBar.delegate = self
        initCollectionView()
    }

    func initCollectionView() {
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.allowsSelection = false
        collectionView.backgroundColor = UIColor.white
        searchResultView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }
        updateCollectionViewLayout()
        enableScreenRotateListener { [weak self] in
            self?.updateCollectionViewLayout()
        }

        collectionView.register(StudentsSelectorCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: StudentsSelectorCollectionViewCell.self))
    }

    private func updateCollectionViewLayout() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.collectionView.setNeedsLayout()
            self.collectionView.layoutIfNeeded()
            if self.collectionView.frame.width > 650 {
                // 大屏幕, 两列，中间留出 10 的间距
                self.collectionViewLayout.itemSize = CGSize(width: self.collectionView.frame.width / 2 - 10, height: 94)
            } else {
                // 小屏幕
                self.collectionViewLayout.itemSize = CGSize(width: self.collectionView.frame.width, height: 94)
            }
        }
    }
}

// MARK: - TableView

extension StudentSearchController: UICollectionViewDelegate, UICollectionViewDataSource, StudentsSelectorCollectionViewCellDelegate {
    func studentsSelectorCollectionViewCellIsEdit() -> Bool {
        return false
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBar.blur()
    }
    
    
    func studentsSelectorCollectionViewCell(didTappedAtButton cell: StudentsSelectorCollectionViewCell) {
        studentsCell(cell: cell)
    }

    func studentsSelectorCollectionViewCell(didTappedAtContentView cell: StudentsSelectorCollectionViewCell) {
        studentsCell(cell: cell)
    }

    func studentsCell(cell: StudentsSelectorCollectionViewCell) {
        let studentData = studentSearchData[cell.tag]
        switch studentData.getStudentType() {
        case .none:
//            let controller = NewStudentDetailController()
//            controller.modalPresentationStyle = .fullScreen
//            controller.hero.isEnabled = true
//            controller.studentData = studentSearchData[cell.tag]
//            controller.enablePanToDismiss()
//            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//            present(controller, animated: true, completion: nil)
            let controller = StudentDetailsViewController()
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.studentData = studentSearchData[cell.tag]
            controller.enablePanToDismiss()
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            present(controller, animated: true, completion: nil)
            break
        case .invite, .addLesson, .rejected, .newLesson:
            let controller = AddLessonDetailController(studentData: studentSearchData[cell.tag])
            controller.hero.isEnabled = true
            controller.modalPresentationStyle = .fullScreen
            controller.enablePanToDismiss()
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            present(controller, animated: true, completion: nil)
            break
        case .resend:
            TKAlert.show(target: self, title: "Resend", message: "Do you want to resend the invitation", buttonString: "RESEND") {
//                TKToast.show(msg: "调用后台重新发送")
                TKToast.show(msg: "Invitation sent.", style: .success)
                CommonsService.shared.sendEmailNotificatioinForInvitationFromTeacher(studentName: studentData.name, email: studentData.email, teacherId: studentData.teacherId)
            }
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return studentSearchData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: StudentsSelectorCollectionViewCell.self), for: indexPath) as! StudentsSelectorCollectionViewCell
        cell.tag = indexPath.row
        cell.delegate = self
        cell.initItem(.normal)
        cell.initData(studentData: studentSearchData[indexPath.row])
        return cell
    }
}

// MARK: - Data

extension StudentSearchController {
    override func initData() {
    }
}

// MARK: - Action

extension StudentSearchController: TKSearchBarDelegate {
    
    func tkSearchBar(didReturn searchBar: TKSearchBar) {
        searchBar.blur()
    }
    
    func tkSearchBar(textChanged searchBar: TKSearchBar, text: String) {
        switch searchType! {
        case .teacherStudent:
            teacherSearch(searchBar, text)
            break
        case .materialStudent:

            break
        }
    }

    func teacherSearch(_ searchBar: TKSearchBar, _ text: String) {
        if text.count == 0 {
            studentSearchData.removeAll()
            collectionView.reloadData()
        } else {
            studentSearchData = []
            let pre3 = NSPredicate(format: "SELF CONTAINS[cd] %@", text.lowercased())
            for item in studentDatas {
                if pre3.evaluate(with: item.name.lowercased()) {
                    studentSearchData.append(item)
                }
            }
            collectionView.reloadData()
            if studentSearchData.count > 0 {
                OperationQueue.main.addOperation { [weak self] in
                    guard let self = self else { return }
                    self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
            }
        }
    }
}
