SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMMaterialsNeededInsert]
/************************************************************
* CREATED:		02/06/08  CHS
* Modified By:	GF 09/16/2011 TK-08528 Missing VendorGroup, POCo on insert
*				GF 11/16/2011 TK-10027 get phase group from HQCo for PMCo
*
*
* USAGE:
*   Inserts the PM Materials Needed
*	
* CALLED FROM:
*	ViewpointCS Portal 
*
*	Calculations:
*		If the value for UM is �LS�, then Units and Unit Cost values 
*		are ignored and the Amount value is used as free form entry.
*
*		If the value for UM is not �LS�, and there are values entered 
*		for Units and Unit Cost, then the Amount field will be over-written 
*		with the value of Units * Unit Cost. 
*   
************************************************************/	
(
	@PMCo bCompany,
	@Project bJob,
	@Seq int,
	@RecordType char(1),
	@PCOType bDocType,
	@PCO bPCO,
	@PCOItem bPCOItem,
	@ACO bACO,
	@ACOItem bACOItem,
	@MaterialGroup bGroup,
	@MaterialCode bMatl,
	@MtlDescription bItemDesc,
	@PhaseGroup bGroup,
	@Phase bPhase,
	@CostType bJCCType,
	@MaterialOption char(1),
	@VendorGroup bGroup,
	@Vendor bVendor,
	@POCo bCompany,
	@PO VARCHAR(30),
	@POItem bItem,
	@RecvYN bYN,
	@Location bLoc,
	@MO char(1),
	@MOItem bItem,
	@UM bUM,
	@Units bUnits,
	@UnitCost bUnitCost,
	@StringUnitCost varchar(30),
	@ECM bECM,
	@Amount bDollar,
	@StringAmount varchar(30),
	@ReqDate bDate,
	@InterfaceDate bDate,
	@TaxGroup bGroup,
	@TaxCode bTaxCode,
	@TaxType tinyint,
	@SendFlag bYN,
	@Notes VARCHAR(MAX),
	@RequisitionNum varchar,
	@MSCo bCompany,
	@Quote varchar,
	@INCo bCompany,
	@UniqueAttchID uniqueidentifier,
	@RQLine bItem,
	@IntFlag varchar,
	@POTrans int,
	@POMth bMonth
)
	

AS
	SET NOCOUNT ON;

declare @rcode int, @message varchar(255)
		--@MaterialGroup bGroup,
		--@PhaseGroup bGroup,
		--@VendorGroup bGroup,
		--@TaxGroup bGroup
		
select @rcode = 0, @message = ''

---- TK-08528 get APCO from PM Company Parameters
SELECT @POCo = p.APCo
FROM dbo.PMCO p WITH (NOLOCK)
WHERE p.PMCo = @PMCo

---- TK-10027 phase group from HQCo for JCCo
SELECT  @PhaseGroup = h.PhaseGroup
FROM dbo.HQCO h WITH (NOLOCK)
WHERE h.HQCo = @PMCo

---- TK-10027 other Groups from HQCO for POCo (APCo)
SELECT @VendorGroup = h.VendorGroup,
		@TaxGroup = h.TaxGroup,
		@MaterialGroup = h.MatlGroup
FROM dbo.HQCO h WITH (NOLOCK)
WHERE h.HQCo = @POCo

---- TK-08528 get group info from HQ for PMCo
----select  @PhaseGroup = h.PhaseGroup,
----		@TaxGroup = h.TaxGroup,
----		@MaterialGroup = h.MatlGroup,
----		@VendorGroup = hp.VendorGroup
----from dbo.HQCO h with (nolock)
----JOIN dbo.HQCO hp ON hp.HQCo = @POCo
----WHERE h.HQCo = @PMCo

---- TK-08528 HUH? THIS WILL NOT WORK
--select @TaxCode = t.TaxCode from HQTX t with (nolock) where @TaxGroup = t.TaxGroup

select @MaterialOption = 'P', @SendFlag = 'Y', @RecordType = 'O'

Set @Seq = (Select IsNull((Max(Seq)+1),1) from PMMF with (nolock) where PMCo = @PMCo and Project = @Project)

if @POTrans = -1 set @POTrans = null
if @Vendor= -1 set @Vendor = null

-- check for dirty data
if @UM Like '%LS%' and 	@UM <> 'LS'
	begin
		select @rcode = 1, @message = 'Invalid Unit of Measure string [' + @UM + ']: check for leading or trailing spaces.'
		goto bspmessage
	end



if @UM = 'LS'
	begin
		select @Units = 0, @UnitCost = 0
		select @Amount = cast(cast(@StringAmount as money) as numeric(12,2))
	end

else
	begin	
		select @UnitCost = cast(cast(@StringUnitCost as FLOAT) as numeric(16,5))
		select @Amount = @Units * @UnitCost
	end





INSERT INTO PMMF(PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, 
		ACO, ACOItem, MaterialGroup, MaterialCode, MtlDescription, PhaseGroup, 
		Phase, CostType, MaterialOption, VendorGroup, Vendor, POCo, PO, POItem, 
		RecvYN, Location, MO, MOItem, UM, Units, UnitCost, ECM, Amount, ReqDate, 
		InterfaceDate, TaxGroup, TaxCode, TaxType, SendFlag, Notes, RequisitionNum, 
		MSCo, Quote, INCo, UniqueAttchID, RQLine, IntFlag, POTrans, POMth)

VALUES(@PMCo, @Project, @Seq, @RecordType, @PCOType, @PCO, @PCOItem, @ACO, 
		@ACOItem, @MaterialGroup, @MaterialCode, @MtlDescription, @PhaseGroup, @Phase, 
		@CostType, @MaterialOption, @VendorGroup, @Vendor, @POCo, @PO, @POItem, 
		@RecvYN, @Location, @MO, @MOItem, @UM, @Units, @UnitCost, @ECM, @Amount, 
		@ReqDate, @InterfaceDate, @TaxGroup, @TaxCode, @TaxType, @SendFlag, @Notes, 
		@RequisitionNum, @MSCo, @Quote, @INCo, @UniqueAttchID, @RQLine, @IntFlag, @POTrans, @POMth)

DECLARE @KeyID int
SET @KeyID = SCOPE_IDENTITY()
execute vpspPMMaterialsNeededGet @PMCo, @Project, @KeyID

bspexit:
return @rcode

bspmessage:
	RAISERROR(@message, 11, -1)
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vpspPMMaterialsNeededInsert] TO [VCSPortal]
GO
