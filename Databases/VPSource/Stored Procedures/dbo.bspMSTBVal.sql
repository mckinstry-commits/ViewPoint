
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***********************************************************/
CREATE procedure [dbo].[bspMSTBVal]
/***********************************************************
* CREATED BY: GG 10/06/00
* MODIFIED By : GG 11/27/00 - changed datatype from bAPRef to bAPReference
*             : DANF 01/22/00 - Added update of MatlCost when null
*               GF 02/13/2001 - Missing parameter passed to bspMSTBProdVal
*	             RM 03/05/01 - Added validation of Reason Code
*               DANF 03/29/01 - Changed error message on equipment and employee.
*               GF 05/10/2001 - Added validation for paytype and check no.
*               GF 05/22/2001 - More validation and more etc.
*               GG 07/31/01 - Recalculate and update material cost if 0.00 - #14136
*               GF 09/18/01 - Recalculate and update material cost without restriction
*               GF 09/18/01 - Added validation for phase group. #14635
*               GF 09/24/01 - Check numerics for nulls. #14674
*               GF 10/08/01 - Fix for matlcost when fromloc, material, um changed. #14851
*				 GF 02/11/02 - Fix to use To INCo material group when validating material & UM
*				 SR 07/09/02 - issue 17738 - pass @phasegroup to bspJCVPHASE
*               allenn 08/26/02 - Allow 'MS Addons' source for issue 17737
*				 GF 09/03/2002 - issue #18402 - validate void flag is 'Y' or 'N'
*				 GF 10/08/2002 - issue #18771 - changed tax type validate for null
*				 GF 10/15/2002 - issue #18973 - validate Weight UM (@wghtum) to HQUM
*				 GF 01/03/2003 - issue #19679 - if material from outside vendor verify UM to HQMU not INMU
*				 GF 01/03/2003 - issue #19720 - when in 'C' mode and changing the void flag from 'N' to 'Y'
*									production was not being calculated to back out old. Problem in if statement
*				 GF 01/29/2003 - issue #19434 - @discoff or @taxdisc must be zero for SaleType = 'J' or 'I'
*				 GF 03/03/2003 - issue #20572 - added validation for null tax code and tax discount <> 0
*				 GF 05/13/2003 - issue #21230 - added check for null @matlunits and @oldmatlunits. set to zero.
*				 GF 08/31/2004 - issue #25449 - need to check for equipment like trigger Type <> 'C' and Status = 'A'
*				 GF 02/08/2006 - issue #120087 - added check for to material group material std um <> posted um
*				 GF 06/17/2007 - issue #120282 - verify paytype is not null for customer tickets.
*				 GF 07/23/2007 - issue #30641 - validate revenue code set up for category
*				 GF 02/26/2008 - issue #127145 validate @tojcco and @toinco are null when not appropriate sale type
*				 GF 06/23/2008 - issue #128290 new tax type 3-VAT for international tax
*				DAN SO 10/12/2009 - issue #129350 - validate associated surcharges (and reformatted procedure)
*												  - update HQBE error messages for surcharge errors
*												  - clean up any MSTB Surcharge records if there are any errors
*				DAN SO 06/01/2010 - issue #139335 - Verify Payment Type and Check # is null for Job and Inventory Sales
*				DAN SO 06/03/2010 - issue #139961 - Verify Surcharges Records already exist in MSTB
&				GF 06/10/2010 -		issue #139945 surcharges set the material cost equal to the surcharge amount.
*				MH 09/28/2010 -		issue #140411 Corrected HaulType validation.  Need to check for possible null value.
*				MH 08/21/2011 - B04189/TK07787 Add Haul Payment Tax ability.
*				GF 08/25/2012 TK-17370 add validation for empty sale type
*				GF 04/05/2013 TFS-46115 more information for surcharge ticket errors
*
*
*
* USAGE:
* Called from MS Batch Process form to validate a Ticket batch
*
* Errors in batch added to bHQBE using bspHQBEInsert
*
* INPUT PARAMETERS
*   @msco          MS Co#
*   @mth           Batch Month
*   @batchid       Batch ID
*
* OUTPUT PARAMETERS
*   @errmsg        error message
*
* RETURN VALUE
*   0              success
*   1              fail
****************************************************/
@msco bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output
as
set nocount on

declare @rcode int, @errorstart varchar(10), @errortext varchar(255), @status tinyint, @opencursor tinyint,
		@msglco bCompany, @jrnl bJrnl, @msinv varchar(10), @verifyhaul bYN, @inusebatchid bBatchID, @msg varchar(255),
		@stdum bUM, @category varchar(10), @autoprod bYN, @sendjcct varchar(5), @jcum bUM, @oldautoprod bYN,
		@oldcategory varchar(10), @oldstdum bUM, @glco bCompany, @NumMSTBSurcharges int, @NumMSSurcharges int

---- bMSTB declares
declare @seq int, @transtype char(1), @mstrans bTrans, @saledate bDate, @fromloc bLoc, @vendorgroup bGroup,
		@matlvendor bVendor, @saletype char(1), @custgroup bGroup, @customer bCustomer, @custjob varchar(20),
		@custpo varchar(20), @paytype char(1), @checkno bCMRef, @hold bYN, @jcco bCompany, @job bJob, @phasegroup bGroup,
		@toinco bCompany, @toloc bLoc, @matlgroup bGroup, @material bMatl, @um bUM, @matlphase bPhase,
		@matlcosttype bJCCType, @matlunits bUnits, @unitprice bUnitCost, @ecm bECM, @matltotal bDollar,
		@matlcost bDollar, @haultype char(1), @haulvendor bVendor, @truck bTruck, @driver varchar(30),
		@emco bCompany, @equip bEquip, @emgroup bGroup, @prco bCompany, @employee bEmployee, @trucktype varchar(10),
		@zone varchar(10), @haulcode bHaulCode, @haulbasis bUnits, @haulphase bPhase, @haulcosttype bJCCType, @haultotal bDollar,
		@paycode bPayCode, @paytotal bDollar, @revcode bRevCode, @revtotal bDollar, @taxgroup bGroup,
		@taxcode bTaxCode, @taxtype tinyint, @taxtotal bDollar, @discoff bDollar, @taxdisc bDollar, @void bYN, @reasoncode bReasonCode,
		@oldsaledate bDate, @oldfromloc bLoc, @oldvendorgroup bGroup, @oldmatlvendor bVendor, @oldsaletype char(1),
		@oldcustgroup bGroup, @oldcustomer bCustomer, @oldcustjob varchar(20), @oldcustpo varchar(20), @oldpaytype char(1),
		@oldhold bYN, @oldjcco bCompany, @oldjob bJob, @oldphasegroup bGroup, @oldtoinco bCompany, @oldtoloc bLoc,
		@oldmatlgroup bGroup, @oldmaterial bMatl, @oldum bUM, @oldmatlphase bPhase, @oldmatlcosttype bJCCType,
		@oldmatlunits bUnits, @oldunitprice bUnitCost, @oldecm bECM, @oldmatltotal bDollar, @oldmatlcost bDollar,
		@oldhaultype char(1), @oldhaulvendor bVendor, @oldtruck bTruck, @olddriver varchar(30), @oldemco bCompany,
		@oldequip bEquip, @oldemgroup bGroup, @oldprco bCompany, @oldemployee bEmployee, @oldtrucktype varchar(10),
		@oldzone varchar(10), @oldhaulcode bHaulCode, @oldhaulphase bPhase, @oldhaulcosttype bJCCType, @oldhaultotal bDollar,
		@oldpaycode bPayCode, @oldpaytotal bDollar, @oldrevcode bRevCode, @oldrevtotal bDollar, @oldtaxgroup bGroup,
		@oldtaxcode bTaxCode, @oldtaxtype tinyint, @oldtaxtotal bDollar, @olddiscoff bDollar, @oldtaxdisc bDollar,
		@oldvoid bYN, @oldmsinv varchar(10), @oldapref bAPReference, @oldverify bYN,@oldreasoncode bReasonCode,
		@nullnumericflag tinyint, @haulrate bUnitCost, @payrate bUnitCost, @revrate bUnitCost, @discrate bUnitCost,
		@paybasis bUnits, @revbasis bUnits, @taxbasis bDollar, @discbasis bUnits, @oldmatlcostuc bUnitCost,
		@toinmatlgroup bGroup, @tomatlstdum bUM, @wghtum bUM, @equip_cat bCat, @valueadd varchar(1), @KeyID bigint, 
		@SurchargeKeyID bigint, @SurchargeCode int, @CleanSurchargeRecords bYN, @ParentSeq int,
		@haulpaytaxtype tinyint, @haulpaytaxcode bTaxCode, @haulpaytaxrate bUnitCost, @haulpaytaxamt bDollar,
		@oldhaulpaytaxtype tinyint, @oldhaulpaytaxcode bTaxCode, @oldhaulpaytaxrate bUnitCost, @oldhaulpaytaxamt bDollar


