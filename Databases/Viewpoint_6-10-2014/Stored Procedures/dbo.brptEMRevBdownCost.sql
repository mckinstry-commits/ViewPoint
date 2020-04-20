SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[brptEMRevBdownCost]
   (@EMCo bCompany,
   --@BeginCat varchar(10) ='', @EndCat varchar(10) = 'zzzzzzzzz',
   @BeginEquip bEquip ='', @EndEquip bEquip = 'zzzzzzzzz',
   @BeginMth bMonth= '01/01/1951', @ThruMth bMonth='01/01/2050')
   /* created 08/31/99 Tracy */
   /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                         fixed : using tables instead of views. Issue #20721 
      Mod 11/05/04 CR added NoLocks #25903
   */
   
   as
   create table #EMRevBdownCost
    (Type			char(2)		Null, /*RB=Revenue Breakdown or RD=Revenue Detail CD=CostDetail*/
     EMCo			tinyint		NULL,
     EMGroup		tinyint		null,
     Equipment		char(10)	Null,
     RevBdownCode		varchar(10)	Null,
     Mth			smalldatetime	Null,
     Trans			int		Null,
     RevCode		char(10)        NULL,
     RevBdownAmount	decimal(16,2)	NULL,
     RevTimeUnits		decimal(12,3)	Null,
     RevDetailAmt		decimal(16,2)	Null,
     CostTrans		int		null,
     CostCode		varchar(10)	null,
     CostType		tinyint		null,
     CostUnits		decimal(12,3)	null,
     CostDollars		decimal(16,2)	null
    )
   
   /* insert Revenue info */
   insert into #EMRevBdownCost
     (Type,EMCo, EMGroup,RevBdownCode,Mth,Trans,Equipment,RevCode,RevBdownAmount)
   
        Select 'RB',EMRB.EMCo, EMRB.EMGroup,EMRB.RevBdownCode, EMRB.Mth, EMRB.Trans,EMRB.Equipment,EMRB.RevCode,EMRB.Amount
   
   	FROM EMRB with (NOLOCK)
   	where  EMRB.EMCo=@EMCo and EMRB.Equipment>=@BeginEquip and EMRB.Equipment<=@EndEquip
   	and EMRB.Mth>=@BeginMth
   	and EMRB.Mth<=@ThruMth
   
   /* insert Revenue Detail info */
   insert into #EMRevBdownCost
     (Type,EMCo, EMGroup,Mth,Trans,Equipment,RevCode,RevTimeUnits,RevDetailAmt)
   
        Select 'RD',EMRD.EMCo, EMRD.EMGroup, EMRD.Mth, EMRD.Trans,
           EMRD.Equipment,EMRD.RevCode,sum(EMRD.TimeUnits),sum(EMRD.Dollars)
   
   	FROM   EMRD with (NOLOCK)
   	where  EMRD.EMCo=@EMCo and EMRD.Equipment>=@BeginEquip and EMRD.Equipment<=@EndEquip
   	       and EMRD.Mth>=@BeginMth
   	       and EMRD.Mth<=@ThruMth
   group by EMRD.EMCo, EMRD.EMGroup, EMRD.Mth, EMRD.Trans,
            EMRD.Equipment,EMRD.RevCode
   
   /* insert Cost info */
   
   insert into #EMRevBdownCost
   (Type,EMCo, EMGroup,Equipment,RevBdownCode,Mth,CostTrans,CostCode,CostType,CostUnits,CostDollars)
   
        Select 'CD',EMCD.EMCo, EMCD.EMGroup,EMCD.Equipment,EMCC.RevBdownCode, EMCD.Mth, EMCD.EMTrans,EMCD.CostCode, EMCD.EMCostType,
   	 EMCD.Units, EMCD.Dollars
   
    	FROM EMCD with (NOLOCK)
   Left Join EMCC on EMCD.EMGroup=EMCC.EMGroup and EMCD.CostCode=EMCC.CostCode
   	where  EMCD.EMCo=@EMCo and EMCD.Equipment>=@BeginEquip and EMCD.Equipment<=@EndEquip
   	       and EMCD.Mth>=@BeginMth
   	       and EMCD.Mth<=@ThruMth
   
   /* select the results */
   
   select a.Type, a.EMCo,a.EMGroup,a.Equipment,EquipDesc=EMEM.Description,a.RevBdownCode,RevBdownDesc=EMRT.Description,
          a.Mth,a.Trans,a.RevCode,RevCodeDesc=EMRC.Description,a.RevBdownAmount,a.RevTimeUnits,
          a.RevDetailAmt,a.CostTrans,a.CostCode,a.CostType,CTDesc=EMCT.CostType,a.CostUnits,a.CostDollars,
   
     CoName=HQCO.Name,
   --  BeginCategory=@BeginCat,
   --  EndCategory=@EndCat,
     BeginEquip=@BeginEquip,
     EndEquip=@EndEquip,
     BegMonth=@BeginMth,
     ThruMonth=@ThruMth
   
      from #EMRevBdownCost a
   
     JOIN EMEM on EMEM.EMCo=a.EMCo and EMEM.Equipment=a.Equipment
   --   Left Join EMCM on EMCM.EMCo=a.EMCo and EMCM.Category=EMEM.Category
      Left Join EMRC with (NOLOCK) on EMRC.EMGroup=a.EMGroup and EMRC.RevCode=a.RevCode
      Left Join EMRT with (NOLOCK) on EMRT.EMGroup=a.EMGroup and EMRT.RevBdownCode=a.RevBdownCode
   
      Left Join EMCC with (NOLOCK) on EMCC.EMGroup=a.EMGroup and EMCC.CostCode=a.CostCode
      Left Join EMCT with (NOLOCK) on EMCT.EMGroup=a.EMGroup and EMCT.CostType=a.CostType
      Join HQCO with (NOLOCK) on HQCO.HQCo=a.EMCo

GO
GRANT EXECUTE ON  [dbo].[brptEMRevBdownCost] TO [public]
GO
