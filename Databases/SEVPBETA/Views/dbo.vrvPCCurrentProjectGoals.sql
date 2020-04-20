SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE View [dbo].[vrvPCCurrentProjectGoals]

/**************
 Created:  09/24/10 HH
 Modified:
 
 Usage:
 
 
*************/
 
as



SELECT JM.JCCo
		,JM.Job	
		,CM.Contract	
		,PPC.PotentialProject	
		,PPC.VendorGroup	
		,PPC.CertificateType

 FROM JCJM JM
INNER JOIN JCCM CM 
	ON CM.Contract = JM.Contract
	AND CM.JCCo = JM.JCCo
INNER JOIN PCPotentialWork PW 
	ON PW.PotentialProject = CM.PotentialProject 
	AND CM.JCCo = PW.JCCo
INNER JOIN PCPotentialProjectCertificate PPC 
	ON PPC.PotentialProject = CM.PotentialProject 
	AND PPC.JCCo = CM.JCCo 

GO
GRANT SELECT ON  [dbo].[vrvPCCurrentProjectGoals] TO [public]
GRANT INSERT ON  [dbo].[vrvPCCurrentProjectGoals] TO [public]
GRANT DELETE ON  [dbo].[vrvPCCurrentProjectGoals] TO [public]
GRANT UPDATE ON  [dbo].[vrvPCCurrentProjectGoals] TO [public]
GO
