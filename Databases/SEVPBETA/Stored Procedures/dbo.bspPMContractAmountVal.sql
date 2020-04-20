SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPMContractAmountVal] 
   /*****************************************************************
   	Created: RM 02/21/01
   		 TV 05/25/01 -Reedit Error message.				
   		
   	
   	Usage:  Used to validate that contract amounts are 0 when 
   		ACO is set to internal.
   
   	Pass in: 
   		@co - PMCo
   		@project - Project
   		@aco - aco#
   		@intext - Internal/External flag
   
   	output:
   
   	returns:
   		@rcode
   
   *****************************************************************/
   (@co bCompany,@project bProject,@aco bACO,@intext char(1) = null,@ApprovedAmt bDollar = null, @errmsg varchar(255) output)
   AS
   
   declare @rcode int,@separator varchar(30)
   select @rcode = 0,@separator = char(013) + char(010)--, @errmsg = 'An error has occurred.'
   
   
   
   if @intext is null or @intext = ''  --I am validating the approved Amount field
   begin
   if @ApprovedAmt <> 0
   begin
   select @intext = IntExt from PMOH with (nolock) where PMCo = @co and Project = @project and ACO = @aco
   	if @intext = 'I'
   	begin
   		select @rcode = 1,@errmsg =  'Amount must be 0 for Internal Change Orders.'
   		goto bsperror
   	end		
   end
   end
   
   if @intext = 'I' --I am validating the Int/Ext flag
   begin
   	if exists(select ApprovedAmt from PMOI with (nolock) where PMCo = @co and Project = @project and ACO = @aco and ApprovedAmt <> 0)
   		begin
   			select @rcode = 1,@errmsg = isnull(@errmsg,'') + @separator + 'Cannot change to internal change order while approved amount is not 0.'
   		end
   end
   
   if @rcode <> 0 goto bsperror
   
   return @rcode
   
   
   
   bsperror:
   	select @errmsg = isnull(@errmsg,'') + @separator + 'bspPMContractAmountVal'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMContractAmountVal] TO [public]
GO
