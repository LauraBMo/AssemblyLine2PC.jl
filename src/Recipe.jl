
struct Recipe{T,S}
    ## Step: (deep, item, speed)
    rec::Vector{T} ## Vector of steps
    G::S
end

recipe(r::Recipe) = r.rec
get_graph(r::Recipe) = r.G
root(R::Recipe) = first(recipe(R)).item

function resetspeed!(R::Recipe, newspeed)
    rec = recipe(R)
    _, _, oldspeed = first(rec)
    ratio = newspeed / oldspeed
    for (i, (deep, item, speed)) in enumerate(rec)
        R.rec[i] = (deep=deep, item=item, speed=ratio * speed)
    end
end

function Base.print(io::IO, r::Recipe; indent="*", kwargs...)
    for (deep, item, speed) in recipe(r)
        tabstr = repeat(indent, length(deep) + 1)
        @printf "%s %s(%0.2f[u/s])\n" tabstr item speed
    end
end
Base.show(io::IO, recipe::Recipe) = Base.print(io, recipe)
Base.show(io::IO, ::MIME"text/plain", recipe::Recipe) = Base.print(io, recipe)

function recipe(item::String, speed=1.0, deep="", G=datatree(); miners=nothing)
    p_recipe = pre_recipe(item, speed, deep, G; miners=miners)
    return Recipe{eltype(p_recipe),typeof(G)}(p_recipe, G)
end

function pre_recipe(item::String, speed=1.0, deep="", G=datatree(); miners=nothing)
    if !isnothing(miners)
        speed = topspeed(item, miners, G)
    end
    p_recipe = [(deep=deep, item=item, speed=speed)]
    alphebet = collect('a':'z')
    # if !istransorraw(item)
    # if !israwmaterial(item)
    neighborhood = outneighbor_labels(G, item)
    if !isempty(neighborhood)
        for (i, next_item) in enumerate(neighborhood)
            loc_speed = speed * G[item, next_item]
            loc_deep = deep * alphebet[i]
            append!(p_recipe, pre_recipe(next_item, loc_speed, loc_deep, G))
        end
    end
    return p_recipe
end

function (R::Recipe{T})(item, del...;
                        include=[], delete=[], full=true) where T
    rec = recipe(R)
    previous_steps = read_steps(rec, item)
    append!(delete, del), unique!(delete)
    subtitle = clear_steps!(previous_steps, rec, include, delete)
    if isempty(previous_steps)
        return nothing
    end
    tags, speeds = first.(previous_steps), last.(previous_steps)
    total = sum(speeds)
    title = @sprintf "Needs %s(%0.2f[u/s]) to produce" item total 
    d, frac = approximate_with_fractions(speeds ./ total)
    speeds_sources = [cost(rec, it) for it in tags]

    del_notes = ""
    if !isempty(include) || !isempty(delete)
        c = cost(rec, item)
        del_notes *= " (actual cost $(c)u/s ($(c - total) plus))." 
    end

    if length(previous_steps) == 1
        @printf "%s >> %s(%0.2f[u/s]).\n" title first(tags) first(speeds_sources)
        print(subtitle * del_notes)
    else
        result = pretty_table(
            ## row1 are parts, row2 target speeds
            permutedims(hcat(frac, speeds_sources));
            kwargs_default()...,
            formatters=[(v, i, j) -> (i == 1 ? Int(v) : v)],
            # column_labels          = collect(enumerate(first.(inv_recipe))),
            column_labels=join.(enumerate(tags)),
            show_row_number_column=false,
            source_notes="Splitting for $(item): $d parts" * del_notes,
            # subtitle = "split factor $d",
            title=title,
            subtitle=subtitle,
        )
        result
    end
    if full && !istransraw(item)
        viewgraph(get_graph(R))(item; speed=total)
    end
end

(R::Recipe)(; include=[], delete=[], full=true) = 
 (R)(root(R); include=include, delete=delete, full=full)

#### Some utils
function cost(rec::AbstractVector, item::String)
    I = findall(step -> step.item == item, rec)
    return sum(step -> step.speed, rec[I])
end

isup(step1, step2) = !(length(step1.deep) >= length(step2.deep))
function get_uptag(rec, i)
    j = findlast(k -> isup(rec[k], rec[i]), 1:i)
    up_step = rec[j]
    return (up_step).item
end

function push_or_add!(pre_step, tag, sp)
    isnew = findfirst_in(tag, first.(pre_step))
    if isnothing(isnew)
        push!(pre_step, [tag, sp])
    else
        pre_step[isnew][2] += sp
    end
end

findall_steps(rec, item) = findall(step -> step.item == item, rec)
# findall_steps(rec, item) = findall( ==(item), rec)

function read_steps(rec, item)
    steps = findall_steps(rec, item)
    _, root, speed = first(rec)
    previous_steps = []
    if isempty(steps)
        @printf "\n -- No need of \"%S\" to produce \"%S\", just relax!\n" item root
        return previous_steps
    end
    if item == root
        append!(previous_steps, [[root, speed]])
        return previous_steps
    end
    for i in steps
        ## Speed needed in step i-th comes from item in step (inv_i)-th.
        tag = get_uptag(rec, i)
        push_or_add!(previous_steps, tag, rec[i].speed)
    end
    return previous_steps
end

function title_setroot(rec)
    _, root, speed = first(rec)
    return @sprintf "-- Goal %s at (%0.2f[u/s])" root speed
end

function clear_steps!(steps, rec, include, delete)
    title = title_setroot(rec)
    if !isempty(include)
        title *= (" (removed: " * join(include, ", ") * ").")
        include_items = [first(steps[i]) for i in include]
        filter!(step -> in(step[1], include_items), steps)
    end
    if !isempty(delete)
        title *= (" (removed: " * join(delete, ", ") * ").")
        delete_items = [first(steps[i]) for i in delete]
        filter!(step -> !in(step[1], delete_items), steps)
    end
    return title
end
