//
//  StudentDetailsV2ViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/11/17.
//  Copyright © 2022 spelist. All rights reserved.
//

import AttributedString
import FirebaseFirestore
import Hero
import MessageUI
import PromiseKit
import SDWebImage
import SnapKit
import UIKit

class StudentDetailsV2ViewController: TKBaseViewController {
    private lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Student detail", rightButton: "") { [weak self] in
        self?.onNavigationBarRightButtonTapped()
    }

    @Live private var materialsCollectionViewHeight: CGFloat = 1
    private lazy var materialsCollectionView: UICollectionView = makeMaterialsCollectionView()

    @Live var memo: String = ""
    @Live var latestAttendance: String = ""
    @Live var birthday: TimeInterval = 0.0
    @Live var credits: [TKCredit] = []

    @Live var teachers: [String: TKTeacher] = [:]
    @Live var teacherUsers: [String: TKUser] = [:]

    @Live var lessonConfigs: [TKLessonScheduleConfigure] = []
    @Live var materials: [TKMaterial] = []
    @Live var homeworks: [TKPractice] = []
    @Live var lessonSchedules: [TKLessonSchedule] = []
    @Live var achievements: [TKAchievement] = []
    @Live var lessonTypes: [TKLessonType] = []

    @Live var latestTransaction: TKTransaction?
    @Live var nextBills: [TKInvoice] = []

    @Live var isParentUserLoading: Bool = true
    @Live var parentUser: TKUser?

    @Live var studentConversation: TKConversation?
    @Live var parentConversation: TKConversation?

    private var isStudentAvatarLoading: Bool = true
    private var isStudentAvatarExists: Bool = false

    private var isParentAvatarLoading: Bool = true
    private var isParentAvatarExists: Bool = false

    @Live var isStudentView: Bool = false

    @Live var isShowAllLessonTypes: Bool = false

    @Live var studentUser: TKUser?
    @Live var student: TKStudent
    init(_ student: TKStudent) {
        self.student = student
        super.init(nibName: nil, bundle: nil)
        memo = student.memo
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.debug("进入学生: \(student.studentId) 详情")
        loadData()
    }

    deinit {
        logger.debug("销毁 => StudentDetailsV2ViewController")
        materialsCollectionView.removeObserver(self, forKeyPath: "contentSize", context: nil)
    }
}

extension StudentDetailsV2ViewController {
    override func initView() {
        super.initView()
        navigationBar.updateLayout(target: self)

        ViewBox {
            VScrollStack {
                makeStudentView()

                makeParentView()

                makeLessonView()

                makeStudentMemoView()

                makeBirthdayView()

                makeAttendanceView()

                makeBalanceView()

                makeStudentActivityView()

                makeAwardView()

                makeNotesView()

                makeMaterialsView()

                makeBottomButtonsView()
            }.applyScrollView { scrollView in
                scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UiUtil.safeAreaBottom(), right: 0)
            }
        }
        .addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func makeBottomButtonsView() -> ViewBox {
        ViewBox(top: 80, left: 20, bottom: 10, right: 20) {
            VStack(alignment: .center, spacing: 20) {
                BlockButton(title: "ARCHIVE", style: .warning).size(width: 180, height: 50)
                    .bind { [weak self] button in
                        guard let self = self else { return }
                        self.$student.addSubscriber { student in
                            if student.invitedStatus != .archived {
                                button.isHidden = false
                            } else {
                                button.isHidden = true
                            }
                        }
                    }
                    .apply { button in
                        button.layer.cornerRadius = 5
                        button.layer.borderWidth = 0
                        button.layer.shadowOffset = CGSize(width: 0, height: 4)
                        button.layer.shadowRadius = 5
                        button.layer.shadowOpacity = 0.7
                    }
                    .onTapped { [weak self] _ in
                        self?.onArchiveButtonTapped()
                    }

                HStack(alignment: .center, spacing: 20) {
                    Button().title("REACTIVATE", for: .normal)
                        .titleColor(ColorUtil.main, for: .normal)
                        .font(.bold(17))
                        .height(24)
                        .onTapped { [weak self] _ in
                            guard let self = self else { return }
                            self.onReactivateTapped()
                        }
                        .apply { [weak self] button in
                            guard let self = self else { return }
                            self.$student.addSubscriber { student in
                                if student.invitedStatus == .archived {
                                    button.isHidden = false
                                } else {
                                    button.isHidden = true
                                }
                            }
                        }

                    BlockButton(title: "REMOVE STUDENT", style: .warning).size(width: 180, height: 50)
                        .bind { [weak self] button in
                            guard let self = self else { return }
                            self.$student.addSubscriber { student in
                                if student.invitedStatus == .archived {
                                    button.isHidden = false
                                } else {
                                    button.isHidden = true
                                }
                            }
                        }
                        .apply { button in
                            button.layer.cornerRadius = 5
                            button.layer.borderWidth = 0
                            button.layer.shadowOffset = CGSize(width: 0, height: 4)
                            button.layer.shadowRadius = 5
                            button.layer.shadowOpacity = 0.7
                        }
                        .onTapped { [weak self] _ in
                            self?.onDeleteButtonTapped()
                        }
                }
            }
        }
        .isHidden($isStudentView)
    }

    private func makeStudentView() -> ViewBox {
        /// Student
        ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
            ViewBox(top: 16, left: 20, bottom: 16, right: 20) {
                VStack {
                    Label("Student").textColor(.secondary).font(.cardTitle)
                    Spacer(spacing: 20)
                    HStack(alignment: .center, spacing: 20) {
                        AvatarView(size: 60).size(width: 60, height: 60)
                            .completion { [weak self] avatarView, error in
                                guard let self = self else { return }
                                self.isStudentAvatarLoading = false
                                avatarView.avatarView.avatarImgView.backgroundColor = UIColor(hex: "#C2ECE0")
                                if error != nil {
                                    self.isStudentAvatarExists = false
                                    avatarView.avatarView.avatarImgView.image = UIImage(named: "content_segment_camera")!
                                        .imageWithTintColor(color: .white)
                                        .resizeImage(CGSize(width: 30, height: 30))
                                    avatarView.avatarView.avatarImgView.contentMode = .center
                                    avatarView.avatarView.avatarName?.isHidden = true
                                } else {
                                    self.isStudentAvatarExists = true
                                    avatarView.avatarView.avatarImgView.contentMode = .scaleAspectFill
                                }
                            }
                            .apply { [weak self] avatarView in
                                guard let self = self else { return }
                                self.$student.addSubscriber { student in
                                    avatarView.loadAvatar(withUserId: student.studentId, name: student.name)
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                guard let self = self else { return }
                                guard !self.isStudentAvatarLoading else { return }
                                guard let studentUser = self.studentUser else {
                                    return
                                }
                                var canUpdate: Bool = true
                                if studentUser.active && self.isStudentAvatarExists {
                                    canUpdate = false
                                }
                                guard canUpdate else { return }

                                self.onStudentAvatarTapped()
                            }
                        VStack(spacing: 3) {
                            Label().textColor(.primary).font(.title)
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$student.addSubscriber { student in
                                        label.text = student.name
                                    }
                                }
                            HStack(alignment: .top, spacing: 10) {
                                ImageView(image: UIImage(named: "ic_email_gray")).size(width: 16, height: 16)
                                Label().textColor(ColorUtil.Font.primary)
                                    .font(.content)
                                    .numberOfLines(0)
                                    .lineBreakMode(.byCharWrapping)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$student.addSubscriber { student in
                                            label.text = student.email
                                        }
                                    }
                            }
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                self.$studentUser.addSubscriber { user in
                                    guard let email = user?.email else { return }
                                    if email.isEmpty || email.contains(GlobalFields.fakeEmailSuffix) {
                                        view.isHidden = true
                                    } else {
                                        view.isHidden = false
                                    }
                                }
                            }
                            HStack(alignment: .top, spacing: 10) {
                                ImageView(image: UIImage(named: "ic_phone")?.imageWithTintColor(color: .tertiary)).size(width: 16, height: 16)
                                Label().textColor(ColorUtil.Font.primary)
                                    .font(.content)
                                    .numberOfLines(0)
                                    .lineBreakMode(.byWordWrapping)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$studentUser.addSubscriber { user in
                                            guard let phoneNumber = user?.phoneNumber else { return }
                                            if phoneNumber.isValid {
                                                label.text = phoneNumber.string
                                            } else {
                                                label.text = ""
                                            }
                                        }
                                    }
                            }
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                self.$studentUser.addSubscriber { user in
                                    guard let phoneNumber = user?.phoneNumber else { return }
                                    if phoneNumber.isValid {
                                        view.isHidden = false
                                    } else {
                                        view.isHidden = true
                                    }
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 10) {
                                ImageView(image: UIImage(named: "address")).size(width: 16, height: 16)
                                Label().textColor(ColorUtil.Font.primary)
                                    .font(.content)
                                    .numberOfLines(0)
                                    .lineBreakMode(.byWordWrapping)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$studentUser.addSubscriber { user in
                                            guard let address = user?.addresses.first else { return }
                                            if address.isValid {
                                                label.text = address.addressString
                                            } else {
                                                label.text = ""
                                            }
                                        }
                                    }
                            }
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                self.$studentUser.addSubscriber { user in
                                    guard let user else { return }
                                    if user.addresses.isNotEmpty {
                                        view.isHidden = false
                                    } else {
                                        view.isHidden = true
                                    }
                                }
                            }
                        }
                        ImageView.iconArrowRight().size(width: 22, height: 22)
