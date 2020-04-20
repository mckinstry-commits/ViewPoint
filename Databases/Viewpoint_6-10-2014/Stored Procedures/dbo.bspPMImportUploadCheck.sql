SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMImportUploadCheck    Script Date: 2/11/2005 ******/
   CREATE  procedure [dbo].[bspPMImportUploadCheck]
   /*******************************************************************************
    * Creation Date: 02/11/2005 GF
    * Modified Date: 
    *
    *
    * This SP is called from the bspPMImportUpload procedure to check for PMWD.UM that are 
    * different from the JCCH.UM. If found, then checks for committed cost in bJCCP. 
    * If exists, error is returned and user must correct problem before upload can continue.
    * Need to do this because possible to update committed to JCCP only with no detail in JCCD.
    *
    * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
    *
    * Pass In
    * PMCo			PM Company
    * ImportId		ImportId to upload
    * Project		Project
    *
    * RETURN PARAMS
    *   msg           Error Message, or Success message
    *
    * Returns
    * STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
    *
   ********************************************************************************/
   (@pmco bCompany = Null, @importid varchar(10) = Null, @project bJob = Null, @errmsg varchar(255) output)
   as
   set nocount on
    
   declare @rcode int, @opencosttype int, @phasegroup bGroup, @phase bPhase, @costtype bJCCType, @um bUM, @jcchum bUM
    
   select @rcode=0, @opencosttype=0
   
   
   -- -- -- create cursor on bPMWD to check cost type UM
   declare costtype_cursor cursor LOCAL FAST_FORWARD
   for select PhaseGroup, Phase, CostType, UM
   from bPMWD where PMCo=@pmco and ImportId=@importid
    
   open costtype_cursor
   set @opencosttype=1
    
   costtype_cursor_loop:   --loop through all costtypes for this importid
   fetch next from costtype_cursor into @phasegroup, @phase, @costtype, @um
   
   if @@fetch_status <> 0 goto costtype_cursor_end
   
   -- -- -- get JCCH.UM
   select @jcchum = UM 
   from bJCCH where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup 
   and Phase= @phase and CostType=@costtype
   -- -- -- if record does not exist move to next
   if @@rowcount = 0 goto costtype_cursor_loop
   -- -- -- if UM are same move to next
   if @jcchum = @um goto costtype_cursor_loop
   
   -- -- -- check JCCD for source not = 'OE' and UM is different
   -- -- -- if found then skip, the import will only update hours and costs
   if exists (select * from bJCCD where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup
   				and Phase=@phase and CostType=@costtype and UM<>@um and JCTransType<>'OE')
   		goto costtype_cursor_loop
   
   
   -- -- -- check import phase cost type um to JCCH.um for differences
   -- -- -- if found, look for committed dollars in bJCCP. Do not allow
   -- -- -- upload if committed dollars exist and um change.
   if exists(select 1 from bJCCP where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup 
    			and Phase=@phase and CostType=@costtype and (TotalCmtdCost <> 0 or RemainCmtdCost <> 0))
    	begin
    	select @errmsg = 'Cannot change UM for Phase: ' + isnull(@phase,'') + ' CostType: ' + isnull(convert(varchar(3),@costtype),'') +
   					 + '. Committed dollars exist in JCCP!', @rcode = 1
   	goto bspexit
    	end
   
   
   
   goto costtype_cursor_loop
   
   
   costtype_cursor_end:
   -- close and deallocate cursor
   if @opencosttype = 1
   	begin
   	close costtype_cursor
   	deallocate costtype_cursor
   	set @opencosttype = 0
   	end
    
    
   
    
   
   
   bspexit:
   if @opencosttype = 1
   	begin
   	close costtype_cursor
   	deallocate costtype_cursor
   	set @opencosttype = 0
   	end
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMImportUploadCheck] TO [public]
GO
