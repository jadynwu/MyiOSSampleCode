import UIKit


//https://leetcode-cn.com/problems/coin-change/
//给定不同面额的硬币coins和一个总金额amount。编写一个函数来计算可以凑成总金额所需的最少的硬币个数。如果没有任何一种硬币组合能组成总金额，返回 -1。


//输入: coins = [1, 2, 5], amount = 11
//输出: 3
//解释: 11 = 5 + 5 + 1


//输入: coins = [2], amount = 3
//输出: -1


//说明:
//你可以认为每种硬币的数量是无限的。

//总额为n k个数
//状态转移方程：
//0 n==0
//f(n) = 1 + min{f(n - i),i in [1,k]}


//暴力解法
func coinChange(_ coins: [Int], _ amount: Int) -> Int {
    if amount == 0 {
        return 0
    }
    
    var min = NSIntegerMax
    for coin in coins {
        if amount < coin {
            continue
        }
        //减去当前的coin后，剩下需要多少次
        let a = coinChange(coins, amount - coin)
        if min > a && a > 0 {
            min = a
        }
    }
    return min == NSIntegerMax ? -1 : min + 1
}


print(coinChange([1,2,5], 6));



