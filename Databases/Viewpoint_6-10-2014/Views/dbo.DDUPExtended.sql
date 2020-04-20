SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DDUPExtended]
AS
SELECT  dbo.DDUP.*, 
        dbo.pUsers.[UserName], dbo.pUsers.[UserID], dbo.pUsers.[PID], dbo.pUsers.[SID], dbo.pUsers.[LastPIDChange], dbo.pUsers.[FirstName],
        dbo.pUsers.[MiddleName], dbo.pUsers.[LastName], dbo.pUsers.[LastLogin], 
        dbo.pUsers.[PRCo] AS Expr1, dbo.pUsers.[PREmployee], dbo.pUsers.[HRCo] AS Expr2,
        dbo.pUsers.[HRRef] AS Expr3, dbo.pUsers.[VendorGroup], dbo.pUsers.[Vendor], dbo.pUsers.[CustGroup], dbo.pUsers.[Customer], dbo.pUsers.[FirmNumber],
        dbo.pUsers.[Contact], dbo.pUsers.[DefaultSiteID], dbo.pUsers.[VPUserName] AS Expr4, dbo.pUsers.[AdministerPortal],
        dbo.pUserSites.[RoleID] 
FROM         dbo.DDUP LEFT OUTER JOIN
                      dbo.pUsers WITH (NOLOCK) ON dbo.DDUP.VPUserName = dbo.pUsers.VPUserName
                      LEFT OUTER JOIN dbo.pUserSites WITH (NOLOCK) ON dbo.pUsers.DefaultSiteID = dbo.pUserSites.SiteID AND dbo.pUsers.UserID = dbo.pUserSites.UserID
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:      AL,vtDDUPExtendedd
-- Create date: 10/14/11
-- Description: Handles deleting a record from the 
--              DDUP Table and pUsersTable
-- Edited:      2012-01-10 - Chris Crewdson - Cleanup to delete old trigger in this script
--				2012-3-30  - Ken Eucker - Added a line to remove all entries in pUserSites for the user
-- =============================================
CREATE TRIGGER [dbo].[vtDDUPExtendedd]
   ON  [dbo].[DDUPExtended]
   INSTEAD OF DELETE
AS 
BEGIN

	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

Delete from DDUP where VPUserName in (select VPUserName from deleted)

Delete from pUsers where UserName in (Select UserName from deleted)

Delete from pUserSites where UserID in (Select UserID from deleted)

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*=============================================================================
-- Author:      AL,vtDDUPExtendedi
-- Create date: 10/14/11
-- Description: Handles inserting a new record into the 
--              DDUP Table
-- Modified:    2012-01-31 - Chris Crewdson - Changed to dynamic SQL to support custom fields
--
--
-- Notes:
--  It might be useful to wrap the dyanamic SQL execution like 'EXEC(@tsqlHead)'
--  and the execution of vspCreateAndExecuteInsert with transactions.
--
=============================================================================*/
CREATE TRIGGER [dbo].[vtDDUPExtendedi]
   ON  [dbo].[DDUPExtended]
   INSTEAD OF INSERT
AS 
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;
    
    --Declarations
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
    -- Select the set to be inserted into a temp table so 
    SELECT *
    INTO #DDUPTempTableForInsert
    FROM INSERTED
    
    --Create dynamic sql to set defaults into columns that have NOT NULL constraints
    DECLARE @tsqlHead varchar(MAX),
            @tsql varchar(MAX)
    SET @tsqlHead = 'UPDATE #DDUPTempTableForInsert SET '
    SET @tsql = ''
    SELECT @tsql = @tsql + '[' + c.name + '] = CASE WHEN ['+ c.name + '] IS NULL AND ' + CONVERT(char(1),c.is_nullable) + ' = 0 THEN '
        + REPLACE(REPLACE(dc.definition,'(',''),')','') +
        ' ELSE [' + c.name + '] END,'
    FROM 
        sys.default_constraints AS dc JOIN 
        sys.columns AS c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id JOIN
        sys.tables t ON t.object_id = c.object_id
    WHERE 
        t.name = 'vDDUP'

    --If NOT NULL constraints were found, update the temp table with defaults
    IF LEN(@tsql) > 1
    BEGIN
        --Remove the last comma from the concatenation
        SELECT @tsqlHead = @tsqlHead + LEFT(@tsql, LEN(@tsql)-1)
        
        BEGIN TRY
            -- Run the update
            EXEC(@tsqlHead)
        END TRY
        BEGIN CATCH
            SELECT 
                @ErrorMessage = ERROR_MESSAGE(),
                @ErrorSeverity = ERROR_SEVERITY(),
                @ErrorState = ERROR_STATE();

            RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
            GOTO vspexit
        END CATCH
    END
    
    --Execute the insert from the temp table to the real table
    BEGIN TRY
        -- Run the update
        EXECUTE vspCreateAndExecuteInsert 'vDDUP', '#DDUPTempTableForInsert'
    END TRY
    BEGIN CATCH
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH

    --Note: We are not inserting into pUsers here, even though it is part of DDUPExtended. 
    --      A portal user is explicitly created elsewhere.

    vspexit:
    --Clean up the temp table
    IF OBJECT_ID('tempdb..#DDUPTempTableForInsert') IS NOT NULL DROP TABLE #DDUPTempTableForInsert

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:      AL,vtDDUPExtendedu
-- Create date: 10/14/11
-- Description: Handles updating a record in the 
--              DDUP Table and pUsersTable
-- Edited:      2012-01-10 - Chris Crewdson - Changed to dynamic SQL to support custom fields
--              2012-03-29 - Ken Eucker - Added an update and insert for the pUserSites table a
--                  and the new RoleID column in this view
--              2012-04-12 - Chris Crewdson - Added NULL check to pUserSites INSERT
-- =============================================
CREATE TRIGGER [dbo].[vtDDUPExtendedu]
   ON  [dbo].[DDUPExtended]
   INSTEAD OF UPDATE
