// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

/// use local package path
let packageLocal: Bool = false

let oscaEssentialsVersion = Version("1.1.0")
let oscaTestCaseExtensionVersion = Version("1.1.0")
let oscaMobilityVersion = Version("1.1.0")
let oscaMapUIVersion = Version("1.2.0")
let oscaWeatherVersion = Version("1.1.0")

let package = Package(
  name: "OSCAMobilityUI",
  defaultLocalization: "de",
  platforms: [.iOS(.v15)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "OSCAMobilityUI",
      targets: ["OSCAMobilityUI"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    // OSCAEssentials
    packageLocal ? .package(path: "../OSCAEssentials") :
    .package(url: "https://git-dev.solingen.de/smartcityapp/modules/oscaessentials-ios.git",
             .upToNextMinor(from: oscaEssentialsVersion)),
    // OSCAMobility
    packageLocal ? .package(path: "../OSCAMobilityMonitor") :
    .package(url: "https://git-dev.solingen.de/smartcityapp/modules/oscamobilitymonitor-ios.git",
             .upToNextMinor(from: oscaMobilityVersion)),
    // OSCAMapUI
    packageLocal ? .package(path: "../OSCAMapUI") :
    .package(url: "https://git-dev.solingen.de/smartcityapp/modules/oscamapui-ios.git",
             .upToNextMinor(from: oscaMapUIVersion)),
    // OSCAWeather
    packageLocal ? .package(path: "../OSCAWeather") :
    .package(url: "https://git-dev.solingen.de/smartcityapp/modules/oscaweather-ios.git",
             .upToNextMinor(from: oscaWeatherVersion)),
    // OSCATestCaseExtension
    packageLocal ? .package(path: "../OSCATestCaseExtension") :
    .package(url: "https://git-dev.solingen.de/smartcityapp/modules/oscatestcaseextension-ios.git",
             .upToNextMinor(from: oscaTestCaseExtensionVersion))
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "OSCAMobilityUI",
      dependencies: [.product(name: "OSCAMobility",
                              package: packageLocal ? "OSCAMobilityMonitor" : "oscamobilitymonitor-ios"),
                     .product(name: "OSCAMapUI",
                              package: packageLocal ? "OSCAMapUI" : "oscamapui-ios"),
                     .product(name: "OSCAWeather",
                              package: packageLocal ? "OSCAWeather" : "oscaweather-ios"),
                     /* OSCAEssentials */
                     .product(name: "OSCAEssentials",
                              package: packageLocal ? "OSCAEssentials" : "oscaessentials-ios")],
      path: "OSCAMobilityUI/OSCAMobilityUI",
      exclude: ["Info.plist",
                "SupportingFiles"],
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "OSCAMobilityUITests",
      dependencies: ["OSCAMobilityUI",
                     .product(name: "OSCATestCaseExtension",
                              package: packageLocal ? "OSCATestCaseExtension" : "oscatestcaseextension-ios")],
      path: "OSCAMobilityUI/OSCAMobilityUITests",
      exclude:[],
      resources: [.process("Resources")]
    ),
  ]
)