//                        ImageView(image: UIImage(named: "imgInfo")).size(width: 22, height: 22)
//                            .onViewTapped { [weak self] _ in
//                                guard let self = self else { return }
//                                self.onStudentInfoTapped()
//                            }
                    }
                    .onViewTapped { [weak self] _ in
                        guard let self = self, let studentUser else { return }
                        let controller = StudioUserProfileEditViewController(studentUser)
                        controller.enableHero()
                        Tools.getTopViewController()?.present(controller, animated: true)
                        controller.onUserUpdated = { user in
                            self.studentUser = user
                        }
                    }
                    Spacer(spacing: 10)
                    /// conversations
                    ViewBox(left: 80, right: 20) {
                        ViewBox(top: 8, left: 8, bottom: 8, right: 8) {
                            HStack(alignment: .center, spacing: 8) {
                                ViewBox {
                                    Label().textColor(.white)
                                        .font(.cardBottomButton)
                                        .textAlignment(.center)
                                        .apply { [weak self] label in
                                            guard let self = self else { return }
                                            self.$studentConversation.addSubscriber { conversation in
                                                if let conversation = conversation, let user = conversation.users.first(where: { $0.userId == UserService.user.id() ?? "" }) {
                                                    label.text = "\(user.unreadMessageCount)"
                                                } else {
                                                    label.text = ""
                                                }
                                            }
                                        }
                                }
                                .backgroundColor(ColorUtil.red)
                                .cornerRadius(8)
                                .size(width: 16, height: 16)
                                .apply { [weak self] view in
                                    guard let self = self else { return }
                                    self.$studentConversation.addSubscriber { conversation in
                                        if let conversation = conversation, let user = conversation.users.first(where: { $0.userId == UserService.user.id() ?? "" }) {
                                            if user.unreadMessageCount == 0 {
                                                view.isHidden = true
                                            } else {
                                                view.isHidden = false
                                            }
                                        } else {
                                            view.isHidden = true
                                        }
                                    }
                                }

                                ImageView(image: UIImage(named: "message"))
                                    .size(width: 22, height: 22)
                                    .apply { [weak self] imageView in
                                        guard let self = self else { return }
                                        self.$studentConversation.addSubscriber { conversation in
                                            if let conversation = conversation {
                                                if conversation.latestMessage != nil {
                                                    imageView.image = UIImage(named: "message_gray")
                                                } else {
                                                    imageView.image = UIImage(named: "message")
                                                }
                                                let unreadMessageCount = conversation.users.first(where: { $0.userId == UserService.user.id() ?? "" })?.unreadMessageCount ?? 0
                                                if unreadMessageCount == 0 {
                                                    imageView.isHidden = false
                                                } else {
                                                    imageView.isHidden = true
                                                }
                                            } else {
                                                imageView.isHidden = false
                                                imageView.image = UIImage(named: "message")
                                            }
                                        }
                                    }

                                Label()
                                    .font(.cardBottomButton)
                                    .contentHuggingPriority(.fittingSizeLevel, for: .horizontal)
                                    .contentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$studentConversation.addSubscriber { conversation in
                                            if let conversation = conversation, let latestMessage = conversation.latestMessage {
                                                label.text = latestMessage.messageText()
                                                label.textColor = .secondary
                                            } else {
                                                label.text = "Chat now"
                                                label.textColor = .clickable
                                            }
                                        }
                                    }
                                Label().textColor(.secondary)
                                    .font(.cardBottomButton)
                                    .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                    .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$studentConversation.addSubscriber { conversation in
                                            if let conversation = conversation, let latestMessage = conversation.latestMessage {
                                                label.text = latestMessage.datetime.timeString()
                                            } else {
                                                label.text = ""
                                            }
                                        }
                                    }
                            }
                        }
                        .cornerRadius(3)
                        .onViewTapped { [weak self] _ in
                            self?.onStudentConversationTapped()
                        }
                        .apply { [weak self] view in
                            guard let self = self else { return }
                            self.$studentConversation.addSubscriber { conversation in
                                if let conversation, conversation.latestMessage != nil {
                                    view.backgroundColor = UIColor(hex: "#f3f3f4")
                                } else {
                                    view.backgroundColor = ColorUtil.main.withAlphaComponent(0.16)
                                }
                            }
                        }
                    }

                    /// add tag
                    ViewBox(top: 10, left: 80, bottom: 0, right: 20) {
                        VStack(alignment: .leading) {
                            Button().title("  Tag", for: .normal)
                                .titleColor(.clickable, for: .normal)
                                .font(.cardBottomButton)
                                .image(UIImage(named: "ic_add_primary_small"), for: .normal)
                                .size(width: 60, height: 22)
                                .onTapped { [weak self] _ in
                                    guard let self = self else { return }
                                    self.onStudentTagsTapped()
                                }
                        }
                    }.apply { [weak self] view in
                        guard let self = self else { return }
                        self.$student.addSubscriber { student in
                            var tags: [String] = []
                            for tagList in student.tags.compactMap({ $0.tags }) {
                                tags += tagList
                            }
                            if tags.isEmpty {
                                view.isHidden = false
                            } else {
                                view.isHidden = true
                            }
                        }
                    }
                    /// tagListView
                    ViewBox(top: 10, left: 75, bottom: 0, right: 15) {
                        TKTagListView()
                            .apply { [weak self] tagListView in
                                guard let self = self else { return }
                                self.$student.addSubscriber { student in
                                    var tags: [String] = []
                                    for tagList in student.tags.compactMap({ $0.tags }) {
                                        tags += tagList
                                    }
                                    logger.debug("当前学生的所有tag: \(tags)")
                                    tags = tags.sorted(by: { $0.count < $1.count })
                                    tagListView.tags(tags.compactMap({ TKTagListView.Tag(style: .text, text: $0) }))
                                }
                            }
                            .didTagTapped { [weak self] _, _ in
                                guard let self = self else { return }
                                self.onStudentTagsTapped()
                            }
                    }
                    .onViewTapped { [weak self] _ in
                        guard let self = self else { return }
                        self.onStudentTagsTapped()
                    }
                    .apply { [weak self] view in
                        guard let self = self else { return }
                        self.$student.addSubscriber { student in
                            var tags: [String] = []
                            for tagList in student.tags.compactMap({ $0.tags }) {
                                tags += tagList
                            }
                            if tags.isEmpty {
                                view.isHidden = true
                            } else {
                                view.isHidden = false
                            }
                        }
                    }
                }
            }.cardStyle()
        }
    }

    private func makeParentView() -> ViewBox {
        /// parent
        ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
            ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                VStack {
                    HStack(alignment: .center) {
                        Label("Parent").textColor(.secondary)
                            .font(.cardTitle)
                        Button().image(UIImage(named: "icAddPrimary")?.resizeImage(CGSize(width: 22, height: 22)), for: .normal)
                            .apply { [weak self] button in
                                guard let self = self else { return }
                                self.$parentUser.addSubscriber { user in
                                    guard !self.isParentUserLoading else {
                                        button.isHidden = true
                                        return
                                    }
                                    if user == nil {
                                        button.isHidden = false
                                    } else {
                                        button.isHidden = true
                                    }
                                }

                                self.$isParentUserLoading.addSubscriber { isLoading in
                                    guard self.parentUser == nil else {
                                        button.isHidden = true
                                        return
                                    }
                                    if isLoading {
                                        button.isHidden = true
                                    } else {
                                        button.isHidden = false
                                    }
                                }
                            }
                            .onTapped { [weak self] _ in
                                self?.onAddParentTapped()
                            }
                        LoadingView(CGSize(width: 22, height: 22))
                            .isLoading($isParentUserLoading)
                            .hiddenWithLoading(true)
                    }
                    Spacer(spacing: 20).apply { [weak self] view in
                        guard let self = self else { return }
                        self.$parentUser.addSubscriber { parentUser in
                            if parentUser == nil {
                                view.isHidden = true
                            } else {
                                view.isHidden = false
                            }
                        }
                    }
                    HStack(alignment: .center, spacing: 20) {
                        AvatarView(size: 60)
                            .completion { [weak self] avatarView, error in
                                guard let self = self else { return }
                                self.isParentAvatarLoading = false
                                avatarView.avatarView.avatarImgView.backgroundColor = UIColor(hex: "#C2ECE0")
                                if error != nil {
                                    self.isParentAvatarExists = false
                                    avatarView.avatarView.avatarImgView.image = UIImage(named: "content_segment_camera")!
                                        .imageWithTintColor(color: .white)
                                        .resizeImage(CGSize(width: 30, height: 30))
                                    avatarView.avatarView.avatarImgView.contentMode = .center
                                    avatarView.avatarView.avatarName?.isHidden = true
                                } else {
                                    self.isParentAvatarExists = true
                                    avatarView.avatarView.avatarImgView.contentMode = .scaleAspectFill
                                }
                            }
                            .apply { [weak self] avatarView in
                                guard let self = self else { return }
                                self.$parentUser.addSubscriber { user in
                                    if let user = user {
                                        avatarView.loadAvatar(withUserId: user.userId, name: user.name)
                                    }
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                guard let self = self else { return }
                                guard !self.isParentUserLoading else { return }
                                guard let parentUser = self.parentUser else { return }
                                var canUpdate: Bool = true
                                if parentUser.active && self.isParentAvatarExists {
                                    canUpdate = false
                                }
                                guard canUpdate else { return }
                                self.onParentAvatarTapped(for: parentUser.userId)
                            }
                        VStack(spacing: 3) {
                            Label().textColor(.primary).font(.title)
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$parentUser.addSubscriber { user in
                                        guard let user else { return }
                                        label.text = user.name
                                    }
                                }
                            HStack(alignment: .top, spacing: 10) {
                                ImageView(image: UIImage(named: "ic_email_gray")).size(width: 16, height: 16)
                                Label().textColor(ColorUtil.Font.primary)
                                    .font(.content)
                                    .numberOfLines(0)
                                    .lineBreakMode(.byCharWrapping)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$parentUser.addSubscriber { user in
                                            guard let user else { return }
                                            label.text = user.email
                                        }
                                    }
                            }
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                self.$parentUser.addSubscriber { user in
                                    guard let email = user?.email else { return }
                                    if email.isEmpty || email.contains(GlobalFields.fakeEmailSuffix) {
                                        view.isHidden = true
                                    } else {
                                        view.isHidden = false
                                    }
                                }
                            }
                            HStack(alignment: .top, spacing: 10) {
                                ImageView(image: UIImage(named: "ic_phone")?.imageWithTintColor(color: .tertiary)).size(width: 16, height: 16)
                                Label().textColor(ColorUtil.Font.primary)
                                    .font(.content)
                                    .numberOfLines(0)
                                    .lineBreakMode(.byWordWrapping)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$parentUser.addSubscriber { user in
                                            guard let phoneNumber = user?.phoneNumber else { return }
                                            if phoneNumber.isValid {
                                                label.text = phoneNumber.string
                                            } else {
                                                label.text = ""
                                            }
                                        }
                                    }
                            }
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                self.$parentUser.addSubscriber { user in
                                    guard let phoneNumber = user?.phoneNumber else { return }
                                    if phoneNumber.isValid {
                                        view.isHidden = false
                                    } else {
                                        view.isHidden = true
                                    }
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 10) {
                                ImageView(image: UIImage(named: "address")).size(width: 16, height: 16)
                                Label().textColor(ColorUtil.Font.primary)
                                    .font(.content)
                                    .numberOfLines(0)
                                    .lineBreakMode(.byWordWrapping)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$parentUser.addSubscriber { user in
                                            guard let address = user?.addressDetail else { return }
                                            if address.isValid {
                                                label.text = address.addressString
                                            } else {
                                                label.text = ""
                                            }
                                        }
                                    }
                            }
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                self.$parentUser.addSubscriber { user in
                                    guard let address = user?.addressDetail else { return }
                                    if address.isValid {
                                        view.isHidden = false
                                    } else {
                                        view.isHidden = true
                                    }
                                }
                            }
                        }
                        ImageView.iconArrowRight().size(width: 22, height: 22)
