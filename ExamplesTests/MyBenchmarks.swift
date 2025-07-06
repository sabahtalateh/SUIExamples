//import Testing
//import Foundation
import XCTest

class PerformanceTests: XCTestCase {
    
    func testArrayProcessingPerformance() {
        // Setup test data outside of measure block
        let testData = Array(0..<10000)
        
        measure {
            // Code to measure - должен быть детерминированным
            let result = testData
                .filter { $0 % 2 == 0 }
                .map { $0 * $0 }
                .reduce(0, +)
            
            // Don't include validation in measure block
            _ = result
        }
    }
    
    func testStringSortingPerformance() {
        let strings = (0..<1000).map { "TestString_\($0)" }
        
        measure {
            _ = strings.sorted()
        }
    }
    
    func testSlowMatrixMultiplication() {
            // Setup large matrices outside of measure block
            let matrixSize = 100  // 500x500 matrices - will be very slow
            let matrixA = generateRandomMatrix(size: matrixSize)
            let matrixB = generateRandomMatrix(size: matrixSize)
            
            // Configure measurement options for slow test
            let options = XCTMeasureOptions()
            options.iterationCount = 3  // Fewer iterations because each run is very slow
            
            measure(
//                metrics: [
//                    XCTClockMetric(),    // Wall clock time
//                    XCTCPUMetric(),      // CPU usage
//                    XCTMemoryMetric()    // Memory usage
//                ],
//                options: options
            ) {
                // Matrix multiplication - O(n³) complexity, very slow for large matrices
                let result = multiplyMatrices(matrixA, matrixB)
                
                // Don't include validation in measure block, just ensure result isn't optimized away
                _ = result[0][0]
            }
        }
        
        // Generate random matrix for testing
        private func generateRandomMatrix(size: Int) -> [[Double]] {
            var matrix: [[Double]] = []
            for _ in 0..<size {
                var row: [Double] = []
                for _ in 0..<size {
                    row.append(Double.random(in: 1.0...10.0))
                }
                matrix.append(row)
            }
            return matrix
        }
        
        // Naive matrix multiplication - intentionally slow O(n³) implementation
        private func multiplyMatrices(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
            let n = a.count
            var result = Array(repeating: Array(repeating: 0.0, count: n), count: n)
            
            for i in 0..<n {
                for j in 0..<n {
                    for k in 0..<n {
                        result[i][j] += a[i][k] * b[k][j]
                    }
                }
            }
            
            return result
        }
}
