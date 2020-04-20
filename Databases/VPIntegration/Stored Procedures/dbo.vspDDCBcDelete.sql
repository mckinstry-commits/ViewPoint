SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDDTVal    Script Date: 8/28/99 9:34:19 AM ******/
  CREATE proc [dbo].[vspDDCBcDelete]
  /***************************************
  * Created: JRK 10/31/06
  * Modified: 
  *
  * Delete DDCBc (custom combobox) items.
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


  DELETE FROM DDCBc 
  WHERE ComboType=@combotype

  if @@rowcount = 0
  	begin
  	select @msg = 'DDCBc delete failed!', @rcode = 1
  	end

  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDCBcDelete] TO [public]
GO
