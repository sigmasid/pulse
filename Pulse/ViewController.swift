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
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func loadQuestions(sender: UIButton) {
        let politicalQuestions = loadPoliticalQuestions()
        let startupQuestions = loadStartupQuestions()
        let questionPath = databaseRef.child("questions")
        
        for question in politicalQuestions {
            let questionPost = questionPath.childByAutoId()
            questionPost.setValue(question)
            let questionID = questionPost.key
            politicalQuestionsID.append(questionID)
        }
        for question in startupQuestions {
            let questionPost = questionPath.childByAutoId()
            questionPost.setValue(question)
            let questionID = questionPost.key
            startupQuestionsID.append(questionID)
        }
    }
    
    
    @IBAction func loadTags(sender: UIButton) {
        let tags = ["politics", "startups"]
        let topicsPath = databaseRef.child("tags")
        
        for tag in tags {
            let tagPath = topicsPath.child(tag).child("questions")
            for question in loadQuestionIDs(tag) {
                let postPath = tagPath.child(question)
                postPath.setValue(true)
            }
        }
    }
    
    func loadPoliticalQuestions() -> [NSObject] {
        let q1 = ["title": "I support ","tags": ["politics" : true], "choices": ["hillary" : true,"trump" : true]]
        let q2 = ["title": "My most important issue this election season is ", "tags": ["politics" : true], "choices": ["national security" : true,"immigration" : true,"economy" : true,"other" : true]]
        let q3 = ["title": "I am ", "tags": ["politics" : true], "choices": ["in favor of" : true,"against" : true]]
        let q4 = ["title": "I am ", "tags": ["politics" : true], "choices": ["in favor of" : true,"against" : true]]
        let q5 = ["title": "Homeless in San Francisco", "tags": ["politics" : true], "choices": ["support" : true,"against" : true]]
        let q6 = ["title": "Should the minimum wage be raised to $15 per hour ", "tags": ["politics" : true], "choices": ["yes" : true,"no" : true]]
        
        return [q1, q2, q3, q4, q5, q6]
    }
    
    func loadStartupQuestions() -> [NSObject] {
        let q1 = ["title": "The hardest part of being an entreprenuer is ", "tags": ["politics" : true], "choices": ["hillary" : true,"trump" : true]]
        let q2 = ["title": "The best advice I ever got was ", "tags": ["politics" : true]]
        let q3 = ["title": "My favorite question to ask in an interview is ", "tags": ["politics" : true], "choices": ["in favor of" : true,"against" : true]]
        let q4 = ["title": "Do you need a co-founder ", "tags": ["politics" : true], "choices": ["yes" : true,"maybe" : true,"no" : true]]
        let q5 = ["title": "What keeps me up at night ", "tags": ["startups" : true]]
        let q6 = ["title": "Best advice for pitching VCs ", "tags": ["startups" : true]]
        let q7 = ["title": "What I get really down I ", "tags": ["startups" : true]]
        return [q1, q2, q3, q4, q5, q6, q7]
    }
    
    func loadQuestionIDs(tagName: String) -> [String] {
        switch tagName {
        case "politics": return politicalQuestionsID
        case "startups": return startupQuestionsID
        default : return [""]
        }
    }
}

