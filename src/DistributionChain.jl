module DistributionChain

using Graphs
using MetaGraphsNext
using AbstractTrees

export build_distribution_graph, parse_distribution_tree
export optimize_distribution_chain, SplitResult

# ==================== Data Structures ====================

"""
    SplitResult

Result of optimization for a single node containing:
- node_id: The vertex ID in the graph
- split_ratios: Vector of integers in range [3, 100] for each branch
- efficiency: How well the splits match target proportions (0-1)
- flow_to_leaves: Dict mapping recipe_item_index to flow proportion
"""
struct SplitResult
    node_id::Int
    split_ratios::Vector{Int}
    efficiency::Float64
    flow_to_leaves::Dict{Int, Float64}
end

# ==================== Parsing Tree Representation ====================

"""
    parse_distribution_tree(tree_spec)

Parse a tree specification like [[1; 2, 3, (4, 5)], [2; (5, 2), 6], ...]
into a nested tuple structure compatible with AbstractTrees.

Format: [node_id; children...] where:
- children can be node_ids (internal nodes referenced later)
- or (node_id, recipe_item_index) tuples for leaves

Returns a root node as (node_id, children...) where leaves are (node_id, recipe_idx)
"""
function parse_distribution_tree(tree_spec::AbstractVector)
    if isempty(tree_spec)
        return (0,)
    end
    
    # Build a map of node_id -> spec
    node_map = build_node_map(tree_spec)
    
    # Parse root (first spec)
    root_spec = tree_spec[1]
    return parse_node_spec(root_spec, node_map)
end

"""
    build_node_map(tree_spec)

Build a dictionary mapping node IDs to their specifications.
"""
function build_node_map(tree_spec::AbstractVector)
    node_map = Dict{Int, Any}()
    for spec in tree_spec
        if spec isa AbstractVector && length(spec) >= 1
            node_id = Int(spec[1])
            node_map[node_id] = spec
        end
    end
    return node_map
end

"""
    parse_node_spec(spec, node_map)

Parse a single node specification into a tuple structure.
"""
function parse_node_spec(spec::AbstractVector, node_map::Dict)
    if length(spec) < 1
        return (0,)
    end
    
    node_id = Int(spec[1])
    
    if length(spec) == 1
        return (node_id,)
    end
    
    children_specs = spec[2:end]
    children = parse_children(children_specs, node_map)
    
    return (node_id, children...)
end

"""
    parse_children(children_specs, node_map)

Parse all children specifications for a node.
"""
function parse_children(children_specs::AbstractVector, node_map::Dict)
    children = Any[]
    for child_spec in children_specs
        child = parse_single_child(child_spec, node_map)
        if child !== nothing
            push!(children, child)
        end
    end
    return children
end

"""
    parse_single_child(child_spec, node_map)

Parse a single child specification. Returns nothing if invalid.
"""
function parse_single_child(child_spec, node_map::Dict)
    if child_spec isa Tuple && length(child_spec) == 2
        # Leaf node: (node_id, recipe_item_index)
        return (Int(child_spec[1]), Int(child_spec[2]))
    elseif child_spec isa Integer
        # Reference to another internal node
        if haskey(node_map, Int(child_spec))
            return parse_node_spec(node_map[Int(child_spec)], node_map)
        end
    elseif child_spec isa AbstractVector
        # Inline node specification
        return parse_node_spec(child_spec, node_map)
    end
    return nothing
end

# ==================== Building Distribution Graph ====================

