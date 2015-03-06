//
//  ViewController.swift
//  ChunDemo
//
//  Created by Chun Ye on 3/6/15.
//  Copyright (c) 2015 Chun Tips. All rights reserved.
//

import UIKit
import Chun

class ViewController: UIViewController {

    private var tableView: UITableView!
    private let exampleData: [String] = ["http://f0.topit.me/0/b9/b9/1181382070975b9b90m.jpg", "http://f1.topit.me/1/45/3d/11586062669043d451m.jpg", "http://fb.topit.me/b/c3/37/115313637314637c3bm.jpg", "http://f1.topit.me/1/96/18/114642187970f18961m.jpg", "http://f0.topit.me/0/de/6b/11477141107ce6bde0m.jpg", "http://f11.topit.me/m/200912/16/12609717687530.jpg", "http://ff.topit.me/f/c4/50/11308588056e550c4fm.jpg", "http://i11.topit.me/m/201010/15/12871363744270.jpg", "http://f11.topit.me/m/201012/08/12918172069789.jpg", "http://i11.topit.me/m/201011/01/12886163338383.jpg", "http://f11.topit.me/m/201002/02/12650420481465.jpg", "http://i11.topit.me/m/201002/28/12673520814629.jpg", "http://f11.topit.me/m/201006/06/12758189507406.jpg", "http://f11.topit.me/m/201103/13/12999820639166.jpg", "http://f0.topit.me/0/b9/b9/1181382070975b9b90m.jpg", "http://f1.topit.me/1/45/3d/11586062669043d451m.jpg", "http://fb.topit.me/b/c3/37/115313637314637c3bm.jpg", "http://f1.topit.me/1/96/18/114642187970f18961m.jpg", "http://f0.topit.me/0/de/6b/11477141107ce6bde0m.jpg", "http://f11.topit.me/m/200912/16/12609717687530.jpg", "http://ff.topit.me/f/c4/50/11308588056e550c4fm.jpg", "http://i11.topit.me/m/201010/15/12871363744270.jpg", "http://f11.topit.me/m/201012/08/12918172069789.jpg", "http://i11.topit.me/m/201011/01/12886163338383.jpg", "http://f11.topit.me/m/201002/02/12650420481465.jpg", "http://i11.topit.me/m/201002/28/12673520814629.jpg", "http://f11.topit.me/m/201006/06/12758189507406.jpg", "http://f11.topit.me/m/201103/13/12999820639166.jpg", "http://f0.topit.me/0/b9/b9/1181382070975b9b90m.jpg", "http://f1.topit.me/1/45/3d/11586062669043d451m.jpg", "http://fb.topit.me/b/c3/37/115313637314637c3bm.jpg", "http://f1.topit.me/1/96/18/114642187970f18961m.jpg", "http://f0.topit.me/0/de/6b/11477141107ce6bde0m.jpg", "http://f11.topit.me/m/200912/16/12609717687530.jpg", "http://ff.topit.me/f/c4/50/11308588056e550c4fm.jpg", "http://i11.topit.me/m/201010/15/12871363744270.jpg", "http://f11.topit.me/m/201012/08/12918172069789.jpg", "http://i11.topit.me/m/201011/01/12886163338383.jpg", "http://f11.topit.me/m/201002/02/12650420481465.jpg", "http://i11.topit.me/m/201002/28/12673520814629.jpg", "http://f11.topit.me/m/201006/06/12758189507406.jpg", "http://f11.topit.me/m/201103/13/12999820639166.jpg", "http://f0.topit.me/0/b9/b9/1181382070975b9b90m.jpg", "http://f1.topit.me/1/45/3d/11586062669043d451m.jpg", "http://fb.topit.me/b/c3/37/115313637314637c3bm.jpg", "http://f1.topit.me/1/96/18/114642187970f18961m.jpg", "http://f0.topit.me/0/de/6b/11477141107ce6bde0m.jpg", "http://f11.topit.me/m/200912/16/12609717687530.jpg", "http://ff.topit.me/f/c4/50/11308588056e550c4fm.jpg", "http://i11.topit.me/m/201010/15/12871363744270.jpg", "http://f11.topit.me/m/201012/08/12918172069789.jpg", "http://i11.topit.me/m/201011/01/12886163338383.jpg", "http://f11.topit.me/m/201002/02/12650420481465.jpg", "http://i11.topit.me/m/201002/28/12673520814629.jpg", "http://f11.topit.me/m/201006/06/12758189507406.jpg", "http://f11.topit.me/m/201103/13/12999820639166.jpg"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func loadTableView() {
            self.tableView = UITableView(frame: CGRectZero, style: .Plain)
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.tableView.registerClass(ImageTableViewCell.classForCoder(), forCellReuseIdentifier: "ImageTableViewCell")
            self.view.addSubview(self.tableView)
            
            let views = ["tableView": self.tableView]
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[tableView]-0-|", options: NSLayoutFormatOptions(0), metrics: nil, views: views))
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[tableView]-0-|", options: NSLayoutFormatOptions(0), metrics: nil, views: views))
        }
        
        loadTableView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.exampleData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCellWithIdentifier("ImageTableViewCell") as! ImageTableViewCell
        let imageURLString = self.exampleData[indexPath.row]
        let imageURL = NSURL(string: imageURLString)!
        tableViewCell.testImageView.setImageWithURL(imageURL, placeholderImage: UIImage(named: "default"))
        return tableViewCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 90.0
    }
}

