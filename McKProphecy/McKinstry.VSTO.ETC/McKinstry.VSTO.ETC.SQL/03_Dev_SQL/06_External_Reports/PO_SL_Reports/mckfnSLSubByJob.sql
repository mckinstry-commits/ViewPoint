use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnSLSubByJob' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION dbo.mckfnSLSubByJob'
	DROP FUNCTION dbo.mckfnSLSubByJob
end
go

print 'CREATE FUNCTION dbo.mckfnSLSubByJob'
go

CREATE FUNCTION [dbo].[mckfnSLSubByJob]
(
	@Job		bJob 
)
-- ========================================================================
-- Object Name: dbo.mckfnSLSubByJob
-- Author:		Ziebell, Jonathan
-- Create date: 03/21/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	05/11/2017 Initial Build
--				J.Ziebell	06/16/2017 Update
-- ========================================================================
RETURNS TABLE
AS 
RETURN  
SELECT    SLF.SL AS 'SubContract'
		, SLF.Description AS 'Description'
		, SLF.Vendor AS 'Vendor #'
		, SLF.Name AS 'Vendor'
		, SLF.Phase AS 'Phase Code'
		--, SLF.CostType AS 'Cost Type'
		, SLF.LineDescr as 'Line Descr'
		, SLF.ItemCount AS 'Line Count'
		, SLF.SLStatus AS 'SL Status'
		, SLF.CurrentAmount AS 'Current Amount'
		, SLF.Invoiced 
		, SLF.Paid
		, SLF.Retainage
		, SLF.CurrentDue AS 'Current Due'
		, SLF.RemainingCommitted AS 'Remaining Committed'
		, SLF.Overspend as 'Overspend'
FROM dbo.mckvwSLJobFlat SLF
	--INNER JOIN	JCCT CT 
	--	ON SLF.PhaseGroup = CT.PhaseGroup
	--	AND SLF.CostType = CT.CostType 
WHERE SLF.Job = @Job

 GO

 Grant SELECT ON dbo.mckfnSLSubByJob TO [MCKINSTRY\Viewpoint Users]

 ---select top 1000 * from brvSLSubContrByJob;