"""
    build_distribution_graph(np::Recipe, it::String, tree_spec)

Build a MetaGraph distribution chain from:
- np: A recipe (e.g., recipe("NProcessor"))
- it: The input item name
- tree_spec: Tree specification like [[1; 2, 3, (4, 5)], [2; (5, 2), 6], ...]

The graph uses MetaGraphsNext's native metadata system:
- Vertex properties: :node_type, :node_index, :recipe_item_index, :split_ratios
- Edge properties: :flow_ratio

Returns a MetaGraph with DiGraph backbone.
"""
function build_distribution_graph(np, it::String, tree_spec::AbstractVector)
    # Get the recipe output to understand leaf targets
    recipe_result = np(it)
    
    # Parse the tree structure using AbstractTrees-compatible format
    root_node = parse_distribution_tree(tree_spec)
    
    # Create the MetaGraph using MetaGraphsNext's constructor
    G = MetaGraph(DiGraph(); label_type=Int)
    
    # Set graph-level metadata
    G[:graph_info] = "Distribution chain for $(it)"
    G[:item] = it
    G[:recipe_root] = np.root
    
    # Build the graph recursively
    node_counter = Ref(1)
    build_graph_from_node!(G, root_node, node_counter, nothing)
    
    return G
end

function build_graph_from_node!(G::MetaGraph, node::Tuple, 
                                 counter::Ref{Int}, parent::Union{Nothing, Int})
    current_id = counter[]
    counter[] += 1
    
    node_id = node[1]
    
    if length(node) == 2 && node[2] isa Integer
        # Leaf node: (node_id, recipe_item_index)
        recipe_item_index = node[2]
        
        add_vertex!(G, current_id)
        G[current_id, :node_type] = :leaf
        G[current_id, :node_index] = node_id
        G[current_id, :recipe_item_index] = recipe_item_index
        G[current_id, :split_ratios] = Int[]
        
        if parent !== nothing
            add_edge!(G, parent, current_id)
            G[parent, current_id, :flow_ratio] = 1
        end
    else
        # Internal node (root or intermediate)
        # node = (node_id, child1, child2, ...)
        node_type = parent === nothing ? :root : :internal
        
        add_vertex!(G, current_id)
        G[current_id, :node_type] = node_type
        G[current_id, :node_index] = node_id
        G[current_id, :recipe_item_index] = 0
        G[current_id, :split_ratios] = Int[]
        
        if parent !== nothing
            add_edge!(G, parent, current_id)
            G[parent, current_id, :flow_ratio] = 1
        end
        
        # Process children (node[2:end])
        for i in 2:length(node)
            child = node[i]
            build_graph_from_node!(G, child, counter, current_id)
        end
        
        # Initialize split ratios after children are added
        child_ids = outneighbors(G, current_id)
        G[current_id, :split_ratios] = ones(Int, length(child_ids))
    end
end

# ==================== Optimization ====================

"""
    optimize_distribution_chain(G::MetaGraph, np, it::String; 
                                min_ratio=3, max_ratio=100)

Main optimization function that finds optimal integer split ratios for the entire
distribution chain using a simple recursive greedy approach.

Arguments:
- G: Distribution graph built by build_distribution_graph
- np: Recipe object
- it: Input item name
- min_ratio: Minimum ratio value (default: 3)
- max_ratio: Maximum ratio value (default: 100)

Returns a vector of SplitResult for each internal node.

Uses target proportions from the recipe graph to determine optimal splits.
"""
function optimize_distribution_chain(G::MetaGraph, np, it::String; 
                                      min_ratio::Int=3, max_ratio::Int=100)
    results = SplitResult[]
    
    # Get target proportions from recipe graph
    targets = get_recipe_targets(np, it)
    
    # Find root vertex
    root_id = find_root(G)
    
    # Recursively optimize from root
    optimize_node_recursive!(G, root_id, targets, results, 1.0, min_ratio, max_ratio)
    
    return results
end

"""
    get_recipe_targets(np, it::String)

Extract target proportions for items that need the input item `it`.
Returns Dict{recipe_item_index => proportion}
"""
function get_recipe_targets(np, it::String)
    neighbors = outneighbors(G_recipe, it)

    if isempty(neighbors)
        return Dict{Int, Float64}()
    end

    # Get proportions (edge weights in recipe graph)
    targets = extract_neighbor_proportions(G_recipe, it, neighbors)

    # Normalize to sum to 1
    return normalize_targets(targets)
end

