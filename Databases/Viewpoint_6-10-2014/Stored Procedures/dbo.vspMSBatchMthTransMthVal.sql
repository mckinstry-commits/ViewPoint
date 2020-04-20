SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROC [dbo].[vspMSBatchMthTransMthVal]
   /***********************************************************
    * CREATED BY: TRL 10/18/06
    *
    *
    * USAGE:
    * 	validates Batch Mth against MSTransMth on MS HaulPayments, MatlPayments
    *
    * INPUT PARAMETERS
    *   BatchMonth
    *   TransMonth
    * OUTPUT PARAMETERS
    *   @msg      Description or error message
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   
   (@batchmonth smalldatetime = null, @transmonth smalldatetime=null, @msg varchar(60) output)
   as
   
   set nocount on
   declare @rcode int, @dueopt tinyint
   select @rcode = 0
   
   if @batchmonth is null
   	begin
   		select @msg = 'Missing BatchMonth!', @rcode = 1
   		goto vspexit
   	end
   
   if @transmonth is null
   	begin
	 	select @msg = 'Missing MS Transaction Month!', @rcode = 1
   		goto vspexit
   	end
   
	If datediff ("mm",@transmonth,@batchmonth) < 0 
	begin
	select @msg = 'Transaction month must be less than or equal to batch month!', @rcode = 1
   		goto vspexit
	end
   
   vspexit:
	If @rcode <> 0 
	select @msg = @msg + char(13)+Char(10) + ' [vspMSBatchMthTransMthVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSBatchMthTransMthVal] TO [public]
GO
