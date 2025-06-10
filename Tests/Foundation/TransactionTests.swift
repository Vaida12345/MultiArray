//
//  TransactionTests.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//

import Testing
import MultiArray
import os


@Suite
struct TransactionTests {
    
//    @Suite(.disabled())
    struct Trace {
        @Test func transpose() async throws {
            let multiArray = MultiArray<Float>.random(200, 400, 200)
            let signpost = OSSignposter(subsystem: "Trace", category: .pointsOfInterest)
            let _ = signpost.withIntervalSignpost("Transpose") {
                let result = multiArray.withTransaction { proxy in
                    let proxy = proxy.transposed(0, 1)
                    return proxy
                }
                return result
            }
        }
        
        @Test func convertIndexForward() async throws {
            var index: Int = 0
            let length = 1000_000
            let indexes = UnsafeMutableBufferPointer<Int>.allocate(capacity: length)
            _ = indexes.initialize(from: 1...length)
            let strides = UnsafeMutableBufferPointer<Int>.allocate(capacity: length)
            _ = strides.initialize(from: 1...length)
            
            let signpost = OSSignposter(subsystem: "Trace", category: .pointsOfInterest)
            let _ = signpost.withIntervalSignpost("Convert") {
                MultiArrayConvertIndex(from: indexes, to: &index, strides: strides)
            }
        }
        
        @Test func convertIndexBackward() async throws {
            let index: Int = 0
            let length = 100
            let indexes = UnsafeMutableBufferPointer<Int>.allocate(capacity: length)
            _ = indexes.initialize(from: 1...length)
            let strides = UnsafeMutableBufferPointer<Int>.allocate(capacity: length)
            _ = strides.initialize(from: 1...length)
            
            let signpost = OSSignposter(subsystem: "Trace", category: .pointsOfInterest)
            let _ = signpost.withIntervalSignpost("Convert") {
                MultiArrayConvertIndex(from: index, to: indexes, strides: strides)
            }
        }
    }
    
    @Test func transpose() async throws {
        let multiArray = MultiArray<Float>.random(2, 4, 2)
        let new = multiArray.withTransaction { proxy in
            let proxy = proxy.transposed(0, 1)
            #expect(proxy.shape == [4, 2, 2])
            return proxy
        }
        
        #expect(new.shape == [4, 2, 2])
        #expect(multiArray[0, 0, 0] == new[0, 0, 0])
        #expect(multiArray[0, 1, 0] == new[1, 0, 0])
        #expect(multiArray[0, 2, 0] == new[2, 0, 0])
        #expect(multiArray[0, 3, 0] == new[3, 0, 0])
        #expect(multiArray[1, 0, 0] == new[0, 1, 0])
        #expect(multiArray[1, 1, 0] == new[1, 1, 0])
        #expect(multiArray[1, 2, 0] == new[2, 1, 0])
        #expect(multiArray[1, 3, 0] == new[3, 1, 0])
    }
    
    @Test func reshape() async throws {
        let multiArray = MultiArray<Float>.random(2, 7, 3)
        let new = multiArray.withTransaction { proxy in
            let proxy = proxy.reshape(-1, 7)
            assert(proxy.shape == [6, 7])
            return proxy
        }
        
        #expect(new == multiArray.reshape(-1, 7))
    }
    
    @Suite struct Slice {
        
        @Test func full() async throws {
            let multiArray = MultiArray<Float>.random(2, 7, 3)
            let new = multiArray.withTransaction { proxy in
                proxy.sliced(nil, nil, nil)
            }
            
            #expect(new == multiArray)
        }
        
        @Test func none() async throws {
            let multiArray = MultiArray<Float>.random(2, 7, 3)
            let new = multiArray.withTransaction { proxy in
                proxy.sliced(0..<0, 0..<0, 0..<0) // not recommended, only works for all zeros.
            }
            
            #expect(new.shape == [0, 0, 0])
        }
        
        @Test func leading() async throws {
            let multiArray = MultiArray<Float>.random(3, 7, 3)
            let new = multiArray.withTransaction { proxy in
                proxy.sliced(0..<2, nil, nil)
            }
            
            #expect(new.shape == [2, 7, 3])
            for i in 0..<7 {
                #expect(new[0, i, 0] == multiArray[0, i, 0])
                #expect(new[0, i, 1] == multiArray[0, i, 1])
                #expect(new[0, i, 2] == multiArray[0, i, 2])
                #expect(new[1, i, 0] == multiArray[1, i, 0])
                #expect(new[1, i, 1] == multiArray[1, i, 1])
                #expect(new[1, i, 2] == multiArray[1, i, 2])
            }
        }
        
        @Test func middle() async throws {
            let multiArray = MultiArray<Float>.random(3, 7, 3)
            let new = multiArray.withTransaction { proxy in
                proxy.sliced(nil, 4..<6, nil)
            }
            
            #expect(new.shape == [3, 2, 3])
            for i in 0..<3 {
                for ii in 0..<3 {
                    #expect(new[i, 0, ii] == multiArray[i, 4, ii])
                    #expect(new[i, 1, ii] == multiArray[i, 5, ii])
                }
            }
        }
        
        @Test func last() async throws {
            let multiArray = MultiArray<Float>.random(3, 7, 3)
            let new = multiArray.withTransaction { proxy in
                proxy.sliced(nil, nil, 1..<3)
            }
            
            #expect(new.shape == [3, 7, 2])
            for i in 0..<7 {
                #expect(new[0, i, 0] == multiArray[0, i, 1])
                #expect(new[1, i, 0] == multiArray[1, i, 1])
                #expect(new[2, i, 0] == multiArray[2, i, 1])
                #expect(new[0, i, 1] == multiArray[0, i, 2])
                #expect(new[1, i, 1] == multiArray[1, i, 2])
                #expect(new[2, i, 1] == multiArray[2, i, 2])
            }
        }
        
        @Test func mixture() {
            let multiArray = MultiArray<Float>.random(3, 4, 3)
            let new = multiArray.withTransaction { proxy in
                proxy.sliced(nil, 1..<3, 1..<2)
            }
            
            #expect(new.shape == [3, 2, 1])
            for i in 0..<3 {
                #expect(new[i, 0, 0] == multiArray[i, 1, 1])
                #expect(new[i, 1, 0] == multiArray[i, 2, 1])
            }
        }
    }
    
    @Test func offset() async throws {
        let multiArray = MultiArray<Float>.random(1, 7, 3)
        var new = MultiArray<Float>.allocate(2, 7, 3)
        new.buffer.initialize(repeating: .nan)
        
        multiArray.withTransaction(into: &new) { proxy in
            proxy.offset(1, 0, 0)
        }
        
        for i in 0..<7 {
            for ii in 0..<3 {
                #expect(new[0, i, ii].isNaN)
                #expect(new[1, i, ii] == multiArray[0, i, ii])
            }
        }
    }
    
    @Test func offset2() async throws {
        let multiArray = MultiArray<Float>.random(1, 7, 3)
        var new = MultiArray<Float>.allocate(1, 8, 5)
        new.buffer.initialize(repeating: .nan)
        
        multiArray.withTransaction(into: &new) { proxy in
            proxy.offset(0, 1, 2)
        }
        
        print(multiArray)
        print(new)
        
        #expect(new[0, 0, 0].isNaN)
        #expect(new[0, 0, 1].isNaN)
        
        for i in 0..<7 {
            for ii in 0..<3 {
                #expect(new[0, i + 1, ii + 2] == multiArray[0, i, ii])
            }
        }
    }
}
