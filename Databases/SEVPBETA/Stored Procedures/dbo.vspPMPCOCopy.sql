SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPMPCOCopy]
/***********************************************************
* Created By:	GP	03/22/2011 - V1# B-02378
* Modified By:	
* Code Review:	GF	03/23/2011
*				GF 06/27/2011 - TK-06237
*				DAN SO 06/28/2011 - TK-06237 - Copy Purchase information
*				GP	06/28/2011 - TK-06445 Added PricingMethod to PMOL insert
*				DAN SO 07/07/2011 - TK-06553 - Copy SCO/POCO info 
*				SCOTTP/ANDYW  01/08/2013 - TK-20644 - When copying PMOI get Destination Contract from JCJMPM
*
* Used in PM PCOS Copy to do exactly what it sounds like.
*****************************************************/
(@PMCo bCompany, @Project bProject, @PCOType bPCOType, @PCO bPCO, 
@NewProject bProject, @NewPCOType bPCOType, @NewPCO bPCO, @NewPCODesc bItemDesc, @Username bVPUserName, 
@msg varchar(255) output)
as
set nocount on
   
declare @rcode int, @PMDHNextSeq INT, @DefaultDaysDue SMALLINT,
		@PCOStatus VARCHAR(6), @BeginStatus VARCHAR(6)
		
select @rcode = 0
if @NewPCODesc = ''		set @NewPCODesc = null

--------------
--VALIDATION--
--------------
if @PMCo is null
begin
	select @msg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @Project is null
begin
	select @msg = 'Missing Project.', @rcode = 1
	goto vspexit
end

if @PCOType is null
begin
	select @msg = 'Missing PCO Type.', @rcode = 1
	goto vspexit
end

if @PCO is null
begin
	select @msg = 'Missing PCO.', @rcode = 1
	goto vspexit
end

if @NewProject is null
begin
	select @msg = 'Missing New Project.', @rcode = 1
	goto vspexit
end	
else
begin
	--validate project
	exec @rcode = dbo.vspPMProjectVal @PMCo, @NewProject, '0;1;2;3', null, null, null, null, null,
				null, null, null, null, null, @DefaultDaysDue OUTPUT, null, null, null, null, null, null, 
				null, null, null, @msg output
	if @rcode = 1	goto vspexit
end

if @NewPCOType is null
begin
	select @msg = 'Missing New PCO Type.', @rcode = 1
	goto vspexit
end
else
begin
	--validate pco type
	exec @rcode = dbo.vspPMDocTypeValForPCO @NewPCOType, null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null, null, null, @msg output
	if @rcode = 1	goto vspexit	
end

if @NewPCO is null
begin
	select @msg = 'Missing New PCO.', @rcode = 1
	goto vspexit
end

--make sure source pco exists
if not exists (select top 1 1 from dbo.bPMOP where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO)
begin
	select @msg = 'The source PCO does not exist.', @rcode = 1
	goto vspexit
end

--check for existing pco
if exists (select top 1 1 from dbo.bPMOP where PMCo = @PMCo and Project = @NewProject and PCOType = @NewPCOType and PCO = @NewPCO)
begin
	select @msg = 'PCO record already exists, select a new PCO.', @rcode = 1
	goto vspexit
end

--------   
--COPY--
--------

----TK-06237 BEGIN
--header info (PMOP)
---- get PM company info
SELECT @BeginStatus = BeginStatus
FROM dbo.bPMCO WHERE PMCo=@PMCo
IF @@rowcount = 0 SET @BeginStatus = nULL
---- get beginning status for PCO from PMSC
SET @PCOStatus = NULL
select Top 1 @PCOStatus = Status
FROM dbo.bPMSC WHERE DocCat = 'PCO' AND CodeType = 'B'
---- if not begin status setup for 'PCO' category
---- use PM Company begin status
IF @@rowcount = 0 SET @PCOStatus = @BeginStatus


insert dbo.bPMOP (PMCo, Project, PCOType, PCO, [Description], Issue, [Contract], PendingStatus, 
	Date1, Date2, Date3, ApprovalDate, Notes, IntExt, ROMAmount, Details, Reference,
	InitiatedBy, Priority, ReasonCode, BudgetType, SubType, ContractType, [Status], POType, ResponsiblePerson,
	DateCreated, VendorGroup, ResponsibleFirm, PricingMethod)
select @PMCo, @NewProject, @NewPCOType, @NewPCO, @NewPCODesc, Issue, [Contract], PendingStatus, 
	Date1, Date2, Date3, ApprovalDate, Notes, IntExt, ROMAmount, Details, Reference,
	InitiatedBy, Priority, ReasonCode, BudgetType, SubType, ContractType, @PCOStatus, POType, ResponsiblePerson,
	dbo.vfDateOnly(), VendorGroup, ResponsibleFirm, PricingMethod 
	from dbo.PMOP 
	where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO


--pco distribution (PMCD)
delete dbo.bPMCD where PMCo = @PMCo and Project = @NewProject and PCOType = @NewPCOType and PCO = @NewPCO


