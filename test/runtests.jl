using Test
using LoadLeveller
using MPI

include("test_utils.jl")
include("test_mc.jl")

tests = [
    "test_runnertask.jl"
    "test_jobinfo.jl"
    "test_runner.jl"
    "test_walker.jl"
    "test_observable.jl"
    "test_random_wrap.jl"
    "test_results.jl"
    "test_evaluable.jl"
    "test_measurements.jl"
    "test_mccontext.jl"
    "test_merge.jl"
    "test_taskmaker.jl"
]

for test in tests
    include(test)
end
