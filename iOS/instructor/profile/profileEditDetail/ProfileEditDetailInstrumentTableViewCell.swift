//
//  ProfileEditDetailInstrumentTableViewCell.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/9.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class ProfileEditDetailInstrumentTableViewCell: UITableViewCell {
    static let defaultHeight: CGFloat = 78

    var cellHeight: CGFloat = 78

    weak var delegate: ProfileEditDetailInstrumentTableViewCellDelegate?

    var data: [TKInstrument] = []

    var currentInstrument: TKInstrument!

    var index: Int = 0

    var number: Int = 0

    private var backView: TKView!
    private var barView: TKView!
    private var titleLabel: TKLabel!
    private var currentInstrumentImageView: TKImageView!
    private var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewFlowLayout!
    private var loadingView: TKLoading!

    private var deleteButton: TKButton!

    private var itemHeight: CGFloat = 0

    private var isOpen: Bool = false
    private var selectAnIconLabel: TKLabel!
    private var arrowImageView: TKImageView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initView()
        bindEvents()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileEditDetailInstrumentTableViewCell {
    private func initView() {
        contentView.backgroundColor = ColorUtil.backgroundColor
        deleteButton = TKButton.create()
            .setImage(name: "close", size: CGSize(width: 22, height: 22))
        contentView.addSubview(view: deleteButton) { make in
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(70)
            make.height.equalTo(78)
        }

        backView = TKView.create()
            .backgroundColor(color: UIColor.white)
            .corner(size: 5)
            .showShadow()
            .showBorder(color: ColorUtil.borderColor)
        contentView.addSubview(view: backView) { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10)
        }

        titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 18))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Icon of lesson type")

        backView.addSubview(view: titleLabel) { make in
            make.top.equalToSuperview().offset(24)
//            make.right.equalToSuperview().offset(-20)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(20)
        }
        arrowImageView = TKImageView.create()
            .setImage(name: "icArrowDown")
            .addTo(superView: backView, withConstraints: { make in
                make.right.equalToSuperview().offset(-10)
                make.size.equalTo(22)
                make.centerY.equalTo(titleLabel)
            })
        selectAnIconLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: ColorUtil.main)
            .text(text: "Select an icon")
            .addTo(superView: backView, withConstraints: { make in
                make.right.equalTo(arrowImageView.snp.left).offset(-5)
                make.centerY.equalTo(titleLabel)
            })

        currentInstrumentImageView = TKImageView.create()
            .setImage(color: ColorUtil.main)
            .setSize(48)
            .asCircle()
        currentInstrumentImageView.image = nil
        backView.addSubview(view: currentInstrumentImageView) { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.size.equalTo(48)
            make.left.equalToSuperview().offset(20)
        }

        collectionViewLayout = UICollectionViewFlowLayout()
        var width = (UIScreen.main.bounds.width - 86) / 4
        if width >= 72 {
            width = 72
        }
        itemHeight = width + 18
        collectionViewLayout.itemSize = CGSize(width: width, height: itemHeight)
        collectionViewLayout.minimumInteritemSpacing = 2
        collectionViewLayout.minimumLineSpacing = 10
        collectionViewLayout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(ProfileEditDetailInstrumentItemCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ProfileEditDetailInstrumentItemCollectionViewCell.self))
        backView.addSubview(view: collectionView) { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(35)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(10)
        }
        collectionView.layer.opacity = 0

        loadingView = TKLoading()
        backView.addSubview(view: loadingView) { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.left.equalTo(titleLabel.snp.right).offset(4)
            make.size.equalTo(10)
        }
        loadingView.show(size: 10)

        barView = TKView.create()
            .backgroundColor(color: UIColor.white.withAlphaComponent(0))
        backView.addSubview(view: barView) { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(78)
        }

        cellHeight = 78
    }

    private func bindEvents() {
        deleteButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.profileEditDetailInstrumentTableViewCell(removeAt: self.index)
        }

        barView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if !self.isOpen {
                if self.data.count == 0 {
                    self.delegate?.profileEditDetailInstrumentTableViewCell(tappedAt: self.index)
                } else {
                    self.open(data: self.data)
                }
            } else {
                guard self.currentInstrument != nil else {
                    return
                }
                self.close(with: self.currentInstrument)
            }
        }

        barView.onTouchesBegan { [weak self] _, _ in
            self?.delegate?.profileEditDetailInstrumentTableViewCell(isEditing: true)
        }

        barView.onTouchesMoved { [weak self] touches, _ in
            guard let self = self else { return }
            self.delegate?.profileEditDetailInstrumentTableViewCell(isEditing: true)
            if let touch = touches.first {
                let point = touch.location(in: self.backView)
                let prePoint = touch.previousLocation(in: self.backView)

                if prePoint.x > point.x {
                    if self.backView.center.x <= (UIScreen.main.bounds.width / 2 - 70) {
                    } else {
                        self.backView.center.x -= (prePoint.x - point.x)
                    }
                } else {
                    if self.backView.center.x <= (UIScreen.main.bounds.width / 2) {
                        self.backView.center.x -= (prePoint.x - point.x)
                    }
                }
            }
        }

        barView.onTouchesEnded { [weak self] _, _ in
            guard let self = self else { return }
            if self.backView.center.x <= (UIScreen.main.bounds.width / 2 - 35) {
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.backView.center.x = UIScreen.main.bounds.width / 2 - 70
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.backView.center.x = UIScreen.main.bounds.width / 2
                })
            }
            self.delegate?.profileEditDetailInstrumentTableViewCell(isEditing: false)
        }
    }

    private func getNumber(number: Int) -> String {
        guard number > 0 else {
            return ""
        }
        switch number {
        case 1:
            return "Primary"
        case 2:
            return "Second"
        case 3:
            return "Third"
        case 4:
            return "Fourth"
        default:
            return "\(number.description)th"
        }
    }
}

