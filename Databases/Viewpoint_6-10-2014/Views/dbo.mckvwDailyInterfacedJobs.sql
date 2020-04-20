SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.mckvwDailyInterfacedJobs
AS
SELECT        j.JCCo, j.Job, j.Description, j.Contract, j.ProjectMgr, MAX(c.udDateChanged) AS LastPhaseChange, MAX(po.InterfaceDate) AS LastPOInterface, MAX(c.InterfaceDate) 
                         AS LastPhaseInterface
FROM            dbo.JCJM AS j LEFT OUTER JOIN
                         dbo.JCCH AS c ON c.JCCo = j.JCCo AND c.Job = j.Job LEFT OUTER JOIN
                         dbo.PMMF AS po ON po.VendorGroup = j.VendorGroup AND j.JCCo = po.PMCo AND j.Job = po.Project
WHERE        (c.InterfaceDate = CAST(CONVERT(CHAR(11), GETDATE(), 113) AS datetime)) OR
                         (po.InterfaceDate = CAST(CONVERT(CHAR(11), GETDATE(), 113) AS datetime))
GROUP BY j.JCCo, j.Job, j.Description, j.Contract, j.ProjectMgr
GO
GRANT SELECT ON  [dbo].[mckvwDailyInterfacedJobs] TO [public]
GRANT INSERT ON  [dbo].[mckvwDailyInterfacedJobs] TO [public]
GRANT DELETE ON  [dbo].[mckvwDailyInterfacedJobs] TO [public]
GRANT UPDATE ON  [dbo].[mckvwDailyInterfacedJobs] TO [public]
GRANT SELECT ON  [dbo].[mckvwDailyInterfacedJobs] TO [Viewpoint]
GRANT INSERT ON  [dbo].[mckvwDailyInterfacedJobs] TO [Viewpoint]
GRANT DELETE ON  [dbo].[mckvwDailyInterfacedJobs] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[mckvwDailyInterfacedJobs] TO [Viewpoint]
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[33] 4[21] 2[28] 3) )"
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
         Begin Table = "j"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 309
               Right = 323
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 7
               Left = 605
               Bottom = 251
               Right = 788
            End
            DisplayFlags = 280
            TopColumn = 18
         End
         Begin Table = "po"
            Begin Extent = 
               Top = 146
               Left = 509
               Bottom = 322
               Right = 700
            End
            DisplayFlags = 280
            TopColumn = 0
         End
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
         Width = 3105
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
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
', 'SCHEMA', N'dbo', 'VIEW', N'mckvwDailyInterfacedJobs', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'mckvwDailyInterfacedJobs', NULL, NULL
GO
