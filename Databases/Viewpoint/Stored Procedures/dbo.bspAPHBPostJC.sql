SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPHBPostJC    Script Date: 8/28/99 9:36:00 AM ******/
 CREATE    procedure [dbo].[bspAPHBPostJC]
/***********************************************************
* CREATED BY:	SE	10/27/1997
* MODIFIED By : GH	06/22/1999 Corrected problem with Unable to remove posted distributions from APJC
*                          JC Interface level 2
*				GG	03/03/2000	- Reversed sign on updates to remaining committed units and costs in JC
*				GG	06/20/2000	- Modified to update tax info to bJCCD
*				GG	11/27/2000	- changed datatype from bAPRef to bAPReference
*				kb	08/13/2001	- issue #13963
*				kb	01/24/2002	- issue #15922
*				CMW 03/15/2002	- issue # 16503
*				kb	10/28/2002	- issue #18878 - fix double quotes
*				MV	03/07/2003	- #19926 update/insert RemCmtdUnits/Cost, TotalCmtdUnits/Cost
*				GF	08/11/2003	- issue #22112 - performance improvements
*				GF	09/23/2003	- issue #22112 - variables declared do not match columns in cursor
*				MV	11/26/2003	- #23061 isnull wrap
*				MV	11/14/2006	- #120033 Update JCCD Actuals to include TaxBasis (0 gross, 0 taxamt, <>0 taxbasis)
*				DC	10/22/2008	- #128052 Remove Committed Cost Flag
*				DC	12/14/2009	- #122288 - Store Tax rate in POIT
*				GP	06/28/2010	- #135813 change bSL to varchar(30) 
*				GF	08/03/2011	- TK-07143 expand PO
*				CHS	08/11/2011	- TK-07620
*				MV	09/15/11	- TK-08442 update bJCCD with POItemLine value.
*  
* USAGE:
* Called from the bspAPHBPost procedure to post JC distributions
* tracked in bAPJC.  Interface level to JC is assigned in AP Company.
* Even if the JC Interface level is set at 0 (none), committed units and
* costs must be updated to JC for POs and Subcontracts.
*
* Interface levels:
*  0       No update of actual units or costs to JC, but will still update
*          committed and received n/invcd units and cost to JCCP.
*  1       Interface at the transaction line level.  Each line on an invoice
*          creates a JCCD entry.
*  2       Interface at the transaction level.  All lines  on a transaction
*          posted to the same job, phase, and cost type will be summarized
*          into a single JCCD entry.
*
* INPUT PARAMETERS
*   @co            AP Co#
*   @mth           Batch month
*   @batchid       Batch ID#
*   @dateposted    Posting date
*
* OUTPUT PARAMETERS
*   @errmsg        Message used for errors
*
* RETURN VALUE
*   0              success
*   1              fail
*****************************************************/
 (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(100) output)
 as
 set nocount on
 
 declare @rcode int,	@jcinterfacelvl tinyint, --DC #128052 @pocmtddetailtojc bYN,   @slcmtddetailtojc bYN,
 		@openPOSLcursor tinyint, @openLvl0cursor tinyint, @openLvl1cursor tinyint, @openLvl2cursor tinyint,
 		@jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @units bUnits,
 		@postremcmtdunits bUnits, @jcunits bUnits, @jccmtdunits bUnits, @totalcost bDollar, @remcmtdcost bDollar,
 		@jcunitcost bUnitCost, @ecm bECM, @jctrans bTrans, @msg varchar(200), @rniunits bUnits, @rnicost bDollar,
 		@aptrans bTrans, @apline smallint, @linedesc bDesc, @seq int, @invdate bDate, @oldnew tinyint,
 		@um bUM, @vendorgroup bGroup, @vendor bVendor, @apref bAPReference, @jcum bUM, @transdesc bDesc, @sl varchar(30),
 		@slitem bItem, @po VARCHAR(30), @poitem bItem, @POItemLine int, @matlgroup bGroup, @material bMatl, @glco bCompany, @glacct bGLAcct,
 		@taxtype tinyint, @taxgroup bGroup, @taxcode bTaxCode, @taxbasis bDollar, @taxamt bDollar, @remcmtdunits bUnits,
 		@totalcmtdunits bUnits, @totalcmtdcost bDollar, @posttotcmtdunits bUnits,
 		@totalcmtdtax bDollar, @remcmtdtax bDollar  --DC #122288
 
 select @rcode = 0, @openPOSLcursor = 0, @openLvl0cursor = 0, @openLvl1cursor = 0, @openLvl2cursor = 0
 
 -- get JC interface level
 select @jcinterfacelvl = JCInterfaceLvl from bAPCO with (nolock) where APCo = @co
  
 /* DC #128052
 -- get Committed Cost Update option for POs
 select @pocmtddetailtojc = CmtdDetailToJC from bPOCO with (nolock) where POCo = @co
 */
 
 /* DC #128052
 -- get Committed Cost Update option for Subcontracts
 select @slcmtddetailtojc = CmtdDetailToJC from bSLCO with (nolock) where SLCo = @co
 */ 	
 
 -- if updating Committed units or costs in detail from PO or SL, process at the Line level
 declare bcPOSL cursor LOCAL FAST_FORWARD
 for select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, APLine, OldNew,
     APTrans, VendorGroup, Vendor, APRef, InvDate, SL, SLItem, PO, POItem, POItemLine,
     MatlGroup, Material, LineDesc, GLCo, GLAcct, UM, Units, JCUM, JCUnits,
     JCUnitCost, ECM, TotalCost, RNIUnits, RNICost, RemCmtdCost,TaxGroup,
 	TaxCode, TaxType, TaxBasis, TaxAmt, RemCmtdUnits, TotalCmtdUnits,
 	TotalCmtdCost,
 	TotalCmtdTax, RemCmtdTax  --DC #122288
 from bAPJC
 where APCo = @co and Mth = @mth and BatchId = @batchid /*@pocmtddetailtojc = 'Y' and DC #128052 */ 
	and PO is not null
 union
 select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, APLine, OldNew,
     APTrans, VendorGroup, Vendor, APRef, InvDate, SL, SLItem, PO, POItem, POItemLine,
     MatlGroup, Material, LineDesc, GLCo, GLAcct, UM, Units, JCUM, JCUnits,
  	JCUnitCost, ECM, TotalCost, RNIUnits, RNICost, RemCmtdCost,TaxGroup,
 	TaxCode, TaxType, TaxBasis, TaxAmt, RemCmtdUnits, TotalCmtdUnits,
 	TotalCmtdCost,
 	TotalCmtdTax, RemCmtdTax  --DC #122288
 from bAPJC
 where APCo = @co and Mth = @mth and BatchId = @batchid /*and @slcmtddetailtojc = 'Y' DC #128052 */
	and SL is not null
  
 -- open cursor
 open bcPOSL
 select @openPOSLcursor = 1
 
 -- loop through all rows in cursor
 posl_posting_loop:
 fetch next from bcPOSL into @jcco, @job, @phasegroup, @phase, @jcctype, @seq,
         @apline, @oldnew, @aptrans, @vendorgroup, @vendor, @apref, @invdate,
  	    @sl, @slitem, @po, @poitem, @POItemLine, @matlgroup, @material, @linedesc, @glco, @glacct,
         @um, @units, @jcum, @jcunits, @jcunitcost, @ecm, @totalcost, @rniunits,
         @rnicost, @remcmtdcost, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt,
 		@remcmtdunits, @totalcmtdunits, @totalcmtdcost,
 		@totalcmtdtax, @remcmtdtax  --DC #122288
 
 if @@fetch_status = -1 goto posl_posting_end
 if @@fetch_status <> 0 goto posl_posting_loop
 
 -- change to Remaining Committed Units and Cost
 select @postremcmtdunits = @units /*@detailcmtdunits = @units*/, @jccmtdunits = @jcunits
 --#19926 remcmtdunits should be negative for regular POs or standing POs flagged for receiving
 -- but 0 for a standing PO not flagged for receiving 
 if @remcmtdcost = 0 and @totalcmtdcost > 0 --standing PO not flagged for receiving
 	begin
 	select @postremcmtdunits = 0 -- total - invoiced nets to 0
 	select @posttotcmtdunits = @totalcmtdunits	-- total has not been established yet
 	end
 else
 	begin
 	select @postremcmtdunits = (-1 * @postremcmtdunits) --reduce PostedRemCmtdUnits by invoiced units
 	select @posttotcmtdunits = 0	--totals are already established in POEntry or POReceipts
 	end 
 
 if @jcinterfacelvl = 0      -- not interfacing Actual units or costs
 	begin
 	select @units = 0, @jcunits = 0, @jcunitcost = 0, @totalcost = 0
 	end
 
 begin transaction
 
 -- add JC Cost Detail - update Actuals (unless JC interface level = 0) and Remaining Committed
 if @units <> 0 or @totalcost <> 0 or @postremcmtdunits <> 0  --@detailcmtdunits <> 0
 		or @remcmtdcost <> 0 or @taxbasis <> 0 or @totalcmtdcost <> 0
 	begin
 	-- get next available transaction # for JCCD
 	exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @msg output
 	if @jctrans = 0
 		begin
 		select @errmsg = 'Unable to update JC Cost Detail.  ' + isnull(@msg,''), @rcode=1
 		goto posl_posting_error
 		end
 
 	-- add JC Cost Detail entry
 	-- #19926 - insert RemCmtdUnits/Cost, TotalCmtdUnits/Cost 
 	insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
             JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostedUnitCost,
             PostedECM,PostTotCmUnits, PostRemCmUnits, UM, ActualUnitCost, PerECM, ActualUnits, ActualCost,
             RemainCmtdUnits, RemainCmtdCost, APCo, VendorGroup, Vendor, APRef, SL,
             SLItem, PO, POItem, POItemLine, MatlGroup, Material, GLCo, GLTransAcct, APTrans,
             APLine, TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt,TotalCmtdUnits, TotalCmtdCost,
             TotalCmtdTax, RemCmtdTax)  --DC #122288
 	values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @invdate, 'AP',
             'AP Entry', @linedesc, @batchid, @um, @units, case when @units <> 0 then @totalcost/@units else 0 end,
             @ecm,@posttotcmtdunits,@postremcmtdunits /*-(@detailcmtdunits)*/, @jcum, @jcunitcost, 
 			@ecm, @jcunits, @totalcost, @remcmtdunits /*-(@jccmtdunits)*/, @remcmtdcost, @co, @vendorgroup, 
 			@vendor, @apref, @sl, @slitem, @po, @poitem, @POItemLine, @matlgroup, @material, @glco, @glacct, @aptrans, @apline,
             @taxtype, @taxgroup, @taxcode, @taxbasis, @taxamt,@totalcmtdunits, @totalcmtdcost,
             @totalcmtdtax, @remcmtdtax)  --DC #122288
 	if @@error <> 0 goto posl_posting_error
 	end
 
 -- update Received not Invoiced in JCCP
 if @rniunits <> 0 or @rnicost <> 0
 	begin
 	update bJCCP
 	set RecvdNotInvcdUnits = RecvdNotInvcdUnits + @rniunits, RecvdNotInvcdCost = RecvdNotInvcdCost + @rnicost
 	where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
 	and Phase = @phase and CostType = @jcctype
 	if @@rowcount = 0
 		begin
 		insert bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, RecvdNotInvcdUnits, RecvdNotInvcdCost)
 		values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, @rniunits, @rnicost)
 		if @@error <> 0 goto posl_posting_error
 		end
 	end
 
 -- delete current row from cursor
 delete from bAPJC where APCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
 and PhaseGroup = @phasegroup and Phase = @phase and	JCCType = @jcctype and BatchSeq = @seq 
 and APLine = @apline and OldNew = @oldnew
 if @@rowcount <> 1
 	begin
 	select @errmsg = 'Unable to remove posted distributions from APJC.', @rcode = 1
 	goto posl_posting_error
 	end
 
 commit transaction
 
 goto posl_posting_loop
 
 posl_posting_error:
 	rollback transaction
 	goto bspexit
 
 posl_posting_end:       -- finished with PO & SL transactions requiring detail committed cost updates
 	close bcPOSL
 	deallocate bcPOSL
 	select @openPOSLcursor = 0
 
 -- JC Interface Level = 0 - No Actuals, but must update changes to Remaining Committed and Recvd n/Invcd
 if @jcinterfacelvl = 0
     begin
     declare bcLvl0 cursor LOCAL FAST_FORWARD
 	for select JCCo, Job, PhaseGroup, Phase, JCCType, convert(numeric(12,3), sum(RNIUnits)),
         convert(numeric(12,2), sum(RNICost)), convert(numeric(12,2), sum(RemCmtdCost)),
 		convert(numeric(12,3), sum(RemCmtdUnits)), convert(numeric(12,2), sum(TotalCmtdCost)),
 		convert(numeric(12,3), sum(TotalCmtdUnits))
     from bAPJC where APCo = @co and Mth = @mth and BatchId = @batchid
     group by JCCo, Job, PhaseGroup, Phase, JCCType
 
     -- open cursor
     open bcLvl0
     select @openLvl0cursor = 1
 
     -- loop through all rows in cursor
     lvl0_posting_loop:
 	fetch next from bcLvl0 into @jcco, @job, @phasegroup, @phase, @jcctype, @rniunits, 
 			@rnicost, @remcmtdcost, @remcmtdunits, @totalcmtdcost, @totalcmtdunits
 
 	if @@fetch_status = -1 goto lvl0_posting_end
 	if @@fetch_status <> 0 goto lvl0_posting_loop
 	 
 	-- get Remaining Committed Units - only come from PO and SLs
 	-- commented out per #19926 - remcmtdunits are set in bAPJC for PO or SL
 	/* select @jccmtdunits = 0
 		select @jccmtdunits = isnull(sum(JCUnits),0)
 		from bAPJC
 		where APCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco
 		and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype
 		and (PO is not null or SL is not null)*/
 
 	begin transaction
 
 	-- update Remaining Committed and Received not Invoiced in JCCP
 	-- #19926 - update/insert RemCmtdUnits/Cost, TotalCmtdUnits/Cost 
 	if /*@jccmtdunits*/ @remcmtdunits <> 0 or @rniunits <> 0 or @rnicost <> 0 or @remcmtdcost <> 0
 			or @totalcmtdunits <> 0 or @totalcmtdcost <> 0
 		begin
 		update bJCCP
 		set RemainCmtdUnits = RemainCmtdUnits + @remcmtdunits /*- @jccmtdunits*/,
 				RemainCmtdCost = RemainCmtdCost + @remcmtdcost,RecvdNotInvcdUnits = RecvdNotInvcdUnits + @rniunits,
 				RecvdNotInvcdCost = RecvdNotInvcdCost + @rnicost, TotalCmtdUnits = TotalCmtdUnits + @totalcmtdunits,
 				TotalCmtdCost = TotalCmtdCost + @totalcmtdcost
 		where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
 		and Phase = @phase and CostType = @jcctype
 		if @@rowcount = 0
 			begin
 			insert bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, RemainCmtdUnits, RemainCmtdCost,
                     RecvdNotInvcdUnits, RecvdNotInvcdCost,TotalCmtdUnits, TotalCmtdCost)
 			values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, @remcmtdunits /*-(@jccmtdunits)*/,
 					 @remcmtdcost,@rniunits, @rnicost, @totalcmtdunits, @totalcmtdcost)
 			if @@error <> 0 goto lvl0_posting_error
 			end
 		end
 
 	-- delete current row from cursor
 	delete from bAPJC where APCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
 	and PhaseGroup = @phasegroup and Phase = @phase and	JCCType = @jcctype
 
 	commit transaction
 
 	goto lvl0_posting_loop
 
 	lvl0_posting_error:
 		rollback transaction
 		goto bspexit
 
 	lvl0_posting_end:       -- finished JC inteface level 0 - none
         close bcLvl0
         deallocate bcLvl0
         select @openLvl0cursor = 0
 
 end
 
 -- JC Interface Level = 1 - Line - One entry in JCCD per Job/Phase/CT/AP Trans#/Line #
 if @jcinterfacelvl = 1
     begin
     declare bcLvl1 cursor LOCAL FAST_FORWARD
 	for select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, APLine, OldNew,
         APTrans, VendorGroup, Vendor, APRef, InvDate, SL, SLItem, PO, POItem, POItemLine,
         MatlGroup, Material, LineDesc, GLCo, GLAcct, UM, Units, JCUM, JCUnits,
         JCUnitCost, ECM, TotalCost, RNIUnits, RNICost, RemCmtdCost,TaxGroup,
 		TaxCode, TaxType, TaxBasis, TaxAmt, RemCmtdUnits,TotalCmtdUnits, TotalCmtdCost,
 		TotalCmtdTax, RemCmtdTax --DC #122288
 	from bAPJC where APCo = @co and Mth = @mth and BatchId = @batchid
 
     -- open cursor
     open bcLvl1
     select @openLvl1cursor = 1
 
     -- loop through all rows in cursor
     lvl1_posting_loop:
 	fetch next from bcLvl1 into @jcco, @job, @phasegroup, @phase, @jcctype, @seq,
         @apline, @oldnew, @aptrans, @vendorgroup, @vendor, @apref, @invdate,
  	    @sl, @slitem, @po, @poitem, @POItemLine, @matlgroup, @material, @linedesc, @glco, @glacct,
         @um, @units, @jcum, @jcunits, @jcunitcost, @ecm, @totalcost, @rniunits,
         @rnicost, @remcmtdcost, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt,
 		@remcmtdunits,@totalcmtdunits, @totalcmtdcost,
 		@totalcmtdtax, @remcmtdtax  --DC #122288
 
 	if @@fetch_status = -1 goto lvl1_posting_end
 	if @@fetch_status <> 0 goto lvl1_posting_loop
 		
 		
 	-- get Remaining Committed Units - must be a PO or SL
 	-- commented out per #19926 - remcmtdunits are set in bAPJC for PO or SL
 	/*select @jccmtdunits = 0
 		if @sl is not null or @po is not null select @jccmtdunits = isnull(@jcunits,0)*/
 
 	begin transaction
 
 	-- add JC Cost Detail - update Actuals only
 	if @units <> 0 or @totalcost <> 0 or @taxbasis <> 0
 		begin
 		-- get next available transaction # for JCCD
 		exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @msg output
 		if @jctrans = 0
 			begin
 			select @errmsg = 'Unable to update JC Cost Detail.  ' + isnull(@msg,''), @rcode=1
 			goto lvl1_posting_error
 			end
 
 		-- add JC Cost Detail entry
 		insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
                 JCTransType, Source, Description, BatchId, PostedUM, PostedUnitCost,
                 PostedUnits, PostedECM, UM, ActualUnitCost, PerECM, ActualUnits, ActualCost,
                 APCo, VendorGroup, Vendor, APRef, SL, SLItem, PO, POItem, POItemLine, MatlGroup,
                 Material, GLCo, GLTransAcct, APTrans, APLine, TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt,
                 TotalCmtdTax, RemCmtdTax)  --DC #122288
 		values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @invdate,
                 'AP', 'AP Entry', @linedesc, @batchid, @um, case when @units <> 0 then @totalcost/@units else 0 end,
                 @units, @ecm, @jcum, @jcunitcost, @ecm, @jcunits, @totalcost,
                 @co, @vendorgroup, @vendor, @apref, @sl, @slitem, @po, @poitem, @POItemLine, @matlgroup,
                 @material, @glco, @glacct, @aptrans, @apline, @taxtype, @taxgroup, @taxcode, @taxbasis, @taxamt,
                 @totalcmtdtax, @remcmtdtax)  --DC #122288
 		if @@error <> 0 goto lvl1_posting_error
 		end
 
 	-- update Remaining Committed and Received not Invoiced in JCCP
 
 	-- #19926 - update/insert RemCmtdUnits/Cost, TotalCmtdUnits/Cost 
 	if @rniunits <> 0 or @rnicost <> 0 or /*@jccmtdunits*/ @remcmtdunits <> 0 or @remcmtdcost <> 0
 			or @totalcmtdunits <> 0 or @totalcmtdcost <> 0
 		begin
 		update bJCCP
  	        set RemainCmtdUnits = RemainCmtdUnits + @remcmtdunits /*- @jccmtdunits*/, RemainCmtdCost = RemainCmtdCost + @remcmtdcost,
                 RecvdNotInvcdUnits = RecvdNotInvcdUnits + @rniunits, RecvdNotInvcdCost = RecvdNotInvcdCost + @rnicost,
 				TotalCmtdUnits = TotalCmtdUnits + @totalcmtdunits, TotalCmtdCost = TotalCmtdCost + @totalcmtdcost
 		where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
 		and Phase = @phase and CostType = @jcctype
 		if @@rowcount = 0
 			begin
 			-- select @jccmtdunits = isnull(@jccmtdunits,0)
 			insert bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, RemainCmtdUnits, RemainCmtdCost,
                     RecvdNotInvcdUnits, RecvdNotInvcdCost, TotalCmtdUnits, TotalCmtdCost)
 			values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, @remcmtdunits /* -(@jccmtdunits)*/,
 					@remcmtdcost,@rniunits, @rnicost, @totalcmtdunits, @totalcmtdcost)
 			if @@error <> 0 goto lvl1_posting_error
 			end
 		end
 
 	-- delete current row from cursor
 	delete from bAPJC where APCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
 	and PhaseGroup = @phasegroup and Phase = @phase and	JCCType = @jcctype and BatchSeq = @seq 
 	and APLine = @apline and OldNew = @oldnew
 	if @@rowcount <> 1
 		begin
 		select @errmsg = 'Unable to remove posted distributions from APJC.', @rcode = 1
 		goto lvl1_posting_error
 		end
 
 	commit transaction
 
 	goto lvl1_posting_loop
 
     lvl1_posting_error:
         rollback transaction
         goto bspexit
 
     lvl1_posting_end:       -- finished with JC interface level 1 - Line
         close bcLvl1
         deallocate bcLvl1
         select @openLvl1cursor = 0
 
 end
 
 -- JC Interface Level = 2 - Transaction - One entry in JCCD per Job/Phase/CT/AP Trans#
 if @jcinterfacelvl = 2
     begin
     declare bcLvl2 cursor LOCAL FAST_FORWARD
 	for select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, OldNew, Vendor, APRef, TransDesc, InvDate,
         TaxGroup, TaxCode, TaxType,
     	convert(numeric(12,3), sum(JCUnits)), convert(numeric(12,2), sum(TotalCost)),
 		convert(numeric(12,3), sum(RNIUnits)),convert(numeric(12,2), sum(RNICost)),
 		convert(numeric(12,2), sum(RemCmtdCost)),convert(numeric(12,2), sum(TaxBasis)),
 		convert(numeric(12,2), sum(TaxAmt)), convert(numeric(12,3), sum(RemCmtdUnits)),
 		convert(numeric(12,3), sum(TotalCmtdUnits)), convert(numeric(12,2), sum(TotalCmtdCost)),
 		convert(numeric(12,2), sum(TotalCmtdTax)), convert(numeric(12,2), sum(RemCmtdTax))  --DC #122288
     from bAPJC
     where APCo = @co and Mth = @mth and BatchId = @batchid
     group by JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, OldNew, Vendor, APRef, TransDesc, InvDate,
         	 TaxGroup, TaxCode, TaxType
 
     -- open cursor
     open bcLvl2
     select @openLvl2cursor = 1
 
     -- loop through all rows in cursor
     lvl2_posting_loop:
 	fetch next from bcLvl2 into @jcco, @job, @phasegroup, @phase, @jcctype, @seq, @oldnew,
             @vendor, @apref, @transdesc, @invdate, @taxgroup, @taxcode, @taxtype, @jcunits, 
 			@totalcost, @rniunits, @rnicost, @remcmtdcost, @taxbasis, @taxamt, @remcmtdunits,
 			@totalcmtdunits, @totalcmtdcost,
 			@totalcmtdtax, @remcmtdtax  --DC #122288
 
         if @@fetch_status = -1 goto lvl2_posting_end
         if @@fetch_status <> 0 goto lvl2_posting_loop
 
 		
         -- get additional info for JC update from APJC
         select @aptrans = APTrans, @vendorgroup = VendorGroup, @jcum = JCUM
         from bAPJC with (nolock)
         where APCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
             and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype and BatchSeq = @seq
             and Vendor = @vendor and isnull(APRef,'') = isnull(@apref,'')
             and isnull(TransDesc,'') = isnull(@transdesc,'') and InvDate = @invdate
             and isnull(TaxGroup,0) = isnull(@taxgroup,0) and isnull(TaxCode,'') = isnull(@taxcode,'')
             and isnull(TaxType,0) = isnull(@taxtype,0)
 
         -- calculate Unit Cost
         select @jcunitcost = 0, @ecm = 'E'
         if @jcunits <> 0 select @jcunitcost = @totalcost / @jcunits
 
         -- get Remaining Committed Units - only come from PO and SLs
 		-- commented out per #19926 - Remaining Committed units are set in bAPJC for PO or SL
         /*select @jccmtdunits = 0
         select @jccmtdunits = isnull(sum(JCUnits),0)
         from bAPJC
         where APCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco
             and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype
             and BatchSeq = @seq and (PO is not null or SL is not null)*/
 
         begin transaction
 
         -- add JC Cost Detail - update Actuals only
         if @jcunits <> 0 or @totalcost <> 0 or @taxbasis <> 0
             begin
             -- get next available transaction # for JCCD
             exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @msg output
  	        if @jctrans = 0
                 begin
    	            select @errmsg = 'Unable to update JC Cost Detail.  ' + isnull(@msg,''), @rcode=1
                 goto lvl2_posting_error
        	        end
             -- add JC Cost Detail entry
             insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
                 JCTransType, Source, Description, BatchId, UM, ActualUnitCost, PerECM, ActualUnits,
                 ActualCost, APCo, VendorGroup, Vendor, APRef, APTrans, TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt,
                 TotalCmtdTax, RemCmtdTax)  --DC #122288
             values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @invdate,
                 'AP', 'AP Entry', @transdesc, @batchid, @jcum, @jcunitcost, @ecm, @jcunits,
                 @totalcost, @co, @vendorgroup, @vendor, @apref, @aptrans, @taxtype, @taxgroup, @taxcode, @taxbasis, @taxamt,
                 @totalcmtdtax, @remcmtdtax)  --DC #122288
             end
 
         -- update Remaining Committed and Received not Invoiced in JCCP
 		-- #19926 - update/insert RemCmtdUnits/Cost, TotalCmtdUnits/Cost 
         if @rniunits <> 0 or @rnicost <> 0 or /*@jccmtdunits*/@remcmtdunits <> 0 or @remcmtdcost <> 0
 			or @totalcmtdunits <> 0 or @totalcmtdcost <> 0 
             begin
             update bJCCP
  	        set RemainCmtdUnits = RemainCmtdUnits + @remcmtdunits /*- @jccmtdunits*/, RemainCmtdCost = RemainCmtdCost + @remcmtdcost,
                 RecvdNotInvcdUnits = RecvdNotInvcdUnits + @rniunits, RecvdNotInvcdCost = RecvdNotInvcdCost + @rnicost,
 				TotalCmtdUnits = TotalCmtdUnits + @totalcmtdunits, TotalCmtdCost = TotalCmtdCost + @totalcmtdcost
             where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
                 and Phase = @phase and CostType = @jcctype
             if @@rowcount = 0
                 begin
                 insert bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, RemainCmtdUnits, RemainCmtdCost,
                     RecvdNotInvcdUnits, RecvdNotInvcdCost, TotalCmtdUnits, TotalCmtdCost)
                 values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, @remcmtdunits /*-(@jccmtdunits)*/, @remcmtdcost,
                     @rniunits, @rnicost, @totalcmtdunits, @totalcmtdcost)
                 if @@error <> 0 goto lvl2_posting_error
                 end
             end
 
         -- delete current row from cursor
   	    delete from bAPJC
         where APCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
             and PhaseGroup = @phasegroup and Phase = @phase and	JCCType = @jcctype and
             BatchSeq = @seq and Vendor = @vendor and isnull(APRef,'') = isnull(@apref,'')
             and isnull(TransDesc,'') = isnull(@transdesc,'') and InvDate = @invdate and OldNew = @oldnew
             and isnull(TaxGroup,0) = isnull(@taxgroup,0) and isnull(TaxCode,'') = isnull(@taxcode,'')
             and isnull(TaxType,0) = isnull(@taxtype,0)
 
         if @@rowcount = 0
            begin
  	        select @errmsg = 'Unable to remove posted distributions from APJC.', @rcode = 1
   	        goto lvl2_posting_error
  	        end
 
         commit transaction
 
         goto lvl2_posting_loop
 
     lvl2_posting_error:
         rollback transaction
         goto bspexit
 
     lvl2_posting_end:       -- finished with JC interface level 2 - Transaction
         close bcLvl2
         deallocate bcLvl2
 
 	select @openLvl2cursor = 0
     end
 
 
 
 bspexit:
     if @openPOSLcursor = 1
         begin
  		close bcPOSL
  		deallocate bcPOSL
  		end
 
     if @openLvl0cursor = 1
         begin
  		close bcLvl0
  		deallocate bcLvl0
  		end
 
     if @openLvl1cursor = 1
         begin
  		close bcLvl1
  		deallocate bcLvl1
  		end
 
     if @openLvl2cursor = 1
         begin
  		close bcLvl2
  		deallocate bcLvl2
  		end
 
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPHBPostJC] TO [public]
GO
