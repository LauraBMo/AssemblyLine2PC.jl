
findalltransraw(table) = findall(istransraw, first.(eachrow(table)))
findallradioactive(table) = findall(isradio, first.(eachrow(table)))

miner_formatter(columns) = (v, i, j) -> (in(j, columns) ? nMiners(v) : v)
int_formatter(rows) = (v, i, j) -> (in(i, rows) ? Int(v) : v)
# miner_formatter(columns) = (v, i, j) -> (in(j, columns) ? nMiners(v) : v)

function __summary(j, data, title, fun)
    if j == 1
        title
    elseif j == 4
        nMiners(sum(fun, data[:, j]))
    else
        sum(fun, data[:, j])
    end
end
my_summary() = [
    (data, j) -> __summary(j, data, "Sum:", x -> x),
    (data, j) -> __summary(j, data, "Sum Ceil:", x -> ceil(Int, x)),
]

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
    hls = [hl_transrawline(crayon"250"),]
    if size(table, 1) > 1
        append!(hls,
            [
                hl_line(_ord[end], crayon"red"),
                hl_line(_ord[end-1], crayon"light_blue"),
                hl_item(sorteditems[end], crayon"bold red"),
                hl_item(sorteditems[end-1], crayon"bold light_blue"),
            ])
        reverse!(hls)
    end
    return hls
end

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
        row_number_column_label=" #",
        style=DEFAULT_STYLE,
        table_format=DEFAULT_FORMAT,
    )
end
