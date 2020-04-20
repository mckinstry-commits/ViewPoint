SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspHRCompAssetValAssigned]
   /************************************************************************
   * CREATED:	MH 6/1/04    
   * MODIFIED: mh 2/8/05 Issue 28134 - added @assignmsg variable to pass
   *			into bspHRCompAssetVal 
   *			DAN SO 07/17/09 - Issue: #132218 - Asset Desc not correct - added Country to bspHRCompAssetVal call
   *
   * Purpose of Stored Procedure
   *
   *    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
    (@hrco bCompany, @asset varchar(20), @hrref bHRRef, @valtype char(1), @datein bDate,
   	@dateout bDate, @msg varchar(100) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @lasthrref bHRRef, @status tinyint, @Country VARCHAR(10), @assignmsg varchar(8000)
   
       select @rcode = 0

	--@assignmsg is used by HRCompAssets.     
   	--exec @rcode = dbo.bspHRCompAssetVal @hrco, @asset, 'X', @assignmsg output, @msg output
	declare @assignto varchar(30), @memo varchar(60), @checkoutstatus bYN

	-- ISSUE #132218
	exec @rcode = dbo.bspHRCompAssetVal @hrco, @asset, 'X', @assignmsg output, @assignto output, 
	@dateout output, @memo output, @datein output, @checkoutstatus output, @Country OUTPUT, @msg output
   
   	if @rcode = 0
   	begin
   
   		select @status = Status from dbo.HRCA with (nolock) where HRCo = @hrco and Asset = @asset
   		--First check if Asset it already assigned
   		--if (Select Status from dbo.HRCA with (nolock) where HRCo = @hrco and Asset = @asset) <> 0
   		if @status <> 0
   		begin
   			if @status = 2
   			begin
   				select @msg = 'Asset is unavailable for check out', @rcode = 1
   				goto bspexit
   			end
   
   			--we are at a status of 1
   			select @lasthrref = HRRef from dbo.HRTA with (nolock) where HRCo = @hrco and Asset = @asset and
   			DateOut = (select Max(DateOut) from dbo.HRTA with (nolock) where HRCo = @hrco and 
   			Asset = @asset and DateIn is null)
   
   			if @lasthrref <> @hrref
   			begin
   				select @msg = 'Asset is unavailable for checkout', @rcode = 1
   /*
   				select @msg = 'Asset is currently assigned or unavailable for check out. Last HRRef = ' +
   				convert(varchar(20), @lasthrref) + ' Current HRRef = ' + convert(varchar(20), @hrref), @rcode = 1
   */
   				goto bspexit
   			end
   
   			else
   			begin
   				if (@dateout is null) and (@datein is null)
   				begin
   					select @msg = 'Asset is unavailable for checkout', @rcode = 1
   				end
   			end
   
   		end
   	end
   
   bspexit:
   
       --poss error and clean up code goes here
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCompAssetValAssigned] TO [public]
GO
