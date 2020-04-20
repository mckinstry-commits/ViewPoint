SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPOItemGet    Script Date: 8/28/99 9:32:32 AM ******/
    CREATE        proc [dbo].[bspAPPOItemGet]
      /***********************************************************
      * CREATED BY	: kf 7/3/97
      * MODIFIED BY	: kf 7/3/97   SAE 7/13/97 gr 5/10/99 kb 12/13/99
      *                : GR 04/06/00 - added RecvYN, RecvdUnits, RecvdCost output params as per issue 6310
      *                : kb 8/10/00 - issue #9798
      *                kb 10/28/2 - issue #18878 - fix double quotes
      *				kb 10/29/2 - issue #19163 - added job status output parameter
      *				mv 05/15/03 - #18763 - get paytype from bPOIT
      *				GF 07/10/2003 - #12682 - speed improvements
      *				MV 10/23/03 - #22001 return glcostoverride flag from INCO, set flag to 'Y' for Exp type
      *				MV 02/09/04	- #18769 get PayCategory from bPOIT
      *				MV 10/27/04 - #25714 - back out OldUnits, OldGrossAmt from batch units,amounts
      *				DC 11/07/08 - #130833 - add the 'Supplier' field to the PO Entry form
	  *				MV 12/17/09 - #137039 - Use POHD.VendorGroup if POIT.SupplierGroup is null
	  *				MH 03/19/11 - TK-02793 - Add SM Fields
	  *				MV 05/26/11 - #14400 - return ReviewerGroup based on POItem Type
      *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
      *				MV 08/08/11 - TK07237 - AP project to use POItemLine
      *				MV 08/17/11 -TK-07237 - Add POItemLine validation
	 *				TRL 04/12/12 - TK-13994 Added output parameters for SMPhase and SMJCCostType and SMPHaseGroup
      *
      * USAGE:
      * Called by AP Invoice Programs (Recurring, Unapproved, Entry)
      * Returns info for AP
      * an error is returned if any of the following occurs
      *
      * INPUT PARAMETERS
      *   POCo  PO Co - this is the same as the AP Co
      *   PO
      *   PO Item
      ***********************************************************/
      (@poco bCompany = 0, @po varchar(30) = null, @poitem bItem=null,@POItemLine INT = NULL, @poitemtype tinyint output,
     	@jcco bCompany output, @job bJob output, @phasegrp bGroup output, @phase bPhase output, @jcct bJCCType output,
     	@emco bCompany output, @wo bWO output, @woitem bItem output, @equip bEquip output, @emgroup bGroup output,
     	@costcode bCostCode output, @emct bEMCType output, @inco bCompany output, @loc bLoc output, @matlgrp bGroup output,
     	@material bMatl output, @glacct bGLAcct output, @um bUM output, @units bUnits output, @unitcost bUnitCost output,
     	@ecm bECM output, @gross bDollar output, @taxgroup bGroup output, @taxcode bTaxCode output, @taxtype tinyint output,
     	@glco bCompany output, @glcostoveride bYN output, @comptype varchar(10) output, @component bEquip output, @recvyn bYN output,
       @recvdunits bUnits output, @recvdcost bUnitCost output, @jobstatus int output, @paytype tinyint output,@paycategory int output,
       @supplier bVendor output, @suppliergroup bGroup output, @smco bCompany output, @smworkorder int output, @smscope int output,
	  @smphasegroup bGroup = null output, @smphase bPhase = null output,@smjccosttype bJCCType =null output,
   		@ReviewerGroup VARCHAR(10)OUTPUT, @msg varchar(60) output )
     as
   
     set nocount on
   
     declare @rcode int, @numrows int, /*issue 9798*/ @apunits bUnits, @apcost bDollar, @Dept bDept
     select @rcode = 0
   
     if @poco is null
     	begin
     	select @msg = 'Missing PO Company!', @rcode = 1
   
     	goto bspexit
     	end
   
     if @po is null
   
     	begin
   
     	select @msg = 'Missing PO!', @rcode = 1
     	goto bspexit
     	end
   
   
     if @poitem is null
     	begin
     	select @msg = 'Missing PO Item#!', @rcode = 1
     	goto bspexit
     	end
     	
     IF @POItemLine IS NULL
     	BEGIN
     	SELECT @msg = 'Missing PO Item Dist!', @rcode = 1
     	GOTO bspexit
     	END
   	
	
   
	SELECT @poitemtype=l.ItemType, @jcco= Case when l.ItemType=1 then l.PostToCo else null end, @job=l.Job,
     	@phasegrp=l.PhaseGroup, @phase=l.Phase, @jcct=l.JCCType, @emco= Case when l.ItemType=4 or l.ItemType=5
     	then l.PostToCo else null end, @wo=l.WO, @woitem=l.WOItem, @equip=l.Equip, @emgroup=l.EMGroup,
     	@costcode=l.CostCode, @emct=l.EMCType, @comptype=l.CompType, @component=l.Component,
     	@inco= Case when l.ItemType=2 then l.PostToCo else null end,
     	@loc=l.Loc, @matlgrp=i.MatlGroup, @material=i.Material, @glacct=l.GLAcct, @um=i.UM,
     	@units= Case when i.RecvYN='Y' then l.RecvdUnits - l.InvUnits else l.RemUnits end,
     	@unitcost=i.CurUnitCost, @ecm=i.CurECM, @gross= Case when i.RecvYN='Y' then l.RecvdCost - l.InvCost
     	else l.RemCost end, @taxgroup=l.TaxGroup, @taxcode=l.TaxCode, @taxtype=l.TaxType,@msg=i.Description,
		@glco=l.GLCo, @recvyn = i.RecvYN, @recvdunits = l.RecvdUnits, @recvdcost = l.RecvdCost, @paytype = l.PayType,
   		@paycategory = l.PayCategory,
		@supplier = i.Supplier, @suppliergroup = isnull(i.SupplierGroup,h.VendorGroup),
		@smco = l.SMCo, @smworkorder = l.SMWorkOrder, @smscope = l.SMScope,
		@smphasegroup=l.SMPhaseGroup,@smphase=l.SMPhase,@smjccosttype=l.SMJCCostType
	FROM dbo.POItemLine l
	JOIN dbo.POIT i ON l.POCo=i.POCo AND l.PO=i.PO AND l.POItem=i.POItem
	JOIN dbo.POHD h on l.POCo=h.POCo and l.PO=h.PO
