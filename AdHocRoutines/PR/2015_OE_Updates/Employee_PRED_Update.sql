USE Viewpoint
GO

SELECT 
	preh.PRCo
,	preh.Employee
,	preh.FirstName
,	preh.LastName
,	pred.DLCode
,	prdl.DLType
--,	prdl.DednCode
,	prdl.Description
,	pred.EmplBased	
,	pred.Frequency	
--ProcessSeq	
--FileStatus	
--RegExempts	
--AddExempts	
--OverMiscAmt	
--MiscAmt	
--MiscFactor	
--VendorGroup	
--Vendor	
--APDesc	
,	pred.GLCo	
--OverGLAcct	
,	pred.OverCalcs	-- A (Fixed Amount), N (Inactive)
,	pred.RateAmt	
,	pred.OverLimit	
,	pred.Limit	
--NetPayOpt	
--MinNetPay	
--AddonType	
--AddonRateAmt	
--Notes	
--CSCaseId	
--CSFipsCode	
--CSMedCov	
--EICStatus	
--UniqueAttchID	
--LimitRate	
--CSAllocYN	
--CSAllocGroup	
--MiscAmt2	
--MembershipNumber	
--LifeToDateArrears	
--LifeToDatePayback	
--EligibleForArrearsCalc	
--OverrideStdArrearsThreshold	
--RptArrearsThresholdOverride	
--ThresholdFactorOverride	
--ThresholdAmountOverride	
--OverrideStdPaybackSettings	
--PaybackPerPayPeriodOverride	
--PaybackFactorOverride	
--PaybackAmountOverride	
--SuperWeeklyMin
,	pred.KeyID AS PRED_KeyId
,	pred.RateAmt AS New2015Amount
,	CASE
		WHEN pred.DLCode=106 then pred.Limit
		ELSE 0 
	END AS New2015_106Limit
,	CASE
		WHEN pred.DLCode=107 then pred.Limit
		ELSE 0 
	END AS New2015_107Limit
FROM 
	PREH preh LEFT OUTER JOIN
	PRED pred ON
		preh.PRCo=pred.PRCo
	AND preh.Employee=pred.Employee
	AND preh.ActiveYN='Y'
	AND preh.PRCo < 100
	AND pred.DLCode IN ( 105,112,109,113,108,107,106) JOIN
	PRDL prdl ON
		pred.PRCo=prdl.PRCo
	AND pred.DLCode=prdl.DLCode
ORDER BY
	preh.PRCo
,	preh.Employee
,	pred.DLCode
