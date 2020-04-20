SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.mcksp_Gen_RLB_AP_PO_Detail_Export
AS
SELECT        dbo.POHD.POCo, dbo.POHD.PO, dbo.POIT.POItem, dbo.POIT.Material, dbo.POIT.Description, dbo.POIT.RecvYN, dbo.POIT.UM, dbo.POIT.OrigUnits, 
                         dbo.POIT.OrigUnitCost, dbo.POIT.CurUnits, dbo.POIT.CurUnitCost, dbo.POIT.RemUnits, dbo.POIT.OrigCost, dbo.POIT.OrigTax, dbo.POIT.CurCost, dbo.POIT.CurTax, 
                         dbo.POIT.RemCost, dbo.POIT.RemTax
FROM            dbo.POIT WITH (nolock) INNER JOIN
                         dbo.POHD WITH (nolock) ON dbo.POIT.POCo = dbo.POHD.POCo AND dbo.POIT.PO = dbo.POHD.PO
WHERE        (dbo.POHD.Status = 0)
GO
GRANT SELECT ON  [dbo].[mcksp_Gen_RLB_AP_PO_Detail_Export] TO [public]
GRANT INSERT ON  [dbo].[mcksp_Gen_RLB_AP_PO_Detail_Export] TO [public]
GRANT DELETE ON  [dbo].[mcksp_Gen_RLB_AP_PO_Detail_Export] TO [public]
GRANT UPDATE ON  [dbo].[mcksp_Gen_RLB_AP_PO_Detail_Export] TO [public]
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
         Begin Table = "POIT"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 213
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "POHD"
            Begin Extent = 
               Top = 6
               Left = 251
               Bottom = 185
               Right = 431
            End
            DisplayFlags = 280
            TopColumn = 49
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
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
', 'SCHEMA', N'dbo', 'VIEW', N'mcksp_Gen_RLB_AP_PO_Detail_Export', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'mcksp_Gen_RLB_AP_PO_Detail_Export', NULL, NULL
GO
