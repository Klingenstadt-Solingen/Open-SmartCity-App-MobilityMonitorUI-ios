//
//  OSCAMobilityPTDetailCellViewModel.swift
//  OSCAMobilityUI
//
//  Created by Mammut Nithammer on 05.10.22.
//

import Combine
import Foundation
import OSCAMobility

public final class OSCAMobilityPTDetailCellViewModel {
  var direction: String = ""
  var lineNumber: String = ""
  var delay: Int = 0
  var departure: String = "-"
  var minsUntilDeparture = 0
  var departureTime: String = ""

  let availableOption: OSCAMobilityResponse.AvailableOption
  private let cellRow: Int
  private var bindings = Set<AnyCancellable>()
  
  let deeplink: String?

  public init(availableOption: OSCAMobilityResponse.AvailableOption,
              at row: Int) {
    self.availableOption = availableOption
    self.deeplink = availableOption.deeplinks?.ios
    cellRow = row
    setupBindings()
  }

  private func setupBindings() {
    direction = availableOption.name ?? ""
    lineNumber = availableOption.shortName ?? ""
    delay = (availableOption.delayed ?? false) ? Int(round(Double(availableOption.delay ?? 0)) / 60) : 0

    if let departureTimePlanned = availableOption.departureTimePlanned {
      let calendar = Calendar.current
      
      let departureWithDelay = calendar.date(byAdding: .minute, value: delay, to: departureTimePlanned)
      
      let timeComponents = calendar.dateComponents([.hour, .minute], from: departureWithDelay ?? departureTimePlanned)
      let nowComponents = calendar.dateComponents([.hour, .minute], from: Date())

      if let difference = calendar.dateComponents([.minute], from: nowComponents, to: timeComponents).minute {
        departure = "\(difference)"
        self.minsUntilDeparture = difference
      }
      
      self.departureTime = String(format: "%02d:%02d", timeComponents.hour ?? 0, timeComponents.minute ?? 0)
    }
  }
}
