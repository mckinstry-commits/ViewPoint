SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vspVPMenuGetCompanySubFolderItems]
/**************************************************
* Created: GG 07/11/03
* Modified: JRK 12/19/03 - RPRTShared no longer has an IconKey field so select null instead.
* Modified: JRK 01/20/04 - Include ReportType and CustomReport and RptOwner.  Needed for displaying
*  different columns in the ListView of the menu.
*			GG 02/09/04 - return Y/N indicating SQL Reporting Services report for all items 
*			JRK 1/26/06 - Return IconKey for report items.
*			JRK 4/12/06 - FormType 9 is Setup.
*			CC	07/09/09 - #129922 - Added link for form header to culture text
*			CC 07/15/09 - Issue #133695 - Hide forms that are not applicable to the current country
*			AMR 06/22/11 - Issue TK-07089, Fixing performance issue with if exists statement.
*
* Used by VPMenu to list all forms and reports assigned to the company-defined
* ('our Viewpoint') or any of its sub-folders.  Resultset includes 'Accessible' flag
* to indicate whether the user is allowed to run the form or report in the 
* given Company. 
*
* In vDDSI, Co will be non-zero for the company-specific items, and VPUserName and
* Mod will be "".  In this proc we will select icons that have the specified Co nbr and
* SubFolder nbr.
* (For other modules, including My Viewpoint, Co will be zero and VPUserName and Mod
*  will not be the empty string.)
*
* Inputs:
*	@co			Active Company # - needed for selection and security
*	@subfolder		Sub-Folder ID# - 0 used for module level items
* Output:
*	resultset of users' accessible items for the sub folder
*
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
    (
      @co bCompany = NULL ,
      @subfolder SMALLINT = NULL ,
      @culture INT = NULL ,
      @country CHAR(2) = NULL ,
      @errmsg VARCHAR(512) OUTPUT
    )
AS 
    SET nocount ON 

    DECLARE @rcode INT ,
        @user bVPUserName ,
        @opencursor TINYINT ,
        @itemtype CHAR(1) ,
        @menuitem VARCHAR(30) ,
        @access TINYINT ,
        @reportid INT

    IF @co IS NULL
        OR @subfolder IS NULL 
        BEGIN
            SELECT  @errmsg = 'Missing required input parameters: Company # and/or Sub-Folder!'
								+ CHAR(13) + CHAR(10)
								+ '[vspVPMenuGetCompanySubFolderItems]' ,
                    @rcode = 1
            RETURN @rcode
        END

    IF @co = 0 
        BEGIN
            SELECT  @errmsg = 'Company cannot be zero!' 
								+ CHAR(13) + CHAR(10)
								+ '[vspVPMenuGetCompanySubFolderItems]' ,
                    @rcode = 1
            RETURN @rcode
        END

    SELECT  @rcode = 0 ,
            @user = SUSER_SNAME()

-- use a local table to hold all Forms and Reports for the Sub-Folder
    DECLARE @allitems TABLE
        (
          ItemType CHAR(1) ,
          MenuItem VARCHAR(30) ,
          Title VARCHAR(60) ,
          IconKey VARCHAR(20) ,
          FormOrReportType VARCHAR(10) ,
          RptOwner VARCHAR(128) ,
          CustomReport CHAR(1) ,
          MenuSeq INT ,
          LastAccessed DATETIME ,
          Accessible CHAR(1) ,
          AssemblyName VARCHAR(50) ,
          FormClassName VARCHAR(50) ,
          Custom TINYINT ,
          AppType VARCHAR(30)
        )

/* 
 		Load Forms  
 - Set CustomReport to null for all forms.
 - Set RptOwner to null for all forms, per Gail and Carol.
 - FormOrReportType has logic described below.
*/

    INSERT  @allitems
            ( ItemType ,
              MenuItem ,
              Title ,
              IconKey ,
              FormOrReportType ,
              RptOwner ,
              MenuSeq ,
              LastAccessed ,
              Accessible ,
              AssemblyName ,
              FormClassName ,
              Custom ,
              AppType
            )
            SELECT DISTINCT
                    'F' ,
                    i.MenuItem ,
                    ISNULL(CultureText.CultureText, f.Title) AS Title ,
                    f.IconKey , 
 /* 
   FormOrReportType, when used for forms:
   - User Defined programs have Form names beginning with "UD".
     "User Defined" is more than 10 chars, out output "UserDefine".
   - If not UD, get the value from the FormType field.
     It stores tinyints (1, 2 or 3), so map to friendly strings.
 */
                    CASE SUBSTRING(f.Form, 1, 2)
                      WHEN 'UserDefine' THEN 'UD'
                      ELSE CASE f.FormType
                             WHEN 1 THEN 'Setup'
                             WHEN 2 THEN 'Posting'
                             WHEN 3 THEN 'Processing'
                             WHEN 4 THEN 'Post Dtl'
                             WHEN 5 THEN 'Batch Proc'
                             WHEN 6 THEN 'Detail'
                             WHEN 7 THEN 'Batch Proc'
                             WHEN 8 THEN 'Setup'
                             WHEN 9 THEN 'Setup'
                             ELSE ''
                           END
                    END ,
                    NULL ,
                    i.MenuSeq ,
                    u.LastAccessed ,
                    'Y' ,
                    f.AssemblyName ,
                    f.FormClassName ,
                    0 ,
                    'N'
            FROM    vDDSI i
                    JOIN DDFHShared f ON f.Form = i.MenuItem
                    JOIN DDMFShared m ON m.Form = i.MenuItem
                    LEFT JOIN DDFU u ON u.VPUserName = @user
                                        AND u.Form = i.MenuItem
                    LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture
                                                              AND CultureText.TextID = f.TitleID
                    LEFT OUTER JOIN dbo.DDFormCountries ON f.Form = dbo.DDFormCountries.Form
            WHERE   i.Co = @co
                    AND i.SubFolder = @subfolder
                    AND i.ItemType = 'F' -- Different WHERE than for User SubFolders.
                    AND ( dbo.DDFormCountries.Country = @country
                          OR dbo.DDFormCountries.Country IS NULL
                        )


