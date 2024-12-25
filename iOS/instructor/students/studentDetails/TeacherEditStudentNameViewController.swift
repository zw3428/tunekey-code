//
//  TeacherEditStudentNameViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/9/24.
//  Copyright © 2021 spelist. All rights reserved.
//

import FirebaseFirestore
import SnapKit
import UIKit

class TeacherEditStudentNameViewController: TKBaseViewController {
    enum TargetType {
        case nickname
        case realName
    }

    private let contentViewHeight: CGFloat = 264 + UiUtil.safeAreaBottom()
    lazy var contentView: TKView = makeContentView()
    var nameTextBox: TKTextBox = TKTextBox.create()
        .placeholder(nil)
        .keyboardType(.default)
        .inputType(.text)
        .isShadowShow(false)
    private var targetTypeRadioGroup: TKRadioGroup = TKRadioGroup(["Set as nickname", "Change real name"])
    var cancelButton: TKBlockButton = TKBlockButton(frame: .zero, title: "CANCEL", style: .cancel)
    var updateButton: TKBlockButton = TKBlockButton(frame: .zero, title: "UPDATE")

    var student: TKStudent

    private var targetType: TargetType = .nickname

    private var isShow: Bool = false

    init(_ student: TKStudent) {
        self.student = student
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
}

extension TeacherEditStudentNameViewController {
    private func makeContentView() -> TKView {
        let view = TKView.create()
            .backgroundColor(color: .white)
            .corner(size: 10)
            .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

        let titleLabel = Label("Edit Name").textColor(.tertiary)
            .font(.cardTitle)
            .addTo(superView: view) { make in
                make.top.equalToSuperview().offset(20)
                make.left.equalToSuperview().offset(20)
                make.height.equalTo(20)
            }

        nameTextBox.addTo(superView: view) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(64)
        }

        targetTypeRadioGroup.addTo(superView: view) { make in
            make.top.equalTo(nameTextBox.snp.bottom).offset(10)
            make.height.equalTo(20)
            make.right.equalToSuperview().offset(-20)
        }
        targetTypeRadioGroup.select(at: 0)
        targetTypeRadioGroup.onItemSelected { [weak self] index in
            guard let self = self else { return }
            switch index {
            case 0:
                self.targetType = .nickname
            default:
                self.targetType = .realName
            }
        }

        let buttonWidth = (UIScreen.main.bounds.width - 50) / 2
        cancelButton.addTo(superView: view) { make in
            make.top.equalTo(targetTypeRadioGroup.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(50)
            make.width.equalTo(buttonWidth)
        }

        updateButton.addTo(superView: view) { make in
            make.top.equalTo(targetTypeRadioGroup.snp.bottom).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(50)
            make.width.equalTo(buttonWidth)
        }

        return view
    }
}

extension TeacherEditStudentNameViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        contentView.addTo(superView: view) { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(contentViewHeight)
        }
        contentView.transform = CGAffineTransform(translationX: 0, y: contentViewHeight)
        nameTextBox.value(student.name)
    }

    private func show() {
        guard !isShow else { return }
        isShow = true

        animate(timeInterval: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = .identity
        } completion: { [weak self] in
            self?.nameTextBox.focus()
        }
    }

    private func hide() {
        animate(timeInterval: 0.2) { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: self.contentViewHeight)
        } completion: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}

extension TeacherEditStudentNameViewController {
    override func bindEvent() {
        super.bindEvent()

        cancelButton.onTapped { [weak self] _ in
            self?.hide()
        }

        updateButton.onTapped { [weak self] _ in
            self?.updateNickname()
        }
    }

    private func updateNickname() {
        guard let user = ListenerService.shared.user else { return }
        let name = nameTextBox.getValue()
        guard !name.isEmpty else {
            return
        }
        view.endEditing(true)
        cancelButton.disable()

        let id: String
        switch user.currentUserDataVersion {
        case .singleTeacher:
            id = student.teacherId
        case .studio:
            id = student.studioId
        default: return
        }
        logger.debug("准备修改 \(student.studentId) 的姓名，修改方式: \(targetType) ｜ 改为: \(name)")
        updateButton.startLoading { [weak self] in
            guard let self = self else { return }
            Firestore.firestore().runTransaction { transaction, _ in
                transaction.updateData(["name": name], forDocument: DatabaseService.collections.teacherStudentList().document("\(id):\(self.student.studentId)"))
                if self.targetType == .realName {
                    transaction.updateData(["name": name], forDocument: DatabaseService.collections.user().document(self.student.studentId))
                }
                return nil
            } completion: { _, error in
                if let error = error {
                    logger.error("更新失败: \(error)")
                    self.cancelButton.enable()
                    self.updateButton.stopLoadingWithFailed()
                    TKToast.show(msg: TipMsg.saveFailed, style: .error)
                } else {
                    EventBus.send(key: .teacherStudentListChanged)
                    self.cancelButton.enable()
                    self.updateButton.stopLoading {
                        self.hide()
                    }
                }
            }
        }
    }
}
