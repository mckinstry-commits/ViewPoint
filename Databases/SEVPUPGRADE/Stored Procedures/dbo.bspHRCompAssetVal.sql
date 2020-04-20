SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspHRCompAssetVal]
/************************************************************************
* CREATED:  mh 5/18/2004    
* MODIFIED: CHS 11/20/08 - #130774 - added country output
*
* Purpose of Stored Procedure
*
*    Validate an Asset against bHRCA.
*    
*           
* Notes about Stored Procedure
* 
*  @valtype is the type of validation we are doing.  If it's 'M' we are validating
*  Asset in HRCompanyAssets.  If no asset found assume an add and do not return error.
*  Anything other then 'M' then we are validating an Asset elsewhere and we will want
*  to know if it exists or not.
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
   
(@hrco bCompany, @asset varchar(20), @valtype char(1), @assignmsg varchar(8000) = null output, 
@assignto varchar(30) output, @dateout bDate output, @memo varchar(60) output, @datein bDate output,
@checkoutstatus bYN output, @country varchar(10) output, @msg varchar(80) = null output)
   

   as
   set nocount on


select @country = HQCO.DefaultCountry
from HQCO with (nolock) where HQCO.HQCo = @hrco
   
       declare @rcode int
   
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
   
   	if @valtype is null
   		select @valtype = 'X'
   
   	select @msg = AssetDesc from dbo.HRCA with (nolock) where HRCo = @hrco and Asset = @asset
   
   	if @@rowcount = 0
   	begin
   		if @valtype <> 'M'
   			select @msg = 'Asset does not exist in HR Company Assets.', @rcode = 1
   		else
  			select @msg = ''
   	end 
	else
	begin
--		exec @rcode = bspHRCompAssetGetLastAssign @hrco, @asset, @assignmsg output
--		if @rcode = 1
--			select @assignmsg = 'Unable to retrieve last assignment information for asset.'

--test
		select @assignto = convert(varchar(20),isnull(c.Assigned,'')) + ' ' + isnull(e.FullName,''), 
		@dateout = a.DateOut, @memo = a.MemoOut, @checkoutstatus = 'Y'
   		from dbo.HRTA a with (nolock) 
   		join dbo.HRRMName e with (nolock) on a.HRCo = e.HRCo and a.HRRef = e.HRRef 
  		join dbo.HRCA c with (nolock) on a.HRCo = c.HRCo and a.HRRef = c.Assigned and a.Asset = c.Asset
   		where a.HRCo = @hrco and a.Asset = @asset and a.DateOut = (select max(DateOut) from dbo.HRTA with (nolock)
   			where HRCo = @hrco and Asset = @asset and DateIn is null)
--test

   		select @assignmsg = 'Assigned To: ' + convert(varchar(20),isnull(c.Assigned,'')) + 
   		' ' + isnull(e.FullName,'') + ' ' + 'on ' + convert(varchar(11),isnull(a.DateOut,'')) + '.  Out Memo: ' + isnull(a.MemoOut,'')
   		from dbo.HRTA a with (nolock) 
   		join dbo.HRRMName e with (nolock) on a.HRCo = e.HRCo and a.HRRef = e.HRRef 
  		join dbo.HRCA c with (nolock) on a.HRCo = c.HRCo and a.HRRef = c.Assigned and a.Asset = c.Asset
   		where a.HRCo = @hrco and a.Asset = @asset and a.DateOut = (select max(DateOut) from dbo.HRTA with (nolock)
   			where HRCo = @hrco and Asset = @asset and DateIn is null)
   
   		--if @assignmsg is null
		if @assignto is null
		begin
			--test
			select @assignto = convert(varchar(20),isnull(c.Assigned,'')) + ' ' + isnull(e.FullName,''), 
			@dateout = a.DateOut, @memo = a.MemoIn, @datein = convert(varchar(11),isnull(a.DateIn,'')), @checkoutstatus = 'N'
			from dbo.HRTA a with (nolock) 
   			join dbo.HRRMName e with (nolock) on a.HRCo = e.HRCo and a.HRRef = e.HRRef
   			join dbo.HRCA c with (nolock) on a.HRCo = c.HRCo and a.HRRef = c.Assigned and a.Asset = c.Asset
   			where a.HRCo = @hrco and a.Asset = @asset and a.DateOut = (select max(DateOut) from dbo.HRTA with (nolock)
   			where HRCo = @hrco and Asset = @asset and DateIn is not null)

			--test
   			select @assignmsg = 'Last Assigned To: ' + convert(varchar(20),isnull(c.Assigned,'')) + ' ' + isnull(e.FullName,'') + 
   			' on ' + convert(varchar(11),isnull(a.DateOut,'')) + '.  Returned ' + convert(varchar(11),isnull(a.DateIn,'')) + 
   			'.  In Memo: ' + isnull(a.MemoIn, '')
   			from dbo.HRTA a with (nolock) 
   			join dbo.HRRMName e with (nolock) on a.HRCo = e.HRCo and a.HRRef = e.HRRef
   			join dbo.HRCA c with (nolock) on a.HRCo = c.HRCo and a.HRRef = c.Assigned and a.Asset = c.Asset
   			where a.HRCo = @hrco and a.Asset = @asset and a.DateOut = (select max(DateOut) from dbo.HRTA with (nolock)
   			where HRCo = @hrco and Asset = @asset and DateIn is not null)
		end
	end


   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCompAssetVal] TO [public]
GO
