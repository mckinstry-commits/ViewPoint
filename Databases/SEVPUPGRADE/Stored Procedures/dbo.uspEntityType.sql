SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspEntityType] /** User Defined Validation Procedure **/
(@EntityAbbr char(1) =null, @msg varchar(255) output)

as
set nocount on

declare @rcode int
select @rcode = 0

   select @msg=EntityDescription from udEntityType with (nolock) where EntityAbbr = @EntityAbbr
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid Vendor Entity Type: ' + isnull(@EntityAbbr,'') + ' !', @rcode = 1
   	goto bspexit
   	end


bspexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspEntityType] TO [public]
GO
