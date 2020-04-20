SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[PMContractManagers]
/***
 CREATED:   5/2/2011 DH.
 MODIFIED:  
 
 USAGE:  View is used to select the first job assigned to a contract in order to 
		 return Project Manager and Architect by contract for use in Viewpoint document templates.  If more
		 than one project manager and/or architect exist on multiple jobs assigned to a contract,
		 this view will only return the project manager and architect on the first job (job with the lowest number)
		 assigned to that contract.  View is similar to the brvJCContrMinJob used for reports except that it returns
		 only contracts with assiged jobs (Inner joins instead of left outer).
		 
******/		 


 as Select    a.JCCo
			, a.Contract
			, FirstJob = b.MinJob
			, VendorGroup = c.VendorGroup
			, ArchEngFirm = c.ArchEngFirm
			, c.ContactCode as ArchContact
			, c.ProjectMgr
       FROM JCCM a WITH (NOLOCK)
       INNER JOIN (Select JCCo, Contract, MinJob=Min(Job) From JCJM With (NoLock)
					 Group By JCCo, Contract) As b
          ON   a.JCCo = b.JCCo
               and a.Contract = b.Contract 
       INNER JOIN JCJM c on c.JCCo=b.JCCo and c.Job=b.MinJob



GO
GRANT SELECT ON  [dbo].[PMContractManagers] TO [public]
GRANT INSERT ON  [dbo].[PMContractManagers] TO [public]
GRANT DELETE ON  [dbo].[PMContractManagers] TO [public]
GRANT UPDATE ON  [dbo].[PMContractManagers] TO [public]
GO
