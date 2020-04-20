SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vspVACustomTabRelatedGridVal]
/***************************************
* Created:	RM 04-29-08
* Modified: AMR - 6/27/11 - TK-06411, Fixing performance issue by using an inline table function.
*
* Used to validate a related grid form being assigned to a custom tab.
*
* Inputs:
*	@relatedform			Form
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
      @form VARCHAR(30) = NULL,
      @tab TINYINT = NULL,
      @relatedform CHAR(30) = NULL,
      @msg VARCHAR(512) = NULL OUTPUT
    )
AS 
    SET nocount ON

    DECLARE @rcode INT
    SELECT  @rcode = 0

    IF @relatedform IS NULL
        OR @tab IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Form and/or Tab#!',
                    @rcode = 1
            RETURN @rcode
        END

    SELECT  @msg = Title
    FROM    dbo.vDDFHc (NOLOCK)
    WHERE   Form = @relatedform
    
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Form not found.  You can only assign custom (UD) forms to related tabs.!',
                    @rcode = 1
            RETURN @rcode
        END

    IF EXISTS ( SELECT  1
                FROM    dbo.vfDDFIShared(@form)
                WHERE   Tab = @tab ) 
        BEGIN
            SELECT  @msg = 'Cannot assign a related grid to a tab with custom fields!',
                    @rcode = 1
            RETURN @rcode
        END

    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVACustomTabRelatedGridVal] TO [public]
GO