//                        ImageView(image: UIImage(named: "imgInfo")).size(width: 22, height: 22)
//                            .onViewTapped { [weak self] _ in
//                                guard let self = self else { return }
//                                self.onParentInfoTapped()
//                            }
                    }
                    .apply { [weak self] view in
                        guard let self = self else { return }
                        self.$parentUser.addSubscriber { user in
                            if user == nil {
                                view.isHidden = true
                            } else {
                                view.isHidden = false
                            }
                        }
                    }
                    .onViewTapped { [weak self] _ in
                        guard let self = self, let parentUser else { return }
                        let controller = StudioParentDetailViewController(parentUser)
                        controller.enableHero()
                        Tools.getTopViewController()?.present(controller, animated: true)
                    }
                    Spacer(spacing: 10).apply { [weak self] view in
                        guard let self = self else { return }
                        self.$parentUser.addSubscriber { parentUser in
                            if parentUser == nil {
                                view.isHidden = true
                            } else {
                                view.isHidden = false
                            }
                        }
                    }
                    // conversation
                    ViewBox(left: 80, right: 20) {
                        ViewBox(top: 8, left: 8, bottom: 8, right: 8) {
                            HStack(alignment: .center, spacing: 8) {
                                ViewBox {
                                    Label().textColor(.white)
                                        .font(.regular(size: 10))
                                        .textAlignment(.center)
                                        .apply { [weak self] label in
                                            guard let self = self else { return }
                                            self.$parentConversation.addSubscriber { conversation in
                                                if let conversation = conversation, let user = conversation.users.first(where: { $0.userId == UserService.user.id() ?? "" }) {
                                                    label.text = "\(user.unreadMessageCount)"
                                                } else {
                                                    label.text = ""
                                                }
                                            }
                                        }
                                }
                                .backgroundColor(ColorUtil.red)
                                .cornerRadius(8)
                                .size(width: 16, height: 16)
                                .apply { [weak self] view in
                                    guard let self = self else { return }
                                    self.$parentConversation.addSubscriber { conversation in
                                        if let conversation = conversation, conversation.latestMessageId != "", let user = conversation.users.first(where: { $0.userId == UserService.user.id() ?? "" }) {
                                            if user.unreadMessageCount == 0 {
                                                view.isHidden = true
                                            } else {
                                                view.isHidden = false
                                            }
                                        } else {
                                            view.isHidden = true
                                        }
                                    }
                                }

                                ImageView(image: UIImage(named: "message"))
                                    .size(width: 22, height: 22)
                                    .apply { [weak self] imageView in
                                        guard let self = self else { return }
                                        self.$parentConversation.addSubscriber { conversation in
                                            if let conversation = conversation, !conversation.latestMessageId.isEmpty {
                                                imageView.image = UIImage(named: "message_gray")
                                                let unreadMessageCount = conversation.users.first(where: { $0.userId == UserService.user.id() ?? "" })?.unreadMessageCount ?? 0
                                                if unreadMessageCount == 0 {
                                                    imageView.isHidden = false
                                                } else {
                                                    imageView.isHidden = true
                                                }
                                            } else {
                                                imageView.isHidden = false
                                                imageView.image = UIImage(named: "message")
                                            }
                                        }
                                    }

                                Label().font(.cardBottomButton)
                                    .contentHuggingPriority(.fittingSizeLevel, for: .horizontal)
                                    .contentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$parentConversation.addSubscriber { conversation in
                                            if let conversation = conversation, let latestMessage = conversation.latestMessage, conversation.latestMessageId != "" {
                                                label.text = latestMessage.messageText()
                                                label.textColor = .secondary
                                            } else {
                                                label.text = "Chat now"
                                                label.textColor = .clickable
                                            }
                                        }
                                    }
                                Label().textColor(.secondary)
                                    .font(.cardBottomButton)
                                    .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                    .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$parentConversation.addSubscriber { conversation in
                                            if let conversation = conversation, let latestMessage = conversation.latestMessage, conversation.latestMessageId != "" {
                                                label.text = latestMessage.datetime.timeString()
                                            } else {
                                                label.text = ""
                                            }
                                        }
                                    }
                            }
                        }
                        .cornerRadius(3)
                        .onViewTapped { [weak self] _ in
                            self?.onParentConversationTapped()
                        }
                        .apply { [weak self] view in
                            guard let self = self else { return }
                            self.$parentConversation.addSubscriber { conversation in
                                if let conversation, conversation.latestMessageId != "" {
                                    view.backgroundColor = UIColor(hex: "#f3f3f4")
                                } else {
                                    view.backgroundColor = ColorUtil.main.withAlphaComponent(0.16)
                                }
                            }
                        }
                    }
                    .apply { [weak self] view in
                        guard let self = self else { return }
                        self.$parentUser.addSubscriber { parentUser in
                            if parentUser == nil {
                                view.isHidden = true
                            } else {
                                view.isHidden = false
                            }
                        }
                    }
                }
            }
            .cardStyle()
        }
    }

    private func makeLessonView() -> ViewBox {
        ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
            ViewBox(top: 20, left: 0, bottom: 10, right: 0) {
                VStack {
                    ViewBox(left: 20, right: 20) {
                        HStack(alignment: .center) {
                            Label().textColor(.secondary)
                                .font(.cardTitle)
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$credits.addSubscriber { credits in
                                        logger.debug("credit发生变化: \(credits.count)")
                                        let count = credits.count
                                        label.text = ""
                                        if count == 0 {
                                            label.attributed.text = ASAttributedString(string: "Scheduled Lessons", .font(.cardTitle), .foreground(.secondary))
                                        } else {
                                            label.attributed.text = ASAttributedString(string: "Scheduled Lessons ", .font(.cardTitle), .foreground(.secondary)) + ASAttributedString(string: "(\(count) credit\(count > 1 ? "s" : ""))", .font(.cardTitle), .foreground(.clickable), .action {
                                                logger.debug("点击credits")
                                                self.onCreditsTapped()
                                            })
                                        }
                                    }
                                }
                            Button().image(UIImage(named: "icAddPrimary"), for: .normal)
                                .size(width: 22, height: 22)
                                .onTapped { [weak self] _ in
                                    self?.onAddLessonTapped()
                                }
                                .apply { [weak self] button in
                                    guard let self = self else { return }
                                    self.$isStudentView.addSubscriber { isStudentView in
                                        button.isHidden = isStudentView
                                    }
                                }
                        }
                    }
                    VList(withData: $lessonConfigs) { lessonConfigs in
                        for (index, config) in lessonConfigs.enumerated() {
                            ViewBox {
                                VStack {
                                    ViewBox(top: 20, left: 20, bottom: index < lessonConfigs.count - 1 ? 20 : 0, right: 20) {
                                        HStack(alignment: .top, spacing: 20) {
                                            ImageView(image: UIImage(named: ""))
                                                .size(width: 60, height: 60)
                                                .apply { [weak self] imageView in
                                                    guard let self = self else { return }
                                                    if let lessonType = self.lessonTypes.first(where: { $0.id == config.lessonTypeId }), let instrument = ListenerService.shared.instruments.first(where: { $0.id.description == lessonType.instrumentId }) {
                                                        imageView.sd_setImage(with: URL(string: instrument.minPictureUrl))
                                                    } else {
                                                        imageView.image = nil
                                                    }
                                                }
                                            VStack(spacing: 8) {
                                                Label().textColor(.primary)
                                                    .font(.title)
                                                    .contentHuggingPriority(.defaultHigh, for: .vertical)
                                                    .contentCompressionResistancePriority(.defaultHigh, for: .vertical)
                                                    .apply { label in
                                                        if let lessonType = ListenerService.shared.studioManagerData.lessonTypes.first(where: { $0.id == config.lessonTypeId }) {
                                                            label.text = lessonType.name
                                                        } else {
                                                            label.text = ""
                                                        }
                                                    }
                                                Label().textColor(.secondary)
                                                    .font(.content)
                                                    .contentHuggingPriority(.defaultHigh, for: .vertical)
                                                    .contentCompressionResistancePriority(.defaultHigh, for: .vertical)
                                                    .apply { label in
                                                        if let lessonType = ListenerService.shared.studioManagerData.lessonTypes.first(where: { $0.id == config.lessonTypeId }) {
                                                            let price: String
                                                            if config.specialPrice >= 0 {
                                                                price = "$\(config.specialPrice.roundTo(places: 2))"
                                                            } else {
                                                                price = lessonType.price.string
                                                            }
                                                            label.text = "\(lessonType.timeLength) minutes, \(price)"
                                                        } else {
                                                            label.text = ""
                                                        }
                                                    }
                                                Label().textColor(.secondary)
                                                    .font(.content)
                                                    .numberOfLines(0)
                                                    .contentHuggingPriority(.defaultHigh, for: .vertical)
                                                    .contentCompressionResistancePriority(.defaultHigh, for: .vertical)
                                                    .apply { label in
                                                        var timeFormat: String = "hh:mm a"
                                                        var recurrenceTypeString: String = ""
                                                        switch config.repeatType {
                                                        case .none:
                                                            timeFormat = "hh:mm a, MMM dd, yyyy"
                                                        case .weekly:
                                                            recurrenceTypeString = "Weekly"
                                                        case .biWeekly:
                                                            recurrenceTypeString = "Bi-Weekly"
                                                        case .monthly:
                                                            break
                                                        }
                                                        var days: String = ""
                                                        switch config.repeatType {
                                                        case .none, .monthly:
                                                            days = ""
                                                        case .weekly, .biWeekly:
                                                            let diff = TimeUtil.getUTCWeekdayDiffV2(timestamp: Int(config.startDateTime))
                                                            var weekdays: [Int] = []
                                                            for day in config.repeatTypeWeekDay {
                                                                var _day = day - diff
                                                                if _day < 0 {
                                                                    _day = 6
                                                                } else if _day > 6 {
                                                                    _day = 0
                                                                }
                                                                weekdays.append(_day)
                                                            }
                                                            logger.debug("[课程显示] => 周转换,原先数据: \(config.repeatTypeWeekDay) -> \(weekdays)")
                                                            let daysList: [String] = weekdays.sorted(by: { $0 < $1 }).compactMap({ TimeUtil.getWeekDayShotName(weekDay: $0) })
                                                            days = daysList.joined(separator: "/")
                                                        }
                                                        let time: String = config.startDateTime.toLocalFormat(timeFormat)
                                                        label.text = [time, recurrenceTypeString, days].filter({ !$0.isEmpty }).joined(separator: ", ")
                                                    }
                                                HStack(alignment: .center, spacing: 10) {
                                                    AvatarView(size: 22).apply { [weak self] avatarView in
                                                        guard let self = self else { return }
                                                        if let teacher = self.teacherUsers[config.teacherId] {
                                                            avatarView.loadAvatar(withUserId: config.teacherId, name: teacher.name)
                                                        } else {
                                                            avatarView.loadAvatar(withUserId: config.teacherId, name: "")
                                                        }
                                                    }
                                                    Label().textColor(.secondary)
                                                        .font(.content)
                                                        .apply { [weak self] label in
                                                            guard let self = self else { return }
                                                            if let teacher = self.teacherUsers[config.teacherId] {
                                                                label.text = teacher.name
                                                            } else {
                                                                label.text = ""
                                                            }
                                                        }
                                                }
                                            }
                                            VStack {
                                                Spacer(spacing: 15)
                                                ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                                            }
                                        }
                                    }
                                    ViewBox(left: 20) {
                                        Divider(weight: 1, color: ColorUtil.dividingLine)
                                    }
                                    .height(1)
                                    .apply { [weak self] view in
                                        guard let self = self else { return }
                                        self.$isShowAllLessonTypes.addSubscriber { isShowAllLessonTypes in
                                            if isShowAllLessonTypes {
                                                if index < lessonConfigs.count - 1 {
                                                    view.isHidden = false
                                                } else {
                                                    view.isHidden = true
                                                }
                                            } else {
                                                if index < 1 {
                                                    view.isHidden = false
                                                } else {
                                                    view.isHidden = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                self.$isShowAllLessonTypes.addSubscriber { isShowAllLessonTypes in
                                    UIView.animate(withDuration: 0.2) {
                                        if isShowAllLessonTypes {
                                            view.isHidden = false
                                        } else {
                                            if index > 1 {
                                                view.isHidden = true
                                            } else {
                                                view.isHidden = false
                                            }
                                        }
                                    }
                                }
                            }
                            .onViewTapped { [weak self] _ in
                                self?.onLessonScheduleConfigTapped(config)
                            }
                        }
                    }
                    .apply { [weak self] view in
                        guard let self = self else { return }
                        self.$lessonConfigs.addSubscriber { configs in
                            if configs.isEmpty {
                                view.isHidden = true
                            } else {
                                view.isHidden = false
                            }
                        }
                    }

                    ViewBox {
                        VStack(alignment: .center) {
                            HStack(alignment: .center) {
                                Button().image(UIImage(named: "icArrowDown"), for: .normal)
                                    .height(40)
                                    .onTapped { [weak self] _ in
                                        self?.isShowAllLessonTypes.toggle()
                                    }
                            }
                        }
                    }
                    .apply { [weak self] view in
                        guard let self = self else { return }
                        self.$isShowAllLessonTypes.addSubscriber { isShowAllLessonTypes in
                            UIView.animate(withDuration: 0.2) {
                                if isShowAllLessonTypes {
                                    view.transform = .init(rotationAngle: .pi)
                                } else {
                                    view.transform = .identity
                                }
                            }
                        }

                        self.$lessonConfigs.addSubscriber { configs in
                            if configs.count > 2 {
                                view.isHidden = false
                            } else {
                                view.isHidden = true
                            }
                        }
                    }

                    View().height(10)
                        .apply { [weak self] view in
                            guard let self = self else { return }
                            self.$lessonConfigs.addSubscriber { configs in
                                view.isHidden = configs.isNotEmpty
                            }
                        }
                }
            }
            .cardStyle()
        }
    }

    private func makeBalanceView() -> ViewBox {
        ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
            ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                VStack(spacing: 10) {
                    HStack(alignment: .top, spacing: 20) {
                        ImageView(image: UIImage(named: "ic_billing_yellow"))
                            .size(width: 22, height: 22)
                        Label("Balance").textColor(.primary)
                            .font(.title)
                            .contentHuggingPriority(.fittingSizeLevel, for: .horizontal)
                            .contentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
                        ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                    }
                    ViewBox(left: 42) {
                        VStack(spacing: 10) {
                            Label().apply { [weak self] label in
                                guard let self = self else { return }
                                self.$latestTransaction.addSubscriber { transaction in
                                    if let transaction = transaction {
                                        label.isHidden = false
                                        label.attributed.text = ASAttributedString(string: "Last payment: ", .font(.content), .foreground(.secondary)) + ASAttributedString(string: " on \(transaction.createTimestamp.toLocalFormat("M/dd/yyyy"))", .font(.content), .foreground(.primary))
                                    } else {
                                        label.isHidden = true
                                    }
                                }
                            }
                            HStack(alignment: .top, spacing: 2) {
                                Label("Due: ").textColor(.secondary)
                                    .font(.content)
                                    .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                Label().textColor(.primary)
                                    .font(.content)
                                    .contentHuggingPriority(.defaultLow, for: .horizontal)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$nextBills.addSubscriber { nextBills in
                                            let strings: [String] = nextBills.compactMap({ "\($0.totalAmount.string) on \($0.billingTimestamp.toLocalFormat("M/dd/yyyy"))" })
                                            label.text = strings.joined(separator: "\n")
                                        }
                                    }
                            }
                            .apply { [weak self] view in
                                guard let self = self else { return }
                                self.$nextBills.addSubscriber { nextBills in
                                    if nextBills.isEmpty {
                                        view.isHidden = true
                                    } else {
                                        view.isHidden = false
                                    }
                                }
                            }
                        }
                    }
                    .apply { [weak self] view in
                        guard let self = self else { return }
                        self.$nextBills.addSubscriber { nextBills in
                            if nextBills.isEmpty && self.latestTransaction == nil {
                                view.isHidden = true
                            } else {
                                view.isHidden = false
                            }
                        }

                        self.$latestTransaction.addSubscriber { latestTransaction in
                            if latestTransaction == nil && self.nextBills.isEmpty {
                                view.isHidden = true
                            } else {
                                view.isHidden = false
                            }
                        }
                    }
                }
            }
            .cardStyle()
            .onViewTapped { [weak self] _ in
                self?.onStudentBalanceViewTapped()
            }
        }
    }

    private func makeStudentActivityView() -> ViewBox {
        ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
            ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                VStack {
                    HStack(alignment: .top, spacing: 20) {
                        ImageView(image: UIImage(named: "icStudientActivityGray"))
                            .size(width: 22, height: 22)
                        Label("Student Activity").textColor(.primary)
                            .font(.title)
                            .contentHuggingPriority(.fittingSizeLevel, for: .horizontal)
                            .contentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
                        ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                    }
                    ViewBox(top: 10, left: 42, bottom: 0, right: 20) {
                        VStack(spacing: 4) {
                            Label().apply { [weak self] label in
                                guard let self = self else { return }
                                // 计算总的练习时长
                                self.$homeworks.addSubscriber { homeworks in
                                    var practiceTimeLength = homeworks.filter({ !$0.assignment }).compactMap({ $0.totalTimeLength }).reduce(0, { $0 + $1 })
                                    logger.debug("练习的总时长: \(practiceTimeLength)")
                                    practiceTimeLength = practiceTimeLength / 60 / 60
                                    let content: String
                                    if practiceTimeLength == 0 {
                                        content = "0 hrs"
                                    } else if practiceTimeLength <= 0.1 {
                                        content = "0.1 hrs"
                                    } else {
                                        content = "\(practiceTimeLength.roundTo(places: 1)) hrs"
                                    }
                                    let text = "Practice hrs: \(content)"
                                    label.attributedText = Tools.attributenStringColor(text: text, selectedText: content, allColor: .secondary, selectedColor: .primary, font: .content, selectedFont: .content, fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
                                }
                            }
                            Label().apply { [weak self] label in
                                guard let self = self else { return }
                                self.$homeworks.addSubscriber { homeworks in
                                    let assignmentCount: Double = Double(homeworks.count(where: { $0.assignment }))
                                    var doneCount: Double = Double(homeworks.count(where: { $0.assignment && $0.done }))
                                    if doneCount != 0 {
                                        doneCount = doneCount / Double(homeworks.count)
                                    }
                                    let content: String
                                    if assignmentCount > 0 {
                                        content = "\(Int(doneCount * 100))% completion"
                                    } else {
                                        content = "No assignment"
                                    }
                                    let text = "Assignment: \(content)"
                                    label.attributedText = Tools.attributenStringColor(text: text, selectedText: content, allColor: .secondary, selectedColor: .primary, font: .content, selectedFont: .content, fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
                                }
                            }
                        }
                    }
                }
            }
            .cardStyle()
            .onViewTapped { [weak self] _ in
                self?.onStudentActivityViewTapped()
            }
        }
    }

    private func makeAwardView() -> ViewBox {
        ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
            ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                VStack {
                    HStack(alignment: .top, spacing: 20) {
                        ImageView(image: UIImage(named: "icAchievement"))
                            .size(width: 22, height: 22)
                        Label("Award").textColor(.primary)
                            .font(.title)
                            .contentHuggingPriority(.fittingSizeLevel, for: .horizontal)
                            .contentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
                        ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                    }
                    ViewBox(top: 10, left: 42, bottom: 0, right: 20) {
                        VStack(spacing: 4) {
                            Label().apply { [weak self] label in
                                guard let self = self else { return }
                                self.$achievements.addSubscriber { achievements in
                                    if let achievement = achievements.first {
                                        let typeName: String = "\(achievement.typeName): "
                                        label.attributedText = Tools.attributenStringColor(text: "\(typeName)\(achievement.name)", selectedText: typeName, allColor: .primary, selectedColor: .secondary, font: .content, selectedFont: .content, fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
                                    }
                                }
                            }
                            Label().apply { [weak self] label in
                                guard let self = self else { return }
                                self.$achievements.addSubscriber { achievements in
                                    label.attributedText = Tools.attributenStringColor(text: "Total: \(achievements.count) badges", selectedText: "Total: ", allColor: .primary, selectedColor: .secondary, font: .content, selectedFont: .content, fontSize: 15, selectedFontSize: 15, ignoreCase: true, charasetSpace: 0)
                                }
                            }
                        }
                    }
                }
            }
            .cardStyle()
            .onViewTapped { [weak self] _ in
                guard let self = self else { return }
                self.onAwardViewTapped()
            }
        }
        .apply { [weak self] view in
            guard let self = self else { return }
            self.$achievements.addSubscriber { achievements in
                if achievements.isEmpty {
                    view.isHidden = true
                } else {
                    view.isHidden = false
                }
            }
        }
    }

    private func makeNotesView() -> ViewBox {
        ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
            ViewBox(top: 20, bottom: 20, right: 20) {
                VStack {
                    ViewBox(left: 20) {
                        HStack(alignment: .top, spacing: 20) {
                            ImageView(image: UIImage(named: "icLessonNotes"))
                                .size(width: 22, height: 22)
                            Label("Notes").textColor(.primary)
                                .font(.title)
                                .contentHuggingPriority(.fittingSizeLevel, for: .horizontal)
                                .contentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
                            ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                        }
                    }
                    ViewBox(top: 10) {
                        HStack(alignment: .top) {
                            VStack {
                                Label().textColor(.secondary)
                                    .font(.content)
                                    .textAlignment(.center)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$lessonSchedules.addSubscriber { lessons in
                                            if let lesson = lessons.sorted(by: { $0.shouldDateTime > $1.shouldDateTime }).first(where: { !$0.teacherNoteV2.isEmpty }) {
                                                label.text = lesson.shouldDateTime.toLocalFormat("dd")
                                            }
                                        }
                                    }
                                Label().textColor(.secondary)
                                    .font(.content)
                                    .textAlignment(.center)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$lessonSchedules.addSubscriber { lessons in
                                            if let lesson = lessons.sorted(by: { $0.shouldDateTime > $1.shouldDateTime }).first(where: { !$0.teacherNoteV2.isEmpty }) {
                                                label.text = lesson.shouldDateTime.toLocalFormat("MMM")
                                            }
                                        }
                                    }
                            }
                            .contentHuggingPriority(.defaultHigh, for: .horizontal)
                            .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                            .width(62)
                            VStack {
                                Label().textColor(.primary)
                                    .font(.content)
                                    .numberOfLines(0)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$lessonSchedules.addSubscriber { lessons in
                                            if let notes = lessons.sorted(by: { $0.shouldDateTime > $1.shouldDateTime }).first(where: { !$0.teacherNoteV2.isEmpty })?.teacherNoteV2 {
                                                let text = notes.getPreviewText()
                                                if text.isEmpty {
                                                    label.isHidden = true
                                                } else {
                                                    label.isHidden = false
                                                    label.text = text
                                                }
                                            }
                                        }
                                    }
                                HList(alignment: .leading, spacing: 10, withData: $lessonSchedules) { lessons in
                                    if let notes = lessons.sorted(by: { $0.shouldDateTime > $1.shouldDateTime }).first(where: { !$0.teacherNoteV2.isEmpty })?.teacherNoteV2 {
                                        for content in notes.getPreviewImages() {
                                            ImageView().size(width: 60, height: 60)
                                                .cornerRadius(5)
                                                .contentMode(.scaleAspectFill)
                                                .clipsToBounds(true)
                                                .borderWidth(1)
                                                .borderColor(ColorUtil.Font.fourth)
                                                .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                                .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                                                .apply { imageView in
                                                    if let path = content.localMediaPath() {
                                                        imageView.sd_setImage(with: path)
                                                    } else {
                                                        imageView.sd_setImage(with: URL(string: content.url))
                                                    }
                                                }
                                        }
                                    } else {
                                        View()
                                    }
                                }.apply { [weak self] view in
                                    guard let self = self else { return }
                                    self.$lessonSchedules.addSubscriber { lessons in
                                        if let notes = lessons.sorted(by: { $0.shouldDateTime > $1.shouldDateTime }).first(where: { !$0.teacherNoteV2.isEmpty })?.teacherNoteV2 {
                                            if notes.getPreviewImages().isEmpty {
                                                view.isHidden = true
                                            } else {
                                                view.isHidden = false
                                            }
                                        } else {
                                            view.isHidden = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }.cardStyle()
        }
        .apply { [weak self] view in
            guard let self = self else { return }
            self.$lessonSchedules.addSubscriber { lessons in
                if lessons.sorted(by: { $0.shouldDateTime > $1.shouldDateTime }).first(where: { !$0.teacherNoteV2.isEmpty }) != nil {
                    view.isHidden = false
                } else {
                    view.isHidden = true
                }
            }
        }
    }

    private func makeMaterialsView() -> ViewBox {
        ViewBox(top: 10, left: 20, bottom: 10, right: 20) {
            ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                VStack(spacing: 20) {
                    HStack(alignment: .center, spacing: 20) {
                        ImageView(image: UIImage(named: "icMaterials"))
                            .size(width: 22, height: 22)
                        Label("Materials").textColor(.primary)
                            .font(.title)
                        ImageView(image: UIImage(named: "arrowRight"))
                            .size(width: 22, height: 22)
                    }

                    ViewBox {
                        materialsCollectionView
                    }
                    .height($materialsCollectionViewHeight)
                    .apply { [weak self] view in
                        guard let self = self else { return }
                        self.$materials.addSubscriber { materials in
                            view.isHidden = materials.isEmpty
                        }
                    }
                }
            }
            .cardStyle()
            .onViewTapped { [weak self] _ in
                self?.onMaterialsViewTapped()
            }
        }
    }

    private func makeMaterialsCollectionView() -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: {
            let layout = DGCollectionViewLeftAlignFlowLayout()
            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 5
            layout.scrollDirection = .vertical
            let width = (UIScreen.main.bounds.width - 90) / 3
            layout.itemSize = CGSize(width: width, height: (UIScreen.main.bounds.width - 50) / 3)
            return layout
        }())
        collectionView.register(MaterialsCell.self, forCellWithReuseIdentifier: String(describing: MaterialsCell.self))
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
//        collectionView.delegate = self
        collectionView.tag = 2
        collectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        $materials.addSubscriber { _ in
            collectionView.reloadData()
        }
        return collectionView
    }

    private func makeStudentMemoView() -> ViewBox {
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                HStack(alignment: .top, spacing: 20) {
                    ImageView(image: UIImage(named: "icTerms")).size(width: 22, height: 22)
                    VStack(spacing: 10) {
                        HStack(alignment: .center, spacing: 10) {
                            Label("Memo").textColor(.primary)
                                .font(.title)
                            Label($memo).textColor(.secondary)
                                .font(.content)
                                .textAlignment(.right)
                                .numberOfLines(1)
                            ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                        }
                        Label("Add memo, address, or parents contact etc.").textColor(.secondary)
                            .font(.content)
                            .numberOfLines(0)
                    }
                }
            }
            .cardStyle()
            .onViewTapped { [weak self] _ in
                self?.onMemoTapped()
            }
        }
        .backgroundColor(ColorUtil.backgroundColor)
    }

    private func makeAttendanceView() -> ViewBox {
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                HStack(alignment: .top) {
                    ImageView(image: UIImage(named: "icTerms")?.imageWithTintColor(color: ColorUtil.main)).size(width: 22, height: 22)
                    ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)) {
                        VStack(spacing: 10) {
                            HStack {
                                Label("Lesson History").textColor(.primary)
                                    .font(.title)
                                    .size(height: 24)
                                    .contentHuggingPriority(.defaultLow, for: .horizontal)
                                    .contentCompressionResistancePriority(.defaultLow, for: .horizontal)
                                Label().textColor(.secondary)
                                    .font(.content)
                                    .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                    .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                            }
                            Label($latestAttendance)
                                .textColor(.secondary)
                                .font(.content)
                                .numberOfLines(2)
                                .apply { [weak self] label in
                                    guard let self = self else { return }
                                    self.$latestAttendance.addSubscriber { attendance in
                                        label.isHidden = attendance.isEmpty
                                    }
                                }
                        }
                    }
                    ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                }
            }
            .cardStyle()
            .onViewTapped { [weak self] _ in
                self?.onAttendanceTapped()
            }
        }
        .backgroundColor(ColorUtil.backgroundColor)
        .apply { [weak self] view in
            guard let self = self else { return }
            self.$lessonSchedules.addSubscriber { lessonSchedules in
                if lessonSchedules.isEmpty {
                    view.isHidden = true
                } else {
                    view.isHidden = false
                }
            }
        }
    }

    private func makeBirthdayView() -> ViewBox {
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                HStack(alignment: .top) {
                    ImageView(image: UIImage(named: "ic_birthday")).size(width: 22, height: 22)
                    ViewBox(paddings: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)) {
                        VStack {
                            HStack {
                                Label("Birthday").textColor(.primary)
                                    .font(.title)
                                    .size(height: 22)
                                    .contentHuggingPriority(.defaultLow, for: .horizontal)
                                    .contentCompressionResistancePriority(.defaultLow, for: .horizontal)
                                Label().textColor(.secondary)
                                    .font(.content)
                                    .contentHuggingPriority(.defaultHigh, for: .horizontal)
                                    .contentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                                    .apply { [weak self] label in
                                        guard let self = self else { return }
                                        self.$birthday.addSubscriber { birthday in
                                            if birthday == 0 {
                                                label.text = "Optional"
                                            } else {
                                                label.text = Date(seconds: birthday).toLocalFormat("M/d/yyyy")
                                            }
                                        }
                                    }
                            }
                            Spacer(spacing: 10)
                            Label("A pop-up reminder won't let you miss out the celebration.")
                                .textColor(.secondary)
                                .font(.content)
                                .numberOfLines(2)
                                .size(height: 40)
                        }
                    }
                    ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                }
            }
            .cardStyle()
            .onViewTapped { [weak self] _ in
                guard let self = self else { return }
                let controller = DatePickerViewController()
                if let user = self.studentUser {
                    let defaultDate: DateInRegion
                    if user.birthday == 0 {
                        defaultDate = DateInRegion(year: 2000, month: 1, day: 1, region: .localRegion)
                    } else {
                        defaultDate = DateInRegion(seconds: user.birthday, region: .localRegion)
                    }
                    controller.selectedYear = defaultDate.year
                    controller.selectedMonth = defaultDate.month
                    controller.selectedDay = defaultDate.day
                }
                controller.modalPresentationStyle = .custom
                Tools.getTopViewController()?.present(controller, animated: false)
                controller.onDateSelected = { date in
                    guard let user = self.studentUser else { return }
                    self.showFullScreenLoadingNoAutoHide()
                    UserService.user.updateUserBirthday(user.userId, birthday: date.timeIntervalSince1970)
                        .done { _ in
                            self.hideFullScreenLoading()
                            self.studentUser?.birthday = date.timeIntervalSince1970
                            self.birthday = date.timeIntervalSince1970
                        }
                        .catch { error in
                            self.hideFullScreenLoading()
                            TKToast.show(msg: "Update student birthday failed, please try it later.", style: .error)
                            logger.error("发生错误: \(error)")
                        }
                }
            }
        }
        .backgroundColor(ColorUtil.backgroundColor)
    }
}

