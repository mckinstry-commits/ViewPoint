SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.JBILTotal
AS
SELECT     TOP 100 PERCENT dbo.JBIN.JBCo, dbo.JBIN.BillMonth, dbo.JBIN.BillNumber, ISNULL(SUM(dbo.JBIL.Total), 0) AS JBILInvTotal
FROM         dbo.JBIN INNER JOIN
                      dbo.JBIL ON dbo.JBIL.JBCo = dbo.JBIN.JBCo AND dbo.JBIL.BillMonth = dbo.JBIN.BillMonth AND dbo.JBIL.BillNumber = dbo.JBIN.BillNumber
GROUP BY dbo.JBIN.JBCo, dbo.JBIN.BillMonth, dbo.JBIN.BillNumber
ORDER BY dbo.JBIN.JBCo, dbo.JBIN.BillMonth, dbo.JBIN.BillNumber


GO
GRANT SELECT ON  [dbo].[JBILTotal] TO [public]
GRANT INSERT ON  [dbo].[JBILTotal] TO [public]
GRANT DELETE ON  [dbo].[JBILTotal] TO [public]
GRANT UPDATE ON  [dbo].[JBILTotal] TO [public]
GRANT SELECT ON  [dbo].[JBILTotal] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBILTotal] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBILTotal] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBILTotal] TO [Viewpoint]
GO
