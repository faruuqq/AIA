//
//  NewSecondVC.swift
//  AIA
//
//  Created by Muhammad Faruuq Qayyum on 13/01/21.
//

import UIKit

class NewSecondVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.reloadData()
        }
    }
    @IBOutlet weak var input1: UITextField!
    @IBOutlet weak var input2: UITextField!
    
    struct Section {
        let date: Date
    }
    
    var section: [Section] = []
    var item1: [DailyAdjusted] = []
    var item2: [DailyAdjusted] = []
    let homeVC = HomeVC()

    private let symbolList = ["Select Symbol", "IBM", "IBMJ", "IBMK", "FB", "AMZN", "MSFT"]
    private let symbolPicker1 = UIPickerView()
    private let symbolPicker2 = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        homeVC.configureAlert()
        self.title = "Compare Symbol"
        configurePicker()
        doneToolBar()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func compareBtnAction(_ sender: UIButton) {
        
        if input1.text == "" || input1.text == "Select Symbol" || input2.text == "" || input2.text == "Select Symbol" {
            let popUp = UIAlertController(title: nil, message: "No matching data", preferredStyle: .alert)
            popUp.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(popUp, animated: true, completion: nil)
            return
        }
        
        homeVC.indicator.startAnimating()
        homeVC.indicator.isHidden = false
        present(homeVC.alert, animated: true, completion: nil)
        
        let format = DateFormatter()
        format.locale = .current
        format.dateStyle = .medium
        format.dateFormat = "yyyy-MM-dd"
        
        fetchDailyAdjusted(keywords: input1.text!) { [weak self] (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let data):
                self?.item1 = []
                data.forEach { (item) in
                    let date = item.key
                    let value = item.value as? [String: Any]
                    let open = value!["1. open"] as! String
                    let low = value!["3. low"] as! String

                    let newItem = DailyAdjusted(open1: open, low1: low, date: format.date(from: date)!, open2: "", low2: "")
                    let newSection = Section(date: format.date(from: date)!)
                    self?.section.append(newSection)
                    self?.item1.append(newItem)
                }
            }
        }
        
        fetchDailyAdjusted(keywords: input2.text!) { [weak self] (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let data):
                self?.item2 = []
                data.forEach { (item) in
                    let date = item.key
                    let value = item.value as? [String: Any]
                    let open = value!["1. open"] as! String
                    let low = value!["3. low"] as! String
                    let newItem = DailyAdjusted(open1: "", low1: "", date: format.date(from: date)!, open2: open, low2: low)
                    self?.item2.append(newItem)
                    self?.tableView.reloadData()
                }
            }
            self?.homeVC.indicator.stopAnimating()
            self?.homeVC.alert.dismiss(animated: true, completion: nil)
        }
    }
}

extension NewSecondVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension NewSecondVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return section.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let format = DateFormatter()
        format.locale = .current
        format.dateStyle = .medium
        
        let sorted = self.section.sorted { $0.date > $1.date }
        
        return format.string(from: sorted[section].date)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.nibBundle?.loadNibNamed("SecondCell", owner: self, options: nil)?.first as! SecondCell
        
            
        cell.symbol1.text = self.input1.text
        cell.symbol2.text = self.input2.text
        
        let sortedItem1 = item1.sorted { $0.date! > $1.date! }
        let sortedItem2 = item2.sorted { $0.date! > $1.date! }
        
        cell.open1.text = "Open: \(sortedItem1[indexPath.row].open1)"
        cell.low1.text = "Low: \(sortedItem1[indexPath.row].low1)"
        
        cell.open2.text = "Open: \(sortedItem2[indexPath.row].open2)"
        cell.low2.text = "Low: \(sortedItem2[indexPath.row].low2)"
        
        return cell
    }
    
}

extension NewSecondVC: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return symbolList[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var selectedRow = row
        if selectedRow == 0 {
            selectedRow = 1
            pickerView.selectRow(selectedRow, inComponent: component, animated: true)
        }
        
        switch pickerView.tag {
        case 1:
            input1.text = symbolList[row]
        case 2:
            input2.text = symbolList[row]
        default:
            return
        }
        
    }
}

extension NewSecondVC: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return symbolList.count
    }
}

extension NewSecondVC {
    
    fileprivate func configurePicker() {
        symbolPicker1.delegate = self
        symbolPicker1.dataSource = self
        
        symbolPicker2.delegate = self
        symbolPicker1.delegate = self
        
        symbolPicker1.tag = 1
        symbolPicker2.tag = 2
        
        input1.inputView = symbolPicker1
        input2.inputView = symbolPicker2
    }
    
    fileprivate func doneToolBar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(doneTapped(_:)))
        toolbar.setItems([doneBtn], animated: true)
        input1.inputAccessoryView = toolbar
        input2.inputAccessoryView = toolbar
        
    }
    
    @objc
    func doneTapped(_ sender: UIPickerView) {
        view.endEditing(true)
    }
    
    fileprivate func fetchDailyAdjusted(keywords: String, completion: @escaping (Result<[String: Any], Error>) -> ()) {
        var components = URLComponents(string: "https://www.alphavantage.co/query?")
        components?.queryItems = [
            URLQueryItem(name: "function", value: "TIME_SERIES_DAILY_ADJUSTED"),
            URLQueryItem(name: "symbol", value: keywords),
            URLQueryItem(name: "apikey", value: homeVC.loadKeychain())
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
                    
                    let times = result!["Time Series (Daily)"] as? [String: Any]
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
