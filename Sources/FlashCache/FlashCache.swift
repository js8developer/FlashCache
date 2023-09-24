//
//  FlashCache.swift
//
//
//  Created by Jason Schneider on 9/24/23.
//

import Foundation

/**
 A generic caching class designed for quickly storing and retrieving key-value pairs using an NSCache as the underlying storage mechanism.

 You can use `FlashCache` to cache values associated with specific keys, allowing for efficient access to frequently used data in your application. It is designed as a thread-safe, easy-to-use caching solution.

 - Note: The key type (`Key`) must conform to the `Hashable` protocol for proper cache functionality.
 - Warning: This cache does not guarantee the retention of objects for any specific duration and may remove entries based on system resource constraints.

 Example usage:
 ```swift
 // Creating a FlashCache
 let cache = FlashCache<String, Int>()

 // Inserting a value into the cache
 cache.insert(42, forKey: "answer")

 // Retrieving a value from the cache
 if let cachedValue = cache.value(forKey: "answer") {
     print("The answer is \(cachedValue)")
 }

 // Removing a value from the cache
 cache.removeValue(forKey: "answer")
 */
public final class FlashCache<Key: Hashable, Value> {
    private let wrapped = NSCache<WrappedKey, Entry>()
    // Specify the cache policy (default is .defaultPolicy)
    public let cachePolicy: CachePolicy
    public let maxCacheSize: Int

    private var keysLRU: [WrappedKey] = [] // For LRU policy
    public var lruCount: Int {
        return keysLRU.count
    }

    private var usageCounts: [WrappedKey: Int] = [:] // For LFU policy
    public var lfuCount: Int {
        return usageCounts.count
    }

    /// Initializes a new instance of FlashCache.
    ///
    public init(cachePolicy: CachePolicy = .defaultPolicy, maxCacheSize: Int = 100) {
        self.cachePolicy = cachePolicy
        self.maxCacheSize = maxCacheSize
    }

    /// Inserts a value into the cache associated with a specific key.
    ///
    /// - Parameters:
    ///   - value: The value to be cached.
    ///   - key: The key to associate with the value.
    ///
    public func insert(_ value: Value, forKey key: Key) {
        let entry = Entry(value: value)
        let wrappedKey = WrappedKey(key)
        wrapped.setObject(entry, forKey: wrappedKey)
        applyCachePolicy(wrappedKey: wrappedKey)
    }

    /// Retrieves a cached value associated with a specific key.
    ///
    /// - Parameter key: The key associated with the value to retrieve.
    /// - Returns: The cached value if it exists, or nil if the key is not found in the cache.
    ///
    public func value(forKey key: Key) -> Value? {
        let wrappedKey = WrappedKey(key)
        let entry = wrapped.object(forKey: wrappedKey)
        applyCachePolicy(wrappedKey: wrappedKey)
        return entry?.value
    }

    /// Removes a cached value associated with a specific key.
    ///
    /// - Parameter key: The key associated with the value to remove.
    ///
    public func removeValue(forKey key: Key) {
        wrapped.removeObject(forKey: WrappedKey(key))
    }

    /// Clears the cache
    ///
    public func removeAll() {
        wrapped.removeAllObjects()
    }
}

// MARK: - WrappedKey

extension FlashCache {
    final class WrappedKey: NSObject {
        let key: Key

        init(_ key: Key) { self.key = key }

        override var hash: Int { return key.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }
            return value.key == key
        }
    }
}

// MARK: - Entry

extension FlashCache {
    final class Entry {
        let value: Value

        init(value: Value) {
            self.value = value
        }
    }
}

// MARK: - Cache Policies

extension FlashCache {
    /// This method applies the cache policy logic based on the current cache policy setting.
    ///
    /// - Parameter wrappedKey: The key wrapped as a WrappedKey object, to be used for policy-based
    /// decision-making.
    ///
    private func applyCachePolicy(wrappedKey: WrappedKey) {
        switch cachePolicy {
        case .leastFrequentlyUsed: applyLFUCachePolicy(wrappedKey: wrappedKey)
        case .leastRecentlyUsed: applyLRUCachePolicy(wrappedKey: wrappedKey)
        default: // Default policy (no specific logic)
            break
        }
    }

    // MARK: - LFU

    /// This method implements the Least Frequently Used (LFU) policy logic.
    /// It increments the usage count for a given key and removes the least frequently used entry
    /// when the cache size exceeds a specified limit.
    ///
    /// - Parameter wrappedKey: The key wrapped as a WrappedKey object, for which LFU policy is
    /// applied.
    ///
    private func applyLFUCachePolicy(wrappedKey: WrappedKey) {
        // Increment usage count for LFU policy
        incrementUsageCount(forKey: wrappedKey)

        // Apply LFU policy: remove the least frequently used entry
        if usageCounts.count > maxCacheSize {
            if let leastFrequentKey = findLeastFrequentKey() {
                wrapped.removeObject(forKey: leastFrequentKey)
                usageCounts[leastFrequentKey] = nil
            }
        }
    }

    /// This method increments the usage count for a given key in the LFU policy.
    ///
    /// - Parameter key: The key for which the usage count should be incremented.
    ///
    private func incrementUsageCount(forKey key: WrappedKey) {
        usageCounts[key, default: 0] += 1
    }

    /// This method finds and returns the key with the lowest usage count in the LFU policy.
    ///
    /// - Returns: Returns the WrappedKey object with the lowest usage count if found. Returns nil
    /// if there are no keys in the cache or if all keys have the same usage count.
    ///
    private func findLeastFrequentKey() -> WrappedKey? {
        var leastFrequentKey: WrappedKey?
        var leastFrequentCount = Int.max

        for (key, count) in usageCounts {
            if count < leastFrequentCount {
                leastFrequentCount = count
                leastFrequentKey = key
            }
        }

        return leastFrequentKey
    }

    // MARK: - LRU

    /// This method implements the Least Recently Used (LRU) policy logic.
    /// It maintains the order of accessed keys and removes the least recently used entry when the
    /// cache size exceeds a specified limit.
    ///
    /// - Parameter wrappedKey: The key wrapped as a WrappedKey object, for which LRU policy is
    /// applied.
    ///
    private func applyLRUCachePolicy(wrappedKey: WrappedKey) {
        keysLRU.append(wrappedKey)

        // Apply LRU policy: remove the least recently used entry
        if keysLRU.count > maxCacheSize {
            if let oldestKey = keysLRU.first {
                wrapped.removeObject(forKey: oldestKey)
                keysLRU.removeFirst()
            }
        }
    }
}

public extension FlashCache {
    /**
     Provides subscript access to the cache for convenient read and write operations.

     Usage:

     // Retrieving a value from the cache
     let cachedValue = cache["answer"]

     // Inserting a value into the cache
     cache["key"] = value

     // Removing a value from the cache
     cache["key"] = nil

     */

    ///   Provides subscript access to the cache for convenient read and write operations.
    ///
    /// - Parameter key: The key associated with the value to retrieve or set.
    /// - Returns: The cached value if reading, or nil if setting to nil.
    ///
    subscript(key: Key) -> Value? {
        get { return value(forKey: key) }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                removeValue(forKey: key)
                return
            }

            insert(value, forKey: key)
        }
    }
}
