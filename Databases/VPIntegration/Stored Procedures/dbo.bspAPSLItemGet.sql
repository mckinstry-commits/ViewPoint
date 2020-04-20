SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPSLItemGet    Script Date: 8/28/99 9:32:33 AM ******/
   CREATE proc [dbo].[bspAPSLItemGet]
   /***********************************************************
    * CREATED BY	: kf 7/3/97
    * MODIFIED BY	: kf 7/3/97
    *                GG 05/16/00 - Added return parameter for Stored Matls
    *                GR 08/16/00 - Added return param for Job Status
    *              kb 10/29/2 - issue #18878 - fix double quotes
    *               MV 07/14/08 - #128288 SL TaxCodes for GST
	*				MV 03/04/09 - #132164 - return Job Reviewer Group
	*				GP 6/28/10 - #135813 change bSL to varchar(30) 
    *
    * USAGE:
    * Called by AP Invoice Programs (Recurring, Unapproved, Entry) to
    * return info about a Subcontract Item
    *
    * INPUT PARAMETERS
    *   @slco              SL Co# - this is the same as the AP Co
    *   @sl                Subcontract
    *   @slitem            SL Item#
    *
    * OUTPUT PARAMETERS
    *   @jcco              JC Co#
    *   @job               Job
    *   @phasegrp          Phase Group
    *   @phase             Phase
    *   @jcct              JC Cost Type
    *   @glco              GL Co# - based on JC Co#
    *   @glacct            GL Account - job expense
    *   @um                Unit of measure
    *   @units             Remaining Units (Current - Invoiced)
    *   @unitcost          Current unit cost
    *   @gross             Remaining Cost (Current - Invoiced)
    *   @glcostoveride     Allow GL Acct override (from bJCCO)
    *   @retgpct           Work Complete retainage percentage
    *   @supplier          Supplier
    *   @storedmatls       Stored Materials
    *   @status            Job Status
    *   @msg               Item description or error message
    *
    * RETURN
    *   0 = success, 1 = error
    ******************************************************/
       (@slco bCompany = 0, @sl varchar(30) = null, @slitem bItem=null, @jcco bCompany output, @job bJob output,
   	@phasegrp bGroup output, @phase bPhase output, @jcct bJCCType output, @glco bCompany output,
   	@glacct bGLAcct output, @um bUM output, @units bUnits output, @unitcost bUnitCost output,
   	@gross bDollar output, @glcostoveride bYN output, @retgpct bPct output, @supplier bVendor output,
    @storedmatls bDollar output, @status int output,@taxgroup bGroup output, @taxtype int output,
    @taxcode bTaxCode output, @reviewergroup varchar (10) output, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- get Item information from bSLIT
   select @jcco=JCCo, @job=Job, @phasegrp=PhaseGroup, @phase=Phase, @jcct=JCCType, @glacct=GLAcct,
   	@um=UM, @units=CurUnits-InvUnits, @unitcost=CurUnitCost, @gross=CurCost-InvCost,
   	@msg=Description, @glco=GLCo, @retgpct=WCRetPct, @supplier=Supplier, @storedmatls = StoredMatls,
    @taxgroup = TaxGroup,@taxtype=TaxType,@taxcode=TaxCode
   from SLIT
   where SLCo=@slco and SL=@sl and SLItem=@slitem
   if @@rowcount=0
   	begin
   	select @msg = 'Invalid SL Item!', @rcode = 1
   	goto bspexit
   	end
   
   -- get JobStatus from JC JobMaster
   select @status = JobStatus, @reviewergroup = RevGrpInv
   from bJCJM where JCCo=@jcco and Job=@job
   if @@rowcount = 0
       begin
       select @msg = 'Invalid Job!', @rcode = 1
       goto bspexit
       end
   
   -- get GL Account override option from JC Company
   select @glcostoveride = GLCostOveride
   from JCCO
   where JCCo=@jcco
   if @@rowcount = 0
       begin
       select @msg = 'Invalid Job Cost Company!', @rcode = 1
       goto bspexit
       end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPSLItemGet] TO [public]
GO
