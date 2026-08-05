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
| `Diameter` | in, mm | `to_in`, `to_mm` |
| `Length` | ft, m | `to_ft`, `to_m` |
| `Pressure` | psi, bar, Pa | `to_psi`, `to_bar`, `to_pa` |
| `Volume` | m³, bbl, L, scf, strokes | `to_m3`, `to_bbl`, `to_ltr` |
| `StrokeCapacity` | L/stk, bbl/stk | pairs with `Volume{STK}` |
| `PumpRate` | bpm, gpm, L/min | `to_bpm`, `to_gpm`, `to_lpm` |
| `Density` | ppg, kg/m³, SG | `to_ppg`, `to_kg_m3`, `to_sg` |
| `Temperature` | °F, °C, K | `to_degF`, `to_degC`, `to_kelvin`, `to_rankine` |
| `GasConc` / `GasRate` | scf/bbl, SCFM, SCMM | `to_scfm`, `to_scmm` |
| `LiquidConc` | ft³/sk, L/100kg (LHK), gal/sk (GPS), L/MT | `to_ft3sk`, `to_lhk`, `to_gps`, `to_lmt` |

Constants of general use are also exported, e.g. `P_ATM` (atmospheric pressure, 14.7 psi).

## Usage

```julia
using UomDefinitions

# tag values with their unit
rate  = PumpRate(8.0, bpm)
depth = Length(12_500.0, ft)

# convert between units — result keeps its unit tag
to_lpm(rate)          # 1271.9 L/min
to_m(depth)           # 3810.0 m

# numeric + unit-singleton convenience form
to_bar(2_500.0, psi)  # 172.4 bar
```

## Extending

To add a unit family, follow the pattern in any existing file (`src/pressure.jl` is a good template):

1. Create `src/<family>.jl` defining the abstract unit type, singleton unit structs, the quantity struct, conversion constants, and `to_xxx` methods.
2. `include` the file and add the exports in `src/UomDefinitions.jl`.
3. Add `test/test_<family>.jl` and include it in `test/runtests.jl`.

## Installation & tests

The package is not registered; use it via a local path:

```julia
using Pkg
Pkg.develop(path="path/to/UomDefinitions")
```

Run the test suite from the package directory:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```
