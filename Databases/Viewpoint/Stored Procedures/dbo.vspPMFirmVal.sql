SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE   proc [dbo].[vspPMFirmVal]
/*********************************************
 * Created By:	GF 04/07/2005
 * Modified By:
 *
 *
 *
 * validates PM Firm for PM Firm contacts
 *
 * Pass:
 *	PM VendorGroup
 *	PM FirmSort    Firm or sortname of firm, will validate either
 *
 * Returns:
 *	FirmNumber
 *   Firm Contact
 *
 * Success returns:
 *      FirmNumber and Firm Name
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@vendorgroup bGroup, @firmsort bSortName, @firmout bFirm = null output,
 @contact varchar(30) output, @phone bPhone output, @fax bPhone output, 
 @email varchar(60) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @firmsort is null
	begin
   	select @msg = 'Missing Firm!', @rcode = 1
   	goto bspexit
   	end

-- -- -- if firm is not numeric then assume a SortName
if dbo.bfIsInteger(@firmsort) = 1
	begin
  	if len(@firmsort) < 7
		begin
  		-- -- -- validate firm to make sure it is valid to use
  		select @firmout = FirmNumber, @contact=ContactName, @msg=FirmName, @phone=Phone, @fax=Fax, @email=EMail
  		from PMFM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=convert(int,convert(float, @firmsort))
  		end
  	else
  		begin
  		select @msg = 'Invalid firm number, length must be 6 digits or less.', @rcode = 1
  		goto bspexit
  		end
  	end

-- -- -- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
   	begin
   	select @firmout = FirmNumber, @contact=ContactName, @msg = FirmName, @phone=Phone, @fax=Fax, @email=EMail
   	from PMFM with (nolock) where VendorGroup=@vendorgroup and SortName=@firmsort
   	-- -- -- if not found,  try to find closest
   	if @@rowcount = 0
   		begin
   		select @firmout=FirmNumber, @contact=ContactName, @msg=FirmName, @phone=Phone, @fax=Fax, @email=EMail
   		from PMFM with (nolock) where VendorGroup=@vendorgroup and SortName like @firmsort + '%'
   		if @@rowcount = 0
			begin
   		 	select @msg = 'PM Firm ' + convert(varchar(15),isnull(@firmsort,'')) + ' not on file!', @rcode = 1
  			goto bspexit
  			end
   		end
   	end






bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMFirmVal] TO [public]
GO
