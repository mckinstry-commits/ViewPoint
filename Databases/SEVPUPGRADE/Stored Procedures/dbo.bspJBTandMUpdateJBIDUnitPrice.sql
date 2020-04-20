SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMUpdateJBIDUnitPrice Script Date: 05/17/04 9:32:34 AM ******/
CREATE proc [dbo].[bspJBTandMUpdateJBIDUnitPrice]
/********************************************************************************************************
* CREATED BY: TJL 05/17/04 Issue #22526, Accurately accumulate JBID UM, Units, UnitPrice, ECM.  Phase #1
* MODIFIED BY:  TJL 12/14/04 - Issue #26526, Treat EM Equip transactions as Hourly based when RevCode is NULL
*		TJL 09/14/06 - Issue #122403, Show UM, Units, UnitPrice, ECM for NULL Material when SummaryOpt = 1 (Full Detail)
*		TJL 04/24/08 - Issue #127564, Units being zero'd on Hourly RevCodes using TimeUnitHours
*
*
* USED IN:
*	bspJBTandMInit
*	bspJBTandMAddJCTrans
*
* USAGE:
*	Evaluates current JBID Record for this transaction.  This procedure updates JBID as necessary
*	to allow JBIJ Insert trigger to accurately accumulate totals (UM, Units, Hours, UnitPrice, ECM)
*	as transactions get added.  These same values are set to NULL/Zero when transactions are incompatible
*	and averaging/conversions are not possible.
*
* Material:
*	1) Leaves alone if JBID UM is same as Posted UM or if Posted UM can be converted to JBID UM
*	2) Converts JBID UM, Units, UnitPrice, ECM to common values if UM Conversion is possible
*	3) NULL/Zero out JBID UM, Units, UnitPrice, ECM if Posted UM cannot be converted to JBID UM 
*
* Labor:  (No JBID updates required at this time.)
*
* Equipment:
*	1) Four separated conditional considerations.  Each requiring additional evaluation
*	   accordingly.  Each described below in the Equipment section.
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
*********************************************************************************************************/

(@co bCompany, @billmth bMonth, @billnum int, @line int, @jbidseq int, @jctranstype char(2),
@priceopt char(1), @matlgroup bGroup, @material bMatl, @inco bCompany, @loc bLoc, 
@emgroup bGroup, @equipment bEquip, @emrevcode bRevCode, @hours bHrs, @units bUnits,
@postedum bUM, @template varchar(10), @ctcategory char(1), @markupopt char(1), @msg varchar(275) output)

as

set nocount on

declare	@rcode int, @jbidum bUM, @jbidmaterial bMatl, @jbidunits bUnits, @jbidhrs bHrs,
@hqmtum bUM, @hqmtpriceecm bECM, @hqmtcostecm bECM, @hqmuconversion bUnitCost,
@inmtpriceecm bECM, @inmtlastecm bECM, @inmtavgecm bECM, @inmtstdecm bECM,
@inmuconversion bUnitCost, @overrideopt char(1), @overridecostopt char(1), 
@ecmfactor tinyint,	@ecm bECM, @emrcbasis char(1), @emrchrspertimeum bHrs,
@jbijcount int, @tempseqsumopt tinyint
--@jbidsubtotal numeric(15,5), @jbidmarkupaddl bDollar, @jbidmarkuprate bUnitCost,

select @rcode = 0

select @tempseqsumopt = TemplateSeqSumOpt
from bJBID d with (nolock)
where d.JBCo = @co and d.BillMonth = @billmth and d.BillNumber = @billnum and d.Line = @line and d.Seq = @jbidseq

select @jbijcount = count(*)
from bJBIJ with (nolock)
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
and Line = @line and Seq = @jbidseq 

/*********************************** Material Evaluation ***********************************/

