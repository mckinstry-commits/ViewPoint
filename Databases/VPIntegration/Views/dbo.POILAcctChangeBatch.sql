SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[POILAcctChangeBatch]
AS
SELECT *
FROM dbo.vPOILAcctChangeBatch

GO
GRANT SELECT ON  [dbo].[POILAcctChangeBatch] TO [public]
GRANT INSERT ON  [dbo].[POILAcctChangeBatch] TO [public]
GRANT DELETE ON  [dbo].[POILAcctChangeBatch] TO [public]
GRANT UPDATE ON  [dbo].[POILAcctChangeBatch] TO [public]
GO
