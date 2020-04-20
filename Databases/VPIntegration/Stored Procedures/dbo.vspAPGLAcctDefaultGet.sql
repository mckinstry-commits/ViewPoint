SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINGlacctDflt    Script Date: 12/6/2004 8:26:01 AM ******/
    CREATE proc [dbo].[vspAPGLAcctDefaultGet]
     /***********************************************************
      * CREATED BY: MV 05/23/06
      * Modified by:	MV 11/13/07 #29702 return Rev Grp for Unapproved Exp lines 
      *					mh 03/19/11 - TK02793 
      *					MH 08/08/11 - TK07417 Check SMWorkOrderScope.IsComplete.  If tracking WIP and value = 'Y' then
      *					Cost Account will be returned as opposed to WIP.
      *					MH 08/12/11 - TK07482 - Swap MiscellaneousType for SMCostType
      *					DAN SO 01/03/2012 - TK-10952 - updated call to udpated bspEMGlacctDflt procedure
      *
      * USAGE:
      * calls out to specific stored proc to get default GLAcct based on line type 
      *
      * INPUT PARAMETERS
	  *	@linetype
      * @co  
	  * @job
	  * @phasegrp
	  * @phase
	  * @jccosttype
      * @location   	
      * @material   	
      *	@matlgroup
	  * @vendorgroup
	  * @vendor
	  * @emgroup
	  * @equip
	  * @emcosttype
	  * @costcode	
	  * @smco
	  * @smworkorder
	  * @smscope
	  * @smcosttype
      *
      * OUTPUT PARAMETERS
      *   @smglco - GL Company used by an SM Department to which the GL Account is tied to.
      *   @glacct        
      *   @msg           Error message
      *
      * RETURN VALUE
      *   0         success
      *   1         failure
      *****************************************************/
     	(@linetype int, @co bCompany = null, @job bJob = null, @phasegrp bGroup = null,
		 @phase bPhase = null,@jccosttype bJCCType = null, @location bLoc = null, @material bMatl = null,
     	 @matlgroup bGroup = null, @vendorgrp bGroup = null, @vendor bVendor = null,@emgroup bGroup = null,
		 @equip bEquip = null, @emcosttype bEMCType = null, @costcode bCostCode = null, 
		 @smco bCompany = null, @smworkorder int = null, @smscope int = null, @smcosttype varchar(10) = null,
		 @smglco bCompany output, @glacct bGLAcct output, @reviewergroup varchar(10) output,@msg varchar(255) output)
    
     as
     set nocount on
     
     declare @rcode int,@overridegl bYN, @gltransacct bGLAcct, @iscomplete bYN,
			@EMGLOverride bYN -- TK-10952 --
    
     SELECT @rcode = 0
     SELECT @glacct = NULL	
     SELECT @iscomplete = 'N'	
    
     if @linetype is null
         begin
         select @msg = 'Missing line type.', @rcode = 1
         goto bspexit
         end
    
  if @linetype = 1 --Job
	begin
		exec @rcode =  bspJCCAGlacctDflt @co, @job, @phasegrp, @phase, @jccosttype, 'N', @glacct = @glacct output,
				 @msg = @msg output
	end

  if @linetype = 2 --Inventory
	begin
		exec @rcode = bspINGlacctDflt @co,@location, @material,@matlgroup,@glacct = @glacct output,@overridegl = @overridegl output,
			@msg = @msg output
	end

  if @linetype = 3 -- Expense
	begin
		exec @rcode = bspAPGlacctDflt @vendorgrp,@vendor,@matlgroup, @material,@glacct = @glacct output,@msg = @msg output
		if @rcode = 0
		begin
			--Get Reviewer Group for Vendor's GLAcct not Material GLAcct
			select @reviewergroup = ReviewerGroup from GLAC where GLCo=@co and GLAcct=@glacct
		end
	end

  if @linetype = 4 -- EM or WO
	begin
		-- TK-10952 --
		exec @rcode = bspEMGlacctDflt @co,@emgroup,@emcosttype,@costcode,@equip, @gltransacct output, @EMGLOverride output, @msg = @msg output
		if @rcode = 0 select @glacct=@gltransacct
 	end

	IF @linetype = 8
	BEGIN
	
		--This will return the GL Account when creating a Transaction line for an SM Miscellanious transaction.
  		DECLARE @DefaultCostAcct bGLAcct, @DefaultRevenueAcct bGLAcct, 
  		@DefaultWIPAcct bGLAcct, @smlinetype tinyint,@istrackingwip bYN
		
		SELECT @smlinetype = 3

		SELECT @istrackingwip = IsTrackingWIP, @iscomplete = IsComplete
		FROM SMWorkOrderScope 
		WHERE SMCo = @smco and WorkOrder = @smworkorder and Scope = @smscope
	
		SELECT @smglco = GLCo, @DefaultCostAcct = CostGLAcct, 
		@DefaultRevenueAcct = RevenueGLAcct, @DefaultWIPAcct = CostWIPGLAcct
		FROM dbo.vfSMGetAccountingTreatment (@smco, @smworkorder, @smscope, @smlinetype, @smcosttype)
		
		IF @istrackingwip = 'Y' and @iscomplete = 'N'
		BEGIN
			SELECT @glacct = @DefaultWIPAcct
		END
		ELSE
		BEGIN
			SELECT @glacct = @DefaultCostAcct
		END
		
	END
	
     bspexit:
     	if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[vspAPGLAcctDefaultGet]'
     	return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspAPGLAcctDefaultGet] TO [public]
GO
