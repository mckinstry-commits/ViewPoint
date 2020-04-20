SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Drop proc brptEMMthDeprCostRev
    /****** Object:  Stored Procedure dbo.brptEMMthDeprCostRev ******/
    CREATE   proc [dbo].[brptEMMthDeprCostRev]
    (@EMCo bCompany, @BeginCat varchar(10) ='', @EndCat varchar(10) = 'zzzzzzzzz',
    @BeginEquip bEquip ='', @EndEquip bEquip = 'zzzzzzzzz',
    @BeginMonth bMonth= '01/01/1951',
    @ThruMonth bMonth='01/01/2050')
    /* created 08/23/99 Tracy */
    /*   declare @EMCo bCompany, @BeginCat varchar , @EndCat varchar ,
    @BeginEquip bEquip , @EndEquip varchar ,
    @BeginMth bMonth,
    @ThruMth bMonth
    
    Select @EMCo=1,, @BeginCat='' , @EndCat='zzzzzzzzzz' ,
    @BeginEquip ='' , @EndEquip ='zzzzzzzzzz' ,, @EndMth ='01/01/2050' */
    /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                       fixed : using tables instead of views. Issue #20721 
     Mod 11/5/04 CR added NoLocks  #25902
   */
    
    
    as
    create table #EMMthDeprCostRev
        	 (Type		char(1)		Null, /*R=Revenue or C=Cost*/
          	EMCo		tinyint		NULL,
          	Category		char(10)	Null,
          	EMGroup		tinyint		null,
         	Equipment		char(10)	Null,
          	Month		smalldatetime	Null,
          	FiscalPeriod		tinyint		Null,
         	FiscalYear		smallint	Null,
         	RevCode	        	char(10)        NULL,
          	RevAvailableHrs	decimal(10,2)	NULL,
    --     	RevEstWorkUnits	decimal(12,3)	null,
    --      	RevEstTime	decimal(10,2)	Null,
    --      	RevEstAmt		decimal(16,2)	Null,
          	RevActualWorkUnits decimal(12,3)  NULL,
          	RevActTime		decimal(10,2)	Null,
          	RevActAmt		decimal(16,2)	Null,
    
         	CostCode		varchar(10)     NULL,
          	CostType		tinyint         NULL,
    
          	CTDesc		char(5)		Null,
    
          	CostActUnits		decimal(12,3)	null,
          	CostActCost		decimal(16,2)	Null,
    --      	CostEstUnits	decimal(12,3)   NULL,
    --      	CostEstCost	decimal(16,2)   NULL,
    
        	 Asset		Varchar(20)      Null,
    	AmtTaken	Numeric (9,2)	Null
    
    )
    
    /* insert Revenue info */
    insert into #EMMthDeprCostRev
    (Type,EMCo, EMGroup,Equipment,Month,RevCode,RevAvailableHrs,
          /*RevEstWorkUnits,RevEstTime,RevEstAmt,*/RevActualWorkUnits,RevActTime,RevActAmt)
    
    Select 'R',EMAR.EMCo, EMAR.EMGroup,EMAR.Equipment, EMAR.Month, EMAR.RevCode,EMAR.AvailableHrs,
    	/*EMAR.EstWorkUnits,EMAR.EstTime,EMAR.EstAmt,*/EMAR.ActualWorkUnits,
    	EMAR.Actual_Time,EMAR.ActualAmt
    
    FROM EMAR with (NOLOCK)
    where  EMAR.EMCo=@EMCo and EMAR.Equipment>=@BeginEquip and EMAR.Equipment<=@EndEquip
    and EMAR.Month>=@BeginMonth
    and EMAR.Month<=@ThruMonth
    
    /* insert Cost info */
    insert into #EMMthDeprCostRev
    (Type,EMCo, EMGroup,Equipment,Month,CostCode,CostType,CostActUnits,CostActCost/*,CostEstUnits,CostEstCost*/)
    
    Select 'C',EMMC.EMCo, EMMC.EMGroup,EMMC.Equipment, EMMC.Month, EMMC.CostCode, EMMC.CostType,
    	EMMC.ActUnits, EMMC.ActCost/*, EMMC.EstUnits, EMMC.EstCost*/
    
    FROM EMMC with (NOLOCK)
    where  EMMC.EMCo=@EMCo and EMMC.Equipment>=@BeginEquip and EMMC.Equipment<=@EndEquip
    and EMMC.Month>=@BeginMonth
    and EMMC.Month<=@ThruMonth
    
   /*insert Depr Info*/
   insert into #EMMthDeprCostRev
   (Type,EMCo, Equipment,Month,Asset,AmtTaken)
   Select 'D',EMCD.EMCo,EMCD.Equipment,EMCD.Mth,EMCD.Asset,EMCD.Dollars
   
   FROM EMCD with (NOLOCK)
   where EMCD.EMCo=@EMCo and EMCD.Equipment>=@BeginEquip and EMCD.Equipment<=@EndEquip
   and EMCD.Mth>=@BeginMonth
   and EMCD.Mth<=@ThruMonth
   and EMCD.EMTransType='Depn'
    
    
    /* select the results */
    
    select a.Type,a.EMCo,Category=EMEM.Category,CatDesc=EMCM.Description,a.EMGroup,a.Equipment,EquipDesc=EMEM.Description,
    	a.Month,FiscalPeriod=GLFP.FiscalPd,FiscalYear=GLFP.FiscalYr,a.RevCode,
    	RevCodeDesc=EMRC.Description,RevTimeUM=EMRC.TimeUM,a.RevAvailableHrs,/* a.RevEstWorkUnits,a.RevEstTime,
          	a.RevEstAmt,*/a.RevActualWorkUnits,a.RevActTime,a.RevActAmt,
    
          	a.CostCode,CostCodeDesc=EMCC.Description,a.CostType,CTAbbreviation=EMCT.Abbreviation,
    	CostUM=EMCH.UM,a.CostActUnits,a.CostActCost,/* a.CostEstUnits,a.CostEstCost,*/a.Asset,a.AmtTaken,
    
      CoName=HQCO.Name,
      BeginCategory=@BeginCat,
      EndCategory=@EndCat,
      BeginEquip=@BeginEquip,
      EndEquip=@EndEquip,
      BegMonth=@BeginMonth,
      ThruMonth=@ThruMonth
    
       from #EMMthDeprCostRev a
    
       JOIN EMEM with (NOLOCK) on EMEM.EMCo=a.EMCo and EMEM.Equipment=a.Equipment
       Join GLFP with (NOLOCK) on GLFP.GLCo=a.EMCo and GLFP.Mth=a.Month
       Left Join EMCM with (NOLOCK) on EMCM.EMCo=a.EMCo and EMCM.Category=EMEM.Category
       Left Join EMRC with (NOLOCK) on EMRC.EMGroup=a.EMGroup and EMRC.RevCode=a.RevCode
       --Left Join EMDS on EMDS.EMCo=a.EMCo and EMDS.Equipment=a.Equipment and EMDS.Month=a.Month
       Left Join EMCC with (NOLOCK) on EMCC.EMGroup=a.EMGroup and EMCC.CostCode=a.CostCode
       Left Join EMCT with (NOLOCK) on EMCT.EMGroup=a.EMGroup and EMCT.CostType=a.CostType
       Left Join EMCH with (NOLOCK) on EMCH.EMCo=a.EMCo and EMCH.Equipment=a.Equipment and EMCH.EMGroup=a.EMGroup
    	 and EMCH.CostCode=a.CostCode and EMCH.CostType=a.CostType
       Join HQCO with (NOLOCK) on HQCO.HQCo=a.EMCo

GO
GRANT EXECUTE ON  [dbo].[brptEMMthDeprCostRev] TO [public]
GO
