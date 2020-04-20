SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[HQMA] 
AS 
/***********************************************************************
*	Created by: 	?
*	Checked by:
*
*	Altered by: 	CC 05/26/2009 - View that returns a list of all HQMA records a user has access to
*					-Checked by JonathanP 05/26/2009
*
*	Returns:		All HQMA records that a user has access to
*
***********************************************************************/

	--Use left anti-semi join pattern, (http://code.msdn.microsoft.com/SQLExamples/Wiki/View.aspx?title=QueryBasedUponAbsenceOfData&referringTitle=Home#LeftAntiSemiJoins)
	--By using IS NULL on the Exclusion list it effectively filters out all matching records (which should be excluded)
	--This method was compared against a NOT IN query, and selecting from a derived table using EXCEPT to 
	--filter out records.  This method was the best performing of the three.
	SELECT bHQMA.*
	FROM bHQMA
	LEFT OUTER JOIN HQSAExclusions
		ON bHQMA.AuditID = HQSAExclusions.AuditID
	WHERE HQSAExclusions.AuditID IS NULL	
GO
GRANT SELECT ON  [dbo].[HQMA] TO [public]
GRANT INSERT ON  [dbo].[HQMA] TO [public]
GRANT DELETE ON  [dbo].[HQMA] TO [public]
GRANT UPDATE ON  [dbo].[HQMA] TO [public]
GRANT SELECT ON  [dbo].[HQMA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQMA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQMA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQMA] TO [Viewpoint]
GO
