import GRDB
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    private var dbQueue: DatabaseQueue!
    
    init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let databaseURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("db.sqlite")
            
            dbQueue = try DatabaseQueue(path: databaseURL.path)

            // Register migrations
            var migrator = DatabaseMigrator()

            migrator.registerMigration("v1") { db in
               // Create the initial users table
               try db.create(table: "users") { t in
                   t.column("id", .text).primaryKey()
                   t.column("email", .text).notNull()
                   t.column("username", .text).notNull()
                   t.column("pin", .text).notNull()
                   t.column("hasIncomingCallRequest", .boolean).notNull().defaults(to: false)
                   t.column("profileImageData", .blob)
                   t.column("deviceToken", .text)
                   t.column("friends", .text)
               }
               
               // Create the friends table
               try db.create(table: "friends") { t in
                   t.column("id", .text).primaryKey()
                   t.column("email", .text).notNull()
                   t.column("username", .text).notNull()
                   t.column("pin", .text).notNull()
                   t.column("profileImageData", .blob)
                   t.column("deviceToken", .text)
                   t.column("userId", .text).notNull().references("users", onDelete: .cascade) // Foreign key reference to users
               }
            }

            // Migrate the database to the latest version
            try migrator.migrate(dbQueue)
        } catch {
            NSLog("LOG: Error setting up database: \(error)")
        }
    }
}

// MARK: User CRUD
extension DatabaseManager {
    func createUser(user: UserRecord) {
        do {
            _ = try dbQueue.write { db in
                try user.save(db)
            }
            NSLog("LOG: Successfully added new user record")
            printUsersTable()
        } catch {
            print("Failed to save user: \(error)")
        }
    }

    
    func readUser(id: String) -> UserRecord? {
        do {
            let userRecord = try dbQueue.read { db in
                try UserRecord.fetchOne(db, key: id)
            }
            return userRecord
        } catch {
            NSLog("LOG: Failed to read user from database: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func printUsersTable() {
        NSLog("LOG: printUserTable")
        do {
            try dbQueue.read { db in
                let userRecords = try UserRecord.fetchAll(db)
                for userRecord in userRecords {
                    print(userRecord)
                }
            }
        } catch {
            print("Failed to fetch user records: \(error)")
        }
    }
}

// MARK: Friend Record
extension DatabaseManager {
    func createFriend(friend: FriendRecord) {
        do {
            _ = try dbQueue.write { db in
                try friend.save(db)
            }
        } catch {
            NSLog("LOG: Failed to save friend: \(error.localizedDescription)")
        }
    }
}
