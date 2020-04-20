SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vwMcKSubcontracts]
AS
SELECT    distinct t2.Name AS OurCompany, t2.Address AS CompanyAddress, t2.Address2 AS CompanyAddress2, t2.City AS CompanyCity, t2.State AS CompanyState, t2.Phone as CompanyPhone,
                      t2.Zip AS CompanyZip, t3.Name AS VendorName, t5.MailAddress AS VendorAddress, t5.MailAddress2 AS VendorAddress2, t5.MailCity AS VendorCity, t5.MailState AS VendorState, 
                      t5.MailZip AS VendorZip, t1.PMCo, t1.Project, t1.SLCo, t1.SL, t1.JCCo, t1.Job, t1.Description, t1.VendorGroup, t1.Vendor, t1.HoldCode, t1.PayTerms, t1.CompGroup, 
                      t1.Status, t1.MthClosed, t1.InUseMth, t1.InUseBatchId, t1.Purge, t1.Approved, t1.ApprovedBy, t1.Notes, t1.AddedMth, t1.AddedBatchID, t1.OrigDate, t1.UniqueAttchID, 
                      t1.KeyID, t1.SLCloseBatchID, t1.MaxRetgOpt, FORMAT(ISNULL(ps.WCRetgPct,0) * 100, '#0.00') as MaxRetgPct, t1.MaxRetgAmt, t1.InclACOinMaxYN, t1.MaxRetgDistStyle, t1.ApprovalRequired, t1.udSLContractNo, 
                      t1.udSource, t1.udConv, t1.udCGCTable, t1.udCGCTableID, t1.udSLDrawings, t1.udSafety, t1.udScheduleOVal, t1.udProjSchedule, t1.udBalancing, t1.udConsulting, 
                      t1.udFacility, t1.udScope, t1.udControls, t1.udDesignServ, t1.udProServTesting, t1.udSoftProServ, t1.udSoftLicense, t1.udSoftSupMaintYN, t1.udSoftHost, 
                      t1.udWorkOrderYN, t1.udFederalYN, t1.udPerfBondYN, t1.udCostPlusYN, t1.udNegMods, '' as udSubType, t1.udGTC, t1.udInvYN, t1.udEEO, t1.udMastSub, 
                      t1.udInsurance, t1.udCommissioningYN, t1.udRoofingYN, t1.udLighting, t1.udAddendum, t1.udMasIns, t1.udCertPRPrevYN, t1.udConstruction, t1.DocType, 
                      t1.udProServYN, bt.Description as udBillType, t1.udSbstntlComp
                    ,  jobmaster.Description as JobName
                    , jobmaster.MailAddress as JobAddress
					, jobmaster.MailAddress2 as JobAddress2
					, jobmaster.MailCity as JobCity
					, jobmaster.MailState as JobState
					, jobmaster.MailZip as JobZip
					, jobmaster.JobPhone as JobPhone
					, jobmaster.ContactCode
					, jobmaster.ProjectMgr
					, emp.Email as PMEmail
					,(emp.Name) as ProjectManager
					, COALESCE(t5.EMail,pp.EMail,'') as VendorEmail
					, t5.Phone as VendorPhone
					, FORMAT((t4.SLTotalOrig + t4.PMSLAmtOrig),'C','en-us') as SLTotalOrig
					, pp.FirstName + ' ' + pp.LastName as VendorContactName
					, t4.MaxRetgByPct
					, COALESCE(se.State,'0') as StateExhibit 
					,FORMAT(m.ExecDate ,'MM/dd/yyyy','en-us') as ExecuteDate
					--,se.KeyID as StateExhibitID
FROM         dbo.SLHDPM AS t1 INNER JOIN
					  dbo.HQCO AS t2 ON t1.SLCo = t2.HQCo Left outer JOIN
					  dbo.APVM AS t3 ON t2.VendorGroup = t3.VendorGroup AND t1.Vendor = t3.Vendor LEFT outer JOIN
                      dbo.bJCJM jobmaster on t1.Job = jobmaster.Job and t1.JCCo = jobmaster.JCCo LEFT outer JOIN
                      dbo.JCMP emp on jobmaster.ProjectMgr = emp.ProjectMgr and jobmaster.JCCo = emp.JCCo  Left outer Join
                      dbo.PMSLTotal t4 ON t1.SLCo = t4.SLCo and t1.SL = t4.SL LEFT OUTER JOIN
                      dbo.PMSS c ON c.SLCo = t1.SLCo and c.SL = t1.SL and c.Send='Y' and c.CC='N'  LEFT OUTER JOIN
                      dbo.PMPM pp on pp.FirmNumber = c.SendToFirm and  pp.VendorGroup = c.VendorGroup and pp.ContactCode = c.SendToContact LEFT OUTER JOIN
                      dbo.PMFM t5 ON t5.VendorGroup = pp.VendorGroup and t5.FirmNumber= pp.FirmNumber and t5.Vendor = t1.Vendor LEFT OUTER JOIN
                      dbo.udSubStateExhibits se ON t1.SLCo = se.PMCo and t1.SL = se.PMSL LEFT OUTER JOIN
                      dbo.udMSA m on t1.Vendor = m.Vendor and t1.VendorGroup = m.VendorGroup LEFT OUTER JOIN
                      dbo.udBillTypes bt ON t1.udBillType = bt.BillType LEFT OUTER JOIN
                      dbo.PMSL ps ON ps.SL = t1.SL and ps.SLCo = t1.SLCo and SLItem = 1
                      

where t1.Status !=2
GO
GRANT SELECT ON  [dbo].[vwMcKSubcontracts] TO [public]
GRANT INSERT ON  [dbo].[vwMcKSubcontracts] TO [public]
GRANT DELETE ON  [dbo].[vwMcKSubcontracts] TO [public]
GRANT UPDATE ON  [dbo].[vwMcKSubcontracts] TO [public]
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[30] 4[15] 2[37] 3) )"
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
         Begin Table = "t1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 221
            End
            DisplayFlags = 280
            TopColumn = 65
         End
         Begin Table = "t2"
            Begin Extent = 
               Top = 6
               Left = 259
               Bottom = 125
               Right = 438
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t3"
            Begin Extent = 
               Top = 6
               Left = 476
               Bottom = 125
               Right = 702
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "jobmaster"
            Begin Extent = 
               Top = 126
               Left = 38
               Bottom = 255
               Right = 327
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "emp"
            Begin Extent = 
               Top = 258
               Left = 38
               Bottom = 387
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t4"
            Begin Extent = 
               Top = 258
               Left = 246
               Bottom = 387
               Right = 416
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 390
               Left = 38
               Bottom = 519
               Right = 226
            End
            DisplayFlags = 280
            TopColumn = 0
  ', 'SCHEMA', N'dbo', 'VIEW', N'vwMcKSubcontracts', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'       End
         Begin Table = "pp"
            Begin Extent = 
               Top = 390
               Left = 264
               Bottom = 519
               Right = 453
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t5"
            Begin Extent = 
               Top = 522
               Left = 38
               Bottom = 651
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "se"
            Begin Extent = 
               Top = 522
               Left = 246
               Bottom = 651
               Right = 416
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "m"
            Begin Extent = 
               Top = 654
               Left = 38
               Bottom = 783
               Right = 237
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "bt"
            Begin Extent = 
               Top = 654
               Left = 275
               Bottom = 783
               Right = 445
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
      Begin ColumnWidths = 10
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
', 'SCHEMA', N'dbo', 'VIEW', N'vwMcKSubcontracts', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'vwMcKSubcontracts', NULL, NULL
GO