select @rcode = 0, @nullnumericflag = 0, @CleanSurchargeRecords = 'N'

---- validate HQ Batch
exec @rcode = dbo.bspHQBatchProcessVal @msco, @mth, @batchid, 'MS Tickets', 'MSTB', @errmsg output, @status output
---- issue 17737
if @rcode = 1
   	begin
   	exec @rcode = dbo.bspHQBatchProcessVal @msco, @mth, @batchid, 'MS Addons', 'MSTB', @errmsg output, @status output
   	end
if @rcode <> 0 goto bspexit
if @status < 0 or @status > 3
	begin
	select @errmsg = 'Invalid Batch status!', @rcode = 1
	goto bspexit
	end

---- set HQ Batch status to 1 (validation in progress)
update bHQBC set Status = 1
where Co = @msco and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
	end

---- clear HQ Batch Errors
delete bHQBE where Co = @msco and Mth = @mth and BatchId = @batchid

---- clear IN, JC, EM, and GL distribution entries
delete bMSPA where MSCo = @msco and Mth = @mth and BatchId = @batchid
delete bMSIN where MSCo = @msco and Mth = @mth and BatchId = @batchid
delete bMSJC where MSCo = @msco and Mth = @mth and BatchId = @batchid
delete bMSRB where MSCo = @msco and Mth = @mth and BatchId = @batchid
delete bMSEM where MSCo = @msco and Mth = @mth and BatchId = @batchid
delete bMSGL where MSCo = @msco and Mth = @mth and BatchId = @batchid

---- get Company info from MS Company
select @msglco = GLCo, @jrnl = Jrnl
from bMSCO with (nolock) where MSCo = @msco
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid MS Company #' + isnull(convert(varchar(3),@msco),''), @rcode = 1
	goto bspexit
	end

---- validate Month in MS GL Co# - subledgers must be open
exec @rcode = dbo.bspHQBatchMonthVal @msglco, @mth, 'MS', @errmsg output
if @rcode <> 0 goto bspexit

---- validate Journal
if not exists(select top 1 1 from bGLJR with (nolock) where GLCo = @msglco and Jrnl = @jrnl)
	begin
		select @errmsg = 'Invalid Journal ' + isnull(@jrnl,'') + ' assigned in MS Company!', @rcode = 1
		goto bspexit
	end


---------------------------------------------
-- INSERT/POST SURCHARGES INTO MSTB TO BE  --
-- PROCESSED LIKE A NORMAL MS TICKET ENTRY --
---------------------------------------------

-- ISSUE: #139961 --
SELECT @NumMSTBSurcharges = COUNT(*) 
  FROM bMSTB WITH (NOLOCK)
 WHERE Co = @msco
   AND Mth = @mth
   AND BatchId = @batchid
   AND SurchargeKeyID IS NOT NULL

SELECT @NumMSSurcharges = COUNT(*) 
  FROM bMSSurcharges WITH (NOLOCK)
 WHERE Co = @msco
   AND Mth = @mth
   AND BatchId = @batchid

-- CHECK TO MAKE SURE SURCHARGE RECORDS HAVE NOT ALREADY BEEN POSTED IN MSTB --
IF @NumMSTBSurcharges <> @NumMSSurcharges
	BEGIN

		-- ISSUE #129350 --
		EXEC @rcode = dbo.vspMSSurchargePost @msco, @mth, @batchid, @errmsg output

		IF @rcode = 1
			BEGIN
				SET @errortext = isnull(@errmsg,'')
				GOTO bspexit
			END  
	END
	

---- declare cursor on MS Ticket Batch for validation
declare bcMSTB cursor LOCAL FAST_FORWARD
  	 for select BatchSeq,BatchTransType,MSTrans,SaleDate,FromLoc,VendorGroup,
       MatlVendor,SaleType,CustGroup,Customer,CustJob,CustPO,PaymentType,CheckNo,Hold,JCCo,Job,PhaseGroup,
       INCo,ToLoc,MatlGroup,Material,UM,MatlPhase,MatlJCCType,WghtUM,MatlUnits,UnitPrice,ECM,MatlTotal,MatlCost,
       HaulerType,HaulVendor,Truck,Driver,EMCo,Equipment,EMGroup,PRCo,Employee,TruckType,Zone,HaulCode,HaulBasis,
       HaulPhase,HaulJCCType,HaulRate,HaulTotal,PayCode,PayBasis,PayRate,PayTotal,RevCode,RevBasis,RevRate,RevTotal,
       TaxGroup,TaxCode,TaxType,TaxBasis,TaxTotal,DiscBasis,DiscRate,DiscOff,TaxDisc,Void,ReasonCode,OldSaleDate,
       OldFromLoc,OldVendorGroup,OldMatlVendor,OldSaleType,OldCustGroup,
       OldCustomer,OldCustJob,OldCustPO,OldPaymentType,OldHold,OldJCCo,OldJob,OldPhaseGroup,OldINCo,OldToLoc,
       OldMatlGroup,OldMaterial,OldUM,OldMatlPhase,OldMatlJCCType,OldMatlUnits,OldUnitPrice,OldECM,OldMatlTotal,
       OldMatlCost,OldHaulerType,OldHaulVendor,OldTruck,OldDriver,OldEMCo,OldEquipment,OldEMGroup,OldPRCo,
       OldEmployee,OldTruckType,OldZone,OldHaulCode,OldHaulPhase,OldHaulJCCType,OldHaulTotal,OldPayCode,
       OldPayTotal,OldRevCode,OldRevTotal,OldTaxGroup,OldTaxCode,OldTaxType,OldTaxTotal,OldDiscOff,OldTaxDisc,
       OldVoid,OldMSInv,OldAPRef,OldVerifyHaul,OldReasonCode, KeyID, SurchargeKeyID, SurchargeCode,
       HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate, HaulPayTaxAmt, OldHaulPayTaxType, OldHaulPayTaxCode,
       OldHaulPayTaxRate, OldHaulPayTaxAmt
   from bMSTB where Co = @msco and Mth = @mth and BatchId = @batchid
   
-- open cursor
open bcMSTB

