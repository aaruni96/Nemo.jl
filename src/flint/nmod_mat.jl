################################################################################
#
#  nmod_mat.jl: flint nmod_mat types in julia
#
################################################################################

################################################################################
#
#  Data type and parent object methods
#
################################################################################

parent_type(::Type{zzModMatrix}) = zzModMatrixSpace

elem_type(::Type{zzModMatrixSpace}) = zzModMatrix

dense_matrix_type(::Type{zzModRingElem}) = zzModMatrix

function check_parent(x::T, y::T, throw::Bool = true) where T <: Zmodn_mat
   fl = base_ring(x) != base_ring(y)
   fl && throw && error("Residue rings must be equal")
   fl && return false
   fl = (ncols(x) != ncols(y)) && (nrows(x) != nrows(y))
   fl && throw && error("Matrices have wrong dimensions")
   return !fl
end

###############################################################################
#
#   Similar & zero
#
###############################################################################

function similar(::zzModMatrix, R::zzModRing, r::Int, c::Int)
   z = zzModMatrix(r, c, R.n)
   z.base_ring = R
   return z
end

zero(m::zzModMatrix, R::zzModRing, r::Int, c::Int) = similar(m, R, r, c)

################################################################################
#
#  Manipulation
#
################################################################################

@inline function getindex(a::zzModMatrix, i::Int, j::Int)
  @boundscheck Generic._checkbounds(a, i, j)
  u = ccall((:nmod_mat_get_entry, libflint), UInt,
              (Ref{zzModMatrix}, Int, Int), a, i - 1 , j - 1)
  return zzModRingElem(u, base_ring(a)) # no reduction needed
end

#as above, but as a plain UInt, no bounds checking
function getindex_raw(a::T, i::Int, j::Int) where T <: Zmodn_mat
  return ccall((:nmod_mat_get_entry, libflint), UInt,
                 (Ref{T}, Int, Int), a, i - 1, j - 1)
end

@inline function setindex!(a::T, u::UInt, i::Int, j::Int) where T <: Zmodn_mat
  @boundscheck Generic._checkbounds(a, i, j)
  R = base_ring(a)
  setindex_raw!(a, mod(u, R.n), i, j)
end

@inline function setindex!(a::T, u::ZZRingElem, i::Int, j::Int) where T <: Zmodn_mat
  @boundscheck Generic._checkbounds(a, i, j)
  setindex_raw!(a, u, i, j)
end

@inline function setindex!(a::zzModMatrix, u::zzModRingElem, i::Int, j::Int)
  @boundscheck Generic._checkbounds(a, i, j)
  (base_ring(a) != parent(u)) && error("Parent objects must coincide")
  setindex_raw!(a, u.data, i, j) # no reduction necessary
end

setindex!(a::T, u::Integer, i::Int, j::Int) where T <: Zmodn_mat =
        setindex!(a, ZZRingElem(u), i, j)

# as per setindex! but no reduction mod n and no bounds checking
function setindex_raw!(a::T, u::UInt, i::Int, j::Int) where T <: Zmodn_mat
  ccall((:nmod_mat_set_entry, libflint), Nothing,
          (Ref{T}, Int, Int, UInt), a, i - 1, j - 1, u)
end

# as per setindex! but no reduction mod n and no bounds checking
function setindex_raw!(a::T, u::ZZRingElem, i::Int, j::Int) where T <: Zmodn_mat
  t = ZZRingElem()
  ccall((:fmpz_mod_ui, libflint), UInt,
          (Ref{ZZRingElem}, Ref{ZZRingElem}, UInt), t, u, a.n)
  tt = ccall((:fmpz_get_ui, libflint), UInt, (Ref{ZZRingElem}, ), t)
  setindex_raw!(a, tt, i, j)
end

function deepcopy_internal(a::zzModMatrix, dict::IdDict)
  z = zzModMatrix(nrows(a), ncols(a), a.n)
  if isdefined(a, :base_ring)
    z.base_ring = a.base_ring
  end
  ccall((:nmod_mat_set, libflint), Nothing,
          (Ref{zzModMatrix}, Ref{zzModMatrix}), z, a)
  return z
end

nrows(a::T) where T <: Zmodn_mat = a.r

ncols(a::T) where T <: Zmodn_mat = a.c

nrows(a::zzModMatrixSpace) = a.nrows

ncols(a::zzModMatrixSpace) = a.ncols

