MODEL CIGRE

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

  -- CIGRE: constantes da Tabela 5-3
  --
  -- Configuração                         Polaridade   k1             E0
  -- Air gap/post/long rod                    +       0.8E-6         600
  -- Air gap/post/long rod                    -       1.0E-6         670
  -- Disc insulator                           +       1.2E-6         520
  -- Disc insulator                           -       1.3E-6         600
  --
  -- k1 em [m2/(V2*s)]
  -- E0 em [kV/m]

  DATA d       {dflt:4.15}    -- comprimento do isolamento [m]
       k1      {dflt:0.8E-6}  -- constante de velocidade [m^2/(V^2/s)]
       e0      {dflt:600}     -- campo crítico [kV/m]
       q       {dflt:400}     -- carga por comprimento [microC/m]
       rarc    {dflt:1}       -- resistência do arco [ohm]

  VAR uopen                  -- módulo da tensão de Thévenin [V]
      uterm                  -- módulo da tensão no isolador [V]
      e0si                   -- campo crítico [V/m]
      qsi                    -- carga por comprimento [C/m]
      field                  -- campo no trecho restante [V/m]
      gap                    -- trecho ainda não percorrido [m]
      vlead                  -- velocidade do líder [m/s]
      l                      -- comprimento total do líder [m]
      imag                   -- módulo da corrente do líder [A]
      stream                 -- streamer desenvolvido: 0 ou 1
      trip                   -- flashover: 0 ou 1
      tstream                -- instante de formação do streamer [microS]
      acoef                  -- coeficiente da equação quadrática
      bcoef                  -- coeficiente da equação quadrática
      delta                  -- discriminante

  INIT
    v       :=v0
    i       :=i0
    uopen   :=abs(v0)
    uterm   :=abs(v0)
    e0si    :=1000*e0
    qsi     :=q*1.0E-6
    field   :=0
    gap     :=d
    vlead   :=0
    l       :=0
    imag    :=abs(i0)
    stream  :=0
    trip    :=0
    tstream :=-1
    acoef   :=0
    bcoef   :=1
    delta   :=1

    integral(vlead) :=0
    histdef(v)      :=v0
    histdef(i)      :=i0
  ENDINIT

  EXEC

    IF trip=0 THEN
      -- Antes do desenvolvimento do líder não existe corrente.
      i:=0
      v:=vth
      uopen:=abs(vth)
      uterm:=uopen

      -- Critério CIGRE para o streamer:
      --
      --             U(ts) >= E0*d
      --
      -- Não é utilizado o critério integral do modelo de Wang.
      IF stream=0 THEN
        IF uopen>=e0si*d THEN
          stream:=1
          tstream:=t*1.0E6
        ENDIF
      ENDIF

      IF stream=1 AND l<d THEN
        gap:=d-l {min:1.0E-6}

        -- O líder somente progride se o campo sem carga
        -- já for superior ao campo crítico.
        IF uopen/gap>e0si THEN

          -- Solução simultânea de:
          --
          -- vlead = k1*U*(U/gap-E0)
          -- i     = q*vlead
          -- U     = abs(vth)-rth*abs(i)
          --
          -- Resulta em:
          -- acoef*U^2 + bcoef*U - abs(vth) = 0

          acoef:=rth*qsi*k1/gap
          bcoef:=1-rth*qsi*k1*e0si

          IF acoef>1.0E-30 THEN
            delta:=bcoef*bcoef+4*acoef*uopen

            -- Forma numericamente estável da raiz positiva.
            uterm:=2*uopen/(bcoef+sqrt(delta))
                    {min:0, max:uopen}
          ELSE
            -- Fonte ideal, rth=0.
            uterm:=uopen
          ENDIF

          field:=uterm/gap

          IF field>e0si THEN
            vlead:=k1*uterm*(field-e0si) {min:0}
            imag:=qsi*vlead

            v:=sign(vth)*uterm
            i:=sign(vth)*imag
          ELSE
            vlead:=0
            imag:=0
            i:=0
            v:=vth
            uterm:=uopen
          ENDIF

        ELSE
          vlead:=0
          imag:=0
          i:=0
          v:=vth
          uterm:=uopen
          field:=uopen/gap
        ENDIF

      ELSE
        vlead:=0
        imag:=0
        i:=0
        v:=vth
      ENDIF

      -- Comprimento acumulado do líder.
      l:=integral(vlead) {dmax:d}

      IF l>=d THEN
        trip:=1
        vlead:=0
        imag:=0
      ENDIF
    ENDIF

    -- Após o flashover, o isolamento é substituído por rarc.
    IF trip=1 THEN
      i:=vth/(rth+rarc)
      v:=rarc*i
    ENDIF

  ENDEXEC

ENDMODEL