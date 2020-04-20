USE Viewpoint
go

IF NOT EXISTS ( SELECT 1 FROM sysobjects WHERE type='U' AND name='PRED_20141229_BACKUP')
BEGIN
PRINT 'BACKUP PRED TABLE'
SELECT * INTO PRED_20141229_BACKUP FROM PRED
END
go

--Update existing PRED Records to "Inactive".  Souce list of deductions is complete and existing need to be deactivated.

BEGIN TRAN

DECLARE @rcnt INT

UPDATE 
	PRED 
SET
	 Frequency='I'
WHERE
	PRCo<100
AND DLCode IN ( 105,112,109,113,108,107,106 ) 
AND Frequency <> 'I'

SELECT @rcnt=@@ROWCOUNT

IF @@ERROR=0
BEGIN
	COMMIT TRAN
	PRINT CAST(@rcnt AS VARCHAR(20)) + ' existing Deducations "Inactivated"'
END
ELSE
BEGIN
	ROLLBACK TRAN 
	PRINT 'No existing Deducations "Inactivated" (tran error rollback)'
END
go

SET NOCOUNT ON

DECLARE empcur CURSOR for
SELECT distinct
	preh.PRCo
,	preh.Employee
,	preh.LastName
,	preh.FirstName
,	preh.ActiveYN
FROM 
	PREH preh 
	JOIN OE2015 oe ON
		preh.PRCo=oe.PRCo
	AND preh.Employee=oe.Employee
	LEFT JOIN PRED pred ON
		preh.PRCo=pred.PRCo
	AND preh.Employee=pred.Employee
WHERE
	preh.PRCo < 100
--AND preh.ActiveYN='Y'
--AND pred.DLCode IN (105,112,109,113,108,107,106)
ORDER BY
	preh.PRCo
,	preh.Employee
FOR READ ONLY

DECLARE @rcnt INT

DECLARE @PRCo		bCompany
DECLARE @Employee	bEmployee
DECLARE @LastName	VARCHAR(30)
DECLARE @FirstName	VARCHAR(30)
DECLARE @ActiveYN	bYN

DECLARE @D105OrigAmt	bUnitCost
DECLARE @D112OrigAmt	bUnitCost
DECLARE @D109OrigAmt	bUnitCost
DECLARE @D113OrigAmt	bUnitCost
DECLARE @D108OrigAmt	bUnitCost
DECLARE @D107OrigAmt	bUnitCost
DECLARE @D107OrigLimit	bUnitCost
DECLARE @D106OrigAmt	bUnitCost
DECLARE @D106OrigLimit	bUnitCost

DECLARE @D105NewAmt	bUnitCost
DECLARE @D112NewAmt	bUnitCost
DECLARE @D109NewAmt	bUnitCost
DECLARE @D113NewAmt	bUnitCost
DECLARE @D108NewAmt	bUnitCost
DECLARE @D107NewAmt	bUnitCost
DECLARE @D107NewLimit	bUnitCost
DECLARE @D106NewAmt	bUnitCost
DECLARE @D106NewLimit	bUnitCost

SELECT @rcnt = 0

PRINT
	CAST('Cnt' AS CHAR(8))
+	CAST('Co' AS CHAR(8))		--bCompany
+	CAST('Employee' AS CHAR(10))	--bEmployee
+	CAST('Active' AS CHAR(8))		--bYN
+	CAST('LastName' AS CHAR(32))	--VARCHAR(30)
+	CAST('FirstName' AS CHAR(32))	--VARCHAR(30)

PRINT REPLICATE('-',100)

OPEN empcur
FETCH empcur INTO
	@PRCo		--bCompany
,	@Employee	--bEmployee
,	@LastName	--VARCHAR(30)
,	@FirstName	--VARCHAR(30)
,	@ActiveYN

