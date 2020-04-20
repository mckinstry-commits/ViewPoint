SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRTrainGetResources]
/************************************************************************
* CREATED:	mh 8/23/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Return a set of Resources to be used by HRTrainClassReg.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company', @rcode = 1
		goto vspexit
	end

--	select h.HRCo, h.PRCo, h.HRRef, h.LastName + ' ' + isnull(h.FirstName, '') as 'FullName', h.SortName, h.PRGroup, 
--	p.ChkSort, p.Crew, h.PositionCode, p.JCCo, p.Job, t.TrainCode 
--	from HRRM h
--	join HRET t on h.HRCo = t.HRCo and h.HRRef = t.HRRef and t.ClassSeq is null and t.Status = 'U'
--	left Join PREH p on h.PRCo = p.PRCo and h.PREmp = p.Employee
--	where h.HRCo = @hrco and h.ActiveYN = 'Y' Order By h.SortName
--
--	select h.HRCo, h.PRCo, h.HRRef, h.LastName + ' ' + isnull(h.FirstName, '') as 'FullName', h.SortName, h.PRGroup, 
--	p.ChkSort, p.Crew, h.PositionCode, p.JCCo, p.Job
--	from HRRM h
--	left Join PREH p on h.PRCo = p.PRCo and h.PREmp = p.Employee
--	where h.HRCo = @hrco and h.ActiveYN = 'Y' Order By h.SortName

	select h.HRCo, h.PRCo, h.HRRef, h.LastName + ' ' + isnull(h.FirstName, '') as 'FullName', h.SortName, h.PRGroup, 
	p.ChkSort, p.Crew, h.PositionCode, p.JCCo, p.Job, t.TrainCode 
	from HRRM h
	join HRET t on h.HRCo = t.HRCo and h.HRRef = t.HRRef and t.ClassSeq is null and t.Status = 'U'
	left Join PREH p on h.PRCo = p.PRCo and h.PREmp = p.Employee
	where h.HRCo = @hrco and h.ActiveYN = 'Y' 
union
	select h.HRCo, h.PRCo, h.HRRef, h.LastName + ' ' + isnull(h.FirstName, '') as 'FullName', h.SortName, h.PRGroup, 
	p.ChkSort, p.Crew, h.PositionCode, p.JCCo, p.Job, null as 'TrainCode'
	from HRRM h
	left Join PREH p on h.PRCo = p.PRCo and h.PREmp = p.Employee
	where h.HRCo = @hrco and h.ActiveYN = 'Y' order by h.SortName

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRTrainGetResources] TO [public]
GO
