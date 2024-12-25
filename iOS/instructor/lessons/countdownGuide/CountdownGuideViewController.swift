//
//  CountdownGuideViewController.swift
//  TuneKey
//
//  Created by zyf on 2021/4/12.
//  Copyright © 2021 spelist. All rights reserved.
//

import UIKit

extension UIImageView {
    static func fromGif(frame: CGRect, resourceName: String) -> UIImageView? {
        guard let path = Bundle.main.path(forResource: resourceName, ofType: "gif") else {
            print("Gif does not exist at that path")
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(gifData as CFData, nil) else { return nil }
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
        let gifImageView = UIImageView(frame: frame)
        gifImageView.animationImages = images
        return gifImageView
    }
}

class CountdownGuideViewController: TKBaseViewController {
    lazy var imageView = UIImageView()
}

extension CountdownGuideViewController {
    override func initView() {
        super.initView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        guard let path = Bundle.main.path(forResource: "Tap", ofType: "gif") else { return }
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { return }
        let image = UIImage.sd_image(withGIFData: data)
        imageView.addTo(superView: view, withConstraints: { make in
            make.bottom.equalToSuperview().offset(-10 - tabBarHeight)
            make.right.equalTo(-20)
            make.size.equalTo(60)
        })
        imageView.image = image
        imageView.startAnimating()
        imageView.animationDuration = 2
        imageView.animationRepeatCount = 999999999
        
        TKLabel.create()
            .font(font: FontUtil.medium(size: 30))
            .text(text: "Tap to xxxxxxxxx")
            .textColor(color: .white)
            .alignment(alignment: .center)
            .addTo(superView: view) { (make) in
                make.bottom.equalTo(imageView.snp.top).offset(-40)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
            }
    }

    override func bindEvent() {
        super.bindEvent()
        view.onViewTapped { [weak self] _ in
            self?.dismiss(animated: false, completion: nil)
        }
    }
}
