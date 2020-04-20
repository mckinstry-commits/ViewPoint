SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
   
CREATE      VIEW [dbo].[PREHName]
/***************************************
* Created:		??
* Modified:	EN 2/23/05 - added with (nolock)
*			GG 06/08/07 - #124797 - added Crew
*			MH 07/28/10 - #131640 - SM Added full name
*	
*	Used by:	Provides limited data in a nonsecure view of PR Employees
****************************************/
AS
SELECT  PRCo, Employee, LastName, FirstName, MidName, SortName, ActiveYN,
	InsCode, PRDept, Craft, Class, JCCo, Job, EMFixedRate, Suffix, Email, Crew,
	(case when Suffix is null then isnull(LastName, '') + ', ' + isnull(FirstName, '') + ' ' + isnull(MidName, '')
				else isnull(LastName, '') + ' ' + Suffix + ', ' + isnull(FirstName,'') + ' ' + isnull(MidName,'') end) as FullName
FROM dbo.bPREH a with (nolock)



GO
GRANT SELECT ON  [dbo].[PREHName] TO [public]
GRANT INSERT ON  [dbo].[PREHName] TO [public]
GRANT DELETE ON  [dbo].[PREHName] TO [public]
GRANT UPDATE ON  [dbo].[PREHName] TO [public]
GRANT SELECT ON  [dbo].[PREHName] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PREHName] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PREHName] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PREHName] TO [Viewpoint]
GO
