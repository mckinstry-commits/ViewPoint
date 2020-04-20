SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron LAng
-- Create date: 5/22/08
	
-- Modified:	5/28/08 AL Added check for blank password, Rolled forwards to 6.1.1 
-- Description:	Changes the password on both the application role and 
--				in DDVS
-- =============================================
CREATE PROCEDURE [dbo].[vspVAResetAppRolePassword]
	-- Add the parameters for the stored procedure here
	(@alteredstring as varchar(30), @msg varchar(60) output)
	
		
AS
BEGIN
SET NOCOUNT ON;
	
declare @sql as NVARCHAR(2000), @gate varchar(60), @rcode int, @currapprole bYN

select @rcode = 0

if @alteredstring = ''
	begin
	select @msg = 'Application Role password cannot be blank', @rcode = 1
	goto bspexit
	end


   -- Insert statements for procedure here
	Update DDVS 
	Set AppRolePassword = @alteredstring
	
	select @sql = 'Alter APPLICATION ROLE Viewpoint WITH PASSWORD = ''' + @alteredstring + ''''
		
	exec sp_executesql @sql

bspexit:
  	return @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspVAResetAppRolePassword] TO [public]
GO
