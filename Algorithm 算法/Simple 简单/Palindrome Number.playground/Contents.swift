import UIKit

//https://leetcode-cn.com/problems/palindrome-number/

//回文数

func isPalindrome(_ x: Int) -> Bool {

    if (x > 0 && x % 10 == 0) || x < 0 {
        return false
    }
    
    var rev = 0
    var X = x
    while X > rev {
        let a = X % 10
        X = X / 10
        rev = rev * 10 + a
    }
    return rev == X || X == rev / 10
}

print(isPalindrome(12321))
