//
//  OSCAMobilityMainViewController.swift
//  OSCAMobilityUI
//
//  Created by Mammut Nithammer on 05.10.22.
//

import Combine
import CoreLocation
import MapKit
import OSCAEssentials
import OSCAMapUI
import OSCAMobility
import OSCAWeather
import UIKit

public class OSCAMobilityMainViewController: UIViewController, Alertable {
  @IBOutlet private var collectionView: UICollectionView!
  @IBOutlet private var mapView: MKMapView!
  
  public lazy var activityIndicationView = ActivityIndicatorView(style: .large)
  
  private typealias DataSource = UICollectionViewDiffableDataSource<OSCAMobilityRequest.MobilityType, OSCAMobilityResponse>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<OSCAMobilityRequest.MobilityType, OSCAMobilityResponse>
  private var viewModel: OSCAMobilityMainViewModel!
  private var bindings = Set<AnyCancellable>()
  private var userLocation: CLLocation?
  private var timer: DispatchSourceTimer?
  private var refreshTiming: Int = 60
  
  private var dataSource: DataSource!
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    self.setupViews()
    self.setupBindings()
    self.viewModel.viewDidLoad()
    
    let queue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".timer")
    timer = DispatchSource.makeTimerSource(queue: queue)
      timer!.schedule(deadline: .now(), repeating: .seconds(self.refreshTiming))
    timer!.setEventHandler { [weak self] in
        if((self?.userLocation) != nil){
            self?.viewModel.fetchMobility(lat: self!.userLocation!.coordinate.latitude , lon: self!.userLocation!.coordinate.longitude)
            self?.viewModel.fetchWeather(for: self!.userLocation!)
        }
    }
    timer!.resume()
  }
      
  override public func viewDidDisappear(_ animated: Bool) {
      self.timer?.cancel()
      self.timer = nil
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.setup(
      largeTitles: true,
      tintColor: OSCAMobilityUI.configuration.colorConfig.navigationTintColor,
      titleTextColor: OSCAMobilityUI.configuration.colorConfig.navigationTitleTextColor,
      barColor: OSCAMobilityUI.configuration.colorConfig.navigationBarColor)
    
    // Solingen Hauptbahnhof
//    viewModel.fetchMobility(lat: 51.161300933868745, lon: 7.00264613279818)
      self.viewModel.setLoadingState(.loading)
      self.userLocation = {
          if let location = CLLocationManager().location {
              return location
          } else if let location = self.viewModel.defaultLoation{
              return CLLocation(latitude: location.latitude, longitude: location.longitude)
          }
          return CLLocation(latitude: 0.0, longitude: 0.0)
      }()
      
      self.setMapRegion(location: self.userLocation!)
      self.viewModel.fetchMobility(lat: self.userLocation!.coordinate.latitude, lon: self.userLocation!.coordinate.longitude)
      self.viewModel.fetchWeather(for: self.userLocation!)
      
  }

  private func setupViews() {
    self.navigationItem.title = self.viewModel.screenTitle
    
    self.view.backgroundColor = OSCAMobilityUI.configuration.colorConfig.backgroundColor
    self.view.addSubview(self.activityIndicationView)
    self.activityIndicationView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      self.activityIndicationView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
      self.activityIndicationView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
      self.activityIndicationView.heightAnchor.constraint(equalToConstant: 100.0),
      self.activityIndicationView.widthAnchor.constraint(equalToConstant: 100.0),
    ])
    
    self.mapView.layer.cornerRadius = OSCAMobilityUI.configuration.cornerRadius
    self.mapView.clipsToBounds = true
    
    self.collectionView.delegate = self
    self.collectionView.backgroundColor = .clear
    
    self.setupCollectionView()
    self.setupMapView()
    
  }

  private func setupBindings() {
    self.viewModel.$response
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] response in
        guard let `self` = self else { return }
        self.configureDataSource()
        
        let allValues = response.flatMap { $0.value }
        self.updateSections(response)
        self.addPOIsToMapView(allValues)
      })
      .store(in: &self.bindings)

    self.viewModel.$weather
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink { [weak self] stations in
        guard let `self` = self else { return }
        self.setWeather(station: stations.first)
      }
      .store(in: &self.bindings)

    let stateValueHandler: (OSCAMobilityMainViewModelState) -> Void = { [weak self] state in
      guard let `self` = self else { return }

      switch state {
      case .loading:
        self.startLoading()

      case .finishedLoading:
        self.finishLoading()

      case let .error(error):
        self.finishLoading()
        self.showAlert(
          title: self.viewModel.alertTitleError,
          error: error,
          actionTitle: self.viewModel.alertActionConfirm)
      }
    }

    self.viewModel.$state
      .receive(on: RunLoop.main)
      .sink(receiveValue: stateValueHandler)
      .store(in: &self.bindings)
  }

  private func setupCollectionView() {
    self.collectionView.collectionViewLayout = UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
      
      let sectionResponse = self.viewModel.response[orderedIndex: sectionIndex]
      let countSectionItems = sectionResponse?.value.first?.availableOptions?.count ?? 0
      let estimatedHeight = (CGFloat(countSectionItems) * 44) + 100
      
      let size = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1),
        heightDimension: .estimated(estimatedHeight))
      let item = NSCollectionLayoutItem(layoutSize: size)
      let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)
      
      let section = NSCollectionLayoutSection(group: group)
      section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 0)
      section.interGroupSpacing = 8

      return section
    }
  }

  private func setWeather(station: OSCAWeatherObserved?) {
    guard let station = station,
          let rain = station.valueArray?.weatherValues
      .first(where: { $0.type == .precipitation })?.value,
          let temperature = station.valueArray?.weatherValues
      .first(where: { $0.type == .temperature })?.value
    else { return }

    let weatherIconButton = UIBarButtonItem(
      image: UIImage(systemName: rain < 0.3 ? "sun.max" : "cloud.rain"),
      style: .plain,
      target: nil,
      action: nil)
    weatherIconButton.tintColor = OSCAMobilityUI.configuration.colorConfig.navigationTitleTextColor
    weatherIconButton.imageInsets = UIEdgeInsets(top: 0.0, left: 30.0, bottom: 0, right: 0)
    
    let temperatureButton = UIBarButtonItem(
      title: "\(temperature)°C",
      style: .plain,
      target: nil,
      action: nil)
    temperatureButton.tintColor = OSCAMobilityUI.configuration.colorConfig.navigationTitleTextColor
    
    self.navigationItem.rightBarButtonItems = [temperatureButton, weatherIconButton]
  }

  private func createLayout() -> UICollectionViewLayout {
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .absolute(319))
    
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(45))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(top: 32, leading: 0, bottom: 0, trailing: 0)
    section.interGroupSpacing = 16

    return UICollectionViewCompositionalLayout(section: section)
  }

  private func startLoading() {
    self.collectionView.isUserInteractionEnabled = false

    self.activityIndicationView.isHidden = false
    self.activityIndicationView.startAnimating()
  }

  private func finishLoading() {
    self.collectionView.isUserInteractionEnabled = true
    self.activityIndicationView.stopAnimating()
  }

  private func updateSections(_ response: OSCAMobilityMainViewModel.MobilityResponseMap) {
    let orderedResponse = response.orderedByTypeIndex()

    var snapshot = Snapshot()
    orderedResponse.forEach { response in
      snapshot.appendSections([response.key])
      snapshot.appendItems(response.value)
    }
    
    self.dataSource.apply(snapshot, animatingDifferences: true)
  }

  private func setMapRegion(location: CLLocation) {
    /// set map's region
    let centerCoordinates = location.coordinate
    let span = CLLocationDistance(1000)
    let region = MKCoordinateRegion(center: centerCoordinates,
                                    latitudinalMeters: span,
                                    longitudinalMeters: span)
    self.mapView.setRegion(region,
                           animated: true)
  }

  private func setupMapView() {
    self.mapView.showsUserLocation = true
    self.mapView.delegate = self
    self.mapView.showsUserLocation = true
    self.mapView.register(
      OSCAPoiAnnotationMarkerView.self,
      forAnnotationViewWithReuseIdentifier: OSCAMobilityMainViewController.AnnotationViewReuseIdentifiers.poiAnnotationMarker
        .rawValue
    )
  }

  private func removeAllPOIs() {
    let allAnnotations = mapView.annotations
    self.mapView.removeAnnotations(allAnnotations)
  }

  private func addPOIsToMapView(_ items: [OSCAMobilityResponse]) {
    var annotations: [OSCAPoiAnnotation] = []
    
    for item in items {
      guard let options = item.availableOptions else { return }

      for option in options {
        guard let lat = option.location?.lat,
              let lon = option.location?.lon else { return }

        let coordinates = CLLocationCoordinate2D(latitude: lat,
                                                 longitude: lon)
        let imageUrl = item.symbolURL ?? option.symbolUrl ?? ""
        let annotation = OSCAPoiAnnotation(
          title: "",
          coordinate: coordinates,
          poiObjectId: option.id ?? UUID().uuidString,
          imageUrl: imageUrl,
          uiSettings: nil)

        annotations.append(annotation)
      }
    }
    self.mapView.addAnnotations(annotations)
  }
}

