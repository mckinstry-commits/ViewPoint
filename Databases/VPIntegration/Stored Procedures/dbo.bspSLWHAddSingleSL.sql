SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Stored Procedure dbo.bspSLWHAddSingleSL    Script Date: 8/28/99 9:36:38 AM ******/
CREATE proc [dbo].[bspSLWHAddSingleSL]      
	/***********************************************************
	* CREATED BY: kb 1/29/98
	* MODIFIED By : GG 12/07/98
	*		GG 05/15/00 - removed Prev WC columns from bSLIT
	*		kb 5/15/00 - added JB init
	*		kb 8/7/00 - issue #10485
	*		kb 10/16/00 - issue #10964
	*		GR 11/21/00 - changed datatype from bAPRef to bAPReference
	*		kb 1/12/01 - issue #11852
	*		tv 3/28/01 - issue #11602
	*		kb 7/18/1 - issue #12371
	*		kb 07/25/01 - issue #13939
	*		kb 8/13/1 - issue #13902
	*		kb 8/27/1 - issue #14365
	*		kb 9/9/1 - issue #14365
	*		kb 9/11/1 - issue #14366
	*		kb 9/17/1 - issue #13773	*		kb 10/16/1 - issue #14876
	*		ES 04/07/07 - #23959 Correct Units calculation
	*		MV 10/27/04 - #25660 use WC,PrevWC from JBIS, fix SLWI insert calculations
	*		MV 03/09/05 - #27327 trap for arithmetic overflow in SLWI.WCPctComplete calc
	*		MV 03/16/05 - #27327 make return message bigger
	*		MV 03/23/05 = #27327 check for SL header before adding
	*		DC 08/08/07 - #124944 - SL Items not initializing because WCPctComplete over -99.9999
	*		DC 04/21/08 - #127792 - SQL failure error when adding a subcontract previously deleted from worksheet
	*		DC 09/08/08 - #129462 - Divide by zero error in SL WS Init
	*		TJL 02/16/09 - #132290 - Add CMAcct in APVM as default and use here.
	*		DC 03/04/09 - #129889 - AUS SL - Track Claimed  and Certified amounts
	*		DC 04/08/09 - Issue #131402 - Error message init when units in JB <> units on SL item.
	*		MV 01/18/10 - #131826 - - use Pay Control from APVM if no default Pay Control set on SL Add.
*************************************************************************************
*	when looking at this sp for issue 131402 it was determined that this SP needed 
*	a complete re-write.  I copied the old sp as it was on 4/8/09 below so all of the 
*	notes and logic wouldn't be lost.
*
**************************************************************************************
	*		DC 06/25/09 - #134485 - Initialize Subcontract does not show W/C % to Date in Info or Grid	
	*		DC 9/1/09 - #135225 - Pay Control, APRef, Description, Due Date fields not defaulting
	*		DC 02/23/10 - #129892 - Handle max retainage
	*		DC 06/29/10 - #135813 - expand subcontract number
	*		GF 11/13/2012 TK-19330 SL Claim Cleanup
	*
	*
	* USAGE:
	* Called by the SL Worksheet Add form to initialize a single
	* Subcontract.
	*
	* When JB is complete, this procedure will optionally use billing
	* information to initialize current work complete and stored materials.
	* Until then, current invoice units and amounts are initialized as 0.00
	*
	*
	*  INPUT PARAMETERS
	*	@slco		Current SL Co#
	*	@jcco		JC Co# to restrict Subcontracts
	*	@job 		Job to restrict Subcontracts
	*	@sl		Subcontract to add
	*	@paycontrol	Payment Control for AP trans
	*	@apref		Reference for AP trans
	*	@invdescription	Header description for AP trans
	*	@invdate	Invoice Date for AP trans
	*	@duedate	Due Date for AP trans
	*	@cmco		CM Co# for AP trans
	*	@cmacct		CM Account for AP trans
	*
	* OUTPUT PARAMETERS
	*   	@msg     	error message if error occurs
	*
	* RETURN VALUE
	*   	0         	success
	*   	1         	failure
	*		2			SL Items not initializing because WCPctComplete over -99.9999
	*		3			Max Retainage needs to be adjusted
	*		4			Max Retainage exceeded - AUS Claimed and Certified retainage can not be adjusted
	*****************************************************/   
	(@slco bCompany, @jcco bCompany, @job bJob, @sl VARCHAR(30), --bSL, DC #135813
		@paycontrol varchar(10),
		@apref bAPReference,@invdescription bDesc, @invdate bDate, @duedate bDate,
		@cmco bCompany, @cmacct bCMAcct, @initfromjb bYN, @billmth bMonth,
		@msg varchar(255) output)
	as
	set nocount on

	DECLARE @rcode int, @vendor bVendor,@vendorgroup bGroup, @slitcurcost bDollar, @description bItemDesc, --bDesc, DC #135813
		@slitinvcost bDollar, @slitem bItem, @itemtype tinyint, @phasegroup bGroup,
		@phase bPhase, @slitum bUM, @slitcurunits bUnits, @slitcurunitcost bUnitCost,
		@slitwcretpct bPct, @slitprevsm bDollar, @smretpct bPct, @linedesc bItemDesc,
		@supplier bVendor, @payterms bPayTerms, @holdcode bHoldCode, @itemdesc bItemDesc,
		@slduedate bDate, @discdate bDate, @discrate bRate, @jbchgordunits bUnits,
		@sljcco bCompany, @sljob bJob, @status tinyint, @rc int, @slitinvunits bUnits,
		@billnum int, @contractitem bContractItem, @contract bContract,
		@initsubs bYN, @thisinvunits bUnits, @billchange bYN, @jbcurrcontract bDollar,
		@totalbilledamt bDollar, @sltotyn bYN, @totalbilledunits bUnits,
		@thisinvamt bDollar, @jbcurrunits bUnits, 
		@jbtotalcurrcontract bDollar, @jbchgordamt bDollar, @jbunitsbilled bUnits,
		@jbprevunitsbilled bUnits, @jbtotalcurrunits bUnits, @jccium bUM, @slitcount int, @slwicount int,
		@username bVPUserName, @jbwccost bDollar, @jbprevwccost bDollar, @wcpctcomplete float,@wcpmsg varchar (200),
		@apvmcmacct bCMAcct, @apcocmacct bCMAcct, @apvmpaycontrol varchar(10),
		@slwh_keyid bigint, @wcunits bUnits,
		@jccicontractunits bUnits, @apulgrossamt bDollar, @apulwcunits bUnits, @apulretamt bDollar,
		@wccost bDollar, @wcretamt bDollar, @unitsclaimed bUnits,
		@amtclaimed bDollar,@jbwcunits bUnits,@wctodateunits bUnits,
		@jbwcretamt bDollar, @jbwctodate bDollar, @jbwctodateunits bUnits, @wctodate bDollar, 
		@wcretpct bPct   
		
	DECLARE @iNextRowIdItem int,	--Used to loop through Subcontracts Items
			@iCurrentRowIdItem int, --Used to loop through Subcontracts Items
			@iLoopControlItem int  --Used to loop through Subcontracts Items	
			
	--DC #129892			
	DECLARE @retgamtwithheld bDollar, @slwiretgamt bDollar, @totalretamt bDollar,
			@maxretgamt bDollar, @amounttobewithheld bDollar, @diststyle char(1),
			@CountItemsToAdjust int, @RemainingItemRetg bDollar, @slwiwcretamt bDollar, 
			@retmsg varchar(255)
						         
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
	      
	SELECT @rcode = 0, @username = SUSER_SNAME(),@wcpmsg = ''
	SELECT @thisinvunits=0, @thisinvamt=0, @billnum = null, @slitinvunits = 0  --DC Fix
	SELECT @iLoopControlItem = 0  
	   
	-- get Subcontract Header info
	SELECT @sljcco = JCCo, @sljob = Job, @description = Description, @vendorgroup = VendorGroup,
			@vendor = Vendor, @holdcode = HoldCode, @payterms = PayTerms, @status = Status
	FROM SLHD   
	WHERE SLCo = @slco and SL = @sl
	   
	--Get info from APCO.  SLTotYN = Allow transactions to exceed current total cost (Y/N)   
	SELECT @sltotyn = SLTotYN, @apcocmacct = CMAcct 
	FROM bAPCO 
	WHERE APCo = @slco
	   
	IF @@rowcount = 0
		BEGIN
		SELECT @msg = 'Invalid Subcontract ' + @sl + '.  Cannot add to Worksheet.', @rcode = 1
		GOTO bspexit
		END

	IF @status <> 0
		BEGIN
		SELECT @msg = 'Subcontract ' + @sl + ' is not Open.  Cannot add to Worksheet.', @rcode = 1
		goto bspexit
		END

	IF @sljcco <> @jcco or @sljob <> @job
		BEGIN
		SELECT @msg = 'Subcontract ' + @sl + ' is associated with another Job.  Cannot add to Worksheet.', @rcode = 1
		goto bspexit
		END
	   	   	   	   		
	--check to see if the subcontract is already in the worksheet.  If it is but not all
	--of the items are in the worksheet, it will add the missing items.
	IF exists(select TOP 1 1 from bSLWH with (nolock) where SLCo = @slco and SL = @sl)
		BEGIN
		SELECT @slitcount = count(1) from SLIT with (nolock) where SLCo = @slco and SL = @sl
		SELECT @slwicount = count(1) from SLWI with (nolock) where SLCo = @slco and SL = @sl
		IF @slitcount = @slwicount
			BEGIN
 			SELECT @msg='Subcontract ' + @sl + ' already exists on the Worksheet.', @rcode = 1
 			goto bspexit  --DC #129892
			END
		END					

	-- use input Due Date, or calculate one based on Pay Terms
	SELECT @slduedate = @duedate
	IF @slduedate is null
		BEGIN
		exec @rc = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @slduedate output,
			@discrate output, @msg output
		IF @rc <> 0
			BEGIN
			SELECT @slduedate = @invdate	-- if one cannot be calculated, use Invoice Date
			END
		END
   
	IF @slduedate is null SELECT @slduedate = @invdate 
					
	SELECT @apvmcmacct = CMAcct, @apvmpaycontrol = PayControl
	FROM bAPVM
	WHERE VendorGroup = @vendorgroup and Vendor = @vendor

	-- add Worksheet Header
	IF not exists(select 1 from bSLWH where SLCo = @slco and SL = @sl)
		BEGIN					
		INSERT bSLWH (SLCo,SL,JCCo,Job,Description,VendorGroup,Vendor,PayTerms,HoldCode,ReadyYN, UserName, 
			InvDate, DueDate, CMCo, CMAcct,
			PayControl, APRef, InvDescription)  --DC #135225
		VALUES(@slco,@sl,@sljcco,@sljob,@description,@vendorgroup,@vendor,@payterms,@holdcode,'N', @username,
			@invdate, @slduedate, @cmco, isnull(@cmacct, isnull(@apvmcmacct, @apcocmacct)),
			isnull(@paycontrol,@apvmpaycontrol), @apref, @invdescription)  --DC #135225
		
		--get the key id for the inserted record				
		SELECT @slwh_keyid = KeyID from bSLWH WHERE SLCo = @slco and SL = @sl and UserName = @username
		END
				   		
	--Insert SLIT records into @SLWI_temp table
	INSERT INTO @SLWI_temp(keyid, slco, sl, slitem, itemtype, itemdesc, phasegroup, phase, um,curunits,curunitcost,
		curcost,wcretpct, storedmatls, smretpct,linedesc,vendorgroup,supplier,invcost,invunits) 
	select t.KeyID, t.SLCo, @sl, t.SLItem, t.ItemType, t.Description, t.PhaseGroup, t.Phase, t.UM, t.CurUnits, t.CurUnitCost, 
		t.CurCost, t.WCRetPct, t.StoredMatls, t.SMRetPct, t.Description, t.VendorGroup, t.Supplier, t.InvCost, t.InvUnits
	from bSLIT t
	where t.SLCo = @slco and t.SL = @sl 
			and not exists(select 1 from bSLWI w where w.SLCo = t.SLCo and w.SL = t.SL and w.SLItem = t.SLItem)  			   			   			
   			  		   		
	--Get keyid to loop through SLWI_temp table   			  		   						
	SELECT @iNextRowIdItem = MIN(keyid)
	FROM   @SLWI_temp
				
	IF ISNULL(@iNextRowIdItem,0) = 0
		--no SLWI records for the subcontract.
		BEGIN			  
		SELECT @iLoopControlItem = 1			
		END	

