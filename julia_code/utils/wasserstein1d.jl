function wasserstein1d(a::AbstractVector{<:Real},
                       b::AbstractVector{<:Real};
                       p::Real = 1)

    # Copy + sort as Float64
    x = sort(Float64.(a))
    y = sort(Float64.(b))

    n = length(x)
    m = length(y)

    # Uniform masses
    mx = fill(1.0 / n, n)
    my = fill(1.0 / m, m)

    i = 1
    j = 1
    cost = 0.0
    pp = float(p)

    while i <= n && j <= m
        mass = min(mx[i], my[j])
        # transport this mass between x[i] and y[j]
        cost += mass * abs(x[i] - y[j])^pp

        mx[i] -= mass
        my[j] -= mass

        if mx[i] <= 0
            i += 1
        end
        if my[j] <= 0
            j += 1
        end
    end

    return pp == 1.0 ? cost : cost^(1/pp)
end