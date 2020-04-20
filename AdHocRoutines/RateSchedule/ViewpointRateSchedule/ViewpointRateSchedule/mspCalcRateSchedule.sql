IF EXISTS (SELECT 1 FROM sysobjects WHERE type='P' AND name='mspCalcRateSchedule')
BEGIN
	PRINT 'DROP PROCEDURE mspCalcRateSchedule'
	DROP PROCEDURE mspCalcRateSchedule
END
go

PRINT 'CREATE PROCEDURE mspCalcRateSchedule'
go

CREATE PROCEDURE mspCalcRateSchedule
(
	@inCompany			bCompany		= NULL 
,	@inCraft			bCraft			= NULL
,	@inClass			bClass			= NULL
,	@inEffectiveDate	bDate			= NULL
,	@inContract			bContract		= NULL
,	@inEmployee			bEmployee		= NULL
)

AS


SET NOCOUNT ON

IF @inEffectiveDate IS NULL
	SELECT @inEffectiveDate = CAST(GETDATE() AS SMALLDATETIME)

IF @inCompany IS NOT NULL AND @inEmployee IS NOT NULL
BEGIN
	SELECT
		@inCompany=PRCo
	,	@inCraft=Craft
	,	@inClass=Class
	FROM
		dbo.PREHFullName
	WHERE
		PRCo=@inCompany
	AND Employee=@inEmployee
END

DECLARE @retTable TABLE
(
	Company					bCompany	NOT NULL
,	Craft					bCraft		NOT NULL
,	CraftDesc				bDesc		NULL
,	CraftLabel				bDesc		NULL
,	Class					bClass		NOT NULL
,	ClassDesc				bDesc		NULL
,	ShopClassYN				bYN			NOT NULL DEFAULT ('N')
,	Shift					int			NOT NULL DEFAULT (1)
,	RegStdRate      		bUnitCost	NOT NULL DEFAULT (0.00)
,	OTStdRate				bUnitCost	NOT NULL DEFAULT (0.00)      
,	DTStdRate				bUnitCost	NOT NULL DEFAULT (0.00)
,	RegRate					bUnitCost	NOT NULL DEFAULT (0.00)
,	OTRate					bUnitCost	NOT NULL DEFAULT (0.00)      
,	DTRate					bUnitCost	NOT NULL DEFAULT (0.00)
,	LiabilityMarkup			bRate		NOT NULL DEFAULT (0.00)
,	JCFixedRateBurden		bRate		NOT NULL DEFAULT (0.00)
,	RegUnionFringeAndBurden	bUnitCost	NOT NULL DEFAULT (0.00)
,	OTUnionFringeAndBurden	bUnitCost	NOT NULL DEFAULT (0.00)
,	DTUnionFringeAndBurden	bUnitCost	NOT NULL DEFAULT (0.00)
,	AddonAmount				bUnitCost	NOT NULL DEFAULT (0.00)
,	[L_401KEmployerMatch]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_AKSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_AZSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_AdminFund-Pctofgross]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_AdminFund-perhr]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_AnnuityPension]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_AnnunityPension]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_ApprenticeTraining-Pctofgro]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_ApprenticeTraining]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_BAMF-perhr]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_BLMCC]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_CAF]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_CASUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_COSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_DrugTesting]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_EducationalDevelopment]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_EmpCo-op&EducationalTrust]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_FMSBurden]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_FUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_FlexPlan]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_GASUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_GroupLife/ADD-Empr]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_GrpMedicalPlan-Empr]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_H&WVariableFactor]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_HRA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_Health&Welfare-VariCalc]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_Health&Welfare]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_IASUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_IDSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_ILSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_IndustrialFund]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_IndustryFundPctofGross]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_InternationalDues-Monthly]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_KSSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_LMCCTDues]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_LMCC]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_LMCI/LMCFTrust]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_LRT]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_LaneTransit]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_LocalPension]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_LocalTrainingFund]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_MCAWWW]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_MCA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_MDSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_MISUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_MNSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_MOSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_MTSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_MedicareEmployer]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_MoneyPurchase]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NCSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NDSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NEBF-PctofBase]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NEBFPension]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NECADues]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NECA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NEMI]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NLMCC]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NVSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NationalPension]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NationalTrainingFund]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_NatlMGMT]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_OKSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_ORSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_ORWBFAssessmentEmpr]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_OrganizationalAssessmentPct]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_OrganizationalTrust]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_PMCA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_PacificCoastPension]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_PainterProgressionFund]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_PrevailingWageEnforcement]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_Rebound]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_SAP]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_SASMI]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_SDSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_SMOHIT]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_ScholarshipFund]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_ShopBurden]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_SocialSecurityEmployer]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_StatePension-Pctofgross]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_StatePension]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_TXSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_TriMet]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_UTSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_WASUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_WISUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_WWSPEDues]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_WYSUTA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_WorkersComp-WY]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_WorkersCompWA]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_WorkersComp]		bUnitCost	NOT NULL DEFAULT (0)
,	[L_WorkingDuesPctofgross]		bUnitCost	NOT NULL DEFAULT (0)
)

DECLARE prcmcur cursor FOR
SELECT DISTINCT 
	prcm.PRCo
,	prcm.Craft
,	prcm.Description AS CraftDese
,	prcm.Notes AS CraftLabel
FROM
	HQCO hqco join
	PRCM prcm ON
		hqco.HQCo=prcm.PRCo
	AND hqco.udTESTCo<>'Y'
	AND prcm.Craft <> '0000' JOIN
	PRCC prcc ON
		prcm.PRCo=prcc.PRCo
	AND prcm.Craft=prcc.Craft
WHERE
	( prcm.PRCo=@inCompany OR @inCompany IS NULL )
AND	( prcm.Craft=@inCraft OR @inCraft IS NULL )
AND	( prcc.Class=@inClass OR @inClass IS NULL )

ORDER BY
	prcm.PRCo
,	prcm.Craft

FOR READ ONLY

DECLARE @indent INT
SET @indent=10

DECLARE @PRCo bCompany
DECLARE @Craft bCraft
DECLARE @CraftDesc bDesc
DECLARE @CraftLabel bDesc
DECLARE @CraftCount int

DECLARE @craftaddoncount INT  -- PRCI where EDLCode=PREC.EarnCode
DECLARE @craftdedliabcount INT -- PRCI WHERE EDLCode=PRDL.DLCode
DECLARE @crafttemplatecount INT -- PRCT 

DECLARE @craftaddonmethod VARCHAR(2)
DECLARE @craftaddonearncode	int
DECLARE @craftaddonearndesc bDesc
DECLARE @craftaddonrate bUnitCost
DECLARE @craftaddonfactor bRate

DECLARE @craftaddonamount	bUnitCost