if @material is null and @jctranstype in ('AP', /*'PO',*/ 'IN', 'MI', 'MS', 'MO', 'MT')
   	and @ctcategory = 'M'
	begin
	/* Two Conditions here:
	   1)  Null Material value, SummaryOpt = Full Detail (one JBID record per Transaction).  User intends
		   to see UM, Units, UnitPrice, and ECM for NULL JCCD Material value.  Skip code, do not NULL out values.

	   2)  Null Material value, SummaryOpt <> Full Detail.  Material value may have been set to NULL due
		   to the SummaryOpt setting.  In this case, UM, Units, UnitPrice, ECM may be mixed values and
		   combining them makes specific values worthless.  If this is the very first JBIJ record (JC Trans)
		   being added, null out these values.  Skip for each subsequent Transaction since UM and ECM 
		   are already NULL. */
	if  @tempseqsumopt <> 1 and @jbijcount = 0
   		begin
   		update bJBID 
   		set UM = null, Units = 0, UnitPrice = 0, ECM = null, 
   			AuditYN = 'N' 
   		from bJBID
   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   			and Seq = @jbidseq
   		if @@rowcount = 0
   			begin
   			select @msg = 'An error has occurred while updating Bill Sequence record! - #0', @rcode = 1
   			goto bspexit
   			end
	   
   		update bJBID 
   		set AuditYN = 'Y' 
   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   			and Seq = @jbidseq
   		end
	end		/* End Material is NULL */

   /* This transaction contains a Material value.  Therefore sequence summary option is set 
      in such a way that material values will be unique for the sequence.  We must therefore
      do further evaluation inorder to accumulate and average specific JBID values. */
