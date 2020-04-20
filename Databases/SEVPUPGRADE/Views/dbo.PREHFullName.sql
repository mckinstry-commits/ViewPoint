SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[PREHFullName]
/***************************************
*	Created:	EN 8/31/05 - created for 6x
*	Modified:	GG 09/21/06 - #122535 - removed comma following first name
*				GG 06/08/07 - #124797 - added Crew
*				EN 10/29/07 - #125883 - added Suffix to FullName if one exists
*				MH 08/20/09 - #       - Added PR Group
*	
*	Used by:		lookup PREHFullName
****************************************/
AS
SELECT top 100 percent PRCo, Employee, LastName, FirstName, MidName, 
			  (case when Suffix is null then isnull(LastName, '') + ', ' + isnull(FirstName, '') + ' ' + isnull(MidName, '')
				else isnull(LastName, '') + ' ' + Suffix + ', ' + isnull(FirstName,'') + ' ' + isnull(MidName,'') end) as FullName, 
				SortName, ActiveYN, InsCode, PRDept, Craft, Class, JCCo, Job, EMFixedRate, Suffix, Email, Crew, 
				TimesheetRevGroup, PRGroup
   FROM         dbo.bPREH a with (nolock)

GO
GRANT SELECT ON  [dbo].[PREHFullName] TO [public]
GRANT INSERT ON  [dbo].[PREHFullName] TO [public]
GRANT DELETE ON  [dbo].[PREHFullName] TO [public]
GRANT UPDATE ON  [dbo].[PREHFullName] TO [public]
GO
