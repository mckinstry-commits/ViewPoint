SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMPCOSCreatePOCOs]
/*****************************************
* Created By:	TRL	04/15/2011 
* Modified By:	GF 06/07/2011 TK-05921
*				GF 06/21/2011 TK-06039
*				TL 12/01/2011 TK-10436 add parameter 'N' for vspPMPOCONumCreate
*				JG 12/06/2011 TK-10541 - Notes being concatenated from PMOL records to PMSubcontractCO Detail.
*	
******************************************/
(@PMCo bCompany, @Project bProject, @PCO bPCO, @PCOType bDocType,
 @PMMFKeyIDString varchar(max) = null,@PMOLKeyIDString varchar(max) = null,
 @AddToPOCONum int, @LastPOCONumPO varchar(30) output, @LastPOCO int output,
 @errmsg varchar(255) output)

as

set nocount on
   
declare @rcode int, @POCo bCompany,@useapprsubco bYN,@NewPOCONum int,
		@PMMFcurrentKeyID varchar(10),@PMOLcurrentKeyID varchar(10),
		@CurrentVendor bVendor, @CurrentPO varchar(30),@POItem bItem,
		@MaterialType varchar(1), @Seq int, @LastVendor bVendor, 
		@LastPO varchar(30), @pmpoconum smallint, @poconum SMALLINT,
		@retcode INT, @retmsg VARCHAR(255), @PMOLNotes VARCHAR(MAX)

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
select @POCo = APCo from dbo.PMCO where PMCo = @PMCo

--set processing params
select @LastVendor=-1, @LastPO='',  @CurrentVendor=null, @CurrentPO=null
	
while @PMMFKeyIDString is not null
begin
	--get next keyid
	if charindex(char(44), @PMMFKeyIDString) <> 0
		begin
			select @PMMFcurrentKeyID = substring(@PMMFKeyIDString, 1, charindex(char(44), @PMMFKeyIDString) - 1)
			select @PMOLcurrentKeyID = substring(@PMOLKeyIDString, 1, charindex(char(44), @PMOLKeyIDString) - 1)
		end	
	else
		begin
			select @PMMFcurrentKeyID = @PMMFKeyIDString	
			select @PMOLcurrentKeyID = @PMOLKeyIDString	
		end	
		
	--remove current keyid from keystring
	select @PMMFKeyIDString = substring(@PMMFKeyIDString, len(@PMMFcurrentKeyID) + 2, (len(@PMMFKeyIDString) - len(@PMMFcurrentKeyID) + 1))
	select @PMOLKeyIDString = substring(@PMOLKeyIDString, len(@PMOLcurrentKeyID) + 2, (len(@PMOLKeyIDString) - len(@PMOLcurrentKeyID) + 1))
			
	--Get Current row Vendor and SL	
	select @CurrentVendor = Vendor, @CurrentPO = PO, @POItem=POItem, @Seq = Seq
	From dbo.PMMF
	Where KeyID = @PMMFcurrentKeyID

	--Get Current row Notes from PCO Phase Item. TK-10541
	SELECT @PMOLNotes = Notes
	FROM dbo.PMOL
	WHERE KeyID = @PMOLcurrentKeyID	
	
	--@AddToPOCONum only when One Vendor and PO are having
	--POCONum created in frmPMPCOItemCreatePOCOs
	If IsNull(@AddToPOCONum,'') <> ''
		begin
		select @NewPOCONum = @AddToPOCONum
		END
	ELSE
		BEGIN
		--New POCONum are created 
		--A. Vendor changes 
		--B. No Change to Vendor but PO Changes
		If @LastPO <> @CurrentPO ----AND @LastVendor <> @CurrentVendor 
			BEGIN
			---- call the POCO create procedure to generate next POCONum
			SET @NewPOCONum = NULL
			EXEC @retcode = dbo.vspPMPOCONumCreate @PMMFcurrentKeyID, 'N',@NewPOCONum OUTPUT, @retmsg OUTPUT
			IF @retcode <> 0
				BEGIN
				SELECT @errmsg = @retmsg, @rcode = 1
				GOTO vspexit
				END

			IF @NewPOCONum IS NULL
				BEGIN
				SELECT @errmsg = 'Error occurred generating next POCO Number.', @rcode = 1
				GOTO vspexit
				END
				
			END
		END
	
	
	--New POCONums are created 
	--A. Vendor changes 
	--B. No Change to Vendor but PO Changes
	----If @LastVendor<>@CurrentVendor and @LastPO<>@CurrentPO
	----	BEGIN
	----	---- get next POCO Number from PMPOCO
	----	SELECT @NewPOCONum = isnull(max(POCONum) + 1, 1)
	----	FROM dbo.PMPOCO
	----	WHERE POCo = @POCo
	----		AND PO=@CurrentPO 
	----	IF ISNULL(@NewPOCONum,0) = 0 SET @NewPOCONum = 1
	----	END
		
	--@AddToPOCONum only when One Vendor and PO are having
	--POCONums created in frmPMPCOItemCreatePOCO
	----If IsNull(@AddToPOCONum,'') <> ''
	----begin
	----	select @NewPOCONum = @AddToPOCONum
	----end
	
	
	If IsNUll(@NewPOCONum,'') <> '' or @NewPOCONum <> 0
		begin
		
		----update PMOL
		Update dbo.PMOL
		Set POCONum = @NewPOCONum, POCONumSeq=@Seq
		From dbo.PMOL
		Where KeyID = @PMOLcurrentKeyID
		
		----update PMMF
		Update dbo.PMMF
		Set POCONum = @NewPOCONum
		From dbo.PMMF
		Where KeyID = @PMMFcurrentKeyID
	
		---- update PMSubcontractCO with first Notes for the Details. TK-10541	
		IF @PMOLNotes IS NOT NULL AND dbo.Trim(@PMOLNotes) <> ''
			BEGIN
				UPDATE dbo.PMPOCO
				---- Add two spaces between notes
				SET Details = CASE WHEN Details IS NOT NULL THEN Details + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) ELSE '' END + @PMOLNotes
				WHERE PMCo = @PMCo
					AND Project = @Project
					AND PO = @CurrentPO
					AND POCONum = @NewPOCONum		
		
			END
		end
	

	--Set Last Vendor and PO processed
	SET @LastVendor=@CurrentVendor
	SET @LastPO=@CurrentPO
	SET @LastPOCONumPO=@CurrentPO
	SET @LastPOCO=@NewPOCONum
	
	--get the final value
	if charindex(char(44), @PMMFKeyIDString) = 0	
	begin
		set @PMMFKeyIDString = @PMMFKeyIDString + char(44)
		set @PMOLKeyIDString = @PMOLKeyIDString + char(44)
	end
	--set string to null if no values left
	if len(@PMMFKeyIDString) < 2		
	begin
		set @PMMFKeyIDString = null
		set @PMOLKeyIDString = null
	end
end

   
vspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMPCOSCreatePOCOs] TO [public]
GO
