//
//  DigitalSignatureController.swift
//  TuneKey
//
//  Created by WHT on 2020/10/21.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

class DigitalSignatureController: TKBaseViewController {
    var mainView = UIView()
    var studentId: String = ""
    var teacherId: String = ""
    private var backView = UIView()
    private var titleLable: TKLabel!
    private var signView: TKView!
    private var signTimeLabel: TKLabel!
    private var leftButton: TKBlockButton!
    private var rightButton: TKBlockButton!
    private var buttonLayout: TKView!
    private var signatureView: SwiftSignatureView!
    var confirmAction: ((_ signature: UIImage) -> Void)!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
}

// MARK: - View

extension DigitalSignatureController {
    override func initView() {
        view.backgroundColor = UIColor.clear
        initBackView()
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.height.equalTo(340)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalToSuperview()
        }
        mainView.backgroundColor = UIColor.white
        mainView.setTopRadius()
        mainView.transform = CGAffineTransform(translationX: 0, y: 500)
        initSignView()
    }

    private func initBackView() {
        backView.backgroundColor = UIColor.black.withAlphaComponent(0)
        view.addSubview(view: backView) { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-UiUtil.safeAreaBottom())
        }
        backView.isUserInteractionEnabled = true
        backView.onViewTapped { _ in
        }
    }

    private func initSignView() {
        titleLable = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Digital signature")
            .addTo(superView: mainView, withConstraints: { make in
                make.left.top.equalToSuperview().offset(20)
            })
        signView = TKView.create()
            .showBorder(color: ColorUtil.dividingLine)
            .corner(size: 5)
            .addTo(superView: mainView, withConstraints: { make in
                make.top.equalTo(titleLable.snp.bottom).offset(10)
                make.left.equalTo(20)
                make.right.equalTo(-20)
                make.size.equalTo(200)
            })
        signatureView = SwiftSignatureView()
        signatureView.delegate = self
        signatureView.maximumStrokeWidth = 5
        signatureView.minimumStrokeWidth = 3
        signView.addSubview(view: signatureView) { make in
            make.top.right.left.bottom.equalToSuperview()
        }
        signTimeLabel = TKLabel.create()
            .textColor(color: UIColor.black)
            .addTo(superView: signView, withConstraints: { make in
                make.right.bottom.equalTo(-10)
            })
        signTimeLabel.font = UIFont(name: "Bradley Hand", size: 15)
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy"
        signTimeLabel.text("\(df.string(from: Date()))")

        var buttonWidth: CGFloat = 0
        if deviceType == .phone {
            buttonWidth = (UIScreen.main.bounds.width - 50) / 2
        } else {
            buttonWidth = 330 / 2
        }
        buttonLayout = TKView()
        mainView.addSubview(view: buttonLayout) { make in
            make.height.equalTo(52)
            make.top.equalTo(signView.snp.bottom).offset(20)
            if deviceType == .phone {
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            } else {
                make.width.equalTo(340)
                make.centerX.equalToSuperview()
            }
        }
        rightButton = TKBlockButton(frame: CGRect.zero, title: "SUBMIT", style: .normal)
        rightButton.disable()
        buttonLayout.addSubview(rightButton)
        rightButton.onTapped { [weak self] _ in
            guard let self = self, let signatureImg = self.signatureView.getCroppedSignature() else { return }
            self.uploadSignature(image: signatureImg)
        }
        rightButton.snp.makeConstraints { make in
            make.width.equalTo(buttonWidth)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(50)
        }
        leftButton = TKBlockButton(frame: CGRect.zero, title: "CANCEL", style: .cancel)

        buttonLayout.addSubview(leftButton)
        leftButton.snp.makeConstraints { make in
            make.width.equalTo(buttonWidth)
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(50)
        }
        leftButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.hide()
        }
    }
}

// MARK: - Data

extension DigitalSignatureController {
    override func initData() {
    }

    func uploadSignature(image: UIImage) {
        guard let imageData = image.pngData() else {
            TKToast.showConnectionFailedToast()
            return
        }
        showFullScreenLoadingNoAutoHide()
        StorageService.shared.uploadFile(with: imageData, to: "/signature/\(teacherId):\(studentId).png") { progress, _ in
            print("progress:\(progress)")
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.updateStudentList(image)
        }
    }

    func updateStudentList(_ image: UIImage) {
        addSubscribe(
            UserService.teacher.updateStudentList(studentId: studentId, teacherId: teacherId, data: ["signPolicyTime": Date().timestamp])
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    self.hide {
                        TKToast.show(msg: "Submit Successful!")
                        self.confirmAction(image)
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    TKToast.showConnectionFailedToast()
                    logger.debug("======\(err)")
                })
        )
    }
}

// MARK: - Action

extension DigitalSignatureController: SwiftSignatureViewDelegate {
    func swiftSignatureViewDidDrawGesture(_ view: ISignatureView, _ tap: UIGestureRecognizer) {
    }

    func swiftSignatureViewDidDraw(_ view: ISignatureView) {
        rightButton.enable()
    }

    func show() {
        UIView.animate(withDuration: 0.3) {
            self.backView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.mainView.transform = CGAffineTransform.identity
        }
    }

    func hide(completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: 0.3, animations: {
            self.backView.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.mainView.frame.origin = CGPoint(x: 0, y: TKScreen.height)
        }) { _ in
            self.dismiss(animated: false, completion: {
                completion()
            })
        }
    }
}
