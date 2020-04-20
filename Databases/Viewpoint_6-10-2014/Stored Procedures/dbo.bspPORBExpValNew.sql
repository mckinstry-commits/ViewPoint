SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORBExpValNew    Script Date: 8/28/99 9:36:40 AM ******/
CREATE     procedure [dbo].[bspPORBExpValNew]
/***********************************************************
* CREATED BY: DANF 04/12/01
* MODIFIED By: DANF 09/05/02 - Added Phase Group to bspJobTypeVal & bspPORBExpValJob
*			  RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
*			  MV 08/16/05 - #29558 - return AvgECM to bspPORBExpVal
*			DC 02/13/08 - #119843 - Null in GLAcct brings back no error message - Add Isnull
*				DC 03/07/08 - Issue #127075:  Modify PO/RQ  for International addresses
*			DC 12/08/09 - #122288 = Store Tax Rate in POIT
*			mh 11/19/10 - #131640 Changes to support SM PO integration
*			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*			GF 08/22/2011 - TK-07879 PO Item Line
*			GF 10/20/2011 TK-09213 GL Sub Type for S - Service
*
*
* USAGE:
* Called from bspPORBExpVal to validate the current values in
* Add and Changed lines.
*
* Errors in batch added to bHQBE
*
* INPUT PARAMETERS:
*  @poco               PO Company
*  @mth                Batch month
*  @batchid            Batch ID#
*  @porbrecvddate      Date of Receipt
*  @apglco             AP GL Company #
*  @expjrnl            Expense Journal
*  @porbpo             Purchase Order
*  @porbpoitem         Purchase Order Item
*  @porbbatchtranstype Batch transaction type
*  @porbrecvdunits     Units received
*  @PORBPOItemLine	 PO Item Line
*
* OUTPUT PARAMETERS
*  @jcum               JC Unit of Measure
*  @jcunits            Units converted to JC UM
*  @emum               EM Unit of Measure
*  @emunits            Units converted to EM UM
*  @stdum              Material Standard unit of mearsure
*  @stdunits           Units converted to Std UM
*  @costopt            IN Cost option
*  @fixedunitcost      Fixed Unit Cost
*  @fixedecm           ECM for Fixed Unit Cost
*  @burdenyn           IN Burdened Unit Cost option
*  @loctaxglacct       IN Tax GL Account
*  @locmiscglacct      IN Misc/Freight GL Account
*  @locvarianceglacct  IN Cost Variance GL Account
*  @intercoarglacct    Intercompany AR GL Account
*  @intercoapglacct    Intercompany AP GL Account
*  @taxphase           Tax Phase
*  @taxct              Tax JC Cost Type
*  @taxglacct          Tax Expense GL Account
*  @errmsg             error message
*
* RETURN VALUE
*    0                 success
*    1                 failure
*****************************************************/
      @poco bCompany, @mth bMonth, @batchid bBatchID, @porbrecvddate bDate,
      @apglco bCompany, @expjrnl bJrnl, @porbpo varchar(30), @porbpoitem bItem, 
      @porbbatchtranstype char(1), @porbrecvdunits bUnits,
      ---- TK-07879
      @PORBPOItemLine INT,
      @jcum bUM output, @jcunits bUnits output, @emum bUM output, @emunits bUnits output,
      @stdum bUM output, @stdunits bUnits output, @costopt tinyint output,
      @fixedunitcost bUnitCost output, @fixedecm bECM output, @burdenyn bYN output,
      @loctaxglacct bGLAcct output, @locmiscglacct bGLAcct output, @locvarianceglacct bGLAcct output,
      @intercoarglacct bGLAcct output, @intercoapglacct bGLAcct output,
      @taxphase bPhase output, @taxct bJCCType output, @taxglacct bGLAcct output,
      @avgecm bECM output, @errmsg varchar(255) output

as
set nocount on
   
-- APLB declares
DECLARE @grossamt bDollar, @taxbasis bDollar, @taxamt bDollar, @retainage bDollar
DECLARE @rcode int, @accounttype char(1), @active bYN, @msg varchar(255)

