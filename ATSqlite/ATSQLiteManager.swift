//
//  ATSQLiteManager.swift
//  swift_sqlite3
//
//  Created by Pacoyeung on 3/16/18.
//  Copyright © 2018 Pacoyeung. All rights reserved.
//

#if os(iOS)
    import UIKit
#endif

#if os(OSX)
    import AppKit
#endif

typealias TransactionQueryBlock = ()->(Bool?)

struct QueryResult {
    var errNum:ATSQLiteError?
    var resultSet:Array<Dictionary<String, Any>>?
    var rowId:Int?
}


public enum ATSQLiteError:Int {
    case TRANSACTION_ERROR
    case SQLITE_OPEN_CONNECTION_ERROR
    case SQLITE_CLOSE_CONNECTION_ERROR
    case SQLITE_NULL_CONNECTION_ERROR
    case SQLITE_PREPARE_QUERY_ERROR
    case SQLITE_STEP_QUERY_ERROR
    case SQLITE_CREATE_RESULTSET_ERROR
    
}




public enum ATSQLiteQueryType:Int32{
    case Unknown
    case Select
    case Update
    case Delete
    case Create
    case Insert
    case Drop
}


class ATSQLiteManager: NSObject {
    private var connection:OpaquePointer?
    private var stmt:OpaquePointer?
    private var errString:UnsafeMutablePointer<Int8>?

//    private var tranOperationQueue:OperationQueue?
    private var operationqueue:OperationQueue?
    
    public static let shared:ATSQLiteManager = {
        let ref = ATSQLiteManager()
        ref.openConnection()
        return ref
    }()
    public override init()
    {
        super.init()
//        self.tranOperationQueue = OperationQueue()
//        self.tranOperationQueue?.maxConcurrentOperationCount = 1
        self.operationqueue = OperationQueue()
        self.operationqueue?.maxConcurrentOperationCount = 1
    }
    
    public func closeConnection()
    {
        self.operationqueue!.isSuspended = true
        self.operationqueue!.waitUntilAllOperationsAreFinished()
        
        if(sqlite3_close(self.connection) != SQLITE_OK)
        {
            NSLog("Error Code: %d",ATSQLiteError.SQLITE_CLOSE_CONNECTION_ERROR.rawValue)
            assert(false)
        }
    }
    
    public func openConnectionWith(filePath: String)
    {
        if(self.connection != nil)
        {
            self.closeConnection()
        }
        
        if(sqlite3_open(filePath, &self.connection) != SQLITE_OK)
        {
            NSLog("Error Code: %d",ATSQLiteError.SQLITE_OPEN_CONNECTION_ERROR.rawValue)
            assert(false)
        }
        
        self.operationqueue!.isSuspended = false
    }
    
    private func openConnection()
    {
        let filePath:String = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sqlite3.db").path
        self.openConnectionWith(filePath: filePath)
    }
    
    private func selectResult(stmt:OpaquePointer?,_ query:QueryString,_ queryResult:inout QueryResult)
    {
        var flag:Int32 = SQLITE_ERROR
        while(true)
        {
            flag = sqlite3_step(stmt)
            if(flag != SQLITE_ROW)
            {
                break
            }
            let colCount = sqlite3_data_count(stmt)
            var dic:Dictionary<String, Any> = [:]
            
            for idx in 0..<colCount
            {
                let intType = sqlite3_column_type(stmt, idx)
                let colName = String(cString: sqlite3_column_name(stmt, idx))
                
                switch (intType)
                {
                case SQLITE_INTEGER:
                    let data = Int(sqlite3_column_int(stmt, idx))
                    if(query.attributes == nil || query.attributes!.count == 0)
                    {
                        dic[colName] = data
                    }else{
                        dic[query.attributes![Int(idx)]] = data
                    }
                    break;
                case SQLITE_FLOAT:
                    let data = Double(sqlite3_column_double(stmt, idx))
                    if(query.attributes == nil || query.attributes!.count == 0)
                    {
                        dic[colName] = data
                    }else{
                        dic[query.attributes![Int(idx)]] = data
                    }
                    break;
                case SQLITE_BLOB:
                    let data = Data(bytes: sqlite3_column_blob(stmt, idx), count: Int(sqlite3_column_bytes(stmt, idx)))
                    if(query.attributes == nil || query.attributes!.count == 0)
                    {
                        dic[colName] = data
                    }else{
                        dic[query.attributes![Int(idx)]] = data
                    }
                    break;
                case SQLITE_NULL:
                    if(query.attributes == nil || query.attributes!.count == 0)
                    {
                        dic[colName] = ""
                    }else{
                        dic[query.attributes![Int(idx)]] = ""
                    }
                    break;
                case SQLITE_TEXT:
                    let data = String(cString: sqlite3_column_text(stmt, idx))
                    if(query.attributes == nil || query.attributes!.count == 0)
                    {
                        dic[colName] = data
                    }else{
                        dic[query.attributes![Int(idx)]] = data
                    }
                    break;
                default:
                    if(query.attributes == nil || query.attributes!.count == 0)
                    {
                        dic[colName] = ""
                    }else{
                        dic[query.attributes![Int(idx)]] = ""
                    }
                    break;
                }
            }
            queryResult.resultSet!.append(dic)
        }
        
        if(flag != SQLITE_DONE)
        {
            print(sqlite3_errmsg(self.connection))
            NSLog("Error Code: %d",ATSQLiteError.SQLITE_CREATE_RESULTSET_ERROR.rawValue)
            assert(false)
        }
    }
    
