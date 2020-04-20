SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMPCOSCreateSubCOs]
/*****************************************
* Created By:	TRL	03/16/2011
* Modified By:	GF 06/21/2011 TK-06039
*				TL 12/01/2011 TK-10436 add parameter 'N' for.vspPMSubcontractCOCreate
*				JG 12/06/2011 TK-10541 - Notes being concatenated from PMOL records to PMSubcontractCO Detail.
*				DAN SO 03/14/2012 TK-13139 - Added second 'N' to vspPMSubcontractCOCreate call
*
******************************************/
(@PMCo bCompany, @Project bProject, @PCO bPCO, @PCOType bDocType,
 @PMSLKeyIDString varchar(max) = null,@PMOLKeyIDString varchar(max) = null,
 @AddToSubCO int, @LastSubCOSL VARCHAR(30) output, @LastSubCO int output,
 @errmsg varchar(255) output)

as
set nocount on
   
declare @rcode int, @retcode INT, @retmsg VARCHAR(255), @SLCo bCompany, @useapprsubco bYN,
		@NewSubCO int, @PMSLcurrentKeyID varchar(10), @PMOLcurrentKeyID varchar(10), 
		@CurrentVendor bVendor, @CurrentSL VARCHAR(30), @SLItem bItem, @SLItemType int,
		@Seq int, @LastVendor bVendor, @LastSL VARCHAR(30), @PMOLNotes VARCHAR(MAX)

select @rcode = 0

if @PMCo is null
begin
	select @errmsg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @Project is null
begin
	select @errmsg = 'Missing Project.', @rcode = 1
	goto vspexit
end

if @PCOType is null
begin
	select @errmsg = 'Missing PCOType.', @rcode = 1
	goto vspexit
end

--get slco		
select @SLCo = APCo, @useapprsubco = UseApprSubCo from dbo.PMCO where PMCo = @PMCo

--set processing params
select @LastVendor=-1, @LastSL='',  @CurrentVendor=null, @CurrentSL=null
	
while @PMSLKeyIDString is not null
begin
	--get next keyid
	if charindex(char(44), @PMSLKeyIDString) <> 0
		begin
			select @PMSLcurrentKeyID = substring(@PMSLKeyIDString, 1, charindex(char(44), @PMSLKeyIDString) - 1)
			select @PMOLcurrentKeyID = substring(@PMOLKeyIDString, 1, charindex(char(44), @PMOLKeyIDString) - 1)
		end	
	else
		begin
			select @PMSLcurrentKeyID = @PMSLKeyIDString	
			select @PMOLcurrentKeyID = @PMOLKeyIDString	
		end	
		
	--remove current keyid from keystring
	select @PMSLKeyIDString = substring(@PMSLKeyIDString, len(@PMSLcurrentKeyID) + 2, (len(@PMSLKeyIDString) - len(@PMSLcurrentKeyID) + 1))
	select @PMOLKeyIDString = substring(@PMOLKeyIDString, len(@PMOLcurrentKeyID) + 2, (len(@PMOLKeyIDString) - len(@PMOLcurrentKeyID) + 1))
			
	--Get Current row Vendor and SL	
	select @CurrentVendor = Vendor, @CurrentSL = SL, @SLItem=SLItem, @Seq = Seq
	From dbo.PMSL
	Where KeyID = @PMSLcurrentKeyID
	
	--Get Current row Notes from PCO Phase Item. TK-10541
	SELECT @PMOLNotes = Notes
	FROM dbo.PMOL
	WHERE KeyID = @PMOLcurrentKeyID
	
	--@AddToSubCo only when One Vendor and SL are having
	--SubCO's created in frmPMPCOItemCreateSubCO
	If IsNull(@AddToSubCO,'') <> ''
		begin
		select @NewSubCO = @AddToSubCO
		END
	ELSE
		BEGIN
		--New SubCO's are created 
		--A. Vendor changes 
		--B. No Change to Vendor but SL Changes
		If @LastSL <> @CurrentSL ----AND @LastVendor <> @CurrentVendor 
			BEGIN
			---- call the subcontract co create procedure to generate next SubCO
			SET @NewSubCO = NULL
			-- TK-13139 --
			EXEC @retcode = dbo.vspPMSubcontractCOCreate @PMSLcurrentKeyID, 'N', 'N', @NewSubCO OUTPUT, @retmsg OUTPUT
			IF @retcode <> 0
				BEGIN
				SELECT @errmsg = @retmsg, @rcode = 1
				GOTO vspexit
				END

			IF @NewSubCO IS NULL
				BEGIN
				SELECT @errmsg = 'Error occurred generating next SubCO.', @rcode = 1
				GOTO vspexit
				END
				
			END
		END
		
	If IsNUll(@NewSubCO,'')<>'' or @NewSubCO <> 0
		begin
		
		--update PMOL
		Update dbo.PMOL
		Set SubCO = @NewSubCO, SubCOSeq=@Seq
		From dbo.PMOL
		Where KeyID = @PMOLcurrentKeyID 
		
		--update PMSL
		Update dbo.PMSL
		Set SubCO = @NewSubCO
		From dbo.PMSL
		Where KeyID = @PMSLcurrentKeyID
	
		---- update PMSubcontractCO with first Notes for the Details. TK-10541	
		IF @PMOLNotes IS NOT NULL AND dbo.Trim(@PMOLNotes) <> ''
			BEGIN
				UPDATE dbo.PMSubcontractCO
				---- Add two spaces between notes
				SET Details = CASE WHEN Details IS NOT NULL THEN Details + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ELSE '' END + @PMOLNotes
				WHERE PMCo = @PMCo
					AND Project = @Project
					AND SL = @CurrentSL
					AND SubCO = @NewSubCO		
		
			END
		end
	

	--Set Last Vendor and SL processed
	select @LastVendor=@CurrentVendor, @LastSL=@CurrentSL, 
	 @LastSubCOSL=@CurrentSL,@LastSubCO=@NewSubCO
	
	--get the final value
	if charindex(char(44), @PMSLKeyIDString) = 0	
	begin
		set @PMSLKeyIDString = @PMSLKeyIDString + char(44)
		set @PMOLKeyIDString = @PMOLKeyIDString + char(44)
	end
	--set string to null if no values left
	if len(@PMSLKeyIDString) < 2		
	begin
		set @PMSLKeyIDString = null
		set @PMOLKeyIDString = null
	end
end

   
vspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMPCOSCreateSubCOs] TO [public]
GO
