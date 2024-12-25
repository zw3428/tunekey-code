//
//  TKAVPlayerViewController.swift
//  TuneKey
//
//  Created by zyf on 2022/10/6.
//  Copyright © 2022 spelist. All rights reserved.
//

import BMPlayer
import UIKit
extension TKAVPlayerViewController {
    struct Resource {
        var url: URL
        var name: String = ""
        var cover: URL
    }
}
class TKAVPlayerViewController: TKBaseViewController {
    let player = BMPlayer()

    var resource: Resource
    init(_ resource: Resource) {
        self.resource = resource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player.pause()
    }
}

extension TKAVPlayerViewController {
    override func initView() {
        super.initView()
        player.addTo(superView: view) { make in
            make.edges.equalToSuperview()
//            make.top.equalTo(self.view).offset(20)
//            make.left.right.equalTo(self.view)
//            make.height.equalTo(player.snp.width).multipliedBy(9.0 / 16.0).priority(750)
        }
        player.setVideo(resource: BMPlayerResource(url: resource.url, name: resource.name, cover: resource.cover, subtitle: nil))
        player.backBlock = { [weak self] isBack in
            logger.debug("isBack: \(isBack)")
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
    }
}