parent(a::Zmodn_mat) = matrix_space(base_ring(a), nrows(a), ncols(a))

base_ring(a::zzModMatrixSpace) = a.base_ring

base_ring(a::T) where T <: Zmodn_mat = a.base_ring

zero(a::zzModMatrixSpace) = a()

function one(a::zzModMatrixSpace)
  (nrows(a) != ncols(a)) && error("Matrices must be square")
  z = a()
  ccall((:nmod_mat_one, libflint), Nothing, (Ref{zzModMatrix}, ), z)
  return z
end

function iszero(a::T) where T <: Zmodn_mat
  r = ccall((:nmod_mat_is_zero, libflint), Cint, (Ref{T}, ), a)
  return Bool(r)
end

################################################################################
#
#  Comparison
#
################################################################################

==(a::T, b::T) where T <: Zmodn_mat = (a.base_ring == b.base_ring) &&
        Bool(ccall((:nmod_mat_equal, libflint), Cint,
                (Ref{T}, Ref{T}), a, b))

isequal(a::T, b::T) where T <: Zmodn_mat = ==(a, b)

################################################################################
#
#  Transpose
#
################################################################################

function transpose(a::T) where T <: Zmodn_mat
  z = similar(a, ncols(a), nrows(a))
  ccall((:nmod_mat_transpose, libflint), Nothing,
          (Ref{T}, Ref{T}), z, a)
  return z
end

function transpose!(a::T) where T <: Zmodn_mat
  !is_square(a) && error("Matrix must be a square matrix")
  ccall((:nmod_mat_transpose, libflint), Nothing,
          (Ref{T}, Ref{T}), a, a)
end

###############################################################################
#
#   Row and column swapping
#
###############################################################################

function swap_rows!(x::T, i::Int, j::Int) where T <: Zmodn_mat
  ccall((:nmod_mat_swap_rows, libflint), Nothing,
        (Ref{T}, Ptr{Nothing}, Int, Int), x, C_NULL, i - 1, j - 1)
  return x
end

function swap_rows(x::T, i::Int, j::Int) where T <: Zmodn_mat
   (1 <= i <= nrows(x) && 1 <= j <= nrows(x)) || throw(BoundsError())
   y = deepcopy(x)
   return swap_rows!(y, i, j)
end

function swap_cols!(x::T, i::Int, j::Int) where T <: Zmodn_mat
  ccall((:nmod_mat_swap_cols, libflint), Nothing,
        (Ref{T}, Ptr{Nothing}, Int, Int), x, C_NULL, i - 1, j - 1)
  return x
end

function swap_cols(x::T, i::Int, j::Int) where T <: Zmodn_mat
   (1 <= i <= ncols(x) && 1 <= j <= ncols(x)) || throw(BoundsError())
   y = deepcopy(x)
   return swap_cols!(y, i, j)
end

function reverse_rows!(x::T) where T <: Zmodn_mat
   ccall((:nmod_mat_invert_rows, libflint), Nothing,
         (Ref{T}, Ptr{Nothing}), x, C_NULL)
   return x
end

reverse_rows(x::T) where T <: Zmodn_mat = reverse_rows!(deepcopy(x))

function reverse_cols!(x::T) where T <: Zmodn_mat
   ccall((:nmod_mat_invert_cols, libflint), Nothing,
         (Ref{T}, Ptr{Nothing}), x, C_NULL)
   return x
end

reverse_cols(x::T) where T <: Zmodn_mat = reverse_cols!(deepcopy(x))

################################################################################
#
#  Unary operators
#
################################################################################

function -(x::T) where T <: Zmodn_mat
  z = similar(x)
  ccall((:nmod_mat_neg, libflint), Nothing,
          (Ref{T}, Ref{T}), z, x)
  return z
end

################################################################################
#
#  Binary operators
#
################################################################################

function +(x::T, y::T) where T <: Zmodn_mat
  check_parent(x,y)
  z = similar(x)
  ccall((:nmod_mat_add, libflint), Nothing,
          (Ref{T}, Ref{T}, Ref{T}), z, x, y)
  return z
end

function -(x::T, y::T) where T <: Zmodn_mat
  check_parent(x,y)
  z = similar(x)
  ccall((:nmod_mat_sub, libflint), Nothing,
          (Ref{T}, Ref{T}, Ref{T}), z, x, y)
  return z
end

