#############################################################################
# Joulia
# A Large-Scale Spatial Power System Model for Julia
# See https://github.com/JuliaEnergy/Joulia.jl
#############################################################################
# Example: ELMOD-DE

using Joulia

using DataFrames, CSV
using Gurobi


data_path = "data"

pp_df = CSV.read(joinpath(data_path, "power_plants.csv"))
avail_con_df = CSV.read(joinpath(data_path, "avail_con.csv"))
prices_df = CSV.read(joinpath(data_path, "prices.csv"))

storages_df = CSV.read(joinpath(data_path, "storages.csv"))

lines_df = CSV.read(joinpath(data_path, "lines.csv"))

load_df = CSV.read(joinpath(data_path, "load.csv"))
nodes_df = CSV.read(joinpath(data_path, "nodes.csv"))
exchange_df = CSV.read(joinpath(data_path, "exchange.csv"))

res_df = CSV.read(joinpath(data_path, "res.csv"))
avail_pv = CSV.read(joinpath(data_path, "avail_pv.csv"))
avail_windon = CSV.read(joinpath(data_path, "avail_windon.csv"))
avail_windoff = CSV.read(joinpath(data_path, "avail_windoff.csv"))

avail = Dict(:PV => avail_pv,
	:WindOnshore => avail_windon,
	:WindOffshore => avail_windoff,
	:global => avail_con_df)

# generation of Joulia data types
pp = PowerPlants(pp_df, avail=avail_con_df, prices=prices_df)
storages = Storages(storages_df)
lines = Lines(lines_df)
nodes = Nodes(nodes_df, load_df, exchange_df)
res = RenewableEnergySource(res_df, avail)

# generation of the Joulia model
elmod = JouliaModel(pp, res, storages, nodes, lines)

# slicing the data in weeks with the first full week starting at hour 49
slices = week_slices(1)[2:end]

# running the Joulia model for week 30 using the Gurobi solver
results = run_model(elmod, 1:672, solver=Gurobi.Optimizer)

# elmod.results[:LOST_LOAD].value |> sum

# sum(nodes.load[n][t] for n in keys(nodes.load), t in 1:672)


# asdf = filter(x -> x.value > 0, elmod.results[:LOST_LOAD])

# test = combine(groupby(asdf, :Node), :value => sum => :value)

# sort!(test, :value, rev=true)

for (k, df) in elmod.results
	filename = string(k) * ".csv"
	CSV.write("results/$filename", df)
end