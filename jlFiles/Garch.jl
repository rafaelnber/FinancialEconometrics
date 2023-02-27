#------------------------------------------------------------------------------
function egarch11LL(par,yx)

  (y,x) = (yx[:,1],yx[:,2:end])            #split up data matrix

  (T,k) = (size(x,1),size(x,2))

  #lnσ²(t) = ω + α*abs(u(t-1)/s[t-1]) + β*lnσ²(t-1) + γ*u(t-1)/s[t-1]
  b         = par[1:k]                        #mean equation, y = x'*b
  (ω,α,β,γ) = par[k+1:k+4]
  yhat = x*b
  u    = y - yhat
  σ²_0 = var(u)

  lnσ²    = zeros(typeof(α),T)
  lnσ²[1] = log(σ²_0)
  for t = 2:T
    σₜ₋₁     = sqrt(exp(lnσ²[t-1]))      #lagged std
    lnσ²[t] = ω + α*abs(u[t-1])/σₜ₋₁ + β*lnσ²[t-1] + γ*u[t-1]/σₜ₋₁
  end
  σ² = exp.(lnσ²)

  LL_t    = -(1/2)*log(2*π) .- (1/2)*log.(σ²) - (1/2)*(u.^2)./σ²
  LL_t[1] = 0

  #LL = sum(LL_t)

  return LL_t,σ²,yhat,u

end
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------

"""
    DccLL(par,data)

# Input
- `par::Vector`:  transformed parameters (a,b), will be transformed into (α,β) below
- `data::Vector`: of arrays: v = data[1], σ² = data[2], Qbar = data[3]

"""
function DccLL(par,data)

  #(α,β) = par
  (α,β) = DccParTrans(par)             #restrict

  (v,σ²,Qbar) = (data[1],data[2],data[3])    #unpack data

  (T,n) = (size(v,1),size(v,2))

  u = v .* sqrt.(σ²)

  Σ = fill(NaN,(n,n,T))
  Q_t   = copy(Qbar)                    #starting guess
  LL_t  = zeros(T)
  for t = 2:T
    Q_t      = (1-α-β)*Qbar + α*v[t-1,:]*v[t-1,:]' + β*Q_t
    q_t      = diag(Q_t)
    R_t      = Q_t./sqrt.(q_t*q_t')
    d_t      = σ²[t,:]
    Σ_t      = R_t.*sqrt.(d_t*d_t')
    LL_t[t]  = -n*log(2*π) - logdet(Σ_t) - u[t,:]'*inv(Σ_t)*u[t,:]
    Σ[:,:,t] = Σ_t
  end

  LL_t = 0.5*LL_t
  #LL = sum(LL_t)

  return LL_t, Σ

end
#------------------------------------------------------------------------------

function DccParTrans(par)
    (a,b) = par
    α      = exp(a)/(1+exp(a)+exp(b))
    β      = exp(b)/(1+exp(a)+exp(b))
  return α,β
end
#------------------------------------------------------------------------------
