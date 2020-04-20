SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDLookupVal    Script Date: 8/28/99 9:32:38 AM ******/
  
  CREATE   procedure [dbo].[vspDDLookupVal]
  /***********************************************************
   * CREATED BY: ??   ?/??/??
   * MODIFIED By : SE 9/04/96
   *					TV moving to dotnet
   * USAGE:
   * validates Lookup
   *
   * INPUT PARAMETERS
  
   *   Lookup       Form Do Purge
   * INPUT PARAMETERS
   *   @msg        error message if something went wrong, otherwise description
   * RETURN VALUE
   *   0 Success
   *   1 fail
   ************************************************************************/
  	@lookup varchar(30) = null, @msg varchar(60) output
  as
  set nocount on
  declare @rcode int
  select @rcode = 0
  
  if @lookup is null
  	begin
  	select @msg = 'Missing Lookup!', @rcode = 1
  	goto bspexit
  	end
  
  select @msg = Title from DDLHShared where Lookup= @lookup
  
  if @@rowcount = 0
  	begin
  	select @msg = 'Lookup not on file!', @rcode = 1
  	end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDLookupVal] TO [public]
GO
