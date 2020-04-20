SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspDDGetDatatypeLookupInfo]
/********************************
* Created: GG 05/20/04  
* Modified:	AMR - Issue ?, Fixing performance issue by using an inline table function.
*
* Called from Field Overrides (F3) Lookup Overrides to retrieve
* current datatype lookup and override info for a specific form and field seq#
*
* Input:
*	@form		current form name
*	@seq		field sequence #
*
* Output:
*	@datatypelookup		Datatype lookup 
*	@overrideparams		Lookup parameters (null = no override params)
*	@overrideactive		Active Y,N,(null = no override)
*	@overrideloadseq	Load Sequence # (null = no override)
*	@errmsg				Error message
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
    (
      @form VARCHAR(30) = NULL,
      @seq SMALLINT = NULL,
      @datatypelookup VARCHAR(30) = NULL OUTPUT,
      @overrideparams VARCHAR(256) = NULL OUTPUT,
      @overrideactive bYN = NULL OUTPUT,
      @overrideloadseq TINYINT = NULL OUTPUT,
      @errmsg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
	
    DECLARE @rcode INT
	
    SELECT  @rcode = 0

-- get Datatype Lookup w/override information
    SELECT  @datatypelookup = d.Lookup,
            @overrideparams = c.LookupParams,
            @overrideactive = c.ActiveLookup,
            @overrideloadseq = c.LookupLoadSeq
            -- use an inline table function for performance
    FROM    dbo.vfDDFIShared(@form) s
            LEFT OUTER JOIN vDDFIc c ON s.Form = c.Form
                                        AND s.Seq = c.Seq
            LEFT OUTER JOIN vDDDT d ON d.Datatype = s.Datatype
    WHERE   s.Seq = @seq

    RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDGetDatatypeLookupInfo] TO [public]
GO
