SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[vspDDFieldPropSaveStatusText]
/**************************************************
* Created:  MJ 01/18/06 
* Modified: JRK 12/13/06 Add IF to update vDDFIc if it is a custom field.
*			AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function.
*
* Called from the Field Properties form to update a field's standard Status Text
*
* Inputs
*	@form			Form
*	@seq 			Seq
*	@statustext 	Status Text
*
* Output
*	@errmsg
*
****************************************************/
    (
      @form VARCHAR(30) = NULL,
      @seq SMALLINT = NULL,
      @statustext VARCHAR(256) = NULL,
      @errmsg VARCHAR(60) OUTPUT
    )
AS 
    SET nocount ON 
    DECLARE @rcode INT,
			@fieldtype TINYINT
    SELECT  @rcode = 0
    

    SELECT  @fieldtype = FieldType
    -- using inline table function for perf
    FROM    dbo.vfDDFIShared(@form)
    WHERE   Seq = @seq
    
--select @errmsg = 'FieldType=' + cast(@fieldtype as varchar(60))
--goto vspexit

    IF ( @fieldtype = 4 )
-- update Status Text for a user control
        BEGIN
            UPDATE  vDDFIc
            SET     StatusText = @statustext
            WHERE   Form = @form
                    AND Seq = @seq
            IF @@rowcount = 0 
                BEGIN
                    SELECT  @errmsg = 'Unable to set status text of custom field.',
                            @rcode = 1
					RETURN @rcode
                END
        END
    ELSE
-- update Status Text for a regular control
        BEGIN
            UPDATE  vDDFI
            SET     StatusText = @statustext
            WHERE   Form = @form
                    AND Seq = @seq
            IF @@rowcount = 0 
                BEGIN
                    SELECT  @errmsg = 'Unable to set status text.',
                            @rcode = 1
                    RETURN @rcode
                END
        END

    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFieldPropSaveStatusText] TO [public]
GO
