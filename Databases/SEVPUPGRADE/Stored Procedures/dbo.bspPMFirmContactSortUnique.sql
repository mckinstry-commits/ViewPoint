SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMFirmContactSortUnique    Script Date: 8/28/99 9:35:11 AM ******/
   CREATE   proc [dbo].[bspPMFirmContactSortUnique]
   /*************************************
   * CREATED BY    : SAE  12/16/97
   * LAST MODIFIED : SAE  12/16/97
   * validates PM Firm Contact Sort name to make sure it's unique by Firm
   *
   * Pass:
   *	PM VendorGroup
   *       PM Firm	       Firm this sort name is going to( sort name is unique by Firm)
   *       PM Contact     Contact this sort name is on(so we don't get tripped up by or own)
   *	PM ContactSort    Hopefully unique Sort name
   * Returns:
   *	Nothing
   * Success returns:
   *      Nothing
   *
   * Error returns:
   
   *	1 and error message
   *       0 Success
   *
   *******************************/
   (@vendorgroup bGroup, @firm bFirm, @contact bEmployee, @contactsort varchar(15), @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @msg='Unique'
   
   if @contactsort is null
   	begin
   	select @msg = 'Missing contact sort name!', @rcode = 1
   	goto bspexit
   	end
   
   
   -- See if Firm sort name exists
   select @msg='Sort name already used on Firm ' + convert(varchar(10), FirmNumber) + ' contact ' + convert(varchar(10), ContactCode), @rcode=1
   from bPMPM with (nolock) where VendorGroup = @vendorgroup and FirmNumber=@firm 
   and SortName=@contactsort and (ContactCode<>@contact)
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMFirmContactSortUnique] TO [public]
GO
