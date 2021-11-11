//
//  ViewController.swift
//  ios-covid19
//
//  Created by 허지인 on 2021/11/10.
//

import UIKit

import Alamofire
import Charts

class ViewController: UIViewController {

    @IBOutlet weak var totalCaseLabel: UILabel!
    @IBOutlet weak var newCaseLabel: UILabel!
    @IBOutlet weak var pieChartView: PieChartView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchCovidOverview(completionHandler: { [weak self] result in
            guard let self = self else {return}
            switch result {
            case let .success(result):
                debugPrint("sucess \(result)")
                
            case let .failure(error):
                debugPrint("error \(error)")
            }
            
        })
        // Do any additional setup after loading the view.
    }
    
    func fetchCovidOverview (
        // @escaping 클로저 - 함수로 탈출한다는 의미
        // 함수의 인자로 클로저가 전달 되지만 함수가 반환된 후에도 실행되는 것을 의미 (함수에서 선언된 로컬변수가 밖에서도 유효)
        // 예시는 비동기 작업을 하는 경우 completionHandler로 escaping 클로저로 많이 사용
        // 보통 네트워킹 통신은 비동기적으로 작업되기 때문에 completionHandler 클로저는 fetchCovidOverview가 반환된 후에 호출됨
        // 이유는 서버에서 데이터를 언제 응답시켜줄지 모르기 때문에
        // 이렇게 하지 않으면 서버에서 비동기로 응답받기전 completionHandler클로저가 호출되기 전에 함수가 종료돼
        // 응답을 받아도 completionHandler가 호출되지 않는다.
        
        // 그래서 함수 내에서 비동기 작업을 하고 비동기 작업의 결과를 completionHandler로 콜백을 시켜줘야 한다면
        // @escaping 클로저를 사용하여 함수가 반환된 후에도 실행되게 만들어 주어야한다.
        completionHandler: @escaping (Result<CityCovidOverview, Error>) -> Void
    ){
        let url = "https://api.corona-19.kr/korea/country/new/"
        let param = [
            "serviceKey" : "RjlmEYkSVtPWG4gsrX3a97pTeKODxcFMy"
        ]
        // Alamofire, param 딕셔너리 형태로 파라미터를 전달하면 알아서 url 쿼리 파라미터를 추가해줌
        AF.request(url, method: .get, parameters: param)
            .responseData(completionHandler: { response in
                switch response.result { //응답 데이터를 받을 수 있는 데이터를 체이닝 해줘야함 (.responseData)
                case let .success(data):
                    // 연관 값으로 서버에서 응답받은 데이터를 CitiyCovidOverview 객체에 매핑
                    do {
                        let decoder = JSONDecoder()
                        let result = try decoder.decode(CityCovidOverview.self, from: data)
                        completionHandler(.success(result))
                    }catch {
                        completionHandler(.failure(error))
                    }
                    
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            })
    }
    
}