public extension OSCAMobilityMainViewController {
  enum AnnotationViewReuseIdentifiers: String, CaseIterable {
    /// poi annotation without customized symbol image
    case poiAnnotationMarker = "OSCAMobilityUI.OSCAPoiAnnotationMarkerView"
    /// poi annotation with customized symbol image
    case poiAnnotation = "OSCAMobilityUI.OSCAPoiAnnotationView"
  }
}

extension OSCAMobilityMainViewController {
  private func configureDataSource() {
    self.dataSource = DataSource(
      collectionView: self.collectionView,
      cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell in
        guard let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: OSCAMobilityMainCollectionViewCell.identifier,
          for: indexPath) as? OSCAMobilityMainCollectionViewCell
        else { return UICollectionViewCell() }
      
        cell.viewModel = OSCAMobilityMainCellViewModel(
          imageCache: self.viewModel.imageDataCache,
          response: item,
          dataModule: self.viewModel.dataModule,
          at: indexPath.row)
        
        return cell
      })
  }
}

extension OSCAMobilityMainViewController: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
  }
}

// MARK: - instantiate view conroller

extension OSCAMobilityMainViewController: StoryboardInstantiable {
  /// function call: var vc = OSCAPressReleaseMainViewController.create(viewModel)
  public static func create(with viewModel: OSCAMobilityMainViewModel) -> OSCAMobilityMainViewController {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    let vc: Self = Self.instantiateViewController(OSCAMobilityUI.bundle)
    vc.viewModel = viewModel
    return vc
  }
}

