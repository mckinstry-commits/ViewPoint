CREATE TABLE [dbo].[bJBIJ]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[BillNumber] [int] NOT NULL,
[Line] [int] NULL,
[Seq] [int] NULL,
[JCMonth] [dbo].[bMonth] NOT NULL,
[JCTrans] [dbo].[bTrans] NOT NULL,
[BillStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[Hours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJBIJ_Hours] DEFAULT ((0)),
[Units] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJBIJ_Units] DEFAULT ((0)),
[Amt] [numeric] (15, 5) NOT NULL CONSTRAINT [DF_bJBIJ_Amt] DEFAULT ((0)),
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIJ_AuditYN] DEFAULT ('Y'),
[Purge] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIJ_Purge] DEFAULT ('N'),
[UnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJBIJ_UnitPrice] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[UM] [dbo].[bUM] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[EMRevCode] [dbo].[bRevCode] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJBIJ] ON [dbo].[bJBIJ] ([JBCo], [BillMonth], [BillNumber], [Line], [Seq], [JCMonth], [JCTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBIJ] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE  TRIGGER [dbo].[btJBIJd] ON [dbo].[bJBIJ]
FOR DELETE AS

/**********************************************************************************
*  Created by: kb 5/15/00
*  Modified by: ALLENN 11/16/2001 Issue #13667
* 		kb 2/19/2 - issue #16147
*  		kb 2/2/2 - issue #18143  - to not update JCCD billstatus if purging
*		TJL 11/06/02 - Issue #18740, No need to update JBID when bill is purged
*		TJL 02/11/03 - Issue #20298, Don't remove Billed Status info if BillStatus = 2
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 05/14/04 - Issue #22526, Accurately accumulate JBID UM, Units, UnitPrice, ECM.  Phase #1
*		TJL 06/24/04 - Issue #24915, Increase Accuracy of JBID.SubTotal
*		TJL 12/14/04 - Issue #26526, Treat EM Equip transactions as Hourly based when RevCode is NULL
*		TJL 09/14/06 - Issue #122403, Show UM, Units, UnitPrice, ECM for NULL Material when SummaryOpt = 1 (Full Detail)
*		TJL 10/09/06 - Issue #122360, Related to Issue #26526 above.  Needed further adjustments.
*
*	This trigger rejects delete of bJBIJ
*	if the following error condition exists:
*		none
*
*
************************************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int,
   	@billmth bMonth, @jbidseq int, @jbum bUM, @hours bHrs, @units bUnits,
   	@co bCompany, @mth bMonth, @billnum int, @line int, @jctrans bTrans,
   	@billstatus tinyint, @purgeyn bYN, @JBIJaudityn bYN, @openbJBIJcursor int,
    @markupopt char(1), @jbidum bUM, @priceopt char(1),
   	@jccdmatlgroup bGroup, @jccdmaterial bMatl, @jccdinco bCompany, @jccdloc bLoc,
   	@jccdcosttype bJCCType, @jccdphasegrp bGroup, @ctcategory char(1), 
   	@jctranstype char(2), @updateUPflag bYN, @updateUPtype char(1),
   	@conversion bUnitCost, @jbidunits bUnits, @jbidhrs bHrs, @jbidsubtotal numeric(15,5),
   	@jbidecm bECM, @emrcbasis char(1), @emgroup bGroup, @emrevcode bRevCode,
   	@delunitsYN bYN, @delhrsYN bYN, @calcUPflag char(1), @jbijcount int,
   	@Hbasiscount int, @Ubasiscount int, @ecmfactor smallint, @seqsumopt tinyint
   
   -- @seq int, @amt bDollar,
   
select @numrows = @@rowcount, @openbJBIJcursor = 0

if @numrows = 0 return
set nocount on

declare bJBIJ_delete cursor local fast_forward for
select d.JBCo, d.BillMonth, d.BillNumber, d.Line, d.Seq, d.JCMonth, d.JCTrans,
d.BillStatus, d.UM, d.Hours, d.Units, d.AuditYN, d.Purge,
c.MatlGroup, c.Material, c.INCo, c.Loc, c.CostType, c.PhaseGroup, 
c.JCTransType, d.EMGroup, d.EMRevCode
from deleted d
join bJCCD c with (nolock) on c.JCCo = d.JBCo and c.Mth = d.JCMonth and c.CostTrans = d.JCTrans

open bJBIJ_delete
select @openbJBIJcursor = 1
   
fetch next from bJBIJ_delete into @co, @billmth, @billnum, @line, @jbidseq, @mth, @jctrans,
	@billstatus, @jbum, @hours, @units, @JBIJaudityn, @purgeyn,	
   	@jccdmatlgroup, @jccdmaterial, @jccdinco, @jccdloc, @jccdcosttype, @jccdphasegrp,
   	@jctranstype, @emgroup, @emrevcode
while @@fetch_status = 0
   	begin
   	select @updateUPtype = 'Z', @updateUPflag = 'Y',		-- reset flags
   		@emrcbasis = null, @jbijcount = 0, @Hbasiscount = 0, @Ubasiscount = 0
   
   	/* If purge flag is set to 'Y',three conditions may exist.
   		1) If this is a single Bill being deleted by hitting 'Delete' Key
   		   then exit immediately to skip all unnecessary updates to detail
   		   records that are also being deleted.
   		2) If this is a True Purge then multiple Bills may exist in the 
   		   'delete' queue.  Again, it is OK to exit immediately since the
   		   'delete' queue will contain ONLY Bills (Detail Tables will contain
   		   ONLY records) marked for PURGE.  Therefore there is no sense in
   		   cycling through each Bill because they are ALL marked to be Purged.
   		3) Bill Lines or Detail sequences are being resequenced.  Since all values
   		   have already been established in all related tables, there is no need
   		   to perform trigger updates.
   
   		****NOTE**** 
   		JB is unique in that a user is allowed to delete a bill and its detail
   		from a JB Bill Header form.  There is potential for leaving detail out
   		there if a JBIN record is removed ADHOC but user insist on this capability. */
   
   	/* At this point, the combination of the Purge Flag and Audit Flag
   	   can be used to determine if this is a standard Purge (JCCD Bill
   	   Status NOT changed so exit immediately) or this is a form Delete 
   	   (JCCD BillStatus changed so process each JCTrans). */
   	if @purgeyn = 'Y' and @JBIJaudityn = 'N' 		-- True Purge or Resequence
   		begin
   		if @openbJBIJcursor = 1
   			begin
   			close bJBIJ_delete
   			deallocate bJBIJ_delete
   			select @openbJBIJcursor = 0
   			end
   		return
   		end
   
   	if @purgeyn = 'Y' and @JBIJaudityn = 'Y'	-- Single Bill Delete
   		begin
       	update bJCCD 
   		set JBBillStatus = 0, JBBillNumber = null, JBBillMonth = null
		from bJCCD 
   		where JCCo = @co and Mth = @mth and CostTrans = @jctrans
   		end
   	else
   		begin	--@purgeyn = N, Normal Individual JCTrans Delete processing
   
   		/* Obtain some values to use for further updates to other tables. */
   		select @jbijcount = count(*)
   		from bJBIJ with (nolock)
   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   			and Line = @line and Seq = @jbidseq 
   			and (JCMonth <> @mth or (JCMonth = @mth and JCTrans <> @jctrans))
   
   		select @jbidum = d.UM, @jbidunits = d.Units, @jbidhrs = d.Hours, @jbidsubtotal = SubTotal,
   			@jbidecm = isnull(ECM, 'E')
   		from bJBID d with (nolock)			
   		where d.JBCo = @co and d.BillMonth = @billmth and d.BillNumber = @billnum
   			and d.Line = @line and d.Seq = @jbidseq 
   
   		select @ecmfactor = case isnull(@jbidecm, 1)
   						when 'E' then 1
   						when 'C' then 100
   						when 'M' then 1000 end
   		
   		select @seqsumopt = l.TemplateSeqSumOpt,  @markupopt = l.MarkupOpt, @priceopt = s.PriceOpt
   		from bJBIL l with (nolock)
   		join bJBTS s with (nolock) on s.JBCo = l.JBCo and s.Template = l.Template and s.Seq = l.TemplateSeq
   		where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
   		  	and l.Line = @line

   		select @ctcategory = JBCostTypeCategory 
   		from bJCCT with (nolock)
   		where PhaseGroup = @jccdphasegrp and CostType = @jccdcosttype
   		if @ctcategory is not null
   			begin
   			if (@jctranstype = 'PR' and @ctcategory = 'E') 
   				or (@jctranstype = 'MS' and @ctcategory = 'E') select @jctranstype = 'EM'
   			end
   
   		if @emgroup is not null and @emrevcode is not null
   			begin
   			/* Get Basis for this Equipment transaction */
   			select @emrcbasis = Basis
   			from bEMRC with (nolock)
   			where EMGroup = @emgroup and RevCode = @emrevcode
   			end	
   	
   	/************************************** Update Evaluation Section **************************************/
   		/* Begin evaluation of How (UpdateUPType) we will be updating Units, Hours,
   		   and UnitPrice. It is different depending upon the type of transaction
   		   (JCTransType) that is being processed. 
   		
   			M) Material may need to be converted before updating to JBID for accuracy
   			L) Labor, currently no special conversion required.  Separated just in case. 
   			E) Equipment, requires more research and customer input to determine how to
   			   summarize this accurately.  Separated for future developement 
   			Z) All others.  Update as they have always done unless special request from users. */

   		if @jccdmaterial is null and @jctranstype in ('AP', /*'PO',*/ 'IN', 'MI', 'MS', 'MO', 'MT')
   			and @ctcategory = 'M'
   			begin	/* Begin NULL JCCD Material Type evaluation */
			if @seqsumopt = 1
				begin	
				select @updateUPtype = 'M'
				goto BeginUpdate
				end
			else
				begin
				select @updateUPflag = 'N'
				goto BeginUpdate
				end
			End		/* End NULL JCCD Material Type evaluation */

   		if @jccdmaterial is not null and @jctranstype in ('AP', /*'PO',*/ 'IN', 'MI', 'MS', 'MO', 'MT')
   			and @ctcategory = 'M'
   			begin	/* Begin Material Type evaluation */
   			select @updateUPtype = 'M'
   
   			if @jbidum is null
   				begin
   				select @updateUPflag = 'N'
   				goto BeginUpdate	
   				end
   			else
   				begin	/* Begin @jbidum Not NULL */
   				if @jbum = @jbidum 	
   					begin
   					/* UMs are both the same and @jbidum is not null. */
   					select @updateUPflag = 'Y', @conversion = 1
   					goto BeginUpdate
   					end
   				else
   					begin	/* Begin UMs Different evaluation */
   					/* UMs are different and @jbidum is not null. */
   					If @priceopt = 'C'
   						begin
   						/* Can't really occur.  @jbidum would already be NULL, in 
   						   this case, having been set that way by bspJBTandMUpdateJBIDUnitPrice */
   						select @updateUPflag = 'N'
   						goto BeginUpdate	
   						end
   			
   					if @priceopt = 'P'
   						begin	
   						/* Get Converted UM conversion value.  It must exist otherwise @jbidum
   						   would already be set to NULL by bspJBTandMUpdateJBIDUnitPrice and we
   						   would not have gotten this far. */
   						select @conversion = u.Conversion
   						from bHQMU u with (nolock)
   						where u.MatlGroup = @jccdmatlgroup and u.Material = @jccdmaterial and u.UM = @jbum
   						if @conversion is null
   							begin
   							select @updateUPflag = 'N'
   							goto BeginUpdate	
   							end
   						else
   							begin
   							select @updateUPflag = 'Y'	-- @conversion retrieved above
   							goto BeginUpdate
   							end
   						end
   			
   					if @priceopt = 'L'
   						begin
   						/* Get Converted UM conversion value.  It must exist otherwise @jbidum
   						   would already be set to NULL by bspJBTandMUpdateJBIDUnitPrice and we
   						   would not have gotten this far. */
   						select @conversion = u.Conversion
   						from bINMU u with (nolock)
   						where u.MatlGroup = @jccdmatlgroup and u.Material = @jccdmaterial and u.UM = @jbum
   							and u.INCo = @jccdinco and u.Loc = @jccdloc
   						if @conversion is null
   							begin
   							select @conversion = u.Conversion
   							from bHQMU u with (nolock)
   							where u.MatlGroup = @jccdmatlgroup and u.Material = @jccdmaterial and u.UM = @jbum
   							if @conversion is null
   								begin
   								select @updateUPflag = 'N'
   								goto BeginUpdate	
   								end
   							else
   								begin
   								select @updateUPflag = 'Y'	-- @conversion retrieved above
   								goto BeginUpdate
   								end
   							end
   						end
   					end		/* End UMs Different evaluation */
   				end		/* End @jbidum Not NULL */
   			end		/* End Material Type evaluation */
   	
   		if @jctranstype in ('PR') and @ctcategory = 'L'
   			begin	/* Begin Labor HRS evaluation */
   			select @updateUPtype = 'L'
   			select @updateUPflag = 'Y'	
   			goto BeginUpdate	
   			end		/* End Labor HRS evaluation */
   		
   		if @jctranstype in ('EM',/* 'MS', 'PR',*/ 'JC') and @ctcategory = 'E'	--<-- Most Always will be 'EM' 'E'
   			begin	/* Begin Equipment evaluation */
   			select @updateUPtype = 'E'
   	
   			/* Equipment usage can be Hourly based or Unit based.  In each case below, JBID
   			   has already been preset (by procedure bspJBTandMUpdateJBIDUnitPrice) based upon 
   			   compatibility with this transaction.  Therefore at this point, we already
   			   know (by the condition of JBID), what the basis for this transaction is.  We 
   			   simply need to set update flags accordingly so that the update statement knows
   			   how to update. */
   	
   			/* #1 */
   			if @jbidunits = 0 and @jbidhrs = 0
   				begin	/* Begin JBID is Basis is unknown */
   				/* If JBID Units and Hours are both 0 then either JBID has been set by a transaction that 
   				   was based differently than others before it or, by bad luck and chance, the first two
   			 	   transactions to be processed canceled each other out.  In all cases, we really do not yet know
   				   if we are dealing with UnitBased or Hourly based!  JBIJ insert triggers will now need to
   				   evaluate the basis of this transaction compared to those already in JBIJ and 
   				   either update, if all are the same Basis, or not if the Basis's differ in anyway. */
 				select @Hbasiscount = Count(*)
 				from bJBIJ j with (nolock)
 				left join bEMRC e with (nolock) on e.EMGroup = j.EMGroup and e.RevCode = j.EMRevCode
 				where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum
 					and j.Line = @line and j.Seq = @jbidseq and (e.Basis = 'H' or j.EMRevCode is null)
 					and (j.JCMonth <> @mth or (j.JCMonth = @mth and j.JCTrans <> @jctrans))
   		
   				select @Ubasiscount = Count(*)
   				from bJBIJ j with (nolock)
   				join bEMRC e with (nolock) on e.EMGroup = j.EMGroup and e.RevCode = j.EMRevCode
   				where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum
   					and j.Line = @line and j.Seq = @jbidseq and e.Basis = 'U' and j.UM = @jbum 
   					and (j.JCMonth <> @mth or (j.JCMonth = @mth and j.JCTrans <> @jctrans))
   
   				if @emrcbasis = 'H' or @emrcbasis is null	--A Null EM RevCode is Hourly based
   					begin
   					if (@Hbasiscount = @jbijcount) and @jbidsubtotal = 0 
   						begin
   						/* Offseting values:  All existing records are Hourly based.  Update Hourly Yes */
   						select @updateUPflag = 'Y', @delunitsYN = 'N', @delhrsYN = 'Y', @calcUPflag = 'H'
   						goto BeginUpdate
   						end
   					else	
   						begin
   						/* This seq contains a mixed bag. Update No, leaving values at 0.00/null */
   						select @updateUPflag = 'N'
   						goto BeginUpdate
   						end
   					end
   
   				if @emrcbasis = 'U'
   					begin
   					/* Unfortunately (Unlike Hourly Based), there is no way to know the difference
   					   between whether JBID Units/Hrs are currently 0 because they were purposely
   					   set that way due to Mixed UM (or Mixed Hourly/Unit based) or if so because
   					   of the very unlikely possibility that transactions have been deleted in such
   					   a way leaving the exact combination of transactions that exactly cancel each
   					   other out.  Therefore we will play the odds and once 0, they will remain that
   					   way. */
   					select @updateUPflag = 'N'
   					goto BeginUpdate
   					end
   				end		/* End JBID is Basis is unknown */
   		
   			/* #2 */
   			if @jbidunits <> 0 and @jbidhrs = 0
   				begin	/* Begin JBID is UnitsBased */
   				select @updateUPflag = 'Y', @delunitsYN = 'Y', @delhrsYN = 'N', @calcUPflag = 'U' 
   				goto BeginUpdate		
   				end 	/* End JBID is UnitsBased */
   		
   			/* #3 */
   			if @jbidhrs <> 0 and @jbidunits = 0
   				begin	/* Begin JBID is Hours Based */
   				select @updateUPflag = 'Y', @delunitsYN = 'N', @delhrsYN = 'Y', @calcUPflag = 'H'
   				goto BeginUpdate
   				end  	/* End JBID is Hours Based */	
   		
   			/* #4 */
   			if @jbidhrs <> 0 and @jbidunits <> 0
   				begin	/* Begin JBID is TimeUnits Hours Based */
   				select @updateUPflag = 'Y', @delunitsYN = 'Y', @delhrsYN = 'Y', @calcUPflag = 'U'
   				goto BeginUpdate	
   				end		/* End JBID is TimeUnits Hours Based */
   	
   			end		/* End Equipment evaluation */
   
   /************************************** UPDATE SECTION **************************************************/	
   	BeginUpdate:
   
       	update bJCCD 
   		set JBBillStatus = 0, JBBillNumber = null, JBBillMonth = null
		from bJCCD 
   		where JCCo = @co and Mth = @mth and CostTrans = @jctrans
   		--	and JBBillStatus <> 2	-- To always show transactions in JBTMJCDetail Form, Un-Rem here.
   									--	(Also see btJBIJu)
   	
   		/* The Update statement appears complex and needs to be. Break it down to individual
   		   operations when evaluating it.  The isnull() function is in place because there are 
   		   times when the Update for a particular field is to be ignored or left alone.  In
   		   these instances, the isnull() function will simply put back in what already exists. */
		update bJBID 
   		set Hours = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   					when 'M' then j.Hours - d.Hours			-- Not Necessary, left for consistency
   					when 'L' then j.Hours - d.Hours
   					when 'E' then case @delhrsYN when 'Y' then j.Hours - d.Hours end	
   					else j.Hours - d.Hours end				-- Should be 0 - 0
   				end),j.Hours),
   	  		Units = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   					when 'M' then j.Units - (d.Units * isnull(@conversion,1))
   					when 'L' then j.Units - d.Units			-- Not Necessary, left for consistency
   					when 'E' then case @delunitsYN when 'Y' then j.Units - d.Units end
   					else j.Units - d.Units end				-- Should be 0 - 0
   				end),j.Units),
   			UnitPrice = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   					when 'M' then case when (j.Units - (d.Units * isnull(@conversion,1))) = 0 then 0
   							else ((j.SubTotal - d.Amt)/(j.Units - (d.Units * isnull(@conversion,1)))) * @ecmfactor end
   					when 'L' then case when (j.Hours - d.Hours) = 0 then 0 
   							else (j.SubTotal - d.Amt)/(j.Hours - d.Hours) end
   					when 'E' then case isnull(@emrcbasis,'')
   						when 'U' then case @calcUPflag 
   							when 'U' then case when (j.Units - d.Units) = 0 then 0 
   								else ((j.SubTotal - d.Amt)/(j.Units - d.Units)) * @ecmfactor end end	-- @ecmfactor always 1 here
   						when 'H' then case @calcUPflag
   							when 'H' then case when (j.Hours - d.Hours) = 0 then 0 
   								else (j.SubTotal - d.Amt)/(j.Hours - d.Hours) end
   							when 'U' then case when (j.Units - d.Units) = 0 then 0 
   								else ((j.SubTotal - d.Amt)/(j.Units - d.Units)) * @ecmfactor end end	-- @ecmfactor always 1 here
   						when '' then case @calcUPflag
   							when 'H' then case when (j.Hours - d.Hours) = 0 then 0 
   								else (j.SubTotal - d.Amt)/(j.Hours - d.Hours) end end
   						end									
   					else d.UnitPrice end					-- Should be 0
   				end),j.UnitPrice), 
        		SubTotal = j.SubTotal - d.Amt,
   	  		MarkupTotal = isnull((case @markupopt when 'U' then 
   							case @updateUPflag when 'Y' then case @updateUPtype
   						when 'M' then (j.MarkupRate * (j.Units - (d.Units * isnull(@conversion,1)))) + j.MarkupAddl
   						when 'E' then case @delunitsYN when 'Y' then (j.MarkupRate * (j.Units - d.Units)) + j.MarkupAddl end
   						else (j.MarkupRate * (j.Units - d.Units)) + j.MarkupAddl end
   					end
   				else (j.MarkupRate * (j.SubTotal - d.Amt)) + j.MarkupAddl end),j.MarkupTotal),
   	  		Total = isnull(((j.SubTotal - d.Amt) + case @markupopt when 'U' then 
   							case @updateUPflag when 'Y' then case @updateUPtype
   						when 'M' then ((j.MarkupRate * (j.Units - (d.Units * isnull(@conversion,1)))) + j.MarkupAddl)
   						when 'E' then case @delunitsYN when 'Y' then ((j.MarkupRate * (j.Units - d.Units)) + j.MarkupAddl) end
   						else ((j.MarkupRate * (j.Units - d.Units)) + j.MarkupAddl) end
   					end
   				else ((j.MarkupRate * (j.SubTotal - d.Amt)) + j.MarkupAddl) end),j.Total),
   			AuditYN = 'N',
   			JCMonth = null, JCTrans = null
       	from bJBID j 
   		join deleted d on j.JBCo = d.JBCo and j.BillMonth = d.BillMonth 
   			and j.BillNumber = d.BillNumber and j.Line = d.Line and j.Seq = d.Seq 
   		where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum
       		and j.Line = @line and j.Seq = @jbidseq and d.JCMonth = @mth 
   			and d.JCTrans = @jctrans and d.BillStatus = 1

		update bJBID 
		set AuditYN = 'Y'
		from bJBID j 
		join deleted d on j.JBCo = d.JBCo and j.BillMonth = d.BillMonth 
			and j.BillNumber = d.BillNumber and j.Line = d.Line and j.Seq = d.Seq 
		where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum
			and j.Line = @line and j.Seq = @jbidseq and d.JCMonth = @mth 
			and d.JCTrans = @jctrans and d.BillStatus = 1
		end

	fetch next from bJBIJ_delete into @co, @billmth, @billnum, @line, @jbidseq, @mth, @jctrans,
		@billstatus, @jbum, @hours, @units, @JBIJaudityn, @purgeyn,	
		@jccdmatlgroup, @jccdmaterial, @jccdinco, @jccdloc, @jccdcosttype, @jccdphasegrp,
		@jctranstype, @emgroup, @emrevcode
   	end
   