function *(x::T, y::T) where T <: Zmodn_mat
  (base_ring(x) != base_ring(y)) && error("Base ring must be equal")
  (ncols(x) != nrows(y)) && error("Dimensions are wrong")
  z = similar(x, nrows(x), ncols(y))
  ccall((:nmod_mat_mul, libflint), Nothing,
          (Ref{T}, Ref{T}, Ref{T}), z, x, y)
  return z
end


################################################################################
#
#  Unsafe operations
#
################################################################################

function mul!(a::T, b::T, c::T) where T <: Zmodn_mat
  ccall((:nmod_mat_mul, libflint), Nothing, (Ref{T}, Ref{T}, Ref{T}), a, b, c)
  return a
end

function add!(a::T, b::T, c::T) where T <: Zmodn_mat
  ccall((:nmod_mat_add, libflint), Nothing, (Ref{T}, Ref{T}, Ref{T}), a, b, c)
  return a
end

function sub!(a::T, b::T, c::T) where T <: Zmodn_mat
  ccall((:nmod_mat_sub, libflint), Nothing, (Ref{T}, Ref{T}, Ref{T}), a, b, c)
  return a
end

function zero!(a::T) where T <: Zmodn_mat
  ccall((:nmod_mat_zero, libflint), Nothing, (Ref{T}, ), a)
  return a
end

# entries of b required to be in [0,n)
function mul!(z::Vector{UInt}, a::T, b::Vector{UInt}) where T <: Zmodn_mat
   ccall((:nmod_mat_mul_nmod_vec, libflint), Nothing,
         (Ptr{UInt}, Ref{T}, Ptr{UInt}, Int),
         z, a, b, length(b))
   return z
end

# entries of a required to be in [0,n)
function mul!(z::Vector{UInt}, a::Vector{UInt}, b::T) where T <: Zmodn_mat
   ccall((:nmod_mat_nmod_vec_mul, libflint), Nothing,
         (Ptr{UInt}, Ptr{UInt}, Int, Ref{T}),
         z, a, length(a), b)
   return z
end

function mul!(a::zzModMatrix, b::zzModMatrix, c::zzModRingElem)
    ccall((:nmod_mat_scalar_mul, libflint), Nothing,
        (Ref{zzModMatrix}, Ref{zzModMatrix}, UInt), a, b, c.data)
    return a
end

function mul!(A::fpMatrix, B::fpFieldElem, D::fpMatrix)
    ccall((:nmod_mat_scalar_mul_ui, libflint), Nothing, (Ref{fpMatrix}, Ref{fpMatrix}, UInt), A, D, B.data)
end

################################################################################
#
#  Ad hoc binary operators
#
################################################################################

function *(x::T, y::UInt) where T <: Zmodn_mat
  z = similar(x)
  ccall((:nmod_mat_scalar_mul, libflint), Nothing,
          (Ref{T}, Ref{T}, UInt), z, x, y)
  return z
end

*(x::UInt, y::T) where T <: Zmodn_mat = y*x

function *(x::T, y::ZZRingElem) where T <: Zmodn_mat
  t = ZZRingElem()
  ccall((:fmpz_mod_ui, libflint), UInt,
          (Ref{ZZRingElem}, Ref{ZZRingElem}, UInt), t, y, x.n)
  tt = ccall((:fmpz_get_ui, libflint), UInt, (Ref{ZZRingElem}, ), t)
  return x*tt
end

*(x::ZZRingElem, y::T) where T <: Zmodn_mat = y*x

function *(x::T, y::Integer) where T <: Zmodn_mat
  return x*ZZRingElem(y)
end

*(x::Integer, y::T) where T <: Zmodn_mat = y*x

function *(x::zzModMatrix, y::zzModRingElem)
  (base_ring(x) != parent(y)) && error("Parent objects must coincide")
  return x*y.data
end

*(x::zzModRingElem, y::zzModMatrix) = y*x

################################################################################
#
#  Powering
#
################################################################################

function ^(x::T, y::UInt) where T <: Zmodn_mat
  z = similar(x)
  ccall((:nmod_mat_pow, libflint), Nothing,
          (Ref{T}, Ref{T}, UInt), z, x, y)
  return z
end

function ^(x::T, y::Int) where T <: Zmodn_mat
  ( y < 0 ) && error("Exponent must be positive")
  return x^UInt(y)
end

