SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE view [dbo].[viFact_PMCompliance]
as

with PMCompliance
(POCo,
JCCo,
Project,
ProjMgr,
PO_ID,
SL_ID,
POAndDescription,
SLAndDescription,
CompCode,
Seq,
VendorGroup,
Vendor,
--VendorName,
CompCodeSeqDescription,
ExpDate,
Days,
Type,
TypeNumber, /*1 for PO, 2 for SL*/	
Complied,
CompType,
Verify) 

as

(Select bPOCT.POCo, bPOHD.JCCo, bPOHD.Job as Project, bJCJM.ProjectMgr as ProjMgr,
 bPOHD.KeyID as PO_ID, Null as SL_ID, bPOCT.PO +' '+isnull(bPOHD.Description,'') as POAndDescription,
 Null as SLAndDescription, bPOCT.CompCode as CompCode, bPOCT.Seq as Seq, 
 bPOCT.VendorGroup, bPOCT.Vendor as Vendor, /*bAPVM.Name as VendorName,*/  bPOCT.Description as CompCodeSeqDescription, 
 bPOCT.ExpDate, 
 Case when bPOCT.Verify='Y' and bHQCP.CompType='D' then DateDiff(day,  bPOCT.ExpDate, GetDate()) else Null end as 'Days',
 'PO' as Type, 
  1 as TypeNumber,	
  case when isnull(DateDiff(day,  bPOCT.ExpDate, GetDate()),0)>=0 or 
       (bPOCT.Verify='Y' and (bPOCT.Complied <>'Y' or bPOCT.Complied is null) or
       (bPOCT.Verify='Y' and bPOCT.ExpDate is null and bPOCT.Complied='N')) then 'N' else 'Y' end as Complied, bHQCP.CompType as CompType,
  bPOCT.Verify
 
from bPOCT With (nolock)
Inner join bPOHD With (nolock) on bPOCT.POCo=bPOHD.POCo and bPOCT.PO=bPOHD.PO
left outer Join bJCJM With (nolock) on bPOHD.POCo=bJCJM.JCCo and bPOHD.Job=bJCJM.Job
--left outer Join bAPVM  on bPOCT.POCo=bAPVM.VendorGroup and bPOCT.Vendor=bAPVM.Vendor
inner join bHQCP With (nolock) on bPOCT.CompCode=bHQCP.CompCode

-- where (case when bHQCP.CompType = 'D' then isnull(bPOCT.ExpDate,'1/1/1950') end) <=GetDate()
  --or bPOCT.Complied = 'N'

union all

select  bSLCT.SLCo, bSLHD.JCCo, bSLHD.Job as Project, bJCJM.ProjectMgr as ProjMgr,
Null as PO_ID, bSLHD.KeyID as SL_ID, Null as POAndDescription, bSLCT.SL + ' '+ isnull(bSLHD.Description,'') as SLAndDescription,
bSLCT.CompCode, bSLCT.Seq, bSLCT.VendorGroup, bSLCT.Vendor, /*bAPVM.Name,*/  bSLCT.Description as CompCodeSeqDescription, 
bSLCT.ExpDate, 
Case when bSLCT.Verify='Y' and bHQCP.CompType='D' then DateDiff(day, bSLCT.ExpDate, GetDate() )  else Null end as 'Days',
 'SL' as Type,
 2 as TypeNumber,
 case when isnull(DateDiff(day,  bSLCT.ExpDate, GetDate()),0)>=0 or 
       (bSLCT.Verify='Y' and (bSLCT.Complied <>'Y' or bSLCT.Complied is null) or
       (bSLCT.Verify='Y' and bSLCT.ExpDate is null and bSLCT.Complied='N')) then 'N' else 'Y' end as Complied, bHQCP.CompType,
bSLCT.Verify


from bSLCT With (nolock)
inner join bSLHD With (nolock) on bSLCT.SLCo=bSLHD.SLCo and bSLCT.SL=bSLHD.SL
left outer join bJCJM With (nolock) on bSLHD.SLCo=bJCJM.JCCo and bSLHD.Job=bJCJM.Job 
--left outer join bAPVM on bSLCT.VendorGroup=bAPVM.VendorGroup and bSLCT.Vendor=bAPVM.Vendor
inner join bHQCP With (nolock) on bSLCT.CompCode=bHQCP.CompCode

--where
--(case when bHQCP.CompType = 'D' then isnull(bSLCT.ExpDate,'1/1/1950') end) <= GetDate()  or bSLCT.Complied = 'N'
)

Select   bHQCO.KeyID as POCoID
        ,bPMCO.KeyID as PMCoID
        ,bJCJM.KeyID as JobID
        ,bJCMP.KeyID as ProjMgrID
	    ,P.PO_ID
        ,P.POAndDescription
		,P.SL_ID
		,P.SLAndDescription
		,Case when P.Type='PO' then
		           Cast(cast(P.TypeNumber as varchar(3))+cast(P.PO_ID as varchar(16)) as bigint)
              when P.Type='SL' then
					Cast(cast(P.TypeNumber as varchar(3))+cast(P.SL_ID as varchar(16)) as bigint)
         End as SL_PO
		,Case when P.Type='SL' then P.SLAndDescription 
			  when P.Type='PO' then P.POAndDescription
         End as SL_PODescription
		,bHQCP.KeyID as CompCodeID
        ,P.CompCode
		,bHQCP.Description as CompCodeDescription
        ,P.Seq
		,bAPVM.KeyID as VendorID
        ,P.CompCodeSeqDescription
        ,P.ExpDate
		,P.Days
		,P.Type
		,P.Complied
		,viDim_PMProjectMgrJobs.PMJobID
		,P.CompType
		,P.Verify
		,Row_Number() Over (Order by P.POCo, P.CompCode, P.Type, P.PO_ID, P.SL_ID, P.Seq) as CompCodeSeqID


from PMCompliance P
Join vDDBICompanies on vDDBICompanies.Co=P.JCCo
Inner Join bPMCO With (nolock) on P.JCCo=bPMCO.PMCo
Inner Join bHQCO With (nolock) on P.POCo=bHQCO.HQCo
inner join bHQCP With (nolock) on P.CompCode=bHQCP.CompCode
left outer /*inner*/ Join bJCJM on P.POCo=bJCJM.JCCo and P.Project=bJCJM.Job
inner Join bJCMP With (nolock) on P.POCo=bJCMP.JCCo and P.ProjMgr=bJCMP.ProjectMgr
inner join viDim_PMProjectMgrJobs on P.JCCo=viDim_PMProjectMgrJobs.JCCo and P.ProjMgr=viDim_PMProjectMgrJobs.ProjectMgr 
     and P.Project=viDim_PMProjectMgrJobs.Job
left outer join bAPVM With (nolock) on bAPVM.VendorGroup=P.VendorGroup and bAPVM.Vendor=P.Vendor



GO
GRANT SELECT ON  [dbo].[viFact_PMCompliance] TO [public]
GRANT INSERT ON  [dbo].[viFact_PMCompliance] TO [public]
GRANT DELETE ON  [dbo].[viFact_PMCompliance] TO [public]
GRANT UPDATE ON  [dbo].[viFact_PMCompliance] TO [public]
GRANT SELECT ON  [dbo].[viFact_PMCompliance] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viFact_PMCompliance] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viFact_PMCompliance] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viFact_PMCompliance] TO [Viewpoint]
GO
