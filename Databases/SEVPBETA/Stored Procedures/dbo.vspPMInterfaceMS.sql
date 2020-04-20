SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************/
CREATE    proc [dbo].[vspPMInterfaceMS]
/*************************************
* Created By:	GF 05/23/2011 TK-05347 rw-write for 6.4.0 interface
* Modified By:
*
*
*
* USAGE:
* used by PMInterface to validate material quotes from PM to MS as specified.
* this SP will validate only or validate and interface to MS depending on Validate flag.
* MS does not have change orders. So the change order piece is part of this SP's instead
* of a separate SP. Also remember there is no batch process for MS Quotes. Will use bPMBE
* for MS quote errors.
*
* Pass in :
* PMCo, Project, Mth, Validate flag, MSCo, Quote
*
*
* Returns
*	Error message and return code
*
*******************************/
(@PMCo bCompany, @Project bJob, @Mth bMonth, @Validate bYN, 
 @MSCo bCompany = NULL, @Quote VARCHAR(10) = NULL,
 @msbatchid int output, @errmsg varchar(255) output)
AS
SET NOCOUNT ON
   
declare @rcode int, @pmmfseq int, @opencursor tinyint, @validcnt int, @errorcount int,
		@reqdate bDate, @matlgroup bGroup, @material bMatl, @um bUM, @location bLoc,
		@units bUnits, @unitcost bUnitCost, @ecm bECM, @errtext varchar(255),
		@msqdnotes varchar(max), @pmmfnotes varchar(max),
		@Quotetype char(1), @jcco bCompany, @job bJob, @msqderr varchar(100), @fromloc bLoc,
		@msqdmatl bMatl, @msqdum bUM, @msqdquoteunits bUnits, @msqdstatus tinyint, 
		@msqdorderunits bUnits, @pmbeseq int, @msqd_seq int, @phase bPhase, @phasegroup bGroup,
		@msqd_price bUnitCost, @pmmf_price bUnitCost, @price_change bYN,
		@PMMF_KeyID BIGINT, @DatePosted bDate
   
select @rcode = 0, @errorcount = 0, @opencursor = 0, @msbatchid = -1
   
if isnull(@PMCo,0) = 0 or isnull(@Project,'') = '' or isnull(@Mth,'') = ''
    begin
    select @errmsg = 'Missing MS information!', @rcode = 1
    goto bspexit
    end
   
---- check for date posted
if isnull(@Validate,'Y') = 'N' AND @DatePosted IS NULL SET @DatePosted = dbo.vfDateOnly()
   --if isnull(@Validate,'Y') = 'N' and @DatePosted is null
   --	begin
   --	select @errmsg = 'Missing Posting Date!', @rcode = 1
   --	goto bspexit
   --	end
   
   -- check for data to interface for originals, if no found then exit
   --if isnull(@aco,'') = ''
   --	begin
if not exists (select top 1 1 from bPMMF a with (nolock) where a.PMCo=@PMCo AND a.Project=@Project
				AND a.SendFlag='Y' and a.MaterialOption='Q' 
				AND a.MSCo = @MSCo AND a.Quote = @Quote and a.InterfaceDate is null)
	BEGIN
    goto bspexit
    END
--end
--ELSE
---- check for data to interface for change orders, if no found then exit
--	begin
--	if not exists (select top 1 1 from bPMMF a with (nolock) where a.PMCo=@PMCo and a.Project=@Project and a.ACO=@aco
--		and a.RecordType='C' and a.SendFlag='Y' and a.MaterialOption='Q' and a.Quote is not null
--		and a.InterfaceDate is null)
--     	goto bspexit
--	end

-- set batch ID to zero - used by front-end to verify MS quote data to interface 0 yes, -1 no
set @msbatchid = 0
   
