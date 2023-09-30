//
//  MuviPlayerViewController.swift
//  MUVI-iOS
//
//  Created by Dibyajyoti on 11/01/23.
//  Copyright © 2023 Muvi. All rights reserved.
//

import UIKit
import MuviPlayer
import MediaPlayer
import AVKit

protocol WatchPartyPlayerDelegate {

    func playerDidPlay()
    
    func playerDidPause()
    
    func playerDidChanged(currentTime: NSNumber)
    
    func playerDidEnd()
    
}

class MuviPlayerViewController: UIViewController, AVRoutePickerViewDelegate {
    
    var currentUser: User!

    static let shared = MuviPlayerViewController(nibName: "MuviPlayerViewController", bundle: nil)

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var playerViewContainer: UIView!
    
    @IBOutlet weak var contentOverlay: UIImageView!
    
    @IBOutlet weak var contentPoster: UIImageView!
    
    @IBOutlet weak var playButton: UIButton!
    
    var watchPartyDelegate: WatchPartyPlayerDelegate!
    
    var appD = UIApplication.shared.delegate as! AppDelegate
    
    var playerView = MuviPlayerView()
    
    /// Stores the selected index of resolution list
    var selectedResolutionIndex: Int = 0
    
    var currentAudioTrack: MuviPlayerMediaTrack?
    
    /// Store selected index of subtitle list, -1 for Off
    var selectedSubtitleIndex: Int = 0
    
    var initialPlayerHeight: CGFloat = UIScreen.main.bounds.height
    let scrnProtraitHeightConst: CGFloat = UIScreen.main.bounds.height
    let scrnProtraitWidthConst: CGFloat = UIScreen.main.bounds.width
    var isVideoVertical: Bool = false
    var isFullScreen: Bool = false
    var isComingFromPIP = false
    
    // Video log
    var isPlayerSeeking: Bool = false
    var callLogTimer: Timer!
    
    var startTime       = 0.0
    var endTime         = ""
    var contentTypesID  = ""
    var logID           = ""
    var logTempID       = ""
    var restrictStreamID = ""
    
    var isComingFromOffline = false
    var playerState: MuviPlayerState = .play
    var pollingType = "3"
    var pollingId = ""
    var optionId = ""
    var pollingExterlinkSelected = false
    var isAuthorized = 0
    var pollingViewWidth : CGFloat = 200
    var pollingViewHeight : CGFloat = 200
    var isCloseTapped = false
    var externalLinkClicked = false
    var playFromPIP:Bool!
    var playerSubView: MuviVideoPlayer?
    var playerSubItem: MuviPlayerItem?
    var fullscreensState = false
    var shouldPIPStop = false
    var playerVideoPlayed = Bool()
    var playerVideoBack = Bool()
    var playerStatus = ""
    var pipplayerstopped = Bool()
    var maximize_Player = false
    var playerActive = true
    var isComingFromWatchHistory = false
    var isAutoPlay = false
    var isTrailer = false
    var logoImage: UIImage?
    
    //MARK: Live Stream Content
    var liveStream: String?
    var enablePlaybackSpeedStatus = false
    
    var isPlaylist: Int = 0
    
    /// Gesture control : Player
    fileprivate var isVolumeControl : Bool = false
    
    fileprivate var sliderSeekTimeValue : TimeInterval = .nan
    var code: Int = 0
    
    var liveImageView = UIImageView()
    
    open lazy var volumeSlider : UISlider = {
        var slider = UISlider()
        let volumeView = MPVolumeView()
        if let view = volumeView.subviews.first as? UISlider {
            slider = view
        }
        return slider
    }()
    
