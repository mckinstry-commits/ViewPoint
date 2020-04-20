SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                     View [dbo].[vrvPRFlash]

/* 7/11/07 - View used on standard report PR Flash Report (Issue 22763). 
	View combines unposted activity from PR Timesheets and JC Cost by Period - JH */
 
as


/*************************************** Phase 1 ******************************************************/

--Payroll - Job Earnings
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), Phase=max(PRRH.Phase1), PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, 
	TotalPRHours=sum(isnull(PRRE.Phase1RegHrs,0) + isnull(Phase1OTHrs,0) + isnull(Phase1DblHrs,0)),
	ProgressUnits=max(isnull(PRRH.Phase1Units,0)), ProgressCT=max(PRRH.Phase1CostType), 
	RegCT=PREC_Reg.JCCostType, OTLaborCT=PREC_OT.JCCostType, DblLaborCT=PREC_Dbl.JCCostType,
	PRAmount=sum(isnull(PRRE.Phase1RegHrs,0) * PRRE.RegRate + isnull(PRRE.Phase1OTHrs,0) * PRRE.OTRate + isnull(PRRE.Phase1DblHrs,0) * PRRE.DblRate),
	EMAmount=0.00, EMUnits=0.00, EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='PR', RecType=1
from PRRH
	left join PRRE on PRRH.PRCo=PRRE.PRCo and PRRH.Crew=PRRE.Crew and PRRH.PostDate=PRRE.PostDate and PRRH.SheetNum=PRRE.SheetNum
	join PRCO on PRRH.PRCo=PRCO.PRCo 
	left join PREC PREC_Reg on PRCO.PRCo=PREC_Reg.PRCo and PRCO.CrewRegEC=PREC_Reg.EarnCode
	left join PREC PREC_OT on PRCO.PRCo=PREC_OT.PRCo and PRCO.CrewOTEC=PREC_OT.EarnCode
	left join PREC PREC_Dbl on PRCO.PRCo=PREC_Dbl.PRCo and PRCO.CrewDblEC=PREC_Dbl.EarnCode
where PRRH.Phase1 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase1,
	PREC_Reg.JCCostType, PREC_OT.JCCostType, PREC_Dbl.JCCostType


union all

--Equipment
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), PRRH.Phase1, PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum,
	TotalPRHours=0.00, ProgressUnits=0.00, ProgressCT=null,
	RegCT=PRRQ.Phase1CType,OTLaborCT=null, DblLaborCT=null,PRAmount=0.00, 
	EMAmount=sum(Phase1Usage*(case when isnull(EMTE.Rate,0)<>0 then EMTE.Rate 
			when isnull(EMTC.Rate,0)<>0 then EMTC.Rate
			when isnull(EMRH.Rate,0)<>0 then EMRH.Rate else EMRR.Rate end)),
	EMUnits=sum(Phase1Usage),EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='EM', RecType=1
from PRRH
	join PRRQ on PRRH.PRCo=PRRQ.PRCo and PRRH.Crew=PRRQ.Crew and PRRH.PostDate=PRRQ.PostDate and PRRH.SheetNum=PRRQ.SheetNum
	left join EMJT on PRRQ.EMCo=EMJT.EMCo and PRRH.JCCo=EMJT.JCCo and PRRH.Job=EMJT.Job
	join EMEM on PRRQ.EMCo=EMEM.EMCo and PRRQ.Equipment=EMEM.Equipment
	left join EMTE on PRRQ.EMCo=EMTE.EMCo and EMJT.RevTemplate=EMTE.RevTemplate and PRRQ.Equipment=EMTE.Equipment and
		PRRQ.Phase1Rev=EMTE.RevCode
	left join EMTC on PRRQ.EMCo=EMTC.EMCo and EMJT.RevTemplate=EMTC.RevTemplate and EMEM.Category=EMTC.Category and PRRQ.Phase1Rev=EMTC.RevCode
	left join EMRH on PRRQ.EMCo=EMRH.EMCo and PRRQ.Equipment=EMRH.Equipment and PRRQ.Phase1Rev=EMRH.RevCode
	left join EMRR on PRRQ.EMCo=EMRR.EMCo and EMEM.Category=EMRR.Category and PRRQ.Phase1Rev=EMRR.RevCode
	
where PRRH.Phase1 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase1,PRRQ.Phase1CType


union all

/*************************************** Phase 2 ******************************************************/

