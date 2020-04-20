SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****************************************/
CREATE PROCEDURE [dbo].[vpspPMApprovedCOPhasesUpdate]
/************************************************************
* CREATED:     5/2/06  chs
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 01/09/2011 TK-11594
*
*
* USAGE:
*   Updates the PM Approved Change Orders Phase
*
* CALLED FROM:
*	ViewpointCS Portal  
*
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

	----@PhaseGroup bGroup,
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
	@SendYN bYN,
	
	@PhaseDescription varchar(60) = '',
	@BillFlag char(1), 
	@ItemUnitFlag bYN, 
	@PhaseUnitFlag bYN,
	@ActiveYN bYN,
	@InterfacedDate bDate,
	@Notes VARCHAR(MAX),
	
	@Original_PMCo bCompany,
	@Original_Project bJob,
	@Original_PCOType bDocType,
	@Original_PCO bPCO,
	@Original_PCOItem bPCOItem,
	@Original_ACO bACO,
	@Original_ACOItem bACOItem,
	
	----@Original_PhaseGroup bGroup,
	@Original_Phase bPhase,
	@Original_CostType bJCCType,
	@Original_EstUnits bUnits,
	@Original_UM bUM,
	@Original_UnitHours bHrs,
	@Original_EstHours bHrs,
	@Original_HourCost bUnitCost,
	@Original_UnitCost bUnitCost,
	@Original_ECM bECM,
	@Original_EstCost bDollar,
	@Original_SendYN bYN,
	
	@Original_PhaseDescription varchar(60) = '',
	@Original_BillFlag char(1), 
	@Original_ItemUnitFlag bYN, 
	@Original_PhaseUnitFlag bYN,
	@Original_ActiveYN bYN,
	@Original_InterfacedDate bDate,
	@Original_Notes VARCHAR(MAX),
	@Original_UniqueAttchID UNIQUEIDENTIFIER
)
AS 
SET NOCOUNT ON ;

----TK-11594
declare @FormattedPhase varchar(50), @inputmask varchar(30)
declare @rcode int, @msg varchar(255), @descr varchar(60)
declare @contract bContract, @item bContractItem, @OverRide bYN 

declare @BuyOutYN bYN, @PhaseGroup bGroup

select @rcode = 0, @msg = '', @item = null, @descr = '', @contract = null, @item = null
select @BuyOutYN = 'N', @OverRide = 'N', @FormattedPhase = ''


--
--============================ Phase Validation and insertion===========================
select @PhaseGroup = PMCO.PhaseGroup from PMCO with (nolock) where PMCO.PMCo = @PMCo

-- get input mask for bPhase
select @inputmask = InputMask from DDDTShared with (nolock) where Datatype = 'bPhase'

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

if @rcode != 0 goto bspexit


-- set @Description to the default for the phase if left blank
if isnull(@PhaseDescription,'') = '' set @PhaseDescription = isnull(@descr,'')


		-- look for contract item
		set @item = (select ContractItem from PMOI 
						where PMOI.PMCo = @PMCo 
							and PMOI.Project = @Project 
							and PMOI.PCOType = @PCOType 
							and PMOI.PCO = @PCO 
							and PMOI.PCOItem = @PCOItem)

		if @@rowcount = 0
			begin
				select @msg = 'Invalid PCO Item.', @rcode = 1
				goto bspmessage
			end

		set @rcode = 0
		set @msg = ''

		set @OverRide = 'P'

		execute @rcode = dbo.bspPMJCCHAddUpdate @PMCo, @Project, @PhaseGroup, @FormattedPhase, 
					@CostType, @item, @PhaseDescription, @UM, @BillFlag, @ItemUnitFlag,
					@PhaseUnitFlag, @BuyOutYN, @ActiveYN, @OverRide, null,
					@msg output

		if @rcode != 0

			begin	
				select @rcode = 1, @msg = 'Error adding Phase code value ' + @FormattedPhase + '.'
				goto bspmessage
			end

--
--========================================= Calculations====================================
select  @EstUnits = isnull(@EstUnits, 0), @UnitHours = isnull(@UnitHours, 0),
		@EstHours = isnull(@EstHours, 0), @HourCost = isnull(@HourCost, 0),
		@UnitCost = isnull(@UnitCost, 0), @EstCost = isnull(@EstCost, 0)

-- then calculate either Amount or Unit Cost
IF ISNULL(@EstUnits, 0) <> 0
	BEGIN
	IF ISNULL(@UnitCost, 0) <> 0 AND ISNULL(@UnitCost,0) <> ISNULL(@Original_UnitCost,0)
		BEGIN
		---- calculate Amount
		SET @EstCost = @EstUnits * @UnitCost
		END
	ELSE
		BEGIN
		---- calculate Unit Cost
		IF ISNULL(@EstCost, 0) <> 0
			BEGIN
			SET @UnitCost = @EstCost / @EstUnits
			END
		ELSE
			BEGIN
			---- if unable to calculate either Amount or Unit Cost then set everything to zero
			SELECT  @EstUnits = 0, @UnitHours = 0, @EstHours = 0,
					@HourCost = 0, @UnitCost = 0
			END
		END
	END
ELSE
	BEGIN
	select @EstUnits = 0, @UnitHours = 0, @EstHours = 0, @HourCost = 0, @UnitCost = 0
	END



---- UPDATE PMOL
    UPDATE  PMOL
    SET     EstUnits = @EstUnits,
            UM = @UM,
            UnitHours = @UnitHours,
            EstHours = @EstHours,
            HourCost = @HourCost,
            UnitCost = @UnitCost,
            EstCost = @EstCost,
            SendYN = @SendYN,
            Notes = @Notes
    WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( ACO = @Original_ACO )
            AND ( ACOItem = @Original_ACOItem )
            AND ( PhaseGroup = @PhaseGroup )
            AND ( Phase = @Original_Phase )
            AND ( CostType = @Original_CostType )
            AND ( InterfacedDate = @Original_InterfacedDate
                  OR @Original_InterfacedDate IS NULL
                  AND InterfacedDate IS NULL
                ) ;


bspexit:
	return @rcode

bspmessage:
	RAISERROR(@msg, 11, -1);
	return @rcode
	
	
    --UPDATE  PMOL
    --SET     EstUnits = @EstUnits,
    --        UM = @UM,
    --        UnitHours = @UnitHours,
    --        EstHours = @EstHours,
    --        HourCost = @HourCost,
    --        UnitCost = @UnitCost,
    --        EstCost = @EstCost,
    --        SendYN = @SendYN,
    --        Notes = @Notes,
    --WHERE   ( PMCo = @Original_PMCo )
    --        AND ( Project = @Original_Project )
    --        AND ( ACO = @Original_ACO )
    --        AND ( ACOItem = @Original_ACOItem )
    --        AND ( PhaseGroup = @Original_PhaseGroup )
    --        AND ( Phase = @Original_Phase )
    --        AND ( CostType = @Original_CostType )
    --        AND ( InterfacedDate = @Original_InterfacedDate
    --              OR @Original_InterfacedDate IS NULL
    --              AND InterfacedDate IS NULL
    --            ) ;
		
    --SELECT  PMCo,
    --        Project,
    --        PCOType,
    --        PCO,
    --        PCOItem,
    --        ACO,
    --        ACOItem,
    --        PhaseGroup,
    --        Phase,
    --        CostType,
    --        EstUnits,
    --        UM,
    --        UnitHours,
    --        EstHours,
    --        HourCost,
    --        UnitCost,
    --        ECM,
    --        EstCost,
    --        SendYN,
    --        InterfacedDate,
    --        Notes,
    --        UniqueAttchID
    --FROM    PMOL l
    --WHERE   l.PMCo = @PMCo
    --        AND l.Project = @Project
    --        AND l.ACO = @ACO
    --        AND l.ACOItem = @ACOItem





GO
GRANT EXECUTE ON  [dbo].[vpspPMApprovedCOPhasesUpdate] TO [VCSPortal]
GO
