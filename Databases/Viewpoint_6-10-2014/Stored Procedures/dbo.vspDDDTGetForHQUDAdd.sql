SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDDTGetForHQUDAdd]
  /***************************************
  * Created: JRK 10/26/06
  * Modified: 
  *
  * Used to retrieve info about a Viewpoint datatype setup in vDDDT and vDDDTc
  *
  * Used by HQUDAdd
  *
  *
  **************************************/
  	(@datatype char(30) = null, @msg varchar(60) = null output)
  
  as
set nocount on
  
  declare @rcode int
  select @rcode = 0
  
  if @datatype is null
  	begin
  	select @msg = 'Missing Datatype!', @rcode = 1
  	goto vspexit
  	end
  
  select t.InputType, t.Description, t.InputMask, t.InputLength, t.Prec, l.WhereClause
  from dbo.DDDTShared t
  left outer join dbo.DDLHShared l on t.Lookup = l.Lookup
  where Datatype = @datatype
  if @@rowcount = 0
  	begin
  	select @msg = 'Datatype not setup in DDDTShared!', @rcode = 1
  	end
  
vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDTGetForHQUDAdd] TO [public]
GO
