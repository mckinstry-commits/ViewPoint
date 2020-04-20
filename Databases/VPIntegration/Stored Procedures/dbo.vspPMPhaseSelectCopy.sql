SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************/
CREATE procedure [dbo].[vspPMPhaseSelectCopy]
  /************************************************************************
  * Created By:	GF 08/02/2002
  * Modified By:	GF 06/10/2003 - issue #21465 - add subcontract detail when inserting phases.
  *				GF 05/24/2004 - issue #24664 - bump up @phaselist to varchar(8000). Added 3 more phase list variables
  *								to pass more phases that can be copied.
  *				GF 06/15/2006 - issue #120336 - Use JCPM.ProjMinPct when not zero else zero when
  *								inserting JCJP records.
  *				GF 10/29/2007 - issue #126004 - sometimes not adding all cost types. problem in exists check for JCCH.
  *				GF 07/25/2009 - issue #129667 material cost types.
  *
  *
  *
  * Purpose of Stored Procedure
  *    Copy a set of phases w/cost types from JCPM-JCPC to the selected project.
  *
  *
  *
  * Notes about Stored Procedure
  *
  *
  * returns 0 if successfull
  * returns 1 and error msg if failed
  *
  *************************************************************************/
(@pmco bCompany, @project bJob, @phasegroup bGroup, @phaselist varchar(8000), @phaselist1 varchar(8000), 
 @phaselist2 varchar(8000), @phaselist3 varchar(8000), @msg varchar(250) output)
as
set nocount on

declare @rcode int, @char char(1), @phase bPhase, @complete int, @seq int, @commapos int,
  		@phaselistcommapos int, @retstring varchar(8000), @retstringlist varchar(8000),
  		@contract bContract, @item bContractItem, @projminpct bPct, @um bUM,
  		@slcosttype bJCCType, @slcosttype2 bJCCType, @phasecount int, @jcpm_projminpct bPct,
  		@matlcosttype bJCCType, @matlcosttype2 bJCCType

select @rcode = 0, @phasecount = 0

if @pmco is null
	begin
	select @msg = 'Missing PM Company', @rcode = 1
	goto bspexit
	end

if @project is null
	begin
	select @msg = 'Missing PM Project', @rcode = 1
	goto bspexit
	end

if @phasegroup is null
	begin
	select @msg = 'Missing phase group', @rcode = 1
	goto bspexit
	end

------ get subcontract cost type from PMCO
select @slcosttype=SLCostType, @slcosttype2=SLCostType2,
		@matlcosttype=MtlCostType, @matlcosttype2=MatlCostType2
from dbo.PMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0
	begin
  	select @msg = 'Invalid PM Company', @rcode = 1
  	goto bspexit
  	end

------ get JCJM info
select @contract=Contract, @projminpct=ProjMinPct
from dbo.JCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount = 0
	begin
	select @msg = 'Invalid PM Project', @rcode = 1
	goto bspexit
	end

------ get first item from JCCI
select @item=min(Item) from dbo.JCCI with (nolock) where JCCo=@pmco and Contract=@contract
if isnull(@item,'') = ''
	begin
  	select @msg = 'Missing contract item for contract: ' + isnull(@contract,'') + '. Need at least one item.', @rcode = 1
  	goto bspexit
  	end


/***********************************************************/
-- -- -- now copy phases do each phase list separately 
/***********************************************************/
------ now do @phaselist1
if isnull(@phaselist1,'') = ''
  	set @complete = 1
else
  	set @complete = 0
  
