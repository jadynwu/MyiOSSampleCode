import UIKit


//https://leetcode-cn.com/problems/coin-change/



//暴力递归
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

//状态转移方程：
//0 n==0
//f(n) = 1 + min{f(n - i),i in [1,k]}


print(coinChange([1,2,5], 6));



