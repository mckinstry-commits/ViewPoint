SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.APVMforProjectSLandPO
AS
SELECT     TOP (100) PERCENT VendorGroup, Project, Vendor, Name
FROM         (SELECT     s.VendorGroup, s.Project, s.Vendor, a.Name
                       FROM          dbo.SLHDPM AS s INNER JOIN
                                              dbo.APVM AS a ON a.VendorGroup = s.VendorGroup AND a.Vendor = s.Vendor
                       UNION
                       SELECT     p.VendorGroup, p.Project, p.Vendor, a.Name
                       FROM         dbo.POHDPM AS p INNER JOIN
                                             dbo.APVM AS a ON a.VendorGroup = p.VendorGroup AND a.Vendor = p.Vendor) AS APVM

GO
GRANT SELECT ON  [dbo].[APVMforProjectSLandPO] TO [public]
GRANT INSERT ON  [dbo].[APVMforProjectSLandPO] TO [public]
GRANT DELETE ON  [dbo].[APVMforProjectSLandPO] TO [public]
GRANT UPDATE ON  [dbo].[APVMforProjectSLandPO] TO [public]
GRANT SELECT ON  [dbo].[APVMforProjectSLandPO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APVMforProjectSLandPO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APVMforProjectSLandPO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APVMforProjectSLandPO] TO [Viewpoint]
GO
