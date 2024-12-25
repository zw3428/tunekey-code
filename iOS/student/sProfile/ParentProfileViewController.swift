//
//  ParentProfileViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/11/22.
//  Copyright © 2022 spelist. All rights reserved.
//

import AttributedString
import FirebaseFirestore
import PromiseKit
import SnapKit
import UIKit

class ParentProfileViewController: TKBaseViewController {
    private lazy var navigationBar: TKNormalNavigationBar = TKNormalNavigationBar(frame: .zero, title: "Profile")

    private lazy var studentCollectionViewLayout = makeStudentCollectionViewLayout()
    private lazy var studentCollectionView: UICollectionView = makeStudentCollectionView()

    private lazy var studioCollectionViewLayout = makeStudioCollectionViewLayout()
    private lazy var studioCollectionView: UICollectionView = makeStudioCollectionView()

    private var versionLabel: Label = Label().textAlignment(.center)
        .numberOfLines(0)

    @Live private var parentUser: TKUser?

    @Live private var currentStudentPage: Int = 0
    @Live private var currentStudioPage: Int = 0

    private var isDataLoaded: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
}

extension ParentProfileViewController {
    private func makeStudentCollectionViewLayout() -> CenteredCollectionViewFlowLayout {
        let layout = CenteredCollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 30, height: 120)
        return layout
    }

    private func makeStudentCollectionView() -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, centeredCollectionViewFlowLayout: studentCollectionViewLayout)
        collectionView.register(KidCollectionViewCell.self, forCellWithReuseIdentifier: KidCollectionViewCell.id)
        collectionView.register(AddKidCollectionViewCell.self, forCellWithReuseIdentifier: AddKidCollectionViewCell.id)
        collectionView.backgroundColor = ColorUtil.backgroundColor
        collectionView.decelerationRate = .fast
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.tag = 0
        return collectionView
    }

    private func makeStudioCollectionViewLayout() -> CenteredCollectionViewFlowLayout {
        let layout = CenteredCollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 30, height: 110)
        return layout
    }

    private func makeStudioCollectionView() -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, centeredCollectionViewFlowLayout: studioCollectionViewLayout)
        collectionView.register(StudioCollectionViewCell.self, forCellWithReuseIdentifier: StudioCollectionViewCell.id)
        collectionView.backgroundColor = ColorUtil.backgroundColor
        collectionView.decelerationRate = .fast
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.tag = 1
        return collectionView
    }
}

extension ParentProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.tag == 0 {
            guard let currentPage = studentCollectionViewLayout.currentCenteredPage else { return }
            guard currentPage != currentStudentPage else {
                return
            }
            SL.Device.shock(type: .short)
            currentStudentPage = currentPage
        } else {
            guard let currentPage = studioCollectionViewLayout.currentCenteredPage else { return }
            guard currentPage != currentStudentPage else {
                return
            }
            SL.Device.shock(type: .short)
            currentStudioPage = currentPage
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 0 {
            return ParentService.shared.kids.count + 1
        } else {
            return ParentService.shared.currentStudios.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 0 {
            if indexPath.item < ParentService.shared.kids.count {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KidCollectionViewCell.id, for: indexPath) as! KidCollectionViewCell
                let kid = ParentService.shared.kids[indexPath.item]
                cell.avatarModel = .init(id: kid.userId, name: kid.name)
                cell.name = kid.name
                var email = kid.email
                if email.contains(GlobalFields.fakeEmailSuffix) {
                    email = ""
                }
                cell.contactInfo = [kid.phoneNumber.string, email].filter({ !$0.isEmpty }).joined(separator: "\n")
                cell.contentView.onViewTapped { _ in
                    updateUI {
                        let controller = ParentEditKidProfileViewController(kid)
                        controller.enableHero()
                        Tools.getTopViewController()?.present(controller, animated: true)
                    }
                }
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddKidCollectionViewCell.id, for: indexPath) as! AddKidCollectionViewCell
                cell.contentView.onViewTapped { [weak self] _ in
                    self?.onAddKidTapped()
                }
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StudioCollectionViewCell.id, for: indexPath) as! StudioCollectionViewCell
            let studio = ParentService.shared.currentStudios[indexPath.item]
            cell.icon = .init(id: studio.id, name: studio.name)
            cell.name = studio.name
            cell.info = [studio.phoneNumber.string, studio.email].filter({ !$0.isEmpty }).joined(separator: "\n")
            cell.background = studio.storefrontColor
            return cell
        }
    }
}

