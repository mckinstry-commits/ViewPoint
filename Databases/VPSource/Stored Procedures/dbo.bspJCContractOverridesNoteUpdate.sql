SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROCEDURE [dbo].[bspJCContractOverridesNoteUpdate]
   /**********************************************************************
   	Created By: DANF 02/22/2005
       Modified by: 
   
   	Usage: Used to update notes from the contract tab of the JC Overrides Form
   
   	Input:
   		@JCCo - JCCo
   		@Contract - Contract
   		@Notes - Notes
   
   	Output:
   		@rcode
   		@errmsg
   
   
   
   
   
   **********************************************************************/
   (@JCCo bCompany = null, @Contract bContract = null, @Notes varchar(8000), @errmsg varchar(255) = '' output)
   
   as
   
   declare @rcode int, @separator varchar(30)
   
   select @rcode = 0, @separator = char(013) + char(010), @errmsg = '-'
   
   
   
   update dbo.JCCM
   set OverProjNotes=@Notes
   where JCCo=@JCCo and Contract=@Contract
   if @@rowcount<>1
   	begin
   		select @rcode=1, @errmsg = 'An error has occurred updating Contract Overrides Notes for ' + isnull(@Contract,'') + '.'
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCContractOverridesNoteUpdate] TO [public]
GO