/*
 		Load Reports
*/
    INSERT  @allitems
            ( ItemType ,
              MenuItem ,
              Title ,
              IconKey ,
              FormOrReportType ,
              RptOwner ,
              MenuSeq ,
              LastAccessed ,
              Accessible ,
              AssemblyName ,
              FormClassName ,
              Custom ,
              AppType
            )
            SELECT  'R' ,
                    i.MenuItem ,
                    r.Title ,
                    IconKey ,
                    r.ReportType ,
 /*
 RptOwner:
 - RPRTShared now has a "Custom" field that indicates there is a custom report was
   set up, so there is a record in vRPRTc for it.
   If Custom = 1, then we return either "VP" or "User".  All custom reports
   with "viewpointcs" in the ReportOwner field of RPRTShared were modified
   by Viewpoint, so we'll display "VP".  Otherwise a user at the customer
   site created/modified the report and we'll display the text "User".
 */
                    CASE r.Custom
                      WHEN 1 THEN CASE r.ReportOwner
                                    WHEN 'viewpointcs' THEN 'VP'
                                    ELSE 'User'
                                  END
                      ELSE NULL
                    END ,
                    ISNULL(i.MenuSeq, 0) MenuSeq ,
                    u.LastAccessed ,
                    'Y' ,
                    NULL ,
                    NULL ,
                    r.Custom ,
                    r.AppType
            FROM    vDDSI i
					CROSS APPLY (SELECT * FROM dbo.vfRPRTShared(CONVERT(INT, i.MenuItem))) r
                    LEFT JOIN RPUP u ON u.VPUserName = @user
                                        AND u.ReportID = CONVERT(INT, i.MenuItem)
            WHERE   i.Co = @co
                    AND i.SubFolder = @subfolder
                    AND i.ItemType = 'R' -- Different WHERE than for User SubFolders.
                    AND ( r.Country = @country
                          OR r.Country IS NULL
                        )

    IF @user <> 'viewpointcs' 	-- Viewpoint system user has access to all forms 
    BEGIN
		-- create a cursor to process each Item
		DECLARE vcItems CURSOR
		FOR
			SELECT  ItemType ,
					MenuItem
			FROM    @allitems

			OPEN vcItems
			SET @opencursor = 1

		-- check Security for each Menu Item
		FETCH NEXT FROM vcItems INTO @itemtype, @menuitem
		WHILE @@fetch_status = 0 
		BEGIN
			IF @itemtype = 'F' 
				EXEC @rcode = vspDDFormSecurity @co, @menuitem, @access OUTPUT,
					@errmsg = @errmsg OUTPUT
					
			IF @rcode <> 0 
			BEGIN
				CLOSE vcItems
				DEALLOCATE vcItems
				SELECT  @errmsg = @errmsg + CHAR(13) + CHAR(10)
					+ '[vspVPMenuGetCompanySubFolderItems]'
				RETURN @rcode
			END
			
			IF @itemtype = 'R' 
				BEGIN
					SET @reportid = CONVERT(INT, @menuitem)
					EXEC @rcode = vspRPReportSecurity @co, @reportid, @access OUTPUT,
						@errmsg = @errmsg OUTPUT
					IF @rcode <> 0 
					BEGIN
						CLOSE vcItems
						DEALLOCATE vcItems
						SELECT  @errmsg = @errmsg + CHAR(13) + CHAR(10)
							+ '[vspVPMenuGetCompanySubFolderItems]'
						RETURN @rcode
					END
				END
			
			UPDATE  @allitems
			SET     Accessible = CASE WHEN @access IN ( 0, 1 ) THEN 'Y'
									  ELSE 'N'
								 END
			WHERE   ItemType = @itemtype
					AND MenuItem = @menuitem
					
			FETCH NEXT FROM vcItems INTO @itemtype, @menuitem
		END
	
		CLOSE vcItems
		DEALLOCATE vcItems
		SELECT  @opencursor = 0
	END
	
    SELECT  ItemType ,
            MenuItem ,
            Title ,
            IconKey ,
            FormOrReportType ,
            RptOwner ,
            MenuSeq ,
            LastAccessed ,
            Accessible ,
            AssemblyName ,
            FormClassName ,
            AppType
    FROM    @allitems
    ORDER BY MenuSeq ,
            Title
   
   
    RETURN @rcode
	

GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetCompanySubFolderItems] TO [public]
GO
