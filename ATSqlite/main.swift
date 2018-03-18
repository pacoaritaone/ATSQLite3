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

let transactionCommit = { (idx:Int) in
    ATSQLiteManager.shared.executeTransactionQueryBlock({ () -> (Bool?) in
        let query = InsertQuery(table: "student", attributes: ["name","age","gender"], values: ["paco\(idx)","11","F"])
        _ = ATSQLiteManager.shared.executeQuery(query: query!)
        //if result.errNum != nil { err = true; return err}
        return false
    })
}

let transactionRollBack = { (idx:Int) in
    ATSQLiteManager.shared.executeTransactionQueryBlock({ () -> (Bool?) in
        let query = InsertQuery(table: "student", attributes: ["name","age","gender"], values: ["paco\(idx)","22","F"])
        _ = ATSQLiteManager.shared.executeQuery(query: query!)
        //if result.errNum != nil { err = true; return err}
        return true
    })
}

let updateTable = {
    let query = UpdateQuery(table: "student", constraint: "name = 'paco1'", attributes: ["age"], values: ["111"])
    _ = ATSQLiteManager.shared.executeQuery(query: query!)
}

let deleteTable = {
    let query = DeleteQuery(table: "student", constraint: "name = paco1")
    _ = ATSQLiteManager.shared.executeQuery(query: query)
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
    
    //test mult-threading
    for idx in 0..<10
    {
        oq.addOperation({
            transactionCommit(idx)
        })
        oq.addOperation({
            transactionRollBack(idx)
        })
    }
    
    oq.isSuspended = false
    
    DispatchQueue.main.async {
        sleep(5)
        updateTable()
        selectTable()
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
}

main()

CFRunLoopRun()




