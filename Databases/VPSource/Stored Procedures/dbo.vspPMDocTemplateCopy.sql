SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDocTemplateCopy ******/
CREATE  procedure [dbo].[vspPMDocTemplateCopy]
/*******************************************************************************
 * Created By:	GF 02/15/2007 6.x
 * Modified By:	GF 10/30/2009 - issue #134090
 *				GarthT - TK-03251 Added AutoResponse data to template copy.
 *
 *
 *
 * This SP will copy a PM docoument template from a source template to a destination template.
 *
 *
 * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
 *
 * Pass In
 * SrcTemplate		Source template to copy from
 * DestTemplate		Destination template to copy into
 * DestLocation     Destination template location
 * DestFileName		Destination template document file name
 *
 * RETURN PARAMS
 * msg           Error Message, or Success message
 *
 * Returns
 * STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
 *
 ********************************************************************************/
(@srctemplate bReportTitle = null, @desttemplate bReportTitle = null, @destlocation varchar(10) = null,
 @destfilename varchar(60) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @opencursor int

select @rcode = 0, @opencursor = 0

if isnull(@srctemplate,'') = ''
	begin
	select @msg = 'Missing source template', @rcode = 1
	goto bspexit
	end

if isnull(@desttemplate,'') = ''
	begin
	select @msg = 'Missing destination template', @rcode = 1
	goto bspexit
	end

if isnull(@destlocation,'') = ''
	begin
	select @msg = 'Missing destination location', @rcode = 1
	goto bspexit
	end

if isnull(@destfilename,'') = ''
	begin
	select @msg = 'Missing destination file name', @rcode = 1
	goto bspexit
	end


---- verify source template exists
if not exists(select * from HQWD where TemplateName=@srctemplate)
	begin
	select @msg = 'Source Template: ' + isnull(@srctemplate,'') + ' doest not exist.', @rcode = 1
	goto bspexit
	end

---- verify destination template does not exist
if exists(select * from HQWD where TemplateName=@desttemplate)
	begin
	select @msg = 'Destination Template: ' + isnull(@desttemplate,'') + ' already exists.', @rcode = 1
	goto bspexit
	end

---- verify destination location exists
if not exists(select * from HQWL where Location=@destlocation)
	begin
	select @msg = 'Destination location: ' + isnull(@destlocation,'') + ' does not exist.', @rcode = 1
	goto bspexit
	end

---- destination location cannot be 'PMStandard'
if @destlocation = 'PMStandard'
	begin
	select @msg = 'Destination location: ' + isnull(@destlocation,'') + ' cannot be (PMStandard).', @rcode = 1
	goto bspexit
	end



BEGIN TRY

	begin

	begin transaction

	---- copy source template into destination template #134090
	insert into HQWD (TemplateName, Location, TemplateType, FileName, Active, UsedLast, UsedBy,
				WordTable, SuppressZeros, SuppressNotes, StdObject, Notes, CreateFileType, AutoResponse)
	select @desttemplate, @destlocation, a.TemplateType, @destfilename, a.Active, null, null,
				a.WordTable, a.SuppressZeros, a.SuppressNotes, 'N', a.Notes, a.CreateFileType, a.AutoResponse
	from HQWD a where a.TemplateName=@srctemplate

	---- copy source merge fields into destination merge fields
	insert into HQWF (TemplateName, Seq, DocObject, ColumnName, MergeFieldName, MergeOrder, WordTableYN, Format)
	select @desttemplate, a.Seq, a.DocObject, a.ColumnName, a.MergeFieldName, a.MergeOrder, a.WordTableYN, a.Format
	from HQWF a where a.TemplateName=@srctemplate

	---- copy source response fields into destination response fields
	insert into HQDocTemplateResponseField (TemplateName, Seq, DocObject, ColumnName, ResponseFieldName, Caption, ControlType, ResponseValues, Bookmark, ResponseOrder, Visible, [ReadOnly])
	select @desttemplate, a.Seq, a.DocObject, a.ColumnName, a.ResponseFieldName, a.Caption, a.ControlType, a.ResponseValues, a.Bookmark, a.ResponseOrder, a.Visible, a.[ReadOnly]
	from HQDocTemplateResponseField a where a.TemplateName=@srctemplate

	---- copy complete
	commit transaction

	select @msg = 'Document Template has been successfully copied.'
	end

END TRY

BEGIN CATCH
	begin
	IF @@TRANCOUNT > 0
		begin
		rollback transaction
		end
	select @msg = 'Document Template copied failed. ' + ERROR_MESSAGE()
	select @rcode = 1
	end
END CATCH



bspexit:
	select @msg = isnull(@msg,'')
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocTemplateCopy] TO [public]
GO
