//
//  TransactionTests.swift
//  MultiArray
//
//  Created by Vaida on 2025-05-24.
//

import Testing
import MultiArray


@Suite
struct TransactionTests {
    
    @Test func transpose() async throws {
        let multiArray = MultiArray<Float>.random(2, 4, 2)
        let new = multiArray.withTransaction { proxy in
            proxy.transposed(0, 1)
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
            proxy.reshape(-1, 7)
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
}
