SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************
 * Created: ??
 * Modified By:	GF 02/13/2007 - 6.x added INFORMATION_SCHEMA columns
 *
 * 
 * Used for PM Document Templates form.
 *
 * 
 *********************************/

CREATE view [dbo].[HQWFGrid] as
select a.*, b.TemplateType, c.ObjectTable, i.NUMERIC_PRECISION, i.DOMAIN_NAME
   from HQWF a
   JOIN HQWD b ON b.TemplateName=a.TemplateName
   JOIN HQWO c ON c.TemplateType=b.TemplateType and c.DocObject=a.DocObject
   JOIN INFORMATION_SCHEMA.COLUMNS i on i.TABLE_NAME = c.ObjectTable and i.COLUMN_NAME=a.ColumnName

GO
GRANT SELECT ON  [dbo].[HQWFGrid] TO [public]
GRANT INSERT ON  [dbo].[HQWFGrid] TO [public]
GRANT DELETE ON  [dbo].[HQWFGrid] TO [public]
GRANT UPDATE ON  [dbo].[HQWFGrid] TO [public]
GRANT SELECT ON  [dbo].[HQWFGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQWFGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQWFGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQWFGrid] TO [Viewpoint]
GO
