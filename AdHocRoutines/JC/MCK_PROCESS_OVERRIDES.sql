--SELECT ProjCost, Note FROM dbo.JCOP
--SELECT * FROM dbo.JCOR
USE Viewpoint
go

if exists ( select 1 from sysobjects where type='U' and name='MCK_JCOP_UPDATE')
begin
	PRINT 'DROP TABLE MCK_JCOP_UPDATE'
	DROP TABLE MCK_JCOP_UPDATE
end
go

PRINT 'CREATE TABLE MCK_JCOP_UPDATE'
go

CREATE TABLE MCK_JCOP_UPDATE
(
	JCCo			bCompany		NOT null
,	Job				bJob			NOT null
,	Month			bMonth			NOT NULL DEFAULT ( CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME) )
,	ProjCost		bDollar			NOT NULL DEFAULT (0.00)
,	OtherAmount		bDollar			NOT null DEFAULT (0.00)
,	Notes			VARCHAR(MAX)	NULL
)
GO


if exists ( select 1 from sysobjects where type='U' and name='MCK_JCOR_UPDATE')
begin
	PRINT 'DROP TABLE MCK_JCOR_UPDATE'
	DROP TABLE MCK_JCOR_UPDATE
end
go

PRINT 'CREATE TABLE MCK_JCOR_UPDATE'
go

CREATE TABLE MCK_JCOR_UPDATE
(
	JCCo			bCompany		NOT null
,	Contract		bContract		NOT null
,	Month			bMonth			NOT NULL DEFAULT ( CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME) )
,	RevCost			bDollar			NOT NULL DEFAULT (0.00)
,	OtherAmount		bDollar			NOT null DEFAULT (0.00)
,	Notes			VARCHAR(MAX)	NULL
)
GO

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE type='U' AND name='JCOR_20141230_BACKUP')
BEGIN
	PRINT 'BACKUP JCOR TABLE'
	SELECT * INTO JCOR_20141230_BACKUP FROM JCOR
END
ELSE
BEGIN
	PRINT 'RESET JCOR VALUES'

	UPDATE JCOR SET 
		RevCost=t1.RevCost, OtherAmount=t1.OtherAmount, Notes=t1.Notes 
	FROM 
		JCOR_20141230_BACKUP t1 
	WHERE
		JCOR.JCCo=t1.JCCo 
	AND JCOR.Contract=t1.Contract 
	AND JCOR.Month=t1.Month 
	AND (JCOR.RevCost <> t1.RevCost OR JCOR.OtherAmount <> t1.OtherAmount or JCOR.Notes<> t1.Notes )
END
go

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE type='U' AND name='JCOP_20141230_BACKUP')
BEGIN
	PRINT 'BACKUP JCOP TABLE'
	SELECT * INTO JCOP_20141230_BACKUP FROM JCOP
END
ELSE
BEGIN
	PRINT 'RESET JCOP VALUES'

	UPDATE JCOP SET 
		ProjCost=t1.ProjCost, OtherAmount=t1.OtherAmount, Notes=t1.Notes 
	FROM 
		JCOP_20141230_BACKUP t1 
	WHERE
		JCOP.JCCo=t1.JCCo 
	AND JCOP.Job=t1.Job 
	AND JCOP.Month=t1.Month 
	AND (JCOP.ProjCost <> t1.ProjCost OR JCOP.OtherAmount <> t1.OtherAmount or JCOP.Notes<> t1.Notes )

END
go

DECLARE @seedMonth SMALLDATETIME
DECLARE @targetMonth SMALLDATETIME
select @seedMonth='10/1/2014',@targetMonth='12/1/2014'

PRINT 'SEED OVERRIDE DATA from ' + CAST(MONTH(@seedMonth) AS VARCHAR(2)) + '/1/' + CAST(YEAR(@seedMonth) AS VARCHAR(4))

INSERT MCK_JCOR_UPDATE ( JCCo,Contract,Month,RevCost,OtherAmount,Notes )
SELECT JCCo,Contract,@targetMonth,RevCost,OtherAmount,null FROM JCOR WHERE Month=@seedMonth AND JCCo < 100

