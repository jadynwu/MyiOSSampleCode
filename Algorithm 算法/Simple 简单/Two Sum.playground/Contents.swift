import UIKit

//https://leetcode-cn.com/problems/two-sum/

//两数之和
//暴力解法
//中心思想是简单的，就是遍历，一个一个对比
//时间复杂度：由于嵌套了for循环，是O(n^2)
//空间复杂度: 没有创建存储器，是O(1)
func twoSum1(_ nums: [Int], _ target: Int) -> [Int] {
    for (i, num) in nums.enumerated() {
        for index in (i + 1..<nums.count) {
            if target - num == nums[index] {
                return [i, index];
            }
        }
    }
    return []
}

//两次循环解法
//将嵌套循环，转换成了两个循环，其实就是将其中一个循环转换成了空间，把遍历匹配变成了从空间里去找。
//前提：在hash表中查的速度远远快于循环查找的时间。
//第一次循环：遍历数组，创建 [value: index] 的映射hash表
//第二次循环：遍历数组，查找hash表中是否有（target - value）的值，如果有直接输出。
func twoSum2(_ nums: [Int], _ target: Int) -> [Int] {
    var hashTable: Dictionary<Int, Int> = [:]
    
    for (index, value) in nums.enumerated() {
        hashTable.updateValue(index, forKey: value);
    }
    
    for (index, value) in nums.enumerated() {
        if hashTable.keys.contains(target - value) {
            if index == hashTable[target - value]! {
                continue
            }
            return [index, hashTable[target - value]!]
        }
    }
    return []
}



//一次循环解法
//遍历的同时，为hash表添加已经遍历过的值，做到了没有重复。

//1. 创建空hash表，存放格式为（value：index）的数据
//2. 遍历数组，判断hash中是否存在key为target - value的index，如果有则输出
//3. 将value：index存入hash表中
//精髓：向前匹配，避免重复计算
//例如[3,2,4,8]
//3->null
//2->3
//4->3,2
//8->3,2,4
//一共6种情况，除了第一次hash为空的时候，共遍历了7次
func twoSum3(_ nums: [Int], _ target: Int) -> [Int] {
    var hashTable: Dictionary<Int, Int> = [:]
    for (index, value) in nums.enumerated() {
        if hashTable.keys.contains(target - value) {
            return [hashTable[target - value]!, index]
        }
        hashTable.updateValue(index, forKey:value)
    }
    return []
}


twoSum1([2,7,11,15], 18)
twoSum2([3,2,4], 6)
twoSum3([3,2,4], 6)
