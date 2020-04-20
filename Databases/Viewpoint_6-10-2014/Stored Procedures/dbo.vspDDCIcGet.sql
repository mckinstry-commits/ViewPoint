SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDDTVal    Script Date: 8/28/99 9:34:19 AM ******/
  CREATE proc [dbo].[vspDDCIcGet]
  /***************************************
  * Created: JRK 10/31/06
  * Modified: 
  *
  * Retrieve all fields of DDCIc (custom combobox items) to populate the HQUDAdd wizard.
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
  
  select Seq, DatabaseValue, DisplayValue
  from DDCIc (nolock)
  where ComboType = @combotype
  if @@rowcount = 0
  	begin
  	select @msg = 'ComboType is not setup in DDCIc!', @rcode = 1
  	end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDCIcGet] TO [public]
GO
