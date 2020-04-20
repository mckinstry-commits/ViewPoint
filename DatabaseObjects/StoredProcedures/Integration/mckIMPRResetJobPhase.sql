USE [Viewpoint]
GO

/****** Object:  StoredProcedure [dbo].[mckIMPRResetJobPhase]    Script Date: 1/15/2016 11:05:53 AM ******/
DROP PROCEDURE [dbo].[mckIMPRResetJobPhase]
GO

/****** Object:  StoredProcedure [dbo].[mckIMPRResetJobPhase]    Script Date: 1/15/2016 11:05:53 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Curt Salada
-- Create date: 2014-10-01
-- Description:	Work around for bug in PR Timecard template import routine
--
-- 2015-10-23  Curt S.  Populate JCCo and Job for job-related work orders
-- 2015-12-09  Curt S.  Populate GLCo
-- =============================================
CREATE PROCEDURE [dbo].[mckIMPRResetJobPhase] 
	-- Add the parameters for the stored procedure here
	(
	@Company bCompany = 0, 
	@ImportId varchar(20) = 0
	, @ImportTemplate VARCHAR(20)
	, @Form VARCHAR(20)
	, @msg VARCHAR(120) OUTPUT
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	declare @rcode int, /*@recode int,*/ @desc varchar(120)
       
        set nocount on
 
        select @rcode = 0
        
        
        /* check required input params */
        
        if @ImportId is null
          begin
          select @desc = 'Missing ImportId.', @rcode = 1
          goto bspexit
        
          end
        if @ImportTemplate is null
          begin
          select @desc = 'Missing ImportTemplate.', @rcode = 1
          goto bspexit
          end
        
        if @Form is null
          begin
          select @desc = 'Missing Form.', @rcode = 1
          goto bspexit
         end

    -- Insert statements for procedure here
	
	BEGIN
    
	--update the record.
		UPDATE dbo.IMWE
		SET IMWE.UploadVal = IMWE.ImportedVal
		WHERE IMWE.ImportId = @ImportId AND ImportTemplate = @ImportTemplate AND Form = @Form 
			AND Identifier = 70   -- JobPhase
		
		-- upgrade from 6.7 to 6.10.5
		-- Compensate for change in Viewpoint routine bspIMBidtekDefaultsPRTB,
		-- which used to populate the JCCo and Job fields for job-related work orders on "S" timesheets.
		-- We will add that functionality back here.

  		DECLARE @SMCo bCompany
		, @SMWorkOrder INT
		, @JCCo bCompany
		, @Job bJob  
		, @currrec INT  
		, @GLCo bCompany

		-- create temp table list of record seq's for this import
		CREATE TABLE #TempIMWE (RecordSeq INT)
		INSERT INTO #TempIMWE SELECT DISTINCT RecordSeq FROM IMWE WHERE IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form

		-- start at first record seq
		SELECT @currrec = MIN(RecordSeq) FROM #TempIMWE
		WHILE @currrec IS NOT NULL
		BEGIN
			-- get SMCo
			SELECT @SMCo = UploadVal FROM IMWE  
			WHERE IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
			AND IMWE.RecordSeq = @currrec AND IMWE.Identifier = 116

			-- get SMWorkOrder
			SELECT @SMWorkOrder = UploadVal  FROM IMWE  
			WHERE IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
			AND IMWE.RecordSeq = @currrec AND IMWE.Identifier = 117

			-- get Job and JCCo from SMWorkOrder record 
			select @JCCo = JCCo, @Job = Job from SMWorkOrder where SMCo = @SMCo and WorkOrder = @SMWorkOrder
	
			-- populate JCCo
			UPDATE IMWE
			SET IMWE.UploadVal = @JCCo
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrec and IMWE.Identifier = 55

			-- populate Job
			UPDATE IMWE
			SET IMWE.UploadVal = @Job
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrec and IMWE.Identifier = 60

			-- get GLCo from SMCo or JCCo
            -- for non-job work orders, GLCo = SMCo
			-- for job work orders, GLCo = JCCo
			IF @Job IS NULL 
			  SET @GLCo = @SMCo
			ELSE 
			  SET @GLCo = @JCCo

			-- populate GLCo
			UPDATE IMWE
			SET IMWE.UploadVal = @GLCo 
			WHERE IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrec and IMWE.Identifier = 75
			  
			-- advance to next record seq
			SELECT @currrec = MIN(RecordSeq) FROM #TempIMWE WHERE RecordSeq > @currrec
		END
		DROP TABLE #TempIMWE

	END


	bspexit:
	SELECT @msg = ISNULL(@desc,'User Routine') + CHAR(13) + CHAR(10) + '[[mckIMPRResetJobPhase]]'
	RETURN @rcode
END


GO


