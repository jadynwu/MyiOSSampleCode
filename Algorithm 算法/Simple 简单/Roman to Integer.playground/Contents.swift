import UIKit

//https://leetcode-cn.com/problems/roman-to-integer/

//罗马转数字

func romanToInt(_ s: String) -> Int {
    var map = Dictionary<String, Int>()
    map.updateValue(1, forKey: "I")
    map.updateValue(4, forKey: "IV")
    map.updateValue(5, forKey: "V")
    map.updateValue(9, forKey: "IX")
    map.updateValue(10, forKey: "X")
    map.updateValue(40, forKey: "XL")
    map.updateValue(50, forKey: "L")
    map.updateValue(90, forKey: "XC")
    map.updateValue(100, forKey: "C")
    map.updateValue(400, forKey: "CD")
    map.updateValue(500, forKey: "D")
    map.updateValue(900, forKey: "CM")
    map.updateValue(1000, forKey: "M")
    var rec = 0
    var i = 0
    while i < s.count {
        let indexStart = s.index(s.startIndex, offsetBy: i)
        let index1 = s.index(indexStart, offsetBy: 1)
        if s.count - i > 1 {
            let index2 = s.index(indexStart, offsetBy: 2)
            let a = String(s[indexStart..<index2])
            if map.keys.contains(a) {
                rec = rec + map[a]!
                i = i + 2
            } else {
                rec = rec + map[String(s[indexStart..<index1])]!
                i = i + 1
            }
        } else {
            rec = rec + map[String(s[indexStart..<index1])]!
            i = i + 1
        }
    }
    return rec
}

print(romanToInt("III"))

print(romanToInt("IV"))

print(romanToInt("IX"))

print(romanToInt("MCMXCIV"))
