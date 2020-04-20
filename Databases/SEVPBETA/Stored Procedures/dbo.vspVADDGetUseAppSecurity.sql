SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDLookupVal    Script Date: 8/28/99 9:32:38 AM ******/
  
  CREATE   procedure [dbo].[vspVADDGetUseAppSecurity]
  /***********************************************************
   * CREATED BY: JRK 03/06/07
   * MODIFIED By : 
   *					
   * USAGE:
   * gets app role security flag
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
  
  Select TOP 1 UseAppRole, AppRolePassword from vDDVS

  
  if @@rowcount = 0
  	begin
  	select @msg = 'UseAppSecurity not found!', @rcode = 1
  	end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVADDGetUseAppSecurity] TO [public]
GO