"""
    extract_neighbor_proportions(G_recipe, it, neighbors)

Extract proportions from recipe graph neighbors.
"""
function extract_neighbor_proportions(G_recipe, it::String, neighbors)
    targets = Dict{Int, Float64}()
    for (idx, neighbor) in enumerate(neighbors)
        proportion = G_recipe[it, neighbor]
        targets[idx] = proportion
    end
    return targets
end

"""
    normalize_targets(targets)

Normalize target proportions to sum to 1.
"""
function normalize_targets(targets::Dict{Int, Float64})
    total = sum(values(targets))
    for key in keys(targets)
        targets[key] /= total
    end
    return targets
end
    
    # Get proportions (edge weights in recipe graph)
    targets = Dict{Int, Float64}()
    for (idx, neighbor) in enumerate(neighbors)
        proportion = G_recipe[it, neighbor]
        targets[idx] = proportion
    end
    
    # Normalize to sum to 1
    total = sum(values(targets))
    for key in keys(targets)
        targets[key] /= total
    end
    
    return targets
end

function find_root(G::MetaGraph)::Int
    return search_for_root_vertex(G)
end

"""
    search_for_root_vertex(G)

Search for the root vertex in the distribution graph.
"""
function search_for_root_vertex(G::MetaGraph)
    for v in vertices(G)
        if G[v, :node_type] == :root
            return v
        end
    end
    error("No root node found in distribution graph")
end
    end
    error("No root node found in distribution graph")
end

"""
    optimize_node_recursive!(G, node_id, targets, results, inflow, min_ratio, max_ratio)

Recursively optimize split ratios for a node and its descendants.
Uses a greedy approach to find integer ratios that best match
target proportions while respecting the [min_ratio, max_ratio] bounds.
"""
function optimize_node_recursive!(G::MetaGraph, node_id::Int, 
                                   targets::Dict{Int, Float64},
                                   results::Vector{SplitResult},
                                   inflow::Float64,
                                   min_ratio::Int, max_ratio::Int)
    node_type = G[node_id, :node_type]
    
    if node_type == :leaf
        return handle_leaf_optimization(G, node_id, inflow)
    end
    
    children = outneighbors(G, node_id)
    
    if isempty(children)
        return empty_leaf_flows()
    end
    
    # Optimize this node
    optimal_ratios = compute_node_splits(G, children, targets, min_ratio, max_ratio)
    
    # Update graph properties
    update_node_properties!(G, node_id, children, optimal_ratios)
    
    # Distribute flow to children
    flow_to_children = distribute_flow(inflow, optimal_ratios)
    
    # Recursively optimize children and collect leaf flows
    leaf_flows = optimize_children_recursive!(G, children, targets, results, 
                                               flow_to_children, min_ratio, max_ratio)
    
    # Calculate efficiency and store result
    efficiency = calculate_efficiency(leaf_flows, targets)
    push!(results, SplitResult(node_id, optimal_ratios, efficiency, leaf_flows))
    
    return leaf_flows
end

"""
    handle_leaf_optimization(G, node_id, inflow)

Handle leaf node: return flow mapping for this leaf.
"""
function handle_leaf_optimization(G::MetaGraph, node_id::Int, inflow::Float64)
    recipe_idx = G[node_id, :recipe_item_index]
    return Dict(recipe_idx => inflow)
end

"""
    compute_node_splits(G, children, targets, min_ratio, max_ratio)

Compute optimal split ratios for an internal node.
"""
function compute_node_splits(G::MetaGraph, children::Vector{Int},
                              targets::Dict{Int, Float64},
                              min_ratio::Int, max_ratio::Int)
    child_targets = collect_subtree_targets(G, children, targets)
    total_target = sum(child_targets)
    
    if total_target > 0
        return find_optimal_ratios(child_targets, min_ratio, max_ratio)
    else
        n_children = length(children)
        mid_ratio = div(min_ratio + max_ratio, 2)
        return fill(mid_ratio, n_children)
    end
end

