SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspSLWHAdd    Script Date: 8/28/99 9:36:37 AM ******/
CREATE proc [dbo].[bspSLWHAdd]          
	/***********************************************************
	* CREATED BY: kb 1/29/98
	* MODIFIED By : kb 2/4/99
	*		kb 3/22/00 - added initialization from JB
	*		GG 5/10/00 - removed PrevWC columns from bSLIT
	*		kb 6/15/00 - issue #6671
	*		kb 10/16/00 - issue #10964
	*		GR 11/21/00 - changed datatype from bAPRef to bAPReference
	*		kb 1/11/01 - issue #11852
	*		TV 3/19/01 - issue 11602 add bill month validation.
	*		kb 7/18/01 - issue #12371
	*		kb 07/25/01 - issue #13939
	*		kb 8/13/1 - issue #13902
	*		kb 8/27/1 - issue #14365
	*		kb 9/11/1 - issue #14366
	*		kb 9/17/1 - issue #13773
	*		kb 1/24/2 - issue #14779
	*		ES 3/29/04 - Issue #23959 - Units need to be calculated even though UM is 'LS'
	*		MV 10/26/04 - #25660 - use WC,PrevWC from JBIS, fix SLWI insert calculations
	*		MV 03/09/05 - #27327 trap for arithmetic overflow in SLWI.WCPctComplete calc
	*		DC 08/08/07 - #124944 - SL Items not initializing because WCPctComplete over -99.9999
	*		DC 09/08/08 - #129462 - Divide by zero error in SL WS Init
	*		TJL 02/16/09 - #132290 - Add CMAcct in APVM as default and use here.
	*		DC 03/04/09 - #129889 - AUS SL - Track Claimed  and Certified amounts
	*		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
	*		DC 04/08/09 - Issue #131402 - Error message init when units in JB <> units on SL item.
	*		MV 10/19/09 - #131826 - use Pay Control from APVM if no default Pay Control set on SL Init.
*************************************************************************************
*	when looking at this sp for issue 131402 it was determined that this SP needed 
*	a complete re-write.  I copied the old sp as it was on 4/8/09 below so all of the 
*	notes and logic wouldn't be lost.
*
**************************************************************************************
	*		DC 06/25/09 - #134485 - Initialize Subcontract does not show W/C % to Date in Info or Grid
	*		DC 02/23/10 - #129892 - Handle max retainage
	*		DC 06/25/10 - #135813 - expand subcontract number
	*		GF 11/13/2012 TK-19330 SL Claim Cleanup
	*			
	* USAGE:
	* Called by the SL Worksheet form to add or delete a range
	* of Subcontracts from the Worksheet.
	*
	* When JB is complete, this procedure will optionally use billing
	* information to initialize current work complete and stored materials.
	* Until then, current invoice units and amounts are initialized as 0.00
	*
	* INPUT PARAMETERS
	*	@slco			SL Co#
	*	@beginJCCo		Beginning JC Co#
	*	@endJCCo		Ending JC Co#
	*	@beginjob		Beginning Job
	*	@endjob			Ending Job
	*	@beginSL		Beginning Subcontract
	*	@endSL			Ending Subcontract
	*	@addordelete	'A' = add, 'D' = delete
	*	@paycontrol		AP Payment Control
	*	@apref			AP Reference
	*	@invdescription	AP trans description
	*	@invdate		AP invoice date
	*	@duedate		AP due date - if null calculated from Pay Terms
	*	@cmco			CM Co# for AP trans
	*	@cmacct			CM Account for AP trans
	*	@initfromjb		Y/N to initialize values based on Job Billing
	*	@billmth		The bill month from JB
	*	@sendusername	user name of who initialized the worksheet
	*
	*
	* OUTPUT PARAMETERS
	*	@numrows	# of Subcontracts added or deleted from Worksheet
	*  	@msg      	error message if error occurs
	*
	* RETURN VALUE
	*   	0        	success
	*   	1         	Failure
	*****************************************************/
	(@slco bCompany, @beginJCCo bCompany, @endJCCo bCompany, @beginjob bJob,
		@endjob bJob, @beginSL VARCHAR(30), --bSL, DC #135813
		@endSL VARCHAR(30), --bSL, DC #135813
		@addordelete char(1),
		@paycontrol varchar(10),@apref bAPReference,@invdescription bDesc, @invdate bDate,
		@duedate bDate, @cmco bCompany, @cmacct bCMAcct, @initfromjb bYN, @billmth bMonth,
		@sendusername bVPUserName = null, @numrows int output, @msg varchar(255) output)
	as
	set nocount on
	 
	DECLARE @rcode int, @vendor bVendor, @jcco bCompany, @job bJob, @sl VARCHAR(30), --bSL,   DC #135813
		@vendorgroup bGroup, @slitcurcost bDollar, @description bItemDesc, --bDesc, DC #135813
		@slitinvcost bDollar, @slitinvunits bUnits,
		@slitem bItem, @itemtype tinyint, @phasegroup bGroup,
		@phase bPhase, @slitum bUM, @slitcurunits bUnits, @slitcurunitcost bUnitCost,
		@jbprevwccost bDollar, @slitwcretpct bPct, @slitprevsm bDollar, @smretpct bPct, @linedesc bItemDesc, --bDesc, DC #135813
		@supplier bVendor, @payterms bPayTerms, @holdcode bHoldCode, @itemdesc bItemDesc,
		@jbwcunits bUnits, @jbwccost bDollar, @discdate bDate, @discrate bPct, @slduedate bDate, @rc int,     
		@contractitem bContractItem, @contract bContract, @initsubs bYN, 
		@jbcurrcontract bDollar, @jbcurrunits bUnits, @billnum int, @jbchgordunits bUnits,
		@jbchgordamt bDollar, @jbunitsbilled bUnits, 
		@jbprevunitsbilled bUnits,@totalbilledamt bDollar , @totalbilledunits bUnits,
		@jbtotalcurrcontract bDollar, @jbtotalcurrunits bUnits, @pctcomplete bPct,
		@thisinvamt bDollar, @thisinvunits bUnits, @sltotyn bYN, @billchange bYN,
		@jccium bUM, @username bVPUserName, @wcpctcomplete float, @wcpmsg varchar (255),
		@apvmcmacct bCMAcct, @apcocmacct bCMAcct,@apvmpaycontrol varchar(10),
		@slwh_keyid bigint, @jbwcretamt bDollar, @jbwctodate bDollar, 
		@jbwctodateunits bUnits, @apulgrossamt bDollar, @apulwcunits bUnits, @wcunits bUnits, 
		@wccost bDollar, @wcretamt bDollar, @wctodate bDollar, @wctodateunits bUnits, 
		@unitsclaimed bUnits, @amtclaimed bDollar, @jccicontractunits bUnits,
		@apulretamt bDollar, @wcretpct bPct				
	
	DECLARE @iNextRowIdHeader int,	--Used to loop through Subcontracts
		@iCurrentRowIdHeader int,   --Used to loop through Subcontracts
		@iLoopControlHeader int,	--Used to loop through Subcontracts
		@iNextRowIdItem int,		--Used to loop through Subcontracts Items
		@iCurrentRowIdItem int,		--Used to loop through Subcontracts Items 
		@iLoopControlItem int		--Used to loop through Subcontracts Items	     	          
		
	-- Table variable to hold subcontracts to process 		
	DECLARE @SLHD_temp TABLE
		(
		keyid bigint,
		slco tinyint, 
		sl varchar(30),  --DC #135813
		description varchar(60),
		vendorgroup tinyint,
		vendor int,
		jcco tinyint,
		job varchar(10),
		payterms varchar(10),
		holdcode varchar(10)
		) 	
		
	--Table variable to hold add Worksheet Items
	DECLARE @SLWI_temp TABLE (keyid bigint,
		slco tinyint, 
		sl varchar(30),  --DC #135813
		slitem smallint,
		itemtype tinyint,
		itemdesc varchar(60),
		phasegroup tinyint,
		phase varchar(20),
		um varchar(3),
		curunits numeric(12, 3),
		curunitcost numeric(16, 5),
		curcost numeric(12, 2),
		wcretpct numeric(6, 4),
		storedmatls numeric(12, 2),
		smretpct numeric(6, 4),
		linedesc varchar(60),
		vendorgroup tinyint,
		supplier int,
		invcost numeric(12, 2),
		invunits numeric(12, 3)) 			 		
			          
	SELECT @rcode = 0, @numrows = 0, @wcpmsg = ''
	 
	SELECT @username = SUSER_SNAME()
	
	IF @endSL is null SELECT @endSL = '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'  --DC #135813
	IF @beginSL is null SELECT @beginSL = ''
	IF @endJCCo is null SELECT @endJCCo = 255
	IF @beginJCCo is null SELECT @beginJCCo = 0
	IF @endjob is null SELECT @endjob = '~~~~~~~~~'
	IF @beginjob is null SELECT @beginjob = ''
	     	     
	IF @addordelete <> 'A' and @addordelete <> 'D'
		BEGIN
		SELECT @msg = 'Must pass (A or D) to bspSLWHAdd procedure.', @rcode = 1
		goto bspexit
		END
		
	--Get info from APCO.  SLTotYN = Allow transactions to exceed current total cost (Y/N)  
	SELECT @sltotyn = SLTotYN, @apcocmacct = CMAcct 
	FROM bAPCO with (nolock) 
	WHERE APCo = @slco
     
	-- @addordelete = 'D':  Delete Subcontracts from the Worksheet and exit out of sp.
	IF @addordelete='D'
		BEGIN
		-- delete SLWI Invoices					
		DELETE vSLWIInvoices
		FROM vSLWIInvoices i
		JOIN bSLWI l on l.SLCo = i.SLCo and l.SL = i.SL and l.SLItem = i.SLItem
		JOIN bSLWH h on h.SLCo = l.SLCo and h.SL = l.SL
		WHERE h.SLCo=@slco and h.SL>=@beginSL and h.SL<=@endSL and
				h.JCCo>=@beginJCCo and h.JCCo<=@endJCCo and h.Job>=@beginjob
				and h.Job<=@endjob and (@sendusername is null or h.UserName = @sendusername)
							
		-- delete SLWI Items
		DELETE bSLWI 
		FROM bSLWI join bSLWH on bSLWH.SLCo=bSLWI.SLCo and bSLWH.SL=bSLWI.SL
		WHERE bSLWH.SLCo=@slco and bSLWH.SL>=@beginSL and bSLWH.SL<=@endSL and
			bSLWH.JCCo>=@beginJCCo and bSLWH.JCCo<=@endJCCo and bSLWH.Job>=@beginjob
			and bSLWH.Job<=@endjob and (@sendusername is null or bSLWH.UserName = @sendusername)
		-- delete SLWH Header
		DELETE FROM bSLWH 
		WHERE SLCo=@slco and SL>=@beginSL and SL<=@endSL and JCCo>=@beginJCCo and JCCo<=@endJCCo
			and Job>=@beginjob and Job<=@endjob and (@sendusername is null or bSLWH.UserName = @sendusername)

		SELECT @numrows = @@rowcount
		goto bspexit
		END

	--@addordelete = 'A':  Add Subcontracts to the Worksheet, continue with the following.
	SELECT @iLoopControlHeader = 0  
	
	--add subcontract to temp table to process all eligible subcontracts.
	INSERT INTO @SLHD_temp(keyid, slco, sl, description, vendorgroup, vendor, jcco, job, payterms, holdcode) 
	SELECT KeyID, SLCo, SL, Description, VendorGroup,Vendor, JCCo, Job, PayTerms, HoldCode
	FROM SLHD with (nolock)
	WHERE JCCo >= @beginJCCo and JCCo <= @endJCCo and
		SL >= @beginSL and SL <= @endSL and Job >= @beginjob and Job <= @endjob and
		SLCo = @slco and Status = 0

	--Get keyid to loop through @SLHD_temp table   			  		   						
	SELECT @iNextRowIdHeader = MIN(keyid)
	FROM   @SLHD_temp

	IF ISNULL(@iNextRowIdHeader,0) = 0
		--no SLHD records for the subcontract.
		BEGIN		
		SELECT @msg = 'No Subcontract(s) selected.', @rcode = 1, @iLoopControlHeader = 1	  
		goto bspexit			
		END	

	WHILE @iLoopControlHeader = 0  -- start the main (header) processing loop.
		BEGIN
		
		--Get info from the first record in @SLHD_temp
		SELECT @iCurrentRowIdHeader = keyid, @sl = sl, @description = description, @vendorgroup = vendorgroup, @vendor = vendor, @jcco = jcco,
			@job = job, @payterms = payterms, @holdcode = holdcode
		FROM @SLHD_temp
		WHERE keyid = @iNextRowIdHeader

		-- skip Subcontract if already on Worksheet
		IF exists(SELECT TOP 1 1 FROM bSLWH with (nolock) WHERE SLCo = @slco and SL = @sl) goto GetNextSL
	 
		SELECT @slduedate = @duedate
		IF @slduedate is null		-- if entered Due Date is null, calculcate on based on Pay Terms
			BEGIN
			exec @rc = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @slduedate output,
				@discrate output, @msg output
			IF @rc <> 0
				BEGIN
				SELECT @slduedate = @invdate	-- use Invoice Date bspHQPayTermsDateCalc returned an error
				END
			END
			
		IF @slduedate is null SELECT @slduedate = @invdate  -- use Invoice Date if we could not calculate one.

		SELECT @apvmcmacct = CMAcct, @apvmpaycontrol = PayControl
		FROM bAPVM with (nolock)
		WHERE VendorGroup = @vendorgroup and Vendor = @vendor

		-- add subcontract to Worksheet Header
		INSERT bSLWH (SLCo,SL,JCCo,Job,Description,VendorGroup,Vendor,PayControl,
			APRef,InvDescription,InvDate,PayTerms,DueDate,CMCo,CMAcct,HoldCode,ReadyYN, UserName)
		VALUES(@slco,@sl,@jcco,@job,@description,@vendorgroup,@vendor,isnull(@paycontrol,@apvmpaycontrol),
			@apref,@invdescription,@invdate,@payterms,@slduedate,@cmco,isnull(@cmacct, isnull(@apvmcmacct, @apcocmacct)),
			@holdcode,'N',@username)
	     
		SELECT @numrows = @numrows + 1	-- keep count of the # subcontracts added to Worksheet

		--get the key id for the inserted record.  We use this for subcontracts marked for Vendor Invoicing.			
		SELECT @slwh_keyid = KeyID FROM bSLWH with (nolock) WHERE SLCo = @slco and SL = @sl and UserName = @username

		--reset line looping variable
		SELECT @iLoopControlItem = 0
		
		--Clear @SLWI_temp table of items from previous subcontract header.
		DELETE @SLWI_temp
		
		--Insert SLIT records into @SLWI_temp table
		INSERT INTO @SLWI_temp(keyid, slco, sl, slitem, itemtype, itemdesc, phasegroup, phase, um,curunits,curunitcost,
			curcost,wcretpct, storedmatls, smretpct,linedesc,vendorgroup,supplier,invcost,invunits) 
		SELECT KeyID, SLCo, @sl, SLItem, ItemType, Description, PhaseGroup, Phase, UM, CurUnits, CurUnitCost, 
			CurCost, WCRetPct, StoredMatls, SMRetPct, Description, VendorGroup, Supplier, InvCost, InvUnits
		FROM SLIT
		WHERE SLCo = @slco and SL = @sl   			   			   			
   			  		   		
		--Get keyid to loop through SLWI_temp table   			  		   						
		SELECT @iNextRowIdItem = MIN(keyid)
		FROM   @SLWI_temp
				
		IF ISNULL(@iNextRowIdItem,0) = 0
			--no SLWI records for the subcontract.
			BEGIN			  
			SELECT @iLoopControlItem = 1			
			END	
				
		WHILE @iLoopControlItem = 0  -- start the item processing loop.
			BEGIN

			-- get info from the first record in @SLWI_temp		
			SELECT @iCurrentRowIdItem = keyid, @slitem = slitem, @itemtype = itemtype, @itemdesc = itemdesc, @phasegroup = phasegroup,
					@phase = phase, @slitum = um, @slitcurunits = curunits, @slitcurunitcost = curunitcost, @slitcurcost = curcost, 
					@slitwcretpct = wcretpct, @slitprevsm = storedmatls, @smretpct = smretpct, @linedesc = linedesc, 
					@vendorgroup = vendorgroup, @supplier = supplier, @slitinvcost = invcost, @slitinvunits = invunits
			FROM @SLWI_temp
			WHERE keyid = @iNextRowIdItem	

			--Get contract from Job Master for Job Billing Init
			SELECT @contract = Contract 
			FROM bJCJM with (nolock)
			WHERE JCCo = @jcco and Job = @job
			
			--Get contract item from Job Phase for Job Billing Init
			SELECT @contractitem = Item 
			FROM bJCJP with (nolock)
			WHERE JCCo = @jcco and Job = @job and PhaseGroup = @phasegroup and Phase = @phase
	 
			--Get information about the contract item for Job Billing Init
			SELECT @initsubs = InitSubs, @jccium = UM, @jccicontractunits = ContractUnits
			FROM bJCCI with (nolock)
			WHERE JCCo = @jcco and Contract = @contract and Item = @contractitem

			--Get bill number and bill month for Job Billing Init
			IF @billmth is null
				BEGIN
				SELECT @billmth = max(BillMonth) 
				FROM bJBIT with (nolock) 
				WHERE JBCo = @jcco and Contract = @contract and Item = @contractitem
				IF @billmth is not null
					BEGIN
					SELECT @billnum = max(BillNumber) 
					FROM bJBIT with (nolock) 
					WHERE JBCo = @jcco and Contract = @contract and BillMonth = @billmth and Item = @contractitem     
					END
				END

			-- Init from Job Billing flag
			IF @initfromjb = 'Y'
				BEGIN
				IF not exists(SELECT TOP 1 1 FROM bJBIT with (nolock) WHERE JBCo = @jcco and Contract = @contract and BillMonth = @billmth) goto EndJB

				SELECT @thisinvunits=0, @thisinvamt=0, @billnum = null				

				SELECT @billnum = max(BillNumber) FROM JBIT with (nolock) WHERE JBCo= @jcco
				   and BillMonth = @billmth and Contract = @contract and Item = @contractitem
				IF @billnum is not null
					BEGIN
					SELECT @billchange = 'N' /*this gets initialized as 'N', if a change is made
					 to JBIT, the update trigger of JBIT will see if there is an sl worksheet
					 referencing it and if so will update the BillChangedYN flag to 'Y'*/
					 
					--We use JBIS because it summarizes the amounts for a bill from JBIT.  
					SELECT @jbcurrcontract = sum(CurrContract), @jbcurrunits = sum(ContractUnits),
						@jbchgordamt = sum(ChgOrderAmt), @jbchgordunits = sum(ChgOrderUnits),
						@jbunitsbilled = sum(UnitsBilled), @jbprevunitsbilled = sum(PrevUnits),
						@jbwccost=sum(WC), @jbprevwccost=sum(PrevWC)
					FROM JBIS with (nolock) 
					WHERE JBCo = @jcco and BillMonth = @billmth
					   and BillNumber = @billnum and Item = @contractitem
				
					--Get totals by adding cost with previous cost and change order amounts
					SELECT @totalbilledamt = isnull(@jbwccost,0) + isnull(@jbprevwccost,0), 
						@totalbilledunits = isnull(@jbunitsbilled,0) + isnull(@jbprevunitsbilled,0),
     					@jbtotalcurrcontract = isnull(@jbcurrcontract,0) + isnull(@jbchgordamt,0),
						@jbtotalcurrunits = isnull(@jbcurrunits,0) + isnull(@jbchgordunits,0)

					--The following is used to calculate invoice units and amounts.  Basically, we want to create 
					--invoices at the same percent as was billed.  If the contract item has the same UM and Units 
					--then we use the numbers from JB to avoid rounding errors.
					IF @slitum = 'LS' 
						BEGIN
						SELECT @thisinvunits = 0
						SELECT @thisinvamt = case when @jbtotalcurrcontract = 0 then 0 else (@totalbilledamt/@jbtotalcurrcontract) * @slitcurcost end							
						END
					ELSE	
						BEGIN
						IF @jccium = @slitum and @slitcurunits = @jccicontractunits
							BEGIN
							SELECT @thisinvunits = isnull(@totalbilledunits,0)
							SELECT @thisinvamt = isnull(@thisinvunits,0) * isnull(@slitcurunitcost,0)							
							END
						ELSE
							BEGIN
							IF @jccium = 'LS'
								BEGIN
								--DC #134485
								SELECT @thisinvunits = case when @jbtotalcurrcontract = 0 then 0 else (@totalbilledamt/@jbtotalcurrcontract) * @slitcurunits end
								END
							ELSE
								BEGIN
								SELECT @thisinvunits = case when @jbtotalcurrunits = 0 then 0 else (@totalbilledunits/@jbtotalcurrunits) * @slitcurunits end
								END
							SELECT @thisinvamt = case when @jbtotalcurrcontract = 0 then 0 else (@totalbilledamt/@jbtotalcurrcontract) * @slitcurcost end																				
							END
						END
					END
				END
			EndJB:
			
			--DC #134485
			IF @initfromjb = 'N'
				BEGIN
				SELECT @thisinvamt = @slitcurcost - @slitinvcost
				SELECT @thisinvunits = @slitcurunits - @slitinvunits				
				END 																																					
			
			SELECT @linedesc=@itemdesc  -- convert(varchar(30),@itemdesc)  --DC #135813

			-- calculate WCPctComplete here to prevent arithmetic overflow error during SLWI insert
			SELECT @wcpctcomplete = 
					CASE when @slitum = 'LS' then  --@slitum = 'LS'
						 CASE when @initfromjb = 'Y' then
							  case when @slitcurcost = 0 then 0 else @thisinvamt / @slitcurcost end
						 ELSE  --@initfromjb <> 'Y'
							  case when @slitcurcost = 0 then 0 else @slitinvcost / @slitcurcost end
						 END																													
					ELSE   --@slitum <> 'LS'
						 CASE when @initfromjb = 'Y' then
							  case when @slitcurunits = 0 then 0 else @thisinvunits / @slitcurunits end
						 ELSE  --@initfromjb <> 'Y'
							  case when @slitcurunits = 0 then 0 else @slitinvunits / @slitcurunits end
						 END
					END																																								 									 									 

   		            								
			IF @sltotyn = 'N' and @wcpctcomplete > 1 SELECT @thisinvamt = @slitcurcost, @thisinvunits = @slitcurunits, @wcpctcomplete = 1																																		
									
			--SL Items not initializing because WCPctComplete over -99.9999
			IF @wcpctcomplete > 99.9999 or @wcpctcomplete < -99.9999
				BEGIN
				SELECT @wcpmsg = 'To add SL:' + convert(varchar(30),@sl) + ' Item:' + convert(varchar(10),@slitem) + ' increase current cost/units.'
				SELECT @wcpmsg = @wcpmsg + ' Work Complete Percent cannot exceed 9999%.', @rcode = 2
				SELECT @wcpctcomplete = 0  --DC #134485
				--goto Get_Next_Item
				END
						
			SELECT @jbwcunits = case @initfromjb when 'N' then 0 else case @initsubs when 'Y' then
					isnull(@thisinvunits,0)-@slitinvunits else 0 end end
					
			SELECT @jbwccost = case @initfromjb when 'N' then 0 else case @initsubs when 'Y' then 
					isnull(@thisinvamt,0)-(@slitinvcost - @slitprevsm) else 0 end end
					
			SELECT @jbwcretamt = case @initfromjb when 'N' then 0 else case @initsubs when 'Y' then
					@slitwcretpct * (isnull(@thisinvamt,0)-(@slitinvcost - @slitprevsm)) else 0 end end
					
			SELECT @jbwctodate = @slitinvcost +
 				case @initfromjb when 'N' then 0 else
				case @initsubs when 'Y' then isnull(@thisinvamt,0)- @slitinvcost else 0 end end

			SELECT @jbwctodateunits = @slitinvunits +
	  				case @initfromjb when 'N' then 0 else
					case @initsubs when 'Y' then isnull(@thisinvunits,0)-@slitinvunits else 0 end end				
					
			--Set variables to insert into SLWI based on the InitfromJB flag
				SELECT @wcunits = @jbwcunits, @wccost = @jbwccost, @wcretamt = @jbwcretamt,
					@wctodate = @jbwctodate, @wctodateunits = @jbwctodateunits,
					@unitsclaimed = @jbwcunits, @amtclaimed = @jbwccost,
					@wcretpct = @slitwcretpct
					
			-- We calculated what needs to be inserted into the worksheet above.  So the insert statement to 
			--SLWI is the same regardless if they are initializing from JB or APUL
			INSERT bSLWI(SLCo,SL,SLItem,ItemType,Description,PhaseGroup,Phase,UM,
				CurUnits,
				CurUnitCost,CurCost,
				PrevWCUnits,PrevWCCost, 
				WCUnits, 
				WCCost, 
				WCRetPct, 
				WCRetAmt,
				PrevSM, Purchased,Installed,SMRetPct,SMRetAmt,LineDesc,VendorGroup,Supplier,
  				BillMonth,
  				BillNumber,BillChangedYN,
  				WCPctComplete,
  				WCToDate, 
  				WCToDateUnits,
  				UnitsClaimed, AmtClaimed,
				UserName)
			VALUES(@slco,@sl,@slitem,@itemtype,@itemdesc,@phasegroup,@phase,@slitum,
				@slitcurunits,
				@slitcurunitcost,@slitcurcost,  					
				@slitinvunits, @slitinvcost - @slitprevsm,					
				@wcunits, 				 
				@wccost, 							  
				@wcretpct,
				@wcretamt,  						
				@slitprevsm,0,0, @smretpct,0,@linedesc,@vendorgroup,@supplier,										  
				case when @billnum is null then null else @billmth end,
				@billnum, @billchange,					
				@wcpctcomplete,  						
				@wctodate,  
				@wctodateunits,
				@unitsclaimed, @amtclaimed, 						
				@username)
					
			-- initialize Addon Items
			IF @initfromjb = 'Y'
			   BEGIN
			   exec bspSLAddonCalc @slco, @sl, @msg output
			   END
					
			Get_Next_Item:	
							
			-- Reset looping variables.           
			SELECT @iNextRowIdItem = NULL
			          
			-- get the next iRowId
			SELECT @iNextRowIdItem = MIN(keyid)
			FROM @SLWI_temp
			WHERE keyid > @iCurrentRowIdItem

			-- did we get a valid next row id?
			IF ISNULL(@iNextRowIdItem,0) = 0
				BEGIN
				SELECT @iLoopControlItem = 1
				END																											
			END															
			

			--set the WCRetAmt and WCRetPct based on the Max Retainage settings
			EXEC @rc = vspSLWIRetgPctUpdate @slco, @sl, @msg output				

		GetNextSL:
		-- remove SL header if no items were added #27327
		IF not exists(SELECT TOP 1 1 FROM bSLWI WHERE SLCo = @slco and SL = @sl)
			BEGIN
				DELETE FROM bSLWH WHERE SLCo = @slco and SL = @sl
				SELECT @numrows = @numrows - 1	-- reduce count # of Subcontracts added to Worksheet
			END 

		-- Reset looping variables.           
		SELECT @iNextRowIdHeader = NULL
		          
		-- get the next iRowId
		SELECT @iNextRowIdHeader = MIN(keyid)
		FROM @SLHD_temp
		WHERE keyid > @iCurrentRowIdHeader

		-- did we get a valid next row id?
		IF ISNULL(@iNextRowIdHeader,0) = 0
			BEGIN
			SELECT @iLoopControlHeader = 1
			END																																												

		END


bspexit:				
	IF @rcode=2 SELECT @msg=@wcpmsg
	return @rcode		
		
GO
GRANT EXECUTE ON  [dbo].[bspSLWHAdd] TO [public]
GO
