//
//  QueryString.swift
//  ATSqlite
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

class QueryString: NSObject
{
    var queryType:ATSQLiteQueryType?
    var string:String?
    var table:String?
    var constraint:String?
    var attributes:[String]?
    var values:[String]?
    
    public override init()
    {
        super.init()
    }
    
    public func attributesValuesToString(_ attributes:Array<String>,_ values:Array<String>) -> String
    {
        var retStr = ""
        for idx in 0..<attributes.count
        {
            retStr = "," + attributes[idx] + " = " + "'" + values[idx] + "'" + retStr
        }
        let stringIndex = retStr.index(retStr.startIndex, offsetBy: 1)
        retStr = String(retStr[stringIndex...])
        return retStr
    }
    
    public func attributesToString(_ arr:Array<String>) -> String
    {
        var retStr = ""
        
        for str in arr.reversed()
        {
            retStr = "," + str + retStr
        }
        let stringIndex = retStr.index(retStr.startIndex, offsetBy: 1)
        retStr = String(retStr[stringIndex...])
        return retStr
    }
    
    public func valueToString(_ arr:Array<String>) ->String
    {
        var retStr = ""
        
        for str in arr.reversed()
        {
            retStr = "," + "'" + str + "'" + retStr
        }
        let stringIndex = retStr.index(retStr.startIndex, offsetBy: 1)
        retStr = String(retStr[stringIndex...])
        return retStr
    }
    
}



class SelectQuery: QueryString
{
    public init(table:String, constraint:String?, attributes:[String]?)
    {
        super.init()
        self.queryType = .Select
        self.table = table
        self.constraint = constraint
        self.attributes = attributes
        
        var _constraint = constraint
        var sql = "SELECT %@ FROM %@ %@"
        
        if(_constraint == nil || _constraint!.count == 0)
        {
            _constraint = ""
        }else
        {
            if(!_constraint!.uppercased().contains("WHERE"))
            {
                _constraint = "WHERE " + _constraint!
            }
        }
        if(attributes == nil || attributes!.count == 0)
        {
            sql = String(format: sql, "*", table, _constraint!)
        }else
        {
            sql = String(format: sql, attributesToString(attributes!), table, _constraint!)
        }
        self.string = sql
    }
    
    private override init(){}
    
}

class DeleteQuery: QueryString
{
    public init(table:String, constraint:String?)
    {
        super.init()
        self.queryType = .Delete
        self.table = table
        self.constraint = constraint
        
        var _constraint = constraint
        
        let sql = "DELETE FROM %@ %@"
        
        if(_constraint == nil || _constraint!.count == 0)
        {
            _constraint = ""
        }else
        {
            if(!_constraint!.uppercased().contains("WHERE"))
            {
                _constraint = "WHERE " + _constraint!
            }
        }
        
        self.string = String(format: sql, table, _constraint!)
        
    }
    
    private override init(){}
    
}

class InsertQuery: QueryString
{
    public init?(table:String, attributes:[String], values:[String])
    {
        super.init()
        self.queryType = .Insert
        self.table = table
        self.attributes = attributes
        self.values = values
        
        let sql = "INSERT INTO %@ (%@) VALUES (%@)"
        
        if(attributes.count != values.count)
        {
            return nil
        }
        self.string = String(format: sql, table, attributesToString(attributes), valueToString(values))
    }
    
    private override init(){}
}

class UpdateQuery: QueryString
{
    
    public init?(table:String, constraint:String?, attributes:[String], values:[String])
    {
        super.init()
        self.queryType = .Update
        self.table = table
        self.constraint = constraint
        self.attributes = attributes
        self.values = values
        
        let sql = "UPDATE %@ SET %@ %@"
        
        if(attributes.count == 0 || values.count == 0 || attributes.count != values.count)
        {
            return nil
        }
        
        var _constraint = constraint
        
        if(_constraint == nil || _constraint!.count == 0)
        {
            _constraint = ""
        }else
        {
            if(!_constraint!.uppercased().contains("WHERE"))
            {
                _constraint = "WHERE " + _constraint!
            }
        }
        
        self.string = String(format: sql, table, attributesValuesToString(attributes, values), _constraint!)
    }
    
    private override init(){}
}

class GenericQuery: QueryString
{
    public init(query:String)
    {
        super.init()
        self.queryType = .Unknown
        self.string = query
    }
    
    private override init(){}
}

class BeginTransactionQuery:GenericQuery
{
    public init(){
        let query = "BEGIN TRANSACTION;"
        super.init(query: query)
    }
}

class RollbackQuery: GenericQuery
{
    public init(){
        let query = "ROLLBACK;"
        super.init(query: query)
    }
}

class CommitQuery: GenericQuery {
    public init(){
        let query = "COMMIT;"
        super.init(query: query)
    }
}







