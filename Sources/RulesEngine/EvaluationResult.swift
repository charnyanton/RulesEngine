//
//  EvaluationResult.swift
//  RulesEngine
//
//  Created by Anton Charny on 5.09.25.
//


/// Encapsulates a decision result and the rule that triggered it.
struct EvaluationResult<Rule: RuleProtocol>: Sendable {
    /// The decision produced by the rule.
    let decision: Rule.Outcome

    /// The rule that generated the decision.
    let reason: Rule
}
