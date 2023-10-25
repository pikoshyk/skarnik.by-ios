//
//  SKLevenshtein.swift
//  Skarnik
//
//  Created by Logout on 25.10.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import Foundation

class SKLevenshtein {
    
    private struct Array2D {
        var cols:Int, rows:Int
        var matrix: [Int]


        init(cols:Int, rows:Int) {
            self.cols = cols
            self.rows = rows
            matrix = Array(repeating: 0, count: cols*rows)
        }

        subscript(col:Int, row:Int) -> Int {
            get {
                return matrix[cols * row + col]
            }
            set {
                matrix[cols*row+col] = newValue
            }
        }

        func colCount() -> Int {
            return self.cols
        }

        func rowCount() -> Int {
            return self.rows
        }
    }
    
    class func distance(aStr: String, bStr: String) -> Int {
        let a = Array(aStr.utf16)
        let b = Array(bStr.utf16)
        
        var dist = Array2D(cols: a.count + 1, rows: b.count + 1)
        
        for i in 1...a.count {
            dist[i, 0] = i
        }
        
        for j in 1...b.count {
            dist[0, j] = j
        }
        
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i-1] == b[j-1] {
                    dist[i, j] = dist[i-1, j-1]  // noop
                } else {
                    dist[i, j] = min(
                        dist[i-1, j] + 1,  // deletion
                        dist[i, j-1] + 1,  // insertion
                        dist[i-1, j-1] + 1  // substitution
                    )
                }
            }
        }
        
        return dist[a.count, b.count]
    }
}
