using OptimalUncertaintyQuantification

# Example from Stenger, J., Gamboa, F., Keller, M., and Iooss, B., “OPTIMAL UNCERTAINTY QUANTIFICATION OF A RISK MEASUREMENT FROM A THERMAL-HYDRAULIC CODE USING CANONICAL MOMENTS,” International Journal for Uncertainty Quantification, Vol. 10, No. 1, 2020. https://doi.org/10.1615/Int.J.UncertaintyQuantification.2020030800
# results computed via Stenger's python code https://github.com/JeromeStenger/canonicalOUQ

function H(Q::T, Ks::T, Zv::T, Zm::T) where {T}
    return (Q / (T(300) * Ks * √((Zm - Zv) / T(5000))))^(T(3) / T(5))
end
g_h(h) = X -> H(X...) <= h

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
    [50.0, 7501 / 3.0, 125050],
    [54.5, 8911 / 3.0, 647569 / 4],
]

threshold = 4

setup1 = [
    (free = [fill(0.5, 2) for _ in 1:length(c1)], res = 0.8346769701),
    (free = [fill(0.25, 2) for _ in 1:length(c1)], res = 0.8423597615),
    (free = [fill(0.75, 2) for _ in 1:length(c1)], res = 0.8355977711),
    (
        free = [
            [0.11008426115113379, 0.4913831957970459],
            [0.5651453592612876, 0.2538117862083361],
            [0.626793910352374, 0.23410455326227375],
            [0.1247919570769006, 0.609874865666702],
        ],
        res = 0.8877773081,
    ),
]

setup2 = [
    (free = [fill(0.5, 3) for _ in 1:length(c2)], res = 0.9084523325),
    (free = [fill(0.25, 3) for _ in 1:length(c2)], res = 0.9158574604),
    (free = [fill(0.75, 3) for _ in 1:length(c2)], res = 0.9429896112),
    (
        free = [
            [0.11008426115113379, 0.4913831957970459, 0.5651453592612876],
            [0.2538117862083361, 0.626793910352374, 0.23410455326227375],
            [0.1247919570769006, 0.609874865666702, 0.6727928883390367],
            [0.7619157626781667, 0.5888720595243433, 0.36585394350375],
        ],
        res = 0.9018177916,
    ),
]

setup3 = [
    (free = [fill(0.5, 4) for _ in 1:length(c3)], res = 0.938505042),
    (free = [fill(0.25, 4) for _ in 1:length(c3)], res = 0.9267572769),
    (free = [fill(0.75, 4) for _ in 1:length(c3)], res = 0.9327169677),
    (
        free = [
            [
                0.11008426115113379,
                0.4913831957970459,
                0.5651453592612876,
                0.2538117862083361,
            ],
            [0.626793910352374, 0.23410455326227375, 0.1247919570769006, 0.609874865666702],
            [0.6727928883390367, 0.7619157626781667, 0.5888720595243433, 0.36585394350375],
            [
                0.13102565622085904,
                0.9464532262313834,
                0.5743234852783174,
                0.6776499075995779,
            ],
        ],
        res = 0.9596593041,
    ),
]
