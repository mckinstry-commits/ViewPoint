SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRRaceDesc    Script Date: 8/28/99 9:33:17 AM ******/
  CREATE    proc dbo.vspPRRaceDesc
  /***********************************************************
   * CREATED BY: EN 1/18/06
   * MODIFIED By : 
   *
   * USAGE:
   *	Used in PRRace to return description to the key field.
   *
   * INPUT PARAMETERS
   *   PRCo   PR Co to validate agains 
   *   Race   PR race code to validate
   * OUTPUT PARAMETERS
   *   @msg      Description of Race Code
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@prco bCompany = 0, @race char(2) = null, @msg varchar(60) output)
  as
  
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0, @msg = ''
  
  if @prco is not null and isnull(@race,'') <> ''
	begin
	select @msg = Description from dbo.PRRC with (nolock) where PRCo = @prco and Race=@race 
  	end
  
  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRRaceDesc] TO [public]
GO