extension ProfileEditDetailInstrumentTableViewCell {
    func loadData(instrument: TKInstrument?, number: Int) {
        guard let instrument = instrument else {
            return
        }
        loadingView.hide()
        currentInstrument = instrument
        self.number = number + 1
        if instrument.minPictureUrl == "" {
            if #available(iOS 13.0, *) {
                currentInstrumentImageView.image = UIImage(named: "8|8_selected")?.resizeImage(CGSize(width: 35, height: 35)).withTintColor(ColorUtil.gray)
            } else {
                currentInstrumentImageView.image = UIImage(named: "8|8")?.resizeImage(CGSize(width: 35, height: 35))
            }
            currentInstrumentImageView.setBorder()
            currentInstrumentImageView.contentMode = .center
        } else {
            currentInstrumentImageView.contentMode = .scaleAspectFit
            currentInstrumentImageView.sd_setImage(with: URL(string: instrument.minPictureUrl), completed: nil)
        }
//        titleLabel.text("\(instrument.name.description)")
        titleLabel.text("")
    }

    func loadingHide(data: [TKInstrument]) {
        self.data = data
        loadingView.hide()
    }

    func open(data: [TKInstrument]) {
        self.data = data
        selectAnIconLabel.isHidden = true
        UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.arrowImageView?.transform = CGAffineTransform.identity
                .rotated(by: CGFloat(Double.pi))
        }) {  _ in
            
        }
        if data.count > 0 {
            loadingView.hide()
            collectionView.reloadData()
            collectionView.sizeToFit()
            var height: CGFloat = 0
            var lineNumber: Int = 0
            if data.count % 4 == 0 {
                lineNumber = data.count / 4
            } else {
                lineNumber = (data.count / 4) + 1
            }
            height = CGFloat(lineNumber) * itemHeight + CGFloat(lineNumber - 1) * 10
            collectionView.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.collectionView.layer.opacity = 1
                self.cellHeight = height + 99
                if self.cellHeight >= 600 {
                    self.cellHeight = 600
                }
                self.delegate?.profileEditDetailInstrumentTableViewCell(heightChanged: self.cellHeight, at: self.index)
            }
            isOpen = true
        }
    }

    func close(with instrument: TKInstrument) {
        UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.arrowImageView?.transform = CGAffineTransform.identity
                
        }) {  _ in
            
        }
        selectAnIconLabel.isHidden = false
        currentInstrument = instrument
        loadData(instrument: instrument, number: 0)
        collectionView.layer.opacity = 0
        cellHeight = 78
        delegate?.profileEditDetailInstrumentTableViewCell(heightChanged: cellHeight, at: index)
        isOpen = false
    }
}

extension ProfileEditDetailInstrumentTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let instrument = data[indexPath.item]
        if currentInstrument != nil && instrument.id == currentInstrument.id {
            delegate?.profileEditDetailInstrumentTableViewCell(currentInstrumentChanged: instrument, target: self)
        } else {
            let imageViewCopy: TKImageView = TKImageView.create()
            let imageView = (collectionView.cellForItem(at: indexPath) as! ProfileEditDetailInstrumentItemCollectionViewCell).imageView!
            imageViewCopy.image = imageView.image
            _ = imageViewCopy.setSize(48)
            _ = imageViewCopy.asCircle()
            let point = imageView.convert(imageView.frame.origin, to: backView)
            imageViewCopy.frame = CGRect(origin: point, size: imageView.frame.size)
            backView.addSubview(imageViewCopy)
            UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: { [weak self] in
                guard let self = self else { return }
                imageViewCopy.frame = self.currentInstrumentImageView.frame
                self.titleLabel.text("")
            }) { [weak self] _ in
                guard let self = self else { return }
                self.currentInstrumentImageView.image = imageViewCopy.image
                imageViewCopy.removeFromSuperview()
                self.delegate?.profileEditDetailInstrumentTableViewCell(currentInstrumentChanged: instrument, target: self)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ProfileEditDetailInstrumentItemCollectionViewCell.self), for: indexPath) as! ProfileEditDetailInstrumentItemCollectionViewCell
        cell.loadData(data: data[indexPath.item])
        return cell
    }
}

protocol ProfileEditDetailInstrumentTableViewCellDelegate: NSObjectProtocol {
    func profileEditDetailInstrumentTableViewCell(currentInstrumentChanged instrument: TKInstrument, target: ProfileEditDetailInstrumentTableViewCell)
    func profileEditDetailInstrumentTableViewCell(heightChanged height: CGFloat, at index: Int)
    func profileEditDetailInstrumentTableViewCell(tappedAt index: Int)
    func profileEditDetailInstrumentTableViewCell(isEditing: Bool)
    func profileEditDetailInstrumentTableViewCell(removeAt index: Int)
}