--   		@supplier = Supplier, @suppliergroup = SupplierGroup  --DC #130833
--		from POIT with (nolock) 
	WHERE l.POCo=@poco AND l.PO=@po AND l.POItem=@poitem AND l.POItemLine=@POItemLine
	IF @@Rowcount = 0
	BEGIN
		SELECT @msg='PO Item Dist does not exist!', @rcode=1
     	GOTO bspexit
    END
   
     select @numrows=@@rowcount
   /*get job status, Invoice Reviewer Group */
   if @poitemtype = 1
   	begin
   	select @jobstatus = JobStatus, @ReviewerGroup = RevGrpInv -- #144000
   	from bJCJM with (nolock) where JCCo=@jcco and Job=@job
   	if @@rowcount = 0
   	    begin
   	    select @msg = 'Invalid Job!', @rcode = 1
   	    goto bspexit
   	    end
   	end
   
   -- get batch units, cost for add items
     SELECT @apunits = isnull(sum(Units),0)- isnull(sum(OldUnits),0), 
     	     @apcost = isnull(sum(GrossAmt),0) - isnull(sum(OldGrossAmt),0)
     FROM dbo.APLB with (nolock) 
     WHERE Co = @poco and PO = @po and POItem = @poitem AND POItemLine=@POItemLine
     SELECT @units = @units - @apunits, @gross = @gross - @apcost
   
   
     if @poitemtype = 1 /*job type */
        begin
         select @rcode=0, @glcostoveride=GLCostOveride from JCCO with (nolock) where JCCo=@jcco
         if @@rowcount = 0
            begin
             select @msg = 'Not a valid Job Cost Company!', @rcode = 1
             goto bspexit
            end
        end
   
   
     if @poitemtype = 2 /*inventory type */
         BEGIN
			  SELECT @rcode=0	--, @glcostoveride='Y'
	    
			  SELECT @glcostoveride = OverrideGL
				FROM INCO with (nolock) where INCo=@inco
	    
			  IF @@rowcount = 0
			  BEGIN
				  SELECT @msg = 'Not a valid Inventory Company!', @rcode = 1
				  GOTO bspexit
			  END
			 ELSE
			 BEGIN -- #144000 return Loc Master Reviewer Group
				
				SELECT @ReviewerGroup = ReviewerGroup 
				FROM dbo.INLM
				WHERE INCo=@inco AND Loc=@loc
			 END
         END
   
    if @poitemtype = 3 /*expense type */
       begin
     	select @glcostoveride='Y'
     	-- #144000 reviewer group from GL Acct
     	IF @glco IS NOT NULL AND @glacct IS NOT NULL
     	BEGIN
     		SELECT @ReviewerGroup = ReviewerGroup
			FROM dbo.GLAC
			WHERE GLCo=@glco AND GLAcct=@glacct 
     	END
    	end
   	
   
     if @poitemtype = 4 or @poitemtype = 5 /*Equipment or Work Order type */
        BEGIN
         /*select @rcode=0, @glcostoveride='Y'*/
         SELECT /*@glco=GLCo,*/ @rcode=0, @glcostoveride=GLOverride from EMCO with (nolock) where EMCo=@emco
         IF @@rowcount = 0
         BEGIN
             SELECT @msg = 'Not a valid Equipment Company!', @rcode = 1
             GOTO bspexit
         END
         ELSE
         BEGIN -- #144000 EM Department Reviewer Group
			SELECT @Dept = Department
			FROM dbo.EMEM
			WHERE EMCo=@emco AND Equipment=@equip
			IF @Dept IS NOT NULL
			BEGIN
				SELECT @ReviewerGroup = ReviewerGroup
				FROM dbo.EMDM
				WHERE EMCo=@emco AND Department=@Dept 
			END
         END
        END
        
	IF @poitemtype = 6 /*SM Type*/
	BEGIN
		--Not allowing GL Cost Overrides in SM.
		select @glcostoveride = 'N'
	END
	       
   
   bspexit:
   	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspAPPOItemGet] TO [public]
GO