---- declare cursor on PMMF Material Detail for interface to MSQD
--if isnull(@aco,'') = ''
--	begin
declare bcPMMF cursor LOCAL FAST_FORWARD for select Seq, KeyID
from dbo.bPMMF
where PMCo=@PMCo 
	AND Project=@Project
	AND SendFlag='Y' 
	AND MaterialOption='Q'
	AND MSCo = @MSCo
	AND Quote =@Quote
	AND InterfaceDate is null
Group By Seq, KeyID
 
-- open cursor
open bcPMMF
set @opencursor = 1

PMMF_loop:
fetch next from bcPMMF into @pmmfseq, @PMMF_KeyID

if @@fetch_status <> 0 goto PMMF_end
   
-- get PMMF information
select  @MSCo=MSCo, @Quote=Quote, @matlgroup=MaterialGroup, @material=MaterialCode,
		@um=UM, @location=Location, @reqdate=ReqDate, @units=isnull(Units,0),
		@unitcost=isnull(UnitCost,0), @ecm=ECM, @pmmfnotes=Notes, 
		@phasegroup=PhaseGroup, @phase=Phase
from dbo.bPMMF WHERE KeyID = @PMMF_KeyID
   
if isnull(@location,'') = '' goto PMMF_loop
   
select @msqderr = ' MSCo: ' + convert(varchar(3),@MSCo) + ' Quote: ' + isnull(@Quote,'') + ' Location: ' + isnull(@location,'') + ' Material: ' + isnull(@material,'') + ' UM: ' + isnull(@um,'')
-- validate quote in MSQH
select @Quotetype=QuoteType, @jcco=JCCo, @job=Job
from dbo.bMSQH WITH (NOLOCK) where MSCo=@MSCo and Quote=@Quote
if @@rowcount = 0
	BEGIN
	select @errtext = 'Missing from Quote Header.' + isnull(@msqderr,'')
	-- get PMBE sequence
	select @pmbeseq = isnull(max(Seq),0) + 1 from dbo.bPMBE where Co=@PMCo and Project=@Project and Mth=@Mth
	insert into dbo.bPMBE (Co, Project, Mth, Seq, ErrorText)
	select @PMCo, @Project, @Mth, @pmbeseq, @errtext
	select @errorcount = @errorcount + 1
	goto PMMF_loop
	end
   
if @Quotetype <> 'J'
	begin
	select @errtext = 'Invalid Quote, not a job type.' + isnull(@msqderr,'')
	-- get PMBE sequence
	select @pmbeseq = isnull(max(Seq),0) + 1 from dbo.bPMBE where Co=@PMCo and Project=@Project and Mth=@Mth
	insert into dbo.bPMBE (Co, Project, Mth, Seq, ErrorText)
	select @PMCo, @Project, @Mth, @pmbeseq, @errtext
	select @errorcount = @errorcount + 1
	goto PMMF_loop
	end
   
if @jcco <> @PMCo or @job <> @Project
	begin
	select @errtext = 'Invalid Quote, assigned to different JCCO/Job combination' + isnull(@msqderr,'')
	-- get PMBE sequence
	select @pmbeseq = isnull(max(Seq),0) + 1 from dbo.bPMBE where Co=@PMCo and Project=@Project and Mth=@Mth
	insert into dbo.bPMBE (Co, Project, Mth, Seq, ErrorText)
	select @PMCo, @Project, @Mth, @pmbeseq, @errtext
	select @errorcount = @errorcount + 1
	goto PMMF_loop
	end
   
-- check UM <> 'LS'
if @um = 'LS'
	begin
	select @errtext = 'Unit of measure must not be (LS).' + isnull(@msqderr,'')
	-- get PMBE sequence
	select @pmbeseq = isnull(max(Seq),0) + 1 from dbo.bPMBE where Co=@PMCo and Project=@Project and Mth=@Mth
	insert into dbo.bPMBE (Co, Project, Mth, Seq, ErrorText)
	select @PMCo, @Project, @Mth, @pmbeseq, @errtext
	select @errorcount = @errorcount + 1
	goto PMMF_loop
	end
   
