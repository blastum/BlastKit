import Testing
@testable import SwiftEase

@Test func optionalOr_withNonNilValue_returnsOriginalValue() {
    let value: String? = "Hello"
    let result = value.or("Default")
    
    #expect(result == "Hello")
    #expect(type(of: result) == String.self) // Verify de-optionalization
}

@Test func optionalOr_withNilValue_returnsDefaultValue() {
    let value: String? = nil
    let result = value.or("Default")
    
    #expect(result == "Default")
    #expect(type(of: result) == String.self) // Verify de-optionalization
}

@Test func optionalOr_withIntegerTypes_worksCorrectly() {
    let nilInt: Int? = nil
    let validInt: Int? = 42
    
    #expect(nilInt.or(0) == 0)
    #expect(validInt.or(0) == 42)
}

@Test func optionalOr_withComplexTypes_maintainsTypeInformation() {
    struct Person {
        let name: String
    }
    
    let nilPerson: Person? = nil
    let validPerson: Person? = Person(name: "Alice")
    let defaultPerson = Person(name: "Anonymous")
    
    let result1 = nilPerson.or(defaultPerson)
    let result2 = validPerson.or(defaultPerson)
    
    #expect(result1.name == "Anonymous")
    #expect(result2.name == "Alice")
}

@Test func optionalOr_withAutoclosureEvaluation_onlyEvaluatesWhenNeeded() {
    var evaluationCount = 0
    
    func expensiveOperation() -> String {
        evaluationCount += 1
        return "Expensive"
    }
    
    // Test with non-nil value - autoclosure should NOT be evaluated
    let validValue: String? = "Valid"
    let result1 = validValue.or(expensiveOperation())
    
    #expect(result1 == "Valid")
    #expect(evaluationCount == 0) // Autoclosure was not evaluated
    
    // Test with nil value - autoclosure SHOULD be evaluated
    let nilValue: String? = nil
    let result2 = nilValue.or(expensiveOperation())
    
    #expect(result2 == "Expensive")
    #expect(evaluationCount == 1) // Autoclosure was evaluated once
}

@Test func optionalOr_canBeChainedWithOtherMethods() {
    let values: [String?] = ["hello", nil, "world"]
    
    let result = values
        .map { $0.or("empty") }
        .filter { !$0.isEmpty }
        .map { $0.uppercased() }
    
    #expect(result == ["HELLO", "EMPTY", "WORLD"])
}

@Test func optionalOr_withDifferentWrappedTypes_compilesCorrectly() {
    // Test various types to ensure generic behavior
    let optionalDouble: Double? = nil
    let optionalBool: Bool? = true
    let optionalArray: [Int]? = nil
    
    #expect(optionalDouble.or(3.14) == 3.14)
    #expect(optionalBool.or(false) == true)
    #expect(optionalArray.or([1, 2, 3]) == [1, 2, 3])
}

// MARK: - isSet Tests

@Test func optionalIsSet_withNonNilValue_returnsTrue() {
    let value: String? = "Hello"
    
    #expect(value.isSet == true)
}

@Test func optionalIsSet_withNilValue_returnsFalse() {
    let value: String? = nil
    
    #expect(value.isSet == false)
}

@Test func optionalIsSet_withDifferentTypes_worksCorrectly() {
    let string: String? = "test"
    let nilString: String? = nil
    let number: Int? = 42
    let nilNumber: Int? = nil
    let array: [Int]? = [1, 2, 3]
    let nilArray: [Int]? = nil
    
    #expect(string.isSet == true)
    #expect(nilString.isSet == false)
    #expect(number.isSet == true)
    #expect(nilNumber.isSet == false)
    #expect(array.isSet == true)
    #expect(nilArray.isSet == false)
}

// MARK: - isNil Tests

@Test func optionalIsNil_withNonNilValue_returnsFalse() {
    let value: String? = "Hello"
    
    #expect(value.isNil == false)
}

@Test func optionalIsNil_withNilValue_returnsTrue() {
    let value: String? = nil
    
    #expect(value.isNil == true)
}

@Test func optionalIsNil_withDifferentTypes_worksCorrectly() {
    let string: String? = "test"
    let nilString: String? = nil
    let number: Int? = 42
    let nilNumber: Int? = nil
    let bool: Bool? = false
    let nilBool: Bool? = nil
    
    #expect(string.isNil == false)
    #expect(nilString.isNil == true)
    #expect(number.isNil == false)
    #expect(nilNumber.isNil == true)
    #expect(bool.isNil == false)
    #expect(nilBool.isNil == true)
}

// MARK: - Combined Usage Tests

@Test func optionalIsSetAndIsNil_areOpposite() {
    let values: [String?] = ["hello", nil, "world", nil]
    
    values.forEach { value in
        #expect(value.isSet != value.isNil)
    }
}

@Test func optionalStateProperties_canBeUsedInFunctionalChains() {
    let values: [String?] = ["hello", nil, "world", nil, "swift"]
    
    let setValues = values
        .filter { $0.isSet }
        .compactMap { $0 }
    
    let nilCount = values
        .filter { $0.isNil }
        .count
    
    #expect(setValues == ["hello", "world", "swift"])
    #expect(nilCount == 2)
}

@Test func optionalStateProperties_workWithNestedOptionals() {
    let nestedOptional: String?? = "nested"
    let nilNestedOptional: String?? = nil
    let partiallyNilNested: String?? = Optional<String>.none
    
    #expect(nestedOptional.isSet == true)
    #expect(nestedOptional.isNil == false)
    
    #expect(nilNestedOptional.isSet == false)
    #expect(nilNestedOptional.isNil == true)
    
    #expect(partiallyNilNested.isSet == true) // The outer optional has a value (which is nil)
    #expect(partiallyNilNested.isNil == false)
} 