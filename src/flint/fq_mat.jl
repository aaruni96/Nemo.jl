################################################################################
#
#  fq_mat.jl: flint fq_mat types in julia
#
################################################################################

################################################################################
#
#  Data type and parent object methods
#
################################################################################

parent_type(::Type{FqPolyRepMatrix}) = FqPolyRepMatrixSpace

elem_type(::Type{FqPolyRepMatrixSpace}) = FqPolyRepMatrix

dense_matrix_type(::Type{FqPolyRepFieldElem}) = FqPolyRepMatrix

function check_parent(x::FqPolyRepMatrix, y::FqPolyRepMatrix, throw::Bool = true)
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

similar(::FqPolyRepMatrix, R::FqPolyRepField, r::Int, c::Int) = FqPolyRepMatrix(r, c, R)
zero(m::FqPolyRepMatrix, R::FqPolyRepField, r::Int, c::Int) = FqPolyRepMatrix(r, c, R)

################################################################################
#
#  Manipulation
#
################################################################################

@inline function getindex(a::FqPolyRepMatrix, i::Int, j::Int)
   @boundscheck Generic._checkbounds(a, i, j)
   GC.@preserve a begin
      el = ccall((:fq_mat_entry, libflint), Ptr{FqPolyRepFieldElem},
                 (Ref{FqPolyRepMatrix}, Int, Int), a, i - 1 , j - 1)
      z = base_ring(a)()
      ccall((:fq_set, libflint), Nothing, (Ref{FqPolyRepFieldElem}, Ptr{FqPolyRepFieldElem}), z, el)
   end
   return z
end

@inline function setindex!(a::FqPolyRepMatrix, u::FqPolyRepFieldElem, i::Int, j::Int)
   @boundscheck Generic._checkbounds(a, i, j)
   ccall((:fq_mat_entry_set, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Int, Int, Ref{FqPolyRepFieldElem}, Ref{FqPolyRepField}),
         a, i - 1, j - 1, u, base_ring(a))
end

@inline function setindex!(a::FqPolyRepMatrix, u::ZZRingElem, i::Int, j::Int)
   @boundscheck Generic._checkbounds(a, i, j)
   GC.@preserve a begin
      el = ccall((:fq_mat_entry, libflint), Ptr{FqPolyRepFieldElem},
                 (Ref{FqPolyRepMatrix}, Int, Int), a, i - 1, j - 1)
      ccall((:fq_set_fmpz, libflint), Nothing,
            (Ptr{FqPolyRepFieldElem}, Ref{ZZRingElem}, Ref{FqPolyRepField}), el, u, base_ring(a))
   end
end

setindex!(a::FqPolyRepMatrix, u::Integer, i::Int, j::Int) =
        setindex!(a, base_ring(a)(u), i, j)

function deepcopy_internal(a::FqPolyRepMatrix, dict::IdDict)
  z = FqPolyRepMatrix(nrows(a), ncols(a), base_ring(a))
  ccall((:fq_mat_set, libflint), Nothing,
        (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), z, a, base_ring(a))
  return z
end

nrows(a::FqPolyRepMatrix) = a.r

ncols(a::FqPolyRepMatrix) = a.c

nrows(a::FqPolyRepMatrixSpace) = a.nrows

ncols(a::FqPolyRepMatrixSpace) = a.ncols

parent(a::FqPolyRepMatrix) = matrix_space(base_ring(a), nrows(a), ncols(a))

base_ring(a::FqPolyRepMatrixSpace) = a.base_ring

base_ring(a::FqPolyRepMatrix) = a.base_ring

zero(a::FqPolyRepMatrixSpace) = a()

function one(a::FqPolyRepMatrixSpace)
  (nrows(a) != ncols(a)) && error("Matrices must be square")
  return a(one(base_ring(a)))
end

function iszero(a::FqPolyRepMatrix)
   r = ccall((:fq_mat_is_zero, libflint), Cint,
             (Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), a, base_ring(a))
  return Bool(r)
end

