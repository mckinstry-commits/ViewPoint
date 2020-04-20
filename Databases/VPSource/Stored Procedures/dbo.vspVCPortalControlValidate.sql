SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspVCPortalControlValidate]

(@portalControlID int = null, @msg varchar(60) = null output)
as 
set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   	if @portalControlID is null 
   		begin
   			goto spExit
   		end
   	
	if @portalControlID < 0 
		begin
			goto spError
		end

	select @msg = Name 
	from pvPortalControls with (nolock) 
	where PortalControlID = @portalControlID
	
	
	if @@rowcount = 0
   		begin
	   		goto spError
   		end

	spExit:
		return @rcode

	spError:
	select @msg = 'Invalid Portal Control', @rcode = 1
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspVCPortalControlValidate] TO [public]
GO
