SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[pvPCVendorType]
AS
SELECT 'R' AS KeyField, 'Regular' AS VendorDescription
UNION
SELECT 'S', 'Supplier'

GO
GRANT SELECT ON  [dbo].[pvPCVendorType] TO [public]
GRANT INSERT ON  [dbo].[pvPCVendorType] TO [public]
GRANT DELETE ON  [dbo].[pvPCVendorType] TO [public]
GRANT UPDATE ON  [dbo].[pvPCVendorType] TO [public]
GRANT SELECT ON  [dbo].[pvPCVendorType] TO [VCSPortal]
GO