--Payroll - Job Earnings
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), Phase=max(PRRH.Phase2), PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, 
	TotalPRHours=sum(isnull(PRRE.Phase2RegHrs,0) + isnull(Phase2OTHrs,0) + isnull(Phase2DblHrs,0)),
	ProgressUnits=max(isnull(PRRH.Phase2Units,0)), ProgressCT=max(PRRH.Phase2CostType), 
	RegCT=PREC_Reg.JCCostType, OTLaborCT=PREC_OT.JCCostType, DblLaborCT=PREC_Dbl.JCCostType,
	PRAmount=sum(isnull(PRRE.Phase2RegHrs,0) * PRRE.RegRate + isnull(PRRE.Phase2OTHrs,0) * PRRE.OTRate + isnull(PRRE.Phase2DblHrs,0) * PRRE.DblRate),
	EMAmount=0.00, EMUnits=0.00,EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='PR', RecType=2
from PRRH
	left join PRRE on PRRH.PRCo=PRRE.PRCo and PRRH.Crew=PRRE.Crew and PRRH.PostDate=PRRE.PostDate and PRRH.SheetNum=PRRE.SheetNum
	join PRCO on PRRH.PRCo=PRCO.PRCo 
	left join PREC PREC_Reg on PRCO.PRCo=PREC_Reg.PRCo and PRCO.CrewRegEC=PREC_Reg.EarnCode
	left join PREC PREC_OT on PRCO.PRCo=PREC_OT.PRCo and PRCO.CrewOTEC=PREC_OT.EarnCode
	left join PREC PREC_Dbl on PRCO.PRCo=PREC_Dbl.PRCo and PRCO.CrewDblEC=PREC_Dbl.EarnCode
where PRRH.Phase2 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase2,
	PREC_Reg.JCCostType, PREC_OT.JCCostType, PREC_Dbl.JCCostType

union all

--Equipment
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), PRRH.Phase2, PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum,
	TotalPRHours=0.00, ProgressUnits=0.00, ProgressCT=null,
	RegCT=PRRQ.Phase2CType,OTLaborCT=null, DblLaborCT=null,
	PRAmount=0.00,
	EMAmount=sum(Phase2Usage*(case when isnull(EMTE.Rate,0)<>0 then EMTE.Rate 
			when isnull(EMTC.Rate,0)<>0 then EMTC.Rate
			when isnull(EMRH.Rate,0)<>0 then EMRH.Rate else EMRR.Rate end)),
	EMUnits=sum(Phase2Usage),EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='EM', RecType=2
from PRRH
	join PRRQ on PRRH.PRCo=PRRQ.PRCo and PRRH.Crew=PRRQ.Crew and PRRH.PostDate=PRRQ.PostDate and PRRH.SheetNum=PRRQ.SheetNum
	left join EMJT on PRRQ.EMCo=EMJT.EMCo and PRRH.JCCo=EMJT.JCCo and PRRH.Job=EMJT.Job
	join EMEM on PRRQ.EMCo=EMEM.EMCo and PRRQ.Equipment=EMEM.Equipment
	left join EMTE on PRRQ.EMCo=EMTE.EMCo and EMJT.RevTemplate=EMTE.RevTemplate and PRRQ.Equipment=EMTE.Equipment and
		PRRQ.Phase2Rev=EMTE.RevCode
	left join EMTC on PRRQ.EMCo=EMTC.EMCo and EMJT.RevTemplate=EMTC.RevTemplate and EMEM.Category=EMTC.Category and PRRQ.Phase2Rev=EMTC.RevCode
	left join EMRH on PRRQ.EMCo=EMRH.EMCo and PRRQ.Equipment=EMRH.Equipment and PRRQ.Phase2Rev=EMRH.RevCode
	left join EMRR on PRRQ.EMCo=EMRR.EMCo and EMEM.Category=EMRR.Category and PRRQ.Phase2Rev=EMRR.RevCode
	
where PRRH.Phase2 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase2,PRRQ.Phase2CType


union all


/*************************************** Phase 3 ******************************************************/

