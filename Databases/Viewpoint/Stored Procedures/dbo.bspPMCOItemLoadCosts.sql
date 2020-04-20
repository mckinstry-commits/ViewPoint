SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE   proc [dbo].[bspPMCOItemLoadCosts]
/***********************************************************
 * Created By:	GF 12/24/2003
 * Modified By:	GF 07/21/2004 - issue #25184 - separate cursor by PCO or ACO and update statement.
 *				GF 08/30/2004 - issue #25402 - for ACO, only load actual costs w/interface date is null.
 *				GF 03/01/2005 - issue #27222 - if PMOL.UM = 'LS' and no actual units then set to PMOL.EstUnits
 *				GF 01/06/2006 - issue #28845 - added error message for ACO item load costs to check if all PMOL records interfaced.
*				GF 02/29/2008 - issue #127195 #127210 changed to use vspPMOACalcs
 *
 *
 * USAGE:
 * Loads actual costs into PMOL for a specified PCO or ACO item
 * using a range of months and dates passed in from PM Load Costs form.
 *
 * INPUT PARAMETERS
 * PMCO				- JC Company
 * PROJECT			- Project
 * PCOType			- PCO type
 * PCO				- Pending Change Order
 * ACO				- Approved Change Order
 * Contract			- JC Contract
 * Contract Item	- JC Contract item
 * PCOItem			- PCO Item
 * ACOItem			- Approved Change Order Item
 * Begin Month		- Beginning Month
 * End Month		- Ending Month
 * Begin Date		- Beginning Date
 * End Date			- Ending Date
 * Replace Values	- Replace existing values
 *
 *
 * OUTPUT PARAMETERS
 *   @msg - error message if error occurs
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@pmco bCompany = null, @project bJob = null, @pcotype bDocType = null, @pco bPCO = null, 
 @aco bACO = null,  @pcoitem bPCOItem = null, @acoitem bPCOItem = null, @beg_month bMonth = null, 
 @end_month bMonth = null, @beg_date bDate = null, @end_date bDate = null, @replace_values bYN = 'N', 
 @msg varchar(255) output)
as
set nocount on
    
   declare @rcode int, @retcode int, @opencursor tinyint, @errmsg varchar(255), @costs_loaded int,
    		@phasegroup bGroup, @phase bPhase, @costtype bJCCType, @estunits bUnits, @pmol_um bUM, 
    		@esthours bHrs, @ecm bECM, @estcost bDollar, @jccd_um bUM, @actualhours bHrs,
    		@actualunits bUnits, @actualcosts bDollar, @unithours bHrs, @hourcost bUnitCost, 
    		@unitcost bUnitCost
    
   select @rcode = 0, @retcode = 0, @opencursor = 0, @costs_loaded = 0
    
   if @pmco is null
    	begin
    	select @msg = 'Missing PM Company!', @rcode = 1
    	goto bspexit
    	end
    
   if @project is null
    	begin
    	select @msg = 'Missing Project!', @rcode = 1
    	goto bspexit
    	end
    
   if @pcotype is null
    	begin
    	select @pcoitem = null, @pco = null
    	-- check ACO
    	if @aco is null
    		begin
    		select @msg = 'Missing ACO!', @rcode = 1
    		goto bspexit
    		end
    	if @acoitem is null
    		begin
    		select @msg = 'Missing ACO Item!', @rcode = 1
    		goto bspexit
    		end
    	end
   else
    	begin
    	select @acoitem = null, @aco = null
    	-- check PCO
    	if @pco is null
    		begin
    		select @msg = 'Missing PCO!', @rcode = 1
    		goto bspexit
    		end
    	if @pcoitem is null
    		begin
    		select @msg = 'Missing PCO Item!', @rcode = 1
    		goto bspexit
    		end
    	end
    
-- -- -- check for loading costs into ACO Item to verify that the PMOL records have not been interfaced.
if @pcotype is null
	begin
	if not exists(select top 1 1 from bPMOL with (nolock) where PMCo=@pmco and Project=@project
				and ACO = @aco and ACOItem = @acoitem and InterfacedDate is null)
		begin
		select @msg = 'Cannot load costs, all ACO item phase cost type records have been interfaced.', @rcode = 1
		goto bspexit
		end
	end





   -- -- -- declare cursor on PMOL for PCO/ACO item to get and load units, hours, costs from JCCD
   if isnull(@pco,'') <> ''
   	begin
   	declare bcPMOL cursor LOCAL FAST_FORWARD
   	for select PhaseGroup, Phase, CostType, EstUnits, UM, EstHours, ECM, EstCost
   	from bPMOL where PMCo=@pmco and Project=@project and isnull(PCOType,'') = isnull(@pcotype,'')
   	and PCO = @pco and PCOItem = @pcoitem
   	end
   else
   	begin
   	declare bcPMOL cursor LOCAL FAST_FORWARD
   	for select PhaseGroup, Phase, CostType, EstUnits, UM, EstHours, ECM, EstCost
   	from bPMOL where PMCo=@pmco and Project=@project and ACO = @aco and ACOItem = @acoitem
   	and InterfacedDate is null
   	end
   
   -- open cursor
   open bcPMOL
   set @opencursor = 1
      
    PMOL_loop:
    fetch next from bcPMOL into @phasegroup, @phase, @costtype, @estunits, @pmol_um, @esthours, @ecm, @estcost
      
    if @@fetch_status <> 0 goto PMOL_end
    
    select @actualhours = 0, @actualcosts = 0, @actualunits = 0
    
    -- get sum actual hours, and costs from JCCD in month and date range
    select  @actualhours = sum(ActualHours), 
    		 @actualcosts = sum(ActualCost),
    		 @actualunits = sum(ActualUnits)
    from bJCCD where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
    and CostType=@costtype and Mth >= isnull(@beg_month,Mth) and Mth <= isnull(@end_month,Mth)
    and ActualDate >= isnull(@beg_date,ActualDate) and ActualDate <= isnull(@end_date,ActualDate)
    
    -- get sum actual units from JCCD in month and date range and UM equals @pmol_um
    select @actualunits = sum(ActualUnits)
    from bJCCD where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
    and CostType=@costtype and UM=@pmol_um
    and Mth >= isnull(@beg_month,Mth) and Mth <= isnull(@end_month,Mth)
    and ActualDate >= isnull(@beg_date,ActualDate) and ActualDate <= isnull(@end_date,ActualDate)
    if @actualunits is null set @actualunits = 0
    if @actualhours is null set @actualhours = 0
    if @actualcosts is null set @actualcosts = 0
    
    
    -- if no actual units, hours, costs, skip
    if @actualhours = 0 and @actualunits = 0 and @actualcosts = 0 goto PMOL_loop
    
    -- if not replacing values and estimates exist in PMOL, skip
    if @replace_values = 'N' and (@estunits <> 0 or @esthours <> 0 or @estcost <> 0) goto PMOL_loop
    
    if @pmol_um = 'LS' select @actualunits = @estunits
    
    -- calculate unithours, unitcost, and hourcost
    select @unitcost = 0, @unithours = 0, @hourcost = 0
    if @actualunits <> 0 select @unitcost = (@actualcosts/@actualunits)
    if @actualunits <> 0 select @unithours = (@actualhours/@actualunits)
    if @actualhours <> 0 select @hourcost = (@actualcosts/@actualhours)
    if @unitcost is null set @unitcost = 0
    if @unithours is null set @unithours = 0
    if @hourcost is null set @hourcost = 0
    
    -- update PMOL with actual values
   if isnull(@pco,'') <> ''
   	begin
   	update bPMOL set EstUnits = @actualunits, EstHours = @actualhours, EstCost = @actualcosts,
   	 				 UnitHours = @unithours, HourCost = @hourcost, UnitCost = @unitcost
   	where PMCo=@pmco and Project=@project and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
   	and isnull(PCOType,'') = isnull(@pcotype,'') and PCO = @pco and PCOItem = @pcoitem
   -- -- -- 	and isnull(ACO,'') = isnull(@aco,'') and isnull(ACOItem,'') = isnull(@acoitem,'')
   	 if @@rowcount = 0
   	 	begin
   	 	select @msg = 'Unable to update actual values to Phase: ' + isnull(@phase,'') + ' and CostType: ' + isnull(convert(varchar(3),@costtype),'') + '.', @rcode = 1
   	 	goto PMOL_Done
   	 	end
   	end
   else
   	begin
   	update bPMOL set EstUnits = @actualunits, EstHours = @actualhours, EstCost = @actualcosts,
   	 				 UnitHours = @unithours, HourCost = @hourcost, UnitCost = @unitcost
   	where PMCo=@pmco and Project=@project and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
   	and ACO = @aco and ACOItem = @acoitem
   	 if @@rowcount = 0
   	 	begin
   	 	select @msg = 'Unable to update actual values to Phase: ' + isnull(@phase,'') + ' and CostType: ' + isnull(convert(varchar(3),@costtype),'') + '.', @rcode = 1
   	 	goto PMOL_Done
   	 	end
   	end
    
    select @costs_loaded = @costs_loaded + 1
    goto PMOL_loop
    
    
    PMOL_end:
    	close bcPMOL
    	deallocate bcPMOL
    	set @opencursor = 0
    
    
    PMOL_Done:
    	-- deallocate cursor
    	if @opencursor = 1
    		begin
    		close bcPMOL
    		deallocate bcPMOL
    		set @opencursor = 0
    		end
   
   
   -- even if error occured during process, if some costs were loaded and a PCO calculate addons
   if @costs_loaded > 0 and @pcotype is not null
    	begin
    	-- calculate pending amount, addons, markups
    	exec @retcode = dbo.vspPMOACalcs @pmco, @project, @pcotype, @pco, @pcoitem
    	end
   
   
   
   
   
   
   bspexit:
    	if @rcode = 0 select @msg = 'Number of Phase Cost Type records loaded with actual costs: ' + convert(varchar(6),@costs_loaded)
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMCOItemLoadCosts] TO [public]
GO
