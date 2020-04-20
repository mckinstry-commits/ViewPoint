SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRInitPRGridFill]
   /************************************************************************
   * CREATED:  mh 10/2/2004    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Return set of Resources/Employees in bHRHP to HRInitPR.  Set is
   *	used to populate form's grid.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *	Created per issue 25519
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
   
/*   
   	select r.PRCo, r.Employee, r.HRRef, case r.UpdateOpt when 'H' then h.LastName + ', ' + 
   	h.FirstName + ' ' + isnull(h.MiddleName, '') when 'P' then p.LastName + ', ' + 
   	p.FirstName + ' ' + isnull(p.MidName, '') end, case r.Status when 0 then 'Y' else 'N' end, 
   	r.ErrMsg 
   	from dbo.bHRHP r with (nolock)
   	left outer join dbo.bHRRM h with (nolock) on r.HRCo = h.HRCo and r.HRRef = h.HRRef 
   	left outer join dbo.bPREH p with (nolock) on r.PRCo = p.PRCo and r.Employee = p.Employee
   	where r.HRCo = @hrco 
*/
   
   	select r.HRCo, r.PRCo, r.Employee, r.HRRef, case r.UpdateOpt when 'H' then h.LastName + ', ' + 
   	h.FirstName + ' ' + isnull(h.MiddleName, '') when 'P' then p.LastName + ', ' + 
   	p.FirstName + ' ' + isnull(p.MidName, '') end as [Name], r.Status, 
   	r.ErrMsg 
   	from dbo.bHRHP r with (nolock)
   	left outer join dbo.bHRRM h with (nolock) on r.HRCo = h.HRCo and r.HRRef = h.HRRef 
   	left outer join dbo.bPREH p with (nolock) on r.PRCo = p.PRCo and r.Employee = p.Employee
   	where r.HRCo = @hrco 
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRInitPRGridFill] TO [public]
GO
