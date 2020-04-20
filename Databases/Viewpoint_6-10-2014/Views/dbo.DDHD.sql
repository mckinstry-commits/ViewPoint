SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDHD
AS
SELECT     HeaderTable, DetailTable, JoinClause
FROM         dbo.vDDHD

GO
GRANT SELECT ON  [dbo].[DDHD] TO [public]
GRANT INSERT ON  [dbo].[DDHD] TO [public]
GRANT DELETE ON  [dbo].[DDHD] TO [public]
GRANT UPDATE ON  [dbo].[DDHD] TO [public]
GRANT SELECT ON  [dbo].[DDHD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDHD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDHD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDHD] TO [Viewpoint]
GO