if @openbJBIJcursor = 1
   	begin
   	close bJBIJ_delete
   	deallocate bJBIJ_delete
   	select @openbJBIJcursor = 0
   	end
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   /*
   select @co = min(JBCo) 
   from deleted d
   while @co is not null
   	begin
   	select @billmth = min(BillMonth) 
   	from deleted d 
   	where JBCo = @co
    	while @billmth is not null
       	begin
        	select @billnum = min(BillNumber) 
   		from deleted d 
   		where JBCo = @co and BillMonth = @billmth
          	while @billnum is not null
           	begin
            	select @mth = min(JCMonth) 
   			from deleted d 
   
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
            	while @mth is not null
               	begin
                   select @jctrans = min(JCTrans) 
   				from deleted d 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
   					and JCMonth = @mth
                   while @jctrans is not null
                   	begin
                     	select @line = Line, @jbidseq = Seq, @purgeyn = Purge,
   						@JBIJaudityn = AuditYN
   					from deleted d 
   					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
                       	and JCMonth = @mth and JCTrans = @jctrans
   
                     	select @jctrans = min(JCTrans) 
   					from deleted d 
   					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
   						and JCMonth = @mth and JCTrans > @jctrans
                     	end
   
           		select @mth = min(JCMonth) 
   				from deleted d 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and JCMonth > @mth
                 	end
   
             	select @billnum = min(BillNumber) 
   			from deleted d 
   			where JBCo = @co and BillMonth = @billmth and BillNumber > @billnum
             	if @@rowcount = 0 select @billnum = null
             	end
   
    		select @billmth = min(BillMonth) 
   		from deleted d 
   		where JBCo = @co and BillMonth > @billmth
         	if @@rowcount = 0 select @billmth = null
         	end
   
   	select @co = min(JBCo) 
   	from deleted d 
   	where JBCo > @co
      	if @@rowcount = 0 select @co = null
   	end
   */
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   
/*Issue 13667*/
if @purgeyn = 'Y' and @JBIJaudityn = 'Y' return	-- Skip Auditing for Single Bill Delete

Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBIJ', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'BillMonth: ' + convert(varchar(8), d.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),d.BillNumber) 
	+ 'Line: ' + isnull(convert(varchar(10),d.Line), '') + 'Seq: ' + isnull(convert(varchar(10),d.Seq), '') + 'JCMonth: ' + convert(varchar(8), d.JCMonth, 1) 
	+ 'JCTrans: ' + convert(varchar(10),d.JCTrans), d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME()
