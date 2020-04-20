SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viFact_JCCompanySecureUsers]

/****
 Created:  11/22/2010 DH
 Modified:
 
 Usage:  View returns JC Company Key ID's for each user
         for the JCCompanyUser security measure group.  Allows
         filtering of dimension data when job cost company data security
         is implemented.
         
         
********/         

as 

select   u.WindowsUserName /**Windows User Name required for Analysis Services security*/
	   , j.KeyID as JCCoID
	   
From vDDDU d
Join bJCCO j on j.JCCo = cast (d.Instance as tinyint)
Join vDDUP u on u.VPUserName = d.VPUserName
Join vDDBICompanies on vDDBICompanies.Co = j.JCCo
Where d.Datatype='bJCCo' and u.WindowsUserName is not null

GO
GRANT SELECT ON  [dbo].[viFact_JCCompanySecureUsers] TO [public]
GRANT INSERT ON  [dbo].[viFact_JCCompanySecureUsers] TO [public]
GRANT DELETE ON  [dbo].[viFact_JCCompanySecureUsers] TO [public]
GRANT UPDATE ON  [dbo].[viFact_JCCompanySecureUsers] TO [public]
GO