"""
    collect_subtree_targets(G, children, all_targets)

Collect target flows for each child subtree.
"""
function collect_subtree_targets(G::MetaGraph, children::Vector{Int},
                                  all_targets::Dict{Int, Float64})
    return [get_subtree_targets(G, child, all_targets) for child in children]
end

"""
    update_node_properties!(G, node_id, children, optimal_ratios)

Update vertex and edge properties with optimized ratios.
"""
function update_node_properties!(G::MetaGraph, node_id::Int,
                                  children::Vector{Int},
                                  optimal_ratios::Vector{Int})
    set_split_ratios_property!(G, node_id, optimal_ratios)
    set_edge_flow_ratios!(G, node_id, children, optimal_ratios)
end

"""
    set_split_ratios_property!(G, node_id, optimal_ratios)

Set split ratios vertex property.
"""
function set_split_ratios_property!(G::MetaGraph, node_id::Int, optimal_ratios::Vector{Int})
    G[node_id, :split_ratios] = optimal_ratios
end

"""
    set_edge_flow_ratios!(G, node_id, children, optimal_ratios)

Set flow ratio edge properties for all children.
"""
function set_edge_flow_ratios!(G::MetaGraph, node_id::Int, children::Vector{Int}, optimal_ratios::Vector{Int})
    for (i, child) in enumerate(children)
        G[node_id, child, :flow_ratio] = optimal_ratios[i]
    end
end
end

"""
    distribute_flow(inflow, optimal_ratios)

Calculate flow distribution to children based on ratios.
"""
function distribute_flow(inflow::Float64, optimal_ratios::Vector{Int})
    ratio_sum = sum(optimal_ratios)
    return [inflow * r / ratio_sum for r in optimal_ratios]
end

"""
    optimize_children_recursive!(G, children, targets, results, 
                                  flow_to_children, min_ratio, max_ratio)

Recursively optimize all children and merge their leaf flows.
"""
function optimize_children_recursive!(G::MetaGraph, children::Vector{Int},
                                       targets::Dict{Int, Float64},
                                       results::Vector{SplitResult},
                                       flow_to_children::Vector{Float64},
                                       min_ratio::Int, max_ratio::Int)
    return merge_child_leaf_flows(G, children, targets, results, flow_to_children, min_ratio, max_ratio)
end

"""
    merge_child_leaf_flows(G, children, targets, results, flow_to_children, min_ratio, max_ratio)

Optimize all children recursively and merge their leaf flows.
"""
function merge_child_leaf_flows(G::MetaGraph, children::Vector{Int},
                                       targets::Dict{Int, Float64},
                                       results::Vector{SplitResult},
                                       flow_to_children::Vector{Float64},
                                       min_ratio::Int, max_ratio::Int)
    leaf_flows = Dict{Int, Float64}()
    for (i, child) in enumerate(children)
        child_flows = optimize_node_recursive!(G, child, targets, results,
                                                flow_to_children[i], min_ratio, max_ratio)
        merge!(leaf_flows, child_flows)
    end
    return leaf_flows
end
    
    return leaf_flows
end

"""
    get_subtree_targets(G, node_id, all_targets)

Get sum of all target proportions for leaves in this subtree.
"""
function get_subtree_targets(G::MetaGraph, node_id::Int, 
                              all_targets::Dict{Int, Float64})
    node_type = G[node_id, :node_type]

    if node_type == :leaf
        return get_leaf_subtree_target(G, node_id, all_targets)
    end

    # Sum targets from all children
    return sum_children_subtree_targets(G, node_id, all_targets)
end

"""
    get_leaf_subtree_target(G, node_id, all_targets)

Get target for a leaf node.
"""
function get_leaf_subtree_target(G::MetaGraph, node_id::Int, all_targets::Dict{Int, Float64})
    recipe_idx = G[node_id, :recipe_item_index]
    return get(all_targets, recipe_idx, 0.0)
end

"""
    sum_children_subtree_targets(G, node_id, all_targets)

Sum subtree targets from all children of an internal node.
"""
function sum_children_subtree_targets(G::MetaGraph, node_id::Int, all_targets::Dict{Int, Float64})
    total = 0.0
    for child in outneighbors(G, node_id)
        total += get_subtree_targets(G, child, all_targets)
    end
    return total