WHILE @@fetch_status = 0
BEGIN

	SELECT @rcnt=@rcnt + 1

	PRINT
		CAST(@rcnt AS CHAR(8))
	+	CAST(@PRCo AS CHAR(8))		--bCompany
	+	CAST(@Employee AS CHAR(10))	--bEmployee
	+	CAST(@ActiveYN AS CHAR(8))		--bYN
	+	CAST(@LastName AS CHAR(32))	--VARCHAR(30)
	+	CAST(@FirstName AS CHAR(32))	--VARCHAR(30)

	IF @ActiveYN <> 'Y'
	BEGIN
		PRINT 
				REPLICATE(' ',8)
			+	'* INACTIVE EMPLOYEE '

		GOTO emploop
	END 

	--105,112,109,113,108,107,106

	BEGIN -- DL Code 105
	SELECT @D105NewAmt = D105 FROM OE2015 WHERE PRCo=@PRCo AND Employee=@Employee
	IF EXISTS ( SELECT 1 FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=105)
	BEGIN
		SELECT @D105OrigAmt=RateAmt FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=105
		IF @D105NewAmt<>@D105OrigAmt
		BEGIN
			PRINT 
				REPLICATE(' ',8)
			+	'> Update Deduction 105 to '
			+	CAST(@D105NewAmt AS VARCHAR(20))
			+   ' from '
			+	CAST(@D105OrigAmt AS VARCHAR(20))

			UPDATE PRED SET Frequency='W', OverCalcs='A', RateAmt=@D105NewAmt WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=105
		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 105 - No Change'
			UPDATE PRED SET Frequency='W', OverCalcs='A', RateAmt=@D105NewAmt WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=105
		END
	END
	ELSE
    BEGIN
		IF @D105NewAmt <> 0
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'+ Insert Deduction 105 to '
			+	CAST(@D105NewAmt AS VARCHAR(20))

			INSERT PRED 
			(
				PRCo	
			,	Employee	
			,	DLCode	
			,	EmplBased	
			,	Frequency	
			,	ProcessSeq	
			,	FileStatus	
			,	RegExempts	
			,	AddExempts	
			,	OverMiscAmt	
			,	MiscAmt	
			,	MiscFactor	
			,	VendorGroup	
			,	Vendor	
			,	APDesc	
			,	GLCo	
			,	OverGLAcct	
			,	OverCalcs	
			,	RateAmt	
			,	OverLimit	
			,	Limit	
			,	NetPayOpt	
			,	MinNetPay	
			,	AddonType	
			,	AddonRateAmt	
			,	Notes	
			,	CSCaseId	
			,	CSFipsCode	
			,	CSMedCov	
			,	EICStatus	
			,	UniqueAttchID	
			,	LimitRate	
			,	CSAllocYN	
			,	CSAllocGroup	
			--,	KeyID	
			,	MiscAmt2	
			,	MembershipNumber	
			,	LifeToDateArrears	
			,	LifeToDatePayback	
			,	EligibleForArrearsCalc	
			,	OverrideStdArrearsThreshold	
			,	RptArrearsThresholdOverride	
			,	ThresholdFactorOverride	
			,	ThresholdAmountOverride	
			,	OverrideStdPaybackSettings	
			,	PaybackPerPayPeriodOverride	
			,	PaybackFactorOverride	
			,	PaybackAmountOverride	
			,	udSource	
			,	udConv	
			,	udCGCTable	
			,	udCGCTableID	
			,	SuperWeeklyMin
			)
			values
			(
				@PRCo		--PRCo	
			,	@Employee	--Employee
			,	105			--DLCode	
			,	'Y'			--EmplBased	
			,	'W'			--Frequency	
			,	1			--ProcessSeq	
			,	null		--FileStatus	
			,	null		--RegExempts	
			,	null		--AddExempts	
			,	'N'			--OverMiscAmt	
			,	0.00		--MiscAmt	
			,	null		--MiscFactor	
			,	null		--VendorGroup	
			,	null		--Vendor	
			,	null		--APDesc	
			,	@PRCo		--GLCo	
			,	null		--OverGLAcct	
			,	'A'			--OverCalcs	
			,	@D105NewAmt		--RateAmt	
			,	'N'			--OverLimit	
			,	0.00		--Limit	
			,	'N'		--NetPayOpt	
			,	null		--MinNetPay	
			,	'N'		--AddonType	
			,	0.00		--AddonRateAmt	
			,	'2015 OE [LWO as per LW)'		--Notes	
			,	null		--CSCaseId	
			,	null		--CSFipsCode	
			,	'N'		--CSMedCov	
			,	null		--EICStatus	
			,	null		--UniqueAttchID	
			,	null		--LimitRate	
			,	'N'		--CSAllocYN	
			,	null		--CSAllocGroup	
			--,	null		--KeyID	
			,	0.00		--MiscAmt2	
			,	null		--MembershipNumber	
			,	0.00		--LifeToDateArrears	
			,	0.00		--LifeToDatePayback	
			,	'N'		--EligibleForArrearsCalc	
			,	'N'		--OverrideStdArrearsThreshold	
			,	'F'		--RptArrearsThresholdOverride	
			,	0.000000		--ThresholdFactorOverride	
			,	0.00		--ThresholdAmountOverride	
			,	'N'		--OverrideStdPaybackSettings	
			,	'F'		--PaybackPerPayPeriodOverride	
			,	0.000000		--PaybackFactorOverride	
			,	0.00		--PaybackAmountOverride	
			,	null		--udSource	
			,	'N'		--udConv	
			,	null		--udCGCTable	
			,	null		--udCGCTableID	
			,	0.00		--SuperWeeklyMin
			)

