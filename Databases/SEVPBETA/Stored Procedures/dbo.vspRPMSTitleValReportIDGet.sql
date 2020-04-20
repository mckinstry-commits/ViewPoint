SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRPTitleVal    Script Date: 8/28/99 9:35:44 AM ******/
   /****** Object:  Stored Procedure dbo.bspRPTitleVal    Script Date: 3/28/99 12:00:39 AM ******/
CREATE PROCEDURE [dbo].[vspRPMSTitleValReportIDGet] 
   /* Created by TerryLis 12/07/2006 - Added isnull check and with (nolock).
   * Used on MSInvPrint and MS Company Parameters
   * Select Report Id for InvPrinting
	*Selects Report Title for MS Invoice format in MS Company Parameters*/
   (@title varchar(40)= null, @reportid int  output, @msg varchar(60) output)
   AS
   /* validates Report Title exits in RPRT */
   /* returns ReportID*/
   /* pass ReportTitle */
   /* returns error message if error */
   set nocount on
   declare @rcode int
   select @rcode=0, @reportid = 0
         
   if @title is null
      	begin
		select @msg='Missing title!',@rcode=1
   		goto vspexit
   	end

   if exists(select top 1 1 from dbo.RPRTShared with (nolock) where Title=@title)
		Begin
			Select @reportid = ReportID From dbo.RPRTShared with(nolock) Where Title = @title
			If @@rowcount >=2 
			Begin
   				select @msg=isnull(@title,'') + ' has more than one Report ID.',@rcode=1
   				goto vspexit
			End
			if @reportid = 0
			Begin
   				select @msg=isnull(@title,'') + 'has an invalid Report ID.',@rcode=1
   				goto vspexit
			End
	   End
   else
	   	begin
   			select @msg=isnull(@title,'') + ' invalid report title.',@rcode=1
   		end
   vspexit:

   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRPMSTitleValReportIDGet] TO [public]
GO
