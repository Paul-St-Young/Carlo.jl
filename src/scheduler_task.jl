using Formatting

mutable struct SchedulerTask
    target_sweeps::Int64
    sweeps::Int64

    dir::String
    scheduled_runs::Int64
end

is_done(task::SchedulerTask) = task.sweeps >= task.target_sweeps

function run_dir(task::SchedulerTask, run_id::Integer)
    return format("{}/run{:04d}", task.dir, run_id)
end

function merge_results(
    ::Type{MC},
    taskdir::AbstractString;
    parameters::Dict{Symbol,Any},
    data_type::Type{T} = Float64,
    rebin_length::Union{Integer,Nothing} = nothing,
    sample_skip::Integer = 0,
) where {MC<:AbstractMC,T}
    merged_results = merge_results(
        JobTools.list_run_files(taskdir, "meas\\.h5"),
        data_type;
        rebin_length = rebin_length,
        sample_skip = sample_skip,
    )

    evaluator = Evaluator(merged_results)
    register_evaluables(MC, evaluator, parameters)

    results = Dict(
        name => ResultObservable(obs) for
        (name, obs) in merge(merged_results, evaluator.evaluables)
    )
    write_results(
        merge(results),
        taskdir * "/results.json",
        taskdir,
        parameters,
        Version(MC),
    )
    return nothing
end
