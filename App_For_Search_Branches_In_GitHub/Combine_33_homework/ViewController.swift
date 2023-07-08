//
//  ViewController.swift
//  Combine_33_homework
//
//  Created by Артем on 15.03.2023.
//


import UIKit
import Combine
import Foundation


struct Repository : Decodable {
    let name : String
    let language: String?
    
}

struct Branch: Decodable {

 let name: String

}


struct TextRepository : Decodable {
    var texting : String
}



class ViewController: UIViewController, UITableViewDataSource  {
    
    //количество секций
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return source.count
    }
    
    
    //текст ячеек
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        let section = "\(source[section].section[section].name ) [\(source[section].section[section].language ?? "Not found")]"
        return section
        
        
    }
    
    
    //количество ячеек в секции
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let pip = source[section].rows.count
        
        return pip
        
        
    }
    
    //текст ячеек
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        
        cell.textLabel?.text = "\(source[indexPath.section].rows[indexPath.row].name ) "
        
        
        
        
        
        return cell
        
    }
    @IBOutlet weak var textlabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textFielf: UITextField!
    
    //сюда сохраняются ветки
    
    var pop2: [Branch] = []{
        didSet{
            DispatchQueue.main.async { [self] in
                tableView.reloadData()
                
            }
        }
    }
    
    
    //сюда сохраняются репозитории
    
    
    var subscription1 = Set<AnyCancellable>()
    
    var pop: [Repository] = []{
        didSet{
            DispatchQueue.main.async { [self] in
                tableView.reloadData()
                
            }
        }
    }
    
    
    func descriptionPublisher(word : String) -> AnyPublisher<[Repository], Never>{
        
        tableView.reloadData()
        return Just([]).eraseToAnyPublisher()
        
    }
    
    
    var subscription : AnyCancellable? = nil
    var subscription2 : AnyCancellable? = nil
    var subscription3 : AnyCancellable? = nil
    private var cancell: AnyCancellable?
    private var cancell2: AnyCancellable?
    private var cancell3: AnyCancellable?
    
    
    var source: [(section: [Repository], rows: [Branch])] = []{
        didSet{
            DispatchQueue.main.async { [self] in
                tableView.reloadData()
                
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
        serviceAPI()

    }
    
    
    
    
    func serviceAPI () {
        subscription = NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: textFielf)
            .compactMap {$0.object as? UITextField}
            .compactMap {$0.text}
            .debounce(for: .seconds(2.0), scheduler: RunLoop.main)
            .sink { [self] value in
                
                
                tableView.reloadData()

                self.tableView.dataSource = self
                self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
                
                
                let alfavite = ["а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц",
                                "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я"]
                for i in alfavite {
                    guard value.contains(i) == false else {
                        
                        textlabel.textColor = .red
                        textlabel.backgroundColor = .green
                        textlabel.text = "Нельзя вводить русские буквы"
                        
                        return
                    }
                }
          let  url = URL(string: "https://api.github.com/orgs/\(value)/repos")!
                    
          
                

                
                self.cancell = URLSession.shared.dataTaskPublisher(for: url)
                    .map({$0.data})
                
                    .decode(type: [Repository].self, decoder: JSONDecoder())
                
                    .replaceError(with: [])
                    .eraseToAnyPublisher()
                    .assign(to: \.pop, on: self)
                tableView.reloadData()
                
                guard url == URL(string: "https://api.github.com/orgs/\(value)/repos")! else {
                    
                    return }
                print("url success")
                tableView.reloadData()
                _ = Future<Any, Error> { promise in
                    
                    let task = URLSession.shared.dataTask(with: url) { [self] (data, response, error) in
                        if error != nil {
                            print("error")
                            return
                        }
                        guard let data = data, !data.isEmpty else {
                            promise(.failure(error!))
                            return
                        }
                        
                        
                        // Здесь я делаю проверку на результат decode Repository , чтобы загрузить ветки
                        
                        if let searchResults = try? JSONDecoder().decode([Branch].self, from: data) {
                            print("Start Load")
                            source.removeAll()
                            

                            let count = searchResults.count
                            for i in 0..<count{
                                
                                let url2 =
                                URL(string:"https://api.github.com/repos/\(value)/\(searchResults[i].name)/branches")!
                                
                                
                                
                                self.cancell2 = URLSession.shared.dataTaskPublisher(for: url2)
                                    .map({$0.data})
                                
                                    .decode(type: [Branch].self, decoder: JSONDecoder())
                                    .debounce(for: .seconds(2.0), scheduler: RunLoop.main)
                                    .replaceError(with: [])
                                    .eraseToAnyPublisher()
                                    .assign(to: \.pop2, on: self)
                                guard url == URL(string: "https://api.github.com/orgs/\(value)/repos")! else {
                                    
                                    return }
                                print("url success")
                                
                                
                                _ = Future<Any, Error> { promise in
                                    
                                    let task = URLSession.shared.dataTask(with: url2) { [self] (data, response, error) in
                                        if error != nil {
                                            print("error")
                                            return
                                        }
                                        guard let data = data, !data.isEmpty else {
                                            promise(.failure(error!))
                                            return
                                        }
                                        if let searchResults1 = try? JSONDecoder().decode([Branch].self, from: data) {
                                            print("Start Load")
                                            DispatchQueue.main.async { [self] in
                                                
                                                textlabel.textColor = .green
                                                textlabel.text = "Запрос выполнен успешно"
                                                
                                            }
                                            source.append((section: pop, rows: searchResults1))
                                            
                                        } else {
                                            print("error")
                                        }
                                        
                                        
                                    }
                                    task.resume()
                                }
                                
                            }
                            
                            
                        } else {
                            DispatchQueue.main.async {
                                
                                textlabel.textColor = .orange
                                textlabel.text = "Аккаунт не найден"
                            }
                        }
                        
                        
                    }
                    
                    task.resume()
                    
                }
                
            }
        
        
    }
    
    
}
