
"""
    permute_to_front(A, I, dim) -> Array

Reorder the slices of array `A` along dimension `dim` so that the indices
`I = [i1, ..., ik]` come first (in the given order), followed by the
remaining indices in their original relative order.
"""
function permute_to_front(A::AbstractArray, I::AbstractVector{Int}, dim=1)
    n = size(A, dim)

    remaining = setdiff(1:n, I) # indices NOT in I, original order
    new_order = vcat(I, remaining) # I-first ordering

    # Build a full index tuple: `:` for every dim except `dim`
    idx = ntuple(d -> d == dim ? new_order : Colon(), ndims(A))
    return A[idx...]
end

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


## We assume sum(L) == 1 
init_approx(L, d) = fix_approx!([round(Int, x * d) for x in L], d)
function fix_approx!(approx, d)
    total = sum(approx; init = 0)
    while total > d
        _, i = findmax(approx)
        approx[i] -= 1
        total -= 1
    end
    return approx
end

const IT = Iterators
factors(r, n) = IT.filter(I -> sum(I)==0, IT.product(fill(-r:r, n)...))

function find_approx(L, d; range = 1)
    approx = init_approx(L, d)

    old_error = error_approx(L, d, approx)
    out = approx

    # map_zero_sum_tuples(n, range) do I
    # for I in factors(range, length(L))
    #     new_approx = approx .+ I
    #     new_error = error_approx(L, d, new_approx)
    #     if new_error < old_error
    #         out = new_approx
    #         old_error = new_error
    #     end
    # end
    return out, old_error
end

error_approx(L, d, approx) = sum(abs.(L .- (approx./d)); init = 0)

"""
    approximate_with_fractions(L, denominators; kwargs...)

Create rational approximations for list `L` using the best denominator from `denominators`.

Additional keyword arguments are passed to `ceil` in `find_bestapprox`.
"""
function approximate_with_fractions(L, denominators = length(L):100; kwargs...)
    candidates = find_approx.([L], denominators)
    # Find the optimal denominator
    _, i = findmin(C -> last(C), candidates)

    best_d = denominators[i]
    approx = first(candidates[i])
    return best_d, approx
end

# function approximate_with_fractions_splited(split, L, denominators = collect(1:100);
#                                             error = total_error_for_denominator,
#                                             kwargs...)
#     out = Dict()
#     full_split = parse_split!(split, length(L))
#     for I in full_split
#         push!(out,
#               I => approximate_with_fractions(L[I])
#               )
#     end
#     return out
# end

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
