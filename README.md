# ATSQLite

## Support

- OSX
- iOS

## Installation

You can download the project and copy the 'ATSQLiteManager.swift' file  and 'QueryString.swift' file to your project.

## Features

- Thread safe
- Transaction supported
- No extra class creation before use

## Example & Usage

You can download the project and run the demo.

Open Connection (Optional)
```swift
ATSQLiteManager.shared.openConnectionWith(filePath: "/Users/Paco/Document/sqlite3.db")
```

Transaction
```swift
ATSQLiteManager.shared.executeTransactionQueryBlock({ () -> (Bool?) in
    let query = InsertQuery(table: "student", attributes: ["name","age","gender"], values: ["paco","22","F"])
    
    //execution 1
    var result = ATSQLiteManager.shared.executeQuery(query: query!)
    if result.errNum != nil { /* error */ return true }
    
    //execution 2
    var result = ATSQLiteManager.shared.executeQuery(query: query!)
    if result.errNum != nil { /* error */ return true }
    
    /* no error */
return false
})
```
Don't execute commit or rollback query explicitly. It will call commit if return false in the block. otherwise, it will call rollback.

Insert
```swift
let query = InsertQuery(table: "student", attributes: ["name","age","gender"], values: ["paco","11","M"])
_ = ATSQLiteManager.shared.executeQuery(query: query!)
```

Select
```swift
let query = SelectQuery(table: "student", constraint: nil, attributes: nil)
let result = ATSQLiteManager.shared.executeQuery(query: query)
NSLog("%@", result.resultSet!)
```

Update
```swift
let query = UpdateQuery(table: "student", constraint: "name = paco1", attributes: ["age"], values: ["111"])
_ = ATSQLiteManager.shared.executeQuery(query: query!)
```

Delete
```swift
let query = DeleteQuery(table: "student", constraint: "name = paco1")
_ = ATSQLiteManager.shared.executeQuery(query: query)
```

Create
```swift
let query = GenericQuery(query: """
CREATE TABLE IF NOT EXISTS student (
id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
name TEXT,
age INTEGER,
gender TEXT CHECK( gender IN ('M','F'))
)
""")

_ = ATSQLiteManager.shared.executeQuery(query: query)
```

Drop
```swift
let query = GenericQuery(query: "DROP TABLE IF EXISTS student")
_ = ATSQLiteManager.shared.executeQuery(query: query)
```


