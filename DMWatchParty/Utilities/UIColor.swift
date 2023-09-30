//
//  UIColor.swift
//  DMWatchParty
//
//  Created by Dheeraj Kumar Mani on 18/08/23.
//

import UIKit
import Foundation

extension UIColor {
  class func bottomColor() -> UIColor{
      return UIColor.init(hex: "#0D0D0D", alpha: 1)
  }

  class func buttonColor() -> UIColor{
      return UIColor.init(hex: "#118BA6", alpha: 1)
  }

  class func textColor() -> UIColor{
      return UIColor.init(hex: "#D4D4EB", alpha: 1)
  }

  class func placeholderColor() -> UIColor{
      return UIColor.init(hex: "#212431", alpha: 1)
  }

  class func headerColor() -> UIColor{
      return UIColor.init(hex: "#1A1C26", alpha: 1)
  }
  class func backgroundColor() -> UIColor{
      return UIColor.init(hex: "#1A1C26", alpha: 1)
  }

  class func descriptionTextColor() -> UIColor{
      return UIColor.init(hex: "#7B8794", alpha: 1)
  }




  convenience init(hex: String, alpha: CGFloat = 1.0) {
      var sanitizedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
      sanitizedHex = sanitizedHex.replacingOccurrences(of: "#", with: "")
      var rgb: UInt64 = 0
      Scanner(string: sanitizedHex).scanHexInt64(&rgb)

      let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
      let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
      let blue = CGFloat(rgb & 0x0000FF) / 255.0

      self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}