From deleted d
Join bJBCO c with (nolock) on c.JBCo = d.JBCo
Where c.AuditBills = 'Y' and d.AuditYN = 'Y'

return

error:
select @errmsg = @errmsg + ' - cannot delete JBIJ!'

if @openbJBIJcursor = 1
	begin
	close bJBIJ_delete
	deallocate bJBIJ_delete
	select @openbJBIJcursor = 0
	end

RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
CREATE TRIGGER [dbo].[btJBIJi] ON [dbo].[bJBIJ]
FOR INSERT AS

/**************************************************************
*	This trigger rejects insert of bJBIJ
*	 if the following error condition exists:
*		none
*
*  Created by: kb 5/15/00
*  Modified by: kb 9/4/1 - issue #13963
*  		ALLENN 11/16/2001 Issue #13667
*  		kb 2/19/2 - issue #16147
*    	kb 2/27/2 - issue #16432
*		kb 7/22/2 - issue #18036 - update JBID with JCTrans/JCMonth if 
*									line is in full detail summary option
*		TJL 09/09/02 - Issue #17620, Correct Source MarkupOpt when 'U' use Rate * Units
*		TJL 10/15/02 - Issue #19005, Correct Insert statement to bHQMA. Do NOT concatenate NULL values
*		TJL 11/12/02 - Issue #19314, Change @seqsumopt datatype from char(1) to tinyint
*		TJL 06/16/03 - Issue #21410, UnitPrice could change, update JBID accordingly
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor, suspend during Resequencing
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 05/14/04 - Issue #22526, Accurately accumulate JBID UM, Units, UnitPrice, ECM.  Phase #1
*		TJL 06/24/04 - Issue #24915, Increase Accuracy of JBID.SubTotal
*		TJL 12/14/04 - Issue #26526, Treat EM Equip transactions as Hourly based when RevCode is NULL
*		TJL 09/14/06 - Issue #122403, Show UM, Units, UnitPrice, ECM for NULL Material when SummaryOpt = 1 (Full Detail)
*		TJL 10/09/06 - Issue #122360, Related to Issue #26526 above.  Needed further adjustments.
*
*
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int,  
   	@co bCompany, @mth bMonth, @billnum int, @line int, @jccdtrans bTrans,
	@billstatus tinyint, @billmth bMonth, @jbidseq int, @jbum bUM, @hours bHrs,
	@units bUnits, @seqsumopt tinyint, @markupopt char(1), @openbJBIJcursor int,
   	@purgeyn bYN, @JBIJaudityn bYN, @jbidum bUM, @priceopt char(1),
   	@jccdmatlgroup bGroup, @jccdmaterial bMatl, @jccdinco bCompany, @jccdloc bLoc,
   	@jccdcosttype bJCCType, @jccdphasegrp bGroup, @ctcategory char(1), 
   	@jctranstype char(2), @updateUPflag bYN, @updateUPtype char(1),
   	@conversion bUnitCost, @jbidunits bUnits, @jbidhrs bHrs, @jbidsubtotal numeric(15,5),
   	@jbidecm bECM, @jbidmatl bMatl, @emrcbasis char(1), @emgroup bGroup, @emrevcode bRevCode,
   	@addunitsYN bYN, @addhrsYN bYN, @calcUPflag char(1), @jbijcount int,
   	@Hbasiscount int, @Ubasiscount int, @ecmfactor smallint
   
-- @seq int, @amt bDollar, 

select @numrows = @@rowcount, @openbJBIJcursor = 0

if @numrows = 0 return
set nocount on

declare bJBIJ_insert cursor local fast_forward for
select i.JBCo, i.BillMonth, i.BillNumber, i.Line, i.Seq, i.JCMonth, i.JCTrans,
	i.BillStatus, i.UM, i.Hours, i.Units, i.AuditYN, i.Purge,
	c.MatlGroup, c.Material, c.INCo, c.Loc, c.CostType, c.PhaseGroup, 
	c.JCTransType, i.EMGroup, i.EMRevCode
from inserted i
join bJCCD c with (nolock) on c.JCCo = i.JBCo and c.Mth = i.JCMonth and c.CostTrans = i.JCTrans
   
open bJBIJ_insert
select @openbJBIJcursor = 1
   
fetch next from bJBIJ_insert into @co, @billmth, @billnum, @line, @jbidseq, @mth, @jccdtrans,
	@billstatus, @jbum, @hours, @units, @JBIJaudityn, @purgeyn,
	@jccdmatlgroup, @jccdmaterial, @jccdinco, @jccdloc, @jccdcosttype, @jccdphasegrp,
	@jctranstype, @emgroup, @emrevcode
while @@fetch_status = 0
	begin
	select @updateUPtype = 'Z', @updateUPflag = 'Y', 		-- reset flags
		@emrcbasis = null, @jbijcount = 0, @Hbasiscount = 0, @Ubasiscount = 0
   
   	/* If purge flag is set to 'Y', one condition exists.
   		1) Bill Lines or Detail sequences are being resequenced.  Since all values
   		   have already been established in all related tables, there is no need
   		   to perform trigger updates. */
   	if @purgeyn = 'Y' and @JBIJaudityn = 'N' 	-- Resequence operation
   		begin
   		if @openbJBIJcursor = 1
   			begin
   			close bJBIJ_insert
   			deallocate bJBIJ_insert
   			select @openbJBIJcursor = 0
   			end
   		return		
   		end
   
   	/* Obtain some values to use for further updates to other tables. */
   	select @jbijcount = count(*)
   	from bJBIJ with (nolock)
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   		and Line = @line and Seq = @jbidseq 
   		and (JCMonth <> @mth or (JCMonth = @mth and JCTrans <> @jccdtrans))
   
   	select @jbidum = d.UM, @jbidunits = d.Units, @jbidhrs = d.Hours, @jbidsubtotal = SubTotal,
   		@jbidecm = isnull(ECM, 'E'), @jbidmatl = Material
   	from bJBID d with (nolock)			
   	where d.JBCo = @co and d.BillMonth = @billmth and d.BillNumber = @billnum
   		and d.Line = @line and d.Seq = @jbidseq 
   
	select @ecmfactor = case isnull(@jbidecm, 1)
   					when 'E' then 1
   					when 'C' then 100
   					when 'M' then 1000 end
   	
   	select @seqsumopt = l.TemplateSeqSumOpt, @markupopt = l.MarkupOpt, @priceopt = s.PriceOpt
   	from bJBIL l with (nolock)
   	join bJBTS s with (nolock) on s.JBCo = l.JBCo and s.Template = l.Template and s.Seq = l.TemplateSeq
   	where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
   	  	and l.Line = @line
   
   	select @ctcategory = JBCostTypeCategory 
   	from bJCCT with (nolock)
   	where PhaseGroup = @jccdphasegrp and CostType = @jccdcosttype
   	if @ctcategory is not null
   		begin
   		if (@jctranstype = 'PR' and @ctcategory = 'E') 
   			or (@jctranstype = 'MS' and @ctcategory = 'E') select @jctranstype = 'EM'
   		end
   
   	if @emgroup is not null and @emrevcode is not null
   		begin
   		/* Get Basis for this Equipment transaction */
   		select @emrcbasis = Basis
   		from bEMRC with (nolock)
   		where EMGroup = @emgroup and RevCode = @emrevcode	
   		end
   
	/************************************** Update Evaluation Section **************************************/
   	/* Begin evaluation of How (UpdateUPType) we will be updating Units, Hours,
   	   and UnitPrice. It is different depending upon the type of transaction
   	   (JCTransType) that is being processed. 
   	
   		M) Material may need to be converted before updating to JBID for accuracy
   		L) Labor, currently no special conversion required.  Separated just in case. 
   		E) Equipment, requires more research and customer input to determine how to
   		   summarize this accurately.  Separated for future developement 
   		Z) All others.  Update as they have always done unless special request from users. */

   	if @jccdmaterial is null and @jctranstype in ('AP', /*'PO',*/ 'IN', 'MI', 'MS', 'MO', 'MT')
   		and @ctcategory = 'M'
   		begin	/* Begin NULL JCCD Material Type evaluation */
		if @seqsumopt = 1
			begin	
			select @updateUPtype = 'M'
			goto BeginUpdate
			end
		else
			begin
			select @updateUPflag = 'N'
			goto BeginUpdate
			end
		End		/* End NULL JCCD Material Type evaluation */

   	if @jccdmaterial is not null and @jctranstype in ('AP', /*'PO',*/ 'IN', 'MI', 'MS', 'MO', 'MT')
   		and @ctcategory = 'M'
   		begin	/* Begin Material Type evaluation */
   		select @updateUPtype = 'M'
   
   		if @jbijcount = 0
   			begin	/* Begin First J record */
   			if @jbidmatl is null
   				begin
   				/* UM, Units, UnitPrice, ECM will remain 0.00/null */
   				select @updateUPflag = 'N'
   				goto BeginUpdate
   				end
   			else
   				begin
   				/* First record update and Material values, UM, Units, UnitPrice,
   				   ECM, are valid and should be updated. */
   				select @updateUPflag = 'Y', @conversion = 1
   				goto BeginUpdate
   				end
   			end		/* End First J record */
   		else
   			begin	/* Begin J Count not Zero */
   			if @jbidum is null
   				begin
   				select @updateUPflag = 'N'
   				goto BeginUpdate	
   				end
   			else
   				begin	/* Begin @jbidum Not NULL */
   				if @jbum = @jbidum 	
   					begin
   					/* UMs are both the same and @jbidum is not null. */
   					select @updateUPflag = 'Y', @conversion = 1
   					goto BeginUpdate
   					end
   				else
   					begin	/* Begin UMs Different evaluation */
   					/* UMs are different and @jbidum is not null. */
   					If @priceopt = 'C'
   						begin
   						/* Can't really occur.  @jbidum would already be NULL, in 
   						   this case, having been set that way by bspJBTandMUpdateJBIDUnitPrice */
   						select @updateUPflag = 'N'
   						goto BeginUpdate	
   						end
   			
   					if @priceopt = 'P'
   						begin	
   						/* Get Converted UM conversion value.  It must exist otherwise @jbidum
   						   would already be set to NULL by bspJBTandMUpdateJBIDUnitPrice and we
   						   would not have gotten this far. */
   						select @conversion = u.Conversion
   						from bHQMU u with (nolock)
   						where u.MatlGroup = @jccdmatlgroup and u.Material = @jccdmaterial and u.UM = @jbum
   						if @conversion is null
   							begin
   							select @updateUPflag = 'N'
   							goto BeginUpdate	
   
   							end
   						else
   							begin
   							select @updateUPflag = 'Y'	-- @conversion retrieved above
   							goto BeginUpdate
   							end
   						end
   			
   					if @priceopt = 'L'
   						begin
   						/* Get Converted UM conversion value.  It must exist otherwise @jbidum
   						   would already be set to NULL by bspJBTandMUpdateJBIDUnitPrice and we
   						   would not have gotten this far. */
   						select @conversion = u.Conversion
   						from bINMU u with (nolock)
   						where u.MatlGroup = @jccdmatlgroup and u.Material = @jccdmaterial and u.UM = @jbum
   							and u.INCo = @jccdinco and u.Loc = @jccdloc
   						if @conversion is null
   							begin
   							select @conversion = u.Conversion
   							from bHQMU u with (nolock)
   							where u.MatlGroup = @jccdmatlgroup and u.Material = @jccdmaterial and u.UM = @jbum
   							if @conversion is null
   								begin
   								select @updateUPflag = 'N'
   								goto BeginUpdate	
   								end
   							else
   								begin
   								select @updateUPflag = 'Y'	-- @conversion retrieved above
   								goto BeginUpdate
   								end
   							end
   						end
   					end		/* End UMs Different evaluation */
   				end		/* End @jbidum Not NULL */
   			end		/* End J Count not Zero */
   		end		/* End Material Type evaluation */
   
   	if @jctranstype in ('PR') and @ctcategory = 'L'
   		begin	/* Begin Labor HRS evaluation */
   		select @updateUPtype = 'L'
   		select @updateUPflag = 'Y'
   		goto BeginUpdate	
   		end		/* End Labor HRS evaluation */
   	
   	if @jctranstype in ('EM',/*'MS', 'PR',*/ 'JC') and @ctcategory = 'E'	--<-- Most Always will be 'EM' 'E'
   		begin	/* Begin Equipment evaluation */
   		select @updateUPtype = 'E'
   
   		if @jbijcount = 0
   			begin
   			/* First record. Do the update as is. */
   			select @updateUPflag = 'Y', @addunitsYN = 'Y', @addhrsYN = 'Y', @calcUPflag = 'I' 
   			goto BeginUpdate
   			end
   		else
   			begin 	/* Begin J Count not Zero */
   			/* Equipment usage can be Hourly based or Unit based.  In each case below, JBID
   			   has already been preset (by procedure bspJBTandMUpdateJBIDUnitPrice) based upon 
   			   compatibility with this transaction.  Therefore at this point, we already
   			   know (by the condition of JBID), what the basis for this transaction is.  We 
   			   simply need to set update flags accordingly so that the update statement knows
   			   how to update. */
   	
   			/* #1 */
   			if @jbidunits = 0 and @jbidhrs = 0
   				begin	/* Begin JBID is Basis is unknown */
   				/* If JBID Units and Hours are both 0 then either JBID has been set by a transaction that 
   				   was based differently than others before it or, by bad luck and chance, the first two
   			 	   transactions to be processed canceled each other out.  In all cases, we really do not yet know
   				   if we are dealing with UnitBased or Hourly based!  JBIJ insert triggers will now need to
   				   evaluate the basis of this transaction compared to those already in JBIJ and 
   				   either update, if all are the same Basis, or not if the Basis's differ in anyway. */
 				select @Hbasiscount = Count(*)
 				from bJBIJ j with (nolock)
 				left join bEMRC e with (nolock) on e.EMGroup = j.EMGroup and e.RevCode = j.EMRevCode
 				where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum
 					and j.Line = @line and j.Seq = @jbidseq and (e.Basis = 'H' or j.EMRevCode is null)
 					and (j.JCMonth <> @mth or (j.JCMonth = @mth and j.JCTrans <> @jccdtrans))
   		
   				select @Ubasiscount = Count(*)
   				from bJBIJ j with (nolock)
   				join bEMRC e with (nolock) on e.EMGroup = j.EMGroup and e.RevCode = j.EMRevCode
   				where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum
   					and j.Line = @line and j.Seq = @jbidseq and e.Basis = 'U' and j.UM = @jbum 
   					and (j.JCMonth <> @mth or (j.JCMonth = @mth and j.JCTrans <> @jccdtrans))
   
   				if @emrcbasis = 'H' or @emrcbasis is null	--A Null EM RevCode is Hourly based
   					begin
   					if (@Hbasiscount = @jbijcount) and @jbidsubtotal = 0 
   						begin
   						/* Offsetting values:  All existing records are Hourly based.  Update Hourly Yes. */
   						select @updateUPflag = 'Y', @addunitsYN = 'N', @addhrsYN = 'Y', @calcUPflag = 'H'
   						goto BeginUpdate
   						end
   					else	
   						begin
   						/* This seq contains a mixed bag. Update No, leaving values at 0.00/null */
   						select @updateUPflag = 'N'
   						goto BeginUpdate
   						end
   					end
   
   				if @emrcbasis = 'U'
   					begin
   					if (@Ubasiscount = @jbijcount) and @jbidsubtotal = 0 
   						begin
   						/* Offsetting values:  All existing records are Unit based.  Update Units Yes. 
   						   Unfortunately (Unlike Hourly Based), there is no way to know the difference
   						   between whether JBID Units/Hrs are currently 0 because they were purposely
   						   set that way due to Mixed UM (or Mixed Hourly/Unit based) or if so because
   						   of the very unlikely possibility that transactions have been added in such
   						   a way leaving the exact combination of transactions that exactly cancel each
   						   other out.  In this case, it is highly unlikely that we had a mixed bag
   						   resulting in 0 and then the user deleted transactions leaving only the same
   						   type of transactions.  Therefore we will play the odds and allow the update
   						   as though all existing transaction are similar but canceling each out */
   						select @updateUPflag = 'Y', @addunitsYN = 'Y', @addhrsYN = 'N', @calcUPflag = 'U'
   						goto BeginUpdate
   						end
   					else	
   						begin
   						/* This seq contains a mixed bag. Update No, leaving values at 0.00/null */
   						select @updateUPflag = 'N'
   						goto BeginUpdate
   						end
   					end
   				end		/* End JBID is Basis is unknown */
   		
   			/* #2 */
   			if @jbidunits <> 0 and @jbidhrs = 0
   				begin	/* Begin JBID is UnitsBased */
   				select @updateUPflag = 'Y', @addunitsYN = 'Y', @addhrsYN = 'N', @calcUPflag = 'U' 
   				goto BeginUpdate		
   				end 	/* End JBID is UnitsBased */
   		
   			/* #3 */
   			if @jbidhrs <> 0 and @jbidunits = 0
   				begin	/* Begin JBID is Hours Based */
   				select @updateUPflag = 'Y', @addunitsYN = 'N', @addhrsYN = 'Y', @calcUPflag = 'H'
   				goto BeginUpdate
   				end  	/* End JBID is Hours Based */	
   		
   			/* #4 */
   			if @jbidhrs <> 0 and @jbidunits <> 0
   				begin	/* Begin JBID is TimeUnits Hours Based */
   				select @updateUPflag = 'Y', @addunitsYN = 'Y', @addhrsYN = 'Y', @calcUPflag = 'U'
   				goto BeginUpdate	
   				end		/* End JBID is TimeUnits Hours Based */
   			end 	/* End J Count not Zero */			
   		end		/* End Equipment evaluation */
   
   /************************************** UPDATE SECTION **************************************************/	
   BeginUpdate:
   	update bJCCD 
   	set JBBillStatus = @billstatus, JBBillNumber = @billnum,
   	  JBBillMonth = @billmth
   	from bJCCD d 
   	where JCCo = @co and Mth = @mth and CostTrans = @jccdtrans
   	if @@rowcount = 0
   	    begin
   	    select @errmsg = 'Error updating JCCD'
   	    goto error
   	    end
   
   	/* The Update statement appears complex and needs to be. Break it down to individual
   	   operations when evaluating it.  The isnull() function is in place because there are 
   	   times when the Update for a particular field is to be ignored or left alone.  In
   	   these instances, the isnull() function will simply put back in what already exists. */	
   	update bJBID 
   	set Hours = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   					when 'M' then j.Hours + i.Hours		-- Not Necessary, left for consistency
   					when 'L' then j.Hours + i.Hours
   					when 'E' then case @addhrsYN when 'Y' then j.Hours + i.Hours end	
   					else j.Hours + i.Hours end			-- Should be 0 + 0
   				end),j.Hours),
   	  	Units = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   					when 'M' then j.Units + (i.Units * isnull(@conversion,1))
   					when 'L' then j.Units + i.Units		-- Not Necessary, left for consistency
   					when 'E' then case @addunitsYN when 'Y' then j.Units + i.Units end
   					else j.Units + i.Units end			-- Should be 0 + 0
   				end),j.Units),
   		UnitPrice = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   					when 'M' then case when (j.Units + (i.Units * isnull(@conversion,1))) = 0 then 0			 
   							else ((j.SubTotal + i.Amt)/(j.Units + (i.Units * isnull(@conversion,1)))) * @ecmfactor end		
   					when 'L' then case when (j.Hours + i.Hours) = 0 then 0
   							else (j.SubTotal + i.Amt)/(j.Hours + i.Hours) end
   					when 'E' then case isnull(@emrcbasis,'')
   						when 'U' then case @calcUPflag 
   							when 'U' then case when (j.Units + i.Units) = 0 then 0 
   								else ((j.SubTotal + i.Amt)/(j.Units + i.Units)) * @ecmfactor end 	-- @ecmfactor always 1 here
   							when 'I' then i.UnitPrice end
   						when 'H' then case @calcUPflag
   							when 'H' then case when (j.Hours + i.Hours) = 0 then 0 
   								else (j.SubTotal + i.Amt)/(j.Hours + i.Hours) end
   							when 'U' then case when (j.Units + i.Units) = 0 then 0 
   								else ((j.SubTotal + i.Amt)/(j.Units + i.Units)) * @ecmfactor end 	-- @ecmfactor always 1 here
   							when 'I' then i.UnitPrice end
   						when '' then case @calcUPflag
   							when 'H' then case when (j.Hours + i.Hours) = 0 then 0 
   								else (j.SubTotal + i.Amt)/(j.Hours + i.Hours) end
   							when 'I' then i.UnitPrice end
   						end									
   					else i.UnitPrice end				-- Should be 0
   				end),j.UnitPrice), 	
   	  	SubTotal = j.SubTotal + i.Amt,
     		MarkupTotal = isnull((case @markupopt when 'U' then 
   						case @updateUPflag when 'Y' then case @updateUPtype
   					when 'M' then (j.MarkupRate * (j.Units + (i.Units * isnull(@conversion,1)))) + j.MarkupAddl
   					when 'E' then case @addunitsYN when 'Y' then (j.MarkupRate * (j.Units + i.Units)) + j.MarkupAddl end
   					else (j.MarkupRate * (j.Units + i.Units)) + j.MarkupAddl end
   				end
   			else (j.MarkupRate * (j.SubTotal + i.Amt)) + j.MarkupAddl end),j.MarkupTotal),
     		Total = isnull(((j.SubTotal + i.Amt) + case @markupopt when 'U' then 
   						case @updateUPflag when 'Y' then case @updateUPtype
   					when 'M' then ((j.MarkupRate * (j.Units + (i.Units * isnull(@conversion,1)))) + j.MarkupAddl)
   					when 'E' then case @addunitsYN when 'Y' then ((j.MarkupRate * (j.Units + i.Units)) + j.MarkupAddl) end
   					else ((j.MarkupRate * (j.Units + i.Units)) + j.MarkupAddl) end
   				end
   			else ((j.MarkupRate * (j.SubTotal + i.Amt)) + j.MarkupAddl) end),j.Total),
   	  	AuditYN = 'N', 
   		JCMonth = case when @seqsumopt = 1 then @mth else null end, 
   		JCTrans = case when @seqsumopt = 1 then @jccdtrans else null end
   	from bJBID j 
   	join inserted i on i.JBCo = j.JBCo and i.BillMonth = j.BillMonth 
   		and i.BillNumber = j.BillNumber and i.Line = j.Line and i.Seq = j.Seq 
   	where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum 
   		and j.Line = @line and j.Seq = @jbidseq and i.JCMonth = @mth 
   		and i.JCTrans = @jccdtrans and i.BillStatus = 1
   	
   	update bJBID 
   	set AuditYN = 'Y'
   	from bJBID j 
   	join inserted i on i.JBCo = j.JBCo and i.BillMonth = j.BillMonth 
   		and i.BillNumber = j.BillNumber and i.Line = j.Line and i.Seq = j.Seq
   	where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum 
   		and j.Line = @line and j.Seq = @jbidseq and i.JCMonth = @mth 
   		and i.JCTrans = @jccdtrans and i.BillStatus = 1
   
   	fetch next from bJBIJ_insert into @co, @billmth, @billnum, @line, @jbidseq, @mth, @jccdtrans,
   		@billstatus, @jbum, @hours, @units, @JBIJaudityn, @purgeyn,
   		@jccdmatlgroup, @jccdmaterial, @jccdinco, @jccdloc, @jccdcosttype, @jccdphasegrp,
   		@jctranstype, @emgroup, @emrevcode
   	end
   
   if @openbJBIJcursor = 1
   	begin
   	close bJBIJ_insert
   	deallocate bJBIJ_insert
   	select @openbJBIJcursor = 0
   	end
   
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   /*
   select @co = min(JBCo) from inserted i
   while @co is not null
   	begin
   	select @billmth = min(BillMonth) 
   	from inserted i 
   	where JBCo = @co
   	while @billmth is not null
       	begin
       	select @billnum = min(BillNumber) 
   		from inserted i 
   		where JBCo = @co and BillMonth = @billmth
        	while @billnum is not null
           	begin
           	select @mth = min(JCMonth) 
   			from inserted i 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
            	while @mth is not null
              		begin
                   select @jccdtrans = min(JCTrans) 
   				from inserted i 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
                   	and JCMonth = @mth
                   while @jccdtrans is not null
   					begin
   					select @billstatus = BillStatus, @hours = Hours, @units = Units
   					from inserted 
   					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   					  	and JCMonth = @mth and JCTrans = @jccdtrans
   
   					select @line = Line, @jbidseq = Seq 
   					from inserted 
   					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   					  	and JCMonth = @mth and JCTrans = @jccdtrans
   
                       select @jccdtrans = min(JCTrans) 
   					from inserted i 
   					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
                         	and JCMonth = @mth and JCTrans > @jccdtrans
                       if @@rowcount = 0 select @jccdtrans = null
                       end
   
                   select @mth = min(JCMonth) 
   				from inserted i 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
                     	and JCMonth > @mth
                   if @@rowcount = 0 select @mth = null
                   end
   
          		select @billnum = min(BillNumber) 
   			from inserted i 
   			where JBCo = @co and BillMonth = @billmth and BillNumber > @billnum
             	if @@rowcount = 0 select @billnum = null
            	end
   
        	select @billmth = min(BillMonth) 
   		from inserted i 
   		where JBCo = @co and BillMonth > @billmth
        	if @@rowcount = 0 select @billmth = null
         	end
   
   	select @co = min(JBCo) 
   	from inserted i 
   	where JBCo > @co
   	if @@rowcount = 0 select @co = null
   	end
   */
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   
   /*Issue 13667*/
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   Select 'bJBIJ', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + isnull(convert(varchar(10),i.Line),'') + 'Seq: ' + isnull(convert(varchar(10),i.Seq),'') + 'JCMonth: ' + convert(varchar(8),i.JCMonth,1) + 'JCTrans: ' + convert(varchar(10),i.JCTrans),i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME()
   From inserted i
   Join bJBCO c with (nolock) on c.JBCo = i.JBCo
   Where c.AuditBills = 'Y' and i.AuditYN = 'Y'
   
   return
   
   error:
   select @errmsg = @errmsg + ' - cannot insert JBIJ!'
   
   if @openbJBIJcursor = 1
   	begin
   	close bJBIJ_insert
   	deallocate bJBIJ_insert
   	select @openbJBIJcursor = 0
   	end
   
   RAISERROR(@errmsg, 11, -1);
   
   rollback transaction
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE TRIGGER [dbo].[btJBIJu] ON [dbo].[bJBIJ]
FOR UPDATE AS

