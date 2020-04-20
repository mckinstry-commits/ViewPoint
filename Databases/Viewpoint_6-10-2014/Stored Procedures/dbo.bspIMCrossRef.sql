SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMCrossRef]
 /************************************************************************
 * CREATED:		MH 4/12/00
 * MODIFIED:	mh 4/23/01.  Corrected some logic errors.  See below
 *				DANF 10/26/01 Check for any cross reference values before Apply
 *				mh 5/16/03 - make sure IMXD and IMXF use RecordType
 *				rt 10/20/03 - Issue #22770, increase size of @importid to 20.
 *				RT 10/12/04 - #25706, change to xref based on uploadval, not importedval.
 *				CC 02/15/11 - #142869 - allow cross reference to set null based on '[null]' literal (added NULLIF)
 *
 * Purpose of Stored Procedure
 *
 *    Apply cross references set up in IMXH, IMXD, IMXF and IMTD
 *    to IMWE
 *
 *
 * Notes about Stored Procedure
 *
 *
 * returns 0 if successfull
 * returns 1 and error msg if failed
 *
 *************************************************************************/

 (@importtemplate varchar(20), @importid varchar(20), @rectype varchar(30), @msg varchar(80) = '' output)

AS
BEGIN
	SET NOCOUNT ON;

	declare @xrefname varchar(30), @bidtekval varchar(30),
	@sourceident int, @targetident int, @recseq int, @xrefdval varchar(100),
	@uploadval varchar(30), @rcode INT;

	select @rcode = 0;

	if @importtemplate is null
	begin
		select @msg = 'Missing Import Template', @rcode = 1;
		goto bspexit;
	end

	if @importid is null
	begin
		select @msg = 'Missing ImportId', @rcode = 1;
		goto bspexit;
	end

	-- Check ImportTemplate detail for columns to set Cross Reference

	if not exists(
	select IMTD.XRefName
	From IMTD
	join IMXH
	on IMTD.ImportTemplate=IMXH.ImportTemplate and IMTD.XRefName = IMXH.XRefName and
	IMTD.RecordType = IMXH.RecordType
	Where IMTD.ImportTemplate=@importtemplate AND isnull(IMTD.XRefName,'') <> ''
	and IMXH.PMCrossReference <> 'Y' and IMTD.RecordType = @rectype) 
		goto bspexit


	declare cXRefHead cursor local fast_forward for
	select IMTD.XRefName
	From IMTD
	join IMXH
	on IMTD.ImportTemplate=IMXH.ImportTemplate and IMTD.XRefName = IMXH.XRefName and
	IMTD.RecordType = IMXH.RecordType
	Where IMTD.ImportTemplate=@importtemplate AND isnull(IMTD.XRefName,'') <> ''
	and IMXH.PMCrossReference <> 'Y' and IMTD.RecordType = @rectype

	open cXRefHead

	fetch next from cXRefHead into @xrefname

	while @@fetch_status = 0
	begin

	--This is the target identifier where XRef'd value will be written to.
	select @targetident = Identifier
	from IMTD
	where ImportTemplate = @importtemplate and XRefName = @xrefname
	and RecordType = @rectype

	--mark 10/28 added @uploadval = null
	select @recseq = 0, @xrefdval = null, @uploadval = null

	while @recseq is not null
	begin

	declare cXRefCur cursor local fast_forward for
	select ImportField
	from IMXF
	where ImportTemplate = @importtemplate
	and XRefName = @xrefname and RecordType = @rectype

	open cXRefCur

	fetch next from cXRefCur into @sourceident

	while @@fetch_status = 0
	begin
		--mark 4/23
		if @xrefdval is null
		begin
			select @xrefdval = (select ltrim(UploadVal) from IMWE
			where ImportId = @importid and
			ImportTemplate = @importtemplate and
			Identifier = @sourceident and RecordSeq = @recseq
			 and RecordType = @rectype)
		end
		else
		begin
			select @xrefdval = @xrefdval + (select ltrim(UploadVal)
			from IMWE where ImportId = @importid and ImportTemplate = @importtemplate and
			Identifier = @sourceident and RecordSeq = @recseq
			 and RecordType = @rectype)
		end
		--end mark 4/23

		fetch next from cXRefCur into @sourceident

	end

	if @xrefdval is not null and @xrefdval <> ''
	begin

		--mark 4/23 made update statement conditional.

		select @uploadval = (Select BidtekValue from IMXD where ImportTemplate = @importtemplate
		and ImportValue = @xrefdval and XRefName = @xrefname and RecordType = @rectype)

	--mark 10/29
		if @xrefname is not null and @uploadval is not null
		BEGIN
			--note, the '[null]' litteral used in this update statement
			--is also used in frmIMXRefHeader.vb in the imports (IM) module
			--changes to either need to be cross updated
			update IMWE set UploadVal = NULLIF(@uploadval, '[null]')
			where ImportTemplate = @importtemplate and 
			ImportId = @importid and
			Identifier = @targetident and
			RecordSeq = @recseq and
			RecordType = @rectype

		end
	end
	else
	begin

		select @bidtekval = BidtekValue from IMXD where ImportTemplate = @importtemplate and 
		ImportValue = '[null]' and XRefName = @xrefname and RecordType = @rectype

		if @bidtekval is not null
		begin
			update IMWE set UploadVal = @bidtekval
			where ImportTemplate = @importtemplate and
			ImportId = @importid and Identifier = @targetident and 
			RecordSeq = @recseq and 
			RecordType = @rectype
		end
	  end

	close cXRefCur
	deallocate cXRefCur

	--mh 10/29 added @uploadval = null
	select @xrefdval = null,  @uploadval = null
	 
	select @recseq = min(RecordSeq)
	from IMWE
	where ImportTemplate = @importtemplate and
	ImportId = @importid and
	Identifier = @targetident and RecordSeq > @recseq
	 and RecordType = @rectype
	 
	end

	fetch next from cXRefHead into @xrefname

	end

	close cXRefHead
	deallocate cXRefHead

	bspexit:

	return @rcode
END
GO
GRANT EXECUTE ON  [dbo].[bspIMCrossRef] TO [public]
GO