DECLARE @craftdedliabmethod VARCHAR(2)
DECLARE @craftdedliabtype VARCHAR(2)
DECLARE @craftdedliabdlcode	int
DECLARE @craftdedliabdldesc bDesc
DECLARE @craftdedliabrate bUnitCost
DECLARE @craftdedliabfactor bRate

DECLARE @crafttemplate SMALLINT
DECLARE @crafttemplatenotes VARCHAR(35)


DECLARE @Class bClass
DECLARE @ClassDesc bDesc
DECLARE @ClassShopYN bYN
DECLARE @ClassCount int
DECLARE @classvarearncount INT  -- PRCE 
DECLARE @classaddoncount INT  -- PRCF 
DECLARE @classdedliabcount INT -- PRCD
DECLARE @classtemplatecount INT -- PRTC
DECLARE @classratecount INT --PRCP
DECLARE @classjcratecount INT --JCRD 

DECLARE @classvarearnmethod VARCHAR(2)
DECLARE @classvarearnearncode	int
DECLARE @classvarearnearndesc bDesc
DECLARE @classvarearnrate bUnitCost
DECLARE @classvarearnfactor bRate

DECLARE @classaddonmethod VARCHAR(2)
DECLARE @classaddonearncode	int
DECLARE @classaddonearndesc bDesc
DECLARE @classaddonrate bUnitCost
DECLARE @classaddonfactor bRate
DECLARE @classaddonamount	bUnitCost

DECLARE @classdedliabmethod VARCHAR(2)
DECLARE @classdedliabtype VARCHAR(2)
DECLARE @classdedliabdlcode	int
DECLARE @classdedliabdldesc bDesc
DECLARE @classdedliabrate  bUnitCost
DECLARE @classdedliabfactor bRate

DECLARE @classtemplate SMALLINT
DECLARE @classtemplatenotes VARCHAR(35)

DECLARE @classshift INT
DECLARE @classrate bUnitCost
DECLARE @classburden bRate
DECLARE @reg_factor bRate
DECLARE @ot_factor bRate
DECLARE @dt_factor bRate

DECLARE @classjcshift INT
DECLARE @classjcrate bUnitCost
DECLARE @classjcstandardrate bUnitCost
DECLARE @classjcburden bRate
DECLARE @reg_jcfactor bRate
DECLARE @ot_jcfactor bRate
DECLARE @dt_jcfactor bRate

SELECT @CraftCount=0

OPEN prcmcur
FETCH prcmcur INTO
	@PRCo		--bCompany
