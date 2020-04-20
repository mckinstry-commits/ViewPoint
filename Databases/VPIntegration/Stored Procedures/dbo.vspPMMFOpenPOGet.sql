SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************/
CREATE proc [dbo].[vspPMMFOpenPOGet]
/*************************************
 * Created By:		GP	07/21/2009 - Issue #129667
 * Modified By:		GP 7/29/2011 - TK-07143 changed @PO from varchar(10) to varchar(30)
 *				
 *
 * Pass in criteria to get the last entered PO.
 *
 * Pass:
 *	 APCo		   AP Company
 *   PMCo          PM Company
 *	 VendorGroup   Vendor Group
 *	 Vendor		   Vendor
 *   Project       Project
 *	 MatlOption    Material Option
 *
 * Returns:
 *	 MSG if Error
 *
 * Success returns:
 *	 0 on Success, 1 on ERROR
 *
 * Error returns:
 *	 1 and error message
 **************************************/
 (@APCo bCompany = null, @PMCo bCompany = null, @VendorGroup bGroup = null, @Vendor bVendor = null, 
	@Project bJob = null, @PO varchar(30) = null output, @msg varchar(255) output)
 as
 set nocount on
  
 declare @rcode int, @MaxDate bDate
 
 set @rcode = 0
 
	
--Get last OrderDate	
select @MaxDate = max(OrderDate) from dbo.POHD with (nolock) where POCo=@APCo and VendorGroup=@VendorGroup 
	and Vendor=@Vendor and Status=0	

--Get PO
select @PO = max(PO) from dbo.POHD h with (nolock) where h.POCo=@APCo and h.VendorGroup=@VendorGroup 
	and h.Vendor=@Vendor and h.Status=0 and h.OrderDate=@MaxDate and exists(select top 1 1 from dbo.POIT i with (nolock)
	where i.POCo=h.POCo and i.PO=h.PO and i.JCCo=@PMCo and i.Job=@Project)
						


vspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMMFOpenPOGet] TO [public]
GO
