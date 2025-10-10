# Complete Assembly Line 2 Crafting Tree Dictionary

# ==================== RAW MATERIALS ====================
const raws1 = ["Gold", "Diamon", "Iron", "Copper", "Aluminium"]
const raws2 = ["Uranium", "Plutonium"]


"""
    raw_materials

String ordered vector of raw resources that anchor all cost tuples produced by
AssemblyLine2PC.jl.
"""
const raw_materials = vcat(raws1, raws2)

israwmaterial(string) = any(==(string), raw_materials)


transformers_list = ["Wire", "Liquid", "Gear", "Plate"]
## Cable, Refined (missing)
# transformers_names = ["WMaker", "Furance", "Cutter", "CMaker", "HPress", "Refinery"]
# transformers_dict = transformers_list .=> transformers_names

# ==================== BASIC COMPONENTS ====================
function recipes_transformers(raw_type1 = raws1,
                              raw_type2 = raws2,
                              transformers = transformers_list)
    recipes = Dict()
    for (m, t) in Iterators.product(raw_type1, transformers)
        name = m * t
        push!(recipes, name => Dict(m => 1))
    end
    # Add Cable version (sligthly different)
    for m in raw_type1
        name = m * "Cable"
        ingridient = m * "Wire"
        push!(recipes,
            name => Dict(ingridient => 3))
    end
    # Add Refinery version (sligthly different)
    for m in raw_type2
        name = m * "Refined"
        ingridient = m
        push!(recipes,
            name => Dict(ingridient => 1))
    end
    return recipes
end

const transformer_items = collect(keys(recipes_transformers()))
istransformer(string) = in(string, transformer_items)

# ==================== MAKERS RECIPES ====================
mk1 = Dict(
    "Battery" => Dict(
        "Copper" => 1,
        "CopperLiquid" => 2,
    ),
    "Circuit" => Dict(
        "Gold" => 2,
        "CopperWire" => 1,
    ),
    "ElectricBoard" => Dict(
        "CopperWire" => 3,
        "Aluminium" => 2,
    ),
    "Engine" => Dict(
        "IronGear" => 2,
        "Gold" => 2,
    ),
    "Heater" => Dict(
        "IronWire" => 2,
        "Aluminium" => 4,
    ),
    "ServerRack" => Dict(
        "Aluminium" => 1,
        "Iron" => 3,
    ),
    "SolarCell" => Dict(
        "DiamonLiquid" => 1,
        "Gold" => 2,
    ),
)

mk2 = Dict(
    "AdvancedEngine" => Dict(
        "Engine" => 6,
        "Circuit" => 6,
        "Diamon" => 10,
    ),
    "Computer" => Dict(
        "Processor" => 1,
        "PowerSupply" => 1,
        "Fan" => 1,
    ),
    "Fan" => Dict(
        "Circuit" => 2,
        "DiamonGear" => 4,
        "Aluminium" => 6,
    ),
    "Laser" => Dict(
        "Battery" => 6,
        "Heater" => 6,
        "IronLiquid" => 6,
    ),
    "PowerSupply" => Dict(
        "Circuit" => 1,
        "Diamon" => 6,
        "AluminiumLiquid" => 6,
    ),
    "Processor" => Dict(
        "Circuit" => 2,
        "GoldLiquid" => 4,
        "DiamonWire" => 4,
    ),
    "SolarPanel" => Dict(
        "SolarCell" => 1,
        "Circuit" => 1,
        "ElectricBoard" => 1,
    ),
    "SuperComputer" => Dict(
        "Computer" => 2,
        "ServerRack" => 6,
        "Circuit" => 6,
        "GoldCable" => 6,
    ),
)

