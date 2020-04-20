SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDDTGetInputType]
  /***************************************
  * Created: JRK 10/24/06
  * Modified: 
  *
  * Used to retrieve info about a Viewpoint datatype setup in vDDDT and vDDDTc
  *
  * Used HQUDAdd
  *
  *
  **************************************/
  	(@datatype char(30) = null, @inputtype tinyint = null output,
  	 @msg varchar(60) = null output)
  
  as
  set nocount on
  
  declare @rcode int
  select @rcode = 0
  
  if @datatype is null
  	begin
  	select @msg = 'Missing Datatype!', @rcode = 1
  	goto vspexit
  	end
  
  select @inputtype = InputType, @msg = Description
  from dbo.DDDTShared
  where Datatype = @datatype
  if @@rowcount = 0
  	begin
  	select @msg = 'Datatype not setup in DDDTShared!', @rcode = 1
  	end
  
vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDTGetInputType] TO [public]
GO