extension StudentDetailsV2ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        materials.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let id = String(describing: MaterialsCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! MaterialsCell
        cell.cellInitialSize = CGSize(width: (UIScreen.main.bounds.width - 90) / 3, height: (UIScreen.main.bounds.width - 50) / 3)
//            cell.delegate = self
        cell.edit(false)
        cell.tag = indexPath.row
        cell.initData(materialsData: materials[indexPath.row], isShowStudentAvatarView: false)
        return cell
    }
}

extension StudentDetailsV2ViewController {
    private func onNavigationBarRightButtonTapped() {
    }
}

extension StudentDetailsV2ViewController {
    private func loadData() {
        loadUserAndConversations()

        initLessonScheduleConfigs()

        initHomeworks()

        initAchievements()

        initMaterials()

        initMaterialsFromLessons()

        initLessonSchedules()

        initCredits()

        initTransactions()

        initNextBilling()
    }

    private func loadUserAndConversations() {
        navigationBar.startLoading()
        akasync { [weak self] in
            guard let self = self else { return }
            guard let studentUser = try akawait(self.loadStudentUser()) else {
                updateUI {
                    self.navigationBar.stopLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                }
                return
            }
            self.studentUser = studentUser
            self.birthday = studentUser.birthday
            if let parentId = studentUser.parents.first, let parentUser = try akawait(self.loadParent(withParentId: parentId)) {
                self.parentUser = parentUser
                self.parentConversation = try akawait(self.loadConversation(userId: parentUser.userId))
            } else {
                self.parentUser = nil
            }
            self.isParentUserLoading = false

            self.studentConversation = try akawait(self.loadConversation(userId: self.student.studentId))

            updateUI {
                self.navigationBar.stopLoading()
            }
        }
    }

