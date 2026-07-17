# Insulator Models

## Disruptive Effect (DE) Model

The accumulated disruptive effect is calculated as:

$$
DE(t)=\int_{t_0}^{t}\left[e(\tau)-V_0\right]^{k_{da}}\,d\tau,
\qquad e(\tau)>V_0
$$

When $e(\tau)\leq V_0$, the integrand is set to zero. Flashover occurs when
$DE(t)\geq DE_c$, where:

$$
DE_c=1.1506\,(CFO)^{k_{da}}.
$$

### Inputs and Units

| Input | Description | Unit supplied to MODELS |
|---|---|---|
| `v_node_1` | Instantaneous voltage at the first node | V |
| `v_node_2` | Instantaneous voltage at the second node | V |
| `V0` | Voltage threshold at which DE integration starts | kV |
| `CFO` | Critical Flashover Voltage | kV |
| `kda` | DE model exponent | dimensionless |

The model calculates $e(t)=|v_{node\_1}-v_{node\_2}|$ and internally converts
the voltage from V to kV. Since ATP uses seconds as its time unit, time is also
converted internally to microseconds. Therefore, $DE$ and $DE_c$ are expressed
in $\mathrm{kV}^{k_{da}}\,\mu\mathrm{s}$.

The `flashover` output is dimensionless. Its value is 0 before breakdown and 1
after breakdown. The output remains latched at 1 and can be connected to a TACS
switch closing command.
