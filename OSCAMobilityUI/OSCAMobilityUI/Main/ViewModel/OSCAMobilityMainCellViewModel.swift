//
//  OSCAMobilityMainCellViewModel.swift
//  OSCAMobilityUI
//
//  Created by Mammut Nithammer on 05.10.22.
//

import Combine
import Foundation
import OSCAMobility

public final class OSCAMobilityMainCellViewModel {
  var title: String = ""

  var response: OSCAMobilityResponse
  let dataModule: OSCAMobility
  private let cellRow: Int
  private var bindings = Set<AnyCancellable>()
  let imageDataCache: NSCache<NSString, NSData>
  
  let hasDeeplinks: Bool

  enum Section {
    case publicTransport
    case others
  }

  // MARK: Initializer

  public init(imageCache: NSCache<NSString, NSData>,
              response: OSCAMobilityResponse,
              dataModule: OSCAMobility,
              at row: Int) {
    imageDataCache = imageCache
    self.response = response
    self.dataModule = dataModule
    
    
    self.hasDeeplinks = self.response.availableOptions?.contains {
      $0.deeplinks?.ios != nil && (($0.deeplinks?.ios?.isEmpty) == false)
    } ?? false
    
    cellRow = row

    setupBindings()
  }

  // MARK: - OUTPUT

  @Published private(set) var imageData: Data? = nil

  var imageDataFromCache: Data? {
    guard let id = response.iconURL else { return nil }
    let imageData = imageDataCache.object(forKey: NSString(string: id))
    return imageData as Data?
  }

  // MARK: - Private

  private func setupBindings() {
    switch response.type {
      case .airplane, .bus, .cablecar, .longDistanceTrain, .subway, .train, .tram, .regiotrain:
        title = response.stop?.name ?? ""
      case .escooter:
        title = "E-Roller"
      case .taxi:
        title = "Taxi"
      case .bicycle:
        title = "Fahrrad"
      case .carSharing:
        title = "Carsharing"
      case .none:
        break
    }
  }

  private func fetchImage(from url: String) {
    if let url = URL(string: response.iconURL ?? "") {
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
          if let id = self.response.iconURL {
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

extension OSCAMobilityMainCellViewModel {
  func didSetViewModel() {
    if imageDataFromCache == nil {
      guard let url = response.iconURL,
            let _ = URL(string: url)
      else { return }

      fetchImage(from: url)
    } else {
      imageData = imageData as Data?
    }
  }
}
