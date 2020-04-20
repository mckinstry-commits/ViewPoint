SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspDDFormInfo]    
/********************************    
* Created: GG 06/09/03     
* Modified: MV 10/24/06 changed ColumnName to varchar(500) from 256    
*   RM 03/15/07 issue #120842 Remove tabs from results if they have a gridform, and access to the underlying form is denied    
*   JK 03/26/07 Read field FormHelpFile.    
*   GG 05/04/07 - if Report has any Form Parameter Defaults return all Report Params    
*   GG 09/07/07 - #125347 - mods for secure form links    
*   GG 09/21/07 - #125526 - return parameter defaults from accessible reports only    
*   JK 11/06/07 - #125885 - return (new) OriginalGridColHeading    
*   GG 11/13/07 - #126121 - fix to recognize fields on UD form as custom    
*   AL 1/3/08 - #126595 - fix to properly set assembly for custom fields.    
*   CC 04/08/08 - #127214 - Added support for localized labels.    
*   RM 04/25/08 - Add related tab links    
*   GF 05/31/08 - issue #128466 problems with datatype security for PM Projects using (bJCJM)  
* 	DC 10/20/08 - issue #129914 Added FilterOption in 1st resultset  
* 	CC 10/27/08 - Issue #129817 Remove culture override from datatypes  
* 	JonathanP 02/25/09 - #132390 - Updated to handle attachment security level column in DDFS  
* 	DC 3/24/2009 - # 127948 - Put in an additional resultset to give more information about Tabs that are removed due to Tab security  
* 	JonathanP 04/22/09 - #133379 - The field resultset now joins on UDTC to try and order the columns for UD forms.  
* 	CC 07/02/09 - #129922 - Added link for form header to culture text
* 	Dave C 09/15/2009 - ##135238 - Returning columns to track whether a form should be able to launch the "Form Properties"
*				  form, or the "Field Properties" form, in result set 1
*	CC 10/06/09  - #135075 - Added exclude from copy field
*	JVH 10/29/09 - #127862 - Added custom grid column heading field
*	CC 01/07/10	 - #135020 - Include limit record property
*   TEJ 02/24/10 - #137817 - Expanded the size of the GridColHeading for recordset 5. Because it defaulting to the
*                            Culture text if it existed, if the text was longer than 30 characters the Stored
*                            Proc was choking on it because it had to truncate.
*	AMR 02/3/11 - Issue #142350, making case sensitive by aliasing the datatype column so it is not ambigious
*	AMR 06/22/11 - Issue ?, Fixing performance issue with if exists statement.
*	AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function.
*   Kene - 1/12/2012 - B-07352 - Added the collection of the OpenAttachmentViewer column from DDFU for adding the enhancement from D-01584
*	AMR - 1/18/2012 - TK-11843 - Removing the extra cross apply that is not needed because we build the @formreports with this to begin with
*   Kene - 4/24/2012 - B-07352 - Added the collection of the FormattedNotesTab column from DDFH for marking the tab for formatted notes*    
*   Kene - 5/8/2012 - B-07352 - Added the collection of Type from the DDFTc table
*   TEJ - 5/24/2012 - B-09595 - Added ButtonRefresh as part of the CustomButton load
*	AMR - 4/15/2013 - 44990 - Widening the ViewName column
*    
* Called from the VPForm Class to retrieve all DD Form Header, Tab, and Input info needed to     
* load a Viewpoint form.    
*    
* Input:    
* @co  Current active company #    
* @form Form name    
*    
* Output:    
* Multiple resultsets - 1st: Form Header info    
*      - 2nd: Tab Link Info  
*    - 3rd: Form Tab info    
*      - 4th: Form Inputs (field info)    
*      - 5th: Form Input Lookup Headers    
*      - 6th: Custom Group Box controls    
*      - 7th: ComboBox Items    
*      - 8th: Accessible Form Reports     
*      - 9th: Form Report Parameter Defaults    
*    -10th: Form Buttons  
*    -11th: Form Button Parameters  
*    
* Return code:    
* 0 = success, 1 = failure    
*    
*********************************/
    (
      @co bCompany = NULL ,
      @form VARCHAR(30) = NULL ,
      @culture INT = NULL ,
      @errmsg VARCHAR(512) OUTPUT
    )
