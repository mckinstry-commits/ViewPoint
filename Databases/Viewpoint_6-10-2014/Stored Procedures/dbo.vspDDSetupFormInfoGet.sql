SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspDDMOVal    Script Date: 8/28/99 9:34:21 AM ******/
 CREATE   proc [dbo].[vspDDSetupFormInfoGet]
  /***********************************************************
   * CREATED BY: kb 9/29/5
   * MODIFIED By : 
   *			
   * USAGE:
   * validates Module
   *
   * INPUT PARAMETERS
   *	@setupform
   *
   * OUTPUT PARAMTERS
	@setupform
        @assemblyname
	@formclassname
        @errmsg

   * RETURN VALUE
   *   0 Success
   *   1 fail
   ************************************************************************/
  	(@setupform varchar(20), @assemblyname varchar(50) output, @formclassname varchar(50) output,
        @errmsg varchar(500) output)
  as
  set nocount on
  begin
  	declare @rcode int
  	select @rcode = 0
  if @setupform is null
  	begin
  	select @errmsg = 'Missing Setup Form!', @rcode = 1
  	goto vspexit
  	end
  
  select @assemblyname = AssemblyName, @formclassname = FormClassName from dbo.vDDFH
  	where Form = @setupform
  if @@rowcount = 0
  	begin
  	select @errmsg = 'Setup Form not on file!', @rcode = 1
  	end
  
  vspexit:
  	return @rcode                                                   
  end

GO
GRANT EXECUTE ON  [dbo].[vspDDSetupFormInfoGet] TO [public]
GO