-- set open cursor flag to true
select @opencursor = 1

MSTB_loop:
fetch next from bcMSTB into @seq,@transtype,@mstrans,@saledate,@fromloc,@vendorgroup,
		@matlvendor,@saletype,@custgroup,@customer,@custjob,@custpo,@paytype,@checkno,@hold,@jcco,@job,@phasegroup,
		@toinco,@toloc,@matlgroup,@material,@um,@matlphase,@matlcosttype,@wghtum,@matlunits,@unitprice,@ecm,@matltotal,@matlcost,
		@haultype,@haulvendor,@truck,@driver,@emco,@equip,@emgroup,@prco,@employee,@trucktype,@zone,@haulcode,@haulbasis,
		@haulphase,@haulcosttype,@haulrate,@haultotal,@paycode,@paybasis,@payrate,@paytotal,@revcode,@revbasis,@revrate,
		@revtotal,@taxgroup,@taxcode,@taxtype,@taxbasis,@taxtotal,@discbasis,@discrate,@discoff,@taxdisc,@void,
		@reasoncode,@oldsaledate,@oldfromloc,@oldvendorgroup,@oldmatlvendor,@oldsaletype,@oldcustgroup,
		@oldcustomer,@oldcustjob,@oldcustpo,@oldpaytype,@oldhold,@oldjcco,@oldjob,@oldphasegroup,@oldtoinco,@oldtoloc,
		@oldmatlgroup,@oldmaterial,@oldum,@oldmatlphase,@oldmatlcosttype,@oldmatlunits,@oldunitprice,@oldecm,@oldmatltotal,
		@oldmatlcost,@oldhaultype,@oldhaulvendor,@oldtruck,@olddriver,@oldemco,@oldequip,@oldemgroup,@oldprco,
		@oldemployee,@oldtrucktype,@oldzone,@oldhaulcode,@oldhaulphase,@oldhaulcosttype,@oldhaultotal,@oldpaycode,
		@oldpaytotal,@oldrevcode,@oldrevtotal,@oldtaxgroup,@oldtaxcode,@oldtaxtype,@oldtaxtotal,@olddiscoff,@oldtaxdisc,
		@oldvoid,@oldmsinv,@oldapref,@oldverify,@oldreasoncode, @KeyID, @SurchargeKeyID, @SurchargeCode,
		@haulpaytaxtype, @haulpaytaxcode, @haulpaytaxrate, @haulpaytaxamt, @oldhaulpaytaxtype, @oldhaulpaytaxcode, 
		@oldhaulpaytaxrate, @oldhaulpaytaxamt
				   
	if @@fetch_status <> 0 goto MSTB_end
   
   -- save Batch Sequence # for any errors that may be found
   SET @nullnumericflag = 0
   SET @errorstart = 'Seq#' + dbo.vfToString(@seq)
    

   -- validate transaction type
   if @transtype not in ('A','C','D')
       begin
		   select @errortext = @errorstart + ' -  Invalid transaction type, must be (A, C, or D).'
		   goto MSTB_error
       end

----TK-17370 validate sale type is not empty (imports)
IF ISNULL(@saletype,'') = ''
	BEGIN
	select @errortext = @errorstart + ' -  Invalid sale type, must be (C, J, or I).'
	GOTO MSTB_error
	END

