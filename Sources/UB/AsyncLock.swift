import Foundation

/// `AsyncLock` creates a mutex from a semaphore that executes a closure in a locked context
public struct AsyncLock {
    fileprivate let _queue: DispatchQueue
    fileprivate let _semaphore: DispatchSemaphore

    init(_ className: String = "AsyncLock") {
        _queue = DispatchQueue(label: "com.ultralight-beam.bluetooth.\(className).DispatchQueue\(UUID().uuidString)", attributes: DispatchQueue.Attributes.concurrent)
        _semaphore = DispatchSemaphore(value: 1)
    }

    public mutating func lockAsync(_ closure: @escaping () -> Void) {
        let semaphore = _semaphore
        _queue.async(flags: .barrier) {

            semaphore.wait()

            defer {
                semaphore.signal()
            }

            closure()
        }
    }

    public mutating func lockAsync<T>(_ closure: @escaping () -> T, onComplete: @escaping (T) -> Void) {
        let semaphore = _semaphore
        _queue.async {

            semaphore.wait()

            defer {
                semaphore.signal()
            }

            let result = closure()
            onComplete(result)
        }
    }

    public mutating func lockSync(_ closure: @escaping () -> Void) {
        _queue.sync{
            closure()
        }
    }

    public mutating func lockSync<T>(_ closure: @escaping () -> T, onComplete: @escaping (T) -> Void) {
        _queue.sync{
            let result = closure()
            onComplete(result)
        }
    }
}