AS 
    SET nocount ON    
    
    DECLARE @rcode INT ,
        @datasecurity bYN ,
        @datatype VARCHAR(30) ,
        @qualifiercolumn VARCHAR(30) ,
        @mastercolumn VARCHAR(30) ,
        @dfltsecuritygroup INT ,
        @formaccess TINYINT ,
        @recadd bYN ,
        @recupdate bYN ,
        @recdelete bYN ,
        @attachmentSecurityLevel INT ,
        @opencursor TINYINT ,
        @tab TINYINT ,
        @tabaccess TINYINT ,
        @showonmenu bYN ,
        @reportid INT ,
        @openreportcursor TINYINT ,
        @access TINYINT ,
        @errmsg2 VARCHAR(512) ,
        @secureform VARCHAR(30) ,
        @detailformsecurity bYN    
    
    SELECT  @rcode = 0 ,
            @datasecurity = 'N' ,
            @dfltsecuritygroup = 0 ,
            @formaccess = 0 ,
            @recadd = 'Y' ,
            @recupdate = 'Y' ,
            @recdelete = 'Y' ,
            @attachmentSecurityLevel = -1    
    
    IF @co IS NULL
        OR @form IS NULL 
        BEGIN    
            SELECT  @errmsg = 'Missing required input parameters: Company # and/or Form!' ,
                    @rcode = 1    
            GOTO vspexit    
        END    
-- check Form Security info    
    EXEC @rcode = vspDDFormSecurity @co, @form, @formaccess OUTPUT,
        @recadd OUTPUT, @recupdate OUTPUT, @recdelete OUTPUT,
        @attachmentSecurityLevel OUTPUT, @errmsg OUTPUT    
    IF @rcode <> 0 
        GOTO vspexit     
    IF @formaccess NOT IN ( 0, 1 )
        OR @formaccess IS NULL 
        SET @formaccess = 2 -- denied    
    
-- get Secure Form and Detail Security info    
    SELECT  @secureform = SecurityForm ,
            @detailformsecurity = DetailFormSecurity
    FROM    dbo.DDFHShared (NOLOCK)
    WHERE   Form = @form    
    IF @@rowcount = 0 
        BEGIN    
            SELECT  @errmsg = 'Invalid Form!' ,
                    @rcode = 1    
            GOTO vspexit    
        END    
    
-- get Data Security info related to this form    
    SELECT  @datasecurity = 'Y' ,
            @datatype = d.Datatype ,
            @qualifiercolumn = d.QualifierColumn ,
            @mastercolumn = d.MasterColumn ,
            @dfltsecuritygroup = d.DfltSecurityGroup
    FROM    dbo.DDDTShared d ( NOLOCK ) ---- issue #128466    
            JOIN dbo.DDFHShared f ( NOLOCK ) ON SUBSTRING(f.ViewName, 1, 4) = SUBSTRING(d.MasterTable,
                                                              2, 4) -- Form's view matches Datatype's master table    
    WHERE   f.Form = @form
            AND d.Secure = 'Y'  -- Datatype must be secured    
    
    
-- 1st resultset - return Form Header and Security info    
    SELECT  s.Form ,
            ISNULL(CultureText.CultureText, s.Title) AS Title ,
            s.FormType ,
            s.ViewName ,
            s.JoinClause ,
            s.WhereClause ,
            s.HelpFile ,
            s.HelpKeyword ,
            s.ProgressClip ,
            u.Options ,
            ISNULL(u.DefaultTabPage, s.DefaultTabPage) AS DefaultTabPage ,
            ISNULL(u.FormPosition, '') AS FormPosition ,
            ISNULL(u.GridRowHeight, 0) AS GridRowHeight ,
            u.SplitPosition AS SplitPosition ,
            @formaccess AS FormAccess ,
            @recadd AS RecAdd ,
            @recupdate AS RecUpdate ,
            @recdelete AS RecDelete ,
            @attachmentSecurityLevel AS AttachmentSecurityLevel ,
            @datasecurity AS DataSecurity ,
            @datatype AS SecureDatatype ,
            @mastercolumn AS MasterColumn ,
            @qualifiercolumn AS QualifierColumn ,
            @dfltsecuritygroup AS DfltSecurityGroup ,
            s.AssemblyName AS AssemblyName ,
            s.FormClassName AS FormClassName ,
            s.NotesTab ,
            s.FormattedNotesTab ,
            ISNULL(s.LoadProc, '') AS LoadProc ,
            ISNULL(s.LoadParams, '') AS LoadParams ,
            ISNULL(s.PostedTable, '') AS PostedTable ,
            ISNULL(s.AllowAttachments, 'N') AS AllowAttachments ,
            s.HasProgressIndicator ,
            s.ShowOnMenu ,
            s.CoColumn ,
            ISNULL(x.AssemblyName, '') AS BatchProcessAssemblyname ,
            ISNULL(x.FormClassName, '') AS BatchProcessFormClassname ,
            ISNULL(s.OrderByClause, '') AS OrderByClause ,
            s.Mod AS FormModule ,
            u.FilterOption ,
            u.OpenAttachmentViewer ,
            m.HelpKeyword AS ModHelpKeyword ,
            s.ShowFormProperties ,
            s.ShowFieldProperties ,
            ISNULL(u.LimitRecords, 'N') AS LimitRecords
    FROM    dbo.DDFHShared s ( NOLOCK )
            LEFT OUTER JOIN dbo.vDDFU u ( NOLOCK ) ON u.VPUserName = SUSER_SNAME()
                                                      AND u.Form = s.Form
            LEFT JOIN dbo.vDDFH x ( NOLOCK ) ON x.Form = s.BatchProcessForm
            LEFT OUTER JOIN vDDMO m ( NOLOCK ) ON s.Mod = m.Mod
            LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture
                                                         AND CultureText.TextID = s.TitleID
    WHERE   s.Form = @form    
    
    