---- validate Sale Type
IF @saletype NOT IN ('C','J','I')
	BEGIN
	SELECT @errortext = @errorstart + ' - Invalid Sale Type, must be (C, J, or I)!'
	GOTO MSTB_error
	END


   -- check numerics for nulls
	if @matlunits is null
		begin
			select @matlunits = 0, @nullnumericflag = 1
		end
	if @oldmatlunits is null
		begin
			select @oldmatlunits = 0, @nullnumericflag = 1
		end
	if @matltotal is null
		begin
			select @matltotal = 0, @nullnumericflag = 1
		end
	if @matlcost is null
		begin
			select @matlcost = 0, @nullnumericflag = 1
		end
	if @haulbasis is null
		begin
			select @haulbasis = 0, @nullnumericflag = 1
		end
	if @haulrate is null
		begin
			select @haulrate = 0, @nullnumericflag = 1
		end
	if @haultotal is null
		begin
			select @haultotal = 0, @nullnumericflag = 1
		end
	if @paybasis is null
		begin
			select @paybasis = 0, @nullnumericflag = 1
		end
	if @payrate is null
		begin
			select @payrate = 0, @nullnumericflag = 1
		end
	if @paytotal is null
		begin
			select @paytotal = 0, @nullnumericflag = 1
		end
	if @revbasis is null
		begin
			select @revbasis = 0, @nullnumericflag = 1
		end
	if @revrate is null
		begin
			select @revrate = 0, @nullnumericflag = 1
		end
	if @revtotal is null
		begin
			select @revtotal = 0, @nullnumericflag = 1
		end
	if @taxbasis is null
		begin
			select @taxbasis = 0, @nullnumericflag = 1
		end
	if @taxtotal is null
		begin
			select @taxtotal = 0, @nullnumericflag = 1
		end
	if @discbasis is null
		begin
			select @discbasis = 0, @nullnumericflag = 1
		end
	if @discrate is null
		begin
			select @discrate = 0, @nullnumericflag = 1
		end
	if @discoff is null
		begin
			select @discoff = 0, @nullnumericflag = 1
		end
	if @taxdisc is null
		begin
			select @taxdisc = 0, @nullnumericflag = 1
		end
	if @taxcode is null and @taxdisc <> 0
		begin
			select @taxdisc = 0, @nullnumericflag = 1
		end
	if @haulpaytaxrate is null
		begin
			select @haulpaytaxrate = 0, @nullnumericflag = 1
		end
	if @haulpaytaxamt is null
		begin
			select @haulpaytaxamt = 0, @nullnumericflag = 1
		end
   
	-----------------------------
	-- update numerics if null --
	-----------------------------
	if @nullnumericflag = 1
		begin
			update bMSTB set MatlTotal=@matltotal, MatlCost=@matlcost, HaulBasis=@haulbasis, HaulRate=@haulrate,
							HaulTotal=@haultotal, PayBasis=@paybasis, PayRate=@payrate, PayTotal=@paytotal,
							RevBasis=@revbasis, RevRate=@revrate, RevTotal=@revtotal, TaxBasis=@taxbasis,
							TaxTotal=@taxtotal, DiscBasis=@discbasis, DiscRate=@discrate, DiscOff=@discoff, 
							TaxDisc=@taxdisc, MatlUnits=@matlunits, OldMatlUnits=@oldmatlunits, HaulPayTaxRate = @haulpaytaxrate,
							HaulPayTaxAmt = @haulpaytaxamt
				where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
				
			if @@rowcount <> 1
				begin
					select @errortext = @errorstart + '- unable to update numeric values for ticket.'
					goto MSTB_error
				end
		end --if @nullnumericflag = 1
		
		
	-----------------------------
	-- VALIDATE SURCHARGE CODE --
	-----------------------------
	-- ISSUE: #129350 --
	IF @transtype in ('A', 'C')
		BEGIN
			IF @SurchargeKeyID IS NOT NULL
				BEGIN
					IF NOT EXISTS(SELECT 1 FROM bMSSurchargeCodes WITH (NOLOCK) WHERE SurchargeCode = @SurchargeCode)
						BEGIN
							SET @errortext = @errorstart + '- Invalid Surcharge Code.'
							GOTO MSTB_error
						END
				END
		END
		
   
	----------------------------------------
	-- validation specific to Add entries --
	----------------------------------------
	if @transtype = 'A'
		begin
			-- validate Trans#
			if @mstrans is not null
				begin
					select @errortext = @errorstart + ' - New entries must have a null Transaction #!'
					goto MSTB_error
				end
				
			----#139945 when a surcharge record we do not need to calculate the cost, use the ticket material total
			if @SurchargeKeyID is not null
				begin
				set @matlcost = @matltotal
				end
			else
				begin
				-- if material cost is missing or 0.00 then material may not have been setup when uploaded, try to find cost
				exec @rcode = dbo.bspMSTicMatlCostGet @msco, @fromloc, @matlgroup, @material, @um, @matlunits, @matlcost output, @msg = @errmsg output
				if @rcode = 1
					begin
					select @errortext = @errorstart + ' - ' + @errmsg
					goto MSTB_error
					end
				end
			----#139945
			
			-- update material cost
			update bMSTB
			set MatlCost  = @matlcost
			where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
					
			if @@rowcount <> 1
				begin
					select @errortext = @errorstart + '- unable to update Material Cost.'
					goto MSTB_error
				end

		end	--if @transtype = 'A'
		
	-----------------------------------------------------------
	-- validation specific to both Change and Delete entries --
	-----------------------------------------------------------
	if @transtype in ('C','D')
		begin
		
			-- validate Trans#
			if @mstrans is null
				begin
					select @errortext = @errorstart + ' - Change and Delete entries must have a Transaction #!'
					goto MSTB_error
				end
				
			-- check MS Ticket Detail
			select @msinv = MSInv, @verifyhaul = VerifyHaul, @inusebatchid = InUseBatchId
			from bMSTD with (nolock) where MSCo = @msco and Mth = @mth and MSTrans = @mstrans
			
			if @@rowcount = 0
				begin
					select @errortext = @errorstart + ' - Invalid Transaction #!'
					goto MSTB_error
				end
				
			if isnull(@inusebatchid,0) <> @batchid
				begin
					select @errortext = @errorstart + ' - Transaction # is not locked by the current Batch!'
					goto MSTB_error
				end
				
			-- get info from old Material
			select @oldcategory = Category, @oldstdum = StdUM
			from bHQMT with (nolock) where MatlGroup = @oldmatlgroup and Material = @oldmaterial and Active = 'Y'
			
			if @@rowcount = 0
				begin
					select @errortext = @errorstart + ' - Invalid old Material, must be setup in HQ and active!'
					goto MSTB_error
				end
			
			if @oldmatlvendor is null  -- sold from stock
				begin
					select @oldautoprod = AutoProd
					from bINMT with (nolock) 
					where INCo = @msco and Loc = @oldfromloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial and Active = 'Y'
			
					if @@rowcount = 0
						begin
							select @errortext = @errorstart + ' - Invalid old Material, must be stocked and active at old Location!'
							goto MSTB_error
						end
     			end
       end --if @transtype in ('C','D')
       
    -------------------------------------------
	-- validation specific to Change entries --
	-------------------------------------------
	if @transtype = 'C'
		begin
		
			if @fromloc <> @oldfromloc or @material <> @oldmaterial or @um <> @oldum
				begin
				----#139945 when a surcharge record we do not need to calculate the cost, use the ticket material total
				if @SurchargeKeyID is not null
					begin
					set @matlcost = @matltotal
					end
				else
					begin
					exec @rcode = dbo.bspMSTicMatlCostGet @msco, @fromloc, @matlgroup, @material, @um, @matlunits, 
														@matlcost output, @msg = @errmsg output						
					if @rcode = 1
						begin
						select @errortext = @errorstart + ' - ' + @errmsg
						goto MSTB_error
						end
					end
				----#139945

				---- update material cost
				update bMSTB set MatlCost  = @matlcost
				where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
					
					if @@rowcount <> 1
						begin
							select @errortext = @errorstart + '- unable to update Material Cost.'
							goto MSTB_error
						end
				end --if @fromloc <> @oldfromloc ...

			if @msinv is not null
				begin
					-- limit changes on invoiced transactions
					if isnull(@fromloc,'')<>isnull(@oldfromloc,'') or isnull(@saletype,'')<>isnull(@oldsaletype,'')
						or isnull(@customer,0)<>isnull(@oldcustomer,0) or isnull(@custjob,'')<>isnull(@oldcustjob,'')
						or isnull(@custpo,'')<>isnull(@oldcustpo,'') or isnull(@paytype,'')<>isnull(@oldpaytype,'')
						or isnull(@hold,'')<>isnull(@oldhold,'') or isnull(@jcco,0)<>isnull(@oldjcco,0)
						or isnull(@job,'')<>isnull(@oldjob,'') or isnull(@toinco,0)<>isnull(@oldtoinco,0)
						or isnull(@toloc,'')<>isnull(@oldtoloc,'') or isnull(@matltotal,0)<>isnull(@oldmatltotal,0)
						or isnull(@haultotal,0)<>isnull(@oldhaultotal,0) or isnull(@taxtotal,0)<>isnull(@oldtaxtotal,0)
						or isnull(@discoff,0)<>isnull(@olddiscoff,0) or isnull(@taxdisc,0)<>isnull(@oldtaxdisc,0)
						or isnull(@void,'')<>isnull(@oldvoid,'')
						begin
							select @errortext = @errorstart + ' - Ticket has been invoiced, cannot change purchaser or dollar amounts!'
							goto MSTB_error
						end
				end --if @msinv is not null
				
			if @verifyhaul = 'Y'
				begin
					-- limit changes if Haul has been verified
					if isnull(@saledate,'')<>isnull(@oldsaledate,'') or @haultype <> @oldhaultype
						or isnull(@haulvendor,0)<>isnull(@oldhaulvendor,0) or isnull(@truck,'')<>isnull(@oldtruck,'')
						or isnull(@driver,'')<>isnull(@olddriver,'') or isnull(@emco,0)<>isnull(@oldemco,0)
						or isnull(@equip,'')<>isnull(@oldequip,'') or isnull(@prco,0)<>isnull(@oldprco,0)
						or isnull(@employee,0)<>isnull(@oldemployee,0) or isnull(@haulcode,'')<>isnull(@oldhaulcode,'')
						or isnull(@haultotal,0)<>isnull(@oldhaultotal,0) or isnull(@void,'')<>isnull(@oldvoid,'')
						begin
							select @errortext = @errorstart + ' - Haul has been verified, cannot change haul related information!'
							goto MSTB_error
						end
				end --if @verifyhaul = 'Y'
        end --if @transtype = 'C'
           
		-------------------------------------------
		-- validation specific to Delete entries --
		-------------------------------------------
		if @transtype = 'D'
			begin
			
				if @msinv is not null
					begin
						select @errortext = @errorstart + ' - Already invoiced, cannot delete!'
						goto MSTB_error
					end
					
				if @verifyhaul = 'Y'
					begin
						select @errortext = @errorstart + ' - Haul has been verified, cannot delete!'
						goto MSTB_error
					end
			end --if @transtype = 'D'
					
		---------------------------------------------------
		-- validation specific to Add and Change entries --
		---------------------------------------------------
		if @transtype in ('A','C')
			begin

				-- Hold flag must be (Y,N)
				if @hold not in ('Y','N')
					begin
						select @errortext = @errorstart + ' - Hold flag missing!'
						goto MSTB_error
					end
					
				-- Void flag must be (Y,N)
				if @void not in ('Y','N')
					begin
						select @errortext = @errorstart + ' - Void flag missing!'
						goto MSTB_error
					end

				-- must have a Sale Date
				if @saledate is null
					begin
						select @errortext = @errorstart + ' - Sale Date missing!'
						goto MSTB_error
					end
   
				-- validate Weight U/M
				if @wghtum is not null
					begin
						if not exists(select 1 from bHQUM with (nolock) where UM = @wghtum)
							begin
								select @errortext = @errorstart + 'Invalid Weight U/M: ' + isnull(@wghtum,'')
								goto MSTB_error
							end
					end
   

				-- validate From Location
				if not exists(select top 1 1 from bINLM with (nolock) where INCo = @msco and Loc = @fromloc and Active = 'Y')
					if @@rowcount = 0
						begin
							select @errortext = @errorstart + ' - Invalid sales Location, ' + isnull(@fromloc,' ') + ' must be setup in IN and active!'
							goto MSTB_error
						end

						
				-- validate Material Vendor
				if @matlvendor is not null
					begin
						if not exists(select top 1 1 from bAPVM with (nolock) where VendorGroup = @vendorgroup and Vendor = @matlvendor and ActiveYN = 'Y')
							begin
								select @errortext = @errorstart + ' - Invalid Material Vendor, ' + isnull(convert(varchar(6),@matlvendor),'') + ' must be setup in AP and active!'
								goto MSTB_error
							end
					end
					
				-----------------------------
				-- validate Customer sales --
				-----------------------------
				if @saletype = 'C'
					begin
						if not exists(select top 1 1 from bARCM with (nolock) where CustGroup = @custgroup and Customer = @customer and Status <> 'I')
							begin
								select @errortext = @errorstart + ' - Invalid Customer, ' + isnull(convert(varchar(6),@customer),'') + ' must be setup in AR and active!'
								goto MSTB_error
							end
							
						-- must have Payment Type
						if isnull(@paytype,'') = ''
							begin
								select @errortext = @errorstart + ' - Missing Pay Type, cannot be null.'
								goto MSTB_error
							end
							
						if @paytype not in ('A','C','X')
							begin
								select @errortext = @errorstart + ' - Invalid Payment Type, must be (A, C, or X)!'
								goto MSTB_error
							end
							
						if @paytype <> 'C' and @checkno is not null
							begin
								select @errortext = @errorstart + ' - Invalid Check #. Check # may only be assigned with Payment Type (C) !'
								goto MSTB_error
							end
							
						if @matlphase is not null
							begin
								select @errortext = @errorstart + ' - Material phase must be null with customer sale type.'
								goto MSTB_error
							end
							
						if @matlcosttype is not null
							begin
								select @errortext = @errorstart + ' - Material cost type must be null with customer sale type.'
								goto MSTB_error
							end
							
						if @haulphase is not null
							begin
								select @errortext = @errorstart + ' - Haul phase must be null with customer sale type.'
								goto MSTB_error
							end
							
						if @haulcosttype is not null
							begin
								select @errortext = @errorstart + ' - Haul cost type must be null with customer sale type.'
								goto MSTB_error
							end

						if @jcco is not null
							begin
								select @errortext = @errorstart + ' - JC Company must be null with customer sale type.'
								goto MSTB_error
							end
							
						if @job is not null
							begin
								select @errortext = @errorstart + ' - Job must be null with customer sale type.'
								goto MSTB_error
							end
							
						if @toinco is not null
							begin
								select @errortext = @errorstart + ' - IN Company must be null with customer sale type.'
								goto MSTB_error
							end
							
						if @toloc is not null
							begin
								select @errortext = @errorstart + ' - To Location must be null with customer sale type.'
								goto MSTB_error
							end
					end --if @saletype = 'C'
   
				------------------------
				-- validate Job sales --
				------------------------
				if @saletype = 'J'
					begin
						exec @rcode = bspJCJMPostVal @jcco, @job, @msg = @errmsg output
						
						if @rcode = 1
							begin
								select @errortext = @errorstart + ' - ' + @errmsg
								goto MSTB_error
							end
							
						-- Phase Group
						exec @rcode = bspHQGroupVal @phasegroup, @msg = @errmsg output

						if @rcode = 1
							begin
								select @errortext = @errorstart + ' - Invalid HQ Phase Group.'
								goto MSTB_error
							end
							
						-- ISSUE: #139335 --
						IF @paytype IS NOT NULL
							BEGIN
								SELECT @errortext = @errorstart + ' - Payment Type must be null with job sale type.'
								GOTO MSTB_error
							END

						-- ISSUE: #139335 --
						IF @checkno IS NOT NULL
							BEGIN
								SELECT @errortext = @errorstart + ' - Check # Type must be null with job sale type.'
								GOTO MSTB_error
							END

						if @customer is not null
							begin
								select @errortext = @errorstart + ' - Customer must be null with job sale type.'
								goto MSTB_error
							end
							
						if @custjob is not null
							begin
								select @errortext = @errorstart + ' - Customer Job must be null with job sale type.'
								goto MSTB_error
							end
							
						if @custpo is not null
							begin
								select @errortext = @errorstart + ' - Customer PO must be null with job sale type.'
								goto MSTB_error
							end
							
						if @toinco is not null
							begin
								select @errortext = @errorstart + ' - IN Company must be null with customer sale type.'
								goto MSTB_error
							end
							
						if @toloc is not null
							begin
								select @errortext = @errorstart + ' - To Location must be null with job sale type.'
								goto MSTB_error
							end
							
						if isnull(@matlphase,'') = ''
							begin
								select @errortext = @errorstart + ' - Material Phase must not be null with job sale type.'
								goto MSTB_error
							end
							
						if isnull(@matlcosttype, '') = ''
							begin
								select @errortext = @errorstart + ' - Material cost type must not be null with job sale type.'
								goto MSTB_error
							end
							
						if isnull(@haulcode,'') <> '' and isnull(@haulphase,'') = ''
							begin
								select @errortext = @errorstart + ' - Haul phase must not be null with job sale type and haul code assigned.'
								goto MSTB_error
							end
							
						if isnull(@haulcode,'') <> '' and isnull(@haulcosttype,'') = ''
							begin
								select @errortext = @errorstart + ' - Haul cost type must not be null with job sale type and haul code assigned.'
								goto MSTB_error
							end
							
						if isnull(@haulcode,'') = '' and isnull(@haulphase,'') <> ''
							begin
								select @errortext = @errorstart + ' - Haul phase must be null with job sale type and no haul code assigned.'
								goto MSTB_error
							end
							
						if isnull(@haulcode,'') = '' and isnull(@haulcosttype,'') <> ''
							begin
								select @errortext = @errorstart + ' - Haul cost type must be null with job sale type and no haul code assigned.'
								goto MSTB_error
							end
					end --if @saletype = 'J'
   
				-----------------------
				-- validate IN sales --
				-----------------------
				if @saletype = 'I'
					begin
					
						if not exists(select top 1 1 from bINLM with (nolock) where INCo = @toinco and Loc = @toloc and Active = 'Y')
							begin
								select @errortext = @errorstart + ' - Invalid purchasing Location, ' + isnull(@toloc,' ') + ' must be setup in IN and active!'
								goto MSTB_error
							end

						if @toinco = @msco and @toloc = @fromloc
							begin
								select @errortext = @errorstart + ' - Invalid purchasing Location, ' + isnull(@fromloc,' ') + ' must not equal sales Location!'
								goto MSTB_error
							end
							
						-- ISSUE: #139335 --
						IF @paytype IS NOT NULL
							BEGIN
								SELECT @errortext = @errorstart + ' - Payment Type must be null with inventory sale type.'
								GOTO MSTB_error
							END

						-- ISSUE: #139335 --
						IF @checkno IS NOT NULL
							BEGIN
								SELECT @errortext = @errorstart + ' - Check # Type must be null with inventory sale type.'
								GOTO MSTB_error
							END

						if @matlphase is not null
							begin
								select @errortext = @errorstart + ' - Material phase must be null with inventory sale type.'
								goto MSTB_error
							end

						if @matlcosttype is not null
							begin
								select @errortext = @errorstart + ' - Material cost type must be null with inventory sale type.'
								goto MSTB_error
							end
							
						if @haulphase is not null
							begin
								select @errortext = @errorstart + ' - Haul phase must be null with inventory sale type.'
								goto MSTB_error
							end
							
						if @haulcosttype is not null
							begin
								select @errortext = @errorstart + ' - Haul cost type must be null with inventory sale type.'
								goto MSTB_error
							end
							
						if @customer is not null
							begin
								select @errortext = @errorstart + ' - Customer must be null with inventory sale type.'
								goto MSTB_error
							end
							
						if @custjob is not null
							begin
								select @errortext = @errorstart + ' - Customer Job must be null with inventory sale type.'
								goto MSTB_error
							end

						if @custpo is not null
							begin
								select @errortext = @errorstart + ' - Customer PO must be null with inventory sale type.'
								goto MSTB_error
							end

						if @jcco is not null
							begin
								select @errortext = @errorstart + ' - JC Company must be null with customer sale type.'
								goto MSTB_error
							end

						if @job is not null
							begin
								select @errortext = @errorstart + ' - Job must be null with inventory sale type.'
								goto MSTB_error
							end
							
					end --if @saletype = 'I'

				-----------------------  
				-- validate Discount --
				-----------------------
				if @saletype in ('J','I') and (@discoff <> 0 or @taxdisc <> 0)
					begin
						select @errortext = @errorstart + 'Discount and Tax Discount can only be offered on Customer sales.'
						goto MSTB_error
					end
					
				------------------
				-- validate ECM --
				------------------
				if isnull(@ecm,'') = ''
					begin
						select @errortext = @errorstart + ' - Invalid ECM, cannot be null or empty!'
						goto MSTB_error
					end

				if @ecm not in ('E','C','M')
					begin
						select @errortext = @errorstart + ' -  Invalid ECM, must be (E, C, or M)!'
						goto MSTB_error
					end
					
				-----------------------
				-- validate Material --
				-----------------------
				select @category = Category, @stdum = StdUM
				from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material and Active = 'Y' 
			
				if @@rowcount = 0
					begin
						select @errortext = @errorstart + ' - Invalid Material, ' + isnull(@material,' ') + ' must be setup in HQ and active!'
						goto MSTB_error
					end

				if @matlvendor is null  -- sold from stock
					begin
						select @autoprod = AutoProd
						from bINMT with (nolock) 
						where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup 
						and Material = @material and Active = 'Y'
						
						if @@rowcount = 0
							begin
								select @errortext = @errorstart + ' - Invalid Material, ' + isnull(@material,' ') + ' must be stocked and active at sales Location, ' + isnull(@fromloc,'') + ' !'
							goto MSTB_error
						end
					end
   
				if @saletype = 'I'
					begin
						select @toinmatlgroup=MatlGroup from bHQCO where HQCo=@toinco
   						
						if not exists(select top 1 1 from bINMT with (nolock) where INCo = @toinco and Loc = @toloc 
							and MatlGroup = @toinmatlgroup and Material = @material and Active = 'Y')
  							begin
								select @errortext = @errorstart + ' - Invalid Material, ' + isnull(@material,' ') + ' must be stocked and active at purchasing Location, ' + isnull(@toloc,'') + ' !'
								goto MSTB_error
							end
					end
							
				-----------------
				-- validate UM --
				-----------------
				if not exists(select top 1 1 from bHQUM with (nolock) where UM = @um)
					begin
						select @errortext = @errorstart + ' - Invalid unit of measure, ' + isnull(@um,'') + ' must be setup in HQ!'
						goto MSTB_error
					end
           
				if @um <> @stdum
					begin
					
						if @matlvendor is null  
							begin
   							
								-- sold from stock
								if not exists(select top 1 1 from bINMU with (nolock) 
											where INCo = @msco and MatlGroup = @matlgroup 
											and Material = @material and Loc = @fromloc and UM = @um)
									begin
										select @errortext = @errorstart + ' - Invalid UM for this Material, ' + isnull(@material,' ') + ' at sales Location, ' + isnull(@fromloc,'') + ' !'
										goto MSTB_error
									end
							end
						else
							begin
								-- purchased from outside vendor
								if not exists(select top 1 1 from bHQMU with (nolock) where MatlGroup = @matlgroup and Material = @material and UM = @um)
									begin
										select @errortext = @errorstart + ' - Invalid UM for this Material, ' + isnull(@material,' ') + ' in HQMU !'
										goto MSTB_error
									end
							end --if @matlvendor is null 
   
						if @saletype = 'I'
							begin
								-- check if um for to location is the STD UM issue #120087
								select @tomatlstdum=StdUM from bHQMT with (nolock) where MatlGroup=@toinmatlgroup and Material=@material
								
								-- when to std um <> um then must exists in bINMU
								if @tomatlstdum <> @um
									begin
										if not exists(select top 1 1 from bINMU with (nolock) 
												where INCo = @toinco and MatlGroup = @toinmatlgroup
												and Material = @material and Loc = @toloc and UM = @um)

											begin
												select @errortext = @errorstart + ' - Invalid UM for this Material, ' + isnull(@material,' ') + ' at purchasing Location, ' + isnull(@toloc,'') + ' !'
												goto MSTB_error
											end
									end
							end
							
					end -- if @um <> @stdum
					
				-------------------------------------------
				-- validate Material Phase and Cost Type --
				-------------------------------------------
				if @saletype = 'J'
					begin
						-- Phase
						if isnull(@matlphase,'') <> ''
							begin
                   
								exec @rcode = dbo.bspJCVPHASE @jcco, @job, @matlphase, @phasegroup, 'N', @msg = @errmsg output
								
								if @rcode = 1
									begin
										select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
										goto MSTB_error
									end
							end
						else
							begin
								select @errortext = @errorstart + ' - missing material phase.'
								goto MSTB_error
							end
   
						-- Cost Type
						select @sendjcct = convert(varchar(5),@matlcosttype)
               
						if isnull(@sendjcct,'') <> ''
							begin
								exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup,@matlphase, @sendjcct, 'N', @um=@jcum output, @msg=@errmsg output
                   
								if @rcode = 1
									begin
										select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
										goto MSTB_error
    								end
							end
						else
							begin
								select @errortext = @errorstart + ' - missing material cost type.'
								goto MSTB_error
							end
							
					end --if @saletype = 'J'
   
				--------------------------
				-- validate Hauler Type --
				--------------------------
				--Issue 140411 Table allows a null value for HaulType.  Must make check for null or 
				--comparison will fail and error will not be caught.
				if isnull(@haultype,'') not in ('N','E','H')
					begin
     					select @errortext = @errorstart + ' - Invalid Hauler Type, must be (N, E, or H)!'
         				goto MSTB_error
					end
					
				--------------------------	
				-- validate Haul Vendor --
				--------------------------
				if @haultype = 'H'
					begin
						if not exists(select top 1 1 from bAPVM with (nolock) where VendorGroup = @vendorgroup and Vendor = @haulvendor and ActiveYN = 'Y')
							begin
								select @errortext = @errorstart + ' - Invalid Haul Vendor, ' + isnull(convert(varchar(6),@haulvendor),' ') + ' either missing or inactive!'
								goto MSTB_error
							end
     				end

				------------------------
				-- validate Equipment --
				------------------------
				if @haultype = 'E'
					begin
			
						select @equip_cat=Category
						from bEMEM with (nolock) 
						where EMCo=@emco and Equipment=@equip and Type <> 'C' and Status ='A'
						
						if @@rowcount <> 1
							begin
								select @errortext = @errorstart + ' - Invalid Equipment, ' + isnull(@equip,' ') + ' either missing or inactive!'
								goto MSTB_error
							end
		
				-----------------------
				-- validate Employee --
				-----------------------
				if @employee is not null
					begin
						if not exists(select top 1 1 from bPREH with (nolock) where PRCo = @prco and Employee = @employee)
							begin
								select @errortext = @errorstart + ' - Invalid Employee, ' + convert(varchar(6),@employee) + ' is missing!'
								goto MSTB_error
							end
						end
					end

				-------------------------
				-- validate Truck Type --
				-------------------------
				if @trucktype is not null
					begin
						if not exists(select top 1 1 from bMSTT with (nolock) where MSCo = @msco and TruckType = @trucktype)
							begin
								select @errortext = @errorstart + ' - Invalid Truck Type, ' + isnull(@trucktype,'') + ' !'
								goto MSTB_error
							end
					end
					
				------------------------	
				-- validate Haul Code --
				------------------------
				if @haulcode is null
					begin
						if isnull(@haulbasis,0) <> 0
							begin
								select @errortext = @errorstart + ' - Invalid haul basis - no haul code assigned.'
								goto MSTB_error
							end
							
						if isnull(@haultotal,0) <> 0
							begin
								select @errortext = @errorstart + ' - Invalid haul total - no haul code assigned.'
								goto MSTB_error
         					end
         					
					end -- if @haulcode is null
					
      			if @haulcode is not null
					begin
						if not exists(select top 1 1 from bMSHC with (nolock) where MSCo = @msco and HaulCode = @haulcode)
							begin
								select @errortext = @errorstart + ' - Invalid Haul Code, ' + isnull(@haulcode,'') + ' !'
								goto MSTB_error
							end
							
						-- validate Haul Phase and Cost Type
						if @saletype = 'J'
							begin
                   
								-- Phase
								if isnull(@haulphase,'') <> ''
									begin
										exec @rcode = dbo.bspJCVPHASE @jcco, @job, @haulphase, 
													@phasegroup, 'N', @msg = @errmsg output
								
										if @rcode = 1
											begin
												select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
												goto MSTB_error
											end
									end
								else
									begin
										select @errortext = @errorstart + ' - missing haul phase.'
										goto MSTB_error
									end
   
								-- Cost Type
								select @sendjcct = convert(varchar(5),@haulcosttype)
								
								if isnull(@sendjcct,'') <> ''
									begin
										exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup,@haulphase, 
													@sendjcct, 'N', @um = @jcum output, @msg = @errmsg output
													
										if @rcode = 1
											begin
  												select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
  												goto MSTB_error
											end
									end
               			else
							begin
								select @errortext = @errorstart + ' - missing haul cost type.'
								goto MSTB_error
  							end
						
						end -- if @saletype = 'J'
						
					end -- if @haulcode is not null
   
				-----------------------
				-- validate Pay Code --
				-----------------------
				if @paycode is null
					begin
						if isnull(@paytotal,0) <> 0
							begin
								select @errortext = @errorstart + ' - Invalid pay total - no pay code assigned.'
								goto MSTB_error
							end
					end
					
				if @paycode is not null
					begin
						if not exists(select top 1 1 from bMSPC with (nolock) where MSCo = @msco and PayCode = @paycode)
							begin
								select @errortext = @errorstart + ' - Invalid Pay Code, ' + isnull(@paycode,'') + ' !'
								goto MSTB_error
							end
               
						if @haultype <> 'H'
							begin
          						select @errortext = @errorstart + ' - Pay Code, ' + isnull(@paycode,'') + ' only allowed with  Haul Vendor!' 
								goto MSTB_error
							end
							
					end -- if @paycode is not null

				---------------------------
				-- validate Revenue Code --
				---------------------------
				if @revcode is null
					begin
						if isnull(@revtotal,0) <> 0
							begin
								select @errortext = @errorstart + ' - Invalid revenue total - no revenue code assigned.'
								goto MSTB_error
							end
					end
					
				if @revcode is not null
					begin
						if not exists(select top 1 1 from bEMRC with (nolock) where EMGroup=@emgroup and RevCode=@revcode)
							begin
								select @errortext = @errorstart + ' - Invalid EM Revenue Code, ' + isnull(@revcode,'') + ' !'
								goto MSTB_error
							end
				
						if @haultype <> 'E'
							begin
								select @errortext = @errorstart + ' - Revenue Code only allowed with Equipment!'
								goto MSTB_error
							end
				else
					begin
						-- issue #30641 - validate equipment and revenue code category
						if @equip is not null
							begin
								if not exists(select top 1 1 from bEMRR with (nolock) 
										where EMCo=@emco and RevCode=@revcode
										and EMGroup=@emgroup and Category=@equip_cat)
									begin
										select @errortext=@errorstart + 'Revenue Code must be set up in Revenue Rates by Category!'
										goto MSTB_error
									end
								end
								
							end -- if @equip is not null
							
					end -- if @revcode is not null

				------------------------
				-- validate Tax Code --
				-----------------------
				if @taxcode is null
					begin
						if isnull(@taxtotal,0) <> 0
							begin
								select @errortext = @errorstart + ' - Invalid tax total - no tax code assigned.'
								goto MSTB_error
							end
   			
   						if isnull(@taxdisc,0) <> 0
   							begin
   								select @errortext = @errorstart + ' - Invalid tax discount - no tax code assigned.'
								goto MSTB_error
							end
  					end

				if @taxcode is not null
					begin
						select @valueadd=ValueAdd
						from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode
				
						if @@rowcount = 0
							begin
								select @errortext = @errorstart + ' - Invalid Tax Code: ' + isnull(@taxcode,'') + ' !'
								goto MSTB_error
							end
				
						-----------------------		
   						-- validate tax type --
   						-----------------------
   						if @taxtype is null
   							begin
   								select @errortext = @errorstart + ' - Invalid tax type - no tax type assigned.'
   								goto MSTB_error
   							end
				
						if @taxtype not in (1,2,3)
							begin
								select @errortext = @errorstart + ' - Invalid Tax Type, must be 1, 2, or 3.'
								goto MSTB_error
							end
				
						if @taxtype = 3 and isnull(@valueadd,'N') <> 'Y'
							begin
								select @errortext = @errorstart + ' - Invalid Tax Code: ' + isnull(@taxcode,'') + '. Must be a value added tax code!'
								goto MSTB_error
							end
							
					end -- if @taxcode is not null

				if @haulpaytaxcode is null
					begin
						if isnull(@haulpaytaxamt,0) <> 0
							begin
								select @errortext = @errorstart + ' - Invalid Haul Pay Tax amount - no Haul Pay Tax Code assigned.'
							end
					end					
					
				if @haulpaytaxcode is not null
					begin
						select @valueadd=ValueAdd
						from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @haulpaytaxcode
				
						if @@rowcount = 0
							begin
								select @errortext = @errorstart + ' - Invalid Haul Pay Tax Code: ' + isnull(@haulpaytaxcode,'') + ' !'
								goto MSTB_error
							end
				
						-----------------------		
   						-- validate tax type --
   						-----------------------
   						if @haulpaytaxtype is null
   							begin
   								select @errortext = @errorstart + ' - Invalid Haul Pay Tax Type - no tax type assigned.'
   								goto MSTB_error
   							end
				
						if @haulpaytaxtype not in (1,2,3)
							begin
								select @errortext = @errorstart + ' - Invalid Haul Pay Tax Type, must be 1, 2, or 3.'
								goto MSTB_error
							end
				
						if @haulpaytaxtype = 3 and isnull(@valueadd,'N') <> 'Y'
							begin
								select @errortext = @errorstart + ' - Invalid Haul Pay Tax Code: ' + isnull(@haulpaytaxcode,'') + '. Must be a value added tax code!'
								goto MSTB_error
							end
							
					end -- if @haulpaytaxcode is not null
										
			end -- if @transtype in ('A','C')
   
		---------------------------
		-- ReasonCode validation --
		---------------------------
   		if not exists(select top 1 1 from bHQRC with (nolock) 
   			where ReasonCode = @reasoncode) and @reasoncode is not null and @reasoncode <> ''
   			
   			begin
   				select @errortext = @errorstart + '- Invalid Reason Code - ' + isnull(@reasoncode,'')
   				goto MSTB_error
   			end
   
		----------------------------------------------------------------------------------------------------
		-- update Production Audit for auto produced materials sold from stock - changed for issue #19720 --
		----------------------------------------------------------------------------------------------------
		if @oldmatlvendor is null and @oldautoprod = 'Y' and @oldmatlunits <> 0 and @oldvoid = 'N'
           and (@transtype = 'D' or (@transtype = 'C' and (@fromloc <> @oldfromloc or @material <> @oldmaterial
           or @matlunits <> @oldmatlunits or @oldvoid <> @void)))
           
           begin

				-- create 'old' production distributions --
   				exec @rcode = dbo.bspMSTBValProd @msco, @mth, @batchid, @seq, @oldfromloc, @oldmatlgroup, 
   								@oldmaterial, @oldcategory, @oldstdum, @oldmatlunits, @oldum, '0', @errmsg output
           
				if @rcode = 1 goto MSTB_loop
           end
   
		if @matlvendor is null and @autoprod = 'Y' and @matlunits <> 0 and @void = 'N'
			and (@transtype = 'A' or (@transtype = 'C' and (@fromloc <> @oldfromloc or @material <> @oldmaterial
			or @matlunits <> @oldmatlunits or @oldvoid <> @void)))

			begin

				-- create 'new' production distributions --
				exec @rcode = dbo.bspMSTBValProd @msco, @mth, @batchid, @seq, @fromloc, @matlgroup, 
								@material, @category, @stdum, @matlunits, @um, '1', @errmsg output
								
				if @rcode = 1 goto MSTB_loop
			end
   
		-----------------------------------------------------------------------------
		-- update remaining IN, JC, EM, and GL distributions associated with entry --
		-----------------------------------------------------------------------------
		if @transtype in ('C','D') and @oldvoid = 'N'
			begin
			
				-- create 'old' distributions --
				exec @rcode = dbo.bspMSTBValDist @msco, @mth, @batchid, @seq, '0', @errmsg output
				
				if @rcode = 1 goto MSTB_loop
			end
			
		if @transtype in ('A','C') and @void = 'N'
			begin

				-- create 'new' distributions
				exec @rcode = dbo.bspMSTBValDist @msco, @mth, @batchid, @seq, '1', @errmsg output

				if @rcode = 1 goto MSTB_loop
			end
   
