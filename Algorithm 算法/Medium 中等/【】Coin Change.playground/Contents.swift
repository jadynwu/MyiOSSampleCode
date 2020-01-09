import UIKit


//https://leetcode-cn.com/problems/coin-change/


//状态转移方程：
//0 n==0
//f(n) = 1 + min{f(n - i),i in [1,k]}
func coinChange(_ coins: [Int], _ amount: Int) -> Int {
    
}

print(coinChange([1,2,5], 6));



