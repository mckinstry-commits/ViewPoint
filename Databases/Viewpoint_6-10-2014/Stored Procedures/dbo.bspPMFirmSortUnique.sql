SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMFirmSortUnique    Script Date: 8/28/99 9:35:11 AM ******/
   CREATE proc [dbo].[bspPMFirmSortUnique]
   /*************************************
   * CREATED BY    : SAE  12/16/97
   * LAST MODIFIED : SAE  12/16/97
   * validates PM Firm Sort name to make sure it's unique
   *
   * Pass:
   *	PM VendorGroup
   *       PM Firm	       Firm this sort name is going to(so we don't get tripped up by our own )
   *	PM FirmSort    Hopefully unique Sort name
   * Returns:
   *	Nothing
   * Success returns:
   *      FirmNumber and Firm Name
   *
   * Error returns:
   
   *	1 and error message
   *       0 Success
   *******
   *******************************/
   (@vendorgroup bGroup, @firm bFirm, @firmsort varchar(15), @msg varchar(60) output)
   
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @msg='Unique'
   
   if @firmsort is null
   	begin
   	select @msg = 'Missing Firm sort name!', @rcode = 1
   	goto bspexit
   	end
   
   
   -- See if Firm sort name exists
   select @msg='Sort name already used on Firm ' + convert(varchar(10), FirmNumber), @rcode=1
   from bPMFM with (nolock) where VendorGroup = @vendorgroup and SortName=@firmsort and FirmNumber <> @firm
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMFirmSortUnique] TO [public]
GO