    private func insertResult(stmt:OpaquePointer?,_ queryResult:inout QueryResult)
    {
        if(sqlite3_step(stmt) != SQLITE_DONE)
        {
            print(sqlite3_errmsg(self.connection))
            NSLog("Error Code: %d",ATSQLiteError.SQLITE_STEP_QUERY_ERROR.rawValue)
            assert(false)
        }else
        {
            queryResult.rowId = NSInteger(sqlite3_last_insert_rowid(self.connection))
        }
    }
    
    private func prepareQuery(query:QueryString) -> QueryResult
    {
        
        if(query.string == nil || query.queryType == nil){ assert(false) }
        
        var queryResult = QueryResult(errNum: nil, resultSet: [], rowId: nil)
        var stmt:OpaquePointer?
        defer {
            sqlite3_finalize(stmt)
        }
        var code:Int32! = 0
        code = sqlite3_prepare(self.connection, query.string, -1, &stmt, nil)
        
        if(code != SQLITE_OK && code != SQLITE_ROW && code != SQLITE_DONE)
        {
            print(sqlite3_errmsg(self.connection))
            NSLog("Error Code: %d",ATSQLiteError.SQLITE_PREPARE_QUERY_ERROR.rawValue)
            queryResult.errNum = ATSQLiteError.SQLITE_PREPARE_QUERY_ERROR
            return queryResult
        }
        
        switch(query.queryType!)
        {
        case .Select:
            self.selectResult(stmt: stmt, query, &queryResult)
        case .Insert:
            self.insertResult(stmt: stmt, &queryResult)
            break;
        case .Update,.Delete,.Create,.Drop,.Unknown:
            if(sqlite3_step(stmt) != SQLITE_DONE)
            {
                print(sqlite3_errmsg(self.connection))
                NSLog("Error Code: %d",ATSQLiteError.SQLITE_STEP_QUERY_ERROR.rawValue)
                assert(false)
            }
            break;
        }
        return queryResult
    }
    
    public func executeQuery(query:QueryString) -> QueryResult
    {
        if(self.connection == nil)
        {
            NSLog("Error Code: %d",ATSQLiteError.SQLITE_NULL_CONNECTION_ERROR.rawValue)
            assert(false)
        }
        
        var retResult:QueryResult? = nil
        let lock:DispatchSemaphore = DispatchSemaphore(value: 0)

        self._executeQuery(query: query) { (result:QueryResult) in
            retResult = result
            lock.signal()
        }
        lock.wait()
        return retResult!
    }
    
    private func _executeQuery(query:QueryString, completion:@escaping (QueryResult)->())
    {
        if(OperationQueue.current == self.operationqueue)
        {
            completion(self.prepareQuery(query: query))
        }else
        {
//            self.operationqueue!.addOperation({
//                self.tranOperationQueue!.isSuspended = true
//                self.tranOperationQueue!.waitUntilAllOperationsAreFinished()
//                let result = self.prepareQuery(query: query)
//                self.tranOperationQueue!.isSuspended = false
//                completion(result)
//            })
            self.operationqueue!.addOperation {
                completion(self.prepareQuery(query: query))
            }
        }
    }
    
    public func executeTransactionQueryBlock(_ transactionQueryBlock:@escaping TransactionQueryBlock)
    {
        if(self.connection == nil)
        {
            NSLog("Error Code: %d",ATSQLiteError.SQLITE_NULL_CONNECTION_ERROR.rawValue)
            assert(false)
        }
        
        let block = {
            let queryTransaction = BeginTransactionQuery()
            _ = self.executeQuery(query: queryTransaction)
            var err = transactionQueryBlock()
            defer {
                if(err == false)
                {
                    let queryTransaction = CommitQuery()
                    _ = self.executeQuery(query: queryTransaction)
                }else
                {
                    let queryTransaction = RollbackQuery()
                    _ = self.executeQuery(query: queryTransaction)
                }
            }
        }
//        self.tranOperationQueue!.addOperation {
//            self.operationqueue!.isSuspended = true
//            self.operationqueue!.waitUntilAllOperationsAreFinished()
//            block()
//            self.operationqueue!.isSuspended = false
//        }
        self.operationqueue!.addOperation {
            block()
        }
        
    }
    
}
