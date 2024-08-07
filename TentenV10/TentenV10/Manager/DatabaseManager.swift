import GRDB
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    private var dbQueue: DatabaseQueue!

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        // TODO: need to update the user record
        do {
            let databaseURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("db.sqlite")
            
            dbQueue = try DatabaseQueue(path: databaseURL.path)

            // Register migrations
            var migrator = DatabaseMigrator()

            migrator.registerMigration("v1") { db in
                // Check if the table already exists to avoid duplicate creation
                if try db.tableExists("users") {
                    print("Table 'users' already exists.")
                } else {
                    // Create the initial users table
                    try db.create(table: "users") { t in
                        t.column("id", .text).primaryKey()
                        t.column("email", .text).notNull()
                        t.column("displayName", .text)
                        t.column("profileImageData", .blob)
                    }
                }
            }

            migrator.registerMigration("v2") { db in
                // Add deviceToken to users table
                try db.alter(table: "users") { t in
                    t.add(column: "deviceToken", .text)
                }
            }
            
            // Remove displayName, add username, pin, and hasIncomingCallRequest columns
            migrator.registerMigration("v3") { db in
                try db.alter(table: "users") { t in
                    t.drop(column: "displayName")
                    t.add(column: "username", .text).notNull().defaults(to: "default_username")
                    t.add(column: "pin", .text).notNull().defaults(to: "0000")
                    t.add(column: "hasIncomingCallRequest", .boolean).notNull().defaults(to: false)
                }
            }
            
            // Add friends column
            migrator.registerMigration("v4") { db in
                try db.alter(table: "users") { t in
                    _ = t.add(column: "friends", .text).notNull().defaults(to: "[]")
                }
            }
            
            // Migrate the database to the latest version
            try migrator.migrate(dbQueue)
        } catch {
            print("Database setup error: \(error)")
        }
    }
}

// MARK: UserRecord CRUD
extension DatabaseManager {
    func saveUser(user: UserRecord) {
        do {
            try dbQueue.write { db in
                try user.save(db)
            }
        } catch {
            print("Failed to save user: \(error)")
        }
    }

    func deleteUser(id: String) {
        do {
            _ = try dbQueue.write { db in
                try UserRecord.deleteOne(db, key: id)
            }
        } catch {
            print("Failed to delete user: \(error)")
        }
    }

    func fetchUser(id: String) -> UserRecord? {
        do {
            return try dbQueue.read { db in
                try UserRecord.fetchOne(db, key: id)
            }
        } catch {
            print("Failed to fetch user: \(error)")
            return nil
        }
    }
    
    // TODO: need to add update
}