################################################################################
#
#  Comparison
#
################################################################################

function ==(a::FqPolyRepMatrix, b::FqPolyRepMatrix)
   if !(a.base_ring == b.base_ring)
      return false
   end
   r = ccall((:fq_mat_equal, libflint), Cint,
             (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), a, b, base_ring(a))
   return Bool(r)
end

isequal(a::FqPolyRepMatrix, b::FqPolyRepMatrix) = ==(a, b)

################################################################################
#
#  Transpose
#
################################################################################

function transpose(a::FqPolyRepMatrix)
   z = FqPolyRepMatrix(ncols(a), nrows(a), base_ring(a))
   for i in 1:nrows(a)
      for j in 1:ncols(a)
         z[j, i] = a[i, j]
      end
   end
   return z
end

# There is no transpose for FqPolyRepMatrix
#function transpose(a::FqPolyRepMatrix)
#  z = FqPolyRepMatrixSpace(base_ring(a), ncols(a), nrows(a))()
#  ccall((:fq_mat_transpose, libflint), Nothing,
#        (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), z, a, base_ring(a))
#  return z
#end
#
#function transpose!(a::FqPolyRepMatrix)
#  !is_square(a) && error("Matrix must be a square matrix")
#  ccall((:fq_mat_transpose, libflint), Nothing,
#        (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), a, a, base_ring(a))
#end

###############################################################################
#
#   Row and column swapping
#
###############################################################################

function swap_rows!(x::FqPolyRepMatrix, i::Int, j::Int)
  ccall((:fq_mat_swap_rows, libflint), Nothing,
        (Ref{FqPolyRepMatrix}, Ptr{Nothing}, Int, Int, Ref{FqPolyRepField}),
        x, C_NULL, i - 1, j - 1, base_ring(x))
  return x
end

function swap_rows(x::FqPolyRepMatrix, i::Int, j::Int)
   (1 <= i <= nrows(x) && 1 <= j <= nrows(x)) || throw(BoundsError())
   y = deepcopy(x)
   return swap_rows!(y, i, j)
end

function swap_cols!(x::FqPolyRepMatrix, i::Int, j::Int)
  ccall((:fq_mat_swap_cols, libflint), Nothing,
        (Ref{FqPolyRepMatrix}, Ptr{Nothing}, Int, Int, Ref{FqPolyRepField}),
        x, C_NULL, i - 1, j - 1, base_ring(x))
  return x
end

function swap_cols(x::FqPolyRepMatrix, i::Int, j::Int)
   (1 <= i <= ncols(x) && 1 <= j <= ncols(x)) || throw(BoundsError())
   y = deepcopy(x)
   return swap_cols!(y, i, j)
end

function reverse_rows!(x::FqPolyRepMatrix)
   ccall((:fq_mat_invert_rows, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ptr{Nothing}, Ref{FqPolyRepField}), x, C_NULL, base_ring(x))
   return x
end

reverse_rows(x::FqPolyRepMatrix) = reverse_rows!(deepcopy(x))

function reverse_cols!(x::FqPolyRepMatrix)
   ccall((:fq_mat_invert_cols, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ptr{Nothing}, Ref{FqPolyRepField}), x, C_NULL, base_ring(x))
   return x
end

reverse_cols(x::FqPolyRepMatrix) = reverse_cols!(deepcopy(x))

################################################################################
#
#  Unary operators
#
################################################################################

function -(x::FqPolyRepMatrix)
   z = similar(x)
   ccall((:fq_mat_neg, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), z, x, base_ring(x))
   return z
end

################################################################################
#
#  Binary operators
#
################################################################################

function +(x::FqPolyRepMatrix, y::FqPolyRepMatrix)
   check_parent(x,y)
   z = similar(x)
   ccall((:fq_mat_add, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}),
         z, x, y, base_ring(x))
   return z
end

function -(x::FqPolyRepMatrix, y::FqPolyRepMatrix)
   check_parent(x,y)
   z = similar(x)
   ccall((:fq_mat_sub, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}),
         z, x, y, base_ring(x))

   return z