-- hold all Tab info in local table variable until security can be determined    
-- access to related grid tabs determined by form security    
    DECLARE @formtabs TABLE
        (
          Tab TINYINT ,
          Title VARCHAR(30) ,
          GridForm VARCHAR(30) ,
          TabAccess TINYINT ,
          Custom CHAR(1) ,
          LoadSeq TINYINT ,
          QueryName varchar(50),
          [Type] TINYINT ,
          IsStandard CHAR(1) ,
          IsVisible CHAR(1) ,
          RelatedFormsExistForRelated CHAR(1)
        )    
   
  -- hold Tab info that was removed from the above table based on access level  
    DECLARE @deniedformtabs TABLE
        (
          Tab TINYINT ,
          Title VARCHAR(30) ,
          GridForm VARCHAR(30) ,
          TabAccess TINYINT ,
          Custom CHAR(1) ,
          LoadSeq TINYINT ,
          QueryName varchar(50),
          [Type] TINYINT ,
          IsStandard CHAR(1) ,
          IsVisible CHAR(1) ,
          RelatedFormsExistForRelated CHAR(1)
        )  
   
   
    
    INSERT  @formtabs
            ( Tab ,
              Title ,
              GridForm ,
              TabAccess ,
              Custom ,
              LoadSeq ,
              IsStandard ,
              QueryName ,
              [Type] ,
              IsVisible ,
              RelatedFormsExistForRelated
            )
            SELECT  t.Tab ,
                    t.Title ,
                    t.GridForm ,
                    0 ,
                    t.Custom ,
                    t.LoadSeq , -- assume full access    
                    t.IsStandard ,
                    t.QueryName ,
                    t.[Type] ,
                    t.IsVisible ,
                    'N'
            FROM    dbo.DDFTShared t ( NOLOCK )
            WHERE   t.Form = @form
            ORDER BY t.LoadSeq    
    
-- use a cursor to get access level for each Tab    
    DECLARE vcTabSecurity CURSOR
    FOR
        SELECT  Tab ,
                GridForm
        FROM    @formtabs    
    
    OPEN vcTabSecurity    
    SET @opencursor = 1    
    
    DECLARE @RelatedFormsExistForRelated CHAR(1) ,
        @tabgridform VARCHAR(30)    
 
-- loop through all Tabs on the Form    
    tab_loop:    
    FETCH NEXT FROM vcTabSecurity INTO @tab, @tabgridform    
    IF @@fetch_status <> 0 
        GOTO tab_loop_end    
    
    SELECT  @tabaccess = 0 ,
            @RelatedFormsExistForRelated = 'N'    
    
 -- access to related Grid tabs determined by Form Security    
    IF @tabgridform IS NOT NULL 
        BEGIN    
            EXEC @rcode = vspDDFormSecurity @co, @tabgridform,
                @tabaccess OUTPUT, NULL, NULL, NULL, -1, @errmsg OUTPUT    
            IF @rcode <> 0
                OR ISNULL(@tabaccess, 2) = 2 --Denied, will return null if security not setup for form    
                BEGIN    
     
                    INSERT  INTO @deniedformtabs
                            SELECT  *
                            FROM    @formtabs
                            WHERE   Tab = @tab -- add tab to deniedtabs  
                    DELETE  @formtabs
                    WHERE   Tab = @tab -- remove tab from resultset so user won't have access to it    
                    GOTO tab_loop    
                END    
  -- determine if the related Grid tab has any related Grids of its own, used with cascading deletes    
            IF EXISTS ( SELECT TOP 1
                                1
                        FROM    dbo.DDFTShared (NOLOCK)
                        WHERE   Form = @tabgridform
                                AND GridForm IS NOT NULL ) 
                BEGIN     
                    SELECT  @RelatedFormsExistForRelated = 'Y'    
                END    
        END    
    ELSE 
        BEGIN    
  -- if form is secured by tab check access to other tabs excluding primary grid tab     
            IF @tab > 0
                AND @formaccess = 1
                AND ( @secureform = @form
                      OR @detailformsecurity = 'Y'
                    ) -- tab security not valid on forms whose security in based on other forms    
                BEGIN    
                    EXEC @rcode = vspDDTabSecurity @co, @form, @tab,
                        @tabaccess OUTPUT, @errmsg OUTPUT    
                    IF @rcode <> 0
                        OR @tabaccess = 2 --Denied    
                        BEGIN    
      
                            INSERT  INTO @deniedformtabs
                                    SELECT  *
                                    FROM    @formtabs
                                    WHERE   Tab = @tab -- add tab to deniedtabs     
                            DELETE  @formtabs
                            WHERE   Tab = @tab --remove tab from resultset so user won't have access to it    
                            GOTO tab_loop    
                        END    
                END    
        END    
    
    UPDATE  @formtabs
    SET     TabAccess = @tabaccess ,
            RelatedFormsExistForRelated = @RelatedFormsExistForRelated -- save Tab Access level    
    WHERE   Tab = @tab    
      
    GOTO tab_loop    
    
    tab_loop_end: -- processed all Tabs on the Form    
    CLOSE vcTabSecurity    
    DEALLOCATE vcTabSecurity    
    SET @opencursor = 0    
 --end    
    