WHILE @iLoopControlItem = 0  -- start the main processing loop.
	BEGIN
		
		-- get info from the first record in @SLWI_temp		
		SELECT @iCurrentRowIdItem = keyid, @slitem = slitem, @itemtype = itemtype, @itemdesc = itemdesc, @phasegroup = phasegroup,
				@phase = phase, @slitum = um, @slitcurunits = curunits, @slitcurunitcost = curunitcost, @slitcurcost = curcost, 
				@slitwcretpct = wcretpct, @slitprevsm = storedmatls, @smretpct = smretpct, @linedesc = linedesc, 
				@vendorgroup = vendorgroup, @supplier = supplier, @slitinvcost = invcost, @slitinvunits = invunits
		FROM @SLWI_temp
		WHERE keyid = @iNextRowIdItem	
				   		 		   		
		/*get jb stuff*/
		SELECT @billnum = null,  @billchange = null
		
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
				 WHERE JBCo = @jcco	and Contract = @contract and BillMonth = @billmth and Item = @contractitem
				 END
			 END

		-- If the subcontract is marked for vendor invoicing, we ignore the Init from Job Billing flag				   		 		   		
		IF @initfromjb = 'Y'
			BEGIN
			IF not exists(SELECT TOP 1 1 FROM bJBIT with (nolock) WHERE JBCo = @jcco and Contract = @contract and BillMonth = @billmth) goto EndJB
	   
			SELECT @thisinvunits=0, @thisinvamt=0, @billnum = null	   
			
			SELECT @billnum = max(BillNumber) 
			FROM JBIT with (nolock)
			WHERE JBCo= @jcco and BillMonth = @billmth and Contract = @contract and Item = @contractitem
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
				WHERE JBCo = @jcco and BillMonth = @billmth and BillNumber = @billnum and Item = @contractitem
	   
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
       
				END ----@billnum is not null done



			EndJB:
			END ----@initfromjb = 'Y' done

		--DC #134485
		IF @initfromjb = 'N'
			BEGIN
			SELECT @thisinvamt = @slitcurcost - @slitinvcost
			SELECT @thisinvunits = @slitcurunits - @slitinvunits				
			END 

		SELECT @linedesc= convert(varchar(30),@itemdesc)

		---- calculate WCPctComplete here to prevent arithmetic overflow error during SLWI insert
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
			
		--DC #134485
		--SELECT @wcpctcomplete = @thisinvamt / @slitcurcost 
		IF @sltotyn = 'N' and @wcpctcomplete > 1 SELECT @thisinvamt = @slitcurcost, @thisinvunits = @slitcurunits, @wcpctcomplete = 1																													
								
		--SL Items not initializing because WCPctComplete over -99.9999
		IF @wcpctcomplete > 99.9999 or @wcpctcomplete < -99.9999
			BEGIN
			SELECT @wcpmsg = 'To add SL:' + convert(varchar(30),@sl) + ' Item:' + convert(varchar(10),@slitem) + ' increase current cost/units.'  --DC #135813
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

	END ---- main processing loop complete



