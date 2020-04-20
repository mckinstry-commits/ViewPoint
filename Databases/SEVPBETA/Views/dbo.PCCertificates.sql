SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[PCCertificates]
AS


SELECT a.* FROM dbo.vPCCertificates a



GO
GRANT SELECT ON  [dbo].[PCCertificates] TO [public]
GRANT INSERT ON  [dbo].[PCCertificates] TO [public]
GRANT DELETE ON  [dbo].[PCCertificates] TO [public]
GRANT UPDATE ON  [dbo].[PCCertificates] TO [public]
GO
