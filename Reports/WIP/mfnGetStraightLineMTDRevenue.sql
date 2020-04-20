--DROP FUNCTION mfnGetStraightLineMTDRevenue
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA='dbo' AND ROUTINE_NAME='mfnGetStraightLineMTDRevenue')
BEGIN
	PRINT 'DROP FUNCTION mfnGetStraightLineMTDRevenue'
	DROP FUNCTION dbo.mfnGetStraightLineMTDRevenue
END
go

--create function mfnGetStraightLineMTDRevenue
PRINT 'CREATE FUNCTION mfnGetStraightLineMTDRevenue'
go
create FUNCTION dbo.mfnGetStraightLineMTDRevenue
(
	@processMonth			SMALLDATETIME
,	@slTermStart			SMALLDATETIME
,	@slTerm					INT
,	@prevMthJtdEarnedRev	DECIMAL(18,2)
,	@currMthWipRev			DECIMAL(18,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
	IF (@slTermStart IS NULL OR @slTerm IS NULL OR @slTerm <= 0)
		RETURN 0.0

	DECLARE @remMthInTerm INT
	SELECT @remMthInTerm = @slTerm - DATEDIFF(MONTH, @slTermStart, @processMonth)
	
	IF (@remMthInTerm > @slTerm) -- Term start date is in future
		RETURN 0.0 --ISNULL(@prevMthJtdEarnedRev, 0.0)

	IF (@remMthInTerm <= 0)		 -- Term ended in past
		RETURN CAST((ISNULL(@currMthWipRev, 0.0) - ISNULL(@prevMthJtdEarnedRev, 0.0)) AS DECIMAL(18,2))

	-- Term is in progress
	RETURN CAST((ISNULL(@currMthWipRev, 0.0) - ISNULL(@prevMthJtdEarnedRev, 0.0))/@remMthInTerm AS DECIMAL(18,2))
	END
GO

-- Test Script
--select dbo.mfnGetStraightLineMTDRevenue(GetDate(), null, null, null, null)

--select dbo.mfnGetStraightLineMTDRevenue('11/1/2014', '12/1/2014', 1, 0, 121000)
--select dbo.mfnGetStraightLineMTDRevenue('11/1/2014', '12/1/2014', 1, 120000, 121000)
--select dbo.mfnGetStraightLineMTDRevenue('11/1/2014', '12/1/2014', 1, 120000, 0)

--select dbo.mfnGetStraightLineMTDRevenue('12/1/2014', '12/1/2014', 1, 0, 121000)
--select dbo.mfnGetStraightLineMTDRevenue('12/1/2014', '12/1/2014', 1, 120000, 121000)
--select dbo.mfnGetStraightLineMTDRevenue('12/1/2014', '12/1/2014', 1, 120000, 0)

--select dbo.mfnGetStraightLineMTDRevenue('1/1/2015', '12/1/2014', 1, 0, 121000)
--select dbo.mfnGetStraightLineMTDRevenue('1/1/2015', '12/1/2014', 1, 120000, 121000)
--select dbo.mfnGetStraightLineMTDRevenue('1/1/2015', '12/1/2014', 1, 120000, 0)