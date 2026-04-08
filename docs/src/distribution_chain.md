# Distribution Chain Optimization Interface

This module provides an interface for optimizing distribution chains in Assembly Line 2 production lines using MetaGraphsNext.jl and AbstractTrees.jl.

## Overview

The `DistributionChain` module helps you model and optimize how resources flow through a production line. Given:
- A recipe (e.g., `recipe("NProcessor")`)
- An input item `it` 
- A tree-graph representing the distribution chain

The optimizer finds the best integer splitting ratios (in range 3:100) to distribute the inflow of item `it` to feed the production of downstream items.

## Tree Graph Format

The distribution chain is specified as a nested array structure:

```julia
tree_spec = [
    [1; 2, 3, (4, 5)],      # Node 1 (root): children nodes 2, 3, and leaf (4→item 5)
    [2; (5, 2), 6],         # Node 2: leaf (5→item 2), child node 6
    [3; (7, 9), (8, 10)],   # Node 3: leaves (7→item 9), (8→item 10)
    [6; (9, 1), (10, 4), (11, 3)]  # Node 6: leaves (9→item 1), (10→item 4), (11→item 3)
]
```

### Syntax Rules:
- `[node_id; children...]` - Internal node specification
- `(leaf_node_id, recipe_item_index)` - Leaf node that feeds the j-th item in the recipe
- Each internal node must have 2-3 children (as per assembly line constraints)
- The first element is always the root node

## Usage

### Basic Example

```julia
using AssemblyLine2PC
using .DistributionChain

# Create a recipe
np = recipe("NProcessor")

# Choose an input item to analyze
it = "Circuit"

# Define distribution tree
tree_spec = [
    [1; 2, (3, 1)],           # Root splits to node 2 and leaf to item 1
    [2; (4, 2), (5, 3)]       # Node 2 splits to leaves for items 2 and 3
]

# Build the distribution graph
G = build_distribution_graph(np, it, tree_spec)

# Optimize split ratios (default range: 3-100)
results = optimize_distribution_chain(G, np, it)

# View results
print_optimization_results(results)
```

### Advanced Example with Custom Optimizer

```julia
# Create optimizer with custom bounds
optimizer = DistributionOptimizer(
    min_ratio=5,      # Minimum split ratio
    max_ratio=50,     # Maximum split ratio  
    tolerance=0.01    # Convergence tolerance
)

# Run optimization
results = optimize_distribution_chain(G, np, it; optimizer=optimizer)
```

## API Reference

### Data Structures

#### `DistributionNode`
Represents a node in the parsed tree structure.
- `is_leaf::Bool` - Whether this is a leaf node
- `children::Vector{DistributionNode}` - Child nodes (for internal nodes)
- `node_id::Int` - Node identifier
- `recipe_item_index::Int` - Which recipe item this leaf feeds (for leaves)

#### `DistributionGraph{T}`
A MetaGraph with specialized vertex and edge metadata:
- **Vertex data**: `DistributionVertex` containing node type, index, and split ratios
- **Edge data**: `DistributionEdge` containing flow ratios

#### `SplitResult`
Optimization result for a single node:
- `node_id::Int` - The optimized node
- `split_ratios::Vector{Int}` - Integer ratios for each branch
- `efficiency::Float64` - How well targets are matched (0-1)
- `flow_to_leaves::Dict{Int, Float64}` - Final flow proportions to each recipe item

#### `DistributionOptimizer`
Configures the optimization:
```julia
optimizer = DistributionOptimizer(min_ratio=3, max_ratio=100, tolerance=0.01)
```

### Functions

#### `parse_distribution_tree(tree_spec::AbstractVector)`
Parse a tree specification into a `DistributionNode` structure.

**Returns**: `DistributionNode` (root of parsed tree)

#### `build_distribution_graph(np::Recipe, it::String, tree_spec::AbstractVector)`
Build a MetaGraph from recipe, item, and tree specification.

**Arguments**:
- `np`: Recipe object (e.g., from `recipe("NProcessor")`)
- `it`: Input item name
- `tree_spec`: Tree specification array

**Returns**: `DistributionGraph`

#### `optimize_distribution_chain(G::DistributionGraph, np, it::String; optimizer=DistributionOptimizer())`
Main optimization function. Finds optimal integer split ratios for the entire chain.

**Arguments**:
- `G`: Distribution graph
- `np`: Recipe object
- `it`: Input item name
- `optimizer`: Optional `DistributionOptimizer` configuration

**Returns**: `Vector{SplitResult}` - optimization results for each internal node

#### `validate_distribution_graph(G::DistributionGraph)`
Validate that the distribution graph is well-formed.

**Returns**: `(is_valid::Bool, message::String)`

#### `print_optimization_results(results::Vector{SplitResult})`
Pretty-print optimization results to stdout.

## How the Optimizer Works

The optimizer uses a recursive greedy approach:

1. **Extract Targets**: From the recipe, determine what proportion of item `it` goes to each downstream item.

2. **Traverse Tree**: Starting from the root, recursively process each internal node.

3. **Calculate Subtree Targets**: For each internal node, sum the target proportions of all leaves in its subtree.

4. **Find Optimal Ratios**: For each node's children, find integer ratios in [min_ratio, max_ratio] that best approximate the relative target proportions.

5. **Refine Iteratively**: Adjust ratios to minimize error between actual and target flows.

6. **Track Efficiency**: Calculate how well the final distribution matches targets.

## Example Output

```
=== Distribution Chain Optimization Results ===

Node 1:
  Split ratios: [45, 35, 20]
  Efficiency: 0.9876
  Flow to leaves:
    Item 1: 0.3333
    Item 2: 0.4167
    Item 3: 0.2500

Node 2:
  Split ratios: [52, 48]
  Efficiency: 0.9945
  Flow to leaves:
    Item 2: 0.5200
    Item 3: 0.4800
```

## Constraints

- Each internal node must have 2-3 children (matching assembly line machine constraints)
- Split ratios must be integers in the range [min_ratio, max_ratio] (default: 3-100)
- The tree must have exactly one root node
- All leaves must reference valid recipe item indices

## Integration with AssemblyLine2PC

The module integrates seamlessly with the existing recipe system:

```julia
using AssemblyLine2PC

# Get recipe
np = recipe("NProcessor")

# Analyze what needs a specific component
np("Circuit")  # Shows which items use Circuit and their proportions

# Use this information to build an optimized distribution chain
tree_spec = [...]  # Design based on factory layout
G = build_distribution_graph(np, "Circuit", tree_spec)
results = optimize_distribution_chain(G, np, "Circuit")
```

## Testing

Run the test examples:

```julia
using AssemblyLine2PC
include("test/TestDistributionChain.jl")
using .TestDistributionChain

# Run examples
example_usage()
complex_example()
simple_two_branch_example()
demonstrate_parser()
```

## Dependencies

- `MetaGraphsNext.jl` - Graph representation with metadata
- `AbstractTrees.jl` - Tree traversal and visualization
- `Graphs.jl` - Graph algorithms

## Future Enhancements

Potential improvements:
- Support for dynamic re-optimization when recipes change
- Multi-objective optimization (e.g., minimize waste, maximize throughput)
- Visualization of distribution graphs
- Export to factory planning tools
- Support for more than 3 children per node (if game mechanics allow)
