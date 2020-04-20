SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************/
CREATE  procedure [dbo].[bspMSLBVal]
/***********************************************************
* CREATED BY: GG 11/06/00
* MODIFIED By : GG 11/27/00 - changed datatype from bAPRef to bAPReference
*               GF 05/22/2001 - more validation
*				  SR 07/09/02 - issue 17738 - pass @phasegroup to bspJCVPHASE
*				  GF 10/08/2002 - issue #18771 - changed tax type validate for null
*				  GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
*				GF 02/08/2006 - issue #120169 use to location material group and validate std um to posted um
*				GF 07/08/2008 - issue #128290 new tax type 3-VAT for international tax
*				DAN SO 06/16/2010 - Issue #140033 - PaymentType and CheckNo checks
*				MV 09/07/11 - TK-08245 - add validation of Haul Tax fields.
*
*
*
* USAGE:
* Called from bspMSHBVal to validate Lines associated with
* a given Hauler Time Sheet entry
*
* Errors in batch added to bHQBE using bspHQBEInsert
*
* INPUT PARAMETERS
*   @msco              MS Co#
*   @mth               Batch Month
*   @batchid           Batch ID
*   @seq               Batch Seq#
*   @headertranstype   Transaction type from Header
*   @haultype          Hauler Type - 'E' Equipment or 'H' Haul Vendor
*   @emgroup           EM Group to qualify Revenue Code
*
* OUTPUT PARAMETERS
*   @errmsg        error message
*
* RETURN VALUE
*   0              success
*   1              fail
*****************************************************/
(@msco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @headertranstype char(1),
 @haultype char(1), @emgroup bGroup, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @errorstart varchar(30), @errortext varchar(255), @opencursor tinyint,
        @msinv varchar(10), @apref bAPReference, @inusebatchid bBatchID, @msg varchar(255), @stdum bUM,
        @sendjcct varchar(5), @jcum bUM

-- -- -- bMSLB declares
declare @haulline smallint, @transtype char(1), @mstrans bTrans, @fromloc bLoc, @vendorgroup bGroup,
        @matlvendor bVendor, @matlgroup bGroup, @material bMatl, @um bUM, @saletype char(1),
        @custgroup bGroup, @customer bCustomer, @custjob varchar(20), @custpo varchar(20), @paytype char(1), @checkno bCMRef, -- ISSUE: #140033
        @hold bYN, @jcco bCompany, @job bJob, @phasegroup bGroup, @haulphase bPhase, @hauljcct bJCCType,
        @toinco bCompany, @toloc bLoc, @trucktype varchar(10), @zone varchar(10), @haulcode bHaulCode,
        @haulbasis bUnits, @haultotal bDollar, @paycode bPayCode, @paytotal bDollar, @revcode bRevCode,
        @revtotal bDollar, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @taxtotal bDollar,
        @discoff bDollar, @taxdisc bDollar, @oldfromloc bLoc, @oldvendorgroup bGroup, @oldmatlvendor bVendor,
        @oldmatlgroup bGroup, @oldmaterial bMatl, @oldum bUM, @oldsaletype char(1), @oldcustgroup bGroup,
        @oldcustomer bCustomer, @oldcustjob varchar(20), @oldcustpo varchar(20), @oldpaytype char(1), 
        @oldhold bYN, @oldjcco bCompany, @oldjob bJob, @oldphasegroup bGroup, @oldhaulphase bPhase,
        @oldhauljcct bJCCType, @oldtoinco bCompany, @oldtoloc bLoc, @oldtrucktype varchar(10),
        @oldzone varchar(10), @oldhaulcode bHaulCode, @oldhaulbasis bUnits, @oldhaultotal bDollar,
        @oldpaycode bPayCode, @oldpaytotal bDollar, @oldrevcode bRevCode, @oldrevtotal bDollar, @oldtaxgroup bGroup,
        @oldtaxcode bTaxCode, @oldtaxtype tinyint, @oldtaxtotal bDollar, @olddiscoff bDollar, @oldtaxdisc bDollar,
		@tomatlgroup bGroup, @tomatlstdum bUM, @valueadd varchar(1),
		@haulpaytaxtype tinyint, @haulpaytaxcode bTaxCode, @haulpaytaxrate bUnitCost, @haulpaytaxamt bDollar,
		@oldhaulpaytaxtype tinyint, @oldhaulpaytaxcode bTaxCode, @oldhaulpaytaxrate bUnitCost, @oldhaulpaytaxamt bDollar

select @rcode = 0, @opencursor = 0
   
   -- declare cursor on MS Hauler Time Sheet Batch Lines for validation
   declare bcMSLB cursor LOCAL FAST_FORWARD
   	for select HaulLine, BatchTransType, MSTrans, FromLoc, VendorGroup,
        MatlVendor, MatlGroup, Material, UM, SaleType, CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, -- ISSUE: #140033
        Hold, JCCo, Job, PhaseGroup, HaulPhase, HaulJCCType, INCo, ToLoc, TruckType, Zone, HaulCode,
        HaulBasis, HaulTotal, PayCode, PayTotal, RevCode, RevTotal, TaxGroup, TaxCode, TaxType, TaxTotal,
        DiscOff, TaxDisc, OldFromLoc, OldVendorGroup, OldMatlVendor, OldMatlGroup, OldMaterial, OldUM,
        OldSaleType, OldCustGroup, OldCustomer, OldCustJob, OldCustPO, OldPaymentType, 
		OldHold, OldJCCo, OldJob, OldPhaseGroup, OldHaulPhase, OldHaulJCCType, OldINCo, OldToLoc, OldTruckType, OldZone,
        OldHaulCode, OldHaulBasis, OldHaulTotal, OldPayCode, OldPayTotal, OldRevCode, OldRevTotal,
        OldTaxGroup, OldTaxCode, OldTaxType, OldTaxTotal, OldDiscOff, OldTaxDisc,
        HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate, HaulPayTaxAmt, OldHaulPayTaxType, OldHaulPayTaxCode,
		OldHaulPayTaxRate, OldHaulPayTaxAmt
    from bMSLB where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
    -- open cursor
    open bcMSLB
    select @opencursor = 1
   
    MSLB_loop:
        fetch next from bcMSLB into @haulline, @transtype, @mstrans, @fromloc, @vendorgroup,
            @matlvendor, @matlgroup, @material, @um, @saletype, @custgroup, @customer, @custjob, @custpo, @paytype, @checkno, -- ISSUE: #140033
			@hold, @jcco, @job, @phasegroup, @haulphase, @hauljcct, @toinco, @toloc,
            @trucktype, @zone, @haulcode, @haulbasis, @haultotal, @paycode, @paytotal, @revcode, @revtotal,
            @taxgroup, @taxcode, @taxtype, @taxtotal, @discoff, @taxdisc, @oldfromloc, @oldvendorgroup,
            @oldmatlvendor, @oldmatlgroup, @oldmaterial, @oldum, @oldsaletype, @oldcustgroup,
            @oldcustomer, @oldcustjob, @oldcustpo, @oldpaytype, 
			@oldhold, @oldjcco, @oldjob, @oldphasegroup, @oldhaulphase, @oldhauljcct, @oldtoinco, @oldtoloc, @oldtrucktype, @oldzone, 
			@oldhaulcode, @oldhaulbasis, @oldhaultotal, @oldpaycode, @oldpaytotal, @oldrevcode, @oldrevtotal, 
			@oldtaxgroup, @oldtaxcode, @oldtaxtype, @oldtaxtotal, @olddiscoff, @oldtaxdisc,
			@haulpaytaxtype, @haulpaytaxcode, @haulpaytaxrate, @haulpaytaxamt, @oldhaulpaytaxtype, @oldhaulpaytaxcode, 
			@oldhaulpaytaxrate, @oldhaulpaytaxamt
   
        if @@fetch_status <> 0 goto MSLB_end
   
        -- save Batch Sequence # for any errors that may be found
        select @errorstart = 'Seq#' + convert(varchar(6),@seq) + ' Line#' + convert(varchar(6),@haulline)
   
        -- validate transaction type
        if @transtype not in ('A','C','D')
            begin
            select @errortext = @errorstart + ' -  Invalid transaction type, must be (A, C, or D).'
            goto MSLB_error
            end
        if @headertranstype in ('A','D') and @transtype <> @headertranstype
            begin
            select @errortext = @errorstart + ' - Invalid transaction type, must match header.'
            goto MSLB_error
            end
   
        -- validation specific to Add entries
        if @transtype = 'A'
            begin
            -- validate Trans#
            if @mstrans is not null
                begin
     	        select @errortext = @errorstart + ' - New entries must have a null MS Transaction #!'
                goto MSLB_error
                end
            end
        -- validation specific to both Change and Delete entries
        if @transtype in ('C','D')
            begin
            -- validate Trans#
            if @mstrans is null
                begin
                select @errortext = @errorstart + ' - Change and Delete entries must have a MS Transaction #!'
                goto MSLB_error
                end
            -- check MS Ticket Detail
            select @msinv = MSInv, @apref = APRef, @inusebatchid = InUseBatchId
            from bMSTD where MSCo = @msco and Mth = @mth and MSTrans = @mstrans
            if @@rowcount = 0
                begin
                select @errortext = @errorstart + ' - Invalid MS Transaction #!'
                goto MSLB_loop
                end
            if isnull(@inusebatchid,0) <> @batchid
                begin
                select @errortext = @errorstart + ' - MS Transaction # is not locked by the current Batch!'
                goto MSLB_error
                end
            end
        -- validation specific to Change entries
        if @transtype = 'C'
            begin
            if @msinv is not null
                begin
                -- limit changes on invoiced transactions
                if isnull(@fromloc,'')<>isnull(@oldfromloc,'') or isnull(@saletype,'')<>isnull(@oldsaletype,'')
                    or isnull(@customer,0)<>isnull(@oldcustomer,0) or isnull(@custjob,'')<>isnull(@oldcustjob,'')
                    or isnull(@custpo,'')<>isnull(@oldcustpo,'') or isnull(@paytype,'')<>isnull(@oldpaytype,'')
                    or isnull(@hold,'')<>isnull(@oldhold,'') or isnull(@jcco,0)<>isnull(@oldjcco,0)
                    or isnull(@job,'')<>isnull(@oldjob,'') or isnull(@toinco,0)<>isnull(@oldtoinco,0)
                    or isnull(@toloc,'')<>isnull(@oldtoloc,'') or isnull(@haultotal,0)<>isnull(@oldhaultotal,0)
                    or isnull(@taxtotal,0)<>isnull(@oldtaxtotal,0) or isnull(@discoff,0)<>isnull(@olddiscoff,0)
                    or isnull(@taxdisc,0)<>isnull(@oldtaxdisc,0)
                    begin
                    select @errortext = @errorstart + ' - Transaction has been invoiced, cannot change purchaser or dollar amounts.'
                 goto MSLB_error
                    end
                end
            if @apref is not null
                begin
                -- limit changes on transactions updated to AP, check for Haul Vendor change already made
                if isnull(@paycode,'') <> isnull(@oldpaycode,'') or @paytotal <> @oldpaytotal
                    begin
                    select @errortext = @errorstart + ' - Haul payment has been updated to AP, cannot change Pay Code or amount.'
                    goto MSLB_error
                    end
                end
            -- Haul verification (VerifyHaul = 'Y') applies to Tickets only, so no validation needed here
            end
        -- validation specific to Delete entries
        if @transtype = 'D'
            begin
            if @msinv is not null
                begin
                select @errortext = @errorstart + ' - Already invoiced, cannot delete!'
                goto MSLB_error
                end
            if @apref is not null
                begin
                select @errortext = @errorstart + ' - Haul payment has been updated to AP, cannot delete!'
                goto MSLB_error
                end
            end
        -- validation specific to Add and Change entries
        if @transtype in ('A','C')
            begin
            -- validate From Location
            if not exists(select * from bINLM where INCo = @msco and Loc = @fromloc and Active = 'Y')
            if @@rowcount = 0
                begin
                select @errortext = @errorstart + ' - Invalid sales Location, must be setup in IN and active!'
                goto MSLB_error
                end
            -- validate Material Vendor
            if @matlvendor is not null
                begin
                if not exists(select * from bAPVM where VendorGroup = @vendorgroup and Vendor = @matlvendor and ActiveYN = 'Y')
                    begin
                    select @errortext = @errorstart + ' - Invalid Material Vendor, must be setup in AP and active!'
                    goto MSLB_error
                    end
                end
            -- validate Sale Type
            if @saletype not in ('C','J','I')
                begin
                select @errortext = @errorstart + ' - Invalid Sale Type, must be (C, J, or I)!'
                goto MSLB_error
                end

			-----------------------------
            -- validate Customer sales --
			-----------------------------
            if @saletype = 'C'
                begin

				-- ISSUE: #140033 --
				IF @paytype <> 'C' AND @checkno IS NOT NULL
					BEGIN
						SELECT @errortext = @errorstart + ' - Invalid Check #. Check # may only be assigned with Payment Type (C-Cash).'
						GOTO MSLB_error
					END

                if not exists(select * from bARCM where CustGroup = @custgroup and Customer = @customer and Status <> 'I')
                    begin
                    select @errortext = @errorstart + ' - Invalid Customer, must be setup in AR and active!'
                    goto MSLB_error
                    end
                -- must have Payment Type
                if @paytype not in ('A','C','X')
                    begin
                    select @errortext = @errorstart + ' - Invalid Payment Type, must be (A, C, or X)!'
                    goto MSLB_error
                    end
                end

			------------------------
            -- validate Job sales --
			------------------------
            if @saletype = 'J'
                begin

				-- ISSUE: #140033 --
				IF @paytype IS NOT NULL
					BEGIN
						SELECT @errortext = @errorstart + ' - Payment Type must be null with J-Job Sale Type.'
						GOTO MSLB_error
					END

				-- ISSUE: #140033 --
				IF @checkno IS NOT NULL
					BEGIN
						SELECT @errortext = @errorstart + ' - Check # Type must be null with J-Job Sale Type.'
						GOTO MSLB_error
					END

                exec @rcode = dbo.bspJCJMPostVal @jcco, @job, @msg = @errmsg output
                if @rcode = 1
                    begin
                    select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
                    goto MSLB_error
                    end
                end

			-----------------------
            -- validate IN sales --
			-----------------------
            if @saletype = 'I'
                begin

				-- ISSUE: #140033 --
				IF @paytype IS NOT NULL
					BEGIN
						SELECT @errortext = @errorstart + ' - Payment Type must be null with I-Inventory Sale Type.'
						GOTO MSLB_error
					END

				-- ISSUE: #140033 --
				IF @checkno IS NOT NULL
					BEGIN
						SELECT @errortext = @errorstart + ' - Check # Type must be null with I-Inventory Sale Type.'
						GOTO MSLB_error
					END

                if not exists(select * from bINLM where INCo = @toinco and Loc = @toloc and Active = 'Y')
                    begin
                    select @errortext = @errorstart + ' - Invalid purchasing Location, must be setup in IN and active!'
                    goto MSLB_error
                    end
                if @toinco = @msco and @toloc = @fromloc
                    begin
                    select @errortext = @errorstart + ' - Invalid purchasing Location, must not equal sales Location!'
                    goto MSLB_error
                    end
                end
            -- validate Material
            select @stdum = StdUM
            from bHQMT where MatlGroup = @matlgroup and Material = @material and Active = 'Y'
            if @@rowcount = 0
                begin
                select @errortext = @errorstart + ' - Invalid Material, must be setup in HQ and active!'
                goto MSLB_error
                end
            if @matlvendor is null  -- sold from stock
                begin
                if not exists(select * from bINMT where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup
                        and Material = @material and Active = 'Y')
                    begin
                    select @errortext = @errorstart + ' - Invalid Material, must be stocked and active at sales Location!'
                    goto MSLB_error
                    end
                end
            if @saletype = 'I'
                begin
   			   	select @tomatlgroup=MatlGroup from bHQCO where HQCo=@toinco
                if not exists(select * from bINMT where INCo = @toinco and Loc = @toloc and MatlGroup = @tomatlgroup
                        and Material = @material and Active = 'Y')
                    begin
                    select @errortext = @errorstart + ' - Invalid Material, must be stocked and active at purchasing Location!'
                    goto MSLB_error
                    end
                end
   
            -- validate UM
            if not exists(select * from bHQUM where UM = @um)
                begin
                select @errortext = @errorstart + ' - Invalid unit of measure, must be setup in HQ!'
                goto MSLB_error
                end
            if @um <> @stdum
                begin
                if not exists(select * from bHQMU where MatlGroup = @matlgroup and Material = @material and UM = @um)
                    begin
                    select @errortext = @errorstart + ' - Invalid UM: ' + isnull(@um,'') + '  for Material: ' + isnull(@material,'')
                    goto MSLB_error
                    end
                if @saletype = 'I'
					begin
					-- -- -- check if um for to location is the STD UM issue #120087
					select @tomatlstdum=StdUM from bHQMT with (nolock) where MatlGroup=@tomatlgroup and Material=@material
					-- -- -- when to std um <> um then must exists in bINMU
					if @tomatlstdum <> @um
						begin
						if not exists(select top 1 1 from bINMU with (nolock) where INCo = @toinco and MatlGroup = @tomatlgroup
									and Material = @material and Loc = @toloc and UM = @um)
							begin
							select @errortext = @errorstart + ' - Invalid UM for this Material, ' + isnull(@material,' ') + ' at purchasing Location, ' + isnull(@toloc,'') + ' !'
							goto MSLB_error
							end
						end
					end
-- -- --                     begin
-- -- --                     if not exists(select * from bINMU where INCo = @toinco and MatlGroup = @matlgroup and Material = @material
-- -- --                             and Loc = @toloc and UM = @um)
-- -- --                         begin
-- -- --                         select @errortext = @errorstart + ' - Invalid UM for this Material at purchasing Location!'
-- -- --                         goto MSLB_error
-- -- --                         end
-- -- --                     end
                end
            -- validate Truck Type
            if @trucktype is not null
                begin
                if not exists(select * from bMSTT where MSCo = @msco and TruckType = @trucktype)
                    begin
                    select @errortext = @errorstart + ' - Invalid Truck Type!'
                    goto MSLB_error
                    end
                end
            -- validate Haul Code
            if @haulcode is null
               begin
               if isnull(@haulbasis,0) <> 0
                   begin
                   select @errortext = @errorstart + ' - Invalid haul basis - no haul code assigned.'
                   goto MSLB_error
                   end
               if isnull(@haultotal,0) <> 0
                   begin
                   select @errortext = @errorstart + ' - Invalid haul total - no haul code assigned.'
                   goto MSLB_error
                   end
               end
            if @haulcode is not null
                begin
                if not exists(select * from bMSHC where MSCo = @msco and HaulCode = @haulcode)
                    begin
                    select @errortext = @errorstart + ' - Invalid Haul Code!'
                    goto MSLB_error
                    end
                -- validate Haul Phase and Cost Type
                if @saletype = 'J'
                    begin
                    -- Phase
                    if isnull(@haulphase,'') <> ''
                       begin
                       exec @rcode = dbo.bspJCVPHASE @jcco, @job, @haulphase, @phasegroup, 'N', @msg = @errmsg output
                       if @rcode = 1
                           begin
                           select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
                           goto MSLB_error
                           end
                       end
                   else
                       begin
            select @errortext = @errorstart + ' - missing haul phase.'
                       goto MSLB_error
                       end
   
                   -- Cost Type
                   select @sendjcct = convert(varchar(5),@hauljcct)
                   if isnull(@sendjcct,'') <> ''
                       begin
                       exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup,@haulphase, @sendjcct, 'N', @um = @jcum output, @msg = @errmsg output
                       if @rcode = 1
                           begin
                           select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
                           goto MSLB_error
                           end
                       end
                   else
                       begin
                       select @errortext = @errorstart + ' - missing haul cost type.'
                       goto MSLB_error
                       end
                    end
                end
            -- validate Pay Code
            if @paycode is null
               begin
               if isnull(@paytotal,0) <> 0
                   begin
                   select @errortext = @errorstart + ' - Invalid pay total - no pay code assigned.'
                   goto MSLB_error
                   end
               end
            if @paycode is not null
                begin
                if not exists(select * from bMSPC where MSCo = @msco and PayCode = @paycode)
                    begin
                    select @errortext = @errorstart + ' - Invalid Pay Code!'
                    goto MSLB_error
                    end
                if @haultype <> 'H'
                    begin
                    select @errortext = @errorstart + ' - Pay Code only allowed with Haul Vendor!'
                    goto MSLB_error
                    end
                end
            -- validate Revenue Code
            if @revcode is null
               begin
               if isnull(@revtotal,0) <> 0
                   begin
                   select @errortext = @errorstart + ' - Invalid revenue total - no revenue code assigned.'
                   goto MSLB_error
                   end
               end
            if @revcode is not null
                begin
                if not exists(select * from bEMRC where EMGroup = @emgroup and RevCode = @revcode)
                    begin
                    select @errortext = @errorstart + ' - Invalid EM Revenue Code!'
                    goto MSLB_error
                    end
                if @haultype <> 'E'
                    begin
                    select @errortext = @errorstart + ' - Revenue Code only allowed with Equipment!'
                    goto MSLB_error
                    end
                end
            -- validate Tax Code
           if @taxcode is null
               begin
               if isnull(@taxtotal,0) <> 0
                   begin
                   select @errortext = @errorstart + ' - Invalid tax total - no tax code assigned.'
                   goto MSLB_error
                   end
               end



			if @taxcode is not null
				begin
				select @valueadd=ValueAdd
				from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode
				if @@rowcount = 0
					begin
					select @errortext = @errorstart + ' - Invalid Tax Code: ' + isnull(@taxcode,'') + ' !'
					goto MSLB_error
					end
   				-- validate tax type
   				if @taxtype is null
   					begin
   					select @errortext = @errorstart + ' - Invalid tax type - no tax type assigned.'
   					goto MSLB_error
   					end
				if @taxtype not in (1,2,3)
					begin
					select @errortext = @errorstart + ' - Invalid Tax Type, must be 1, 2, or 3.'
					goto MSLB_error
					end
				if @taxtype = 3 and isnull(@valueadd,'N') <> 'Y'
					begin
					select @errortext = @errorstart + ' - Invalid Tax Code: ' + isnull(@taxcode,'') + '. Must be a value added tax code!'
					goto MSLB_error
					end
				end
			end
   
			IF @haulpaytaxcode IS NULL
			BEGIN
				IF ISNULL(@haulpaytaxamt,0) <> 0
				BEGIN
					SELECT @errortext = @errorstart + ' - Invalid Haul Tax Total - no tax code assigned.'
					GOTO MSLB_error
				END
			END					
					
			IF @haulpaytaxcode IS NOT NULL
			BEGIN
				SELECT @valueadd=ValueAdd
				from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @haulpaytaxcode
		
				IF @@ROWCOUNT = 0
				BEGIN
					SELECT @errortext = @errorstart + ' - Invalid Haul Pay Tax Code: ' + isnull(@haulpaytaxcode,'') + ' !'
					GOTO MSLB_error
				END
		
				-----------------------		
				-- validate tax type --
				-----------------------
				IF @haulpaytaxtype IS NULL
				BEGIN
					SELECT @errortext = @errorstart + ' - Invalid Haul Pay Tax Type - no tax type assigned.'
					GOTO MSLB_error
				END
		
				IF @haulpaytaxtype NOT IN (1,2,3)
				BEGIN
					SELECT @errortext = @errorstart + ' - Invalid Haul Pay Tax Type, must be 1, 2, or 3.'
					GOTO MSLB_error
				END
		
				IF @haulpaytaxtype = 3 AND ISNULL(@valueadd,'N') <> 'Y'
				BEGIN
					SELECT @errortext = @errorstart + ' - Invalid Haul Pay Tax Code: ' + isnull(@haulpaytaxcode,'') + '. Must be a value added tax code!'
					GOTO MSLB_error
				END
						
			END -- IF @haulpaytaxcode IS NOT NULL	
   
   
        -- update JC, EM, and GL distributions associated with Haul Line
        if @transtype in ('C','D')
            begin
            -- create 'old' distributions
            exec @rcode = dbo.bspMSLBValDist @msco, @mth, @batchid, @seq, @haulline, '0', @errmsg output
            if @rcode = 1 goto MSLB_loop
            end
        if @transtype in ('A','C')
            begin
            -- create 'new' distributions
            exec @rcode = dbo.bspMSLBValDist @msco, @mth, @batchid, @seq, @haulline, '1', @errmsg output
            if @rcode = 1 goto MSLB_loop
            end
   
         goto MSLB_loop
   
    MSLB_error:     -- record the validation error and skip to the next line
        exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
        if @rcode <> 0 goto bspexit
        goto MSLB_loop
   
    MSLB_end:   -- finished with Haul Lines for this Sequence
        close bcMSLB
        deallocate bcMSLB
        select @opencursor = 0
   
   
   
   bspexit:
        if @opencursor = 1
     		begin
     		close bcMSLB
     		deallocate bcMSLB
     		end
   
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSLBVal] TO [public]
GO
