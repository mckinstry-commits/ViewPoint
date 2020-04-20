SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.HRRMHRDP
AS
SELECT     HRCo, HRRef, 0 AS Seq, FullName AS 'Name', 'Resource' AS 'Relationship'
FROM         dbo.HRRMName AS m WITH (nolock)
UNION
SELECT     m.HRCo, m.HRRef, p.Seq, p.Name, p.Relationship
FROM         dbo.HRDP AS p WITH (nolock) INNER JOIN
                      dbo.HRRM AS m WITH (nolock) ON p.HRCo = m.HRCo AND p.HRRef = m.HRRef AND p.Seq <> 0

GO
GRANT SELECT ON  [dbo].[HRRMHRDP] TO [public]
GRANT INSERT ON  [dbo].[HRRMHRDP] TO [public]
GRANT DELETE ON  [dbo].[HRRMHRDP] TO [public]
GRANT UPDATE ON  [dbo].[HRRMHRDP] TO [public]
GRANT SELECT ON  [dbo].[HRRMHRDP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRRMHRDP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRRMHRDP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRRMHRDP] TO [Viewpoint]
GO
