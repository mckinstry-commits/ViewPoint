CREATE FUNCTION dbo.mfnFormatZipCode
(
	-- Add the parameters for the function here
	@ZipCode varchar(12)
)
RETURNS varchar(12)
AS
BEGIN
	-- Declare the return variable here
	declare @retZip varchar(12)

	declare @ZipLen int 
	select @ZipCode=REPLACE(@ZipCode,'-','')
	select @ZipLen = len(@ZipCode)

	if @ZipLen > 5
	begin
		if @ZipLen > 6
		begin
			select @retZip=left(@ZipCode,5) + '-' + SUBSTRING(@ZipCode,6,@ZipLen-5)
		end
		else
		begin
			select @retZip=upper(left(@ZipCode,3) + ' ' + right(@ZipCode,3))
		end

	end
	else
	begin
		select @retZip=@ZipCode
	end

	RETURN @retZip

END
GO

grant exec  on dbo.mfnFormatZipCode to public
go


