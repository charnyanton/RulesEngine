//
//  AnyRule.swift
//  RulesEngine
//
//

import Foundation

// Type-erased wrapper for any Rule, with tracking original rule type
struct AnyRule<Context: ApplicationContextProtocol, Outcome>: RuleProtocol {

    // MARK: - Internal properties
    internal let priority: Int
    internal let isOverridable: Bool

    // MARK: - Private properties
    private let evaluator: @Sendable (Context) -> Outcome?
    private let ruleType: Any.Type

    // MARK: - Init
    init<Rule: RuleProtocol>(_ rule: Rule) where Rule.Context == Context, Rule.Outcome == Outcome {
        self.priority = rule.priority
        self.isOverridable = rule.isOverridable
        self.evaluator = rule.evaluate
        self.ruleType = Rule.self
    }

    // MARK: - Methods
    func evaluate(context: Context) -> Outcome? {
        return self.evaluator(context)
    }

    /// Returns true if this wrapper was created from a rule of the given type
    func isRuleType(_ type: Any.Type) -> Bool {
        return self.ruleType == type
    }
}

extension AnyRule: CustomStringConvertible {
    var description: String {
        return String(describing: self.ruleType)
    }
}
