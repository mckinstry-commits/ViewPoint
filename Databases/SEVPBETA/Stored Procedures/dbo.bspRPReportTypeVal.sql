SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRPReportTypeVal    Script Date: 8/28/99 9:35:44 AM ******/
   /****** Object:  Stored Procedure dbo.bspRPReportTypeVal    Script Date: 3/28/99 12:00:39 AM ******/
   CREATE  proc [dbo].[bspRPReportTypeVal]
   /* validates Report type
    * pass in ReportType
    * returns Description
   */
   	(@ReportType varchar(10) = null, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int,@cnt int
   	select @rcode = 0
   	
   select @msg=Description
   	from  dbo.RPTYShared where ReportType=@ReportType
   if @@rowcount<>1
   begin
   	select @msg='Invalid Report Type', @rcode=1
   	goto bspexit
   end
   	
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRPReportTypeVal] TO [public]
GO
