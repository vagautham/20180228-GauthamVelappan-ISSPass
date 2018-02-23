//
//  DashboardViewController.swift
//  ISSP-iOS
//
//  Created by Gautham Velappan/New York/IBM on 2/22/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit
import CoreLocation

class DashboardViewController: UIViewController {
        
    // MARK: Internal Properties
    let urlString = "http://api.open-notify.org/iss-pass.json?"
    
    let Lat = "lat="
    let Lon = "lon="
    let Alt = "alt="
    
    // MARK: IBOutlets
    @IBOutlet weak var latTextField: UITextField!
    @IBOutlet weak var lonTextField: UITextField!
    @IBOutlet weak var altTextField: UITextField!
    
    @IBOutlet weak var lastUpdateLabel: UILabel!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var resultTable: UITableView!
    
    private let locationManager = CLLocationManager()
    
    private var currentLocation: CLLocation! {
        didSet {
            latTextField.text = String(currentLocation.coordinate.latitude)
            lonTextField.text = String(currentLocation.coordinate.longitude)
            
            altTextField.text = String(currentLocation.altitude)
        }
    }
    
    private var response: [[String: Any]]? = nil {
        didSet {
            resultTable.isHidden = (response == nil || response?.count == 0)
            resultTable.reloadData()
        }
    }
    
    private var request: [String: Any]? = nil {
        didSet {
            var lastUpdate = String("Last Updated: ")
            if let date = request?["datetime"] as? Double {
                let dateString = Date(timeIntervalSince1970: date)
                lastUpdate = lastUpdate + String("\n") + dateString.description(with: Locale.current)
            } else {
                lastUpdate = lastUpdate + String("N/A")
            }
            lastUpdateLabel.text = lastUpdate
        }
    }
    
    // MARK: Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        resultTable.dataSource = self
        resultTable.tableFooterView = UIView()
        response = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: IBAction
    @IBAction func onSubmitTapped(_ sender: Any) {
        self.resignAllResponders()
        self.makeRequest()
    }
    
    private func resignAllResponders() {
        if latTextField.isFirstResponder {
            latTextField.resignFirstResponder()
        }
        if lonTextField.isFirstResponder {
            lonTextField.resignFirstResponder()
        }
        if altTextField.isFirstResponder {
            altTextField.resignFirstResponder()
        }
    }
    
    // MARK: Internal Methods
    private func showError(title: String, message: String) {
        let errorAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        errorAlertController.addAction(okAction)
        self.present(errorAlertController, animated: true, completion: nil)
    }
    
    private func timeFormatted(totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        let hours: Int = totalSeconds / 3600
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func makeRequest() {
        var urlString = self.urlString
        
        let latitude = self.latTextField.text ?? ""
        let longitude = self.lonTextField.text ?? ""
        
        urlString = urlString + Lat + latitude
        urlString = urlString + "&" + Lon + longitude
        
        if let altitude = self.altTextField.text, !(altitude.isEmpty) {
            urlString = urlString + "&" + Alt + altitude
        }
        
        guard let url = URL(string: urlString) else { return }
        
        submitButton.isEnabled = false
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                
                self.submitButton.isEnabled = true
                
                guard (data != nil && error == nil),
                let dictionary = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
                    self.showError(title: "Error", message: error!.localizedDescription)
                    return
                }
                
                guard let response = dictionary!["response"] as? [[String: Any]],
                    let request = dictionary!["request"] as? [String: Any] else {
                        if let reason = dictionary!["reason"] as? String {
                            self.showError(title: "Error", message: reason)
                        }
                        return
                }
                
                self.request = request
                self.response = response
            }
        }
        
        task.resume()
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}

extension DashboardViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else { return }
        
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        self.currentLocation = location
        
        locationManager.stopUpdatingLocation()
    }
}

extension DashboardViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return response?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        let data = response![indexPath.row]
        
        cell = tableView.dequeueReusableCell(withIdentifier: "resultTableCell", for: indexPath)
        let duration = self.timeFormatted(totalSeconds: (data["duration"] as? Int) ?? 0)
        (cell.viewWithTag(1) as? UILabel)?.text = duration
        
        let timeInterval = TimeInterval((data["risetime"] as? Int) ?? 0)
        let raiseDate = Date(timeIntervalSince1970: timeInterval)
        (cell.viewWithTag(2) as? UILabel)?.text = raiseDate.description(with: Locale.current)
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "[Duration(HH:MM:SS) : RiseTime(DATE)]"
    }
}