--Payroll - Job Earnings
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), Phase=max(PRRH.Phase3), PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, 
	TotalPRHours=sum(isnull(PRRE.Phase3RegHrs,0) + isnull(Phase3OTHrs,0) + isnull(Phase3DblHrs,0)),
	ProgressUnits=max(isnull(PRRH.Phase3Units,0)), ProgressCT=max(PRRH.Phase3CostType), 
	RegCT=PREC_Reg.JCCostType, OTLaborCT=PREC_OT.JCCostType, DblLaborCT=PREC_Dbl.JCCostType,
	PRAmount=sum(isnull(PRRE.Phase3RegHrs,0) * PRRE.RegRate + isnull(PRRE.Phase3OTHrs,0) * PRRE.OTRate + isnull(PRRE.Phase3DblHrs,0) * PRRE.DblRate),
	EMAmount=0.00, EMUnits=0.00,EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='PR', RecType=3
from PRRH
	left join PRRE on PRRH.PRCo=PRRE.PRCo and PRRH.Crew=PRRE.Crew and PRRH.PostDate=PRRE.PostDate and PRRH.SheetNum=PRRE.SheetNum
	join PRCO on PRRH.PRCo=PRCO.PRCo 
	left join PREC PREC_Reg on PRCO.PRCo=PREC_Reg.PRCo and PRCO.CrewRegEC=PREC_Reg.EarnCode
	left join PREC PREC_OT on PRCO.PRCo=PREC_OT.PRCo and PRCO.CrewOTEC=PREC_OT.EarnCode
	left join PREC PREC_Dbl on PRCO.PRCo=PREC_Dbl.PRCo and PRCO.CrewDblEC=PREC_Dbl.EarnCode
where PRRH.Phase3 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase3,
	PREC_Reg.JCCostType, PREC_OT.JCCostType, PREC_Dbl.JCCostType

union all

--Equipment
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), PRRH.Phase3, PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum,
	TotalPRHours=0.00, ProgressUnits=0.00, ProgressCT=null,
	RegCT=PRRQ.Phase3CType,OTLaborCT=null, DblLaborCT=null, PRAmount=0.00,
	EMAmount=sum(Phase3Usage*(case when isnull(EMTE.Rate,0)<>0 then EMTE.Rate 
			when isnull(EMTC.Rate,0)<>0 then EMTC.Rate
			when isnull(EMRH.Rate,0)<>0 then EMRH.Rate else EMRR.Rate end)),
	EMUnits=sum(Phase3Usage),EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='EM', RecType=3
from PRRH
	join PRRQ on PRRH.PRCo=PRRQ.PRCo and PRRH.Crew=PRRQ.Crew and PRRH.PostDate=PRRQ.PostDate and PRRH.SheetNum=PRRQ.SheetNum
	left join EMJT on PRRQ.EMCo=EMJT.EMCo and PRRH.JCCo=EMJT.JCCo and PRRH.Job=EMJT.Job
	join EMEM on PRRQ.EMCo=EMEM.EMCo and PRRQ.Equipment=EMEM.Equipment
	left join EMTE on PRRQ.EMCo=EMTE.EMCo and EMJT.RevTemplate=EMTE.RevTemplate and PRRQ.Equipment=EMTE.Equipment and
		PRRQ.Phase3Rev=EMTE.RevCode
	left join EMTC on PRRQ.EMCo=EMTC.EMCo and EMJT.RevTemplate=EMTC.RevTemplate and EMEM.Category=EMTC.Category and PRRQ.Phase3Rev=EMTC.RevCode
	left join EMRH on PRRQ.EMCo=EMRH.EMCo and PRRQ.Equipment=EMRH.Equipment and PRRQ.Phase3Rev=EMRH.RevCode
	left join EMRR on PRRQ.EMCo=EMRR.EMCo and EMEM.Category=EMRR.Category and PRRQ.Phase3Rev=EMRR.RevCode
	
where PRRH.Phase3 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase3,PRRQ.Phase3CType


union all

--Job Cost

/*************************************** Phase 4 ******************************************************/

--Payroll - Job Earnings
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), Phase=max(PRRH.Phase4), PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, 
	TotalPRHours=sum(isnull(PRRE.Phase4RegHrs,0) + isnull(Phase4OTHrs,0) + isnull(Phase4DblHrs,0)),
	ProgressUnits=max(isnull(PRRH.Phase4Units,0)), ProgressCT=max(PRRH.Phase4CostType), 
	RegCT=PREC_Reg.JCCostType, OTLaborCT=PREC_OT.JCCostType, DblLaborCT=PREC_Dbl.JCCostType,
	PRAmount=sum(isnull(PRRE.Phase4RegHrs,0) * PRRE.RegRate + isnull(PRRE.Phase4OTHrs,0) * PRRE.OTRate + isnull(PRRE.Phase4DblHrs,0) * PRRE.DblRate),
	EMAmount=0.00, EMUnits=0.00,EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='PR', RecType=4
