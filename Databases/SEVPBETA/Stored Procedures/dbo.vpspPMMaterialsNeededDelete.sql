SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMMaterialsNeededDelete]
/************************************************************
* CREATED:		02/06/08  CHS
* MODIFIED:   TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				GF 11/16/2011 TK-10027
*
* USAGE:
*   Deletes the PM Materials Needed
*	
* CALLED FROM:
*	ViewpointCS Portal  
*   
************************************************************/	
(@KeyID BIGINT)

AS
SET NOCOUNT ON;

DELETE from dbo.PMMF WHERE KeyID = @KeyID;


--(
--	@Original_PMCo bCompany,
--	@Original_Project bJob,
--	@Original_Seq int,
--	@Original_RecordType char(1),
--	@Original_PCOType bDocType,
--	@Original_PCO bPCO,
--	@Original_PCOItem bPCOItem,
--	@Original_ACO bACO,
--	@Original_ACOItem bACOItem,
--	@Original_MaterialGroup bGroup,
--	@Original_MaterialCode bMatl,
--	@Original_MtlDescription bItemDesc,
--	@Original_PhaseGroup bGroup,
--	@Original_Phase bPhase,
--	@Original_CostType bJCCType,
--	@Original_MaterialOption char(1),
--	@Original_VendorGroup bGroup,
--	@Original_Vendor bVendor,
--	@Original_POCo bCompany,
--	@Original_PO varchar(30),
--	@Original_POItem bItem,
--	@Original_RecvYN bYN,
--	@Original_Location bLoc,
--	@Original_MO char(1),
--	@Original_MOItem bItem,
--	@Original_UM bUM,
--	@Original_Units bUnits,
--	@Original_UnitCost bUnitCost,
--	@Original_ECM bECM,
--	@Original_Amount bDollar,
--	@Original_ReqDate bDate,
--	@Original_InterfaceDate bDate,
--	@Original_TaxGroup bGroup,
--	@Original_TaxCode bTaxCode,
--	@Original_TaxType tinyint,
--	@Original_SendFlag bYN,
--	@Original_Notes VARCHAR(MAX),
--	@Original_RequisitionNum varchar(2),
--	@Original_MSCo bCompany,
--	@Original_Quote varchar,
--	@Original_INCo bCompany,
--	@Original_UniqueAttchID uniqueidentifier,
--	@Original_RQLine bItem,
--	@Original_IntFlag varchar(1),
--	@Original_KeyID bigint,
--	@Original_POTrans int,
--	@Original_POMth bMonth
--)


--AS
--	SET NOCOUNT ON;

--DELETE from PMMF
--WHERE
--(PMCo = @Original_PMCo)
--AND (Project = @Original_Project)
--AND (Seq = @Original_Seq)
--AND (RecordType = @Original_RecordType)
--AND (PCOType = @Original_PCOType OR @Original_PCOType IS NULL AND PCOType IS NULL)
--AND (PCO = @Original_PCO OR @Original_PCO IS NULL AND PCO IS NULL)
--AND (PCOItem = @Original_PCOItem OR @Original_PCOItem IS NULL AND PCOItem IS NULL)
--AND (ACO = @Original_ACO OR @Original_ACO IS NULL AND ACO IS NULL)
--AND (ACOItem = @Original_ACOItem OR @Original_ACOItem IS NULL AND ACOItem IS NULL)
--AND (MaterialGroup = @Original_MaterialGroup OR @Original_MaterialGroup IS NULL AND MaterialGroup IS NULL)
--AND (MaterialCode = @Original_MaterialCode OR @Original_MaterialCode IS NULL AND MaterialCode IS NULL)
--AND (MtlDescription = @Original_MtlDescription OR @Original_MtlDescription IS NULL AND MtlDescription IS NULL)
--AND (PhaseGroup = @Original_PhaseGroup OR @Original_PhaseGroup IS NULL AND PhaseGroup IS NULL)
--AND (Phase = @Original_Phase OR @Original_Phase IS NULL AND Phase IS NULL)
--AND (CostType = @Original_CostType OR @Original_CostType IS NULL AND CostType IS NULL)
--AND (MaterialOption = @Original_MaterialOption)
--AND (VendorGroup = @Original_VendorGroup OR @Original_VendorGroup IS NULL AND VendorGroup IS NULL)
--AND (Vendor = @Original_Vendor OR @Original_Vendor IS NULL AND Vendor IS NULL)
--AND (POCo = @Original_POCo OR @Original_POCo IS NULL AND POCo IS NULL)
--AND (PO = @Original_PO OR @Original_PO IS NULL AND PO IS NULL)
--AND (POItem = @Original_POItem OR @Original_POItem IS NULL AND POItem IS NULL)
--AND (RecvYN = @Original_RecvYN OR @Original_RecvYN IS NULL AND RecvYN IS NULL)
--AND (Location = @Original_Location OR @Original_Location IS NULL AND Location IS NULL)
--AND (MO = @Original_MO OR @Original_MO IS NULL AND MO IS NULL)
--AND (MOItem = @Original_MOItem OR @Original_MOItem IS NULL AND MOItem IS NULL)
--AND (UM = @Original_UM)
--AND (Units = @Original_Units)
--AND (UnitCost = @Original_UnitCost)
--AND (ECM = @Original_ECM OR @Original_ECM IS NULL AND ECM IS NULL)
--AND (Amount = @Original_Amount)
--AND (ReqDate = @Original_ReqDate OR @Original_ReqDate IS NULL AND ReqDate IS NULL)
--AND (InterfaceDate = @Original_InterfaceDate OR @Original_InterfaceDate IS NULL AND InterfaceDate IS NULL)
--AND (TaxGroup = @Original_TaxGroup OR @Original_TaxGroup IS NULL AND TaxGroup IS NULL)
--AND (TaxCode = @Original_TaxCode OR @Original_TaxCode IS NULL AND TaxCode IS NULL)
--AND (TaxType = @Original_TaxType OR @Original_TaxType IS NULL AND TaxType IS NULL)
--AND (SendFlag = @Original_SendFlag)
----AND (Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL)
--AND (RequisitionNum = @Original_RequisitionNum OR @Original_RequisitionNum IS NULL AND RequisitionNum IS NULL)
--AND (MSCo = @Original_MSCo OR @Original_MSCo IS NULL AND MSCo IS NULL)
--AND (Quote = @Original_Quote OR @Original_Quote IS NULL AND Quote IS NULL)
--AND (INCo = @Original_INCo OR @Original_INCo IS NULL AND INCo IS NULL)
--AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)
--AND (RQLine = @Original_RQLine OR @Original_RQLine IS NULL AND RQLine IS NULL)
--AND (IntFlag = @Original_IntFlag OR @Original_IntFlag IS NULL AND IntFlag IS NULL)
--AND (KeyID = @Original_KeyID)
--AND (POTrans = @Original_POTrans OR @Original_POTrans IS NULL AND POTrans IS NULL)
--AND (POMth = @Original_POMth OR @Original_POMth IS NULL AND POMth IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspPMMaterialsNeededDelete] TO [VCSPortal]
GO
