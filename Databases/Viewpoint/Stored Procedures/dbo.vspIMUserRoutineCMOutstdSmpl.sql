SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure dbo.vspIMUserRoutineCMOutstdSmpl
	/******************************************************
	* CREATED BY:	Mark H 
	* MODIFIED By: 
	*
	* Usage:	Routine will convert Checks/Efts listed as positive values in an
	*			imported file into negative values acceptable to CM Post.
	*	
	*
	* Input params:
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), 
	@Form varchar(20), @msg varchar(120) output

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	declare @cmtranstypeID int, @amtID int, @vRecSeq int, @vIdent int, @vImportId varchar(20), @vImportTemp varchar(10),
	@vRecordType varchar(10), @vForm varchar(30), @vImportVal varchar


	select @cmtranstypeID = DDUD.Identifier from IMTD
	   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
	   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CMTransType'

	select @amtID = DDUD.Identifier from IMTD
	   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
	   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Amount'

	
	declare a cursor local fast_forward for 
	Select RecordSeq, Identifier, ImportId, ImportTemplate, RecordType, Form, ImportedVal 
	from IMWEDetail where Identifier = @cmtranstypeID and ImportId = @ImportId and 
	ImportTemplate = @ImportTemplate and Identifier = @cmtranstypeID

	open a

	fetch next from a into @vRecSeq, @vIdent, @vImportId, @vImportTemp, @vRecordType, @vForm,
	@vImportVal

	while @@fetch_status = 0
	begin
		if @vImportVal in (1)
		begin
			update IMWE set UploadVal = (convert(decimal, ImportedVal) * -1) 
			where ImportId = @vImportId and Identifier = @amtID and RecordSeq = @vRecSeq
		end

		fetch next from testcurs into @vRecSeq, @vIdent, @vImportId, @vImportTemp, @vRecordType, @vForm,
		@vImportVal
	end

	close a
	deallocate a

	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspIMUserRoutineCMOutstdSmpl] TO [public]
GO
