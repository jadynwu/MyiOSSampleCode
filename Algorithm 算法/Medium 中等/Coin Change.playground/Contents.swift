import UIKit


//https://leetcode-cn.com/problems/coin-change/

//简述：拼成总金额的最小硬币组合，每种硬币数量无限
//状态转移方程：
//0 n==0
//f(n) = 1 + min{f(n - i),i in [1,k]}

var dic = Dictionary<Int,Int>()
//直接递归法
func coinChangeDirectStyle(_ coins: [Int], _ amount: Int) -> Int {
    if amount == 0 {
        
        return 0
    }
    var minTimes = Int.max
    for coin in coins {
        if amount < coin {
            continue
        }
        minTimes = min(minTimes, coinChangeDirectStyle(coins, amount - coin) + 1)
    }
    return minTimes == Int.max ? -1 : minTimes
}


func coinChangeSavedStyle(_ coins: [Int], _ amount: Int) -> Int {
    if amount == 0 {
        return 0
    }
    
    if dic.keys.contains(amount) {
        return dic[amount]!
    }
    var minTimes = Int.max
    for coin in coins {
        if amount < coin {
            continue
        }
        minTimes = min(minTimes, coinChangeDirectStyle(coins, amount - coin) + 1)
    }
    let result = minTimes == Int.max ? -1 : minTimes
    dic[amount] = result
    return result
    
}

//当你拿到DP方程的时候，就可以画出树了，而这个数是有终点的
//DP解法的思路就是先建立一个起点到终点的数组
//填上已知的
//通过已知的计算未知的，如果无法计算，则保留
//数组元素的初始值和题型有关，找最小值就初始为可能的最大的值，反之亦然
func coinChangeDPStyle(_ coins: [Int], _ amount: Int) -> Int {
    if coins.count == 0 {
        return -1
    }
    var arr = Array(repeating: amount + 1, count: amount + 1)
    arr[0] = 0
    for i in 1...amount {
        arr[i] = amount + 1
        for coin in coins {
            if i < coin {
                continue
            }
            arr[i] = min(arr[i], arr[i - coin] + 1)
        }
    }
    return arr[amount] == amount + 1 ? -1 : arr[amount]
}


//print(coinChangeDirectStyle([1,2,5], 11));
print(coinChangeDPStyle([1,2,5], 120));