end
    
    # Sum targets from all children
    total = 0.0
    for child in outneighbors(G, node_id)
        total += get_subtree_targets(G, child, all_targets)
    end
    return total
end

"""
    empty_leaf_flows()

Return an empty dictionary for leaf flows.
"""
function empty_leaf_flows()
    return Dict{Int, Float64}()
end

"""
    find_optimal_ratios(target_flows, min_ratio, max_ratio)

Find integer ratios in [min_ratio, max_ratio] that best approximate
the given target flow proportions.

Uses a simple proportional rounding approach with iterative refinement.
"""
function find_optimal_ratios(target_flows::Vector{Float64}, 
                              min_ratio::Int, max_ratio::Int)
    n = length(target_flows)
    
    if n == 0
        return Int[]
    end
    
    if all(==(0.0), target_flows)
        return equal_distribution_ratios(n, min_ratio, max_ratio)
    end
    
    # Normalize targets
    proportions = normalize_proportions(target_flows)
    
    # Initial proportional ratios
    initial_ratios = compute_initial_ratios(proportions, n, min_ratio, max_ratio)
    
    # Refine ratios iteratively
    return refine_ratios(initial_ratios, proportions, min_ratio, max_ratio)
end

"""
    equal_distribution_ratios(n, min_ratio, max_ratio)

Return equal ratios when all targets are zero.
"""
function equal_distribution_ratios(n::Int, min_ratio::Int, max_ratio::Int)
    mid_ratio = div(min_ratio + max_ratio, 2)
    return fill(mid_ratio, n)
end

"""
    normalize_proportions(target_flows)

Normalize target flows to sum to 1.
"""
function normalize_proportions(target_flows::Vector{Float64})
    total = sum(target_flows)
    return target_flows ./ total
end

"""
    compute_initial_ratios(proportions, n, min_ratio, max_ratio)

Compute initial ratios by scaling proportions and clamping to bounds.
"""
function compute_initial_ratios(proportions::Vector{Float64}, n::Int,
                                 min_ratio::Int, max_ratio::Int)
    mid_range = div(min_ratio + max_ratio, 2)
    initial_ratios = proportions .* mid_range .* n
    
    return [clamp(round(Int, r), min_ratio, max_ratio) for r in initial_ratios]
end

"""
    refine_ratios(ratios, proportions, min_ratio, max_ratio)

Iteratively refine ratios to better match target proportions.
"""
function refine_ratios(ratios::Vector{Int}, proportions::Vector{Float64},
                        min_ratio::Int, max_ratio::Int)
    refined_ratios = copy(ratios)
    
    for iteration in 1:10
        improvement = refine_single_step!(refined_ratios, proportions, min_ratio, max_ratio)
        
        if !improvement
            break
        end
    end
    
    return refined_ratios
end

"""
    refine_single_step!(ratios, proportions, min_ratio, max_ratio)

Perform one refinement step. Returns true if improved, false otherwise.
"""
function refine_single_step!(ratios::Vector{Int}, proportions::Vector{Float64},
                              min_ratio::Int, max_ratio::Int)
    ratio_sum = sum(ratios)
    actual_proportions = ratios ./ ratio_sum
    errors = proportions .- actual_proportions
    
    max_error_idx = argmax(abs.(errors))
    
    if errors[max_error_idx] > 0 && ratios[max_error_idx] < max_ratio
        ratios[max_error_idx] += 1
        return true
    elseif errors[max_error_idx] < 0 && ratios[max_error_idx] > min_ratio
        ratios[max_error_idx] -= 1
        return true
    else
        return false
    end
end