/**************************************************************
*	This trigger rejects update of bJBIJ
*	 if the following error condition exists:
*		none
*
*  Created by: kb 5/15/00
*  Modified by: kb 10/8/1 - issue #14841
* 		ALLENN 11/16/2001 Issue #13667
*		kb 11/27/1 - issue #15395
*		kb 12/11/1 - issue #15395
*     	kb 2/19/2 - issue #16147
*    	kb 4/14/2 - issue #16560
*    	kb 5/1/2 - issue #17095
* 		kb 7/22/2 - issue #18038 - only update billstatus is it is different then what it was before
*		TJL 09/06/02 - Issue #18053, Rounding error during Bill Status #2 updates
*		TJL 09/09/02 - Issue #17620, Correct Source MarkupOpt when 'U' use Rate * Units
*		TJL 11/06/02 - Issue #18740, Exit if (Purge) Column is updated
*		TJL 02/11/03 - Issue #20298, REM'd 'and BillStatus <> 2' from Update bJBIJ 
*		RBT 08/05/03 - Issue #22019, In auditing, convert bDollar and bUnits vars to varchar(13) not 9.
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 05/14/04 - Issue #22526, Accurately accumulate JBID UM, Units, UnitPrice, ECM.  Phase #1
*		TJL 06/24/04 - Issue #24915, Increase Accuracy of JBID.SubTotal
*		TJL 12/14/04 - Issue #26526, Treat EM Equip transactions as Hourly based when RevCode is NULL
*		TJL 09/14/06 - Issue #122403, Show UM, Units, UnitPrice, ECM for NULL Material when SummaryOpt = 1 (Full Detail)
*		TJL 09/28/06 - Issue #28232, 6x Recode.  BillStatus not recorded in HQMA when changed in JBTMBillAllJCDetail form.
*		TJL 10/09/06 - Issue #122360, Related to Issue #26526 above.  Needed further adjustments.
*		TJL 03/26/10 - Issue #138014, JBID amounts get updated when Billable set 'N' then 'Y' consequetively without saving record in between
*	
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int,
   	@jbidseq int, @co bCompany, @mth bMonth, @billnum int, @line int, @billmth bMonth,
	@billstatus tinyint, @jctrans bTrans, @markupopt char(1), @delline int, @delseq int,
   	@openbJBIJcursor int, @oldbillstatus tinyint
   
declare @jbum bUM, @hours bHrs, @units bUnits, @jbidum bUM, @priceopt char(1),
	@jccdmatlgroup bGroup, @jccdmaterial bMatl, @jccdinco bCompany, @jccdloc bLoc,
	@jccdcosttype bJCCType, @jccdphasegrp bGroup, @ctcategory char(1), 
	@jctranstype char(2), @updateUPflag bYN, @updateUPtype char(1),
	@conversion bUnitCost, @jbidunits bUnits, @jbidhrs bHrs, @jbidsubtotal numeric(15,5),
	@jbidecm bECM, @emrcbasis char(1), @emgroup bGroup, @emrevcode bRevCode,
	@deladdunitsYN bYN, @deladdhrsYN bYN, @calcUPflag char(1), @jbijcount int,
	@Hbasiscount int, @Ubasiscount int, @ecmfactor smallint, @seqsumopt tinyint

select @numrows = @@rowcount, @openbJBIJcursor = 0

if @numrows = 0 return
set nocount on
    
/*Issue 13667*/
If Update(Purge)
	begin
	return
	end
   
