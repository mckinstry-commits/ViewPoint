SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDLookupVal    Script Date: 8/28/99 9:32:38 AM ******/
  
  CREATE   procedure [dbo].[vspVADDGetAppPassword]
  /***********************************************************
   * CREATED BY: MJ 04/11/05
   * MODIFIED By : 
   *					
   * USAGE:
   * gets app role security password
   *
   * INPUT PARAMETERS
  
   *   
   * INPUT PARAMETERS
   *   @msg        error message if something went wrong, otherwise description
   * RETURN VALUE
   *   0 Success
   *   1 fail
   ************************************************************************/
  	@msg varchar(60) output
  as
  set nocount on
  declare @rcode int
  select @rcode = 0
  
  Select AppRolePassword from vDDVS

  
  if @@rowcount = 0
  	begin
  	select @msg = 'Password not found!', @rcode = 1
  	end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVADDGetAppPassword] TO [public]
GO
