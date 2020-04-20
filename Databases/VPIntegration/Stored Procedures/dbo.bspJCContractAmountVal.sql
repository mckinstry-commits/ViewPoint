SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[bspJCContractAmountVal] 
   /*****************************************************************
   	Created: RM 02/21/01
   		 TV 05/25/01-HAD to reset error message.
   		TV - 23061 added isnulls		
   	
   	Usage:  Used to validate that contract amounts are 0 when 
   		ACO is set to internal.
   
   	Pass in: 
   		@co - JCCo
   		@Job - Job
   		@aco - aco#
   		@intext - Internal/External flag
   
   	output:
   
   	returns:
   		@rcode
   
   *****************************************************************/
   (@co bCompany,@Job bJob,@aco bACO,@intext char(1) = null,@ContractAmt bDollar = null, @errmsg varchar(255) output)
   AS
   
   declare @rcode int,@separator varchar(30)
   select @rcode = 0,@separator = char(013) + char(010)--, @errmsg = 'An error has occurred.'
   
   
   
   if @intext is null or @intext = '' --Then im validating a Contract Amount Field, and if the @intext = 'I' then it is invalid
   begin
   if @ContractAmt <> 0
   begin
   	select @intext = IntExt from JCOH where JCCo = @co and Job = @Job and ACO = @aco
   	if @intext = 'I'
   	begin	
   		select @rcode = 1,@errmsg = 'Amount must be 0 while change order is internal.'
   		goto bsperror
   	end
   end
   
   end
   
   
   if @intext = 'I' --Then im validating the Int/Ext flag field, and if existing contract amount <> 0 then it is invalid
   begin
   		if exists (select ContractAmt from JCOI where JCCo = @co and Job = @Job and ACO = @aco and ContractAmt <> 0)
   
   		begin
   			select @rcode = 1,@errmsg = @errmsg + @separator + 'May not change to an internal change order while contract amount is not 0.'
   		end
   end
   
   if @rcode<>0
   goto bsperror
   
   return @rcode
   
   bsperror:
   select @errmsg = @errmsg + @separator + 'bspJCContractAmountVal'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCContractAmountVal] TO [public]
GO
