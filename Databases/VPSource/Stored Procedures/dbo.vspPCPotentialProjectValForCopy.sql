SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPCPotentialProjectValForCopy]
  /***********************************************************
   * CREATED BY:	GP	09/30/2010
   * MODIFIED BY:	
   *				
   * USAGE:
   * Used in PM Potential Projects Copy to validate new project copy.
   *
   * INPUT PARAMETERS
   *   JCCo   
   *   PotentialProject
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Department if found.
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@JCCo bCompany, @PotentialProject varchar(20), @msg varchar(255) output)
  as
  set nocount on
  
  declare @rcode int
  set @rcode = 0

	--Get Description
	select @msg = Description 
	from dbo.PCPotentialWork with (nolock)
	where JCCo = @JCCo and PotentialProject = @PotentialProject
	
	-- Check for existence
	if @@rowcount > 0
	begin
		select @msg = 'Potential Project already exists. Enter a new value or use copy to existing option.', @rcode = 1
	end


	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCPotentialProjectValForCopy] TO [public]
GO