SET @rcode = 0

-- declare PO Header
declare @pohdvendorgroup bGroup,  @pohdvendor bVendor, @pohddesc bDesc,
		@pohdorderdate bDate, @pohdorderby varchar(10), @pohdexpdate bDate,
		@pohdstatus tinyint, @pohdjcco bCompany, @pohdjob bJob, @pohdinco bCompany, @pohdloc bLoc,
		@pohdshiploc varchar(10), @pohdaddress varchar(60), @pohdcity varchar(30), @pohdstate varchar(4),
		@pohdzip bZip, @pohdshipins varchar(60), @pohdholdcode bHoldCode, @pohdpayterms bPayTerms,
		@pohdcompgroup varchar(10), @pohdmthclosed bMonth, @pohdinusemth bMonth,
		@pohdinusebatchid bBatchID, @pohdapproved bYN, @pohsapprovedby bVPUserName,
		@pohdpurge bYN, @pohdaddedmth bMonth, @pohdaddedbatchid bBatchID

-- declare PO Item
declare @poititemtype tinyint, @poitmatlgroup bGroup, @poitmaterial bMatl, @poirvendmatid varchar(30),
		@poitdesc bDesc, @poitum bUM, @poitrecvyn bYN, @poitposttoco bCompany, @poitloc bLoc,
		@poitjob bJob, @poitphasegroup bGroup, @poitphase bPhase, @poitjcctype bJCCType, @poitequip bEquip,
		@poitcomptype varchar(10), @poitcomponent bEquip, @poitemgroup bGroup, @poitcostcode bCostCode,
		@poitemctype bEMCType, @poitwo bWO, @poitwoitem bItem, @poitglco bCompany, @poitglacct bGLAcct,
		@poitreqdate bDate, @poittaxgroup bGroup, @poittaxcode bTaxCode, @poittaxtype tinyint,
		@poitorigunits bUnits, @poitorigunitcost bUnitCost, @poitorigecm bECM, @poitorigcost bDollar,
		@poitorigtax bDollar, @poitcurunits bUnits, @poitcurunitcost bUnitCost, @poitcurecm bECM,
		@poitcurcost bDollar, @poitcurtax bDollar, @poitrecvduntis bUnits, @poitrecvdcost bDollar,
		@poitbounits bUnits, @poitbocost bDollar, @poittotalunits bUnits, @poittotalcost bDollar,
		@poittotaltax bDollar, @poitinvunits bUnits, @poitinvcost bDollar, @poitinvtax bDollar,
		@poitremunits bUnits, @poitremcost bDollar, @poitremtax bDollar


---- Read PO Header from POHD
select @pohdvendorgroup = VendorGroup,  @pohdvendor = Vendor, @pohddesc = Description,
    @pohdorderdate = OrderDate, @pohdorderby = OrderedBy, @pohdexpdate = ExpDate,
    @pohdstatus = Status, @pohdjcco = JCCo, @pohdjob = Job, @pohdinco = INCo, @pohdloc = Loc,
    @pohdshiploc = ShipLoc, @pohdaddress = Address, @pohdcity = City, @pohdstate = State,
    @pohdzip = Zip, @pohdshipins = ShipIns, @pohdholdcode = HoldCode, @pohdpayterms = PayTerms,
    @pohdcompgroup = CompGroup, @pohdmthclosed = MthClosed, @pohdinusemth = InUseMth,
    @pohdinusebatchid = InUseBatchId, @pohdapproved = Approved, @pohsapprovedby = ApprovedBy,
    @pohdpurge = Purge, @pohdaddedmth = AddedMth, @pohdaddedbatchid = AddedBatchID
from bPOHD with (nolock) where POCo = @poco and PO = @porbpo
if @@rowcount = 0
	begin
	select @errmsg = ' Invalid PO: ' + isnull(@porbpo,''), @rcode = 1  --DC #119843
	goto bspexit
	end
