testlist = [
# Aqua.jl
  "Aqua.jl",
# Fields-test.jl
  "flint/fmpq-test.jl",
  "flint/gfp-test.jl",
  "flint/gfp_fmpz-test.jl",
  "flint/fq-test.jl",
  "flint/fq_nmod-test.jl",
  "flint/fq_default-test.jl",
  "flint/fq_default_extended-test.jl",
  "flint/fq_embed-test.jl",
  "flint/fq_nmod_embed-test.jl",
  "flint/fq_default_embed-test.jl",
  "flint/padic-test.jl",
  "flint/qadic-test.jl",
  "antic/nf_elem-test.jl",
  "arb/arb-test.jl",
  "arb/Real-test.jl",
  "arb/acb-test.jl",
  "arb/Complex-test.jl",
  "calcium/ca-test.jl",
  "calcium/qqbar-test.jl",
  "gaussiannumbers/fmpqi-test.jl",
# Rings-test.jl
  "flint/fmpz-test.jl",
  "flint/fmpz_factor-test.jl",
  "flint/fmpz_poly-test.jl",
  "flint/fmpz_mod_poly-test.jl",
  "flint/gfp_fmpz_poly-test.jl",
  "flint/nmod-test.jl",
  "flint/fmpz_mod-test.jl",
  "flint/nmod_poly-test.jl",
  "flint/gfp_poly-test.jl",
  "flint/fmpq_poly-test.jl",
  "flint/fq_poly-test.jl",
  "flint/fq_nmod_poly-test.jl",
  "flint/fq_default_poly-test.jl",
# The following two tests are included in fmpz-test.jl
#  "flint/fmpz_rel_series-test.jl",
#  "flint/fmpz_abs_series-test.jl",
  "flint/fmpz_laurent_series-test.jl",
  "flint/fmpz_puiseux_series-test.jl",
# The following two tests are included in fmpq-test.jl
#  "flint/fmpq_rel_series-test.jl",
#  "flint/fmpq_abs_series-test.jl",
  "flint/nmod_abs_series-test.jl",
  "flint/gfp_abs_series-test.jl",
  "flint/fmpz_mod_abs_series-test.jl",
  "flint/gfp_fmpz_abs_series-test.jl",
  "flint/nmod_rel_series-test.jl",
  "flint/gfp_rel_series-test.jl",
  "flint/fmpz_mod_rel_series-test.jl",
  "flint/gfp_fmpz_rel_series-test.jl",
  "flint/fq_rel_series-test.jl",
  "flint/fq_abs_series-test.jl",
  "flint/fq_nmod_rel_series-test.jl",
  "flint/fq_nmod_abs_series-test.jl",
  "flint/fq_default_abs_series-test.jl",
  "flint/fq_default_rel_series-test.jl",
  "flint/nmod_mat-test.jl",
  "flint/fmpz_mod_mat-test.jl",
  "flint/gfp_mat-test.jl",
  "flint/gfp_fmpz_mat-test.jl",
  "flint/fq_mat-test.jl",
  "flint/fq_nmod_mat-test.jl",
  "flint/fq_default_mat-test.jl",
  "flint/fmpz_mat-test.jl",
  "flint/fmpq_mat-test.jl",
  "arb/arb_poly-test.jl",
  "arb/RealPoly-test.jl",
  "arb/acb_poly-test.jl",
  "arb/ComplexPoly-test.jl",
  "arb/arb_mat-test.jl",
  "arb/RealMat-test.jl",
  "arb/acb_mat-test.jl",
  "arb/ComplexMat-test.jl",
  "flint/fmpz_mpoly-test.jl",
  "flint/fmpq_mpoly-test.jl",
  "flint/nmod_mpoly-test.jl",
  "flint/gfp_mpoly-test.jl",
  "flint/gfp_fmpz_mpoly-test.jl",
  "flint/fq_nmod_mpoly-test.jl",
  "flint/fq_default_mpoly-test.jl",
  "gaussiannumbers/fmpzi-test.jl",
# Generic-test.jl
  "generic/Poly-test.jl",
  "generic/MPoly-test.jl",
  "generic/UnivPoly-test.jl",
  "generic/Matrix-test.jl",
  "generic/Module-test.jl",
  "generic/AbsMSeries-test.jl",
# Benchmark-test.jl
  "Benchmark-test.jl",
# gaussiannumbers/continued_fraction-test.jl
  "gaussiannumbers/continued_fraction-test.jl",
# Native-test.jl
  "Native-test.jl",
# Infinity-test.jl
  "Infinity-test.jl",
# HeckeMiscLocalization-test.jl
  "HeckeMiscLocalization-test.jl",
# matrix-test.jl
  "matrix-test.jl",
# poly-test.jl
  "poly-test.jl",
# ZZMatrix-linalg-test.jl
  "ZZMatrix-linalg-test.jl"
]

pmap(include, testlist)
