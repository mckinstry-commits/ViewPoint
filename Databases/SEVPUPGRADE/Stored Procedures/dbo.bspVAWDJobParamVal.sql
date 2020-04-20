SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspVAWDJobParamVal]
   /***********************************************************
    * CREATED BY: JM 9/9/02
    *				TV - 23061 added isnulls
    *				MV - 5/7/07 #124026 use view instead of table 	
    * USAGE:
    * 	Validates Job Param entered in Notifier Jobs form against Query Params in bWDQP.
    *
    * 	Error returned if any of the following occurs:
    * 		No QueryName or Job Param  passed
    *		Job Param not found in bWDQP
    *
    * INPUT PARAMETERS:
    *	QueryName   		QueryName containing referenced parameter
    * 	Param			Parameter to validate
    *
    * OUTPUT PARAMETERS:
    *	@msg      		Error message if error occurs, otherwise
    *				Description of WorkOrder from EMWH
    *
    * RETURN VALUE:
    *	0		success
    *	1		Failure
    *****************************************************/
   
   (@queryname varchar(50) = null,
   @jobparam varchar(50) = null,
   @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   if @queryname is null
   	begin
   	select @msg = 'Missing Query Name!', @rcode = 1
   	goto bspexit
   	end
   if @jobparam is null
   	begin
   	select @msg = 'Missing JobParam!', @rcode = 1
   	goto bspexit
   	end
   
   select top 1 1  from WDQP where QueryName = @queryname and Param = @jobparam
   if @@rowcount = 0
   	begin
   	select @msg = 'Job Param not applicable for this Query!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'') + char(13) + char(10) + '[bspVAWDJobParamVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspVAWDJobParamVal] TO [public]
GO
