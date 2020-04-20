SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspDDRefreshFieldLookups]
/********************************
* Created: GG 06/02/06  
* Modified:	AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function.
*
* Called from Field Overrides (F3) Lookup Overrides to retrieve
* current active lookups with info for a specific form and field seq#
*
* Input:
*	@form				current form name
*	@seq				field sequence #
*
* Output:
*	@errmsg				error message
*	resultset - current lookup information
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
    (
      @form VARCHAR(30) = NULL,
      @seq SMALLINT = NULL,
      @errmsg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
	
    DECLARE @rcode INT

    SET @rcode = 0

    IF @form IS NULL
        OR @seq IS NULL 
        BEGIN
            SELECT  @errmsg = 'Missing input paramters!',
                    @rcode = 1
            RETURN @rcode
        END
	
-- get standard Datatype or Input Lookup
    SELECT  d.[Lookup],
            h.Title,
            s.ActiveLookup AS Active,
            s.LookupParams,
            s.LookupLoadSeq AS LoadSeq,
            h.FromClause,
            h.WhereClause,
            h.JoinClause,
            h.OrderByColumn,
            h.GroupByClause
            -- using inline table function
    FROM    dbo.vfDDFIShared(@form) s
            LEFT OUTER JOIN dbo.vDDDT d ( NOLOCK ) ON d.Datatype = s.Datatype
            LEFT JOIN dbo.DDLHShared h ( NOLOCK ) ON ( h.[Lookup] = d.[Lookup] )
    WHERE	s.Seq = @seq
            AND d.[Lookup] IS NOT NULL
            AND s.ActiveLookup = 'Y'
    UNION
-- get additional Lookups
    SELECT  l.[Lookup],
            h.Title,
            l.Active,
            l.LookupParams,
            l.LoadSeq,
            h.FromClause,
            h.WhereClause,
            h.JoinClause,
            h.OrderByColumn,
            h.GroupByClause
            -- using inline table function
    FROM    dbo.vfDDFIShared(@form) s
            JOIN dbo.DDFLShared l ( NOLOCK ) ON s.Form = l.Form
                                                AND s.Seq = l.Seq
            LEFT JOIN dbo.DDLHShared h ( NOLOCK ) ON h.[Lookup] = l.[Lookup]
    WHERE   s.Seq = @seq
    ORDER BY LoadSeq 

	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDRefreshFieldLookups] TO [public]
GO
