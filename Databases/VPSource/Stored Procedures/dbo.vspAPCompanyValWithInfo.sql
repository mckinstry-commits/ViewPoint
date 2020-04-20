SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspAPCompanyValWithInfo]
   /************************************************
    * Created By MV 05/12/05 6X conversion
	* Modifed By:  TJL 03/06/07, Added VendorGroup as output, Modified params for all DDFI ValProcs using this.
	*		TJL 01/29/08 - Issue #126814:  Return EMCO.MatlLastUsedYN value.  Modified params for all DDFI ValProcs using this.
    *			MV 08/18/08 - #128412 - Get Inventory info from INCo referenced in APCo if no Info in @co passed in.
	*			MV 03/04/09 - #132520 - Get intercompany info from @co passed - Equip, Job, Inventory was done in 128412.
	*			MH 04/05/11 - TK-02796 - SM Changes for AP
	*
    * validates Company number and returns info, Also used in APEntry,
    * APRecurInv, APUnapprovedInvoice
    *
    * USED IN
    *    AP Entry
    *
    * PASS IN
    *   Company#
    *   Type
    *
    * RETURN PARAMETERS
    *   GLCO     the GL Company based on the type
    *   GLCostOverride
    *   MatGrp   Material group for this company
    *   PhaseGrp if Type is Job then Phase Group for JobCostCompany
    *   TaxGrp   Tax Group from this post to company
    *	EMGrp	 EM Group from HQCO
    *   BurdenYN Burden Unit Cost flag from IN Company
    *   msg     Company Description from HQCO
    *
    *
    * RETURNS
    *   0 on Success
    *   1 on ERROR and places error message in msg
   
    **********************************************************/
   	(@co bCompany = 0, @type tinyint,
   	  @glco bCompany output, @glcostoveride bYN output, @matlgroup bGroup output,
   	  @phasegrp bGroup output, @taxgrp bGroup output, @emgrp bGroup output, @burdenyn bYN output,
	  @allowcostcodechg bYN = null output, @vendorgroup bGroup output, @emcomatllastusedyn bYN output,
	  @msg varchar(60) output)
   as
   	set nocount on
   
   	declare @rcode int
   
   select @rcode = 0, @phasegrp=null, @taxgrp=null, @emgrp = null
   
   select @msg = Name, @taxgrp=TaxGroup, @matlgroup=MatlGroup, @phasegrp=PhaseGroup, @vendorgroup = VendorGroup
   from bHQCO with (nolock)
   where @co = HQCo
   if @@rowcount = 0
      begin
      select @msg = 'Not a valid HQ Company!', @rcode = 1
      goto bspexit
      end
   
   if @type = 1 or @type = 7 /*job type */
      begin
      select @glco=GLCo, @glcostoveride=GLCostOveride from JCCO where @co=JCCo
		if @@rowcount = 0
			begin
			select @glco=j.GLCo, @glcostoveride=j.GLCostOveride from dbo.JCCO j (nolock) 
			join dbo.APCO a (nolock) on a.JCCo=j.JCCo
			where a.APCo = @co
			if @@rowcount = 0 
				begin
   				select @msg = 'Not a valid Job Cost Company!', @rcode = 1
				goto bspexit
				end
			end
      end
   
   if @type = 2 /*inventory type */
     begin
     --select @glcostoveride='Y'
     select @glco=GLCo, @burdenyn = BurdenCost, @glcostoveride = OverrideGL
     from INCO where @co=INCo
     if @@rowcount = 0
       begin
			select @glco=i.GLCo, @burdenyn = i.BurdenCost, @glcostoveride = i.OverrideGL
    		from INCO i	join APCO a	on a.INCo=i.INCo where @co=a.APCo
    		if @@rowcount = 0
       		begin
				select @msg = 'Not a valid Inventory Company!', @rcode = 1
				goto bspexit
			end
		end
     end
   
   if @type = 3  /*expense type */
   	begin
  	select @glcostoveride='Y'
  	end
   
   if @type = 4 or @type = 5 /*Equipment or Work Order type */
     begin
     select @glco=GLCo, @glcostoveride=GLOverride, @allowcostcodechg=WOCostCodeChg,
	 @emgrp=EMGroup, @emcomatllastusedyn = MatlLastUsedYN 
     from dbo.EMCO (nolock)
     where @co=EMCo
	if @@rowcount = 0
		begin
		select @glco=e.GLCo, @glcostoveride=e.GLOverride, @allowcostcodechg=e.WOCostCodeChg,
		 @emgrp=e.EMGroup, @emcomatllastusedyn = e.MatlLastUsedYN 
		 from dbo.EMCO e (nolock) join dbo.APCO a (nolock) on a.EMCo = e.EMCo where a.APCo=@co
		if @@rowcount = 0
		   begin
		   select @msg = 'Not a valid Equipment Company!', @rcode = 1
		   goto bspexit
		   end
		end 
	end
	
	IF @type = 8
	BEGIN
		SELECT @glco = GLCo FROM SMCO WHERE SMCo = @co
		IF @@rowcount = 0
		BEGIN
			SELECT @msg = 'Not a valid SM Company!', @rcode = 1
			GOTO bspexit
		END
	END
	 
     
   bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspAPCompanyValWithInfo] TO [public]
GO
