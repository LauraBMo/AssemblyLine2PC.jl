module AssemblyLine2PC

include("Utils.jl")

# using Base: _rationalize_irrational
using Graphs, MetaGraphsNext
using MinerNumbers
using UnPack

include("Data.jl")
include("BuildData.jl")
include("ViewGraph.jl")
include("Recipe.jl")

export cost, total_material, nminers, topspeed

export vertex_costs!, raw_materials, vertex_costs, build_skeletontree

export full_recipe

"""
    cost(graph, item)

Return the total raw-material tuple required to produce a single unit of `item`.

The tuple ordering matches [`raw_materials`](@ref) so each entry represents the
per-unit demand for the corresponding raw resource. This helper is convenient when
you already have a pre-computed `graph` from [`datatree`](@ref) and need to inspect
multiple items without re-running the traversal.
"""
cost(g, v) = sum(g[v])

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
    return nMiners(total_material(name, speed, data) / 5)
end

## The actual time per unit at max update is 0.217391300, which is round to 0.2.
## So, each started produces 4.6 units per second; and not 5 (as I thought).
## How many units per second an started produce:
const PRODUCTION_SPEED = 4.6

"""
    topspeed(item, miners, data=datatree())

Compute the theoretical maximum units per second of `item` that `miners` active
Miners can support.

This is the inverse of [`nminers`](@ref) and is useful when you know the amount of
extraction capacity available and want to determine the production ceiling before
optimizing factory layout details.
"""
topspeed(name, miners, data=datatree()) = PRODUCTION_SPEED * miners / cost(data, name)

# function tree_time_cost(name, speed=1.0, data=get_data())
#     item = data[name]
#     if item[:tier] == 0
#         return nMiners(speed * item[:materials])
#     else
#         recipe = item[:materials]
#         return [(it[1],
#             nminers(it[1], it[2] * speed, data),
#             tree_time_cost(it[1], it[2] * speed), data) for it in recipe]
#     end
# end

# using OrderedCollections

# hastransformer1(str) = findfirst(occursin(str), build_slots())
# hasmaterial1(str) = findfirst(occursin(str), raws1)

# const MAT = "Material"
# const OTH = "Others"

# function build_slots()
#     slots = copy(basic_components_list)
#     push!(slots, "Cable")
#     push!(slots, "Other")
#     pushfirst!(slots, "Material")
#     return slots
# end

# function split_list(total_costs)
#     slots = build_slots()
#     lists = [Pair{String,Int}[] for _ in slots]

#     out = LittleDict{String,Vector{Pair{String,Int}}}(zip(slots, lists))

#     for it in total_costs
#         name = first(it)
#         t = hastransformer1(name)
#         m = hasmaterial1(name)
#         # println("ROW: ", name, t, m)
#         if !(isnothing(t))
#             slot = slots[t]
#             push!(out[slot], it)
#         elseif !(isnothing(m))
#             push!(out["Material"], it)
#         else
#             push!(out["Other"], it)
#         end
#     end
#     return out
# end

# function isless_material(it1, it2)
#     name1, name2 = first(it1), first(it2)
#     # println(name2, " NAMES ", name1)
#     return isless(hasmaterial1(name1), hasmaterial1(name2))
# end
# # sortby_material!(costs_list) = sort!(costs_list, lt=isless_material)

# function sort_list_unit_cost!(total_costs, data)
#     function isless_tier(it1, it2)
#         name1, name2 = first(it1), first(it2)
#         return isless(data[name1][:tier], data[name2][:tier])
#     end
#     all_lists = split_list(total_costs)

#     sort!(all_lists["Material"], lt=isless_material)
#     sort!(all_lists["Cable"], lt=isless_material)
#     for t in basic_components_list
#         sort!(all_lists[t], lt=isless_material)
#     end
#     sort!(all_lists["Other"], lt=isless_tier)
#     # for l in all_lists
#     #     println(l)
#     # end
#     return reduce(vcat, ((values(all_lists))))
# end

# dict_to_vec(dict) = [first(x) => last(x) for x in dict]
# function get_list_unit_cost(item, units=1.0, data=get_data())
#     _dict = Dict()
#     list_unit_cost!(_dict, item, units, data)
#     sort_list_unit_cost!(dict_to_vec(_dict), data)
# end


# function add_or_push!(tree, item, amount)
#     if item in keys(tree)
#         tree[item] += amount
#     else
#         push!(tree, item => amount)
#     end
# end

# function list_unit_cost!(_dict, name, units=1, data=get_data())
#     item = data[name]
#     recipe = item[:materials]
#     if item[:tier] == 0
#         add_or_push!(_dict, name, units)
#     else
#         for it in recipe
#             name = first(it)
#             amount = last(it) * units
#             add_or_push!(_dict, name, amount)
#             list_unit_cost!(_dict, name, amount, data)
#         end
#     end
# end

end # of module AssemblyLine2PC