from PRRH
	left join PRRE on PRRH.PRCo=PRRE.PRCo and PRRH.Crew=PRRE.Crew and PRRH.PostDate=PRRE.PostDate and PRRH.SheetNum=PRRE.SheetNum
	join PRCO on PRRH.PRCo=PRCO.PRCo 
	left join PREC PREC_Reg on PRCO.PRCo=PREC_Reg.PRCo and PRCO.CrewRegEC=PREC_Reg.EarnCode
	left join PREC PREC_OT on PRCO.PRCo=PREC_OT.PRCo and PRCO.CrewOTEC=PREC_OT.EarnCode
	left join PREC PREC_Dbl on PRCO.PRCo=PREC_Dbl.PRCo and PRCO.CrewDblEC=PREC_Dbl.EarnCode
where PRRH.Phase4 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase4,
	PREC_Reg.JCCostType, PREC_OT.JCCostType, PREC_Dbl.JCCostType

union all

--Equipment
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), PRRH.Phase4, PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum,
	TotalPRHours=0.00, ProgressUnits=0.00, ProgressCT=null,
	RegCT=PRRQ.Phase4CType,OTLaborCT=null, DblLaborCT=null, PRAmount=0.00,
	EMAmount=sum(Phase4Usage*(case when isnull(EMTE.Rate,0)<>0 then EMTE.Rate 
			when isnull(EMTC.Rate,0)<>0 then EMTC.Rate
			when isnull(EMRH.Rate,0)<>0 then EMRH.Rate else EMRR.Rate end)),
	EMUnits=sum(Phase4Usage),EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='EM', RecType=4
from PRRH
	join PRRQ on PRRH.PRCo=PRRQ.PRCo and PRRH.Crew=PRRQ.Crew and PRRH.PostDate=PRRQ.PostDate and PRRH.SheetNum=PRRQ.SheetNum
	left join EMJT on PRRQ.EMCo=EMJT.EMCo and PRRH.JCCo=EMJT.JCCo and PRRH.Job=EMJT.Job
	join EMEM on PRRQ.EMCo=EMEM.EMCo and PRRQ.Equipment=EMEM.Equipment
	left join EMTE on PRRQ.EMCo=EMTE.EMCo and EMJT.RevTemplate=EMTE.RevTemplate and PRRQ.Equipment=EMTE.Equipment and
		PRRQ.Phase4Rev=EMTE.RevCode
	left join EMTC on PRRQ.EMCo=EMTC.EMCo and EMJT.RevTemplate=EMTC.RevTemplate and EMEM.Category=EMTC.Category and PRRQ.Phase4Rev=EMTC.RevCode
	left join EMRH on PRRQ.EMCo=EMRH.EMCo and PRRQ.Equipment=EMRH.Equipment and PRRQ.Phase4Rev=EMRH.RevCode
	left join EMRR on PRRQ.EMCo=EMRR.EMCo and EMEM.Category=EMRR.Category and PRRQ.Phase4Rev=EMRR.RevCode
	
where PRRH.Phase4 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase4,PRRQ.Phase4CType


union all

/*************************************** Phase 5 ******************************************************/

--Payroll - Job Earnings
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), Phase=max(PRRH.Phase5), PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, 
	TotalPRHours=sum(isnull(PRRE.Phase5RegHrs,0) + isnull(Phase5OTHrs,0) + isnull(Phase5DblHrs,0)),
	ProgressUnits=max(isnull(PRRH.Phase5Units,0)), ProgressCT=max(PRRH.Phase5CostType), 
	RegCT=PREC_Reg.JCCostType, OTLaborCT=PREC_OT.JCCostType, DblLaborCT=PREC_Dbl.JCCostType,
	PRAmount=sum(isnull(PRRE.Phase5RegHrs,0) * PRRE.RegRate + isnull(PRRE.Phase5OTHrs,0) * PRRE.OTRate + isnull(PRRE.Phase5DblHrs,0) * PRRE.DblRate),
	EMAmount=0.00, EMUnits=0.00,EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='PR', RecType=5