/* The following updates can never occur due to form restrictions.  The
  only updateable fields in JBIJ are BillStatus (by the user) and PurgeYN,
  AuditYN (During processing and bill deletes). */ 
If Update(JBCo)
	Begin
	select @errmsg = 'Cannot change JBCo'
	GoTo error
	End

If Update(BillMonth)
	Begin
	select @errmsg = 'Cannot change BillMonth'
	GoTo error
	End

If Update(BillNumber)
	Begin
	select @errmsg = 'Cannot change BillNumber'
	GoTo error
	End

If Update(JCMonth)
	Begin
	select @errmsg = 'Cannot change JCMonth'
	GoTo error
	End

If Update(JCTrans)
	Begin
	select @errmsg = 'Cannot change JCTrans'
	GoTo error
	End

declare bJBIJ_insert cursor local fast_forward for
select i.JBCo, i.BillMonth, i.BillNumber, i.Line, i.Seq, i.JCMonth, i.JCTrans,
	i.BillStatus, i.UM, i.Hours, i.Units,
	c.MatlGroup, c.Material, c.INCo, c.Loc, c.CostType, c.PhaseGroup, 
	c.JCTransType, i.EMGroup, i.EMRevCode, d.BillStatus
from inserted i
join deleted d with (nolock) on i.JBCo = d.JBCo and i.BillMonth = d.BillMonth and i.BillNumber = d.BillNumber
	and i.JCMonth = d.JCMonth and i.JCTrans = d.JCTrans	
