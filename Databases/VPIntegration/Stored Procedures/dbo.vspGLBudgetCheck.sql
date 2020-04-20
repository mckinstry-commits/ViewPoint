SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspGLBudgetCheck]
/***********************************************************
* Created: GG 05/08/07
* Modified:
*
* Used by GL Budget Init to see if entries exist in bGLBR for a given GLCo/FYEMO/BudgetCode/GLAcctMask.
* Existing entries indicate a previously budgeted amounts.
*
* Input params:
*	@glco			GL Company
*	@fyemo			Fical Year ending month
*	@budgetcode		Budget Code
*	@glacctmask		GL Account mask used to filter accounts
*
* Output params:
*	none
*
* Returns:
*	# of records
**************************************************************************/
	(@glco bCompany = null, @fyemo bMonth = null, @budgetcode bBudgetCode = null,
		@glacctmask bGLAcct = null)

as
set nocount on

-- replace placeholder character in GL Account Mask
select @glacctmask = replace(@glacctmask,'?','_')

-- return # of records in bGLBR for a given GLCo, FYEMO, Budget Code, GL Account Mask
select count(*) from dbo.bGLBR (nolock)
where GLCo = @glco and FYEMO = @fyemo and BudgetCode = @budgetcode and GLAcct like @glacctmask
  
 
vspexit:
   	return

GO
GRANT EXECUTE ON  [dbo].[vspGLBudgetCheck] TO [public]
GO
