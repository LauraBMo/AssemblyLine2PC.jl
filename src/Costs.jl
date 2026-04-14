# 
# 

"""
    vertex_costs(graph, root, item0)

Returns a dictionary `D::Dict{String, Int}`, where keys are all items `item_1,...,item_k` that both they are needed to produce `root`, and for each of them `item0` is directly in its recipe (or outneighbors). And for values, `D["item_i"] = a_i` is the total amount of `item0` needed to produce `item_i` per 1 unit of `root`.

The idea is as follows. The number `T = sum(values(D))` has units `[item0]/[root]` and it is the total amount of `item0` units we do need to produce in order to start producing a unite of `root`.
Now, it is easy to get in the game a flow of `T [item0]/[sec]`; but how do we split it in order to prosuce `root`? Well, we have to divide it into items `item_1,...,item_k` sending to each `D["item_i"]` units. 
"""
function vertex_costs(G, root, item)
    out = Dict{String, Float64}()
    if item == root
        out[root] = 1
    else
        vertex_costs!(out, G, root, item, one(Int))
    end
    return out
end

function vertex_costs!(COSTS::Dict, G, root, item, amount, factor=one(Int))
    ## `factor` is a tax only to pay on the number of machines to obtain an in-game flow goal.
    ## For example, to get an in-game flow of `v [item]/[sec]` we need to add as many machines as for a flow of `v/factor [item]/[sec]`. That is, for any item but raws we need `ceil(Int, v/factor)` many machines and `ceil(Int, v/(5*factor))` starters for raw materials.
    ## So, this tax only limits the `topspeed` for the number of starters.
    neighbors = collect(outneighbor_labels(G, root))
    if item in neighbors
        loc_amount = amount * G[root, item] / factor
        if haskey(COSTS, root)
            COSTS[root] += loc_amount
        else
            COSTS[root] = loc_amount
        end
    end
    for loc_root in neighbors
        loc_amount = amount * G[root, loc_root] / factor
        vertex_costs!(COSTS, G, loc_root, item, loc_amount)
    end
    return COSTS
end

vertex_cost(G, root, item) = sum(values(vertex_costs(G, root, item)); init=0)

"""
    vertex_raw_costs(graph, vertex)

Return the resource footprint tuple for `vertex`. The tuple ordering follows [`RAWS`](@ref).
"""
raw_costs(G, item) = [vertex_cost(G, item, raw) for raw in RAWS]

"""
    cost(graph, item)

Return the total raw-material tuple required to produce a single unit of `item`.

The tuple ordering matches [`raw_materials`](@ref) so each entry represents the
per-unit demand for the corresponding raw resource. This helper is convenient when
you already have a pre-computed `graph` from [`datatree`](@ref) and need to inspect
multiple items without re-running the traversal.
"""
raw_cost(G, item) = sum(raw_costs(G, item))

"""
    nminers(G, item)

Estimate how many Miners are required to maintain `rate` units per second of
`item`.

Each Miner extracts 4.6 = 5*GAME_FACTOR units of raw material per second in Assembly Line 2. The
function uses [`raw_cost`](@ref) to compute the throughput requirements and
then converts that to the number of working Miners needed on the resource patches.
"""
nstarters(G, item) = raw_cost(G, item) / (5 * GAME_FACTOR) 

"""
    topspeed(G, item, miners)

Compute the theoretical maximum units per second of `item` that `miners` can feed.

This is the inverse of [`nminers`](@ref) and is useful when you know the amount of
extraction capacity available and want to determine the production ceiling before
optimizing factory layout details.
"""
topspeed(G, item, starters) = starters / nstarters(G, item)
# miners/nminers(G, item) = (GAME_FACTOR * 5 * miners) / raw_cost(data, item)
# 
