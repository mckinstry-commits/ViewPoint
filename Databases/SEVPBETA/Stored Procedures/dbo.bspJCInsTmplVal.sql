SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCInsTmplVal    Script Date: 8/28/99 9:32:58 AM ******/


CREATE   proc [dbo].[bspJCInsTmplVal]
/***********************************************************
* CREATED BY:		SE		10/2/96
* MODIFIED By:		SE		10/2/96
*					TV		23061 added isnulls
*					CHS		06/10/2009 - #132119 - added description
*
* USAGE:
* Validates JC insurance template.
* An error is returned if any of the following occurs:
* no insurance template passed, no insurance template found.
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against
*   InsTemplate  Insurance template to validate
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Template description
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @instemplate smallint = null, @desc varchar(60) output, @msg varchar(60) output)
as
set nocount on   
   
   
   	declare @rcode int
   	select @rcode = 0
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @instemplate is null
   	begin
   	select @msg = 'Missing Insurance Template!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @desc = Description
   	from JCTN
   	where JCCo = @jcco and InsTemplate = @instemplate
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Insurance template not on file!', @desc = 'New insurance template.',@rcode = 1
   	goto bspexit
   	end


   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCInsTmplVal] TO [public]
GO
