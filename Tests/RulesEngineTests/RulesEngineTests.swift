import Testing
@testable import RulesEngine

// Minimal usage tests for AnyRule and RuleProtocol

@Suite("RulesEngineTests")
struct RulesEngineTests {
    
    @Test
    func testPriorityOrdering() async {
        let ctxB = SampleContext(outcome: .b)
        let anyA = AnyRule(RuleA())
        let anyB = AnyRule(RuleB())

        // A has priority 10, B has 20, but for ctxFalse only B fires
        let main = [anyB, anyA] // intentionally shuffled
        let fallback = EvaluationResult(decision: .x, reason: anyA)
        let engine = RulesEngine(rules: main, overrideRules: [], fallback: fallback, defaultContext: ctxB)
        let result = await engine.makeOutcome()
        #expect(result.decision == .b)
        #expect(result.reason.isRuleType(RuleB.self))
    }

    @Test
    func testOverridePath() async {
        let ctxA = SampleContext(outcome: .a)
        let anyA = AnyRule(RuleA())
        let anyB = AnyRule(RuleB())
        let anyX = AnyRule(OverrideRuleX())

        // A fires for ctxTrue and is overridable, then X overrides
        let fallback = EvaluationResult(decision: .x, reason: anyA)
        let engine = RulesEngine(rules: [anyB, anyA], overrideRules: [anyX], fallback: fallback, defaultContext: ctxA)
        let result = await engine.makeOutcome()
        #expect(result.decision == .x)
        #expect(result.reason.isRuleType(OverrideRuleX.self))
    }

    @Test
    func testTypeErasureIntrospection() {
        let anyA = AnyRule(RuleA())
        let anyB = AnyRule(RuleB())
        let anyX = AnyRule(OverrideRuleX())

        // isRuleType should match exact original rule type
        #expect(anyA.isRuleType(RuleA.self))
        #expect(anyB.isRuleType(RuleB.self))
        #expect(anyX.isRuleType(OverrideRuleX.self))
        #expect(!anyA.isRuleType(RuleB.self))

        // description should contain type name
        #expect(String(describing: anyA).contains("RuleA"))
        #expect(String(describing: anyX).contains("OverrideRuleX"))
    }

    @Test
    func testFallbackWhenNoRulesFire() async {
        let ctxA = SampleContext(outcome: .a)

        let never = AnyRule(NeverRule())

        let fallback = EvaluationResult(decision: .x, reason: never)
        let engine = RulesEngine(rules: [never], overrideRules: [], fallback: fallback, defaultContext: ctxA)
        let res = await engine.makeOutcome()
        #expect(res.decision == .x)
    }

    @Test
    func testUpdateContext() async {
        let ctxB = SampleContext(outcome: .b)
        let ctxA = SampleContext(outcome: .a)
        let anyA = AnyRule(RuleA())
        let anyB = AnyRule(RuleB())
        let anyX = AnyRule(OverrideRuleX())

        let fallback = EvaluationResult(decision: .x, reason: anyA)
        let engine = RulesEngine(rules: [anyB, anyA], overrideRules: [anyX], fallback: fallback, defaultContext: ctxB)

        // Initially, flag is false, so B fires, But B is overridable, so X ovverides it
        let initialDecision = await engine.makeOutcome()
        #expect(initialDecision.decision == .x)
        #expect(initialDecision.reason.isRuleType(OverrideRuleX.self))

        // Update context to true, now A fires and is overridden by X
        await engine.updateContext(ctxA)
        let updatedDecision = await engine.makeOutcome()
        #expect(updatedDecision.decision == .x)
        #expect(updatedDecision.reason.isRuleType(OverrideRuleX.self))
    }

    @Test
    func testNonOverridableRuleNotOverridden() async {
        let ctxC = SampleContext(outcome: .c)
        let anyA = AnyRule(RuleA())
        let anyB = AnyRule(RuleB())
        let anyC = AnyRule(NonOverridableRuleC())
        let anyX = AnyRule(OverrideRuleX())

        // Only C fires for ctxC and it is not overridable, so X must not override
        let fallback = EvaluationResult(decision: .x, reason: anyA)
        let engine = RulesEngine(rules: [anyA, anyB, anyC], overrideRules: [anyX], fallback: fallback, defaultContext: ctxC)

        let result = await engine.makeOutcome()
        #expect(result.decision == .c)
        #expect(result.reason.isRuleType(NonOverridableRuleC.self))
    }

