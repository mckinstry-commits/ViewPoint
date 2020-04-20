SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[SMStandardItemDefault]
AS
SELECT *
FROM dbo.vSMStandardItemDefault
GO
GRANT SELECT ON  [dbo].[SMStandardItemDefault] TO [public]
GRANT INSERT ON  [dbo].[SMStandardItemDefault] TO [public]
GRANT DELETE ON  [dbo].[SMStandardItemDefault] TO [public]
GRANT UPDATE ON  [dbo].[SMStandardItemDefault] TO [public]
GRANT SELECT ON  [dbo].[SMStandardItemDefault] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMStandardItemDefault] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMStandardItemDefault] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMStandardItemDefault] TO [Viewpoint]
GO
