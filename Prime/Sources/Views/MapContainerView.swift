import UIKit
import MapKit

final class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

final class MapContainerView: UIView, MKMapViewDelegate {
    private var mapView: MKMapView!
    
    init(frame: CGRect, location: CLLocationCoordinate2D?) {
        super.init(frame: frame)
        setupMapView(location: location)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupMapView(location: nil)
    }
    
    private func setupMapView(location: CLLocationCoordinate2D?) {
        mapView = MKMapView(frame: bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        addSubview(mapView)
        
        let regionRadius: CLLocationDistance = 1000 // 1 km
        
        guard let location else { return }
        let coordinateRegion = MKCoordinateRegion(
            center: location,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )
        
        mapView.setRegion(coordinateRegion, animated: true)
        
        // Add annotations or overlays as needed
        let annotation = CustomAnnotation(coordinate: location)
        mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            // Return nil for the user's location annotation
            return nil
        }
        
        let reuseIdentifier = "customAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView!.canShowCallout = true
            annotationView!.calloutOffset = CGPoint(x: -5, y: 5)
            annotationView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            annotationView!.annotation = annotation
        }
        
        // Set your custom pin image here
        annotationView!.image = UIImage(named: "pin_fill")
        
        return annotationView
    }
}


