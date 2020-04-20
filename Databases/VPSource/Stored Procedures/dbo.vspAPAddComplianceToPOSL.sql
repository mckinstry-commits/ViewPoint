SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[vspAPAddComplianceToPOSL]
  
  
	/***********************************************************
	* CREATED BY: MV 03/15/05
	* MODIFIED By : MV 02/15/07 - #123691 don't include closed POs or SLs 
	*								for updates/adds
    *				MV 09/04/08 - #129679 - include pending POs and SLs (status 3)
	*				MV 10/09/08 - #129923 - ExpDate should be bDate not varchar
	*
	* USAGE:
	* This procedure is called from APComplyPOSL to add/update/delete
	*	compliance codes from POs or SLs.  APComplyPOSL is called from 
	*	Vendor Compliance after a compliance code is added/changed/deleted.
	*	This stored proc replaces bspAPAddComplianceToPO
	*	and bspAPAddComplianceToSL, combining both into one for 6X.
	*
	*  INPUT PARAMETERS
	*   @co - PO Company to be updated (is the same as the AP Company)
	*   @vendorgroup - Vendor Group for AP Company
	*   @vendor - Vendor to be updated
	*   @compcode - Compliance code to be added
	*   @verify
	*   @expdate - for date type compcodes date compliance expires
	*   @complied - for flag type compcodes Y is complied
	*   @notes - memo from APVC
	*   @mode - 'A' for adds, 'C' for changes, 'D' for deletes
	*	@updatepo - flag indicating there are POs to update
	*	@updatesl - flag indicating there are SLs to update
	*
	* OUTPUT PARAMETERS
	*   @msg      error message if error occurs
	* RETURN VALUE
	*   0         success
	*   1         Failure
	*******************************************************************/
  (@co bCompany, @vendorgroup bGroup, @vendor bVendor, @compcode bCompCode,
  	@verify bYN, @expdate bDate = null, @complied bYN,
  	@mode char(1), @updatepo bYN, @updatesl bYN, @msg varchar(90) output)
  as
  set nocount on
  
  declare @rcode int, @desc bDesc, @seq int, @po varchar(90),@sl varchar(90), @comptype char(1),
	@openPO int, @openSL int, @expirationdate bDate
  
  select @rcode=0,@seq=0,@openPO=0,@openSL=0
  
  select @desc=Description, @comptype = CompType from bHQCP where CompCode=@compcode
  
	if @expdate = '' select @expdate = null

-- Update PO
  if @updatepo='Y'
  	begin
		declare bcUpdatePO cursor LOCAL FAST_FORWARD for
  			select PO from bPOHD with (nolock) where VendorGroup=@vendorgroup and
   			Vendor=@vendor and POCo=@co and (Status =0 or Status=1 or Status = 3)
		open bcUpdatePO
  		select @openPO = 1
Next_PO:
  		fetch next from bcUpdatePO into @po

		if @@fetch_status <> 0 goto End_PO
 		
	if @mode='A'
	begin
  		if exists (select 1 from bPOCT with (nolock) where POCo=@co and PO=@po and CompCode=@compcode)
  			begin
  			update bPOCT set Verify=@verify, ExpDate=@expdate, 
  				Complied= case when @comptype = 'D' then null else @complied end where
  				POCo=@co and PO=@po and CompCode=@compcode
  			end
  		else
  			begin
  			select @seq=MIN(Seq) from bPOCT with (nolock) where POCo=@co and PO=@po and CompCode=@compcode
  			if @seq is null select @seq=0
  			select @seq=@seq+1
   			insert bPOCT (POCo,PO,CompCode,Seq,VendorGroup,Vendor,Description,Verify,ExpDate,Complied,Notes)
  				select @co,@po,@compcode,@seq,@vendorgroup,@vendor,@desc,@verify,@expdate,
  			  	case when @comptype = 'D' then null else @complied end,null
   			end
  	end
  
	if @mode='D'
	begin
		if exists (select 1 from bPOCT with (nolock) where POCo=@co and PO=@po and CompCode=@compcode)
			begin
			delete from bPOCT where POCo=@co and PO=@po and CompCode=@compcode
			--select @rcode=1
			end
	end
  
	if @mode='C'
	begin
		if exists (select 1 from bPOCT with (nolock) where POCo=@co and PO=@po and CompCode=@compcode)
			begin
			update bPOCT set Verify=@verify, ExpDate=@expdate, 
				Complied= case when @comptype = 'D' then  null else @complied end 
				where POCo=@co and PO=@po and CompCode=@compcode
			end
	 end

	goto Next_PO	

End_PO:
	if @openPO = 1
      begin
      close bcUpdatePO
      deallocate bcUpdatePO
      end

end -- end PO update

-- Update SL
if @updatesl = 'Y'
	begin
	select @seq = 0
	declare bcUpdateSL cursor LOCAL FAST_FORWARD for
  			select SL from bSLHD with (nolock) where VendorGroup=@vendorgroup and
   			Vendor=@vendor and SLCo=@co and (Status=0 or Status=1 or Status=3)
	open bcUpdateSL
	select @openSL = 1
Next_SL:
	fetch next from bcUpdateSL into @sl
	if @@fetch_status <> 0 goto End_SL
	if @mode='A'
		begin
		if exists (select 1 from bSLCT with (nolock) where SLCo=@co and SL=@sl and CompCode=@compcode)
			begin
			update bSLCT set Verify=@verify, ExpDate=@expdate, 
			  Complied = case when @comptype = 'D' then null else @complied end 
				from bSLCT where
				SLCo=@co and SL=@sl and CompCode=@compcode
			end
		else
			begin
			select @seq=MIN(Seq) from bSLCT with (nolock) where SLCo=@co and SL=@sl and CompCode=@compcode
			if @seq is null select @seq=0
			select @seq=@seq+1
			insert bSLCT (SLCo,SL,CompCode,Seq,VendorGroup,Vendor,Description,Verify,ExpDate,Complied,Notes)
			select @co,@sl,@compcode,@seq,@vendorgroup,@vendor,@desc,@verify,@expdate,
				case when @comptype = 'D' then null else @complied end,null
			end
	  	end
  
  if @mode='D'
  	begin
 	if exists (select * from bSLCT where SLCo=@co and SL=@sl and CompCode=@compcode)
		begin
		delete from bSLCT where SLCo=@co and SL=@sl and CompCode=@compcode
		--select @rcode=1
		end
  	end
  
  if @mode='C'
  	begin
 	if exists (select 1 from bSLCT with (nolock) where SLCo=@co and SL=@sl and CompCode=@compcode)
		begin
		update bSLCT set Verify=@verify, ExpDate=@expdate, 
			Complied= case when @comptype = 'D' then null else @complied end where
			SLCo=@co and SL=@sl and CompCode=@compcode
		end
  	end

	goto Next_SL


End_SL:
	if @openSL = 1
      begin
      close bcUpdateSL
      deallocate bcUpdateSL
      end

end -- end SL update

  
  vspexit:
   
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPAddComplianceToPOSL] TO [public]
GO
