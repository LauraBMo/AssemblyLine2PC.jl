using AssemblyLine2PC
using Test

@testset "AssemblyLine2PC.jl" begin
    # Write your tests here.
end

# Include DistributionChain tests
include("TestDistributionChain.jl")

@testset "DistributionChain.jl" begin
    using .TestDistributionChain
    using .DistributionChain
    
    @testset "Parse distribution tree" begin
        tree_spec = [
            [1; 2, (3, 1)],
            [2; (4, 2), (5, 3)]
        ]
        root_node = parse_distribution_tree(tree_spec)
        @test !root_node.is_leaf
        @test length(root_node.children) == 2
    end
    
    @testset "Build distribution graph" begin
        np = recipe("Processor")
        it = "Circuit"
        tree_spec = [
            [1; (2, 1), (3, 2)]
        ]
        G = build_distribution_graph(np, it, tree_spec)
        @test nv(G) >= 1
        is_valid, msg = validate_distribution_graph(G)
        @test is_valid
    end
    
    @testset "Optimize distribution chain" begin
        np = recipe("Processor")
        it = "Circuit"
        tree_spec = [
            [1; (2, 1), (3, 2)]
        ]
        G = build_distribution_graph(np, it, tree_spec)
        optimizer = DistributionOptimizer(3, 100)
        results = optimize_distribution_chain(G, np, it; optimizer=optimizer)
        @test !isempty(results)
        @test all(r -> all(ratio -> 3 <= ratio <= 100, r.split_ratios), results)
    end
    
    @testset "Complex tree example" begin
        tree_spec = [
            [1; 2, 3, (4, 5)],
            [2; (5, 2), 6],
            [3; (7, 9), (8, 10)],
            [6; (9, 1), (10, 4), (11, 3)]
        ]
        root_node = parse_distribution_tree(tree_spec)
        @test !root_node.is_leaf
        @test length(root_node.children) == 3
    end
end
