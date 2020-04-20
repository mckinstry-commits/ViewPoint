SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMProcessDetAddons    Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBTandMProcessDetAddons]
/***********************************************************
* CREATED BY	: kb 6/14/00
* MODIFIED BY	: kb 2/7/01 - issue #12222
*		kb 05/21/01 - issue #13511
*  		kb 02/27/02 - issue #16418
*   	kb 02/27/02 - issue #16484
*   	kb 03/06/02 - issue #16496
*   	kb 04/30/02 - issue #17095
*    	kb 05/07/02 - issue #17095
*		TJL 06/19/02 - Issue #17685, Correct Detail Addon against Detail Addon code.
*		TJL 07/09/02 - Issue #17701, Insert PostDate and ActualDate on Addons lines
*		TJL 07/16/02 - Issue #17144, Get proper Discount MarkupRate
*		TJL 09/09/02 - Issue #17620, Correct MarkupTotal when 'U' use Rate * Units
*		TJL 07/31/03 - Issue #21714, Use Markup rate from JCCI if available else use Template markup.
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 07/13/04 - Issue #25099, Correct Null Total into #JBIDTemp error
*		TJL 09/23/04 - Issue #25622, Remove TempTable (#JBIDTemp), use permanent table bJBIDTMWork, remove psuedos
*		TJL 09/30/04 - Issue #25612, Add MarkupOpt (H - Rate by Hour) to Detail Addons
*		TJL 09/25/06 - Issue #121269 (5x - #121253), Correct JCTransactions being place on two bills when initialized simultaneously
*		TJL 07/31/08 - Issue #128962, JB International Sales Tax
*		TJL 08/20/10 - Issue #140764, TaxRate calculations accurate to only 5 decimal places.  Needs to be 6
*		KK  01/07/12 - TK-11752 #145231 Corrected the "detail Addon" section to calculate LineType "D" rather than "S"
*
* USED IN:
*
*	bspJBTandMInit
*
* USAGE:
*
*	To place initial 0.00 value Detail Addon records into the JBIDTMWork table
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
(@co bCompany, 
 @billmth bMonth, 
 @billnum int, 
 @template varchar(30), 
 @invdate bDate, 
 @contract bContract, 
 @msg varchar(255) output)

AS 
SET NOCOUNT ON
   
DECLARE @rcode int,					@linekey varchar(100), 
		@detailkey varchar(500),	@jcmonth bMonth,
   		@jctrans bTrans,			@tempseq int, 
   		@markupopt char(1),			@markuprate numeric(17,6),
   		@tempseqgroup int,			@addlmarkup bDollar, 
   		@addontype char(1),			@seqdesc varchar(128),
   		@addonseq int,				@taxgroup bGroup, 
   		@taxcode bTaxCode,    		@item bContractItem, 
   		@taxrate bRate,		   		@custgroup bGroup, 
   		@customer bCustomer,   		@retpct bPct,			
   		@postdate bDate,    		@actualdate bDate, 
   		@payterms bPayTerms,   		@discrate bPct, 
   		@Slineaddl bDollar,    		@jccimarkuprate bRate, 
   		@job bJob,			   		@phasegroup bGroup, 
   		@phase bPhase,		   		@retgaddonseq int, 
   		@retgtaxaddonseq int 

DECLARE @1linekey1opencursor tinyint, 
		@2addon1opencursor tinyint, 
		@3linekey2opencursor tinyint,
   		@4addon2opencursor tinyint
   
SELECT  @rcode = 0, 
		@1linekey1opencursor = 0, 
		@2addon1opencursor = 0, 
		@3linekey2opencursor = 0,
   		@4addon2opencursor = 0
   
/* Get some values from the Bill Header - Only needs to be done once. */
SELECT @payterms = PayTerms
FROM bJBIN WITH (NOLOCK) 
WHERE JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum
   
SELECT @discrate = DiscRate 
FROM bHQPT WITH (NOLOCK) 
WHERE PayTerms = @payterms

DECLARE bcLineKey1 CURSOR LOCAL FAST_FORWARD FOR
SELECT  w.LineKey, 
		w.TemplateSeq, 
		w.MarkupAddl, 
		w.Item, 
		w.CustGroup, 
		w.Customer,
		i.TaxGroup, 
		i.TaxCode, 
		i.RetainPCT, 
		i.MarkUpRate
