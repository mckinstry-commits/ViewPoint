SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/******************************************************/
CREATE procedure [dbo].[bspMSTBValJob]
/*****************************************************************************
 * Created By:	GG 10/21/00
 * Modified By: danf 01/29/00 correct begin and ending syntax around tax code
 *				GF 03/02/2001 - issue 12984 problem with nulls.
 *				GG 11/12/01 - #15029 - recalc 'posted unit price' with JC dist only haul or tax amts included
 *				GG 01/14/02 - #15397 - fix conversion to JC units 
 *				SR 07/09/02 17738 pass @phasegroup to bspJCVCOSTTYPE
 *				SR 07/14/02 -17892 - put isnulls around @jchrs on inserting into MSJC
 *				DANF 09/05/02 - 17738 Added Phase Group to bspJCCAGlacctDflt
 *				GF 03/17/2003 - issue #20722 incorrect update of JCCD.ActualUnits
 *				GF 09/03/2003 - issue #22326 need to check for null GL acct before insert into MSJC.
 *				GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
 *				GF 05/02/2004 - #24418 - added @emgroup and @revcode as input params to add to bMSJC new columns.
 *				GG 07/27/04 - #25218 - fix tax updates to bMSJC
 *				MV 01/14/05 - #21648 - set actuals to 0 in bMSJC if UpdateMSActualsYN='N'
 *				GF 09/13/2006 - #122420 - added input parameter for @haulvendor to write to JC distribution table.
 *				GF 11/16/2006 - #123132 - remmed out using @haulvendor when one distribution record only
 *				GF 07/08/2008 - issue #128290 international tax GST/PST
 *				GF 03/29/2010 - issue #129350 surcharges
 *				GF 04/05/2013 TFS-46115 more information for surcharge ticket errors
 *
 *
 *			 
 * USAGE:
 *   Called by bspMSTBValDist to create JC and GL distributions related to
 *   a Job ticket.
 *
 *   Adds/updates entries in bMSJC and bMSGL.
 *
 *   Errors in batch added to bHQBE using bspHQBEInsert
 *
 * INPUT PARAMETERS
 *   @msco           MS/IN Co#
 *   @mth            Batch month
 *   @batchid        Batch ID
 *   @seq            Batch Sequence
 *   @oldnew         0 = old (use old values from bMSTB, reverse sign on amounts),
 *                   1 = new (use current values from bMSTB)
 *   @fromloc        Sold from IN Location
 *   @mstrans        MS Trans (null if new entry)
 *   @ticket         Ticket #
 *   @saledate       Sale date
 *   @vendorgroup    Vendor Group
 *   @matlvendor     Material Vendor (null if sold from stock)
 *   @matlgroup      Material Group
 *   @material       Material sold
 *   @jcco           JC Co#
 *   @job            Job
 *   @phasegroup     Phase Group
 *   @toglco         JC GL Co#
 *   @jcmatlglacct   Job Expense Account for material
 *   @emco           EM Co#
 *   @equipment      Equipment used for delivery
 *	@emgroup		EM Group
 *	@revcode		EM Revenue Code
 *   @prco           PR Co#
 *   @employee       Employee operating Equipment
 *   @matlphase      Material Phase
 *   @matljcct       Material JC Cost Type
 *   @matlunits      Units sold
 *   @matlum         Posted unit of measure
 *   @stdum          Standard unit of measure
 *   @umconv         Conversion fator to std u/m
 *   @matltotal      Total material charge
 *   @haulphase      Haul Phase
 *   @hauljcct       Haul JC Cost Type
 *   @haulbasis      Haul units
 *   @haultotal      Haul charge
 *   @hrs            Hours
 *   @taxgroup       Tax Group
 *   @taxcode        Tax Code
 *   @taxtype        Tax Type (1 = Sales, 2 = Use)
 *   @taxbasis       Taxable basis amount
 *   @taxtotal       Tax amount
 *	@unitprice		Material unit price
 *	@ecm			Material unit price per E,C,M
 *	 @haulvendor	 Haul Vendor
 *	@gsttaxamt		GST Tax Amount
 *  @SurchargeKeyID MSTB KeyID for surcharge record
 *  @SurchargeCode  SurchargeCode
 *
 *
 * OUTPUT PARAMETERS
 *   @errmsg        error message
 *
 * RETURN
 *   0 = success, 1 = error
 *
 *******************************************************************************/
 (@msco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @oldnew tinyint, @fromloc bLoc,
  @mstrans bTrans, @ticket bTic, @saledate bDate, @vendorgroup bGroup, @matlvendor bVendor,
  @matlgroup bGroup, @material bMatl, @jcco bCompany, @job bJob, @phasegroup bGroup,
  @toglco bCompany, @jcmatlglacct bGLAcct, @emco bCompany, @equipment bEquip, @emgroup bGroup,
  @revcode bRevCode, @prco bCompany, @employee bEmployee, @matlphase bPhase, @matljcct bJCCType,
  @matlunits bUnits, @matlum bUM, @stdum bUM, @umconv bUnits, @matltotal bDollar, @haulcode bHaulCode, 
  @haulphase bPhase, @hauljcct bJCCType, @haulbasis bUnits, @haultotal bDollar, @hrs bHrs, @taxgroup bGroup,
  @taxcode bTaxCode, @taxtype tinyint, @taxbasis bDollar, @taxtotal bDollar, @unitprice bUnitCost,
  @ecm bECM, @haulvendor bVendor, @gsttaxamt bDollar, @SurchargeKeyID bigint = null, @SurchargeCode smallint = null, ---- #129350
  @errmsg varchar(255) output)
 as
 set nocount on
 
 declare @rcode int, @errorstart varchar(80), @haulposted tinyint, @taxposted tinyint, @taxphase bPhase, @taxjcct bJCCType,
 		@sendjcct varchar(5), @um bUM, @jcum bUM, @msg varchar(255), @jcunits bUnits, @jcumconv bUnitCost, @jctotal bDollar,
 		@jchrs bHrs, @jctaxgroup bGroup, @jctaxcode bTaxCode, @jctaxtype tinyint, @jctaxbasis bDollar, @jctaxtotal bDollar,
 		@jcunitcost bUnitCost, @jchaulglacct bGLAcct, @haulcodebasis tinyint, @haulcodeum bUM,
 		@haulunits bUnits, @haulum bUM, @jctaxglacct bGLAcct, @errortext varchar(255), @revbased bYN, @updateactuals bYN,
		@tempvendor bVendor
		----TFS-46115
		,@ParentSeq INT
   
 select @rcode = 0
 
 ----TFS-46115
