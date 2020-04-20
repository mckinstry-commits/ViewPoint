SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.mckReadyForInterface
AS


SELECT 'Subcontract' AS InterfaceType, 
	sh.PMCo AS [Company], 
	sh.Project AS [Project], 
	'SL - '+sh.SL AS [Header], 
	('Item - ' + CONVERT(VARCHAR(30), si.SLItem)) AS [Item], 
	cc.DisplayValue AS [ItemType], 
	pm.Name AS [POCName],
	pm.Email AS [POCEmail]
	--, SendFlag,
	--si.InterfaceDate, si.IntFlag
FROM dbo.PMSL si
LEFT OUTER JOIN SLHDPM sh ON si.PMCo = sh.PMCo AND si.Project = sh.Project AND si.SL = sh.SL
INNER JOIN DDCI cc ON cc.ComboType = 'SLItemType' AND si.SLItemType = cc.DatabaseValue
INNER JOIN JCJM js ON js.JCCo = sh.PMCo AND js.Job = si.Project
INNER JOIN JCCM cs ON cs.JCCo = js.JCCo AND cs.Contract = js.Contract
LEFT OUTER JOIN JCMP pm ON cs.JCCo = pm.JCCo AND pm.ProjectMgr = cs.udPOC
LEFT OUTER JOIN dbo.PMSubcontractCO sco ON sco.PMCo = si.PMCo AND sco.Project = si.Project AND sco.SL = si.SL
WHERE (si.InterfaceDate IS NULL AND si.SendFlag = 'Y' AND sh.Approved = 'Y') OR (sco.ReadyForAcctg = 'Y' AND si.InterfaceDate IS NULL)

UNION ALL 

SELECT 'Phase' AS InterfaceType, 
		pc.JCCo AS [Company], 
		pc.Job AS [Project], 
		('Phase - '+pc.Phase) AS [Header], 
		('CostType - '+ CONVERT(VARCHAR(30), pc.CostType)) AS [Item], 
		c.DisplayValue AS [ItemType],
		pmc.Name AS [POCName],
		pmc.Email AS [POCEmail]
FROM JCCH pc 
INNER JOIN DDCI c ON c.ComboType = 'JCCHSourceStatus' AND pc.SourceStatus = c.DatabaseValue
INNER JOIN JCJM jp ON jp.JCCo = pc.JCCo AND jp.Job = pc.Job
INNER JOIN JCCM cp ON cp.JCCo = jp.JCCo AND jp.Contract = cp.Contract
INNER JOIN JCMP pmc ON pmc.JCCo = cp.JCCo AND cp.udPOC = pmc.ProjectMgr
WHERE pc.SourceStatus = 'Y' AND pc.ActiveYN = 'Y' AND pc.InterfaceDate IS NULL --AND pc.Job = '654321-002'

UNION ALL

SELECT 'ACO' AS [InterfaceType], aci.PMCo AS [Company], aci.Project AS [Project],
	 'ACO - '+ CONVERT(VARCHAR(30),(aci.ACO)) AS [Header], 'Item - '+ CONVERT(VARCHAR(30),aci.ACOItem) AS [Item],'ACO' AS [ItemType], apm.Name AS [POCName], apm.Email AS [POCEmail]
FROM PMOI aci
INNER JOIN PMOH ach ON aci.PMCo = ach.PMCo AND aci.Project = ach.Project AND aci.ACO = ach.ACO

INNER JOIN JCJM aj ON aj.JCCo = aci.PMCo AND aj.Job = aci.Project
INNER JOIN JCCM ac ON ac.JCCo = aj.JCCo AND ac.Contract = aj.Contract
LEFT OUTER JOIN JCMP apm ON apm.JCCo = ac.JCCo AND apm.ProjectMgr = ac.udPOC
WHERE aci.InterfacedDate IS NULL AND aci.Approved = 'Y' AND ach.ReadyForAcctg = 'Y'

UNION ALL

SELECT 'PO' AS [InterfaceType], pi.PMCo AS [Company], pi.Project AS [Project], 'PO - '+ CONVERT(VARCHAR(30),(pi.PO)) AS [Header], 'Item - '+ CONVERT(VARCHAR(30),pi.POItem) AS [Item], 'PO' AS [ItemType], pmp.Name, pmp.Email
--, pi.InterfaceDate, pi.IntFlag, pi.SendFlag, ph.Approved
FROM PMMF pi
INNER JOIN POHDPM ph ON ph.POCo = pi.POCo AND ph.Project = pi.Project AND ph.PO = pi.PO
INNER JOIN JCJM pjm ON pjm.JCCo = ph.JCCo AND pjm.Job = ph.Job
INNER JOIN JCCM pcm ON pcm.JCCo = pjm.JCCo AND pcm.Contract = pjm.Contract
INNER JOIN JCMP pmp ON pmp.JCCo = pcm.JCCo AND pmp.ProjectMgr = pcm.udPOC
WHERE pi.InterfaceDate IS NULL AND pi.SendFlag = 'Y' AND ph.Approved = 'Y'


GO
GRANT SELECT ON  [dbo].[mckReadyForInterface] TO [public]
GRANT INSERT ON  [dbo].[mckReadyForInterface] TO [public]
GRANT DELETE ON  [dbo].[mckReadyForInterface] TO [public]
GRANT UPDATE ON  [dbo].[mckReadyForInterface] TO [public]
GO

EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[4] 4[22] 2[16] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'mckReadyForInterface', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'mckReadyForInterface', NULL, NULL
GO