,	@Craft		--bCraft
,	@CraftDesc	--bDesc
,	@CraftLabel --bDesc
WHILE @@fetch_status = 0
BEGIN
	SELECT @CraftCount=@CraftCount+1, @ClassCount=0
	SELECT @craftaddonamount=0, @classaddonamount=0

	SELECT
		@reg_factor=reg_prec.Factor
	,	@ot_factor=ot_prec.Factor
	,	@dt_factor=dt_prec.Factor
	FROM 
		PRCO prco JOIN
		PREC reg_prec ON
			prco.PRCo=reg_prec.PRCo
		AND prco.CrewRegEC=reg_prec.EarnCode JOIN
		PREC ot_prec ON
			prco.PRCo=ot_prec.PRCo
		AND prco.CrewOTEC=ot_prec.EarnCode JOIN
		PREC dt_prec ON
			prco.PRCo=dt_prec.PRCo
		AND prco.CrewDblEC=dt_prec.EarnCode

	SELECT
		@reg_jcfactor=reg_prec.Factor
	,	@ot_jcfactor=ot_prec.Factor
	,	@dt_jcfactor=dt_prec.Factor
	FROM 
		PRCO prco JOIN
		PREC reg_prec ON
			prco.PRCo=reg_prec.PRCo
		AND reg_prec.EarnCode=1 JOIN
		PREC ot_prec ON
			prco.PRCo=ot_prec.PRCo
		AND ot_prec.EarnCode=2 JOIN
		PREC dt_prec ON
			prco.PRCo=dt_prec.PRCo
		AND dt_prec.EarnCode=3

	SELECT
		@classburden=jctl.LiabilityRate
	FROM
		JCTL jctl
	WHERE
		jctl.JCCo=@PRCo
	AND jctl.LiabTemplate=1 
	AND jctl.LiabType=5

	-- Get inventory of child elements needed for Rate Calculations
	SELECT @craftaddoncount = COUNT(*) FROM PRCI prci JOIN PREC prec ON prci.PRCo=prec.PRCo AND prci.EDLCode=prec.EarnCode AND prci.PRCo=@PRCo AND prci.Craft=@Craft
	SELECT @craftdedliabcount = COUNT(*) FROM PRCI prci JOIN PRDL prdl ON prci.PRCo=prdl.PRCo AND prci.EDLCode=prdl.DLCode AND prci.PRCo=@PRCo AND prci.Craft=@Craft
	SELECT @crafttemplatecount = COUNT(*) FROM PRCT prct WHERE prct.PRCo=@PRCo AND prct.Craft=@Craft
	
	DECLARE prcccur CURSOR FOR
    SELECT 
		prcc.Class
	,	prcc.Description AS ClassDesc
	,	prcc.udShopYN AS ClassShopYN
	FROM
		PRCC prcc
	WHERE
		prcc.PRCo=@PRCo
	AND prcc.Craft=@Craft
	AND ( prcc.Class=@inClass OR @inClass IS NULL )
	ORDER BY
		prcc.Class
	FOR READ ONLY 

	OPEN prcccur
	FETCH prcccur INTO
		@Class		--bClass
	,	@ClassDesc	--bDesc
	,	@ClassShopYN --bYN

	WHILE @@fetch_status = 0
	BEGIN
		SELECT @ClassCount=@ClassCount+1

		-- Get inventory of child elements needed for Rate Calculations
		SELECT @classvarearncount=COUNT(*) FROM PRCE prce WHERE prce.PRCo=@PRCo AND Craft=@Craft AND Class=@Class  --VariableEarnings
		SELECT @classaddoncount=COUNT(*) FROM PRCF prcf WHERE prcf.PRCo=@PRCo AND Craft=@Craft AND Class=@Class -- AddOn
		SELECT @classdedliabcount=COUNT(*) FROM PRCD prcd WHERE prcd.PRCo=@PRCo AND Craft=@Craft AND Class=@Class-- Deductions/Liabilities
		SELECT @classtemplatecount=COUNT(*) FROM PRTC prtc WHERE prtc.PRCo=@PRCo AND Craft=@Craft AND Class=@Class -- Craft/Class Templates
		SELECT @classratecount=COUNT(*) FROM PRCP prcp WHERE prcp.PRCo=@PRCo AND Craft=@Craft AND Class=@Class --Class Rates
		SELECT @classjcratecount=COUNT(*) FROM JCRD jcrd WHERE jcrd.PRCo=@PRCo AND Craft=@Craft AND Class=@Class AND jcrd.JCCo=@PRCo AND jcrd.RateTemplate=1 AND jcrd.EarnFactor=1 --JC Fixed Rates -- Header is JCRT 

		-- Print Craft Header
		BEGIN 
		PRINT REPLICATE('*',200)

		PRINT
			CAST('CraftRow' AS CHAR(10))
		+	CAST('Co' AS CHAR(5))		--bCompany
		+	CAST('Craft' AS CHAR(12))		--bCraft
		+	CAST('CraftDesc' AS CHAR(32))	--bDesc
		+	CAST('AddOns' AS CHAR(10))
		+	CAST('DedLiabs' AS CHAR(10))
		+	CAST('Templates' AS CHAR(10))

		PRINT REPLICATE('*',200)
		END 


		-- Print Craft Details
		PRINT
			CAST(@CraftCount AS CHAR(10))
		+	CAST(@PRCo AS CHAR(5))		--bCompany
		+	CAST(@Craft AS CHAR(12))		--bCraft
		+	CAST(@CraftDesc AS CHAR(32))	--bDesc
		+	CAST(@craftaddoncount AS CHAR(10))	--bDesc
		+	CAST(@craftdedliabcount AS CHAR(10))	--bDesc
		+	CAST(@crafttemplatecount AS CHAR(10))	--bDesc

		PRINT REPLICATE('*',200)

		-- Print Class Header
		PRINT 
			REPLICATE(' ', @indent)
		+	REPLICATE('=',200-@indent)
	
		PRINT 
			REPLICATE(' ', @indent)
		+	CAST('ClassRow' AS CHAR(10))
		+	CAST('Craft' AS CHAR(12))		--bCraft
		+	CAST('CraftDesc' AS CHAR(32))	--bDesc
		+	CAST('Class' AS CHAR(12))		--bCraft
		+	CAST('ClassDesc' AS CHAR(32))	--bDesc
		+	CAST('Shop' AS CHAR(5))	--bDesc
		+	CAST('VarEars' AS CHAR(10))
		+	CAST('Addons' AS CHAR(10))
		+	CAST('DedLiabs' AS CHAR(10))
		+	CAST('Templates' AS CHAR(10))
		+	CAST('PRRates' AS CHAR(10))
		+	CAST('JCRates' AS CHAR(10))

		PRINT 
			REPLICATE(' ', @indent)
		+	REPLICATE('=',200-@indent)

		PRINT 
			REPLICATE(' ', @indent)
		+	CAST(@ClassCount AS CHAR(10))
		+	CAST(@Craft AS CHAR(12))		--bCraft
		+	CAST(@CraftDesc AS CHAR(32))	--bDesc
		+	CAST(@Class AS CHAR(12))		--bCraft
		+	CAST(@ClassDesc AS CHAR(32))	--bDesc
		+	CAST(@ClassShopYN AS CHAR(5))	--bDesc
		+	CAST(@classvarearncount AS CHAR(10))	--bDesc
		+	CAST(@classaddoncount AS CHAR(10))	--bDesc
		+	CAST(@classdedliabcount AS CHAR(10))	--bDesc
		+	CAST(@classtemplatecount AS CHAR(10))	--bDesc
		+	CAST(@classratecount AS CHAR(10))	--bDesc
		+	CAST(@classjcratecount AS CHAR(10))	--bDesc

		-- Print Class Header
		PRINT 
			REPLICATE(' ', @indent)
		+	REPLICATE('=',200-@indent)

		PRINT 
			REPLICATE(' ', @indent*2)
		+	REPLICATE('-',200-(@indent*2))

		PRINT 
			REPLICATE(' ', @indent*2)
		+	CAST('Shift' AS CHAR(10))
		+	CAST('Burden' AS CHAR(10))
		+	CAST('RegRate' AS CHAR(15))		--bCraft
		+	CAST('OTRate' AS CHAR(15))		--bCraft
		+	CAST('DTRate' AS CHAR(15))		--bCraft
		+	CAST('RegStdRate' AS CHAR(15))		--bCraft
		+	CAST('OTStdRate' AS CHAR(15))		--bCraft
		+	CAST('DTStdRate' AS CHAR(15))		--bCraft

		PRINT 
			REPLICATE(' ', @indent*2)
		+	REPLICATE('-',150-(@indent*2))

		IF @classratecount > 0
		BEGIN
			DECLARE classratecur CURSOR FOR
			SELECT
				prcp.Shift
			,	prcp.NewRate
			FROM 
				PRCP prcp
			WHERE
				prcp.PRCo=@PRCo
			AND prcp.Craft=@Craft
			AND prcp.Class=@Class
			ORDER BY
				prcp.Shift
			FOR READ ONLY

			OPEN classratecur
			FETCH classratecur INTO
				@classshift
			,	@classrate

			WHILE @@FETCH_STATUS=0
			BEGIN

				PRINT
					REPLICATE(' ',@indent*2)
				+	CAST(@classshift AS char(10))
				+	CAST(@classburden AS char(10))
				+	CAST(CAST(@classrate*@reg_factor AS NUMERIC(16,5)) AS char(15))
				+	CAST(CAST(@classrate*@ot_factor AS NUMERIC(16,5)) AS char(15))
				+	CAST(CAST(@classrate*@dt_factor AS NUMERIC(16,5)) AS char(15))
				+	CAST(CAST(@classrate*@reg_factor*(1+@classburden) AS NUMERIC(16,5)) AS char(15))
				+	CAST(CAST(@classrate*@ot_factor*(1+@classburden) AS NUMERIC(16,5)) AS char(15))
				+	CAST(CAST(@classrate*@dt_factor*(1+@classburden) AS NUMERIC(16,5)) AS char(15))

				
				-- NOW WALK THROUGH ADDONS, LIABILITIES, TEMPLATES, etc, and build up loaded rate and breakouts
				-- then check audit table and update changes as necessary.
				
				
				IF @craftaddoncount > 0
				BEGIN 
					PRINT REPLICATE(' ',@indent*3) + 'Process Craft AddOns [A]'
					declare craftaddoncur CURSOR FOR
					SELECT
						prec.Method
					,	prec.EarnCode
					,	coalesce(prec.Description,'') AS EarnCodeDesc
					,	prci.NewRate
					,	prci.Factor
					FROM 
						PRCI prci JOIN 
						PREC prec ON 
							prci.PRCo=prec.PRCo 
						AND prci.EDLCode=prec.EarnCode 
						AND prci.PRCo=@PRCo 
						AND prci.Craft=@Craft
					ORDER BY
						prci.Factor
					,	prci.NewRate
					FOR READ ONLY
					
					OPEN craftaddoncur
					FETCH craftaddoncur INTO
						@craftaddonmethod
					,	@craftaddonearncode	--int
					,	@craftaddonearndesc --bDesc
					,	@craftaddonrate
					,	@craftaddonfactor

					WHILE @@fetch_status=0
					BEGIN
						PRINT 
							REPLICATE(' ', @indent*4)
						+	'Craft AddOn: '+ CAST(@craftaddonmethod AS CHAR(5)) 
						+	CAST(@craftaddonrate AS CHAR(10)) 
						+	CAST(@craftaddonfactor AS CHAR(10))
						+	CAST(@craftaddonearncode AS CHAR(10))
						+	CAST(@craftaddonearndesc AS CHAR(40))

						--DECLARE @craftaddonamount	bUnitCost
						SELECT @craftaddonamount = @craftaddonamount +
						case @craftaddonmethod
							WHEN 'A' THEN @craftaddonrate --'Amount'		-- Amount
							WHEN 'D' THEN 0 --'Day'			-- Rate per day
							WHEN 'DN' THEN 0 --'Decuction'	-- Rate of a deduction
							WHEN 'F' THEN 0 --'Factored'	-- Factored Rate per Hour	
							WHEN 'G' THEN @craftaddonrate --'Gross'		-- Rate of Gross
							WHEN 'H' THEN @craftaddonrate --'Hourly'		-- Rate per hour
							WHEN 'N' THEN 0 --'Net'			-- Rate of net
							WHEN 'R' THEN 0 --'Routine'			-- Routine
							WHEN 'S' THEN 0 --'Straight'	-- Straight Time Equivelant
							WHEN 'V' THEN 0 --'Variable'	-- Variable Factored Rate
							ELSE 0 --'Unknown'
						END
							--WHEN 'H' THEN @craftaddonamount=@craftaddonamount+@craftaddonrate
							--WHEN 'G' THEN @craftaddonamount=@craftaddonamount+@craftaddonrate

						FETCH craftaddoncur INTO
							@craftaddonmethod
						,	@craftaddonearncode	--int
						,	@craftaddonearndesc --bDesc
						,	@craftaddonrate
						,	@craftaddonfactor

					END

					CLOSE craftaddoncur
					DEALLOCATE craftaddoncur
						
				END
				IF @craftdedliabcount > 0
				BEGIN 
					PRINT REPLICATE(' ',@indent*3) + 'Process Craft Deducations and Liabilities [B]'
					--@craftdedliabcount = COUNT(*) FROM PRCI prci JOIN PRDL prdl ON prci.PRCo=prdl.PRCo AND prci.EDLCode=prdl.DLCode AND prci.PRCo=@PRCo AND prci.Craft=@Craft
					declare craftdedliabcur CURSOR FOR
					SELECT
						prdl.Method
					,	prdl.DLType
					,	prdl.DLCode
					,	coalesce(prdl.Description, '') AS DLDesc
					--,	prci.NewRate   -- VP UI Shows from here but table is 0
					,	prdl.RateAmt1  -- VP UI Display Value is actually from here??
					,	prci.Factor
					FROM 
						PRCI prci JOIN 
						PRDL prdl ON 
							prci.PRCo=prdl.PRCo 
						AND prci.EDLCode=prdl.DLCode
						AND prci.PRCo=@PRCo 
						AND prci.Craft=@Craft
					ORDER BY
						prci.Factor
					,	prci.NewRate
					FOR READ ONLY
					
					OPEN craftdedliabcur
					FETCH craftdedliabcur INTO
						@craftdedliabmethod 
					,	@craftdedliabtype --VARCHAR(2)
					,	@craftdedliabdlcode
					,	@craftdedliabdldesc
					,	@craftdedliabrate 
					,	@craftdedliabfactor 

					WHILE @@fetch_status=0
					BEGIN
						PRINT 
							REPLICATE(' ', @indent*4)
						+	'Craft LiabDed: '
						+	CAST(@craftdedliabmethod AS CHAR(5)) 
						+	CAST(@craftdedliabtype AS CHAR(5)) 
						+	CAST(@craftdedliabrate AS CHAR(10)) 
						+	CAST(@craftdedliabfactor AS CHAR(10))
						+	CAST(@craftdedliabdlcode AS CHAR(10))
						+	CAST(@craftdedliabdldesc AS CHAR(40))

						FETCH craftdedliabcur INTO
							@craftdedliabmethod 
						,	@craftdedliabtype --VARCHAR(2)
						,	@craftdedliabdlcode
						,	@craftdedliabdldesc
						,	@craftdedliabrate 
						,	@craftdedliabfactor 

					END

					CLOSE craftdedliabcur
					DEALLOCATE craftdedliabcur

				END

				IF @crafttemplatecount > 0
				BEGIN
					PRINT REPLICATE(' ',@indent*3) + 'Process Craft Template [C]'
					--	SELECT @crafttemplatecount = COUNT(*) FROM PRCT prct WHERE prct.PRCo=@PRCo AND prct.Craft=@Craft
					declare crafttemplatecur CURSOR FOR
					SELECT
						prct.Template
					,	COALESCE(prct.Notes,'') AS Notes
					FROM 
						PRCT prct
					WHERE
							prct.PRCo=@PRCo 
						AND prct.Craft=@Craft
					ORDER BY
						prct.Template
					FOR READ ONLY
					
					OPEN crafttemplatecur
					FETCH crafttemplatecur INTO
						@crafttemplate 
					,	@crafttemplatenotes

					WHILE @@fetch_status=0
					BEGIN
						PRINT 
							REPLICATE(' ', @indent*4)
						+	'Craft Template: '+ CAST(@crafttemplate AS CHAR(5)) 
						+	CAST(@crafttemplatenotes AS CHAR(40))

						FETCH crafttemplatecur INTO
							@crafttemplate 
						,	@crafttemplatenotes

					END

					CLOSE crafttemplatecur
					DEALLOCATE crafttemplatecur


				END

				if @classvarearncount > 0
				BEGIN
					PRINT REPLICATE(' ',@indent*3) + 'Process Class Varialbe Earnings [D]'
					--SELECT @classvarearncount=COUNT(*) FROM PRCE prce WHERE prce.PRCo=@PRCo AND Craft=@Craft AND Class=@Class  --VariableEarnings
					declare classvarearncur CURSOR FOR
					SELECT
						prec.Method
					,	prec.EarnCode
					,	coalesce(prec.Description,'') AS EarnCodeDesc
					,	prce.NewRate
					,	prce.Shift
					FROM 
						PRCE prce JOIN 
						PREC prec ON 
							prce.PRCo=prec.PRCo 
						AND prce.EarnCode=prec.EarnCode 
						AND prce.PRCo=@PRCo 
						AND prce.Craft=@Craft 
						AND prce.Class=@Class
						AND prce.Shift=@classshift  --LWO
					ORDER BY
						prce.Shift
					,	prce.NewRate
					FOR READ ONLY
					
					OPEN classvarearncur
					FETCH classvarearncur INTO
						@classvarearnmethod --VARCHAR(2)
					,	@classvarearnearncode	--int
					,	@classvarearnearndesc --bDesc
					,	@classvarearnrate --bUnitCost
					,	@classvarearnfactor --bRate

					WHILE @@fetch_status=0
					BEGIN
						PRINT 
							REPLICATE(' ', @indent*4)
						+	'Class VarEarngs: '+ CAST(@classvarearnmethod AS CHAR(5)) 
						+	CAST(@classvarearnrate AS CHAR(10)) 
						+	CAST(@classvarearnfactor AS CHAR(10))
						+	CAST(@classvarearnearncode AS CHAR(10))
						+	CAST(@classvarearnearndesc AS CHAR(40))

						FETCH classvarearncur INTO
							@classvarearnmethod --VARCHAR(2)
						,	@classvarearnearncode	--int
						,	@classvarearnearndesc --bDesc
						,	@classvarearnrate --bUnitCost
						,	@classvarearnfactor --bRate
					END

					CLOSE classvarearncur
					DEALLOCATE classvarearncur

				END

				if @classaddoncount > 0
				BEGIN 
					PRINT REPLICATE(' ',@indent*3) + 'Process Class AddOns [E]'
					--SELECT @classaddoncount=COUNT(*) FROM PRCF prcf WHERE prcf.PRCo=@PRCo AND Craft=@Craft AND Class=@Class -- AddOn

					declare classaddoncur CURSOR FOR
					SELECT
						prec.Method
					,	prec.EarnCode
					,	coalesce(prec.Description,'') AS EarnCodeDesc
					,	prcf.NewRate
					,	prcf.Factor
					FROM 
						PRCF prcf JOIN 
						PREC prec ON 
							prcf.PRCo=prec.PRCo 
						AND prcf.EarnCode=prec.EarnCode 
						AND prcf.PRCo=@PRCo 
						AND prcf.Craft=@Craft 
						AND prcf.Class=@Class
					ORDER BY
						prcf.Factor
					,	prcf.NewRate
					FOR READ ONLY
					
					OPEN classaddoncur
					FETCH classaddoncur INTO
						@classaddonmethod
					,	@classaddonearncode	--int
					,	@classaddonearndesc --bDesc
					,	@classaddonrate
					,	@classaddonfactor

					WHILE @@fetch_status=0
					BEGIN
						PRINT 
							REPLICATE(' ', @indent*4)
						+	'Class AddOn: '+ CAST(@classaddonmethod AS CHAR(5)) 
						+	CAST(@classaddonrate AS CHAR(10)) 
						+	CAST(@classaddonfactor AS CHAR(10))
						+	CAST(@classaddonearncode AS CHAR(10))
						+	CAST(@classaddonearndesc AS CHAR(40))

						--DECLARE @classaddonamount	bUnitCost
						SELECT @classaddonamount = @classaddonamount +
						case @classaddonmethod
							WHEN 'A' THEN @classaddonrate --'Amount'		-- Amount
							WHEN 'D' THEN 0 --'Day'			-- Rate per day
							WHEN 'DN' THEN 0 --'Decuction'	-- Rate of a deduction
							WHEN 'F' THEN 0 --'Factored'	-- Factored Rate per Hour	
							WHEN 'G' THEN @classaddonrate --'Gross'		-- Rate of Gross
							WHEN 'H' THEN @classaddonrate --'Hourly'		-- Rate per hour
							WHEN 'N' THEN 0 --'Net'			-- Rate of net
							WHEN 'R' THEN 0 --'Routine'			-- Routine
							WHEN 'S' THEN 0 --'Straight'	-- Straight Time Equivelant
							WHEN 'V' THEN 0 --'Variable'	-- Variable Factored Rate
							ELSE 0 --'Unknown'
						END


						FETCH classaddoncur INTO
							@classaddonmethod
						,	@classaddonearncode	--int
						,	@classaddonearndesc --bDesc
						,	@classaddonrate
						,	@classaddonfactor

					END

					CLOSE classaddoncur
					DEALLOCATE classaddoncur
					
				END
				 
				if @classdedliabcount > 0
				BEGIN
					PRINT REPLICATE(' ',@indent*3) + 'Process Class Deducations and Liabilities [F]'
					-- Dont forget to process Shop detail @ClassShopYN
					--SELECT @classdedliabcount=COUNT(*) FROM PRCD prcd WHERE prcd.PRCo=@PRCo AND Craft=@Craft AND Class=@Class -- Deductions/Liabilities
					declare classdedliabcur CURSOR FOR
					SELECT
						prdl.Method
					,	prdl.DLType
					,	prdl.DLCode
					,	coalesce(prdl.Description, '') AS DLDesc
					--,	prci.NewRate   -- VP UI Shows from here but table is 0
					,	prcd.NewRate  -- VP UI Display Value is actually from here??
					,	prcd.Factor
					FROM 
						PRCD prcd JOIN
						PRDL prdl ON
							prcd.PRCo=prdl.PRCo
						AND prcd.DLCode=prdl.DLCode
						AND prcd.PRCo=@PRCo 
						AND prcd.Craft=@Craft
						AND prcd.Class=@Class						
					ORDER BY
						prcd.Factor
					,	prcd.NewRate
					FOR READ ONLY
					
					OPEN classdedliabcur
					FETCH classdedliabcur INTO
						@classdedliabmethod --VARCHAR(2)
					,	@classdedliabtype --VARCHAR(2)
					,	@classdedliabdlcode	--int
					,	@classdedliabdldesc --bDesc
					,	@classdedliabrate  --bUnitCost
					,	@classdedliabfactor --brate


					WHILE @@fetch_status=0
					BEGIN
						PRINT 
							REPLICATE(' ', @indent*4)
						+	'Class LiabDed: '
						+	CAST(@classdedliabmethod AS CHAR(5)) 
						+	CAST(@classdedliabtype AS CHAR(5)) 
						+	CAST(@classdedliabrate AS CHAR(10)) 
						+	CAST(@classdedliabfactor AS CHAR(10))
						+	CAST(@classdedliabdlcode AS CHAR(10))
						+	CAST(@classdedliabdldesc AS CHAR(40))

						FETCH classdedliabcur INTO
						@classdedliabmethod --VARCHAR(2)
					,	@classdedliabtype --VARCHAR(2)
					,	@classdedliabdlcode	--int
					,	@classdedliabdldesc --bDesc
					,	@classdedliabrate  --bUnitCost
					,	@classdedliabfactor --brate

					END

					CLOSE classdedliabcur
					DEALLOCATE classdedliabcur

				END
					
				if @classtemplatecount > 0
				BEGIN 
					PRINT REPLICATE(' ',@indent*3) + 'Process Class Template [G]'
					--SELECT @classtemplatecount=COUNT(*) FROM PRTC prtc WHERE prtc.PRCo=@PRCo AND Craft=@Craft AND Class=@Class -- Craft/Class Templates
					declare classtemplatecur CURSOR FOR
					SELECT
						prtc.Template
					,	COALESCE(prtc.Notes,'') AS Notes
					FROM 
						PRTC prtc
					WHERE
							prtc.PRCo=@PRCo 
						AND prtc.Craft=@Craft
						AND prtc.Class=@Class
					ORDER BY
						prtc.Template
					FOR READ ONLY
					
					OPEN classtemplatecur
					FETCH classtemplatecur INTO
						@crafttemplate 
					,	@crafttemplatenotes

					WHILE @@fetch_status=0
					BEGIN
						PRINT 
							REPLICATE(' ', @indent*4)
						+	'Class Template: '+ CAST(@classtemplate AS CHAR(5)) 
						+	CAST(@classtemplatenotes AS CHAR(40))

						FETCH classtemplatecur INTO
							@classtemplate 
						,	@classtemplatenotes

					END

					CLOSE classtemplatecur
					DEALLOCATE classtemplatecur

				END 
				PRINT ''

				INSERT @retTable
				(
					Company					--bCompany	NOT NULL
				,	Craft					--bCraft		NOT NULL
				,	CraftDesc				--bDesc		NULL
				,	CraftLabel				--bDesc		NULL
				,	Class					--bClass		NOT NULL
				,	ClassDesc				--bDesc		NULL
				,	ShopClassYN				--bYN			NOT NULL DEFAULT ('N')
				,	Shift					--INT			NOT NULL DEFAULT (1)
				,	RegStdRate      		--bUnitCost	NOT NULL DEFAULT (0.00)
				,	OTStdRate				--bUnitCost	NOT NULL DEFAULT (0.00)      
				,	DTStdRate				--bUnitCost	NOT NULL DEFAULT (0.00)
				,	RegRate					--bUnitCost	NOT NULL DEFAULT (0.00)
				,	OTRate					--bUnitCost	NOT NULL DEFAULT (0.00)      
				,	DTRate					--bUnitCost	NOT NULL DEFAULT (0.00)
				,	LiabilityMarkup			--bRate		NOT NULL DEFAULT (0.00)
				,	JCFixedRateBurden		--bRate		NOT NULL DEFAULT (0.00)
				,	RegUnionFringeAndBurden	--bRate		NOT NULL DEFAULT (0.00)
				,	OTUnionFringeAndBurden	--bRate		NOT NULL DEFAULT (0.00)
				,	DTUnionFringeAndBurden	--bRate		NOT NULL DEFAULT (0.00)
				,	AddonAmount				--bRate	NOT NULL DEFAULT (0.00)
				)
				SELECT
					@PRCo
				,	@Craft
				,	@CraftDesc
				,	COALESCE(@CraftLabel,@CraftDesc)
				,	@Class
				,	@ClassDesc
				,	@ClassShopYN
				,	@classshift
				,	CAST(@classrate*@reg_factor AS NUMERIC(16,5))
				,	CAST(@classrate*@ot_factor AS NUMERIC(16,5))
				,	CAST(@classrate*@dt_factor AS NUMERIC(16,5))
				,	CAST(@classrate*@reg_factor*(1+@classburden) AS NUMERIC(16,5))
				,	CAST(@classrate*@ot_factor*(1+@classburden) AS NUMERIC(16,5))
				,	CAST(@classrate*@dt_factor*(1+@classburden) AS NUMERIC(16,5))
				,	@classburden
				,	0
				,	CAST(@classrate*@reg_factor*@classburden AS NUMERIC(16,5))
				,	CAST(@classrate*@ot_factor*@classburden AS NUMERIC(16,5))
				,	CAST(@classrate*@dt_factor*@classburden AS NUMERIC(16,5))
				,	COALESCE(@classaddonamount, @craftaddonamount,0)
				
				FETCH classratecur INTO
					@classshift
				,	@classrate

			END


			CLOSE classratecur
			DEALLOCATE classratecur
		END

		IF @classjcratecount > 0
		BEGIN
			DECLARE classjcratecur CURSOR FOR
			--SELECT * FROM JCRD WHERE Class='501AC' AND RateTemplate=1 AND EarnFactor=1 AND PRCo=1
			SELECT
				jcrd.Shift
			,	jcrd.NewRate
			,	jcrd.udStandardRate
			,	jcrd.udBurdenPercent
			FROM 
				JCRD jcrd 
			WHERE
				jcrd.PRCo=@PRCo
			AND jcrd.Craft=@Craft
			AND jcrd.Class=@Class
			AND jcrd.JCCo=@PRCo
			AND RateTemplate=1
			AND EarnFactor=1.000000
			ORDER BY
				jcrd.Shift
			FOR READ ONLY

			OPEN classjcratecur
			FETCH classjcratecur INTO
				@classjcshift
			,	@classjcrate
			,	@classjcstandardrate
			,	@classjcburden

			WHILE @@FETCH_STATUS=0
			BEGIN
				PRINT
					REPLICATE(' ',@indent*2)
				+	CAST(@classjcshift AS char(10))
				+	CAST(@classjcburden AS char(10))
				+	CAST(CAST(@classjcrate*@reg_jcfactor AS NUMERIC(16,5)) AS char(15))
				+	CAST(CAST(@classjcrate*@ot_jcfactor AS NUMERIC(16,5)) AS char(15))
				+	CAST(CAST(@classjcrate*@dt_jcfactor AS NUMERIC(16,5)) AS char(15))
				+	CAST(CAST(@classjcstandardrate*@reg_jcfactor AS NUMERIC(16,5)) AS char(15))
				+	CAST(CAST(@classjcstandardrate*@ot_jcfactor AS NUMERIC(16,5)) AS char(15))
				+	CAST(CAST(@classjcstandardrate*@dt_jcfactor AS NUMERIC(16,5)) AS char(15))

				-- THIS SHOULD BE GOOD FOR STAFF --- Time to check audit table and update changes as necessary.
				
				INSERT @retTable
				(
					Company					--bCompany		NOT NULL
				,	Craft					--bCraft		NOT NULL
				,	CraftDesc				--bDesc			NULL
				,	CraftLabel				--bDesc		NULL
				,	Class					--bClass		NOT NULL
				,	ClassDesc				--bDesc			NULL
				,	ShopClassYN				--bYN			NOT NULL DEFAULT ('N')
				,	Shift					--INT			NOT NULL DEFAULT (1)
				,	RegStdRate      		--bUnitCost		NOT NULL DEFAULT (0.00)
				,	OTStdRate				--bUnitCost		NOT NULL DEFAULT (0.00)      
				,	DTStdRate				--bUnitCost		NOT NULL DEFAULT (0.00)
				,	RegRate					--bUnitCost		NOT NULL DEFAULT (0.00)
				,	OTRate					--bUnitCost		NOT NULL DEFAULT (0.00)      
				,	DTRate					--bUnitCost		NOT NULL DEFAULT (0.00)
				,	LiabilityMarkup			--bRate			NOT NULL DEFAULT (0.00)
				,	JCFixedRateBurden		--bRate			NOT NULL DEFAULT (0.00)
				,	RegUnionFringeAndBurden	--bRate		NOT NULL DEFAULT (0.00)
				,	OTUnionFringeAndBurden	--bRate		NOT NULL DEFAULT (0.00)
				,	DTUnionFringeAndBurden	--bRate		NOT NULL DEFAULT (0.00)
				,	AddonAmount	--bRate		NOT NULL DEFAULT (0.00)
				) 
				select
					@PRCo
				,	@Craft
				,	@CraftDesc
				,	COALESCE(@CraftLabel,@CraftDesc)
				,	@Class
				,	@ClassDesc
				,	@ClassShopYN
				,	@classjcshift
				,	CAST( (@classjcstandardrate*@reg_jcfactor) AS NUMERIC(16,5))
				,	CAST( (@classjcstandardrate*@ot_jcfactor) AS NUMERIC(16,5))
				,	CAST( (@classjcstandardrate*@dt_jcfactor) AS NUMERIC(16,5))
				,	CAST( (@classjcrate*@reg_jcfactor) AS NUMERIC(16,5))
				,	CAST( (@classjcrate*@ot_jcfactor) AS NUMERIC(16,5))
				,	CAST( (@classjcrate*@dt_jcfactor) AS NUMERIC(16,5))
				,	CAST(0 AS NUMERIC(8,6))
				,	@classjcburden
				,	CAST(0 AS NUMERIC(8,6))
				,	CAST(0 AS NUMERIC(8,6))
				,	CAST(0 AS NUMERIC(8,6))
				,	COALESCE(@classaddonamount, @craftaddonamount,0)
				
				FETCH classjcratecur INTO
					@classjcshift
				,	@classjcrate
				,	@classjcstandardrate
				,	@classjcburden

			END

			CLOSE classjcratecur
			DEALLOCATE classjcratecur

		END

		SELECT 
			@classvarearncount=0
		,	@classaddoncount=0
		,	@classdedliabcount=0
		,	@classtemplatecount=0
		,	@classratecount=0
		,	@classjcratecount=0
        
		FETCH prcccur INTO
			@Class		--bClass
		,	@ClassDesc	--bDesc
		,	@ClassShopYN --bYN

	END

	CLOSE prcccur
	DEALLOCATE prcccur

	PRINT ''

	FETCH prcmcur INTO
		@PRCo		--bCompany
	,	@Craft		--bCraft
	,	@CraftDesc	--bDesc
	,	@CraftLabel --bDesc
