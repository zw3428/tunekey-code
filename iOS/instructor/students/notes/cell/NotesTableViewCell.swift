//
//  NotesTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2022/11/9.
//  Copyright © 2022 spelist. All rights reserved.
//

import SnapKit
import UIKit

class NotesTableViewCell: UITableViewCell {
    static let id: String = String(describing: NotesTableViewCell.self)
    struct NoteData {
        var who: String
        var note: String
    }

    @Live var date: String = ""
    @Live var notes: [NoteData] = []

    private var textViews: [TextView] = []

    @Live var layoutSubviewsCount: Int = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSubviewsCount += 1
    }
}

extension NotesTableViewCell {
    private func initViews() {
        ViewBox(paddings: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)) {
            ViewBox(paddings: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
                VStack(spacing: 10) {
                    HStack(alignment: .center, spacing: 10) {
                        ImageView(image: UIImage(named: "icCalendar"))
                            .size(width: 22, height: 22)
                        Label($date).textColor(ColorUtil.Font.third)
                            .font(FontUtil.bold(size: 18))
                    }
                    .height(22)
                    .contentCompressionResistancePriority(.defaultHigh, for: .vertical)
                    ViewBox(left: 32) {
                        VList(spacing: 10, withData: $notes) { notes in
                            for note in notes {
                                TextView().isEditable(false)
                                    .isSelectable(true)
                                    .isScrollEnabled(false)
                                    .contentCompressionResistancePriority(.defaultHigh, for: .vertical)
                                    .apply { textView in
                                        textView.textContainer.lineFragmentPadding = 0
                                        textView.tintColor = .clickable
                                        textView.attributedText = Tools.attributenStringColor(text: "\(note.who)\(note.note)",
                                                                                              selectedText: note.who,
                                                                                              allColor: ColorUtil.Font.third,
                                                                                              selectedColor: ColorUtil.Font.primary,
                                                                                              font: FontUtil.regular(size: 18),
                                                                                              selectedFont: FontUtil.regular(size: 18),
                                                                                              fontSize: 18,
                                                                                              selectedFontSize: 18)
                                    }
                            }
                        }
                    }
                    .apply { [weak self] view in
                        guard let self = self else { return }
                        self.$notes.addSubscriber { notes in
                            if notes.isEmpty {
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
        .backgroundColor(ColorUtil.backgroundColor)
        .fill(in: contentView)
    }

    func getHeight() -> CGFloat {
        let fixedHeight: CGFloat = 10 + 10 + 20 + 20 + 22 + (notes.isEmpty ? 0 : 10)
        var height: CGFloat = fixedHeight
        for note in notes {
            let text = "\(note.who)\(note.note)"
            let h = text.heightWithStringAttributes(attributes: [NSAttributedString.Key.font: FontUtil.regular(size: 18)], fixedWidth: UIScreen.main.bounds.width - 112)
            height += h
        }
        height += (CGFloat(notes.count) * 10 )
        return height
    }
}