if @material is not null and @jctranstype in ('AP', /*'PO',*/ 'IN', 'MI', 'MS', 'MO', 'MT')
   	and @ctcategory = 'M'
   /* If a JBID record already exists then if it is a Material related record, we need
      to evaluate UM for consistency.  If due to Template Summary/Sort levels, Materials
      are being combined that contain different UM, then UM, Units and UnitPrice might not 
      be able to be accurately determined and may need to be Null/Zeroed out. */
   	begin	/* Begin Material Not Null */
   	select @jbidum = UM, @jbidmaterial = Material
   		--@jbidsubtotal = SubTotal,	@jbidmarkupaddl = MarkupAddl, @jbidmarkuprate = MarkupRate
   	from bJBID with (nolock) 
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
   		and Line = @line and Seq = @jbidseq
   	if @@rowcount = 0
   		begin
   		select @msg = 'Original Bill sequence detail record is missing! - Material', @rcode = 1
   		goto bspexit
   		end
   
   	/* if JBID material is null (Because summarizing at a level that may Mix 
   	   different materials) or JBID material is different from this transactions
   	   material (This can only happen if sort level is at a higher level than the
   	   Summary option where Material does not get nulled out, I don't think that
   	   this can happen with material), then we cannot determine UM, Units and 
   	   UnitPrice with any accuracy and all must be Null or Zero'd out. */
   	if @jbidmaterial is null or (@material <> @jbidmaterial)
   		begin
   		/* Materials are mixed.  Set UM, Units, UnitPrice to Null/Zero */
   		update bJBID 
   		set UM = null, Units = 0, UnitPrice = 0, ECM = null, 
   			MarkupTotal = isnull((case when @markupopt = 'U' then MarkupAddl /*@jbidmarkupaddl*/ end),MarkupTotal),
   			Total = isnull((case when @markupopt = 'U' then SubTotal + MarkupAddl /*@jbidsubtotal + @jbidmarkupaddl*/ end),Total),
   			AuditYN = 'N' 
   		from bJBID
   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   			and Seq = @jbidseq
   		if @@rowcount = 0
   			begin
   			select @msg = 'An error has occurred while updating Bill Sequence record! - #1', @rcode = 1
   			goto bspexit
   			end
   
   		update bJBID 
   		set AuditYN = 'Y' 
   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   			and Seq = @jbidseq
   		end
   	else
   		begin	/* Begin Same Material evaluation */
   		if (@postedum <> @jbidum) and @jbidum is not null
   			begin	/* Begin Price Option evaluation, update JBID UM */
   			if @priceopt = 'C'
   				begin	/* Begin PriceOpt 'C', Cannot Convert */
   				/* There is no Converted UM possible under PriceOpt 'C'.  Therefore
   				   because the Posted UM is different then what is currently in 
   				   JBID, there is no common UM to use in order to calculate a
   				   common UnitPrice.  Null/Zero out JBID UM, Units, UnitPrice, ECM.   */
   				update bJBID 
   				set UM = Null, Units = 0, UnitPrice = 0, ECM = null, 
   					MarkupTotal = isnull((case when @markupopt = 'U' then MarkupAddl /*@jbidmarkupaddl*/ end),MarkupTotal),
   					Total = isnull((case when @markupopt = 'U' then SubTotal + MarkupAddl /*@jbidsubtotal + @jbidmarkupaddl*/ end),Total),
   					AuditYN = 'N' 
   				from bJBID
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   					and Seq = @jbidseq
   				if @@rowcount = 0
   					begin
   					select @msg = 'An error has occurred while updating Bill Sequence record! - #2', @rcode = 1
   					goto bspexit
   					end
   
   				update bJBID 
   				set AuditYN = 'Y' 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   					and Seq = @jbidseq
   
   				select @jbidum = null	--This now becomes the JBID UM
   				end 	/* End PriceOpt 'C', Cannot Convert */
   
   			if @priceopt = 'P'
   				begin	/* Begin PriceOpt 'P' */
   				/* First, if different and the original JBID UM is not HQMT.StdUM then
   				   we will need to convert the original entry back to StdUM, Units and 
   				   UnitPrice to have the possibility of accumulating values
   				   based on Converted values. If different the possibilities are:
   					1)  JBID UM is HQMT StdUM and Posted UM can be converted
   					2)  JBID UM is not HQMT StdUM but can be converted to Posted UM which is StdUM
   					3)  JBID UM is not HQMT StdUM but cannot be converted to Posted UM 
   		
   				   Price Option 'P' deals strictly with HQMT and HQMU.  Any conversion we
   				   do is based upon values in these two tables only. */
   
   				/* Get HQMT UM for comparison to determine if Conversion is necessary. */
   				select @hqmtum = StdUM, @hqmtpriceecm = PriceECM, @hqmtcostecm = CostECM
   				from bHQMT with (nolock)
   				where MatlGroup = @matlgroup and Material = @material
   
   				if @jbidum <> @hqmtum and @hqmtum is not null	-- Conversion will be required
   					begin	/* Begin JBID not StdUM, May need conversion 'P' */
   					
   					select @hqmuconversion = Conversion
   					from bHQMU u with (nolock)
   					where u.MatlGroup = @matlgroup and u.Material = @material and u.UM = @jbidum
   
   					if @hqmuconversion is not null
   						begin	/* Begin Can Convert */
   						/* JBID is currently based upon Converted UM and rates.  Since it was originally
   					       converted UM/Rate values we can still accumulate Units and determine
   					   	   UnitPrice as long as we set things back to the lowest possible 
   					   	   denominator which typically is StdUM. */
   
   						/* ECM to be used is PriceECM unless Material Overrides says otherwise. */
   						select @overrideopt = OverrideOpt
   						from bJBMO with (nolock)
   						where JBCo = @co and Template = @template and MatlGroup = @matlgroup
   							and Material = @material
   
   						if @overrideopt is not null
   							begin
   							select @ecm = case @overrideopt when 'P' then @hqmtpriceecm
   								else @hqmtcostecm end
   							end
   						else
   							begin
   							select @ecm = @hqmtpriceecm
   							end
   
   						/* Set @ecmfactor based upon the correct HQMT ECM */
   						select @ecmfactor = case @ecm 
   							when 'E' then 1
   							when 'C' then 100
   							when 'M' then 1000 else 1 end
   
   						/* Reset bJBID UM, UnitPrice, Units, ECM */
   						update bJBID 
   						set UM = @hqmtum, 
   							UnitPrice = case when ((Units * @hqmuconversion)/isnull(@ecmfactor,1)) = 0 then 0
   								else SubTotal/((Units * @hqmuconversion)/isnull(@ecmfactor,1)) end,
   							Units = (Units * @hqmuconversion), ECM = @ecm, 
   							MarkupTotal = isnull((case when @markupopt = 'U' 
   								then (MarkupRate /*@jbidmarkuprate*/ * (Units * @hqmuconversion)) + MarkupAddl /*@jbidmarkupaddl*/ end),MarkupTotal),
   							Total = isnull((case when @markupopt = 'U' 
   								then SubTotal /*@jbidsubtotal*/ + ((MarkupRate /*@jbidmarkuprate*/ * (Units * @hqmuconversion)) + MarkupAddl /*@jbidmarkupaddl*/) end),Total),
   							AuditYN = 'N' 
   						from bJBID
   						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   							and Seq = @jbidseq
   						if @@rowcount = 0
   							begin
   							select @msg = 'An error has occurred while updating Bill Sequence record! - #3', @rcode = 1
   							goto bspexit
   							end
   
   						update bJBID 
   						set AuditYN = 'Y' 
   						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   							and Seq = @jbidseq
   				
   						select @jbidum = @hqmtum	--This now becomes the JBID UM
   						end		/* End Can Convert */
   					else
   						begin	/* Begin Cannot Convert */
   						/* This JBID UM is not a Converted UM, therefore it was NOT converted
   					   	   initially.  In this case, since JBID UM and Posted UM are different, what we
   						   have is a MatlGroup, Material with two unique UM.  If this is the case, then
   						   UnitCost cannot be determined.  Null/Zero out JBID UM, Units, UnitPrice, ECM. */
   						update bJBID 
   						set UM = Null, Units = 0, UnitPrice = 0, ECM = null, 
   							MarkupTotal = isnull((case when @markupopt = 'U' then MarkupAddl /*@jbidmarkupaddl*/ end),MarkupTotal),
   							Total = isnull((case when @markupopt = 'U' then SubTotal + MarkupAddl /*@jbidsubtotal + @jbidmarkupaddl*/ end),Total),
   							AuditYN = 'N'
   						from bJBID 
   						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   							and Seq = @jbidseq
   						if @@rowcount = 0
   							begin
   							select @msg = 'An error has occurred while updating Bill Sequence record! - #4', @rcode = 1
   							goto bspexit
   							end
   
   						update bJBID 
   						set AuditYN = 'Y' 
   						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   							and Seq = @jbidseq
   
   						select @jbidum = null	--This now becomes the JBID UM
   						end		/* End Cannot Convert */
   					end 	/* End JBID not StdUM, May need conversion 'P' */
   				end		/* End PriceOpt 'P' */
   
   			if @priceopt = 'L'
   				begin	/* Begin Price Option 'L' */
   				/* First, if different and the original JBID UM is not HQMT.StdUM then
   				   we will need to convert the original entry back to StdUM, Units and 
   				   UnitPrice to have the possibility of accumulating values
   				   based on Converted values. If different the possibilities are:
   					1)  JBID UM is HQMT StdUM and Posted UM can be converted
   					2)  JBID UM is not HQMT StdUM but can be converted to Posted UM
   					3)  JBID UM is not HQMT StdUM but cannot be converted to Posted UM 
   		
   				   Price Option 'L' deals strictly with INMT, HQMT and INMU, HQMU.  Any conversion we
   				   do is based upon values in these tables. */
   
   				/* Get HQMT UM for comparison to determine if Conversion is necessary. */
   				select @hqmtum = StdUM, @hqmtpriceecm = PriceECM, @hqmtcostecm = CostECM
   				from bHQMT with (nolock)
   				where MatlGroup = @matlgroup and Material = @material
   
   				if @jbidum <> @hqmtum and @hqmtum is not null	-- Conversion will be required
   					begin	/* Begin JBID not StdUM, May need conversion 'L' */
   
   					select @inmuconversion = Conversion
   					from bINMU u with (nolock)
   					where u.INCo = @inco and u.Loc = @loc
   						and u.MatlGroup = @matlgroup and u.Material = @material and u.UM = @jbidum
   
   					select @hqmuconversion = Conversion
   					from bHQMU u with (nolock)
   					where u.MatlGroup = @matlgroup and u.Material = @material and u.UM = @jbidum
   
   					if @hqmuconversion is not null or @inmuconversion is not null
   						begin	/* Begin Can Convert */
   						/* JBID is currently based upon Converted UM and rates.  Since it was originally
   					       converted UM/Rate values we can still accumulate Units and determine
   					   	   UnitPrice as long as we set things back to the lowest possible 
   					   	   denominator which typically is StdUM. */
   
   						select @inmtpriceecm = PriceECM, @inmtlastecm = LastECM, @inmtavgecm = AvgECM, 
   							@inmtstdecm = StdECM
   						from bINMT with (nolock)
   						where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup
   							and Material = @material
   			
   						/* ECM to be used is PriceECM unless Material Overrides says otherwise. */
   						select @overrideopt = OverrideOpt, @overridecostopt = CostOpt
   						from bJBMO with (nolock)
   						where JBCo = @co and Template = @template and MatlGroup = @matlgroup
   							and Material = @material
   
   						if @overrideopt is not null
   							begin
   							if @overrideopt = 'C'
   								begin
   		       					select @ecm = isnull((case isnull(@overridecostopt,'') 
   									when 'S' then @inmtstdecm
          								when 'A' then @inmtavgecm 
   									when 'L' then @inmtlastecm end), isnull(@hqmtcostecm, 'E'))
   								end
   							else
   								select @ecm = isnull(@inmtpriceecm, isnull(@hqmtpriceecm, 'E'))
   							end
   						else
   							begin
   							select @ecm = isnull(@inmtpriceecm, isnull(@hqmtpriceecm, 'E'))
   							end
   
   						/* Set @ecmfactor based upon the correct HQMT ECM */
   						select @ecmfactor = case @ecm 
   							when 'E' then 1
   							when 'C' then 100
   							when 'M' then 1000 else 1 end
   
   						/* Reset bJBID UM, UnitPrice, Units, ECM */
   						update bJBID 
   						set UM = @hqmtum, 
   							UnitPrice = case when ((Units * isnull(@inmuconversion,@hqmuconversion))/isnull(@ecmfactor,1)) = 0 then 0
   								else SubTotal/((Units * isnull(@inmuconversion,@hqmuconversion))/isnull(@ecmfactor,1)) end,
   							Units = (Units * isnull(@inmuconversion,@hqmuconversion)), ECM = @ecm, 
   							MarkupTotal = isnull((case when @markupopt = 'U' 
   								then (MarkupRate /*@jbidmarkuprate*/ * (Units * isnull(@inmuconversion,@hqmuconversion))) + MarkupAddl /*@jbidmarkupaddl*/ end),MarkupTotal),
   							Total = isnull((case when @markupopt = 'U' 
   								then SubTotal /*@jbidsubtotal*/ + ((MarkupRate /*@jbidmarkuprate*/ * (Units * isnull(@inmuconversion,@hqmuconversion))) + MarkupAddl /*@jbidmarkupaddl*/) end),Total),
   							AuditYN = 'N'
   						from bJBID
   						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   							and Seq = @jbidseq
   						if @@rowcount = 0
   							begin
   							select @msg = 'An error has occurred while updating Bill Sequence record! - #5', @rcode = 1
   							goto bspexit
   							end
   
   						update bJBID 
   						set AuditYN = 'Y' 
   						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   							and Seq = @jbidseq
   				
   						select @jbidum = @hqmtum	--This now becomes the JBID UM
   						end		/* End Can Convert */
   					else
   						begin	/* Begin Cannot Convert */
   						/* This JBID UM is not a Converted UM, therefore it was NOT converted
   					   	   initially.  In this case, since JBID UM and Posted UM are different, what we
   						   have is a MatlGroup, Material with two unique UM.  If this is the case, then
   						   UnitCost cannot be determined.  Null/Zero out JBID UM, Units, UnitPrice, ECM. */
   						update bJBID 
   						set UM = Null, Units = 0, UnitPrice = 0, ECM = null, 
   							MarkupTotal = isnull((case when @markupopt = 'U' then MarkupAddl /*@jbidmarkupaddl*/ end),MarkupTotal),
   							Total = isnull((case when @markupopt = 'U' then SubTotal + MarkupAddl /*@jbidsubtotal + @jbidmarkupaddl*/ end),Total),
   							AuditYN = 'N'
   						from bJBID 
   						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   							and Seq = @jbidseq
   						if @@rowcount = 0
   							begin
   							select @msg = 'An error has occurred while updating Bill Sequence record! - #6', @rcode = 1
   							goto bspexit
   							end
   
   						update bJBID 
   						set AuditYN = 'Y' 
   						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   							and Seq = @jbidseq
   
   						select @jbidum = null	--This now becomes the JBID UM
   						end		/* End Cannot Convert */
   					end		/* End JBID not StdUM, May need conversion 'L' */
   				end 	/* End Price Option 'L' */
   			end		/* End Price Option evaluation, update JBID UM */
   		end		/* End Same Material evaluation */
   
   	/* At this stage, we have evaluated the existing JBID record.  It may have
   	   been converted above.  The following section is kind of the reverse of
   	   everything that took place above.  In this case, JBID was StdUM to begin with and the
   	   current UM being posted might beable to be converted and therefore we still may 
   	   beable to calculate UnitPrice.
   
   	   @postedUM and @jbidum can both be Converted UM or both can be StdUM
   	   or they are entirely different. 
   
   	   If @postedum (This transactions) <> @jbidum (whats already in JBID, converted above) then 
   	   @jbidum will now be bHQMT.StdUM and There are two possibilities:
   		1)  A Conversion is required to determine proper UnitCost
   		2)  This is a completely different UM and UnitCost cannot be determined */
   	if (@postedum <> @jbidum) and @jbidum is not null
   		begin
   		/* If @priceopt = 'C'
   			begin
   				Taken care of above, no conversion is possible
   			end
   		*/
   
   		if @priceopt = 'P'
   			begin	/* Begin UM different eval */
   			/* Determine if Converted UM exists */
   			if not exists(select 1 from bHQMU u with (nolock)
   					join bHQMT t with (nolock) on t.MatlGroup = u.MatlGroup and t.Material = u.Material
   					where u.MatlGroup = @matlgroup and u.Material = @material and u.UM = @postedum)
   				begin
   				/* There is no Coversion UM, therefore Per #2 above, UnitCost cannot be
   				   determined.  Null/Zero out JBID UM, Units, UnitPrice */
   				update bJBID 
   				set UM = Null, Units = 0, UnitPrice = 0, ECM = null, 
   					MarkupTotal = isnull((case when @markupopt = 'U' then MarkupAddl /*@jbidmarkupaddl*/ end),MarkupTotal),
   					Total = isnull((case when @markupopt = 'U' then SubTotal + MarkupAddl /*@jbidsubtotal + @jbidmarkupaddl*/ end),Total),
   					AuditYN = 'N'
   				from bJBID 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   					and Seq = @jbidseq
   				if @@rowcount = 0
   					begin
   					select @msg = 'An error has occurred while updating Bill Sequence record! - #7', @rcode = 1
   					goto bspexit
   					end
   
   				update bJBID 
   				set AuditYN = 'Y' 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   					and Seq = @jbidseq
   				end
   			end
   
   		if @priceopt = 'L'
   			begin
   			/* Determine if Converted UM exists */
   			if not exists(select 1 from bINMU u with (nolock)
   					join bHQMT t with (nolock) on t.MatlGroup = u.MatlGroup and t.Material = u.Material
   					where u.MatlGroup = @matlgroup and u.Material = @material and u.UM = @postedum
   						and u.INCo = @inco and u.Loc = @loc)
   				begin
   				if not exists(select 1 from bHQMU u with (nolock)
   						join bHQMT t with (nolock) on t.MatlGroup = u.MatlGroup and t.Material = u.Material
   						where u.MatlGroup = @matlgroup and u.Material = @material and u.UM = @postedum)
   					begin
   					/* There is no Coversion UM, therefore Per #2 above, UnitCost cannot be
   					   determined.  Null/Zero out JBID UM, Units, UnitPrice */
   					update bJBID 
   					set UM = Null, Units = 0, UnitPrice = 0, ECM = null, 
   						MarkupTotal = isnull((case when @markupopt = 'U' then MarkupAddl /*@jbidmarkupaddl*/ end),MarkupTotal),
   						Total = isnull((case when @markupopt = 'U' then SubTotal + MarkupAddl /*@jbidsubtotal + @jbidmarkupaddl*/ end),Total),
   						AuditYN = 'N' 
   					from bJBID
   					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   						and Seq = @jbidseq
   					if @@rowcount = 0
   						begin
   						select @msg = 'An error has occurred while updating Bill Sequence record! - #8', @rcode = 1
   						goto bspexit
   						end
   
   					update bJBID 
   					set AuditYN = 'Y' 
   					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   						and Seq = @jbidseq
   					end
   				end
   			end
   		end		/* End UM different eval */
   	goto bspexit
   	end		/* End Material Not Null */
   
