SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[viDim_JCJob]

/**************************************************
 * Alterd: DH 3/17/08
 * Modified:      
 * Usage:  Dimension View from Job Master for use in SSAS Cubes. 
 *
 *
 ********************************************************/
--Add Unassigned record
as

select   bJCJM.KeyID as JobID
		,bJCCO.KeyID as JCCoID
		,bHQCO.Name as CompanyName
        ,bJCJM.Job
        ,bJCJM.Description
		,bJCJM.Job +' '+ Description as JobAndDescription
        ,bJCJM.Contract
        ,case when bJCJM.JobStatus=1 then 'Open'
			 when bJCJM.JobStatus=2 then 'Soft Closed'
			 when bJCJM.JobStatus=3 then 'Closed'
			 when bJCJM.JobStatus=0 then 'Pending'
		end as JobStatus,
        bJCJM.MailState,
        bJCJM.MailCountry

From bJCJM
Join bJCCO on bJCCO.JCCo=bJCJM.JCCo
Join bHQCO on bHQCO.HQCo=bJCJM.JCCo
Join vDDBICompanies on vDDBICompanies.Co=bJCJM.JCCo


union All
Select  0,
		0,		
	   'Unassigned' ,
		null,
		null,
		null,
		null,
		null,
		null,
		null

GO
GRANT SELECT ON  [dbo].[viDim_JCJob] TO [public]
GRANT INSERT ON  [dbo].[viDim_JCJob] TO [public]
GRANT DELETE ON  [dbo].[viDim_JCJob] TO [public]
GRANT UPDATE ON  [dbo].[viDim_JCJob] TO [public]
GRANT SELECT ON  [dbo].[viDim_JCJob] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_JCJob] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_JCJob] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_JCJob] TO [Viewpoint]
GO
