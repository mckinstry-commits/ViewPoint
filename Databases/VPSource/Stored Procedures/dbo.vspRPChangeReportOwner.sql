SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRPChangeReportOwner    Script Date: 8/28/99 9:35:48 AM ******/
CREATE             proc [dbo].[vspRPChangeReportOwner]
   /**************************************************************
   * Object:  Stored Procedure dbo.bspRPChangeReportOwner
   * CREATED:  TERRYL 03/010/06
   * MODIFIED:  
   *
   * Purpose of Stored Procedure
   *  Changes the report Owner from the current owner to a new owner.
   *
   *  Parameters
   *  Report Title
   *  Current Report Owner
   *  New Report Owner
   *  Update All Reports
   *  message output
   *
   **************************************************************/
   
   (@ReportID int =0, @CurrentOwner varchar(128)=null, @NewOwner varchar(128)=null, 
   @User varchar(128)=null, @UpdateAll bYN = 'N', @msg varchar(255) output)
   
    as
   set nocount on
   
   
   declare @rcode int, @UpdatedRecords int
   
   select @rcode = 0
   
   
   if IsNull(@ReportID,0)=0
   	begin
   		select @msg = 'Missing Report ReportID!', @rcode = 1
   		goto vspexit
   	end
   
 if IsNull(@ReportID,0) <= 9999
   	begin
   		select @msg = 'Viewpoint Standard Reports less than 10,000 cannot be changed!', @rcode = 1
   		goto vspexit
   	end

   if @CurrentOwner is null
   	begin
   		select @msg = 'Missing Current Owner Name!', @rcode = 1
   		goto vspexit
   	end
   
   if @NewOwner is null
   	begin
   		select @msg = 'Missing New Owner Name!', @rcode = 1
   		goto vspexit
   	end
   
   if (@CurrentOwner='bidtek' or @NewOwner='bidtek') and @User<>'bidtek'
   	begin
   		select @msg = 'You are not allowed to change the owner of a report from or/to bidtek!', @rcode = 1
   		goto vspexit
   	end
   
   if (@CurrentOwner='viewpointcs' or @NewOwner='viewpointcs') and @User<>'viewpointcs'
   	begin
   		select @msg = 'You are not allowed to change the owner of a report from or/to viewpointcs!', @rcode = 1
		goto vspexit
   	end
   	
   if @UpdateAll is null
   	begin
   		select @msg = 'Missing Update Flag!', @rcode = 1
   		goto vspexit
   	end
   
   if not exists (select top 1 1 from dbo.DDUP with (nolock) where VPUserName=@NewOwner) 
   	begin
   		select @msg = 'DDUP user name not on file!', @rcode = 1
   		goto vspexit
   	end
   
If isnull(@UpdateAll,'') = 'Y' 
   	begin
   		-- Update All reports from the current owner to the new owner
   		Update dbo.RPRTc
   		Set ReportOwner = @NewOwner
   		where ReportOwner = @CurrentOwner and ReportID >=10000
		set @UpdatedRecords=isnull(@@rowcount,0)
		goto updatedrecs
   	End
Else   
   	begin
   		-- Update the current report from the current owner to the new owner
   		Update dbo.RPRTc
   		Set ReportOwner = @NewOwner
   		where ReportID = @ReportID and ReportID >=10000
        set @UpdatedRecords=isnull(@@rowcount,0)
		goto updatedrecs
   	End
  
updatedrecs:
   	if isnull(@UpdatedRecords,0) = 0
		Begin
   			select @msg = 'No Reports were updated to the new owner.'
			goto vspexit
		End

    if isnull(@UpdatedRecords,0) = 1
		Begin
   			select @msg = 'Report ID:  ' + Convert(varchar,isnull(@ReportID,0))  + ' has been changed from the Owner ' + @CurrentOwner + ' to the Owner ' + @NewOwner
			goto vspexit
		End
    
	if isnull(@UpdatedRecords,0) > 1
		Begin
   			--select @msg = convert(varchar(10),@UpdatedRecords) + ' Report Titles have been changed from the Owner ' + @CurrentOwner + ' to the Owner ' + @NewOwner
			select @msg = 'All Report IDs previously assigned to Owner ' + @CurrentOwner + ' have been changed to Owner ' + @NewOwner + '.' --+ Char(10)
		--	'Where the "Current Owner" equals ' + @CurrentOwner + ' and the "New Owner" equals ' + @NewOwner
			goto vspexit
		End
 
   vspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRPChangeReportOwner] TO [public]
GO