function ^(x::T, y::ZZRingElem) where T <: Zmodn_mat
  ( y < 0 ) && error("Exponent must be positive")
  ( y > ZZRingElem(typemax(UInt))) &&
          error("Exponent must be smaller than ", ZZRingElem(typemax(UInt)))
  return x^(UInt(y))
end

################################################################################
#
#  Strong echelon form and Howell form
#
################################################################################

function strong_echelon_form!(a::T) where T <: Zmodn_mat
  ccall((:nmod_mat_strong_echelon_form, libflint), Nothing, (Ref{T}, ), a)
end

@doc raw"""
    strong_echelon_form(a::zzModMatrix)

Return the strong echeleon form of $a$. The matrix $a$ must have at least as
many rows as columns.
"""
function strong_echelon_form(a::zzModMatrix)
  (nrows(a) < ncols(a)) &&
              error("Matrix must have at least as many rows as columns")
  z = deepcopy(a)
  strong_echelon_form!(z)
  return z
end

function howell_form!(a::T) where T <: Zmodn_mat
  ccall((:nmod_mat_howell_form, libflint), Nothing, (Ref{T}, ), a)
end

@doc raw"""
    howell_form(a::zzModMatrix)

Return the Howell normal form of $a$. The matrix $a$ must have at least as
many rows as columns.
"""
function howell_form(a::zzModMatrix)
  (nrows(a) < ncols(a)) &&
              error("Matrix must have at least as many rows as columns")

  z = deepcopy(a)
  howell_form!(z)
  return z
end

################################################################################
#
#  Trace
#
################################################################################

function tr(a::T) where T <: Zmodn_mat
  !is_square(a) && error("Matrix must be a square matrix")
  r = ccall((:nmod_mat_trace, libflint), UInt, (Ref{T}, ), a)
  return base_ring(a)(r)
end

################################################################################
#
#  Determinant
#
################################################################################

function det(a::zzModMatrix)
  !is_square(a) && error("Matrix must be a square matrix")
  if is_prime(a.n)
     r = ccall((:nmod_mat_det, libflint), UInt, (Ref{zzModMatrix}, ), a)
     return base_ring(a)(r)
  else
     try
        return AbstractAlgebra.det_fflu(a)
     catch
        return AbstractAlgebra.det_df(a)
     end
  end
end

################################################################################
#
#  Rank
#
################################################################################

function rank(a::T) where T <: Zmodn_mat
  r = ccall((:nmod_mat_rank, libflint), Int, (Ref{T}, ), a)
  return r
end

################################################################################
#
#  Inverse
#
################################################################################

function inv(a::zzModMatrix)
  !is_square(a) && error("Matrix must be a square matrix")
  if is_prime(a.n)
     z = similar(a)
     r = ccall((:nmod_mat_inv, libflint), Int,
               (Ref{zzModMatrix}, Ref{zzModMatrix}), z, a)
     !Bool(r) && error("Matrix not invertible")
     return z
  else
     b = lift(a)
     c, d = pseudo_inv(b)
     R = base_ring(a)

     if !isone(gcd(d, modulus(R)))
        error("Matrix not invertible")
     end
     return change_base_ring(R, c) * inv(R(d))
  end
end

################################################################################
#
#  Linear solving
#
################################################################################

function solve(x::T, y::T) where T <: Zmodn_mat
  (base_ring(x) != base_ring(y)) && error("Matrices must have same base ring")
  !is_square(x)&& error("First argument not a square matrix in solve")
  (y.r != x.r) || y.c != 1 && ("Not a column vector in solve")
  z = similar(y)
  r = ccall((:nmod_mat_solve, libflint), Int,
          (Ref{T}, Ref{T}, Ref{T}), z, x, y)
  !Bool(r) && error("Singular matrix in solve")
  return z
end

function AbstractAlgebra.solve_triu(x::T, y::T) where T <: Zmodn_mat
   (base_ring(x) != base_ring(y)) && error("Matrices must have same base ring")
   is_upper_trangular(x) || error("Matrix must be upper triangular")
   z = similar(x, nrows(x), ncols(y))
   solve_triu!(z, x, y, 0)
   return z
end

#solves upper_triangular_part(B)A = C, 
#if unit == 1, then only the strictly upper triangular part is used
#and the diagonal is assumed to be 1
#
# useful in the context of solving/ lu decomposition: the lu
# is done inplace, so the lower part wil be "l", the upper "u",
# both are implicit only.
function solve_triu!(A::T, B::T, C::T, unit::Int = 0) where T <: Zmodn_mat
   ccall((:nmod_mat_solve_triu, Nemo.libflint), Cvoid, (Ref{T}, Ref{T}, Ref{T}, Cint), A, B, C, unit)
