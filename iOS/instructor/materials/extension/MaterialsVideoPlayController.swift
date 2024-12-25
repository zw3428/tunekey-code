//
//  MaterialsVideoPlayController.swift
//  TuneKey
//
//  Created by WHT on 2020/9/18.
//  Copyright © 2020 spelist. All rights reserved.
//

import AVFoundation
import AVKit
import UIKit

class MaterialsVideoPlayController: TKBaseViewController {
    var materialsData: TKMaterial!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let videoURL = URL(string: materialsData.url)
            let player = AVPlayer(url: videoURL!)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = view.bounds
            view.layer.addSublayer(playerLayer)
            player.play()
    }
}

// MARK: - View

extension MaterialsVideoPlayController {
    override func initView() {
    
    
    }
}

// MARK: - Data

extension MaterialsVideoPlayController {
    override func initData() {
    }
}
