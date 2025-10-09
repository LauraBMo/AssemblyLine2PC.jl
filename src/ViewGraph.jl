
export viewgraph

using Printf
using PrettyTables

struct ViewGraph{T}
    G::T
end

viewgraph(G) = ViewGraph(G)
graph(VG::ViewGraph) = VG.G

function get_pathdownwards(G, item, speed,
    path,
    miners=nothing)
    if !(isnothing(miners))
        speed *= topspeed(item, miners, G)
    end
    end_item = item
    end_speed = speed
    string_path = @sprintf "%s(%0.2fu/s)" item speed
    for i in path
        next_item = outneighbor_label(G, end_item, i)
        v = G[end_item, next_item]
        end_speed *= v
        end_item = next_item
        if v > 1
            string_path *= @sprintf ">x%d>%s(%0.2fu/s)" v end_item end_speed
        else
            string_path *= @sprintf ">>%s" end_item
        end
    end
    string_path *= ":"
    return end_item, end_speed, string_path
end

function (VG::ViewGraph)(item::String, I...;
    speed=one(Int),
    miners=nothing)
    G = graph(VG)
    real_item, real_speed, title = get_pathdownwards(G, item, speed, I, miners)
    table = recipe_table(real_item, real_speed, G)
    if isnothing(table)
        @printf "TOTAL: %5.2fu of raw-material; Requires: %s Miners" real_speed nMiners(real_speed / 5)
        return nothing
    end
    prettyrecipe(table, title)
end

## Total cost of items in subrecipe = [2,3] for item at level 'I' onforward.
## TODO TODO
## TODO TODO
function (VG::ViewGraph)(item::String, subrecipe::AbstractVector, I...;
    speed=one(Int), miners=nothing)
    G = graph(VG)
    real_item, real_speed, title = get_pathdownwards(G, item, speed, I, miners)
    table = subrecipe_table(real_item, subrecipe, real_speed, G)
    if isnothing(table)
        @printf "TOTAL: %5.2fu of raw-material; Requires: %s Miners" real_speed nMiners(real_speed / 5)
        return nothing
    end
    table = sort_recipe_table(table, G)
    prettyrecipe(table, title)
end
## TODO TODO
## TODO TODO

function recipe_table(name, speed=one(Int), data=datatree())
    # header = ["Component", "Rate", "Makers"; tracked materials...]
    out = Matrix{Any}(undef, 0, HLENGTH)
    recipe = outneighbor_labels(data, name)
    # wide = maximum(length, recipe)
    if isempty(recipe)
        return nothing
    end
    for it in recipe
        itspeed = speed * data[name, it]
        # N = nminers(it, itspeed, data)
        # N = nMiners(itspeed/5)
        newrow = [it itspeed Int(ceil(itspeed)) itspeed itspeed * collect(data[it])...]
        out = vcat(out, newrow)
    end
    return out
end

function subrecipe_table(name, subrecipe, speed=one(Int), data=datatree())
    # header = ["Component", "Rate", "Makers"; "Gold",...]
    table = recipe_table(name, speed, data)
    for i in subrecipe
        it = outneighbor_label(data, name, i)
        itspeed = speed * data[name, it]
        new_table = recipe_table(it, itspeed, data)
        table = add_recipe_table(table, new_table)
    end
    return table
end

function sort_recipe_table(table, data)
    rows = collect(eachrow(table))
    sort!(rows, by=x -> vertex_high(data, first(x)))
    out = Matrix{Any}(undef, HLENGTH, 0)
    out = reduce(hcat, rows; init=out)
    return permutedims(out)
end

function add_recipe_table(table1, table2)
    out = table1
    intable1(str) = findfirst(==(str), first(eachrow(table1)))
    for newrow in eachrow(table2)
        name = first(newrow)
        isintable1 = intable1(name)
        if isnothing(isintable1)
            out = vcat(out, permutedims(newrow))
        else
            out[isintable1, 2:end] += newrow[2:end]
        end
    end
    return out
end


## Make it a macro?
function highlighters_recipetable(table)
    _ord = sortperm(map(row -> sum(row[3:end]), eachrow(table)))
    sorteditems = table[:, 1][_ord]
    hl_item(string, color) = TextHighlighter(
        (data, i, j) -> (data[i, j] == string),
        color
    )

    hl_line(n, color) = TextHighlighter(
        (data, i, j) -> (i == n),
        color
    )

    hl_transrawline(color) = TextHighlighter(
        (data, i, j) -> istransraw(data[i, 1]),
        color
    )
    hls = [
        hl_transrawline(crayon"250"),
    ]
    if size(table, 1) > 1
        hls = vcat(hls, [
            hl_item(sorteditems[end], crayon"bold red"),
            hl_item(sorteditems[end-1], crayon"bold light_blue"),
            hl_line(_ord[end], crayon"red"),
            hl_line(_ord[end-1], crayon"light_blue"),
        ])
    end
    return hls
