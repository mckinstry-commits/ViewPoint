SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************
* Created: 
* Modified:	AMR 06/22/11 - TK-07089, Fixing performance issue with if exists statement.
*			GPT 08/31/11 - TK-08120, Only generate a report action when marked Active in RPRFShared. 
*			HH  02/15/13 - TFS 13614, add additional result set for report parameters
*
* Retrieves all RP Report Header, Parameter, and Lookup info needed to 
* load a Viewpoint report.
*
* Input:
*	@RecordType			
*	@RestrictToEditActions
*
* Output:
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
   
CREATE PROCEDURE [dbo].[vspVPGetToolbarActions]
    @RecordType VARCHAR(128) ,
    @RestrictToEditActions bYN = 'N'
AS 
    BEGIN
        SET NOCOUNT ON ;

        CREATE TABLE #Groups
            (
              GroupId INT ,
              GroupName VARCHAR(30) ,
              GroupOrder INT ,
              ImageKey VARCHAR(128)
            ) ;

	-- Get the groups
        INSERT  INTO #Groups
                ( GroupId ,
                  GroupName ,
                  GroupOrder ,
                  ImageKey
                )
                SELECT  DDCustomGroups.Id ,
                        DDCustomGroups.Name ,
                        DDCustomGroups.[Order] ,
                        DDCustomGroups.ImageKey
                FROM    DDCustomGroups
                        INNER JOIN DDCustomRecordTypes ON DDCustomRecordTypes.Id = DDCustomGroups.RecordTypeId
                WHERE   DDCustomRecordTypes.Name = @RecordType
                ORDER BY DDCustomGroups.[Order] ;

    -- add the reports group, which is potentially a part of every toolbar
        CREATE TABLE #Reports
            (
              GroupId INT ,
              Id INT ,
              Name VARCHAR(64) ,
              [Description] VARCHAR(128) ,
              ImageKey VARCHAR(128) ,
              ActionType INT ,
              [Action] VARCHAR(MAX) ,
              KeyID INT ,
              OrderId INT IDENTITY(1, 1) ,
              RequiresRecords CHAR(1)
            ) ;
	

	-- Return the Actions in the groups
        DECLARE @sql NVARCHAR(MAX) ,
            @paramDefinition NVARCHAR(MAX) ;
	
        SET @paramDefinition = N'@Groups TABLE READONLY
	(
	  GroupId int,
	  GroupName varchar(30),
	  GroupOrder int,
	  ImageKey varchar(128)
	);' ;
	
	
        SET @sql = N'
	INSERT INTO #Reports (GroupId, Id, Name, [Description], ImageKey, ActionType, [Action], KeyID, RequiresRecords)
    SELECT	grp.GroupId AS GroupId, 
			DDCustomActions.ActionId AS Id, 
			DDCustomActions.Name, 
			DDCustomActions.Description, 
			DDCustomActions.ImageKey, 
			DDCustomActions.ActionType, 
			DDCustomActions.Action, 
			DDCustomActions.KeyID ,
			DDCustomActions.RequiresRecords
    FROM DDCustomActions
    INNER JOIN DDCustomActionGroup ON DDCustomActionGroup.ActionId = DDCustomActions.ActionId
    INNER JOIN #Groups grp ON grp.GroupId = DDCustomActionGroup.GroupId
    WHERE 1=1 ' ;
        IF @RestrictToEditActions = 'Y' 
            BEGIN
                SET @sql = @sql
                    + ' AND DDCustomActions.Name = ''Edit Record'' ' ;
            END
        SET @sql = @sql + ' ORDER BY grp.GroupOrder, DDCustomActions.Name; ' ;

        EXEC sp_executesql @sql ;
	
	-- look for the Reports group, get the ID.  If it doesn't exist,
	-- create it
        DECLARE @ReportID INT
        SET @ReportID = ( SELECT    GroupId
                          FROM      #Groups
                          WHERE     GroupName = 'Reports'
                        )
        IF @ReportID IS NULL 
            BEGIN
			-- if there is no reports group, create one
                INSERT  INTO #Groups
                        ( GroupId ,
                          GroupName ,
                          GroupOrder ,
                          ImageKey
                        )
                        SELECT  999 ,
                                'Reports' ,
                                100 ,
                                'R_16_REPORT' ;
                SET @ReportID = 999 ;
            END
	
    -- add in the reports if we aren't restricted to edit actions
        IF NOT @RestrictToEditActions = 'Y' 
            INSERT  INTO #Reports
                    ( GroupId ,
                      Id ,
                      Name ,
                      [Description] ,
                      ImageKey ,
                      ActionType ,
                      [Action] ,
                      KeyID ,
                      RequiresRecords
                    )
                    SELECT  @ReportID ,
                            0 ,
                            r.Title ,
                            r.Title ,
                            r.IconKey ,
                            1 ,
                            r.ReportID ,
                            0 ,
                            'N'
                    FROM    RPFRShared s
							-- using inline table function for index seeks
							CROSS APPLY (SELECT Title, IconKey, ReportID FROM dbo.vfRPRTShared(s.ReportID)) r
                    WHERE   [Form] = @RecordType And [Active] = 'Y';

	-- go through #Reports and for any report type (ActionType = 1) change
	-- the group number to 999
        UPDATE  #Reports
        SET     GroupId = @ReportID
        WHERE   ActionType = 1 ;
	
	-- Return the groups
        SELECT  GroupId ,
                GroupName ,
                ImageKey
        FROM    #Groups
        ORDER BY GroupOrder ;
	
	-- Return the actions and reports
        SELECT  GroupId ,
                Id ,
                Name ,
                Description ,
                ImageKey ,
                ActionType ,
                Action ,
                KeyID ,
                OrderId ,
                RequiresRecords
        FROM    #Reports
        ORDER BY OrderId ;
	
	-- Return the action parameters
        SELECT  dbo.DDCustomActionParameters.ActionId ,
                ParameterID ,
                DDCustomActionParameters.Name ,
                DefaultType ,
                DefaultValue ,
                @RecordType AS RecordTypeName
        FROM    DDCustomActionParameters
                INNER JOIN DDCustomActionGroup ON DDCustomActionGroup.ActionId = dbo.DDCustomActionParameters.ActionId
                INNER JOIN DDCustomGroups ON DDCustomGroups.Id = DDCustomActionGroup.GroupId
                INNER JOIN DDCustomRecordTypes ON DDCustomRecordTypes.Id = DDCustomGroups.RecordTypeId
        WHERE   DDCustomRecordTypes.Name = @RecordType ;
	
	-- Return the report parameters
		SELECT	#Reports.[Action] AS ReportID ,
				DisplaySeq ,
				ParameterName ,
				ISNULL(LTRIM(RTRIM(Datatype)), '') AS Datatype,
				CASE	
					WHEN ParameterDefault = '%C'	THEN 4 -- Active Company
					ELSE 0
				END AS DefaultType ,
				ParameterDefault AS DefaultValue ,
				CASE
					-- Get column for work center mapping from datatype in DDFIShared
					WHEN (SELECT TOP 1 ColumnName FROM DDFIShared WHERE Form = @RecordType AND Datatype = RPRPShared.Datatype AND ColumnName IS NOT NULL) IS NOT NULL 
						THEN LTRIM(RTRIM((SELECT TOP 1 ColumnName FROM DDFIShared WHERE Form = @RecordType AND Datatype = RPRPShared.Datatype AND ColumnName IS NOT NULL)))
					-- Try to get column by RPFDShared mapping
					WHEN ISNULL((SELECT ColumnName FROM DDFIShared where Form = @RecordType and Seq = (SELECT REPLACE(ParameterDefault, '%FI', '') FROM RPFDShared where RPFDShared.ParameterName = RPRPShared.ParameterName and Form = @RecordType and ReportID = #Reports.[Action] AND DefaultType = 4)),'') <> '' 
						THEN (SELECT ColumnName FROM DDFIShared where Form = @RecordType and Seq = (SELECT REPLACE(ParameterDefault, '%FI', '') FROM RPFDShared where RPFDShared.ParameterName = RPRPShared.ParameterName and Form = @RecordType and ReportID = #Reports.[Action] AND DefaultType = 4))
					-- Try to get column by data type substring
					WHEN SUBSTRING(Datatype, 2, 30) <> '' 
						THEN LTRIM(RTRIM(SUBSTRING(Datatype, 2, 30)))
					-- Try to get column by parameter name
					ELSE 
						LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE( ParameterName, '?' , '' ), '@' , '' ), 'Beginning', ''), 'Begin', ''), 'Beg', ''), 'Ending', ''), 'Ending', ''), 'End', '')))
				END AS MappingColumn
		FROM	RPRPShared
				INNER JOIN #Reports ON #Reports.[Action] = RPRPShared.ReportID
		WHERE   #Reports.ActionType = 1 
		ORDER	BY RPRPShared.ReportID, RPRPShared.DisplaySeq;

        IF OBJECT_ID('tempdb..#Groups', 'U') IS NOT NULL 
            DROP TABLE #Groups ;
        IF OBJECT_ID('tempdb..#Reports', 'U') IS NOT NULL 
            DROP TABLE #Reports ;
	
    END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetToolbarActions] TO [public]
GO