FROM bJBIDTMWork w WITH (NOLOCK)
JOIN bJCCI i WITH (NOLOCK) 
ON i.JCCo = @co AND i.Contract = @contract AND i.Item = w.Item
WHERE w.LineType = 'S' AND w.JBCo = @co AND w.VPUserName = SUSER_SNAME()
GROUP BY w.LineKey, 
		 w.TemplateSeq, 
		 w.MarkupAddl, 
		 w.Item, 
		 w.CustGroup, 
		 w.Customer,
   		 i.TaxGroup, 
   		 i.TaxCode, 
   		 i.RetainPCT, 
   		 i.MarkUpRate
   
/* Open first cursor */
OPEN bcLineKey1
SELECT @1linekey1opencursor = 1

fetch next from bcLineKey1 into @linekey, @tempseq, @Slineaddl, @item, @custgroup,
   	@customer, @taxgroup, @taxcode, @retpct, @jccimarkuprate

while @@fetch_status = 0
   	begin	/* Begin LineKey1 Loop */
   	if exists(select 1 from bJBTA with (nolock) where JBCo = @co and Template = @template
       	and Seq = @tempseq)
   		begin
    	if @taxcode is not null
        	begin
        	exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate output,
           	@msg = @msg output
          	end
   
   		declare bcAddon1 cursor local fast_forward for
   		select a.AddonSeq
   		from bJBTA a with (nolock) 
   		join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq 
   		where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq and s.Type = 'D'
   		group by a.AddonSeq
   
   		open bcAddon1
   		select @2addon1opencursor = 1
   
   		fetch next from bcAddon1 into @addonseq
   		while @@fetch_status = 0
           	begin	/* Begin Detail Addon1 Loop */
        	select @markupopt = MarkupOpt, 
				@markuprate = case MarkupOpt
               		when 'T' then case when @taxcode is not null then
               			isnull(@taxrate,0) else MarkupRate end
               		when 'X' then case when @taxcode is not null then
               			isnull(@taxrate,0) else MarkupRate end
               		when 'R' then case when @contract is null
               			then MarkupRate else case MarkupRate when 0
               			then isnull(@retpct,MarkupRate) else MarkupRate end end
					when 'D' then case when isnull(@discrate,0)<>0 then
						case MarkupRate when 0 then @discrate else MarkupRate end
						else MarkupRate end
					when 'S' then case when isnull(@jccimarkuprate,0) <> 0 then
						case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
						else MarkupRate end
              			else MarkupRate end,
               @tempseqgroup = GroupNum, @addlmarkup = AddonAmt,
               @addontype = Type, @seqdesc = Description
         	from bJBTS with (nolock) 
   			where JBCo = @co and Template = @template and Seq = @addonseq
   
        	/* only process detail addons here */
        	if @addontype <> 'D' goto NextAddon
   
   			/* Initialize a 0.00 value entry in bJBIDTMWork table for each Detail Addon.  The detail addon values
			   will be updated later from 'bspJBTandMInit' by calling 'bspJBTandMUpdateSeqAddons'*/
        	select @contract= Contract, @item = Item, @job = Job,
           		@phasegroup = PhaseGroup, @phase = Phase,
				@postdate = PostDate, @actualdate = ActualDate,
				@template = Template
			from bJBIDTMWork with (nolock)  
   			where LineKey = @linekey and LineType = 'S'  and TemplateSeq = @tempseq and JBCo = @co and VPUserName = SUSER_SNAME()  
   			group by Contract, Item, Job, PhaseGroup, Phase, PostDate,
				ActualDate, Template, LineKey

			insert bJBIDTMWork (JBCo, VPUserName, Contract,Item, TemplateSeq, TemplateSeqType,
               	DetailKey, Description, Job, PhaseGroup, Phase, PostDate,
               	ActualDate, StdPrice, Units, UnitPrice, Hours, SubTotal,
               	MarkupOpt, MarkupRate, MarkupAddl, MarkupTotal, Total, Retainage, Discount,
               	Template, TemplateSeqGroup, LineKey, AddonSeq,
               	AppliedToSeq, LineType, TaxGroup, TaxCode)
			select  @co, SUSER_SNAME(), @contract, @item, @addonseq, 'D',
               	'Addon', @seqdesc, @job, @phasegroup, @phase, @postdate,
               	@actualdate, 0, 0, 0, 0, 0,								
               	@markupopt, @markuprate, @addlmarkup, 0, 0, 0, 0,
				@template, null, @linekey, @addonseq, 
               	@tempseq, 'D', @taxgroup, case when @markupopt in ('T', 'X') then @taxcode else null end
   
		NextAddon:
   			fetch next from bcAddon1 into @addonseq
			end		/* End Detail Addon1 Loop */
   
   		if @2addon1opencursor = 1
   			begin
   			close bcAddon1
   			deallocate bcAddon1
   			select @2addon1opencursor = 0
   			end
   		end		/* End TemplateSeq */
   
   	fetch next from bcLineKey1 into @linekey, @tempseq, @Slineaddl, @item, @custgroup,
		@customer, @taxgroup, @taxcode, @retpct, @jccimarkuprate
	end		/* End LineKey1 Loop */

