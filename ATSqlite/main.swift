//
//  main.swift
//  ATSqlite
//
//  Created by Pacoyeung on 3/16/18.
//  Copyright © 2018 Pacoyeung. All rights reserved.
//

import Foundation


let oq = OperationQueue()
oq.maxConcurrentOperationCount = 1

let ds = DispatchSemaphore(value: 0)

oq.addOperation {
    ds.wait()
}

let createTable = {
    let query = GenericQuery(query: """
    CREATE TABLE IF NOT EXISTS student (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT,
    age INTEGER,
    gender TEXT CHECK( gender IN ('M','F'))
    )
    """)
    
    let result = ATSQLiteManager.shared.executeQuery(query: query)
}

let insertTable = {
    let query = InsertQuery(table: "student", attributes: ["name","age","gender"], values: ["paco","11","M"])
    let result = ATSQLiteManager.shared.executeQuery(query: query!)
}

let selectTable = {
    let query = SelectQuery(table: "student", constraint: nil, attributes: nil)
    let result = ATSQLiteManager.shared.executeQuery(query: query)
    NSLog("%@", result.resultSet!)
}

let transaction = {
    ATSQLiteManager.shared.executeTransactionQueryBlock({ () -> (ATSQLiteError?) in
        let query = InsertQuery(table: "student", attributes: ["name","age","gender"], values: ["paco","11","F"])
        let result = ATSQLiteManager.shared.executeQuery(query: query!)
        if result.errNum != nil { return result.errNum}
        return ATSQLiteError.GG
    })
}


//oq.addOperation(transaction)
oq.addOperation(selectTable)

ds.signal()

CFRunLoopRun()




