//
//  OSCAMobilityUI.swift
//  OSCAMobilityUI
//
//  Created by Mammut Nithammer on 05.10.22.
//

import OSCAEssentials
import OSCAMobility
import OSCAWeather
import UIKit

public protocol OSCAMobilityUIModuleConfig: OSCAUIModuleConfig {
  var shadowSettings: OSCAShadowSettings { get set }
  var cornerRadius: Double { get set }
  var deeplinkScheme: String { get set }
} // end public protocol OSCAMobilityUIModuleConfig

public struct OSCAMobilityUIDependencies {
  let dataModule: OSCAMobility
  let weatherModule: OSCAWeather
  let moduleConfig: OSCAMobilityUIModuleConfig
  let analyticsModule: OSCAAnalyticsModule?

  public init(dataModule: OSCAMobility,
              weatherModule: OSCAWeather,
              moduleConfig: OSCAMobilityUIModuleConfig,
              analyticsModule: OSCAAnalyticsModule? = nil
  ) {
    self.dataModule = dataModule
    self.moduleConfig = moduleConfig
    self.weatherModule = weatherModule
    self.analyticsModule = analyticsModule
  } // end public init
}

public struct OSCAMobilityUIConfig: OSCAMobilityUIModuleConfig {
  /// module title
  public var title: String?
  public var shadowSettings: OSCAShadowSettings = OSCAShadowSettings(opacity: 0.2,
                                                                     radius: 10,
                                                                     offset: CGSize(width: 0, height: 2))
  public var cornerRadius: Double = 10.0
  public var fontConfig: OSCAFontConfig = OSCAFontSettings()
  public var colorConfig: OSCAColorConfig = OSCAColorSettings()
  /// app deeplink scheme URL part before `://`
  public var deeplinkScheme: String = "solingen"

  public init(title: String? = nil,
              shadowSettings: OSCAShadowSettings = OSCAShadowSettings(opacity: 0.2,
                                                                      radius: 10,
                                                                      offset: CGSize(width: 0, height: 2)),
              cornerRadius: Double = 10.0,
              fontConfig: OSCAFontConfig = OSCAFontSettings(),
              colorConfig: OSCAColorConfig = OSCAColorSettings(),
              deeplinkScheme: String = "solingen"
  ) {
    self.shadowSettings = shadowSettings
    self.cornerRadius = cornerRadius
    self.fontConfig = fontConfig
    self.colorConfig = colorConfig
    self.deeplinkScheme = deeplinkScheme
  }
}

public struct OSCAMobilityUI: OSCAUIModule {
  /// module DI container
  private var moduleDIContainer: OSCAMobilityUIDIContainer!
  public var version: String = "1.0.4"
  public var bundlePrefix: String = "de.osca.mobility.ui"

  public internal(set) static var configuration: OSCAMobilityUIModuleConfig!
  /// module `Bundle`
  ///
  /// **available after module initialization only!!!**
  public internal(set) static var bundle: Bundle!

  /**
   create module and inject module dependencies
   - Parameter mduleDependencies: module dependencies
   */
  public static func create(with moduleDependencies: OSCAMobilityUIDependencies) -> OSCAMobilityUI {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    var module: Self = Self(config: moduleDependencies.moduleConfig)
    module.moduleDIContainer = OSCAMobilityUIDIContainer(dependencies: moduleDependencies)
    return module
  } // end public static func create with module dependencies

  /// public initializer with module configuration
  /// - Parameter config: module configuration
  public init(config: OSCAUIModuleConfig) {
    #if SWIFT_PACKAGE
      Self.bundle = Bundle.module
    #else
      guard let bundle: Bundle = Bundle(identifier: bundlePrefix) else { fatalError("Module bundle not initialized!") }
      Self.bundle = bundle
    #endif
    guard let extendedConfig = config as? OSCAMobilityUIConfig else { fatalError("Config couldn't be initialized!") }
    OSCAMobilityUI.configuration = extendedConfig
  } // end public init
} // end public struct OSCAMobilityUI

// MARK: - public ui module interface

extension OSCAMobilityUI {
  /**
   public module interface `getter`for `OSCAMobilityFlowCoordinator`
   - Parameter router: router needed or the navigation graph
   */
  public func getMobilityFlowCoordinator(router: Router) -> OSCAMobilityFlowCoordinator {
    #if DEBUG
      print("\(String(describing: self)): \(#function)")
    #endif
    let flow = moduleDIContainer.makeMobilityFlowCoordinator(router: router)
    return flow
  } // end public func getMobilityFlowCoordinator

  /// public module interface `getter` for `OSCAMobilityMainViewModel`
  public func getMobilityMainViewModel(actions: OSCAMobilityMainViewModelActions) -> OSCAMobilityMainViewModel {
    let viewModel = moduleDIContainer.makeOSCAMobilityMainViewModel(actions: actions)
    return viewModel
  } // end public func getMobilityMainViewModel
} // end extension OSCAMobilityUI