/* Close first cursor */   
if @1linekey1opencursor = 1
   	begin
   	close bcLineKey1
   	deallocate bcLineKey1
   	select @1linekey1opencursor = 0
   	end

/* As a result of the International Sales Tax issue and the need to calculate Tax on a Retainage amount
   it became necessary to run this second loop to pick up those remaining Detail Addons applied against other 
   Detail Addons but NOT also applied against a Source sequence.  Because these remaining Detail Addons are not  
   also applied against a Source sequence, they get overlooked during the first loop. 
   ***Note Limitation ***
   We can have Detail Addons that apply against other Detail Addons but only IF the other Detail Addons 
   themselves are applied against Source sequences.  In other words I can have a RetgTax Detail Addon that
   applies against a Retainage Detail addon because the Retainage Detail Addon does apply against Source
   sequences.  I cannot (ILLEGAL SETUP) apply another Detail Addon against the RetgTax Detail Addon 
   described above because it applies only against the Retainage Detail Addon and nothing else. */
DECLARE bcLineKey1 CURSOR LOCAL FAST_FORWARD FOR
SELECT  w.LineKey, 
		w.TemplateSeq, 
		w.MarkupAddl, 
		w.Item, 
		w.CustGroup, 
		w.Customer,
		i.TaxGroup, 
		i.TaxCode, 
		i.RetainPCT, 
		i.MarkUpRate
FROM bJBIDTMWork w WITH (NOLOCK)
JOIN bJCCI i WITH (NOLOCK) 
ON i.JCCo = @co AND i.Contract = @contract AND i.Item = w.Item
WHERE w.LineType = 'D' AND w.JBCo = @co AND w.VPUserName = SUSER_SNAME()
GROUP BY w.LineKey, 
		 w.TemplateSeq, 
		 w.MarkupAddl, 
		 w.Item, 
		 w.CustGroup, 
		 w.Customer,
		 i.TaxGroup, 
		 i.TaxCode, 
		 i.RetainPCT, 
		 i.MarkUpRate

/* Open second cursor */    
OPEN bcLineKey1
SELECT @1linekey1opencursor = 1

fetch next from bcLineKey1 into @linekey, @tempseq, @Slineaddl, @item, @custgroup,
   	@customer, @taxgroup, @taxcode, @retpct, @jccimarkuprate
