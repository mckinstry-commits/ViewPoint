SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROC [dbo].[vspDDGetFormProperties]
/********************************
* Created: GG 02/27/04  
* Modified:	GG 02/21/05 - #26324 - added ShowForm, ShowGrid to vDDFI, removed Hidden
*			GG 07/16/07 - #122520 - exclude PRTB Rate/Amt if user does not have permission
*			RM 09/13/07 - Include Dummy DDFH info if UD form
*			GG 04/04/08 - #127671 - include Security Form info
*			CC 07/09/09 - #129922 - Use culture specific Form/Tab names
*           JD 11/13/09 - #131937 - Default Attachment Type by Form, added UserDefaultAttachmentTypeID
*                                   and SystemDefaultAttachmentTypeID to the 3rd resultset - Form header info.
*			AMR - 6/27/11 - TK-06411, Fixing performance issue by using an inline table function.
*
* Called from Form Properties to construct a dataset with current values for inputs,
* tabs, form header properties, and linked reports.
*
* Input:
*	@form			current form 
*
* Output:
*	1st resultset - current input property settings
*	2nd resultset - tabs
*	3rd resultset - editable form header info
*	4th resultset - standard icon and progress clip 
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
    (
      @form VARCHAR(30),
      @culture INT = NULL
    )
AS 
    SET nocount ON
	
    DECLARE @rcode INT
	
    SELECT  @rcode = 0

-- 1st resulset - Current property settings for all inputs
    SELECT  s.Seq,
            ISNULL(s.Description, '') AS [Description],
            ISNULL(s.ViewName, '') AS [View],
            ISNULL(s.ColumnName, '') AS [Column],
            COALESCE(s.Label, d.Label, '') AS [Label],
            ISNULL(s.InputType, d.InputType) AS [InputType],
            s.FieldType AS [FieldType],
            s.ControlType AS [ControlType],
            s.DescriptionColumn AS [DescCol],
            s.AutoSeqType AS [AutoSeq],
            ISNULL(s.Datatype, '') AS [Datatype],
            COALESCE(s.InputMask, d.InputMask, '') AS [InputMask],
            COALESCE(s.InputLength, d.InputLength, 0) AS [InputLength],
            COALESCE(s.Prec, d.Prec, -1) AS [Precision],	-- return -1 to indicate null value
            ISNULL(s.SetupForm, d.SetupForm) AS [SetupForm],
            s.SetupParams AS [SetupParams],
            s.Tab AS [Tab],
--s.TabIndex as [TabIndex],
--isnull(u.GridCol,s.GridCol) as [Grid Column],
            ISNULL(u.DefaultType, s.DefaultType) AS [DefaultType],
            ISNULL(u.DefaultValue, s.DefaultValue) AS [DefaultValue],
            ISNULL(u.InputReq, s.Req) AS [Req],
            COALESCE(u.InputSkip, s.InputSkip, 'N') AS [SkipInput],
            ISNULL(u.ShowGrid, s.ShowGrid) AS [ShowGrid],
            ISNULL(u.ShowForm, s.ShowForm) AS [ShowForm],
            s.UpdateGroup AS [UpdateGroup],
            s.ValLevel AS [ValLevel],
            s.ValProc AS [ValProc],
            s.ValParams AS [ValParams],
            s.SecondaryValProc AS [SecondaryValProc],
            s.SecondaryValParams AS [SecondaryValParams],
            s.SecondaryValLevel AS [SecondaryValLevel],
            s.HelpKeyword AS [HelpKeyword],
            s.StatusText AS [StatusText]
            -- use inline table function for perf
    FROM    dbo.vfDDFIShared(@form) s 
            LEFT OUTER JOIN dbo.vDDUI u ( NOLOCK ) ON u.VPUserName = SUSER_SNAME()
                                                      AND u.Form = s.Form
                                                      AND u.Seq = s.Seq
            LEFT OUTER JOIN dbo.DDDTShared d ( NOLOCK ) ON d.Datatype = s.Datatype
            LEFT OUTER JOIN dbo.vDDFH f ( NOLOCK ) ON f.Form = s.Form
            LEFT JOIN dbo.vDDUP p ( NOLOCK ) ON p.VPUserName = SUSER_NAME()
    WHERE   -- exclude control type 99 (no control) when not logged on as 'viewpointcs' 
            ( s.ControlType <> 99 
		--- exclude PR Rates/Amt if user does not have permission
                  AND NOT ( s.ViewName = 'PRTB'
                            AND s.ColumnName IN ( 'Rate', 'Amt' )
                            AND p.ShowRates = 'N'
                          )
		-- show all if logged in as viewpointcs
                  OR SUSER_SNAME() = 'viewpointcs'
                )
    ORDER BY s.Seq


-- 2nd resultset - Tabs
    SELECT  s.Tab,
            COALESCE(CultureText.CultureText, s.Title, '') AS [Title],
            ISNULL(s.GridForm, '') AS [GridForm],
            ISNULL(s.Custom, '') AS [Custom],
            ISNULL(s.LoadSeq, '') AS [LoadSeq]
    FROM    dbo.DDFTShared s ( NOLOCK )
            LEFT OUTER JOIN dbo.DDFT ON s.Form = dbo.DDFT.Form
                                        AND s.Tab = dbo.DDFT.Tab
                                        AND s.Title = dbo.DDFT.Title
            LEFT OUTER JOIN dbo.DDCTShared AS CultureText ON dbo.DDFT.TitleID = CultureText.TextID
                                                             AND CultureText.CultureID = @culture
    WHERE   s.Form = @form
    ORDER BY s.LoadSeq

-- 3rd resultset - Form header info 
    SELECT  s.Form,
            COALESCE(CultureText.CultureText, s.Title, '') AS [Title],
            s.NotesTab,
            ISNULL(s.ProgressClip, '') AS [ProgressClip],
            ISNULL(s.HasProgressIndicator, '') AS [HasProgressIndicator],
            COALESCE(u.DefaultTabPage, -1) AS [UserTabPage],
            ISNULL(s.IconKey, '') AS [IconKey],
            ISNULL(s.SecurityForm, '') AS [SecurityForm],
            s.DetailFormSecurity,
            u.DefaultAttachmentTypeID AS [UserDefaultAttachmentTypeID],
            s.DefaultAttachmentTypeID AS [SystemDefaultAttachmentTypeID],
            s.AllowAttachments AS [AllowAttachments]
    FROM    dbo.DDFHShared s ( NOLOCK )
            LEFT OUTER JOIN dbo.vDDFU u ( NOLOCK ) ON u.VPUserName = SUSER_SNAME()
                                                      AND u.Form = s.Form
            LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture
                                                         AND CultureText.TextID = s.TitleID
    WHERE   s.Form = @form
    ORDER BY s.Form

-- 4th resultset - Standard icon, progress clip, and tab page defaults
    IF ( SUBSTRING(@form, 1, 2) <> 'ud' ) 
        SELECT  ISNULL(ProgressClip, '') AS [ProgressClip],
                ISNULL(IconKey, '') AS [IconKey],
                ISNULL(DefaultTabPage, 1) AS [DefaultTabPage]
        FROM    dbo.vDDFH (NOLOCK)
        WHERE   Form = @form 
    ELSE --For UD Forms, we need to return dummy info
        SELECT  NULL AS [ProgressClip],
                NULL AS [IconKey],
                1 AS [DefaultTabPage]

    RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspDDGetFormProperties] TO [public]
GO