end

function *(x::FqPolyRepMatrix, y::FqPolyRepMatrix)
   (base_ring(x) != base_ring(y)) && error("Base ring must be equal")
   (ncols(x) != nrows(y)) && error("Dimensions are wrong")
   z = similar(x, nrows(x), ncols(y))
   ccall((:fq_mat_mul, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), z, x, y, base_ring(x))
   return z
end


################################################################################
#
#  Unsafe operations
#
################################################################################

function mul!(a::FqPolyRepMatrix, b::FqPolyRepMatrix, c::FqPolyRepMatrix)
   ccall((:fq_mat_mul, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}),
         a, b, c, base_ring(a))
  return a
end

function add!(a::FqPolyRepMatrix, b::FqPolyRepMatrix, c::FqPolyRepMatrix)
   ccall((:fq_mat_add, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}),
         a, b, c, base_ring(a))
  return a
end

function zero!(a::FqPolyRepMatrix)
   ccall((:fq_mat_zero, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), a, base_ring(a))
   return a
end

function mul!(z::Vector{FqPolyRepFieldElem}, a::FqPolyRepMatrix, b::Vector{FqPolyRepFieldElem})
   ccall((:fq_mat_mul_vec_ptr, libflint), Nothing,
         (Ptr{Ref{FqPolyRepFieldElem}}, Ref{FqPolyRepMatrix}, Ptr{Ref{FqPolyRepFieldElem}}, Int, Ref{FqPolyRepField}),
         z, a, b, length(b), base_ring(a))
   return z
end

function mul!(z::Vector{FqPolyRepFieldElem}, a::Vector{FqPolyRepFieldElem}, b::FqPolyRepMatrix)
   ccall((:fq_mat_vec_mul_ptr, libflint), Nothing,
         (Ptr{Ref{FqPolyRepFieldElem}}, Ptr{Ref{FqPolyRepFieldElem}}, Int, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}),
         z, a, length(a), b, base_ring(b))
   return z
end

################################################################################
#
#  Ad hoc binary operators
#
################################################################################

function *(x::FqPolyRepMatrix, y::FqPolyRepFieldElem)
   z = similar(x)
   for i in 1:nrows(x)
      for j in 1:ncols(x)
         z[i, j] = y * x[i, j]
      end
   end
   return z
end

*(x::FqPolyRepFieldElem, y::FqPolyRepMatrix) = y * x

function *(x::FqPolyRepMatrix, y::ZZRingElem)
   return base_ring(x)(y) * x
end

*(x::ZZRingElem, y::FqPolyRepMatrix) = y * x

function *(x::FqPolyRepMatrix, y::Integer)
   return x * base_ring(x)(y)
end

*(x::Integer, y::FqPolyRepMatrix) = y * x

################################################################################
#
#  Powering
#
################################################################################

# Fall back to generic one

################################################################################
#
#  Row echelon form
#
################################################################################

function rref(a::FqPolyRepMatrix)
   z = deepcopy(a)
   r = ccall((:fq_mat_rref, libflint), Int,
             (Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), z, base_ring(a))
   return r, z
end

function rref!(a::FqPolyRepMatrix)
   r = ccall((:fq_mat_rref, libflint), Int,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), a, base_ring(a))
   return r
end

#################################################################################
#
#  Trace
#
#################################################################################

function tr(a::FqPolyRepMatrix)
   !is_square(a) && error("Non-square matrix")
   n = nrows(a)
   t = zero(base_ring(a))
   for i in 1:nrows(a)
      add!(t, t, a[i, i])
   end
   return t
end

################################################################################
#
#  Determinant
#
################################################################################

function det(a::FqPolyRepMatrix)
   !is_square(a) && error("Non-square matrix")
   n = nrows(a)
   R = base_ring(a)
   if n == 0
      return zero(R)
   end
   r, p, l, u = lu(a)
   if r < n
      return zero(R)
   else
      d = one(R)
      for i in 1:nrows(u)
         mul!(d, d, u[i, i])
      end
      return (parity(p) == 0 ? d : -d)
   end
