# 
# 
# iscostset(cost) = !(all(iszero, cost)) # Cost already set for vertex 'v'
"""
    cost(graph, item)

Return the total raw-material tuple required to produce a single unit of `item`.

The tuple ordering matches [`raw_materials`](@ref) so each entry represents the
per-unit demand for the corresponding raw resource. This helper is convenient when
you already have a pre-computed `graph` from [`datatree`](@ref) and need to inspect
multiple items without re-running the traversal.
"""
cost(g, v) = sum(vertex_raw_costs(g, v))

"""
    total_material(item, rate, data=datatree())

Calculate the total raw-material throughput required to sustain `rate` units per
second of `item`.

This multiplies [`cost`](@ref) by the desired production rate so downstream sizing
and balancing can be performed in a single step.
"""
total_material(name, speed, data=datatree()) = speed * cost(data, name) # u/sec

"""
    nminers(item, rate=1, data=datatree())

Estimate how many Miners are required to maintain `rate` units per second of
`item`.

Each Miner extracts 5 units of raw material per second in Assembly Line 2. The
function uses [`total_material`](@ref) to compute the throughput requirements and
then converts that to the number of working Miners needed on the resource patches.
"""
function nminers(name, speed=one(Int), data=datatree()) # speed in u/sec
    # Each Miner produces 5u/sec
    return nMiners(total_material(name, speed, data) / PRODUCTION_SPEED)
end

"""
    topspeed(item, miners, data=datatree())

Compute the theoretical maximum units per second of `item` that `miners` active
Miners can support.

This is the inverse of [`nminers`](@ref) and is useful when you know the amount of
extraction capacity available and want to determine the production ceiling before
optimizing factory layout details.
"""
topspeed(name, miners, data=datatree()) = PRODUCTION_SPEED * miners / cost(data, name)

"""
    vertex_raw_costs(graph, vertex)

Return the resource footprint tuple for `vertex`. The tuple ordering follows [`raw_materials`](@ref).
"""
function vertex_raw_costs(G, v)
    # Return as tuple (ensure 'raw_materials' order)
    return [vertex_cost(G, v, r) for r in raw_materials]
end

"""
    vertex_cost!(cost, graph, vertex, item)

Accumulate resource demand of `item` for `vertex` into `cost`.
"""
function vertex_cost!(COST, G, v, item, speed)
    neighbors = collect(outneighbor_labels(G, v))
    if item in neighbors
        COST[1] += speed * G[v, item]
    end
    for u in neighbors
        vertex_cost!(COST, G, u, item, speed * G[v, u])
    end
    return COST
end

"""
    vertex_cost(graph, vertex, item, speed=1)

Return the resource footprint of `item` for `vertex`, scaled by `speed` units per
second.
"""
function vertex_cost(G, v, item)
    # Initial zeroed cost;
    # Put it in a vector for multi-access in a for-selfcalling loop.
    cost = [zero(Int)]
    # Populate with actual cost
    vertex_cost!(cost, G, v, item, one(Int))
    return cost[1]
end


"""
    vertex_costs!(cost, graph, vertex, item)

Accumulate resource demand of `item` for `vertex` into `cost`.
"""
function vertex_costs!(COSTS::Dict, G, v, item, speed)
    neighbors = collect(outneighbor_labels(G, v))
    if item in neighbors
        sp = speed * G[v, item]
        if haskey(COSTS, v)
            COSTS[v] += sp
        else
            COSTS[v] = sp
        end
    end
    for u in neighbors
        sp = speed * G[v, u]
        vertex_costs!(COSTS, G, u, item, sp)
    end
    return COSTS
end

"""
    vertex_cost(graph, vertex, item, speed=1)

Return the resource footprint of `item` for `vertex`, scaled by `speed` units per
second.
"""
function vertex_costs(G, v, item)
    return vertex_costs!(Dict(), G, v, item, one(Int))
end
