//
//  MaterialsV3HeaderCollectionReusableView.swift
//  TuneKey
//
//  Created by 砚枫张 on 2024/5/9.
//  Copyright © 2024 spelist. All rights reserved.
//

import UIKit

class MaterialsV3HeaderCollectionReusableView: UICollectionReusableView {
    
    @Live var title: NSAttributedString = .init(string: "")
    @Live var isPaddingShow: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MaterialsV3HeaderCollectionReusableView {
    private func initView() {
        ViewBox(top: 10, left: 0, bottom: 10, right: 0) {
            HStack(alignment: .center) {
                View().width(20)
                    .isShow($isPaddingShow)
                Label().textColor(.primary)
                    .font(.cardTitle)
                    .attributedText($title)
                View().width(20)
                    .isShow($isPaddingShow)
            }
        }
        .fill(in: self)
    }
}
