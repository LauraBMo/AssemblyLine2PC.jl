# Distribution Chain Optimization Interface

A minimal interface for optimizing distribution chains in AssemblyLine2PC using MetaGraphsNext.jl and AbstractTrees.jl.

## Overview

This module provides tools to:
1. Parse tree specifications representing distribution chains
2. Build MetaGraph representations using MetaGraphsNext
3. Optimize integer split ratios (range 3-100) using a recursive greedy algorithm

## Key Features

- **No `@metadata` macro**: Uses MetaGraphsNext's native `set_prop!` API
- **No child count validation**: Trees can have any number of children
- **Minimal code**: Leverages Graphs.jl and MetaGraphsNext APIs directly
- **AbstractTrees compatible**: Parsed trees are tuple structures compatible with AbstractTrees

## Usage

```julia
using AssemblyLine2PC
using .DistributionChain

# Create recipe and choose item
np = recipe("NProcessor")
it = "Circuit"

# Define tree specification
# Format: [[node_id; children...], ...]
# Leaves are (node_id, recipe_item_index) tuples
tree_spec = [
    [1; 2, (3, 1)],           # Root: child node 2, leaf (3->item 1)
    [2; (4, 2), (5, 3)]       # Node 2: leaves (4->item 2), (5->item 3)
]

# Build distribution graph
G = build_distribution_graph(np, it, tree_spec)

# Optimize distribution chain
results = optimize_distribution_chain(G, np, it; min_ratio=3, max_ratio=100)

# Print results
print_optimization_results(results)
```

## Tree Specification Format

The tree is specified as a vector of node specifications:
- `[node_id; children...]` for internal nodes
- `(node_id, recipe_item_index)` for leaves

Example: `[[1; 2, 3, (4, 5)], [2; (5, 2), 6], ...]`

Where:
- Node 1 (root) has children: node 2, node 3, and leaf (4→recipe item 5)
- Node 2 has: leaf (5→recipe item 2) and child node 6

## API Reference

### Core Functions

- `parse_distribution_tree(tree_spec)`: Parse tree spec into AbstractTrees-compatible tuple
- `build_distribution_graph(np, it, tree_spec)`: Build MetaGraph from recipe and tree
- `optimize_distribution_chain(G, np, it; min_ratio=3, max_ratio=100)`: Find optimal splits

### Utility Functions

- `print_distribution_graph(G)`: Display graph structure
- `print_optimization_results(results)`: Display optimization results

## Graph Structure

The MetaGraph uses these properties:

**Vertex properties:**
- `:node_type` - `:root`, `:internal`, or `:leaf`
- `:node_index` - Original node ID from spec
- `:recipe_item_index` - For leaves: which recipe item this feeds
- `:split_ratios` - For internal nodes: optimized integer ratios

**Edge properties:**
- `:flow_ratio` - Integer flow ratio on this edge

**Graph-level metadata:**
- `:graph_info` - Description string
- `:item` - The item being distributed
- `:recipe_root` - Root of the recipe

## Algorithm

The optimizer uses a recursive greedy approach:
1. Start from root, traverse depth-first
2. For each internal node, calculate target proportions for subtrees
3. Find integer ratios in [min_ratio, max_ratio] that best match targets
4. Use iterative refinement to minimize error
5. Store results and update graph properties

## Testing

Run the test suite:
```julia
include("test/TestDistributionChain.jl")
using .TestDistributionChain
run_all_tests()
```

## Dependencies

- MetaGraphsNext.jl - Graph representation with metadata
- AbstractTrees.jl - Tree iteration utilities
- Graphs.jl - Graph algorithms
