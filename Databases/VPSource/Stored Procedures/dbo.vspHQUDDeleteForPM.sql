SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspHQUDDeleteImport    Script Date: 8/28/99 9:32:34 AM ******/
CREATE  proc [dbo].[vspHQUDDeleteForPM]
/***********************************************************
* Created By:	GF 05/07/2010 - issue #139442
* Modified By:  AJW 09/17/12 - B-07373 import forms > 4 characters now
*
*
*
* Only called from vspHQUDDelete.
*
* USAGE: This vsp will delete user memos from PM document tracking grids and PM Import Template Detail.
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@TableName varchar(60) = null, @ViewName varchar(60) = null, @ColumnName varchar(60) = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @ImportForm varchar(60), @TableView varchar(60)

set @rcode = 0
set @ImportForm = null
set @TableView = null

---- verify we have needed information to delete
if @TableName is null goto bspexit
if @ColumnName is null goto bspexit


---- find grid form in PMVG (Document Tracking Grids) and remove from PMVC (Grid Columns)
select @TableView = TableView from dbo.bPMVC with (nolock) where TableView = substring(@TableName,2,30)

if @TableView is not null
	begin
	---- delete column from all PM Document Tracking Views
	delete from dbo.bPMVC
	where TableView = @TableView and ColumnName = @ColumnName
	end


---- find import form name in PMUD and remove from import template detail
select @ImportForm = Form from dbo.bPMUD with (nolock) where Form = substring(@TableName,2,30)

if @ImportForm is null goto bspexit

---- delete column from all PM import templates 
delete dbo.bPMUD
where Form = @ImportForm and ColumnName = @ColumnName



  
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQUDDeleteForPM] TO [public]
GO