join bJCCD c with (nolock) on c.JCCo = i.JBCo and c.Mth = i.JCMonth and c.CostTrans = i.JCTrans

open bJBIJ_insert
select @openbJBIJcursor = 1
   
fetch next from bJBIJ_insert into @co, @billmth, @billnum, @line, @jbidseq, @mth, @jctrans,
   	@billstatus, @jbum, @hours, @units,
   	@jccdmatlgroup, @jccdmaterial, @jccdinco, @jccdloc, @jccdcosttype, @jccdphasegrp,
   	@jctranstype, @emgroup, @emrevcode, @oldbillstatus
while @@fetch_status = 0
   	begin
   	select @updateUPtype = 'Z', @updateUPflag = 'Y',		-- reset flags
   		@emrcbasis = null, @jbijcount = 0, @Hbasiscount = 0, @Ubasiscount = 0
   
   	if update(BillStatus) and @billstatus <> @oldbillstatus 
   		begin
   		/* If this transaction has just been flagged as Non-Billable, then JBIJ Line and Seq
   		   have already been set to NULL by the form.  Therefore we must reset these variables 
   		   based upon the deleted record rather than the inserted record. */
   	 	select @delline = Line, @delseq = Seq
   	  	from deleted  d 
   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
   			and JCMonth = @mth and JCTrans = @jctrans
   		if @billstatus = 2
   			begin
   			select @line = @delline, @jbidseq = @delseq
   			end
   
   		/* Obtain some values to use for further updates to other tables. */
   		select @jbijcount = count(*)
   		from bJBIJ with (nolock)
   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   			and Line = @line and Seq = @jbidseq 
   			and (JCMonth <> @mth or (JCMonth = @mth and JCTrans <> @jctrans))
    				
   		select @jbidum = d.UM, @jbidunits = d.Units, @jbidhrs = d.Hours, @jbidsubtotal = SubTotal,
   			@jbidecm = isnull(ECM, 'E')
   		from bJBID d with (nolock)			
   		where d.JBCo = @co and d.BillMonth = @billmth and d.BillNumber = @billnum
   			and d.Line = @line and d.Seq = @jbidseq 
   
   		select @ecmfactor = case isnull(@jbidecm, 1)
   						when 'E' then 1
   						when 'C' then 100
   						when 'M' then 1000 end
    
   		select @seqsumopt = l.TemplateSeqSumOpt, @markupopt = l.MarkupOpt, @priceopt = s.PriceOpt
   		from bJBIL l with (nolock)
   		join bJBTS s with (nolock) on s.JBCo = l.JBCo and s.Template = l.Template and s.Seq = l.TemplateSeq
   		where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
   		  	and l.Line = @line
   
   		select @ctcategory = JBCostTypeCategory 
   		from bJCCT with (nolock)
   		where PhaseGroup = @jccdphasegrp and CostType = @jccdcosttype
   		if @ctcategory is not null
   			begin
   			if (@jctranstype = 'PR' and @ctcategory = 'E') 
   				or (@jctranstype = 'MS' and @ctcategory = 'E') select @jctranstype = 'EM'
   			end
   
   		if @emgroup is not null and @emrevcode is not null
   			begin
   			/* Get Basis for this Equipment transaction */
   			select @emrcbasis = Basis
   			from bEMRC with (nolock)
   			where EMGroup = @emgroup and RevCode = @emrevcode
   			end	
   
   	/************************************** Update Evaluation Section **************************************/
   		/* Begin evaluation of How (UpdateUPType) we will be updating Units, Hours,
   		   and UnitPrice. It is different depending upon the type of transaction
   		   (JCTransType) that is being processed. 
   		
   			M) Material may need to be converted before updating to JBID for accuracy
   			L) Labor, currently no special conversion required.  Separated just in case. 
   			E) Equipment, requires more research and customer input to determine how to
   			   summarize this accurately.  Separated for future developement 
   			Z) All others.  Update as they have always done unless special request from users. */

   		if @jccdmaterial is null and @jctranstype in ('AP', /*'PO',*/ 'IN', 'MI', 'MS', 'MO', 'MT')
   			and @ctcategory = 'M'
   			begin	/* Begin NULL JCCD Material Type evaluation */
			if @seqsumopt = 1
				begin	
				select @updateUPtype = 'M'
				goto BeginUpdate
				end
			else
				begin
				select @updateUPflag = 'N'
				goto BeginUpdate
				end
			End		/* End NULL JCCD Material Type evaluation */

   		if @jccdmaterial is not null and @jctranstype in ('AP', /*'PO',*/ 'IN', 'MI', 'MS', 'MO', 'MT')
   			and @ctcategory = 'M'
   			begin	/* Begin Material Type evaluation */
   			select @updateUPtype = 'M'
   	
   			if @jbidum is null
   				begin
   				select @updateUPflag = 'N'
   				goto BeginUpdate	
   				end
   			else
   				begin	/* Begin @jbidum Not NULL */
   				if @jbum = @jbidum 	
   					begin
   					/* UMs are both the same and @jbidum is not null. */
   					select @updateUPflag = 'Y', @conversion = 1
   					goto BeginUpdate
   					end
   				else
   					begin	/* Begin UMs Different evaluation */
   					/* UMs are different and @jbidum is not null. */
   					If @priceopt = 'C'
   						begin
   						/* Can't really occur.  @jbidum would already be NULL, in 
   						   this case, having been set that way by bspJBTandMUpdateJBIDUnitPrice */
   						select @updateUPflag = 'N'
   						goto BeginUpdate	
   						end
   			
   					if @priceopt = 'P'
   						begin	
   						/* Get Converted UM conversion value.  It must exist otherwise @jbidum
   						   would already be set to NULL by bspJBTandMUpdateJBIDUnitPrice and we
   						   would not have gotten this far. */
   						select @conversion = u.Conversion
   						from bHQMU u with (nolock)
   						where u.MatlGroup = @jccdmatlgroup and u.Material = @jccdmaterial and u.UM = @jbum
   						if @conversion is null
   							begin
   							select @updateUPflag = 'N'
   							goto BeginUpdate	
   							end
   						else
   							begin
   							select @updateUPflag = 'Y'	-- @conversion retrieved above
   							goto BeginUpdate
   							end
   						end
   			
   					if @priceopt = 'L'
   						begin
   						/* Get Converted UM conversion value.  It must exist otherwise @jbidum
   						   would already be set to NULL by bspJBTandMUpdateJBIDUnitPrice and we
   						   would not have gotten this far. */
   						select @conversion = u.Conversion
   						from bINMU u with (nolock)
   						where u.MatlGroup = @jccdmatlgroup and u.Material = @jccdmaterial and u.UM = @jbum
   							and u.INCo = @jccdinco and u.Loc = @jccdloc
   						if @conversion is null
   							begin
   							select @conversion = u.Conversion
   							from bHQMU u with (nolock)
   							where u.MatlGroup = @jccdmatlgroup and u.Material = @jccdmaterial and u.UM = @jbum
   							if @conversion is null
   								begin
   								select @updateUPflag = 'N'
   								goto BeginUpdate	
   								end
   							else
   								begin
   								select @updateUPflag = 'Y'	-- @conversion retrieved above
   								goto BeginUpdate
   								end
   							end
   						end
   					end		/* End UMs Different evaluation */
   				end		/* End @jbidum Not NULL */
   			end		/* End Material Type evaluation */
   	
   		if @jctranstype in ('PR') and @ctcategory = 'L'
   			begin	/* Begin Labor HRS evaluation */
   			select @updateUPtype = 'L'
   			select @updateUPflag = 'Y'	
   			goto BeginUpdate	
   			end		/* End Labor HRS evaluation */
   		
   		if @jctranstype in ('EM',/* 'MS', 'PR',*/ 'JC') and @ctcategory = 'E'	--<-- Most Always will be 'EM' 'E'
   			begin	/* Begin Equipment evaluation */
   			select @updateUPtype = 'E'
   	
   			/* Equipment usage can be Hourly based or Unit based.  In each case below, JBID
   			   has already been preset (by procedure bspJBTandMUpdateJBIDUnitPrice) based upon 
   			   compatibility with this transaction.  Therefore at this point, we already
   			   know (by the condition of JBID), what the basis for this transaction is.  We 
   			   simply need to set update flags accordingly so that the update statement knows
   			   how to update. */
   	
   			/* #1 */
   			if @jbidunits = 0 and @jbidhrs = 0
   				begin	/* Begin JBID is Basis is unknown */
   				/* If JBID Units and Hours are both 0 then either JBID has been set by a transaction that 
   				   was based differently than others before it or, by bad luck and chance, the first two
   			 	   transactions to be processed canceled each other out.  In all cases, we really do not yet know
   				   if we are dealing with UnitBased or Hourly based!  JBIJ insert triggers will now need to
   				   evaluate the basis of this transaction compared to those already in JBIJ and 
   				   either update, if all are the same Basis, or not if the Basis's differ in anyway. */
 				select @Hbasiscount = Count(*)
 				from bJBIJ j with (nolock)
 				left join bEMRC e with (nolock) on e.EMGroup = j.EMGroup and e.RevCode = j.EMRevCode
 				where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum
 					and j.Line = @line and j.Seq = @jbidseq and (e.Basis = 'H' or j.EMRevCode is null)
 					and (j.JCMonth <> @mth or (j.JCMonth = @mth and j.JCTrans <> @jctrans))
   		
   				select @Ubasiscount = Count(*)
   				from bJBIJ j with (nolock)
   				join bEMRC e with (nolock) on e.EMGroup = j.EMGroup and e.RevCode = j.EMRevCode
   				where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum
   					and j.Line = @line and j.Seq = @jbidseq and e.Basis = 'U' and j.UM = @jbum 
   					and (j.JCMonth <> @mth or (j.JCMonth = @mth and j.JCTrans <> @jctrans))
   
   				if @emrcbasis = 'H' or @emrcbasis is null	--A Null EM RevCode is Hourly based 
   					begin
   					if (@Hbasiscount = @jbijcount) and @jbidsubtotal = 0 
   						begin
   						/* Offsetting values:  All existing records are Hourly based.  Update Hourly Yes */
   						select @updateUPflag = 'Y', @deladdunitsYN = 'N', @deladdhrsYN = 'Y', @calcUPflag = 'H'
   						goto BeginUpdate
   						end
   					else	
   						begin
   						/* This seq contains a mixed bag. Update No, leaving values at 0.00/null */
   						select @updateUPflag = 'N'
   						goto BeginUpdate
   						end
   					end
   
   				if @emrcbasis = 'U'
   					begin
   					/* Unfortunately (Unlike Hourly Based), there is no way to know the difference
   					   between whether JBID Units/Hrs are currently 0 because they were purposely
   					   set that way due to Mixed UM (or Mixed Hourly/Unit based) or if so because
   					   of the very unlikely possibility that transactions have been marked billableYN in 
   					   such a way leaving the exact combination of transactions that exactly cancel each
   					   other out.  Therefore we will play the odds and once 0, they will remain that
   					   way. */
   					select @updateUPflag = 'N'
   					goto BeginUpdate
   					end
   				end		/* End JBID is Basis is unknown */
   	
   			/* #2 */
   			if @jbidunits <> 0 and @jbidhrs = 0
   				begin	/* Begin JBID is UnitsBased */
   				select @updateUPflag = 'Y', @deladdunitsYN = 'Y', @deladdhrsYN = 'N', @calcUPflag = 'U' 
   				goto BeginUpdate		
   				end 	/* End JBID is UnitsBased */
   		
   			/* #3 */
   			if @jbidhrs <> 0 and @jbidunits = 0
   				begin	/* Begin JBID is Hours Based */
   				select @updateUPflag = 'Y', @deladdunitsYN = 'N', @deladdhrsYN = 'Y', @calcUPflag = 'H'
   				goto BeginUpdate
   				end  	/* End JBID is Hours Based */	
   		
   			/* #4 */
   			if @jbidhrs <> 0 and @jbidunits <> 0
   				begin	/* Begin JBID is TimeUnits Hours Based */
   				select @updateUPflag = 'Y', @deladdunitsYN = 'Y', @deladdhrsYN = 'Y', @calcUPflag = 'U'
   				goto BeginUpdate	
   				end		/* End JBID is TimeUnits Hours Based */
   	
   			end		/* End Equipment evaluation */
   
   /************************************** UPDATE SECTION **************************************************/	
   	BeginUpdate:
   
   		if @billstatus = 2		--in (0,2)
			begin
   			update bJCCD 
   			set JBBillStatus = 2 
   			where JCCo = @co and Mth = @mth and CostTrans = @jctrans
   				and JBBillStatus <> @billstatus
   
   			/* The Update statement appears complex and needs to be. Break it down to individual
   			   operations when evaluating it.  The isnull() function is in place because there are 
   			   times when the Update for a particular field is to be ignored or left alone.  In
   			   these instances, the isnull() function will simply put back in what already exists. */
   	  		update bJBID 
   			Set Hours = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   						when 'M' then j.Hours - d.Hours			-- Not Necessary, left for consistency
   						when 'L' then j.Hours - d.Hours
   						when 'E' then case @deladdhrsYN when 'Y' then j.Hours - d.Hours end	
   						else j.Hours - d.Hours end				-- Should be 0 - 0
   					end),j.Hours),
   		  		Units = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   						when 'M' then j.Units - (d.Units * isnull(@conversion,1))
   						when 'L' then j.Units - d.Units			-- Not Necessary, left for consistency
   						when 'E' then case @deladdunitsYN when 'Y' then j.Units - d.Units end
   						else j.Units - d.Units end				-- Should be 0 - 0
   					end),j.Units),
   				UnitPrice = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   						when 'M' then case when (j.Units - (d.Units * isnull(@conversion,1))) = 0 then 0
   								else ((j.SubTotal - d.Amt)/(j.Units - (d.Units * isnull(@conversion,1)))) * @ecmfactor end
   						when 'L' then case when (j.Hours - d.Hours) = 0 then 0 
   								else (j.SubTotal - d.Amt)/(j.Hours - d.Hours) end
   						when 'E' then case isnull(@emrcbasis,'')
   							when 'U' then case @calcUPflag 
   								when 'U' then case when (j.Units - d.Units) = 0 then 0 
   									else ((j.SubTotal - d.Amt)/(j.Units - d.Units)) * @ecmfactor end end	-- @ecmfactor always 1 here
   							when 'H' then case @calcUPflag
   								when 'H' then case when (j.Hours - d.Hours) = 0 then 0 
   									else (j.SubTotal - d.Amt)/(j.Hours - d.Hours) end
   								when 'U' then case when (j.Units - d.Units) = 0 then 0 
   									else ((j.SubTotal - d.Amt)/(j.Units - d.Units)) * @ecmfactor end end	-- @ecmfactor always 1 here
   							when '' then case @calcUPflag
   								when 'H' then case when (j.Hours - d.Hours) = 0 then 0 
   									else (j.SubTotal - d.Amt)/(j.Hours - d.Hours) end end
   							end									
   						else d.UnitPrice end					-- Should be 0
   					end),j.UnitPrice), 
   	     		SubTotal = j.SubTotal - d.Amt,
   		  		MarkupTotal = isnull((case @markupopt when 'U' then 
   								case @updateUPflag when 'Y' then case @updateUPtype
   							when 'M' then (j.MarkupRate * (j.Units - (d.Units * isnull(@conversion,1)))) + j.MarkupAddl
   							when 'E' then case @deladdunitsYN when 'Y' then (j.MarkupRate * (j.Units - d.Units)) + j.MarkupAddl end
   							else (j.MarkupRate * (j.Units - d.Units)) + j.MarkupAddl end
   						end
   					else (j.MarkupRate * (j.SubTotal - d.Amt)) + j.MarkupAddl end),j.MarkupTotal),
   		  		Total = isnull(((j.SubTotal - d.Amt) + case @markupopt when 'U' then 
   								case @updateUPflag when 'Y' then case @updateUPtype
   							when 'M' then ((j.MarkupRate * (j.Units - (d.Units * isnull(@conversion,1)))) + j.MarkupAddl)
   							when 'E' then case @deladdunitsYN when 'Y' then ((j.MarkupRate * (j.Units - d.Units)) + j.MarkupAddl) end
   							else ((j.MarkupRate * (j.Units - d.Units)) + j.MarkupAddl) end
   						end
   					else ((j.MarkupRate * (j.SubTotal - d.Amt)) + j.MarkupAddl) end),j.Total),
   				AuditYN = 'N'
			from bJBID j 
   			join deleted d on d.JBCo = j.JBCo and d.BillMonth = j.BillMonth 
   				and d.BillNumber = j.BillNumber and d.Line = j.Line and d.Seq = j.Seq
			where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum
               	and j.Line = @line and j.Seq = @jbidseq and d.JCMonth = @mth 
   				and d.JCTrans = @jctrans
   
			update bJBID 
   			set AuditYN = 'Y'
			from bJBID j 
   			join deleted d on d.JBCo = j.JBCo and d.BillMonth = j.BillMonth 
   				and d.BillNumber = j.BillNumber and d.Line = j.Line and d.Seq = j.Seq
			where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum
               	and j.Line = @line and j.Seq = @jbidseq and d.JCMonth = @mth 
   				and d.JCTrans = @jctrans
   
   			/* If the transaction has just been added manually (or automatically) and if the 
   			   transaction is flagged as Non-Billable then, at this moment, there is a Line/Seq
   			   value that must be set to NULL now.  (This is different than a 
   			   transaction that already exists and whos Bill Status is just now being
   			   set to Non-Billable using the form checkbox)
   
   			   To always show transactions in JBTMJCDetail Form, rem updates
   			   to bJBIJ below. (Also See btJBIJd) */
			update bJBIJ 
   			set Line = null, Seq = null, AuditYN = 'N'
   			from bJBIJ 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
   				and JCMonth = @mth and JCTrans = @jctrans  --and BillStatus <> 2	REM'D Issue #20298
                                 
   			update bJBIJ 
   			set AuditYN = 'Y'
   			from bJBIJ 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
   				and JCMonth = @mth and JCTrans = @jctrans 
    
           	end
    
		if @billstatus =1
			begin
 			update bJCCD 
			set JBBillStatus = 1 
			where JCCo = @co and Mth = @mth and CostTrans = @jctrans 
				and JBBillStatus <> 1
   
   			/* The Update statement appears complex and needs to be. Break it down to individual
   			   operations when evaluating it.  The isnull() function is in place because there are 
   			   times when the Update for a particular field is to be ignored or left alone.  In
   			   these instances, the isnull() function will simply put back in what already exists. */	
   			update bJBID 
   			set Hours = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   							when 'M' then j.Hours + i.Hours		-- Not Necessary, left for consistency
   							when 'L' then j.Hours + i.Hours
   							when 'E' then case @deladdhrsYN when 'Y' then j.Hours + i.Hours end	
   							else j.Hours + i.Hours end			-- Should be 0 + 0
   						end),j.Hours),
   			  	Units = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   							when 'M' then j.Units + (i.Units * isnull(@conversion,1))
   							when 'L' then j.Units + i.Units		-- Not Necessary, left for consistency
   							when 'E' then case @deladdunitsYN when 'Y' then j.Units + i.Units end
   							else j.Units + i.Units end			-- Should be 0 + 0
   						end),j.Units),
   				UnitPrice = isnull((case @updateUPflag when 'Y' then case @updateUPtype
   							when 'M' then case when (j.Units + (i.Units * isnull(@conversion,1))) = 0 then 0
   									else ((j.SubTotal + i.Amt)/(j.Units + (i.Units * isnull(@conversion,1)))) * @ecmfactor end
   							when 'L' then case when (j.Hours + i.Hours) = 0 then 0
   									else (j.SubTotal + i.Amt)/(j.Hours + i.Hours) end
   							when 'E' then case isnull(@emrcbasis,'')
   								when 'U' then case @calcUPflag 
   									when 'U' then case when (j.Units + i.Units) = 0 then 0 
   										else ((j.SubTotal + i.Amt)/(j.Units + i.Units)) * @ecmfactor end	-- @ecmfactor always 1 here 
   									when 'I' then i.UnitPrice end
   								when 'H' then case @calcUPflag
   									when 'H' then case when (j.Hours + i.Hours) = 0 then 0 
   										else (j.SubTotal + i.Amt)/(j.Hours + i.Hours) end
   									when 'U' then case when (j.Units + i.Units) = 0 then 0 
   										else ((j.SubTotal + i.Amt)/(j.Units + i.Units)) * @ecmfactor end	-- @ecmfactor always 1 here 
   									when 'I' then i.UnitPrice end
   								when '' then case @calcUPflag
   									when 'H' then case when (j.Hours + i.Hours) = 0 then 0 
   										else (j.SubTotal + i.Amt)/(j.Hours + i.Hours) end
   									when 'I' then i.UnitPrice end
   								end									
   							else i.UnitPrice end				-- Should be 0
   						end),j.UnitPrice), 	
   			  	SubTotal = j.SubTotal + i.Amt,
   		  		MarkupTotal = isnull((case @markupopt when 'U' then 
   								case @updateUPflag when 'Y' then case @updateUPtype
   							when 'M' then (j.MarkupRate * (j.Units + (i.Units * isnull(@conversion,1)))) + j.MarkupAddl
   							when 'E' then case @deladdunitsYN when 'Y' then (j.MarkupRate * (j.Units + i.Units)) + j.MarkupAddl end
   							else (j.MarkupRate * (j.Units + i.Units)) + j.MarkupAddl end
   						end
   					else (j.MarkupRate * (j.SubTotal + i.Amt)) + j.MarkupAddl end),j.MarkupTotal),
   		  		Total = isnull(((j.SubTotal + i.Amt) + case @markupopt when 'U' then 
   								case @updateUPflag when 'Y' then case @updateUPtype
   							when 'M' then ((j.MarkupRate * (j.Units + (i.Units * isnull(@conversion,1)))) + j.MarkupAddl)
   							when 'E' then case @deladdunitsYN when 'Y' then ((j.MarkupRate * (j.Units + i.Units)) + j.MarkupAddl) end
   							else ((j.MarkupRate * (j.Units + i.Units)) + j.MarkupAddl) end
   						end
   					else ((j.MarkupRate * (j.SubTotal + i.Amt)) + j.MarkupAddl) end),j.Total),
   				AuditYN = 'N'
			from bJBID j 
   			join inserted i on i.JBCo = j.JBCo and i.BillMonth = j.BillMonth 
   				and i.BillNumber = j.BillNumber and i.Line = j.Line and i.Seq = j.Seq
			where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum 
   				and j.Line = @line and j.Seq = @jbidseq and i.JCMonth = @mth 
   				and i.JCTrans = @jctrans
   
			update bJBID 
   			set AuditYN = 'Y'
			from bJBID j 
   			join inserted i on i.JBCo = j.JBCo and i.BillMonth = j.BillMonth 
    				and i.BillNumber = j.BillNumber and i.Line = j.Line and i.Seq = j.Seq
			where j.JBCo = @co and j.BillMonth = @billmth and j.BillNumber = @billnum 
    				and j.Line = @line and j.Seq = @jbidseq and i.JCMonth = @mth 
    				and i.JCTrans = @jctrans
           	end
		end
   
   	fetch next from bJBIJ_insert into @co, @billmth, @billnum, @line, @jbidseq, @mth, @jctrans,
   		@billstatus, @jbum, @hours, @units,
   		@jccdmatlgroup, @jccdmaterial, @jccdinco, @jccdloc, @jccdcosttype, @jccdphasegrp,
   		@jctranstype, @emgroup, @emrevcode, @oldbillstatus
   	end
   