-- 2rd resultset - return related tab field links    
-- Needs to be brought back before Tab info so that it can be     
-- used during the loop where we are setting up tabs.    
    SELECT  s.Tab ,
            s.GridKeySeq ,
            s.ParentFieldSeq
    FROM    DDRelatedFormsShared s
            JOIN @formtabs t ON s.Tab = t.Tab
    WHERE   s.Form = @form    
    
  
-- 3rd resultset - return denied Form Tabs  
    SELECT  Tab ,
            Title ,
            GridForm ,
            TabAccess ,
            Custom ,
            LoadSeq ,
            IsStandard ,
            IsVisible ,
            RelatedFormsExistForRelated
    FROM    @deniedformtabs
    ORDER BY LoadSeq   
  
-- 4th resultset - return Form Tabs with Security info    
    SELECT  FormTabs.Tab ,
            ISNULL(CultureText.CultureText, FormTabs.Title) AS CultureTitle ,
            FormTabs.Title ,
            FormTabs.GridForm ,
            TabAccess ,
            Custom ,
            FormTabs.LoadSeq ,
            IsStandard ,
            IsVisible ,
            FormTabs.QueryName ,
            FormTabs.[Type] ,
            RelatedFormsExistForRelated
    FROM    @formtabs AS FormTabs
            LEFT OUTER JOIN DDFT ON FormTabs.Title = dbo.DDFT.Title
                                    AND FormTabs.Tab = dbo.DDFT.Tab
                                    AND dbo.DDFT.Form = @form
                                    AND FormTabs.IsStandard = 'Y'
            LEFT OUTER JOIN dbo.DDCTShared AS CultureText ON dbo.DDFT.TitleID = CultureText.TextID
                                                             AND CultureText.CultureID = @culture
    ORDER BY LoadSeq    
     
-- declare Form Inputs table to return currrent, standard, custom, and user input properties    
    DECLARE @forminputs TABLE
        (
          AutoSeq TINYINT ,
          ColumnName VARCHAR(500) ,
          ControlType TINYINT ,
          ControlPosition VARCHAR(20) ,
          CustDefaultType TINYINT ,
          CustDefaultValue VARCHAR(256) ,
          CustGridCol SMALLINT ,
          CustInputSkip CHAR(1) ,
          CustSetupForm VARCHAR(30) ,
          CustSetupParams VARCHAR(256) ,
          CustShowOnForm CHAR(1) ,
          CustShowOnGrid CHAR(1) ,
          CustValLevel TINYINT ,
          CustValParams VARCHAR(256) ,
          CustValProc VARCHAR(60) ,
          CustReq CHAR(1) ,
          CustTab TINYINT ,
          CustTabIndex SMALLINT ,
          Datatype VARCHAR(30) ,
          DatatypeLabel VARCHAR(30) ,
          CultureLabel VARCHAR(250) ,
          Description VARCHAR(60) ,
          DescriptionCol VARCHAR(256) ,
          FieldType TINYINT ,
          FormLabel VARCHAR(30) ,
          HelpKeyword VARCHAR(60) ,
          InputLength SMALLINT ,
          InputMask VARCHAR(30) ,
          InputType TINYINT ,
          IsCustom CHAR(1) ,
          LabelDescColumnName VARCHAR(256) ,
          Prec TINYINT ,
          Secure CHAR(1) ,
          Seq SMALLINT ,
          StatusText VARCHAR(256) ,
          StdGridCol SMALLINT ,
          StdReq CHAR(1) ,
          StdSetupForm VARCHAR(30) ,
          StdSetupParams VARCHAR(256) ,
          StdTab TINYINT ,
          StdValLevel TINYINT ,
          StdValParams VARCHAR(256) ,
          StdValProc VARCHAR(60) ,
          UpdateGroup VARCHAR(20) ,
          UserColWidth SMALLINT ,
          UserDefaultType TINYINT ,
          UserDefaultValue VARCHAR(256) ,
          UserGridCol SMALLINT ,
          UserShowOnForm CHAR(1) ,
          UserShowOnGrid CHAR(1) ,
          UserInputSkip CHAR(1) ,
          UserReq CHAR(1) ,
          ViewName VARCHAR(257) ,
          StdSetupAssemblyName VARCHAR(50) ,
          StdSetupFormClassName VARCHAR(60) ,
          CustSetupAssemblyName VARCHAR(50) ,
          CustSetupFormClassName VARCHAR(60) ,
          CustMinValue VARCHAR(20) ,
          CustMaxValue VARCHAR(20) ,
          CustValExpression VARCHAR(256) ,
          CustValExpError VARCHAR(256) ,
          StdMinValue VARCHAR(20) ,
          StdMaxValue VARCHAR(20) ,
          StdValExpression VARCHAR(256) ,
          StdValExpError VARCHAR(256) ,
          StdShowOnForm CHAR(1) ,
          StdShowOnGrid CHAR(1) ,
          GridColHeading VARCHAR(250) ,
          OriginalGridColHeading VARCHAR(30) ,
          UserShowDesc TINYINT ,
          HeaderLinkSeq SMALLINT ,
          CustControlSize VARCHAR(20) ,
          DescriptionColWidth SMALLINT ,
          Computed CHAR(1) ,
          StdShowDesc TINYINT ,
          CustShowDesc TINYINT ,
          StdColWidth SMALLINT ,
          StdDescriptionColWidth SMALLINT ,
          StdIsFormFilter CHAR(1) ,
          CustomIsFormFilter CHAR(1) ,
          ExcludeFromRecordCopy CHAR(1) ,
          CustomGridColHeading VARCHAR(30)
        )    
    
