# [Architecture overview](@id architecture-tour)

```@contents
Pages = ["architecture.md"]
Depth = 3
```

## Data ingestion pipeline

AssemblyLine2PC constructs a layered [`MetaGraph`](https://juliagraphs.org/MetaGraphsNext.jl/stable/) `G`
where vertex are all the items in the game encode as name String.
Weighted edges encode ingredient ratios for its recipe, when `item1` recipe requires `n` units of `item2`, the graph `G` has an edge `item1>n>item2`. 
For example, raw-materials are kind of "leaves".
The `datatree` builder stitches together transformer, maker, and radioactive recipes
from the raw datasets defined in [`Data.jl`](https://github.com/LauraBMo/AssemblyLine2PC.jl/blob/main/src/Data.jl).

1. **Skeleton graph** – [`build_skeletontree`](@ref build_skeletontree) creates vertices for every item with initial zero resource tuples, and adds edges for all recipes.
2. **Cost accumulation** – [`vertex_costs`](@ref vertex_costs) recursively tallies raw
   resource demand (total number of raw-materials units needed to produce 1u of item), storing the result directly on the vertex for constant-time lookups.
3. **Topological traversal** – [`datatree`](@ref datatree) Topological order ensures downstream costs are always available when needed.

!!! tip
    The tuple stored on each vertex aligns with [`raw_materials`](@ref raw_materials).
    Keep this ordering in mind when performing manual indexing, or prefer helper
    functions such as [`cost`](@ref cost) and [`total_material`](@ref) to avoid
    off-by-one mistakes.

## Extending the recipe set

Recipes are grouped by production tier in `RECIPES`. Adding new content usually
requires updating the dataset definitions and optionally attaching annotations to
new vertex types. A typical extension looks like:

```julia
using AssemblyLine2PC

recipes = AssemblyLine2PC.mk3  # start from an existing tier
push!(recipes, "FusionCell" => [("SuperAlloy", 2), ("CryoFuel", 1)])

tree = datatree()
vertex_data = tree["FusionCell"]
```

Because the graph is recomputed from scratch, modifications remain deterministic
and cache-friendly for documentation builds and tests.

## Related API

```@docs
build_skeletontree
datatree
vertex_costs
vertex_costs!
```
