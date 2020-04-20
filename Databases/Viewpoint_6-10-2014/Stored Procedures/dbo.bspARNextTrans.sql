SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspARNextTrans]
   /*************************************
   * Gets next AR invoice number stored in ARCO file (Inappropriately named)
   * Modified By:	GF 01/14/2003 - Improve speed
   *		GF 06/18/2003 - issue #21568 - more speed improvement. Removed transaction
   *						get ARCO.InvLastNum, add 1, update ARCO, then check for 
   *						existance. If exists, loop back and do again.
   *		TJL 03/17/04 - Issue 24064, Do NOT audit (HQMA) ARCO.InvLastNum during normal processes
   *
   * Usage:
   *	Used to get Next Invoice Number Defaults for various AR modules.  
   *	Modules using this routine are:
   *
   *	ARFinChgCalc	(Called from bspARFinanceChgCalc)
   *	ARInvoiceEntry	(Uses AR_Module Event ARGetNextTrans)
   *	ARReleaseRetg	(Uses AR_Module Event ARGetNextTrans)
   *
   * Pass In:
   *	ARCO
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1
   *
   **************************************/
   (@arco bCompany = 0, @lastinvoice varchar(10) output, @errmsg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @arlastinvoice varchar(10), @jbco bCompany
   
   select @rcode = 0, @arlastinvoice = null, @lastinvoice = null
   
   if @arco = 0
   	begin
   	select @errmsg = 'Missing Company number!', @rcode = 1
   	goto bspexit
   	end
   
   /* validate HQ Company number */
   exec @rcode = bspHQCompanyVal @arco, @errmsg output
   if @rcode <> 0 goto bspexit
   
   /* Get ARCo Information */
   select @arlastinvoice = InvLastNum, @jbco=JCCo 
   from ARCO with (nolock)
   where ARCo = @arco
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to get next available AR invoice number!'
   	select @rcode = 1
   	goto bspexit
   	end
   
   /* Can only auto process true Numeric style invoice numbers. */
   if isnumeric(@arlastinvoice) = 1
   	begin
   	/* Adding +1 to @arlastinvoice results in removing leading spaces.  Using the STR() function
   	   creates a 10 char, right justified, string again. */
   	select @lastinvoice = str((convert(bigint,@arlastinvoice) + 1),10)
   
   	/* Once the initial invoice value is determined, check for its existence in various modules.
   	   If it does already exist, Increment it by +1 and do the check again. */
   	arinvloop:
   	if exists(select 1 from bARTH with (nolock) where ARCo=@arco and Invoice=@lastinvoice) or
   		exists(select 1 from bARBH with (nolock) where Co=@arco and Invoice=@lastinvoice) or
   		exists(select 1 from bJBAR with (nolock) where Co=@jbco and Invoice=@lastinvoice) or
   		exists(select 1 from bJBIN with (nolock) where JBCo=@jbco and Invoice=@lastinvoice)
   		begin
   		select @lastinvoice = str((convert(bigint,@lastinvoice) + 1),10)
   		goto arinvloop
   		end
   
     	update bARCO
    	set InvLastNum = @lastinvoice, AuditYN = 'N'
    	where ARCo=@arco
   	if @@rowcount = 0
         	begin
         	select @errmsg = 'Error updating LastInvoice Number in AR Company!'
         	select @rcode = 1
   		goto bspexit
         	end
   	
   	update bARCO
   	set AuditYN = 'Y'
   	where ARCo = @arco
   	end
   else
   	begin
   	select @errmsg = 'AR Company LastInvoice Number is not numeric and may not be Automatically incremented!'
   	select @rcode = 1
   	goto bspexit
   	end	
   
   bspexit:
   if @rcode<>0 
   	begin
   	select @lastinvoice = null
   	select @errmsg=@errmsg		--+ char(13) + char(10) + '[bspARNextTrans]'
   	end
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARNextTrans] TO [public]
GO
