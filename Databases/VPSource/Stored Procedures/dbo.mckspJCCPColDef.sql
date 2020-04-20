SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 10/4/13
-- Description:	JC Cost Projections Columns Default
-- =============================================
CREATE PROCEDURE [dbo].[mckspJCCPColDef] 
	-- Add the parameters for the stored procedure here
	@Company int = 0, 
	@VPUserName varchar (30)= NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--TEST ONLY
	--SET @Company = 101
	--SET @VPUserName = 'MCKINSTRY\EricS'
	--TEST ONLY
    -- Insert statements for procedure here
	DECLARE @DefaultCols TABLE(
				JCCo int,
	          Form VARCHAR(30),
	          UserName VARCHAR(128),
	          ChangedOnly CHAR(1),
	          ItemUnitsOnly CHAR(1),
	          PhaseUnitsOnly CHAR(1),
	          ShowLinkedCT CHAR(1),
	          ShowFutureCO CHAR(1),
	          RemainUnits CHAR(1),
	          RemainHours CHAR(1),
	          RemainCosts CHAR(1),
	          OpenForm CHAR(1),
	          PhaseOption CHAR(1),
	          BegPhase VARCHAR(20),
	          EndPhase VARCHAR(20),
	          CostTypeOption CHAR(1),
	          SelectedCostTypes VARCHAR(1000),
	          VisibleColumns VARCHAR(1000),
	          ColumnOrder VARCHAR(1000),
	          ThruPriorMonth CHAR(1),
	          NoLinkedCT CHAR(1),
	          ProjMethod CHAR(1),
	          Production CHAR(1),
	          ProjInitOption CHAR(1),
	          ProjWriteOverPlug CHAR(1),
	          RevProjFilterBegItem VARCHAR(16),
	          RevProjFilterEndItem VARCHAR(16),
	          RevProjFilterBillType CHAR(1),
	          RevProjCalcWriteOverPlug CHAR(1),
	          RevProjCalcMethod CHAR(1),
	          RevProjCalcMethodMarkup NUMERIC(6,4),
	          RevProjCalcBillType CHAR(1),
	          RevProjCalcBegContract VARCHAR(10),
	          RevProjCalcEndContract VARCHAR(10),
	          RevProjCalcBegItem VARCHAR(16),
	          RevProjCalcEndItem VARCHAR(16),
	          ProjInactivePhases CHAR(1),
	          OrderBy CHAR(1),
	          CycleMode CHAR(1),
	          RevProjFilterBegDept VARCHAR(10),
	          RevProjFilterEndDept VARCHAR(10),
	          RevProjCalcBegDept VARCHAR(10),
	          RevProjCalcEndDept VARCHAR(10),
	          ColumnWidth VARCHAR(max)
	          )
	INSERT INTO @DefaultCols
		SELECT JCCo ,
	          Form ,
	          UserName ,
	          ChangedOnly ,
	          ItemUnitsOnly ,
	          PhaseUnitsOnly ,
	          ShowLinkedCT ,
	          ShowFutureCO ,
	          RemainUnits ,
	          RemainHours ,
	          RemainCosts ,
	          OpenForm ,
	          PhaseOption ,
	          BegPhase ,
	          EndPhase ,
	          CostTypeOption ,
	          SelectedCostTypes ,
	          VisibleColumns ,
	          ColumnOrder ,
	          ThruPriorMonth ,
	          NoLinkedCT ,
	          ProjMethod ,
	          Production ,
	          ProjInitOption ,
	          ProjWriteOverPlug ,
	          RevProjFilterBegItem ,
	          RevProjFilterEndItem ,
	          RevProjFilterBillType ,
	          RevProjCalcWriteOverPlug ,
	          RevProjCalcMethod ,
	          RevProjCalcMethodMarkup ,
	          RevProjCalcBillType ,
	          RevProjCalcBegContract ,
	          RevProjCalcEndContract ,
	          RevProjCalcBegItem ,
	          RevProjCalcEndItem ,
	          ProjInactivePhases ,
	          OrderBy ,
	          CycleMode ,
	          RevProjFilterBegDept ,
	          RevProjFilterEndDept ,
	          RevProjCalcBegDept ,
	          RevProjCalcEndDept ,
	          ColumnWidth
	        FROM JCUO 
	          WHERE @Company = JCCo AND UserName = 'PML1' AND Form = 'JCProjection' ;
	    
	    INSERT INTO @DefaultCols
		SELECT JCCo ,
	          Form ,
	          UserName ,
	          ChangedOnly ,
	          ItemUnitsOnly ,
	          PhaseUnitsOnly ,
	          ShowLinkedCT ,
	          ShowFutureCO ,
	          RemainUnits ,
	          RemainHours ,
	          RemainCosts ,
	          OpenForm ,
	          PhaseOption ,
	          BegPhase ,
	          EndPhase ,
	          CostTypeOption ,
	          SelectedCostTypes ,
	          VisibleColumns ,
	          ColumnOrder ,
	          ThruPriorMonth ,
	          NoLinkedCT ,
	          ProjMethod ,
	          Production ,
	          ProjInitOption ,
	          ProjWriteOverPlug ,
	          RevProjFilterBegItem ,
	          RevProjFilterEndItem ,
	          RevProjFilterBillType ,
	          RevProjCalcWriteOverPlug ,
	          RevProjCalcMethod ,
	          RevProjCalcMethodMarkup ,
	          RevProjCalcBillType ,
	          RevProjCalcBegContract ,
	          RevProjCalcEndContract ,
	          RevProjCalcBegItem ,
	          RevProjCalcEndItem ,
	          ProjInactivePhases ,
	          OrderBy ,
	          CycleMode ,
	          RevProjFilterBegDept ,
	          RevProjFilterEndDept ,
	          RevProjCalcBegDept ,
	          RevProjCalcEndDept ,
	          ColumnWidth
	        FROM JCUO 
	          WHERE @Company = JCCo AND UserName = 'PML1' AND Form = 'JCRevProj' ;
	    
	          
	    UPDATE @DefaultCols 
			SET JCCo = @Company,
			UserName = @VPUserName
			WHERE Form = 'JCRevProj' OR Form = 'JCProjection';
	        
	INSERT INTO dbo.bJCUO
	        SELECT * FROM @DefaultCols
	    
END
GO
