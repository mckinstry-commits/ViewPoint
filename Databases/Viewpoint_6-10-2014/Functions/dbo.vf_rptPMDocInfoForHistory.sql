SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [dbo].[vf_rptPMDocInfoForHistory]

/*************
 Created:  HH 5/13/2011
 Modified: 
 
 Usage: Gets the Document information for the PMIssueHistoryRelatedItems
		 
		Function is used in the following report views: PM Issue History Report
		  
 Input Parameters:
	@TableName  - Table to get information
	@TableKeyID - Key to determine row in @TableName
	
 Output:  DocInformation

***************/		  	    

(
	@TableName varchar(30),
	@TableKeyID int
)

/*Document Info. */
RETURNS @DocInfo TABLE
(
	Document bDocument
	,DocCategory varchar(max)
	,DocType bDocType
	,DocDate smalldatetime
)

AS

BEGIN
	
	--Declaration 
	DECLARE @Document bDocument
			,@DocCategory varchar(max)
			,@DocType bDocType
			,@DocDate smalldatetime

	--Initialize 
	Select @Document = '', @DocCategory = '', @DocType='', @DocDate=null

	--Approved Change Order
	IF @TableName = 'bPMOH'
	BEGIN
		Select @Document = ACO, @DocCategory = 'ACO', @DocType=IntExt, @DocDate=ApprovalDate FROM bPMOH WHERE KeyID = @TableKeyID
	END
	--Contract Change Order
	ELSE IF @TableName = 'vPMContractChangeOrder'
	BEGIN
		Select @Document = ID , @DocCategory = 'CCO', @DocDate=Date  FROM vPMContractChangeOrder WHERE KeyID = @TableKeyID
    END
    --Change Order Request
	ELSE IF @TableName = 'vPMChangeOrderRequest'
	BEGIN
		Select @Document = COR , @DocCategory = 'COR', @DocDate=Date FROM vPMChangeOrderRequest WHERE KeyID = @TableKeyID
    END
    --Daily Log 
	ELSE IF @TableName = 'bPMDL'
	BEGIN
		Select @Document = DailyLog , @DocCategory = 'DAILY', @DocDate=LogDate FROM bPMDL WHERE KeyID = @TableKeyID
    END
    --Drawing Log 
	ELSE IF @TableName = 'bPMDG'
	BEGIN
		Select @Document = Drawing, @DocCategory ='DRAWING', @DocType = DrawingType, @DocDate=DateIssued FROM bPMDG WHERE KeyID = @TableKeyID
    END
    --Drawing Log Revision
	/*ELSE IF @TableName = ''
	BEGIN
		Select @Document = , @DocCategory = , @DocType= FROM @TableName WHERE KeyID = @TableKeyID
    END*/
    --Inspection Log select distinct DocCategory from PMDT
	ELSE IF @TableName = 'bPMIL'
	BEGIN
		Select @Document = InspectionCode, @DocCategory ='INSPECT' , @DocType=InspectionType, @DocDate=InspectionDate FROM bPMIL WHERE KeyID = @TableKeyID
    END
    --Letter Of Transmittal
	ELSE IF @TableName = 'bPMTM'
	BEGIN
		Select @Document = Transmittal , @DocCategory = 'TRANSMITTAL', @DocDate=TransDate FROM bPMTM WHERE KeyID = @TableKeyID
    END
    --Material Order 
	ELSE IF @TableName = 'bINMO'
	BEGIN
		Select @Document = MO, @DocCategory = 'MATERIALORDER', @DocDate=OrderDate FROM bINMO WHERE KeyID = @TableKeyID
    END
    --Meeting Minute
	ELSE IF @TableName = 'bPMMM'
	BEGIN
		Select @Document = Meeting, @DocCategory = 'MTG', @DocType=MeetingType, @DocDate=MeetingDate FROM bPMMM WHERE KeyID = @TableKeyID
    END
    --Other Document
	ELSE IF @TableName = 'bPMOD'
	BEGIN
		Select @Document = Document, @DocCategory = 'OTHER', @DocType=DocType, @DocDate=DateDue  FROM bPMOD WHERE KeyID = @TableKeyID
    END
    --Pending Change Order 
	ELSE IF @TableName = 'bPMOP'
	BEGIN
		Select @Document = PCO, @DocCategory = 'PCO', @DocType=PCOType, @DocDate=DateCreated  FROM bPMOP WHERE KeyID = @TableKeyID
    END
    --Project Issue
	ELSE IF @TableName = 'bPMIM'
	BEGIN
		Select @Document = Issue, @DocCategory ='ISSUE', @DocDate=DateInitiated FROM bPMIM WHERE KeyID = @TableKeyID
    END
    --Project Note
	ELSE IF @TableName = 'bPMPN'
	BEGIN
		Select @Document = NoteSeq, @DocCategory = 'NOTE', @DocDate=AddedDate FROM bPMPN WHERE KeyID = @TableKeyID
    END
    --Punch List
	ELSE IF @TableName = 'bPMPU'
	BEGIN
		Select @Document = PunchList, @DocCategory = 'PUNCHLIST', @DocDate=PunchListDate  FROM bPMPU WHERE KeyID = @TableKeyID
    END
    --Purchase Order 
	ELSE IF @TableName = 'bPOHD'
	BEGIN
		Select @Document = PO, @DocCategory = 'PO', @DocDate=OrderDate FROM bPOHD WHERE KeyID = @TableKeyID
    END
    --Purchase Change Order
	ELSE IF @TableName = 'vPMPOCO'
	BEGIN
		Select @Document = POCONum, @DocCategory = 'POCO', @DocDate=Date FROM vPMPOCO WHERE KeyID = @TableKeyID
    END
    --Request For Information
	ELSE IF @TableName = 'bPMRI'
	BEGIN
		Select @Document = RFI, @DocCategory = 'RFI', @DocType=RFIType, @DocDate=RFIDate  FROM bPMRI WHERE KeyID = @TableKeyID
    END
    --Subcontract
	ELSE IF @TableName = 'bSLHD'
	BEGIN
		Select @Document = SL, @DocCategory = 'SL', @DocDate=OrigDate FROM bSLHD WHERE KeyID = @TableKeyID
    END
    --Subcontract Change Order
	ELSE IF @TableName = 'vPMSubcontractCO'
	BEGIN
		Select @Document = SubCO, @DocCategory = 'SUBCO', @DocDate=Date FROM vPMSubcontractCO WHERE KeyID = @TableKeyID
    END
    --Submittal
	ELSE IF @TableName = 'bPMSM'
	BEGIN
		Select @Document = Submittal, @DocCategory = 'SUBMIT' , @DocType=SubmittalType, @DocDate=DateReqd FROM bPMSM WHERE KeyID = @TableKeyID
    END
    --Submittal Item
	ELSE IF @TableName = 'bPMSI'
	BEGIN
		Select @Document = Submittal, @DocCategory = 'SUBMITITEM', @DocType=SubmittalType, @DocDate=DateReqd FROM bPMSI WHERE KeyID = @TableKeyID
    END
    --Test Log
	ELSE IF @TableName = 'bPMTL'
	BEGIN
		Select @Document = TestCode, @DocCategory = 'TEST', @DocType=TestType, @DocDate=TestDate FROM bPMTL WHERE KeyID = @TableKeyID
    END
    

	INSERT INTO @DocInfo (Document, DocCategory, DocType, DocDate)
	VALUES (@Document, @DocCategory, @DocType, @DocDate)

	RETURN

END	 		

GO
GRANT SELECT ON  [dbo].[vf_rptPMDocInfoForHistory] TO [public]
GO
