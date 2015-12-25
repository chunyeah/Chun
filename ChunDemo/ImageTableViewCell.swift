//
//  ImageTableViewCell.swift
//  Chun
//
//  Created by Chun Ye on 3/6/15.
//  Copyright (c) 2015 Chun Tips. All rights reserved.
//

import UIKit

class ImageTableViewCell: UITableViewCell {
    
    var testImageView: UIImageView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.testImageView = UIImageView(frame: CGRectZero)
        self.testImageView.contentMode = .ScaleAspectFit
        self.testImageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.testImageView)
        
        let views = ["testImageView": self.testImageView]
        self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[testImageView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[testImageView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
