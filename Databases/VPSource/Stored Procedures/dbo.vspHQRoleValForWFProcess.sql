SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE PROCEDURE [dbo].[vspHQRoleValForWFProcess]
/***********************************************************
* CREATED BY:	JG	02/24/2012 - TK-13110
* MODIFIED By:	
*				JG 3/13/2012 - TK-00000 - Modified based on DocType changes.
*
* USAGE:
* validates HQ Role existance and duplication and returns role description
*
* INPUT PARAMETERS
* Role			Job Role to validate
* IgnoreActive	Flag to ignore Active flag
*
* OUTPUT PARAMETERS                    
* @msg   error message if error occurs otherwise Description of role
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@process VARCHAR(20),
 @role varchar(20) = null, @ignoreActive dbo.bYN = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @active char(1)

set @rcode = 0
set @active = 'N'

EXEC	@rcode = [dbo].[vspHQRoleVal]
		@role = @role,
		@ignoreActive = @ignoreActive,
		@msg = @msg  OUTPUT

IF @rcode <> 0
BEGIN
	GOTO bspexit
END	

-- Check for duplicates
IF EXISTS	( 
			SELECT 1 
			FROM WFProcessStep
			WHERE Process = @process
				AND [Role] = @role
			)
BEGIN
	SELECT @msg = 'Role already exists for the Workflow Process.', @rcode = 1
END	

bspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspHQRoleValForWFProcess] TO [public]
GO