extension ParentProfileViewController {
    override func initView() {
        super.initView()
        navigationBar.hiddenLeftButton()
        navigationBar.updateLayout(target: self)

        ViewBox {
            VScrollStack {
                ViewBox(top: 10, left: 0, bottom: 10, right: 0) {
                    studentCollectionView
                }.height(140)
                ViewBox(top: 0, left: 0, bottom: 10, right: 0) {
                    studioCollectionView
                }
                .apply { view in
                    ParentService.shared.$currentStudios.addSubscriber { studios in
                        view.isHidden = studios.isEmpty
                    }
                }
                .height(130)
                ViewBox(top: 0, left: 20, bottom: 10, right: 20) {
                    ViewBox(top: 20, left: 20, bottom: 0, right: 0) {
                        VStack {
                            ViewBox(top: 0, left: 0, bottom: 10, right: 0) {
                                Label("Settings").textColor(ColorUtil.Font.primary)
                                    .font(.regular(size: 13))
                            }
                            makeCommonSettingItem(UIImage(named: "profile"), title: "Parent's Profile")
                                .onViewTapped { [weak self] _ in
                                    self?.onParentProfileTapped()
                                }
                            Divider(weight: 1, color: ColorUtil.dividingLine)
                            makeCommonSettingItem(UIImage(named: "icChangePassword"), title: "Password")
                                .onViewTapped { _ in
                                    let controller = ChangePasswordViewController()
                                    controller.enableHero()
                                    Tools.getTopViewController()?.present(controller, animated: true, completion: nil)
                                }
//                            Divider(weight: 1, color: ColorUtil.dividingLine)
//                            makeCommonSettingItem(UIImage(named: "icCalendar"), title: "Calendar Connection")
                            Divider(weight: 1, color: ColorUtil.dividingLine)
                            makeCommonSettingItem(UIImage(named: "billing"), title: "Payment")
                                .onViewTapped { [weak self] _ in
                                    guard let self = self else { return }
                                    let controller = ParentPaymentViewController()
                                    controller.enableHero()
                                    self.present(controller, animated: true)
//                                    guard let student = ParentService.shared.currentStudent else { return }
//                                    let controller = StudentDetailsBalanceViewController(student)
//                                    controller.isStudentView = true
//                                    controller.enableHero()
//                                    self.present(controller, animated: true)
                                }
                            Divider(weight: 1, color: ColorUtil.dividingLine)
                            makeCommonSettingItem(UIImage(named: "icMessage"), title: "Contact Us")
                                .onViewTapped { _ in
                                    let controller = ContactUsSelectorViewController()
                                    controller.modalPresentationStyle = .custom
                                    Tools.getTopViewController()?.present(controller, animated: false, completion: nil)
                                }
                            Divider(weight: 1, color: ColorUtil.dividingLine)
                            makeCommonSettingItem(UIImage(named: "icTerms"), title: "Terms and Privacy")
                                .onViewTapped { _ in
                                    let controller = ProfileAboutUsViewController()
                                    controller.enableHero()
                                    Tools.getTopViewController()?.present(controller, animated: true, completion: nil)
                                }
                            Divider(weight: 1, color: ColorUtil.dividingLine)
                            makeCommonSettingItem(UIImage(named: "faq"), title: "FAQ")
                                .onViewTapped { _ in
                                    CommonsWebViewViewController.show("https://www.tunekey.app/faq/mobile")
                                }
                        }
                    }.cardStyle()
                }
                ViewBox(top: 40, left: 20, bottom: 20, right: 20) {
                    versionLabel
                }
                Spacer(spacing: 200)
            }
        }.addTo(superView: view) { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func makeCommonSettingItem(_ icon: UIImage?, title: String) -> ViewBox {
        ViewBox(top: 16, left: 0, bottom: 16, right: 20) {
            HStack(alignment: .center, spacing: 20) {
                ImageView(image: icon?.resizeImage(CGSize(width: 22, height: 22))).size(width: 22, height: 22)
                Label(title).textColor(ColorUtil.Font.third).font(.bold(18))
                ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
            }
        }
    }
}

extension ParentProfileViewController {
    override func bindEvent() {
        super.bindEvent()
        $currentStudentPage.addSubscriber { currentPage in
            logger.debug("翻页了: \(currentPage)")
            if ParentService.shared.kids.isSafeIndex(currentPage) {
                ParentService.shared.currentKid = ParentService.shared.kids[currentPage]
            } else {
                ParentService.shared.currentKid = nil
            }
            if let student = ParentService.shared.students.first(where: { $0.studentId == ParentService.shared.currentKid?.userId ?? "" }) {
                guard ParentService.shared.currentStudent?.studentId ?? "" != student.studentId else {
                    logger.debug("相同的选择,不做事件发送")
                    return
                }
                logger.debug("更改已选择的学生: \(student.studentId)")
                ParentService.shared.currentStudent = student
                ParentService.shared.currentStudios = ParentService.shared.studios.filter({ $0.id == student.studioId })
            } else {
                logger.debug("当前更改选择的学生为空")
                ParentService.shared.currentStudent = nil
                ParentService.shared.currentStudios = []
            }

            EventBus.send(key: .parentKidSelected)
        }

        ParentService.shared.$currentStudios.addSubscriber { [weak self] _ in
            self?.studioCollectionView.reloadData()
        }

        EventBus.listen(key: .parentDataLoaded, target: self) { [weak self] _ in
            self?.loadData()
        }
    }

    private func onAddKidTapped() {
        StudioTeamsNewStudentV2ViewController.show(for: parentUser) {
            ParentService.shared.reloadData()
        }
    }

    private func onParentProfileTapped() {
        updateUI {
            let controller = ParentProfileEditViewController()
            controller.enableHero()
            Tools.getTopViewController()?.present(controller, animated: true)
        }
    }
}

extension ParentProfileViewController {
    override func initData() {
        super.initData()
        AppService.shared.fetchAppVersionFromAppStore()
            .done { [weak self] appVersion in
                guard let self = self else { return }
                if let appVersion {
                    logger.debug("获取到的版本信息: \(appVersion)")
                    if appVersion != iosVersion {
                        let attributedTexts = ASAttributedString(string: "Your current version is \(iosVersion) for iOS.\nThe latest version is available for update. ", with: [.font(FontUtil.medium(size: 13)), .foreground(ColorUtil.Font.fourth)]) + ASAttributedString(string: "UPDATE NOW", with: [.font(FontUtil.medium(size: 13)), .foreground(ColorUtil.main), .action({
                            let url = URL(string: "https://apps.apple.com/app/id1479006791")!
                            UIApplication.shared.open(url)
                        })])
                        self.versionLabel.attributed.text = attributedTexts
                    } else {
                        let attributedTexts = ASAttributedString(string: "Your current version is \(iosVersion) for iOS.\nYour Tunekey has been updated to the latest version.", with: [.font(FontUtil.medium(size: 13)), .foreground(ColorUtil.Font.fourth)])
                        self.versionLabel.attributed.text = attributedTexts
                    }
                } else {
                    logger.error("获取到的版本信息是空的")
                }
            }
            .catch { error in
                logger.error("获取版本信息失败: \(error)")
            }
    }

    private func loadData() {
        parentUser = ListenerService.shared.user
        updateUI {
            logger.debug("重新加载数据")
            self.currentStudentPage = self.studentCollectionViewLayout.currentCenteredPage ?? 0
            self.studentCollectionView.reloadData()
            self.studioCollectionView.reloadData()
        }
    }
}

extension ParentProfileViewController {
    class KidCollectionViewCell: TKBaseCollectionViewCell {
        static let id: String = String(describing: KidCollectionViewCell.self)

        @Live var avatarModel: AvatarView.Model = .init(id: "", name: "")
        @Live var name: String = ""
        @Live var contactInfo: String = ""

        override func initViews() {
            super.initViews()

            ViewBox(top: 10, left: 5, bottom: 10, right: 5) {
                ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                    HStack(alignment: .center, spacing: 20) {
                        AvatarView(size: 60).loadAvatar(withUser: $avatarModel)
                        VStack(spacing: 3) {
                            Label($name).textColor(ColorUtil.Font.third)
                                .font(.bold(18))
                                .contentHuggingPriority(.defaultHigh, for: .vertical)
                                .contentCompressionResistancePriority(.defaultHigh, for: .vertical)
                            Label($contactInfo).textColor(ColorUtil.Font.primary)
                                .font(.regular(size: 13))
                                .numberOfLines(0)
                                .contentHuggingPriority(.defaultHigh, for: .vertical)
                                .contentCompressionResistancePriority(.defaultHigh, for: .vertical)
                        }
                        ImageView(image: UIImage(named: "arrowRight")).size(width: 22, height: 22)
                    }
                }.cardStyle()
            }.fill(in: contentView)
        }
    }

    class StudioCollectionViewCell: TKBaseCollectionViewCell {
        static let id = String(describing: StudioCollectionViewCell.self)
        @Live var icon: AvatarView.Model = .init(id: "", name: "")
        @Live var name: String = ""
        @Live var info: String = ""
        @Live var background: String = ""
        override func initViews() {
            super.initViews()
            ViewBox(paddings: UIEdgeInsets(top: 0, left: 5, bottom: 10, right: 5)) {
                ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                    HStack {
                        AvatarView(size: 60)
                            .loadAvatar(withStudio: $icon)
                            .size(width: 60, height: 60)
                        Spacer(spacing: 20)
                        VStack {
                            Label($name)
                                .font(.bold(18))
                                .textColor(.white)
                            Spacer(spacing: 6)
                            Label($info)
                                .font(.regular(size: 13))
                                .textColor(.white)
                        }
                    }
                }
                .backgroundColor(withHex: $background)
                .cardStyle()
            }
            .addTo(superView: contentView) { make in
                make.top.left.right.bottom.equalToSuperview()
            }
        }
    }

    class AddKidCollectionViewCell: TKBaseCollectionViewCell {
        static let id: String = String(describing: AddKidCollectionViewCell.self)
        override func initViews() {
            super.initViews()
            ViewBox(top: 10, left: 5, bottom: 10, right: 5) {
                ViewBox(top: 20, left: 20, bottom: 20, right: 20) {
                    HStack(alignment: .center, spacing: 20) {
                        ImageView(image: UIImage(named: "icAddPrimary")?.imageWithTintColor(color: .white).resizeImage(CGSize(width: 23, height: 23)))
                            .contentMode(.center)
                            .cornerRadius(30)
                            .size(width: 60, height: 60)
                            .borderColor(.white)
                            .borderWidth(1)
                        Label("Add Kid").textColor(.white).font(.bold(18))
                    }
                }
                .cardStyle()
                .backgroundColor(ColorUtil.main)
            }
            .fill(in: contentView)
        }
    }
}