end

################################################################################
#
#  Rank
#
################################################################################

function rank(a::FqPolyRepMatrix)
   n = nrows(a)
   if n == 0
      return 0
   end
   r, _, _, _ = lu(a)
   return r
end

################################################################################
#
#  Inverse
#
################################################################################

function inv(a::FqPolyRepMatrix)
   !is_square(a) && error("Matrix must be a square matrix")
   z = similar(a)
   r = ccall((:fq_mat_inv, libflint), Int,
             (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), z, a, base_ring(a))
   !Bool(r) && error("Matrix not invertible")
   return z
end

################################################################################
#
#  Linear solving
#
################################################################################

function solve(x::FqPolyRepMatrix, y::FqPolyRepMatrix)
   (base_ring(x) != base_ring(y)) && error("Matrices must have same base ring")
   !is_square(x)&& error("First argument not a square matrix in solve")
   (nrows(y) != nrows(x)) || ncols(y) != 1 && ("Not a column vector in solve")
   z = similar(y)
   r = ccall((:fq_mat_solve, libflint), Int,
             (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}),
             z, x, y, base_ring(x))
   !Bool(r) && error("Singular matrix in solve")
   return z
end

function can_solve_with_solution(a::FqPolyRepMatrix, b::FqPolyRepMatrix; side::Symbol = :right)
   (base_ring(a) != base_ring(b)) && error("Matrices must have same base ring")
   if side == :left
      (ncols(a) != ncols(b)) && error("Matrices must have same number of columns")
      (f, x) = can_solve_with_solution(transpose(a), transpose(b); side=:right)
      return (f, transpose(x))
   elseif side == :right
      (nrows(a) != nrows(b)) && error("Matrices must have same number of rows")
      x = similar(a, ncols(a), ncols(b))
      r = ccall((:fq_mat_can_solve, libflint), Cint,
                (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix},
                 Ref{FqPolyRepField}), x, a, b, base_ring(a))
      return Bool(r), x
   else
      error("Unsupported argument :$side for side: Must be :left or :right.")
   end
end

function can_solve(a::FqPolyRepMatrix, b::FqPolyRepMatrix; side::Symbol = :right)
   fl, _ = can_solve_with_solution(a, b, side = side)
   return fl
end

################################################################################
#
#  LU decomposition
#
################################################################################

function lu!(P::Generic.Perm, x::FqPolyRepMatrix)
   P.d .-= 1

   rank = Int(ccall((:fq_mat_lu, libflint), Cint,
                (Ptr{Int}, Ref{FqPolyRepMatrix}, Cint, Ref{FqPolyRepField}),
                P.d, x, 0, base_ring(x)))

  P.d .+= 1

  # flint does x == PLU instead of Px == LU (docs are wrong)
  inv!(P)

  return rank
end

function lu(x::FqPolyRepMatrix, P = SymmetricGroup(nrows(x)))
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
            L[i, j] = one(R)
         elseif j <= m
            L[i, j] = R()
         end
      end
   end
   return rank, p, L, U
end

################################################################################
#
#  Windowing
#
################################################################################

function Base.view(x::FqPolyRepMatrix, r1::Int, c1::Int, r2::Int, c2::Int)

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

   z = FqPolyRepMatrix()
   z.base_ring = x.base_ring
   z.view_parent = x
   ccall((:fq_mat_window_init, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Int, Int, Int, Int, Ref{FqPolyRepField}),
         z, x, r1 - 1, c1 - 1, r2, c2, base_ring(x))
   finalizer(_fq_mat_window_clear_fn, z)
   return z
end

function Base.view(x::FqPolyRepMatrix, r::AbstractUnitRange{Int}, c::AbstractUnitRange{Int})
   return Base.view(x, first(r), first(c), last(r), last(c))
end