    private func loadStudentUser() -> Promise<TKUser?> {
        return UserService.user.getUser(id: student.studentId)
    }

    private func loadParent(withParentId userId: String) -> Promise<TKUser?> {
        return UserService.user.getUser(id: userId)
    }

    private func loadConversation(userId: String) -> Promise<TKConversation?> {
        return ChatService.conversation.getPrivateFromLocal(userId: userId)
    }

    private func loadLessonScheduleConfigs() -> Promise<[TKLessonScheduleConfigure]> {
        Promise { resolver in
            when(fulfilled: [
                DatabaseService.collections.lessonScheduleConfigure()
                    .whereField("studentId", isEqualTo: self.student.studentId)
                    .whereField("studioId", isEqualTo: self.student.studioId)
                    .whereField("delete", isEqualTo: false)
                    .getDocumentsData(TKLessonScheduleConfigure.self),
                DatabaseService.collections.lessonScheduleConfigure()
                    .whereField("studioId", isEqualTo: self.student.studioId)
                    .whereField("delete", isEqualTo: false)
                    .whereField("groupLessonStudents.\(self.student.studentId).status", isEqualTo: TKLessonScheduleConfigure.GroupLessonStudent.Status.active.rawValue)
                    .getDocumentsData(TKLessonScheduleConfigure.self),
            ])
            .done { result in
                var data: [TKLessonScheduleConfigure] = []
                for items in result {
                    data += items
                }
                resolver.fulfill(data)
            }
            .catch { error in
                resolver.reject(error)
            }
        }
    }

    private func loadHomework() -> Promise<[TKPractice]> {
        Promise { resolver in
            DatabaseService.collections.practice()
                .whereField("studentId", isEqualTo: self.student.studentId)
                .whereField("studioId", isEqualTo: self.student.studioId)
                .whereField("startTime", isGreaterThanOrEqualTo: 0)
                .getDocuments { snapshot, error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        if let data = [TKPractice].deserialize(from: snapshot?.documents.compactMap { $0.data() }) as? [TKPractice] {
                            resolver.fulfill(data)
                        } else {
                            resolver.fulfill([])
                        }
                    }
                }
        }
    }

    private func loadAchievements() -> Promise<[TKAchievement]> {
        Promise { resolver in
            DatabaseService.collections.achievement()
                .whereField("studentId", isEqualTo: self.student.studentId)
                .whereField("studioId", isEqualTo: self.student.studioId)
                .order(by: "shouldDateTime", descending: true)
                .getDocuments { snapshot, error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        if let data = [TKAchievement].deserialize(from: snapshot?.documents.compactMap({ $0.data() })) as? [TKAchievement] {
                            resolver.fulfill(data)
                        } else {
                            resolver.fulfill([])
                        }
                    }
                }
        }
    }

    private func loadMaterials() -> Promise<[TKMaterial]> {
        Promise { resolver in
            DatabaseService.collections.material()
                .whereField("studentIds", arrayContains: self.student.studentId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        if let data = snapshot?.getData(TKMaterial.self) {
                            resolver.fulfill(data)
                        } else {
                            resolver.fulfill([])
                        }
                    }
                }
        }
    }

    private func loadMaterialsFromLessons() -> Promise<[TKMaterial]> {
        akasync { [weak self] in
            guard let self else { return [] }
            do {
                let lessonScheduleMaterials = try akawait(MaterialsService.shared.fetchFromLessonSchedule(forStudent: self.student))
                let materials = try akawait(MaterialsService.shared.fetchMaterials(lessonScheduleMaterials.compactMap({ $0.materialId })))
                return materials
            } catch {
                logger.error("获取来自课程的materials失败: \(error)")
                return []
            }
        }
    }

    private func loadTeachers(_ teacherIds: [String]) -> Promise<[TKTeacher]> {
        return UserService.teacher.getTeachers(ids: teacherIds)
    }

    private func loadTeacherUsers(_ teacherIds: [String]) -> Promise<[String: TKUser]> {
        Promise { resolver in
            UserService.user.getUserList(userIds: teacherIds)
                .done { userDic in
                    resolver.fulfill(userDic)
                }
                .catch { error in
                    resolver.reject(error)
                }
        }
    }

    private func loadLessonSchedules() -> Promise<[TKLessonSchedule]> {
        Promise { resolver in
            let currentDate = Date()
            let startTime = currentDate.add(component: .month, value: -30).startOfDay.timeIntervalSince1970
            let endTime = currentDate.endOfDay.timeIntervalSince1970
            DatabaseService.collections.lessonSchedule()
                .whereField("studentId", isEqualTo: self.student.studentId)
                .whereField("studioId", isEqualTo: self.student.studioId)
                .whereField("shouldDateTime", isGreaterThanOrEqualTo: startTime)
                .whereField("shouldDateTime", isLessThan: endTime)
                .getDocumentsData(TKLessonSchedule.self) { data, error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        resolver.fulfill(data)
                    }
                }
        }
    }

    private func loadCredits() -> Promise<[TKCredit]> {
        Promise { resolver in
            DatabaseService.collections.credit()
                .whereField("studioId", isEqualTo: self.student.studioId)
                .whereField("studentId", isEqualTo: self.student.studentId)
                .getDocumentsData(TKCredit.self) { data, error in
                    if let error = error {
                        resolver.reject(error)
                    } else {
                        resolver.fulfill(data)
                    }
                }
        }
    }
}

extension StudentDetailsV2ViewController {
    private func initLessonScheduleConfigs() {
        loadLessonScheduleConfigs()
            .done { [weak self] configs in
                guard let self = self else { return }
                self.lessonConfigs = configs
                logger.debug("当前获取到的config: \(configs.count)")
                let lessonTypeIds = configs.compactMap({ $0.lessonTypeId })
                self.initLessonTypes(lessonTypeIds: lessonTypeIds)
                let teacherIds = configs.compactMap({ $0.teacherId })
                self.loadTeachers(teacherIds)
                    .done { teachers in
                        var teacherDic: [String: TKTeacher] = [:]
                        for teacher in teachers {
                            teacherDic[teacher.userId] = teacher
                        }
                        self.teachers = teacherDic
                    }
                    .catch { error in
                        logger.error("获取老师数据失败: \(error)")
                    }
                self.loadTeacherUsers(teacherIds)
                    .done { users in
                        self.teacherUsers = users
                    }
                    .catch { error in
                        logger.error("获取老师用户数据失败: \(error)")
                    }
            }
            .catch { error in
                logger.error("获取lessonConfig失败: \(error)")
            }
    }

    private func initLessonTypes(lessonTypeIds: [String]) {
        let lessonTypeIdsList = lessonTypeIds.filterDuplicates({ $0 }).group(count: 10)
        let actions = lessonTypeIdsList.compactMap({
            DatabaseService.collections.lessonType().whereField("id", in: $0)
                .getDocumentsData(TKLessonType.self)
        })
        when(fulfilled: actions)
            .done { [weak self] results in
                guard let self = self else { return }
                for data in results {
                    self.lessonTypes += data
                }
            }
            .catch { error in
                logger.error("获取Lesson type 失败: \(error)")
            }
    }

