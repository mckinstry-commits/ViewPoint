SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   CREATE      procedure [dbo].[bspMSLBValJob]
    /*****************************************************************************
    * Created By:	GG 11/04/00
    * Modified:	GG 01/31/01 - fixed ECM update to bMSJC
    *           	GG 02/02/01 - fixed UnitPrice update to bMSJC
    *           	GG 05/11/01 - add 'begin' and 'end' to tax code validation
    *				GG 05/31/02 - #17524 - initialize JC tax basis and total
    *				SR 07/09/02 - 17738 pass @phasegroup to bspJCVCOSTTYPE
    *				SR 07/15/02 - 17892 put isnull around @jchrs for inserting into MSJC
    *           	DANF 09/05/02 - 17738 Add phase group to bspJCCAGlacctDflt
    *			 	GF 06/02/2003 - #21395 null GLAcct insert into bMSJC.
    *				GF 05/02/2004 - #24418 - added @emgroup and @revcode as input params to add to bMSJC new columns.
    *				MV 01/14/05 - #21648 - set actuals to 0 in bMSJC if UpdateMSActualsYN='N'
 *				GF 07/08/2008 - issue #128290 international tax GST/PST
    *
    * USAGE:
    *   Called by bspMSLBVal to create JC and GL distributions related to
    *   a Hauler Time Sheet line.
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
    *   @haulline       Haul Line
    *   @oldnew         0 = old (use old values from bMSLB, reverse sign on amounts),
    *                   1 = new (use current values from bMSLB)
    *   @fromloc        Sold from IN Location
    *   @mstrans        MS Trans (null if new entry)
    *   @saledate       Sale date
    *   @vendorgroup    Vendor Group
    *   @haulvendor     Material Vendor (null if sold from stock)
    *   @matlgroup      Material Group
    *   @material       Material sold
    *   @jcco           JC Co#
    *   @job            Job
    *   @phasegroup     Phase Group
    *   @toglco         JC GL Co#
    *   @emco           EM Co#
    *   @equipment      Equipment used for delivery
    *   @emgroup	EM Group
    *   @revcode	EM Revenue Code
    *   @prco           PR Co#
    *   @employee       Employee operating Equipment
    *   @matlum         Posted unit of measure
    *   @stdum          Standard unit of measure
    *   @umconv         Conversion fator to std u/m
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
 *	@gsttaxamt		GST Tax Amount
    *
    * OUTPUT PARAMETERS
    *   @errmsg        error message
    *
    * RETURN
    *   0 = success, 1 = error
    *
    *******************************************************************************/
        (@msco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @haulline smallint, @oldnew tinyint,
         @fromloc bLoc, @mstrans bTrans, @saledate bDate, @vendorgroup bGroup, @haulvendor bVendor,
         @matlgroup bGroup, @material bMatl, @jcco bCompany, @job bJob, @phasegroup bGroup, @toglco bCompany,
         @emco bCompany, @equipment bEquip, @emgroup bGroup, @revcode bRevCode, @prco bCompany, @employee bEmployee, @matlum bUM, @stdum bUM,
         @umconv bUnits, @haulcode bHaulCode, @haulphase bPhase, @hauljcct bJCCType, @haulbasis bUnits,
         @haultotal bDollar, @hrs bHrs, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint,
         @taxbasis bDollar, @taxtotal bDollar, @gsttaxamt bDollar, @errmsg varchar(255) output)
   as
   set nocount on
    
   declare @rcode int, @errorstart varchar(10), @taxposted tinyint, @taxphase bPhase, @taxjcct bJCCType,
    @sendjcct varchar(5), @um bUM, @jcum bUM, @msg varchar(255), @jcunits bUnits, @jcumconv bUnitCost, @jctotal bDollar,
    @jchrs bHrs, @jctaxgroup bGroup, @jctaxcode bTaxCode, @jctaxtype tinyint, @jctaxbasis bDollar, @jctaxtotal bDollar,
    @jcunitcost bUnitCost, @unitprice bUnitCost, @jchaulglacct bGLAcct, @haulcodebasis tinyint, @haulcodeum bUM,
    @haulunits bUnits, @haulum bUM, @jctaxglacct bGLAcct, @errortext varchar(255), @revbased bYN,@updateactuals bYN 
    
    select @rcode = 0, @errorstart = 'Seq#' + convert(varchar(6),@seq) + ' Line#' + convert(varchar(6),@haulline)
   
    select @updateactuals = UpdateMSActualsYN from JCJM with (nolock) where JCCo=@jcco and Job=@job
   
    -- process Job sale (skipped if posted to another GL Co# and using Interco invoicing option)
    select @taxposted = 0  -- indicates whether tax has been posted for the line
    
---- back out GST from tax total
select @taxtotal = @taxtotal - @gsttaxamt

    -- get Tax info
    if @taxcode is not null
        begin
        select @taxphase = Phase, @taxjcct = JCCostType
        from bHQTX where TaxGroup = @taxgroup and TaxCode = @taxcode
        if @@rowcount = 0
            begin
            select @errmsg = 'Invalid Tax Code!', @rcode = 1    -- already validated
            goto bspexit
            end
        end
    -- use posted haul phase and cost type unless overridden by tax code
    if @taxphase is null select @taxphase = @haulphase
    if @taxjcct is null select @taxjcct = @hauljcct
   
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
    
    -- Haul distributions
    if @haultotal <> 0
        begin
     	-- get Job Expense Account for haul
        exec @rcode = dbo.bspJCCAGlacctDflt @jcco, @job, @phasegroup, @haulphase, @hauljcct, 'N', @jchaulglacct output, @errmsg output
        if @rcode = 1 goto bspexit
   	 if @jchaulglacct is null
   		begin
   		select @errmsg = @errorstart + ' - Missing Haul Job Expense Account!', @rcode = 1
   		goto bspexit
   		end
        -- get Haul Code info
        select @haulcodebasis = HaulBasis, @haulcodeum = UM
        from bMSHC where MSCo = @msco and HaulCode = @haulcode
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
            select @jcumconv = 0
            if @jcum <> @stdum
                begin
                select @jcumconv = Conversion
                from bINMU
                where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material and UM = @jcum
                end
            if @jcumconv <> 0 select @jcunits = @haulunits * (@umconv / @jcumconv)
            end
    
        select @jctotal = @haultotal, @jctaxbasis = 0, @jctaxtotal = 0
    
        if (@taxphase = @haulphase and @taxjcct = @hauljcct)
            select @jctotal = @jctotal + @taxtotal, @jctaxgroup = @taxgroup, @jctaxcode = @taxcode, @jctaxtype = @taxtype,
                @jctaxbasis = @taxbasis, @jctaxtotal = @taxtotal, @taxposted = 1 -- include tax
    
        if @haulunits <> 0 select @unitprice = (@jctotal / @haulunits)  -- recalc unit price
        if @jcunits <> 0 select @jcunitcost = (@haultotal / @jcunits)
        if @jcunits is null select @jcunits = 0
        if @jcunitcost is null select @jcunitcost = 0
    
        -- add JC distribution for haul expense
        insert bMSJC(MSCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, FromLoc, MatlGroup,
            Material, BatchSeq, HaulLine, OldNew, MSTrans, SaleDate, VendorGroup, Vendor, GLCo, GLAcct,
            Hrs, UM, Units, UnitPrice, ECM, Amount, JCUM, JCUnits, JCUnitCost, EMCo, Equipment,
            PRCo, Employee, TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal, EMGroup, RevCode)
        values(@msco, @mth, @batchid, @jcco, @job, @phasegroup, @haulphase, @hauljcct, @fromloc, @matlgroup,
            @material, @seq, @haulline, @oldnew, @mstrans, @saledate, @vendorgroup, @haulvendor, @toglco, @jchaulglacct,
            isnull(@jchrs,0), @haulum, @haulunits, @unitprice, 'E', @jctotal, @jcum,
   		 case @updateactuals when 'Y' then @jcunits else 0 end, 
   		 case @updateactuals when 'Y' then @jcunitcost else 0 end, @emco, @equipment,
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
            and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
        if @@rowcount = 0
            insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, SaleDate,
                FromLoc, MatlGroup, Material, SaleType, JCCo, Job, Amount)
            values(@msco, @mth, @batchid, @toglco, @jchaulglacct, @seq, @haulline, @oldnew, @mstrans, @saledate,
                @fromloc, @matlgroup, @material, 'J', @jcco, @job, @jctotal)
        end
    
    -- Tax distributions (if not posted with material or haul)
    if @taxtotal <> 0 and @taxposted = 0    -- tax not posted with haul
        begin
        -- get Job Expense Account for tax
        exec @rcode = dbo.bspJCCAGlacctDflt @jcco, @job, @phasegroup, @taxphase, @taxjcct, 'N', @jctaxglacct output, @errmsg output
        if @rcode = 1 goto bspexit
        -- get JC UM
        select @sendjcct = convert(varchar(5),@taxjcct)
        exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup, @taxphase, @sendjcct, 'N', @um = @jcum output, @msg = @errmsg output
        if @rcode = 1 goto bspexit  -- already validated
    
        -- add JC distribution for tax expense
        insert bMSJC(MSCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, FromLoc, MatlGroup,
            Material, BatchSeq, HaulLine, OldNew, MSTrans, SaleDate, VendorGroup, Vendor, GLCo, GLAcct,
            Hrs, UM, Units, UnitPrice, ECM, Amount, JCUM, JCUnits, JCUnitCost, EMCo, Equipment,
            PRCo, Employee, TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal, EMGroup, RevCode)
        values(@msco, @mth, @batchid, @jcco, @job, @phasegroup, @taxphase, @taxjcct, @fromloc, @matlgroup,
            @material, @seq, @haulline, @oldnew, @mstrans, @saledate, @vendorgroup, @haulvendor, @toglco, @jctaxglacct,
            0, null, 0, 0, 'E', @taxtotal, @jcum, 0, 0, @emco, @equipment,
            @prco, @employee, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxtotal, @emgroup, @revcode)
    
        -- validate Job Expense Account for tax
        exec @rcode = bspGLACfPostable @toglco, @jctaxglacct, 'J', @errmsg output
        if @rcode <> 0
            begin
            select @errortext = @errorstart + ' - Job GL account for tax ' + isnull(@errmsg,'')
            exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	    goto bspexit
            end
        -- Job Expense debit for tax
        update bMSGL set Amount = Amount + @taxtotal
        where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @jctaxglacct
            and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
        if @@rowcount = 0
            insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, SaleDate,
                FromLoc, MatlGroup, Material, SaleType, JCCo, Job, Amount)
            values(@msco, @mth, @batchid, @toglco, @jctaxglacct, @seq, @haulline, @oldnew, @mstrans, @saledate,
                @fromloc, @matlgroup, @material, 'J', @jcco, @job, @taxtotal)
            end
   
   
   
   bspexit:
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSLBValJob] TO [public]
GO