function _fq_mat_window_clear_fn(a::FqPolyRepMatrix)
   ccall((:fq_mat_window_clear, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), a, base_ring(a))
end

function sub(x::FqPolyRepMatrix, r1::Int, c1::Int, r2::Int, c2::Int)
  return deepcopy(Base.view(x, r1, c1, r2, c2))
end

function sub(x::FqPolyRepMatrix, r::AbstractUnitRange{Int}, c::AbstractUnitRange{Int})
  return deepcopy(Base.view(x, r, c))
end

getindex(x::FqPolyRepMatrix, r::AbstractUnitRange{Int}, c::AbstractUnitRange{Int}) = sub(x, r, c)

################################################################################
#
#  Concatenation
#
################################################################################

function hcat(x::FqPolyRepMatrix, y::FqPolyRepMatrix)
   (base_ring(x) != base_ring(y)) && error("Matrices must have same base ring")
   (x.r != y.r) && error("Matrices must have same number of rows")
   z = similar(x, nrows(x), ncols(x) + ncols(y))
   ccall((:fq_mat_concat_horizontal, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}),
         z, x, y, base_ring(x))
   return z
end

function vcat(x::FqPolyRepMatrix, y::FqPolyRepMatrix)
   (base_ring(x) != base_ring(y)) && error("Matrices must have same base ring")
   (x.c != y.c) && error("Matrices must have same number of columns")
   z = similar(x, nrows(x) + nrows(y), ncols(x))
   ccall((:fq_mat_concat_vertical, libflint), Nothing,
         (Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}),
         z, x, y, base_ring(x))
   return z
end

################################################################################
#
#  Conversion
#
################################################################################

function Array(b::FqPolyRepMatrix)
  a = Array{FqPolyRepFieldElem}(undef, b.r, b.c)
  for i = 1:nrows(b)
    for j = 1:ncols(b)
      a[i, j] = b[i, j]
    end
  end
  return a
end

################################################################################
#
#  Characteristic polynomial
#
################################################################################

function charpoly(R::FqPolyRepPolyRing, a::FqPolyRepMatrix)
  !is_square(a) && error("Matrix must be square")
  base_ring(R) != base_ring(a) && error("Must have common base ring")
  p = R()
  ccall((:fq_mat_charpoly, libflint), Nothing,
          (Ref{FqPolyRepPolyRingElem}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), p, a, base_ring(a))
  return p
end

function charpoly_danivlesky!(R::FqPolyRepPolyRing, a::FqPolyRepMatrix)
  !is_square(a) && error("Matrix must be square")
  base_ring(R) != base_ring(a) && error("Must have common base ring")
  p = R()
  ccall((:fq_mat_charpoly_danilevsky, libflint), Nothing,
          (Ref{FqPolyRepPolyRingElem}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), p, a, base_ring(a))
  return p
end


################################################################################
#
#  Minimal polynomial
#
################################################################################

function minpoly(R::FqPolyRepPolyRing, a::FqPolyRepMatrix)
  !is_square(a) && error("Matrix must be square")
  base_ring(R) != base_ring(a) && error("Must have common base ring")
  m = deepcopy(a)
  p = R()
  ccall((:fq_mat_minpoly, libflint), Nothing,
          (Ref{FqPolyRepPolyRingElem}, Ref{FqPolyRepMatrix}, Ref{FqPolyRepField}), p, m, base_ring(a))
  return p
end

###############################################################################
#
#   Promotion rules
#
###############################################################################

promote_rule(::Type{FqPolyRepMatrix}, ::Type{V}) where {V <: Integer} = FqPolyRepMatrix

promote_rule(::Type{FqPolyRepMatrix}, ::Type{FqPolyRepFieldElem}) = FqPolyRepMatrix

promote_rule(::Type{FqPolyRepMatrix}, ::Type{ZZRingElem}) = FqPolyRepMatrix

################################################################################
#
#  Parent object overloading
#
################################################################################

function (a::FqPolyRepMatrixSpace)()
  z = FqPolyRepMatrix(nrows(a), ncols(a), base_ring(a))
  return z