    private func initHomeworks() {
        loadHomework()
            .done { [weak self] homeworks in
                guard let self = self else { return }
                self.homeworks = homeworks
            }
            .catch { error in
                logger.error("获取homework失败: \(error)")
            }
    }

    private func initAchievements() {
        loadAchievements()
            .done { [weak self] achievements in
                guard let self = self else { return }
                self.achievements = achievements
            }
            .catch { error in
                logger.error("获取achievements失败: \(error)")
            }
    }

    private func initMaterials() {
        loadMaterials()
            .done { [weak self] materials in
                guard let self = self else { return }
                self.materials += materials.filter({ item in
                    !self.materials.contains(where: { $0.id == item.id })
                })
            }
            .catch { error in
                logger.error("获取Materials失败: \(error)")
            }
    }

    private func initMaterialsFromLessons() {
        loadMaterialsFromLessons()
            .done { [weak self] materials in
                guard let self = self else { return }
                self.materials += materials.filter({ item in
                    !self.materials.contains(where: { $0.id == item.id })
                })
            }
            .catch { error in
                logger.error("获取Materials失败: \(error)")
            }
    }

    private func initLessonSchedules() {
        loadLessonSchedules()
            .done { [weak self] lessonSchedules in
                guard let self = self else { return }
                self.lessonSchedules = lessonSchedules
                if let firstLesson = lessonSchedules.filter({ $0.shouldDateTime <= Date().timeIntervalSince1970 }).sorted(by: { $0.shouldDateTime > $1.shouldDateTime }).first {
                    if let firstAttendance = firstLesson.attendance.sorted(by: { $0.createTime > $1.createTime }).first?.desc {
                        self.latestAttendance = firstAttendance
                    } else {
                        self.latestAttendance = "Normal @ \(Date(seconds: firstLesson.shouldDateTime).toLocalFormat("h:mm a, MM/dd/yyyy"))"
                    }
                } else {
                    self.latestAttendance = ""
                }
            }
            .catch { error in
                logger.error("获取课程失败: \(error)")
            }
    }

    private func initCredits() {
        loadCredits()
            .done { [weak self] credits in
                guard let self = self else { return }
                self.credits = credits
                logger.debug("获取到的credits数量:\(credits.count)")
            }
            .catch { error in
                logger.error("获取Credits失败: \(error)")
            }
    }

    private func initTransactions() {
        DatabaseService.collections.transactions()
            .whereField("payerId", isEqualTo: student.studentId)
            .whereField("transactionType", isEqualTo: TKTransaction.TransactionType.pay.rawValue)
            .order(by: "createTimestamp", descending: true)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let doc = snapshot?.documents.first, let transaction = TKTransaction.deserialize(from: doc.data()) {
                    self.latestTransaction = transaction
                    logger.debug("[balance相关] => 获取到transaction: \(transaction.toJSONString() ?? "")")
                } else {
                    self.latestTransaction = nil
                    logger.error("[balance相关] => 当前获取最后交易失败: \(String(describing: error))")
                }
            }
    }

    private func initNextBilling() {
        DatabaseService.collections.invoice()
            .whereField("studentId", isEqualTo: student.studentId)
            .whereField("studioId", isEqualTo: student.studioId)
            .whereField("status", in: [TKInvoiceStatus.created.rawValue, TKInvoiceStatus.sent.rawValue, TKInvoiceStatus.paying.rawValue])
            .order(by: "billingTimestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let docs = snapshot?.documents, let invoices: [TKInvoice] = [TKInvoice].deserialize(from: docs.compactMap({ $0.data() })) as? [TKInvoice] {
                    self.nextBills = invoices.filter({ !$0.markAsPay })
                } else {
                    self.nextBills = []
                    logger.error("[balance相关] => 获取nextBill失败: \(String(describing: error))")
                }
            }
    }
}

extension StudentDetailsV2ViewController {
    override func bindEvent() {
        super.bindEvent()
        $teachers.addSubscriber { [weak self] _ in
            guard let self = self else { return }
            let config = self.lessonConfigs
            self.lessonConfigs = config
        }

        $teacherUsers.addSubscriber { [weak self] _ in
            guard let self = self else { return }
            let config = self.lessonConfigs
            self.lessonConfigs = config
        }

        EventBus.listen(key: .studioManagerStudentsChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            if let student = ListenerService.shared.studioManagerData.students.first(where: { $0.studentId == self.student.studentId && $0.studioId == self.student.studioId }) {
                self.student = student
            }
        }

        EventBus.listen(key: .studioStudentLessonScheduleConfigChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.initLessonScheduleConfigs()
            self.initLessonSchedules()
        }

        EventBus.listen(key: .studioLessonSchedulesChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.initLessonScheduleConfigs()
            self.initLessonSchedules()
        }

        EventBus.listen(key: .refreshUserInfo, target: self) { [weak self] _ in
            guard let self = self else { return }
            guard self.isStudentView else { return }
            self.loadStudentUser()
                .done { user in
                    self.studentUser = user
                }
                .catch { error in
                    logger.error("重新加载学生user失败：\(error)")
                }
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "contentSize" else { return }
        let contentSize = materialsCollectionView.contentSize
        let maxHeight = (((UIScreen.main.bounds.width - 50) / 3) * 3) + 20
        if contentSize.height >= maxHeight {
            materialsCollectionViewHeight = maxHeight
        } else {
            materialsCollectionViewHeight = contentSize.height
        }
    }
}

extension StudentDetailsV2ViewController {
    private func onStudentTagsTapped() {
        let controller = TagsSetupViewController()
        controller.tagsDataSource = { _ in
            ListenerService.shared.studioManagerData.studio?.studioTags ?? []
        }
        controller.selectedTagsDataSource = { [weak self] _ in
            self?.student.tags ?? []
        }
        controller.onSaveButtonTapped = { [weak self] selectedTags in
            guard let self = self else { return }
            var student = self.student
            student.tags = selectedTags
            controller.dismiss(animated: true)
            self.showFullScreenLoadingNoAutoHide()
            self.saveStudent(student: student) { error in
                self.hideFullScreenLoading()
                if let error = error {
                    logger.error("保存学生失败: \(error)")
                    TKToast.show(msg: "Save tags failed, please try again later.", style: .error)
                } else {
                    self.student = student
                }
            }
        }
        present(controller, animated: true)
    }
}

extension StudentDetailsV2ViewController {
    private func onAddParentTapped() {
        logger.debug("点击添加parent: \(studentUser?.toJSONString() ?? "")")
        guard let studentUser = studentUser else { return }
        logger.debug("进入添加parent")
        StudioTeamsNewStudentV2ViewController.show(for: studentUser) { [weak self] in
            guard let self = self else { return }
            logger.debug("开始重新加载parent数据")
            self.reloadParentInfo()
        }
    }

    private func reloadParentInfo() {
        akasync { [weak self] in
            guard let self = self else { return }
            updateUI {
                self.navigationBar.startLoading()
                self.isParentUserLoading = true
            }
            guard let studentUser = try akawait(self.loadStudentUser()) else {
                updateUI {
                    self.navigationBar.stopLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .error)
                }
                return
            }
            self.studentUser = studentUser
            if let parentId = studentUser.parents.first, let parentUser = try akawait(self.loadParent(withParentId: parentId)) {
                self.parentUser = parentUser
                self.parentConversation = try akawait(self.loadConversation(userId: parentUser.userId))
            } else {
                self.parentUser = nil
            }
            updateUI {
                self.navigationBar.stopLoading()
                self.isParentUserLoading = false
            }
        }
    }
}

extension StudentDetailsV2ViewController {
    private func saveStudent(student: TKStudent, _ completion: @escaping (Error?) -> Void) {
        DatabaseService.collections.teacherStudentList()
            .document("\(student.studioId):\(student.studentId)")
            .setData(student.toJSON() ?? [:], merge: true) { error in
                completion(error)
            }
    }

    private func saveStudentUser(_ user: TKUser, _ completion: @escaping (Error?) -> Void) {
        DatabaseService.collections.user()
            .document(user.userId)
            .setData(user.toJSON() ?? [:], merge: true) { error in
                completion(error)
            }
    }
}

extension StudentDetailsV2ViewController {
    private func onAddLessonTapped() {
        logger.debug("点击添加课程")
        StudioAddLessonForStudentViewController.show(student)
    }
}

extension StudentDetailsV2ViewController {
    private func onCreditsTapped() {
        let controller = StudioStudentCreditsViewController(student: student, credits: credits)
        controller.enableHero()
        present(controller, animated: true)
        controller.onCreditsChanged = { [weak self] credits in
            guard let self = self else { return }
            self.credits = credits
        }
    }
}

extension StudentDetailsV2ViewController {
    private func onMemoTapped() {
        let controller = LessonDetailAddNewContentViewController()
        controller.titleString = "Memo"
        controller.rightButtonString = "CONFIRM"
        controller.text = student.memo
        controller.modalPresentationStyle = .custom
        present(controller, animated: false)
        controller.onRightButtonTapped = { [weak self] text in
            guard let self = self else { return }
            controller.showFullScreenLoadingNoAutoHide()
            self.updateMemo(text, forStudent: self.student) { error in
                controller.hideFullScreenLoading()
                if let error = error {
                    TKToast.show(msg: "Update memo failed, please try again later.", style: .error)
                    logger.error("update memo failed: \(error)")
                } else {
                    controller.hide()
                    self.student.memo = text
                    self.memo = text
                }
            }
        }
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }
    }

    private func updateMemo(_ memo: String, forStudent student: TKStudent, completion: @escaping (Error?) -> Void) {
        DatabaseService.collections.teacherStudentList()
            .document("\(student.studioId):\(student.studentId)")
            .updateData(["memo": memo]) { error in
                completion(error)
            }
    }
}

extension StudentDetailsV2ViewController {
    private func onAttendanceTapped() {
        let controller = StudentDetailsAttendanceListViewController(student)
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true)
    }
}

extension StudentDetailsV2ViewController {
    private func onStudentConversationTapped() {
        if let conversation = studentConversation {
            MessagesViewController.show(conversation)
        } else {
            // 创建私聊
            showFullScreenLoadingNoAutoHide()
            getPrivateConversation(userId: student.studentId)
                .done { [weak self] conversation in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if let conversation {
                        self.studentConversation = conversation
                        MessagesViewController.show(conversation)
                    } else {
                        TKToast.show(msg: "Fetch conversation failed, please try again later.", style: .error)
                    }
                }
                .catch { error in
                    logger.error("获取会话失败: \(error)")
                    TKToast.show(msg: "Fetch conversation failed, please try again later.", style: .error)
                }
        }
    }

    private func onParentConversationTapped() {
        guard let parentUser else { return }
        if let conversation = parentConversation {
            MessagesViewController.show(conversation)
        } else {
            // 创建私聊
            showFullScreenLoadingNoAutoHide()
            getPrivateConversation(userId: parentUser.userId)
                .done { [weak self] conversation in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if let conversation {
                        self.parentConversation = conversation
                        MessagesViewController.show(conversation)
                    } else {
                        TKToast.show(msg: "Fetch conversation failed, please try again later.", style: .error)
                    }
                }
                .catch { error in
                    logger.error("获取会话失败: \(error)")
                    TKToast.show(msg: "Fetch conversation failed, please try again later.", style: .error)
                }
        }
    }

    private func getPrivateConversation(userId: String) -> Promise<TKConversation?> {
        akasync {
            let conversation = try akawait(ChatService.conversation.getPrivateFromLocal(userId: userId))
            if let conversation {
                return conversation
            } else {
                let conversation = try akawait(ChatService.conversation.getPrivateWithoutLocal(userId))
                return conversation
            }
        }
    }
}

