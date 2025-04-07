//
//  OSCAMobilityDetailTableViewCell.swift
//  OSCAMobilityUI
//
//  Created by Mammut Nithammer on 05.10.22.
//

import OSCAEssentials
import Combine
import UIKit

public final class OSCAMobilityDetailTableViewCell: UITableViewCell {
  @IBOutlet private var logoImageView: UIImageView!
  @IBOutlet private var nameLabel: UILabel!
  @IBOutlet private var fuelImageView: UIImageView!
  @IBOutlet private var walkDurationLabel: UILabel!
  @IBOutlet private var walkIconImageView: UIImageView!
  
  private var bindings = Set<AnyCancellable>()
  public static let identifier = String(describing: OSCAMobilityDetailTableViewCell.self)
  public var viewModel: OSCAMobilityDetailCellViewModel! {
    didSet {
      self.setupView()
      self.setupBindings()
      self.viewModel.didSetViewModel()
    }
  }
  
  private func setupView() {
    self.backgroundColor = .clear
    
    self.nameLabel.text = self.viewModel.name
    self.nameLabel.font = OSCAMobilityUI.configuration.fontConfig.captionLight
    self.nameLabel.textColor = OSCAMobilityUI.configuration.colorConfig.textColor
    self.nameLabel.numberOfLines = 1
    
    self.walkDurationLabel.text = self.viewModel.walkDuration == 0 ? "-" : "\(self.viewModel.walkDuration)"
    self.walkDurationLabel.font = OSCAMobilityUI.configuration.fontConfig.bodyHeavy
    self.walkDurationLabel.textColor = OSCAMobilityUI.configuration.colorConfig.textColor
    self.walkDurationLabel.numberOfLines = 1
    
    self.walkIconImageView.image = UIImage(systemName: "figure.walk")
    self.walkIconImageView.tintColor = OSCAMobilityUI.configuration.colorConfig.textColor
    
    if self.viewModel.imageDataFromCache != nil {
      self.logoImageView.image = UIImage(data: self.viewModel.imageDataFromCache!)
    }
    self.logoImageView.contentMode = .scaleAspectFit
    
    self.fuelImageView.isHidden = false
    
    switch self.viewModel.fuel {
    case let value where value >= 0.8:
      self.fuelImageView.image = UIImage(systemName: "battery.100")?.withRenderingMode(.alwaysOriginal)
    case let value where value < 0.8 && value >= 0.6:
      self.fuelImageView.image = UIImage(systemName: "battery.75")?.withRenderingMode(.alwaysOriginal)
      self.fuelImageView.tintColor = .systemGreen
    case let value where value < 0.6 && value >= 0.4:
      self.fuelImageView.image = UIImage(systemName: "battery.50")?.withRenderingMode(.alwaysOriginal)
      self.fuelImageView.tintColor = .systemGreen
    case let value where value < 0.4 && value >= 0.2:
      self.fuelImageView.image = UIImage(systemName: "battery.25")?.withRenderingMode(.alwaysOriginal)
      self.fuelImageView.tintColor = .systemOrange
    case let value where value < 0.2 && value >= 0:
      self.fuelImageView.image = UIImage(systemName: "battery.0")?.withRenderingMode(.alwaysOriginal)
      self.fuelImageView.tintColor = .systemRed
    default:
      self.fuelImageView.isHidden = true
    }
  }
  
  private func setupBindings() {
    self.viewModel.$imageData
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] imageData in
        guard let `self` = self,
              let imageData = imageData
        else { return }
        
        self.logoImageView.image = UIImage(data: imageData)
      })
      .store(in: &self.bindings)
  }
  
  override public func prepareForReuse() {
    self.logoImageView.image = nil
    self.fuelImageView.image = nil
  }
}
