SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    function [dbo].[vfPOVendorCompliedYN]
  (@poco bCompany, @vendorgroup bGroup, @vendor bVendor, @invdate bDate)
      returns bYN
   /***********************************************************
    * CREATED BY	: DC 11/19/08
    * MODIFIED BY	: 
    *
    * USAGE:
    * Used to return a Complied flag value of "Y" or "N" for 
	*	 vendor compliance
    *
    * INPUT PARAMETERS
    * 	@poco
    * 	@vendorgroup
    * 	@vendor
    *	InvDate 
    *
    * OUTPUT PARAMETERS
    *  @compliedyn      
    *
    *****************************************************/
      as
      begin

        declare @compliedyn bYN 
		select @compliedyn = 'Y'
 
       -- check if vendor is out of compliance
		if exists(select 1 from bAPVC v join bHQCP h on v.CompCode=h.CompCode
   		where v.APCo=@poco and v.VendorGroup=@vendorgroup and v.Vendor=@vendor
   		and v.Verify='Y' and ((CompType='D' and (ExpDate<@invdate or
   		ExpDate is null)) or (CompType='F' and (Complied='N' or Complied is null))))
		begin
		select @compliedyn='N'
		end
 			
  	return @compliedyn
      end

GO
GRANT EXECUTE ON  [dbo].[vfPOVendorCompliedYN] TO [public]
GO
