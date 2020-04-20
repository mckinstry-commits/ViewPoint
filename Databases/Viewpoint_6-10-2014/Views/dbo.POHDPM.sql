SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 09/07/2006 6.x only
* Modfied By:
*
* Provides a view of PO Header for 6.x
* Since PMPOHeader form uses PMCo and Project, need to
* alias JCCO as [PMCo] and Job as [Project] so that
* POHD purchase orders can be referenced in PM PO Header.
* Alias column for ShipToJob flag which is 'Y' when
* POHD.ShipAddress equals JCJM.ShipAddress.
*
*****************************************/
CREATE VIEW dbo.POHDPM
AS
SELECT        JCCo AS PMCo, Job AS Project, POCo, PO, VendorGroup, Vendor, Description, OrderDate, OrderedBy, ExpDate, Status, JCCo, Job, INCo, Loc, ShipLoc, Address, City, 
                         State, Zip, ShipIns, HoldCode, PayTerms, CompGroup, MthClosed, InUseMth, InUseBatchId, Approved, ApprovedBy, Purge, Notes, AddedMth, AddedBatchID, 
                         UniqueAttchID, Attention, PayAddressSeq, POAddressSeq, Address2, KeyID, Country, POCloseBatchID, udSource, udConv, udCGCTable, udCGCTableID, 
                         udOrderedBy, DocType, udMCKPONumber, udShipToJobYN, udPRCo, udAddressName, udPOFOB, udShipMethod, udPurchaseContact, udPMSource
FROM            dbo.POHD AS a
GO
GRANT SELECT ON  [dbo].[POHDPM] TO [public]
GRANT INSERT ON  [dbo].[POHDPM] TO [public]
GRANT DELETE ON  [dbo].[POHDPM] TO [public]
GRANT UPDATE ON  [dbo].[POHDPM] TO [public]
GRANT SELECT ON  [dbo].[POHDPM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POHDPM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POHDPM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POHDPM] TO [Viewpoint]
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
         Begin Table = "a"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 282
               Right = 270
            End
            DisplayFlags = 280
            TopColumn = 41
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
', 'SCHEMA', N'dbo', 'VIEW', N'POHDPM', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'POHDPM', NULL, NULL
GO
