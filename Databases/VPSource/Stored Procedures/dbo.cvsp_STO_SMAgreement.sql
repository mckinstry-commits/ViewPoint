SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvsp_STO_SMAgreement] (
		@ToCo			 bCompany, 
		@FromCo			 bCompany,
		@DefaultCustomer INT, 
		@DeleteDataYN	 CHAR(1))

AS 
/**************************************************************************************************
Copyright:	2013 Coaxis/Viewpoint Construction Software (VCS) 
			The TSQL code in this procedure may not be reproduced, copied, modified,
			or executed without the expressed written consent from VCS.

Project:	Timberline to Viewpoint V6 SM Conversion 
Author:		Chris Lounsbury
Purpose:	Converts Timberline SM PM Task Items into Viewpoint SM Work Schedule Tasks
			
Change Log:

	2013xxxx	BA	Initial Coding by Brenda Ackerson
	20130419	CL	Changed logic for populating the status dates which drive Viewpoint statuses
					Reformated code for readability
	20130509	CL	Changed AutoRenew logic to flip to Y if TL AGRSTATUS = 50.  Unsure at this point
					if all Timberline installations will utilize same logic
**************************************************************************************************/
BEGIN TRY
	
	/******************************************************************
		Declare variables
	******************************************************************/
		DECLARE @MaxID	INT 

	/******************************************************************
		Backup existing table. Format in: table_YYYY MM DD HH MM SS
	******************************************************************/
		DECLARE @SQL VARCHAR(8000) = 'SELECT * INTO vSMAgreement_',
				@TS	 VARCHAR(30)
				
		SELECT	@TS	 = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
		SELECT	@SQL = @SQL + @TS + ' FROM vSMAgreement'
		EXEC	(@SQL)

	/******************************************************************
		Modify table attributes
	******************************************************************/	
		ALTER TABLE vSMAgreement NOCHECK CONSTRAINT ALL
		ALTER TABLE vSMAgreement DISABLE TRIGGER ALL
		SET IDENTITY_INSERT vSMAgreement ON

	/******************************************************************
		Check Delete flag and remove existing data if required
	******************************************************************/
		IF UPPER(@DeleteDataYN) = 'Y'
		BEGIN
			DELETE vSMAgreement WHERE SMCo = @ToCo
		END

	/******************************************************************
		Perform the conversion
	******************************************************************/
		-- Get last used Primary Key
		SET @MaxID = (SELECT ISNULL(MAX(SMAgreementID), 0) FROM dbo.vSMAgreement)

		INSERT vSMAgreement (
				 SMAgreementID
				,SMCo
				,Agreement
				,Revision
				,RevisionType
				,DateActivated
				,DateCancelled
				,DateTerminated
				,Description
				,CustGroup
				,Customer
				,EffectiveDate
				,NonExpiring
				,ExpirationDate
				,AutoRenew
				,RateTemplate
				,AgreementPrice
				,PricingFrequency
				,ReportID
				,Notes
				,AgreementType
				,CustomerPO
				,AlternateAgreement
				,PreviousRevision
				,AmendmentRevision
				,DateCreated)

		SELECT	SMAgreementID=@MaxID+ROW_NUMBER() OVER (ORDER BY co.HQCo, agp.AGREEMENTNBR, agp.AGREEMENTSEQ)
				,SMCo=@ToCo
				,Agreement=agp.AGREEMENTNBR
				,Revision=agp.AGREEMENTSEQ
				,RevisionType= --NEEDS EDITED. NEED TO KNOW WHAT THE VALUES MEAN.
					CASE
						WHEN agp.AGRSTATUS=20 THEN 0 --Quote
						WHEN agp.AGRSTATUS=30 THEN 1 --Cancelled
						WHEN agp.AGRSTATUS=40 THEN 2 --Active
						WHEN agp.AGRSTATUS=50 THEN 3 --Expired
						WHEN agp.AGRSTATUS=60 THEN 4 --Terminated
						WHEN agp.AGRSTATUS=70 THEN 3 --Expired												
						ELSE 0
					END
				
				,DateActivated = CASE WHEN agp.AGRSTATUS = 20 THEN NULL
									  ELSE agp.DATEENTER
									  END
				,DateCancelled = NULL
				,DateTerminated = NULL		
				,Description = site.Description
				,CustGroup = co.CustGroup
				,Customer = ISNULL(xsc.NewCustomerID,@DefaultCustomer)
				,EffectiveDate = agp.STARTDATE
				,NonExpiring = 'N'
				,ExpirationDate = agp.EXPIREDATE
				,AutoRenew = CASE WHEN agp.AGRSTATUS = 50 
								  THEN 'Y'
								  ELSE 'N'
								  END
				,RateTemplate = xrt.NewRateTemplate
				,AgreementPrice = CONVERT(NUMERIC(12,2),agp.AGRAMOUNT)
				,PricingFrequency = NULL
				,ReportID = NULL
				,Notes=agr.COMMENTS
				,AgreementType = xat.NewAgrType
				,CustomerPO = NULL
				,AlternateAgreement = agr.ALTAGRNBR
				,PreviousRevision =
					CASE	
						WHEN agp.AGREEMENTSEQ=1 THEN NULL
						ELSE agp.AGREEMENTSEQ-1
					END
				,AmendmentRevision=NULL
				,DateCreated=agr.DATEENTER

		FROM	CV_TL_Source_SM.dbo.AGRPERIOD agp --5672
		
		JOIN	CV_TL_Source_SM.dbo.AGREEMENT agr 
			ON	agr.AGREEMENTNBR = agp.AGREEMENTNBR --5672
		
		JOIN	bHQCO co
			ON	co.HQCo = @ToCo
		
		JOIN	CV_TL_Source_SM.dbo.AGRTYPE agt
			ON	agt.AGRTYPENBR = agp.AGRTYPENBR
		
		JOIN	budXRefSMAgrTypes xat
			ON	xat.SMCo = @FromCo 
			AND xat.OldAgrType = agt.AGRTYPENBR	
		
		JOIN	budXRefCustomer xsc
			ON	xsc.OldCustomerID = agr.ARCUST		
		
		JOIN	budXRefSMRateTemplate xrt
			ON	xrt.SMCo = @FromCo 
			AND xrt.OldRateTemplate = agp.RATESHEETNBR
		
		JOIN	vSMAgreement vag
			ON	vag.SMCo = @ToCo 
			AND vag.Agreement = agr.AGREEMENTNBR
			
		JOIN	vSMServiceSite AS site
			ON	agr.SERVSITENBR = site.ServiceSite
		
		WHERE	vag.Agreement IS NULL 
		
		ORDER BY co.HQCo, 
				 agr.AGREEMENTNBR, 
				 agr.AGREEMENTSEQ

	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMAgreement OFF
		ALTER TABLE vSMAgreement CHECK CONSTRAINT ALL;
		ALTER TABLE vSMAgreement ENABLE TRIGGER ALL;

	/******************************************************************
		Review data
	******************************************************************/	
		SELECT * FROM vSMAgreement WHERE SMCo = @ToCo
		
END TRY

BEGIN CATCH
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMAgreement OFF
		ALTER TABLE vSMAgreement CHECK CONSTRAINT ALL;
		ALTER TABLE vSMAgreement ENABLE TRIGGER ALL;
		
	/******************************************************************
		Error
	******************************************************************/	
		SELECT ERROR_MESSAGE() 
				+ ' at line number ' 
				+ CAST(ERROR_LINE() AS VARCHAR)
END CATCH
GO