end

#solves lower_triangular_part(B)A = C, 
#if unit == 1, then only the strictly lower triangular part is used
#and the diagonal is assumed to be 1
function solve_tril!(A::T, B::T, C::T, unit::Int = 0) where T <: Zmodn_mat
   ccall((:nmod_mat_solve_tril, Nemo.libflint), Cvoid, (Ref{T}, Ref{T}, Ref{T}, Cint), A, B, C, unit)
end

################################################################################
#
#  LU decomposition
#
################################################################################

function lu!(P::Generic.Perm, x::T) where T <: Zmodn_mat
  P.d .-= 1

  rank = Int(ccall((:nmod_mat_lu, libflint), Cint, (Ptr{Int}, Ref{T}, Cint),
           P.d, x, 0))

  P.d .+= 1

  # flint does x == PLU instead of Px == LU (docs are wrong)
  inv!(P)

  return rank
end

function lu(x::T, P = SymmetricGroup(nrows(x))) where T <: Zmodn_mat
  m = nrows(x)
  n = ncols(x)
  P.n != m && error("Permutation does not match matrix")
  p = one(P)
  R = base_ring(x)
  U = deepcopy(x)

  L = similar(x, m, m)

  rank = lu!(p, U)

  for i = 1:m
    for j = 1:n
      if i > j
        L[i, j] = U[i, j]
        U[i, j] = R()
      elseif i == j
        L[i, j] = R(1)
      elseif j <= m
        L[i, j] = R()
      end
    end
  end
  return rank, p, L, U
end

#to support FAST lu!
function AbstractAlgebra.Strassen.apply!(A::fpMatrix, P::Perm{Int}; offset::Int = 0)
  n = length(P.d)
  t = zeros(Int, n-offset)
  for i=1:n-offset
    t[i] = unsafe_load(reinterpret(Ptr{Int}, A.rows), P.d[i] + offset)
  end
  for i=1:n-offset
    unsafe_store!(reinterpret(Ptr{Int}, A.rows), t[i], i + offset)
  end
end

################################################################################
#
#  Windowing
#
################################################################################

function Base.view(x::zzModMatrix, r1::Int, c1::Int, r2::Int, c2::Int)

   _checkrange_or_empty(nrows(x), r1, r2) ||
      Base.throw_boundserror(x, (r1:r2, c1:c2))

   _checkrange_or_empty(ncols(x), c1, c2) ||
      Base.throw_boundserror(x, (r1:r2, c1:c2))

   if (r1 > r2)
     r1 = 1
     r2 = 0
   end
   if (c1 > c2)
     c1 = 1
     c2 = 0
   end

  z = zzModMatrix()
  z.base_ring = x.base_ring
  z.view_parent = x
  ccall((:nmod_mat_window_init, libflint), Nothing,
          (Ref{zzModMatrix}, Ref{zzModMatrix}, Int, Int, Int, Int),
          z, x, r1 - 1, c1 - 1, r2, c2)
  finalizer(_nmod_mat_window_clear_fn, z)
  return z
end

function Base.view(x::T, r::AbstractUnitRange{Int}, c::AbstractUnitRange{Int}) where T <: Zmodn_mat
  return Base.view(x, first(r), first(c), last(r), last(c))
end

function _nmod_mat_window_clear_fn(a::zzModMatrix)
  ccall((:nmod_mat_window_clear, libflint), Nothing, (Ref{zzModMatrix}, ), a)
end

function sub(x::T, r1::Int, c1::Int, r2::Int, c2::Int) where T <: Zmodn_mat
  return deepcopy(Base.view(x, r1, c1, r2, c2))
end

function sub(x::T, r::AbstractUnitRange{Int}, c::AbstractUnitRange{Int}) where T <: Zmodn_mat
  return deepcopy(Base.view(x, r, c))
end

function getindex(x::T, r::AbstractUnitRange{Int}, c::AbstractUnitRange{Int}) where T <: Zmodn_mat
   sub(x, r, c)
end

################################################################################
#
#  Concatenation
#
################################################################################

