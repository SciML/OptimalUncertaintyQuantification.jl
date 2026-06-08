# OUQBase.jl

[![Join the chat at https://julialang.zulipchat.com #sciml-bridged](https://img.shields.io/static/v1?label=Zulip&message=chat&color=9558b2&labelColor=389826)](https://julialang.zulipchat.com/#narrow/stream/279055-sciml-bridged)
[![Global Docs](https://img.shields.io/badge/docs-SciML-blue.svg)](https://docs.sciml.ai/OptimalUncertaintyQuantification/stable/)

[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor%27s%20Guide-blueviolet)](https://github.com/SciML/ColPrac)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)

OUQBase.jl is a component of the [OptimalUncertaintyQuantification.jl](https://github.com/SciML/OptimalUncertaintyQuantification.jl) monorepo. It holds the core Optimal Uncertainty Quantification interface: admissible sets, OUQ systems and problems, and the reduction transformations (Winkler extremal measures and Stenger canonical moments) that turn an OUQ problem into a solvable optimization.
While completely independent and usable on its own, users wanting the full Optimal Uncertainty Quantification suite should use [OptimalUncertaintyQuantification.jl](https://github.com/SciML/OptimalUncertaintyQuantification.jl).
