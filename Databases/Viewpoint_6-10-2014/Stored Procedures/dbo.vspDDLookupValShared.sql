SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspDDLookupValShared]
  /***********************************************************
   * CREATED BY:  TL 06/29/05
   * MODIFIED By : 
   *
   * USAGE: Used to verify Lookup
   * Used on Forms: 
   *
   * INPUT PARAMETERS
  
   *   Form         Form to validate
   * INPUT PARAMETERS
   *   @Lookup Main table from DDLHShared
   *   @msg        error message if something went wrong
   * RETURN VALUE
   *   0 Success
   *   1 fail
   ************************************************************************/
  	(@Lookup varchar(30) = null, @msg varchar(60) output)
  as
  set nocount on
  declare @rcode int
  select @rcode = 0
  
  
  if @Lookup is null
  	begin
  	select @msg = 'Missing Lookup!', @rcode = 1
  	goto vspexit
  	end
  
  select  @msg = Title
  from dbo.DDLHShared
  where Lookup = @Lookup
  if @@rowcount = 0
  	begin
  	select @msg = 'Lookup not on file!', @rcode = 1
  	end
  
  vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDLookupValShared] TO [public]
GO