function hcat(x::T, y::T) where T <: Zmodn_mat
  (base_ring(x) != base_ring(y)) && error("Matrices must have same base ring")
  (x.r != y.r) && error("Matrices must have same number of rows")
  z = similar(x, nrows(x), ncols(x) + ncols(y))
  ccall((:nmod_mat_concat_horizontal, libflint), Nothing,
          (Ref{T}, Ref{T}, Ref{T}), z, x, y)
  return z
end

function vcat(x::T, y::T) where T <: Zmodn_mat
  (base_ring(x) != base_ring(y)) && error("Matrices must have same base ring")
  (x.c != y.c) && error("Matrices must have same number of columns")
  z = similar(x, nrows(x) + nrows(y), ncols(x))
  ccall((:nmod_mat_concat_vertical, libflint), Nothing,
          (Ref{T}, Ref{T}, Ref{T}), z, x, y)
  return z
end

################################################################################
#
#  Conversion
#
################################################################################

function Array(b::zzModMatrix)
  a = Array{zzModRingElem}(undef, b.r, b.c)
  for i = 1:b.r
    for j = 1:b.c
      a[i,j] = b[i,j]
    end
  end
  return a
end

################################################################################
#
#  Lifting
#
################################################################################

@doc raw"""
    lift(a::T) where {T <: Zmodn_mat}

Return a lift of the matrix $a$ to a matrix over $\mathbb{Z}$, i.e. where the
entries of the returned matrix are those of $a$ lifted to $\mathbb{Z}$.
"""
function lift(a::T) where {T <: Zmodn_mat}
  z = ZZMatrix(nrows(a), ncols(a))
  ccall((:fmpz_mat_set_nmod_mat, libflint), Nothing,
          (Ref{ZZMatrix}, Ref{T}), z, a)
  return z
end

function lift!(z::ZZMatrix, a::T) where T <: Zmodn_mat
  ccall((:fmpz_mat_set_nmod_mat, libflint), Nothing,
          (Ref{ZZMatrix}, Ref{T}), z, a)
  return z
end

################################################################################
#
#  Characteristic polynomial
#
################################################################################

function charpoly(R::zzModPolyRing, a::zzModMatrix)
  m = deepcopy(a)
  p = R()
  ccall((:nmod_mat_charpoly, libflint), Nothing,
          (Ref{zzModPolyRingElem}, Ref{zzModMatrix}), p, m)
  return p
end

################################################################################
#
#  Minimal polynomial
#
################################################################################

function minpoly(R::zzModPolyRing, a::zzModMatrix)
  p = R()
  ccall((:nmod_mat_minpoly, libflint), Nothing,
          (Ref{zzModPolyRingElem}, Ref{zzModMatrix}), p, a)
  return p
end

###############################################################################
#
#   Promotion rules
#
###############################################################################

promote_rule(::Type{zzModMatrix}, ::Type{V}) where {V <: Integer} = zzModMatrix

promote_rule(::Type{zzModMatrix}, ::Type{zzModRingElem}) = zzModMatrix

promote_rule(::Type{zzModMatrix}, ::Type{ZZRingElem}) = zzModMatrix

################################################################################
#
#  Parent object overloading
#
################################################################################

function (a::zzModMatrixSpace)()
  z = zzModMatrix(nrows(a), ncols(a), modulus(base_ring(a)))
  z.base_ring = a.base_ring
  return z
end

function (a::zzModMatrixSpace)(b::Integer)
   M = a()
   for i = 1:nrows(a)
      for j = 1:ncols(a)
         if i != j
            M[i, j] = zero(base_ring(a))
         else
            M[i, j] = base_ring(a)(b)
         end
      end
   end
   return M
end

function (a::zzModMatrixSpace)(b::ZZRingElem)
   M = a()
   for i = 1:nrows(a)
      for j = 1:ncols(a)
         if i != j
            M[i, j] = zero(base_ring(a))
         else
            M[i, j] = base_ring(a)(b)
         end
      end
   end
   return M
end

function (a::zzModMatrixSpace)(b::zzModRingElem)
   parent(b) != base_ring(a) && error("Unable to coerce to matrix")
   M = a()
   for i = 1:nrows(a)
      for j = 1:ncols(a)
         if i != j
            M[i, j] = zero(base_ring(a))
         else
            M[i, j] = deepcopy(b)
         end
      end
   end
   return M
end