/*************************************** Labor Evaluation **************************************/
if @jctranstype in ('PR') and @ctcategory = 'L'
   	begin	/* Begin Labor HRS evaluation */
   	/* Currently there are no special JBID updates required for Labor transactions.  The
   	   bJBIJ insert trigger will continuously update bJBID.UnitPrice based upon current
   	   Subtotal / accumulated ActualHours. */
   	select @rcode = 0
   	goto bspexit
   	end		/* End Labor HRS evaluation */
   
/*************************************** Equipment Evaluation **************************************/
if @jctranstype in ('EM',/*'MS', 'PR',*/ 'JC') and @ctcategory = 'E'	--<-- Most Always will be 'EM' 'E'
   	begin	/* Begin Equipment evaluation */
   	/* Equipment usage can be Hourly based or Unit based.  */
   
   	select @jbidunits = Units, @jbidhrs = Hours, @jbidum = UM
   		-- @jbidsubtotal = SubTotal, @jbidmarkupaddl = MarkupAddl
   	from bJBID with (nolock) 
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
   		and Line = @line and Seq = @jbidseq
   	if @@rowcount = 0
   		begin
   		select @msg = 'Original Bill sequence detail record is missing! - Equipment', @rcode = 1
   		goto bspexit
   		end
   
   	select @emrcbasis = Basis, @emrchrspertimeum = HrsPerTimeUM
   	from bEMRC with (nolock)
   	where EMGroup = @emgroup and RevCode = @emrevcode
   	 
   	/*  1) If JBID Units and Hours are both 0 then either JBID has been set by a transaction that 
   		   was based differently than others before it or, by bad luck and chance, the first two 
   		   transactions to be processed canceled each other out.  In all cases, we really do not yet know
   		   if we are dealing with UnitBased or Hourly based.  Leave JBID as is.  JBIJ
   		   insert trigger will later evaluate the basis of this transaction compared to 
   		   those already in JBIJ and either update, if all are the same Basis, or not if
   		   the Basis's differ.
   
   		2) If JBID Units exists with No Hours, then JBID is UnitBased at this moment.  If this 
   		   transaction is HoursBased or if UnitBased and @postedum (This transactions UM) <> @jbidum 
   		   or this transaction has no Revcode then NULL JBID
   
   	   	3) If JBID Hours exist with No Units then JBID is HoursBased at this moment.  If this transaction
   		   is UnitsBased then NULL JBID.  If this transaction is HoursBased and both Units and Hours exist, 
   		   then Leave alone.  JBIJ insert trigger will later need to use Hours to update the JBID record.
   
   	   	4) If Hours and Units exist then JBID is HoursBased using TimeUnits.  
		   a) If this transaction is UnitsBased or this transaction has no RevCode then NULL JBID. Units and
			  hours no longer make sense.  We have a combination of Hours based and Units based.
		   b) If this transactions contains only Hours then JBID needs to be Converted to Straight Hours.  
   		      (Units = 0, UnitPrice = SubTotal/Hours). 
		   c) If this transactions Contains both Hours and Units then leave it alone.  We have no way of 
			  comparing EMRC.HrsPerTimeUM for this transaction being added against all of the transactions
			  currently making up the summarized version of the JBID record.  (Calculating a value representing
			  JBID.HrsPerTimeUM (@jbidhrs/@jbidunits) fails due to rounding issues.  Therefore units will
			  be accumulated as each transaction is processed.  User needs to setup the template to assure
			  that transactions with different RevCodes and different HrsPerTimeUM are not mixed into a
			  single JBID record. */
   
   	/* #1 */
   	if @jbidunits = 0 and @jbidhrs = 0
   		begin	/* Begin JBID Basis is unknown */
   		select @rcode = 0
   		goto bspexit
   		end		/* End JBID Basis is unknown */
   
   	/* #2 */
   	if @jbidunits <> 0 and @jbidhrs = 0
   		begin	/* Begin JBID is UnitsBased */
   		if @emrcbasis = 'H' or (@emrcbasis = 'U' and @postedum <> @jbidum) or @emrcbasis is null
   			begin
   			update bJBID 
   			set UM = Null, Units = 0, Hours = 0, UnitPrice = 0, ECM = null, 
   				MarkupTotal = isnull((case when @markupopt = 'U' then MarkupAddl /*@jbidmarkupaddl*/ end),MarkupTotal),
   				Total = isnull((case when @markupopt = 'U' then SubTotal + MarkupAddl /*@jbidsubtotal + @jbidmarkupaddl*/ end),Total),
   				AuditYN = 'N'
   			from bJBID 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   				and Seq = @jbidseq
   			if @@rowcount = 0
   				begin
   				select @msg = 'An error has occurred while updating Bill Sequence record! - #9', @rcode = 1
   				goto bspexit
   				end
   	
   			update bJBID 
   			set AuditYN = 'Y' 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   				and Seq = @jbidseq
   			end
   		end 	/* End JBID is UnitsBased */
   
   	/* #3 */
   	if @jbidhrs <> 0 and @jbidunits = 0
   		begin	/* Begin JBID is Hours Based */
   		if @emrcbasis = 'U' 	--A NULL RevCode is Hours based
   			begin
   			update bJBID 
   			set UM = Null, Units = 0, Hours = 0, UnitPrice = 0, ECM = null, AuditYN = 'N'
   			from bJBID 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   				and Seq = @jbidseq
   			if @@rowcount = 0
   				begin
   				select @msg = 'An error has occurred while updating Bill Sequence record! - #10', @rcode = 1
   				goto bspexit
   				end
   	
   			update bJBID 
   			set AuditYN = 'Y' 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   				and Seq = @jbidseq
   			end
   		end  	/* End JBID is Hours Based */	
   
   	/* #4 */
   	if @jbidhrs <> 0 and @jbidunits <> 0
   		begin	/* Begin JBID is TimeUnits Hours Based */
   		if @emrcbasis = 'U' or @emrcbasis is null	
   			begin
   			update bJBID 
   			set UM = Null, Units = 0, Hours = 0, UnitPrice = 0, ECM = null, AuditYN = 'N'
   			from bJBID 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   				and Seq = @jbidseq
   			if @@rowcount = 0
   				begin
   				select @msg = 'An error has occurred while updating Bill Sequence record! - #11', @rcode = 1
   				goto bspexit
   				end
   	
   			update bJBID 
   			set AuditYN = 'Y' 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   				and Seq = @jbidseq
   			end
   	
   		if @emrcbasis = 'H' 
			begin
			if (@hours <> 0 and @units = 0) 
				begin
   				update bJBID 
   				set UM = Null, Units = 0, UnitPrice = (/*@jbidsubtotal*/SubTotal/@jbidhrs), 	
   					ECM = null, AuditYN = 'N'
   				from bJBID 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   					and Seq = @jbidseq
   				if @@rowcount = 0
   					begin
   					select @msg = 'An error has occurred while updating Bill Sequence record! - #12', @rcode = 1
   					goto bspexit
   					end

   				update bJBID 
   				set AuditYN = 'Y' 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   					and Seq = @jbidseq
				end

			/* Removed per Issue #127564 on 04/24/08
			   The intent was to test and see if the transaction being added contained the same EMRC.HrsPerTimeUM
			   as the current JBID record.  If not, then the JBID record units were zero'd and UnitPrice was converted
			   to Hourly Rate. However due to rounding the test (@hours/@units) <> (@jbidhrs/@jbidunits) almost always 
			   failed even when the transactions contained the same HrsPerTimeUM.  

			   The following code corrects this situation assuming that HrsPerTimeUM are relatively predictable.
			   Meaning they are always whole numbers like (1, 8 (day), 40 (week) etc.) and never mixed numbers 
			   like 8.5 or anything similar.  For now we will leave this adjustment out and see how if flys in the
			   field. */ 