end

const LENGTH = 4
# const MATERIAL_HEADERS = tracked_materials
# const MATERIAL_UNITS = fill("u/s", length(MATERIAL_HEADERS))
const HLENGTH = LENGTH + length(tracked_materials)
const RECIPE_HEADERS = [
    ["Item", "Ratio", "Mkrs", "5xPacks", tracked_materials...],
    # ["", "u/s", "count", "packs", MATERIAL_UNITS...],
]
const TRANSRAW_HEADERS = [
    ["Raw Material", "Ratio", "number of Miners"],
]


istransraw(name) = (israwmaterial(name) || istransformer(name))
findalltransraw(table) = findall(istransraw, first.(eachrow(table)))

miner_formatter(columns) = (v, i, j) -> (in(j, columns) ? v : nMiners(v / 5))

function kwargs_default()
    DEFAULT_STYLE = TextTableStyle(;
        first_line_column_label=crayon"bold",
        source_note=crayon"bold light_blue",
    )
    DEFAULT_FORMAT = TextTableFormat(;
        @text__no_vertical_lines,
        # vertical_line_after_row_number_column = true
        vertical_line_after_continuation_column=true,
        vertical_line_at_beginning=true,
    )
    return (
        show_row_number_column=true,
        row_number_column_label="Num",
        style=DEFAULT_STYLE,
        table_format=DEFAULT_FORMAT,
    )
end

function kwargs_recipetable(table, title="")
    kwargs = kwargs_default()
    notminers_columns = [1, 2, 3]
    align = [:l, fill(:r, size(table, 2) - 1)...]
    return (
        title=title,
        column_labels=RECIPE_HEADERS,
        alignment=align,
        formatters=[miner_formatter(notminers_columns)],
        highlighters=highlighters_recipetable(table),
        summary_rows=my_summary(),
        summary_row_labels=["", ""],
        kwargs...
    )
end

function kwargs_transrawtable()
    kwargs = kwargs_default()
    return (kwargs...,
        title="Transformers & Raw Materials",
        column_labels=TRANSRAW_HEADERS,
        alignment=[:l, :r, :r],
    )
end

function build_transraw_table(recipes)
    _table = Matrix{Any}(undef, 0, length(TRANSRAW_HEADERS[1]))
    for row in eachrow(recipes)
        total_row = sum(row[(LENGTH+1):end])
        new_row = [row[1:2]..., nMiners(total_row / 5)]
        _table = vcat(_table, permutedims(new_row))
    end
    return _table
end

function prettyrecipe(table, title="", notminers_columns=[1, 2, 3])
    total = sum(table[:, (LENGTH+1):end])

    transraw = findalltransraw(table)
    transraw_table = build_transraw_table(table[transraw, :])

    src_string = @sprintf "TOTAL: %5.2fu of raw-material; Requires: %s Miners" total nMiners(total / 5)
    if isempty(transraw_table)
        pretty_table(table; kwargs_recipetable(table, title)...,
            source_notes=src_string)
    else
        pretty_table(table; kwargs_recipetable(table, title)...)
        pretty_table(transraw_table; kwargs_transrawtable()...,
            source_notes=src_string)
    end
    # return pt_transraw, pt
end

# using Printf
# function show_recipe(name, speed=one(Int), data=datatree())
#     # print("Recipe for $(name) at $(speed)u/s\n")
#     @printf "Recipe for %s at %0.2fu/s: Crafts & Miners\n" name speed
#     recipe = outneighbor_labels(data, name)
#     wide = maximum(length, recipe)
#     for it in recipe
#         itspeed = speed*data[name, it]
#         # N = float(MinerNumbers.number(nminers(it, itspeed, data)))
#         N = nminers(it, itspeed, data)
#         # print("|_> $(it) at $(itspeed): $(ceil(itspeed)) craft, $(N) Miners\n")
#         @printf "|_> %-*s(%5.2f u/s): %02d Mkr and %s Mi\n" wide it itspeed ceil(itspeed) N
#     end
# end
