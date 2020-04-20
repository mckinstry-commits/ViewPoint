SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvPMBillFlagLookup
AS
SELECT     'Y' AS KeyField, 'Units & Cost' AS 'BillFlagDescription'
UNION
SELECT     'N' AS KeyField, 'Neither' AS 'BillFlagDescription'
UNION
SELECT     'C' AS KeyField, 'Cost' AS 'BillFlagDescription'

GO
GRANT SELECT ON  [dbo].[pvPMBillFlagLookup] TO [public]
GRANT INSERT ON  [dbo].[pvPMBillFlagLookup] TO [public]
GRANT DELETE ON  [dbo].[pvPMBillFlagLookup] TO [public]
GRANT UPDATE ON  [dbo].[pvPMBillFlagLookup] TO [public]
GRANT SELECT ON  [dbo].[pvPMBillFlagLookup] TO [VCSPortal]
GO
