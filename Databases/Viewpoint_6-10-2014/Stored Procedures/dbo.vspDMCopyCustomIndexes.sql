SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jonathan Paullin
-- Create date: 12/18/2008
-- Modified:	Dave C 9/15/09 -- Issue#: 135403 Changing INSERT to explicitly name the columns to be
--								  inserted into, preventing a compile error in the case that HQAI has
--								  altered.
--
-- Description:	This procedure will copy custom indexes from one attachment to another.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMCopyCustomIndexes]	
	@sourceAttachmentID int, @destinationAttachmentID int, @returnMessage varchar(512) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON; 
	
	-- Insert the copied attachment indexes from one attachment ID to another. IndexSeq will be set to 
	-- null since the trigger on bHQAI will handle it.
	insert into HQAI
	  		  (AttachmentID, IndexSeq, IndexName, APCo, APVendorGroup, APVendor, APReference,
			   APCheckNumber, ARCo, ARCustomer, ARInvoice, JCCo, JCJob, JCPhaseGroup, JCPhase,
			   JCCostType, JCContract, JCContractItem, POCo, POPurchaseOrder, POItem, EMCo,
			   EMEquipment,EMCostCode, EMCostType, PRCo, PREmployee, HRCo, HRReference,
			   MIMaterialGroup, MIMaterial, MIMonth, MITransaction, INCo, INLoc, MSCo,
			   MSTicket, SLCo, SLSubcontract, SLSubcontractItem, Notes, UniqueAttchID,
			   CustomYN, UserCustom1, UserCustom2, UserCustom3, UserCustom4, UserCustom5,
			   PMIssue, PMFirmNumber, PMFirmType, PMFirmContact, PMSubmSrcFirm, PMSubmSrcContact,
			   ARCustGroup, EMGroup, PMACO, PMACOItem, PMPCO, PMPCOItem, PMPCOType, PMDocType,
			   PMSubmittal, PMTransmittal, PMRFQ, PMRFI, PMDocument, PMInspectionCode, PMTestCode,
			   PMDrawing, PMMeeting, PMPunchList, PMLogDate, PMDailyLog, GLCo, GLAcct, PMRev,
			   PMSMPItem, RQCo, RQID, RQLine, RQQuote, RQQuoteLine, PRGroup, PREndDate, MO, MOItem, CMDeposit)
		select @destinationAttachmentID as AttachmentID, null as IndexSeq, IndexName, APCo, APVendorGroup,  
			   APVendor, APReference, APCheckNumber, ARCo, ARCustomer, ARInvoice, JCCo, JCJob,  
			   JCPhaseGroup, JCPhase, JCCostType, JCContract, JCContractItem, POCo, POPurchaseOrder, 
			   POItem, EMCo, EMEquipment, EMCostCode, EMCostType, PRCo, PREmployee, HRCo, HRReference, 
			   MIMaterialGroup, MIMaterial, MIMonth, MITransaction, INCo, INLoc, MSCo, MSTicket, 
			   SLCo, SLSubcontract, SLSubcontractItem, Notes, UniqueAttchID, CustomYN, UserCustom1, 
			   UserCustom2, UserCustom3, UserCustom4, UserCustom5, PMIssue, PMFirmNumber, 
			   PMFirmType, PMFirmContact, PMSubmSrcFirm, PMSubmSrcContact, ARCustGroup, EMGroup, 
			   PMACO, PMACOItem, PMPCO, PMPCOItem, PMPCOType, PMDocType, PMSubmittal, 
			   PMTransmittal, PMRFQ, PMRFI, PMDocument, PMInspectionCode, PMTestCode, PMDrawing, 
			   PMMeeting, PMPunchList, PMLogDate, PMDailyLog, GLCo, GLAcct, PMRev, PMSMPItem, RQCo, 
			   RQID, RQLine, RQQuote, RQQuoteLine, PRGroup, PREndDate, MO, MOItem, CMDeposit 
		from HQAI 
		where AttachmentID = @sourceAttachmentID and CustomYN = 'Y'
END



GO
GRANT EXECUTE ON  [dbo].[vspDMCopyCustomIndexes] TO [public]
GO
