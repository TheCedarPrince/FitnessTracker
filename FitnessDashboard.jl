using DataFrames
using DBInterface
using FunSQL
using FunSQL: From, Get, Group, Select, render, reflect
using Genie, Stipple, StippleUI
using Genie.Renderers.Html
using SQLite
using Stipple
using StipplePlotly
using StippleUI

db = DBInterface.connect(SQLite.DB, "exercise.db")
table_info = reflect(db).tables

weights = table_info[:weights]
running = table_info[:running]

weights_data =
    From(weights) |> FunSQL.render |> sql -> DBInterface.execute(db, sql) |> DataFrame

running_data =
    From(running) |> FunSQL.render |> sql -> DBInterface.execute(db, sql) |> DataFrame

pd(; x, y, name) =
    PlotData(x = x, y = y, plot = StipplePlotly.Charts.PLOT_TYPE_LINE, name = name)

export Model

@reactive mutable struct Model <: ReactiveModel
    plot_weight_data::R{Vector{PlotData}} = [
        pd(
            x = [Dates.Date(row.WORKOUT_DATE)],
            y = [row.WEIGHT * row.REPS],
            name = row.EXERCISE,
        ) for row in eachrow(weights_data)
    ]

    layout_weight_data::R{PlotLayout} = PlotLayout(
        plot_bgcolor = "#333",
        title = PlotLayoutTitle(text = "Weight Lifted Over Year", font = Font(24)),
        xaxis = [PlotLayoutAxis(title_text = "Date")],
        yaxis = [PlotLayoutAxis(title_text = "Total Weight Lifted per Exercise")],
    )

    config_weight_data::R{PlotConfig} = PlotConfig()
    
    plot_running_data::R{Vector{PlotData}} = [
        pd(
            x = [Dates.Date(row.WORKOUT_DATE)],
            y = [row.DISTANCE],
            name = row.RUN_TYPE,
        ) for row in eachrow(running_data)
    ]

    layout_running_data::R{PlotLayout} = PlotLayout(
        plot_bgcolor = "#333",
        title = PlotLayoutTitle(text = "Distance Ran Over Year", font = Font(24)),
        xaxis = [PlotLayoutAxis(title_text = "Date")],
    )

    config_running_data::R{PlotConfig} = PlotConfig()

end

model = Model |> init

function ui(model)
    page(
        model,
        class = "container",
        [
            plot(
                :plot_weight_data,
                layout = :layout_weight_data,
                config = :config_weight_data,
            ),
            plot(
                :plot_running_data,
                layout = :layout_running_data,
                config = :config_running_data,
            ),
        ],
    )
end

route("/") do
    Stipple.init(Model) |> ui |> html
end
