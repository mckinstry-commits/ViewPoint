SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE              proc dbo.brptCCPMEstCO
     (@JCCo bCompany, @Project1 bProject ='', @Project2 bProject= 'zzzzzzzzz' ,@ThroughMth bMonth,@ACOThroughDate bDate)
   as
--created on 1/13/05 sbj can use /* for commenting as well */ changed to use IN for project 1 & 2 instead of range of projects  
  create table #CCPMEstandCO
   	(JCCo		tinyint		Null,
  	Type		tinyint		Null,
   	Project		char(10)	Null,
   	PhaseGroup	tinyint		Null,
   	Phase		char(20)	Null,
   	CostType	tinyint		Null,
   	OrigEstCost     decimal(16,2)            NULL,
   	ActualCost	decimal(16,2)	Null,
   	RemainCmtdCost	decimal(16,2)	Null,
   	TotalCmtdCost	decimal(16,2)	Null,	
   	ProjCost		decimal(16,2)	Null,
  	Plugged		varchar(1)	Null,
   
   	ACO		varchar(10)	Null,
   	ACOItem		varchar(10)	Null,
   	ACOAmt		decimal(16,2)	Null,
   
   	PCOType		varchar(10)	Null,
   	PCO		varchar(10)	Null,
   	PCOItem		varchar(10)	Null,
   	PCOAmt		decimal(16,2)	Null,
   	ACOFlag		varchar(1)	Null,
   	Addon			smallint		Null,
  	AddonPhaseGroup		tinyint		Null,	
  	AddonPhase		char(20)		Null,
  	AddonCostType		tinyint			NULL,
  	AddonAmount		decimal(16,2)            NULL,
  	StatusIncludeInProj	char(6)		NULL,
  	TypeIncludeInProj	char(6)		NULL 
  	 )
  /* index added to aid report speed. 04/23/03 NF */ 	
     create nonclustered index biCCPMEstCO on #CCPMEstandCO (Type, PhaseGroup, ACO)
  
  
  /*insert Addons*/
      insert into #CCPMEstandCO
   	(JCCo,Type,Project,PhaseGroup, Phase, CostType, ACO,ACOItem,Project.PCOType, PCO, PCOItem, ACOFlag,Addon,AddonPhaseGroup, AddonPhase,AddonCostType ,AddonAmount,StatusIncludeInProj)
   Select distinct JCCH.JCCo,2,JCCH.Job,NULL,NULL,NULL, PMOL.ACO,PMOL.ACOItem,PMOI.PCOType,PMOI.PCO, PMOI.PCOItem, PMOI.Approved, PMOA.AddOn, PMPA.PhaseGroup,PMPA.Phase,PMPA.CostType, PMOA.AddOnAmount,PMSC.IncludeInProj--Addition made 6/4/02
   from JCCH
   left join PMOL on JCCH.JCCo=PMOL.PMCo and JCCH.Job=PMOL.Project and
   	JCCH.PhaseGroup=PMOL.PhaseGroup and JCCH.Phase=PMOL.Phase and JCCH.CostType=PMOL.CostType
   Left Join PMOI on PMOI.PMCo=JCCH.JCCo and PMOI.Project=JCCH.Job and
   	PMOL.PCOType=PMOI.PCOType and PMOL.PCO=PMOI.PCO and PMOL.PCOItem=PMOI.PCOItem
   Left join PMSC on PMOI.Status=PMSC.Status/* - Addition made on 6/4/02 by Aghaa */
   inner join PMOA on PMOI.PMCo=PMOA.PMCo and  PMOI.Project=PMOA.Project and PMOI.PCOType=PMOA.PCOType and PMOI.PCO=PMOA.PCO and
  	PMOI.PCOItem=PMOA.PCOItem
   inner Join PMPA on PMOA.PMCo=PMPA.PMCo and PMOA.Project=PMPA.Project and PMOA.AddOn=PMPA.AddOn 
   where JCCH.JCCo=@JCCo and JCCH.Job in (@Project1, @Project2)
   	and PMPA.Phase IS NOT NULL
  
  
  
  update #CCPMEstandCO 
  set 	PhaseGroup=AddonPhaseGroup,
  	Phase=AddonPhase,
  	CostType=AddonCostType,
  	PCOAmt=AddonAmount
  where   Type=2 and PhaseGroup IS NULL
  
  update #CCPMEstandCO 
  set 	PhaseGroup=AddonPhaseGroup,
  	Phase=AddonPhase,
  	CostType=AddonCostType,
  	ACOAmt=AddonAmount,
  	PCOAmt=0
  where   Type=2 and ACO is NOT NULL 
  
  
   /* insert JCCH and JCCP info */
     insert into #CCPMEstandCO
     (JCCo,Type,Project,PhaseGroup,Phase,CostType,OrigEstCost,Plugged)
   
     Select JCCH.JCCo,1,JCCH.Job,JCCH.PhaseGroup,JCCH.Phase,JCCH.CostType,JCCH.OrigCost,JCCH.Plugged
  
   
   From JCCH
   
  where JCCH.JCCo=@JCCo and JCCH.Job in (@Project1, @Project2) 
  
     insert into #CCPMEstandCO
     (JCCo, Type, Project, PhaseGroup, Phase, CostType, ActualCost,RemainCmtdCost,TotalCmtdCost, ProjCost)
  
   
     Select JCCP.JCCo, 1,JCCP.Job, JCCP.PhaseGroup, JCCP.Phase, JCCP.CostType,JCCP.ActualCost,JCCP.RemainCmtdCost,JCCP.TotalCmtdCost,JCCP.ProjCost
  
   
   From JCCH
   Left Join JCCP on JCCH.JCCo=JCCP.JCCo and JCCH.Job=JCCP.Job and
   	JCCH.PhaseGroup=JCCP.PhaseGroup and JCCH.Phase=JCCP.Phase and
   	JCCH.CostType=JCCP.CostType
   
   where JCCH.JCCo=@JCCo and JCCH.Job in (@Project1, @Project2) and isnull(JCCP.Mth, @ThroughMth)<=@ThroughMth
  
   
  
   /* insert Approved Change Orders */
     insert into #CCPMEstandCO
   	(JCCo,Type,Project,PhaseGroup,Phase,CostType,ACO,ACOItem,ACOAmt,ACOFlag)
   Select JCCH.JCCo,1, JCCH.Job,JCCH.PhaseGroup,JCCH.Phase,JCCH.CostType,
   	PMOL.ACO,PMOL.ACOItem,PMOL.EstCost,PMOI.Approved
   from JCCH
  
   left join PMOL on JCCH.JCCo=PMOL.PMCo and JCCH.Job=PMOL.Project and
   	JCCH.PhaseGroup=PMOL.PhaseGroup and JCCH.Phase=PMOL.Phase and JCCH.CostType=PMOL.CostType
   Left Join PMOI on PMOI.PMCo=JCCH.JCCo and PMOI.Project=JCCH.Job and
   	PMOL.ACO=PMOI.ACO and PMOL.ACOItem=PMOI.ACOItem
   where JCCH.JCCo=@JCCo and JCCH.Job in (@Project1, @Project2)
   	and PMOI.Approved='Y' and PMOI.ApprovedDate<=@ACOThroughDate
   
   /* insert Pending Change Orders */
     insert into #CCPMEstandCO
   	(JCCo,Type,Project,PhaseGroup,Phase,CostType,PCOType,PCO,PCOItem,PCOAmt,ACOFlag,StatusIncludeInProj,TypeIncludeInProj)
   Select JCCH.JCCo,1,JCCH.Job,JCCH.PhaseGroup,JCCH.Phase,JCCH.CostType,PMOL.PCOType,
   	PMOL.PCO,PMOL.PCOItem,PMOL.EstCost,PMOI.Approved,PMSC.IncludeInProj,--Addition made 1/28/02
  	PMDT.IncludeInProj
   from JCCH
   left join PMOL on JCCH.JCCo=PMOL.PMCo and JCCH.Job=PMOL.Project and
   	JCCH.PhaseGroup=PMOL.PhaseGroup and JCCH.Phase=PMOL.Phase and JCCH.CostType=PMOL.CostType
   Left Join PMOI on PMOI.PMCo=JCCH.JCCo and PMOI.Project=JCCH.Job and
   	PMOL.PCOType=PMOI.PCOType and PMOL.PCO=PMOI.PCO and PMOL.PCOItem=PMOI.PCOItem 
   Left join PMSC on PMOI.Status=PMSC.Status/* - Addition made on 1/28/02 by Aghaa */
   Left join PMDT on PMOI.PCOType=PMDT.DocType/*- Addition made on4/3/02 by aghaa*/
   where JCCH.JCCo=@JCCo and JCCH.Job in (@Project1, @Project2)
   	and PMOI.Approved='N' /*and PMOI.ApprovedDate<=@ACOThroughDate*/
   
  
  
  
  
  
    /* select the results */
     select a.JCCo,a.Type,a.Project,a.PhaseGroup,a.Phase,a.CostType,a.OrigEstCost,a.ActualCost,
   	a.RemainCmtdCost,a.TotalCmtdCost,a.ProjCost,
   	a.ACO,a.ACOItem,a.ACOAmt,
   	a.PCOType,a.PCO,a.PCOItem,a.PCOAmt,
   	a.ACOFlag,a.Addon,a.AddonPhase,a.AddonAmount,
          CoName=HQCO.Name, ProjDesc=JCJM.Description,
          PM=JCJM.ProjectMgr,PMName=JCMP.Name,
          Project1=@Project1,
          Project2=@Project2,
          PhaseDesc=JCJP.Description,
      CostTypeDesc=JCCT.Abbreviation,
  ThroughMth=@ThroughMth,
  ACOThroughDate=@ACOThroughDate,
  Plugged=IsNull(JCCH.Plugged,'N'), a.StatusIncludeInProj, a.TypeIncludeInProj
   
        from #CCPMEstandCO a
   
   	Join JCJM on JCJM.JCCo=a.JCCo and JCJM.Job=a.Project 
       JOIN JCJP on JCJP.JCCo=a.JCCo and JCJP.Job=a.Project and
               JCJP.PhaseGroup=a.PhaseGroup and JCJP.Phase=a.Phase  
       Join HQCO on HQCO.HQCo=a.JCCo
       Join JCCT on JCCT.PhaseGroup=a.PhaseGroup and JCCT.CostType=a.CostType 
  	Left Join JCMP on JCMP.JCCo=JCJM.JCCo and JCMP.ProjectMgr=JCJM.ProjectMgr
       Left Join JCCH on a.JCCo=JCCH.JCCo  and a.Project=JCCH.Job  and a.PhaseGroup=JCCH.PhaseGroup  
  	and a.Phase=JCCH.Phase   and a.CostType=JCCH.CostType
  --order by a.Phase
GO
GRANT EXECUTE ON  [dbo].[brptCCPMEstCO] TO [public]
GO
