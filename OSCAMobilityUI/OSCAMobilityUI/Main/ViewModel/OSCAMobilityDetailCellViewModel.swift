//
//  OSCAMobilityDetailCellViewModel.swift
//  OSCAMobilityUI
//
//  Created by Mammut Nithammer on 05.10.22.
//

import Combine
import Foundation
import OSCAMobility

public final class OSCAMobilityDetailCellViewModel {
  var name: String = ""
  var fuel: Double = -1
  var walkDuration: Int = 0
  var deeplink: String?

  let availableOption: OSCAMobilityResponse.AvailableOption
  private let dataModule: OSCAMobility
  private let cellRow: Int
  private var bindings = Set<AnyCancellable>()
  let imageDataCache: NSCache<NSString, NSData>

  public init(imageCache: NSCache<NSString, NSData>,
              availableOption: OSCAMobilityResponse.AvailableOption,
              dataModule: OSCAMobility,
              at row: Int) {
    imageDataCache = imageCache
    self.availableOption = availableOption
    self.dataModule = dataModule
    self.deeplink = availableOption.deeplinks?.ios
    cellRow = row

    setupBindings()
  }

  // MARK: - OUTPUT

  @Published private(set) var imageData: Data? = nil

  var imageDataFromCache: Data? {
    guard let id = availableOption.iconURL else { return nil }
    let imageData = imageDataCache.object(forKey: NSString(string: id))
    return imageData as Data?
  }

  private func setupBindings() {
    name = availableOption.name ?? ""
    fuel = availableOption.energyLevel ?? -1
    walkDuration = Int(round((availableOption.distance ?? 0) / 75))
  }

  private func fetchImage(from url: String) {
    if let url = URL(string: availableOption.iconURL ?? "") {
      dataModule.fetchImageData(url: url)
        .sink(receiveCompletion: { completion in
          switch completion {
          case .finished:
            print("\(Self.self): finished \(#function)")

          case let .failure(error):
            print(error)
            print("\(Self.self): .sink: failure \(#function)")
          }
        }, receiveValue: { data in
          if let id = self.availableOption.iconURL {
            self.imageDataCache.setObject(
              NSData(data: data),
              forKey: NSString(string: id))
          }
          self.imageData = data
        })
        .store(in: &bindings)
    }
  }
}

// MARK: - INPUT. View event methods

extension OSCAMobilityDetailCellViewModel {
  func didSetViewModel() {
    if imageDataFromCache == nil {
      guard let url = availableOption.iconURL,
            let _ = URL(string: url)
      else { return }

      fetchImage(from: url)
    } else {
      imageData = imageData as Data?
    }
  }
}
