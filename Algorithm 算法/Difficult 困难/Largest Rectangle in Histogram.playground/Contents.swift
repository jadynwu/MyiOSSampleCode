import UIKit


//https://leetcode-cn.com/problems/largest-rectangle-in-histogram/
//柱状图中最大的矩形

//给定 n 个非负整数，用来表示柱状图中各个柱子的高度。每个柱子彼此相邻，且宽度为 1 。

//求在该柱状图中，能够勾勒出来的矩形的最大面积。

//单调栈解法
func largestRectangleArea(_ heights: [Int]) -> Int {
    let newHeights = [0] + heights + [0];
    var stack = [Int]()
    var largest = 0
    for i in 0..<newHeights.count {
        while stack.count > 0 && newHeights[i] < newHeights[stack.last!] {
            let ht = newHeights[stack.last!]
            stack.remove(at: stack.count - 1)
            largest = max(largest, ht * (i - 1 - stack.last!))
        }
        stack.append(i)
    }
    return largest
}

print(largestRectangleArea([2,1,5,6,2,3]))