from PRRH
	left join PRRE on PRRH.PRCo=PRRE.PRCo and PRRH.Crew=PRRE.Crew and PRRH.PostDate=PRRE.PostDate and PRRH.SheetNum=PRRE.SheetNum
	join PRCO on PRRH.PRCo=PRCO.PRCo 
	left join PREC PREC_Reg on PRCO.PRCo=PREC_Reg.PRCo and PRCO.CrewRegEC=PREC_Reg.EarnCode
	left join PREC PREC_OT on PRCO.PRCo=PREC_OT.PRCo and PRCO.CrewOTEC=PREC_OT.EarnCode
	left join PREC PREC_Dbl on PRCO.PRCo=PREC_Dbl.PRCo and PRCO.CrewDblEC=PREC_Dbl.EarnCode
where PRRH.Phase5 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase5,
	PREC_Reg.JCCostType, PREC_OT.JCCostType, PREC_Dbl.JCCostType

union all

--Equipment
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), PRRH.Phase5, PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum,
	TotalPRHours=0.00, ProgressUnits=0.00, ProgressCT=null,
	RegCT=PRRQ.Phase5CType,OTLaborCT=null, DblLaborCT=null,PRAmount=0.00,
	EMAmount=sum(Phase5Usage*(case when isnull(EMTE.Rate,0)<>0 then EMTE.Rate 
			when isnull(EMTC.Rate,0)<>0 then EMTC.Rate
			when isnull(EMRH.Rate,0)<>0 then EMRH.Rate else EMRR.Rate end)),
	EMUnits=sum(Phase5Usage),EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='EM', RecType=5
from PRRH
	join PRRQ on PRRH.PRCo=PRRQ.PRCo and PRRH.Crew=PRRQ.Crew and PRRH.PostDate=PRRQ.PostDate and PRRH.SheetNum=PRRQ.SheetNum
	left join EMJT on PRRQ.EMCo=EMJT.EMCo and PRRH.JCCo=EMJT.JCCo and PRRH.Job=EMJT.Job
	join EMEM on PRRQ.EMCo=EMEM.EMCo and PRRQ.Equipment=EMEM.Equipment
	left join EMTE on PRRQ.EMCo=EMTE.EMCo and EMJT.RevTemplate=EMTE.RevTemplate and PRRQ.Equipment=EMTE.Equipment and
		PRRQ.Phase5Rev=EMTE.RevCode
	left join EMTC on PRRQ.EMCo=EMTC.EMCo and EMJT.RevTemplate=EMTC.RevTemplate and EMEM.Category=EMTC.Category and PRRQ.Phase5Rev=EMTC.RevCode
	left join EMRH on PRRQ.EMCo=EMRH.EMCo and PRRQ.Equipment=EMRH.Equipment and PRRQ.Phase5Rev=EMRH.RevCode
	left join EMRR on PRRQ.EMCo=EMRR.EMCo and EMEM.Category=EMRR.Category and PRRQ.Phase5Rev=EMRR.RevCode
	
where PRRH.Phase5 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase5,PRRQ.Phase5CType


union all

/*************************************** Phase 6 ******************************************************/

--Payroll - Job Earnings
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), Phase=max(PRRH.Phase6), PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, 
	TotalPRHours=sum(isnull(PRRE.Phase6RegHrs,0) + isnull(Phase6OTHrs,0) + isnull(Phase6DblHrs,0)),
	ProgressUnits=max(isnull(PRRH.Phase6Units,0)), ProgressCT=max(PRRH.Phase6CostType), 
	RegCT=PREC_Reg.JCCostType, OTLaborCT=PREC_OT.JCCostType, DblLaborCT=PREC_Dbl.JCCostType,
	PRAmount=sum(isnull(PRRE.Phase6RegHrs,0) * PRRE.RegRate + isnull(PRRE.Phase6OTHrs,0) * PRRE.OTRate + isnull(PRRE.Phase6DblHrs,0) * PRRE.DblRate),
	EMAmount=0.00, EMUnits=0.00,EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='PR', RecType=6
