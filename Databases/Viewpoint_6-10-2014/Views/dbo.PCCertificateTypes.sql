SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.PCCertificateTypes
AS
SELECT     dbo.vPCCertificateTypes.*
FROM         dbo.vPCCertificateTypes

GO
GRANT SELECT ON  [dbo].[PCCertificateTypes] TO [public]
GRANT INSERT ON  [dbo].[PCCertificateTypes] TO [public]
GRANT DELETE ON  [dbo].[PCCertificateTypes] TO [public]
GRANT UPDATE ON  [dbo].[PCCertificateTypes] TO [public]
GRANT SELECT ON  [dbo].[PCCertificateTypes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCCertificateTypes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCCertificateTypes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCCertificateTypes] TO [Viewpoint]
GO
