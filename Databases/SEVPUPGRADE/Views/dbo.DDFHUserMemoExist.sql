SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[DDFHUserMemoExist] 
/*******************************************************
* Created:	
* Modified:	DANF 02/23/2005
*			JRK 10/18/06 Utilize updated view DDFHUserMemoForms
*			JRK 10/09/07 Restrict 'ud' tables from the view.
*			CC	07/02/09 - #129922 - Added link for form header to culture text
*
*	View for the HQUserMemoDelete form.
*
********************************************************/
    
as

select top 100 percent fh.Form, fh.Title, fh.ViewName, fh.TitleID
from DDFIc fic (nolock)
join DDFHUserMemoForms fh (nolock) on fh.Form = fic.Form
where FieldType = 4 and substring(Lower(fh.Form),1,2) <> 'ud'
group by fh.Form, fh.Title, fh.ViewName, fh.TitleID
order by fh.Title


GO
GRANT SELECT ON  [dbo].[DDFHUserMemoExist] TO [public]
GRANT INSERT ON  [dbo].[DDFHUserMemoExist] TO [public]
GRANT DELETE ON  [dbo].[DDFHUserMemoExist] TO [public]
GRANT UPDATE ON  [dbo].[DDFHUserMemoExist] TO [public]
GO
