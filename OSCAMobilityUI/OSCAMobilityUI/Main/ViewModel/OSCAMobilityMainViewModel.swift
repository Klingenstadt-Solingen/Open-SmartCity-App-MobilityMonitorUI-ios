//
//  OSCAMobilityMainViewModel.swift
//  OSCAMobilityUI
//
//  Created by Mammut Nithammer on 05.10.22.
//

import Combine
import CoreLocation
import Foundation
import OSCAMobility
import OSCAWeather
import OSCAEssentials

public struct OSCAMobilityMainViewModelActions {
}

public enum OSCAMobilityMainViewModelError: Error, Equatable {
  case mobilityFetch
  case weatherFetch
}

public enum OSCAMobilityMainViewModelState: Equatable {
  case loading
  case finishedLoading
  case error(OSCAMobilityMainViewModelError)
}

public final class OSCAMobilityMainViewModel {
  let dataModule: OSCAMobility
  let weatherModule: OSCAWeather
  private let actions: OSCAMobilityMainViewModelActions?
  private var bindings = Set<AnyCancellable>()
    var defaultLoation: OSCAGeoPoint? { self.dataModule.defaultLocation }
  
  public typealias MobilityResponseMap = [OSCAMobilityRequest.MobilityType : [OSCAMobilityResponse]]
  

  // MARK: Initializer

  public init(dataModule: OSCAMobility,
              weatherModule: OSCAWeather,
              actions: OSCAMobilityMainViewModelActions) {
    self.dataModule = dataModule
    self.weatherModule = weatherModule
    self.actions = actions
  } // end public init

  // MARK: - OUTPUT

  enum Section { case mobility }

  @Published private(set) var state: OSCAMobilityMainViewModelState = .loading
  @Published private(set) var response: MobilityResponseMap = [:]
  @Published private(set) var weather: [OSCAWeatherObserved] = []

  let imageDataCache = NSCache<NSString, NSData>()
    
    public func setLoadingState(_ state: OSCAMobilityMainViewModelState){
        self.state = state
    }
}

extension OSCAMobilityMainViewModel {
  public func fetchMobility(lat: CLLocationDegrees, lon: CLLocationDegrees) {
    OSCAMobilityRequest.MobilityType.allCases.forEach { type in
        fetchMobility(type: type, lat: lat, lon: lon)
    }
  }
  
  public func fetchMobility(type: OSCAMobilityRequest.MobilityType, lat: CLLocationDegrees, lon: CLLocationDegrees) {

    dataModule
      .fetchMobility(type: type, lat: lat, lon: lon, maxDetailItems: 5)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
          self.state = .finishedLoading

        case let .failure(error):
          switch error {
          case let .networkDataLoading(statusCode: statusCode, data: data):
            print(statusCode)
            print("Error: \(String(data: data, encoding: .utf8))")
          case let .networkJSONDecoding(error: err):
            print(err)
          default:
            print(error)
          }
          self.state = .error(.mobilityFetch)
        }
      }, receiveValue: { result in
        self.response[type] = result
      })
      .store(in: &bindings)
  }

  public func fetchWeather(for location: CLLocation) {
    let lat = location.coordinate.latitude
    let lon = location.coordinate.longitude

    weatherModule
      .getWeatherObserved(limit: 1, query: ["where": "{\"geopoint\": {\"$nearSphere\": { \"__type\": \"GeoPoint\", \"latitude\": \(lat), \"longitude\": \(lon) }}}"])
      .sink { completion in
        switch completion {
        case .finished:
          self.state = .finishedLoading
        }
      } receiveValue: { result in
        switch result {
        case let .success(weatherStations):
          self.weather = weatherStations
        case .failure:
          self.state = .error(.weatherFetch)
        }
      }
      .store(in: &bindings)
  }

  func getImageData(from urlString: String) -> AnyPublisher<Data, OSCAMobilityError>? {
    guard let url = URL(string: urlString) else { return nil }

    let pubisher: AnyPublisher<Data, OSCAMobilityError> = dataModule.fetchImageData(url: url)
    return pubisher
  }

  func getImageDataFromCache(with urlString: String) -> Data? {
    let imageData = imageDataCache.object(forKey: NSString(string: urlString))
    return imageData as Data?
  }
}

extension OSCAMobilityMainViewModel {
  func viewDidLoad() {
  }
}

// MARK: - OUTPUT Localized Strings

extension OSCAMobilityMainViewModel {
  var screenTitle: String { return NSLocalizedString(
    "mobility_title",
    bundle: OSCAMobilityUI.bundle,
    comment: "The screen title for press releases") }
  var alertTitleError: String { return NSLocalizedString(
    "alert_title_error",
    bundle: OSCAMobilityUI.bundle,
    comment: "The alert title for an error") }
  var alertActionConfirm: String { return NSLocalizedString(
    "alert_title_confirm",
    bundle: OSCAMobilityUI.bundle,
    comment: "The alert action title to confirm") }
  var searchPlaceholder: String { return NSLocalizedString("search_placeholder", bundle: OSCAMobilityUI.bundle, comment: "Placeholder for searchbar") }
}

extension OSCAMobilityRequest.MobilityType {
  public var referenceIndex: Int? {
    return Self.allCases.firstIndex(of: self)
  }
  
  public static func fromIndex(index: Int) -> Self? {
    let allCases = Self.allCases
    guard index >= 0, index < allCases.count else { return nil }
    return allCases[index]
  }
}

extension Dictionary where Key == OSCAMobilityRequest.MobilityType, Value == [OSCAMobilityResponse] {
  
  public typealias MobilityResponsePair = (key: OSCAMobilityRequest.MobilityType, value: [OSCAMobilityResponse])
  
  func orderedByTypeIndex() -> [MobilityResponsePair] {
      var filtered: [MobilityResponsePair] = []
      
      // Filter out empty responses so that they dont show in the list
      self.forEach { responsePair in
          if let optionsCount = responsePair.value.first?.availableOptions?.count {
              if (optionsCount > 0) {
                  filtered.append(responsePair)
              }
          }
      }
      
    let sortedArray = filtered.sorted(by: {
      guard let firstIndex = $0.key.referenceIndex,
            let secondIndex = $1.key.referenceIndex
      else { return false }
      return firstIndex < secondIndex
    })
     
    return sortedArray
  }
  
  subscript(orderedIndex index: Int) -> MobilityResponsePair? {
    let orderedArray = self.orderedByTypeIndex()
    guard index >= 0, index < orderedArray.count else { return nil }
    return orderedArray[index]
  }
}

