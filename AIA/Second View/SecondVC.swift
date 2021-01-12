//
//  SecondVC.swift
//  AIA
//
//  Created by Muhammad Faruuq Qayyum on 12/01/21.
//

import UIKit

class SecondVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var input1: UITextField!
    @IBOutlet weak var input2: UITextField!
    
    struct Section: Hashable {
        let date: Date
        var identifier = UUID()
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
    }
    
    var section: [Section] = []
    var item: [DailyAdjusted] = []

    private let symbolList = ["Select Symbol", "IBM", "IBMJ", "IBMK", "FB", "AMZN", "MSFT"]
    private let symbolPicker1 = UIPickerView()
    private let symbolPicker2 = UIPickerView()
    
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, DailyAdjusted>
    
    class DataSource: UITableViewDiffableDataSource<Section, DailyAdjusted> {
        
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let format = DateFormatter()
            format.locale = .current
            format.dateStyle = .medium
            
            let sorted = snapshot().sectionIdentifiers.sorted { $0.date > $1.date }
            return format.string(from: sorted[section].date)
        }
        
    }
    
    var dataSource: DataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Compare Symbol"
        configurePicker()
        doneToolBar()
        configureTableViewDataSource()
    }
    
    @IBAction func compareBtnAction(_ sender: UIButton) {
        var snapshot = DataSourceSnapshot()
        let format = DateFormatter()
        format.locale = .current
        format.dateStyle = .medium
        format.dateFormat = "yyyy-MM-dd"

        fetchDailyAdjusted(keywords: input1.text!) { (result) in
            switch result {
            case .success(let data):
//                print(data)
                self.item = []
                data.forEach { (item) in
                    let date = item.key
                    let value = item.value as? [String: Any]
                    let open = value!["1. open"] as! String
                    let low = value!["3. low"] as! String
                    print(date)
                    let newItem = DailyAdjusted(open: open, low: low, date: date)
                    let newSection = Section(date: format.date(from: date)!)
                    self.item.append(newItem)
                    self.section.append(newSection)
                    snapshot.appendSections([newSection])
                    snapshot.appendItems([newItem], toSection: newSection)
                    self.dataSource.apply(snapshot, animatingDifferences: true)
                }
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
}

extension SecondVC {
    fileprivate func configureTableViewDataSource() {
        dataSource = DataSource(tableView: tableView, cellProvider: { (tableView, indexPath, item) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = item.open
            cell.detailTextLabel?.text = item.low
            return cell
        })
        
    }
    
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
            URLQueryItem(name: "apikey", value: "E2GZMXN5UJD1MWLW")
        ]
        
        var request = URLRequest(url: components!.url!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (data, response, error) in
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
                        return
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

extension SecondVC: UIPickerViewDelegate {
    
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

extension SecondVC: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return symbolList.count
    }
    
}

