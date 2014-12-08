#
# Phase lag index
#
# See Stam, C. J., Nolte, G., & Daffertshofer, A. (2007).
# Phase lag index: Assessment of functional connectivity from multi
# channel EEG and MEG with diminished bias from common sources.
# Human Brain Mapping, 28(11), 1178–1193. doi:10.1002/hbm.20346
immutable PLI <: RealPairwiseStatistic; end
immutable PLIAccumulator{T}
    s::Complex{T}   # Sum of sign(imag(conj(v1)*(v2)))
end
accumulator{T<:Real}(::PLI, ::Type{T}) = PLIAccumulator{T}(complex(zero(T), zero(T)))
finish(x::PLIAccumulator, n::Int) = abs(x.s)/n

#
# Unbiased squared phase lag index, weighted phase
#
# See Vinck, M., Oostenveld, R., van Wingerden, M., Battaglia, F., &
# Pennartz, C. M. A. (2011). An improved index of phase-synchronization
# for electrophysiological data in the presence of volume-conduction,
# noise and sample-size bias. NeuroImage, 55(4), 1548–1565.
# doi:10.1016/j.neuroimage.2011.01.055
immutable PLI2Unbiased <: RealPairwiseStatistic; end
immutable PLI2UnbiasedAccumulator{T}
    s::Complex{T}   # Sum of sign(imag(conj(v1)*(v2)))
end
accumulator{T<:Real}(::PLI2Unbiased, ::Type{T}) =
    PLI2UnbiasedAccumulator{T}(complex(zero(T), zero(T)))
accumulate{T<:Real}(x::Union(PLIAccumulator{T}, PLI2UnbiasedAccumulator{T}),
                    v1::Complex{T}, v2::Complex{T}) =
    typeof(x)(x.s + sign(imag(conj(v1)*v2)))
finish(x::PLI2UnbiasedAccumulator, n::Int) = abs2(x.s)/(n*(n-1)) - 1/(n-1)

#
# Weighted phase lag index
#
# See Vinck et al. (2011) as above.
immutable WPLI <: RealPairwiseStatistic; end
immutable WPLIAccumulator{T}
    si::Complex{T}   # Sum of imag(conj(v1)*(v2))
    sa::T            # Sum of abs(imag(conj(v1)*(v2)))
end
accumulator{T<:Real}(::WPLI, ::Type{T}) =
    WPLIAccumulator{T}(complex(zero(T), zero(T)), zero(T))
function accumulate{T<:Real}(x::WPLIAccumulator{T}, v1::Complex{T}, v2::Complex{T})
    z = imag(conj(v1)*v2)
    WPLIAccumulator(x.si + z, x.sa + abs(z))
end
finish(x::WPLIAccumulator, n::Int) = abs(x.si)/x.sa

#
# Debiased (i.e. still somewhat biased) WPLI^2
#
# See Vinck et al. (2011) as above.
immutable WPLI2Debiased <: RealPairwiseStatistic; end
immutable WPLI2DebiasedAccumulator{T}
    si::Complex{T}   # Sum of imag(conj(v1)*(v2))
    sa::T            # Sum of abs(imag(conj(v1)*(v2)))
    sa2::T           # Sum of abs2(imag(conj(v1)*(v2)))
end
accumulator{T<:Real}(::WPLI2Debiased, ::Type{T}) =
    WPLI2DebiasedAccumulator{T}(complex(zero(T), zero(T)), zero(T), zero(T))
function accumulate{T<:Real}(x::WPLI2DebiasedAccumulator{T}, v1::Complex{T}, v2::Complex{T})
    z = imag(conj(v1)*v2)
    WPLI2DebiasedAccumulator(x.si + z, x.sa + abs(z), x.sa2 + abs2(z))
end
finish(x::WPLI2DebiasedAccumulator, n::Int) = (abs2(x.si) - x.sa2)/(abs2(x.sa) - x.sa2)

#
# Functions applicable to all phase lag-style metrics
#
typealias PLStat Union(PLI, PLI2Unbiased, WPLI, WPLI2Debiased)

allocwork{T<:Complex}(::PLStat, X::AbstractVecOrMat{T}, Y::AbstractVecOrMat{T}=X) =
    nothing

# Single input matrix
function computestat!{T<:Real}(t::PLStat, out::AbstractMatrix{T}, work::Nothing,
                               X::AbstractVecOrMat{Complex{T}})
    chkinput(out, X)
    for k = 1:size(X, 2), j = 1:k
        v = accumulator(t, T)
        @simd for i = 1:size(X, 1)
            @inbounds v = accumulate(v, X[i, j], X[i, k])
        end
        out[j, k] = finish(v, size(X, 1))
    end
    out
end

# Two input matrices
function computestat!{T<:Real}(t::PLStat, out::AbstractMatrix{T}, work::Nothing,
                               X::AbstractVecOrMat{Complex{T}},
                               Y::AbstractVecOrMat{Complex{T}})
    chkinput(out, X, Y)
    for k = 1:size(Y, 2), j = 1:size(X, 2)
        v = accumulator(t, T)
        @simd for i = 1:size(X, 1)
            @inbounds v = accumulate(v, X[i, j], Y[i, k])
        end
        out[j, k] = finish(v, size(X, 1))
    end
    out
end
