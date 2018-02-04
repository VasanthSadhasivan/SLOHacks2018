//
//  Helper.swift
//  SLOHacks2018
//
//  Created by Vasanth Sadhasivan on 2/3/18.
//  Copyright © 2018 Vasanth Sadhasivan. All rights reserved.
//

import Foundation
import GLKit
import ARKit
import Firebase
import FirebaseDatabase
import FirebaseCore
import CoreLocation

class Helper{
    
    static let locationManager : CLLocationManager = CLLocationManager()
    static var myLocation : CLLocation? = nil
    static var places : [Place]? = [Place]()
    static var databaseReference : DatabaseReference!
    
    static func createTransformationMatrix(distance : Float, azimuth : Float, floor : Int) -> matrix_float4x4
    {
        let translationMatrix = GLKMatrix4MakeTranslation(0, Float(floor * -10), -1 * distance)
        let rotationMatrix = GLKMatrix4MakeYRotation(GLKMathDegreesToRadians(360-(azimuth)))
        return float4x4((SCNMatrix4FromGLKMatrix4(GLKMatrix4Multiply(rotationMatrix, translationMatrix))))
        //How this could be employed: anchor = ARAnchor(transform: createTransformationMatrix(distance: XXX, azimuth: XXX, floor: XXX))
    }
    
    static func calculateAzimuth(startLocationLatitude : Float, startLocationLongitude : Float, endLocationLatitude : Float, endLocationLongitude : Float) -> Float
    {
        var azimuth: Float = 0
        let lat1 = GLKMathDegreesToRadians(startLocationLatitude)
        let lon1 = GLKMathDegreesToRadians(startLocationLongitude)
        let lat2 = GLKMathDegreesToRadians(endLocationLatitude)
        let lon2 = GLKMathDegreesToRadians(endLocationLongitude)
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        azimuth = GLKMathRadiansToDegrees(Float(radiansBearing))
        if(azimuth < 0) { azimuth += 360 }
        return azimuth
    }
    
    static func startLocationService(delegate : CLLocationManagerDelegate)
    {
        // For use in foreground
        locationManager.stopUpdatingLocation()
        myLocation = nil
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled()
        {
            locationManager.delegate = delegate
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    static func getPlaces() {
        databaseReference = Database.database().reference()
        
        databaseReference.observeSingleEvent(of: .value, with: { (data) in

            for child in data.children.allObjects{
                let name : String = ((child as! DataSnapshot).key) as String
                let imageURL : String = (((child as! DataSnapshot).children.allObjects[0] as! DataSnapshot).value) as! String
                let latitude : Float = (((child as! DataSnapshot).children.allObjects[1] as! DataSnapshot).value) as! Float
                let longitude : Float = (((child as! DataSnapshot).children.allObjects[2] as! DataSnapshot).value) as! Float
                places?.append(Place(name: name, latitude: Double(latitude), longitude: Double(longitude), anchor: nil, imageURL: imageURL))
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    static func sceneViewSetup(delegate : ARSKViewDelegate, sceneView : ARSKView){
        sceneView.delegate = delegate
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        // Load the SKScene from 'Scene.sks'
        if let scene = SKScene(fileNamed: "Scene")
        {
            sceneView.presentScene(scene)
        }
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        
        // Run the view's session
        sceneView.session.run(configuration)
    }


    static func calcualateLatLongDist(lat_01: Float, lon_01: Float, lat_02: Float, lon_02: Float) -> Float
    {
        let eRadius : Float = 6371008                          // mean volumetric radius (m) nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html
        let dLat : Float    = deg2rad(deg: lat_02-lat_01)           // Calc radians between two latidual points using the function   deg2rad [ below ]
        let dLon : Float    = deg2rad(deg: lon_02-lon_01)           // Same but with long
        let a : Float       = sin(dLat/2) * sin(dLat/2) + cos(deg2rad(deg: lat_01)) * cos(deg2rad(deg: lat_02)) * sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let d = eRadius * c // Distance in km
        return d
    }
    
    static func deg2rad(deg: Float) -> Float
    {
        return deg * (Float.pi/180)
    }


    static func calcARAnchors(){
        DispatchQueue.global(qos: .background).async {
            while (places?.count)! < 2{
            }
        
            for place : Place in places!{
                let azimuth = calculateAzimuth(startLocationLatitude: Float((myLocation?.coordinate.latitude)!), startLocationLongitude: Float((myLocation?.coordinate.latitude)!), endLocationLatitude: Float(place.getLatitude()), endLocationLongitude:  Float(place.getLongitude()))
            
                let distance = calcualateLatLongDist(lat_01: Float((myLocation?.coordinate.latitude)!), lon_01:         Float((myLocation?.coordinate.latitude)!), lat_02: Float(place.getLatitude()), lon_02: Float(place.getLongitude()))
            
                place.setAnchor(anchor: ARAnchor(transform: createTransformationMatrix(distance: distance, azimuth: azimuth, floor: 1)))
                print(place.getAnchor())
            }
        }
    }

}








