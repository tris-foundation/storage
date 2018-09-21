/******************************************************************************
 *                                                                            *
 * Tris Foundation disclaims copyright to this source code.                   *
 * In place of a legal notice, here is a blessing:                            *
 *                                                                            *
 *     May you do good and not evil.                                          *
 *     May you find forgiveness for yourself and forgive others.              *
 *     May you share freely, never taking more than you give.                 *
 *                                                                            *
 ******************************************************************************/

import Test
import File
@testable import Storage

final class PersistenceTests: TestCase {
    let temp = Path(string: "/tmp/PersistenceTests")

    override func tearDown() {
        try? Directory.remove(at: temp)
    }

    func testContainerWriteLog() {
        struct User: Entity, Equatable {
            let name: String

            var id: String { return name }
        }

        let path = temp.appending(#function)

        let container = Storage.Container<User>(
            name: "User",
            at: path,
            coder: JsonCoder())

        let user = User(name: "user")
        let guest = User(name: "guest")
        let admin = User(name: "admin")

        scope {
            try container.insert(user)
            try container.insert(guest)
            try container.insert(admin)
            let expected: [User.Key : Undo<User>.Action] = [
                user.id : .delete,
                guest.id : .delete,
                admin.id : .delete,
            ]
            assertEqual(container.undo.items.count, expected.count)
            for (key, value) in expected {
                assertEqual(container.undo.items[key], value)
            }
        }

        scope {
            try container.writeWAL()
            assertEqual(container.undo.items.count, 0)
            assertEqual(container.remove(guest.id), guest)
            assertEqual(container.undo.items.count, 1)
            try container.writeWAL()
        }

        scope {
            let path = path.appending("User")
            let file = File(name: "wal", at: path)
            let wal = try WAL.Reader<User>(from: file)
            var records = [WAL.Record<User>]()
            while let next = try wal.readNext() {
                records.append(next)
            }
            assertEqual(records.sorted(by: id), [
                .upsert(user),
                .upsert(guest),
                .upsert(admin),
                .delete(guest.id)
            ].sorted(by: id))
        }
    }

    func testContainerRecoveryFromLog() {
        struct User: Entity, Equatable {
            let name: String
            var id: String {
                return name
            }
        }

        let user = User(name: "user")
        let guest = User(name: "guest")
        let admin = User(name: "admin")

        let records: [WAL.Record<User>] = [
            .upsert(user),
            .upsert(guest),
            .upsert(admin),
            .delete(guest.id)
        ]

        scope {
            let path = temp.appending(#function).appending("User")
            let file = File(name: "wal", at: path)
            let wal = try WAL.Writer<User>(to: file)
            try records.forEach(wal.append)
        }

        scope {
            let storage = try Storage(at: temp.appending(#function))
            storage.register(User.self)
            try storage.restore()

            let users = try storage.container(for: User.self)
            assertEqual(users.count, 2)
            assertNil(users.get("guest"))
            let user = users.get("user")
            assertEqual(user?.name, "user")
        }
    }

    func testContainerSnapshot() {
        struct User: Entity {
            let name: String
            var id: String {
                return name
            }
        }

        let path = temp.appending(#function)

        scope {
            let storage = try Storage(at: path)
            let container = try storage.container(for: User.self)
            try container.insert(User(name: "first"))
            try container.insert(User(name: "second"))
            try container.insert(User(name: "third"))

            try storage.makeSnapshot()
        }

        let containerPath = path.appending("User")
        assertTrue(File.isExists(at: containerPath.appending("snapshot")))

        scope {
            let storage = try Storage(at: path)
            storage.register(User.self)
            try storage.restore()

            let users = try storage.container(for: User.self)
            assertEqual(users.count, 3)
        }
    }
}


// MARK: utils

// Sort WAL records
func id<T>(lhs: WAL.Record<T>, rhs: WAL.Record<T>) -> Bool
    where T.Key: Comparable
{
    switch (lhs, rhs) {
    case let (.upsert(lhse), .upsert(rhse)): return lhse.id < rhse.id
    case let (.delete(lhsk), .delete(rhsk)): return lhsk < rhsk
    case let (.upsert(lhse), .delete(rhsk)): return lhse.id < rhsk
    case let (.delete(lhsk), .upsert(rhse)): return lhsk < rhse.id
    }
}