if @openbJBIJcursor = 1
   	begin
   	close bJBIJ_insert
   	deallocate bJBIJ_insert
   	select @openbJBIJcursor = 0
   	end
   
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   /*
    select @co = min(JBCo) 
    from inserted i
    while @co is not null
    	begin
    	select @billmth = min(BillMonth) 
    	from inserted i 
    	where JBCo = @co
    	while @billmth is not null
         	begin
          	select @billnum = min(BillNumber) 
    		from inserted i 
    		where JBCo = @co and BillMonth = @billmth
         	while @billnum is not null
             	begin
             	select @mth = min(JCMonth) 
    			from inserted i 
    			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
             	while @mth is not null
                  	begin
                  	select @jctrans = min(JCTrans) 
    				from inserted i 
    				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
    					and JCMonth = @mth
    				while @jctrans is not null
    					begin
   					if update(BillStatus) or update(Units)
   						begin
   					 	select @billstatus = BillStatus, @line = Line, @jbidseq = Seq
   					  	from inserted  i 
   						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
   							and JCMonth = @mth and JCTrans = @jctrans
   			
   						end
   
                    	select @jctrans = min(JCTrans) 
    					from inserted i 
    					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
                        	and JCMonth = @mth and JCTrans > @jctrans
                     	end
    
                	select @mth = min(JCMonth) 
    				from inserted i 
    				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
    					and JCMonth > @mth
                  	end
    
            	select @billnum = min(BillNumber) 
    			from inserted i 
    			where JBCo = @co and BillMonth = @billmth and BillNumber > @billnum
             	if @@rowcount = 0 select @billnum = null
             	end
    
         	select @billmth = min(BillMonth) 
    		from inserted i 
    		where JBCo = @co and BillMonth > @billmth
         	if @@rowcount = 0 select @billmth = null
         	end
    
    	select @co = min(JBCo) 
    	from inserted i 
    	where JBCo > @co
    	end
   
   */
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   
/*Issue 13667*/
If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where c.AuditBills = 'Y')
   	BEGIN
	If Update(BillStatus)
		Begin
     	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
     	Select 'bJBIJ', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + isnull(convert(varchar(10),i.Line), '') + 'Seq: ' + isnull(convert(varchar(10),i.Seq), '') + 'JCMonth: ' + convert(varchar(8),i.JCMonth,1) + 'JCTrans: ' + convert(varchar(10),i.JCTrans),i.JBCo, 'C', 'BillStatus', d.BillStatus, i.BillStatus, getdate(), SUSER_SNAME()
     	From inserted i
     	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.JCMonth = i.JCMonth and d.JCTrans = i.JCTrans
     	Join bJBCO c on c.JBCo = i.JBCo
     	Where isnull(d.BillStatus,'') <> isnull(i.BillStatus,'')
     		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
     	End

   --  	If Update(Hours)
   --       	Begin
   --       	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   --      	Select 'bJBIJ', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + isnull(convert(varchar(10),i.Line), '') + 'Seq: ' + isnull(convert(varchar(10),i.Seq), '') + 'JCMonth: ' + convert(varchar(8),i.JCMonth,1) + 'JCTrans: ' + convert(varchar(10),i.JCTrans),i.JBCo, 'C', 'Hours', convert(varchar(11), d.Hours), convert(varchar(11), i.Hours), getdate(), SUSER_SNAME()
   --       	From inserted i
   --       	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.JCMonth = i.JCMonth and d.JCTrans = i.JCTrans
   --       	Join bJBCO c on c.JBCo = i.JBCo
   --       	Where d.Hours <> i.Hours
   --       		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
   --       	End
   --   
   --  	If Update(Units)
   --   		Begin
   --       	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   --       	Select 'bJBIJ', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + isnull(convert(varchar(10),i.Line), '') + 'Seq: ' + isnull(convert(varchar(10),i.Seq), '') + 'JCMonth: ' + convert(varchar(8),i.JCMonth,1) + 'JCTrans: ' + convert(varchar(10),i.JCTrans),i.JBCo, 'C', 'Units', convert(varchar(13), d.Units), convert(varchar(13), i.Units), getdate(), SUSER_SNAME()
   --       	From inserted i
   --       	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.JCMonth = i.JCMonth and d.JCTrans = i.JCTrans
   --       	Join bJBCO c on c.JBCo = i.JBCo
   --       	Where d.Units <> i.Units
   --       		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
   --       	End
   --   
   --  	If Update(Amt)
   --     	Begin
   --       	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   --       	Select 'bJBIJ', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + isnull(convert(varchar(10),i.Line), '') + 'Seq: ' + isnull(convert(varchar(10),i.Seq), '') + 'JCMonth: ' + convert(varchar(8),i.JCMonth,1) + 'JCTrans: ' + convert(varchar(10),i.JCTrans),i.JBCo, 'C', 'Amt', convert(varchar(16), d.Amt), convert(varchar(16), i.Amt), getdate(), SUSER_SNAME()
   --       	From inserted i
   --       	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.JCMonth = i.JCMonth and d.JCTrans = i.JCTrans
   --       	Join bJBCO c on c.JBCo = i.JBCo
   --       	Where d.Amt <> i.Amt
   --       		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
   --       	End
	END
    
return

error:
select @errmsg = @errmsg + ' - cannot update JBIJ!'

if @openbJBIJcursor = 1
	begin
	close bJBIJ_insert
	deallocate bJBIJ_insert
	select @openbJBIJcursor = 0
	end

RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
  
 






GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBIJ].[AuditYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBIJ].[Purge]'
GO
