create TRIGGER trIU_JCCP_RecalcForecast 
   ON  bJCCP
   AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--SELECT * FROM JCCP
	DECLARE jccp CURSOR for
	SELECT DISTINCT JCCo, Job 
	FROM inserted 
	ORDER BY JCCo, Job  
	FOR READ ONLY

	declare @trCo			bCompany
	declare @trJob			bJob
	
	OPEN jccp
	FETCH jccp INTO
		@trCo			--bCompany
	,	@trJob			--bJob
	
	WHILE @@fetch_status=0
	BEGIN
		EXEC mspRecalcJCCostForecast 
			@Company	=@trCo			--bCompany
		,	@Job		=@trJob	--bJob
		,	@InitMonths ='Y'			--bYN
		,	@Debug		=0				--INT = 0

		FETCH jccp INTO
			@trCo			--bCompany
		,	@trJob			--bJob
	END
	
	CLOSE jccp	
	DEALLOCATE jccp	

END
GO