//
//  ProfileAboutUsPrivacyPolicyViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/10/9.
//  Copyright © 2019 spelist. All rights reserved.
//

import UIKit

class ProfileAboutUsPrivacyPolicyViewController: TKBaseViewController {


}

extension ProfileAboutUsPrivacyPolicyViewController {
    override func initView() {
        _ = TKLabel.create()
            .text(text: "Privacy policy")
            .addTo(superView: self.view, withConstraints: { (make) in
                make.center.equalToSuperview()
            })
    }
}
