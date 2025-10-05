## Needs Data.jl, depends on it.
export datatree

const RECIPES = [
    recipes_transformers(),
    mk1, mk2, mk3,
    rmk1, rmk2
]

## Improve: More effitien use of previus computed data
function datatree()
    data = build_skeletontree()
    for v in topological_sort_by_dfs(data)
        node = label_for(data, v)
        # Get final tuple, ensure right order!
        costs = vertex_costs(data, node)
        data[node] = costs
    end
    return data
end

## Build skeleton tree (only edge metadata)
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
    vertex_data_type=NTuple{5,Int},
    edge_data_type=Int64,  # How many source's recipe requires of target.
    graph_data="Full data graph",  # tag for the whole graph
)

# tier 0; amount none
const INIT_DATA = (0, 0, 0, 0, 0)
function build_skeletontree!(tree, maker_recipes)
    for item in maker_recipes
        name, recipe = first(item), last(item)
        tree[name] = INIT_DATA
        for ingridient in recipe
            iname, n = first(ingridient), last(ingridient)
            tree[iname] = INIT_DATA
            tree[name, iname] = n
        end
    end
end

# Cost is a Dict{String, Int} 'C' where 'C["raw-material"] = n. needed for 1u of v'
costs_dict(::Type{T}=Int, materials=raw_materials) where T =
    Dict(materials .=> zeros(T, length(materials)))
# Dict(materials .=> zeros(nMiners, length(materials)))
costs_to_ntuple(dict, materials=raw_materials) =
    ntuple(i -> dict[materials[i]], Val(5))

function vertex_costs!(COSTS, g, v, speed=one(Int))
    # println(v)
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
vertex_costs(g, v, speed=one(Int)) =
    costs_to_ntuple(vertex_costs!(costs_dict(typeof(speed)), g, v, speed))