"""
    calculate_efficiency(actual_flows, targets)

Calculate how well the actual flows match targets.
Returns a value between 0 (poor) and 1 (perfect match).
"""
function calculate_efficiency(actual_flows::Dict{Int, Float64}, 
                               targets::Dict{Int, Float64})
    if isempty(targets)
        return 1.0
    end

    total_error = compute_total_flow_error(actual_flows, targets)

    # Convert error to efficiency (1 - normalized_error)
    return clamp_efficiency(total_error, length(targets))
end

"""
    compute_total_flow_error(actual_flows, targets)

Compute total absolute error between actual flows and targets.
"""
function compute_total_flow_error(actual_flows::Dict{Int, Float64}, targets::Dict{Int, Float64})
    total_error = 0.0
    for (key, target) in targets
        actual = get(actual_flows, key, 0.0)
        total_error += abs(actual - target)
    end
    return total_error
end

"""
    clamp_efficiency(total_error, n_targets)

Convert total error to efficiency value clamped to [0, 1].
"""
function clamp_efficiency(total_error::Float64, n_targets::Int)
    efficiency = 1.0 - (total_error / (2 * n_targets))
    return max(0.0, min(1.0, efficiency))
end
    
    total_error = 0.0
    for (key, target) in targets
        actual = get(actual_flows, key, 0.0)
        total_error += abs(actual - target)
    end
    
    # Convert error to efficiency (1 - normalized_error)
    efficiency = 1.0 - (total_error / (2 * length(targets)))
    return max(0.0, min(1.0, efficiency))
end

# ==================== Utility Functions ====================

"""
    print_optimization_results(results::Vector{SplitResult})

Pretty-print optimization results.
"""
function print_optimization_results(results::Vector{SplitResult})
    print_results_header()
    for result in results
        print_single_result(result)
    end
end

"""
    print_results_header()

Print the optimization results header.
"""
function print_results_header()
    println("=== Distribution Chain Optimization Results ===
")
end

"""
    print_single_result(result)

Print a single optimization result.
"""
function print_single_result(result::SplitResult)
    println("Node $(result.node_id):")
    println("  Split ratios: $(result.split_ratios)")
    println("  Efficiency: $(round(result.efficiency, digits=4))")
    println("  Flow to leaves:")
    print_leaf_flows(result.flow_to_leaves)
    println()
end

"""
    print_leaf_flows(flow_to_leaves)

Print flow to leaves dictionary.
"""
function print_leaf_flows(flow_to_leaves::Dict{Int, Float64})
    for (leaf_idx, flow) in sort(collect(flow_to_leaves))
        println("    Item $leaf_idx: $(round(flow, digits=4))")
    end
end
        println()
    end
end

"""
    print_distribution_graph(G::MetaGraph)

Print the structure of a distribution graph using AbstractTrees.
"""
function print_distribution_graph(G::MetaGraph)
    println("Distribution Graph Structure:")
    println("  Item: $(G[:item])")
    println("  Recipe Root: $(G[:recipe_root])")
    println()
    
    root_id = find_root(G)
    print_tree(G, root_id, 0)
end

function print_tree(G::MetaGraph, node_id::Int, indent::Int)
    node_type = G[node_id, :node_type]
    node_index = G[node_id, :node_index]

    prefix = create_indent(indent)
    if node_type == :leaf
        print_leaf_node(prefix, node_index, G[node_id, :recipe_item_index])
    else
        print_internal_node(prefix, node_index, G[node_id, :split_ratios])
        for child in outneighbors(G, node_id)
            print_tree(G, child, indent + 1)
        end
    end
end

"""
    create_indent(indent)

Create indentation string for tree printing.
"""
function create_indent(indent::Int)
    return "  " ^ indent
end

"""
    print_leaf_node(prefix, node_index, recipe_idx)

Print a leaf node in the tree.
"""
function print_leaf_node(prefix::String, node_index::Int, recipe_idx::Int)
    println("Leaf[] -> Recipe item ")
end

"""
    print_internal_node(prefix, node_index, ratios)

Print an internal node in the tree.
"""
function print_internal_node(prefix::String, node_index::Int, ratios::Vector{Int})
    println("Internal[] (ratios: )")
end
    end
end

end # module DistributionChain