END

CLOSE prcmcur
DEALLOCATE prcmcur

SELECT 
	Company					--bCompany	NOT NULL
,	Craft					--bCraft		NOT NULL
,	CraftDesc				--bDesc		NULL
,	CraftLabel				--bDesc		NULL
,	Class					--bClass		NOT NULL
,	ClassDesc				--bDesc		NULL
,	ShopClassYN				--bYN			NOT NULL DEFAULT ('N')
,	Shift					--INT			NOT NULL DEFAULT (1)
,	RegStdRate      		--bUnitCost	NOT NULL DEFAULT (0.00)
,	OTStdRate				--bUnitCost	NOT NULL DEFAULT (0.00)      
,	DTStdRate				--bUnitCost	NOT NULL DEFAULT (0.00)
,	RegRate					--bUnitCost	NOT NULL DEFAULT (0.00)
,	OTRate					--bUnitCost	NOT NULL DEFAULT (0.00)      
,	DTRate					--bUnitCost	NOT NULL DEFAULT (0.00)
,	LiabilityMarkup			--bRate		NOT NULL DEFAULT (0.00)
,	JCFixedRateBurden		--bRate		NOT NULL DEFAULT (0.00)
,	RegUnionFringeAndBurden	--bRate		NOT NULL DEFAULT (0.00)
,	OTUnionFringeAndBurden	--bRate		NOT NULL DEFAULT (0.00)
,	DTUnionFringeAndBurden	--bRate		NOT NULL DEFAULT (0.00)
,	AddonAmount
,[L_401KEmployerMatch]	
,[L_AKSUTA]	
,[L_AZSUTA]	
,[L_AdminFund-Pctofgross]	
,[L_AdminFund-perhr]	
,[L_AnnuityPension]	
,[L_AnnunityPension]	
,[L_ApprenticeTraining-Pctofgro]	
,[L_ApprenticeTraining]	
,[L_BAMF-perhr]	
,[L_BLMCC]	
,[L_CAF]	
,[L_CASUTA]	
,[L_COSUTA]	
,[L_DrugTesting]	
,[L_EducationalDevelopment]	
,[L_EmpCo-op&EducationalTrust]	
,[L_FMSBurden]	
,[L_FUTA]	
,[L_FlexPlan]	
,[L_GASUTA]	
,[L_GroupLife/ADD-Empr]	
,[L_GrpMedicalPlan-Empr]	
,[L_H&WVariableFactor]	
,[L_HRA]	
,[L_Health&Welfare-VariCalc]	
,[L_Health&Welfare]	
,[L_IASUTA]	
,[L_IDSUTA]	
,[L_ILSUTA]	
,[L_IndustrialFund]	
,[L_IndustryFundPctofGross]	
,[L_InternationalDues-Monthly]	
,[L_KSSUTA]	
,[L_LMCCTDues]	
,[L_LMCC]	
,[L_LMCI/LMCFTrust]	
,[L_LRT]	
,[L_LaneTransit]	
,[L_LocalPension]	
,[L_LocalTrainingFund]	
,[L_MCAWWW]	
,[L_MCA]	
,[L_MDSUTA]	
,[L_MISUTA]	
,[L_MNSUTA]	
,[L_MOSUTA]	
,[L_MTSUTA]	
,[L_MedicareEmployer]	
,[L_MoneyPurchase]	
,[L_NCSUTA]	
,[L_NDSUTA]	
,[L_NEBF-PctofBase]	
,[L_NEBFPension]	
,[L_NECADues]	
,[L_NECA]	
,[L_NEMI]	
,[L_NLMCC]	
,[L_NVSUTA]	
,[L_NationalPension]	
,[L_NationalTrainingFund]	
,[L_NatlMGMT]	
,[L_OKSUTA]	
,[L_ORSUTA]	
,[L_ORWBFAssessmentEmpr]	
,[L_OrganizationalAssessmentPct]	
,[L_OrganizationalTrust]	
,[L_PMCA]	
,[L_PacificCoastPension]	
,[L_PainterProgressionFund]	
,[L_PrevailingWageEnforcement]	
,[L_Rebound]	
,[L_SAP]	
,[L_SASMI]	
,[L_SDSUTA]	
,[L_SMOHIT]	
,[L_ScholarshipFund]	
,[L_ShopBurden]	
,[L_SocialSecurityEmployer]	
,[L_StatePension-Pctofgross]	
,[L_StatePension]	
,[L_TXSUTA]	
,[L_TriMet]	
,[L_UTSUTA]	
,[L_WASUTA]	
,[L_WISUTA]	
,[L_WWSPEDues]	
,[L_WYSUTA]	
,[L_WorkersComp-WY]	
,[L_WorkersCompWA]	
,[L_WorkersComp]	
,[L_WorkingDuesPctofgross]	
FROM 
	@retTable
