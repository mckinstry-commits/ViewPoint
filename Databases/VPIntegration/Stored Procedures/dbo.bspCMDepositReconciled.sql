SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMDepositReconciled    Script Date: 8/28/99 9:32:37 AM ******/
   CREATE proc [dbo].[bspCMDepositReconciled]
   
   /***********************************************************
    * CREATED BY:  JM 12/15/97
    * MODIFIED By: JM 1/21/98 corrected logic per Gary 
    *
    * USAGE:
    * 	Returns whether CM Deposit reconciled = true if 
    *	CMDT.StmtDate exists for a specified CMCo, CMAcct, 
    *	CMTransType (= 2 for Deposit) and the CMRef being checked
    *
    * INPUT PARAMETERS
    *   CMCo
    *   CMAcct
    *   CMRef (ie CM Deposit to be checked)
    * 
    * OUTPUT PARAMETERS
    *	@msg 		If exists, error message, otherwise nothing
    *
    * RETURN VALUE
    *	0		Deposit not reconciled
    *	1		Deposit reconciled
    *	2		Error
    *****************************************************/ 
   
   (@cmco bCompany = 0, @cmacct bCMAcct = null, @cmref bCMRef = null, 
   @msg varchar(60) output)
   
   as
   
   set nocount on
   declare @rcode int, @stmtdate bDate
   	
   if @cmco = 0
   	begin
   	select @msg = 'Missing CM Company#', @rcode = 2
   	goto bspexit
   	end
   
   if @cmacct is null
   	begin
   	select @msg = 'Missing CM Acct!', @rcode = 2
   	goto bspexit
   	end
   
   if @cmref is null
   	begin
   
   	select @msg = 'Missing Deposit No!', @rcode = 2
   	goto bspexit
   	end
   
   select @stmtdate = StmtDate 
   	from CMDT 
   	where CMCo = @cmco and CMAcct = @cmacct 
   		and CMTransType = 2 and CMRef = @cmref --CMTransType = deposit
   
   if @stmtdate is not null
   	begin
   	select @rcode = 1 --deposit reconciled
   	goto bspexit
   	end
   else
   	select @rcode = 0 --deposit not reconciled
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMDepositReconciled] TO [public]
GO
