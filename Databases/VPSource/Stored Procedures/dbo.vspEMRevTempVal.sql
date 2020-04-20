SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE  procedure [dbo].[vspEMRevTempVal]
/*******************************************************************************
    * Created By:	GP 08/27/2008 - Issue #127494
    * Modified By:
	*
	* INPUT:	@EMCo
	*			@RevTemplate
	*
	* OUTPUT:	@msg
	*
	* RETURN VALUE:		0 - Success
	*					1 - Failure
    *
    * This procedure checks to make sure that an identitcal Revenue Template value is not going to
	* be inserted.
    * 
 ********************************************************************************/
(@EMCo bCompany = null, @RevTemplate varchar(10) =  null,
 @msg varchar(255) output)

as
SET nocount on

DECLARE @rcode int
SET @rcode = 0


------ make sure To Revenue Template name does not exist already
SELECT RevTemplate FROM bEMTH WHERE EMCo = @EMCo and RevTemplate = @RevTemplate
IF @@rowcount <> 0
BEGIN
	SELECT @msg = 'Revenue Template already exists! To Revenue Template must be a new template.', @rcode = 1
	GOTO vspexit
END


vspexit:
	IF @rcode<>0 SELECT @msg = isnull(@msg,'')
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMRevTempVal] TO [public]
GO
