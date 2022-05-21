using Base: prompt, run
using CSV
using DataFrames
using Dates
using REPL.TerminalMenus
using SQLite

cached_workout = prompt(
    "Do you want to use a cached workout? Input filepath here, otherwise, press ENTER",
)

if isempty(cached_workout)
    exercise_path = prompt(
        "What is the path to your exercise list? Input a directory path to locate the exercise list. Otherwise, leave blank. Default: \"\"",
    )

    println("")

    if !isempty(exercise_path)
        reset = prompt(
            "Would you like to create an exercise list? Enter Y for yes, N for no. Default: N",
        )
        if reset == "Y"
            open(joinpath(exercise_path, "exercise_list.csv"), "w") do f
                write(f, "EXERCISE,WEIGHT,REPS,MUSCLE_GROUP\n")
            end
        end
    end

    println("")

    open(joinpath(exercise_path, "exercise_list.csv"), "a") do f
        exercise_name = prompt(
            "Please input name of new exercise (leave empty and press ENTER if no new exercises).",
        )
        while !isempty(exercise_name)
            muscle_group = prompt(
                "Please input muscle group of new exercise (leave empty and press ENTER if no new exercises).",
            )
            write(f, "$(exercise_name),0,0,$(muscle_group)\n")
            run(`clear`)

            exercise_name = prompt(
                "Exercise added. Please input name of next exercise (leave empty and press ENTER if no new exercises).",
            )
        end
    end

    weight_df = CSV.read(joinpath(exercise_path, "exercise_list.csv"), DataFrame)
    println("Log workout activity.")

    updated_df = DataFrame()
    for row in eachrow(weight_df)
        println("Logging exercise $(row.EXERCISE) information.")
        response = prompt("""Is the following information correct for this exercise?\n
           $(row.EXERCISE):\n
        Weight: $(row.WEIGHT)
        Reps Count: $(row.REPS)\n
        Muscle Group: $(row.MUSCLE_GROUP)\n
         Enter ENTER for Yes, E to Edit, and press N to skip logging exercise""")
        if response == "E"
            exercise = row.EXERCISE
            weight = prompt("Change weight") |> x -> parse(Float64, x)
            reps = prompt("Change rep count") |> x -> parse(Float64, x)
            muscle_group = prompt("Change muscle group")
            push!(
                updated_df,
                Dict(
                    :EXERCISE => exercise,
                    :WEIGHT => weight,
                    :REPS => reps,
                    :MUSCLE_GROUP => muscle_group,
                ),
                cols = :union,
            )
        elseif isempty(response)
            push!(
                updated_df,
                Dict(
                    :EXERCISE => row.EXERCISE,
                    :WEIGHT => row.weight,
                    :REPS => row.reps,
                    :MUSCLE_GROUP => muscle_group,
                ),
                cols = :union,
            )
        else
            continue
        end

    end

    filter!(row -> !in(row.EXERCISE, updated_df.EXERCISE), weight_df)
    weight_df = vcat(weight_df, updated_df)
    cache_path = prompt(
        """Here is the recorded workout:
              $(weight_df)
        	Would you like to save this workout? Enter a filename and path if so, otherwise, press ENTER to skip
    """,
    )

    if !isempty(cache_path)
        CSV.write(cache_path, weight_df)
    end

    date = Dates.format(now(), dateformat"YYYY-mm-dd")
    date_change = prompt(
        "Log this workout for $date? If incorrect date, write date in form of YYYY-MM-DD, otherwise, press ENTER",
    )

    if !isempty(date_change)
        date = Date(date_change, dateformat"YYYY-mm-dd")
    end

    println("Logging now")

    db = SQLite.DB("exercise.db")

    for row in eachrow(weight_df)
        DBInterface.execute(
            db,
            """INSERT INTO weights (`WORKOUT_DATE`, `EXERCISE`, `WEIGHT`, `REPS`, `MUSCLE_GROUP`) VALUES("$(string(date))", "$(row.EXERCISE)", $(row.WEIGHT), $(row.REPS), "$(row.MUSCLE_GROUP)");""",
        )
    end

    println("Workout logged!")

else

    weight_df = CSV.read(cached_workout, DataFrame)

    println("Workout:
     $weight_df
     ")

    date = Dates.format(now(), dateformat"YYYY-mm-dd")
    date_change = prompt(
        "Log workout for $date? If incorrect date, write date in form of YYYY-MM-DD, otherwise, press ENTER",
    )

    if !isempty(date_change)
        date = Date(date_change, dateformat"YYYY-mm-dd")
    end

    println("Logging now")

    db = SQLite.DB("exercise.db")

    for row in eachrow(weight_df)
        DBInterface.execute(
            db,
            """INSERT INTO weights (`WORKOUT_DATE`, `EXERCISE`, `WEIGHT`, `REPS`, `MUSCLE_GROUP`) VALUES("$(string(date))", "$(row.EXERCISE)", $(row.WEIGHT), $(row.REPS), "$(row.MUSCLE_GROUP)");""",
        )
    end

    println("Workout logged!")

end
