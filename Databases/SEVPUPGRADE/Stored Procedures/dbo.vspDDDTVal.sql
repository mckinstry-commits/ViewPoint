SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspDDDTVal    Script Date: 8/28/99 9:34:19 AM ******/
  CREATE proc [dbo].[vspDDDTVal]
  /***************************************
  * Created: kb 4/26/5
  * Modified: 
  *
  * Used to validate Viewpoint datatype setup in DDDT
  *
  **************************************/
  	(@datatype char(30) = null, @lookup varchar(30) = null output,
  	 @setupform varchar(30) = null output, @msg varchar(60) = null output)
  
  as
  set nocount on
  
  declare @rcode int
  select @rcode = 0
  
  if @datatype is null
  
  	begin
  	select @msg = 'Missing Datatype!', @rcode = 1
  	goto bspexit
  	end
  
  select @msg = Description, @lookup = Lookup, @setupform = SetupForm
  from vDDDT (nolock)
  where Datatype = @datatype
  if @@rowcount = 0
  	begin
  	select @msg = 'Datatype not setup in DDDT!', @rcode = 1
  	end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDTVal] TO [public]
GO
