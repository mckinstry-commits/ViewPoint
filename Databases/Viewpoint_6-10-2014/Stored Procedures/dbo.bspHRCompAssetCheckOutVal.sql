SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[bspHRCompAssetCheckOutVal]
   /************************************************************************
   * CREATED:  mh 5/19/04    
   * MODIFIED: mh 2/8/05 Issue 28134 - added @assignmsg variable to pass
   *			into bspHRCompAssetVal   
   *
   * Purpose of Stored Procedure
   *
   *	Validates an Asset.  It must exist in HRCA.
   *	Determine if the Asset is checked out.
   *	If not checked out determine if it is available for checkout.
   *	Procedure will also return the captions used by controls on the form
   *	along with a flag to set which mode the form will be in.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *	@hrco - HR Company you are in
   *	@asset - Asset to be checked in or out
   *	@chkinoutcap - Caption for the frame
   *	@dateinoutcap - Caption for the date 
   *	@memoinoutcap - Memo for the memo
   *	@checkin - flag to determine if form will be in check in or check out mode.
   *	@dateout - date asset was checked out
   *
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @asset varchar(20), @hrref bHRRef output, @chkinoutcap varchar(10) output,  
   	@dateinoutcap varchar(10) output, @memoinoutcap varchar(10) output,
   	/*@checkin char(1) output*/ @status tinyint output, @dateout bDate output,
   	@msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @assignmsg varchar(8000) 
   
       select @rcode = 0
   
   	if @hrco is null
   	begin	
   		select @msg = 'Missing Required HR Company!', @rcode = 1
   		goto bspexit
   	end
   
   	if @asset is null
   	begin
   		select @msg = 'Missing Asset!', @rcode = 1
   		goto bspexit
   	end


	--@assignmsg is used by HRCompAssets.     
   	--exec @rcode = dbo.bspHRCompAssetVal @hrco, @asset, 'X', @assignmsg output, @msg output

	declare @assignto varchar(30), @memo varchar(60), @datein bDate, @checkoutstatus bYN, @valdateout bDate

	exec @rcode = dbo.bspHRCompAssetVal @hrco, @asset, 'X', @assignmsg output, @assignto output, 
	@valdateout output, @memo output, @datein output, @checkoutstatus output, @msg output
   
   	if @rcode = 0
   	begin
   		--is asset checked out?
--   		if (select max(DateOut) from dbo.HRTA with (nolock)
--   		where HRCo = @hrco and Asset = @asset and DateIn is null) is not null
		if @checkoutstatus = 'Y'
   		begin
   			--Asset is checked out
   			select @hrref = t.HRRef, @chkinoutcap = 'Check In', @dateinoutcap = 'Date In:', 
   			@memoinoutcap = 'Memo In:', /*@checkin = 'Y'*/ @status = a.Status, @dateout = t.DateOut,
			@dateout = @valdateout
   			from dbo.HRTA t with (nolock) Join dbo.HRCA a with (nolock) on 
   			t.HRCo = a.HRCo and
   			t.Asset = a.Asset
   			where t.HRCo = @hrco and t.Asset = @asset and 
   			t.DateOut = (select max(DateOut) from dbo.HRTA with (nolock)
   			where HRCo = @hrco and Asset = @asset and DateIn is null)
   
   			goto bspexit
   		end
   		else
   		begin
   			--asset is checked in.  Is it available for check out?
   
   			select @status = Status from dbo.HRCA  with (nolock) where HRCo = @hrco and Asset = @asset
   
   			if @status = 0
   			begin
   				select @chkinoutcap = 'Check Out', @dateinoutcap = 'Date Out:', 
   				@memoinoutcap = 'Memo Out:', @dateout = null /*, @checkin = 'N', @status = Status */
   				from dbo.HRCA with (nolock) where HRCo = @hrco and Asset = @asset
   				goto bspexit
   			end
   
   			else
   				select @msg = 'Asset not available for checkout', @rcode = 1
   		end
   	end
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCompAssetCheckOutVal] TO [public]
GO
