SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     PROCEDURE [dbo].[bspJCInitOverrides]
   /*******************************************************************************
   * Created By:	DANF 01/18/2005
   * Modified By:	GP	10/6/2008 - Issue 129423, changed if not exist statements to use tables
   *									instead of views.
   *
   *	Usage:
   *		This is used to initialize JC revenue and cost overrides.
   *
   *	Input:
   *	@JCCo  JCCompany
   *	@Mth    Month
   *	@ShowSoftClose bYN
   *
   *	Output:
   *	@errmsg
   *	@rcode
   *
   **********************************************************************************/
   (@JCCo bCompany = null, @Mth bMonth = null, @ShowSoftClose bYN = null, @errmsg varchar(255) = '' output)
   AS
   
   declare @rcode int, @separator varchar(30), @PrevMonth bYN
   
   select @rcode = 0, @separator = char(013) + char(010), @errmsg = 'An error has occurred.'
   
   --Start Error Detection/Validation
   if @JCCo is null
   	begin
   	select @rcode = 1,@errmsg = @errmsg + @separator + 'JCCompany is null!'
   	end
   
   if not exists(select top 1 1 from JCCM where JCCo = @JCCo)
   	begin
   	select @rcode = 1,@errmsg = @errmsg + @separator + 'JC Company not set up in JC Company Master!'
   	end
   
   if isnull(@Mth,'') = ''
   	begin
   	select @rcode = 1,@errmsg = @errmsg + @separator + 'Invalid Month!'
   	end
   
   --End error detection/Validation
   if @rcode <> 0 goto bspexit
   
   If @ShowSoftClose = 'Y' 
   	begin
   	-- Initialize JCOP for Cost Overrides
   	insert dbo.JCOP
   	(JCCo, Job, Month, ProjCost, OtherAmount)
   	select jm.JCCo, jm.Job, @Mth, 0, 0
   	from dbo.JCJM jm with (nolock)
   	where jm.JCCo = @JCCo and jm.JobStatus in (1,2) and
   	not exists ( select 1 from dbo.bJCOP op with (nolock)
   				where op.JCCo = jm.JCCo and op.Job=jm.Job and op.Month=@Mth)
   
   
   	-- Initialize JCOR for Revenue Overrides
   	insert dbo.JCOR
   	(JCCo, Contract, Month, RevCost, OtherAmount)
   	select cm.JCCo, cm.Contract, @Mth, 0, 0
   	from dbo.JCCM cm with (nolock)
       where cm.JCCo = @JCCo and cm.StartMonth <= @Mth and cm.ContractStatus in (1,2) and
   	not exists ( select 1 from dbo.bJCOR op with (nolock)
   				where op.JCCo = cm.JCCo and op.Contract=cm.Contract and op.Month=@Mth)
   
   
   	end
   else
   	begin
   
   	-- Initialize JCOP for Cost Overrides
   	insert dbo.JCOP
   	(JCCo, Job, Month, ProjCost, OtherAmount)
   	select jm.JCCo, jm.Job, @Mth, 0, 0
   	from JCJM jm with (nolock)
   	where jm.JCCo = @JCCo and jm.JobStatus = 1 and
   	not exists ( select 1 from dbo.bJCOP op with (nolock)
   				where op.JCCo = jm.JCCo and op.Job=jm.Job and op.Month=@Mth)
   
   	-- Initialize JCOR for Revenue Overrides
   	insert dbo.JCOR
   	(JCCo, Contract, Month, RevCost, OtherAmount)
   	select cm.JCCo, cm.Contract, @Mth, 0, 0
   	from JCCM cm with (nolock)
       where cm.JCCo = @JCCo and cm.StartMonth <= @Mth and cm.ContractStatus = 1 and
   	not exists ( select 1 from dbo.bJCOR op with (nolock)
   				where op.JCCo = cm.JCCo and op.Contract=cm.Contract and op.Month=@Mth)
   
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCInitOverrides] TO [public]
GO
