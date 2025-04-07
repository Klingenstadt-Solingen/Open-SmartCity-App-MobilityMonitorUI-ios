//
//  MobilityFlow+OSCADeeplinkHandeble.swift
//  OSCAMobilityUI
//
//  Created by Stephan Breidenbach on 21.02.23.
//

import Foundation
import OSCAEssentials

extension OSCAMobilityFlowCoordinator: OSCADeeplinkHandeble {
  ///```console
  ///xcrun simctl openurl booted \
  /// "solingen://mobilitymonitor/"
  /// ```
  public func canOpenURL(_ url: URL) -> Bool {
    let deeplinkScheme: String = dependencies
      .deeplinkScheme
    return url.absoluteString.hasPrefix("\(deeplinkScheme)://mobilitymonitor")
  }// end public func canOpenURL
  
  public func openURL(_ url: URL,
                      onDismissed:(() -> Void)?) throws -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function): url: \(url.absoluteString)")
#endif
    guard canOpenURL(url) else { return }
    showMobilityMain(animated: true,
                     onDismissed: onDismissed)
  }// end public func openURL
}// end extension final class OSCAMobilityFlowCoordinator
