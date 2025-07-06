import Testing
@testable import Examples

struct ExamplesTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test("Basic performance test")
    func basicPerformanceTest() {
        let startTime = ContinuousClock.now
        
        // Code to benchmark
        let result = (0..<10000).map { $0 * $0 }.reduce(0, +)
        
        let elapsed = ContinuousClock.now - startTime
        print("⏱️ Basic test completed in: \(elapsed)")
        #expect(result > 0) // Optional validation
    }
    
    @Test("Array sorting performance")
    func arraySortingPerformance() async {
        let testData = Array((1...50000).shuffled())
        
        let measurement = await withMeasurement {
            _ = testData.sorted()
        }
        
        print("📊 Sorting took: \(measurement.duration)")
        #expect(measurement.duration < .seconds(1)) // Assert max time
    }

    // Helper function for measurement
    func withMeasurement<T>(_ operation: () async throws -> T) async rethrows -> (result: T, duration: Duration) {
        let start = ContinuousClock.now
        let result = try await operation()
        let duration = ContinuousClock.now - start
        return (result, duration)
    }
}