--			if ((@hours <> 0 and @units <> 0) and (round((@hours/@units),0) <> round((@jbidhrs/@jbidunits),0)))
--   				begin
--   				update bJBID 
--   				set UM = Null, Units = 0, UnitPrice = (/*@jbidsubtotal*/SubTotal/@jbidhrs), 	
--   					ECM = null, AuditYN = 'N'
--   				from bJBID 
--   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
--   					and Seq = @jbidseq
--   				if @@rowcount = 0
--   					begin
--   					select @msg = 'An error has occurred while updating Bill Sequence record! - #12', @rcode = 1
--   					goto bspexit
--   					end
--
--   				update bJBID 
--   				set AuditYN = 'Y' 
--   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
--   					and Seq = @jbidseq
--	   	   		end
			end
   		end		/* End JBID is TimeUnits Hours Based */
   	goto bspexit
   	end		/* End Equipment evaluation */
   
/* All of the above is designed to massage the JBID record in preparation for this transaction
  that is about to be added.  

  The JBID record is now set either:
Material:
1)  To a value that the incoming transactions UM can easily be converted to
   OR
2)  Has been Set to NULL because the UM of this transaction is not compatible
    with other transactions associated with this same JBID sequence.

Labor:
1) No Action required.

Equipment:
1) Has been modified as described in the Equipment Section above.

  Once the transaction gets added to bJBIJ, the JBIJ insert trigger will now be able to
  do a quick evaluation and determine if JBID Units and UnitPrice can still be accurately
  calculated.  A similar evaluation will also take place relative to JBID HRS and UnitPrice
  for Labor type transactions. */

bspexit:

if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[bspJBTandMUpdateJBIDUnitPrice]'

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMUpdateJBIDUnitPrice] TO [public]
GO