-- validate quote detail record to MSQD
select @msqdstatus=Status
from dbo.bMSQD WITH (NOLOCK) 
where MSCo=@MSCo and Quote=@Quote and FromLoc=@location and Material=@material 
and UM=@um and PhaseGroup=@phasegroup and Phase=@phase
if @@rowcount = 1
	begin
	-- status must be 0-bid, 1-ordered
	if @msqdstatus = 2
		begin
		select @errtext = 'Quote detail status must not be 2-completed.' + isnull(@msqderr,'')
		-- get PMBE sequence
		select @pmbeseq = isnull(max(Seq),0) + 1 from dbo.bPMBE where Co=@PMCo and Project=@Project and Mth=@Mth
		insert into dbo.bPMBE (Co, Project, Mth, Seq, ErrorText)
		select @PMCo, @Project, @Mth, @pmbeseq, @errtext
		select @errorcount = @errorcount + 1
		goto PMMF_loop
		end
	end
ELSE
   	begin
   	-- check for quote detail record with no phase
   	select @msqdstatus=Status
   	from dbo.bMSQD WITH (NOLOCK) 
   	where MSCo=@MSCo and Quote=@Quote and FromLoc=@location and Material=@material 
   	and UM=@um and PhaseGroup=@phasegroup and Phase is null
   	if @@rowcount = 1
   		begin
   		-- status must be 0-bid, 1-ordered
   		if @msqdstatus = 2
   			begin
   			select @errtext = 'Quote detail status must not be 2-completed.' + isnull(@msqderr,'')
   			-- get PMBE sequence
   			select @pmbeseq = isnull(max(Seq),0) + 1 from dbo.bPMBE where Co=@PMCo and Project=@Project and Mth=@Mth
   			insert into dbo.bPMBE (Co, Project, Mth, Seq, ErrorText)
   			select @PMCo, @Project, @Mth, @pmbeseq, @errtext
   			select @errorcount = @errorcount + 1
   			goto PMMF_loop
   			end
   		end
   	end

-- if validateonly flag is 'Y' we are done for now.
if isnull(@Validate,'Y') = 'Y' goto PMMF_loop

-- now see if MSQD record for location, material, um, phase
SET @msqd_price = 0
SET @price_change = 'N'
SELECT @msqd_price = UnitPrice 
from dbo.bMSQD with (nolock)
where MSCo=@MSCo and Quote=@Quote and FromLoc=@location and Material=@material
and UM=@um and PhaseGroup=@phasegroup and Phase=@phase
if @@rowcount = 0 
	begin
	-- check MSQD by location, material, um
	select @msqd_price = UnitPrice
	from dbo.bMSQD with (nolock)
	where MSCo=@MSCo and Quote=@Quote and FromLoc=@location and Material=@material
	and UM=@um and Phase is null
	end

---- now check PMMF if the unit price is different for the location, material, um, and all phases
if exists(select UnitCost from dbo.bPMMF with (nolock) where PMCo=@PMCo and Project=@Project 
			and MaterialOption='Q' and SendFlag='Y' and MSCo=@MSCo and Quote=@Quote
			and Location=@location and MaterialCode=@material and UM=@um
			and UnitCost <> @unitcost)
	BEGIN
	SET @price_change = 'Y'
	END
ELSE
	BEGIN
	SET @price_change = 'N'
	END
   
-- if price change flag is 'N' and MSQD.UnitPrice was found 
-- and PMMF.UnitCost<>MSQD.UnitPrice then price change = 'Y'
if @price_change = 'N' and @msqd_price <> 0 and @msqd_price <> @unitcost set @price_change = 'Y'

