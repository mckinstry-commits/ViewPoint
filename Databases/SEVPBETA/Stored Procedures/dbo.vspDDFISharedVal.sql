SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vspDDFISharedVal]
/***************************************
* Created: RM 04-29-08
* Modified: AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function., Fixing performance issue by using an inline table function.
*
* Used to validate DDFI Sequences in DDFIShared
*
* Inputs:
*	@form			Form
*	@tab			Tab		
*
* Outputs:
*	@msg			Tab title or error message
*
* Return code:
*	0 = success, 1 = error
*
**************************************/
    (
      @form CHAR(30) = NULL,
      @seq INT = NULL,
      @msg VARCHAR(255) = NULL OUTPUT
    )
AS 
    SET nocount ON

    DECLARE @rcode INT
    SELECT  @rcode = 0

	IF @form IS NULL
        OR @seq IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Form and/or Seq#!',
                    @rcode = 1
            RETURN @rcode
        END

    SELECT  @msg = [Description]
    FROM    dbo.vfDDFIShared(@form)
    WHERE	Seq = @seq
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Invalid Sequence!',
                    @rcode = 1
			RETURN @rcode
        END

    RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspDDFISharedVal] TO [public]
GO
