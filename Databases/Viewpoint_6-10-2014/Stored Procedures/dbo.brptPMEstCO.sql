SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[brptPMEstCO]      
      (@JCCo bCompany, @BeginProject bProject ='', @EndProject bProject= 'zzzzzzzzz' ,@ThroughMth bMonth,@ACOThroughDate bDate)      
    as      
   /*   Mod CR Added NOLOCK # 25922   
     
        Mod DH 2/24.  Issue 138272.  Changed selection of Addons starting on line 61. Also,
        removed update statements on the temp table as these were just confusing and unneeded.
        New Addon select statement will return pending addons and approved addons that were not
        updated to PMOL.     
      
       NOTE:  SP may need to be modified when PM issue 138206 is fixed.  Where clause 
       starting on line 106 considered temporary.
      
     this stored proc is used in PM Revised Estimates and PM Job Cost and Pending Change Orders      
     
      
                                      */      
         
   create table #PMEstandCO      
     (JCCo  tinyint  Null,      
    Type  tinyint  Null,      
     Project  char(10) Null,      
     PhaseGroup tinyint  Null,      
     Phase  char(20) Null,      
     CostType tinyint  Null,      
     OrigEstCost     decimal(16,2)            NULL,      
     ActualCost decimal(16,2) Null,      
     RemainCmtdCost decimal(16,2) Null,      
     TotalCmtdCost decimal(16,2) Null,       
     ProjCost  decimal(16,2) Null,      
    Plugged  varchar(1) Null,      
          
     ACO  varchar(10) Null,      
     ACOItem  varchar(10) Null,      
     ACOAmt  decimal(16,2) Null,      
          
     PCOType  varchar(10) Null,      
     PCO  varchar(10) Null,      
     PCOItem  varchar(10) Null,      
     PCOAmt  decimal(16,2) Null,      
     ACOFlag  varchar(1) Null,      
     Addon   smallint  Null,      
    AddonPhaseGroup  tinyint  Null,       
    AddonPhase  char(20)  Null,      
    AddonCostType  tinyint   NULL,      
    AddonAmount  decimal(16,2)            NULL,    
    AddonStatus char(1) NULL,  
    StatusIncludeInProj char(6)  NULL,      
    TypeIncludeInProj char(6)  NULL       
     )      
   /* index added to aid report speed. 04/23/03 NF */        
      create nonclustered index biPMEstCO on #PMEstandCO (Type, PhaseGroup, ACO)      
         
         
   /*insert Addons*/      
       insert into #PMEstandCO      
     (JCCo,Type,Project,PhaseGroup, Phase, CostType,
	  ACO,ACOItem,Project.PCOType, PCO, PCOItem,
	  ACOFlag,Addon,AddonPhaseGroup, AddonPhase,AddonCostType ,AddonAmount,StatusIncludeInProj,AddonStatus,
	  PCOAmt, ACOAmt)
      
    Select  PMOA.PMCo,2 ,PMOA.Project,PMPA.PhaseGroup,PMPA.Phase,PMPA.CostType,
		    PMOL.ACO,PMOL.ACOItem,PMOI.PCOType,PMOI.PCO, PMOI.PCOItem,
			PMOI.Approved, PMOA.AddOn, PMPA.PhaseGroup,PMPA.Phase,PMPA.CostType,
		    PMOA.AddOnAmount,PMSC.IncludeInProj, PMOA.Status 
			,(case when PMOI.Approved = 'N' then PMOA.AddOnAmount else 0 end) as PCOAmt
			--,(case when PMOI.Approved = 'Y' and PMOA.Status = 'N' then PMOA.AddOnAmount else 0 end) as ACOAmt
			,(case when PMOI.Approved = 'Y'
					and PMPA.Phase is not null
					and PMOL.Phase is null 
			   then PMOA.AddOnAmount end) as ACOAmt
    /*from JCCH with (NOLOCK)      
    left join PMOL with (NOLOCK) on JCCH.JCCo=PMOL.PMCo and JCCH.Job=PMOL.Project and      
     JCCH.PhaseGroup=PMOL.PhaseGroup and JCCH.Phase=PMOL.Phase and JCCH.CostType=PMOL.CostType      
    Left Join PMOI with (NOLOCK) on PMOI.PMCo=JCCH.JCCo and PMOI.Project=JCCH.Job and      
     PMOL.PCOType=PMOI.PCOType and PMOL.PCO=PMOI.PCO and PMOL.PCOItem=PMOI.PCOItem      
    Left join PMSC with (NOLOCK) on PMOI.Status=PMSC.Status/* - Addition made on 6/4/02 by Aghaa */      
    inner join PMOA with (NOLOCK) on PMOI.PMCo=PMOA.PMCo and  PMOI.Project=PMOA.Project and PMOI.PCOType=PMOA.PCOType and PMOI.PCO=PMOA.PCO and      
    PMOI.PCOItem=PMOA.PCOItem      
    inner Join PMPA with (NOLOCK) on PMOA.PMCo=PMPA.PMCo and PMOA.Project=PMPA.Project and PMOA.AddOn=PMPA.AddOn       
   */
