USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='McKspGetHQTXTaxRates' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
	Begin
		Print 'DROP PROCEDURE dbo.McKspGetHQTXTaxRates'
		DROP PROCEDURE dbo.McKspGetHQTXTaxRates
	End
GO

Print 'CREATE PROCEDURE dbo.McKspGetHQTXTaxRates'
GO


CREATE PROCEDURE dbo.McKspGetHQTXTaxRates
AS
/* ========================================================================
-- Object Name: dbo.McKspGetHQTXTaxRates
-- Author:		 Leo Gurdian, Arun Thomas
-- Create date: 12/07/2017
-- Description: A tool that compares tax rates from Dept. of Revenue, Zip2Tax and HQTX Sales Tax Rates analysis for import into Viewpoint
-- History:		
	USER				DATE			DESC

	Leo Gurdian		12.07.17		initial concept
	Leo Gurdian		06.28.19		TFS XXXX - Prod Release
*/ 
Begin

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;
	Declare @errmsg varchar(8000) = ''

Begin Try

	With cte (Type, TaxCode, udReportingCode, Description, EffectiveDate, TaxRate)
      As
      (
	      Select 
	      IIF(RIGHT(a.TaxCode,1)='X','Exempt','Taxable') AS Type,
	      a.TaxCode, 
	      a.udReportingCode,
	      a.Description,
	      a.EffectiveDate,
	      dbo.vfHQTaxRate (1, a.TaxCode, ISNULL(a.EffectiveDate, '2079-05-01')) * 100 AS TaxRate 
	      From dbo.HQTX a
	      Where Left(TaxCode,2) = 'WA'
			      AND Right(TaxCode,2) <> '_C'
			      AND Right(TaxCode,2) <> '_X'
			      AND Right(TaxCode,1) <> 'X'
			      AND Right(TaxCode,2) <> '_P'
			      AND udReportingCode <> ''
      ) 
      Select DISTINCT a.Type, a.TaxCode, a.udReportingCode, a.Description, a.EffectiveDate, a.TaxRate
      From cte a JOIN cte b ON 
		      a.TaxCode = b.TaxCode
		      AND a.Description = b.Description
      Order by TaxCode;

End try

Begin Catch
	Set @errmsg =  ERROR_PROCEDURE() + ', ' + N'Line:' + cast(ERROR_LINE() as varchar) + ' | ' + ERROR_MESSAGE();
	Goto i_exit
End Catch

i_exit:

	if (@errmsg <> '')
		Begin
		 RAISERROR(@errmsg, 11, -1);
		 --failure
		End
End
GO

Grant EXECUTE ON dbo.McKspGetHQTXTaxRates TO [MCKINSTRY\Viewpoint Users]

GO