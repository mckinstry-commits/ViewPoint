SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspPMRequestForQuoteMigrateDataUD]
/***********************************************************
* CREATED BY:	GP	06/03/2013 TFS 49467
* MODIFIED BY:	AJW 7/2/2013 TFS 54443 Error after creating ud field
*				
* USAGE:
*	Used in PM Request for Quote Migrate Data to push data to PMRequestForQuote and create PCO record relation.
*	Adds all UD fields that don't currently exist and migrates data to those fields for provided record.
*
* INPUT PARAMETERS
*   NewRFQKeyID - newly created KeyID to find record and link to PMRQ for update
*	Description - some original from PMRQ, user can override for duplicate records
*
* OUTPUT PARAMETERS
*   @Msg	Errors
*
* RETURN VALUE
*   0       Success
*   1       Failure
*****************************************************/ 

(@NewRFQKeyID BIGINT, @Msg VARCHAR(255) = NULL OUTPUT)
AS
SET NOCOUNT ON


--Validate
IF @NewRFQKeyID IS NULL
BEGIN
	SET @Msg = 'Invalid new RFQ KeyID.'
	RETURN 1
END


DECLARE
	@UDColumnCounter INT, @UDMaxSeq INT, @UDColumnName VARCHAR(30),
	@UDVPDataType VARCHAR(30), @UDUseVPDataType bYN, @UDColumnLength INT, @UDColumnInputType TINYINT, @UDMask VARCHAR(30), @UDPrecision TINYINT,
	@UDLabelText VARCHAR(30), @UDGridColumnText VARCHAR(30), @UDStatusText VARCHAR(256), @UDRequired bYN, @UDDescription bDesc, @UDControlType TINYINT,
	@UDComboType VARCHAR(20), @UDValLevel TINYINT, @UDValProc VARCHAR(60), @UDValParams VARCHAR(256), @UDValMin VARCHAR(20), @UDValMax VARCHAR(20),
	@UDValExpression VARCHAR(256), @UDValExpressionError VARCHAR(256), @UDDefaultType TINYINT, @UDDefaultValue VARCHAR(256), @UDActiveLookup bYN,
	@UDUpdate NVARCHAR(MAX), @UDColumnList VARCHAR(MAX)


------------------------
--USER DEFINED COLUMNS--
------------------------
DECLARE @UDColumns TABLE
(
  Seq INT IDENTITY (1,1),
  ColumnName VARCHAR(30)
)

--Fill table w/ all ud columns in bPMRQ that are not in vPMRequestForQuote
INSERT @UDColumns (ColumnName)
SELECT a.ColumnName
FROM dbo.DDFIc a
WHERE a.Form = 'PMRFQ' AND a.ViewName = 'PMRQ' AND a.ColumnName LIKE 'ud%'
	AND NOT EXISTS (SELECT 1 FROM DDFIc b WHERE b.Form = 'PMRequestForQuote' AND b.ViewName = 'PMRequestForQuote' AND b.ColumnName = a.ColumnName)

--Loop through table
SET @UDColumnCounter = 1
SELECT @UDMaxSeq = MAX(Seq) FROM @UDColumns
WHILE @UDColumnCounter <= @UDMaxSeq
BEGIN
	SELECT @UDColumnName = ColumnName FROM @UDColumns WHERE Seq = @UDColumnCounter

	--Get info from source user defined field
	SELECT  @UDVPDataType = Datatype,
			@UDUseVPDataType = CASE WHEN Datatype IS NOT NULL THEN 'Y' ELSE 'N' END, 
			@UDColumnLength = InputLength,
			@UDColumnInputType = InputType,
			@UDMask = InputMask,
			@UDPrecision = Prec,
			@UDLabelText = Label,
			@UDGridColumnText = GridColHeading,
			@UDStatusText = StatusText,
			@UDRequired = Req,
			@UDDescription = [Description],
			@UDControlType = ControlType,
			@UDComboType = ComboType,
			@UDValLevel = ValLevel,
			@UDValProc = ValProc,
			@UDValParams = ValParams,
			@UDValMin = MinValue,
			@UDValMax = MaxValue,
			@UDValExpression = ValExpression,
			@UDValExpressionError = ValExpError,
			@UDDefaultType = DefaultType,
			@UDDefaultValue = DefaultValue,
			@UDActiveLookup = ActiveLookup
	FROM dbo.DDFIc 
	WHERE ViewName = 'PMRQ' AND ColumnName = @UDColumnName		

	--Add column to vPMRequestForQuote and add vDDFIc record
	EXECUTE dbo.vspHQUDAdd 'PMRequestForQuote', 1, 'vPMRequestForQuote', 'PMRequestForQuote', @UDColumnName, @UDUseVPDataType, @UDColumnInputType, @UDColumnLength,
		@UDVPDataType, @UDMask, @UDPrecision, @UDLabelText, @UDGridColumnText, @UDStatusText, @UDRequired, @UDDescription, @UDControlType, @UDComboType, @UDValLevel,
		@UDValProc, @UDValParams, @UDValMin, @UDValMax, @UDValExpression, @UDValExpressionError, @UDDefaultType, @UDDefaultValue, @UDActiveLookup, @Msg OUTPUT

	SET @UDColumnCounter = @UDColumnCounter + 1
END --End loop


--Copy ud data
DELETE @UDColumns

--Get all ud columns from viewpoint
INSERT @UDColumns (ColumnName)
SELECT a.ColumnName
FROM dbo.DDFIc a
WHERE a.Form = 'PMRFQ' AND a.ViewName = 'PMRQ' AND a.ColumnName LIKE 'ud%'
	AND EXISTS (SELECT 1 FROM DDFIc b WHERE b.Form = 'PMRequestForQuote' AND b.ViewName = 'PMRequestForQuote' AND b.ColumnName = a.ColumnName)

--Exit if no ud columns found
IF (SELECT MAX(Seq) FROM @UDColumns) IS NULL
BEGIN
	RETURN 0
END

--Build insert string
SET @UDUpdate = 'UPDATE dbo.PMRequestForQuote SET '

--Loop through table
SELECT @UDColumnCounter = MIN(Seq), @UDColumnList = '' FROM @UDColumns
SELECT @UDMaxSeq = MAX(Seq) FROM @UDColumns
WHILE @UDColumnCounter <= @UDMaxSeq
BEGIN
	SELECT @UDColumnName = ColumnName FROM @UDColumns WHERE Seq = @UDColumnCounter

	--Add column
	SET @UDUpdate = @UDUpdate + @UDColumnName + ' = PMRQ.' + @UDColumnName

	--Add commma after all columns except the last
	IF @UDColumnCounter <> @UDMaxSeq
	BEGIN
		SET @UDUpdate = @UDUpdate + ', '
	END

	SET @UDColumnCounter = @UDColumnCounter + 1
END --End loop

--Finish insert string
SET @UDUpdate = @UDUpdate 
	+ ' FROM dbo.PMRequestForQuote JOIN dbo.PMRQ ON PMRequestForQuote.PMRQKeyID = PMRQ.KeyID WHERE PMRequestForQuote.KeyID = ' 
	+ CAST(@NewRFQKeyID AS VARCHAR(30))

--execute in try/catch to return error to UI
DECLARE @rcode int

BEGIN TRY
	EXECUTE sp_executesql @UDUpdate
	SELECT @rcode = 0, @Msg = null
END TRY
BEGIN CATCH
	SELECT @rcode = 1,@Msg = 'vspPMRequestForQuoteMigrateDataUD - Error updating ud fields!'
END CATCH

RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMRequestForQuoteMigrateDataUD] TO [public]
GO
