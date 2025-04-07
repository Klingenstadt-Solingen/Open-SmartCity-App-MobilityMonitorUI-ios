//
//  OSCAMobilityMainCollectionViewCell.swift
//  OSCAMobilityUI
//
//  Created by Mammut Nithammer on 05.10.22.
//

import Combine
import OSCAEssentials
import OSCAMobility
import UIKit

public final class OSCAMobilityMainCollectionViewCell: UICollectionViewCell, UITableViewDelegate {
  @IBOutlet private var wrapperView: UIView!
  @IBOutlet private var shadowView: UIView!
  @IBOutlet private var imageShadow: UIView!
  @IBOutlet private var imageView: UIImageView!
  @IBOutlet private var titleLabel: UILabel!
  @IBOutlet private var tableView: UITableView!
  @IBOutlet private var upperRightLabel: UILabel!
  
  private var bindings = Set<AnyCancellable>()
  public static let identifier = String(describing: OSCAMobilityMainCollectionViewCell.self)
  public var viewModel: OSCAMobilityMainCellViewModel! {
    didSet {
      self.setupView()
      self.setupBindings()
      self.viewModel.didSetViewModel()
    }
  }
  
  private typealias DataSource = UITableViewDiffableDataSource<OSCAMobilityMainCellViewModel.Section, OSCAMobilityResponse.AvailableOption>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<OSCAMobilityMainCellViewModel.Section, OSCAMobilityResponse.AvailableOption>
  private var dataSource: DataSource!
  
  private func setupView() {
    self.tableView.delegate = self
    self.tableView.backgroundColor = .clear
    self.tableView.allowsSelection = viewModel.hasDeeplinks
    
    self.layer.masksToBounds = false
    
    self.contentView.backgroundColor = .clear
    self.contentView.layer.masksToBounds = false
    
    self.wrapperView.backgroundColor = OSCAMobilityUI.configuration.colorConfig.secondaryBackgroundColor
    self.wrapperView.layer.cornerRadius = OSCAMobilityUI.configuration.cornerRadius
    self.wrapperView.layer.masksToBounds = true
    
    self.shadowView.backgroundColor = .clear
    self.shadowView.addShadow(with: OSCAMobilityUI.configuration.shadowSettings)
    
    self.titleLabel.text = viewModel.title
    self.titleLabel.font = OSCAMobilityUI.configuration.fontConfig.bodyHeavy
    self.titleLabel.textColor = OSCAMobilityUI.configuration.colorConfig.textColor
    self.titleLabel.numberOfLines = 1
    
    if(viewModel.response.type?.isPublicTransport() ?? false){
      self.upperRightLabel.text = String(format: "%.0fm", viewModel.response.stop?.distance ?? "")
      self.upperRightLabel.font = OSCAMobilityUI.configuration.fontConfig.captionHeavy
      self.upperRightLabel.textColor = OSCAMobilityUI.configuration.colorConfig.textColor
      self.upperRightLabel.numberOfLines = 1
    } else {
      self.upperRightLabel.text = ""
    }
    
    if self.viewModel.imageDataFromCache == nil {
      self.imageView.image = UIImage()
      self.imageView.backgroundColor = .systemRed
    } else {
      self.imageView.image = UIImage(data: self.viewModel.imageDataFromCache!)
    }
    
    self.imageShadow.backgroundColor = .clear
    self.imageShadow.addShadow(with: OSCAMobilityUI.configuration.shadowSettings)
    self.imageView.contentMode = .scaleAspectFill
    self.imageView.layer.cornerRadius = OSCAMobilityUI.configuration.cornerRadius
    self.imageView.layer.masksToBounds = true
    
    self.configureDataSource()
    self.updateSections(self.viewModel.response.availableOptions ?? [])
  }
  
  private func setupBindings() {
    self.viewModel.$imageData
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] imageData in
        guard let `self` = self,
              let imageData = imageData
        else { return }
        
        self.imageView.image = UIImage(data: imageData)
      })
      .store(in: &self.bindings)
  }
  
  private func configureDataSource() {
    self.dataSource = DataSource(
      tableView: self.tableView,
      cellProvider: { (tableView, indexPath, item) -> UITableViewCell in
        if item.departureTimePlanned != nil {
          guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OSCAMobilityPTDetailTableViewCell.identifier,
            for: indexPath) as? OSCAMobilityPTDetailTableViewCell
          else { return UITableViewCell() }
          
          cell.viewModel = OSCAMobilityPTDetailCellViewModel(
            availableOption: item,
            at: indexPath.row)
          
          return cell
        } else {
          guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OSCAMobilityDetailTableViewCell.identifier,
            for: indexPath) as? OSCAMobilityDetailTableViewCell
          else { return UITableViewCell() }
          
          cell.viewModel = OSCAMobilityDetailCellViewModel(
            imageCache: self.viewModel.imageDataCache,
            availableOption: item,
            dataModule: self.viewModel.dataModule,
            at: indexPath.row)
          return cell
        }
      })
  }
  
  private func updateSections(_ options: [OSCAMobilityResponse.AvailableOption]) {
    var snapshot = Snapshot()
    var orderedOptions = options
    
    switch self.viewModel.response.type {
    case .airplane, .bus, .cablecar, .longDistanceTrain, .subway, .train, .tram, .regiotrain:
      snapshot.appendSections([.publicTransport])
      orderedOptions = options.sorted(by: {
        guard let first = $0.departureTimeEstimated,
              let second = $1.departureTimeEstimated else { return false }
        return first < second
      })
    default:
      snapshot.appendSections([.others])
    }
    
    snapshot.appendItems(orderedOptions)
    self.dataSource.apply(snapshot, animatingDifferences: true)
  }
  
  override public func prepareForReuse() {
    self.imageView.image = nil
  }
  
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {    
    guard let rawCell = tableView.cellForRow(at: indexPath) else { return }
    let isPublicTransportCell = rawCell.reuseIdentifier == OSCAMobilityPTDetailTableViewCell.identifier
    
    if(!isPublicTransportCell){
      guard let cell = rawCell as? OSCAMobilityDetailTableViewCell else { return }
      
      if let url = URL(string: cell.viewModel.deeplink ?? ""), UIApplication.shared.canOpenURL(url) {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }
      tableView.deselectRow(at: indexPath, animated: true)
    }
}
