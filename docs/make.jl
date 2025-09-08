using AssemblyLine2PC
using Documenter

DocMeta.setdocmeta!(AssemblyLine2PC, :DocTestSetup, :(using AssemblyLine2PC); recursive=true)

makedocs(;
    modules=[AssemblyLine2PC],
    authors="LauBMo <laurea987@gmail.com> and contributors",
    sitename="AssemblyLine2PC.jl",
    format=Documenter.HTML(;
        canonical="https://LauraBMo.github.io/AssemblyLine2PC.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/LauraBMo/AssemblyLine2PC.jl",
    devbranch="main",
)