AS 
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;
    
    --Declarations
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
    --Update the pUsers table. This can be done simply because there are no custom fields.
    UPDATE pUsers SET DefaultSiteID = i.DefaultSiteID, AdministerPortal = i.AdministerPortal, CustGroup = i.CustGroup,
                      Customer = i.Customer, VendorGroup = i.VendorGroup, Vendor = i.Vendor, FirmNumber = i.FirmNumber,
                      Contact = i.Contact
                      FROM pUsers INNER JOIN INSERTED i ON pUsers.UserName = i.UserName  
    
    -- If default UserSite does exist for UserID, UPDATE, otherwise INSERT
    UPDATE pUserSites SET RoleID = i.RoleID
    FROM pUserSites JOIN INSERTED i ON pUserSites.UserID = i.UserID AND pUserSites.SiteID = i.DefaultSiteID 
    
    INSERT INTO pUserSites (UserID, SiteID, RoleID) 
    SELECT i.UserID, i.DefaultSiteID, i.RoleID 
    FROM INSERTED i LEFT JOIN pUserSites ON pUserSites.UserID = i.UserID AND pUserSites.SiteID = i.DefaultSiteID 
    WHERE 
        pUserSites.UserID IS NULL AND --Insert if record is missing, update above will get existing records
        i.UserID IS NOT NULL AND -- If there is no pUser part of the INSERTED record, don't try to insert it
        i.RoleID IS NOT NULL -- This can happen because we don't have a full FK and PK. Don't insert.

    --Update the vDDUP table. This must be done with dynamic SQL because there could be custom fields on DDUP
    SELECT INSERTED.* 
    INTO #DDUPTempUpdateTable
    FROM INSERTED LEFT JOIN vDDUP ON INSERTED.VPUserName = vDDUP.VPUserName
    
    BEGIN TRY
        -- Run the update
        EXECUTE vspCreateAndExecuteUpdate 'vDDUP', '#DDUPTempUpdateTable', 'vDDUP.VPUserName = #DDUPTempUpdateTable.VPUserName'
    END TRY
    BEGIN CATCH
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH

    --Remove the temp table
    IF OBJECT_ID('tempdb..#DDUPTempUpdateTable') IS NOT NULL DROP TABLE #DDUPTempUpdateTable

END
GO
GRANT SELECT ON  [dbo].[DDUPExtended] TO [public]
GRANT INSERT ON  [dbo].[DDUPExtended] TO [public]
GRANT DELETE ON  [dbo].[DDUPExtended] TO [public]
GRANT UPDATE ON  [dbo].[DDUPExtended] TO [public]
GRANT SELECT ON  [dbo].[DDUPExtended] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDUPExtended] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDUPExtended] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDUPExtended] TO [Viewpoint]
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[56] 4[6] 2[20] 3) )"
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
         Begin Table = "vDDUP"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 246
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pUsers"
            Begin Extent = 
               Top = 6
               Left = 284
               Bottom = 125
               Right = 451
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
      Begin ColumnWidths = 367
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
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
', 'SCHEMA', N'dbo', 'VIEW', N'DDUPExtended', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'         Width = 1500
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
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
', 'SCHEMA', N'dbo', 'VIEW', N'DDUPExtended', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane3', N'         Width = 1500
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
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append ', 'SCHEMA', N'dbo', 'VIEW', N'DDUPExtended', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane4', N'= 1400
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
', 'SCHEMA', N'dbo', 'VIEW', N'DDUPExtended', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=4
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'DDUPExtended', NULL, NULL
GO
