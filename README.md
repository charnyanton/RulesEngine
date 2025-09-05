# RulesEngine

**RulesEngine** is a fully generic decision-making engine for Swift.  
It is actor-based and relies on rules that are applied to a mutable context.  
The library helps you describe complex logic with simple and independent rules.

## Features
- **Generic and type-safe**: Works with any context type conforming to `ApplicationContextProtocol`.
- **Priority-based evaluation**: Rules are sorted by priority (lower number = higher priority).
- **Context-driven**: You can update the context at runtime and receive new decisions without touching the rules.
- **Override rules**: Allow replacing overridable decisions made by main rules.
- **Type erasure**: `AnyRule` lets you store heterogeneous rules in a single collection.
- **Modular**: Each unit of logic is encapsulated in its own `evaluate(context:)` method.

## Why use it?
Instead of writing long `if/else` or `switch` chains that quickly become spaghetti code,  
you define a set of small rules. Each rule focuses on one piece of logic inside `evaluate`.  
The engine handles iterating through them by priority, applying overrides, and returning the final decision.

This makes your code:
- readable,  
- easy to test,  
- simple to extend.

## Example
```swift
struct MyContext: ApplicationContextProtocol {
    let userRole: Role
}

enum Role { case admin, guest }

struct AdminRule: RuleProtocol {
    typealias Context = MyContext
    typealias Outcome = String
    
    let priority = 10
    let isOverridable = true
    
    func evaluate(context: MyContext) -> String? {
        return context.userRole == .admin ? "AdminAccess" : nil
    }
}

let fallback = EvaluationResult(decision: "GuestAccess", reason: AnyRule(AdminRule()))
let engine = RulesEngine(
    rules: [AnyRule(AdminRule())],
    overrideRules: [],
    fallback: fallback,
    defaultContext: MyContext(userRole: .guest)
)

let outcome = await engine.makeOutcome()
print(outcome.decision) // "GuestAccess"