if @pohdstatus <> 0   -- status must be open
	begin
	select @errmsg = ' PO: ' + isnull(@porbpo,'') + ' is not open!', @rcode = 1  --DC #119843
	goto bspexit
	end
if @pohdinusemth <> @mth or @pohdinusebatchid <> @batchid
	begin
	select @errmsg = ' PO: ' + isnull(@porbpo,'') + ' is already in use by another batch!', @rcode = 1  --DC #119843
	goto bspexit
	end
   
--- Read PO Item from POItemLine and POIT TK-07879
select  @poititemtype = line.ItemType, @poitmatlgroup = item.MatlGroup, @poitmaterial = item.Material,
		@poirvendmatid = item.VendMatId, @poitdesc = item.Description, @poitum = item.UM,
		@poitrecvyn = item.RecvYN, @poitposttoco = line.PostToCo, @poitloc = line.Loc,
		@poitjob = line.Job, @poitphasegroup = line.PhaseGroup, @poitphase = line.Phase,
		@poitjcctype = line.JCCType, @poitequip = line.Equip, @poitcomptype = line.CompType,
		@poitcomponent = line.Component, @poitemgroup = line.EMGroup, @poitcostcode = line.CostCode,
		@poitemctype = line.EMCType, @poitwo = line.WO, @poitwoitem = line.WOItem, @poitglco = line.GLCo,
		@poitglacct = line.GLAcct, @poitreqdate = line.ReqDate, @poittaxgroup = line.TaxGroup,
		@poittaxcode = line.TaxCode, @poittaxtype = line.TaxType, @poitorigunits = line.OrigUnits,
		@poitorigunitcost = item.OrigUnitCost, @poitorigecm = item.OrigECM, @poitorigcost = line.OrigCost,
		@poitorigtax = line.OrigTax, @poitcurunits = line.CurUnits, @poitcurunitcost = item.CurUnitCost,
		@poitcurecm = item.CurECM, @poitcurcost = line.CurCost, @poitcurtax = line.CurTax,
		@poitrecvduntis = line.RecvdUnits, @poitrecvdcost = line.RecvdCost, @poitbounits = line.BOUnits,
		@poitbocost = line.BOCost, @poittotalunits = line.TotalUnits, @poittotalcost = line.TotalCost,
		@poittotaltax = line.TotalTax, @poitinvunits = line.InvUnits, @poitinvcost = line.InvCost,
		@poitinvtax = line.InvTax, @poitremunits = line.RemUnits, @poitremcost = line.RemCost,
		@poitremtax = line.RemTax
FROM dbo.vPOItemLine line
INNER JOIN dbo.bPOIT item ON item.POCo=line.POCo AND item.PO=line.PO AND item.POItem=line.POItem
WHERE line.POCo = @poco AND line.PO = @porbpo
	AND line.POItem = @porbpoitem
	AND line.POItemLine = @PORBPOItemLine
----from bPOIT with (nolock) where POCo = @poco and PO = @porbpo and POItem = @porbpoitem
if @@rowcount = 0
	begin
	select @errmsg = ' Invalid PO: ' + isnull(@porbpo,'') + ' Item:' + convert(varchar(6),isnull(@porbpoitem,'')), @rcode = 1  --DC #119843
	goto bspexit
	end

