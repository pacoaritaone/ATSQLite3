//
//  main.swift
//  ATSqlite
//
//  Created by Pacoyeung on 3/16/18.
//  Copyright © 2018 Pacoyeung. All rights reserved.
//

import Foundation

let createTable = {
    let query = GenericQuery(query: """
    CREATE TABLE IF NOT EXISTS student (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT,
    age INTEGER,
    gender TEXT CHECK( gender IN ('M','F'))
    )
    """)
    
    _ = ATSQLiteManager.shared.executeQuery(query: query)
}

let insertTable = {
    let query = InsertQuery(table: "student", attributes: ["name","age","gender"], values: ["paco","11","M"])
    _ = ATSQLiteManager.shared.executeQuery(query: query!)
}

let selectTable = {
    let query = SelectQuery(table: "student", constraint: nil, attributes: nil)
    let result = ATSQLiteManager.shared.executeQuery(query: query)
    NSLog("%@", result.resultSet!)
}

let transactionCommit = {
    ATSQLiteManager.shared.executeTransactionQueryBlock({ () -> (Bool?) in
        let query = InsertQuery(table: "student", attributes: ["name","age","gender"], values: ["paco","11","F"])
        _ = ATSQLiteManager.shared.executeQuery(query: query!)
        //if result.errNum != nil { err = true; return err}
        return false
    })
}

let transactionRollBack = {
    ATSQLiteManager.shared.executeTransactionQueryBlock({ () -> (Bool?) in
        let query = InsertQuery(table: "student", attributes: ["name","age","gender"], values: ["paco","22","F"])
        _ = ATSQLiteManager.shared.executeQuery(query: query!)
        //if result.errNum != nil { err = true; return err}
        return true
    })
}

let dropTable = {
    let query = GenericQuery(query: "DROP TABLE IF EXISTS student")
    _ = ATSQLiteManager.shared.executeQuery(query: query)
    
}

func main()
{
    
    dropTable()
    createTable()
    
    let oq = OperationQueue()
    oq.maxConcurrentOperationCount = 5
    
    oq.isSuspended = true
    oq.waitUntilAllOperationsAreFinished()
    
    for _ in 0..<10
    {
        oq.addOperation(transactionCommit)
        oq.addOperation(transactionRollBack)
    }
    
    oq.isSuspended = false
    
    DispatchQueue.main.async {
        sleep(5)
        selectTable()
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
}

main()

CFRunLoopRun()