-- if @price_change = 'Y' then add MSQD record with phase if possible
if @price_change = 'Y'
	begin
	-- insert or update MSQD with PMMF information
	select @msqdstatus=Status, @msqdquoteunits=isnull(QuoteUnits,0),
		   @msqdorderunits=isnull(OrderUnits,0), @msqdnotes=Notes
	from dbo.bMSQD
	where MSCo=@MSCo and Quote=@Quote and FromLoc=@location and Material=@material 
	and UM=@um and PhaseGroup=@phasegroup and Phase=@phase
	if @@rowcount = 0
		begin
		-- get next sequence for quote
		set @msqd_seq = 0
		select @msqd_seq = max(Seq) from dbo.bMSQD where MSCo=@MSCo and Quote=@Quote
		if @@rowcount = 0 or @msqd_seq is null set @msqd_seq = 0
		-- new quote detail, insert into MSQD
		insert into dbo.bMSQD (MSCo, Quote, FromLoc, MatlGroup, Material, UM, QuoteUnits, UnitPrice,
				ECM, ReqDate, Status, OrderUnits, SoldUnits, AuditYN, Notes, Seq, PhaseGroup, Phase)
		select @MSCo, @Quote, @location, @matlgroup, @material, @um, @units, @unitcost,
				@ecm, @reqdate, 0, 0, 0, 'N', @pmmfnotes, @msqd_seq + 1, @phasegroup, @phase

		-- update interface date in PMMF
		update dbo.bPMMF set InterfaceDate=@DatePosted
		WHERE KeyID = @PMMF_KeyID
		goto PMMF_loop
		end
   
	-- if notes are empty in MSQD and PMMF set to null
	if isnull(@msqdnotes,'') = '' and isnull(@pmmfnotes,'') = ''
		begin
		select @msqdnotes = null
		goto MSQD_UPDATE_PHASE
		end
	-- if MSQD notes are empty and PMMF notes are not set to PMMF notes
	if isnull(@msqdnotes,'') = '' and isnull(@pmmfnotes,'') <> ''
		begin
		select @msqdnotes = @pmmfnotes
		goto MSQD_UPDATE_PHASE
		end
	-- if MSQD and PMMF notes are not empty concatenate
	if isnull(@msqdnotes,'') <> '' and isnull(@pmmfnotes,'') <> ''
		begin
		select @msqdnotes = @msqdnotes + CHAR(13) + CHAR(10) + @pmmfnotes
		end



	MSQD_UPDATE_PHASE:
	-- when MSQD 0-bid status accumulate quote units and replace unit price and ecm
	if @msqdstatus = 0
		begin
		update dbo.bMSQD set QuoteUnits=@msqdquoteunits + @units, UnitPrice=@unitcost, ECM=@ecm, Notes=@msqdnotes
		where MSCo=@MSCo and Quote=@Quote and FromLoc=@location and Material=@material 
		and UM=@um and PhaseGroup=@phasegroup and Phase=@phase
		-- update interface date in PMMF
		update dbo.bPMMF set InterfaceDate=@DatePosted
		WHERE KeyID = @PMMF_KeyID
		goto PMMF_loop
		end
	   	
	-- when MSQD 1-ordered status accumulate quote units, order units, and replace unit price and ecm.
	if @msqdstatus = 1
		begin
		update dbo.bMSQD set QuoteUnits=@msqdquoteunits + @units, UnitPrice=@unitcost, ECM=@ecm, 
						 OrderUnits=@msqdorderunits + @units, Notes=@msqdnotes
		where MSCo=@MSCo and Quote=@Quote and FromLoc=@location and Material=@material 
		and UM=@um and PhaseGroup=@phasegroup and Phase=@phase
		-- update interface date in PMMF
		update dbo.bPMMF set InterfaceDate=@DatePosted
		WHERE KeyID = @PMMF_KeyID
		goto PMMF_loop
		END
		
	goto PMMF_loop
	END