    func initialPlayerSetup(isAutoplay : Bool = false) {
        var finalVideoURL: URL!
        finalVideoURL = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
        if let url =  finalVideoURL{
            let item = MuviPlayerItem(url: url)
            var playedLength : Double = 0.0
            let seekTime = CMTimeMake(value: Int64(playedLength), timescale: 1)
            if(seekTime == .zero){
                playerView.set(item: item, playerState: playerState)
            }
            else{
                playerView.set(item: item, seekTime: seekTime, playerState: playerState)
            }
        }
        
        playerView.controls?.playPauseButton?.activeImage = UIImage(named: "phoenix_pause")
        playerView.controls?.playPauseButton?.inactiveImage = UIImage(named: "phoenix_play")
        playerView.controls?.fullscreenButton?.activeImage = UIImage(named: "fullscreen_close")
        playerView.controls?.fullscreenButton?.inactiveImage = UIImage(named: "fullscreen1")
        
        if isAutoplay {
            isAutoPlay = true
            playerView.controls?.playPauseButton?.set(active: false)
        } else {
            playerView.controls?.playPauseButton?.set(active: true)
        }
        
        playerView.controls?.pipButton?.isHidden = true
        playerView.controls?.fullscreenButton?.isHidden = isTrailer ? true : false
        playerView.controls?.resolutionButton?.isHidden = true // (muviPlayerData?.licenseUrl != "" && (muviPlayerData?.videoResolution?.count == 0))
        playerView.controls?.subtitleButton?.isHidden = true // ((muviPlayerData?.subtitleData?.count) == 0)
        playerView.controls?.backButton?.isHidden = isTrailer || isFullScreen ? false : true
        playerView.controls?.backButton?.setImage(UIImage(named: "Icon_back"), for: .normal)
        
        playerView.enablePlaybackSpeed = true
        playerView.defaultPlayBackSpeed = 1
        playerView.resetPlayBackSpeed()
        
        playerView.controls?.multipleAudioButton?.isHidden = true
        playerView.controls?.forwardButton?.isHidden = isTrailer ? true : false
        playerView.controls?.rewindButton?.isHidden = isTrailer ? true : false
        playerView.controls?.forwardButton?.isEnabled = false
        playerView.controls?.rewindButton?.isEnabled = false
        playerView.controls?.seekbarSlider?.tintColor = UIColor.blue
        playerView.controls?.seekbarSlider?.minimumTrackTintColor = UIColor.blue
        playerView.controls?.seekbarSlider?.maximumTrackTintColor = UIColor.gray
        playerView.controls?.sliderThumbTintColor = UIColor.blue
        //playerView.controls?.seekbarSlider?.thumbTintColor = UIColor.buttonColor()
        //playerView.controls?.seekbarSlider?.setThumbImage(makeCircleWith(), for: .normal)
        //playerView.controls?.seekbarSlider?.setThumbImage(makeCircleWith(), for: .highlighted)
        
        playerView.playbackDelegate = self
        playerView.removeSubtitles()
        setupPlayerView()
        
        
        if isAutoplay {
            self.playerState = .pause
            self.playerView.player.pause()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.backgroundColor()
        playerView.frame = self.playerViewContainer.bounds
        playerView.backgroundColor = .black
        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerViewContainer.addSubview(playerView)
        playerViewContainer.backgroundColor = .black
        playerView.isHidden = true
        
        self.contentOverlay.tintColor = UIColor.backgroundColor()
        self.contentOverlay.isHidden = false
        self.playButton.backgroundColor = UIColor.buttonColor().withAlphaComponent(0.6)
        self.playButton.layer.cornerRadius = self.playButton.frame.height / 2
        self.playButton.layer.masksToBounds = true
        self.playButton.setImage(UIImage(named: "raidenPlayVector"), for: .normal)
        self.playButton.tintColor = UIColor.textColor()
        self.playButton.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
        
        let customBackButtonImage = UIImage(named: "chevron.backward")
        // Set the custom back button appearance
        self.navigationController?.navigationBar.backIndicatorImage = customBackButtonImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = customBackButtonImage
        self.navigationController?.navigationBar.tintColor = UIColor.textColor()
        
        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        playerView.subtitleFontColor = UIColor.white
        playerView.subtitleBackgroundColor = UIColor.black
        
        playerView.useMuviPlayerControls = true
        
        //  self.initialPlayerSetup()
        
       // setupPlayerView()
        self.setupTableView()
        
        /// Accessibility Tags for MuviPlayer SDK Components /////
        playerView.controls?.playPauseButton?.accessibilityIdentifier = "play"
        playerView.controls?.seekbarSlider?.accessibilityIdentifier = "progress_bar"
        playerView.controls?.fullscreenButton?.accessibilityIdentifier = "max_min"
        playerView.controls?.subtitleButton?.accessibilityIdentifier = "subtitle_button"
        playerView.controls?.resolutionButton?.accessibilityIdentifier = "resolution"
        playerView.controls?.airplayButton?.accessibilityIdentifier = "airplay"
        playerView.controls?.currentTimeLabel?.accessibilityIdentifier = "current_time"
        playerView.controls?.totalTimeLabel?.accessibilityIdentifier = "total_time"
        playerView.controls?.backButton?.accessibilityIdentifier = "back"
        playerView.waterMarkLabel.accessibilityIdentifier = "watermark"
        let rect = CGRect(
            origin: CGPoint(x: 0, y: 0),
            size: CGSize(width: 60,height: 60)
        )
        
        
        //        NotificationCenter.default.addObserver(self, selector: #selector(callPlayer), name: .playerIsReady, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(brightnessDidChange), name: UIScreen.brightnessDidChangeNotification, object: nil)
        
        //Add live icon to video player
        self.liveImageView = UIImageView(image: UIImage(named: "live"))
        self.liveImageView.semanticContentAttribute = .forceRightToLeft
        self.liveImageView.contentMode = .scaleAspectFill
        self.liveImageView.backgroundColor = .clear
        self.liveImageView.translatesAutoresizingMaskIntoConstraints = false
        playerView.addSubview(self.liveImageView)
        
        NSLayoutConstraint.activate([
            self.liveImageView.heightAnchor.constraint(equalToConstant: 25),
            self.liveImageView.widthAnchor.constraint(equalToConstant: 50),
            self.liveImageView.rightAnchor.constraint(equalTo: playerView.rightAnchor, constant: -8),
            self.liveImageView.topAnchor.constraint(equalTo: playerView.topAnchor, constant: 8)
        ])
        
        let customBackButton = UIBarButtonItem(image: UIImage(named: "back_icon"), style: .plain, target: self, action: #selector(customBackButtonTapped))
        navigationItem.leftBarButtonItem = customBackButton
    }
    
    @objc func customBackButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setupTableView(){
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 0))
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(UINib(nibName: "DetailsPageInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "DetailsPageInfoTableViewCell")
    }
    
    func setupPlayerView() {
        playerView.controls?.multipleAudioButton?.isHidden = true
        playerView.controls?.subtitleButton?.isHidden = true
        playerView.controls?.resolutionButton?.isHidden = true
        playerView.controls?.multipleAudioButton?.activeImage = UIImage(named: "player_headphone")
        playerView.controls?.backButton?.isHidden = isTrailer ? false : true
        playerView.controls?.backButton?.isHidden = !self.isFullScreen
        self.playerView.controls?.rewindButton?.isEnabled = false
        self.playerView.controls?.forwardButton?.isEnabled = false
        
        if playerState == .play{
            self.playerView.play()
        }else{
            self.playerView.pause()
        }
        if self.contentOverlay != nil {
            self.contentOverlay.tintColor = UIColor.backgroundColor()
            self.contentOverlay.contentMode = .scaleToFill
            self.contentPoster.contentMode = .scaleToFill
        }
    }
    
    func setupMuviPlayerViewDidLoad() {
        self.appD.restrictRotation = .portrait
        playerView.frame = self.playerViewContainer.bounds
        playerView.playbackDelegate = self
        playerView.controls?.playPauseButton?.set(active: true)
        playerView.controls?.pipButton?.isHidden = true
        playerView.controls?.fullscreenButton?.isHidden = true
        playerView.controls?.playBackSpeedButton?.isHidden = true
        playerView.controls?.resolutionButton?.isHidden = true // (muviPlayerData?.licenseUrl != "" && (muviPlayerData?.videoResolution?.count == 0))
        playerView.controls?.subtitleButton?.isHidden = true //((muviPlayerData?.subtitleData?.count) == 0
        playerView.controls?.airplayContainer?.isHidden = true
        playerView.controls?.multipleAudioButton?.isHidden = true
        playerView.controls?.forwardButton?.isHidden = false
        playerView.controls?.rewindButton?.isHidden = false
        playerView.controls?.seekbarSlider?.tintColor = UIColor.buttonColor()
        playerView.controls?.seekbarSlider?.minimumTrackTintColor = UIColor.buttonColor()
        playerView.controls?.seekbarSlider?.maximumTrackTintColor = UIColor.gray
        playerView.controls?.sliderThumbTintColor = UIColor.buttonColor()
     //   setupPlayerView()
        playerView.controls?.pollingCardButton.isHidden = true
        
    }
    
    fileprivate func setUpButtonStates() {
        self.playerView.controls?.forwardButton?.isEnabled = false
        self.playerView.controls?.rewindButton?.isEnabled = false
    }
    
    func initialSetup(isFromPIP: Bool = false) {
        if !isFromPIP {
            playerState = .play
        }
        
        
        var finalVideoURL: URL!
        
        finalVideoURL = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
        
        if let url =  finalVideoURL{
            let item = MuviPlayerItem(url: url)
            
            var playedLength = 0.0
            
            let seekTime = CMTimeMake(value: Int64(playedLength), timescale: 1)
            print("2#....\(seekTime)")
            
            if UserDefaults.standard.string(forKey: "resume_watch_last_seen_status") == "1"
                && self.playerStatus == "complete"{
                let totalVideoLength =  0
                let videolengthFromLastTenSec = totalVideoLength - 10
                
                isPlayerSeeking = true
                let seekTime = CMTimeMake(value: Int64(videolengthFromLastTenSec), timescale: 1)
                playerView.set(item: item, seekTime: seekTime, playerState: playerState)
                
            } else if((seekTime == .zero) || UserDefaults.standard.string(forKey: "resume_watch_status") == "0") && !isComingFromPIP {
                DispatchQueue.main.async {
                    self.playerView.set(item: item, playerState: self.playerState)
                }
            }
            else{
                DispatchQueue.main.async {
                    self.isPlayerSeeking = true
                    self.playerView.set(item: item, seekTime: seekTime, playerState: self.playerState)
                }
            }
        }
        shouldPIPStop = false
        if !isFromPIP {
            reInitializePlayerVariables()
        }
        
    }
    
    @objc func brightnessDidChange() {
        
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let interruptionTypeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeRawValue) else {
            return
        }
        
        switch interruptionType {
        case .began:
            if playerView.isPlaying {
                playerView.pause()
            }
            
        case .ended:
            print("player interrupted by call, ended")
        default:
            print("UNKNOWN")
        }
    }
    
    
    override func viewDidLayoutSubviews() {    }
    
    private func makeCircleWith(size: CGSize = CGSize(width: 10, height: 10), backgroundColor: UIColor = UIColor.blue) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(backgroundColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        let bounds = CGRect(origin: .zero, size: size)
        context?.addEllipse(in: bounds)
        context?.drawPath(using: .fill)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupMuviPlayerViewDidLoad()
        self.playerView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.isComingFromOffline{
            self.isFullScreen = true
            self.playerView.controls?.fullscreenButton?.isHidden = true
        }
    //    self.initializePlayer(isFromPIP: false, isPlay: false)
        self.playerView.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.isFullScreen = false
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        self.playerView.player.pause()
        self.playerView.isHidden = true
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool{
        if !isVideoVertical{
            return true
        }
        return false
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("Video Size: \(size)")
        
    }
    
    @objc func updateScreenOrientation(){
        if !isVideoVertical{
            
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeRight:
                print("Landscape Right")
                isFullScreen = true
                break;
            case .unknown:
                print("Unknown")
                break;
            case .portrait:
                print("Portrait")
                isFullScreen = false
                break;
            case .portraitUpsideDown:
                print("Portrait UpsideDown")
                isFullScreen = false
                break;
            case .landscapeLeft:
                print("Landscape Left")
                isFullScreen = true
                break;
            @unknown default:
                print("Default")
                isFullScreen = false
                break;
            }
            
            self.playerView.controls?.fullscreenButton?.set(active: isFullScreen)
        }
    }
    
    
    deinit{
        self.appD.restrictRotation = .portrait
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}

extension MuviPlayerViewController: MuviPlayerPlaybackDelegate {
   
    func playbackItemReady(player: MuviVideoPlayer, item: MuviPlayerItem?) {
        /**************************************Check current video is live/normal conten**t**************************************
        let currentVideoType = player.currentItem?.accessLog()?.events.last?.playbackType
        
        if currentVideoType == StreamingType.live_content.rawValue {
            print("live content")
        }
        else if currentVideoType == StreamingType.vod_content.rawValue {
            print("vod content")
        }
        else {
            print("other content")
        }
        */
        
        if isAutoPlay { //If the content plays again from begining, update playerstatus = "start"
            playerView.stopBuffering()
            isAutoPlay = false
            playerView.pause()
            playerStatus = "start"
        }
        else {
            playerView.play()
        }
        
        if playerVideoBack {
            return
        }
        
        playerVideoPlayed = true
        
      

        
        if !isFullScreen{
            let playerViewSize = item?.presentationSize ?? .zero
            if (playerViewSize.height > playerViewSize.width){
                
                self.isVideoVertical = true
                self.initialPlayerHeight = scrnProtraitHeightConst * 0.65
                self.appD.restrictRotation = .portrait
                
            }else{
                self.isVideoVertical = false
                self.initialPlayerHeight = scrnProtraitHeightConst * 0.35
                self.appD.restrictRotation = .portrait //.allButUpsideDown
            }
        }
        
        
        playerView.controls?.multipleAudioButton?.isHidden = !((item?.audioTracks.count ?? 0) > 1 )
        
        playerView.controls?.resolutionButton?.isHidden = true
        
        playerView.controls?.subtitleButton?.isHidden = true
        
        
        if self.currentAudioTrack != nil{
            guard let allTracks = item?.audioTracks else { return }
            for tracks in allTracks{
                if tracks.language == currentAudioTrack?.language{
                    item!.setMediaTrack(track: tracks)
                    return
                }
            }
        }
        
    
    }

    func backButtonAction(player: MuviVideoPlayer, item: MuviPlayerItem?) {
        
                dismiss(animated: true)
           
    }

    
    
    func postBackAction(player: MuviVideoPlayer, item: MuviPlayerItem?) {
        
    }

    func playbackDidEnd(player: MuviVideoPlayer, notification: Notification) {
        
    }
    
    func nextButtonAction(player: MuviVideoPlayer, item: MuviPlayerItem?) {
        
    }
    
    func previousButtonAction(player: MuviVideoPlayer, item: MuviPlayerItem?) {
        
    }
    
    func resolutionButtonAction(player: MuviVideoPlayer, item: MuviPlayerItem?) {
    }
    
    func subtitleButtonAction(player: MuviVideoPlayer, item: MuviPlayerItem?) {
      
    }

    func fullscreenButtonAction(player: MuviVideoPlayer, item: MuviPlayerItem?) {
        
    }
    
    func seekingDidStart(player: MuviVideoPlayer, item: MuviPlayerItem?) {
  
    }
    
    func seekingDidEnd(player: MuviVideoPlayer, item: MuviPlayerItem?) {
        if let currentTime = getSeekTime(from: item?.currentTime()) {
            watchPartyDelegate?.playerDidChanged(currentTime: currentTime)
        }
    }
    
    func togglePlayback(shouldPlay: Bool) {
        if shouldPlay { watchPartyDelegate?.playerDidPlay() }
        else { watchPartyDelegate?.playerDidPause() }
    }
    
    func multiAudioButton(player: MuviVideoPlayer, item: MuviPlayerItem?) {
        
        
    }
    func pollingCardButtonAction(player: MuviVideoPlayer, item: MuviPlayerItem?) {

        
    }
}

////--Anu
//extension Notification.Name {
//    static let playerIsReady = Notification.Name("playerisready")
//}

extension MuviPlayerViewController {
  func initializePlayer(isFromPIP: Bool = false, isPlay: Bool = true) {
      
        
        if !isFromPIP {
            playerState = .play
            // self.appD.playerState = self.playerState
        }

        
                
        var finalVideoURL: URL!
        finalVideoURL = URL(string: "https://d10xsoss226fg9.cloudfront.net/0BDsuAhWCYkJ8AOW9S8y8WPPjkIsR82G/3D28C83C85544F0D9517DD2E7C7EEDAA/vl/603e7fde0c0a48a2b780dfa25a1e37f9/John_Wick_Chapter_1____Full_Movie_Hindi_Dubbed-1690533227208.mp4")
        
        if let url =  finalVideoURL{
            let item = MuviPlayerItem(url: url)
        

            var playedLength = 0.0
            
            
            
            let seekTime = CMTimeMake(value: Int64(playedLength), timescale: 1)
            print("2#....\(seekTime)")

            if(seekTime == .zero){
                self.playerView.set(item: item, playerState: self.playerState)


            }
            else{
                self.playerView.set(item: item, seekTime: seekTime, playerState: self.playerState)

            }
            self.playerVideoBack = false

        }
        setupPlayerView()
        setupPictureInPicture()
        if !isFromPIP {
            reInitializePlayerVariables()
            playerView.enablePlaybackSpeed = enablePlaybackSpeedStatus
            playerView.defaultPlayBackSpeed = 1
            playerView.resetPlayBackSpeed()
        }
        
    }
    
    fileprivate func reInitializePlayerVariables(){
        
        
        
            selectedResolutionIndex = 0
        
        currentAudioTrack = nil
        selectedSubtitleIndex = 0
        isVideoVertical = false
        isFullScreen = self.isComingFromOffline ? true : false
        playerState = .play
        // self.appD.playerState = self.playerState
        playerView.removeSubtitles()
        self.logID           = ""
        self.logTempID       = ""
        self.restrictStreamID = ""
        
    }
}


extension MuviPlayerViewController: AVPictureInPictureControllerDelegate {
    
    func setupPictureInPicture() {
        print("---------setupPIP")
//        do{
//            try AVAudioSession.sharedInstance().setCategory(.playback)
//            try AVAudioSession.sharedInstance().setActive(true)
//        }catch{
//            print("AudioSessin Playback error occured")
//        }
//
//        // Ensure PiP is supported by current device.
//        if AVPictureInPictureController.isPictureInPictureSupported() {
//            // Create a new controller, passing the reference to the AVPlayerLayer.
//            self.appD.pictureInPictureController = AVPictureInPictureController(playerLayer: playerView.renderingView.playerLayer)
//            self.appD.pictureInPictureController.delegate = self
//        }
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
 
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
       
    }
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("---------pictureInPictureControllerWillStartPictureInPicture")
       
    }
        
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print("---------failedToStartPictureInPictureWithError", error)
        print(error)
    }
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.isComingFromPIP = false
//        if pipplayerstopped {
//            UIScreen.main.brightness = appD.playerBrightness
//            pipplayerstopped = false
//        }
//        else {
//            MuviPIPVideoPlayer.shared.destroy()
//            UIScreen.main.brightness = appD.deviceBrightness
//        }
    }
        
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        print("---------restoreUserInterfaceForPictureInPictureStopWithCompletionHandler")
       
            completionHandler(true)
        

    }
}