INSERT MCK_JCOP_UPDATE ( JCCo,Job,Month,ProjCost,OtherAmount,Notes )
SELECT JCCo,Job,@targetMonth,ProjCost,OtherAmount,null FROM JCOP WHERE Month=@seedMonth AND JCCo < 100
go

if exists ( select 1 from sysobjects where type='P' and name='MCK_PROCESS_OVERRIDES')
begin
	PRINT 'DROP PROCEDURE MCK_PROCESS_OVERRIDES'
	DROP PROCEDURE MCK_PROCESS_OVERRIDES
end
go

PRINT 'CREATE PROCEDURE MCK_PROCESS_OVERRIDES'
go

CREATE PROCEDURE MCK_PROCESS_OVERRIDES
(
	@Month	bMonth
,	@Reset	bYN = 'N'
,	@DoUpdates	bYN = 'N'
)
AS
BEGIN
	SET NOCOUNT ON 

	IF @Reset IS NULL
		SELECT @Reset='N'

	IF @DoUpdates IS NULL
		SELECT @DoUpdates='N'


	IF @Month IS NULL
		SELECT @Month=CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME)
	ELSE 
		SELECT @Month=CAST(CAST(MONTH(@Month) AS VARCHAR(2)) + '/1/' + CAST(YEAR(@Month) AS VARCHAR(4)) AS SMALLDATETIME)

	--Update Existing Projections to 0 for specified Month
	IF @Reset = 'Y'
	BEGIN
		IF @DoUpdates = 'Y'
		BEGIN
			UPDATE JCOR SET RevCost=0,OtherAmount=0 WHERE JCCo < 100 AND Month=@Month
			UPDATE JCOP SET ProjCost=0,OtherAmount=0 WHERE JCCo < 100 AND Month=@Month
		END
	END

	DECLARE	@srcJCCo			bCompany		--NOT null
	DECLARE	@srcContract		bContract		--NOT null
	DECLARE	@srcJob				bJob		--NOT null
	DECLARE	@srcMonth			bMonth			--NOT NULL DEFAULT ( CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME) )
	DECLARE	@srcCost			bDollar			--NOT NULL DEFAULT (0.00)
	DECLARE	@curCost			bDollar			--NOT NULL DEFAULT (0.00)
	DECLARE	@srcOtherAmount		bDollar			--NOT null DEFAULT (0.00)
	DECLARE	@srcNotes			VARCHAR(MAX)	--NULL

	DECLARE	@staticNotes		VARCHAR(MAX)
	SET @staticNotes = 'JC Override from Accounting for ' + CAST(MONTH(@Month) AS VARCHAR(2)) + '/1/' + CAST(YEAR(@Month) AS VARCHAR(4))

	--Loop through provided values and update/insert as appropriate
	--JCOR
	declare jcorcur CURSOR FOR
	SELECT
		JCCo			--bCompany			NOT null
	,	Contract		--bContract			NOT null
	,	Month			--bMonth			NOT NULL DEFAULT ( CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME) )
	,	RevCost			--bDollar			NOT NULL DEFAULT (0.00)
	,	OtherAmount		--bDollar			NOT null DEFAULT (0.00)
	,	Notes			--VARCHAR(MAX)		NULL
	FROM
		MCK_JCOR_UPDATE
	WHERE
		Month=@Month
	ORDER BY
		JCCo
	,	Contract
	FOR READ ONLY

	PRINT REPLICATE('-',100)
	PRINT 'JC Revenue Overrides ' + CAST(MONTH(@Month) AS VARCHAR(2)) + '/1/' + CAST(YEAR(@Month) AS VARCHAR(4))
	PRINT REPLICATE('-',100)
	PRINT 
		CAST('JCCo' AS CHAR(10))
	+	CAST('Contract' AS CHAR(15))
	+	'Message'
	PRINT REPLICATE('-',100)

	OPEN jcorcur
	FETCH jcorcur INTO
		@srcJCCo			--bCompany		NOT null
	,	@srcContract		--bContract		NOT null
	--,	@srcJob				--bJob			NOT null
	,	@srcMonth			--bMonth		NOT NULL DEFAULT ( CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME) )
	,	@srcCost			--bDollar		NOT NULL DEFAULT (0.00)
	,	@srcOtherAmount		--bDollar		NOT null DEFAULT (0.00)
	,	@srcNotes			--VARCHAR(MAX)	NULL

	WHILE @@FETCH_STATUS=0
	BEGIN
		IF NOT EXISTS ( SELECT 1 FROM JCCM WHERE JCCo=@srcJCCo AND Contract=@srcContract )
		BEGIN
			PRINT 
				CAST(@srcJCCo AS CHAR(10))
			+	CAST(@srcContract AS CHAR(15))
			+	'Contract does not exists.'

			GOTO contractloop
		END

		IF EXISTS ( SELECT 1 FROM JCOR WHERE JCCo=@srcJCCo AND Contract=@srcContract AND Month=@srcMonth )
		BEGIN
			--Update Existing JCOR Record
			SELECT @curCost=RevCost FROM JCOR WHERE JCCo=@srcJCCo AND Contract=@srcContract AND Month=@srcMonth
			IF @curCost <> 0
			BEGIN
				PRINT 
					CAST(@srcJCCo AS CHAR(10))
				+	CAST(@srcContract AS CHAR(15))
				+	'Existing non-zero Revenue Projection Exists'
			END
			ELSE
            BEGIN
				PRINT 
					CAST(@srcJCCo AS CHAR(10))
				+	CAST(@srcContract AS CHAR(15))
				+	'Update Revenue Projection to ' + CAST(@srcCost AS VARCHAR(25))
				IF @DoUpdates = 'Y'
				BEGIN
					UPDATE JCOR SET RevCost=@srcCost, OtherAmount=@srcOtherAmount WHERE JCCo=@srcJCCo AND Contract=@srcContract AND Month=@srcMonth
				END
			END
		END
		ELSE
        begin
			--Insert New JCOR Record
			PRINT 
				CAST(@srcJCCo AS CHAR(10))
			+	CAST(@srcContract AS CHAR(15))
			+	'Insert Revenue Projection of ' + CAST(@srcCost AS VARCHAR(25))
			IF @DoUpdates = 'Y'
			BEGIN
				INSERT JCOR (JCCo,Contract,Month,RevCost,OtherAmount, Notes)
				VALUES (@srcJCCo,@srcContract,@srcMonth,@srcCost,@srcOtherAmount, COALESCE(@srcNotes,@staticNotes,'') )
			END
		END

		contractloop:

		FETCH jcorcur INTO
			@srcJCCo			--bCompany		NOT null
		,	@srcContract		--bContract		NOT null
		--,	@srcJob				--bJob			NOT null
		,	@srcMonth			--bMonth		NOT NULL DEFAULT ( CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME) )
		,	@srcCost			--bDollar		NOT NULL DEFAULT (0.00)
		,	@srcOtherAmount		--bDollar		NOT null DEFAULT (0.00)
		,	@srcNotes			--VARCHAR(MAX)	NULL

	END

	CLOSE jcorcur
	DEALLOCATE jcorcur

	SELECT @srcCost=0,@srcOtherAmount=0

	--JCOP
	declare jcopcur CURSOR FOR
	SELECT
		JCCo			--bCompany		NOT null
	,	Job				--bJob			NOT null
	,	Month			--bMonth			NOT NULL DEFAULT ( CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME) )
	,	ProjCost		--bDollar			NOT NULL DEFAULT (0.00)
	,	OtherAmount		--bDollar			NOT null DEFAULT (0.00)
	,	Notes			--VARCHAR(MAX)	NULL
	FROM
		MCK_JCOP_UPDATE
	ORDER BY
		JCCo
	,	Job
	FOR READ ONLY

	PRINT REPLICATE('-',100)
	PRINT 'JC Cost Overrides ' + CAST(MONTH(@Month) AS VARCHAR(2)) + '/1/' + CAST(YEAR(@Month) AS VARCHAR(4))
	PRINT REPLICATE('-',100)
	PRINT 
		CAST('JCCo' AS CHAR(10))
	+	CAST('Job' AS CHAR(15))
	+	'Message'
	PRINT REPLICATE('-',100)

	OPEN jcopcur
	FETCH jcopcur INTO
		@srcJCCo			--bCompany		NOT null
	--,	@srcContract		--bContract		NOT null
	,	@srcJob				--bJob			NOT null
	,	@srcMonth			--bMonth		NOT NULL DEFAULT ( CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME) )
	,	@srcCost			--bDollar		NOT NULL DEFAULT (0.00)
	,	@srcOtherAmount		--bDollar		NOT null DEFAULT (0.00)
	,	@srcNotes			--VARCHAR(MAX)	NULL

	WHILE @@FETCH_STATUS=0
	BEGIN
		IF NOT EXISTS ( SELECT 1 FROM JCJM WHERE JCCo=@srcJCCo AND Job=@srcJob )
		BEGIN
			PRINT 
				CAST(@srcJCCo AS CHAR(10))
			+	CAST(@srcJob AS CHAR(15))
			+	'Job does not exists.'

			GOTO jobloop
		END

		IF EXISTS ( SELECT 1 FROM JCOP WHERE JCCo=@srcJCCo AND Job=@srcJob AND Month=@srcMonth )
		BEGIN
			--Update Existing JCOR Record
			SELECT @curCost=ProjCost FROM JCOP WHERE JCCo=@srcJCCo AND Job=@srcJob AND Month=@srcMonth
			IF @curCost <> 0
			BEGIN
				PRINT 
					CAST(@srcJCCo AS CHAR(10))
				+	CAST(@srcJob AS CHAR(15))
				+	'Existing non-zero Cost Projection Exists'
			END
			ELSE
            BEGIN
				PRINT 
					CAST(@srcJCCo AS CHAR(10))
				+	CAST(@srcJob AS CHAR(15))
				+	'Update Cost Projection to ' + CAST(@srcCost AS VARCHAR(25))
				
				IF @DoUpdates = 'Y'
				BEGIN
					UPDATE JCOP SET ProjCost=@srcCost, OtherAmount=@srcOtherAmount WHERE JCCo=@srcJCCo AND Job=@srcJob AND Month=@srcMonth
				END
			END
		END
		ELSE
        begin
			--Insert New JCOP Record
			PRINT 
				CAST(@srcJCCo AS CHAR(10))
			+	CAST(@srcJob AS CHAR(15))
			+	'Insert Cost Projection of ' + CAST(@srcCost AS VARCHAR(25))

			IF @DoUpdates = 'Y'
			BEGIN
				INSERT JCOP (JCCo,Job,Month,ProjCost,OtherAmount, Notes)
				VALUES (@srcJCCo,@srcJob,@srcMonth,@srcCost,@srcOtherAmount, COALESCE(@srcNotes,@staticNotes,'') )
			END
		END

		jobloop:

		FETCH jcopcur INTO
			@srcJCCo			--bCompany		NOT null
		--,	@srcContract		--bContract		NOT null
		,	@srcJob				--bJob			NOT null
		,	@srcMonth			--bMonth		NOT NULL DEFAULT ( CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME) )
		,	@srcCost			--bDollar		NOT NULL DEFAULT (0.00)
		,	@srcOtherAmount		--bDollar		NOT null DEFAULT (0.00)
		,	@srcNotes			--VARCHAR(MAX)	NULL

	END

	CLOSE jcopcur
	DEALLOCATE jcopcur

END
GO


PRINT ''
PRINT '1. INSERT SOURCE DATA INTO MCK_JCOR_UPDATE'
PRINT '2. INSERT SOURCE DATA INTO MCK_JCOP_UPDATE'
PRINT '3. EXEC MCK_PROCESS_OVERRIDES @Month=''12/1/2014'', @Reset=''N'', @DoUpdates=''N'''

--SELECT * FROM MCK_JCOR_UPDATE
--SELECT * FROM MCK_JCOP_UPDATE

--EXEC MCK_PROCESS_OVERRIDES @Month='11/1/2014'


EXEC MCK_PROCESS_OVERRIDES @Month='12/1/2014', @Reset='N', @DoUpdates='N'