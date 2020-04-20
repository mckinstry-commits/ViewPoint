SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/******************************************/
CREATE PROCEDURE [dbo].[vpspPMApprovedCOPhasesInsert]
/************************************************************
* CREATED:     5/2/06  chs
* Modified By:	GF 01/09/2011 TK-11594 missing phase group
*
*
* USAGE:
*   Inserts the PM Approved Change Orders Phase
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/

(
	@PMCo bCompany,
	@Project bJob,
	@PCOType bDocType,
	@PCO bPCO,
	@PCOItem bPCOItem,
	@ACO bACO,
	@ACOItem bACOItem,
	@Phase bPhase,
	@CostType bJCCType,
	@EstUnits bUnits,
	@UM bUM,
	@UnitHours bHrs,
	@EstHours bHrs,
	@HourCost bUnitCost,
	@UnitCost bUnitCost,
	@ECM bECM,
	@EstCost bDollar,
	@SendYN CHAR(1),
	@InterfacedDate bDate,
	@Notes VARCHAR(MAX),
	@UniqueAttchID UNIQUEIDENTIFIER,
	----TK-11594
	@PhaseDescription VARCHAR(60),
	@BillFlag CHAR(1),
	@ItemUnitFlag CHAR(1),
	@PhaseUnitFlag CHAR(1),
	@ActiveYN CHAR(1)
)

AS
SET NOCOUNT ON;

----TK-11594
--============================ Phase Validation and insertion===========================
declare @FormattedPhase varchar(50)
declare @inputmask varchar(30)
declare @rcode int, @msg varchar(255), @descr varchar(60)
declare @contract bContract, @item bContractItem
declare @OverRide bYN
declare @BuyOutYN bYN
DECLARE @PhaseGroup bGroup

select @rcode = 0, @msg = 'not set', @item = null, @descr = '', @contract = null, @item = null
select @BuyOutYN = 'N', @OverRide = 'N', @FormattedPhase = ''

select @PhaseGroup = PMCO.PhaseGroup from dbo.PMCO with (nolock) where PMCO.PMCo = @PMCo

-- get input mask for bPhase
select @inputmask = InputMask from dbo.DDDTShared with (nolock) where Datatype = 'bPhase'

-- format value to phase
exec @rcode = dbo.bspHQFormatMultiPart @Phase, @inputmask, @FormattedPhase output

-- throw error if unable to format the phase
if @rcode != 0 
	begin	
		select @rcode = 1, @msg = 'Error Formatting Phase code ' + @Phase + '!'
		goto bspmessage
	end


-- phase code validation on FormattedPhase
execute @rcode = dbo.bspJCVPHASEForPM @PMCo, @Project, @FormattedPhase, @OverRide, 
	null, @descr, @PhaseGroup, @contract, @item, null, null, null, null, null, 
	@msg output

if @rcode != 0 goto bspmessage

-- set @Description to the default for the phase if left blank
if isnull(@PhaseDescription,'') = '' set @PhaseDescription = isnull(@descr,'')

select @item = @PCOItem
select @rcode = 0, @msg = ''
set @OverRide = 'P'
		
execute @rcode = dbo.bspPMJCCHAddUpdate @PMCo, @Project, @PhaseGroup, @FormattedPhase, 
			@CostType, @item, @PhaseDescription, @UM, @BillFlag, @ItemUnitFlag,
			@PhaseUnitFlag, @BuyOutYN, @ActiveYN, @OverRide, null,
			@msg output

if @rcode != 0
	begin	
		select @rcode = 1--, @msg = 'Error adding Phase code value ' + @FormattedPhase + '.'
		goto bspmessage
	end


--
--========================================= Calculations====================================

--
--========================================= Calculations====================================

select  @EstUnits = isnull(@EstUnits, 0), @UnitHours = isnull(@UnitHours, 0),
		@EstHours = isnull(@EstHours, 0), @HourCost = isnull(@HourCost, 0), 
		@UnitCost = isnull(@UnitCost, 0), @EstCost = isnull(@EstCost, 0)

-- then calculate either Amount or Unit Cost
IF ISNULL(@EstUnits, 0) <> 0
	BEGIN
	if isnull(@UnitCost, 0) <> 0
		begin
		-- calculate Amount
		SET @EstCost = @EstUnits * @UnitCost
		end
	else
		begin
		-- calculate Unit Cost
		if isnull(@EstCost, 0) <> 0
			BEGIN
			SET @UnitCost = @EstCost / @EstUnits
			END

		-- if unable to calculate either Amount or Unit Cost then set everything to zero
		ELSE
			BEGIN
			SELECT  @EstUnits = 0, @UnitHours = 0, @EstHours = 0, 
					@HourCost = 0, @UnitCost = 0
			END
		end
	end
ELSE
	BEGIN
	SELECT  @EstUnits = 0, @UnitHours = 0, @EstHours = 0,
			@HourCost = 0, @UnitCost = 0
	END

select @ECM = 'E'


INSERT 
INTO PMOL(PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, 
PhaseGroup, Phase, CostType, EstUnits, UM, UnitHours, EstHours, 
HourCost, UnitCost, ECM, EstCost, SendYN, InterfacedDate, Notes, 
UniqueAttchID) 

VALUES (@PMCo, @Project, @PCOType, @PCO, @PCOItem, @ACO, @ACOItem, 
@PhaseGroup, @Phase, @CostType, @EstUnits, @UM, @UnitHours, 
@EstHours, @HourCost, @UnitCost, @ECM, @EstCost, 
@SendYN, @InterfacedDate, @Notes, @UniqueAttchID);


DECLARE @KeyID int
SET @KeyID = SCOPE_IDENTITY()
execute vpspPMApprovedCOPhasesGet @PMCo, @Project, @ACO, @ACOItem, @KeyID

bspexit:
	return @rcode

bspmessage:
	RAISERROR(@msg, 11, -1);
	return @rcode



----INSERT 
----INTO PMOL(PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, 
----	PhaseGroup, Phase, CostType, EstUnits, UM, UnitHours, EstHours, 
----	HourCost, UnitCost, ECM, EstCost, SendYN, InterfacedDate, Notes, 
----	UniqueAttchID) 

----VALUES (@PMCo, @Project, @PCOType, @PCO, @PCOItem, @ACO, @ACOItem, 
----	@PhaseGroup, @Phase, @CostType, @EstUnits, @UM, @UnitHours, 
----	@EstHours, @HourCost, @UnitCost, @ECM, @EstCost, 
----	@SendYN, @InterfacedDate, @Notes, @UniqueAttchID);


----DECLARE @KeyID int
----SET @KeyID = SCOPE_IDENTITY()
----execute vpspPMApprovedCOPhasesGet @PMCo, @Project, @ACO, @ACOItem, @KeyID



GO
GRANT EXECUTE ON  [dbo].[vpspPMApprovedCOPhasesInsert] TO [VCSPortal]
GO