FROM PMOA With (NoLock)

INNER JOIN	PMPA With (NoLock)
	ON  PMPA.PMCo = PMOA.PMCo 
	AND PMPA.Project = PMOA.Project 
	AND PMPA.AddOn = PMOA.AddOn
INNER JOIN	PMOI With (NoLock)
	ON	PMOI.PMCo = PMOA.PMCo
	AND PMOI.Project = PMOA.Project
	AND PMOI.PCOType = PMOA.PCOType
	AND PMOI.PCO = PMOA.PCO
	AND PMOI.PCOItem = PMOA.PCOItem
LEFT JOIN	PMOL With (NoLock)
	ON  PMOA.PMCo = PMOL.PMCo
	AND PMOA.Project = PMOL.Project
	AND PMOA.PCOType = PMOL.PCOType
	AND PMOA.PCO = PMOL.PCO
	AND PMOA.PCOItem = PMOL.PCOItem
	AND PMPA.Phase = PMOL.Phase
	AND PMPA.CostType = PMOL.CostType
LEFT JOIN PMSC with (NOLOCK) 
	on PMOI.Status=PMSC.Status

Where 
	(PMOI.Approved = 'N'
	 OR (PMOI.Approved = 'Y' 
		 and PMOA.Status = 'N')
         )
     and PMOA.PMCo=@JCCo and PMOA.Project>=@BeginProject and PMOA.Project<=@EndProject      
     and PMPA.Phase IS NOT NULL 

--Temporary Fix:  Includes unapproved COs or approved COs where AddOn Phase does not exist in PMOL
/*Where 
	(PMOI.Approved = 'N'

	 OR (PMOI.Approved = 'Y'
		 and PMPA.Phase is not null
		 and PMOL.Phase is null))*/
 
     
         
         
         
 /*  update #PMEstandCO       
   set  PhaseGroup=AddonPhaseGroup,      
    Phase=AddonPhase,      
    CostType=AddonCostType,      
    PCOAmt=AddonAmount      
   where   Type=2 and PhaseGroup IS NULL    */  
         
   /*update #PMEstandCO       
   set  PhaseGroup=AddonPhaseGroup,      
    Phase=AddonPhase,      
    CostType=AddonCostType,      
    ACOAmt=AddonAmount,    
    PCOAmt=0      
   where   Type=2 and ACO is NOT NULL and AddonStatus = 'N'      */

