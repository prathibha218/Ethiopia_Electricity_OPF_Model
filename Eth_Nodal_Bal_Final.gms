*$title "Optimal Power Flow Model for Ethiopia"
*_______________________________________________________________________________
* Filename: Eth_Nodal_Bal_Final.gms
*
* Description: Optimal Power Flow Model for Ethiopia that determines cost-optimal generation operations
* and grid expansion by considering transmission capacity constraints, tranmission expansion constraints,
* and nodal balance constaints
*
*Input data file:
*ETHREGnodalFinal.xlsx
*_______________________________________________________________________________
*==== SECTION: DATA DECLARATION
sets
    t              "time (hour)"
    bus            "set of all buses in the system"
    s              /1, 2 / "number of seasons"
;

alias(bus,i,j);

parameters
  Pd(bus,t,s)     "bus real power demand (MW)"
  Pg(i,t,s)       "real power produced by generators at bus (MW)"

  d(s)            "number of days in season 's' "
  Pmax(i,s)       "maximum real power generation output at bus (MW)"
  cap(i)          "capacity of generation at bus (MW)"
  Pmin(i)         "minimum real power generation output at bus (MW)"
  cap_fact(i,s)   "capacity factor of generator (MWh/MWh)"

  totalgen(t,s)     "total generation at each hour (MW)"
  totaldem(t,s)     "total demand at each hour (MW)"

  rate(i,j)
  branchstatus(i,j)
  trans(i,j)        "lengths of transmission lines (mi)"
  bs(i,j)           "another line status variable: '0' indicates not online '1' indicates online"
  r                 /0.1 / "discount rate for expansion cost"
  N                 /20/   "years need to recover investment"
  
;
*==== SECTION: DATA INPUT
$CALL GDXXRW I=ETHREGnodal2.xlsx O=ETHREGnodal2.gdx trace=3 INDEX=Index!A1
$GDXIN ETHREGnodal2.gdx
$LOAD bus, t, branchstatus, bs
$LOAD Pmax, Pmin, Pd, cap, d
$LOAD rate, loss
$LOAD trans
$GDXIN

*===== SECTION: VARIABLE DEFINITION
free variables
    V_P(i,t,s)          "real power generation at bus (MW)"
;

positive variable
    V_LineP(i,j,t,s)    "power flow on line conneting node 'i' to node 'j' (MW)"
    exp(i,j)            "total expansion on line connecting node 'i' to node 'j' (MW)"
;
free variable
    V_objcost           "total cost of objective function ($)"
;
*===== SECTION: EQUATION DEFINITION
equations
    c_node(i,t,s)    "nodal balance equation"
    c_obj            "objective function"
    Linemax(i,j,t,s) "transmission capacity constraint"
    exp_tot          "transmission capacity expansion constraint"

;
*===== SECTION: EQUATIONS Part 1: Objective Function
*Objective function
c_obj..
    V_objcost =e=
     sum((i,t,s),d(s)*3.25*V_P(i,t,s))+ sum(i, 45.53*1000*cap(i))
     + ((r*(1+r)**N)/(((1+r)**N)-1))*sum((i,j)$branchstatus(i,j), 1000*trans(i,j)*exp(i,j))

*Here 3.25 $/MWh is the variable cost, 45.53 $1000/MW is the fixed cost, and 1000 $/MW-mi is the expansion cost 
;

*===== SECTION: EQUATIONS Part 2: Constraints
*Nodal balance equation
c_node(i,t,s)..
V_P(i,t,s) =e= - sum(j$branchstatus(j,i), (1-loss(i,j))*V_LineP(j,i,t,s)) + sum(j$branchstatus(i,j), V_LineP(i,j,t,s))
+ Pd(i,t,s)
;

*Tranmission Capacity Constraint
Linemax(i,j,t,s)$branchstatus(i,j)..
V_LineP(i,j,t,s) =l=  rate(i,j) + exp(i,j)
;

*Tranmission Expansion Capacity Constraint
exp_tot..
sum((i,j), exp(i,j)*trans(i,j))  =l= 0.1*sum((i,j), rate(i,j)*trans(i,j))
*0.1 indicates that the new expansion has an upper threshold of 10% of the present MW-mi of transmission lines
;

*===== SECTION: VARIABLE BOUNDS
* Generator power generation limits - Load Flow Analysis
V_P.lo(i,t,s) = Pmin(i);
V_P.up(i,t,s) = Pmax(i,s);


*===== SECTION: MODEL DEFINITION
model m_nodal /c_node, c_obj, Linemax, exp_tot/;

solve m_nodal min V_objcost using LP;

*==== SECTION: SOLUTTION ANALYSIS

Pg(i,t,s) = V_P.l(i,t,s);
cap_fact(i,s) = sum(t, Pg(i,t,s))/(Pmax(i,s)*24);

*24 is calculating over 24 hours

Display Pg, V_lineP.l, V_objcost.l, cap_fact;