SET @errorstart = 'Seq# ' + dbo.vfToString(@seq)
IF @SurchargeKeyID IS NOT NULL
	BEGIN
	SELECT @ParentSeq = MSTB.BatchSeq
	FROM dbo.bMSTB MSTB WITH (NOLOCK)
	WHERE MSTB.KeyID = @SurchargeKeyID
	IF @@ROWCOUNT = 1
		BEGIN
		SELECT @errorstart = @errorstart + ' Parent Seq: ' + dbo.vfToString(@ParentSeq) + ' Surcharge Code: ' + dbo.vfToString(@SurchargeCode)
		END
	END
    
 select @updateactuals = UpdateMSActualsYN from JCJM with (nolock) where JCCo=@jcco and Job=@job
   
 -- process Job sale (skipped if posted to another GL Co# and using Interco invoicing option)
 select @haulposted = 0, @taxposted = 0, @tempvendor = null  -- indicates whether haul and tax have been posted for the seq

---- back out GST from tax total
select @taxtotal = @taxtotal - @gsttaxamt

-- get Tax info
if @taxcode is not null
   begin
   select @taxphase = Phase, @taxjcct = JCCostType
   from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid Tax Code!', @rcode = 1    -- already validated
       goto bspexit
       end
   end
-- use posted material phase and cost type unless overridden by tax code
if @taxphase is null select @taxphase = @matlphase
if @taxjcct is null select @taxjcct = @matljcct
   
   -- get JC UM for material phase and cost type
   select @sendjcct = convert(varchar(5),@matljcct), @jcunits = 0
   exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup,@matlphase, @sendjcct, 'N', @um = @jcum output, @msg = @errmsg output
   if @rcode = 1 goto bspexit  -- already validated
   
   -- if JC u/m equals posted u/m, set JC units equal to posted
   if @jcum = @matlum
       begin
       select @jcunits = @matlunits
       end
   else
       begin
       -- get conversion for JC unit of measure (if none found, JC units will be 0)
       select @jcumconv = 1
       if @jcum <> @stdum
           begin
           select @jcumconv = Conversion
           from bINMU with (nolock) 
           where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material and UM = @jcum
  		 if @@rowcount = 0 select @jcumconv = 0
           end
       if @jcumconv <> 0 select @jcunits = @matlunits * (@umconv / @jcumconv)
       end
   
   -- initialize amounts
   select @jctotal = @matltotal, @jchrs = 0, @jctaxgroup = null, @jctaxcode = null, @jctaxtype = null,
       @jctaxbasis = 0, @jctaxtotal = 0, @jcunitcost = 0
   
   if (@haulphase = @matlphase and @hauljcct = @matljcct)
       select @jctotal = @jctotal + @haultotal, @jchrs = @hrs, @haulposted = 1  -- include haul
   
   if (@taxphase = @matlphase and @taxjcct = @matljcct)
       select @jctotal = @jctotal + @taxtotal, @jctaxgroup = @taxgroup, @jctaxcode = @taxcode, @jctaxtype = @taxtype,
           @jctaxbasis = @taxbasis, @jctaxtotal = @taxtotal, @taxposted = 1 -- include tax
  
  if @jcunits <> 0 select @jcunitcost = (@jctotal / @jcunits) -- unit cost per jc um
  -- use 'posted unit price' if JC units and amount match posted values 
  if @jcunits = @matlunits and @jctotal = @matltotal and @ecm = 'E' select @jcunitcost = @unitprice
  -- recalc 'posted unit price' only if haul or tax amounts included
  if @jctotal <> @matltotal and @matlunits <> 0 select @unitprice = (@jctotal / @matlunits), @ecm = 'E'  -- recalc unit price
  
  --make sure we don't have any null values
  if @jcunits is null select @jcunits = 0
  if @jcunitcost is null select @jcunitcost = 0
  if @unitprice is null select @unitprice = 0
  if @ecm is null select @ecm = 'E'
  -- check for null matl GL Acct
  if @jcmatlglacct is null
 	begin
 	select @errortext = @errorstart + ' - Missing Matl GL Acct for Phase: ' + isnull(@matlphase,'') + ' , Cost Type: ' + isnull(convert(varchar(3),@matljcct),'') + ' !'
     exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
 	goto bspexit
 	end
 
 -- -- check bMSHC haul code to see if revenue based. If 'Y' then load @revcode into bMSJC else null for @revcode
 if isnull(@haulcode,'') <> ''
 	begin
 	select @revbased=RevBased from bMSHC where MSCo=@msco and HaulCode=@haulcode
 	if @@rowcount = 0 or @revbased = 'N' set @revcode = null
 	end
 else
 	begin
 	set @revcode = null
 	end
 
---- if @haulposted = 1 and @matlvendor is null use @haulvendor else @matlvendor
---- issue #123132
select @tempvendor = @matlvendor
-- -- if @haulposted = 1 and @matlvendor is null
-- -- 	begin
-- -- 	select @tempvendor = @haulvendor
-- -- 	end

---- add JC distribution
insert bMSJC(MSCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, FromLoc, MatlGroup,
	Material, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate, VendorGroup, Vendor, GLCo, GLAcct,
	Hrs, UM, Units, UnitPrice, ECM, Amount, JCUM, JCUnits, JCUnitCost, EMCo, Equipment,
	PRCo, Employee, TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal, EMGroup, RevCode)
values(@msco, @mth, @batchid, @jcco, @job, @phasegroup, @matlphase, @matljcct, @fromloc, @matlgroup,
	@material, @seq, 0, @oldnew, @mstrans, @ticket, @saledate, @vendorgroup, @tempvendor, /*@matlvendor,*/ @toglco, @jcmatlglacct,
	isnull(@jchrs,0), @matlum, @matlunits, @unitprice, @ecm, @jctotal, @jcum,
	case @updateactuals when 'Y' then @jcunits else 0 end, 
	case @updateactuals when 'Y' then @jcunitcost else 0 end, @emco, @equipment,
	@prco, @employee, @jctaxgroup, @jctaxcode, @jctaxtype, @jctaxbasis, @jctaxtotal, @emgroup, @revcode)

---- validate Job Expense Account for material
exec @rcode = dbo.bspGLACfPostable @toglco, @jcmatlglacct, 'J', @errmsg output
if @rcode <> 0
	begin
	select @errortext = @errorstart + ' - Job Account for material ' + isnull(@errmsg,'')
	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
	goto bspexit
	end

-- Job Expense debit for material (may include haul and/or tax)
update bMSGL set Amount = Amount + @jctotal
where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @jcmatlglacct
and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
if @@rowcount = 0
	begin
	insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
		FromLoc, MatlGroup, Material, SaleType, JCCo, Job, Amount)
	values(@msco, @mth, @batchid, @toglco, @jcmatlglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
		@fromloc, @matlgroup, @material, 'J', @jcco, @job, @jctotal)
	end
   
   -- Haul distributions (if not included with material)
   if @haultotal <> 0 and @haulposted = 0  -- not posted with material
       begin
       -- get Job Expense Account for haul
       exec @rcode = dbo.bspJCCAGlacctDflt @jcco, @job, @phasegroup, @haulphase, @hauljcct, 'N', @jchaulglacct output, @errmsg output
       if @rcode = 1 goto bspexit
       -- get Haul Code info
       select @haulcodebasis = HaulBasis, @haulcodeum = UM
       from bMSHC with (nolock) where MSCo = @msco and HaulCode = @haulcode
       if @@rowcount = 0
           begin
           select @errmsg = 'Invalid Haul Code!', @rcode = 1   -- already validated
           goto bspexit
           end
       -- determine units and u/m
       select @haulunits = 0, @haulum = null, @jchrs = 0, @unitprice = 0
       if @haulcodebasis = 1 select @haulunits = @haulbasis, @haulum = @matlum     -- unit based, use posted um
       if @haulcodebasis = 2 select @jchrs = @hrs  -- hourly based, no units
       if @haulcodebasis in (3,4,5) select @haulunits = @haulbasis, @haulum = @haulcodeum  -- use haul code um
   
       -- get JC UM
       select @sendjcct = convert(varchar(5),@hauljcct), @jcunits = 0, @jcunitcost = 0
       exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup,@haulphase, @sendjcct, 'N', @um = @jcum output, @msg = @errmsg output
       if @rcode = 1 goto bspexit  -- already validated
   
       -- if JC u/m equals haul u/m, set JC units equal to posted
       if @jcum = @haulum
           begin
           select @jcunits = @haulunits
           end
       else
           begin
           -- get conversion for JC unit of measure
           select @jcumconv = 1
           if @jcum <> @stdum
               begin
               select @jcumconv = Conversion
               from bINMU with (nolock) 
               where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material and UM = @jcum
  			 if @@rowcount = 0 select @jcumconv = 0
               end
           if @jcumconv <> 0 select @jcunits = @haulunits * (@umconv / @jcumconv)
           end
   
 	select @jctotal = @haultotal, @haulposted = 1
 
 	-- #25218 - initialize JC tax variables
 	select  @jctaxgroup = null, @jctaxcode = null, @jctaxtype = null, @jctaxbasis = 0, @jctaxtotal = 0
 
 	if (@taxphase = @haulphase and @taxjcct = @hauljcct and @taxposted = 0)	-- #25218 - skip if tax already posted
           select @jctotal = @jctotal + @taxtotal, @jctaxgroup = @taxgroup, @jctaxcode = @taxcode, @jctaxtype = @taxtype,
               @jctaxbasis = @taxbasis, @jctaxtotal = @taxtotal, @taxposted = 1 -- include tax
   
      if @haulunits <> 0 select @unitprice = (@jctotal / @haulunits)  -- recalc unit price
      if @jcunits <> 0 select @jcunitcost = (@haultotal / @jcunits)
      if @jcunits is null select @jcunits = 0
      if @jcunitcost is null select @jcunitcost = 0
 	 -- check for null Haul GL Acct
 	 if @jchaulglacct is null
 		begin
 		select @errortext = @errorstart + ' - Missing Haul GL Acct for Phase: ' + isnull(@haulphase,'') + ' , Cost Type: ' + isnull(convert(varchar(3),@hauljcct),'') + ' !'
 	    exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
 		goto bspexit
 		end
	

       -- add JC distribution for haul expense
       insert bMSJC(MSCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, FromLoc, MatlGroup,
           Material, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate, VendorGroup, Vendor, GLCo, GLAcct,
           Hrs, UM, Units, UnitPrice, ECM, Amount, JCUM, JCUnits, JCUnitCost, EMCo, Equipment,
           PRCo, Employee, TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal, EMGroup, RevCode)
       values(@msco, @mth, @batchid, @jcco, @job, @phasegroup, @haulphase, @hauljcct, @fromloc, @matlgroup,
           @material, @seq, 0, @oldnew, @mstrans, @ticket, @saledate, @vendorgroup, isnull(@haulvendor, @matlvendor), @toglco, @jchaulglacct,
           isnull(@jchrs,0), @haulum, @haulunits, @unitprice, 'E', @jctotal, @jcum,
 		  case @updateactuals when 'Y' then @jcunits else 0 end, 
 		  case @updateactuals when 'Y' then @jcunitcost else 0 end,@emco, @equipment,
           @prco, @employee, @jctaxgroup, @jctaxcode, @jctaxtype, @jctaxbasis, @jctaxtotal, @emgroup, @revcode)
   
       -- validate Job Expense Account for haul
       exec @rcode = dbo.bspGLACfPostable @toglco, @jchaulglacct, 'J', @errmsg output
       if @rcode <> 0
           begin
  
           select @errortext = @errorstart + ' - Job Account for hauling ' + isnull(@errmsg,'')
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
     	    goto bspexit
           end
       -- Job Expense debit for haul
       update bMSGL set Amount = Amount + @jctotal
       where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @jchaulglacct
           and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
       if @@rowcount = 0
           insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
               FromLoc, MatlGroup, Material, SaleType, JCCo, Job, Amount)
           values(@msco, @mth, @batchid, @toglco, @jchaulglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
               @fromloc, @matlgroup, @material, 'J', @jcco, @job, @jctotal)
       end
   
   -- Tax distributions (if not posted with material or haul)
   if @taxtotal <> 0 and @taxposted = 0    -- tax not posted with material or haul
      begin
      -- get Job Expense Account for tax
      exec @rcode = dbo.bspJCCAGlacctDflt @jcco, @job, @phasegroup, @taxphase, @taxjcct, 'N', @jctaxglacct output, @errmsg output
      if @rcode = 1 goto bspexit
 
      -- get JC UM
      select @sendjcct = convert(varchar(5),@taxjcct)
      exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup,@taxphase, @sendjcct, 'N', @um = @jcum output, @msg = @errmsg output
      if @rcode = 1 
 		begin
 		select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
 		exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
 		goto bspexit  -- already validated
 		end
 
 	 -- check for null Tax GL Acct
 	 if @jctaxglacct is null
 		begin
 		select @errortext = @errorstart + ' - Missing JC Expense GL Acct for Phase: ' + isnull(@taxphase,'') + ' , Cost Type: ' + isnull(convert(varchar(3),@taxjcct),'') + ' !'
 	    exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
 		goto bspexit
 		end
 
       -- add JC distribution for tax expense
       insert bMSJC(MSCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, FromLoc, MatlGroup,
           Material, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate, VendorGroup, Vendor, GLCo, GLAcct,
           Hrs, UM, Units, UnitPrice, ECM, Amount, JCUM, JCUnits, JCUnitCost, EMCo, Equipment,
           PRCo, Employee, TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal, EMGroup, RevCode)
       values(@msco, @mth, @batchid, @jcco, @job, @phasegroup, @taxphase, @taxjcct, @fromloc, @matlgroup,
           @material, @seq, 0, @oldnew, @mstrans, @ticket, @saledate, @vendorgroup, @matlvendor, @toglco, @jctaxglacct,
           0, null, 0, 0, 'E', @taxtotal, @jcum, 0, 0, @emco, @equipment,
           @prco, @employee, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxtotal, @emgroup, @revcode)
   
       -- validate Job Expense Account for tax
       exec @rcode = dbo.bspGLACfPostable @toglco, @jctaxglacct, 'J', @errmsg output
       if @rcode <> 0
           begin
           select @errortext = @errorstart + ' - Job GL account for tax ' + isnull(@errmsg,'')
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
     	    goto bspexit
           end
       -- Job Expense debit for tax
       update bMSGL set Amount = Amount + @taxtotal
       where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @jctaxglacct
           and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
       if @@rowcount = 0
           insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
               FromLoc, MatlGroup, Material, SaleType, JCCo, Job, Amount)
           values(@msco, @mth, @batchid, @toglco, @jctaxglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
               @fromloc, @matlgroup, @material, 'J', @jcco, @job, @taxtotal)
           end
  
  
  
  
 bspexit:
  	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(13) + '[bspMSTBValJob]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTBValJob] TO [public]
GO