from PRRH
	left join PRRE on PRRH.PRCo=PRRE.PRCo and PRRH.Crew=PRRE.Crew and PRRH.PostDate=PRRE.PostDate and PRRH.SheetNum=PRRE.SheetNum
	join PRCO on PRRH.PRCo=PRCO.PRCo 
	left join PREC PREC_Reg on PRCO.PRCo=PREC_Reg.PRCo and PRCO.CrewRegEC=PREC_Reg.EarnCode
	left join PREC PREC_OT on PRCO.PRCo=PREC_OT.PRCo and PRCO.CrewOTEC=PREC_OT.EarnCode
	left join PREC PREC_Dbl on PRCO.PRCo=PREC_Dbl.PRCo and PRCO.CrewDblEC=PREC_Dbl.EarnCode
where PRRH.Phase6 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase6,
	PREC_Reg.JCCostType, PREC_OT.JCCostType, PREC_Dbl.JCCostType

union all

--Equipment
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), PRRH.Phase6, PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum,
	TotalPRHours=0.00, ProgressUnits=0.00, ProgressCT=null,
	RegCT=PRRQ.Phase6CType,OTLaborCT=null, DblLaborCT=null, PRAmount=0.00,
	EMAmount=sum(Phase6Usage*(case when isnull(EMTE.Rate,0)<>0 then EMTE.Rate 
			when isnull(EMTC.Rate,0)<>0 then EMTC.Rate
			when isnull(EMRH.Rate,0)<>0 then EMRH.Rate else EMRR.Rate end)),
	EMUnits=sum(Phase6Usage),EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='EM', RecType=6
from PRRH
	join PRRQ on PRRH.PRCo=PRRQ.PRCo and PRRH.Crew=PRRQ.Crew and PRRH.PostDate=PRRQ.PostDate and PRRH.SheetNum=PRRQ.SheetNum
	left join EMJT on PRRQ.EMCo=EMJT.EMCo and PRRH.JCCo=EMJT.JCCo and PRRH.Job=EMJT.Job
	join EMEM on PRRQ.EMCo=EMEM.EMCo and PRRQ.Equipment=EMEM.Equipment
	left join EMTE on PRRQ.EMCo=EMTE.EMCo and EMJT.RevTemplate=EMTE.RevTemplate and PRRQ.Equipment=EMTE.Equipment and
		PRRQ.Phase6Rev=EMTE.RevCode
	left join EMTC on PRRQ.EMCo=EMTC.EMCo and EMJT.RevTemplate=EMTC.RevTemplate and EMEM.Category=EMTC.Category and PRRQ.Phase6Rev=EMTC.RevCode
	left join EMRH on PRRQ.EMCo=EMRH.EMCo and PRRQ.Equipment=EMRH.Equipment and PRRQ.Phase6Rev=EMRH.RevCode
	left join EMRR on PRRQ.EMCo=EMRR.EMCo and EMEM.Category=EMRR.Category and PRRQ.Phase6Rev=EMRR.RevCode
	
where PRRH.Phase6 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase6,PRRQ.Phase6CType


union all
/*************************************** Phase 7 ******************************************************/

--Payroll - Job Earnings
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), Phase=max(PRRH.Phase7), PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, 
	TotalPRHours=sum(isnull(PRRE.Phase7RegHrs,0) + isnull(Phase7OTHrs,0) + isnull(Phase7DblHrs,0)),
	ProgressUnits=max(isnull(PRRH.Phase7Units,0)), ProgressCT=max(PRRH.Phase7CostType), 
	RegCT=PREC_Reg.JCCostType, OTLaborCT=PREC_OT.JCCostType, DblLaborCT=PREC_Dbl.JCCostType,
	PRAmount=sum(isnull(PRRE.Phase7RegHrs,0) * PRRE.RegRate + isnull(PRRE.Phase7OTHrs,0) * PRRE.OTRate + isnull(PRRE.Phase7DblHrs,0) * PRRE.DblRate),
	EMAmount=0.00, EMUnits=0.00,EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='PR', RecType=7
from PRRH
	left join PRRE on PRRH.PRCo=PRRE.PRCo and PRRH.Crew=PRRE.Crew and PRRH.PostDate=PRRE.PostDate and PRRH.SheetNum=PRRE.SheetNum
	join PRCO on PRRH.PRCo=PRCO.PRCo 
	left join PREC PREC_Reg on PRCO.PRCo=PREC_Reg.PRCo and PRCO.CrewRegEC=PREC_Reg.EarnCode
	left join PREC PREC_OT on PRCO.PRCo=PREC_OT.PRCo and PRCO.CrewOTEC=PREC_OT.EarnCode
	left join PREC PREC_Dbl on PRCO.PRCo=PREC_Dbl.PRCo and PRCO.CrewDblEC=PREC_Dbl.EarnCode
