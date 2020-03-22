//
//  CoreLocation+Combine.swift
//  Open
//
//  Created by John McAvey on 3/21/20.
//  Copyright © 2020 John McAvey. All rights reserved.
//

import Foundation
import CoreLocation
import Combine

enum CLLocationError: Error  {
    case disallowed
    case unkown(Error)
}

enum CLLocationEvent {
    case resumed
    case paused
    case didVisit(CLVisit)
    case didExit(CLRegion)
    case didEnter(CLRegion)
    case beganMonitoring(CLRegion)
    case endedMonitoring(CLRegion)
    case newHeading(CLHeading)
    case newLocations([CLLocation])
    case finishedDeferredUpdate
    case failedDeferredUpdate(Error)
    case authorizationStatus(CLAuthorizationStatus)
    case newState(state: CLRegionState, region: CLRegion)
    case failedMonitoring(region: CLRegion?, error: Error)
    case failedRanging(beacon: CLBeaconIdentityConstraint, error: Error)
    case range(beacons: [CLBeacon], contraint: CLBeaconIdentityConstraint)
}

class CLLocationWrapper: NSObject, CLLocationManagerDelegate {
    struct Config {
        static var standard: Config {
            return Config(shouldDisplayHeadingCalibration: false, authorizationLevel: .authorizedWhenInUse)
        }
        let shouldDisplayHeadingCalibration: Bool
        let authorizationLevel: CLAuthorizationStatus
    }
    static var shared: CLLocationWrapper {
        CLLocationWrapper(manager: CLLocationManager())
    }
    let manager: CLLocationManager
    let config: Config
    
    public let events: AnyPublisher<CLLocationEvent, CLLocationError>
    private let eventDrop: PassthroughSubject<CLLocationEvent, CLLocationError>
    
    init(manager: CLLocationManager, config: Config = .standard) {
        self.manager = manager
        self.config = config
        self.eventDrop = PassthroughSubject()
        self.events = self.eventDrop.share().print().eraseToAnyPublisher()
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.authorizationStatus() != config.authorizationLevel {
            self.requestAuth()
        } else {
            manager.startUpdatingLocation()
        }
    }
    
    func requestAuth() {
        switch config.authorizationLevel {
        case .authorizedAlways:
            manager.requestAlwaysAuthorization()
        default:
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.paused)
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.resumed)
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.didVisit(visit))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(completion: .failure(.unkown(error)))
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.didExit(region))
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.didEnter(region))
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        guard self.shouldOperateOn(manager) else { return false }
        return self.config.shouldDisplayHeadingCalibration
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.beganMonitoring(region))
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.newHeading(newHeading))
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.newLocations(locations))
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        guard self.shouldOperateOn(manager) else { return }
        if let err = error {
            self.eventDrop.send(.failedDeferredUpdate(err))
        } else {
            self.eventDrop.send(.finishedDeferredUpdate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard self.shouldOperateOn(manager) else { return }
        if ![CLAuthorizationStatus.denied, CLAuthorizationStatus.notDetermined].contains(status) {
            manager.startUpdatingLocation()
        }
        self.eventDrop.send(.authorizationStatus(status))
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.newState(state: state, region: region))
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.failedMonitoring(region: region, error: error))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint, error: Error) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.failedRanging(beacon: beaconConstraint, error: error))
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        guard self.shouldOperateOn(manager) else { return }
        self.eventDrop.send(.range(beacons: beacons, contraint: beaconConstraint))
    }
    
    func shouldOperateOn(_ manager: CLLocationManager) -> Bool {
        return manager == self.manager
    }
}

extension CLLocationManager {
    class var locations: AnyPublisher<[CLLocation], CLLocationError> {
        return CLLocationWrapper.shared
        .events
        .compactMap { event in
            if case .newLocations(let locations) = event {
                return locations
            }
            return nil
        }
        .eraseToAnyPublisher()
    }
    class var currentLocation: AnyPublisher<CLLocation, CLLocationError> {
        return self.locations
            .compactMap() { (locations: [CLLocation]) in locations.first }
            .eraseToAnyPublisher()
    }
}
