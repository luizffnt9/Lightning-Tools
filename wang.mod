MODEL WANG94

  DATA n
       n2 {dflt:1}

  INPUT vth
        rth
        gth
        v0
        i0

  VAR v
      i

  OUTPUT i

  -- Wang et al. (2014), Tabelas V e VI
  DATA d       {dflt:4.15} -- comprimento total da cadeia [m]
       k1      {dflt:500}  -- streamer [kV/m]
       k2      {dflt:140}  -- streamer [kV]
       k0      {dflt:1.3}  -- lider [m2/(kV*ms)]
       e0      {dflt:570}  -- campo limiar [kV/m]
       nlead   {dflt:2}    -- 1 porcelana; 2 composite
       q       {dflt:500}  -- carga por comprimento [microC/m]
       rarc    {dflt:1}    -- resistencia do arco [ohm]

  VAR ukv                   -- tensao no isolador [kV]
      uint                  -- integral da tensao [kV*s]
      eth                   -- limiar do streamer [kV]
      stream                -- streamer concluido: 0 ou 1
      erem                  -- campo no trecho restante [kV/m]
      vlead                 -- velocidade de um lider [m/s]
      vtotal                -- velocidade total desenvolvida [m/s]
      x                     -- comprimento total desenvolvido [m]
      trip                  -- flashover: 0 ou 1
      vmag                  -- modulo da tensao [V]
      imag                  -- modulo da corrente de pre-descarga [A]
      gap                   -- comprimento [m]
      coef                  -- q*10^-6*K0 convertido para unidades SI
      den                   -- denominador para utilizar no thevenin

  INIT
    v      :=v0
    i      :=i0
    ukv    :=0
    uint   :=0
    eth    :=k1*d+k2
    stream :=0
    erem   :=0
    vlead  :=0
    vtotal :=0
    x      :=0
    trip   :=0
    vmag   :=abs(v0)
    imag   :=abs(i0)
    gap    :=d
    coef   :=q*1.0E-3*k0
    den    :=1

    integral(ukv)    :=0
    integral(vtotal) :=0
    histdef(v)       :=v0
    histdef(i)       :=i0
  ENDINIT

  EXEC
    IF trip=0 THEN
      -- Equacao (5): integral(U dt)/t >= k1*d+k2.
      IF stream=0 THEN
        i:=0
        v:=vth
        ukv :=abs(v)/1000
        uint:=integral(ukv)

        IF t>0 AND uint>=eth*t THEN
          stream:=1
        ENDIF
      ENDIF

      
      -- v=vth-rth*i e i=q*vlead.
      IF stream=1 AND x<d THEN
        gap:=d-x
        den:=1+coef*rth/(1000*gap)
        imag:=coef*(abs(vth)/(1000*gap)-e0)/den {min:0}
        vmag:=abs(vth)-imag*rth {min:0, max:abs(vth)}

        v:=sign(vth)*vmag
        i:=sign(vth)*imag
        ukv:=vmag/1000
        erem:=ukv/(d-x)

        IF erem>e0 THEN
          vlead:=1000*k0*(erem-e0)
        ELSE
          vlead:=0
          imag:=0
          i:=0
          v:=vth
          ukv:=abs(v)/1000
        ENDIF

        -- Wang: x=xL na porcelana e x=2*xL no composite.
        vtotal:=nlead*vlead
      ELSE
        vlead :=0
        vtotal:=0
        imag:=0
        i:=0
      ENDIF

      x:=integral(vtotal) {dmax:d}

      IF x>=d THEN
        trip  :=1
        vlead :=0
        vtotal:=0
      ENDIF
    ENDIF


    -- Solucao considerando a resistência do arco
    IF trip=1 THEN
      i:=vth/(rth+rarc)
      v:=rarc*i
    ENDIF
  ENDEXEC

ENDMODEL
