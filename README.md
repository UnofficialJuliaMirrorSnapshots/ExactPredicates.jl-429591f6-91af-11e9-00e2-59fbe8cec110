# ExactPredicates.jl

→ [Documentation](https://lairez.github.io/ExactPredicates.jl/)

This package provides two important predicates for geometry in the Euclidean plane: `orient` and `incircle`.

They are ports in Julia of the [CGAL](https://www.cgal.org/) C++ predicates, implemented by Sylvain Pion.
They use floating point arithmetic and fallback to slow exact arithmetic when required. The algorithm has been proved robust and correct in a formal proof system by Guillaume Melquiond and Sylvain Pion ([“Formal certification of arithmetic filters for geometric predicates”](https://hal.inria.fr/inria-00344518), *IMACS 2005*) in all cases:

- underflows and overflows in the floating point computation;
- degenerate configurations (collinear points, colliding vertices, etc.).

**Robust** means that the code:

- raises an exception on `NaN` and `Inf` arguments;
- gives a correct answer on all other inputs, no matter what.