--			SELECT * FROM PRED WHERE DLCode=105 AND PRCo<100
		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 105 - No Value to Add'
		END
	END
	END -- DL Code 105

	BEGIN -- DL Code 112
	SELECT @D112NewAmt = D112 FROM OE2015 WHERE PRCo=@PRCo AND Employee=@Employee
	IF EXISTS ( SELECT 1 FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=112)
	BEGIN
		SELECT @D112OrigAmt=RateAmt FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=112
		IF @D112NewAmt <> @D112OrigAmt
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'> Update Deduction 112 to '
			+	CAST(@D112NewAmt AS VARCHAR(20))
			+   ' from '
			+	CAST(@D112OrigAmt AS VARCHAR(20))

			UPDATE PRED SET Frequency='W', OverCalcs='A', RateAmt=@D112NewAmt WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=112
		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 112 - No Change'
			UPDATE PRED SET Frequency='W', OverCalcs='A', RateAmt=@D112NewAmt WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=112
		END
	END
	ELSE
    BEGIN
		IF @D112NewAmt <> 0
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'+ Insert Deduction 112 to '
			+	CAST(@D112NewAmt AS VARCHAR(20))

			INSERT PRED 
			(
				PRCo	
			,	Employee	
			,	DLCode	
			,	EmplBased	
			,	Frequency	
			,	ProcessSeq	
			,	FileStatus	
			,	RegExempts	
			,	AddExempts	
			,	OverMiscAmt	
			,	MiscAmt	
			,	MiscFactor	
			,	VendorGroup	
			,	Vendor	
			,	APDesc	
			,	GLCo	
			,	OverGLAcct	
			,	OverCalcs	
			,	RateAmt	
			,	OverLimit	
			,	Limit	
			,	NetPayOpt	
			,	MinNetPay	
			,	AddonType	
			,	AddonRateAmt	
			,	Notes	
			,	CSCaseId	
			,	CSFipsCode	
			,	CSMedCov	
			,	EICStatus	
			,	UniqueAttchID	
			,	LimitRate	
			,	CSAllocYN	
			,	CSAllocGroup	
			--,	KeyID	
			,	MiscAmt2	
			,	MembershipNumber	
			,	LifeToDateArrears	
			,	LifeToDatePayback	
			,	EligibleForArrearsCalc	
			,	OverrideStdArrearsThreshold	
			,	RptArrearsThresholdOverride	
			,	ThresholdFactorOverride	
			,	ThresholdAmountOverride	
			,	OverrideStdPaybackSettings	
			,	PaybackPerPayPeriodOverride	
			,	PaybackFactorOverride	
			,	PaybackAmountOverride	
			,	udSource	
			,	udConv	
			,	udCGCTable	
			,	udCGCTableID	
			,	SuperWeeklyMin
			)
			values
			(
				@PRCo		--PRCo	
			,	@Employee	--Employee
			,	112			--DLCode	
			,	'Y'			--EmplBased	
			,	'W'			--Frequency	
			,	1			--ProcessSeq	
			,	null		--FileStatus	
			,	null		--RegExempts	
			,	null		--AddExempts	
			,	'N'			--OverMiscAmt	
			,	0.00		--MiscAmt	
			,	null		--MiscFactor	
			,	null		--VendorGroup	
			,	null		--Vendor	
			,	null		--APDesc	
			,	@PRCo		--GLCo	
			,	null		--OverGLAcct	
			,	'A'			--OverCalcs	
			,	@D112NewAmt		--RateAmt	
			,	'N'			--OverLimit	
			,	0.00		--Limit	
			,	'N'		--NetPayOpt	
			,	null		--MinNetPay	
			,	'N'		--AddonType	
			,	0.00		--AddonRateAmt	
			,	'2015 OE [LWO as per LW)'		--Notes	
			,	null		--CSCaseId	
			,	null		--CSFipsCode	
			,	'N'		--CSMedCov	
			,	null		--EICStatus	
			,	null		--UniqueAttchID	
			,	null		--LimitRate	
			,	'N'		--CSAllocYN	
			,	null		--CSAllocGroup	
			--,	null		--KeyID	
			,	0.00		--MiscAmt2	
			,	null		--MembershipNumber	
			,	0.00		--LifeToDateArrears	
			,	0.00		--LifeToDatePayback	
			,	'N'		--EligibleForArrearsCalc	
			,	'N'		--OverrideStdArrearsThreshold	
			,	'F'		--RptArrearsThresholdOverride	
			,	0.000000		--ThresholdFactorOverride	
			,	0.00		--ThresholdAmountOverride	
			,	'N'		--OverrideStdPaybackSettings	
			,	'F'		--PaybackPerPayPeriodOverride	
			,	0.000000		--PaybackFactorOverride	
			,	0.00		--PaybackAmountOverride	
			,	null		--udSource	
			,	'N'		--udConv	
			,	null		--udCGCTable	
			,	null		--udCGCTableID	
			,	0.00		--SuperWeeklyMin
			)

		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 112 - No Value to Add'
		END
	END
	END -- DL Code 112

	BEGIN -- DL Code 109
	SELECT @D109NewAmt = D109 FROM OE2015 WHERE PRCo=@PRCo AND Employee=@Employee
	IF EXISTS ( SELECT 1 FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=109)
	BEGIN
		SELECT @D109OrigAmt=RateAmt FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=109
		IF @D109NewAmt <> @D109OrigAmt
		BEGIN
			PRINT 
				REPLICATE(' ',8)
			+	'> Update Deduction 109 to '
			+	CAST(@D109NewAmt AS VARCHAR(20))
			+   ' from '
			+	CAST(@D109OrigAmt AS VARCHAR(20))

			UPDATE PRED SET Frequency='W', OverCalcs='A', RateAmt=@D109NewAmt WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=109
		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 109 - No Change'
			UPDATE PRED SET Frequency='W', OverCalcs='A', RateAmt=@D109NewAmt WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=109
		END
	END
	ELSE
    BEGIN
		IF @D109NewAmt <> 0
		BEGIN
			PRINT 
				REPLICATE(' ',8)
			+	'+ Insert Deduction 109 to '
			+	CAST(@D109NewAmt AS VARCHAR(20))

			INSERT PRED 
			(
				PRCo	
			,	Employee	
			,	DLCode	
			,	EmplBased	
			,	Frequency	
			,	ProcessSeq	
			,	FileStatus	
			,	RegExempts	
			,	AddExempts	
			,	OverMiscAmt	
			,	MiscAmt	
			,	MiscFactor	
			,	VendorGroup	
			,	Vendor	
			,	APDesc	
			,	GLCo	
			,	OverGLAcct	
			,	OverCalcs	
			,	RateAmt	
			,	OverLimit	
			,	Limit	
			,	NetPayOpt	
			,	MinNetPay	
			,	AddonType	
			,	AddonRateAmt	
			,	Notes	
			,	CSCaseId	
			,	CSFipsCode	
			,	CSMedCov	
			,	EICStatus	
			,	UniqueAttchID	
			,	LimitRate	
			,	CSAllocYN	
			,	CSAllocGroup	
			--,	KeyID	
			,	MiscAmt2	
			,	MembershipNumber	
			,	LifeToDateArrears	
			,	LifeToDatePayback	
			,	EligibleForArrearsCalc	
			,	OverrideStdArrearsThreshold	
			,	RptArrearsThresholdOverride	
			,	ThresholdFactorOverride	
			,	ThresholdAmountOverride	
			,	OverrideStdPaybackSettings	
			,	PaybackPerPayPeriodOverride	
			,	PaybackFactorOverride	
			,	PaybackAmountOverride	
			,	udSource	
			,	udConv	
			,	udCGCTable	
			,	udCGCTableID	
			,	SuperWeeklyMin
			)
			values
			(
				@PRCo		--PRCo	
			,	@Employee	--Employee
			,	109			--DLCode	
			,	'Y'			--EmplBased	
			,	'W'			--Frequency	
			,	1			--ProcessSeq	
			,	null		--FileStatus	
			,	null		--RegExempts	
			,	null		--AddExempts	
			,	'N'			--OverMiscAmt	
			,	0.00		--MiscAmt	
			,	null		--MiscFactor	
			,	null		--VendorGroup	
			,	null		--Vendor	
			,	null		--APDesc	
			,	@PRCo		--GLCo	
			,	null		--OverGLAcct	
			,	'A'			--OverCalcs	
			,	@D109NewAmt		--RateAmt	
			,	'N'			--OverLimit	
			,	0.00		--Limit	
			,	'N'		--NetPayOpt	
			,	null		--MinNetPay	
			,	'N'		--AddonType	
			,	0.00		--AddonRateAmt	
			,	'2015 OE [LWO as per LW)'		--Notes	
			,	null		--CSCaseId	
			,	null		--CSFipsCode	
			,	'N'		--CSMedCov	
			,	null		--EICStatus	
			,	null		--UniqueAttchID	
			,	null		--LimitRate	
			,	'N'		--CSAllocYN	
			,	null		--CSAllocGroup	
			--,	null		--KeyID	
			,	0.00		--MiscAmt2	
			,	null		--MembershipNumber	
			,	0.00		--LifeToDateArrears	
			,	0.00		--LifeToDatePayback	
			,	'N'		--EligibleForArrearsCalc	
			,	'N'		--OverrideStdArrearsThreshold	
			,	'F'		--RptArrearsThresholdOverride	
			,	0.000000		--ThresholdFactorOverride	
			,	0.00		--ThresholdAmountOverride	
			,	'N'		--OverrideStdPaybackSettings	
			,	'F'		--PaybackPerPayPeriodOverride	
			,	0.000000		--PaybackFactorOverride	
			,	0.00		--PaybackAmountOverride	
			,	null		--udSource	
			,	'N'		--udConv	
			,	null		--udCGCTable	
			,	null		--udCGCTableID	
			,	0.00		--SuperWeeklyMin
			)

		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 109 - No Value to Add'
		END
	END
	END -- DL Code 109

	BEGIN -- DL Code 113
	SELECT @D113NewAmt = D113 FROM OE2015 WHERE PRCo=@PRCo AND Employee=@Employee
	IF EXISTS ( SELECT 1 FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=113)
	BEGIN
		SELECT @D113OrigAmt=RateAmt FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=113
		IF @D113NewAmt <> @D113OrigAmt
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'> Update Deduction 113 to '
			+	CAST(@D113NewAmt AS VARCHAR(20))
			+   ' from '
			+	CAST(@D113OrigAmt AS VARCHAR(20))

			UPDATE PRED SET Frequency='W', OverCalcs='A', RateAmt=@D113NewAmt WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=113
		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 113 - No Change'
			UPDATE PRED SET Frequency='W', OverCalcs='A', RateAmt=@D113NewAmt WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=113
		END
	END
	ELSE
    BEGIN
		IF @D113NewAmt<>0
		BEGIN
			PRINT 
				REPLICATE(' ',8)
			+	'+ Insert Deduction 113 to '
			+	CAST(@D113NewAmt AS VARCHAR(20))

			
			INSERT PRED 
			(
				PRCo	
			,	Employee	
			,	DLCode	
			,	EmplBased	
			,	Frequency	
			,	ProcessSeq	
			,	FileStatus	
			,	RegExempts	
			,	AddExempts	
			,	OverMiscAmt	
			,	MiscAmt	
			,	MiscFactor	
			,	VendorGroup	
			,	Vendor	
			,	APDesc	
			,	GLCo	
			,	OverGLAcct	
			,	OverCalcs	
			,	RateAmt	
			,	OverLimit	
			,	Limit	
			,	NetPayOpt	
			,	MinNetPay	
			,	AddonType	
			,	AddonRateAmt	
			,	Notes	
			,	CSCaseId	
			,	CSFipsCode	
			,	CSMedCov	
			,	EICStatus	
			,	UniqueAttchID	
			,	LimitRate	
			,	CSAllocYN	
			,	CSAllocGroup	
			--,	KeyID	
			,	MiscAmt2	
			,	MembershipNumber	
			,	LifeToDateArrears	
			,	LifeToDatePayback	
			,	EligibleForArrearsCalc	
			,	OverrideStdArrearsThreshold	
			,	RptArrearsThresholdOverride	
			,	ThresholdFactorOverride	
			,	ThresholdAmountOverride	
			,	OverrideStdPaybackSettings	
			,	PaybackPerPayPeriodOverride	
			,	PaybackFactorOverride	
			,	PaybackAmountOverride	
			,	udSource	
			,	udConv	
			,	udCGCTable	
			,	udCGCTableID	
			,	SuperWeeklyMin
			)
			values
			(
				@PRCo		--PRCo	
			,	@Employee	--Employee
			,	113			--DLCode	
			,	'Y'			--EmplBased	
			,	'W'			--Frequency	
			,	1			--ProcessSeq	
			,	null		--FileStatus	
			,	null		--RegExempts	
			,	null		--AddExempts	
			,	'N'			--OverMiscAmt	
			,	0.00		--MiscAmt	
			,	null		--MiscFactor	
			,	null		--VendorGroup	
			,	null		--Vendor	
			,	null		--APDesc	
			,	@PRCo		--GLCo	
			,	null		--OverGLAcct	
			,	'A'			--OverCalcs	
			,	@D113NewAmt		--RateAmt	
			,	'N'			--OverLimit	
			,	0.00		--Limit	
			,	'N'		--NetPayOpt	
			,	null		--MinNetPay	
			,	'N'		--AddonType	
			,	0.00		--AddonRateAmt	
			,	'2015 OE [LWO as per LW)'		--Notes	
			,	null		--CSCaseId	
			,	null		--CSFipsCode	
			,	'N'		--CSMedCov	
			,	null		--EICStatus	
			,	null		--UniqueAttchID	
			,	null		--LimitRate	
			,	'N'		--CSAllocYN	
			,	null		--CSAllocGroup	
			--,	null		--KeyID	
			,	0.00		--MiscAmt2	
			,	null		--MembershipNumber	
			,	0.00		--LifeToDateArrears	
			,	0.00		--LifeToDatePayback	
			,	'N'		--EligibleForArrearsCalc	
			,	'N'		--OverrideStdArrearsThreshold	
			,	'F'		--RptArrearsThresholdOverride	
			,	0.000000		--ThresholdFactorOverride	
			,	0.00		--ThresholdAmountOverride	
			,	'N'		--OverrideStdPaybackSettings	
			,	'F'		--PaybackPerPayPeriodOverride	
			,	0.000000		--PaybackFactorOverride	
			,	0.00		--PaybackAmountOverride	
			,	null		--udSource	
			,	'N'		--udConv	
			,	null		--udCGCTable	
			,	null		--udCGCTableID	
			,	0.00		--SuperWeeklyMin
			)

