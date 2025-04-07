//
//  OSCAMobilityPTDetailTableViewCell.swift
//  OSCAMobilityUI
//
//  Created by Mammut Nithammer on 05.10.22.
//

import OSCAEssentials
import Combine
import UIKit

public final class OSCAMobilityPTDetailTableViewCell: UITableViewCell {
  @IBOutlet private var lineNumberLabel: UILabel!
  @IBOutlet private var colorView: UIView!
  @IBOutlet private var lineDirectionLabel: UILabel!
  
  @IBOutlet private var departureLabel: UILabel!
  
  @IBOutlet private var upperRightLabel: UILabel!

  public static let identifier = String(describing: OSCAMobilityPTDetailTableViewCell.self)
  public var viewModel: OSCAMobilityPTDetailCellViewModel! {
    didSet {
      self.setupView()
    }
  }

  private func setupView() {
    self.backgroundColor = .clear
    
    self.colorView.addLimitedCornerRadius(OSCAMobilityUI.configuration.cornerRadius)
    self.colorView.backgroundColor = UIColor(hex: "#\(self.viewModel.availableOption.color ?? "000000")") ?? OSCAMobilityUI.configuration.colorConfig.grayColor

    self.lineDirectionLabel.text = self.viewModel.direction
    self.lineDirectionLabel.font = OSCAMobilityUI.configuration.fontConfig.captionLight
    self.lineDirectionLabel.textColor = OSCAMobilityUI.configuration.colorConfig.textColor
    self.lineDirectionLabel.numberOfLines = 1

    self.lineNumberLabel.text = self.viewModel.lineNumber
    self.lineNumberLabel.font = OSCAMobilityUI.configuration.fontConfig.captionHeavy
    if let color = colorView.backgroundColor {
      self.lineNumberLabel.textColor = color.isDarkColor
        ? OSCAMobilityUI.configuration.colorConfig.whiteDark
        : OSCAMobilityUI.configuration.colorConfig.blackColor
    } else {
      self.lineNumberLabel.textColor = OSCAMobilityUI.configuration.colorConfig.whiteDark
    }
    self.lineNumberLabel.numberOfLines = 1

    setDepartureLabel(minsUntilDeparture: viewModel.minsUntilDeparture)

    self.upperRightLabel.text = ""
    self.upperRightLabel.font = OSCAMobilityUI.configuration.fontConfig.captionHeavy
    self.upperRightLabel.textColor = .black
    self.upperRightLabel.numberOfLines = 1
    //self.upperRightLabel.isHidden = !(self.viewModel.availableOption.delayed ?? false)
  }
  
  private func setDepartureLabel(minsUntilDeparture: Int) {
    var leftLabelText = ""
    var middleText = ""
    var rightLabelText = ""

    switch(minsUntilDeparture){
      case let mins where mins == 0:
        middleText = "Jetzt"
      case let mins where mins < 0:
        leftLabelText = "vor"
        middleText = " \(abs(minsUntilDeparture)) "
        rightLabelText = "Min."
      case let mins where mins > 15:
        middleText = self.viewModel.departureTime
      default:
        leftLabelText = "in"
        middleText = " \(minsUntilDeparture) "
        rightLabelText = "Min."
    }
    
    self.departureLabel.font = OSCAMobilityUI.configuration.fontConfig.bodyLight
    let attributedString = NSMutableAttributedString(string: leftLabelText + middleText + rightLabelText)
    
    
    attributedString.addAttribute(NSAttributedString.Key.font,
                                  value: OSCAMobilityUI.configuration.fontConfig.bodyHeavy,
                                  range: NSRange(location: leftLabelText.count, length: middleText.count))
    
    self.departureLabel.attributedText = attributedString
    
    self.departureLabel.textColor = OSCAMobilityUI.configuration.colorConfig.textColor
    self.departureLabel.numberOfLines = 1
  }
}
