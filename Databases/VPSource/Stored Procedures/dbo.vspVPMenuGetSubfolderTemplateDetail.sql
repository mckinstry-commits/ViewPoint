SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPMenuGetSubfolderTemplateDetail]      
/**************************************************      
* Created: JRK 05/25/2005      
* Modified:   Dave C 5-26-09 -- now using DDTDShared view    
* Modified:   Dave C 6-1-09 -- changed to also return the FolderTemplate Name, as    
* well as the Report name  
*				AMR 06/22/11 - Issue TK-07089 , Fixing performance issue with if exists statement.
*       
*      
* Gets the collection of subfolder template detail for a specified template.      
* Useful in VPMenu for populating a subfolder with shortcuts to forms and reports.      
*      
* Inputs:      
* @id  smallint value identifies the FolderTemplate      
*      
* Output:      
* resultset of Viewpoint Modules with access info      
* @errmsg  Error message      
*      
*      
* Return code:      
* @rcode 0 = success, 1 = failure      
*      
****************************************************/      
 (@id smallint = null, @errmsg varchar(512) output)      
as      
      
set nocount on       
      
declare @rcode int      
select @rcode = 0      
      
      
if @id is null      
 begin      
 select @errmsg = 'Missing required input parameter: id', @rcode = 1      
 goto vspexit      
 end      
      
--Return Forms      
SELECT
	d.FolderTemplate,
	t.Title As TemplateName,
	d.ItemType,
	d.MenuItem,
	f.Title As FriendlyName,
	d.MenuSeq 
FROM
	DDTDShared d
		INNER JOIN
	DDFHShared f
		ON d.MenuItem = f.Form
		INNER JOIN 
	DDTFShared t
		ON d.FolderTemplate = t.FolderTemplate
WHERE
	d.FolderTemplate = @id

UNION ALL

--Return Reports
SELECT
	d.FolderTemplate,
	t.Title As TemplateName,
	d.ItemType,
	d.MenuItem,
	r.Title As FriendlyName,
	d.MenuSeq 
FROM
	dbo.DDTDShared d
	INNER JOIN dbo.DDTFShared t ON d.FolderTemplate = t.FolderTemplate
	-- use inline table function to reduce index scans
	CROSS APPLY (SELECT Title FROM dbo.vfRPRTShared(d.MenuItem)) r 
WHERE
		d.FolderTemplate = @id
	AND	d.ItemType = 'R'
      
vspexit:      
if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuGetSubfolderTemplateDetail]'      
return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetSubfolderTemplateDetail] TO [public]
GO
