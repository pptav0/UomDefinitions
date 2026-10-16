# UomDefinitions

Type-safe units-of-measure definitions and conversions for oilfield engineering calculations, written in Julia. This package is the foundational layer of the Simulytics platform: it centralizes unit definitions and conversion rules so hydraulic and cementing calculations stay unambiguous across modules.

## Design

Every unit is a singleton type under an abstract family, and every quantity is a struct tagged with its unit at the type level:

```julia
abstract type PressureUnit <: Uom end
struct PSI <: PressureUnit end          # unit type
const psi = PSI()                       # ergonomic singleton

p = Pressure(100.0, psi)                # Pressure{PSI}
to_bar(p)                               # Pressure{BAR}: 6.8948 bar
```

Because the unit lives in the type parameter, conversions dispatch statically and mixing units by accident is a method error, not a silent bug. Conversion factors are named constants (e.g. `PSI_PER_BAR`, `L_PER_BBL`) exported alongside the conversion functions.

## Unit families

| Family | Units | Conversions |
|---|---|---|
| `Diameter` | in, mm, 64ths of an inch (choke sizes, `d64`) | `to_in`, `to_mm`, `to_d64` |
| `Length` | ft, m | `to_ft`, `to_m` |
| `Pressure` | psi, bar, Pa, MPa | `to_psi`, `to_bar`, `to_pa`, `to_mpa` |
| `Volume` | m³, bbl, L, scf, strokes | `to_m3`, `to_bbl`, `to_ltr` |
| `StrokeCapacity` | L/stk, bbl/stk | pairs with `Volume{STK}` |
| `PumpRate` | bpm, gpm, L/min | `to_bpm`, `to_gpm`, `to_lpm` |
| `Density` | ppg, kg/m³, SG | `to_ppg`, `to_kg_m3`, `to_sg` |
| `Temperature` | °F, °C, K | `to_degF`, `to_degC`, `to_kelvin`, `to_rankine` |
| `GasConc` / `GasRate` | scf/bbl, SCFM, SCMM | `to_scfm`, `to_scmm` |
| `LiquidConc` | ft³/sk, L/100kg (LHK), gal/sk (GPS), L/MT | `to_ft3sk`, `to_lhk`, `to_gps`, `to_lmt` |
| `Capacity` | bbl/ft, gal/ft, ft³/ft, m³/m, L/m (volume per unit length) | `to_bbl_ft`, `to_gal_ft`, `to_ft3_ft`, `to_m3_m`, `to_l_m` |
| `Area` | in², ft², m² | `to_in2`, `to_ft2`, `to_m2` |
| `Mass` | kg, lbm | `to_kg`, `to_lbm` |
| `Acceleration` | m/s², ft/s² | `to_m_s2`, `to_ft_s2` |
| `Force` | N, lbf | `to_n`, `to_lbf` |

`to_unit(q, unit)` converts any quantity (`Density`, `Pressure`, `PumpRate`, `Length`, `Diameter`, `Volume`, `Capacity`, `Area`, `Mass`, `Acceleration`, `Force`) to the unit given as a singleton, so a *unit set* can be applied generically (`annulus_capacity(…; out=l_m)` in SimuUtils).

## Gravity and force primitives

`GRAVITY = Acceleration(9.80665, m_s2)` is the single gravity definition. Force arises from two products only: `pressure_force(ΔP, A)` (psi·in² = lbf, Pa·m² = N) and `weight_of(ρ, V)` / `weight_of(m)` (lbm under standard gravity = lbf, kg·g = N).

### Decompositions

`Components{Q}(x, y, res)` is a generic 2D decomposition over any quantity: `x` and `y` are the two orthogonal parts and `res` is the magnitude of the vector being decomposed, so `hypot(x, y) ≈ res` always holds. The struct does not own a frame; each producing function states its own. (`Forces` is a backward-compatible alias.)

Gravity is always vertical. Inclination (`inc`, measured from vertical) changes the path and how a load is carried, never gravity itself:

