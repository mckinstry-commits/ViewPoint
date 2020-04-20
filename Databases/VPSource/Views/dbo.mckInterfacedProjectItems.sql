
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[mckInterfacedProjectItems]
AS
SELECT 'Phase' AS InterfaceType, ch.InterfaceDate, ch.Job, '' AS ItemType, pm.Name, pm.Email
FROM dbo.JCCH ch
INNER JOIN JCJM jh ON jh.JCCo = ch.JCCo AND jh.Job = ch.Job
INNER JOIN JCCM cm ON cm.JCCo = jh.JCCo AND cm.Contract = jh.Contract
LEFT OUTER JOIN JCMP pm ON pm.JCCo = cm.JCCo AND pm.ProjectMgr = cm.udPOC
WHERE InterfaceDate IS NOT NULL
AND (InterfaceDate BETWEEN CAST(CONVERT(CHAR(11), CURRENT_TIMESTAMP, 113) AS DATETIME) AND
		CAST(CONVERT(CHAR(11), DATEADD(day, -1, CURRENT_TIMESTAMP), 113) AS DATETIME))
UNION ALL
SELECT 'PO' AS InterfaceType, mf.InterfaceDate, mf.Project AS Job, '' AS ItemType, pmf.Name, pmf.Email
FROM dbo.PMMF mf
INNER JOIN JCJM jf ON jf.JCCo = mf.PMCo AND jf.Job = mf.Project
INNER JOIN JCCM cf ON cf.JCCo = jf.JCCo AND cf.Contract = jf.Contract
LEFT OUTER JOIN JCMP pmf ON pmf.JCCo = cf.JCCo AND pmf.ProjectMgr = cf.udPOC
WHERE InterfaceDate IS NOT NULL
AND (InterfaceDate BETWEEN CAST(CONVERT(CHAR(11), CURRENT_TIMESTAMP, 113) AS DATETIME)
		AND CAST(CONVERT(CHAR(11), DATEADD(day, -1, CURRENT_TIMESTAMP), 113) AS DATETIME))
UNION ALL
SELECT 'Subcontract' AS InterfaceType, InterfaceDate, Project AS Job, co.DisplayValue AS ItemType, pms.Name, pms.Email
FROM dbo.PMSL s
INNER JOIN DDCI co ON co.ComboType = 'SLItemType' AND s.SLItemType = co.Seq
INNER JOIN JCJM js ON js.JCCo = s.PMCo AND js.Job = s.Project
INNER JOIN JCCM cs ON cs.JCCo = js.JCCo AND cs.Contract = js.Contract
LEFT OUTER JOIN JCMP pms ON pms.JCCo = cs.JCCo AND pms.ProjectMgr = cs.udPOC
WHERE InterfaceDate IS NOT NULL
AND (InterfaceDate BETWEEN CAST(CONVERT(CHAR(11), CURRENT_TIMESTAMP, 113) AS DATETIME)
		AND CAST(CONVERT(CHAR(11), DATEADD(day, -1, CURRENT_TIMESTAMP), 113) AS DATETIME))
UNION ALL
SELECT 'ACO' AS InterfaceType, a.InterfacedDate, a.Project AS Job, '' AS ItemType, pma.Name, pma.Email
FROM PMOI a
INNER JOIN JCJM ja ON ja.JCCo = a.PMCo AND ja.Job = a.Project
INNER JOIN JCCM ca ON ca.JCCo = ja.JCCo AND ca.Contract = ja.Contract
LEFT OUTER JOIN JCMP pma ON pma.JCCo = ca.JCCo AND pma.ProjectMgr = ca.udPOC
WHERE InterfacedDate IS NOT NULL
AND 
	(InterfacedDate BETWEEN CAST(CONVERT(CHAR(11), CURRENT_TIMESTAMP, 113) AS DATETIME)
		AND CAST(CONVERT(CHAR(11), DATEADD(day, -1, CURRENT_TIMESTAMP), 113) AS DATETIME));

GO

GRANT SELECT ON  [dbo].[mckInterfacedProjectItems] TO [public]
GRANT INSERT ON  [dbo].[mckInterfacedProjectItems] TO [public]
GRANT DELETE ON  [dbo].[mckInterfacedProjectItems] TO [public]
GRANT UPDATE ON  [dbo].[mckInterfacedProjectItems] TO [public]
GO

EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
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
', 'SCHEMA', N'dbo', 'VIEW', N'mckInterfacedProjectItems', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'mckInterfacedProjectItems', NULL, NULL
GO
