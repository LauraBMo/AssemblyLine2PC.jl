
function upprices!(ratio = 1)
    ## Update and rescalate by ratio
    for mk in [pmk1, pmk2, pmk3, prmk1, prmk2]
        for (item, price) in mk
            PRICES[item] = ratio*price 
        end
    end
end

"""
    profit(item; data=datatree())

Returns the number of units of currency per miner (or starter) produced by `item`.
"""
function profit(item; data=datatree())
    revenue = PRICES[item]
    miners = cost(data, item) 
    return revenue/miners
end

function profits()
    allitems = keys(PRICES)
    out = allitems .=> profit.(allitems)
    sort!(out, by=last)
    return out
end

pmk1 = Dict(
    "ElectricBoard" => 1.19,
    "Heater" => 1.28,
    "ServerRack" => 0.736, 
    "Engine" => 1.28,
    "Battery" => 0.92,
    "SolarCell" => 0.736,
    "Circuit" => 0.644,
)

pmk2 = Dict(
    "SolarPanel" => 6.44,
    "SuperComputer" => 421.96,
    "AdvancedEngine" => 30.98,
    "PowerSupply" => 5.21,
    "Computer" => 44.12,
    "Laser" => 35.52,
    "Fan" => 6.42,
    "Processor" => 6.02,
)


pmk3 = Dict(
    "Explosive" => 521,
    "AIRobot" => 63420,
    "AIRobotHead" => 11520,
    "AIProcessor" => 3830,
    "ElectricEngine" => 221.2, 
    "IgnitionSystem" => 43190,
    "Trigger" => 381,
    "AIRobotBody" => 8270,
    "AIRobotArms" => 344.88,
)

prmk1 = Dict(
    "NCell" => 41_040,
    "PCell" => 527.2,
    "PCircuit" => 494,
    "NCircuit" => 30_050,
    "UCircuit" => 494,
    "UCell" => 527.2,
)

prmk2 = Dict(
    "AtomicBomb" => 3_419_0000,
    "NCore" => 843_210,
    "NProcessor" => 698_150, 
    "AIRBomber" => 1_430_000_000,
)
