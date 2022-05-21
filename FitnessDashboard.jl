using DataFrames
using DBInterface
using FunSQL
using FunSQL: From, Get, Group, Select, render, reflect
using Genie, Stipple, StippleUI
using Genie.Renderers.Html
using PlotlyBase
using SQLite
using Stipple
using StipplePlotly
using StipplePlotly: PlotLayout, PlotConfig
using StippleUI

db = DBInterface.connect(SQLite.DB, "exercise.db")
table_info = reflect(db).tables

weights = table_info[:weights]

weights_data =
    From(weights) |> FunSQL.render |> sql -> DBInterface.execute(db, sql) |> DataFrame

weights_data.WORKOUT_DATE = Dates.Date.(weights_data.WORKOUT_DATE)
sort!(weights_data, :WORKOUT_DATE)

pd(; x, y) = PlotData(x = x, y = y, plot = StipplePlotly.Charts.PLOT_TYPE_LINE)

@reactive mutable struct Model <: ReactiveModel
    data::R{Vector{Vector{PlotData}}} = [
        [pd(x = group.WORKOUT_DATE, y = group.WEIGHT .* group.REPS)] for
        group in groupby(weights_data, :EXERCISE)
    ]
    layout::R{Vector{PlotLayout}} = [
        PlotLayout(
            title = PlotLayoutTitle(text = "$(group.EXERCISE |> first)", font = Font(24)),
            xaxis = [PlotLayoutAxis(xy = "x", title_text = "Date", font = Font(14))],
            yaxis = [
                PlotLayoutAxis(
                    xy = "y",
                    title_text = "Total Weight Lifted",
                    font = Font(14),
                ),
            ],
            showlegend = false,
            margin_r = 0,
        ) for group in groupby(weights_data, :EXERCISE)
    ]

end

function handlers(model)
    on(model.isready) do isready
        isready || return
        push!(model)
    end

    model
end

function ui(model::Model)
    page(
        model,
        class = "container",
        [
            row([h1("Weight Lifting Exercises")])
            row([
                cell(
                    class = "st-module",
                    [plot("data[index-1]", layout = "layout[index-1]")],
                    @recur("index in 5")
                ),
            ])
            row([
                cell(
                    class = "st-module",
                    [plot("data[index+4]", layout = "layout[index+4]")],
                    @recur("index in 5")
                ),
            ])
        ],
    )
end

model = init(Model)
route("/") do
    model |> handlers |> ui |> html
end

up(8000)
