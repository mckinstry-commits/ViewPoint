SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE [dbo].[vspRPReportInfo]
/********************************
* Created: GG 07/29/03 
* Modified: GG 12/09/03 - added Prec column
*           TRL 06/07/25 - Issue 28492, added ParamRequired field
*           George Clingerman 4/20/2010 - Add VPUserName to report info returned
*			AMR 06/22/11 - Issue TK-07089 , Fixing performance issue with if exists statement.
*
* Retrieves all RP Report Header, Parameter, and Lookup info needed to 
* load a Viewpoint report.
*
* Input:
*	@co			Current active company #
*	@reportid	Report ID#
*
* Output:
*	Multiple resultsets - 1st: Report Header info
*						- 2nd: Report Parameters
*						- 3rd: Report Parameter Lookups
*						- 4th: Report Parameter Lookup Detail
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
    (
      @co bCompany = NULL ,
      @reportid INT = NULL ,
      @errmsg VARCHAR(512) OUTPUT
    )
AS 
    SET nocount ON

    DECLARE @rcode INT ,
        @access TINYINT
	
    SELECT  @rcode = 0 ,
            @access = 0

    IF @co IS NULL
        OR @reportid IS NULL 
        BEGIN
            SELECT  @errmsg = 'Missing required input parameters: Company # and/or Report ID#!' ,
                    @rcode = 1
            GOTO vspexit
        END

-- check Report Security 
    EXEC @rcode = vspRPReportSecurity @co, @reportid, @access OUTPUT,
        @errmsg OUTPUT
    IF @rcode <> 0 
        GOTO vspexit
    IF @access IS NULL
        OR @access <> 0 	-- must have access
        BEGIN
            SELECT  @rcode = 1
            GOTO vspexit		-- return error if access denied
        END

-- 1st resultset - return Report Header and Location info
    SELECT  t.Title ,
            t.[FileName] ,
            t.ReportDesc ,
            t.UserNotes ,
            l.[Path] ,
            u.PrinterName ,
            u.PaperSource ,
            u.PaperSize ,
            u.Duplex ,
            u.Orientation ,
            u.Zoom ,
            u.ViewerWidth ,
            u.ViewerHeight ,
            u.VPUserName
    FROM    dbo.vfRPRTShared(@reportid) t
            JOIN vRPRL l ON t.Location = l.Location
            LEFT OUTER JOIN vRPUP u ON t.ReportID = u.ReportID
                                       AND u.VPUserName = SUSER_SNAME()
   
--Issue 28492 included ParamRequired field
-- 2nd resultset - return active Report Parameters ordered by Display Seq
    SELECT  s.ParameterName ,
            s.ReportDatatype ,
            s.Datatype ,
            s.Description ,
            ISNULL(s.InputType, d.InputType) AS InputType ,
            ISNULL(s.InputMask, d.InputMask) AS InputMask ,
            COALESCE(s.InputLength, d.InputLength, 0) AS InputLength ,
            COALESCE(s.Prec, d.Prec, 0) AS Prec ,
            s.DisplaySeq ,
            s.ParameterDefault ,
            s.ParamRequired
    FROM    RPRPShared s
            LEFT OUTER JOIN DDDTShared d ON d.Datatype = s.Datatype
    WHERE   s.ReportID = @reportid
    ORDER BY s.DisplaySeq

-- 3rd resultset - return active Report Lookup info ordered by Parameter Name and Load Seq
-- get standard Datatype or Parameter Lookup
    SELECT  s.ParameterName ,
            d.ReportLookup AS Lookup ,
            h.Title ,
            s.LookupParams ,
            s.LookupSeq AS LoadSeq ,
            h.FromClause ,
            h.WhereClause ,
            h.JoinClause ,
            h.OrderByColumn ,
            h.GroupByClause
    FROM    RPRPShared s
            LEFT OUTER JOIN vDDDT d ON d.Datatype = s.Datatype
            LEFT JOIN DDLHShared h ON ( h.Lookup = d.ReportLookup )
    WHERE   s.ReportID = @reportid
            AND s.ActiveLookup = 'Y'
            AND d.ReportLookup IS NOT NULL
    UNION
-- get additional Lookups
    SELECT  s.ParameterName ,
            l.Lookup ,
            h.Title ,
            l.LookupParams ,
            l.LoadSeq ,
            h.FromClause ,
            h.WhereClause ,
            h.JoinClause ,
            h.OrderByColumn ,
            h.GroupByClause
    FROM    RPRPShared s
            JOIN RPPLShared l ON s.ReportID = l.ReportID
                                 AND s.ParameterName = l.ParameterName
            LEFT JOIN DDLHShared h ON h.Lookup = l.Lookup
    WHERE   s.ReportID = @reportid
    ORDER BY s.ParameterName ,
            LoadSeq

/*--4th resultset - returns Lookup detail
select s.ParameterName, h.Seq, d.Lookup as Lookup, 
h.ColumnName, h.ColumnHeading, h.ColumnLength, h.Datatype, h.InputType, h.InputLength,
h.InputMask, h.Prec
from RPRPShared s
left outer join vDDDT d on d.Datatype = s.Datatype
left join DDLDShared h on (h.Lookup = d.Lookup)
where s.ReportID = @reportid and d.Lookup is not null
union
-- get additional Lookups
select s.ParameterName, h.Seq, l.Lookup, 
h.ColumnName, h.ColumnHeading, h.ColumnLength, h.Datatype, h.InputType, h.InputLength,
h.InputMask, h.Prec
from RPRPShared s
join RPPLShared l on s.ReportID = l.ReportID and s.ParameterName = l.ParameterName 
left join DDLDShared h on h.Lookup = l.Lookup
where s.ReportID = @reportid
order by s.ParameterName, l.Lookup, h.Seq */


    vspexit:
    IF @rcode <> 0 
        SELECT  @errmsg = @errmsg + CHAR(13) + CHAR(10) + '[vspRPReportInfo]'
    RETURN @rcode

 


 




















GO
GRANT EXECUTE ON  [dbo].[vspRPReportInfo] TO [public]
GO
