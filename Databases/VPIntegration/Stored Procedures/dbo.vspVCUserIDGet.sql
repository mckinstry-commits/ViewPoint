SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspVCUserIDGet]
/*************************************
* Created By:	CHS 4/2/2008
*
* returns user ID number
*	
* Pass:
*	username
*
* Success returns:
*	0 and user id #
*
* Error returns:
*	1 and error message
**************************************/
(@userName varchar(50) = null, @userID int = null output, @message varchar(255) = '' output)

as 
set nocount on

declare @returnCode int
select @returnCode = 0

if isnull(@userName, '') = ''
	begin
		select @message = 'Missing User Name.', @returnCode = 1
		goto vsp_exit
	end

select @userID = UserID from pUsers with (nolock) where @userName = UserName

if @@rowcount = 0
	begin
   		select @message = 'No valid User ID# could be found for user name ' + @userName + ',', @returnCode = 1
	end

vsp_exit:
	return @returnCode


GO
GRANT EXECUTE ON  [dbo].[vspVCUserIDGet] TO [public]
GO
