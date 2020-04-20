SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PCPotentialProjectCertificate] as select a.* From vPCPotentialProjectCertificate a
GO
GRANT SELECT ON  [dbo].[PCPotentialProjectCertificate] TO [public]
GRANT INSERT ON  [dbo].[PCPotentialProjectCertificate] TO [public]
GRANT DELETE ON  [dbo].[PCPotentialProjectCertificate] TO [public]
GRANT UPDATE ON  [dbo].[PCPotentialProjectCertificate] TO [public]
GO
