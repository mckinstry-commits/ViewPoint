SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMProcessMiscDist    Script Date: 8/28/99 9:32:34 AM ******/
   CREATE proc [dbo].[bspJBTandMProcessMiscDist]
   /***********************************************************
   * CREATED BY	: kb 11/22/00
   * MODIFIED BY	:	TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
   *		TJL 10/06/03 - Issue #17897, Rewrote to be consistent with AR and Vision.
   *		TJL 10/07/03 - Issue #17897, Corrected MiscDistCode references to datatype char(10) (Consistent w/AR and MS)
   *		TJL 04/14/04 - Issue #24317, Corrected FreeForm, Non-Contract MiscDistCode failure
   *
   * USED IN:
   *
   * USAGE:
   *
   * INPUT PARAMETERS
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   
   (@co bCompany,  @template varchar(10), @billmth bMonth, @billnum int,
   @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @miscseq int, @line int, @basis bDollar, @miscdistcode char(10),
   	@custgroup bGroup, @distdate bDate, @contract bContract, @customer bCustomer,
   	@JCCMmiscdistcode char(10), @ARCMmiscdistcode char(10), @tsgroup int, 
   	@tsdescription bDesc, @mdcdescription bDesc, @markupopt char(1), @markuprate bUnitCost,
   	@openJBTScursor int, @firstmdcflag int
   
   --@miscdistrate bRate,
   
   select @rcode = 0, @openJBTScursor = 0, @firstmdcflag = 0
   
   /* If Freeform or initialized, Contract Bills, get necessary values here. */
   select @basis = sum(t.AmtBilled), @distdate = n.InvDate, @contract = n.Contract, @customer = n.Customer,
   	@custgroup = n.CustGroup, @JCCMmiscdistcode = c.MiscDistCode, @ARCMmiscdistcode = a.MiscDistCode
   from bJBIT t with (nolock)
   join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   join bJCCM c with (nolock) on c.JCCo = n.JBCo and c.Contract = n.Contract
   join bARCM a with (nolock) on a.CustGroup = n.CustGroup and a.Customer = n.Customer
   where t.JBCo = @co and t.BillMonth = @billmth and t.BillNumber = @billnum
   group by n.InvDate, n.Contract, n.Customer, n.CustGroup, c.MiscDistCode, a.MiscDistCode
   
   /* If Freeform or initialized, Non-Contract Bill, we will need to acquired necessary values differently. */
   if @contract is null
   	begin
   	select @basis = sum(l.Total), @distdate = n.InvDate, @custgroup = n.CustGroup,
   		@ARCMmiscdistcode = a.MiscDistCode
   	from bJBIL l with (nolock)
   	join bJBIN n with (nolock) on n.JBCo = l.JBCo and n.BillMonth = l.BillMonth and n.BillNumber = l.BillNumber
   	join bARCM a with (nolock) on a.CustGroup = n.CustGroup and a.Customer = n.Customer
   	where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
   	group by n.InvDate, n.CustGroup, a.MiscDistCode
   	end
   
   /* Cycle through 'M' type template seq and associated MiscDistCodes */
   declare bcJBTS cursor local fast_forward for
   select Seq, MiscDistCode, GroupNum, Description, MarkupOpt, MarkupRate
   from bJBTS with (nolock)
   where JBCo = @co and Template = @template and Type = 'M'
   
   open bcJBTS
   select @openJBTScursor = 1
   
   fetch next from bcJBTS into @miscseq, @miscdistcode, @tsgroup, @tsdescription, @markupopt, @markuprate
   while @@fetch_status = 0
   	begin	/* Begin 'M' type sequence loop */
   	/* if Sequence MiscDistCode is null, then use JCCM MiscDistCode else use ARCM MiscDistCode. */ 
   	if @miscdistcode is null	
   		begin
   		select @miscdistcode = isnull(@JCCMmiscdistcode, @ARCMmiscdistcode)
   		end
   
   	/* If by this time MiscDistCode is not null, process it, otherwise get next 'M' sequence */
   	if @miscdistcode is not null
       	begin	/* Begin @miscdistcode not null */
        	select /*@miscdistrate = Rate,*/ @mdcdescription = Description 
   		from bARMC with (nolock) 
   		where CustGroup = @custgroup and MiscDistCode = @miscdistcode
   
   		/* This has been removed per Issue #17897.  The bill values are used as a basis for Misc
   		   Distributions only.  The distribution is NOT part of the bill value and therefore there
   		   is no reason to create a JBIL line for it.  (This value should not appear on the Bill!)
   		   This entire process really is just to create a rudamentary default in the JBMD table. 
   
   		   Vision adds a Line to the bill displaying a Basis and 0.00 in the total.  The following
   		   will do the same if it ever becomes an issue. */
   		/*
         	if not exists(select 1 from bJBIL with (nolock) where JBCo = @co and BillMonth = @billmth and
               	BillNumber = @billnum and TemplateSeq = @miscseq)
          		begin
           	select @line = isnull(max(Line),0)+10 
   			from bJBIL with (nolock) 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   
          		insert bJBIL (JBCo,BillMonth,BillNumber,Line,Template,TemplateSeq,
               	TemplateSeqGroup,LineType,Description,MarkupOpt,MarkupRate,Basis,
                   MarkupAddl, MarkupTotal,Total,Retainage,Discount,ReseqYN)
   			values (@co, @billmth, @billnum, @line, @template, @miscseq,
   				@tsgroup, 'M', @tsdescription, @markupopt, @markuprate, isnull(@basis,0),
   				0, 0, 0, 0, 0, 'N')
            	end
   		*/
   
   		/* Create default values in the JBMD table as a starting point for the user.  Different than
   		   Vision, user is not allowed to MarkupOpt and MarkupRate on the Template.  Therefore the
   		   full amount of the bill will be applied to the first MiscDistCode only and each code
   		   there after will get added with an amount of 0.00.  (Decided by Carolm - 10/08/03).  This
   		   is however, consistent with adding the codes manually.  (Pretty Useless)
   
   		   No updates occur as manual changes are made to the bill.  (Transactions added or amounts
   		   change manually).  It is not our intention to override the initial or modified values. */
   
   		/* UNLIKE VISION - Per Carolm */
   		if not exists(select 1 from bJBMD with (nolock) where JBCo = @co and BillMonth = @billmth
   	      		and BillNumber = @billnum and CustGroup = @custgroup and MiscDistCode = @miscdistcode)
   	    	begin
   	     	insert bJBMD (JBCo, BillMonth, BillNumber, CustGroup, MiscDistCode,
   	        	DistDate, Description, Amt)
   	      	values (@co, @billmth, @billnum, @custgroup, @miscdistcode,
   	           	@distdate, isnull(@tsdescription, @mdcdescription), 0)
   	      	end
   		
   		if @firstmdcflag = 0
   			begin
   			/* If we ever decide to update on manual Bill changes, this will do so correctly */
   	    	update bJBMD 
   			set Amt = isnull(@basis,0)
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   	        	and CustGroup = @custgroup and MiscDistCode = @miscdistcode
   	
   			select @firstmdcflag = 1
   			end
   
   		/* LIKE VISION - Need to allow access to MarkupOpt and MarkupRate on Template seq. */
   		--if not exists(select 1 from bJBMD with (nolock) where JBCo = @co and BillMonth = @billmth
   	    --  		and BillNumber = @billnum and CustGroup = @custgroup and MiscDistCode = @miscdistcode)
   	    --	begin
   	    -- 	insert bJBMD (JBCo, BillMonth, BillNumber, CustGroup, MiscDistCode,
   	    --    	DistDate, Description, Amt)
   	    --  	values (@co, @billmth, @billnum, @custgroup, @miscdistcode,
   	    --       	@distdate, isnull(@tsdescription, @mdcdescription), (isnull(@basis,0) * isnull(@markuprate,0)))
   	    --  	end
   		--else
   		--	begin
   			/* If we ever decide to update on manual Bill changes, this will do so correctly */
   	    --	update bJBMD 
   		--	set Amt = isnull(@basis,0)* isnull(@markuprate,0)
   		--	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   	    --    	and CustGroup = @custgroup and MiscDistCode = @miscdistcode
   		--	end
   		end		/* End @miscdistcode not null */
   
   	/* Get Next 'M' type template seq and associated MiscDistCode */
   	fetch next from bcJBTS into @miscseq, @miscdistcode, @tsgroup, @tsdescription, @markupopt, @markuprate
   	end		/* Begin 'M' type sequence loop */
   
   bspexit:
   if @openJBTScursor = 1
   	begin
   	close bcJBTS
   	deallocate bcJBTS
   	select @openJBTScursor = 0
   	end
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMProcessMiscDist] TO [public]
GO
