SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* =============================================
 Author: Raveen Boyagoda
 Create date:
 Description: This View is to get data into Projected Final Billing Detail Report
				Report Name CustomJCContractStatDetail.rpt*/
CREATE VIEW dbo.mckJCContractStatDetail
AS
SELECT        dbo.JCJP.JCCo, dbo.JCJP.Contract, dbo.JCCH.udMarkup, dbo.JCCP.ProjCost, dbo.JCJP.Phase, dbo.JCJP.Description, dbo.JCCT.Abbreviation, dbo.JCCP.ProjHours, 
                         dbo.JCCH.udSellRate, dbo.JCCT.CostType, dbo.JCCP.ProjCost * ISNULL(dbo.JCCH.udMarkup, 0.00) AS Fee, CASE WHEN JCCH.CostType IN (1, 4) 
                         THEN (JCCP.ProjHours * ISNULL(JCCH.udSellRate, 0.00)) + (JCCP.ProjCost * ISNULL(JCCH.udMarkup, 0.00)) 
                         ELSE (JCCP.ProjCost + (JCCP.ProjCost * ISNULL(JCCH.udMarkup, 0.00))) END AS ProjBillingByPhase, dbo.JCCM.ContractAmt, dbo.JCJP.Job, 
                         dbo.JCCT.Description AS CTDescription, dbo.JCCP.Mth, dbo.JCCM.ContractStatus
FROM            dbo.JCCT INNER JOIN
                         dbo.JCCH ON dbo.JCCT.CostType = dbo.JCCH.CostType AND dbo.JCCT.PhaseGroup = dbo.JCCH.PhaseGroup INNER JOIN
                         dbo.JCJP ON dbo.JCCH.JCCo = dbo.JCJP.JCCo AND dbo.JCCH.Job = dbo.JCJP.Job AND dbo.JCCH.PhaseGroup = dbo.JCJP.PhaseGroup AND 
                         dbo.JCCH.Phase = dbo.JCJP.Phase RIGHT OUTER JOIN
                         dbo.JCCP ON dbo.JCCH.JCCo = dbo.JCCP.JCCo AND dbo.JCCH.Job = dbo.JCCP.Job AND dbo.JCCH.PhaseGroup = dbo.JCCP.PhaseGroup AND 
                         dbo.JCCH.Phase = dbo.JCCP.Phase AND dbo.JCCH.CostType = dbo.JCCP.CostType LEFT OUTER JOIN
                         dbo.JCCM ON dbo.JCJP.JCCo = dbo.JCCM.JCCo AND dbo.JCJP.Contract = dbo.JCCM.Contract
GO
GRANT SELECT ON  [dbo].[mckJCContractStatDetail] TO [public]
GRANT INSERT ON  [dbo].[mckJCContractStatDetail] TO [public]
GRANT DELETE ON  [dbo].[mckJCContractStatDetail] TO [public]
GRANT UPDATE ON  [dbo].[mckJCContractStatDetail] TO [public]
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[47] 4[4] 2[6] 3) )"
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
         Begin Table = "JCJP"
            Begin Extent = 
               Top = 7
               Left = 670
               Bottom = 400
               Right = 840
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "JCCP"
            Begin Extent = 
               Top = 10
               Left = 18
               Bottom = 477
               Right = 215
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "JCCH"
            Begin Extent = 
               Top = 16
               Left = 286
               Bottom = 449
               Right = 461
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "JCCM"
            Begin Extent = 
               Top = 178
               Left = 899
               Bottom = 444
               Right = 1099
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "JCCT"
            Begin Extent = 
               Top = 183
               Left = 518
               Bottom = 412
               Right = 712
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
      Begin ColumnWidths = 18
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      ', 'SCHEMA', N'dbo', 'VIEW', N'mckJCContractStatDetail', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'   Width = 1500
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
', 'SCHEMA', N'dbo', 'VIEW', N'mckJCContractStatDetail', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'mckJCContractStatDetail', NULL, NULL
GO