extension StudentDetailsV2ViewController {
    private func onLessonScheduleConfigTapped(_ config: TKLessonScheduleConfigure) {
//        guard config.lessonCategory == .single else { return }
        akasync { [weak self] in
            guard let self = self else { return }
            updateUI {
                self.showFullScreenLoadingNoAutoHide()
            }
            let followUps = ListenerService.shared.studioManagerData.followUps.filter({ $0.status == .pending })
            var lessonScheduleIds: [String] = []
            for followUp in followUps {
                switch followUp.dataType {
                case .reschedule:
                    if let rescheduleData = followUp.rescheduleData {
                        lessonScheduleIds.appendIfNotExists(rescheduleData.scheduleId)
                    }
                case .conflicts:
                    if let conflicts = followUp.conflictData {
                        lessonScheduleIds.appendIfNotExists(conflicts.lessonScheduleId)
                        lessonScheduleIds.appendIfNotExists(conflicts.conflictedLessonScheduleId)
                    }
                case .cancellation:
                    if let cancellation = followUp.cancellationData {
                        lessonScheduleIds.appendIfNotExists(cancellation.oldScheduleId)
                    }
                case .cancellations:
                    let cancellations = followUp.cancellationsData
                    lessonScheduleIds += cancellations.compactMap({ $0.id })
                case .noshows:
                    if let noshow = followUp.noshowData {
                        lessonScheduleIds.appendIfNotExists(noshow.lessonScheduleId)
                    }
                case .newLessonFromCredit, .studentLessonConfigRequests:
                    break
                }
            }
            let lessonSchedulesData = try akawait(LessonService.lessonSchedule.getLessonSchedules(ids: lessonScheduleIds))
            let lessonSchedules = lessonSchedulesData.list
            updateUI {
                self.hideFullScreenLoading()
                if lessonSchedules.filter({ $0.lessonScheduleConfigId == config.id }).isNotEmpty {
                    // 有 followUp
                    SL.Alert.show(target: self, title: "Edit Lesson?", message: "Please confirm or reschedule your pending request for this lesson on the Follow Up tab, instead of editing lesson configurations which will change all recurring lessons.", leftButttonString: "Go back", centerButttonString: "Edit Lesson", rightButtonString: "Follow Up") {
                    } centerButtonAction: {
                        self.toLessonConfigEditViewController(config)
                    } rightButtonAction: {
                        self.toFollowUpViewController()
                    } onShow: { alert in
                        alert.leftButtonColor = ColorUtil.main
                        alert.centerButtonColor = ColorUtil.main
                        alert.rightButtonColor = ColorUtil.main
                    }
                } else {
                    guard let role = ListenerService.shared.currentRole, (role == .studioManager || role == .teacher) else { return }
                    // 没有 followUp
                    SL.Alert.show(target: self, title: "Edit Lesson?", message: "Editing the lesson configurations changes all recurring lessons.\nTo reschedule or cancel a single lesson only, tap the icon on the top right of the specific lesson detail in the calendar.", leftButttonString: "Go back", centerButttonString: "Calendar", rightButtonString: "Edit Lesson") {
                    } centerButtonAction: {
                        self.dismiss(animated: true) {
                            if let topController = Tools.getTopViewController() as? StudioTeamsViewController, let parentController = topController.parent as? MainViewController {
                                logger.debug("当前的controller类名: \(String(describing: type(of: topController)))")
                                parentController.selectedIndex = 1
                            } else {
                                logger.debug("无法获取最顶层的controller")
                            }
                        }
                    } rightButtonAction: {
                        self.toLessonConfigEditViewController(config)
                    } onShow: { alert in
                        alert.leftButtonColor = ColorUtil.main
                        alert.centerButtonColor = ColorUtil.main
                        alert.rightButtonColor = ColorUtil.main
                    }
                }
            }
        }
    }

    private func toLessonConfigEditViewController(_ config: TKLessonScheduleConfigure) {
        let controller = StudioLessonConfigEditViewController(config)
        controller.enableHero()
        present(controller, animated: true)
    }

    private func toFollowUpViewController() {
        let controller = StudioCalendarFollowUpsViewController()
        controller.enableHero()
        present(controller, animated: true)
    }
}

extension StudentDetailsV2ViewController {
    private func onArchiveButtonTapped() {
        SL.Alert.show(target: self, title: "Archive student?", message: "Are you sure archive this student?", leftButttonString: "Archive", rightButtonString: "Go back", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main) { [weak self] in
            self?.commitArchiveStudent()
        } rightButtonAction: {
        }
    }

    private func commitArchiveStudent() {
        guard let studio = ListenerService.shared.studioManagerData.studio else {
            return
        }
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller()
            .name("studioService-archiveStudents")
            .appendData(key: "studentIds", value: [student.studentId])
            .appendData(key: "studioId", value: studio.id)
            .call { [weak self] _, error in
                guard let self = self else { return }
                if let error {
                    logger.debug("archive Student 失败: \(error)")
                    TKToast.show(msg: "Failed to archive, please try again later.", style: .warning)
                    self.hideFullScreenLoading()
                } else {
                    self.hideFullScreenLoading()
                    self.student.invitedStatus = .archived
                    EventBus.send(EventBus.CHANGE_SCHEDULE_ONLINE)
                    EventBus.send(key: .teacherStudentListChanged)
                    EventBus.send(key: .studioManagerStudentsChanged)
                    EventBus.send(key: .studioStudentLessonScheduleConfigChanged, object: self.student.studentId)
                }
            }
    }

    private func onDeleteButtonTapped() {
        SL.Alert.show(target: self, title: "Delete student?", message: "Are you sure delete this student?", leftButttonString: "DELETE", rightButtonString: "Go back", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main) { [weak self] in
            self?.commitDeleteStudent()
        } rightButtonAction: {
        } onShow: { alert in
            alert.leftButton?.text = "DELETE"
        }
    }

    private func commitDeleteStudent() {
        guard let studio = ListenerService.shared.studioManagerData.studio else {
            return
        }
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller().name("studioService-removeStudent")
            .appendData(key: "studentId", value: student.studentId)
            .appendData(key: "studioId", value: studio.id)
            .call { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    logger.error("删除学生失败: \(error)")
                    TKToast.show(msg: "Delete student failed, please try again later.", style: .error)
                } else {
                    EventBus.send(key: .studioManagerStudentsChanged)
                    self.dismiss(animated: true) {
                        TKToast.show(msg: "Delete student successfully.", style: .success)
                    }
                }
            }
    }

    private func onReactivateTapped() {
        SL.Alert.show(target: self, title: "Reactivate student?", message: "Are you sure reactivate this student?", leftButttonString: "Reactivate", rightButtonString: "Go back", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main) { [weak self] in
            self?.commitReactivateStudent()
        } rightButtonAction: {
        }
    }

    private func commitReactivateStudent() {
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller().name("studioService-reactivateStudent")
            .appendData(key: "studentId", value: student.studentId)
            .appendData(key: "studioId", value: student.studioId)
            .call { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    logger.debug("archive Student 失败: \(error)")
                    TKToast.show(msg: "Failed to reactivate, please try again later.", style: .warning)
                } else {
                    self.student.invitedStatus = .confirmed
                    EventBus.send(EventBus.CHANGE_SCHEDULE_ONLINE)
                    EventBus.send(key: .teacherStudentListChanged)
                    EventBus.send(key: .studioManagerStudentsChanged)
                    EventBus.send(key: .studioStudentLessonScheduleConfigChanged, object: self.student.studentId)
                }
            }
    }
}

extension StudentDetailsV2ViewController {
    private func onAwardViewTapped() {
        let controller = AchievementViewController()
        controller.hero.isEnabled = true
        controller.isStudentEnter = isStudentView
        controller.teacherId = student.teacherId
        controller.studentId = student.studentId
        controller.data = achievements
        controller.modalPresentationStyle = .fullScreen
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    private func onStudentBalanceViewTapped() {
        let controller = StudentDetailsBalanceViewController(student)
        controller.isStudentView = isStudentView
        controller.modalPresentationStyle = .fullScreen
        controller.hero.isEnabled = true
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    private func onStudentActivityViewTapped() {
        let data = TKPracticeAssignment(assignments: [], time: "", startTime: 0, endTime: Date().timeIntervalSince1970, practice: homeworks)
        let controller = PracticeDetailViewController(data, studentId: student.studentId)
        controller.enableHero()
        present(controller, animated: true, completion: nil)
//        let controller = PracticeViewController()
//        controller.studentId = student.studentId
//        controller.teacherId = student.teacherId
//        controller.practiceData = homeworks
//        controller.type = .studentDetail
//        controller.modalPresentationStyle = .fullScreen
//        controller.hero.isEnabled = true
//        controller.enablePanToDismiss()
//        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//        present(controller, animated: true, completion: nil)
    }

    private func onMaterialsViewTapped() {
        let controller = MaterialsV3ViewController(.list, files: materials)
        controller.enableHero()
        present(controller, animated: true)
//        let controller = Materials2ViewController(type: .list, isEdit: false, data: materials)
//        controller.modalPresentationStyle = .fullScreen
//        controller.hero.isEnabled = true
//        controller.enablePanToDismiss()
//        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//        present(controller, animated: true, completion: nil)
    }
}

extension StudentDetailsV2ViewController {
    private func onStudentAvatarTapped() {
        guard !isStudentAvatarLoading else {
            logger.debug("还在加载头像")
            return
        }
        guard let studentUser, !studentUser.active || !isStudentAvatarExists else {
            logger.debug("当前学生激活了/没获取到")
            return
        }

        PopSheet().items([
            .init(title: "Photo") { [weak self] in
                guard let self = self else { return }
                self.showGallery(tab: .imageTab, for: studentUser.userId)
            },
            .init(title: "Camera") { [weak self] in
                guard let self = self else { return }
                self.showGallery(tab: .cameraTab, for: studentUser.userId)
            },
        ])
        .show()
    }

    private func onParentAvatarTapped(for userId: String) {
        PopSheet().items([
            .init(title: "Photo") { [weak self] in
                guard let self = self else { return }
                self.showGallery(tab: .imageTab, for: userId)
            },
            .init(title: "Camera") { [weak self] in
                guard let self = self else { return }
                self.showGallery(tab: .cameraTab, for: userId)
            },
        ])
        .show()
    }

    private func showGallery(tab: Config.GalleryTab, for userId: String) {
        Gallery.show(tabsToShow: [tab], imageLimit: 1) { [weak self] images, _ in
            guard let self = self else { return }
            guard let image = images.first else { return }
            self.hideFullScreenLoading()
            ImageCropper.crop(image: image) { image in
                self.uploadAvatarImage(image, for: userId)
            }
        } inFetchingProgress: { [weak self] progress in
            guard let self = self else { return }
            self.showFullScreenLoadingNoAutoHide()
            self.updateFullScreenLoadingMsg(msg: "Fetching image, \(Int(progress * 100))%")
        }
    }

    private func uploadAvatarImage(_ image: UIImage, for userId: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        let path = "\(UserService.user.getAvatarFolderPath())/\(userId).jpg"
        logger.debug("上传头像: \(userId)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        showFullScreenLoadingNoAutoHide()
        StorageService.shared.uploadFile(with: imageData, to: path, metadata: metadata) { [weak self] progress, _ in
            self?.updateFullScreenLoadingMsg(msg: "Uploading... \(Int(progress * 100))%")
        } completion: { [weak self] isSuccess in
            self?.hideFullScreenLoading()
            if isSuccess {
                TKToast.show(msg: "Uploading successfully.", style: .success)
                let url = UserService.user.getAvatarPath(userId)
                SDImageCache.shared.removeImage(forKey: url)
                EventBus.send(key: .refreshUserAvatarImage, object: userId)
            } else {
                TKToast.show(msg: "Upload failed, please try again later.", style: .error)
            }
        }
    }
}

extension StudentDetailsV2ViewController {
    private func onStudentInfoTapped() {
        if isStudentView {
            logger.debug("点击进入学生的edit页面")
            guard let user = ListenerService.shared.user else {
                logger.debug("当前用户没有信息,返回")
                return
            }
            logger.debug("进入个人信息修改页,当前用户信息: \(user.toJSONString() ?? "")")
            let controller = SProfileUserInfoController()
            controller.user = user
            controller.navigationBar.hiddenRightButton()
            controller.enableHero()
            present(controller, animated: true, completion: nil)
        } else {
            var items: [TKPopAction.Item] = []
            if student.phone.count >= 5 {
                items.append(
                    TKPopAction.Item(title: student.phone) { [weak self] in
                        guard let self = self else { return }
                        let phone = "telprompt://\(self.student.phone)"
                        guard let url = URL(string: phone) else { return }
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    })
            }
            if student.email != "" && !SL.FormatChecker.shared.isFakeEmail(student.email) {
                items.append(
                    TKPopAction.Item(title: student.email) { [weak self] in
                        guard let self = self else { return }
                        self.sendEmail(email: student.email)
                    }
                )
            }
            items.append(.init(title: "Edit name", action: { [weak self] in
                guard let self = self else { return }
                let controller = TeacherEditStudentNameViewController(self.student)
                controller.modalPresentationStyle = .custom
                Tools.getTopViewController()?.present(controller, animated: false, completion: nil)
            }))

            items.append(.init(title: "Edit student's home address", action: { [weak self] in
                guard let self = self, var studentUser = self.studentUser else { return }
                let controller = StudioBillingSettingUpdateAddressPopWindowViewController()
                if let address = studentUser.addresses.first {
                    controller.address = .init(addressLine: address.line1, city: address.city, country: address.country, state: address.state, zipCode: address.postal_code)
                }
                controller.onConfirmButtonTapped = { address in
                    let _address = TKPaymentAddress(city: address.city, country: address.country, line1: address.addressLine, line2: "", postal_code: address.zipCode, state: address.state)
                    studentUser.addresses = [_address]
                    self.showFullScreenLoadingNoAutoHide()
                    self.saveStudentUser(studentUser) { error in
                        self.hideFullScreenLoading()
                        if let error {
                            logger.debug("发生错误：\(error)")
                            TKToast.show(msg: "Save address faild, please try again later.", style: .error)
                        } else {
                            TKToast.show(msg: "Save sucessfully.", style: .success)
                            self.studentUser = studentUser
                        }
                    }
                }
                controller.modalPresentationStyle = .custom
                Tools.getTopViewController()?.present(controller, animated: false)
            }))
            TKPopAction.show(items: items, isCancelShow: true, target: self)
        }
    }
}

extension StudentDetailsV2ViewController: MFMailComposeViewControllerDelegate {
    func sendEmail(email: String) {
        // 0.首先判断设备是否能发送邮件
        if MFMailComposeViewController.canSendMail() {
            // 1.配置邮件窗口
            let mailView = configuredMailComposeViewController(email: email)
            // 2. 显示邮件窗口
            present(mailView, animated: true, completion: nil)
        } else {
            print("Whoop...设备不能发送邮件")
            showSendMailErrorAlert()
        }
    }

    // 提示框，提示用户设置邮箱
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Mail is not turned on", message: TipMsg.accessForEmailApp, preferredStyle: .alert)
        sendMailErrorAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
        present(sendMailErrorAlert, animated: true) {}
    }

    // MARK: - helper methods

    // 配置邮件窗口
    func configuredMailComposeViewController(email: String) -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self

        mailComposeVC.setToRecipients([email])
        mailComposeVC.setSubject("")
        mailComposeVC.setMessageBody("", isHTML: false)

        return mailComposeVC
    }

    // MARK: - Mail Delegate

    // 用户退出邮件窗口时被调用
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result.rawValue {
        case MFMailComposeResult.sent.rawValue:
            print("邮件已发送")
        case MFMailComposeResult.cancelled.rawValue:
            print("邮件已取消")
        case MFMailComposeResult.saved.rawValue:
            print("邮件已保存")
        case MFMailComposeResult.failed.rawValue:
            print("邮件发送失败")
        default:
            print("邮件没有发送")
            break
        }
        controller.dismiss(animated: true, completion: nil)
    }
}

