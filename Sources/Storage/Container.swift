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

import File

extension Storage {
    public class Container<T: Entity> {
        typealias Entity = T

        let name: String
        let path: Path
        let coder: StreamCoder

        var items: [T.Key: T]
        var undo = Undo()

        func onInsert(newValue: T) {
            undo.onInsert(newValue: newValue)
        }

        func onUpsert(oldValue: T, newValue: T) {
            undo.onUpsert(oldValue: oldValue, newValue: newValue)
        }

        func onDelete(oldValue: T) {
            undo.onDelete(oldValue: oldValue)
        }

        init(name: String, at path: Path, coder: StreamCoder) {
            self.name = name
            self.path = path
            self.coder = coder
            self.items = [:]
        }

        enum Error: String, Swift.Error {
            case alreadyExist = "The primary key is already exists"
            case alreadyInSnapshot
        }

        public var count: Int {
            return items.count
        }

        public func insert(_ value: T) throws {
            guard items[value.id] == nil else {
                throw Error.alreadyExist
            }
            onInsert(newValue: value)
            items[value.id] = value
        }

        public func get(_ key: T.Key) -> T? {
            return items[key]
        }

        public func remove(_ key: T.Key) -> T? {
            guard let deleted = items.removeValue(forKey: key) else {
                return nil
            }
            onDelete(oldValue: deleted)
            return deleted
        }

        public func upsert(_ value: T) throws {
            let result = items.removeValue(forKey: value.id)
            switch result {
            case .some(let old):
                onUpsert(oldValue: old, newValue: value)
                items[value.id] = value
            case .none:
                onInsert(newValue: value)
                items[value.id] = value
            }
        }
    }
}

// MARK: secondary keys (not implemented) / fullscan

extension Storage.Container {
    public func first<C>(where key: KeyPath<T, C>, equals value: C) -> T?
        where C: Comparable
    {
        return items.values.first(where: { $0[keyPath: key] == value })
    }

    public func select<C>(where key: KeyPath<T, C>, equals value: C) -> [T]
        where C: Comparable
    {
        return items.values.filter({ $0[keyPath: key] == value })
    }

    public func remove<C>(where key: KeyPath<T, C>, equals value: C) -> [T]
        where C: Comparable
    {
        return items.values.compactMap { item in
            guard item[keyPath: key] == value else {
                return nil
            }
            return remove(item.id)
        }
    }
}