mk3 = Dict(
    "AIProcessor" => Dict(
        "Circuit" => 5,
        "SuperComputer" => 3,
        "CopperPlate" => 10,
        "CopperCable" => 10,
    ),
    "AIRobot" => Dict(
        "AIRobotBody" => 1,
        "AIRobotHead" => 1,
        "IronPlate" => 15,
        "DiamonCable" => 10,
    ),
    "AIRobotArms" => Dict(
        "Laser" => 3,
        "AluminiumPlate" => 6,
        "AluminiumCable" => 6,
        "Iron" => 10,
    ),
    "AIRobotBody" => Dict(
        "ElectricEngine" => 3,
        "SolarPanel" => 4,
        "AIRobotArms" => 4,
        "ElectricBoard" => 6,
    ),
    "AIRobotHead" => Dict(
        "AIProcessor" => 1,
        "GoldPlate" => 10,
        "DiamonCable" => 5,
        "Circuit" => 15,
    ),
    "ElectricEngine" => Dict(
        "Battery" => 5,
        "AdvancedEngine" => 2,
        "ElectricBoard" => 6,
        "IronPlate" => 6,
    ),
    "Explosive" => Dict(
        "Circuit" => 5,
        "DiamonWire" => 10,
        "CopperCable" => 10,
        "Heater" => 10,
    ),
    "IgnitionSystem" => Dict(
        "Trigger" => 2,
        "Explosive" => 5,
        "AIProcessor" => 1,
        "Battery" => 5,
    ),
    "Trigger" => Dict(
        "Iron" => 40,
        "DiamonWire" => 10,
        "Circuit" => 5,
        "ElectricBoard" => 8,
    ),
)

# ==================== RADIOACTIVE MAKERS RECIPES ====================
## This makers need fuel to work, exactly 1/6th of a refined Uranium or Plutonium unit per second.
## We add "Fuel" flag to account for it in costs computations.
rmk1 = Dict(
    "NCell" => Dict(
        "PCell" => 2,
        "UCell" => 2,
        "SolarCell" => 3,
        "ElectricBoard" => 3,
        "Heater" => 3,
    ),
    "NCircuit" => Dict(
        "PCircuit" => 2,
        "UCircuit" => 2,
        "Circuit" => 3,
        "GoldCable" => 3,
        "Processor" => 3,
    ),
    "PCell" => Dict(
        "Plutonium" => 4,
        "SolarCell" => 4,
        "DiamonLiquid" => 10,
        "GoldCable" => 4,
        "CopperCable" => 4,
    ),
    "PCircuit" => Dict(
        "Plutonium" => 5,
        "Circuit" => 5,
        "Copper" => 5,
        "GoldCable" => 3,
        "DiamonWire" => 3,
    ),
    "UCell" => Dict(
        "Uranium" => 4,
        "SolarCell" => 4,
        "DiamonLiquid" => 10,
        "GoldCable" => 4,
        "CopperCable" => 4,
    ),
    "UCircuit" => Dict(
        "Uranium" => 5,
        "Circuit" => 5,
        "Copper" => 5,
        "GoldCable" => 3,
        "DiamonWire" => 3,
    ),
)

rmk2 = Dict(
    "NCore" => Dict(
        "NCell" => 1,
        "PCell" => 1,
        "UCell" => 1,
        "Processor" => 10,
        "DiamonCable" => 4,
        "GoldCable" => 4,
    ),
    "NProcessor" => Dict(
        "NCircuit" => 1,
        "PCircuit" => 1,
        "UCircuit" => 1,
        "AIProcessor" => 1,
        "Processor" => 5,
        "DiamonPlate" => 10,
    ),
    "AtomicBomb" => Dict(
        "NProcessor" => 1,
        "NCore" => 1,
        "IgnitionSystem" => 2,
        "NCell" => 2,
        "Uranium" => 15,
        "Plutonium" => 15,
    ),
    "AIRBomber" => Dict(
        "AtomicBomb" => 1,
        "AIRobot" => 1,
        "NCore" => 1,
        "NCell" => 1,
        "NProcessor" => 1,
        "NCircuit" => 1,
    ),
)

const radioactive_makers = union(collect(keys(rmk1)), collect(keys(rmk2)))
isradioactive(string) = in(string, radioactive_makers)