where PRRH.Phase7 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase7,
	PREC_Reg.JCCostType, PREC_OT.JCCostType, PREC_Dbl.JCCostType

union all

--Equipment
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), PRRH.Phase7, PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum,
	TotalPRHours=0.00, ProgressUnits=0.00, ProgressCT=null,
	RegCT=PRRQ.Phase7CType,OTLaborCT=null, DblLaborCT=null,PRAmount=0.00, 
	EMAmount=sum(Phase7Usage*(case when isnull(EMTE.Rate,0)<>0 then EMTE.Rate 
			when isnull(EMTC.Rate,0)<>0 then EMTC.Rate
			when isnull(EMRH.Rate,0)<>0 then EMRH.Rate else EMRR.Rate end)),
	EMUnits=sum(Phase7Usage),EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='EM', RecType=7
from PRRH
	join PRRQ on PRRH.PRCo=PRRQ.PRCo and PRRH.Crew=PRRQ.Crew and PRRH.PostDate=PRRQ.PostDate and PRRH.SheetNum=PRRQ.SheetNum
	left join EMJT on PRRQ.EMCo=EMJT.EMCo and PRRH.JCCo=EMJT.JCCo and PRRH.Job=EMJT.Job
	join EMEM on PRRQ.EMCo=EMEM.EMCo and PRRQ.Equipment=EMEM.Equipment
	left join EMTE on PRRQ.EMCo=EMTE.EMCo and EMJT.RevTemplate=EMTE.RevTemplate and PRRQ.Equipment=EMTE.Equipment and
		PRRQ.Phase7Rev=EMTE.RevCode
	left join EMTC on PRRQ.EMCo=EMTC.EMCo and EMJT.RevTemplate=EMTC.RevTemplate and EMEM.Category=EMTC.Category and PRRQ.Phase7Rev=EMTC.RevCode
	left join EMRH on PRRQ.EMCo=EMRH.EMCo and PRRQ.Equipment=EMRH.Equipment and PRRQ.Phase7Rev=EMRH.RevCode
	left join EMRR on PRRQ.EMCo=EMRR.EMCo and EMEM.Category=EMRR.Category and PRRQ.Phase7Rev=EMRR.RevCode
	
where PRRH.Phase7 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase7,PRRQ.Phase7CType


union all

/*************************************** Phase 8 ******************************************************/

--Payroll - Job Earnings
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), Phase=max(PRRH.Phase8), PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, 
	TotalPRHours=sum(isnull(PRRE.Phase8RegHrs,0) + isnull(Phase8OTHrs,0) + isnull(Phase8DblHrs,0)),
	ProgressUnits=max(isnull(PRRH.Phase8Units,0)), ProgressCT=max(PRRH.Phase8CostType), 
	RegCT=PREC_Reg.JCCostType, OTLaborCT=PREC_OT.JCCostType, DblLaborCT=PREC_Dbl.JCCostType,
	PRAmount=sum(isnull(PRRE.Phase8RegHrs,0) * PRRE.RegRate + isnull(PRRE.Phase8OTHrs,0) * PRRE.OTRate + isnull(PRRE.Phase8DblHrs,0) * PRRE.DblRate),
	EMAmount=0.00, EMUnits=0.00,EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='PR', RecType=8
from PRRH
	left join PRRE on PRRH.PRCo=PRRE.PRCo and PRRH.Crew=PRRE.Crew and PRRH.PostDate=PRRE.PostDate and PRRH.SheetNum=PRRE.SheetNum
	join PRCO on PRRH.PRCo=PRCO.PRCo 
	left join PREC PREC_Reg on PRCO.PRCo=PREC_Reg.PRCo and PRCO.CrewRegEC=PREC_Reg.EarnCode
	left join PREC PREC_OT on PRCO.PRCo=PREC_OT.PRCo and PRCO.CrewOTEC=PREC_OT.EarnCode
	left join PREC PREC_Dbl on PRCO.PRCo=PREC_Dbl.PRCo and PRCO.CrewDblEC=PREC_Dbl.EarnCode
where PRRH.Phase8 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase8,
	PREC_Reg.JCCostType, PREC_OT.JCCostType, PREC_Dbl.JCCostType

union all

