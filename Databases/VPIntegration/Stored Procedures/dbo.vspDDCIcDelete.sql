SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDDTVal    Script Date: 8/28/99 9:34:19 AM ******/
  CREATE proc [dbo].[vspDDCIcDelete]
  /***************************************
  * Created: JRK 10/31/06
  * Modified: 
  *
  * Delete DDCIc (custom combobox items) with matching key.
  *
  **************************************/
  	(@combotype varchar(20) = null, @msg varchar(60) output)
  
  as
  set nocount on
  
  declare @rcode int
  select @rcode = 0
  
if @combotype is null
    	begin
  	select @msg = 'Missing ComboType!', @rcode = 1
  	goto bspexit
  	end

  delete from DDCIc
  where ComboType = @combotype

  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDCIcDelete] TO [public]
GO