-- insert current and user override values    
    INSERT  @forminputs
            ( AutoSeq ,
              ColumnName ,
              ControlType ,
              ControlPosition ,
              CustDefaultType ,
              CustDefaultValue ,
              CustGridCol ,
              CustInputSkip ,
              CustSetupForm ,
              CustSetupParams ,
              CustShowOnForm ,
              CustShowOnGrid ,
              CustValLevel ,
              CustValParams ,
              CustValProc ,
              CustReq ,
              CustTab ,
              CustTabIndex ,
              Datatype ,
              DatatypeLabel ,
              CultureLabel ,
              Description ,
              DescriptionCol ,
              FieldType ,
              FormLabel ,
              HelpKeyword ,
              InputLength ,
              InputMask ,
              InputType ,
              IsCustom ,
              LabelDescColumnName ,
              Prec ,
              Secure ,
              Seq ,
              StatusText ,
              StdGridCol ,
              StdReq ,
              StdSetupForm ,
              StdSetupParams ,
              StdTab ,
              StdValLevel ,
              StdValParams ,
              StdValProc ,
              UpdateGroup ,
              UserColWidth ,
              UserDefaultType ,
              UserDefaultValue ,
              UserGridCol ,
              UserShowOnForm ,
              UserShowOnGrid ,
              UserInputSkip ,
              UserReq ,
              ViewName ,
              StdSetupAssemblyName ,
              StdSetupFormClassName ,
              CustSetupAssemblyName ,
              CustSetupFormClassName ,
              StdShowOnForm ,
              StdShowOnGrid ,
              GridColHeading ,
              OriginalGridColHeading ,
              UserShowDesc ,
              HeaderLinkSeq ,
              CustControlSize ,
              DescriptionColWidth ,
              Computed ,
              StdShowDesc ,
              CustShowDesc ,
              StdColWidth ,
              StdDescriptionColWidth ,
              StdIsFormFilter ,
              CustomIsFormFilter ,
              ExcludeFromRecordCopy ,
              CustomGridColHeading
            )
            SELECT  ISNULL(s.AutoSeqType, 0) ,
                    ISNULL(s.ColumnName, '') ,
                    ISNULL(s.ControlType, 99) ,
                    ISNULL(s.ControlPosition, '') ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    ISNULL(s.Datatype, '') ,
                    d.Label ,
                    c1.CultureText ,
                    ISNULL(s.Description, '') ,
                    ISNULL(s.DescriptionColumn, '') ,
                    ISNULL(s.FieldType, 0) ,
                    s.Label ,
                    ISNULL(s.HelpKeyword, '') ,
                    COALESCE(s.InputLength, d.InputLength, 0) ,
                    COALESCE(s.InputMask, d.InputMask, '') ,
                    ISNULL(s.InputType, d.InputType) ,
                    s.Custom , --#126121 - use custom flag     
                    ISNULL(s.DescriptionColumn, '') ,
                    COALESCE(s.Prec, d.Prec, 0) ,
                    CASE WHEN d.Secure = 'Y' THEN 'Y'
                         ELSE 'N'
                    END ,
                    s.Seq ,
                    ISNULL(s.StatusText, '') ,
                    0 ,
                    'N' ,
                    NULL ,
                    NULL ,
                    0 ,
                    0 ,
                    NULL ,
                    NULL ,
                    s.UpdateGroup ,
                    u.ColWidth ,
                    u.DefaultType ,
                    u.DefaultValue ,
                    u.GridCol ,
                    u.ShowForm ,
                    u.ShowGrid ,
                    u.InputSkip ,
                    u.InputReq ,
                    ISNULL(s.ViewName, '') ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,  /*coalesce(d.Label,s.Label, s.GridColHeading,'')*/
                    COALESCE(c2.CultureText, s.GridColHeading, '') ,
                    NULL ,
                    u.ShowDesc ,
                    s.HeaderLinkSeq ,
                    s.CustomControlSize ,
                    u.DescriptionColWidth ,
                    s.Computed ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    NULL ,
                    s.ExcludeFromRecordCopy ,
                    s.CustomGridColHeading
                    -- use inline table for perf
            FROM    dbo.vfDDFIShared(@form) s
                    LEFT OUTER JOIN dbo.vDDUI u ( NOLOCK ) ON u.VPUserName = SUSER_SNAME()
                                                              AND u.Form = s.Form
                                                              AND u.Seq = s.Seq
                    LEFT OUTER JOIN dbo.DDDTShared d ( NOLOCK ) ON d.Datatype = s.Datatype
                    LEFT OUTER JOIN DDCTShared c1 WITH ( NOLOCK ) ON s.LabelTextID = c1.TextID
                                                              AND c1.CultureID = @culture
                    LEFT OUTER JOIN DDCTShared c2 WITH ( NOLOCK ) ON s.ColumnTextID = c2.TextID
                                                              AND c2.CultureID = @culture
    
