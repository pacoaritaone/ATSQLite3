//
//  ATSQLiteLog.swift
//  ATSqlite
//
//  Created by Pacoyeung on 3/18/18.
//  Copyright © 2018 Pacoyeung. All rights reserved.
//

import Foundation

public enum Log:Int{
    case record
    case debug
    case err
    case warn
}

public func ATSQLiteLog(_ type:Log,_ logStr:String,_ file:String? = #file,_ function:String? = #function,_ line:Int? = #line)
{
    #if !DEBUG
        if(type == Log.debug)
        {
            return
        }
    #endif
    
    var logo = ""
    
    switch (type) {
    case .debug:
        logo = "📱"
        break
    case .record:
        logo = "📝"
        break
    case .warn:
        logo = "⚠️"
        break;
    case .err:
        logo = "🚫"
        break
    }
    
    NSLog(logo+"%@ %@ at line:%d ~>\n%@", URL(string: file!)!.lastPathComponent, function!, line!, logStr)
}
