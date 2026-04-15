
@kwdef mutable struct Recipe{T}
    root::String = "NProcessor"
    target::Float64 = 1.0 # [root]/[sec]
    G::T = datatree()
end

graph(R::Recipe) = R.G
root(R::Recipe) = R.root
target(R::Recipe) = R.target

vertex_costs(R::Recipe, item) = vertex_costs(R.G, R.root, item)
vertex_cost(R::Recipe, item) = vertex_cost(R.G, R.root, item)
function resettarget!(R::Recipe, newtarget)
    R.target = newtarget
end

function Base.print(io::IO, R::Recipe; indent=" ", kwargs...)
    R(root(R))
    # for (deep, item, speed) in recipe(R)
    #     tabstr = repeat(indent, length(deep) + 1)
    #     @printf "%s %s(%0.2f[u/s])\n" tabstr item speed * R.speed
    # end
end
Base.show(io::IO, recipe::Recipe) = Base.print(io, recipe)
Base.show(io::IO, ::MIME"text/plain", recipe::Recipe) = Base.print(io, recipe)


function recipe(item::String, target=1.0, G=datatree(); miners=nothing)
    if !isnothing(miners)
        target = topspeed(G, item, miners)
    end
    return Recipe{typeof(G)}(item, target, G)
end

function recipe(R::Recipe, item::String=root(R), amount=target(R), deep="", G=graph(R))
    out = [(deep=deep, item=item, amount=amount)]
    alphebet = collect('a':'z')
    # if !istransorraw(item)
    # if !israwmaterial(item)
    neighborhood = outneighbor_labels(G, item)
    if !isempty(neighborhood)
        for (i, next_item) in enumerate(neighborhood)
            loc_amount = amount * G[item, next_item]
            loc_deep = deep * alphebet[i]
            append!(out, recipe(R, next_item, loc_amount, loc_deep))
        end
    end
    return out
end

function (R::Recipe)(item::String;
                     full=true, # Show Graph View
                     group=nothing, other=true,
                     apart=nothing,
                     exact=false,
                     npack = 5, n = npack,
                     )
    costs = collect(vertex_costs(R, item))
    sort!(costs; by=last, rev=true)
    # @show costs
    # @show sum(values(costs))

    if isnothing(apart)
        R(item, costs; full=full, group=group, n = n)
    else
        R(item, costs[∉(apart).(1:end)]; full=full, group=group, n = n)
        print("\n")
        R(item, costs[apart]; full=full, group=nothing, n = 5)
    end
end

(R::Recipe)(; full=true, group=nothing) = (R).(RAWS; full=full, group=group)

function (R::Recipe)(item::String, costs::AbstractVector;
                     full=true, # Show Graph View
                     group=nothing, other=true,
                     apart=nothing,
                     exact=false,
                     npack = 5, n = npack,
                     )
                     # full=true, group=nothing, npack = 5, n = npack)
    names, amounts = first.(costs), last.(costs)
    amount = sum(amounts; init=0) # [item]/[R.root] ## = vertex_cost(R, item) - apart
    # d, frac = approximate_with_fractions(speeds ./ total)
    speeds_sources = [target(R) * vertex_cost(R, it) for it in names]

    if exact
        D = gcd(amounts)
        splittings = amounts ./ D
    else
        d, splittings = approximate_with_fractions(amounts ./ amount)
    end

    ## See `vertex_costs` comment.
    ## R, amount, item, costs, names
    speed = target(R) * amount
    title = @sprintf "Needs %s(%0.2f[u/s]" item speed
    if israw(item)
        # title *= @sprintf " miners: %0.2f" total/(5*GAME_FACTOR)
        nstarters = ceil(Int, speed/(5*GAME_FACTOR))
        title *= @sprintf " starters: %i" nstarters
        title *= @sprintf " %ix: %i+%i/%i" n divrem(nstarters, n)... n
    else
        title *= @sprintf " makers: %i" ceil(Int, speed/GAME_FACTOR)
    end
    title *= ") to produce:"
    subtitle = @sprintf "-- Goal %s at (%0.2f[u/s])\n" root(R) target(R)
    if (length(costs) == 1) && !(root(R) == names[1])
        title *= @sprintf " >> %s(%0.2f[u/s])." names[1] speeds_sources[1]
    end

    if length(costs) == 1
        @printf "%s\n" title
        @printf "%s" subtitle
        viewgraph(graph(R))(item; speed=speed, npacks = n)
        return nothing
    end
    # _data = permutedims(hcat(collect(amounts), speeds_sources))
    _data = permutedims(hcat(splittings,
                             splittings./d,
                             amounts./amount,
                             speeds_sources,
                             ceil.([Int], speeds_sources/0.92)
                             ))
    kwagrs = kwargs_default()
    spearator = "."
    if !isnothing(group)
        _togroup = group
        if other
            _togroup = [i for i in 1:(length(speeds)) if !(i in group)]
        end
        nn = length(_togroup)
        _data = permute_to_front(_data, _togroup, 2)
        _labels=join.(enumerate(names), [spearator])
        _labels = permute_to_front(_labels, _togroup)
        
        _data[1, 1] = sum(_data[1, 1:nn])
        # _data[1, 2:nn] .= 0.0
        
        l1 = join(_labels[1:nn], "+")
        # println(nn, _labels, _data, l1)
        kwagrs = (kwagrs...,
                  column_labels=[[MultiColumn(nn, l1), _labels[(nn+1):end]...]],
                  merge_column_label_cells=:auto,
                  formatters=[# (v, i, j) -> (i == 1 ? Int(v) : v),
                              (v, i, j) -> ((i == 1 && j in 2:nn) ? "_" : v),
                              ],
                  )
    end
    result = pretty_table(
        _data;
        column_labels=join.(enumerate(names), [spearator]),
        row_labels=["Parts", "Get prop.", "To apx.", "Produce", "Makers"],
        formatters=[# (v, i, j) -> (i == 1 ? Int(v) : v)
                    ],
        kwagrs...,
        show_row_number_column=false,
        source_notes="Splitting for $(item): $(sum(amounts)) parts",
        title=title,
        subtitle=subtitle,
        )
    result
    if full
        viewgraph(graph(R))(item; speed = speed, npack = n)
    end
end