ORDER BY
	Company					--bCompany	NOT NULL
,	Craft					--bCraft		NOT NULL
,	Class					--bClass		NOT NULL
,	Shift					--INT			NOT NULL DEFAULT (1)

RETURN @@rowcount

GO

PRINT 'GRANT EXEC ON mspCalcRateSchedule TO PUBLIC'
go

GRANT EXEC ON mspCalcRateSchedule TO PUBLIC
go

PRINT 'EXEC mspCalcRateSchedule @inCraft = NULL	@inClass = NULL,@inEffectiveDate = NULL, @inContract	= null'
go

PRINT ''
go
--DECLARE @count INT

/*
exec  mspCalcRateSchedule
	@inCompany			= null
,	@inCraft			= NULL --'0016.00' --'0001'
,	@inClass			= NULL --'3500.900JR'
,	@inEffectiveDate	= NULL
,	@inContract			= NULL
,	@inEmployee			= null

SELECT @count
*/
go


exec mspCalcRateSchedule
	@inCompany			= null
,	@inCraft			= '0016.00' --'0001'
,	@inClass			= '3500.000FM' --'3500.900JR'
,	@inEffectiveDate	= NULL
,	@inContract			= NULL
,	@inEmployee			= null

GO

/*
exec mspCalcRateSchedule
	@inCompany			= 1
,	@inCraft			= NULL --'0016.00' --'0001'
,	@inClass			= '501PC' --'3500.900JR'
,	@inEffectiveDate	= NULL
,	@inContract			= NULL
,	@inEmployee			= null
*/
GO

