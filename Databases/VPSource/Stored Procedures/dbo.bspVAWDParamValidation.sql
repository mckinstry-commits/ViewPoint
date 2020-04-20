SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspVAWDParamValidation] 
   /********************************************
   *    Created by TV 10/25/02
   *				TV - 23061 added isnulls
   *				MV - 5/7/07 #28321 use View instead of table
   *
   *    Purpose: To make sure that if a procedure needs to have a value
   *             assigned to a parameter. That it does.
   *
   *    inputs: @queryname 
   *            @param
   *
   *    output: @errmsg
   ********************************************/
   (@co bCompany, @queryname varchar(50), @param varchar(50), @errmsg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   if exists (select Param from WDQP where QueryName = @queryname) and isnull(@param, '') = ''
       begin
       select @errmsg = 'A ''''Job Query Parameter Values'''' input is required for this Job.', @rcode = 1
       goto bspExit
       end
      
   bspExit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspVAWDParamValidation] TO [public]
GO
