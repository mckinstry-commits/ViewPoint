SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[pvPMMyPOChangeOrder]
AS
SELECT DISTINCT c.POCo, c.PO, ISNULL(c.ChangeOrder, '') AS 'ChangeOrder', 
c.ActDate, i.Job, ISNULL(SUM(c.ChangeCurCost), 0) AS 'SumChangeCurCost', c.KeyID,
i.Phase, ISNULL(i.Material,'') AS 'Material', m.Description as 'MaterialDesc'
FROM         dbo.POCD AS c WITH (nolock) 
		LEFT OUTER JOIN dbo.POIT AS i WITH (nolock) ON c.POCo = i.POCo AND c.PO = i.PO
		LEFT OUTER JOIN dbo.HQMT AS m WITH (nolock) ON i.MatlGroup = m.MatlGroup and i.Material = m.Material
GROUP BY c.POCo, c.PO, c.ChangeOrder, c.ActDate, i.Job, c.KeyID, i.Phase, i.Material, m.Description

GO
GRANT SELECT ON  [dbo].[pvPMMyPOChangeOrder] TO [public]
GRANT INSERT ON  [dbo].[pvPMMyPOChangeOrder] TO [public]
GRANT DELETE ON  [dbo].[pvPMMyPOChangeOrder] TO [public]
GRANT UPDATE ON  [dbo].[pvPMMyPOChangeOrder] TO [public]
GRANT SELECT ON  [dbo].[pvPMMyPOChangeOrder] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvPMMyPOChangeOrder] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvPMMyPOChangeOrder] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvPMMyPOChangeOrder] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvPMMyPOChangeOrder] TO [Viewpoint]
GO
