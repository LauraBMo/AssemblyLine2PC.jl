## Needs Data.jl, depends on it.
export datatree

const RECIPES = [
    recipes_transformers(),
    mk1, mk2, mk3,
    rmk1, rmk2,
]

# const MATERIAL_COUNT = length(raw_materials)
const MATERIAL_COUNT = 7

"""
    datatree()

Construct the complete crafting graph for Assembly Line 2.

The resulting [`MetaGraph`](https://juliagraphs.org/MetaGraphsNext.jl/stable/) stores
per-item resource footprints as vertex metadata so downstream analysis can reuse the
same structure without re-traversing recipe data. The tuple stored on each vertex
aligns with [`raw_materials`](@ref), ensuring deterministic indexing for raw
material accounting and visualization routines.
"""
function datatree()
    ## Create graph with all vertices, vertices-data pre-set to (0,...,0)
    ## and edges 'item1 >n> item2' when 'item1' requires 'n' unites of 'item2'.
    data = build_skeletontree()
    for v in topological_sort_by_dfs(data)
        node = label_for(data, v)
        # Get final tuple, ensure right order!
        costs = vertex_costs(data, node)
        data[node] = costs
    end
    return data
end

"""
    build_skeletontree()

Create an empty recipe graph seeded with vertices for every known item. Edges only
store ingredient ratios; raw-resource footprints are populated later by
[`datatree`](@ref).
"""
function build_skeletontree()
    G = empty_tree()
    ## Add recipes' metadata
    for maker in RECIPES
        build_skeletontree!(G, maker)
    end
    return G
end

empty_tree() = MetaGraph(
    DiGraph();  # initial empty directed graph
    label_type=String,  # Item name
    # 1.- Vertex's high.
    # 2.- How many units of _EACH_ raw material is needed to produce 1u.
    vertex_data_type=NTuple{MATERIAL_COUNT,Int},
    edge_data_type=Int64,  # How many source's recipe requires of target.
    graph_data="Full data graph",  # tag for the whole graph
)

# tier 0; amount none
init_data(::Type{T}=Int) where T = tuple(zeros(T, MATERIAL_COUNT)...)
function build_skeletontree!(tree, maker_recipes)
    for (name, recipe) in maker_recipes
        tree[name] = init_data()
        for (iname, n) in recipe
            tree[iname] = init_data()
            tree[name, iname] = n
        end
    end
end

"""
    vertex_costs!(costs, graph, vertex, speed=1)

Accumulate raw-resource demand for `vertex` into `costs`, scaling contributions by
`speed` units per second.
"""
function vertex_costs!(COSTS, g, v, speed=one(Int))
    # println(v)
    # Cost is a Dict{String, Int} 'C' where 'C["raw-material"] = n. needed for 1u of v'
    neighbors = outneighbor_labels(g, v)
    if isempty(neighbors) # leave of the pseudo-tree
        # v is a raw-material
        COSTS[v] += speed
    else
        for n in neighbors
            vertex_costs!(COSTS, g, n, speed * g[v, n])
        end
        # println(map(n -> vertex_cost(g, n), neighbors))
    end
    return COSTS
end

# Get final tuple, ensure right order!
"""
    vertex_costs(graph, vertex, speed=1)

Return the resource footprint tuple for `vertex`, scaled by `speed` units per
second. The tuple ordering follows [`raw_materials`](@ref).
"""
function vertex_costs(G, v, speed=one(Int))
    # Cost will be a Dict{String, Int} 'C' where 'C["raw-material"] = n' are needed for 1u of v'
    # Initial zeroed cost dict
    cost_dict = Dict(raw_materials .=> init_data(typeof(speed))) 
    # Populate with actual costs
    vertex_costs!(cost_dict, G, v, speed)
    # Return as tuple (following raw_materials order)
    return ([cost_dict[rm] for rm in raw_materials]..., )
end
