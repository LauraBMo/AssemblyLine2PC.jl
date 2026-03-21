module TestDistributionChain

# Test module for DistributionChain
# Demonstrates how to use the distribution chain optimization interface

using ..AssemblyLine2PC
using .DistributionChain

"""
    example_usage()

Demonstrates the complete workflow for optimizing a distribution chain.

Example tree specification:
[[1; 2, 3, (4, 5)], [2; (5, 2), 6], [3; (7, 9), (8, 10)], [6; (9, 1), (10, 4), (11, 3)]]

This represents:
- Node 1 (root): has children nodes 2, 3, and leaf (4, 5) meaning node 4 feeds recipe item 5
- Node 2: has leaf (5, 2) and child node 6
- Node 3: has leaves (7, 9) and (8, 10)
- Node 6: has leaves (9, 1), (10, 4), and (11, 3)
"""
function example_usage()
    println("=== Distribution Chain Optimization Example ===\n")

    # Step 1: Create a recipe
    np = recipe("NProcessor")
    println("Recipe created: NProcessor\n")

    # Step 2: Choose an input item
    it = "Circuit"
    println("Analyzing distribution for item: $it\n")

    # First, let's see what the recipe says about this item
    println("Recipe analysis for $it:")
    np(it)
    println()

    # Step 3: Define a distribution tree
    # Format: [[node_id; children...], ...]
    # Leaves are specified as (node_id, recipe_item_index) tuples
    tree_spec = [
        [1; 2, (3, 1)],           # Root node 1: child node 2, leaf (3->item 1)
        [2; (4, 2), (5, 3)]       # Node 2: leaves (4->item 2), (5->item 3)
    ]

    println("Tree specification:")
    println(tree_spec)
    println()

    # Step 4: Build the distribution graph
    G = build_distribution_graph(np, it, tree_spec)
    println("Distribution graph built with $(nv(G)) vertices and $(ne(G)) edges\n")

    # Step 5: Print graph structure using AbstractTrees style
    print_distribution_graph(G)
    println()

    # Step 6: Optimize the distribution chain
    println("Optimizing distribution chain...\n")
    results = optimize_distribution_chain(G, np, it; min_ratio=3, max_ratio=100)

    # Step 7: Print results
    print_optimization_results(results)

    return G, results
end

"""
    complex_example()

A more complex example with multiple levels of distribution.
"""
function complex_example()
    println("\n=== Complex Distribution Chain Example ===\n")

    np = recipe("NProcessor")
    it = "Plate"

    # More complex tree with 3 levels
    tree_spec = [
        [1; 2, 3],                    # Root: two internal children
        [2; (4, 1), (5, 2)],          # Node 2: two leaves
        [3; (6, 3), (7, 4)]           # Node 3: two leaves
    ]

    G = build_distribution_graph(np, it, tree_spec)
    println("Complex graph: $(nv(G)) vertices, $(ne(G)) edges\n")

    print_distribution_graph(G)
    println()

    results = optimize_distribution_chain(G, np, it)
    print_optimization_results(results)

    return G, results
end

"""
    simple_two_branch_example()

Simplest possible case: root with two leaves.
"""
function simple_two_branch_example()
    println("\n=== Simple Two Branch Example ===\n")

    np = recipe("NProcessor")
    it = "Gold"

    # Simplest tree: root with two leaves
    tree_spec = [
        [1; (2, 1), (3, 2)]
    ]

    G = build_distribution_graph(np, it, tree_spec)
    println("Simple graph: $(nv(G)) vertices, $(ne(G)) edges\n")

    print_distribution_graph(G)
    println()

    results = optimize_distribution_chain(G, np, it)
    print_optimization_results(results)

    return G, results
end

"""
    demonstrate_parser()

Shows how the tree parser works with AbstractTrees-compatible output.
"""
function demonstrate_parser()
    println("\n=== Tree Parser Demonstration ===\n")

    tree_spec = [
        [1; 2, (3, 1)],
        [2; (4, 2), (5, 3)]
    ]

    println("Input tree spec:")
    println(tree_spec)
    println()

    parsed = parse_distribution_tree(tree_spec)
    println("Parsed tree (AbstractTrees-compatible tuple structure):")
    println(parsed)
    println()

    # Use AbstractTrees to iterate
    println("Tree nodes (using AbstractTrees.children):")
    for node in AbstractTrees.Leaves(parsed)
        println("  Leaf: $node")
    end
    println()

    return parsed
end

# Run all examples if called directly
function run_all_tests()
    println("="^60)
    println("DISTRIBUTION CHAIN TEST SUITE")
    println("="^60)

    try
        demonstrate_parser()
    catch e
        @warn "Parser demo failed" exception=e
    end

    try
        simple_two_branch_example()
    catch e
        @warn "Simple example failed" exception=e
    end

    try
        example_usage()
    catch e
        @warn "Main example failed" exception=e
    end

    try
        complex_example()
    catch e
        @warn "Complex example failed" exception=e
    end

    println("\n" * "="^60)
    println("ALL TESTS COMPLETED")
    println("="^60)
end

end # module TestDistributionChain
