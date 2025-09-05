//
//  RulesEngineProtocol.swift
//  RulesEngine
//
//  Created by Anton Charny on 5.09.25.
//


/// Protocol defining the interface for a generic decision maker actor.
protocol RulesEngineProtocol: Actor {
    /// The context type used for decision evaluation.
    associatedtype Context: ApplicationContextProtocol

    /// The rule type managed by this decision maker.
    associatedtype Rule: RuleProtocol where Rule.Context == Context

    /// Computes and returns a new decision along with its triggering rule.
    func makeOutcome() -> EvaluationResult<Rule>

    /// Adds a new main rule.
    func addRule(_ rule: Rule)

    /// Adds a new override rule.
    func addOverrideRule(_ rule: Rule)

    /// Removes rules matching the given predicate from both main and override sets.
    func removeRules(where predicate: (Rule) -> Bool)
    
    /// Returns the last computed decision, if any.
    func getActualDecision() -> EvaluationResult<Rule>?
}