extension UINavigationController
{
    /// Given the kind of a (UIViewController subclass),
    /// removes any matching instances from self's
    /// viewControllers array.
    
    func removeAnyViewControllers(ofKind kind: AnyClass)
    {
        self.viewControllers = self.viewControllers.filter { !$0.isKind(of: kind)}
    }
    
    /// Given the kind of a (UIViewController subclass),
    /// returns true if self's viewControllers array contains at
    /// least one matching instance.
    
    func containsViewController(ofKind kind: AnyClass) -> Bool
    {
        return self.viewControllers.contains(where: { $0.isKind(of: kind) })
    }
}

extension MuviPlayerViewController : UITableViewDelegate, UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    1
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    1
  }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return self.configdetailsPageInfoCell(tableView, cellForRowAt: indexPath)
  }

  func configdetailsPageInfoCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> DetailsPageInfoTableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "DetailsPageInfoTableViewCell", for: indexPath) as! DetailsPageInfoTableViewCell
    cell.contentDesc.text = "With the untimely death of his beloved wife still bitter in his mouth, John Wick, the expert former assassin, receives one final gift from her–a precious keepsake to help John find a new meaning in life now that she is gone. But when the arrogant Russian mob prince, Iosef Tarasov, and his men pay Wick a rather unwelcome visit to rob him of his prized 1969 Mustang and his wife’s present, the legendary hitman will be forced to unearth his meticulously concealed identity.\nBlind with revenge, John will immediately unleash a carefully orchestrated maelstrom of destruction against the sophisticated kingpin, Viggo Tarasov, and his family, who are fully aware of his lethal capacity. Now, only blood can quench the boogeyman’s thirst for retribution."
    cell.contentDuration.text = "2h 13mins"
    cell.favBtn.isHidden = false
    cell.shareBtn.isHidden = false
    cell.plusBtn.isHidden = false
    cell.watchTrailerBtn.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
    cell.shareBtn.addTarget(self, action: #selector(createParty), for: .touchUpInside)
    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }

  @objc func playVideo(){
    self.playerView.isHidden = false
    self.playerView.player.play()
      self.initializePlayer(isFromPIP: false, isPlay: false)
  }
    
    @objc func createParty(){
        //Watch Party Here
        self.playerView.player.pause()
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc : ModalViewController = storyboard.instantiateViewController(withIdentifier: "ModalViewController") as! ModalViewController
        vc.delegate = self
        vc.modalPresentationStyle = .automatic
        self.navigationController?.present(vc, animated: true)
    }
    
}

extension MuviPlayerViewController : modalViewPresent {
    
    func disminssCurrentVC(isDisMiss: Bool, partyType: Int) {
        if isDisMiss {
            if partyType == 0 {
                self.goToCreatePartyVC(partyType: 0)
            } else {
                self.goToCreatePartyVC(partyType: 1)
            }
        }
    }
    
    func goToCreatePartyVC(partyType: Int){
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc : CreatePartyViewController = storyboard.instantiateViewController(withIdentifier: "CreatePartyViewController") as! CreatePartyViewController
        vc.partyType = partyType
        vc.currentUser = currentUser
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
