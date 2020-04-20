SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptEMMthCostRev    Script Date: 8/28/99 9:35:58 AM ******/
      CREATE          proc [dbo].[brptEMMthCostRev]
      (@EMCo bCompany, @BeginCat varchar(10) =' ', @EndCat varchar(10) = 'zzzzzzzzzz',
      @BeginEquip bEquip =' ', @EndEquip bEquip = 'zzzzzzzzzz',
      @BeginMonth bMonth= '01/01/1950',
      @ThruMonth bMonth='12/01/2050')
      /* created 08/23/99 Tracy */
      /* Modified to add the Status from EMEM to the cost records 07/24/02 E.T.*/
      /*   declare @EMCo bCompany, @BeginCat varchar , @EndCat varchar ,
      @BeginEquip bEquip , @EndEquip varchar ,
      @BeginMth bMonth,
      @ThruMth bMonth
      
      Select @EMCo=1,, @BeginCat='' , @EndCat='zzzzzzzzzz' ,
      @BeginEquip ='' , @EndEquip ='zzzzzzzzzz' ,, @EndMth ='01/01/2050' */
      /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                         fixed : using tables instead of views. Issue #20721 
   	Mod 10/17/03 CR Added EMRC.Basis Issue #21470
   
   */
      /* Issue 25863 add with (nolock) DW 10/22/04*/
      
      as
      create table #EMMthCostRev
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
      --      RevEstWorkUnits	decimal(12,3)	null,
      --      RevEstTime	decimal(10,2)	Null,
      --      RevEstAmt		decimal(16,2)	Null,
            RevActualWorkUnits decimal(12,3)  NULL,
            RevActTime		decimal(10,2)	Null,
            RevActAmt		decimal(16,2)	Null,
            HrsPerTimeUM         decimal(10,2)       null,
      	 Status			char(1)		null, --addition 3/20/02 AA.
          	 Basis		char(1)  Null,
            CostCode		varchar(10)     NULL,
            CostType		tinyint         NULL,
      
            CTDesc		char(5)		Null,
      
            CostActUnits		decimal(12,3)	null,
            CostActCost		decimal(16,2)	Null,
    	Department		varchar(10)   NULL
   
      --      CostEstUnits	decimal(12,3)   NULL,
      --      CostEstCost	decimal(16,2)            NULL
      
      )
    
    
    
    
     /* insert Revenue info */
     insert into #EMMthCostRev
     (Type,EMCo, EMGroup,Equipment,Month,RevCode,RevAvailableHrs,
           /*RevEstWorkUnits,RevEstTime,RevEstAmt,*/RevActualWorkUnits,RevActTime,RevActAmt,HrsPerTimeUM,Department,Status,Basis)
     
     Select 'R',EMAR.EMCo, EMAR.EMGroup,EMAR.Equipment, EMAR.Month, EMAR.RevCode,EMAR.AvailableHrs,
     	/*EMAR.EstWorkUnits,EMAR.EstTime,EMAR.EstAmt,*/EMAR.ActualWorkUnits,
     	EMAR.Actual_Time,EMAR.ActualAmt, EMRC.HrsPerTimeUM,EMEM.Department,EMEM.Status, EMRC.Basis
     
     FROM EMAR with(nolock)
     JOIN EMEM with(nolock) on EMEM.EMCo=EMAR.EMCo and EMEM.Equipment=EMAR.Equipment
     join EMRC with(nolock) on EMAR.EMGroup=EMRC.EMGroup and EMAR.RevCode=EMRC.RevCode
     where  EMAR.EMCo=@EMCo and EMAR.Equipment>=@BeginEquip and EMAR.Equipment<=@EndEquip
     and EMEM.Category>=@BeginCat and EMEM.Category<=@EndCat
     and EMAR.Month>=@BeginMonth
     and EMAR.Month<=@ThruMonth
    
     /* insert Cost info */
     insert into #EMMthCostRev
     (Type,EMCo, EMGroup,Equipment,Month,CostCode,CostType,CostActUnits,CostActCost,Department,Status /*,CostEstUnits,CostEstCost*/)
     
     Select 'C',EMMC.EMCo, EMMC.EMGroup,EMMC.Equipment, EMMC.Month, EMMC.CostCode, EMMC.CostType,
     	EMMC.ActUnits, EMMC.ActCost,EMEM.Department,EMEM.Status /*, EMMC.EstUnits, EMMC.EstCost*/
     
     FROM EMMC with(nolock)
    
     JOIN EMEM with(nolock) on EMEM.EMCo=EMMC.EMCo and EMEM.Equipment=EMMC.Equipment
     where  EMMC.EMCo=@EMCo and EMMC.Equipment>=@BeginEquip and EMMC.Equipment<=@EndEquip
     and EMEM.Category>=@BeginCat and EMEM.Category<=@EndCat
     and EMMC.Month>=@BeginMonth
     and EMMC.Month<=@ThruMonth
    
      
      
      /* select the results */
      
      select a.Type,a.EMCo,Category=EMEM.Category,CatDesc=EMCM.Description,a.EMGroup,a.Equipment,EquipDesc=EMEM.Description,
      	a.Month,FiscalPeriod=GLFP.FiscalPd,FiscalYear=GLFP.FiscalYr,a.RevCode,a.Department,
      	RevCodeDesc=EMRC.Description,RevTimeUM=EMRC.TimeUM,a.RevAvailableHrs,/* a.RevEstWorkUnits,a.RevEstTime,
            	a.RevEstAmt,*/a.Status,a.Basis,a.RevActualWorkUnits,a.RevActTime,a.RevActAmt,a.HrsPerTimeUM,
      
            	a.CostCode,CostCodeDesc=EMCC.Description,a.CostType,CTAbbreviation=EMCT.Abbreviation,
      	CostUM=EMCH.UM,a.CostActUnits,a.CostActCost, /* a.CostEstUnits,a.CostEstCost,*/
      
        CoName=HQCO.Name,
        BeginCategory=@BeginCat,
        EndCategory=@EndCat,
        BeginEquip=@BeginEquip,
        EndEquip=@EndEquip,
        BegMonth=@BeginMonth,
        ThruMonth=@ThruMonth
      
         from #EMMthCostRev a
      
         JOIN EMEM with(nolock) on EMEM.EMCo=a.EMCo and EMEM.Equipment=a.Equipment
         Join GLFP with(nolock) on GLFP.GLCo=a.EMCo and GLFP.Mth=a.Month
         Left Join EMCM with(nolock) on EMCM.EMCo=a.EMCo and EMCM.Category=EMEM.Category
         Left Join EMRC with(nolock) on EMRC.EMGroup=a.EMGroup and EMRC.RevCode=a.RevCode
      
         Left Join EMCC with(nolock) on EMCC.EMGroup=a.EMGroup and EMCC.CostCode=a.CostCode
         Left Join EMCT with(nolock) on EMCT.EMGroup=a.EMGroup and EMCT.CostType=a.CostType
         Left Join EMCH with(nolock) on EMCH.EMCo=a.EMCo and EMCH.Equipment=a.Equipment and EMCH.EMGroup=a.EMGroup
      	 and EMCH.CostCode=a.CostCode and EMCH.CostType=a.CostType
         Join HQCO with(nolock) on HQCO.HQCo=a.EMCo

GO
GRANT EXECUTE ON  [dbo].[brptEMMthCostRev] TO [public]
GO
