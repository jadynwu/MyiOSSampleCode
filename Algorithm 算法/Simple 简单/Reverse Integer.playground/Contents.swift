import UIKit


//https://leetcode-cn.com/problems/reverse-integer/

//整数反转
func reverse(_ x: Int) -> Int {
    var rev = 0
    var X = x
    while X != 0 {
        let a = X % 10
        X = X / 10
        rev = rev * 10 + a
    }
    if rev > Int32.max || rev < Int32.min {
        return 0
    }
    return rev
}

print(reverse(1534236469))
