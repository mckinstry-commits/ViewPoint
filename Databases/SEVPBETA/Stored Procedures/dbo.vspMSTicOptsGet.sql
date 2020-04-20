SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspMSTicOptsGet]
/********************************
* Created By:	GF 10/04/2007
* Modified By: AMR 06/22/11 - Issue TK-07089 , Fixing performance issue with if exists statement.
*
*
*
* Called from MS Ticket Options form to construct a dataset with current values for inputs
*
* Input:
* @form			current form 
*
* Output:
*	1st resultset - current input property settings
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/ 
( @form VARCHAR(30) )
AS 
    SET nocount ON

    DECLARE @rcode INT

    SELECT  @rcode = 0

-- resulset - Current property settings for all inputs
    SELECT  s.Seq,
            ISNULL(s.Description, '') AS [Description],
            ISNULL(s.ViewName, '') AS [View],
            ISNULL(s.ColumnName, '') AS [Column],
            COALESCE(u.InputSkip, s.InputSkip, 'N') AS [SkipInput]
    FROM    dbo.vfDDFIShared(@form) s
            LEFT OUTER JOIN dbo.vDDUI u ( NOLOCK ) ON u.VPUserName = SUSER_SNAME()
                                                      AND u.Form = s.Form
                                                      AND u.Seq = s.Seq
    WHERE   s.ControlType <> 99
            AND s.ControlType <> 5
            AND s.FieldType <> 2
            AND s.ViewName = 'MSTB'
    ORDER BY s.Seq


    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSTicOptsGet] TO [public]
GO
