SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  view [dbo].[brvJCContrMinJob]
/***
 CREATED:  ??
 MODIFIED:  5/2/2011  DH.  Added ArchContact for use in Document Templates (TK-04411).
 
 USAGE:  View is used to select the first job assigned to a contract in order to 
		 return Project Manager and Architect by contract for use in Viewpoint reports.  If more
		 than one project manager and/or architect exist on multiple jobs assigned to a contract,
		 this view will only return the project manager and architect on the first job (job with the lowest number)
		 assigned to that contract.
		 
******/		 


 as Select    a.JCCo
			, a.Contract
			, VendorGroup = c.VendorGroup
			, ArchEngFirm = c.ArchEngFirm
			, c.ContactCode as ArchContact
			, Job = b.MinJob
			, c.ProjectMgr
       FROM JCCM a WITH (NOLOCK)
       LEFT JOIN (Select JCCo, Contract, MinJob=Min(Job) From JCJM With (NoLock)
					 Group By JCCo, Contract) As b
          On a.JCCo = b.JCCo
             and a.Contract = b.Contract 
       LEFT JOIN JCJM c on c.JCCo=b.JCCo and c.Job=b.MinJob



GO
GRANT SELECT ON  [dbo].[brvJCContrMinJob] TO [public]
GRANT INSERT ON  [dbo].[brvJCContrMinJob] TO [public]
GRANT DELETE ON  [dbo].[brvJCContrMinJob] TO [public]
GRANT UPDATE ON  [dbo].[brvJCContrMinJob] TO [public]
GO