| Function | Frame | `x` | `y` | `res` |
|---|---|---|---|---|
| `gravity_components(; unit)` | global | `0` | `g` (vertical) | `g` |
| `path_components(Δmd, inc)` | global | `Δmd·sin(inc)` horizontal offset | `Δmd·cos(inc)` = ΔTVD | `Δmd` |
| `load_components(F, inc)` | hole | `F·sin(inc)` side load on the wall | `F·cos(inc)` axial load on the hook | `F`, the vertical weight |

`path_components(…).y` is the vertical step that hydrostatic pressure integrates over. `path_components` accepts `0° ≤ inc ≤ 90°` because `Length` is non-negative. `force_components` is a deprecated alias of `load_components`.

`Diameter` and `Length` bridge into each other: `to_ft` / `to_m` accept a `Diameter` (e.g. a casing OD in inches becomes a `Length{FT}` for area calculations) and `to_in` / `to_mm` accept a `Length`.

## Conversion constants

Every factor is a named, exported constant, and each physical definition is written exactly once. Everything else is derived from it, so a change propagates to every conversion:

| Base definition | Derived from it |
|---|---|
| `M_PER_FT = 0.3048` | `FT_PER_M`, `M3_PER_FT3`, `FT3_PER_M3`, `L_PER_FT3`, `GAL_PER_FT3`, `SCF_PER_SCM`, `SCM_PER_SCF`, `M3_M_PER_FT3_FT`, `FT3_FT_PER_M3_M` |
| `MM_PER_IN = 25.4`, `IN_PER_FT = 12` | `IN_PER_MM`, `MM_PER_FT`, `D64_PER_IN` |
| `L_PER_BBL = 159`, `L_PER_GAL = 3.785411784`, `GAL_PER_BBL = 42` | `FT3_PER_BBL`, `M3_M_PER_BBL_FT`, `BBL_FT_PER_M3_M` |
| `KG_PER_LB = 0.45359237`, `LB_PER_SK = 94` | `LB_PER_KG`, `KG_PER_SK`, `KG_M3_PER_PPG`, `PPG_PER_SG` |
| `ZERO_C_IN_K = 273.15`, `ZERO_C_IN_F = 32`, `F_PER_C = 1.8` | all temperature offsets |
| `KG_PER_MT = 1000`, `KG_PER_HKG = 100`, `L_PER_M3 = 1000` | metric-ton / per-100-kg concentrations |

Constants of general use are also exported, e.g. `P_ATM` (atmospheric pressure, 14.7 psi).

> `L_PER_BBL` is deliberately the field-rounded 159 L rather than the exact 158.987 L. Change it in `src/pump_rates.jl` if you need the exact barrel; every barrel-based factor follows.

## Usage

```julia
using UomDefinitions

# tag values with their unit
rate  = PumpRate(8.0, bpm)
depth = Length(12_500.0, ft)

# convert between units — result keeps its unit tag
to_lpm(rate)          # 1272.0 L/min
to_m(depth)           # 3810.0 m

# numeric + unit-singleton convenience form
to_bar(2_500.0, psi)  # 172.4 bar

# diameters feed length-based geometry
to_ft(Diameter(9.625, inch))   # 0.8021 ft
to_in(Diameter(8, d64))        # 0.125 in (choke size)

# the bare number is always `.value`
to_m(depth).value              # 3810.0
```

Quantities are plain mutable structs with a single `value::Float64` field; there is no operator overloading, so arithmetic is done on `.value` and re-tagged explicitly.

## Extending

To add a unit family, follow the pattern in any existing file (`src/pressure.jl` is a good template):

1. Create `src/<family>.jl` defining the abstract unit type, singleton unit structs, the quantity struct, conversion constants, and `to_xxx` methods. Define new constants as plain `const NAME = value` (no type annotations) and derive them from existing base constants where possible; never repeat a literal that already has a name.
2. `include` the file and add the exports in `src/UomDefinitions.jl`.
3. Add `test/test_<family>.jl` and include it in `test/runtests.jl`.

## Installation & tests

The package is not registered; use it via a local path:

```julia
using Pkg
Pkg.develop(path="path/to/UomDefinitions")
```

Run the test suite from the package directory, with the project activated:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

The `--project=.` flag matters: without it `using UomDefinitions` resolves through the global environment and may load a different checkout of the package.

The package has no runtime dependencies beyond `ConstructionBase`, and every unit file has a matching `test/test_<family>.jl`.
