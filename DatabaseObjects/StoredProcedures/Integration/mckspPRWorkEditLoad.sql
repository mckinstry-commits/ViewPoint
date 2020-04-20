USE [Viewpoint]
GO
/****** Object:  StoredProcedure [dbo].[mckspPRWorkEditLoad]    Script Date: 11/19/2014 1:11:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Eric Shafer
-- Create date: 10/10/2014
-- Description:	Procedure to copy records from MCK_INTEGRATION to the custom udPREmpWorkEdit tables in VP.  
-- Part of the HR.Net integration.
-- =============================================
ALTER PROCEDURE [dbo].[mckspPRWorkEditLoad] 
	-- Add the parameters for the stored procedure here
	@ImportID VARCHAR(10) 
	, @ReturnMessage VARCHAR(MAX) OUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	--DECLARE @ImportID VARCHAR(10) = 'TEST'
	DECLARE @RecordCount BIGINT
	, @RecordCount2 BIGINT
	
	, @MCKUpdateReturn VARCHAR(MAX)
	, @rcode INT = 0;

	DECLARE @strSQL VARCHAR(MAX) = '';

	BEGIN TRY
		BEGIN TRAN
		INSERT INTO dbo.udPREmpWorkEdit
	        ( PRCo ,
	        Employee ,
	        LastName ,
	        FirstName ,
	        MidName ,
	        Suffix ,
			SortName,
	        Address ,
	        Address2 ,
	        City ,
	        State ,
	        Zip ,
	        Country ,
	        Email ,
	        Phone ,
	        SSN ,
	        Race ,
	        Sex ,
	        BirthDate ,
	        HireDate ,
	        RecentRehireDate ,
	        PRGroup ,
	        PRDept ,
	        Craft ,
	        Class ,
	        UnempState ,
	        InsState ,
	        GLCo ,
	        Shift ,
	        udExempt ,
	        EarnCode ,
	        HrlyRate ,
	        OTOpt ,
	        SalaryAmt ,
	        ActiveYN ,
	        TermDate ,
	        OccupCat ,
	        CatStatus ,
	        CSAllocMethod ,
	        udJobTitle,
			ImportID,
			ImportSequence,
			InsCode, 
			ImportType,
			ApprovedYN,
			JCFixedRate, EMFixedRate, YTDSUI, DirDeposit, ud401kEligYN,ud401kElgDate
	        )
		SELECT  e2.PRCo ,
			e2.Employee ,
			e2.LastName ,
			e2.FirstName ,
			e2.MidName ,
			e2.Suffix ,
			ISNULL(e.SortName,dbo.mfnPREmpSortName_HRNet(e2.PRCo,e2.Employee)),
			e2.Address ,
			e2.Address2 ,
			e2.City ,
			e2.State ,
			e2.Zip ,
			e2.Country ,
			e2.Email ,
			e2.Phone ,
			e2.SSN ,
			e2.Race ,
			e2.Sex ,
			e2.BirthDate ,
			e2.HireDate ,
			e2.RecentRehireDate ,
			e2.PRGroup ,
			e2.PRDept ,
			e2.Craft ,
			e2.Class ,
			e2.UnempState ,
			e2.InsState ,
			e2.GLCo ,
			e2.Shift ,
			e2.udExempt ,
			e2.EarnCode ,
			e2.HrlyRate ,
			e2.OTOpt ,
			0,--e2.SalaryAmt ,
			e2.ActiveYN ,
			e2.TermDate ,
			e2.OccupCat ,
			e2.CatStatus ,
			e2.CSAllocMethod ,
			e2.udJobTitle,
			@ImportID,
			e2.Employee ,
			e2.InsCode,
			CASE WHEN e.Employee IS NULL THEN 'NEW RECORD' ELSE 'UPDATE' END,
			'A',
			0,0, 0,'N', e2.ud401kEligYN, e2.ud401kElgDate
		FROM MCK_INTEGRATION.dbo.MCK_WorkEdit_PREH e2
			JOIN MCK_INTEGRATION.dbo.HRNETVPExport e1 ON e2.PRCo = e1.COMPANYREFNO AND e2.Employee = CONVERT(INT, e1.REFERENCENUMBER)
			LEFT JOIN dbo.PREHFullName e ON e2.PRCo = e.PRCo AND e2.Employee = e.Employee
		WHERE e1.ProcessStatus = 'A'
		SELECT @RecordCount = @@ROWCOUNT
		
		IF @RecordCount > 0
		BEGIN
			
			EXEC @rcode = MCK_INTEGRATION.dbo.sp_HRNetVPExpStatusUpdate @CurrentStatus='A', @UpdateStatus = 'I', @RowCount=@RecordCount2 OUT, @ReturnMessage = @MCKUpdateReturn OUT
			--IF @RecordCount <> @RecordCount2
			--BEGIN
			--	SELECT @rcode = 1, @ReturnMessage = 'ERROR: Number in import doesn''t match with the number of updated records processed in status update' 
			--END
			SELECT @ReturnMessage = ISNULL(@ReturnMessage,'') + ISNULL(@MCKUpdateReturn,'')
		END

		SELECT @strSQL = @strSQL + CHAR(10) + 
			'UPDATE A
				SET Notes = '''+COLUMN_NAME+' changed from '' + ISNULL(CAST(B.'+COLUMN_NAME+' AS VARCHAR(100)),'''') + '' to '' + ISNULL(CAST(A.'+COLUMN_NAME+' AS VARCHAR(100)),'''') + CHAR(10) + ISNULL(A.Notes,'''')
			FROM dbo.udPREmpWorkEdit A JOIN dbo.bPREH B ON A.PRCo = B.PRCo AND A.Employee = B.Employee 
				AND ImportID = ''' + @ImportID + '''
				AND A.'+COLUMN_NAME+' <> B.'+COLUMN_NAME+';
				'
		FROM MCK_INTEGRATION.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MCK_WorkEdit_PREH' AND ORDINAL_POSITION > 2;

		--PRINT @strSQL; 
		EXEC (@strSQL);

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SELECT @ReturnMessage = ISNULL(@ReturnMessage,'')+ERROR_MESSAGE(), @rcode = 1

	END CATCH
	RETURN @rcode

END


