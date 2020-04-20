SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMImportUploadFirms    Script Date: 8/28/99 9:35:13 AM ******/
   CREATE  proc [dbo].[bspPMImportUploadFirms]
   /*************************************
   * CREATED BY    : GF  07/13/99
   * LAST MODIFIED : GF  09/09/99
   *                 GF  10/24/2001
   *
   * Pass this a ImportId, Project and VendorGroup and it will
   * initialize any project firms not set up from PMWS & PMWM.
   *
   * Pass:
   *       ImportId	ImportId of data
   *       PMCO		PM Company
   *       Project		Project
   *       VendorGroup	VendorGroup
   *
   * Success returns:
   *	0 on Success, 1 on ERROR
   *
   * Error returns:
   *	1 and error message
   **************************************/
    (@importid varchar(10), @pmco bCompany, @project bJob, @vendorgroup bGroup, @msg varchar(255) output)
   
    as
    set nocount on
   
    declare @rcode int, @validcnt int, @opensubct tinyint, @openmaterial tinyint, @vendor bVendor,
    	 @firm bFirm, @description bDesc, @contact bEmployee, @seq int
   
    select @rcode=0, @opensubct=0, @openmaterial=0
   
    if @pmco is null or @project is null or @importid is null or @vendorgroup is null
       begin
       select @msg = 'Missing information!', @rcode=1
       goto bspexit
       end
   
   -- insert subcontract vendors from bPMWS into bPMPF if not exists
   declare subct_cursor cursor LOCAL FAST_FORWARD
   for select Vendor from bPMWS where PMCo=@pmco and ImportId=@importid
   
   open subct_cursor
   set @opensubct = 1
   
   subct_cursor_loop: -- loop through all subcontrtact vendors for this importid
   fetch next from subct_cursor into @vendor
   if @@fetch_status = 0
         begin
           -- create firm if possible
           if @vendor is not null
              begin
                select @firm=FirmNumber from bPMFM where VendorGroup=@vendorgroup and Vendor=@vendor
                if @@rowcount <> 0
                   begin
                     select @contact=min(ContactCode)
                     from bPMPM where VendorGroup=@vendorgroup and FirmNumber=@firm
                     if @@rowcount <> 0 and @contact is not null
                        begin
                          select @validcnt = Count(*) from bPMPF where PMCo=@pmco and Project=@project
                          and VendorGroup=@vendorgroup and FirmNumber=@firm
                          if @validcnt = 0
                             begin
                               select @description = 'Created from PM Import Upload.'
                               select @seq=1
                               select @seq=isnull(Max(Seq),0)+1
                               from bPMPF where PMCo=@pmco and Project=@project
                               insert bPMPF (PMCo,Project,Seq,VendorGroup,FirmNumber,ContactCode,Description)
                                     values (@pmco,@project,@seq,@vendorgroup,@firm,@contact,@description)
                             end
                        end
                   end
              end
           goto subct_cursor_loop
         end
   
   
   -- deallocate cursor
   if @opensubct = 1
   	begin
   	close subct_cursor
   	deallocate subct_cursor
   	set @opensubct = 0
       end
   
   
   -- insert material vendors from bPMWM into bPMPF if not exists
   declare material_cursor cursor LOCAL FAST_FORWARD
   for select Vendor from bPMWM where PMCo=@pmco and ImportId=@importid
   
   open material_cursor
   set @openmaterial = 1
   
   material_cursor_loop: -- loop through all material vendors for this importid
   fetch next from material_cursor into @vendor
   if @@fetch_status = 0
         begin
           -- create firm if possible
           if @vendor is not null
              begin
                select @firm=FirmNumber from bPMFM where VendorGroup=@vendorgroup and Vendor=@vendor
                if @@rowcount <> 0
                   begin
                     select @contact=min(ContactCode)
                     from bPMPM where VendorGroup=@vendorgroup and FirmNumber=@firm
                     if @@rowcount <> 0 and @contact is not null
                        begin
                          select @validcnt = Count(*) from bPMPF where PMCo=@pmco and Project=@project
                          and VendorGroup=@vendorgroup and FirmNumber=@firm
                          if @validcnt = 0
                             begin
                               select @description = 'Created from PM Import Upload.'
                               insert bPMPF (PMCo,Project,VendorGroup,FirmNumber,ContactCode,Description)
                         values (@pmco,@project,@vendorgroup,@firm,@contact,@description)
                             end
                        end
                   end
              end
           goto material_cursor_loop
         end
   
   -- deallocate cursor
   if @openmaterial = 1
   	begin
   	close material_cursor
   	deallocate material_cursor
   	set @openmaterial = 0
       end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMImportUploadFirms] TO [public]
GO