insert dbo.bPMCD (PMCo, Project, PCOType, PCO, Seq, VendorGroup, SentToFirm, SentToContact, DateSent,
	DateReqd, DateRecd, [Send], PrefMethod, CC)
select @PMCo, @NewProject, @NewPCOType, @NewPCO, Seq, VendorGroup, SentToFirm, SentToContact,
	dbo.vfDateOnly(), DATEADD(DAY,ISNULL(@DefaultDaysDue,0),dbo.vfDateOnly()),
	null, [Send], PrefMethod, CC
	from dbo.PMCD c
	where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO
	
	
--items info (PMOI)
insert dbo.bPMOI (PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, [Description], [Status], ApprovedDate,
	UM, Units, UnitPrice, PendingAmount, ApprovedAmt, Issue, Date1, Date2, Date3, [Contract], ContractItem,
	Approved, ApprovedBy, ForcePhaseYN, FixedAmountYN, FixedAmount, Notes, BillGroup, ChangeDays, InterfacedDate,
	ProjectCopy, BudgetNo, RFIType, RFI, InterfacedBy)
select @PMCo, @NewProject, @NewPCOType, @NewPCO, PCOItem, NULL, NULL, PMOI.[Description], @PCOStatus, NULL,
	UM, Units, UnitPrice, PendingAmount, 0, Issue, Date1, Date2, Date3, JCJMPM.[Contract], ContractItem,
	'N', NULL, ForcePhaseYN, FixedAmountYN, FixedAmount, PMOI.Notes, BillGroup, ChangeDays, NULL,
	'Y', BudgetNo, RFIType, RFI, NULL
	from dbo.PMOI
	join dbo.JCJMPM on JCJMPM.PMCo = PMOI.PMCo and JCJMPM.Project=@NewProject
	where PMOI.PMCo = @PMCo and PMOI.Project = @Project and PMOI.PCOType = @PCOType and PMOI.PCO = @PCO
		
		
--phases (PMOL)
insert dbo.bPMOL (PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, CostType, EstUnits,
	UM, UnitHours, EstHours, HourCost, UnitCost, ECM, EstCost, SendYN, InterfacedDate, Notes, CreatedFromAddOn,
	DistributedAmt, PO, Subcontract, PurchaseAmt, VendorGroup, Vendor, POSLItem, 
	MaterialCode, PurchaseUM, PurchaseUnits, PurchaseUnitCost, -- TK-06237 --
	SubCO, 
	SubCOSeq, 
	POCONum, 
	POCONumSeq) 
select @PMCo, @NewProject, @NewPCOType, @NewPCO, PCOItem, NULL, NULL, PhaseGroup, Phase, CostType, EstUnits,
	UM, UnitHours, EstHours, HourCost, UnitCost, ECM, EstCost, SendYN, NULL, Notes, CreatedFromAddOn,
	DistributedAmt, PO, Subcontract, PurchaseAmt, VendorGroup, Vendor, POSLItem, 
	MaterialCode, PurchaseUM, PurchaseUnits, PurchaseUnitCost, -- TK-06237 --
	-- TK-06553 --
	CASE WHEN ACO IS NULL THEN SubCO	  ELSE NULL END,
	CASE WHEN ACO IS NULL THEN SubCOSeq   ELSE NULL END, 
	CASE WHEN ACO IS NULL THEN POCONum	  ELSE NULL END,
	CASE WHEN ACO IS NULL THEN POCONumSeq ELSE NULL END
from dbo.PMOL
where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO

-- TK-06553 -- START --
-- REMOVE SubCO/POCO INFORMATION FROM ORIGIAL RECORD --
UPDATE	dbo.PMOL
   SET	SubCO = NULL,
		SubCOSeq = NULL,
		POCONum = NULL,
		POCONumSeq = NULL
  FROM	dbo.PMOL
 WHERE	PMCo = @PMCo AND Project = @Project AND PCOType = @PCOType AND PCO = @PCO AND ACO IS NULL
 -- TK-06553 -- END --

				
--history
delete dbo.bPMDH where PMCo = @PMCo and Project = @NewProject and DocType = @NewPCOType and Document = @NewPCO

select @PMDHNextSeq = isnull(max(Seq),0) + 1 from dbo.PMDH where PMCo = @PMCo and Project = @NewProject and DocCategory = 'PCO'

insert dbo.bPMDH (PMCo, Project, DocType, Document, Seq, ActionDateTime, 
	[Action], DocCategory, FieldType, UserName)
values (@PMCo, @NewProject, @NewPCOType, @NewPCO, @PMDHNextSeq, getdate(), 
	'PCO:' + char(9) + 'Copy Project:' + @Project + ' PCOType:' + @PCOType + ' PCO:' + @PCO, 'PCO', 'A', @Username)	

---- update PMOI for copied PCO and set project copy flag to 'N'
UPDATE dbo.bPMOI set ProjectCopy = 'N'
WHERE PMCo=@PMCo and Project=@NewProject AND PCOType=@NewPCOType AND PCO=@NewPCO
----TK-06237 END
   
   
vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOCopy] TO [public]
GO