function (a::zzModMatrixSpace)(arr::AbstractMatrix{BigInt}, transpose::Bool = false)
  _check_dim(nrows(a), ncols(a), arr, transpose)
  z = zzModMatrix(nrows(a), ncols(a), modulus(base_ring(a)), arr, transpose)
  z.base_ring = a.base_ring
  return z
end

function (a::zzModMatrixSpace)(arr::AbstractVector{BigInt})
  _check_dim(nrows(a), ncols(a), arr)
  z = zzModMatrix(nrows(a), ncols(a), modulus(base_ring(a)), arr)
  z.base_ring = a.base_ring
  return z
end

function (a::zzModMatrixSpace)(arr::AbstractMatrix{ZZRingElem}, transpose::Bool = false)
  _check_dim(nrows(a), ncols(a), arr, transpose)
  z = zzModMatrix(nrows(a), ncols(a), modulus(base_ring(a)), arr, transpose)
  z.base_ring = a.base_ring
  return z
end

function (a::zzModMatrixSpace)(arr::AbstractVector{ZZRingElem})
  _check_dim(nrows(a), ncols(a), arr)
  z = zzModMatrix(nrows(a), ncols(a), modulus(base_ring(a)), arr)
  z.base_ring = a.base_ring
  return z
end

function (a::zzModMatrixSpace)(arr::AbstractMatrix{Int}, transpose::Bool = false)
  _check_dim(nrows(a), ncols(a), arr, transpose)
  z = zzModMatrix(nrows(a), ncols(a), modulus(base_ring(a)), arr, transpose)
  z.base_ring = a.base_ring
  return z
end

function (a::zzModMatrixSpace)(arr::AbstractVector{Int})
  _check_dim(nrows(a), ncols(a), arr)
  z = zzModMatrix(nrows(a), ncols(a), modulus(base_ring(a)), arr)
  z.base_ring = a.base_ring
  return z
end

function (a::zzModMatrixSpace)(arr::AbstractMatrix{zzModRingElem}, transpose::Bool = false)
  _check_dim(nrows(a), ncols(a), arr, transpose)
  (length(arr) > 0 && (base_ring(a) != parent(arr[1]))) && error("Elements must have same base ring")
  z = zzModMatrix(nrows(a), ncols(a), modulus(base_ring(a)), arr, transpose)
  z.base_ring = a.base_ring
  return z
end

function (a::zzModMatrixSpace)(arr::AbstractVector{zzModRingElem})
  _check_dim(nrows(a), ncols(a), arr)
  (length(arr) > 0 && (base_ring(a) != parent(arr[1]))) && error("Elements must have same base ring")
  z = zzModMatrix(nrows(a), ncols(a), modulus(base_ring(a)), arr)
  z.base_ring = a.base_ring
  return z
end

function (a::zzModMatrixSpace)(b::ZZMatrix)
  (ncols(a) != b.c || nrows(a) != b.r) && error("Dimensions do not fit")
  z = zzModMatrix(modulus(base_ring(a)), b)
  z.base_ring = a.base_ring
  return z
end

###############################################################################
#
#   Matrix constructor
#
###############################################################################

function matrix(R::zzModRing, arr::AbstractMatrix{<: Union{zzModRingElem, ZZRingElem, Integer}})
   z = zzModMatrix(size(arr, 1), size(arr, 2), R.n, arr)
   z.base_ring = R
   return z
end

function matrix(R::zzModRing, r::Int, c::Int, arr::AbstractVector{<: Union{zzModRingElem, ZZRingElem, Integer}})
   _check_dim(r, c, arr)
   z = zzModMatrix(r, c, R.n, arr)
   z.base_ring = R
   return z
end

###############################################################################
#
#  Zero matrix
#
###############################################################################

function zero_matrix(R::zzModRing, r::Int, c::Int)
   if r < 0 || c < 0
     error("dimensions must not be negative")
   end
   z = zzModMatrix(r, c, R.n)
   z.base_ring = R
   return z
end

###############################################################################
#
#  Identity matrix
#
###############################################################################

function identity_matrix(R::zzModRing, n::Int)
   z = zero_matrix(R, n, n)
   for i in 1:n
      z[i, i] = one(R)
   end
   z.base_ring = R
   return z
end

################################################################################
#
#  Matrix space constructor
#
################################################################################

function matrix_space(R::zzModRing, r::Int, c::Int; cached::Bool = true)
  # TODO/FIXME: `cached` is ignored and only exists for backwards compatibility
  zzModMatrixSpace(R, r, c)
end