extension StudentDetailsV2ViewController {
    private func onParentInfoTapped() {
        guard let parentUser = parentUser else { return }
        // 判断是否已经激活
        let popsheet = PopSheet()
        var contactsItems: [PopSheet.Item] = []
        if !parentUser.email.isEmpty {
            contactsItems.append(.init(title: parentUser.email) { [weak self] in
                guard let self = self else { return }
                self.onParentEmailTapped(parentUser: parentUser)
            })
        }
        if !parentUser.phoneNumber.string.isEmpty {
            contactsItems.append(.init(title: parentUser.phoneNumber.string, action: { [weak self] in
                guard let self = self else { return }
                self.onParentPhoneNumberTapped(parentUser: parentUser)
            }))
        }

        if !contactsItems.isEmpty {
            popsheet.items(contactsItems)
        }

        if !parentUser.active {
            popsheet.items([
                .init(title: "Edit name") { [weak self] in
                    self?.editParentName()
                },
                .init(title: "Unbind for current student", action: { [weak self] in
                    guard let self = self else { return }
                    self.onParentUnbindTapped(parentUser: parentUser)
                }, tintColor: ColorUtil.red),
            ])
        }
        popsheet.show()
    }

    private func onParentEmailTapped(parentUser: TKUser) {
        PopSheet().items([
            .init(title: "Send email", action: { [weak self] in
                guard let self = self else { return }
                self.sendEmail(email: parentUser.email)
            }),
            .init(title: "Edit email", action: { [weak self] in
                self?.editParentEmail()
            }),
        ])
        .show()
    }

    private func onParentPhoneNumberTapped(parentUser: TKUser) {
        PopSheet().items([
            .init(title: "Call: \(parentUser.phoneNumber.string)", action: {
                if let url = URL(string: "tel://\(parentUser.phoneNumber.stringToCall)") {
                    logger.debug("要调用的URL: \(url.absoluteString)")
                    UIApplication.shared.open(url)
                }
            }),
            .init(title: "Edit phone number", action: { [weak self] in
                self?.showUpdateParentPhonePop(parentUser)
            }),
        ])
        .show()
    }

    private func onParentUnbindTapped(parentUser: TKUser) {
        var items: [PopSheet.Item] = [.init(title: "Unbind only", action: { [weak self] in
            self?.onUnbindOnlyForParentTapped()
        })]
        if parentUser.kids.count == 1 {
            items.append(.init(title: "Unbind & delete parent account", action: { [weak self] in
                self?.onUnbindAndDeleteParentTapped()
            }))
        }
        PopSheet().items(items).show()
    }

    private func editParentEmail() {
        SL.Alert.show(target: self, title: "Update parent email?", message: "If you continue, the parent will use the email you changed for logging in. Are you sure you want to continue?", leftButttonString: "Continue", rightButtonString: "Go back", leftButtonColor: ColorUtil.red, rightButtonColor: ColorUtil.main) { [weak self] in
            guard let self = self else { return }
            self.showEditParentEmailPop()
        } rightButtonAction: {
        }
    }

    private func showEditParentEmailPop() {
        guard let parentUser = parentUser else { return }
        let controller = TextFieldPopupViewController()
        controller.titleString = "Update parent email"
        controller.leftButtonString = "CANCEL"
        controller.rightButtonString = "CONFIRM"
        controller.text = parentUser.email
        controller.onShow = { c in
            c.textBox?.selectAll()
        }
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] newEmail in
            guard let self = self else { return }
            controller.hide()
            self.commitEditParentEmail(newEmail: newEmail, parentUserId: parentUser.userId)
        }
        controller.modalPresentationStyle = .custom
        present(controller, animated: false)
    }

    private func commitEditParentEmail(newEmail: String, parentUserId: String) {
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller()
            .name("userService-updateParentEmail")
            .appendData(key: "newEmail", value: newEmail)
            .appendData(key: "parentUserId", value: parentUserId)
            .call { [weak self] result, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    logger.error("更改失败: \(error)")
                    TKToast.show(msg: "Update parent email failed, please try again later.", style: .error)
                } else {
                    if let funcResult = FuncResult.deserialize(from: result?.data as? [String: Any]) {
                        if funcResult.code != 0 {
                            TKToast.show(msg: funcResult.msg, style: .info)
                        } else {
                            TKToast.show(msg: "Successfully.", style: .success)
                            self.parentUser?.email = newEmail
                            self.parentUser?.loginMethod = [TKLoginMethod(method: .email, account: newEmail)]
                        }
                    }
                }
            }
    }

    private func editParentName() {
        guard let parentUser = parentUser else { return }
        let controller = TextFieldPopupViewController()
        controller.titleString = "Update parent name"
        controller.leftButtonString = "CANCEL"
        controller.rightButtonString = "CONFIRM"
        controller.text = parentUser.name
        controller.onShow = { c in
            c.textBox?.selectAll()
        }
        controller.onLeftButtonTapped = { _ in
            controller.hide()
        }
        controller.onRightButtonTapped = { [weak self] newName in
            guard let self = self else { return }
            controller.hide()
            self.commitUpdateParentName(newName: newName, parentUserId: parentUser.userId)
        }
        controller.onTextChanged = { text, _, rightButton in
            if text.isEmpty {
                rightButton.disable()
            } else {
                rightButton.enable()
            }
        }
        controller.modalPresentationStyle = .custom
        present(controller, animated: false)
    }

    private func commitUpdateParentName(newName: String, parentUserId: String) {
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller()
            .name("userService-updateParentName")
            .appendData(key: "newName", value: newName)
            .appendData(key: "parentUserId", value: parentUserId)
            .call { [weak self] result, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    logger.error("更改失败: \(error)")
                    TKToast.show(msg: "Update parent name failed, please try again later.", style: .error)
                } else {
                    if let funcResult = FuncResult.deserialize(from: result?.data as? [String: Any]) {
                        if funcResult.code != 0 {
                            TKToast.show(msg: funcResult.msg, style: .info)
                        } else {
                            TKToast.show(msg: "Successfully.", style: .success)
                            self.parentUser?.name = newName
                        }
                    }
                }
            }
    }

    private func showUpdateParentPhonePop(_ parentUser: TKUser) {
        let controller = StudioUpdateParentPhoneNumberViewController(parentUser.phoneNumber)
        controller.modalPresentationStyle = .custom
        present(controller, animated: false)
        controller.onConfirmButtonTapped = { [weak self] phoneNumber in
            guard let self = self else { return }
            let originalPhoneNumber = parentUser.phoneNumber
            guard phoneNumber.phoneNumber != originalPhoneNumber.phoneNumber || phoneNumber.country != originalPhoneNumber.country else {
                return
            }

            // 发生了更改
            self.commitUpdateParentPhoneNumber(phoneNumber, forParentUser: parentUser)
        }
    }

    private func commitUpdateParentPhoneNumber(_ phoneNumber: TKPhoneNumber, forParentUser parentUser: TKUser) {
        logger.debug("准备提交更改: \(phoneNumber)")
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller().name("userService-updateParentPhoneNumber")
            .appendData(key: "phoneNumber", value: phoneNumber.toJSON() ?? [:])
            .appendData(key: "parentUserId", value: parentUser.userId)
            .call { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    TKToast.show(msg: "Update parent phone number failed, please try again later.", style: .error)
                    logger.error("更改失败: \(error)")
                } else {
                    self.parentUser?.phoneNumber = phoneNumber
                    self.parentUser?.phone = phoneNumber.string
                }
            }
    }
}

extension StudentDetailsV2ViewController {
    private func onUnbindOnlyForParentTapped() {
        SL.Alert.show(target: self, title: "Unbind parent?", message: "Unbind parent for \(student.name)? tap \"Unbind\" to continue.", leftButttonString: "Unbind", rightButtonString: "Go back", leftButtonColor: ColorUtil.red, rightButtonColor: .clickable) { [weak self] in
            self?.commitUnbindOnlyForParent()
        } rightButtonAction: {
        } onShow: { _ in
        }
    }

    private func commitUnbindOnlyForParent() {
        commitUnbindParent(deleteParent: false)
    }

    private func onUnbindAndDeleteParentTapped() {
        SL.Alert.show(target: self, title: "Unbind & delete parent?", message: "Unbind & delete parent for \(student.name)? tap \"Confirm\" to continue.", leftButttonString: "Confirm", rightButtonString: "Go back", leftButtonColor: ColorUtil.red, rightButtonColor: .clickable) { [weak self] in
            self?.commitUnbindAndDeleteParent()
        } rightButtonAction: {
        } onShow: { _ in
        }
    }

    private func commitUnbindAndDeleteParent() {
        commitUnbindParent(deleteParent: true)
    }

    private func commitUnbindParent(deleteParent: Bool) {
        guard let parentUser = parentUser else { return }
        showFullScreenLoadingNoAutoHide()
        FunctionsCaller().name("userService-unbindParentForStudent")
            .appendData(key: "studentId", value: student.studentId)
            .appendData(key: "parentUserId", value: parentUser.userId)
            .appendData(key: "studioId", value: student.studioId)
            .appendData(key: "deleteParent", value: deleteParent)
            .call { [weak self] _, error in
                guard let self = self else { return }
                self.hideFullScreenLoading()
                if let error {
                    logger.error("解绑家长失败: \(error)")
                } else {
                    logger.debug("解绑家长成功")
                    self.parentUser = nil
                }
            }
    }
}
