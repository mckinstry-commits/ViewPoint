SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMAcctValwithInfo    Script Date: 1/16/2003 2:16:47 PM ******/
   
   /****** Object:  Stored Procedure dbo.bspCMAcctValwithInfo    Script Date: 11/12/2002 11:29:02 AM ******/
   
   CREATE   procedure [dbo].[bspCMAcctValwithInfo]
   /************************************************************************
   * CREATED:	MH 11/21/01    
   * MODIFIED: MH 1/16/03 - added changebegbal output param    
   *
   * Purpose of Stored Procedure
   *
   *	Get extended information after a CMAccount has been validated.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@cmco bCompany = 0, @cmacct bCMAcct = null, @bankacct varchar(30) output,
   	@chgbegbal bYN output, @msg varchar(60) output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	exec @rcode = bspCMAcctVal @cmco, @cmacct, @msg output
   
   	if @rcode = 0
   		begin
   			select @bankacct = BankAcct from CMAC where CMCo = @cmco
   				and CMAcct = @cmacct
   		
   		end
   
   	select @chgbegbal = ChangeBegBal from CMCO where CMCo = @cmco 
   
   			
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMAcctValwithInfo] TO [public]
GO
