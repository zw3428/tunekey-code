//
//  LessonDetailsMemoTableViewCell.swift
//  TuneKey
//
//  Created by zyf on 2022/9/14.
//  Copyright © 2022 spelist. All rights reserved.
//

import AttributedString
import UIKit

protocol LessonDetailsMemoTableViewCellDelegate: NSObjectProtocol {
    func lessonDetailsMemoTableViewCell(heightChanged height: CGFloat)
}

class LessonDetailsMemoTableViewCell: UITableViewCell {
    static let id: String = String(describing: LessonDetailsMemoTableViewCell.self)

    weak var delegate: LessonDetailsMemoTableViewCellDelegate?
    var onRecordAttendanceTapped: (() -> Void)?
    @Live var isRecordAttendanceHidden: Bool = true
    var cellHeight: CGFloat = 0

    var memo: String = ""

    var memoLabel: Label?
//    var memoLabel: TextView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LessonDetailsMemoTableViewCell {
    private func initViews() {
        ViewBox(paddings: UIEdgeInsets(top: 30, left: 20, bottom: 10, right: 20)) {
            VStack(spacing: 20) {
                Button().title("Record attendance", for: .normal)
                    .titleColor(ColorUtil.main, for: .normal)
                    .font(FontUtil.regular(size: 15))
                    .size(width: 150, height: 20)
                    .isHidden($isRecordAttendanceHidden)
                    .onTapped { [weak self] _ in
                        guard let self = self else { return }
                        self.onRecordAttendanceTapped?()
                    }
                Label().numberOfLines(0)
                    .apply { [weak self] label in
                        guard let self = self else { return }
                        self.memoLabel = label
                    }
            }
        }
        .backgroundColor(.white)
        .addTo(superView: contentView) { make in
            make.top.left.right.bottom.equalToSuperview()
        }

//        $cellHeight.addSubscriber { [weak self] height in
//            guard let self = self else { return }
//            self.delegate?.lessonDetailsMemoTableViewCell(heightChanged: height)
//        }
//
//        $memo.addSubscriber { [weak self] memoString in
//            guard let self = self else { return }
//            if memoString == "" {
//                self.cellHeight = 0
//            } else {
//                let memoHeight: CGFloat = memoString.heightWithFont(font: FontUtil.regular(size: 13), fixedWidth: UIScreen.main.bounds.width - 40)
//                logger.debug("memo 的高度: \(memoHeight)")
//                self.cellHeight = memoHeight + 40
//            }
//        }
    }

    func setMemo(_ memoString: String, attendance: [TKLessonSchedule.Attendance]) {
//        _ = memoLabel?.text(memoString)
        var content: String = memoString.replacingOccurrences(of: "\n", with: "")
        content = content.trimmingCharacters(in: .whitespaces)
        let regulaStr = "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)"
        guard let regex = try? NSRegularExpression(pattern: regulaStr, options: []) else {
            return
        }
        let results = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
        var attrString = ASAttributedString(string: content, .font(FontUtil.regular(size: 13)), .foreground(ColorUtil.Font.primary), .paragraph(.alignment(.center), .lineBreakMode(.byWordWrapping)))

        for result in results {
            attrString = attrString.set([.font(FontUtil.bold(size: 13)), .foreground(ColorUtil.main), .action({
                guard let range = Range(result.range, in: content) else { return }
                let value = content[range]
                logger.debug("点击了action: \(value)")
                guard let url = URL(string: String(value)) else { return }
                UIApplication.shared.open(url)
            })], range: result.range)
        }
        if !attendance.isEmpty {
            let attendanceString = attendance.compactMap({ $0.desc }).joined(separator: "\n")
            var attributedString: ASAttributedString = ASAttributedString(string: "\(attendanceString)", .font(FontUtil.regular(size: 13)), .foreground(ColorUtil.Font.primary), .paragraph(.alignment(.center), .lineBreakMode(.byWordWrapping)))
            if !content.isEmpty {
                attributedString = attributedString + ASAttributedString(string: "\n") + attrString
            }
            _ = memoLabel?.attributed.text = attributedString
            calcHeight(attributedString.value)
        } else {
            _ = memoLabel?.attributed.text = attrString
            calcHeight(attrString.value)
        }
    }

    private func calcHeight(_ attributedText: NSAttributedString) {
        let rect = attributedText.boundingRect(with: CGSize(width: UIScreen.main.bounds.width - 40, height: CGFloat.infinity), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let height = rect.size.height
        cellHeight = height + 100
        logger.debug("计算出的高度: \(cellHeight)")
        // 50
        delegate?.lessonDetailsMemoTableViewCell(heightChanged: cellHeight)
    }
}
