//
//  ViewController.swift
//  Pulse
//
//  Created by Sidharth Tiwari on 6/29/16.
//  Copyright © 2016 Think Apart. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ViewController: UIViewController {

    var politicalQuestionsID : [String] = []
    var startupQuestionsID : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _answersFilters = FiltersOverlay(frame: self.view.frame)
        self.view.addSubview(_answersFilters)
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func loadQuestions(sender: UIButton) {
        for _ in 0...5 {
            let questionPost = databaseRef.child("filters").childByAutoId()
            questionPost.setValue("true")
        }
//        let politicalQuestions = loadPoliticalQuestions()
//        let startupQuestions = loadStartupQuestions()
//        let questionPath = databaseRef.child("questions")
//        
//        for question in politicalQuestions {
//            let questionPost = questionPath.childByAutoId()
//            questionPost.setValue(question)
//            let questionID = questionPost.key
//            politicalQuestionsID.append(questionID)
//        }
//        for question in startupQuestions {
//            let questionPost = questionPath.childByAutoId()
//            questionPost.setValue("true")
//            let questionID = questionPost.key
//            startupQuestionsID.append(questionID)
//        }
    }
    
    
    @IBAction func loadTags(sender: UIButton) {
//        let tags = ["relationships", "finance"]
//        let topicsPath = databaseRef.child("tags")
//        
//        for tag in tags {
//            let tagPath = topicsPath.child(tag).child("questions")
//            for question in loadQuestionIDs(tag) {
//                let postPath = tagPath.child(question)
//                postPath.setValue(true)
//            }
//        }
    }
    
//    func loadPoliticalQuestions() -> [NSObject] {
//        let q1 = ["title": "Worst Tinder dates ","tags": ["relationships" : true]]
//        let q2 = ["title": "Getting through a divorce ", "tags": ["relationships" : true]]
//        let q3 = ["title": "Who should pay on a first date ", "tags": ["relationships" : true], "choices": ["the guy" : true,"split it" : true, "the girl" : true]]
//        let q4 = ["title": "First date ideas ", "tags": ["relationships" : true]]
//        let q5 = ["title": "What's the most important quality in a guy", "tags": ["relationships" : true], "choices": ["funny" : true,"intelligent" : true,"good looking" : true,"rich" : true]]
//        let q6 = ["title": "What I didn't know about moving in together ", "tags": ["relationships" : true]]
//        let q7 = ["title": "Breaking up after a long relationship ","tags": ["relationships" : true], "choices": ["hillary" : true,"trump" : true]]
//        let q8 = ["title": "What she's thinking when she says it's okay ", "tags": ["relationships" : true]]
//        let q9 = ["title": "What do men look for in a tinder profile ", "tags": ["relationships" : true]]
//        let q10 = ["title": "Coming out to my parents ", "tags": ["relationships" : true]]
//        let q11 = ["title": "Being single ", "tags": ["relationships" : true], "choices": ["love it" : true,"hate it" : true]]
//        let q12 = ["title": "Would you take someone back if they cheated on you ", "tags": ["relationships" : true], "choices": ["yes" : true,"no" : true]]
//        
//        return [q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12]
//    }
//    
//    func loadStartupQuestions() -> [NSObject] {
//        let q1 = ["title": "What impact will Brexit have on startups ", "tags": ["finance" : true], "choices": ["big" : true,"very little" : true,"too early to tell" : true]]
//        let q2 = ["title": "Who should Yahoo sell to ", "tags": ["finance" : true]]
//        let q3 = ["title": "Where are oil prices headed", "tags": ["finance" : true], "choices": ["higher" : true,"lower" : true,"flat" : true]]
//        let q4 = ["title": "Top investment idea for 2H 2016", "tags": ["finance" : true]]
//        let q5 = ["title": "When will the Fed raise rates", "tags": ["finance" : true], "choices": ["sep" : true,"dec" : true,"next year" : true]]
//        let q6 = ["title": "How is the Tech IPO market doing", "tags": ["finance" : true]]
//        let q7 = ["title": "Can oil prices keep rising", "tags": ["finance" : true]]
//        let q8 = ["title": "Is gold a good investment today", "tags": ["finance" : true], "choices": ["yes" : true,"no" : true]]
//        return [q1, q2, q3, q4, q5, q6, q7, q8]
//    }
//    
//    func loadQuestionIDs(tagName: String) -> [String] {
//        switch tagName {
//        case "relationships": return politicalQuestionsID
//        case "finance": return startupQuestionsID
//        default : return [""]
//        }
//    }
}

