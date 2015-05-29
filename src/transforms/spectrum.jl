#
# Power spectrum
#

immutable PowerSpectrum <: Statistic; end

Base.eltype{T<:Real}(::PowerSpectrum, X::AbstractVecOrMat{Complex{T}}) = T
allocwork{T<:Complex}(::PowerSpectrum, X::AbstractVecOrMat{Complex{T}}) = nothing
allocoutput{T<:Real}(::PowerSpectrum, X::AbstractVecOrMat{Complex{T}}) =
    Array(T, 1, nchannels(X))

# Single input matrix
computestat!{T<:Real}(::PowerSpectrum, out::AbstractMatrix{T}, ::Nothing,
                      X::AbstractVecOrMat{Complex{T}}) =
    scale!(sumabs2!(out, X), 1/ntrials(X))

#
# Cross spectrum
#

immutable CrossSpectrum <: PairwiseStatistic; end

# Single input matrix
allocwork{T<:Complex}(::CrossSpectrum, X::AbstractVecOrMat{T}) = nothing
computestat!{T<:Complex}(::CrossSpectrum, out::AbstractMatrix{T}, ::Nothing,
                         X::AbstractVecOrMat{T}) =
    scale!(Ac_mul_A!(out, X), 1/ntrials(X, 2))

# Two input matrices
allocwork{T<:Complex}(::CrossSpectrum, X::AbstractVecOrMat{T}, Y::AbstractVecOrMat{T}) = nothing
computestat!{T<:Complex}(::CrossSpectrum, out::AbstractMatrix{T}, ::Nothing,
                         X::AbstractVecOrMat{T}, Y::AbstractVecOrMat{T}) =
    scale!(Ac_mul_B!(out, X, Y), 1/ntrials(X, 2))

accumulator{T<:Real}(::Type{CrossSpectrum}, ::Type{T}) = zero(Complex{T})
@inline accumulate{T<:Real}(::Type{CrossSpectrum}, x::Complex{T},
                            v1::Complex{T}, v2::Complex{T}) = (x + conj(v1)*v2)
@inline accumulate{T<:Real}(::Type{CrossSpectrum}, x::Complex{T},
                            v1::Complex{T}, v2::Complex{T}, weight::Real) = (x + conj(v1)*v2*weight)
finish(::Type{CrossSpectrum}, x::Complex, n::Int) = x/n
