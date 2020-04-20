SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspDDUPNameValForWFProcess    Script Date: 8/28/99 9:34:22 AM ******/
CREATE  proc [dbo].[vspDDUPNameValForWFProcess]
/**********************************************
* Created:	JG 03/08/12 - TK-13110 - Check for valid and duplicate HQ Approval Process User Names.
* Modified: 
*			JG 3/13/2012 - TK-00000 - Modified based on DocType changes.
*
* Validates VPUserName and checks for duplicates.
*
* Inputs:
*	@uname		User name to validate
*	
* Outputs:
*	@msg		Show PR rates flag or error message
*
* Return code:
*	0 = success, 1 = failure
*
*************************************/

  	(@process VARCHAR(20), @uname bVPUserName = null, @msg varchar(60) output)
as
set nocount on
declare @rcode int
select @rcode = 0


EXEC	@rcode = [dbo].[vspDDUPNameVal]
		@uname = @uname,
		@msg = @msg  OUTPUT

IF @rcode <> 0
BEGIN
	GOTO vspexit
END	

-- Check for duplicates
IF EXISTS	( 
			SELECT 1 
			FROM WFProcessStep
			WHERE Process = @process
				AND UserName = @uname
			)
BEGIN
	SELECT @msg = 'User Name already exists for the WF Process.', @rcode = 1
END	


vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDUPNameValForWFProcess] TO [public]
GO