-- update with standard property values    
    UPDATE  @forminputs
    SET     StdGridCol = ISNULL(s.GridCol, 0) ,
            StdReq = s.Req ,
            StdSetupForm = ISNULL(s.SetupForm, d.SetupForm) ,
            StdSetupParams = s.SetupParams ,
            StdTab = s.Tab ,
            StdValLevel = s.ValLevel ,
            StdValParams = s.ValParams ,
            StdValProc = s.ValProc ,
            StdSetupAssemblyName = CASE WHEN s.SetupForm IS NOT NULL
                                        THEN h.AssemblyName
                                        ELSE h2.AssemblyName
                                   END ,
            StdSetupFormClassName = CASE WHEN s.SetupForm IS NOT NULL
                                         THEN h.FormClassName
                                         ELSE h2.FormClassName
                                    END ,
            StdMinValue = s.MinValue ,
            StdMaxValue = s.MaxValue ,
            StdValExpression = s.ValExpression ,
            StdValExpError = s.ValExpError ,
            StdShowOnForm = s.ShowForm ,
            StdShowOnGrid = s.ShowGrid ,
            StdShowDesc = s.ShowDesc ,
            StdColWidth = s.ColWidth ,
            StdDescriptionColWidth = s.DescriptionColWidth ,
            StdIsFormFilter = s.IsFormFilter ,
            OriginalGridColHeading = s.GridColHeading
    FROM    @forminputs f --join vDDFI s on s.Form = @form and s.Seq = f.Seq    
            JOIN dbo.vDDFI s ( NOLOCK ) ON s.Seq = f.Seq
            LEFT JOIN dbo.vDDFH h ( NOLOCK ) ON h.Form = s.SetupForm
            LEFT JOIN dbo.vDDDT d ( NOLOCK ) ON d.Datatype = s.Datatype
            LEFT JOIN dbo.vDDFH h2 ( NOLOCK ) ON d.SetupForm = h2.Form
    WHERE   s.Form = @form     
-- update with custom (site overrides) property values    
    UPDATE  @forminputs
    SET     CustDefaultType = c.DefaultType ,
            CustDefaultValue = c.DefaultValue ,
            CustGridCol = c.GridCol ,
            CustInputSkip = c.InputSkip ,
            CustSetupForm = c.SetupForm ,
            CustSetupParams = c.SetupParams ,
            CustShowOnForm = c.ShowForm ,
            CustShowOnGrid = c.ShowGrid ,
            CustValLevel = c.ValLevel ,
            CustValParams = c.ValParams ,
            CustValProc = c.ValProc ,
            CustReq = c.Req ,
            CustTab = c.Tab ,
            CustTabIndex = c.TabIndex ,
            CustSetupAssemblyName = h.AssemblyName ,
            CustSetupFormClassName = h.FormClassName ,
            CustMinValue = c.MinValue ,
            CustMaxValue = c.MaxValue ,
            CustValExpression = c.ValExpression ,
            CustValExpError = c.ValExpError ,
            CustShowDesc = c.ShowDesc ,
            CustomIsFormFilter = c.IsFormFilter
    FROM    @forminputs f --join vDDFIc c on c.Form = @form and c.Seq = f.Seq    
            JOIN dbo.vDDFIc c ( NOLOCK ) ON c.Seq = f.Seq
            LEFT JOIN dbo.DDFHShared h ( NOLOCK ) ON h.Form = c.SetupForm
    WHERE   c.Form = @form    
    
