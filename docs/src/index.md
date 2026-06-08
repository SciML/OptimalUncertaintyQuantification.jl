# OptimalUncertaintyQuantification.jl: Optimal Uncertainty Quantification

**DISTRIBUTION STATEMENT A. Approved for public release: distribution unlimited. Case Number: AFRL-2024-5455. Cleared 10/2/2024.**

The Optimal Uncertainty Quantification (OUQ) algorithm provides a means of computing
the bounds of the expectations of quantities of interest despite not having complete
knowledge of the probability distribution of the uncertain variables. This is achieved
by finding the worst/best case distributions in some set ``\mathcal{A}`` of possible
distributions given the knowledge available.

OptimalUncertaintyQuantification.jl implements the OUQ algorithm and its convex and
"moment class" forms in the Julia programming language, using techniques based on
*complete* and *rigorous* global methods in order to bound the effects of finite
computation on the OUQ bounds.

## Installation

To install OptimalUncertaintyQuantification.jl, use the Julia package manager:

```julia
using Pkg
Pkg.add("OptimalUncertaintyQuantification")
```

## Contributing

- Please refer to the
  [SciML ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://github.com/SciML/ColPrac/blob/master/README.md)
  for guidance on PRs, issues, and other matters relating to contributing to SciML.
- See the [SciML Style Guide](https://github.com/SciML/SciMLStyle) for common coding practices and other style decisions.
- There are a few community forums:
  - The #diffeq-bridged and #sciml-bridged channels in the
    [Julia Slack](https://julialang.org/slack/)
  - The #diffeq-bridged and #sciml-bridged channels in the
    [Julia Zulip](https://julialang.zulipchat.com/#narrow/stream/279055-sciml-bridged)
  - On the [Julia Discourse forums](https://discourse.julialang.org)
  - See also [SciML Community page](https://sciml.ai/community/)

## Reproducibility

```@raw html
<details><summary>The documentation of this SciML package was built using these direct dependencies,</summary>
```

```@example
using Pkg # hide
Pkg.status() # hide
```

```@raw html
</details>
```

```@raw html
<details><summary>and using this machine and Julia version.</summary>
```

```@example
using InteractiveUtils # hide
versioninfo() # hide
```

```@raw html
</details>
```
