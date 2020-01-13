import UIKit


public class ListNode {
  public var val: Int
  public var next: ListNode?
  public init(_ val: Int) {
      self.val = val
      self.next = nil
  }
}


func reverseList(_ head: ListNode?) -> ListNode? {
    guard var theHead = head else {
        return nil;
    }
    var indexNode :ListNode?
    var lastNode : ListNode = ListNode.init(theHead.val)
    lastNode.next = nil
    while let next = theHead.next {
        indexNode = ListNode.init(next.val);
        indexNode?.next = lastNode
        lastNode = indexNode!;
        theHead = next
    }
    return lastNode
}
