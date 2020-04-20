SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfCMDepositReconciledYN]
(@cmco bCompany = 0, @cmacct bCMAcct = null, @cmref bCMRef = null)
returns bYN
/***********************************************************
* CREATED BY	: TJL 05/17/07
* MODIFIED BY	
*
* USAGE:
* 	Returns whether CM Deposit reconciled = true if 
*	CMDT.StmtDate exists for a specified CMCo, CMAcct, 
*	CMTransType (= 2 for Deposit) and the CMRef being checked
*
* INPUT PARAMETERS:
*   CMCo
*   CMAcct
*   CMRef (ie CM Deposit to be checked)
*
* OUTPUT PARAMETERS:
*	Y - When reconciled
*	N - When not reconciled
*
*****************************************************/
as
begin

declare @reconciledyn bYN, @stmtdate bDate

/* deposit not reconciled else otherwise determined */
select @reconciledyn = 'N'

select @stmtdate = StmtDate 
from bCMDT with (nolock)
where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref
	and CMTransType = 2		--CMTransType = deposit
   
if @stmtdate is not null
	begin
	select @reconciledyn = 'Y'	--deposit reconciled
	end
  			
return @reconciledyn
end

GO
GRANT EXECUTE ON  [dbo].[vfCMDepositReconciledYN] TO [public]
GO
