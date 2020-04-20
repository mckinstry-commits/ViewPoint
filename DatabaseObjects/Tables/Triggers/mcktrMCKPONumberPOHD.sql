USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mcktrMCKPONumberPOHD]    Script Date: 11/4/2014 4:16:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 11/7/13
-- Description:	Trigger to fill the udMCKPONumber on creation of a PO.
-- 9/15/2014 Discovered bug with multiple PO generation.  
-- --When more than one PO is interfaced simultaneously or more than one is processed from a batch, this could generate the same MCKPO number twice.
--	11/5/2014 UPDATE TO PREVENT DUPLICATE MCKPONumber assignments.  
-- =============================================
ALTER TRIGGER [dbo].[mcktrMCKPONumberPOHD] 
   ON  [dbo].[bPOHD] 
   AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for trigger here
	/*The following section provides a Julian date based PO Number for PO's entered through the PM Module
	It will not effect PO's entered through the PO module.
	*/
	DECLARE 
	@POCo TINYINT,
	@PO VARCHAR(30),
	@MCKPONumber VARCHAR(30),
	@MCKPOPart1 VARCHAR(5),
	@MCKPOPart2 VARCHAR(3),
	@TodayCount TINYINT, 
	@Approved CHAR(1),
	@ApprovedBy Varchar(255)
	,@Status TINYINT

	DECLARE insCrsr CURSOR FOR 
	SELECT POCo,PO, udMCKPONumber, Approved, ApprovedBy, Status 
	FROM INSERTED
	WHERE udMCKPONumber IS NULL

	OPEN insCrsr
	FETCH NEXT FROM insCrsr INTO @POCo,@PO,@MCKPONumber,@Approved, @ApprovedBy, @Status
	WHILE @@FETCH_STATUS=0
	BEGIN

	--SELECT @POCo = POCo, @PO = PO, @MCKPONumber = udMCKPONumber, @Approved = Approved, @ApprovedBy = ApprovedBy, @Status = Status 
	--FROM INSERTED

	/*Custom Validation*/
		DECLARE @rcode INT = 0, @msg VARCHAR(MAX)

		IF EXISTS(
			SELECT TOP 1 1 FROM dbo.POHD i
				JOIN dbo.JCJM ON dbo.JCJM.JCCo = i.JCCo AND dbo.JCJM.Job = i.Job AND JCJM.udProjWrkstrm = 'S'
			WHERE i.POCo=@POCo AND i.PO=@PO
			--SELECT TOP 1 1 
			--FROM INSERTED i
			--	JOIN dbo.JCJM ON dbo.JCJM.JCCo = i.JCCo AND dbo.JCJM.Job = i.Job AND JCJM.udProjWrkstrm = 'S'
				)
			BEGIN
				SELECT @msg = 'PO''s Against Sales Jobs are not permitted', @rcode = 1
				GOTO nextPO
			END
	/*End Validation*/
	--IF (SELECT Approved FROM INSERTED) IS NULL AND (SELECT udMCKPONumber FROM INSERTED) IS NULL
	--BEGIN
	--	SET @MCKPOPart1 = dbo.JulianDate(GETDATE())
	--	SET @TodayCount = (SELECT COUNT('x') FROM POHD WHERE LEFT(udMCKPONumber,5) = @MCKPOPart1)		
	--	SET @MCKPOPart2 = @TodayCount + 1
	--	SET @MCKPOPart2 = dbo.fnMckFormatWithLeading(@MCKPOPart2,0,3)
			
	--	SET @MCKPONumber = @MCKPOPart1 + @MCKPOPart2
		
	--	UPDATE dbo.bPOHD
	--	SET udMCKPONumber = @MCKPONumber
	--	WHERE POCo = @POCo AND PO = @PO
	--END
	--ELSE
	--BEGIN
		--IF UPDATE(Approved)
		BEGIN
			IF @Status <> 3 AND @MCKPONumber IS NULL --AND @ApprovedBy IS NOT NULL
			BEGIN

				BEGIN TRY
					SET @MCKPOPart1 = dbo.JulianDate(GETDATE())
					SET @TodayCount = (SELECT COALESCE(MAX( CAST(REPLACE(udMCKPONumber,dbo.JulianDate(GETDATE()), '')  AS INT)), 0)
					FROM mvwPONumberStore WHERE LEFT(udMCKPONumber,5) = @MCKPOPart1)
					
					SET @MCKPOPart2 = @TodayCount + 1
					SET @MCKPOPart2 = dbo.fnMckFormatWithLeading(@MCKPOPart2,0,3)
				
					SET @MCKPONumber = @MCKPOPart1 + @MCKPOPart2

					INSERT INTO dbo.mckMCKPONumberStore (MCKPONumber)
					VALUES(@MCKPONumber)
				
					UPDATE dbo.bPOHD
					SET udMCKPONumber = @MCKPONumber
					WHERE POCo = @POCo AND PO = @PO

					DELETE FROM mckMCKPONumberStore
					WHERE MCKPONumber = @MCKPONumber
				END TRY
				BEGIN CATCH
					SET @rcode = 1
					SELECT @msg = ERROR_MESSAGE()
					GOTO nextPO
				END CATCH
								
			END
		--END
		END	

		nextPO:
			IF @rcode <> 0
			BEGIN
			RAISERROR (@msg, 16, 1)
			ROLLBACK TRANSACTION
			END

		FETCH NEXT FROM insCrsr INTO @POCo,@PO,@MCKPONumber,@Approved, @ApprovedBy, @Status
	END
		
END

