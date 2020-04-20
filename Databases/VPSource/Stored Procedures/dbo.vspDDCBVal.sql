SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDCBVal]
  /* validates Combo Type entered in DDCB
   * Created By : Robert Tuck - 8/18/05
   * pass in Combo Type
   * returns Combo Type Description or ErrMsg
  */
  	(@combotype varchar(20), @msg varchar(60) output)
  as
  set nocount on
  declare @rcode int
  select @rcode = 0
  
  if @combotype is null
  	begin
  	select @msg = 'Missing Combo Type!', @rcode = 1
  	goto bspexit
  	end
  
  select @msg = Description from DDCB with (nolock)
  	where ComboType = @combotype
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDCBVal] TO [public]
GO
