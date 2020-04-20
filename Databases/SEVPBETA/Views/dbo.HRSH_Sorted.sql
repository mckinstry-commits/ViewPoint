SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************
*
*	Created mh 3/3/2005
*	Purpose	Provide a view of HRSH data sorted by Resource/Effective date.
*
*
*
**********************************/


CREATE view [dbo].[HRSH_Sorted] as 
	select top 100 percent HRCo, HRRef, EffectiveDate, Type, OldSalary, NewSalary,
	NewPositionCode, NextDate, UpdatedYN, HistSeq, CalcYN, BatchId, InUseBatchId,
	InUseMth, Notes, UniqueAttchID
	from dbo.bHRSH Order By HRCo, HRRef, EffectiveDate Desc






GO
GRANT SELECT ON  [dbo].[HRSH_Sorted] TO [public]
GRANT INSERT ON  [dbo].[HRSH_Sorted] TO [public]
GRANT DELETE ON  [dbo].[HRSH_Sorted] TO [public]
GRANT UPDATE ON  [dbo].[HRSH_Sorted] TO [public]
GO
