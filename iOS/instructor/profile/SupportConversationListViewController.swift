//
//  SupportConversationListViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/5/26.
//  Copyright © 2021 spelist. All rights reserved.
//

import UIKit

class SupportConversationListViewController: TKBaseViewController {
    lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Support Conversations", rightButton: "", onRightButtonTapped: {})

    private lazy var tableView: UITableView = makeTableView()

    private var conversations: [TKConversation] = [] {
        didSet {
            logger.debug("获取到的所有会话: \(conversations.toJSONString() ?? "")")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadConversations()
    }
}

extension SupportConversationListViewController {
    private func makeTableView() -> UITableView {
        let tableView = UITableView()
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UiUtil.safeAreaBottom()))
        tableView.backgroundColor = .white
        tableView.allowsSelection = false
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        tableView.separatorColor = ColorUtil.dividingLine
        tableView.setTopRadius()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SupportConversationItemCellTableViewCell.self, forCellReuseIdentifier: String(describing: SupportConversationItemCellTableViewCell.self))
        return tableView
    }
}

extension SupportConversationListViewController {
    override func initView() {
        super.initView()
        enablePanToDismiss()
        navigationBar.updateLayout(target: self)
        tableView.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        initListeners()
    }

    private func initListeners() {
        EventBus.listen(key: .conversationSyncSuccess, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.loadConversations()
        }
    }
}

extension SupportConversationListViewController {
    override func initData() {
        super.initData()
        loadConversations()
        syncSupportConversations()
    }

    private func loadConversations() {
        DBService.conversation.listSupportConversations()
            .done { conversations in
                self.conversations = conversations
                self.tableView.reloadData()
            }
            .catch { error in
                self.conversations = []
                logger.error("获取失败: \(error)")
            }
    }

    private func syncSupportConversations() {
        navigationBar.startLoading()
        DatabaseService.collections.conversation()
            .whereField("title", isEqualTo: "Support Center")
            .getDocuments(source: .server) { [weak self] snapshot, _ in
                guard let self = self else { return }
                self.navigationBar.stopLoading()
                guard let docs = snapshot?.documents, let data = [TKConversation].deserialize(from: docs.compactMap { $0.data() }) as? [TKConversation] else {
                    return
                }
                logger.debug("同步到的conversation数量: \(data.count)")
                data.save()
                self.loadConversations()
            }
    }
}

extension SupportConversationListViewController: UITableViewDataSource, UITableViewDelegate, SupportConversationItemCellTableViewCellDelegate {
    func supportConversationItemCellTableViewCell(didTapped conversation: TKConversation) {
        MessagesViewController.show(conversation)
    }

    func supportConversationItemCellTableViewCell(didTappedAvatar conversation: TKConversation) {
        let userId = conversation.creatorId
        let controller = SupportConversationUserDetailViewController(userId)
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SupportConversationItemCellTableViewCell.self), for: indexPath) as! SupportConversationItemCellTableViewCell
        cell.delegate = self
        cell.loadData(conversations[indexPath.row])
        return cell
    }
}
