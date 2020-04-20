SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspDDMOVal    Script Date: 8/28/99 9:34:21 AM ******/
CREATE  proc [dbo].[vspDDMOVPRPVal]
  /***********************************************************
   * CREATED BY: ??   ?/??/?   Used for Crystal Group to assign Reports to DD
   * MODIFIED By : SE 9/04/96
   *				  DANF 08/03/2004 - Issue 25126 VA can secure forms in the DD module for all users.
   *				  TRL   08/03/2005 - create for 'v' tables
   * USAGE:
   * validates Module
   *
   * INPUT PARAMETERS
  
   *   Module       Module to validate
   * INPUT PARAMETERS
   *   @msg        error message if something went wrong, otherwise description
   * RETURN VALUE
   *   0 Success
   *   1 fail
   ************************************************************************/
  	(@Module varchar(2) = null, @msg varchar(60) output)
  as
  set nocount on
  begin
  	declare @rcode int
  	select @rcode = 0
  if @Module is null
  	begin
  	select @msg = 'Missing Module!', @rcode = 1
  	goto vspexit
  	end
  
  select @msg = Title from dbo.vDDMO
  	where Mod = @Module 
  if @@rowcount = 0
  	begin
  	select @msg = 'Module not on file!', @rcode = 1
  	end
  
  vspexit:
  	return @rcode                                                   
  end

GO
GRANT EXECUTE ON  [dbo].[vspDDMOVPRPVal] TO [public]
GO
