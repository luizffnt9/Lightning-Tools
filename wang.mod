MODEL wang
  DATA d       -- Comprimento total da cadeia [m]
       k1      -- Parametro do streamer [kV/m]
       k2      -- Parametro do streamer [kV]
       k0      -- Parametro do lider [m^2/(kV*ms)]
       e0      -- Campo limiar do lider [kV/m]
       nlead   -- 1 para porcelana; 2 para composite
  INPUT u1     -- Tensao no primeiro terminal [V]
        u2     -- Tensao no segundo terminal [V]
  VAR ukv      -- Tensao aplicada ao isolador [kV]
      uint     -- Integral da tensao [kV*s]
      eth      -- Limiar do streamer [kV]
      stream   -- Estado do streamer
      erem     -- Campo no comprimento restante [kV/m]
      vprop    -- Velocidade efetiva do lider [m/s]
      x        -- Comprimento desenvolvido [m]
      trip     -- Sinal de comando da chave
  OUTPUT trip
  INIT
    ukv    := 0
    uint   := 0
    eth    := k1*d+k2
    stream := 0
    erem   := 0
    vprop  := 0
    x      := 0
    trip   := 0
    integral(ukv)   := 0
    integral(vprop) := 0
  ENDINIT
  EXEC
    ukv  := abs(u1-u2)/1000
    uint := integral(ukv)
    IF stream=0 AND t>0 AND uint>=eth*t THEN
      stream := 1
    ENDIF
    IF stream=1 AND trip=0 AND x<d THEN
      erem := ukv/(d-x)
      IF erem>e0 THEN
        vprop := nlead*1000*k0*(erem-e0)
      ELSE
        vprop := 0
      ENDIF
    ELSE
      vprop := 0
    ENDIF
    x := integral(vprop) {dmax: d}
    IF x>=d THEN
      trip := 1
      vprop := 0
    ENDIF
  ENDEXEC
ENDMODEL