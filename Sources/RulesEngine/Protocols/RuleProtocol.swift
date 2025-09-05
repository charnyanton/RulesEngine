//
//  RuleProtocol.swift
//  RulesEngine
//
//  Created by Anton Charny on 5.09.25.
//


/// Protocol defining a generic decision rule.
protocol RuleProtocol: Sendable {
    /// The associated context type that this rule can evaluate against.
    associatedtype Context: ApplicationContextProtocol

    /// The type of decision returned by this rule.
    associatedtype Outcome: Sendable

    /// Lower value = higher priority.
    var priority: Int { get }

    /// Indicates whether this rule can be overridden by override rules.
    var isOverridable: Bool { get }

    /// Evaluates the rule against the provided context.
    /// - Parameter context: The context to evaluate.
    /// - Returns: A decision if the rule applies; otherwise, nil.
    func evaluate(context: Context) -> Outcome?
}
