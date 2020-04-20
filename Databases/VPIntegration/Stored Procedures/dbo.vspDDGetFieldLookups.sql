SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROC [dbo].[vspDDGetFieldLookups]
/********************************
* Created: GG 05/20/04  
* Modified:	GG 05/26/06
*			AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function.
*			GF 08/22/2012 TK-17316 added restriction to not show DDDT lookup if not active and seq is null
*
* Called from Field Overrides (F3) Lookup Overrides to retrieve
* current lookups for a specific form and field seq#
*
* Input:
*	@form				current form name
*	@seq				field sequence #
*
* Output:
*	@overridesexist		Lookup overrides exist - Y/N
*	resultset - current lookup information
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
    (
      @form VARCHAR(30) = NULL,
      @seq SMALLINT = NULL,
      @overridesexist CHAR(1) OUTPUT
    )
AS 
    SET nocount ON
	
    DECLARE @rcode INT
	
    SELECT  @rcode = 0,
            @overridesexist = 'N'

-- check for Lookup overrides
    IF EXISTS ( SELECT TOP 1
                        1
                FROM    dbo.vDDFIc
                WHERE   Form = @form
                        AND Seq = @seq
                        AND ( ActiveLookup IS NOT NULL
                              OR LookupParams IS NOT NULL
                              OR LookupLoadSeq IS NOT NULL
                            ) ) 
        SELECT  @overridesexist = 'Y'
    IF EXISTS ( SELECT TOP 1
                        1
                FROM    dbo.vDDFLc
                WHERE   Form = @form
                        AND Seq = @seq ) 
        SELECT  @overridesexist = 'Y'

-- resultset of Current Lookups --
-- get Datatype Lookup 
    SELECT  d.Lookup AS Lookup,
            h.Title,
            s.ActiveLookup AS Active,
            s.LookupParams,
            s.LookupLoadSeq AS LoadSeq,
            CASE WHEN ( i.ActiveLookup IS NULL
                        AND i.LookupParams IS NULL
                        AND i.LookupLoadSeq IS NULL
                      ) THEN 'Standard'
                 ELSE 'Override'
            END AS Status		-- 'custom' datatype lookups not allowed
            
            -- use inline table function for perf
    FROM    dbo.vfDDFIShared(@form) s
            LEFT OUTER JOIN dbo.vDDDT d ( NOLOCK ) ON d.Datatype = s.Datatype
            LEFT JOIN dbo.DDLHShared h ( NOLOCK ) ON h.Lookup = d.Lookup
            LEFT JOIN dbo.vDDFIc i ( NOLOCK ) ON i.Form = @form
                                                 AND i.Seq = @seq
    WHERE   s.Seq = @seq
            AND d.Lookup IS NOT NULL
            ----TK-17316
            AND NOT(s.ActiveLookup = 'N' AND s.LookupLoadSeq IS NULL)
    UNION
-- get additional Lookups
    SELECT  l.Lookup,
            h.Title,
            l.Active,
            l.LookupParams,
            l.LoadSeq,
            l.Status
    FROM    dbo.vfDDFIShared(@form) s
            JOIN dbo.DDFLShared l ( NOLOCK ) ON s.Form = l.Form
                                                AND s.Seq = l.Seq
            LEFT JOIN dbo.DDLHShared h ( NOLOCK ) ON h.Lookup = l.Lookup
    WHERE	s.Seq = @seq
    ORDER BY LoadSeq 

   
    RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspDDGetFieldLookups] TO [public]
GO