while @@fetch_status = 0
   	begin	/* Begin LineKey1 Loop */

   	if exists(select 1 from bJBTA with (nolock) where JBCo = @co and Template = @template
       	and Seq = @tempseq)
   		begin
    	if @taxcode is not null
        	begin
        	exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate output,
           	@msg = @msg output
          	end
   
   		declare bcAddon1 cursor local fast_forward for
   		select a.AddonSeq
   		from bJBTA a with (nolock) 
   		join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq 
   		where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq and s.Type = 'D'
   		group by a.AddonSeq
   
   		open bcAddon1
   		select @2addon1opencursor = 1
   
   		fetch next from bcAddon1 into @addonseq
   		while @@fetch_status = 0
           	begin	/* Begin Detail Addon1 Loop */
        	select @markupopt = MarkupOpt, 
				@markuprate = case MarkupOpt
               		when 'T' then case when @taxcode is not null then
               			isnull(@taxrate,0) else MarkupRate end
               		when 'X' then case when @taxcode is not null then
               			isnull(@taxrate,0) else MarkupRate end
               		when 'R' then case when @contract is null
               			then MarkupRate else case MarkupRate when 0
               			then isnull(@retpct,MarkupRate) else MarkupRate end end
					when 'D' then case when isnull(@discrate,0)<>0 then
						case MarkupRate when 0 then @discrate else MarkupRate end
						else MarkupRate end
					when 'S' then case when isnull(@jccimarkuprate,0) <> 0 then
						case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
						else MarkupRate end
              			else MarkupRate end,
               @tempseqgroup = GroupNum, @addlmarkup = AddonAmt,
               @addontype = Type, @seqdesc = Description
         	from bJBTS with (nolock) 
   			where JBCo = @co and Template = @template and Seq = @addonseq
   
        	/* only process detail addons here */
        	if @addontype <> 'D' goto NextAddon2
   
   			/* Initialize a 0.00 value entry in bJBIDTMWork table for each Detail Addon.  The detail addon values
			   will be updated later from 'bspJBTandMInit' by calling 'bspJBTandMUpdateSeqAddons'*/
        	select @contract= Contract, @item = Item, @job = Job,
           		@phasegroup = PhaseGroup, @phase = Phase,
				@postdate = PostDate, @actualdate = ActualDate,
				@template = Template
			from bJBIDTMWork with (nolock)  --TK-11752
   			where LineKey = @linekey and LineType = 'D'  and TemplateSeq = @tempseq and JBCo = @co and VPUserName = SUSER_SNAME()  
   			group by Contract, Item, Job, PhaseGroup, Phase, PostDate,
				ActualDate, Template, LineKey

			/* Before doing the insert check to see that this particular Detail Addon was not already inserted
			   during the first loop (The first loop processes detail addons applied against Source sequences only).
			   This will prevent a duplicate key error. */
			if not exists(select top 1 1 from bJBIDTMWork where JBCo = @co and VPUserName = SUSER_SNAME()
				and AddonSeq = @addonseq and JCTrans is null and JCMonth is null and DetailKey = 'Addon'
				and LineKey = @linekey and Line is null and Item = @item)
				begin
				insert bJBIDTMWork (JBCo, VPUserName, Contract,Item, TemplateSeq, TemplateSeqType,
               		DetailKey, Description, Job, PhaseGroup, Phase, PostDate,
               		ActualDate, StdPrice, Units, UnitPrice, Hours, SubTotal,
               		MarkupOpt, MarkupRate, MarkupAddl, MarkupTotal, Total, Retainage, Discount,
               		Template, TemplateSeqGroup, LineKey, AddonSeq,
               		AppliedToSeq, LineType, TaxGroup, TaxCode)
				select  @co, SUSER_SNAME(), @contract, @item, @addonseq, 'D',
               		'Addon', @seqdesc, @job, @phasegroup, @phase, @postdate,
               		@actualdate, 0, 0, 0, 0, 0,								
               		@markupopt, @markuprate, @addlmarkup, 0, 0, 0, 0,
					@template, null, @linekey, @addonseq, 
               		@tempseq, 'D', @taxgroup, case when @markupopt in ('T', 'X') then @taxcode else null end
				end

		NextAddon2:
   			fetch next from bcAddon1 into @addonseq
			end		/* End Detail Addon1 Loop */
   
   		if @2addon1opencursor = 1
   			begin
   			close bcAddon1
   			deallocate bcAddon1
   			select @2addon1opencursor = 0
   			end
   		end		/* End TemplateSeq */    
   	fetch next from bcLineKey1 into @linekey, @tempseq, @Slineaddl, @item, @custgroup,
		@customer, @taxgroup, @taxcode, @retpct, @jccimarkuprate
	end		/* End LineKey1 Loop */
	
/* Close second cursor */     
if @1linekey1opencursor = 1
begin
   	close bcLineKey1
   	deallocate bcLineKey1
   	select @1linekey1opencursor = 0
end

bspexit:
if @1linekey1opencursor = 1
begin
   	close bcLineKey1
   	deallocate bcLineKey1
   	select @1linekey1opencursor = 0
end
if @2addon1opencursor = 1
begin
   	close bcAddon1
   	deallocate bcAddon1
   	select @2addon1opencursor = 0
end
   
RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBTandMProcessDetAddons] TO [public]
GO
