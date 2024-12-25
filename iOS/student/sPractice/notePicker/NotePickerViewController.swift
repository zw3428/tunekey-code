//
//  NotePickerViewController.swift
//  TuneKey
//
//  Created by zyf on 2020/6/9.
//  Copyright © 2020 spelist. All rights reserved.
//

import UIKit

protocol NotePickerViewControllerDelegate: NSObjectProtocol {
    func notePickerViewController(didSelectedNote note: TKNoteType)
}

class NotePickerViewController: TKBaseViewController {
    
    enum NoteBasedType {
        case full
        case half
        case quarter
        case eighth
    }

    var noteBasedType: NoteBasedType = .full

    weak var delegate: NotePickerViewControllerDelegate?

    private let heightForContentView: CGFloat = 400

    private var selectedIndex: Int = 0

    private var noteData: [TKNoteType] {
        switch noteBasedType {
        case .full:
            return [.full, .half_2, .half_rest_and_half, .half_3, .half_rest_and_half_2, .half_and_half_rest_and_half, .half_2_and_half_rest, .half_rest_and_half_and_half_rest, .quarter_4, .quarter_rest_and_quarter_and_quarter_rest_and_quarter, .quarter_2_and_half, .half_and_quarter_2, .dotted_half_and_quarter, .quarter_and_dotted_half, .quarter_and_half_and_quarter]
        case .half:
            return [.half, .quarter_2, .quarter_rest_and_quarter, .quarter_3, .quarter_rest_and_quarter_2, .quarter_and_quarter_rest_and_quarter, .quarter_2_and_quarter_rest, .quarter_rest_and_quarter_and_quarter_rest, .eighth_4, .eighth_rest_and_eighth_and_eighth_rest_and_eighth, .eighth_2_and_quarter, .quarter_and_eighth_2, .dotted_quarter_and_eighth, .eighth_and_dooted_quarter, .eighth_and_quarter_and_eighth]
        case .quarter:
            return [.quarter, .eighth_2, .eighth_rest_and_eighth, .eighth_3, .eighth_rest_and_eighth_2, .eighth_and_eighth_rest_and_eighth, .eighth_2_and_eighth_rest, .eighth_rest_and_eighth_and_eighth_rest, .sixteenth_4, .sixteenth_rest_and_sixteenth_and_sixteenth_rest_and_sixteenth, .sixteenth_2_and_eighth, .eighth_and_sixteenth_2, .dotted_eighth_and_sixteenth, .sixteenth_and_dotted_eighth, .sixteenth_and_eighth_and_sixteenth]
        case .eighth:
            return [.eighth, .sixteenth_2, .sixteenth_rest_and_sixteenth, .sixteenth_3, .sixteenth_rest_and_sixteenth_2, .sixteenth_and_sixteenth_rest_and_sixteenth, .sixteenth_2_and_sixteenth_rest, .sixteenth_rest_and_sixteenth_and_sixteenth_rest, .thirty_second_4, .thirty_second_rest_and_thirty_second_and_thirty_second_rest_thirty_second, .thirty_second_2_and_sixteenth, .sixteenth_and_thirty_second_2, .dotted_sixteenth_and_thirty_second, .thirty_second_and_dotted_sixteenth, .thirty_second_and_sixteenth_and_thirty_second]
        }
    }

    var contentView: TKView = TKView.create()
        .backgroundColor(color: .white)
        .corner(size: 10)
        .maskCorner(masks: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
    var pickerView: UIPickerView = UIPickerView()
    var closeButton: TKButton = TKButton.create()
        .title(title: "Close")
        .titleFont(font: FontUtil.bold(size: 18))
        .titleColor(color: ColorUtil.Font.fourth)
    var doneButton: TKButton = TKButton.create()
        .title(title: "Done")
        .titleFont(font: FontUtil.bold(size: 18))
        .titleColor(color: ColorUtil.main)

    override func onViewAppear() {
        super.onViewAppear()
        show()
    }

    func show() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.contentView.transform = CGAffineTransform(translationX: 0, y: -self.heightForContentView)
        }, completion: { [weak self] _ in
            self?.pickerView.reloadAllComponents()
            self?.pickerView.selectRow(0, inComponent: 0, animated: true)
            self?.updatePickerViewSubviews()
        })
    }

    func hide() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.contentView.transform = .identity
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    convenience init(noteBasedType: NoteBasedType, defaultNoteType: TKNoteType) {
        self.init(nibName: nil, bundle: nil)
        self.noteBasedType = noteBasedType
        
        var defaultIndex: Int = 0
        for item in noteData.enumerated() {
            if item.element == defaultNoteType {
                defaultIndex = item.offset
            }
        }
        self.selectedIndex = defaultIndex
    }
}

extension NotePickerViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        view.onViewTapped { [weak self] _ in
            self?.hide()
        }
        contentView.onViewTapped { _ in
        }
        addSubview(view: contentView) { make in
            make.top.equalTo(view.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(heightForContentView)
        }

        let widthForButtons = (UIScreen.main.bounds.width - 40) / 2

        contentView.addSubview(view: closeButton) { make in
            make.bottom.equalToSuperview().offset(-20 - view.safeAreaInsets.bottom)
            make.width.equalTo(widthForButtons)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(50)
        }

        contentView.addSubview(view: doneButton) { make in
            make.bottom.equalToSuperview().offset(-20 - view.safeAreaInsets.bottom)
            make.width.equalTo(widthForButtons)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(50)
        }

        pickerView.delegate = self
        pickerView.dataSource = self
        contentView.addSubview(view: pickerView) { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(doneButton.snp.top).offset(-20)
        }

        TKView.create()
            .backgroundColor(color: ColorUtil.main)
            .addTo(superView: contentView) { make in
                make.center.equalTo(pickerView.snp.center)
                make.left.right.equalToSuperview()
                make.height.equalTo(50)
            }

        contentView.bringSubviewToFront(pickerView)

        doneButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.notePickerViewController(didSelectedNote: self.noteData[self.selectedIndex])
            self.hide()
        }
        
        closeButton.onTapped { [weak self] (_) in
            guard let self = self else { return }
            self.hide()
        }
    }
}

extension NotePickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    private func updatePickerViewSubviews() {
        logger.debug("当前选择的是: \(noteData[selectedIndex])")
        for index in 0 ..< noteData.count {
            if let view = pickerView.view(forRow: index, forComponent: 0) {
                _ = view.subviews.compactMap {
                    if $0 is TKImageView {
                        ($0 as? TKImageView)?.setImage(name: index == selectedIndex ? "\(noteData[index].rawValue)_selected" : noteData[index].rawValue)
                    }
                }
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex = row
        updatePickerViewSubviews()
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        _ = pickerView.subviews.compactMap {
            if $0.frame.height <= 0.5 {
                $0.isHidden = true
            }
        }

        let view = TKView.create()

        TKImageView.create()
            .setImage(name: noteData[row].rawValue)
            .addTo(superView: view) { make in
                make.center.equalToSuperview()
                make.size.equalTo(50)
            }
        return view
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return noteData.count
    }
}
