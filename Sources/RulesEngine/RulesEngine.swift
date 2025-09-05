//
//  RulesEngine.swift
//  RulesEngine
//
//

/// Generic actor that manages rules and evaluates decisions.
final actor RulesEngine<Context: ApplicationContextProtocol,
                        Rule: RuleProtocol>: RulesEngineProtocol where Rule.Context == Context {
    
    // MARK: - Private variables
    /// Sorted list of main rules by priority (lower value = higher priority).
    private var rules: [Rule]
    
    /// Sorted list of override rules by priority (lower value = higher priority).
    private var overrideRules: [Rule]
    
    /// The context used for evaluating rules.
    private var context: Context
    
    /// Default fallback decision if no rules match.
    private let fallback: EvaluationResult<Rule>
    
    /// The last decision computed by `makeDecision()`.
    internal private(set) var lastOutcome: EvaluationResult<Rule>?
    
    // MARK: - Init
    /// Initializes a new generic decision maker with given rules and context.
    /// - Parameters:
    ///   - rules: Initial set of main rules.
    ///   - overrideRules: Initial set of override rules.
    ///   - fallback: Fallback decision if no rules apply.
    ///   - defaultContext: Initial context for evaluations.
    init(
        rules: [Rule] = [],
        overrideRules: [Rule] = [],
        fallback: EvaluationResult<Rule>,
        defaultContext: Context
    ) {
        // Sort rules by priority on initialization.
        self.rules = rules.sorted { $0.priority < $1.priority }
        self.overrideRules = overrideRules.sorted { $0.priority < $1.priority }
        self.fallback = fallback
        self.context = defaultContext
    }
    
    // MARK: - Internal methods
    
    /// Computes and returns a new decision based on current rules and context.
    internal func makeOutcome() -> EvaluationResult<Rule> {
        // Compute the decision and store it.
        let result = self.computeOutcome()
        self.lastOutcome = result
        return result
    }
    
    /// Adds a new main rule and re-sorts the rules by priority.
    /// - Parameter rule: The rule to add.
    internal func addRule(_ rule: Rule) {
        self.rules.append(rule)
        self.rules.sort { $0.priority < $1.priority }
    }
    
    /// Adds a new override rule and re-sorts override rules by priority.
    /// - Parameter rule: The override rule to add.
    internal func addOverrideRule(_ rule: Rule) {
        self.overrideRules.append(rule)
        self.overrideRules.sort { $0.priority < $1.priority }
    }
    
    /// Removes rules matching the given predicate from both main and override rule sets.
    /// - Parameter predicate: A closure that returns true for rules to remove.
    internal func removeRules(where predicate: (Rule) -> Bool) {
        self.rules.removeAll(where: predicate)
        self.overrideRules.removeAll(where: predicate)
        self.rules.sort { $0.priority < $1.priority }
        self.overrideRules.sort { $0.priority < $1.priority }
    }
    
    /// Returns the last decision computed by the actor.
    internal func getActualDecision() -> EvaluationResult<Rule>? {
        return self.lastOutcome
    }
    
    /// Updates the internal context used for decision evaluation.
    /// - Parameter context: The new context to use.
    internal func updateContext(_ context: Context) {
        self.context = context
    }
    
    // MARK: - Private methods
    
    /// Internal method to compute the effective decision, applying main rules first and then override rules.
    /// - Returns: The final decision with its triggering rule.
    private func computeOutcome() -> EvaluationResult<Rule> {
        // Evaluate main rules first.
        guard let decision = self.evaluateMainRules(context: self.context) else {
            // No main rules matched; return fallback.
            return self.fallback
        }
        
        // If the decision is not overridable, return it.
        guard decision.reason.isOverridable else {
            return decision
        }
        
        // Check override rules in order.
        for overrideRule in self.overrideRules {
            if let overrideDecision = overrideRule.evaluate(context: self.context) {
                // Return the first matching override decision.
                return EvaluationResult(decision: overrideDecision, reason: overrideRule)
            }
        }
        
        // No override rules applied; return the main decision.
        return decision
    }
    
    /// Iterates through main rules and returns the first matching decision.
    /// - Parameter context: The context to evaluate rules against.
    /// - Returns: A decision with its triggering rule, or nil if none match.
    private func evaluateMainRules(context: Context) -> EvaluationResult<Rule>? {
        for rule in self.rules {
            if let decision = rule.evaluate(context: context) {
                // Found a matching rule; return its decision.
                return EvaluationResult(decision: decision, reason: rule)
            }
        }
        // No rules matched; return nil.
        return nil
    }
}
