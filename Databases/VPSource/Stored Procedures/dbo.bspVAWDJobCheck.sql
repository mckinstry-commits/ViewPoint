SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspVAWDJobCheck]
   /*************************************************************
   *
   *    Created by TV 1/20/03
   *			TV - 23061 added isnulls
   *			MV - 5/7/07 #28321 use View instead of table	
   *			HH - 11/13/12 TK-18458 added QueryType for WF Notifier Queries
   *    
   *    Purpose: To see if Jobs exist for a query. If so notify the 
   *             user that they may have to alter the job
   *
   *    input: @co
   *           @queryname 
   *  
   *    output:@msg    
   *
   *
   **************************************************************/
   (@co bCompany, @queryname varchar(50),@errmsg Varchar(250) output)
   as
   
   set nocount on 
   
   declare @rcode int, @jobcount int
   
   Select @rcode = 0
   
   --Check WDJB for existing jobs
      Select @jobcount = count(JobName) from WDJob where QueryName = @queryname and QueryType = 0
   if @jobcount > 0 
       begin
       select @errmsg = 'changing query will alter parameters. ' + isnull(convert(varchar(50),@jobcount),'') + ' jobs exist that may need to be altered.', @rcode = 1
       end
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspVAWDJobCheck] TO [public]
GO