--DC #129892		
SetRetg:		
	--Find out what has been set as the maximum amount to be withheld from the subcontract header
	EXEC @rc = vspSLMaxRetgAmt @slco, @sl, @maxretgamt output, @retmsg output
	--If @maxretgamt = 0 then no max retainage amount has been setup for the subcontract.
	IF @maxretgamt = 0 
		BEGIN
		SELECT @msg = 'Maximum Retainage limits have not been set on this subcontract.', @rcode = 0
		GOTO bspexit
		END
		
	--DC #129892
	--Find out what has already been withheld	
	EXEC @rc = vspSLRetgWithheld @slco, @sl, @retgamtwithheld output, @retmsg output

	--DC #129892
	--Find out what is defaulted into SLWorksheet to be withheld
	SELECT @slwiretgamt = sum(isnull(WCRetAmt,0))
	FROM bSLWI with (nolock)
	WHERE SLCo = @slco and SL = @sl
	GROUP BY SLCo, SL
	
	--DC #129892
	--Add what has been withheld to what is defaulted to be withheld
	SELECT @totalretamt = @slwiretgamt + @retgamtwithheld
	
	--DC #129892
	--If the totalretamt is less then the maxretgamt then exit
	If @totalretamt > @maxretgamt
		BEGIN
		SELECT @rcode = 3, @retmsg = 'Exceeds maximum retainage limits'			
		END
		

bspexit:   
	-- remove SL header if no items were added 
	IF not exists(select top 1 1 from bSLWI where SLCo = @slco and SL = @sl)
		BEGIN
		delete from bSLWH where SLCo = @slco and SL = @sl
		END 	   	
	   
	IF @rcode=2 select @msg=@wcpmsg
	IF @rcode=3 or @rcode=4 select @msg=@retmsg
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspSLWHAddSingleSL] TO [public]
GO
