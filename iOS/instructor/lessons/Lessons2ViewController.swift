//
//  Lessons2ViewController.swift
//  TuneKey
//
//  Created by zyf on 2020/12/30.
//  Copyright © 2020 spelist. All rights reserved.
//
import EventKit
import FirebaseFirestore
import FirebaseFunctions
import FSCalendar
import NVActivityIndicatorView
import PromiseKit
import SwiftDate
import SwiftEventBus
import UIKit

class Lessons2ViewController: TKBaseViewController {
    // MARK: - data
    private var eventStore = EKEventStore()
    
    // MARK: - views
    private var emptyImageView: TKImageView = TKImageView(image: UIImage(named: "lesson_empty"))
    private var emptyLabel: TKLabel = TKLabel.create()
        .text(text: "Add your lessons in minutes.\n It's easy, we promise!")
        .textColor(color: ColorUtil.Font.primary)
        .setNumberOfLines(number: 0)
        .font(font: FontUtil.bold(size: 16))
        .alignment(alignment: .center)
        .changeLabelRowSpace(lineSpace: 0.8, wordSpace: 0.89)
    
    private lazy var emptyView: UIView = {
        let view = UIView()
        return view
    }()
    
}
