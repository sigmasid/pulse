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
        let tags = ["relationships", "careers"]
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
        let q1 = ["title": "Worst Tinder date stories ","tags": ["relationships" : true]]
        let q2 = ["title": "Should ", "tags": ["relationships" : true], "choices": ["national security" : true,"immigration" : true,"economy" : true,"other" : true]]
        let q3 = ["title": "Gun control debate ", "tags": ["relationships" : true], "choices": ["in favor of" : true,"against" : true]]
        let q4 = ["title": "Obesity epedemic in America ", "tags": ["relationships" : true], "choices": ["in favor of" : true,"against" : true]]
        let q5 = ["title": "I support Trump ", "tags": ["relationships" : true], "choices": ["support" : true,"against" : true]]
        let q6 = ["title": "Jerry Brown and gun control ", "tags": ["relationships" : true], "choices": ["yes" : true,"no" : true]]
        let q7 = ["title": "I support EU exit ","tags": ["relationships" : true], "choices": ["hillary" : true,"trump" : true]]
        let q8 = ["title": "Migration crisis ", "tags": ["relationships" : true], "choices": ["national security" : true,"immigration" : true,"economy" : true,"other" : true]]
        let q9 = ["title": "I am a refugee ", "tags": ["relationships" : true], "choices": ["in favor of" : true,"against" : true]]
        let q10 = ["title": "Driving change through Politics ", "tags": ["relationships" : true], "choices": ["in favor of" : true,"against" : true]]
        let q11 = ["title": "I support Hillary ", "tags": ["relationships" : true], "choices": ["support" : true,"against" : true]]
        let q12 = ["title": "Why elections matter ", "tags": ["relationships" : true], "choices": ["yes" : true,"no" : true]]
        let q13 = ["title": "Fourth of July stories ","tags": ["relationships" : true], "choices": ["hillary" : true,"trump" : true]]
        let q14 = ["title": "Should we send trooops to Syria ", "tags": ["relationships" : true], "choices": ["national security" : true,"immigration" : true,"economy" : true,"other" : true]]
        let q15 = ["title": "Fighting ISIS ", "tags": ["relationships" : true], "choices": ["in favor of" : true,"against" : true]]
        let q16 = ["title": "I am an illegal immigrant ", "tags": ["relationships" : true], "choices": ["in favor of" : true,"against" : true]]
        let q17 = ["title": "I support Obama on immigration ", "tags": ["relationships" : true], "choices": ["support" : true,"against" : true]]
        let q18 = ["title": "Should we build a wall ", "tags": ["relationships" : true], "choices": ["yes" : true,"no" : true]]
        let q19 = ["title": "I support NATO ","tags": ["relationships" : true], "choices": ["hillary" : true,"trump" : true]]
        let q20 = ["title": "Meet the chinese entrepreneurs ", "tags": ["relationships" : true], "choices": ["national security" : true,"immigration" : true,"economy" : true,"other" : true]]
        let q21 = ["title": "Do you support universal ", "tags": ["relationships" : true], "choices": ["in favor of" : true,"against" : true]]
        let q22 = ["title": "Obesity epedemic in America ", "tags": ["relationships" : true], "choices": ["in favor of" : true,"against" : true]]
        let q23 = ["title": "I support Trump ", "tags": ["relationships" : true], "choices": ["support" : true,"against" : true]]
        let q24 = ["title": "Jerry Brown and gun control ", "tags": ["relationships" : true], "choices": ["yes" : true,"no" : true]]
        
        return [q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19, q20, q21, q22, q23, q24]
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

