//
//  ExpandableLabel.swift
//  DMWatchParty
//
//  Created by Dheeraj Kumar Mani on 18/08/23.
//

import UIKit

class ExpandableLabel :UILabel {
    
    override var text: String? {
        didSet {
            if let text = text {
                let buttonAray =  self.superview?.subviews.filter({ (subViewObj) -> Bool in
                    return subViewObj.tag ==  9090
                })
                if text.isEmpty{
                    buttonAray?.forEach({ (button) in
                        button.removeFromSuperview()
                    })
                }else{
                    if buttonAray?.isEmpty ?? false {
                        self.addReadMoreButton()
                    }
                }
            }
        }
    }
    
    var isExpaded = false
    var numoflines = Bool()
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let buttonAray =  self.superview?.subviews.filter({ (subViewObj) -> Bool in
            return subViewObj.tag ==  9090
        })
        
        if buttonAray?.isEmpty == true {
            self.addReadMoreButton()
        }
    }
    
    //Add readmore button in the label.
    func addReadMoreButton() {
        print("addReadMoreButton")
        let theNumberOfLines = numberOfLinesInLabel(yourString: self.text ?? "", labelWidth: self.frame.width, labelHeight: self.frame.height, font: self.font)
        let height = self.frame.height
        self.numberOfLines =  self.isExpaded ? 0 : 3
        
        if theNumberOfLines > 3{
            self.numberOfLines = 3
            numoflines = true
            let button = UIButton(frame: CGRect(x: 0, y: height+15, width: 70, height: 15))
            button.tag = 9090
            button.frame = self.frame
            button.frame.origin.y =  self.frame.origin.y  +  self.frame.size.height + 25
            let viewMoreText = UserDefaults.standard.string(forKey: "view_more") ?? "View More"
            print("viewMoreText: ", viewMoreText)
            button.setTitle(viewMoreText, for: .normal)
            button.titleLabel?.font = UIFont.poppinsRegular(13)
            button.backgroundColor = .clear
            button.setTitleColor(UIColor.buttonColor(), for: .normal)
            button.addTarget(self, action: #selector(ExpandableLabel.buttonTapped(sender:)), for: .touchUpInside)
            self.superview?.addSubview(button)
            self.superview?.bringSubviewToFront(button)
            let viewLessText = UserDefaults.standard.string(forKey: "view_less") ?? "View Less"
            print("viewMoreText: ", viewLessText)
            button.setTitle(viewLessText, for: .selected)
            button.isSelected = self.isExpaded
            button.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                button.bottomAnchor.constraint(equalTo:  self.bottomAnchor, constant: +25)
                ])
        }else{
            self.numberOfLines = 3
            numoflines = false
        }
    }
    
    //Calculating the number of lines. -> Int
    func numberOfLinesInLabel(yourString: String, labelWidth: CGFloat, labelHeight: CGFloat, font: UIFont) -> Int {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = labelHeight
        paragraphStyle.maximumLineHeight = labelHeight
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: AnyObject] = [NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): font, NSAttributedString.Key(rawValue: NSAttributedString.Key.paragraphStyle.rawValue): paragraphStyle]
        
        let constrain = CGSize(width: labelWidth, height: CGFloat(Float.infinity))
        
        let size = yourString.size(withAttributes: attributes)
        
        let stringWidth = size.width
        
        let trimmedString = yourString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("your string here$\(yourString)$")
       
        if trimmedString.contains("\n"){
            
            let firstString = trimmedString.components(separatedBy: .newlines)
            
            var maximumHeight = CGFloat(1.0)
            
            firstString.forEach { currentString in
                
                let dummyLabel = UILabel()
                
                dummyLabel.attributedText = NSMutableAttributedString(string: currentString, attributes: attributes)
                
                dummyLabel.sizeToFit()
                if currentString != ""{
                    maximumHeight = (dummyLabel.frame.height < maximumHeight) ? dummyLabel.frame.height : maximumHeight
                }
            }
            
            let numberOfLines = ceil(Double(size.height/maximumHeight))
            
            
            return Int(numberOfLines)
            
        }
        
          let numberOfLines = ceil(Double(stringWidth/constrain.width))
        
        guard !(numberOfLines.isNaN || numberOfLines.isInfinite) else {
            return 0
        }
        return Int(numberOfLines)
    }
    
    //ReadMore Button Action
    @objc func buttonTapped(sender : UIButton) {
        
        self.isExpaded = !isExpaded
        sender.isSelected =   self.isExpaded
        
        self.numberOfLines =  sender.isSelected ? 0 : 3
        
        self.layoutIfNeeded()
        
        var viewObj :UIView?  = self
        var cellObj :UITableViewCell?
        while viewObj?.superview != nil  {
            
            if let cell = viewObj as? UITableViewCell  {
                
                cellObj = cell
            }
            
            if let tableView = (viewObj as? UITableView)  {
                
                if let indexPath = tableView.indexPath(for: cellObj ?? UITableViewCell()){
                    
                    //tableView.beginUpdates()
                    //print(indexPath)
                    tableView.reloadData()
                    
                }
                return
            }
            
            viewObj = viewObj?.superview
        }
        
        
    }
    
}

