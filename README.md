# OptimalUncertaintyQuantification.jl

**DISTRIBUTION STATEMENT A. Approved for public release: distribution unlimited. Case Number: AFRL-2024-5455. Cleared 10/2/2024.**

The Optimal Uncertainty Quantification (OUQ) algorithm [1] provides a means computing the bounds of the expectations of quantities of interest despite not having complete knowledge of the probability distribution of the uncertain variables. This is achieved by finding the worst/best case distributions in some set $\cal{A}$ of possible distributions given the knowledge available, i.e.,

<img width="680" height="69" alt="image" src="https://github.com/user-attachments/assets/842f61d2-24b3-4377-aabb-cd6a243f3758" />

where $\mu^*$ is the true, but unknown distribution or measure. 

This package implements the OUQ algorithm [1] and its convex [2] and "moment class" [3-4] forms in the Julia programming language. These are implemented using techniques based on *complete* and *rigorous* global methods in order to bound the effects of finite computation on the OUQ bounds [5-8]. 

Additionally, example usage and benchmarks are provided for a set of problems in the open literature (e.g. [benchmarks](https://ths.rwth-aachen.de/research/projects/hypro/benchmarks-of-continuous-and-hybrid-systems/)). 


# Requirements
- Julia v1.12



# References
1. Owhadi, H., Scovel, C., Sullivan, T. J., McKerns, M., and Ortiz, M., “Optimal Uncertainty Quantification,” SIAM Review, Vol. 55, No. 2, 2013, pp. 271–345. https://doi.org/10.1137/10080782X

1.  Han, S., Tao, M., Topcu, U., Owhadi, H., and Murray, R. M., “Convex Optimal Uncertainty Quantification,” SIAM Journal on Optimization, Vol. 25, No. 3, 2015, pp. 1368–1387. https://doi.org/10.1137/13094712X

1. Stenger, J., Gamboa, F., Keller, M., and Iooss, B., “Optimal Uncertainty Quantification of a Risk Measurement from a Thermal-Hydraulic Code Using Canonical Moments", International Journal for Uncertainty Quantification, Vol. 10, No. 1, 2020. https://doi.org/10.1615/Int.J.UncertaintyQuantification.2020030800

1. Stenger, J., Gamboa, F., Keller, M., and Iooss, B., “Canonical Moments for Optimal Uncertainty Quantification on a Variety,” Cham, 2019. https://doi.org/10.1007/978-3-030-26980-7_59

1. Neumaier, A., “Complete Search in Continuous Global Optimization and Constraint Satisfaction,” Acta numerica, Vol. 13, 2004, pp. 271–369.

1. Makino, K., and Berz, M., “Rigorous Integration of Flows and ODEs Using Taylor Models,” New York, NY, USA, 2009. https://doi.org/10.1145/1577190.1577206

1. Scott, J. K., Stuber, M. D., and Barton, P. I., “Generalized McCormick Relaxations,” Journal of Global Optimization, Vol. 51, No. 4, 2011, pp. 569–606. https://doi.org/10.1007/s10898-011-9664-7

1. Horning, A., and Gerlach, A. R., “A Family of High-Order Accurate Contour Integral Methods for Strongly Continuous Semigroups,” 2024. http://arxiv.org/abs/2408.07691 
