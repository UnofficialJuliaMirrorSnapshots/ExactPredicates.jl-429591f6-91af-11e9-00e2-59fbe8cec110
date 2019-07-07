# SPDX-License-Identifier: LGPL-3.0-or-later
#
# Contributors:
#
#   - Sylvain Pion (author of the CGAL C++ version)
#   - Pierre Lairez (Julia port)


module ExactPredicates

import Base: complex

export orient, incircle, acuteangle


global genericcallcounter = 0

function resetgenericcallcounter!()
    global genericcallcounter
    genericcallcounter = 0
end

function incgenericcallcounter!()
    global genericcallcounter
    genericcallcounter += 1
end

function signof(x) :: Int
    if x > zero(x)
        return 1
    elseif x < zero(x)
        return -1
    else
        return 0
    end
end

function exact(z :: Complex)
    return complex(exact(real(z)), exact(imag(z)))
end

function exact(x :: Float64)
    return convert(Rational{BigInt}, x)
end

function det(a, b, c, d)
    return a*d - b*c
end

function det(u :: Complex, v :: Complex)
    return imag(conj(u)*v)
end



"""

    orient(p, q, r) -> Int

Return `1` if `r` is on the left of the oriented line defined by `p` and
`q`. Return `-1` if `r` is on the right. Return `0` if `r` is on the line or
if `p == q`.

The result is guaranteed to be correct if `p`, `q` and `r` are `Complex{Float64}` values, or faithfully convertible to `Complex{Float64}` values *via* `complex`.
"""
orient(p, q, r) = orient(complex(p), complex(q), complex(r))

function orient(p :: Complex, q :: Complex, r :: Complex)
    incgenericcallcounter!()
    return signof(det(q-p, r-p))
end

function orient(p :: ComplexF64, q :: ComplexF64, r :: ComplexF64)
    # port of https://github.com/CGAL/cgal/blob/c68cf8fc4c850f8cd84c6900faa781286a7117ed/Filtered_kernel/include/CGAL/internal/Static_filters/Orientation_2.h
    pqx, pqy = reim(q - p)
    prx, pry = reim(r - p)
    d = pqx*pry - prx*pqy

    # then semi-static filter
    maxx = abs(pqx)
    maxy = abs(pqy)
    aprx = abs(prx)
    apry = abs(pry)


    if maxx < aprx; maxx = aprx; end
    if maxy < apry; maxy = apry; end

    # sort them
    if maxx > maxy
        maxx, maxy = maxy, maxx
    end

    if maxx < 1e-146            # sqrt(min_double/eps)
        # protect against underflow in the computation of eps
        if (maxx == 0)
            return 0
        end
    elseif maxy < 1e153     # sqrt(max_double [hadamard]/2)
        # protect against overflow in the computation of det
        eps = 8.8872057372592798e-16 * maxx * maxy
        if d > eps
            return 1
        elseif d < -eps
            return -1
        end
    end

    @assert isfinite(p) && isfinite(q) && isfinite(r)
    return orient(exact(p), exact(q), exact(r))
end


acuteangle(p, q, r) = acuteangle(complex(p), complex(q), complex(r))


function acuteangle(p :: Complex, q :: Complex, r :: Complex)
    pq = q-p
    pr = r-p
    pr = complex(-imag(pr), real(pr))
    return orient(zero(pq), pq, pr)
end


"""
    incircle(a, b, c, p) -> Int


Assume that `a`, `b` and `c` define a counterclockwise triangle.
Return `1` if `p` is strictly inside the circumcircle of this triangle.
Return `-1` if `p` is outside.
Return `0` if `p` is on the circle.

If the triangle is oriented clockwise, the signs are reversed.
If `a`, `b` and `c` are collinear, this degenerate to an orientation test.

If two of the four arguments are equal, return `0`.

The result is guaranteed to be correct if `a`, `b`, `c` and `p` are `Complex{Float64}` values, or faithfully convertible to `Complex{Float64}` values *via* `complex`.
"""
incircle(a, b, c, p) = incircle(complex(a), complex(b), complex(c), complex(p))

function incircle(a :: Complex, b :: Complex, c :: Complex, p :: Complex)
    incgenericcallcounter!()

    a = a - p
    b = b - p
    c = c - p
    d = abs2(a)*det(b, c)+abs2(b)*det(c, a)+abs2(c)*det(a, b)
    return signof(d)
end


function incircle(p :: ComplexF64, q :: ComplexF64, r :: ComplexF64, t :: ComplexF64)
    # port of https://github.com/CGAL/cgal/blob/c68cf8fc4c850f8cd84c6900faa781286a7117ed/Filtered_kernel/include/CGAL/internal/Static_filters/Side_of_oriented_circle_2.h
    qpx, qpy = reim(q - p)
    rpx, rpy = reim(r - p)
    tpx, tpy = reim(t - p)
    tqx, tqy = reim(t - q)
    rqx, rqy = reim(r - q)

    d = det(qpx*tpy - qpy*tpx, tpx*tqx + tpy*tqy,
            qpx*rpy - qpy*rpx, rpx*rqx + rpy*rqy)

    # We compute the semi-static bound.
    maxx = abs(qpy)
    maxy = abs(qpy)
    arpx = abs(rpx)
    arpy = abs(rpy)
    atqx = abs(tqx)
    atqy = abs(tqy)
    atpx = abs(tpx)
    atpy = abs(tpy)
    arqx = abs(rqx)
    arqy = abs(rqy)

    if maxx < arpx; maxx = arpx; end
    if maxx < atpx; maxx = atpx; end
    if maxx < atqx; maxx = atqx; end
    if maxx < arqx; maxx = arqx; end

    if maxy < arpy; maxy = arpy; end
    if maxy < atpy; maxy = atpy; end
    if maxy < atqy; maxy = atqy; end
    if maxy < arqy; maxy = arqy; end

    if (maxx > maxy)
        maxx, maxy = maxy, maxx
    end

    if maxx < 1e-73
        # Protect against underflow in the computation of eps.
        if maxx == 0
            return 0
        end
    elseif maxy < 1e76        # sqrt(sqrt(max_double/16 [hadamard]))
        eps = 8.8878565762001373e-15 * maxx * maxy * (maxy*maxy)
        if d > eps
            return 1
        elseif d < -eps
            return -1
        end
    end

    @assert isfinite(p) && isfinite(q) && isfinite(r) && isfinite(t)
    return incircle(exact(p), exact(q), exact(r), exact(t))
end



end