--------------   
-- END LOOP --
--------------
goto MSTB_loop


-----------------------------------------------------
-- record error message and go to next batch entry --
-----------------------------------------------------
MSTB_error:	

	----------------------------------------------------------------
	-- MATCH SURCHARGE ERROR WITH PARENT RECORD FOR CLARIFICATION --
	----------------------------------------------------------------
	-- ISSUE: #129350 --
	----TFS-46115  
	IF @SurchargeKeyID IS NOT NULL
		BEGIN
		SELECT @ParentSeq = MSTB.BatchSeq
		FROM dbo.bMSTB MSTB WITH (NOLOCK)
		WHERE MSTB.KeyID = @SurchargeKeyID
		IF @@ROWCOUNT = 1
			BEGIN
			SELECT @errortext = @errortext + ' Parent Seq: ' + dbo.vfToString(@ParentSeq) + ' Surcharge Code: ' + dbo.vfToString(@SurchargeCode)
			END
		END

	---- record error
	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
	-- ANY ERRORS? --
	SET @CleanSurchargeRecords = 'Y'

	if @rcode <> 0 goto bspexit

	goto MSTB_loop


----------------------------------
-- finished with Ticket entries --
----------------------------------
MSTB_end:   
	close bcMSTB
	deallocate bcMSTB
	select @opencursor = 0
   
	------------------------------------------
	-- make sure debits and credits balance --
	------------------------------------------
	select @glco = m.GLCo
	from bMSGL m with (nolock) join bGLAC g with (nolock) on m.GLCo = g.GLCo 
	and m.GLAcct = g.GLAcct and g.AcctType <> 'M'  -- exclude memo accounts for qtys
	where m.MSCo = @msco and m.Mth = @mth and m.BatchId = @batchid
	group by m.GLCo
	having isnull(sum(Amount),0) <> 0

	if @@rowcount <> 0
		begin
			select @errortext =  'GL Company ' + convert(varchar(3), @glco) + ' entries do not balance!'

			exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output

			if @rcode <> 0 goto bspexit
		end
   
	--------------------------------------------------------------
	-- check HQ Batch Errors and update HQ Batch Control status --
	--------------------------------------------------------------
	select @status = 3	-- valid - ok to post

	if exists(select 1 from bHQBE with (nolock) where Co = @msco and Mth = @mth and BatchId = @batchid)
		select @status = 2	-- validation errors

	update bHQBC
	set Status = @status
	where Co = @msco and Mth = @mth and BatchId = @batchid

	if @@rowcount <> 1
		begin
			select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
			goto bspexit
		end

   
	--------------------------------------------------
	-- ANY ERRORS - CLEAN UP MSTB SURCHARGE RECORDS --
	--------------------------------------------------
	-- ISSUE: #129350 --
	IF @CleanSurchargeRecords = 'Y'
		BEGIN
			DELETE bMSTB
			 WHERE Co = @msco 
			   AND Mth = @mth 
			   AND BatchId = @batchid
			   AND SurchargeKeyID IS NOT NULL
		END
   
-----------------
-- END ROUTINE --
-----------------
bspexit:

	-- CLEAN UP CURSOR --
	if @opencursor = 1
		begin
			close bcMSTB
			deallocate bcMSTB
		end

	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')


	--------------------------------------------------
	-- ANY ERRORS - CLEAN UP MSTB SURCHARGE RECORDS --
	--------------------------------------------------
	-- ISSUE: #129350 --
	IF @CleanSurchargeRecords = 'Y'
		BEGIN
			DELETE bMSTB
			 WHERE Co = @msco 
			   AND Mth = @mth 
			   AND BatchId = @batchid
			   AND SurchargeKeyID IS NOT NULL
		END


	return @rcode



GO

GRANT EXECUTE ON  [dbo].[bspMSTBVal] TO [public]
GO
