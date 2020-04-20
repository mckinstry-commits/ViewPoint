SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Determination OF Bad Debt
--Used for Deduction Values in B&O Tax Report

	
--Classification is based on B&O Tax Code on JCJM, then to any child tax codes to determine percentage breakdown and reporting code.
CREATE PROCEDURE [dbo].[mspARTaxSourceData]
(
	@Contract bContract
,	@Mth	  bMonth
)

AS

--DECLARE @Contract bContract
--SELECT @Contract=' 14246-'

DECLARE arthcur CURSOR FOR
SELECT 
	arh.ARCo
,	arh.ARTrans
,	arh.ARTransType
,	arh.Mth
,	arh.JCCo
,	arh.Contract
,	arh.Description
,	arh.CustGroup
,	arh.Customer
--	arh.*--, arl.* 
FROM 
	ARTH arh --JOIN
	--ARTL arl on			-- ARTL Provide Line Detail to ARTH Record
	--	arh.ARCo=arl.ARCo
	--AND arh.ARTrans=arl.ARTrans
	--AND arh.Mth=arl.Mth
WHERE 
	arh.ARCo IN (1,20)
AND (LTRIM(RTRIM(arh.Contract))=LTRIM(RTRIM(@Contract)) OR @Contract IS NULL)
AND ( arh.Mth=@Mth OR @Mth IS NULL )
--AND	ARTransType='W'		
FOR READ ONLY

DECLARE @rcnt INT 

DECLARE @arth_ARCo bCompany
DECLARE @arth_ARTrans bTrans
DECLARE @arth_ARTransType CHAR(1)
DECLARE @arth_Mth bMonth
DECLARE @arth_JCCo bCompany
DECLARE @arth_Contract bContract
DECLARE @arth_Description bDesc
DECLARE @arth_CustGroup bGroup
DECLARE @arth_Customer bCustomer
DECLARE @arth_CustomerName VARCHAR(60)

DECLARE @artl_ARLine SMALLINT
DECLARE @artl_RecType TINYINT
DECLARE @artl_LineType CHAR(1)
DECLARE @artl_TaxGroup bGroup
DECLARE @artl_TaxCode bTaxCode
DECLARE @artl_ContractItem bContractItem

DECLARE @jcci_TaxCode bGroup
DECLARE @jcci_TaxGroup bTaxCode
DECLARE @jcci_Description bDesc

DECLARE @jcjm_Job bJob
DECLARE @jcjm_TaxCode bGroup
DECLARE @jcjm_TaxGroup bTaxCode
DECLARE @jcjm_Description bDesc

SELECT @rcnt=0
			
OPEN arthcur
FETCH arthcur INTO
	@arth_ARCo 
,	@arth_ARTrans 
,	@arth_ARTransType
,	@arth_Mth 
,	@arth_JCCo 
,	@arth_Contract 
,	@arth_Description 
,	@arth_CustGroup
,	@arth_Customer

WHILE @@fetch_status=0
BEGIN
	SELECT @rcnt = @rcnt + 1
	
	SELECT @arth_CustomerName = arcm.Name from ARCM arcm WHERE arcm.CustGroup=@arth_CustGroup AND arcm.Customer=@arth_Customer
	
	PRINT
		CAST('ARTH ' + CAST(@rcnt AS CHAR(4)) AS CHAR(12))
	+	COALESCE(CONVERT(CHAR(12),@arth_Mth,101),'??')
	+	CAST(CAST(@arth_CustomerName AS VARCHAR(60)) + ' (' + CAST(@arth_CustGroup AS VARCHAR(5)) + '.' + CAST(@arth_Customer AS VARCHAR(15)) + ')' AS CHAR(50))
	+	COALESCE(CAST(@arth_ARCo AS CHAR(5)),'??')
	+	COALESCE(CAST(@arth_ARTrans AS CHAR(12)),'??')
	+	COALESCE(CAST(@arth_ARTransType AS CHAR(5)),'??')
	+	COALESCE(CAST(@arth_Description AS CHAR(30)),'??')
	+	COALESCE(CAST(@arth_JCCo AS CHAR(5)),'??') 
	+	COALESCE(CAST(@arth_Contract AS CHAR(15)),'??') 	

	/* ARTL */
	BEGIN --- ARTL SUB CURSOR
	
	--SELECT
	--	ARLine
	--,	RecType
	--,	LineType
	--,	TaxGroup
	--,	TaxCode
	--,	Item
	--FROM 
	--	ARTL artl
	--WHERE
	--	artl.ARCo=20
	--AND artl.Mth='12/01/2012'
	--AND artl.ARTrans=139
	--AND LTRIM(RTRIM(artl.Contract))=LTRIM(RTRIM('14246-'))
		
	DECLARE artlcur CURSOR FOR 
	SELECT
		ARLine
	,	RecType
	,	LineType
	,	TaxGroup
	,	TaxCode
	,	Item
	FROM 
		ARTL artl
	WHERE
		artl.ARCo=@arth_ARCo
	AND artl.Mth=@arth_Mth
	AND artl.ARTrans=@arth_ARTrans
	AND LTRIM(RTRIM(artl.Contract))=LTRIM(RTRIM(@arth_Contract))
	ORDER BY
		ARLine
	FOR READ ONLY
	
	OPEN artlcur
	FETCH artlcur INTO
		@artl_ARLine
	,	@artl_RecType
	,	@artl_LineType
	,	@artl_TaxGroup
	,	@artl_TaxCode
	,	@artl_ContractItem
	
	WHILE @@FETCH_STATUS=0
	BEGIN
		PRINT
			CAST('ARTL' AS CHAR(12))
		+	COALESCE(CAST('' AS CHAR(12)),'??')
		+	COALESCE(CAST(@artl_ARLine AS CHAR(5)),'??')
		+	COALESCE(CAST(@artl_RecType AS CHAR(5)),'??')
		+	COALESCE(CAST(@artl_LineType AS CHAR(5)),'??')
		+	COALESCE(CAST(@artl_TaxGroup AS CHAR(5)),'??')
		+	COALESCE(CAST(@artl_TaxCode AS CHAR(10)),'??')
		+	@artl_ContractItem
		
		
		BEGIN	-- BEGIN JCCI SUB CURSOR

