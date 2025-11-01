import Testing
import Foundation
@testable import SwiftEase

@Test func castable_withStringTypes_castsCorrectly() {
    let value: String = "Hello World"
    let result = value.cast(String.self)
    
    #expect(result == "Hello World")
    #expect(type(of: result) == String?.self)
}

@Test func castable_withStringToOtherType_returnsNil() {
    let value: String = "42"
    let result = value.cast(Int.self)
    
    #expect(result == nil)
}

@Test func castable_withNumericTypes_castsCorrectly() {
    let intValue: Int = 42
    let doubleValue: Double = 3.14
    
    #expect(intValue.cast(Int.self) == 42)
    #expect(intValue.cast(Double.self) == nil) // Int doesn't auto-cast to Double
    #expect(doubleValue.cast(Double.self) == 3.14)
    #expect(doubleValue.cast(Int.self) == nil)
}

@Test func castable_withCollectionTypes_preservesContent() {
    let array: [Int] = [1, 2, 3]
    let dictionary: [String: String] = ["key": "value"]
    let set: Set<Int> = Set([1, 2, 3])
    
    #expect(array.cast([Int].self) == [1, 2, 3])
    #expect(dictionary.cast([String: String].self) == ["key": "value"])
    #expect(set.cast(Set<Int>.self) == Set([1, 2, 3]))
    
    // Test casting to different types
    #expect(array.cast([String].self) == nil)
    #expect(dictionary.cast([Int: Int].self) == nil)
}

@Test func castable_withOptionalValues_handlesCorrectly() {
    let someValue: Int? = 42
    let nilValue: Int? = nil
    
    #expect(someValue.cast(Int.self) == 42)
    #expect(nilValue.cast(Int.self) == nil)
    #expect(someValue.cast(String.self) == nil) // Int can't cast to String
}

@Test func castable_withCustomTypes_worksWithProtocolConformance() {
    struct Person: Castable {
        let name: String
    }
    
    let person = Person(name: "Alice")
    let result = person.cast(Person.self)
    
    #expect(result?.name == "Alice")
}

@Test func castable_canBeChainedWithOtherMethods() {
    let strings: [String] = ["hello", "world"]
    let numbers: [Int] = [42, 100]
    
    let processedStrings = strings
        .compactMap { $0.cast(String.self) }
        .map { $0.uppercased() }
    
    let processedNumbers = numbers
        .compactMap { $0.cast(Int.self) }
        .filter { $0 > 50 }
    
    #expect(processedStrings == ["HELLO", "WORLD"])
    #expect(processedNumbers == [100])
}

@Test func castable_withNSObjectTypes_usesInheritance() {
    let string: NSObject = NSString(string: "test")
    let array: NSObject = NSArray(array: [1, 2, 3])
    
    #expect(string.cast(NSString.self) != nil)
    #expect(array.cast(NSArray.self) != nil)
    #expect(string.cast(NSArray.self) == nil)
}

@Test func castable_withProtocolTypes_maintainsPolymorphism() {
    protocol Drawable {
        func draw()
    }
    
    struct Circle: Drawable, Castable {
        func draw() {}
    }
    
    struct Square: Drawable, Castable {
        func draw() {}
    }
    
    let circle = Circle()
    let square = Square()
    
    #expect(circle.cast(Drawable.self) != nil)
    #expect(square.cast(Drawable.self) != nil)
    #expect(circle.cast(Square.self) == nil)
}

@Test func castable_withNestedOptionals_handlesCorrectly() {
    let nestedOptional: Int?? = 42
    let nilNestedOptional: Int?? = nil
    
    #expect(nestedOptional.cast(Int.self) == 42)
    #expect(nilNestedOptional.cast(Int.self) == nil)
} 