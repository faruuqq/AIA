//
//  ThirdVC.swift
//  AIA
//
//  Created by Muhammad Faruuq Qayyum on 13/01/21.
//

import UIKit

class ThirdVC: UIViewController {
    
    
    @IBOutlet weak var intervalLabel: UITextField!
    @IBOutlet weak var outputLabel: UITextField!
    @IBOutlet weak var apiLabel: UITextField!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.reloadData()
        }
    }
    
    let userDefault = UserDefaults.standard
    private let intervalList = ["Interval", "1min", "5min", "15min", "30min", "60min"]
    private let outputList = ["Output", "Compact", "Full"]
    private let intervalPicker = UIPickerView()
    private let outputPicker = UIPickerView()
    
    struct Section {
        let date: Date
    }
    
    var section: [Section] = []
    var item: [DailyAdjusted] = []
    let homeVC = HomeVC()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        homeVC.configureAlert()
        self.title = "Set Parameter"
        configurePicker()
        doneToolBar()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        intervalLabel.text = userDefault.string(forKey: "interval") ?? ""
        outputLabel.text = userDefault.string(forKey: "output") ?? ""
    }
    
    @IBAction func searchBtn(_ sender: UIButton) {
        view.endEditing(true)
        
        if intervalLabel.text == "" || outputLabel.text == "" || apiLabel.text == "" {
            let popUp = UIAlertController(title: nil, message: "No matching data", preferredStyle: .alert)
            popUp.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(popUp, animated: true, completion: nil)
            return
        }
        
        userDefault.setValue(intervalLabel.text, forKey: "interval")
        userDefault.setValue(outputLabel.text, forKey: "output")
        updateKeychain()
        
        homeVC.indicator.startAnimating()
        homeVC.indicator.isHidden = false
        present(homeVC.alert, animated: true, completion: nil)
        
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        fetchData(symbol: "IBM", api: apiLabel.text!, interval: intervalLabel.text!, outputsize: outputLabel.text!) { [weak self] (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let data):
                print("---------\(data)")
                self?.item = []
                data.forEach { (item) in
                    let date = item.key
                    let value = item.value as? [String: Any]
                    let open = value!["1. open"] as! String
                    let low = value!["3. low"] as! String
                    
                    let newItem = DailyAdjusted(open1: open, low1: low, date: formatter.date(from: date)!, open2: "", low2: "")
                    let newSection = Section(date: formatter.date(from: date)!)
                    
                    self?.item.append(newItem)
                    self?.section.append(newSection)
                    self?.tableView.reloadData()
                }
            }
            self?.homeVC.indicator.stopAnimating()
            self?.homeVC.alert.dismiss(animated: true, completion: nil)
        }
    }
    
}

extension ThirdVC: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 1:
            return intervalList.count
        case 2:
            return outputList.count
        default:
            return intervalList.count
        }
    }
}

extension ThirdVC: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 1:
            return intervalList[row]
        case 2:
            return outputList[row]
        default:
            return intervalList[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var selectedRow = row
        if selectedRow == 0 {
            selectedRow = 1
            pickerView.selectRow(selectedRow, inComponent: component, animated: true)
        }
        
        switch pickerView.tag {
        case 1:
            intervalLabel.text = intervalList[row]
        case 2:
            outputLabel.text = outputList[row]
        default:
            intervalLabel.text = intervalList[row]
        }
    }
    
}

extension ThirdVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ThirdVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return section.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let format = DateFormatter()
        format.locale = .current
        format.dateStyle = .medium
        format.timeStyle = .short
        format.dateFormat = "dd-MM-yyyy HH:mm"
        
        let sorted = self.section.sorted { $0.date > $1.date }
        
        return format.string(from: sorted[section].date)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Open: \(item[indexPath.row].open1)"
        cell.detailTextLabel?.text = "Low: \(item[indexPath.row].low1)"
        
        return cell
    }
    
    
}

extension ThirdVC {
    fileprivate func configurePicker() {
        intervalPicker.delegate = self
        intervalPicker.dataSource = self
        intervalPicker.tag = 1
        intervalLabel.inputView = intervalPicker
        
        outputPicker.delegate = self
        outputPicker.dataSource = self
        outputPicker.tag = 2
        outputLabel.inputView = outputPicker
    }
    
    fileprivate func doneToolBar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(doneTapped(_:)))
        toolbar.setItems([doneBtn], animated: true)
        intervalLabel.inputAccessoryView = toolbar
        outputLabel.inputAccessoryView = toolbar
        
    }
    
    @objc
    func doneTapped(_ sender: UIPickerView) {
        view.endEditing(true)
    }
    
    func updateKeychain() {
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: "alphavantage",
        ] as CFDictionary
        
        let updateFields = [
            kSecValueData: apiLabel.text!.data(using: .utf8)!
        ] as CFDictionary
        
        let status = SecItemUpdate(query, updateFields)
        print("Operation finished with status: \(status)")
    }
    
    fileprivate func fetchData(symbol: String, api: String, interval: String, outputsize: String, completion: @escaping (Result<[String: Any], Error>) -> ()) {
        
        var components = URLComponents(string: "https://www.alphavantage.co/query?")
        components?.queryItems = [
            URLQueryItem(name: "function", value: "TIME_SERIES_INTRADAY"),
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "outputsize", value: outputsize.lowercased()),
            URLQueryItem(name: "apikey", value: api)
        ]
        
        var request = URLRequest(url: components!.url!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { [weak self] (data, response, error) in
            
            guard let response = response as? HTTPURLResponse else { return }
            if response.statusCode != 200 {
                print("status code != 200")
                return
            }
            
            do {
                let result = try JSONSerialization.jsonObject(with: data!) as? [String: Any]
                
                DispatchQueue.main.async {
                    if result?.first?.key == "Error Message" || result?.first?.key == "Note" {
                        print("error message")
                        self?.homeVC.indicator.stopAnimating()
                        self?.homeVC.alert.dismiss(animated: true, completion: {
                            let popUp = UIAlertController(title: nil, message: "No matching data", preferredStyle: .alert)
                            popUp.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self?.present(popUp, animated: true, completion: nil)
                            return
                        })
                    }
                    
                    let times = result!["Time Series (\(interval))"] as? [String: Any]
                    completion(.success(times!))
                }
            } catch let error {
                print(error.localizedDescription)
                completion(.failure(error))
            }
        }
        dataTask.resume()
    }
}
