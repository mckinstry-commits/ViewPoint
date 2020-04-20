SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE dbo.vspVACallAppSecurity 
(@activate bYN,@msg varchar(255) output) 


AS

Execute as user = 'viewpointcs'
BEGIN
	EXEC vspVAAppSec @activate = @activate, @msg = @msg
	RETURN
END
GO
GRANT EXECUTE ON  [dbo].[vspVACallAppSecurity] TO [public]
GO
