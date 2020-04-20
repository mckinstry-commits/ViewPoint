USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mfnJCBatchAllowedDates' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mfnJCBatchAllowedDates'
	DROP FUNCTION dbo.mfnJCBatchAllowedDates
End
GO

Print 'CREATE FUNCTION dbo.mfnJCBatchAllowedDates'
GO


CREATE FUNCTION dbo.mfnJCBatchAllowedDates
(
	@JCCo bCompany
)
-- ========================================================================
--  mers.mfnJCBatchAllowedDates
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	Prophecy Project - McKinstry Projections
-- Update Hist: USER--------DATE-------DESC-----------
--				Ziebell, J	02/09/2017	Fix for More than 2 Months Open
-- ========================================================================
RETURNS TABLE AS RETURN
WITH cte (JCCo, batchmonth, maxbatchmonth) AS
(
    SELECT 
		jcco.JCCo
	,	DATEADD(MONTH,1,glco.LastMthSubClsd) batchmonth
	,	DATEADD(MONTH,glco.MaxOpen,glco.LastMthSubClsd)  maxbatchmonth
    FROM 
	GLCO glco 
		INNER JOIN HQCO HQ
			ON glco.GLCo = HQ.HQCo
			AND ((HQ.udTESTCo ='N') OR (HQ.udTESTCo IS NULL))
		INNER JOIN JCCO jcco
			ON glco.GLCo=jcco.GLCo 
			AND jcco.JCCo=@JCCo
    UNION ALL
    SELECT JCCo,  DATEADD(MONTH, 1, batchmonth), maxbatchmonth
    FROM cte
    WHERE batchmonth < DATEADD(DAY,( DAY(maxbatchmonth) * -1 ) + 1 ,maxbatchmonth) AND JCCo=@JCCo
) 
SELECT 
	JCCo
,	c.batchmonth
FROM 
	cte c

GO

Grant SELECT ON dbo.mfnJCBatchAllowedDates TO [MCKINSTRY\Viewpoint Users]

GO

--Select * From dbo.mfnJCBatchAllowedDates()