extension OSCAMobilityMainViewController: MKMapViewDelegate {
  public func mapView(_: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard annotation is OSCAPoiAnnotation else { return nil }
    guard let oscaAnnotation = annotation as? OSCAPoiAnnotation else { return nil }

    let annotationView = MKAnnotationView(annotation: oscaAnnotation, reuseIdentifier: "Annotation")
    annotationView.annotation = oscaAnnotation
    annotationView.canShowCallout = false

    if let imageUrl = oscaAnnotation.imageUrl {
      if let imageData = self.viewModel.getImageDataFromCache(with: imageUrl) {
        annotationView.image = UIImage(data: imageData)
      } else {
        let publisher: AnyPublisher<Data, OSCAMobilityError>? = self.viewModel.getImageData(from: imageUrl)
        publisher?.receive(on: RunLoop.main)
          .sink { completion in
            switch completion {
            case .finished:
              print("\(Self.self): finished \(#function)")
            case let .failure(error):
              print(error)
              print("\(Self.self): .sink: failure \(#function)")
            }
          } receiveValue: { imageData in
            self.viewModel.imageDataCache.setObject(
              NSData(data: imageData),
              forKey: NSString(string: oscaAnnotation.imageUrl!)
            )

            annotationView.image = UIImage(data: imageData)
          }
          .store(in: &self.bindings)
      }
    } else {
    }

    return annotationView
  }
    
    public func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        setMapRegion(location: CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude) )
    }
}
