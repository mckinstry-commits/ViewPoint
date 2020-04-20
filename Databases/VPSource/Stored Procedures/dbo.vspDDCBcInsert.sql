SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDDTVal    Script Date: 8/28/99 9:34:19 AM ******/
  CREATE proc [dbo].[vspDDCBcInsert]
  /***************************************
  * Created: JRK 10/31/06
  * Modified: 
  *
  * Insert DDCBc (custom combobox) items.
  *
  **************************************/
  	(@combotype varchar(20) = null, @description varchar(30) = null,
	 @msg varchar(60) output)
  
  as
  set nocount on
  
  declare @rcode int
  select @rcode = 0
  
if @combotype is null
    	begin
  	select @msg = 'Missing ComboType!', @rcode = 1
  	goto bspexit
  	end

if @description is null
    	begin
  	select @msg = 'Missing Description!', @rcode = 1
  	goto bspexit
  	end


  INSERT INTO DDCBc (ComboType, Description)
  Values (@combotype, @description)

  if @@rowcount = 0
  	begin
  	select @msg = 'DDCBc insert failed!', @rcode = 1
  	end

  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDCBcInsert] TO [public]
GO
