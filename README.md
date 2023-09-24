# FlashCache ⚡️ (Swift 📦)

Welcome to FlashCache, a Swift package that simplifies in-memory caching with support for multiple cache policies, including Least Frequently Used (LFU) and Least Recently Used (LRU). This package provides a flexible and efficient way to manage frequently accessed data in your Swift projects 🧠.

## Features

- In-memory caching with LFU and LRU policies
- Easy-to-use API for caching and retrieving values
- Swift 5.5 concurrency support
- Customizable cache size and policy settings

## Installation

You can integrate FlashCache into your project using Swift Package Manager (SPM):

1. In Xcode, open your project.
2. Go to "File" > "Swift Packages" > "Add Package Dependency..."
3. Enter the URL of this FlashCache repository: `https://github.com/yourusername/FlashCache`
4. Select the package from the search results.
5. Choose the version or branch you want to use.
6. Add the package to your desired target.

## Usage

### Creating a FlashCache Instance

```swift
import FlashCache

// Create an instance of FlashCache with the desired key and value types
let cache = FlashCache<String, Int>()
```

### Inserting Values into the Cache

```swift
// Insert a value into the cache associated with a specific key
cache.insert(42, forKey: "answer")
```

## Retrieving Values from the Cache

```swift
// Retrieve a cached value associated with a specific key
if let cachedValue = cache.value(forKey: "answer") {
    print("The answer is \(cachedValue)")
} else {
    print("Value not found in the cache.")
}
```

## Removing Values from the Cache

```swift
// Remove a cached value associated with a specific key
cache.removeValue(forKey: "answer")
```

## Setting the Cache Policy

```swift
// Set the cache policy (optional, defaults to no specific policy)
cache.cachePolicy = .leastFrequentlyUsed // LFU policy
cache.cachePolicy = .leastRecentlyUsed // LRU policy
```

## Customization

FlashCache allows you to customize the cache size and implement advanced policy-specific functionality based on your project's requirements. 
You can explore more advanced use cases by referring to the provided code samples and methods.

## Contribution

Contributions are welcome! If you find a bug or have an enhancement in mind, feel free to create an issue or submit a pull request.

## License

This package is licensed under the MIT License.
