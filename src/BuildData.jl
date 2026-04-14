## Needs Data.jl, depends on it.
export datatree, autocomplete_keys

allkeys() = mapreduce(mk -> collect(keys(mk)), vcat, RECIPES)
function autocomplete_keys()
    key_strings = unique!(allkeys())
    return (; zip(Symbol.(key_strings), key_strings)...)
end

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
    # for v in topological_sort_by_dfs(data)
    #     node = label_for(data, v)
    #     # Get final tuple, ensure right order!
    #     costs = vertex_costs(data, node)
    #     data[node] = costs
    # end
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
    vertex_data_type=Nothing,
    edge_data_type=Int64,  # How many [u] of target requires the source's recipe.
    graph_data="Full data graph",  # tag for the whole graph
)

# tier 0; amount none
# const MATERIAL_COUNT = length(raw_materials)
# const MATERIAL_COUNT = 7
# init_data(::Type{T}=Int) where T = ntuple(_ -> zero(T), Val(MATERIAL_COUNT))
init_data(::Type{T}=Int) where T = nothing
function build_skeletontree!(tree, maker_recipes)
    for (name, recipe) in maker_recipes
        tree[name] = init_data()
        for (iname, n) in recipe
            tree[iname] = init_data()
            tree[name, iname] = n
        end
    end
end

