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
    
    @IBOutlet weak var labelStackView: UIStackView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.indicatorView.startAnimating()
        self.fetchCovidOverview(completionHandler: { [weak self] result in
            guard let self = self else {return}
            self.indicatorView.stopAnimating()
            self.indicatorView.isHidden = true
            self.labelStackView.isHidden = false
            self.pieChartView.isHidden = false
            switch result {
            case let .success(result):
                // Alamofire completionHandler 핸들러는 메인스레드에서 작동하기 때문에
                // 따로 메인 디스패치큐를 안만들어도 됨
                self.configureStackView(koreaCovidOverview: result.korea)
                let covidOverviewList = self.makeCovidOverviewList(cityCovidOverview: result)
                self.configureChartView(covidOverviewList: covidOverviewList)
                
                
            case let .failure(error):
                debugPrint("error \(error)")
            }
        })
    }
    
    func makeCovidOverviewList(cityCovidOverview: CityCovidOverview) -> [CovidOverview] {
        return [
            cityCovidOverview.seoul,
            cityCovidOverview.busan,
            cityCovidOverview.daegu,
            cityCovidOverview.incheon,
            cityCovidOverview.gwangju,
            cityCovidOverview.daegu,
            cityCovidOverview.ulsan,
            cityCovidOverview.sejong,
            cityCovidOverview.gyeonggi,
            cityCovidOverview.chungbuk,
            cityCovidOverview.chungnam,
            cityCovidOverview.gyeongbuk,
            cityCovidOverview.gyeongnam,
            cityCovidOverview.jeju,
            cityCovidOverview.quarantine,
        ]
    }
    
    func configureChartView(covidOverviewList: [CovidOverview]) {
        self.pieChartView.delegate = self
        let entries = covidOverviewList.compactMap { [weak self] overview -> PieChartDataEntry? in
            guard let self = self else {return nil}
            return PieChartDataEntry(
                value: self.removeFormatString(string: overview.newCase),
                label: overview.countryName,
                data:  overview
            )
        }
        let dataSet = PieChartDataSet(entries: entries, label: "코로나 발생 현황")
        dataSet.sliceSpace = 1
        dataSet.entryLabelColor = .black
        dataSet.valueTextColor = .black
        dataSet.xValuePosition = .outsideSlice
        dataSet.valueLinePart1OffsetPercentage = 0.8
        dataSet.valueLinePart1Length = 0.2
        dataSet.valueLinePart2Length = 0.3
        
        dataSet.colors = ChartColorTemplates.vordiplom() +
        ChartColorTemplates.joyful() +
        ChartColorTemplates.liberty() +
        ChartColorTemplates.pastel() +
        ChartColorTemplates.material()
        
        self.pieChartView.data = PieChartData(dataSet: dataSet)
        self.pieChartView.spin(duration: 0.3, fromAngle: self.pieChartView.rotationAngle, toAngle: self.pieChartView.rotationAngle + 80)
    }
    
    func removeFormatString(string: String) -> Double {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: string)?.doubleValue ?? 0
    }
    
    func configureStackView(koreaCovidOverview: CovidOverview) {
        self.totalCaseLabel.text = "\(koreaCovidOverview.totalCase) 명"
        self.newCaseLabel.text = "\(koreaCovidOverview.newCase) 명"
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

extension ViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let covidDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: "CovidDetailViewController") as? CovidDetailViewController else { return }
        guard let covidOverView = entry.data as? CovidOverview else {return}
        covidDetailViewController.covidOverview = covidOverView
        self.navigationController?.pushViewController(covidDetailViewController, animated: true)
    }
}