if @porbbatchtranstype not in ('A','C')
	begin
	select @errmsg = 'Must be (A) or (C) to validate with this procedure!', @rcode = 1
	goto bspexit
	end
   
     -- validate JCCo, Job, Phase, and JC Cost Type
     if @poititemtype = 1
         begin
         exec @rcode = bspPORBExpValJob @poitposttoco, @poitphasegroup, @poitjob, @poitphase, @poitjcctype, @poitmatlgroup, @poitmaterial, @poitum, @porbrecvdunits, @jcum output,
             @jcunits output, @errmsg output
         if @rcode <> 0 goto bspexit
         end
     -- validate Work Order and Item
     if @poititemtype = 5
         begin
         exec @rcode = bspPORBExpValWO @poitposttoco, @poitwo, @poitwoitem, @poitequip, @poitcomptype, @poitcomponent, @poitemgroup,
             @poitcostcode, @errmsg output
         if @rcode <> 0 goto bspexit
         end
     -- validate EMCo, Equip, Cost Code, EM Cost Type, Component Type, and Component
     if @poititemtype in (4,5)
         begin
         exec @rcode = bspPORBExpValEquip @poitposttoco, @poitequip, @poitemgroup, @poitcostcode, @poitemctype, @poitcomponent, @poitmatlgroup,
             @poitmaterial, @poitum, @porbrecvdunits, @emum output, @emunits output, @errmsg output
         if @rcode <> 0 goto bspexit
         end
     -- validate IN Co#, Location, Material, and UM
     if @poititemtype = 2
        begin
      exec @rcode = bspPORBExpValInv @poitposttoco, @poitloc, @poitmatlgroup, @poitmaterial, @poitum, @porbrecvdunits, @stdum output, @stdunits output,
             @costopt output, @fixedunitcost output, @fixedecm output, @burdenyn output, @loctaxglacct output,
             @locmiscglacct output, @locvarianceglacct output,@avgecm output, @errmsg output
         if @rcode <> 0 goto bspexit
         end
     -- validate Expense Jrnl in 'posted to' GL Co#
     if @poitglco <> @apglco
        begin
        if not exists(select * from bGLJR with (nolock) where GLCo = @poitglco and Jrnl = @expjrnl)
            begin
            select @errmsg = 'Journal ' + isnull(@expjrnl,'') + ' is not valid in GL Co#' + convert(varchar(3),isnull(@poitglco,'')), @rcode = 1  --DC #119843
            goto bspexit
            end
        end
     -- validate 'posted to' GL Co and Expense Month
     exec @rcode = bspHQBatchMonthVal @poitglco, @mth, 'AP',@errmsg output
     if @rcode <> 0 goto bspexit
   
     -- validate Posted GL Account
     select @accounttype = null
     if @poititemtype = 1 select @accounttype = 'J'    -- job
     if @poititemtype = 2 select @accounttype = 'I'          -- inventory
     if @poititemtype = 3 select @accounttype = 'N'         -- must be null
     if @poititemtype in (4,5) select @accounttype = 'E'   -- equipment
     ----TK-09213
     if @poititemtype = 6 SET @accounttype = 'S'          -- SERVICE
     exec @rcode = bspGLACfPostable @poitglco, @poitglacct, @accounttype, @msg output
     if @rcode <> 0
         begin
       	select @errmsg = 'GL Account:' + isnull(@poitglacct,'') + ':  ' + isnull(@msg,'')  --DC #119843
       	goto bspexit
       	end
     -- if AP GL Co# <> 'Posted To' GL Co# get intercompany accounts
     if @poitglco <> @apglco
         begin
       	select @intercoarglacct = ARGLAcct, @intercoapglacct = APGLAcct
         from bGLIA with (nolock)
         where ARGLCo = @apglco and APGLCo = @poitglco
       	if @@rowcount = 0
             begin
       		select @errmsg = 'Intercompany Accounts not setup in GL. From:' +
                 convert(varchar(3),isnull(@apglco,'')) + ' To: ' + convert(varchar(3),isnull(@poitglco,'')), @rcode = 1  --DC #119843
       		goto bspexit
             end
       	-- validate intercompany GL Accounts
         exec @rcode = bspGLACfPostable @apglco, @intercoarglacct, 'R', @msg output
         if @rcode <> 0
             begin
       	    select @errmsg = 'Intercompany AR Account:' + isnull(@intercoarglacct,'') + ':  ' + isnull(@msg,''), @rcode = 1  --DC #119843
       	  	goto bspexit
           	end
       	exec @rcode = bspGLACfPostable @poitglco, @intercoapglacct, 'P', @msg output
         if @rcode <> 0
        		begin
       		select @errmsg = 'Intercompany AP Account:' + isnull(@intercoapglacct,'') + ':  ' + isnull(@msg,'')  --DC #119843
       		goto bspexit
       		end
         end
     -- validate UM
     if @poitum is not null
         begin
         if not exists(select * from bHQUM with (nolock) where UM = @poitum)
             begin
             select @errmsg = 'Invalid Unit of Measure:' + @poitum, @rcode = 1
       	    goto bspexit
       	    end
         if @poitmaterial is not null
             begin
             select @stdum = StdUM from bHQMT with (nolock) where MatlGroup = @poitmatlgroup and Material = @poitmaterial
             if @@rowcount = 1 and @poitum <> @stdum
                 begin
                 if not exists(select * from bHQMU with (nolock) where MatlGroup = @poitmatlgroup and Material = @poitmaterial and UM = @poitum)
                     begin
                     select @errmsg = 'Invalid Unit of Measure for this Material:' + @poitmaterial, @rcode = 1
                     goto bspexit
       	            end
                 end
             end
         if @poitum = 'LS'
             begin
             if @porbrecvdunits <> 0 or @poitorigunitcost <> 0 or @poitorigecm is not null
                 begin
                 select @errmsg = 'Units, Unit Cost and ECM not allowed with (LS)', @rcode = 1
       	        goto bspexit
       	        end
      end
         end
     if @poitum <> 'LS' and @poitum is not null and @poitorigecm not in('E', 'C', 'M')
         begin
       	select @errmsg = 'ECM must be E, C, or M!', @rcode = 1
        	goto bspexit
         end
   
     -- validate Tax Code
     if @poittaxcode is not null
        begin
        exec @rcode = vspHQTaxRateGet @poittaxgroup, @poittaxcode, @porbrecvddate, NULL, NULL, @taxphase output, @taxct output, 
			NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @errmsg output				
       /* exec @rcode = bspHQTaxRateGet @poittaxgroup, @poittaxcode, @porbrecvddate, @taxrate output, @taxphase output,
            @taxct output, @msg output*/
        if @rcode <> 0
            begin
       	    select @errmsg = 'Tax Code: ' + isnull(@poittaxcode,'') + ':  ' + isnull(@msg,''), @rcode = 1  --DC #119843
       	    goto bspexit
           	end 
   
         -- Tax Phase and Cost Type
         if @poititemtype = 1
             begin
             -- use 'posted' phase and cost type unless overridden by tax code
             if @taxphase is null select @taxphase = @poitphase
             if @taxct is null select @taxct = @poitjcctype
             select @taxglacct = @poitglacct     -- default is 'posted' account
   
             if @taxphase <> @poitphase or @taxct <> @poitjcctype
       		    begin
      	        -- get GL Account for Tax Expense
                 exec @rcode = bspJCCAGlacctDflt @poitposttoco, @poitjob, @poitphasegroup, @taxphase, @taxct, 'N', @taxglacct output, @msg output
              	if @rcode <> 0
      	 	        begin
       	        	select @errmsg = 'Tax GL Account ' + isnull(@msg,''), @rcode = 1
                     goto bspexit
                     end
                 -- validate Tax Account
                 exec @rcode = bspGLACfPostable @poitglco, @taxglacct, 'J', @msg output
       		    if @rcode <> 0
       	       		begin
       		        select @errmsg = 'Tax GL Account:' + isnull(@taxglacct,'') + ':  ' + isnull(@msg,''), @rcode = 1  --DC #119843
                     goto bspexit
       		        end
                 -- validate tax phase/cost type
                 exec @rcode =bspJobTypeVal @poitposttoco, @poitphasegroup, @poitjob, @taxphase, @taxct,  @errmsg=@msg output
                if @rcode <> 0
                    begin
                    select @errmsg ='Job/Tax Phase/CT not setup' + isnull(@msg,''), @rcode = 1
                    goto bspexit
                    end
                 end
             end
         end




bspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspPORBExpValNew] TO [public]
GO