--select * from PRED where PRCo<100 and DLCode=113

		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 113 - No Value to Add'
		END
	END
	END -- DL Code 113

	BEGIN -- DL Code 108
	SELECT @D108NewAmt = D108 FROM OE2015 WHERE PRCo=@PRCo AND Employee=@Employee
	IF EXISTS ( SELECT 1 FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=108)
	BEGIN
		SELECT @D108OrigAmt=RateAmt FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=108
		IF @D108NewAmt<>@D108OrigAmt
		BEGIN
			PRINT 
				REPLICATE(' ',8)
			+	'> Update Deduction 108 to '
			+	CAST(@D108NewAmt AS VARCHAR(20))
			+   ' from '
			+	CAST(@D108OrigAmt AS VARCHAR(20))

			UPDATE PRED SET Frequency='W', OverCalcs='A', RateAmt=@D108NewAmt WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=108
		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 108 - No Change'

			UPDATE PRED SET Frequency='W', OverCalcs='A', RateAmt=@D108NewAmt WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=108
		END
	END
	ELSE
    BEGIN
		IF @D108NewAmt <> 0
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'+ Insert Deduction 108 to '
			+	CAST(@D108NewAmt AS VARCHAR(20))

						
			INSERT PRED 
			(
				PRCo	
			,	Employee	
			,	DLCode	
			,	EmplBased	
			,	Frequency	
			,	ProcessSeq	
			,	FileStatus	
			,	RegExempts	
			,	AddExempts	
			,	OverMiscAmt	
			,	MiscAmt	
			,	MiscFactor	
			,	VendorGroup	
			,	Vendor	
			,	APDesc	
			,	GLCo	
			,	OverGLAcct	
			,	OverCalcs	
			,	RateAmt	
			,	OverLimit	
			,	Limit	
			,	NetPayOpt	
			,	MinNetPay	
			,	AddonType	
			,	AddonRateAmt	
			,	Notes	
			,	CSCaseId	
			,	CSFipsCode	
			,	CSMedCov	
			,	EICStatus	
			,	UniqueAttchID	
			,	LimitRate	
			,	CSAllocYN	
			,	CSAllocGroup	
			--,	KeyID	
			,	MiscAmt2	
			,	MembershipNumber	
			,	LifeToDateArrears	
			,	LifeToDatePayback	
			,	EligibleForArrearsCalc	
			,	OverrideStdArrearsThreshold	
			,	RptArrearsThresholdOverride	
			,	ThresholdFactorOverride	
			,	ThresholdAmountOverride	
			,	OverrideStdPaybackSettings	
			,	PaybackPerPayPeriodOverride	
			,	PaybackFactorOverride	
			,	PaybackAmountOverride	
			,	udSource	
			,	udConv	
			,	udCGCTable	
			,	udCGCTableID	
			,	SuperWeeklyMin
			)
			values
			(
				@PRCo		--PRCo	
			,	@Employee	--Employee
			,	108			--DLCode	
			,	'Y'			--EmplBased	
			,	'W'			--Frequency	
			,	1			--ProcessSeq	
			,	null		--FileStatus	
			,	null		--RegExempts	
			,	null		--AddExempts	
			,	'N'			--OverMiscAmt	
			,	0.00		--MiscAmt	
			,	null		--MiscFactor	
			,	null		--VendorGroup	
			,	null		--Vendor	
			,	null		--APDesc	
			,	@PRCo		--GLCo	
			,	null		--OverGLAcct	
			,	'A'			--OverCalcs	
			,	@D108NewAmt		--RateAmt	
			,	'N'			--OverLimit	
			,	0.00		--Limit	
			,	'N'		--NetPayOpt	
			,	null		--MinNetPay	
			,	'N'		--AddonType	
			,	0.00		--AddonRateAmt	
			,	'2015 OE [LWO as per LW)'		--Notes	
			,	null		--CSCaseId	
			,	null		--CSFipsCode	
			,	'N'		--CSMedCov	
			,	null		--EICStatus	
			,	null		--UniqueAttchID	
			,	null		--LimitRate	
			,	'N'		--CSAllocYN	
			,	null		--CSAllocGroup	
			--,	null		--KeyID	
			,	0.00		--MiscAmt2	
			,	null		--MembershipNumber	
			,	0.00		--LifeToDateArrears	
			,	0.00		--LifeToDatePayback	
			,	'N'		--EligibleForArrearsCalc	
			,	'N'		--OverrideStdArrearsThreshold	
			,	'F'		--RptArrearsThresholdOverride	
			,	0.000000		--ThresholdFactorOverride	
			,	0.00		--ThresholdAmountOverride	
			,	'N'		--OverrideStdPaybackSettings	
			,	'F'		--PaybackPerPayPeriodOverride	
			,	0.000000		--PaybackFactorOverride	
			,	0.00		--PaybackAmountOverride	
			,	null		--udSource	
			,	'N'		--udConv	
			,	null		--udCGCTable	
			,	null		--udCGCTableID	
			,	0.00		--SuperWeeklyMin
			)

		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 108 - No Value to Add'
		END
	END
	END -- DL Code 108

	BEGIN -- DL Code 107
	SELECT @D107NewAmt = D107, @D107NewLimit=D107Limit FROM OE2015 WHERE PRCo=@PRCo AND Employee=@Employee
	IF EXISTS ( SELECT 1 FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=107)
	BEGIN
		SELECT @D107OrigAmt=RateAmt, @D107OrigLimit=Limit FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=107
		IF ( @D107NewAmt <> @D107OrigAmt ) OR ( @D107NewLimit <> @D107OrigLimit )
		BEGIN
			PRINT 
				REPLICATE(' ',8)
			+	'> Update Deduction 107 to '
			+	CAST(@D107NewAmt AS VARCHAR(20))
			+   ' from '
			+	CAST(@D107OrigAmt AS VARCHAR(20))
			+	' LIMIT to ' 
			+	CAST(@D107NewLimit AS VARCHAR(20))
			+   ' from '
			+	CAST(@D107OrigLimit AS VARCHAR(20))

			UPDATE 
				PRED 
			SET 
				Frequency='W'
			,	OverCalcs='A'
			,	RateAmt=@D107NewAmt
			,	Limit=@D107NewLimit
			,	OverLimit =   
				CASE 
					when @D107NewLimit <> 0 then 'Y'
					else 'N'
				END
			WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=107
		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 107 - No Change'

			UPDATE 
				PRED 
			SET 
				Frequency='W'
			,	OverCalcs='A'
			,	RateAmt=@D107NewAmt
			,	Limit=@D107NewLimit
			,	OverLimit =   
				CASE 
					when @D107NewLimit <> 0 then 'Y'
					else 'N'
				END
			WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=107
		END
	END
	ELSE
    BEGIN
		IF @D107NewAmt <> 0 OR @D107NewLimit <> 0
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'+ Insert Deduction 107 to '
			+	CAST(@D107NewAmt AS VARCHAR(20))
			+	' with LIMIT '
			+	CAST(@D107NewLimit AS VARCHAR(20))

						
			INSERT PRED 
			(
				PRCo	
			,	Employee	
			,	DLCode	
			,	EmplBased	
			,	Frequency	
			,	ProcessSeq	
			,	FileStatus	
			,	RegExempts	
			,	AddExempts	
			,	OverMiscAmt	
			,	MiscAmt	
			,	MiscFactor	
			,	VendorGroup	
			,	Vendor	
			,	APDesc	
			,	GLCo	
			,	OverGLAcct	
			,	OverCalcs	
			,	RateAmt	
			,	OverLimit	
			,	Limit	
			,	NetPayOpt	
			,	MinNetPay	
			,	AddonType	
			,	AddonRateAmt	
			,	Notes	
			,	CSCaseId	
			,	CSFipsCode	
			,	CSMedCov	
			,	EICStatus	
			,	UniqueAttchID	
			,	LimitRate	
			,	CSAllocYN	
			,	CSAllocGroup	
			--,	KeyID	
			,	MiscAmt2	
			,	MembershipNumber	
			,	LifeToDateArrears	
			,	LifeToDatePayback	
			,	EligibleForArrearsCalc	
			,	OverrideStdArrearsThreshold	
			,	RptArrearsThresholdOverride	
			,	ThresholdFactorOverride	
			,	ThresholdAmountOverride	
			,	OverrideStdPaybackSettings	
			,	PaybackPerPayPeriodOverride	
			,	PaybackFactorOverride	
			,	PaybackAmountOverride	
			,	udSource	
			,	udConv	
			,	udCGCTable	
			,	udCGCTableID	
			,	SuperWeeklyMin
			)
			select
				@PRCo		--PRCo	
			,	@Employee	--Employee
			,	107			--DLCode	
			,	'Y'			--EmplBased	
			,	'W'			--Frequency	
			,	1			--ProcessSeq	
			,	null		--FileStatus	
			,	null		--RegExempts	
			,	null		--AddExempts	
			,	'N'			--OverMiscAmt	
			,	0.00		--MiscAmt	
			,	null		--MiscFactor	
			,	null		--VendorGroup	
			,	null		--Vendor	
			,	null		--APDesc	
			,	@PRCo		--GLCo	
			,	null		--OverGLAcct	
			,	'A'			--OverCalcs	
			,	@D107NewAmt		--RateAmt	
			,	CASE when @D107NewLimit <> 0 then 'Y' ELSE 'N' END			--OverLimit	
			,	@D107NewLimit		--Limit	
			,	'N'		--NetPayOpt	
			,	null		--MinNetPay	
			,	'N'		--AddonType	
			,	0.00		--AddonRateAmt	
			,	'2015 OE [LWO as per LW)'		--Notes	
			,	null		--CSCaseId	
			,	null		--CSFipsCode	
			,	'N'		--CSMedCov	
			,	null		--EICStatus	
			,	null		--UniqueAttchID	
			,	null		--LimitRate	
			,	'N'		--CSAllocYN	
			,	null		--CSAllocGroup	
			--,	null		--KeyID	
			,	0.00		--MiscAmt2	
			,	null		--MembershipNumber	
			,	0.00		--LifeToDateArrears	
			,	0.00		--LifeToDatePayback	
			,	'N'		--EligibleForArrearsCalc	
			,	'N'		--OverrideStdArrearsThreshold	
			,	'F'		--RptArrearsThresholdOverride	
			,	0.000000		--ThresholdFactorOverride	
			,	0.00		--ThresholdAmountOverride	
			,	'N'		--OverrideStdPaybackSettings	
			,	'F'		--PaybackPerPayPeriodOverride	
			,	0.000000		--PaybackFactorOverride	
			,	0.00		--PaybackAmountOverride	
			,	null		--udSource	
			,	'N'		--udConv	
			,	null		--udCGCTable	
			,	null		--udCGCTableID	
			,	0.00		--SuperWeeklyMin

		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 107 - No Value to Add'
		END
	END
	END -- DL Code 107

	BEGIN -- DL Code 106
	SELECT @D106NewAmt = D106, @D106NewLimit=D106Limit FROM OE2015 WHERE PRCo=@PRCo AND Employee=@Employee
	IF EXISTS ( SELECT 1 FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=106)
	BEGIN
		SELECT @D106OrigAmt=RateAmt, @D106OrigLimit=Limit FROM PRED WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=106
		IF ( @D106NewAmt <> @D106OrigAmt ) OR ( @D106NewLimit <> @D106OrigLimit )
		BEGIN
			PRINT 
				REPLICATE(' ',8)
			+	'> Update Deduction 106 to '
			+	CAST(@D106NewAmt AS VARCHAR(20))
			+   ' from '
			+	CAST(@D106OrigAmt AS VARCHAR(20))
			+	' LIMIT to ' 
			+	CAST(@D106NewLimit AS VARCHAR(20))
			+   ' from '
			+	CAST(@D106OrigLimit AS VARCHAR(20))

			UPDATE 
				PRED 
			SET 
				Frequency='W'
			,	OverCalcs='A'
			,	RateAmt=@D106NewAmt
			,	Limit=@D106NewLimit
			,	OverLimit =   
				CASE 
					when @D106NewLimit <> 0 then 'Y'
					else 'N'
				END
			WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=106

		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 106 - No Change'

			UPDATE 
				PRED 
			SET 
				Frequency='W'
			,	OverCalcs='A'
			,	RateAmt=@D106NewAmt
			,	Limit=@D106NewLimit
			,	OverLimit =   
				CASE 
					when @D106NewLimit <> 0 then 'Y'
					else 'N'
				END
			WHERE PRCo=@PRCo AND Employee=@Employee AND DLCode=106

		END
	END
	ELSE
    BEGIN
		IF @D106NewAmt <> 0 OR @D106NewLimit <> 0
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'+ Insert Deduction 106 to '
			+	CAST(@D106NewAmt AS VARCHAR(20))
			+	' with LIMIT '
			+	CAST(@D106NewLimit AS VARCHAR(20))

									
			INSERT PRED 
			(
				PRCo	
			,	Employee	
			,	DLCode	
			,	EmplBased	
			,	Frequency	
			,	ProcessSeq	
			,	FileStatus	
			,	RegExempts	
			,	AddExempts	
			,	OverMiscAmt	
			,	MiscAmt	
			,	MiscFactor	
			,	VendorGroup	
			,	Vendor	
			,	APDesc	
			,	GLCo	
			,	OverGLAcct	
			,	OverCalcs	
			,	RateAmt	
			,	OverLimit	
			,	Limit	
			,	NetPayOpt	
			,	MinNetPay	
			,	AddonType	
			,	AddonRateAmt	
			,	Notes	
			,	CSCaseId	
			,	CSFipsCode	
			,	CSMedCov	
			,	EICStatus	
			,	UniqueAttchID	
			,	LimitRate	
			,	CSAllocYN	
			,	CSAllocGroup	
			--,	KeyID	
			,	MiscAmt2	
			,	MembershipNumber	
			,	LifeToDateArrears	
			,	LifeToDatePayback	
			,	EligibleForArrearsCalc	
			,	OverrideStdArrearsThreshold	
			,	RptArrearsThresholdOverride	
			,	ThresholdFactorOverride	
			,	ThresholdAmountOverride	
			,	OverrideStdPaybackSettings	
			,	PaybackPerPayPeriodOverride	
			,	PaybackFactorOverride	
			,	PaybackAmountOverride	
			,	udSource	
			,	udConv	
			,	udCGCTable	
			,	udCGCTableID	
			,	SuperWeeklyMin
			)
			select
				@PRCo		--PRCo	
			,	@Employee	--Employee
			,	106			--DLCode	
			,	'Y'			--EmplBased	
			,	'W'			--Frequency	
			,	1			--ProcessSeq	
			,	null		--FileStatus	
			,	null		--RegExempts	
			,	null		--AddExempts	
			,	'N'			--OverMiscAmt	
			,	0.00		--MiscAmt	
			,	null		--MiscFactor	
			,	null		--VendorGroup	
			,	null		--Vendor	
			,	null		--APDesc	
			,	@PRCo		--GLCo	
			,	null		--OverGLAcct	
			,	'A'			--OverCalcs	
			,	@D106NewAmt		--RateAmt	
			,	CASE when @D106NewLimit <> 0 then 'Y' ELSE 'N' END			--OverLimit	
			,	@D106NewLimit		--Limit	
			,	'N'		--NetPayOpt	
			,	null		--MinNetPay	
			,	'N'		--AddonType	
			,	0.00		--AddonRateAmt	
			,	'2015 OE [LWO as per LW)'		--Notes	
			,	null		--CSCaseId	
			,	null		--CSFipsCode	
			,	'N'		--CSMedCov	
			,	null		--EICStatus	
			,	null		--UniqueAttchID	
			,	null		--LimitRate	
			,	'N'		--CSAllocYN	
			,	null		--CSAllocGroup	
			--,	null		--KeyID	
			,	0.00		--MiscAmt2	
			,	null		--MembershipNumber	
			,	0.00		--LifeToDateArrears	
			,	0.00		--LifeToDatePayback	
			,	'N'		--EligibleForArrearsCalc	
			,	'N'		--OverrideStdArrearsThreshold	
			,	'F'		--RptArrearsThresholdOverride	
			,	0.000000		--ThresholdFactorOverride	
			,	0.00		--ThresholdAmountOverride	
			,	'N'		--OverrideStdPaybackSettings	
			,	'F'		--PaybackPerPayPeriodOverride	
			,	0.000000		--PaybackFactorOverride	
			,	0.00		--PaybackAmountOverride	
			,	null		--udSource	
			,	'N'		--udConv	
			,	null		--udCGCTable	
			,	null		--udCGCTableID	
			,	0.00		--SuperWeeklyMin

		END
		ELSE
		BEGIN 
			PRINT 
				REPLICATE(' ',8)
			+	'Deduction 106 - No Value to Add'
		END
	END
	END -- DL Code 106

	emploop:

	PRINT ' '

select
	@D105OrigAmt	=0
,	@D112OrigAmt	=0
,	@D109OrigAmt	=0
,	@D113OrigAmt	=0
,	@D108OrigAmt	=0
,	@D107OrigAmt	=0
,	@D107OrigLimit	=0
,	@D106OrigAmt	=0
,	@D106OrigLimit	=0
,	@D105NewAmt	=0
,	@D112NewAmt	=0
,	@D109NewAmt	=0
,	@D113NewAmt	=0
,	@D108NewAmt	=0
,	@D107NewAmt	=0
,	@D107NewLimit=0	
,	@D106NewAmt	=0
,	@D106NewLimit=0	

	FETCH empcur INTO
		@PRCo		--bCompany
	,	@Employee	--bEmployee
	,	@LastName	--VARCHAR(30)
	,	@FirstName	--VARCHAR(30)
	,	@ActiveYN
END

CLOSE empcur
DEALLOCATE empcur
GO

