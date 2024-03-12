import Foundation
import UIKit
import CoreLocation

extension UIImageView {

    func setCustomImage(_ imgURLString: String?) {
        guard let imageURLString = imgURLString else {
            self.image = UIImage(named: "default.png")
            return
        }
        
        DispatchQueue.global().async { [weak self] in
            let data = try? Data(contentsOf: URL(string: imageURLString)!)
            DispatchQueue.main.async {
                self?.image = data != nil ? UIImage(data: data!) : UIImage(named: "default.png")
            }
        }
    }
}

extension Date {
   func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}


extension String {
    func convertToCoordinates(completion: @escaping (Result<(CLLocationCoordinate2D, String), Error>) -> Void) {
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(self) { (placemarks, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let placemark = placemarks?.first, let location = placemark.location?.coordinate else {
                completion(.failure(NSError(domain: "GeocodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to obtain coordinates"])))
                return
            }
            
            let cityName = placemark.locality ?? ""
            
            completion(.success((location, cityName)))
        }
    }
    
    func hasValidValue() -> Bool {
        return !(self).isEmpty
    }
}

extension String? {
    func hasValidValue() -> Bool {
        return self != nil || !(self ?? "").isEmpty
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
