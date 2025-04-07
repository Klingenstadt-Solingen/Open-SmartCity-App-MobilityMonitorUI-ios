//
//  OSCAMobilityUIDIContainer.swift
//  OSCAMobilityUI
//
//  Created by Mammut Nithammer on 05.10.22.
//

import Foundation
import OSCAEssentials
import OSCAMobility
import OSCANetworkService

/**
 Every isolated module feature will have its own Dependency Injection Container,
 to have one entry point where we can see all dependencies and injections of the module
 */
final class OSCAMobilityUIDIContainer {
  let dependencies: OSCAMobilityUIDependencies

  public init(dependencies: OSCAMobilityUIDependencies) {
    #if DEBUG
      print("\(String(describing: Self.self)): \(#function)")
    #endif
    self.dependencies = dependencies
  } // end init
} // end final class OSCAMobilityUIDIContainer

extension OSCAMobilityUIDIContainer: OSCAMobilityFlowCoordinatorDependencies {
  var deeplinkScheme: String {
    return "solingen"
  }

  // MARK: - Mobility Main

  func makeOSCAMobilityMainViewController(actions: OSCAMobilityMainViewModelActions) -> OSCAMobilityMainViewController {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    let viewModel = makeOSCAMobilityMainViewModel(actions: actions)
    return OSCAMobilityMainViewController.create(with: viewModel)
  } // end makeMobilityViewController

  func makeOSCAMobilityMainViewModel(actions: OSCAMobilityMainViewModelActions) -> OSCAMobilityMainViewModel {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif

    return OSCAMobilityMainViewModel(dataModule: dependencies.dataModule, weatherModule: dependencies.weatherModule, actions: actions)
  } // end func makeMobilityViewModel

  // MARK: - Flow Coordinators

  func makeMobilityFlowCoordinator(router: Router) -> OSCAMobilityFlowCoordinator {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    return OSCAMobilityFlowCoordinator(router: router, dependencies: self)
  } // end func makeMobilityFlowCoordinator
} // end extension class OSCAMobilityUIDIContainer