--Equipment
select JCCo=max(PRRH.JCCo), Job=max(PRRH.Job), PRRH.Phase8, PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum,
	TotalPRHours=0.00, ProgressUnits=0.00, ProgressCT=null,
	RegCT=PRRQ.Phase8CType,OTLaborCT=null, DblLaborCT=null,PRAmount=0.00, 
	EMAmount=sum(Phase8Usage*(case when isnull(EMTE.Rate,0)<>0 then EMTE.Rate 
			when isnull(EMTC.Rate,0)<>0 then EMTC.Rate
			when isnull(EMRH.Rate,0)<>0 then EMRH.Rate else EMRR.Rate end)),
	EMUnits=sum(Phase8Usage),EstQty=0.00,
	EstUnits=0.00, EstHours=0.00, EstCost=0.00, UM=null, 
	TimesheetStatus=max(PRRH.Status), Type='EM', RecType=8
from PRRH
	join PRRQ on PRRH.PRCo=PRRQ.PRCo and PRRH.Crew=PRRQ.Crew and PRRH.PostDate=PRRQ.PostDate and PRRH.SheetNum=PRRQ.SheetNum
	left join EMJT on PRRQ.EMCo=EMJT.EMCo and PRRH.JCCo=EMJT.JCCo and PRRH.Job=EMJT.Job
	join EMEM on PRRQ.EMCo=EMEM.EMCo and PRRQ.Equipment=EMEM.Equipment
	left join EMTE on PRRQ.EMCo=EMTE.EMCo and EMJT.RevTemplate=EMTE.RevTemplate and PRRQ.Equipment=EMTE.Equipment and
		PRRQ.Phase8Rev=EMTE.RevCode
	left join EMTC on PRRQ.EMCo=EMTC.EMCo and EMJT.RevTemplate=EMTC.RevTemplate and EMEM.Category=EMTC.Category and PRRQ.Phase8Rev=EMTC.RevCode
	left join EMRH on PRRQ.EMCo=EMRH.EMCo and PRRQ.Equipment=EMRH.Equipment and PRRQ.Phase8Rev=EMRH.RevCode
	left join EMRR on PRRQ.EMCo=EMRR.EMCo and EMEM.Category=EMRR.Category and PRRQ.Phase8Rev=EMRR.RevCode
	
where PRRH.Phase8 is not null
group by PRRH.PRCo, PRRH.Crew, PRRH.PostDate, PRRH.SheetNum, PRRH.Phase8,PRRQ.Phase8CType


/*************************************** Job Cost Estimated Amounts******************************************************/
union all

select JCCo=JCCP.JCCo, Job=JCCP.Job, Phase=JCCP.Phase, PRCo=null, Crew=null, PostDate='1/1/1950', SheetNum=null, 
	TotalPRHours=0.00,
	ProgressUnits=0.00, ProgressCT=null,
	RegCT=JCCP.CostType, OTLaborCT=null, DblLaborCT=null,
	PRAmount=0.00, EMAmount=0.00, EMUnits=0.00,
	EstQty=sum(case when JCCH.PhaseUnitFlag='Y' then  JCCP.CurrEstUnits else 0 end),
	EstUnits=sum(JCCP.CurrEstUnits),
	EstHours=sum(JCCP.CurrEstHours), 
	EstCost=sum(JCCP.CurrEstCost), UM=JCCH.UM, 
	TimesheetStatus=null, Type='JC', RecType=7
from JCCP
	join JCCH on JCCP.JCCo=JCCH.JCCo and JCCP.Job=JCCH.Job and JCCP.PhaseGroup=JCCH.PhaseGroup and JCCP.Phase=JCCH.Phase and JCCP.CostType=JCCH.CostType
	join (select distinct JCCo, Job from PRRH) as PRRH on JCCP.JCCo=PRRH.JCCo and JCCP.Job=PRRH.Job 
group by JCCP.JCCo, JCCP.Job, JCCP.Phase, JCCP.CostType, JCCH.UM

GO
GRANT SELECT ON  [dbo].[vrvPRFlash] TO [public]
GRANT INSERT ON  [dbo].[vrvPRFlash] TO [public]
GRANT DELETE ON  [dbo].[vrvPRFlash] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRFlash] TO [public]
GRANT SELECT ON  [dbo].[vrvPRFlash] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPRFlash] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPRFlash] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPRFlash] TO [Viewpoint]
GO
