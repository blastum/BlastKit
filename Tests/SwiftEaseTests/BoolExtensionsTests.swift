import Testing
@testable import SwiftEase

// MARK: - Bool.if(_:) Tests

@Test func boolIf_withTrueValue_returnsValue() {
    let result = true.if("Success")
    
    #expect(result == "Success")
    #expect(type(of: result) == String?.self)
}

@Test func boolIf_withFalseValue_returnsNil() {
    let result = false.if("Success")
    
    #expect(result == nil)
}

@Test func boolIf_withDifferentTypes_worksCorrectly() {
    let stringResult = true.if("Hello")
    let intResult = true.if(42)
    let arrayResult = false.if([1, 2, 3])
    
    #expect(stringResult == "Hello")
    #expect(intResult == 42)
    #expect(arrayResult == nil)
}

@Test func boolIf_withAutoclosureEvaluation_onlyEvaluatesWhenTrue() {
    var evaluationCount = 0
    
    func expensiveOperation() -> String {
        evaluationCount += 1
        return "Expensive"
    }
    
    // Test with false - autoclosure should NOT be evaluated
    let falseResult = false.if(expensiveOperation())
    #expect(falseResult == nil)
    #expect(evaluationCount == 0)
    
    // Test with true - autoclosure SHOULD be evaluated
    let trueResult = true.if(expensiveOperation())
    #expect(trueResult == "Expensive")
    #expect(evaluationCount == 1)
}

// MARK: - Bool.if(_:else:) Tests

@Test func boolIfElse_withTrueValue_returnsFirstValue() {
    let result = true.if("Success", else: "Failure")
    
    #expect(result == "Success")
    #expect(type(of: result) == String.self)
}

@Test func boolIfElse_withFalseValue_returnsSecondValue() {
    let result = false.if("Success", else: "Failure")
    
    #expect(result == "Failure")
    #expect(type(of: result) == String.self)
}

@Test func boolIfElse_withDifferentTypes_worksCorrectly() {
    let stringResult = true.if("Hello", else: "Goodbye")
    let intResult = false.if(100, else: 0)
    let arrayResult = true.if([1, 2], else: [3, 4])
    
    #expect(stringResult == "Hello")
    #expect(intResult == 0)
    #expect(arrayResult == [1, 2])
}

@Test func boolIfElse_withAutoclosureEvaluation_onlyEvaluatesCorrectBranch() {
    var trueEvaluationCount = 0
    var falseEvaluationCount = 0
    
    func trueOperation() -> String {
        trueEvaluationCount += 1
        return "True"
    }
    
    func falseOperation() -> String {
        falseEvaluationCount += 1
        return "False"
    }
    
    // Test with true - only first autoclosure should be evaluated
    let trueResult = true.if(trueOperation(), else: falseOperation())
    #expect(trueResult == "True")
    #expect(trueEvaluationCount == 1)
    #expect(falseEvaluationCount == 0)
    
    // Reset counters
    trueEvaluationCount = 0
    falseEvaluationCount = 0
    
    // Test with false - only second autoclosure should be evaluated
    let falseResult = false.if(trueOperation(), else: falseOperation())
    #expect(falseResult == "False")
    #expect(trueEvaluationCount == 0)
    #expect(falseEvaluationCount == 1)
}

// MARK: - Functional Usage Tests

@Test func boolIf_canBeChainedWithOtherMethods() {
    let values = [true, false, true, false]
    
    let messages = values
        .compactMap { $0.if("Active") }
    
    let statuses = values
        .map { $0.if("Online", else: "Offline") }
    
    #expect(messages == ["Active", "Active"])
    #expect(statuses == ["Online", "Offline", "Online", "Offline"])
}

@Test func boolIf_worksWithComplexExpressions() {
    let user = (isAdmin: true, isActive: false)
    
    let adminMessage = user.isAdmin.if("Admin privileges granted")
    let activeStatus = user.isActive.if("Active", else: "Inactive")
    
    #expect(adminMessage == "Admin privileges granted")
    #expect(activeStatus == "Inactive")
}

@Test func boolIf_worksWithOptionalChaining() {
    struct User {
        let isVerified: Bool
    }
    
    let user: User? = User(isVerified: true)
    let noUser: User? = nil
    
    let verifiedMessage = user?.isVerified.if("Verified user")
    let noUserMessage = noUser?.isVerified.if("Verified user")
    
    #expect(verifiedMessage == "Verified user")
    #expect(noUserMessage == nil)
}

@Test func boolIf_withSideEffects_executesOnlyWhenAppropriate() {
    var sideEffectExecuted = false
    
    func sideEffect() -> String {
        sideEffectExecuted = true
        return "Side effect"
    }
    
    // Should not execute side effect
    let _ = false.if(sideEffect())
    #expect(sideEffectExecuted == false)
    
    // Should execute side effect
    let _ = true.if(sideEffect())
    #expect(sideEffectExecuted == true)
}

@Test func boolIfElse_withNestedConditionals_worksCorrectly() {
    let isLoggedIn = true
    let isPremium = false
    
    let accessLevel = isLoggedIn.if(
        isPremium.if("Premium", else: "Standard"),
        else: "Guest"
    )
    
    #expect(accessLevel == "Standard")
} 