SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPCOTotalZeroOut  ******/
CREATE proc [dbo].[bspPMPCOTotalZeroOut]
/***********************************************************
* Created By:	GF 09/10/2004
* Modified By:	GF 02/29/2008 - issue #127195 #127210 changed to use vspPMOACalcs
*
*
* USAGE: Called from PMPCOTotalZeroOut form to zero-out add-ons for project, PCO, PCO Item.
*	The zero out type will define at what level to zero out add-ons for. These types are:
*	(P)roject - at the project level
*	(C)hange Order - at the change order level
*	(I)Item - at the item level
*
*	Pending only add-ons will be zeroed out. If the PCO item is approved, then the add-ons are
*	not touched.
*
* INPUT PARAMETERS
*	PMCo
*	Project
*	PCOType
*	PCO
*	PCOItem
*	ZeroOutType
*
*
* RETURN VALUE
*   returns 0 if successful, 1 if failure
*****************************************************/
  (@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO, 
   @pcoitem bPCOItem, @zeroouttype varchar(1), @msg varchar(255) output)
  as
  set nocount on
  
  declare @rcode int, @retcode int, @opencursor int, @pmoa_pcotype bDocType, @pmoa_pco bPCO,
  		@pmoa_pcoitem bPCOItem, @pmoa_addon int, @lastpcotype bDocType, 
  		@lastpco bPCO, @lastpcoitem bPCOItem, @addon_count int
  
  select @rcode = 0, @opencursor = 0, @addon_count = 0
  
  -- -- -- declare cursor on bPMOA using @zeroouttype
  if @zeroouttype = 'P'
  BEGIN
  	-- create a cursor to process pending change order item add-ons not approved at project level
  	declare bcPMOA cursor LOCAL FAST_FORWARD for select a.PCOType, a.PCO, a.PCOItem, a.AddOn
  	from bPMOA a 
  	join bPMOI i on i.PMCo=a.PMCo and i.Project=a.Project and i.PCOType=a.PCOType and i.PCO=a.PCO and i.PCOItem=a.PCOItem
  	where i.PMCo=@pmco and i.Project=@project and isnull(i.ACO,'') = ''
  	Group By a.PCOType, a.PCO, a.PCOItem, a.AddOn
  END
  
  if @zeroouttype = 'C'
  BEGIN
  	-- create a cursor to process pending change order item add-ons not approved at change order level
  	declare bcPMOA cursor LOCAL FAST_FORWARD for select a.PCOType, a.PCO, a.PCOItem, a.AddOn
  	from bPMOA a
  	join bPMOI i on i.PMCo=a.PMCo and i.Project=a.Project and i.PCOType=a.PCOType and i.PCO=a.PCO and i.PCOItem=a.PCOItem
  	where i.PMCo=@pmco and i.Project=@project and i.PCOType=@pcotype and i.PCO=@pco and isnull(i.ACO,'') = ''
  	Group By a.PCOType, a.PCO, a.PCOItem, a.AddOn
  END
  
  if @zeroouttype = 'I'
  BEGIN
  	-- create a cursor to process pending change order item add-ons not approved at change order level
  	declare bcPMOA cursor LOCAL FAST_FORWARD for select a.PCOType, a.PCO, a.PCOItem, a.AddOn
  	from bPMOA a
  	join bPMOI i on i.PMCo=a.PMCo and i.Project=a.Project and i.PCOType=a.PCOType and i.PCO=a.PCO and i.PCOItem=a.PCOItem
  	where i.PMCo=@pmco and i.Project=@project and i.PCOType=@pcotype and i.PCO=@pco and i.PCOItem=@pcoitem and isnull(i.ACO,'') = ''
  	Group By a.PCOType, a.PCO, a.PCOItem, a.AddOn
  END
  
  -- open cursor
  open bcPMOA
  set @opencursor = 1
  select @lastpcotype = null, @lastpco = null, @lastpcoitem = null
  
  -- loop through all materials in bcPMMF_RQ cursor
  PMOA_loop:
  fetch next from bcPMOA into @pmoa_pcotype, @pmoa_pco, @pmoa_pcoitem, @pmoa_addon
  
  if @@fetch_status <> 0 goto PMOA_end
  
  -- -- -- update bPMOA zeroing out the add-on
  update bPMOA set AddOnPercent = 0, AddOnAmount = 0
  where PMCo=@pmco and Project=@project and PCOType=@pmoa_pcotype
  and PCO=@pmoa_pco and PCOItem=@pmoa_pcoitem and AddOn=@pmoa_addon
  if @@rowcount = 0 goto PMOA_loop
  
  -- -- -- if last values have not been set, set and go to loop
  if @lastpcotype is null
  	begin
  	select @lastpcotype = @pmoa_pcotype, @lastpco = @pmoa_pco, @lastpcoitem = @pmoa_pcoitem
  	select @addon_count = @addon_count + 1
  	goto PMOA_loop
  	end
  
  -- -- -- if all current values = last values goto next PCO item
  if @lastpcotype = @pmoa_pcotype and @lastpco = @pmoa_pco and @lastpcoitem = @pmoa_pcoitem
  	begin
  	select @addon_count = @addon_count + 1
  	goto PMOA_loop
  	end
  
  -- -- -- current vs last values are different - run PCO item totals recalculate for last values
  exec @retcode = dbo.vspPMOACalcs @pmco, @project, @lastpcotype, @lastpco, @lastpcoitem

  -- -- -- set last = current
  select @lastpcotype = @pmoa_pcotype, @lastpco = @pmoa_pco, @lastpcoitem = @pmoa_pcoitem
  select @addon_count = @addon_count + 1
  goto PMOA_loop
  
  
  
  PMOA_end:
  	-- -- -- recalulate last pco item totals and close cursor
  	if @opencursor = 1
  		begin
  		if @lastpcotype is not null
  			begin
  			exec @retcode = dbo.vspPMOACalcs @pmco, @project, @lastpcotype, @lastpco, @lastpcoitem
  			end
  		-- -- -- close cursor
  		close bcPMOA
  		deallocate bcPMOA
  		set @opencursor = 0
  		end
  
  bspexit:
  	if @opencursor = 1
  		begin
  		close bcPMOA
  		deallocate bcPMOA
  		set @opencursor = 0
  		end
  
  	if @rcode <> 0
  		begin
  		select @msg = isnull(@msg,'')
  		end
  	else
  		begin
  		select @msg = 'Number of pending change order item add-ons set to zero: ' + convert(varchar(8), @addon_count) + ' !'
  		end
  
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOTotalZeroOut] TO [public]
GO
