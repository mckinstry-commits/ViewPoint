SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************************/
CREATE proc [dbo].[bspPMFirmMasterLookup]
/******************************************************
     * CREATED BY    : bc 9/16/98
     * LAST MODIFIED : TV 09/06/01
     * Validates firm but allows an 'invalid' firm because the user could be adding a new Firm to master.
     * Which means this bsp should only be used in one place. PMFM.  Not for use at other inputs
     * 				  GF 12/12/2001 - Not working correctly, if a number is entered a error is returned
     * 								  as invalid firm. Also does not allow new entries, same error occurs.
     *				  GF 06/08/2004 - issue #24761 arithmetic overflow error
     *
     *
     * Pass:
     *	PM VendorGroup
     *	PM FirmSort    Firm or sortname of firm, will validate either
     * Returns:
     *	FirmNumber
     * Success returns:
     *      FirmNumber and Firm Name
     *
     * Error returns:
     *	1 and error message
     **************************************/
(@vendorgroup bGroup, @firmsort varchar(15), @firmout bFirm = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @vendorgroup is null
	begin
	select @msg = 'Missing vendor group', @rcode = 1
	goto bspexit
	end

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
   		select @firmout=FirmNumber, @msg=FirmName
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
	select @firmout = FirmNumber, @msg = FirmName
	from PMFM with (nolock) where VendorGroup=@vendorgroup and SortName=@firmsort
	-- -- -- if not found,  try to find closest
	if @@rowcount = 0
		begin
   		set rowcount 1
   		select @firmout=FirmNumber, @msg=FirmName
		from PMFM with (nolock) where VendorGroup=@vendorgroup and SortName like @firmsort + '%'
   		if @@rowcount = 0
   			begin
    		 -- -- -- select @msg = 'PM Firm ' + convert(varchar(6),@firmsort) + ' not on file!', @rcode = 1
    		if dbo.bfIsInteger(@firmsort) = 1 and len(@firmsort) < 7 
   			select @firmout = convert(int, @firmsort)
   		else
   			select @firmout = null
    		goto bspexit
    	   	end
    	set rowcount 0
    	end
    end






bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMFirmMasterLookup] TO [public]
GO
