function __summary(j, data, string, fun)
    if j == 1
        string
    elseif j == 2
        sum(fun, data[:, j])
    else
        sum(fun, data[:, j]./PRODUCTION_SPEED)
    end
end
my_summary() = [
    (data, j) -> __summary(j, data, "Totals:", x -> x),
    (data, j) -> __summary(j, data, "Ceil Sum:", ceil),
]

function outneighbor_label(G, item, i)
    code = code_for(G, item)
    codes = outneighbors(G, code)
    return label_for(G, codes[i])
end

function vertex_high(G, v)
    high = zero(Int)
    neighbors = outneighbor_labels(G, v)
    if !(isempty(neighbors))
        # println(map(n -> vertex_height(g, n), neighbors))
        high = 1 + maximum(n -> vertex_high(G, n), neighbors)
    end
    return high
end

function vertex_fuel_cost(G, v, speed = one(Int))
    cost = ceil(Int, speed)
    neighbors = collect(outneighbor_labels(G, v))
    if !(isempty(neighbors))
        for i in findall(isradioactive, neighbors)
            neighbor = neighbors[i]
            cost += vertex_fuel_cost(G, neighbor, G[v, neighbor] * speed)
        end
    end
    return cost
end

function vertex_total_cost(G, v, cost = zero(Int))
    neighbors = collect(outneighbor_labels(G, v))
    if !(isempty(neighbors))
        # println(map(n -> vertex_cost(g, n), neighbors))
        cost += sum(u -> G[v, u]*vertex_cost(G, u, cost), neighbors)
    end
    return cost
end

function find_bestapprox(L, d; kwargs...)
    ## We assume sum(L) == 1 
    approx = [ceil(Int, x * d; kwargs...) for x in L]
    total = sum(approx; init = 0)
    if total > d
        _, i = findmax(approx)
        approx[i] -= (total - d)
    end
    return approx
end

function total_error_for_denominator(L, d; kwargs...)
    approx = find_bestapprox(L, d; kwargs...)
    return sum(abs.(L .- (approx./d)); init = 0)
end

"""
    approximate_with_fractions(L, denominators; kwargs...)

Create rational approximations for list `L` using the best denominator from `denominators`.

Additional keyword arguments are passed to `ceil` in `find_bestapprox`.
"""
function approximate_with_fractions(L, denominators = collect(1:100);
                                    error = total_error_for_denominator,
                                    kwargs...)
    # Find the optimal denominator
    _, i = findmin(d -> error(L, d; kwargs...), denominators)
    best_d = denominators[i]
    
    # Create fractions using the best denominator
    best_d, find_bestapprox(L, best_d; kwargs...)
end

function approximate_with_fractions_splited(split, L, denominators = collect(1:100);
                                            error = total_error_for_denominator,
                                            kwargs...)
    out = Dict()
    full_split = parse_split!(split, length(L))
    for I in full_split
        push!(out,
              I => approximate_with_fractions(L[I])
              )
    end
    return out
end

################ No Need #######################
# hasvertex_simplemetadata(g, v) = isless(0, tier(g, v))
# nexthigh(highs) = 1 + maximum(highs)
# function nextcost(weights, costs)
#     _costs = last.(costs)
#     return (0, 0, 0, 0, sum(weights .* _costs))
# end

# function vertex_simplemetadata(g, v)
#     neighbors = outneighbor_labels(g, v)
#     if isempty(neighbors) || hasvertex_simplemetadata(g, v)
#         return g[v] ## Initial data
#     else
#         # println(map(n -> vertex_height(g, n), neighbors))
#         next = [vertex_simplemetadata(g, n) for n in neighbors]
#         # Assume we already computed (initial: Any Raw material (h=0, N=1)).
#         # next = [g[n] for n in neighbors] # Dosn't work
#         high = nexthigh(first.(next))
#         weights = [g[v, n] for n in neighbors]
#         cost = nextcost(weights, last.(next))
#     end
#     return (high, cost)
# end
################ No Need #######################

# # Cost is a Dict{String, Int} 'C' where 'C["raw-material"] = n. needed for 1u of v'
# costs_dict(::Type{T}=Int, materials=raws1) where T =
#     Dict(materials .=> zeros(T, length(materials)))
# # Dict(materials .=> zeros(nMiners, length(materials)))
# dict_to_ntuple(dict, materials=raws1) =
#     ntuple(i -> dict[materials[i]], Val(5))

# function vertex_costs!(COSTS, g, v, speed=one(Int))
#     # println(v)
#     neighbors = outneighbor_labels(g, v)
#     if isempty(neighbors) # leave of the pseudo-tree
#         # v is a raw-material
#         COSTS[v] += speed
#     else
#         for n in neighbors
#             vertex_costs!(COSTS, g, n, speed * g[v, n])
#         end
#         # println(map(n -> vertex_cost(g, n), neighbors))
#         # cost = sum(n -> g[v, n]*vertex_cost(g, n), neighbors)
#     end
#     # Get final tuple, ensure right order!
#     return dict_to_ntuple(COSTS)
# end

# vertex_costs(g, v, speed=one(Int)) =
#     vertex_costs!(costs_dict(typeof(speed)), g, v, speed)

# ## Improve: Use previus computed data
# ## Change Tuple{Int, Int} -> Tuple{Int, NTuple{5, Int}} in simpletree,
# ## simply store previus Int into last component. So, we can `data = copy(simpledata)`.
# function datatree()
#     data = build_skeletontree()
#     for v in topological_sort_by_dfs(data)
#         node = label_for(data, v)
#         costs = vertex_costs(data, node)
#         data[node] = (0, costs)
#     end
#     return data
# end
