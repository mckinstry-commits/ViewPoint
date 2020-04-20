SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROCEDURE [dbo].[bspJCRevProjContractItemNote]
   /**********************************************************************
   	Created By: DANF 02/28/2005
       Modified by: 
   
   	Usage: Used to update notes from the Revenue Projections Form
   
   	Input:
   		@JCCo - JCCo
   		@Contract - Contract
   		@Item - ContractItem
   		@Notes - Notes
   
   	Output:
   		@rcode
   		@errmsg
   
   
   
   
   
   **********************************************************************/
   (@JCCo bCompany = null, @Contract bContract = null, @Item bContractItem, @Notes varchar(8000), @errmsg varchar(255) = '' output)
   
   as
   
   declare @rcode int, @separator varchar(30)
   
   select @rcode = 0, @separator = char(013) + char(010), @errmsg = '-'
   
   
   
   update dbo.bJCCI
   set ProjNotes=@Notes
   where JCCo=@JCCo and Contract=@Contract and Item = @Item
   if @@rowcount<>1
   	begin
   		select @rcode=1, @errmsg = 'An error has occurred updating Contract Revenue Projection Notes for ' + isnull(@Contract,'') + '.'
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCRevProjContractItemNote] TO [public]
GO
