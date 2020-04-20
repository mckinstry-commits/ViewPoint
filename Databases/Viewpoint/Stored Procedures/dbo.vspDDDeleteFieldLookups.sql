SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspDDDeleteFieldLookups]
/********************************
* Created: GG 05/31/06  
* Modified:	AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function.
*
* Called from Field Properties (F3) to remove a custom lookup
* from a specific form and field seq#.
*
* Input:
*	@form		current form name
*	@seq		field sequence #
*	@lookup		lookup name
*
* Output:
*	@errmsg		error message
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
    (
      @form VARCHAR(30) = NULL,
      @seq SMALLINT = NULL,
      @lookup VARCHAR(30) = NULL,
      @errmsg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
	
    DECLARE @rcode INT
	
    SELECT  @rcode = 0

    IF @form IS NULL
        OR @seq IS NULL
        OR @lookup IS NULL 
        BEGIN
            SELECT  @errmsg = 'Missing parameter values, cannot delete Lookup!',
                    @rcode = 1
            RETURN @rcode
        END

-- check Datatype Lookup
    IF EXISTS ( SELECT  1
                FROM    dbo.vDDDT d ( NOLOCK )
						-- use inline table function for perf
                        JOIN dbo.vfDDFIShared(@form) s  ON d.Datatype = s.Datatype
                WHERE	s.Seq = @seq
                        AND d.Lookup = @lookup ) 
        BEGIN
            SELECT  @errmsg = @lookup
                    + ' is assigned to this field''s datatype and cannot be deleted.',
                    @rcode = 1
            RETURN @rcode
        END

-- check standard Lookups
    IF EXISTS ( SELECT	1
                FROM    dbo.vDDFL (NOLOCK)
                WHERE   Form = @form
                        AND Seq = @seq
                        AND Lookup = @lookup ) 
        BEGIN
            SELECT  @errmsg = @lookup
                    + ' is a standard lookup and cannot be deleted.',
                    @rcode = 1
            RETURN @rcode
        END

-- remove Lookup from vDDFLc 
    DELETE  vDDFLc
    WHERE   Form = @form
            AND Seq = @seq
            AND Lookup = @lookup

    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDeleteFieldLookups] TO [public]
GO
