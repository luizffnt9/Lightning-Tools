MODEL DE
  DATA v0                 -- start voltage [kV]
       cfo                -- critical flashover voltage [kV]
       kda                -- disruptive-effect exponent
  INPUT v_node_1          -- voltage at terminal 1 [V]
        v_node_2          -- voltage at terminal 2 [V]
  VAR e                   -- voltage magnitude across insulation [kV]
      overvoltage         -- max(e-v0, 0) [kV]
      de_rate             -- integrand converted to kV**kda * us/s
      de_accum            -- accumulated disruptive effect
      de_critical         -- critical disruptive effect
      flashover           -- switch command: 0=open, 1=close
  OUTPUT flashover
  INIT
    e                 := 0
    overvoltage       := 0
    de_rate           := 0
    integral(de_rate) := 0
    de_accum          := 0
    de_critical       := 1.1506*cfo**kda
    flashover         := 0
  ENDINIT
  EXEC
    e := abs(v_node_1-v_node_2)*1.0e-3
    IF flashover = 0 THEN
      overvoltage := max(e-v0, 0)
      de_rate     := 1.0e6*overvoltage**kda
      de_accum    := integral(de_rate)
      IF de_accum >= de_critical THEN
        flashover := 1
      ENDIF
    ELSE
      de_rate := 0
    ENDIF
  ENDEXEC
ENDMODEL