    @Test
    func testDependencyRuleRespectsFlag() async {
        // Rule should fire if dependencyEnabled is true
        let contextEnabled = SampleContext(outcome: .dependency, dependencyEnabled: true)
        let dependencyRule = AnyRule(DependencyRule())
        let fallback = EvaluationResult(decision: .x, reason: dependencyRule)
        let engineEnabled = RulesEngine(
            rules: [dependencyRule],
            overrideRules: [],
            fallback: fallback,
            defaultContext: contextEnabled
        )
        let resultEnabled = await engineEnabled.makeOutcome()
        #expect(resultEnabled.decision == .dependency)
        #expect(resultEnabled.reason.isRuleType(DependencyRule.self))

        // Rule should not fire if dependencyEnabled is false, fallback should be used
        let contextDisabled = SampleContext(outcome: .dependency, dependencyEnabled: false)
        let engineDisabled = RulesEngine(
            rules: [dependencyRule],
            overrideRules: [],
            fallback: fallback,
            defaultContext: contextDisabled
        )
        let resultDisabled = await engineDisabled.makeOutcome()
        #expect(resultDisabled.decision == .x)
        #expect(resultDisabled.reason.isRuleType(DependencyRule.self))
    }
}



// MARK: - Helpers
private struct SampleContext: ApplicationContextProtocol {
    let outcome: Outcome
    let dependencyEnabled: Bool
    
    enum Outcome: String, Equatable {
        case a
        case b
        case c
        case x
        case dependency
    }
    
    init(outcome: Outcome, dependencyEnabled: Bool = false) {
        self.outcome = outcome
        self.dependencyEnabled = dependencyEnabled
    }
}

private struct RuleA: RuleProtocol {
    // Context that this rule understands
    typealias Context = SampleContext
    // Outcome value produced by this rule
    typealias Outcome = SampleContext.Outcome

    // Lower value means higher priority
    let priority: Int = 10

    // This decision may be overridden
    let isOverridable: Bool = true

    func evaluate(context: SampleContext) -> SampleContext.Outcome? {
        // Fire when flag is true
        return context.outcome == .a ? .a : nil
    }
}

private struct RuleB: RuleProtocol {
    typealias Context = SampleContext
    typealias Outcome = SampleContext.Outcome

    let priority: Int = 20
    let isOverridable: Bool = true

    func evaluate(context: Context) -> SampleContext.Outcome? {
        // Fire when flag is false
        return context.outcome == .b ? .b : nil
    }
}

private struct NonOverridableRuleC: RuleProtocol {
    typealias Context = SampleContext
    typealias Outcome = SampleContext.Outcome

    let priority: Int = 30
    let isOverridable: Bool = false

    func evaluate(context: Context) -> SampleContext.Outcome? {
        // Fire when flag is false
        return context.outcome == .c ? .c : nil
    }
}

private struct OverrideRuleX: RuleProtocol {
    typealias Context = SampleContext
    typealias Outcome = SampleContext.Outcome

    // Override rules can have their own priority order
    let priority: Int = 1
    // Override result cannot be overridden again
    let isOverridable: Bool = false

    func evaluate(context: SampleContext) -> SampleContext.Outcome? {
        // Always overrides when reached
        return .x
    }
}

private struct DependencyRule: RuleProtocol {
    typealias Context = SampleContext
    typealias Outcome = SampleContext.Outcome
    let priority: Int = 15
    let isOverridable: Bool = true
    func evaluate(context: SampleContext) -> SampleContext.Outcome? {
        if context.outcome == .dependency && context.dependencyEnabled {
            return .dependency
        }
        return nil
    }
}

// Build rules that do not fire for this context
private struct NeverRule: RuleProtocol {
    typealias Context = SampleContext
    typealias Outcome = SampleContext.Outcome
    let priority: Int = 5
    let isOverridable: Bool = true
    func evaluate(context: SampleContext) -> SampleContext.Outcome? { return nil }
}


