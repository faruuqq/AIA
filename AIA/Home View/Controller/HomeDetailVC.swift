//
//  HomeDetailVC.swift
//  AIA
//
//  Created by Muhammad Faruuq Qayyum on 11/01/21.
//

import UIKit

class HomeDetailVC: UITableViewController {
    
    struct Section: Hashable {
        let date: Date
        var identifier = UUID()
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
    }
    
    var section: [Section] = []
    var loadSymbol: String?
    var item: [Intraday] = []
    let homeVC = HomeVC()

    private var dataSource: DataSource!
    
    typealias DataSource = UITableViewDiffableDataSource<Section, Intraday>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, Intraday>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        homeVC.configureAlert()
        self.title = "Intraday"
        configureTableViewDataSource()
        print(loadSymbol!)
        fetchIntraday(keywords: loadSymbol!)
    }

}

extension HomeDetailVC {
    fileprivate func fetchIntraday(keywords: String) {
        
        homeVC.indicator.startAnimating()
        homeVC.indicator.isHidden = false
        present(homeVC.alert, animated: true, completion: nil)
        
        var snapshot = DataSourceSnapshot()
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var components = URLComponents(string: "https://www.alphavantage.co/query?")
        components?.queryItems = [
            URLQueryItem(name: "function", value: "TIME_SERIES_INTRADAY"),
            URLQueryItem(name: "symbol", value: keywords),
            URLQueryItem(name: "interval", value: "1min"),
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
                    
                    let times = result!["Time Series (1min)"] as? [String: Any]
                    self?.item = []
                    times?.forEach ({ (item) in
//                        print("item = \(item.key)")
                        let date = item.key
                        let value = item.value as? [String: Any]
                        let open = value!["1. open"] as! String
                        let high = value!["2. high"] as! String
                        let low = value!["3. low"] as! String
                        
                        let newItem = Intraday(open: open, high: high, low: low, date: date)
                        let newSection = Section(date: formatter.date(from: date)!)
                        
                        self?.item.append(newItem)
                        self?.section.append(newSection)
//                        self?.applySnapshot(item: self!.item)
                        snapshot.appendSections([newSection])
                        snapshot.appendItems([newItem], toSection: newSection)
                        self?.dataSource.apply(snapshot, animatingDifferences: true)
                    })
                    self?.homeVC.indicator.stopAnimating()
                    self?.homeVC.alert.dismiss(animated: true, completion: nil)
                }
            } catch (let error) {
                DispatchQueue.main.async {
                    print(error.localizedDescription)
                }
            }
        }
        dataTask.resume()
    }
    
    fileprivate func configureTableViewDataSource() {
        dataSource = DataSource(tableView: tableView, cellProvider: { (tableView, indexPath, item) -> UITableViewCell? in
            
            let cell = self.nibBundle?.loadNibNamed("HomeDetailCell", owner: self, options: nil)?.first as! HomeDetailCell
            cell.openLabel.text = "1. Open: \(item.open)"
            cell.highLabel.text = "2. High: \(item.high)"
            cell.lowLabel.text = "3. Low: \(item.low)"
            cell.dateLabel.text = item.date
            return cell
        })
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let format = DateFormatter()
        format.locale = .current
        format.dateStyle = .medium

        let sorted = DataSourceSnapshot().sectionIdentifiers.sorted { $0.date > $1.date }
        return format.string(from: sorted[section].date)
    }
}