/*
		SELECT distinct
			jcci.TaxCode
		,	jcci.TaxGroup
		,	jcci.Description
		FROM 
			JCCI jcci 
		WHERE
			jcci.JCCo=20
		AND LTRIM(RTRIM(jcci.Contract))=LTRIM(RTRIM('14246-'))
		AND jcci.Item=50
*/				
		DECLARE jccicur CURSOR FOR
		SELECT distinct
			jcci.TaxCode
		,	jcci.TaxGroup
		,	jcci.Description
		FROM 
			JCCI jcci 
		WHERE
			jcci.JCCo=@arth_JCCo
		AND LTRIM(RTRIM(jcci.Contract))=LTRIM(RTRIM(@arth_Contract))
		AND jcci.Item=@artl_ContractItem
		FOR READ ONLY
		
		OPEN jccicur
		FETCH jccicur into
			@jcci_TaxCode 
		,	@jcci_TaxGroup 
		,	@jcci_Description
		
		WHILE @@fetch_status=0
		BEGIN
			PRINT
				CAST('JCCI' AS CHAR(12))
			+	COALESCE(CAST('' AS CHAR(12)),'??')
				+	COALESCE(CAST(@jcci_Description AS CHAR(5)),'??')
			+	COALESCE(CAST(@jcci_TaxGroup AS CHAR(5)),'??')
			+	COALESCE(CAST(@jcci_TaxCode AS CHAR(5)),'??')



			BEGIN	-- BEGIN JCJM SUB CURSOR

			DECLARE jccpcur CURSOR FOR
			SELECT distinct
				jcjm.Job
			,	jcjm.TaxCode
			,	jcjm.TaxGroup
			,	jcjm.Description
			FROM 
				JCJP jcjp join
				JCJM jcjm ON
					jcjp.JCCo=jcjm.JCCo
				AND jcjp.Job=jcjm.Job
			WHERE
				jcjp.JCCo=@arth_JCCo
			AND jcjp.Contract=@arth_Contract
			AND jcjp.Item=@artl_ContractItem
			FOR READ ONLY
			
			OPEN jccpcur
			FETCH jccpcur into
				@jcjm_Job 
			,	@jcjm_TaxCode 
			,	@jcjm_TaxGroup 
			,	@jcjm_Description
			
			WHILE @@fetch_status=0
			BEGIN
				PRINT
					CAST('JCJM' AS CHAR(12))
				+	COALESCE(CAST('' AS CHAR(12)),'??')
				+	COALESCE(CAST(@jcjm_Job AS CHAR(12)),'??')
				+	COALESCE(CAST(@jcjm_Description AS CHAR(5)),'??')
				+	COALESCE(CAST(@jcjm_TaxGroup AS CHAR(5)),'??')
				+	COALESCE(CAST(@jcjm_TaxCode AS CHAR(5)),'??')
				
				FETCH jccpcur into
					@jcjm_Job 
				,	@jcjm_TaxCode 
				,	@jcjm_TaxGroup 
				,	@jcjm_Description
			END
			
			CLOSE jccpcur
			DEALLOCATE jccpcur
			
			
			END		-- END JCJM SUB CURSOR


			
			FETCH jccicur into
				@jcci_TaxCode 
			,	@jcci_TaxGroup 
			,	@jcci_Description
		END
		
		CLOSE jccicur
		DEALLOCATE jccicur
		
		END		-- END JCCI SUB CURSOR	
	
		FETCH artlcur INTO
			@artl_ARLine
		,	@artl_RecType
		,	@artl_LineType
		,	@artl_TaxGroup
		,	@artl_TaxCode
		,	@artl_ContractItem
	
	END
	
	CLOSE artlcur
	DEALLOCATE artlcur
	
	END --- END ARTL SUB CURSOR
	
	PRINT ''
	
	FETCH arthcur INTO
		@arth_ARCo 
	,	@arth_ARTrans 
	,	@arth_ARTransType
	,	@arth_Mth 
	,	@arth_JCCo 
	,	@arth_Contract 
	,	@arth_Description 
	,	@arth_CustGroup
	,	@arth_Customer
END
CLOSE arthcur
DEALLOCATE arthcur

GO
