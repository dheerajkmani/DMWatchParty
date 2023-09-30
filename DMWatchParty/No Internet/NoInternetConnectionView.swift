//
//  NoInternetConnectionView.swift
//  Vishwam.tv
//
//  Created by Muvi on 12/12/18.
//  Copyright © 2018 Muvi. All rights reserved.
//

import UIKit
import Network
class NoInternetConnectionView: UIView, NetworkCheckObserver{
   
    

    //Test
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet var mainView: UIView!
    
    @IBOutlet weak var noInternetView: UIImageView!
    public var delegate: NoInternetConnectionViewDelegate?
    
    /// It is used to check Internet Connectivity.
    let reachability = Reachability()!
    let queue = DispatchQueue(label: "Monitor")
    let appD = UIApplication.shared.delegate as! AppDelegate
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        initialSetUp()
    }
    
    func initialSetUp(){
        
        setUpUI()
        startReachability()
        
    }
    
    func startReachability(){
        if #available(iOS 12.0, *){
            let mon: NWPathMonitor = NWPathMonitor()
            mon.pathUpdateHandler = {
                p in
                DispatchQueue.main.async {
                    switch p.status{
                    case .satisfied:
                        if mon.currentPath.usesInterfaceType(.cellular){
                            self.delegate?.getInternetStatus(status: .cellular, isInternetAvailable: true)
                        }else if mon.currentPath.usesInterfaceType(.wifi){
                            self.delegate?.getInternetStatus(status: .wifi, isInternetAvailable: true)
                        }else{
                            //change according to your requirement
                            self.delegate?.getInternetStatus(status: .wifi, isInternetAvailable: true)
                        }
                        break
                    case .requiresConnection:
                        self.appD.isReadyToCast = false
                        self.delegate?.getInternetStatus(status: .none, isInternetAvailable: false)
                    case .unsatisfied:
                        self.appD.isReadyToCast = false
                        self.delegate?.getInternetStatus(status: .none, isInternetAvailable: false)
                    default:
                        self.appD.isReadyToCast = false
                        self.delegate?.getInternetStatus(status: .none, isInternetAvailable: false)
                    }
                }
            }
            mon.start(queue: self.queue)
        }else{
            NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(notification:)), name: .reachabilityChanged, object: reachability)
            do{
                try reachability.startNotifier()
            }catch{
                print("could not start reachability notifier")
            }
        }
    }
    
    @available(iOS 12.0, *)
    func statusDidChange(status: NWPath.Status) {
        if status == .satisfied {
            delegate?.getInternetStatus(status: .wifi, isInternetAvailable: true)
        }else if status == .unsatisfied {
            delegate?.getInternetStatus(status: .wifi, isInternetAvailable: false)
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpUI(){
        Bundle.main.loadNibNamed("NoInternetConnectionView", owner: self, options: nil)
        addSubview(mainView)
        mainView.frame = self.bounds
        mainView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.mainView.backgroundColor = UIColor.appbackgroundColor()
       
        self.noInternetView.image = UIImage(named: "no-internet")
        self.noInternetView.tintColor = UIColor.textColor()
        
        self.retryButton.setTitle(UserDefaults.standard.string(forKey: "try_again") ?? "Retry", for: .normal)
        self.retryButton.setTitleColor(UIColor.buttonColor(), for: .normal)
        self.retryButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        self.retryButton.titleLabel?.font = UIFont.btnTitleLabel()
        self.retryButton.layer.borderWidth = 1.25
        self.retryButton.layer.borderColor = UIColor.buttonColor().cgColor
        self.retryButton.layer.cornerRadius = self.appD.cornerRadius
        self.retryButton.clipsToBounds = true
        
        self.headerLabel.text = UserDefaults.standard.string(forKey: "oops") ?? "Oops!"
        self.headerLabel.textColor = UIColor.buttonColor()
        self.headerLabel.font = UIFont.lblHeader().withSize(20)
        self.headerLabel.backgroundColor = .clear
        
        self.bodyLabel.text = UserDefaults.standard.string(forKey: "no_internet_connection") ?? "No Internet Connection"
        self.bodyLabel.numberOfLines = 0
        self.bodyLabel.textAlignment = .center
        self.bodyLabel.textColor = UIColor.textColor()
        self.bodyLabel.font = UIFont.lblNormal().withSize(14)
        self.bodyLabel.backgroundColor = .clear
        self.retryButton.addTarget(self, action: #selector(self.retryButtonAction(sender:)), for: .touchUpInside)
    }
    
    @objc func retryButtonAction(sender: UIButton){
        delegate?.refreshCurrentViewController(sender: sender)
    }
    
    deinit {
        reachability.stopNotifier()
        
    }
    /// This function is used to check the internet connectivity each time.
    ///
    /// - Parameter notification: NSNotification
    @objc func reachabilityChanged(notification: Notification) {
        
        let reachability = notification.object as! Reachability
        
        switch reachability.connection {
        case .wifi:
            delegate?.getInternetStatus(status: .wifi, isInternetAvailable: true)
        case .cellular:
            delegate?.getInternetStatus(status: .cellular, isInternetAvailable: true)
        case .none:
            delegate?.getInternetStatus(status: .none, isInternetAvailable: false)
            self.appD.isReadyToCast = false
        }
    }
    
    
}

/// It holds the delegate methods for no interent connection
protocol NoInternetConnectionViewDelegate {
    
    /// It is used to handle the retry button Action.
    func refreshCurrentViewController(sender: UIButton)
    
    /// It returns the current internet status with internet source
    ///
    /// - Parameters:
    ///   - status: It returns the internet connection source
    ///   - isInternetAvailable: It returns true or false according to the availability of intrenet connection
    func getInternetStatus(status: ConnectivityType, isInternetAvailable: Bool)
}

/// It is used to hold the connection type for Internet Connection
///
/// - none: It represents the no internet source
/// - wifi: It represents the internet source as WIFI
/// - cellular: It represents the internet source as Mobile Network
public enum ConnectivityType{
    case none, wifi, cellular
}
