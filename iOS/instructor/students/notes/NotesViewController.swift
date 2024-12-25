//
//  NotesViewController.swift
//  TuneKey
//
//  Created by Wht on 2019/8/23.
//  Copyright © 2019年 spelist. All rights reserved.
//
import SnapKit
import UIKit

class NotesViewController: TKBaseViewController {
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    var data: [TKLessonSchedule] = [] {
        didSet {
            cellHeights = .init(repeating: 0, count: data.count)
        }
    }

    private var cellHeights: [CGFloat] = []
    private let tableView = UITableView()
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
}

// MARK: - View

extension NotesViewController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "Notes", target: self)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
//        initCollectionView()

        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.register(NotesTableViewCell.self, forCellReuseIdentifier: NotesTableViewCell.id)
        tableView.addTo(superView: mainView) { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
        }
    }

//    func initCollectionView() {
//        let collectionLayout = UICollectionViewFlowLayout()
//        collectionLayout.scrollDirection = .vertical
//        collectionLayout.minimumInteritemSpacing = 10
//        collectionLayout.minimumLineSpacing = 10
//        collectionLayout.estimatedItemSize = CGSize(width: UIScreen.main.bounds.width, height: 30)
//
//        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
//        collectionView.backgroundColor = ColorUtil.backgroundColor
//        collectionView.delegate = self
//        collectionView.dataSource = self
//        mainView.addSubview(collectionView)
//        collectionView.snp.makeConstraints { make in
//            make.left.right.bottom.equalToSuperview()
//            make.top.equalTo(navigationBar.snp.bottom).offset(10)
//        }
//        collectionView.register(NotesCell.self, forCellWithReuseIdentifier: String(describing: NotesCell.self))
//    }
}

// MARK: - TableView

// extension NotesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return data.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let id = String(describing: NotesCell.self)
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! NotesCell
//        cell.initItem(data: data[indexPath.row])
//        return cell
//    }
// }

extension NotesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        cellHeights[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotesTableViewCell.id, for: indexPath) as! NotesTableViewCell
        var notes: [NotesTableViewCell.NoteData] = []
        let data = data[indexPath.row]
        if data.studentNote != "" {
            notes.append(.init(who: "Student: ", note: data.studentNote))
        }
        if data.teacherNote != "" {
            notes.append(.init(who: "Me: ", note: data.teacherNote))
        }
        cell.notes = notes
        cell.date = Date(seconds: data.shouldDateTime).toLocalFormat("MMM dd")
        cellHeights[indexPath.row] = cell.getHeight()
        return cell
    }
}
