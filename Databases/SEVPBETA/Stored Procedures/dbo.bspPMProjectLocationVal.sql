SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMProjectLocationVal    Script Date: 8/28/99 9:35:17 AM ******/
   CREATE proc [dbo].[bspPMProjectLocationVal]
   /*************************************
   * CREATED BY    : SAE  12/9/97
   * LAST MODIFIED : SAE  12/9/97
   * validates PM Project Location Types
   *
   * Pass:
   *	PM Company
   *	PM Project
   *       PM Location
   *
   * Returns:
   
   *       Description or Error Message
   *
   * Success returns:
   *	0 and Description from FirmType
   *
   * Error returns:
   
   *	1 and error message
   *******
   *******************************/
   (@pmco bCompany, @project bJob, @location varchar(10), @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @pmco is null
   	begin
   	select @msg = 'Missing company!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bPMPL with (nolock)
   where PMCo=@pmco and Project=@project and Location=@location
   if @@rowcount = 0
   	begin
   	select @msg = 'PM Project Location ' + isnull(@location,'') + ' is not on file!', @rcode = 1
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjectLocationVal] TO [public]
GO