--SELECT 
--	pvt.*
--FROM
--(
--SELECT
--	prcd.PRCo
--,	prcd.Craft
--,	prcd.Class
--,	prdl.Method
--,	prdl.DLType
--,	prdl.DLCode
--,	coalesce(prdl.Description, '') AS DLDesc
--,	'L_' + REPLACE(REPLACE(rtrim(rtrim(Description)),'%','Pct'),' ','') AS PivotDesc
----,	prci.NewRate   -- VP UI Shows from here but table is 0
--,	COALESCE(prcd.NewRate,0) AS NewRate  -- VP UI Display Value is actually from here??
--,	prcd.Factor
--FROM 
--	PRCD prcd JOIN
--	PRDL prdl ON
--		prcd.PRCo=prdl.PRCo
--	AND prcd.DLCode=prdl.DLCode
--	AND prcd.PRCo=1
--	AND prcd.Craft='0016.00'
--	AND prcd.Class='3500.000FM'						
--	AND prcd.Factor IN (0,1)
--	AND prdl.DLType='L'
--) t1
--PIVOT
--(
--	SUM(NewRate) FOR PivotDesc in 
--	(
--		[L_401KEmployerMatch],
--		[L_AKSUTA],
--		[L_AZSUTA],
--		[L_AdminFund-Pctofgross],
--		[L_AdminFund-perhr],
--		[L_AnnuityPension],
--		[L_AnnunityPension],
--		[L_ApprenticeTraining-Pctofgro],
--		[L_ApprenticeTraining],
--		[L_BAMF-perhr],
--		[L_BLMCC],
--		[L_CAF],
--		[L_CASUTA],
--		[L_COSUTA],
--		[L_DrugTesting],
--		[L_EducationalDevelopment],
--		[L_EmpCo-op&EducationalTrust],
--		[L_FMSBurden],
--		[L_FUTA],
--		[L_FlexPlan],
--		[L_GASUTA],
--		[L_GroupLife/ADD-Empr],
--		[L_GrpMedicalPlan-Empr],
--		[L_H&WVariableFactor],
--		[L_HRA],
--		[L_Health&Welfare-VariCalc],
--		[L_Health&Welfare],
--		[L_IASUTA],
--		[L_IDSUTA],
--		[L_ILSUTA],
--		[L_IndustrialFund],
--		[L_IndustryFundPctofGross],
--		[L_InternationalDues-Monthly],
--		[L_KSSUTA],
--		[L_LMCCTDues],
--		[L_LMCC],
--		[L_LMCI/LMCFTrust],
--		[L_LRT],
--		[L_LaneTransit],
--		[L_LocalPension],
--		[L_LocalTrainingFund],
--		[L_MCAWWW],
--		[L_MCA],
--		[L_MDSUTA],
--		[L_MISUTA],
--		[L_MNSUTA],
--		[L_MOSUTA],
--		[L_MTSUTA],
--		[L_MedicareEmployer],
--		[L_MoneyPurchase],
--		[L_NCSUTA],
--		[L_NDSUTA],
--		[L_NEBF-PctofBase],
--		[L_NEBFPension],
--		[L_NECADues],
--		[L_NECA],
--		[L_NEMI],
--		[L_NLMCC],
--		[L_NVSUTA],
--		[L_NationalPension],
--		[L_NationalTrainingFund],
--		[L_NatlMGMT],
--		[L_OKSUTA],
--		[L_ORSUTA],
--		[L_ORWBFAssessmentEmpr],
--		[L_OrganizationalAssessmentPct],
--		[L_OrganizationalTrust],
--		[L_PMCA],
--		[L_PacificCoastPension],
--		[L_PainterProgressionFund],
--		[L_PrevailingWageEnforcement],
--		[L_Rebound],
--		[L_SAP],
--		[L_SASMI],
--		[L_SDSUTA],
--		[L_SMOHIT],
--		[L_ScholarshipFund],
--		[L_ShopBurden],
--		[L_SocialSecurityEmployer],
--		[L_StatePension-Pctofgross],
--		[L_StatePension],
--		[L_TXSUTA],
--		[L_TriMet],
--		[L_UTSUTA],
--		[L_WASUTA],
--		[L_WISUTA],
--		[L_WWSPEDues],
--		[L_WYSUTA],
--		[L_WorkersComp-WY],
--		[L_WorkersCompWA],
--		[L_WorkersComp],
--		[L_WorkingDuesPctofgross]	
--	)  
--) pvt



SELECT DISTINCT 
',[' + 'L_' + REPLACE(REPLACE(rtrim(rtrim(Description)),'%','Pct'),' ','') + ']	' FROM PRDL WHERE DLType='L' AND PRCo < 100 ORDER BY 1