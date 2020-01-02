import UIKit


//介绍
//斐波那契问题

//状态转移方程
//f(1) = 1    f(2) = 1
//f(n) = f(n-1) + f(n-2)

//通过n获取f(n)

//暴力递归解法
func fibonacciTest1(_ n: Int) -> Int {
    if n < 1 {
        return 0
    }
    
    if n == 1 || n == 2 {
        return 1
    }
    return fibonacciTest1(n-1) + fibonacciTest1(n-2)
}

let a = fibonacciTest1(10);

print(a);

//带备忘录的递归解法
func fibonacciTest2(_ n: Int) -> Int {
    if n < 1 {
        return 0
    }
    
    var table:Dictionary<Int, Int> = [:]
    return fibonacciTest2WithDic(n, &table)
}

func fibonacciTest2WithDic(_ n: Int,_ table:inout Dictionary<Int, Int>) -> Int {
    
    if n == 1 || n == 2 {
        return 1
    }
    
    if table.keys.contains(n) {
        return table[n]!
    }
    
    let value = fibonacciTest2WithDic(n - 1, &table) + fibonacciTest2WithDic(n - 2, &table)
    table.updateValue(value, forKey: n)
    return fibonacciTest2WithDic(n - 1, &table) + fibonacciTest2WithDic(n - 2, &table)
}

print(fibonacciTest2(10));

//动态规划
func fibonacciTest3(_ n: Int) -> Int {
    if n < 1 {
        return 0
    }
    
    if n == 1 || n == 2 {
        return 1
    }
    
    var i = 0
    var j = 1
    for _ in 1..<n {
        let sum = i + j
        i = j
        j = sum
    }
    return j
}
print(fibonacciTest3(10));
