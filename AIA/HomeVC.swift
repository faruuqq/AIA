//
//  ViewController.swift
//  AIA
//
//  Created by Muhammad Faruuq Qayyum on 11/01/21.
//

import UIKit

class HomeVC: UITableViewController {
    
    var item: [BestMatches] = []
    private var dataSource: DataSource!
    
    let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
    let indicator = UIActivityIndicatorView(frame: CGRect(x: 20, y: 0, width: 60, height: 60))
    
    typealias DataSource = UITableViewDiffableDataSource<Int, BestMatches>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<Int, BestMatches>
    
    let searchController: UISearchController = {
        let search = UISearchController()
        search.searchBar.placeholder = "Search symbol"
        return search
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.hidesWhenStopped = true
        indicator.isHidden = true
        alert.view.addSubview(indicator)
        self.title = "Home"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.delegate = self
        configureTableViewDataSource()
        fetchingData(keywords: "IBM".uppercased())
        
    }

}

extension HomeVC: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        item = []
        fetchingData(keywords: searchBar.searchTextField.text!.uppercased())
        searchController.isActive = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //MARK: due to free apikey, the request is limited. Uncomment code below to enable instant fetching
        
//        item = []
//        fetchingData(keywords: searchBar.searchTextField.text!.uppercased())
    }
    
}

extension HomeVC {
    /*completion: @escaping (Result<[HomeModel], Error>) -> ()*/
    fileprivate func fetchingData(keywords: String) {
        indicator.startAnimating()
        indicator.isHidden = false
        present(alert, animated: true, completion: nil)
        var components = URLComponents(string: "https://www.alphavantage.co/query?")
        components?.queryItems = [
            URLQueryItem(name: "function", value: "SYMBOL_SEARCH"),
            URLQueryItem(name: "keywords", value: keywords),
            URLQueryItem(name: "apikey", value: "E2GZMXN5UJD1MWLW")
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
                let result = try JSONDecoder().decode(HomeModel.self, from: data!)
                DispatchQueue.main.async {
                    if result.bestMatches == [] {
                        print("empty")
                        self?.indicator.stopAnimating()
                        self?.alert.dismiss(animated: true, completion: {
                            let popUp = UIAlertController(title: nil, message: "No matching data", preferredStyle: .alert)
                            popUp.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self?.present(popUp, animated: true, completion: nil)
                            return
                        })
                    }
                    result.bestMatches.forEach { (item) in
                        let newItem = BestMatches(symbol: item.symbol, companyName: item.companyName)
                        self?.item.append(newItem)
                        self?.applySnapshot(item: self!.item)
                        self?.indicator.stopAnimating()
                        self?.alert.dismiss(animated: true, completion: nil)
                    }
                }
            } catch (let error) {
                DispatchQueue.main.async {
                    self?.indicator.stopAnimating()
                    self?.alert.dismiss(animated: true, completion: nil)
                    print(error.localizedDescription)
                }
            }
        }
        dataTask.resume()
    }
    
    fileprivate func configureTableViewDataSource() {
        dataSource = DataSource(tableView: tableView, cellProvider: { (tableView, indexPath, item) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = item.symbol
            cell.detailTextLabel?.text = item.companyName
            return cell
        })
    }
    
    fileprivate func applySnapshot(item: [BestMatches]) {
        var snapshot = DataSourceSnapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(item)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print(dataSource.itemIdentifier(for: indexPath)!)
    }
    
}

