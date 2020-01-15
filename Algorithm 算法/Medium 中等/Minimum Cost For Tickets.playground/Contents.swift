import UIKit
//https://leetcode-cn.com/problems/minimum-cost-for-tickets/

func mincostTickets(_ days: [Int], _ costs: [Int]) -> Int {
    if days.count == 0 {
        return 0
    }
    
    var dpArray = Array(repeating: 366 * days.last!, count: days.last! + 1)
    dpArray[0] = 0
    for idx1 in 1..<dpArray.count {
        let one = dpArray[idx1 - 1] + costs[0]
        let seven = idx1 > 7 ? dpArray[idx1 - 7] + costs[1] : costs[1]
        let thirteen = idx1 > 30 ? dpArray[idx1 - 30] + costs[2] : costs[2]
        
        dpArray[idx1] = min(one, min(seven, thirteen))
    }
    return dpArray.last!
    
}



print(mincostTickets([1,4,6,7,8,20], [2,7,15]))