--#142350 fixing ambigious column    
-- 5th resultset - return Form Inputs    
    SELECT  Seq ,
            ViewName ,
            f.ColumnName ,
            AutoSeq ,
            f.ControlType ,
            ControlPosition ,
            CustDefaultType ,
            CustDefaultValue ,
            CustGridCol ,
            CustInputSkip ,
            CustSetupForm ,
            CustSetupParams ,
            CustSetupAssemblyName ,
            CustSetupFormClassName ,
            CustShowOnForm ,
            CustShowOnGrid ,
            CustValLevel ,
            CustValParams ,
            CustValProc ,
            CustReq ,
            CustTab ,
            CustTabIndex ,
            f.Datatype ,
            DatatypeLabel ,
            CultureLabel ,
            f.Description ,
            DescriptionCol ,
            FieldType ,
            FormLabel ,
            HelpKeyword ,
            f.InputLength ,
            f.InputMask ,
            f.InputType ,
            IsCustom ,
            LabelDescColumnName ,
            f.Prec ,
            Secure ,
            f.StatusText ,
            StdGridCol ,
            StdReq ,
            StdSetupForm ,
            StdSetupParams ,
            StdSetupAssemblyName ,
            StdSetupFormClassName ,
            StdTab ,
            StdValLevel ,
            StdValParams ,
            StdValProc ,
            UpdateGroup ,
            UserColWidth ,
            UserDefaultType ,
            UserDefaultValue ,
            UserGridCol ,
            UserShowOnForm ,
            UserShowOnGrid ,
            UserInputSkip ,
            UserReq ,
            CustMinValue ,
            CustMaxValue ,
            CustValExpression ,
            CustValExpError ,
            StdMinValue ,
            StdMaxValue ,
            StdValExpression ,
            StdValExpError ,
            StdShowOnForm ,
            StdShowOnGrid ,
            GridColHeading ,
            OriginalGridColHeading ,
            UserShowDesc ,
            HeaderLinkSeq ,
            CustControlSize ,
            DescriptionColWidth ,
            Computed ,
            StdShowDesc ,
            CustShowDesc ,
            StdColWidth ,
            StdDescriptionColWidth ,
            StdIsFormFilter ,
            CustomIsFormFilter ,
            f.ExcludeFromRecordCopy ,
            CustomGridColHeading
    FROM    @forminputs f
            LEFT OUTER JOIN UDTC u ON u.TableName = ViewName
                                      AND f.Seq = u.DDFISeq
    ORDER BY COALESCE(u.KeySeq, StdGridCol, CustGridCol) ,
            Seq -- return inputs in grid column order    
--order by coalesce(UserGridCol,CustGridCol,StdGridCol), Seq -- return inputs in grid column order    
    
    
-- 6th resultset - return Form Input Lookup Header info    
-- get standard Datatype or Input Lookup    
    SELECT  s.Seq ,
            d.Lookup AS Lookup ,
            h.Title ,
            s.ActiveLookup AS Active ,
            s.LookupParams ,
            s.LookupLoadSeq AS LoadSeq ,
            'Y' AS StdLookup , -- denotes standard lookup    
            h.FromClause ,
            h.WhereClause ,
            h.JoinClause ,
            h.OrderByColumn ,
            h.GroupByClause
            -- use inline table for perf
    FROM    dbo.vfDDFIShared(@form) s
            LEFT OUTER JOIN dbo.vDDDT d ( NOLOCK ) ON d.Datatype = s.Datatype
            LEFT JOIN dbo.DDLHShared h ( NOLOCK ) ON ( h.Lookup = d.Lookup )
    WHERE   d.Lookup IS NOT NULL
            AND s.ActiveLookup = 'Y'
    UNION    
-- get additional Lookups    
    SELECT  s.Seq ,
            l.Lookup ,
            h.Title ,
            l.Active ,
            l.LookupParams ,
            l.LoadSeq ,
            'N' AS StdLookup ,
            h.FromClause ,
            h.WhereClause ,
            h.JoinClause ,
            h.OrderByColumn ,
            h.GroupByClause
            -- use inline table for perf
    FROM    dbo.vfDDFIShared(@form) s
            JOIN dbo.DDFLShared l ( NOLOCK ) ON s.Form = l.Form
                                                AND s.Seq = l.Seq
            LEFT JOIN dbo.DDLHShared h ( NOLOCK ) ON h.Lookup = l.Lookup
    ORDER BY s.Seq ,
            LoadSeq     
    
-- 7th resultset - Custom group box controls    
    SELECT  Tab ,
            GroupBox ,
            Title ,
            ControlPosition
    FROM    dbo.vDDGBc (NOLOCK)
    WHERE   Form = @form
    ORDER BY Tab ,
            GroupBox    
    