/*   update #PMEstandCO       
   set  PhaseGroup=AddonPhaseGroup,      
    Phase=AddonPhase,      
    CostType=AddonCostType,      
--    ACOAmt=AddonAmount,    12-07-09 MB  
    PCOAmt=0      
   where   Type=2 and ACO is NOT NULL */
         
         
    /* insert JCCH and JCCP info */      
      insert into #PMEstandCO      
      (JCCo,Type,Project,PhaseGroup,Phase,CostType,OrigEstCost,Plugged)      
          
      Select JCCH.JCCo,1,JCCH.Job,JCCH.PhaseGroup,JCCH.Phase,JCCH.CostType,JCCH.OrigCost,JCCH.Plugged      
         
          
    From JCCH with (NOLOCK)      
          
   where JCCH.JCCo=@JCCo and JCCH.Job>=@BeginProject and JCCH.Job<=@EndProject       
         
      insert into #PMEstandCO      
      (JCCo, Type, Project, PhaseGroup, Phase, CostType, ActualCost,RemainCmtdCost,TotalCmtdCost, ProjCost)      
        
          
      Select JCCP.JCCo, 1,JCCP.Job, JCCP.PhaseGroup, JCCP.Phase, JCCP.CostType,JCCP.ActualCost,JCCP.RemainCmtdCost,JCCP.TotalCmtdCost,JCCP.ProjCost      
         
          
    From JCCH with (NOLOCK)      
    Left Join JCCP with (NOLOCK) on JCCH.JCCo=JCCP.JCCo and JCCH.Job=JCCP.Job and      
     JCCH.PhaseGroup=JCCP.PhaseGroup and JCCH.Phase=JCCP.Phase and      
     JCCH.CostType=JCCP.CostType      
          
    where JCCH.JCCo=@JCCo and JCCH.Job>=@BeginProject and JCCH.Job<=@EndProject and isnull(JCCP.Mth, @ThroughMth)<=@ThroughMth      
         
          
         
    /* insert Approved Change Orders */      
      insert into #PMEstandCO      
     (JCCo,Type,Project,PhaseGroup,Phase,CostType,ACO,ACOItem,ACOAmt,ACOFlag)      
    Select JCCH.JCCo,1, JCCH.Job,JCCH.PhaseGroup,JCCH.Phase,JCCH.CostType,      
     PMOL.ACO,PMOL.ACOItem,PMOL.EstCost,PMOI.Approved      
    from JCCH with (NOLOCK)      
         
    left join PMOL with (NOLOCK) on JCCH.JCCo=PMOL.PMCo and JCCH.Job=PMOL.Project and      
     JCCH.PhaseGroup=PMOL.PhaseGroup and JCCH.Phase=PMOL.Phase and JCCH.CostType=PMOL.CostType      
    Left Join PMOI with (NOLOCK) on PMOI.PMCo=JCCH.JCCo and PMOI.Project=JCCH.Job and      
     PMOL.ACO=PMOI.ACO and PMOL.ACOItem=PMOI.ACOItem      
    where JCCH.JCCo=@JCCo and JCCH.Job>=@BeginProject and JCCH.Job<=@EndProject      
     and PMOI.Approved='Y' and PMOI.ApprovedDate<=@ACOThroughDate      
          
    /* insert Pending Change Orders */      
      insert into #PMEstandCO      
     (JCCo,Type,Project,PhaseGroup,Phase,CostType,PCOType,PCO,PCOItem,PCOAmt,ACOFlag,StatusIncludeInProj,TypeIncludeInProj)      
    Select JCCH.JCCo,1,JCCH.Job,JCCH.PhaseGroup,JCCH.Phase,JCCH.CostType,PMOL.PCOType,      
     PMOL.PCO,PMOL.PCOItem,PMOL.EstCost,PMOI.Approved,PMSC.IncludeInProj,--Addition made 1/28/02      
    PMDT.IncludeInProj      
    from JCCH with (NOLOCK)      
    left join PMOL with (NOLOCK) on JCCH.JCCo=PMOL.PMCo and JCCH.Job=PMOL.Project and      
     JCCH.PhaseGroup=PMOL.PhaseGroup and JCCH.Phase=PMOL.Phase and JCCH.CostType=PMOL.CostType      
    Left Join PMOI with (NOLOCK) on PMOI.PMCo=JCCH.JCCo and PMOI.Project=JCCH.Job and      
     PMOL.PCOType=PMOI.PCOType and PMOL.PCO=PMOI.PCO and PMOL.PCOItem=PMOI.PCOItem       
    Left join PMSC with (NOLOCK) on PMOI.Status=PMSC.Status/* - Addition made on 1/28/02 by Aghaa */      
    Left join PMDT with (NOLOCK) on PMOI.PCOType=PMDT.DocType/*- Addition made on4/3/02 by aghaa*/      
    where JCCH.JCCo=@JCCo and JCCH.Job>=@BeginProject and JCCH.Job<=@EndProject      
     and PMOI.Approved='N' /*and PMOI.ApprovedDate<=@ACOThroughDate*/      
          
         
         
         
         
         
     /* select the results */      
      select a.JCCo,a.Type,a.Project,a.PhaseGroup,a.Phase,a.CostType,a.OrigEstCost,a.ActualCost,      
     a.RemainCmtdCost,a.TotalCmtdCost,a.ProjCost,      
     a.ACO,a.ACOItem,a.ACOAmt,      
     a.PCOType,a.PCO,a.PCOItem,a.PCOAmt,      
     a.ACOFlag,a.Addon,a.AddonPhase,a.AddonAmount,      
           CoName=HQCO.Name, ProjDesc=JCJM.Description,      
           PM=JCJM.ProjectMgr,PMName=JCMP.Name,      
           BeginProject=@BeginProject,      
           EndProject=@EndProject,      
           PhaseDesc=JCJP.Description,      
       CostTypeDesc=JCCT.Abbreviation,      
   ThroughMth=@ThroughMth,      
   ACOThroughDate=@ACOThroughDate,      
   Plugged=IsNull(JCCH.Plugged,'N'), a.StatusIncludeInProj, a.TypeIncludeInProj      
          
         from #PMEstandCO a      
          
     Join JCJM with (NOLOCK) on JCJM.JCCo=a.JCCo and JCJM.Job=a.Project       
        JOIN JCJP with (NOLOCK) on JCJP.JCCo=a.JCCo and JCJP.Job=a.Project and      
                JCJP.PhaseGroup=a.PhaseGroup and JCJP.Phase=a.Phase        
        Join HQCO with (NOLOCK) on HQCO.HQCo=a.JCCo      
        Join JCCT with (NOLOCK) on JCCT.PhaseGroup=a.PhaseGroup and JCCT.CostType=a.CostType       
    Left Join JCMP with (NOLOCK) on JCMP.JCCo=JCJM.JCCo and JCMP.ProjectMgr=JCJM.ProjectMgr      
        Left Join JCCH with (NOLOCK) on a.JCCo=JCCH.JCCo  and a.Project=JCCH.Job  and a.PhaseGroup=JCCH.PhaseGroup        
    and a.Phase=JCCH.Phase   and a.CostType=JCCH.CostType      
   --order by a.Phase 
GO
GRANT EXECUTE ON  [dbo].[brptPMEstCO] TO [public]
GO
