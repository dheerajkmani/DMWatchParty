//
//  UIFont.swift
//  DMWatchParty
//
//  Created by Dheeraj Kumar Mani on 18/08/23.
//

import Foundation
import UIKit

extension UIFont {
  static func poppinsRegular(_ size: CGFloat) -> UIFont {
    return UIFont(name: "Poppins-Regular", size: size)!
  }

  static func poppinsBold(_ size: CGFloat) -> UIFont {
      return UIFont(name: "Poppins-Bold", size: size)!
    }

  static func poppinsLight(_ size: CGFloat) -> UIFont {
    return UIFont(name: "Poppins-Light", size: size)!
  }

  static func poppinsSemiBold(_ size: CGFloat) -> UIFont {
    return UIFont(name: "Poppins-SemiBold", size: size)!
  }

  static func poppinsMedium(_ size: CGFloat) -> UIFont {
    return UIFont(name: "Poppins-Medium", size: size)!
  }
}

