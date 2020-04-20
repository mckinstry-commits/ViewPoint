SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBGetLastInvoice    Script Date: 8/28/99 9:36:45 AM ******/
   CREATE proc [dbo].[bspJBGetLastInvoice]
   
   /*******************************************************************************************
   * CREATED BY: kb 2/9/00
   * MODIFIED By : kb 11/15/1 - issue #14739
   *		kb 12/5/1 - issue #15328
   *		TJL 03/15/04 - Issue #24031, Rewrite for common use. Correct Old/New LastInvoice in HQMA, Use JCCO.ARCo, 
   *
   *	
   * USAGE: This will establish Invoice Number defaults based upon JBCO setup.  The invoice
   *	Numbers pull from either JBCO.LastInvoice or ARCO.InvLastNum, are incremented and used
   *	as defaults in the Bill. Also JBCO and ARCO get updated accordingly. 
   *
   *	This procedure is called by:
   *		bspJBTandMIint				(Replaces bspJBGetInvNumForAutoInit)
   *		bspJBProgressBillInit		(Replaces integrated code doing same thing)
   *		Form JBTMBills				(Returns default invoice #.  Form no longer calulates)
   *		Form JBProgBillEdit			(Returns default invoice #.  Form no longer calulates)
   *
   *  INPUT PARAMETERS
   *	@co	= Company
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   ***********************************************************************************************/
   (@co bCompany, @lastinvoice varchar(10) output, @errmsg varchar(255) output)
   as
   
   set nocount on
   
   /*generic declares */
   declare @rcode int, @invopt char(1), @autoseqyn bYN, @arco bCompany, @jblastinvoice varchar(10),
   	@arlastinvoice varchar(10)
   
   select @rcode=0, @lastinvoice = null, @jblastinvoice = null, @arlastinvoice = null
   
   /* Get JBCO, JCCO information */
   select @invopt = b.InvoiceOpt, @jblastinvoice = b.LastInvoice, @autoseqyn = b.AutoSeqInvYN,
   	@arco = c.ARCo
   from bJBCO b with (nolock)
   join bJCCO c on c.JCCo = b.JBCo
   where b.JBCo = @co
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to get next available JB invoice number!', @rcode = 1
   	goto bspexit
   	end
   
   if @autoseqyn = 'Y'
   	begin	/* Begin Auto Invoice Sequencing */
   	if @invopt = 'J' 
   		begin
   		if isnumeric(@jblastinvoice) = 1
   			begin
   			/* Adding +1 to @jblastinvoice results in removing leading spaces.  Using the STR() function
   			   creates a 10 char string again. */
   			select @lastinvoice = str((convert(bigint,@jblastinvoice) + 1),10)
   
   			/* Once the initial invoice value is determined, check for its existence in various modules.
   			   If it does already exist, Increment it by +1 and do the check again. */
   			jbinvloop:
   			if exists(select 1 from bARTH with (nolock) where ARCo=@arco and Invoice=@lastinvoice) or
   				exists(select 1 from bARBH with (nolock) where Co=@arco and Invoice=@lastinvoice) or
   				exists(select 1 from bJBAR with (nolock) where Co=@co and Invoice=@lastinvoice) or
   				exists(select 1 from bJBIN with (nolock) where JBCo=@co and Invoice=@lastinvoice)
   				begin
   				select @lastinvoice = str((convert(bigint,@lastinvoice) + 1),10)
   				goto jbinvloop
   				end
   
   		    update bJBCO
   		 	set LastInvoice = @lastinvoice, AuditYN = 'N'	
   		  	where JBCo=@co
   	    	if @@rowcount = 0
   		      	begin
   		      	select @errmsg = 'Error updating LastInvoice number in JB Company!'
   		      	select @rcode = 1
   				goto bspexit
   		      	end
   		
   			update bJBCO 
   			set AuditYN = 'Y'
   		  	where JBCo=@co
   			end
   		else
   			begin
   			select @errmsg = 'JB Company LastInvoice number is not numeric and may not be automatically incremented!'
   			select @rcode = 1
   			goto bspexit
   			end
   	    end
   
   	if @invopt = 'A'
   	    begin
   		/* Get ARCo Information */
   	    select @arlastinvoice = InvLastNum 
   		from ARCO with (nolock)
   		where ARCo = @arco
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Unable to get next available AR invoice number!', @rcode = 1
   			goto bspexit
   			end
   
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
   				exists(select 1 from bJBAR with (nolock) where Co=@co and Invoice=@lastinvoice) or
   				exists(select 1 from bJBIN with (nolock) where JBCo=@co and Invoice=@lastinvoice)
   				begin
   				select @lastinvoice = str((convert(bigint,@lastinvoice) + 1),10)
   				goto arinvloop
   				end
   		
   		  	update bARCO
   		 	set InvLastNum = @lastinvoice, AuditYN = 'N'
   		 	where ARCo=@arco
   	    	if @@rowcount = 0
   		      	begin
   		      	select @errmsg = 'Error updating LastInvoice number in AR Company!'
   		      	select @rcode = 1
   				goto bspexit
   		      	end
   			
   			update bARCO
   			set AuditYN = 'Y'
   			where ARCo = @arco
   			end
   		else
   			begin
   			select @errmsg = 'AR Company LastInvoice number is not numeric and may not be automatically incremented!'
   			select @rcode = 1
   			goto bspexit
   			end		
   		end
   	end		/* End Auto Invoice Sequencing */
   
   bspexit:
   if @rcode<>0 
   	begin
   	select @lastinvoice = null
   	select @errmsg=@errmsg		--+ char(13) + char(10) + '[bspJBGetLastInvoice]'
   	end
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBGetLastInvoice] TO [public]
GO
