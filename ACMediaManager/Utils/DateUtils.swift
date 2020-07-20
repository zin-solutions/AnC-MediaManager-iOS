//
//  DateUtils.swift
//  ACMediaManager
//
//  Created by Hussein AlMawla on 7/15/20.
//  Copyright © 2020 Arts'n'Code. All rights reserved.
//

import Foundation

class DateUtils{
    public static func getCurrentTimeStampWOMiliseconds(dateToConvert: Date) -> String {
        let objDateformat: DateFormatter = DateFormatter()
        objDateformat.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let strTime: String = objDateformat.string(from: dateToConvert as Date)
        let objUTCDate: NSDate = objDateformat.date(from: strTime)! as NSDate
        let milliseconds: Int64 = Int64(objUTCDate.timeIntervalSince1970)
        let strTimeStamp: String = "\(milliseconds)"
        return strTimeStamp
    }
}