--8th resultset - ComboBoxTypes     
    SELECT  s.Seq AS Seq ,
            c.Seq AS ComboTypeSeq ,
            c.DisplayValue ,
            c.DatabaseValue
            -- use inline table func for perf
    FROM    dbo.vfDDFIShared(@form) s 
            JOIN dbo.DDCIShared c ( NOLOCK ) ON c.ComboType = s.ComboType
    ORDER BY s.Seq ,
            c.Seq    
    
-- hold Form Reports info for 7th resultset in local table variable until Security can be determined    
    DECLARE @formreports TABLE
        (
          ReportID INT ,
          Title VARCHAR(60) ,
          Access TINYINT
        )    
    
    INSERT  @formreports
            ( ReportID,
              Title,
              Access
            )
            SELECT  f.ReportID ,
                    r.Title ,
                    0  -- assume full access    
            FROM    dbo.RPFRShared f ( NOLOCK )
					--use inline table function for performance issue
                    CROSS APPLY (SELECT Title FROM dbo.vfRPRTShared(f.ReportID)) r 
            WHERE   f.Form = @form
                    AND f.Active = 'Y' -- active reports only    
			ORDER BY	r.Title    
    
-- use a cursor to get access level for each Report    
    DECLARE vcReportSecurity CURSOR
    FOR
        SELECT  ReportID
        FROM    @formreports    
    
    OPEN vcReportSecurity    
    SET @openreportcursor = 1    
    
-- loop through all Reports on the Form    
    report_loop:    
    FETCH NEXT FROM vcReportSecurity INTO @reportid    
    
    IF @@fetch_status <> 0 
        GOTO report_loop_end    
    
    EXEC @rcode = vspRPReportSecurity @co, @reportid, @access OUTPUT,
        @errmsg2 OUTPUT    
    IF @rcode <> 0 
        BEGIN    
            SELECT  @errmsg = 'rcode <> 0 returned from vspRPReportSecurity.  @errmsg2='
                    + @errmsg2    
            GOTO vspexit    
        END    
    UPDATE  @formreports
    SET     Access = @access -- save Report Access level    
    WHERE   ReportID = @reportid    
    
    GOTO report_loop    
    
    report_loop_end: -- processed all Reports on the Form    
    CLOSE vcReportSecurity    
    DEALLOCATE vcReportSecurity    
    SET @openreportcursor = 0    
 -- 9th resultset - return accessible Form Reports only    
    SELECT  ReportID ,
            Title
    FROM    @formreports
    WHERE   Access = 0     
    
-- 10th resultset - return Form Report Defaults for the accessible reports    
--select r.Title, d.ReportID, d.ParameterName, d.ParameterDefault    
--from dbo.RPFDShared d (nolock)    
--join @formreports r on r.ReportID = d.ReportID    
--where d.Form = @form    
--order by d.ReportID, d.ParameterName    
-- GG 05/04/07 - if Report has any Form Parameter Defaults return all Report Params    
    SELECT  fr.Title ,
            p.ReportID ,
            p.ParameterName ,
            ISNULL(f.ParameterDefault, p.ParameterDefault) AS ParameterDefault,
			ISNULL(f.UsedForPublish, 0) AS UsedForPublish
    FROM    
			dbo.RPRPShared p ( NOLOCK )
            JOIN @formreports fr ON fr.ReportID = p.ReportID
            LEFT JOIN dbo.RPFDShared f ON f.ReportID = p.ReportID
                                          AND f.ParameterName = p.ParameterName
                                          AND f.Form = @form
    WHERE   fr.ReportID IN ( SELECT  ReportID
                            FROM    RPFDShared
                            WHERE   Form = @form )
            AND fr.Access = 0
    ORDER BY	p.ReportID ,
				p.ParameterName    
  
--11th resultset - Return Button Info  
    SELECT  Form ,
            ButtonID ,
            ButtonText ,
            Parent ,
            ActionType ,
            ButtonRefresh,
            ButtonAction ,
            Width ,
            Height ,
            ButtonTop ,
            ButtonLeft
    FROM    DDFormButtonsCustom
    WHERE   Form = @form  
  
--12th resultset - Return Button Parameter Info  
    SELECT  Form ,
            ButtonID ,
            ParameterID ,
            Name ,
            DefaultType ,
            DefaultValue
    FROM    DDFormButtonParametersCustom
    WHERE   Form = @form  
  
    
    vspexit:    
    IF @opencursor = 1 
        BEGIN    
            CLOSE vcTabSecurity    
            DEALLOCATE vcTabSecurity    
        END    
    IF @openreportcursor = 1 
        BEGIN    
            CLOSE vcReportbSecurity    
            DEALLOCATE vcReportSecurity    
        END    
    
    IF @rcode <> 0 
        SELECT  @errmsg = @errmsg + CHAR(13) + CHAR(10) + '[vspDDFormInfo]'    
    RETURN @rcode  
GO
GRANT EXECUTE ON  [dbo].[vspDDFormInfo] TO [public]
GO
