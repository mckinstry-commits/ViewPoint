SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[bspVAWDQueryVal]
   /***********************************************************
   * CREATED BY: TV 11/05/01
   *	Modified: JM 9/9/02 - Updates JobParams table bWDJP for a Job with params 
   *	from QueryParams table for the Job's Query.
   *				TV - 23061 added isnulls
   *				MV - 5/7/07 #124026 use view instead of table
   *				HH - 10/16/12 TK-18458 changed error message to add @QueryName value
   * USAGE:
   *	Validates query used by frmVAWDJobs vs bWDQY..
   *
   *	Error returned if any of the following occurs:
   * 		No @querynamename  passed
   *
   * INPUT PARAMETERS:
   *	QueryName		Query to verify vs bWDQY
   *
   * OUTPUT PARAMETERS:
   *	@msg      		Error message if error occurs, otherwise
   *
   * RETURN VALUE:
   *	0		success
   *	1		Failure
   *****************************************************/
   (@jobname varchar(150), 
   @queryname varchar(100),
   @errmsg char(255)output)
   
   as 
   
   declare @rcode int, @numrows int
   
   select @rcode = 0
   
   
   set nocount on  
   
   if @queryname is null
   	begin
   	select @errmsg = 'Missing QueryName!', @rcode = 1
   	goto bspexit
   	end 
   
   /* Validate QueryName vs bWDQY */
   select * from WDQY where QueryName = @queryname
   select @numrows =  @@rowcount 
   if @numrows = 0
   	begin
   	select @errmsg = @queryname + ' is not a valid WF Notifier Query.', @rcode = 1
   	goto bspexit
   	end
   
   /* Clear and repopulate bWDJP for this Job */
   /*delete bWDJP where JobName = @jobname
   insert into bWDJP (JobName, Description, Param) select @jobname, Description, Param from bWDQP where QueryName = @queryname*/
   
   bspexit:
   	if @rcode<>0 select @errmsg=@errmsg + char(13) + char(10) + '[bspVAWDQueryVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspVAWDQueryVal] TO [public]
GO
