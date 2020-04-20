SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDUPNameVal    Script Date: 8/28/99 9:34:22 AM ******/
  CREATE  proc [dbo].[vspDDFSNameVal]
  /***********************************************************
   * CREATED BY: mj 3/21/05
   * MODIFIED By : 
   *
   * USAGE:
   * validates UserName
   *
   * INPUT PARAMETERS
  
   *   Form         Form to validate
   * INPUT PARAMETERS
   *   @FormTable         Main table from DDFH
   *   @msg        error message if something went wrong
   * RETURN VALUE
   *   0 Success
   *   1 fail
   ************************************************************************/
  	(@uname bVPUserName = null, @msg varchar(60) output)
  as
  set nocount on
  declare @rcode int
  select @rcode = 0
  
  if @uname is null
  	begin
  	select @msg = 'Missing user name', @rcode = 1
  	goto vspexit
  	end
  
  select @msg = VPUserName from vDDUP where VPUserName = @uname
  if @@rowcount = 0
  	begin
  	select @msg = 'DDUP user name not on file', @rcode = 1
  	end
  
  vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFSNameVal] TO [public]
GO
