SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE  proc [dbo].[bspPMFirmValForPODist]
/*********************************************
* CREATED BY:		CHS  03/08/2010
* LAST MODIFIED:
*	
*					
*
*
* validates PM Firm
*
* Pass:
*	PM VendorGroup
*	PM FirmSort    Firm or sortname of firm, will validate either
*	PM PO KeyID		KeyId to the POHD record
*	PM Distribution Sequence
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
(@vendorgroup bGroup, @firmsort varchar(15), @parentkeyid bigint, @dist_seq bigint = null, @firmout bFirm = null output,
 @contact varchar(30) output, @alreadyindist bYN = 'N' output, @msg varchar(255) output)
as
set nocount on
    
    declare @rcode int
    
    select @rcode = 0
    set @alreadyindist = 'N'
    
    if @firmsort is null
    begin
    	select @msg = 'Missing Firm!', @rcode = 1
		goto bspexit
    end
   
	-- if firm is not numeric then assume a SortName
	if dbo.bfIsInteger(@firmsort) = 1
	begin
   		if len(@firmsort) < 7
   		begin
   			-- validate firm to make sure it is valid to use
   			select @firmout = FirmNumber, @contact=ContactName, @msg=FirmName
   			from PMFM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=convert(int,convert(float, @firmsort))
   		end
   		else
   		begin
   			select @msg = 'Invalid firm number, length must be 6 digits or less.', @rcode = 1
   			goto bspexit
   		end
	end
   	       
    -- if not numeric or not found try to find as Sort Name
	if @@rowcount = 0
    begin
    	select @firmout = FirmNumber, @contact=ContactName, @msg = FirmName
    	from PMFM with (nolock) where VendorGroup=@vendorgroup and SortName=@firmsort
    	-- if not found,  try to find closest
    	if @@rowcount = 0
    	begin
    		select @firmout=FirmNumber, @contact=ContactName, @msg=FirmName
    		from PMFM with (nolock) where VendorGroup=@vendorgroup and SortName like @firmsort + '%'
    		if @@rowcount = 0
     	  	begin
    		 	select @msg = 'PM Firm ' + convert(varchar(15),isnull(@firmsort,'')) + ' not on file!', @rcode = 1
   				goto bspexit
   			end
    	end
    end
   
   
---- need to check to see if the sequence number exists (change mode)
if @dist_seq is null
	begin
	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where PurchaseOrderID = @parentkeyid and CC='N')
		begin
		set @alreadyindist = 'Y'
		----select @msg = 'PM Firm ' + convert(varchar(15),isnull(@firmout,'')) + ' is already configured to receive email!', @rcode = 1
  ---- 		goto bspexit		
		end
	end
else
	BEGIN
   	if exists(select top 1 1 from dbo.PMDistribution with (nolock) where PurchaseOrderID = @parentkeyid and Seq <> @dist_seq and CC='N')
		begin
		set @alreadyindist = 'Y'
		----select @msg = 'PM Firm ' + convert(varchar(15),isnull(@firmout,'')) + ' is already configured to receive email!', @rcode = 1
  ---- 		goto bspexit		
		end
	END

		
   
	bspexit:
   		if @rcode <> 0 select @msg = isnull(@msg,'') 
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMFirmValForPODist] TO [public]
GO
