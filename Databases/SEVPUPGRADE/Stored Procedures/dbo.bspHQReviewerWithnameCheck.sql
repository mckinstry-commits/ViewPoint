SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQReviewerWithnameCheck    Script Date: 8/28/99 9:34:54 AM ******/
   CREATE    procedure [dbo].[bspHQReviewerWithnameCheck]
   /*************************************
   * Created: JM 5/8/98
   * Modified:  DANF 09/14/2004 - Issue 19246 added new login
   *	     DANF 12/21/04 - Issue #26577: Changed reference on DDUP
   *			MV 10/18/06 - #27747 - changed reference from name and DDUP 
   *				to VPUserName and vD
   *			MV 10/15/08 - #127316 - changed err msg to include login name and reviewer
   *
   * Validates HQ Reviewer and verifies that login is assigned
   * to that Reviewer in HQRP (on HQRV form)
   *
   * Pass:
   *	HQ Reviewer to be validated
   *	Login name from Global Object
   *
   * Success returns:
   *	0 and Description from bHQRV
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@reviewer varchar(10) = null, @loginname varchar(30) = null, @msg varchar(100) output)
   as
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   
   if @reviewer is null
   	begin
   	select @msg = 'Missing Reviewer', @rcode = 1
   	goto bspexit
   	end
   
   if @loginname is null
   	begin
   	select @msg = 'Missing Login Name!', @rcode = 1
   	goto bspexit
   	end
   
   /* first, verify Reviewer is valid in HQRV */
   select @msg = Name from dbo.bHQRV where Reviewer= @reviewer
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Reviewer code!', @rcode = 1
   	end
   
   /* now see if the login name in DDUP matches any name for that
   *  Reviewer in HQRP */
   if @loginname <> 'bidtek' and @loginname <> 'viewpointcs'
   	begin
   	select * from dbo.bHQRP
   		where Reviewer = @reviewer and
   		VPUserName in (select VPUserName from dbo.vDDUP where VPUserName = @loginname)
   	if @@rowcount = 0
   		begin
   		select @msg = 'Login: ' + @loginname + ' not registered for Reviewer: ' + @reviewer + ' in HQ Reviewer!', @rcode = 1
   		end
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQReviewerWithnameCheck] TO [public]
GO
