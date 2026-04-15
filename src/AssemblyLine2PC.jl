module AssemblyLine2PC

using Graphs, MetaGraphsNext

using UnPack
using MinerNumbers
# MinerNumbers.set_round!(2)


using Printf
using PrettyTables

include("Utils.jl")

"""
    raw_materials

String ordered vector of raw resources that anchor all cost tuples produced by
AssemblyLine2PC.jl.
"""
const RAWS = ["Gold", "Diamond", "Iron", "Copper", "Aluminum"]
# const raws_radio = ["Uranium", "Plutonium"]

include("Data.jl")

const RECIPES = [
    # rawrecipes(), ## not a good idea
    transrecipes(),
    mk1, mk2, mk3,
    rmk1, rmk2,
]

include("BuildData.jl")
include("Costs.jl")

include("TableUtils.jl")
include("ViewGraph.jl")

export raw_cost, nstarters, topspeed

export vertex_costs!, raw_materials, raw_costs, build_skeletontree

export full_recipe

## The actual time per unit at max update is 0.217391300, which is round to 0.2.
## So, each started produces 4.6 units per second; and not 5 (as I thought).
## How many units per second an started produce:
# const PRODUCTION_SPEED = 4.6

"""
Dimensionless factor to account for a small delay on in-game speeds productions.   
Every time the game says `1` units per `s` sec; in fact, it does mean `GAME_FACTOR = 0.92` units per `s` sec.
For example, starters at max the game says 1u per 0.2sec (which should be 5u/sec); but they produce at 0.92/0.2=4.6u/sec.
"""
const GAME_FACTOR = 0.92

include("Recipe.jl")
# include("Distribution.jl")

# include("Prices.jl")
# const PRICES = Dict(pairs(pmk1)...,
#                     pairs(pmk2)...,
#                     pairs(pmk3)...,
#                     pairs(prmk1)...,
#                     pairs(prmk2)...,
#                     )

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
