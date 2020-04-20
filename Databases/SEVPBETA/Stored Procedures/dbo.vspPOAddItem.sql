SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPOAddItem    Script Date: 10/15/08 9:33:09 AM ******/
	CREATE  proc [dbo].[vspPOAddItem]
	/***********************************************************
	* CREATED BY	: DC	10/15/08
	* MODIFIED BY	:  DC	10/5/09 - #122288 - Store Tax Rate in PO Item
	*					MV	1/13/10 - #137403 - @reqdate input = null
	*					GF 09/12/2010 - issue #141031 changed to use vfDateOnly
	*					GF 7/27/2011 - TK-07144 changed to varchar(30)
	*					EN 9/16/2011 - TK-08292 #144693 added smco, smworkorder, and smscope fields to list of items to save
	*					DAN SO 05/24/2012 - TK-15013 - Added SMPhaseGroup, SMPhase, and SMJCCT fields for SMWO job type
	*
	* USED BY
	*   PO Add Item (Accessed via PO Change Order)
	*
	*
	* USAGE:
	* Add PO Item to POIT.  
	* 
	*
	* INPUT PARAMETERS
	*   poco   
	*   po 
	*   poitem 
	*   itemtype
	*   matlgrp
	*	material
	*	vendmatid
	*	desc
	*	um
	*	recyn
	*	loc
	*	job
	*	phasegrp
	*	phase
	*	jcctype
	*	equip
	*	comptype
	*	component
	*	emgroup
	*	costcode
	*	emctype
	*	wo
	*	woitem
	*	glco
	*	glacct
	*	reqdate
	*	taxgroup
	*	taxcode
	*	taxtype
	*	origunitcost
	*	origecm
	*	notes
	*	paycategory
	*	paytype
	*	inco
	*	emco
	*	jcco
	*	batchid
	*	batchmth
	*	supplier
	*	suppliergroup
	*	taxrate
	*	gstrate
	*	smco
	*	smworkorder
	*	smscope
	*	SMPhaseGroup
	*	SMPhase
	*	SMJCCT
	* 
	* OUTPUT PARAMETERS
	*   @msg      
	*	
	* RETURN VALUE
	*   0         success
	*   1         Failure
	*****************************************************/ 
	(@poco bCompany = 0, @po VARCHAR(30), @poitem bItem, @itemtype tinyint, @matlgrp bGroup,
	@material bMatl, @vendmatid varchar(30),@desc bItemDesc, @um bUM, @recyn bYN,
	@loc bLoc, @job bJob, @phasegrp bGroup, @phase bPhase, @jcctype bJCCType,
	@equip bEquip, @comptype varchar(10), @component bEquip, @emgroup bGroup,
	@costcode bCostCode, @emctype bEMCType, @wo bWO, @woitem bItem, @glco bCompany,
	@glacct bGLAcct, @reqdate bDate = null, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint,
	@origunitcost bUnitCost, @origecm bECM, @notes varchar(max), @paycategory int,
	@paytype tinyint, @inco bCompany, @emco bCompany, @jcco bCompany, 
	@batchid bBatchID, @batchmth bMonth,
	@supplier bVendor, @suppliergroup bGroup,  --DC #130833
	@taxrate bRate, @gstrate bRate, --DC #122288
	@smco bCompany, @smworkorder bWO, @smscope int, --EN TK-08292 #144693
	@SMPhaseGroup bGroup, @SMPhase bPhase, @SMJCCT bJCCType,	-- TK-15013
	@msg varchar(255) output)
	
   as
   
   set nocount on
   
   declare @rcode int, @posttoco bCompany, @origcost bDollar, @dateposted bDate
   
   select @rcode = 0
   
   if @poco is null
	begin
   	select @msg = 'Missing PO Company!', @rcode = 1   
   	goto vspexit
   	end
   
   if @po is null
   	begin   
   	select @msg = 'Missing PO!', @rcode = 1
   	goto vspexit
   	end   
   
   if @poitem is null
   	begin
   	select @msg = 'Missing PO Item#!', @rcode = 1
   	goto vspexit
   	end
   	
   	SELECT @posttoco = CASE @itemtype 
   		WHEN 1 then @jcco 
   		WHEN 2 then @inco 
   		WHEN 3 then @glco 
   		WHEN 4 then @emco 
   		WHEN 5 then @emco
   		WHEN 6 then @smco --EN TK-08292 #144693
   		END    
   		
/* set DatePosted */
----#141031
set @dateposted = dbo.vfDateOnly()
   		  		   		   		 		
	--Add Item to POIT
	insert bPOIT (POCo,PO,POItem,ItemType,MatlGroup,Material,VendMatId,Description,
		UM,RecvYN,PostToCo,Loc,Job,PhaseGroup,Phase,JCCType,Equip,CompType,Component,
		EMGroup,CostCode,EMCType,WO,WOItem,GLCo,GLAcct,ReqDate,TaxGroup,TaxCode,
		TaxType,OrigUnits,OrigUnitCost,OrigECM,OrigCost,OrigTax,CurUnits,CurUnitCost,
		CurECM,CurCost,CurTax,RecvdUnits,RecvdCost,BOUnits,BOCost,TotalUnits,
		TotalCost,TotalTax,InvUnits,InvCost,InvTax,RemUnits,RemCost,RemTax,
		PostedDate,Notes,AddedMth, AddedBatchID,
		PayCategory,PayType,INCo,EMCo,JCCo,JCCmtdTax,
		Supplier, SupplierGroup,  --DC #130833
		TaxRate, GSTRate,  --DC #122288
		SMCo, SMWorkOrder, SMScope, --EN TK-08292 #144693
		SMPhaseGroup, SMPhase, SMJCCostType)	-- TK-15013
	values (@poco,@po,@poitem,@itemtype,@matlgrp,@material,@vendmatid,@desc,
		@um,@recyn,@posttoco,@loc,@job,@phasegrp,@phase,@jcctype,@equip,@comptype,@component,
		@emgroup,@costcode,@emctype,@wo,@woitem,@glco, @glacct,@reqdate,@taxgroup,@taxcode,
		@taxtype,0,@origunitcost,@origecm,0,0,0,@origunitcost,
		@origecm,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,
		@dateposted,@notes,@batchmth, @batchid,
		@paycategory,@paytype,@inco,@emco,@jcco,0,
		@supplier, @suppliergroup,  --DC #130833
		@taxrate, @gstrate,  --DC #122288
		@smco, @smworkorder, @smscope, --EN TK-08292  #144693
		@SMPhaseGroup, @SMPhase, @SMJCCT)	-- TK-15013 
		
	if @@rowcount <> 1
		begin
		select @msg = @@error, @rcode = 1
		goto vspexit
		end   
	                   
   vspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPOAddItem] TO [public]
GO
