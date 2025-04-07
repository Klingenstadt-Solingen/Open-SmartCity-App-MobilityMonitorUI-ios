//
//  OSCAMobilityUITests.swift
//  OSCAMobilityUITests
//
//  Created by Mammut Nithammer on 05.10.22.
//  Reviewed by Stephan Breidenbach on 22.02.23
//

#if canImport(XCTest) && canImport(OSCATestCaseExtension)
import OSCAEssentials
import OSCAMobility
import OSCAWeather
@testable import OSCAMobilityUI
import OSCANetworkService
import OSCATestCaseExtension
import XCTest

final class OSCAMobilityUITests: XCTestCase {
  static let moduleVersion = "1.0.4"
  override func setUpWithError() throws {
    try super.setUpWithError()
  } // end override fun setUp
  
  func testModuleInit() throws {
    let uiModule = try makeDevUIModule()
    XCTAssertNotNil(uiModule)
    XCTAssertEqual(uiModule.version, OSCAMobilityUITests.moduleVersion)
    XCTAssertEqual(uiModule.bundlePrefix, "de.osca.mobility.ui")
    let bundle = OSCAMobilityUI.bundle
    XCTAssertNotNil(bundle)
    let uiBundle = OSCAMobilityUI.bundle
    XCTAssertNotNil(uiBundle)
    let configuration = OSCAMobilityUI.configuration
    XCTAssertNotNil(configuration)
    XCTAssertNotNil(devPlistDict)
    XCTAssertNotNil(productionPlistDict)
  } // end func testModuleInit
  
  func testContactUIConfiguration() throws {
    _ = try makeDevUIModule()
    let uiModuleConfig = try makeUIModuleConfig()
    XCTAssertEqual(OSCAMobilityUI.configuration.title, uiModuleConfig.title)
    XCTAssertEqual(OSCAMobilityUI.configuration.colorConfig.accentColor, uiModuleConfig.colorConfig.accentColor)
    XCTAssertEqual(OSCAMobilityUI.configuration.fontConfig.bodyHeavy, uiModuleConfig.fontConfig.bodyHeavy)
  } // end func testEventsUIConfiguration
} // end finla Class OSCATemplateTests

// MARK: - factory methods

extension OSCAMobilityUITests {
  func makeDevWeatherModuleDependencies() throws -> OSCAWeatherDependencies {
    let networkService = try makeDevNetworkService()
    let userDefaults = try makeUserDefaults(domainString: "de.osca.mobility.ui")
    let dependencies = OSCAWeatherDependencies(networkService: networkService,
                                               userDefaults: userDefaults)
    return dependencies
  }// end func makeDevWeatherModuleDependencies
  
  func makeWeatherModuleDependencies() throws -> OSCAWeatherDependencies {
    let networkService = try makeProductionNetworkService()
    let userDefaults = try makeUserDefaults(domainString: "de.osca.mobility.ui")
    let dependencies = OSCAWeatherDependencies(networkService: networkService,
                                               userDefaults: userDefaults)
    return dependencies
  }// end func makeWeatherModuleDependencies
  
  func makeDevWeatherModule() throws -> OSCAWeather {
    let devDependencies = try makeDevWeatherModuleDependencies()
    let module = OSCAWeather.create(with: devDependencies)
    return module
  }// end func makeDevWeatherModule
  
  func makeWeatherModule() throws -> OSCAWeather {
    let dependencies = try makeWeatherModuleDependencies()
    let module = OSCAWeather.create(with: dependencies)
    return module
  }// end func makeWeatherModule
  
  func makeDevModuleDependencies() throws -> OSCAMobility.Dependencies {
    let networkService = try makeDevNetworkService()
    let userDefaults = try makeUserDefaults(domainString: "de.osca.mobility.ui")
    let dependencies = OSCAMobility.Dependencies(
      networkService: networkService,
      userDefaults: userDefaults
    )
    return dependencies
  } // end public func makeDevModuleDependencies
  
  func makeDevModule() throws -> OSCAMobility {
    let devDependencies = try makeDevModuleDependencies()
    // initialize module
    let module = OSCAMobility.create(with: devDependencies)
    return module
  } // end public func makeDevModule
  
  func makeProductionModuleDependencies() throws -> OSCAMobility.Dependencies {
    let networkService = try makeProductionNetworkService()
    let userDefaults = try makeUserDefaults(domainString: "de.osca.mobility.ui")
    let dependencies = OSCAMobility.Dependencies(
      networkService: networkService,
      userDefaults: userDefaults
    )
    return dependencies
  } // end public func makeProductionModuleDependencies
  
  func makeProductionModule() throws -> OSCAMobility {
    let productionDependencies = try makeProductionModuleDependencies()
    // initialize module
    let module = OSCAMobility.create(with: productionDependencies)
    return module
  } // end public func makeProductionModule
  
  func makeUIModuleConfig() throws -> OSCAMobilityUIConfig {
    OSCAMobilityUIConfig(
      title: "OSCAMobilityUI"
    )
  } // end public func makeUIModuleConfig
  
  func makeDevUIModuleDependencies() throws -> OSCAMobilityUIDependencies {
    let weatherModule = try makeDevWeatherModule()
    let module = try makeDevModule()
    let uiConfig = try makeUIModuleConfig()
    let devDependencies = OSCAMobilityUIDependencies(dataModule: module,
                                                     weatherModule: weatherModule,
                                                     moduleConfig: uiConfig)
    return devDependencies
  } // end public func makeDevUIModuleDependencies
  
  func makeDevUIModule() throws -> OSCAMobilityUI {
    let devDependencies = try makeDevUIModuleDependencies()
    // init ui module
    let uiModule = OSCAMobilityUI.create(with: devDependencies)
    return uiModule
  } // end public func makeUIModule
  
  func makeProductionUIModuleDependencies() throws -> OSCAMobilityUIDependencies {
    let weatherModule = try makeWeatherModule()
    let module = try makeProductionModule()
    let uiConfig = try makeUIModuleConfig()
    let dependencies = OSCAMobilityUIDependencies(dataModule: module,
                                                  weatherModule: weatherModule,
                                                  moduleConfig: uiConfig)
    return dependencies
  } // end public func makeProductionUIModuleDependencies
  
  func makeProductionUIModule() throws -> OSCAMobilityUI {
    let productionDependencies = try makeProductionUIModuleDependencies()
    // init ui module
    let uiModule = OSCAMobilityUI.create(with: productionDependencies)
    return uiModule
  } // end public func makeProductionUIModule
} // end extension OSCAMobilityUITests
#endif
