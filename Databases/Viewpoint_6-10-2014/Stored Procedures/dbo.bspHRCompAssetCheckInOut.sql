SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspHRCompAssetCheckInOut]
    /************************************************************************
    * CREATED:  mh 5/20/04    
    * MODIFIED:	mh 2/6/2006 - 6.x issue 30399    
    *
    * Purpose of Stored Procedure
    *
    *	Check out an asset to a HRResource by creating 
    *	and entry in bHRTA
    *
    *	or
    *
    *	Check in an asset by updating an existing entry in bHRTA    
    *    
    *           
    * Notes about Stored Procedure
    * 
    *	@hrco - HR Company 
    *	@asset - Asset being checked in/out
    *	@dateout - Date asset was checked out (if we are checking in)
    *	@checkInOut - Flag to determine operation (check in or check out)
    *	@hrref - Resource asset will be checked out to
    *	@dateinout - Date of check in/out note: this may differ from @dateout
    *	@memoinout - Memo describing condition in or out
    *	@makeavail - Flag to determine if asset will be made available in bHRCA
    *
    * returns 0 if successfull 
    * returns 1 and error msg if failed
    *
	*  Issue 30399 - During the design process we were aware an Asset cannot be checked out
	*				to the same Resource more then once on a given day.  Need to tighten it
	*				down in this procedure.  Added check to see if key value exists and if so
	*				return an error back to user informing the Asset was previously checked out
	*				to the HRCo/HRRef/Asset/DateOut key combination.  Previously, the update 
	*				of status back to HRCA was handled at the bottom of the procedure after
	*				insert/update to HRTA.  If an error occured in the insert/update it would 
	*				continue the update to HRCA which we do not want.  
    *************************************************************************/
    
        (@hrco bCompany, @asset varchar(20), @dateout bDate, /*@checkInOut char(1)*/ @status tinyint, @hrref bHRRef,
    	@dateinout bDate,@memoinout varchar(60), @makeavail char(1), 
    	@msg varchar(100) = '' output)
    
    as
    set nocount on
    
        declare @rcode int, @newstatus tinyint
    
        select @rcode = 0
    
    	if @hrco is null
    	begin	
    		select @msg = 'Missing Required HR Company!', @rcode = 1
    		goto bspexit
    	end
    
    	if @asset is null
    	begin
    		select @msg = 'Missing Required Asset!', @rcode = 1
    		goto bspexit
    	end
    
    	if @hrref is null
    	begin
    		select @msg = 'Missing Required HR Resource Number!', @rcode = 1
    		goto bspexit
    	end
    
    	if @dateinout is null
    	begin
    		select @msg = 'Missing Required Checking Out/In date!', @rcode = 1
    		goto bspexit
    	end
    
    
    	--may need to validate checkout status here.  Need the date out.
    	
    
    	--if @checkInOut = 'Y' --we are checking asset in
    	if @status <> 0
    	begin
    
    		--Verify  this is an actual check out.  Status could have been
    		--set to 1 but not checked out.
    		if (select DateIn from dbo.HRTA with (nolock) where HRCo = @hrco and 
    		HRRef = @hrref and DateOut = @dateout and Asset = @asset) is null
    		begin
    			Update dbo.HRTA set DateIn = @dateinout, MemoIn = @memoinout
    			where HRCo = @hrco and HRRef = @hrref and DateOut = @dateout and
    			Asset = @asset

				if @@rowcount = 1
				begin    
	    			if @makeavail = 'Y'
    					select @newstatus = 0
    				else	
    					select @newstatus = 1

					Update dbo.HRCA set Status = @newstatus where HRCo = @hrco and Asset = @asset
				end
				else
				begin
					select @msg = 'Error updating HRTA. Unable to check in Asset', @rcode = 1
					goto bspexit
				end
    		end
    		else
    		begin
    			select @msg = 'Asset is not available for CheckOut', @rcode = 1
    			goto bspexit
    		end
    	end
    
    	--if @checkInOut = 'N' -- we are checking asset out
    	if @status = 0
    	begin

		--check that insert will not violate key constraint

			if exists (select * from dbo.HRTA where HRCo = @hrco and HRRef = @hrref and Asset = @asset and DateIn = @dateinout)
			begin
				select @msg = 'Asset previously checked out to Resource ' + convert(varchar(10), @hrref) + ' on ' + convert(varchar(11),@dateinout) + '.  Cannot check out asset.', @rcode = 1
				goto bspexit
			end
			else
			begin
	    		insert dbo.HRTA (HRCo, HRRef, Asset, DateOut, MemoOut)
    			values (@hrco, @hrref, @asset, @dateinout, @memoinout)

    			if @@rowcount = 1
				begin
	    			select @newstatus = 1
					Update dbo.HRCA set Status = @newstatus where HRCo = @hrco and Asset = @asset
				end
				else
				begin
					select @msg = 'Error inserting HRTA. Unable to check in Asset', @rcode = 1
					goto bspexit
				end
			end
    	end 
    
    /*
    	update dbo.HRCA set Status = (case @makeavail when 'Y' then 0 else 1 end)
    	where HRCo = @hrco and Asset = @asset
    */
    
    	--Update dbo.HRCA set Status = @newstatus where HRCo = @hrco and Asset = @asset
    
    bspexit:
    
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCompAssetCheckInOut] TO [public]
GO
