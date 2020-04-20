SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPGLCoVal]
  /***********************************************************
   * CREATED BY: MV 12/01/05
   * MODIFIED By :	
   *              
   *
   * USAGE:
   * validates GL Company number and returns the tax group
   * 
   * INPUT PARAMETERS
   *   GLCo   GLP Co to Validate  
  
  
   * OUTPUT PARAMETERS
   *	@taxgroup 
   *    @msg If Error, error message, otherwise description of Company
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@glco bCompany = 0, @taxgroup int output, @msg varchar(60)=null output)
  as
  
  set nocount on
  
  
  declare @rcode int
  select @rcode = 0
  	
 if @glco is null
  	begin
  	select @msg = 'Missing GL Company#', @rcode = 1
  	goto bspexit
  	end
  
  if exists(select * from GLCO where @glco = GLCo)
  	begin
  	select @taxgroup = TaxGroup from bHQCO where HQCo = @glco
  	goto bspexit
  	end
  else
  	begin
  	select @msg = 'Not a valid GL Company', @rcode = 1
  	end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPGLCoVal] TO [public]
GO
