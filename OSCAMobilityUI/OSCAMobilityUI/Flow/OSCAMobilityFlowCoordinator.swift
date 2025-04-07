//
//  OSCAMobilityFlowCoordinator.swift
//  OSCAMobilityUI
//
//  Created by Mammut Nithammer on 05.10.22.
//

import Foundation
import OSCAEssentials
import OSCAMobility

public protocol OSCAMobilityFlowCoordinatorDependencies {
  var deeplinkScheme: String { get }
  func makeOSCAMobilityMainViewController(actions: OSCAMobilityMainViewModelActions) -> OSCAMobilityMainViewController
} // end protocol OSCAMobilityFlowCoordinatorDependencies

public final class OSCAMobilityFlowCoordinator: Coordinator {
  /**
   `children`property for conforming to `Coordinator` protocol is a list of `Coordinator`s
   */
  public var children: [Coordinator] = []
  
  /**
   router injected via initializer: `router` will be used to push and pop view controllers
   */
  public let router: Router
  
  /**
   dependencies injected via initializer DI conforming to the `OSCAMobilityFlowCoordinatorDependencies` protocol
   */
  let dependencies: OSCAMobilityFlowCoordinatorDependencies
  
  /**
   press release main view controller `OSCAMobilityMainViewController`
   */
  weak var MobilityMainVC: OSCAMobilityMainViewController?
  
  
  public init(router: Router,
              dependencies: OSCAMobilityFlowCoordinatorDependencies
  ) {
    self.router = router
    self.dependencies = dependencies
  } // end init router, dependencies
  
  // MARK: - Mobility Main
  public func showMobilityMain(animated: Bool,
                                    onDismissed: (() -> Void)?) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    if let MobilityMainVC = MobilityMainVC {
      self.router.present(MobilityMainVC,
                          animated: animated,
                          onDismissed: onDismissed)
    } else {
      // Note: here we keep strong reference with actions, this way this flow do not need to be strong referenced
      let actions: OSCAMobilityMainViewModelActions = OSCAMobilityMainViewModelActions() // end let actions
      // instantiate view controller
      let vc = dependencies.makeOSCAMobilityMainViewController(actions: actions)
      self.router.present(vc,
                          animated: animated,
                          onDismissed: onDismissed)
      MobilityMainVC = vc
    }// end if
  }// end public func showMobilityMain
  
  public func present(animated: Bool, onDismissed: (() -> Void)?) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
      showMobilityMain(animated: animated, onDismissed: onDismissed)
  } // end func present
} // end final class OSCAMobilityFlowCoordinator

extension OSCAMobilityFlowCoordinator {
  public func setup() -> Void {
      
  }// end func setup
}// end extension final class OSCAMobilityFlowCoordinator

extension OSCAMobilityFlowCoordinator {
  /**
   add `child` `Coordinator`to `children` list of `Coordinator`s and present `child` `Coordinator`
   */
  public func presentChild(_ child: Coordinator,
                           animated: Bool,
                           onDismissed: (() -> Void)? = nil) {
    children.append(child)
    child.present(animated: animated) { [weak self, weak child] in
      guard let self = self, let child = child else { return }
      self.removeChild(child)
      onDismissed?()
    } // end on dismissed closure
  } // end public func presentChild
  
  private func removeChild(_ child: Coordinator) {
    /// `children` includes `child`!!
    guard let index = children.firstIndex(where: { $0 === child }) else { return } // end guard
    children.remove(at: index)
  } // end private func removeChild
} // end extension public final class OSCAMobilityFlowCoordinator