ELSE

   	-- if @price_change = 'N' then add record without phase if possible
   	begin
   	-- insert or update MSQD with PMMF information
   	select @msqdstatus=Status, @msqdquoteunits=isnull(QuoteUnits,0),
   			@msqdorderunits=isnull(OrderUnits,0), @msqdnotes=Notes
   	from dbo.bMSQD
   	where MSCo=@MSCo and Quote=@Quote and FromLoc=@location and Material=@material 
   	and UM=@um and PhaseGroup=@phasegroup and Phase is null
   	if @@rowcount = 0
   		begin
   		-- get next sequence for quote
   		set @msqd_seq = 0
   		select @msqd_seq = max(Seq) from dbo.bMSQD where MSCo=@MSCo and Quote=@Quote
   		if @@rowcount = 0 or @msqd_seq is null set @msqd_seq = 0
   		-- new quote detail, insert into MSQD
   		insert into dbo.bMSQD (MSCo, Quote, FromLoc, MatlGroup, Material, UM, QuoteUnits, UnitPrice,
   				ECM, ReqDate, Status, OrderUnits, SoldUnits, AuditYN, Notes, Seq, PhaseGroup, Phase)
   		select @MSCo, @Quote, @location, @matlgroup, @material, @um, @units, @unitcost,
   				@ecm, @reqdate, 0, 0, 0, 'N', @pmmfnotes, @msqd_seq + 1, @phasegroup, null
   	
   		-- update interface date in PMMF
   		update dbo.bPMMF set InterfaceDate=@DatePosted
   		WHERE KeyID = @PMMF_KeyID
   		goto PMMF_loop
   		end
   
   	-- if notes are empty in MSQD and PMMF set to null
   	if isnull(@msqdnotes,'') = '' and isnull(@pmmfnotes,'') = ''
   		begin
   		select @msqdnotes = null
   		goto MSQD_UPDATE
   		end
   	-- if MSQD notes are empty and PMMF notes are not set to PMMF notes
   	if isnull(@msqdnotes,'') = '' and isnull(@pmmfnotes,'') <> ''
   		begin
   		select @msqdnotes = @pmmfnotes
   		goto MSQD_UPDATE
   		end
   	-- if MSQD and PMMF notes are not empty concatenate
   	if isnull(@msqdnotes,'') <> '' and isnull(@pmmfnotes,'') <> ''
   		begin
   		select @msqdnotes = @msqdnotes + CHAR(13) + CHAR(10) + @pmmfnotes
   		end
   	end
   
   MSQD_UPDATE:
	-- when MSQD 0-bid status accumulate quote units and replace unit price and ecm
	if @msqdstatus = 0
		begin
		update dbo.bMSQD set QuoteUnits=@msqdquoteunits + @units, UnitPrice=@unitcost, ECM=@ecm, Notes=@msqdnotes
		where MSCo=@MSCo and Quote=@Quote and FromLoc=@location and Material=@material 
		and UM=@um and PhaseGroup=@phasegroup and Phase is null
		-- update interface date in PMMF
		update dbo.bPMMF set InterfaceDate=@DatePosted
		WHERE KeyID = @PMMF_KeyID
		goto PMMF_loop
		end
   
	-- when MSQD 1-ordered status accumulate quote units, order units, and replace unit price and ecm.
	if @msqdstatus = 1
		begin
		update dbo.bMSQD set QuoteUnits=@msqdquoteunits + @units, UnitPrice=@unitcost, ECM=@ecm, 
						 OrderUnits=@msqdorderunits + @units, Notes=@msqdnotes
		where MSCo=@MSCo and Quote=@Quote and FromLoc=@location and Material=@material 
		and UM=@um and PhaseGroup=@phasegroup and Phase is null
		-- update interface date in PMMF
		update dbo.bPMMF set InterfaceDate=@DatePosted
		WHERE KeyID = @PMMF_KeyID
		goto PMMF_loop
		end




goto PMMF_loop



PMMF_end:
	if @opencursor <> 0
		begin
		close bcPMMF
		deallocate bcPMMF
		SET @opencursor = 0
		end
   
	if @errorcount > 0
		begin
		SET @rcode = 1
		end
   
   

bspexit:
	if @opencursor <> 0
	   begin
	   close bcPMMF
	   deallocate bcPMMF
	   SET @opencursor = 0
	   end
   
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMInterfaceMS] TO [public]
GO
