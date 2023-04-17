using HDF5
using ElasticArrays

const binning_output_chunk_size = 1000

mutable struct Observable{T<:AbstractFloat}
    bin_length::Int64
    current_bin_filling::Int64

    samples::ElasticArray{T,2,1,Vector{Float64}}
end

function Observable{T}(bin_length::Integer, vector_length::Integer) where {T}
    samples = ElasticArray{T,2}(undef, vector_length, 1)
    samples[1, 1] = 0
    return Observable(bin_length, 0, samples)
end

function add_sample!(obs::Observable, value::Union{Number,AbstractVector{<:Number}})
    if length(value) != size(obs.samples, 1)
        error(
            "length of added value ($(length(value))) does not fit length of observable ($(size(obs.samples,1)))",
        )
    end

    obs.samples .+= value
    obs.current_bin_filling += 1

    if obs.current_bin_filling == obs.bin_length
        if obs.bin_length > 1
            obs.samples[:, end] /= obs.bin_length
        end

        append!(obs.samples, zeros(size(obs.samples, 1)))
        obs.current_bin_filling = 0
    end

    return nothing
end

function write_measurements!(obs::Observable{T}, out::HDF5.Group) where {T}
    if size(obs.samples, 2) > 1

        if haskey(out, "samples")
            saved_samples = out["samples"]
            old_bin_count = size(saved_samples, 2)
        else
            saved_samples = create_dataset(
                out,
                "samples",
                eltype(obs.samples),
                ((size(obs.samples, 1), size(obs.samples, 2)), (size(obs.samples, 1), -1));
                chunk = (size(obs.samples, 1), binning_output_chunk_size),
            )
            old_bin_count = 0
        end

        HDF5.set_extent_dims(
            saved_samples,
            (size(obs.samples, 1), old_bin_count + size(obs.samples, 2) - 1),
        )
        saved_samples[:, old_bin_count+1:end] = obs.samples[:, 1:end-1]

        obs.samples = ElasticArray{T,2}(copy(obs.samples[:, end:end]))

        if !haskey(out, "bin_length")
            out["bin_length"] = obs.bin_length
        end
    end

end

function write_checkpoint(obs::Observable, out::HDF5.Group)
    @assert size(obs.samples, 2) <= 1
    out["bin_length"] = obs.bin_length
    out["current_bin_filling"] = obs.current_bin_filling
    out["samples"] = obs.samples

    return nothing
end

function read_checkpoint(::Type{Observable{T}}, in::HDF5.Group) where {T}
    return Observable{T}(
        read(in, "bin_length"),
        read(in, "current_bin_filling"),
        read(in, "samples"),
    )
end
