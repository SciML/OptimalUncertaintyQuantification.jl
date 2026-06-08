# Example from Stenger, J., Gamboa, F., Keller, M., and Iooss, B., “OPTIMAL UNCERTAINTY QUANTIFICATION OF A RISK MEASUREMENT FROM A THERMAL-HYDRAULIC CODE USING CANONICAL MOMENTS,” International Journal for Uncertainty Quantification, Vol. 10, No. 1, 2020. https://doi.org/10.1615/Int.J.UncertaintyQuantification.2020030800
# Compared against Stenger's Python implementation: https://github.com/JeromeStenger/canonicalOUQ

using CanonicalMoments
import Random
Random.seed!(1234)

function H(Q, Ks, Zv, Zm)
    return (Q / (300.0 * Ks * √((Zm - Zv) / 5000.0)))^(3.0 / 5.0)
end

g_h(h) = X -> H(X...) <= h

g = g_h(5)
g([1013, 30, 50, 54.5])

ql = [160, 12.55, 49.0, 54.0]    # lower bounds on random variables
qu = [3580.0, 47.45, 51.0, 55.0]  # upper bounds on random variables

c1 = [
    [1320.42], # just means
    [30.0],
    [50.0],
    [54.5],
]

c2 = [
    [1320.42, 2.1632e6], # means and 2nd moments
    [30.0, 949.137],
    [50.0, 7501 / 3.0],
    [54.5, 8911 / 3.0],
]

c3 = [
    [1320.42, 2.1632e6, 4.18e9], # means and 3rd moments
    [30.0, 949.137, 31422.3],
    [50.0, 7501 / 3.0, 125050.0],
    [54.5, 8911 / 3.0, 647569 / 4.0],
]

p1_free = [rand(2) for i in 1:4]
p2_free = [rand(3) for i in 1:4]

pof_ = pof(ql, qu, c1, g_h(2), p1_free)
pof2_ = pof(ql, qu, c2, g_h(2), p2_free)

## Compare to Stenger
### 1 Moment Constraint
threshold = 4
p1_free = [fill(0.5, 2) for i in 1:4]
pof_ = pof(ql, qu, c1, g_h(threshold), p1_free)
@assert pof_ ≈ 0.8346769701

p1_free = [fill(0.25, 2) for i in 1:4]
pof_ = pof(ql, qu, c1, g_h(threshold), p1_free)
@assert pof_ ≈ 0.8423597615

p1_free = [fill(0.75, 2) for i in 1:4]
pof_ = pof(ql, qu, c1, g_h(threshold), p1_free)
@assert pof_ ≈ 0.8355977711

p1_free = [
    [0.11008426115113379, 0.4913831957970459],
    [0.5651453592612876, 0.2538117862083361],
    [0.626793910352374, 0.23410455326227375],
    [0.1247919570769006, 0.609874865666702],
]
pof_ = pof(ql, qu, c1, g_h(threshold), p1_free)
@assert pof_ ≈ 0.8877773081

### 2 Moment Constraints
p2_free = [fill(0.5, 3) for i in 1:4]
pof_ = pof(ql, qu, c2, g_h(threshold), p2_free)
@assert pof_ ≈ 0.9084523325

p2_free = [fill(0.25, 3) for i in 1:4]
pof_ = pof(ql, qu, c2, g_h(threshold), p2_free)
@assert pof_ ≈ 0.9158574604

p2_free = [fill(0.75, 3) for i in 1:4]
pof_ = pof(ql, qu, c2, g_h(threshold), p2_free)
@assert pof_ ≈ 0.9429896112

p2_free = [
    [0.11008426115113379, 0.4913831957970459, 0.5651453592612876],
    [0.2538117862083361, 0.626793910352374, 0.23410455326227375],
    [0.1247919570769006, 0.609874865666702, 0.6727928883390367],
    [0.7619157626781667, 0.5888720595243433, 0.36585394350375],
]
pof_ = pof(ql, qu, c2, g_h(threshold), p2_free)
@assert pof_ ≈ 0.9018177916

### 3 Moment Constraints
p3_free = [fill(0.5, 4) for i in 1:4]
pof_ = pof(ql, qu, c3, g_h(threshold), p3_free)
@assert pof_ ≈ 0.938505042

p3_free = [fill(0.25, 4) for i in 1:4]
pof_ = pof(ql, qu, c3, g_h(threshold), p3_free)
@assert pof_ ≈ 0.9267572769

p3_free = [fill(0.75, 4) for i in 1:4]
pof_ = pof(ql, qu, c3, g_h(threshold), p3_free)
@assert pof_ ≈ 0.9327169677

p3_free = [
    [0.11008426115113379, 0.4913831957970459, 0.5651453592612876, 0.2538117862083361],
    [0.626793910352374, 0.23410455326227375, 0.1247919570769006, 0.609874865666702],
    [0.6727928883390367, 0.7619157626781667, 0.5888720595243433, 0.36585394350375],
    [0.13102565622085904, 0.9464532262313834, 0.5743234852783174, 0.6776499075995779],
]
pof_ = pof(ql, qu, c3, g_h(threshold), p3_free)
@assert pof_ ≈ 0.9596593041
