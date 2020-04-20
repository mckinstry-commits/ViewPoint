SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspDDUpdateFieldLookups]
/********************************
* Created: GG 05/31/06  
* Modified:	AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function.
*
* Called from Field Properties (F3) to add or update lookup overrides
* to a specific form and field seq#.
*
* Input:
*	@form		current form name
*	@seq		field sequence #
*	@lookup		lookup name
*	@params		comma separated list of lookup parameters
*	@active		lookup is active - Y/N 
*	@loadseq	lookup load sequence
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
      @params VARCHAR(256) = NULL,
      @active CHAR(1) = NULL,
      @loadseq TINYINT = NULL,
      @errmsg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
	
    DECLARE @rcode INT
	
    SELECT  @rcode = 0

    IF @form IS NULL
        OR @seq IS NULL
        OR @lookup IS NULL
        OR @active IS NULL 
        BEGIN
            SELECT  @errmsg = 'Missing parameter values!',
                    @rcode = 1
            RETURN @rcode
        END
    IF NOT EXISTS ( SELECT	1
					--use line table function for perf
                    FROM    dbo.vfDDFIShared(@form)
                    WHERE  Seq = @seq ) 
        BEGIN
            SELECT  @errmsg = 'Invalid Form: ' + @form + ' and Seq#:'
                    + CONVERT(VARCHAR, @seq),
                    @rcode = 1
            RETURN @rcode
        END
    IF NOT EXISTS ( SELECT  1
                    FROM    dbo.DDLHShared (NOLOCK)
                    WHERE   Lookup = @lookup ) 
        BEGIN
            SELECT  @errmsg = 'Invalid Lookup: ' + @lookup,
                    @rcode = 1
            RETURN @rcode
        END
    IF @active NOT IN ( 'Y', 'N' ) 
        BEGIN
            SELECT  @errmsg = 'Active property must be ''Y'' or ''N''!',
                    @rcode = 1
            RETURN @rcode
        END
    IF @loadseq IS NULL 
        BEGIN
            SELECT  @errmsg = 'Load sequence # must greater than or equal to 0!',
                    @rcode = 1
            RETURN @rcode
        END

-- check Datatype Lookup 
    IF EXISTS ( SELECT  1
                FROM    dbo.vDDDT d ( NOLOCK )
							--use line table function for perf
                        JOIN dbo.vfDDFIShared(@form) s ON d.Datatype = s.Datatype
                WHERE   s.Seq = @seq
                        AND d.Lookup = @lookup ) 
        BEGIN
            UPDATE  dbo.vDDFIc
            SET     ActiveLookup = @active,
                    LookupParams = @params,
                    LookupLoadSeq = @loadseq
            WHERE   Form = @form
                    AND Seq = @seq
            IF @@rowcount = 0 
                BEGIN
                    INSERT  dbo.vDDFIc
                            ( Form,
                              Seq,
                              ActiveLookup,
                              LookupParams,
                              LookupLoadSeq
                            )
                    VALUES  ( @form,
                              @seq,
                              @active,
                              @params,
                              @loadseq
                            )
                END
            RETURN @rcode
        END
	
-- update/add all other Lookups to vDDFLc
    UPDATE  dbo.vDDFLc
    SET     LookupParams = @params,
            Active = @active,
            LoadSeq = @loadseq
    WHERE   Form = @form
            AND Seq = @seq
            AND Lookup = @lookup
    IF @@rowcount = 0 
        BEGIN
            INSERT  dbo.vDDFLc
                    ( Form,
                      Seq,
                      Lookup,
                      LookupParams,
                      Active,
                      LoadSeq
                    )
            VALUES  ( @form,
                      @seq,
                      @lookup,
                      @params,
                      @active,
                      @loadseq
                    )
        END

	declare @tablename varchar(30)
		select top 1 @tablename = ViewName from vDDFIc where Form = @form and Seq = @seq
		EXEC vspUDVersionUpdate @tablename
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUpdateFieldLookups] TO [public]
GO