while @complete = 0
BEGIN
  	------ get phase code
  	select @char = ','
  	exec dbo.bspParseString @phaselist1, @char, @commapos output, @retstring output, @retstringlist output, @msg output
  	select @phase = @retstring
  	select @phaselist1 = @retstringlist
  	select @phaselistcommapos = @commapos
  
  	if isnull(@phase,'') <> ''
  		begin
  	    ------ insert phase into JCCH for project
  		if not exists(select top 1 1 from dbo.JCJP with (nolock) where JCCo=@pmco and Job=@project and Phase=@phase)
  			begin
  			insert into JCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN)
  			select @pmco, @project, @phasegroup, @phase, b.Description, @contract, @item, isnull(b.ProjMinPct,0), 'Y'
  			from dbo.JCPM b with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
  			if @@rowcount <> 1
  				begin
  				select @msg = 'Phase: ' + @phase + ' could not be added to JCJP for project.', @rcode=1
  				goto bspexit
  				end
  			select @phasecount = @phasecount + 1

  			------ insert cost types from JCPC for phase into JCCH for project
  			insert into JCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, SourceStatus)
  			select @pmco, @project, @phasegroup, @phase, c.CostType, c.UM, c.BillFlag, c.ItemUnitFlag, c.PhaseUnitFlag, 'Y'
  			from dbo.JCPC c with (nolock) where c.PhaseGroup=@phasegroup and c.Phase=@phase
  			and not exists (select top 1 1 from dbo.JCCH j with (nolock) where j.JCCo=@pmco and j.Job=@project
							and j.Phase=@phase and j.CostType=c.CostType)
			and exists(select * from dbo.HQUM u with (nolock) where u.UM=c.UM)
  
  			------ if subcontract cost type created based on PMCo, then create PMSL cost types
  			if isnull(@slcosttype,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@slcosttype
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @slcosttype, 0, @um, 0, 0, @msg OUTPUT
  					end
  				end
  
  			---- if subcontract cost type 2 created based on PMCo, then create PMSL cost types
  			if isnull(@slcosttype2,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@slcosttype2
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @slcosttype2, 0, @um, 0, 0, @msg OUTPUT
  					end
  				end
  				
  			---- if material cost type created based on PMCo, then create PMMF cost types
  			if isnull(@matlcosttype,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@matlcosttype
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @matlcosttype, 0, @um, 0, 0, @msg OUTPUT
  					END
  				end
  
  			---- if material cost type 2 created based on PMCo, then create PMMF cost types
  			if isnull(@matlcosttype2,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@matlcosttype2
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @matlcosttype2, 0, @um, 0, 0, @msg OUTPUT
  					end
  				end
  			end
  		end
  
      if @phaselistcommapos = 0 select @complete = 1
END


-- -- -- now do @phaselist2
if isnull(@phaselist2,'') = ''
	set @complete = 1
else
  	set @complete = 0

while @complete = 0
BEGIN
  	--get phase code
  	select @char = ','
  	exec dbo.bspParseString @phaselist2, @char, @commapos output, @retstring output, @retstringlist output, @msg output
  	select @phase = @retstring
  	select @phaselist2 = @retstringlist
  	select @phaselistcommapos = @commapos
  
  	if isnull(@phase,'') <> ''
  		begin
  	    ------ insert phase into JCCH for project
  		if not exists(select top 1 1 from dbo.JCJP with (nolock) where JCCo=@pmco and Job=@project and Phase=@phase)
  			begin
  			insert into JCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN)
  			select @pmco, @project, @phasegroup, @phase, b.Description, @contract, @item, isnull(b.ProjMinPct,0), 'Y'
  			from dbo.JCPM b with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
  			if @@rowcount <> 1
  				begin
  				select @msg = 'Phase: ' + @phase + ' could not be added to JCJP for project.', @rcode=1
  				goto bspexit
  				end

			select @phasecount = @phasecount + 1
  			------ insert cost types from JCPC for phase into JCCH for project
  			insert into JCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, SourceStatus)
  			select @pmco, @project, @phasegroup, @phase, c.CostType, c.UM, c.BillFlag, c.ItemUnitFlag, c.PhaseUnitFlag, 'Y'
  			from dbo.JCPC c with (nolock) where c.PhaseGroup=@phasegroup and c.Phase=@phase
  			and not exists (select top 1 1 from dbo.JCCH j with (nolock) where j.JCCo=@pmco and j.Job=@project
							and j.Phase=@phase and j.CostType=c.CostType)
			and exists(select * from dbo.HQUM u with (nolock) where u.UM=c.UM)

  			---- if subcontract cost type created based on PMCo, then create PMSL cost types
  			if isnull(@slcosttype,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@slcosttype
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @slcosttype, 0, @um, 0, 0, @msg output
  					end
  				end
  
  			---- if subcontract cost type 2 created based on PMCo, then create PMSL cost types
  			if isnull(@slcosttype2,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@slcosttype2
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @slcosttype2, 0, @um, 0, 0, @msg output
  					end
  				end
  				
  			---- if material cost type created based on PMCo, then create PMMF cost types
  			if isnull(@slcosttype,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@matlcosttype
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @matlcosttype, 0, @um, 0, 0, @msg output
  					end
  				end
  
  			---- if material cost type created based on PMCo, then create PMMF cost types
  			if isnull(@matlcosttype,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@matlcosttype
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @matlcosttype, 0, @um, 0, 0, @msg OUTPUT
  					END
  				end
  
  			---- if material cost type 2 created based on PMCo, then create PMMF cost types
  			if isnull(@matlcosttype2,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@matlcosttype2
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @matlcosttype2, 0, @um, 0, 0, @msg OUTPUT
  					end
  				end
  			end
  		end
  
      if @phaselistcommapos = 0 select @complete = 1
END



------ now do @phaselist3
if isnull(@phaselist3,'') = ''
  	set @complete = 1
else
  	set @complete = 0


while @complete = 0
BEGIN
  	------ get phase code
  	select @char = ','
  	exec dbo.bspParseString @phaselist3, @char, @commapos output, @retstring output, @retstringlist output, @msg output
  	select @phase = @retstring
  	select @phaselist3 = @retstringlist
  	select @phaselistcommapos = @commapos
  
  	if isnull(@phase,'') <> ''
  		begin
  	    ---- insert phase into JCCH for project
  		if not exists(select top 1 1 from JCJP with (nolock) where JCCo=@pmco and Job=@project and Phase=@phase)
  			begin
  			insert into JCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN)
  			select @pmco, @project, @phasegroup, @phase, b.Description, @contract, @item, isnull(b.ProjMinPct,0), 'Y'
  			from dbo.JCPM b with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
  			if @@rowcount <> 1
  				begin
  				select @msg = 'Phase: ' + @phase + ' could not be added to JCJP for project.', @rcode=1
  				goto bspexit
  				end

			select @phasecount = @phasecount + 1
  			------ insert cost types from JCPC for phase into JCCH for project
  			insert into JCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, SourceStatus)
  			select @pmco, @project, @phasegroup, @phase, c.CostType, c.UM, c.BillFlag, c.ItemUnitFlag, c.PhaseUnitFlag, 'Y'
  			from dbo.JCPC c with (nolock) where c.PhaseGroup=@phasegroup and c.Phase=@phase
  			and not exists (select top 1 1 from dbo.JCCH j with (nolock) where j.JCCo=@pmco and j.Job=@project
							and j.Phase=@phase and j.CostType=c.CostType)
			and exists(select * from dbo.HQUM u with (nolock) where u.UM=c.UM)

  			---- if subcontract cost type created based on PMCo, then create PMSL cost types
  			if isnull(@slcosttype,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@slcosttype
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @slcosttype, 0, @um, 0, 0, @msg output
  					end
  				end
  
  			---- if subcontract cost type 2 created based on PMCo, then create PMSL cost types
  			if isnull(@slcosttype2,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@slcosttype2
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @slcosttype2, 0, @um, 0, 0, @msg output
  					end
  				end
  				
  			---- if material cost type created based on PMCo, then create PMMF cost types
  			if isnull(@matlcosttype,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@matlcosttype
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @matlcosttype, 0, @um, 0, 0, @msg OUTPUT
  					END
  				end
  
  			---- if material cost type 2 created based on PMCo, then create PMMF cost types
  			if isnull(@matlcosttype2,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@matlcosttype2
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @matlcosttype2, 0, @um, 0, 0, @msg OUTPUT
  					end
  				end
  			end
  		end
  
      if @phaselistcommapos = 0 select @complete = 1
END




------ now do @phaselist
if isnull(@phaselist,'') = ''
	begin
	select @complete = 1
	end
else
	begin
	select @complete = 0
	end


while @complete = 0
BEGIN
  	---- get phase code
  	select @char = ','
  
  	exec dbo.bspParseString @phaselist, @char, @commapos output, @retstring output, @retstringlist output, @msg output
  
  	select @phase = @retstring
  	select @phaselist = @retstringlist
  	select @phaselistcommapos = @commapos
  
  	if isnull(@phase,'') <> ''
  		begin
  	    ---- insert phase into JCCH for project
  		if not exists(select top 1 1 from JCJP with (nolock) where JCCo=@pmco and Job=@project and Phase=@phase)
  			begin
  			insert into JCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN)
  			select @pmco, @project, @phasegroup, @phase, b.Description, @contract, @item, isnull(b.ProjMinPct,0), 'Y'
  			from JCPM b with (nolock) where PhaseGroup=@phasegroup and Phase=@phase
  			if @@rowcount = 0
  				begin
  				select @msg = 'Phase: ' + @phase + ' could not be added to JCJP for project.', @rcode=1
  				goto bspexit
  				end

			select @phasecount = @phasecount + 1
  			---- insert cost types from JCPC for phase into JCCH for project
  			insert into JCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, SourceStatus)
  			select @pmco, @project, @phasegroup, @phase, c.CostType, c.UM, c.BillFlag, c.ItemUnitFlag, c.PhaseUnitFlag, 'Y'
  			from JCPC c with (nolock) where c.PhaseGroup=@phasegroup and c.Phase=@phase
  			and not exists (select JCCo from JCCH j with (nolock) where j.JCCo=@pmco and j.Job=@project
							and j.Phase=@phase and j.CostType=c.CostType)
			and exists(select * from HQUM u with (nolock) where u.UM=c.UM)
  
  			---- if subcontract cost type created based on PMCo, then create PMSL cost types
  			if isnull(@slcosttype,'') <> ''
  				begin
  				select @um=UM from JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@slcosttype
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @slcosttype, 0, @um, 0, 0, @msg output
  					end
  				end
  
  			------ if subcontract cost type 2 created based on PMCo, then create PMSL cost types
  			if isnull(@slcosttype2,'') <> ''
  				begin
  				select @um=UM from JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@slcosttype2
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @slcosttype2, 0, @um, 0, 0, @msg output
  					end
  				END
  				
  			  			---- if material cost type created based on PMCo, then create PMMF cost types
  			if isnull(@matlcosttype,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@matlcosttype
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @matlcosttype, 0, @um, 0, 0, @msg OUTPUT
  					END
  				end
  
  			---- if material cost type 2 created based on PMCo, then create PMMF cost types
  			if isnull(@matlcosttype2,'') <> ''
  				begin
  				select @um=UM from dbo.JCCH with (nolock) 
  				where JCCo=@pmco and Job=@project and Phase=@phase and CostType=@matlcosttype2
  				if @@rowcount <> 0
  					begin
  					exec @rcode = dbo.bspPMSubOrMatlOrigAdd @pmco, @project, @phasegroup, @phase, @matlcosttype2, 0, @um, 0, 0, @msg OUTPUT
  					end
  				end
  			end
  		end
  
      if @phaselistcommapos = 0 select @complete = 1
END







bspexit:
	if @rcode = 0 
		select @msg = 'Phases copied: ' + convert(varchar(8),@phasecount) + '.'
	else
		select @msg = isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPhaseSelectCopy] TO [public]
GO
