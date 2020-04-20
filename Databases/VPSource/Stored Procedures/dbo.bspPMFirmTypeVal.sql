SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMFirmTypeVal    Script Date: 8/28/99 9:35:11 AM ******/
   CREATE proc [dbo].[bspPMFirmTypeVal]
   /*************************************
   * CREATED BY    : SAE  11/9/97
   * LAST MODIFIED : SAE  11/9/97
   * validates PM Firm Types
   *
   * Pass:
   *	PM Company
   *	PM Firm Type
   *
   * Returns:
   *
   * Success returns:
   *	0 and Description from FirmType
   *
   * Error returns:
   
   *	1 and error message
   *******
   *******************************/
   (@firmtype bFirmType = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @firmtype is null
   	begin
   	select @msg = 'Missing Firm type!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bPMFT with (nolock) where FirmType = @firmtype
   if @@rowcount = 0
   	begin
   	select @msg = 'PM FirmType ' + isnull(@firmtype,'') + ' not on file!', @rcode = 1
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMFirmTypeVal] TO [public]
GO
