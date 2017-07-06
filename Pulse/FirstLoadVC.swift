//
//  FirstLoadVC.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/15/17.
//  Copyright © 2017 Think Apart. All rights reserved.
//

import UIKit

class FirstLoadVC: UIViewController {
    
    internal var getStartedButton = PulseButton(title: "get started", isRound: false)
    internal var loginButton = UIButton()
    
    internal var logo : UIImageView! = UIImageView()
    internal var logoText : UIImageView! = UIImageView()
    
    internal var collectionView : UICollectionView!
    internal let reuseIdentifier = "firstLoadCell"
    
    fileprivate let screenTitles = ["Welcome to Pulse!",
                                    "Content That Matters",
                                    "Voices That Matter",
                                    "Create What Matters"]
    fileprivate let imageDescriptions = ["",
                                         "Pulse Channel: 'The Valley'",
                                         "Pulse Experts",
                                         "Pulse Formats"]
    fileprivate let screenDescriptions = ["home to things that matter",
                                          "discover intelligent & interactive \nprofessional content, series & channels",
                                          "exclusive access to expert voices\n& a platform to showcase\nyour professional expertise",
                                          "bold new formats & experiences\ncreate, collaborate & contribute"]
    fileprivate let imageNames = ["launch_screen_0",
                                  "launch_screen_1",
                                  "launch_screen_2",
                                  "launch_screen_3"]
                              
    public var introDelegate : FirstLaunchDelegate!
    internal var pagersStack = UIStackView()
    fileprivate var cleanupComplete = false
    
    internal var centerIndex : Int = 0 {
        didSet {
            updateSelectedPager(num: centerIndex)
        }
    }
    
    internal var contentOffset: CGFloat {
        return collectionView.contentOffset.x + collectionView.contentInset.left
    }
    
    deinit {
        performCleanup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        addLogo()
        addButtons()
        setupPagers()
        
        view.backgroundColor = .white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    internal func addPagers(num: Int) {
        for _ in 1...num {
            let _pager = UIView()
            _pager.translatesAutoresizingMaskIntoConstraints = false
            _pager.heightAnchor.constraint(equalTo: _pager.widthAnchor).isActive = true
            _pager.backgroundColor = .pulseGrey
            
            pagersStack.addArrangedSubview(_pager)
            
            _pager.layoutIfNeeded()
            _pager.layer.cornerRadius = _pager.frame.width / 2
            _pager.layer.masksToBounds = true
        }
    }
    
    internal func performCleanup() {
        if !cleanupComplete {
            collectionView = nil
            introDelegate = nil
            pagersStack.removeFromSuperview()
            getStartedButton.removeFromSuperview()
            cleanupComplete = true
        }
    }
    
    internal func updateSelectedPager(num: Int) {
        pagersStack.arrangedSubviews[num].backgroundColor = .pulseBlue
        
        for (index, _) in pagersStack.arrangedSubviews.enumerated() {
            if index == num {
                pagersStack.arrangedSubviews[index].backgroundColor = .pulseBlue
            } else {
                pagersStack.arrangedSubviews[index].backgroundColor = .pulseGrey
            }
        }
    }

    internal func buttonPressed(sender: UIButton) {
        if sender == loginButton {
            introDelegate.doneWithIntro(mode: .login)
            dismiss(animated: true, completion: {[weak self] _ in
                guard let `self` = self else { return }
                self.performCleanup()
            })
        } else if sender == getStartedButton {
            introDelegate.doneWithIntro(mode: .other)
            dismiss(animated: true, completion: {[weak self] _ in
                guard let `self` = self else { return }
                self.performCleanup()
            })
        }
    }
    
    func setupCollectionView() {
        let collectionViewFrame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        //        layout.itemSize = CGSize(width: self.bounds.width, height: self.bounds.height)
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        
        collectionView = UICollectionView(frame: collectionViewFrame, collectionViewLayout: layout)
        collectionView.register(PulseIntroCell.self, forCellWithReuseIdentifier: self.reuseIdentifier)
        collectionView.backgroundColor = UIColor.clear

        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.canCancelContentTouches = true
        
        collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        view.addSubview(collectionView)
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    fileprivate func addLogo() {
        view.addSubview(logo)
        view.addSubview(logoText)
        
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.xs.rawValue).isActive = true
        logo.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xs.rawValue).isActive = true
        logo.heightAnchor.constraint(equalToConstant: IconSizes.xSmall.rawValue).isActive = true
        logo.layoutIfNeeded()
        
        logoText.translatesAutoresizingMaskIntoConstraints = false
        logoText.centerYAnchor.constraint(equalTo: logo.centerYAnchor).isActive = true
        logoText.leadingAnchor.constraint(equalTo: logo.trailingAnchor, constant: Spacing.xxs.rawValue).isActive = true
        logoText.heightAnchor.constraint(equalToConstant: IconSizes.xxSmall.rawValue).isActive = true
        logoText.widthAnchor.constraint(equalToConstant: IconSizes.medium.rawValue).isActive = true
        logoText.layoutIfNeeded()
        
        logo.contentMode = .scaleAspectFit
        logoText.contentMode = .scaleAspectFit
        logo.image = UIImage(named: "pulse-logo")
        logoText.image = UIImage(named: "pulse-logo-text")
        logoText.tintColor = .black
    }
    
    fileprivate func addButtons() {
        view.addSubview(getStartedButton)
        view.addSubview(loginButton)
        
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false
        getStartedButton.bottomAnchor.constraint(equalTo: loginButton.topAnchor, constant: -Spacing.xs.rawValue).isActive = true
        getStartedButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        getStartedButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        getStartedButton.heightAnchor.constraint(equalToConstant: PulseButton.regularButtonHeight).isActive = true
        getStartedButton.layoutIfNeeded()
        
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.max.rawValue).isActive = true
        loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
        loginButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/20).isActive = true
        loginButton.layoutIfNeeded()
        
        getStartedButton.makeRound()
        loginButton.makeRound()
        
        getStartedButton.removeShadow()
        getStartedButton.backgroundColor = .pulseRed
        
        getStartedButton.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightMedium, color: .white, alignment: .center)
        loginButton.setButtonFont(FontSizes.body2.rawValue, weight: UIFontWeightRegular, color: .gray, alignment: .center)
        
        loginButton.backgroundColor = .clear
        loginButton.setTitle("login or create account", for: .normal)
        
        getStartedButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }
    
    fileprivate func setupPagers() {
        view.addSubview(pagersStack)
        
        pagersStack.translatesAutoresizingMaskIntoConstraints = false
        pagersStack.heightAnchor.constraint(equalToConstant: 7.5).isActive = true
        pagersStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Spacing.xl.rawValue).isActive = true
        pagersStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        pagersStack.axis = .horizontal
        pagersStack.distribution = .fillEqually
        pagersStack.spacing = Spacing.xs.rawValue
        
        addPagers(num: screenTitles.count)
        updateSelectedPager(num: 0)
    }
}

extension FirstLoadVC: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return screenTitles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PulseIntroCell
        let index = indexPath.row
        cell.setScreenItems(title: screenTitles[index],
                            imageDescription: imageDescriptions[index],
                            screenDescription: screenDescriptions[index],
                            imageName: imageNames[index])
                
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        centerIndex = Int(contentOffset / view.frame.width)
    }
}
