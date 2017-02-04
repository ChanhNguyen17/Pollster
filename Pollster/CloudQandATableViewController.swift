//
//  CloudQandATableViewController.swift
//  Pollster
//
//  Created by Chanh Nguyen on 2/4/17.
//  Copyright © 2017 Stanford University. All rights reserved.
//

import UIKit
import CloudKit

class CloudQandATableViewController: QandATableViewController {
    
    var ckQandARecord: CKRecord {
        get {
            if _ckQandARecord == nil {
                _ckQandARecord = CKRecord(recordType: Cloud.Entity.QandA)
            }
            return _ckQandARecord!
        }
        set {
            _ckQandARecord = newValue
        }
    }
    
    private var _ckQandARecord: CKRecord? {
        didSet {
            let question = ckQandARecord[Cloud.Attribute.Question] as? String ?? ""
            let answers = ckQandARecord[Cloud.Attribute.Answers] as? [String] ?? []
            qanda = QandA(question: question, answers: answers)
            
            asking = ckQandARecord.wasCreatedByThisUser
        }
    }
    
    private let database = CKContainer.default().publicCloudDatabase
    
    @objc private func iCloudUpdate() {
        if !qanda.question.isEmpty && !qanda.answers.isEmpty {
            ckQandARecord[Cloud.Attribute.Question] = qanda.question as CKRecordValue?
            ckQandARecord[Cloud.Attribute.Answers] = qanda.answers as CKRecordValue?
            iCloudSaveRecord(ckQandARecord)
        }
    }
    
    private func iCloudSaveRecord(_ recordToSave: CKRecord) {
        database.save(
            recordToSave,
            completionHandler: {(savedRecord, error) in
                if error?._code == CKError.serverRecordChanged.rawValue {
                    // ignore
                } else if error != nil {
                    self.retryAfterError(error as NSError?, withSelector: #selector(self.iCloudUpdate))
                }
            }
        )
    }
    
    private func retryAfterError(_ error: NSError?, withSelector selector: Selector) {
        if let retryInterval = error?.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
            DispatchQueue.main.async {
                Timer.scheduledTimer(
                    timeInterval: retryInterval,
                    target: self,
                    selector: selector,
                    userInfo: nil,
                    repeats: false
                )
            }
        }
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        iCloudUpdate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ckQandARecord = CKRecord(recordType: Cloud.Entity.QandA)
    }
}
