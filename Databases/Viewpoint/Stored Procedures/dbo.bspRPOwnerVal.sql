SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRPOwnerVal    Script Date: 8/28/99 9:35:43 AM ******/
   /****** Object:  Stored Procedure dbo.bspRPOwnerVal    Script Date: 3/28/99 12:00:39 AM ******/
   CREATE    proc [dbo].[bspRPOwnerVal]
   /* validates Report Owner
    * pass in ReportOwner
    * returns ReportOwner
   *  Modified DANF 09/14/2004 - Issue 19246 added new login
	* Modified TERRYL 07/16/06 changed procedure to use vDDUP for 6.x 
   */
  	(@ReportOwner bVPUserName = null, @msg varchar(60) output)
  as
  	set nocount on
  	declare @rcode int,@cnt int
  	select @rcode = 0
  
  If @ReportOwner='bidtek' and SUSER_SNAME()='bidtek'
  begin
  	select @msg=@ReportOwner
  	goto vspexit
  end
  If @ReportOwner='bidtek' and SUSER_SNAME()<>'bidtek'
  begin
  	select @msg='Only Viewpoint can add/change this report',@rcode=1
  	goto vspexit
  end
  If @ReportOwner='viewpointcs' and SUSER_SNAME()='viewpointcs'
  begin
  	select @msg=@ReportOwner
  	goto vspexit
  end
  If @ReportOwner='viewpointcs' and SUSER_SNAME()<>'viewpointcs'
  begin
  	select @msg='Only Viewpoint can add/change this report',@rcode=1
  	goto vspexit
  end
  If @ReportOwner<>SUSER_SNAME() and user_name()<>'dbo'
  begin
  	select @msg='The owner must be the same as your login name',@rcode=1
  	goto vspexit
  end
  
  if (select count(*) from dbo.vDDUP with (nolock) where VPUserName=@ReportOwner) <> 1
  begin
  	select @msg='Owner is not a valid login name',@rcode=1
  	goto vspexit
  end
  
  vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRPOwnerVal] TO [public]
GO