end

function (a::FqPolyRepMatrixSpace)(b::Integer)
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

function (a::FqPolyRepMatrixSpace)(b::ZZRingElem)
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

function (a::FqPolyRepMatrixSpace)(b::FqPolyRepFieldElem)
   parent(b) != base_ring(a) && error("Unable to coerce to matrix")
   return FqPolyRepMatrix(nrows(a), ncols(a), b)
end

function (a::FqPolyRepMatrixSpace)(arr::AbstractMatrix{T}) where {T <: Integer}
  _check_dim(nrows(a), ncols(a), arr)
  return FqPolyRepMatrix(nrows(a), ncols(a), arr, base_ring(a))
end

function (a::FqPolyRepMatrixSpace)(arr::AbstractVector{T}) where {T <: Integer}
  _check_dim(nrows(a), ncols(a), arr)
  return FqPolyRepMatrix(nrows(a), ncols(a), arr, base_ring(a))
end

function (a::FqPolyRepMatrixSpace)(arr::AbstractMatrix{ZZRingElem})
  _check_dim(nrows(a), ncols(a), arr)
  return FqPolyRepMatrix(nrows(a), ncols(a), arr, base_ring(a))
end

function (a::FqPolyRepMatrixSpace)(arr::AbstractVector{ZZRingElem})
  _check_dim(nrows(a), ncols(a), arr)
  return FqPolyRepMatrix(nrows(a), ncols(a), arr, base_ring(a))
end

function (a::FqPolyRepMatrixSpace)(arr::AbstractMatrix{FqPolyRepFieldElem})
  _check_dim(nrows(a), ncols(a), arr)
  (length(arr) > 0 && (base_ring(a) != parent(arr[1]))) && error("Elements must have same base ring")
  return FqPolyRepMatrix(nrows(a), ncols(a), arr, base_ring(a))
end

function (a::FqPolyRepMatrixSpace)(arr::AbstractVector{FqPolyRepFieldElem})
  _check_dim(nrows(a), ncols(a), arr)
  (length(arr) > 0 && (base_ring(a) != parent(arr[1]))) && error("Elements must have same base ring")
  return FqPolyRepMatrix(nrows(a), ncols(a), arr, base_ring(a))
end

function (a::FqPolyRepMatrixSpace)(b::ZZMatrix)
  (ncols(a) != b.c || nrows(a) != b.r) && error("Dimensions do not fit")
  return FqPolyRepMatrix(b, base_ring(a))
end

###############################################################################
#
#   Matrix constructor
#
###############################################################################

function matrix(R::FqPolyRepField, arr::AbstractMatrix{<: Union{FqPolyRepFieldElem, ZZRingElem, Integer}})
   z = FqPolyRepMatrix(size(arr, 1), size(arr, 2), arr, R)
   return z
end

function matrix(R::FqPolyRepField, r::Int, c::Int, arr::AbstractVector{<: Union{FqPolyRepFieldElem, ZZRingElem, Integer}})
   _check_dim(r, c, arr)
   z = FqPolyRepMatrix(r, c, arr, R)
   return z
end

###############################################################################
#
#  Zero matrix
#
###############################################################################

function zero_matrix(R::FqPolyRepField, r::Int, c::Int)
   if r < 0 || c < 0
     error("dimensions must not be negative")
   end
   z = FqPolyRepMatrix(r, c, R)
   return z
end

###############################################################################
#
#  Identity matrix
#
###############################################################################

function identity_matrix(R::FqPolyRepField, n::Int)
   z = zero_matrix(R, n, n)
   for i in 1:n
      z[i, i] = one(R)
   end
   return z
end

################################################################################
#
#  Matrix space constructor
#
################################################################################

function matrix_space(R::FqPolyRepField, r::Int, c::Int; cached::Bool = true)
  # TODO/FIXME: `cached` is ignored and only exists for backwards compatibility
  FqPolyRepMatrixSpace(R, r, c)
end
